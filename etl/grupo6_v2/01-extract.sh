#!/bin/bash
# ============================================================================
# ETL GRUPO 6 v2 - FASE 1: EXTRACCIÓN
# ============================================================================
# Fuente: PostgreSQL dump (schema_pg.sql + hospital_db_inserts.sql)
# Destino: Tablas staging stg_g6_* en clinica_db
#
# Uso: bash etl/grupo6_v2/01-extract.sh
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DUMP_DIR="/tmp/g6_nuevo/db_hospital grupo6"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL GRUPO 6 v2 - FASE 1: EXTRACCIÓN${NC}"
echo -e "${GREEN}============================================${NC}"

# Verificar que los archivos fuente existen
if [ ! -f "$DUMP_DIR/schema_pg.sql" ] || [ ! -f "$DUMP_DIR/hospital_db_inserts.sql" ]; then
    echo -e "${RED}ERROR: Archivos fuente no encontrados en $DUMP_DIR${NC}"
    echo "       Asegúrate de haber extraído db_hospital grupo6.rar"
    exit 1
fi

# -------------------------------------------------------------------
# PASO 1: Crear tablas staging en clinica_db
# -------------------------------------------------------------------
echo -e "${YELLOW}[1/3] Creando tablas staging...${NC}"
docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo6_v2/01-extract.sql

# -------------------------------------------------------------------
# PASO 2: Preparar inserts con prefijo stg_g6_
# -------------------------------------------------------------------
echo -e "${YELLOW}[2/3] Preparando datos para importación...${NC}"

# Convertir encoding WIN1252 → UTF-8 y renombrar tablas a stg_g6_*
iconv -f WINDOWS-1252 -t UTF-8 "$DUMP_DIR/hospital_db_inserts.sql" | \
    sed 's/INSERT INTO public\.\([a-z_]*\)/INSERT INTO stg_g6_\1/g' | \
    grep "^INSERT INTO stg_g6_\(persona\|paciente\|personal\|especialidad\|zona\|tipo_diagnostico\|cita_medica\|diagnostico\|receta\) " \
    > /tmp/g6v2_inserts_staging.sql

TOTAL_INSERTS=$(wc -l < /tmp/g6v2_inserts_staging.sql)
echo "      Preparados: $TOTAL_INSERTS INSERT statements"

# Copiar al contenedor
CONTAINER=$(docker compose ps -q db)
docker cp /tmp/g6v2_inserts_staging.sql "$CONTAINER:/tmp/g6v2_inserts_staging.sql"

# -------------------------------------------------------------------
# PASO 3: Ejecutar inserts en staging
# -------------------------------------------------------------------
echo -e "${YELLOW}[3/3] Cargando datos en staging...${NC}"
docker compose exec -T db psql -U clinica_user -d clinica_db -f /tmp/g6v2_inserts_staging.sql > /dev/null 2>&1

# Verificación
docker compose exec -T db psql -U clinica_user -d clinica_db -c "
    SELECT 'stg_g6_zona' AS tabla, COUNT(*) AS registros FROM stg_g6_zona
    UNION ALL SELECT 'stg_g6_especialidad', COUNT(*) FROM stg_g6_especialidad
    UNION ALL SELECT 'stg_g6_tipo_diagnostico', COUNT(*) FROM stg_g6_tipo_diagnostico
    UNION ALL SELECT 'stg_g6_persona', COUNT(*) FROM stg_g6_persona
    UNION ALL SELECT 'stg_g6_paciente', COUNT(*) FROM stg_g6_paciente
    UNION ALL SELECT 'stg_g6_personal', COUNT(*) FROM stg_g6_personal
    UNION ALL SELECT 'stg_g6_cita_medica', COUNT(*) FROM stg_g6_cita_medica
    UNION ALL SELECT 'stg_g6_diagnostico', COUNT(*) FROM stg_g6_diagnostico
    UNION ALL SELECT 'stg_g6_receta', COUNT(*) FROM stg_g6_receta
    ORDER BY tabla;
"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}EXTRACCIÓN COMPLETADA${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Siguiente paso: ejecutar 02-transform.sql"
echo "  docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo6_v2/02-transform.sql"
