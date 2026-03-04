#!/bin/bash
# ============================================================================
# ETL: Carga del Data Warehouse (Estrella Simple)
# ============================================================================
# Lee de clinica_db (operacional, puerto 5432) y carga en clinica_db (DW, puerto 5434)
#
# Uso: bash dw/etl-load.sh
# Prerequisito: ambos contenedores db y dw deben estar corriendo
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL: CARGA DATA WAREHOUSE${NC}"
echo -e "${GREEN}============================================${NC}"

# -------------------------------------------------------------------
# PASO 1: Verificar contenedores
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/5] Verificando contenedores...${NC}"
docker compose ps db --status running -q > /dev/null 2>&1 || {
    echo -e "${RED}ERROR: Contenedor 'db' no está corriendo${NC}"; exit 1;
}
docker compose ps dw --status running -q > /dev/null 2>&1 || {
    echo -e "${RED}ERROR: Contenedor 'dw' no está corriendo${NC}"; exit 1;
}
echo "      OK - Ambos contenedores corriendo"

# -------------------------------------------------------------------
# PASO 2: Limpiar tablas DW
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/6] Limpiando tablas DW...${NC}"
docker compose exec -T dw psql -U clinica_user -d clinica_db -c "
    TRUNCATE TABLE fact_atenciones, dim_paciente, dim_medico RESTART IDENTITY CASCADE;
"
echo "      OK - Tablas limpiadas"

# -------------------------------------------------------------------
# PASO 3: Verificar dim_sucursal
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/6] Verificando dim_sucursal...${NC}"
SUC_COUNT=$(docker compose exec -T dw psql -U clinica_user -d clinica_db -tAc "SELECT COUNT(*) FROM dim_sucursal;")
if [ "$SUC_COUNT" -eq 0 ]; then
    echo "      Insertando sucursales..."
    docker compose exec -T dw psql -U clinica_user -d clinica_db -c "
        INSERT INTO dim_sucursal (nombre, host) VALUES
            ('Grupo 3', 'localhost:5433 (PostgreSQL - clinica_db)'),
            ('Grupo 1', 'aws-0-us-west-2.pooler.supabase.com (Supabase)'),
            ('Grupo 6', 'PostgreSQL 17 (dump hospital_db)'),
            ('Grupo 4', 'ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech (Neon)');
    "
fi
echo "      OK - dim_sucursal con $SUC_COUNT sucursales"

# -------------------------------------------------------------------
# PASO 3: Cargar dim_paciente
# -------------------------------------------------------------------
echo -e "${YELLOW}[4/6] Cargando dim_paciente...${NC}"

docker compose exec -T db psql -U clinica_user -d clinica_db -c "
    COPY (
        SELECT
            p.CI,
            p.Nombre,
            p.Fecha_Nacimiento,
            p.Sexo,
            p.Direccion,
            p.Telefono,
            z.Nombre,
            z.Ciudad,
            CASE
                WHEN p.CI LIKE 'G1-%' THEN 'G1'
                WHEN p.CI LIKE 'G4-%' THEN 'G4'
                WHEN p.CI LIKE 'G6-%' THEN 'G6'
                WHEN p.ID_Persona BETWEEN 700001 AND 1000000 THEN 'G4'
                ELSE 'G3'
            END
        FROM PERSONA p
        JOIN ZONA z ON z.ID_Zona = p.ID_Zona
        WHERE p.Matricula IS NULL
        ORDER BY p.ID_Persona
    ) TO STDOUT WITH (FORMAT csv)
" > /tmp/dw_dim_paciente.csv

PAC_COUNT=$(wc -l < /tmp/dw_dim_paciente.csv)
echo "      Extraidos: $PAC_COUNT pacientes"

docker cp /tmp/dw_dim_paciente.csv "$(docker compose ps -q dw)":/tmp/dw_dim_paciente.csv

docker compose exec -T dw psql -U clinica_user -d clinica_db <<'EOSQL'
\copy dim_paciente(ci, nombre, fecha_nacimiento, sexo, direccion, telefono, zona, ciudad, grupo_origen) FROM '/tmp/dw_dim_paciente.csv' WITH (FORMAT csv);

-- Asignar sucursal_key según grupo_origen
UPDATE dim_paciente SET sucursal_key = CASE grupo_origen
    WHEN 'G3' THEN 1
    WHEN 'G1' THEN 2
    WHEN 'G6' THEN 3
    WHEN 'G4' THEN 4
END;
EOSQL
echo "      Cargados: $PAC_COUNT pacientes en dim_paciente (con sucursal_key)"

# -------------------------------------------------------------------
# PASO 4: Cargar dim_medico
# -------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Cargando dim_medico...${NC}"

docker compose exec -T db psql -U clinica_user -d clinica_db -c "
    COPY (
        SELECT DISTINCT
            p.CI,
            p.Nombre,
            p.Matricula,
            p.Sexo,
            COALESCE(e.Nombre, 'Sin especialidad'),
            z.Nombre,
            z.Ciudad,
            CASE
                WHEN p.CI LIKE 'G1-%' THEN 'G1'
                WHEN p.CI LIKE 'G4-%' THEN 'G4'
                WHEN p.CI LIKE 'G6-%' THEN 'G6'
                WHEN p.ID_Persona BETWEEN 1000001 AND 1300000 THEN 'G4'
                ELSE 'G3'
            END
        FROM PERSONA p
        JOIN ZONA z ON z.ID_Zona = p.ID_Zona
        LEFT JOIN ESPECIALIDAD e ON e.ID_Especialidad = p.ID_Especialidad
        WHERE p.Matricula IS NOT NULL
           OR p.ID_Persona IN (SELECT DISTINCT ID_Medico FROM CITA_MEDICA)
        ORDER BY p.CI
    ) TO STDOUT WITH (FORMAT csv)
" > /tmp/dw_dim_medico.csv

MED_COUNT=$(wc -l < /tmp/dw_dim_medico.csv)
echo "      Extraidos: $MED_COUNT medicos"

docker cp /tmp/dw_dim_medico.csv "$(docker compose ps -q dw)":/tmp/dw_dim_medico.csv

docker compose exec -T dw psql -U clinica_user -d clinica_db <<'EOSQL'
\copy dim_medico(ci, nombre, matricula, sexo, especialidad, zona, ciudad, grupo_origen) FROM '/tmp/dw_dim_medico.csv' WITH (FORMAT csv);
EOSQL
echo "      Cargados: $MED_COUNT medicos en dim_medico"

# -------------------------------------------------------------------
# PASO 5: Cargar fact_atenciones
# -------------------------------------------------------------------
echo -e "${YELLOW}[6/6] Cargando fact_atenciones...${NC}"

docker compose exec -T db psql -U clinica_user -d clinica_db -c "
    COPY (
        SELECT
            pac.CI,
            med.CI,
            c.Fecha_Cita,
            EXTRACT(YEAR FROM c.Fecha_Cita)::INT,
            EXTRACT(MONTH FROM c.Fecha_Cita)::INT,
            EXTRACT(QUARTER FROM c.Fecha_Cita)::INT,
            TRIM(TO_CHAR(c.Fecha_Cita, 'Day')),
            c.Hora,
            c.Estado,
            c.Numero_Turno,
            REPLACE(REPLACE(d.Descripcion, E'\n', ' '), E'\r', ' '),
            REPLACE(REPLACE(d.Observaciones, E'\n', ' '), E'\r', ' '),
            d.Tipo_Procedimiento,
            td.Nombre,
            td.Categoria,
            CASE
                WHEN pac.CI LIKE 'G1-%' THEN 'G1'
                WHEN pac.CI LIKE 'G4-%' THEN 'G4'
                WHEN pac.CI LIKE 'G6-%' THEN 'G6'
                WHEN pac.ID_Persona BETWEEN 700001 AND 1000000 THEN 'G4'
                ELSE 'G3'
            END
        FROM DIAGNOSTICO d
        JOIN CITA_MEDICA c ON c.ID_Cita = d.ID_Cita
        JOIN PERSONA pac ON pac.ID_Persona = c.ID_Paciente
        JOIN PERSONA med ON med.ID_Persona = c.ID_Medico
        JOIN TIPO_DIAGNOSTICO td ON td.ID_Tipo_Diagnostico = d.ID_Tipo_Diagnostico
        ORDER BY c.Fecha_Cita, c.ID_Cita
    ) TO STDOUT WITH (FORMAT csv)
" > /tmp/dw_fact_raw.csv

FACT_COUNT=$(wc -l < /tmp/dw_fact_raw.csv)
echo "      Extraidos: $FACT_COUNT registros de hechos"

docker cp /tmp/dw_fact_raw.csv "$(docker compose ps -q dw)":/tmp/dw_fact_raw.csv

docker compose exec -T dw psql -U clinica_user -d clinica_db <<'EOSQL'
BEGIN;

CREATE TEMP TABLE stg_fact (
    paciente_ci        VARCHAR(20),
    medico_ci          VARCHAR(20),
    fecha_cita         DATE,
    anio               INT,
    mes                INT,
    trimestre          INT,
    dia_semana         VARCHAR(15),
    hora               TIME,
    estado             VARCHAR(50),
    numero_turno       INT,
    descripcion        TEXT,
    observaciones      TEXT,
    tipo_procedimiento VARCHAR(100),
    tipo_diagnostico   VARCHAR(100),
    categoria          VARCHAR(100),
    grupo_origen       VARCHAR(10)
);

\copy stg_fact FROM '/tmp/dw_fact_raw.csv' WITH (FORMAT csv);

INSERT INTO fact_atenciones (
    paciente_key, medico_key,
    fecha_cita, anio, mes, trimestre, dia_semana,
    hora, estado, numero_turno,
    descripcion, observaciones, tipo_procedimiento,
    tipo_diagnostico, categoria, grupo_origen
)
SELECT
    dp.paciente_key,
    dm.medico_key,
    sf.fecha_cita, sf.anio, sf.mes, sf.trimestre, sf.dia_semana,
    sf.hora, sf.estado, sf.numero_turno,
    sf.descripcion, sf.observaciones, sf.tipo_procedimiento,
    sf.tipo_diagnostico, sf.categoria, sf.grupo_origen
FROM stg_fact sf
JOIN dim_paciente dp ON dp.ci = sf.paciente_ci
JOIN dim_medico dm ON dm.ci = sf.medico_ci;

COMMIT;
EOSQL

echo "      Cargados en fact_atenciones"

# -------------------------------------------------------------------
# Verificación
# -------------------------------------------------------------------
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}CARGA COMPLETADA - VERIFICACION${NC}"
echo -e "${GREEN}============================================${NC}"
docker compose exec -T dw psql -U clinica_user -d clinica_db -c "
    SELECT 'dim_sucursal' AS tabla, COUNT(*) AS registros FROM dim_sucursal
    UNION ALL
    SELECT 'dim_paciente', COUNT(*) FROM dim_paciente
    UNION ALL
    SELECT 'dim_medico', COUNT(*) FROM dim_medico
    UNION ALL
    SELECT 'fact_atenciones', COUNT(*) FROM fact_atenciones
    ORDER BY tabla;
"

echo ""
echo "Distribución por grupo_origen:"
docker compose exec -T dw psql -U clinica_user -d clinica_db -c "
    SELECT grupo_origen, COUNT(*) AS registros
    FROM fact_atenciones
    GROUP BY grupo_origen
    ORDER BY grupo_origen;
"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL FINALIZADO${NC}"
echo -e "${GREEN}============================================${NC}"
