#!/bin/bash
# ============================================================================
# ETL GRUPO 1 - FASE 1: EXTRACCIÓN (Orquestador)
# ============================================================================
# Descripción: Exporta datos de la BD del Grupo 1 a CSVs y luego los importa
#              a tablas staging en nuestra BD.
#
# Uso: bash etl/grupo1/01-extract.sh
#      (ejecutar desde la raíz del proyecto donde está docker-compose.yml)
#
# Proceso:
#   1. Conecta a BD Grupo 1 (Supabase) → exporta 4 tablas a CSV
#   2. Copia CSVs al contenedor Docker
#   3. Ejecuta 01-extract.sql para crear tablas staging e importar CSVs
# ============================================================================

set -e  # Salir ante cualquier error

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuración de conexión - Grupo 1 (Supabase)
G1_CONN="postgresql://usuario1.fgzrkjkflenmdmyfnkpr:upds2026@35.160.209.8:5432/postgres?sslmode=require"

# Directorio temporal para CSVs
CSV_DIR="/tmp/etl_g1_csv"
mkdir -p "$CSV_DIR"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL GRUPO 1 - FASE 1: EXTRACCIÓN${NC}"
echo -e "${GREEN}============================================${NC}"

# ----------------------------------------------------------------------------
# PASO 1: Exportar datos de Grupo 1 a CSV
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[1/6] Exportando pacientes...${NC}"
docker compose exec -T db psql "$G1_CONN" -c "\copy (SELECT paciente_id, nombre, fecha_nacimiento, genero FROM pacientes ORDER BY paciente_id) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$CSV_DIR/g1_pacientes.csv"
PAC_COUNT=$(( $(wc -l < "$CSV_DIR/g1_pacientes.csv") - 1 ))
echo "      → $PAC_COUNT registros"

echo -e "${YELLOW}[2/6] Exportando personal...${NC}"
docker compose exec -T db psql "$G1_CONN" -c "\copy (SELECT personal_id, nombre, cargo, especialidad FROM personal ORDER BY personal_id) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$CSV_DIR/g1_personal.csv"
PER_COUNT=$(( $(wc -l < "$CSV_DIR/g1_personal.csv") - 1 ))
echo "      → $PER_COUNT registros"

echo -e "${YELLOW}[3/6] Exportando atenciones...${NC}"
docker compose exec -T db psql "$G1_CONN" -c "\copy (SELECT atencion_id, paciente_id, personal_id, fecha_atencion, estado, motivo_consulta FROM atenciones ORDER BY atencion_id) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$CSV_DIR/g1_atenciones.csv"
ATE_COUNT=$(( $(wc -l < "$CSV_DIR/g1_atenciones.csv") - 1 ))
echo "      → $ATE_COUNT registros"

echo -e "${YELLOW}[4/6] Exportando diagnosticos...${NC}"
docker compose exec -T db psql "$G1_CONN" -c "\copy (SELECT diagnostico_id, atencion_id, codigo_cie10, descripcion, severidad FROM diagnosticos ORDER BY diagnostico_id) TO STDOUT WITH (FORMAT csv, HEADER true)" > "$CSV_DIR/g1_diagnosticos.csv"
DIA_COUNT=$(( $(wc -l < "$CSV_DIR/g1_diagnosticos.csv") - 1 ))
echo "      → $DIA_COUNT registros"

# ----------------------------------------------------------------------------
# PASO 2: Copiar CSVs al contenedor Docker
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Copiando CSVs al contenedor...${NC}"
CONTAINER=$(docker compose ps -q db)
docker cp "$CSV_DIR/g1_pacientes.csv" "$CONTAINER:/tmp/g1_pacientes.csv"
docker cp "$CSV_DIR/g1_personal.csv" "$CONTAINER:/tmp/g1_personal.csv"
docker cp "$CSV_DIR/g1_atenciones.csv" "$CONTAINER:/tmp/g1_atenciones.csv"
docker cp "$CSV_DIR/g1_diagnosticos.csv" "$CONTAINER:/tmp/g1_diagnosticos.csv"

# ----------------------------------------------------------------------------
# PASO 3: Crear tablas staging e importar CSVs
# ----------------------------------------------------------------------------
echo -e "${YELLOW}[6/6] Importando a tablas staging...${NC}"
docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo1/01-extract.sql

# ----------------------------------------------------------------------------
# Resumen
# ----------------------------------------------------------------------------
TOTAL=$(( PAC_COUNT + PER_COUNT + ATE_COUNT + DIA_COUNT ))
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}EXTRACCIÓN COMPLETADA${NC}"
echo -e "${GREEN}============================================${NC}"
echo "Pacientes:    $PAC_COUNT"
echo "Personal:     $PER_COUNT"
echo "Atenciones:   $ATE_COUNT"
echo "Diagnósticos: $DIA_COUNT"
echo "TOTAL:        $TOTAL registros"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Siguiente paso: ejecutar 02-transform.sql"
echo "  docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo1/02-transform.sql"
