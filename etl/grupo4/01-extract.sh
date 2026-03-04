#!/bin/bash
# ============================================================================
# ETL GRUPO 4 - FASE 1: EXTRACCIÓN (Orquestador)
# ============================================================================
# Descripción: Exporta datos de la BD del Grupo 4 (Neon - modelo estrella)
#              a CSVs y los importa a tablas staging en nuestra BD PostgreSQL.
#
# Fuente:    PostgreSQL en Neon (Azure eastus2)
#            Host: ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech
#            BD:   neondb (usuario: usuario_lectura, solo lectura)
#
# Nota:      El Grupo 4 migró su BD transaccional a un modelo estrella (DW).
#            Extraemos de sus dimensiones y fact table, no de tablas OLTP.
#
# Uso: bash etl/grupo4/01-extract.sh
#      (ejecutar desde la raíz del proyecto donde está docker-compose.yml)
#
# Proceso:
#   1. Conecta a BD Grupo 4 (Neon) → exporta 3 datasets a CSV
#   2. Copia CSVs al contenedor Docker
#   3. Ejecuta 01-extract.sql para crear tablas staging e importar CSVs
# ============================================================================

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración de conexión - Grupo 4 (Neon)
G4_CONN="postgresql://usuario_lectura:ClaveSegura123@ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech:5432/neondb?sslmode=require"

# Directorio temporal para CSVs
CSV_DIR="/tmp/etl_g4_csv"
mkdir -p "$CSV_DIR"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL GRUPO 4 - FASE 1: EXTRACCIÓN${NC}"
echo -e "${GREEN}============================================${NC}"

# -------------------------------------------------------------------
# Verificar conectividad con Neon
# -------------------------------------------------------------------
echo -e "${YELLOW}[0/5] Verificando conexión a Neon...${NC}"
psql "$G4_CONN" -c "SELECT 1" > /dev/null 2>&1 || {
    echo -e "${RED}ERROR: No se puede conectar a Neon${NC}"; exit 1;
}
echo "      OK - Conexión a Neon establecida"

# -------------------------------------------------------------------
# PASO 1: Exportar pacientes (dim_paciente)
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/5] Exportando dim_paciente (pacientes)...${NC}"
psql "$G4_CONN" -c "\copy (
    SELECT
        paciente_sk,
        ci,
        nombre_completo,
        sexo,
        fecha_nacimiento,
        COALESCE(direccion, 'Sin dato (Grupo 4)'),
        COALESCE(zona, 'Sin dato'),
        COALESCE(municipio, 'Sin dato')
    FROM dim_paciente
    ORDER BY paciente_sk
) TO STDOUT WITH (FORMAT csv)" > "$CSV_DIR/g4_pacientes.csv"
echo "      → $(wc -l < "$CSV_DIR/g4_pacientes.csv") registros"

# -------------------------------------------------------------------
# PASO 2: Exportar personal médico (dim_personal_medico)
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/5] Exportando dim_personal_medico (personal)...${NC}"
psql "$G4_CONN" -c "\copy (
    SELECT
        personal_sk,
        nombre_completo,
        especialidad,
        cargo,
        COALESCE(colegiatura, 'G4-COL-' || personal_sk)
    FROM dim_personal_medico
    ORDER BY personal_sk
) TO STDOUT WITH (FORMAT csv)" > "$CSV_DIR/g4_personal.csv"
echo "      → $(wc -l < "$CSV_DIR/g4_personal.csv") registros"

# -------------------------------------------------------------------
# PASO 3: Exportar atenciones con JOINs a dimensiones
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/5] Exportando fact_atenciones + dim_tiempo + dim_diagnostico...${NC}"
psql "$G4_CONN" -c "\copy (
    SELECT
        fa.atencion_sk,
        dp.ci AS paciente_ci,
        fa.personal_sk,
        dt.fecha,
        dt.anio,
        dt.mes,
        dt.trimestre,
        COALESCE(dt.nombre_dia, 'Sin dato'),
        fa.tipo_atencion,
        fa.estado,
        COALESCE(dd.diagnostico, 'Sin diagnóstico'),
        COALESCE(dd.codigo_cie10, 'N/A'),
        COALESCE(dd.categoria_cie10, 'Sin categoría'),
        COALESCE(dd.grupo_enfermedad, 'Sin grupo'),
        COALESCE(dd.tipo, 'Sin tipo')
    FROM fact_atenciones fa
    JOIN dim_tiempo dt ON dt.tiempo_sk = fa.tiempo_sk
    JOIN dim_paciente dp ON dp.paciente_sk = fa.paciente_sk
    LEFT JOIN dim_diagnostico dd ON dd.diagnostico_sk = fa.diagnostico_principal_sk
    ORDER BY fa.atencion_sk
) TO STDOUT WITH (FORMAT csv)" > "$CSV_DIR/g4_atenciones.csv"
echo "      → $(wc -l < "$CSV_DIR/g4_atenciones.csv") registros"

# -------------------------------------------------------------------
# PASO 4: Copiar CSVs al contenedor Docker
# -------------------------------------------------------------------
echo -e "${YELLOW}[4/5] Copiando CSVs al contenedor...${NC}"
CONTAINER=$(docker compose ps -q db)
for f in "$CSV_DIR"/g4_*.csv; do
    docker cp "$f" "$CONTAINER:/tmp/$(basename $f)"
done
echo "      OK - CSVs copiados"

# -------------------------------------------------------------------
# PASO 5: Importar en tablas staging
# -------------------------------------------------------------------
echo -e "${YELLOW}[5/5] Importando a tablas staging...${NC}"
docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo4/01-extract.sql

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}EXTRACCIÓN GRUPO 4 COMPLETADA${NC}"
echo -e "${GREEN}============================================${NC}"
echo "Siguiente paso:"
echo "  docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo4/02-transform.sql"
