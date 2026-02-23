#!/bin/bash
# ============================================================================
# ETL GRUPO 6 - FASE 1: EXTRACCIÓN
# ============================================================================
# Descripción: Exporta datos de la BD del Grupo 6 (SQLite hospital.db) a CSVs
#              y los importa a tablas staging en nuestra BD PostgreSQL.
#
# Fuente: SQLite → /tmp/grupo6_extract/db/hospital.db
# Destino: clinica_db (tablas con prefijo stg_g6_)
#
# Uso: bash etl/grupo6/01-extract.sh
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SQLITE_DB="/tmp/grupo6_extract/db/hospital.db"
CSV_DIR="/tmp/etl_g6_csv"
mkdir -p "$CSV_DIR"

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}ETL GRUPO 6 - FASE 1: EXTRACCIÓN${NC}"
echo -e "${GREEN}============================================${NC}"

# --- Exportar desde SQLite a CSV ---
echo -e "${YELLOW}[1/8] Exportando Paciente...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT paciente_id, nombres, apellidos, telefono, correo, direccion, fecha_nacimiento, fecha_registro FROM Paciente;" > "$CSV_DIR/g6_pacientes.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_pacientes.csv") - 1 )) registros"

echo -e "${YELLOW}[2/8] Exportando Especialidad...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT especialidad_id, nombre, descripcion FROM Especialidad;" > "$CSV_DIR/g6_especialidades.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_especialidades.csv") - 1 )) registros"

echo -e "${YELLOW}[3/8] Exportando Personal...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT personal_id, nombres, apellidos, rol, especialidad_id, fecha_contratacion FROM Personal;" > "$CSV_DIR/g6_personal.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_personal.csv") - 1 )) registros"

echo -e "${YELLOW}[4/8] Exportando Cita...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT cita_id, paciente_id, medico_id, fecha, hora, estado, fecha_creacion FROM Cita;" > "$CSV_DIR/g6_citas.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_citas.csv") - 1 )) registros"

echo -e "${YELLOW}[5/8] Exportando Historia_Clinica...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT historia_id, paciente_id, fecha_apertura, estado FROM Historia_Clinica;" > "$CSV_DIR/g6_historias.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_historias.csv") - 1 )) registros"

echo -e "${YELLOW}[6/8] Exportando Atencion_Medica...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT atencion_id, historia_id, cita_id, fecha_hora, motivo_consulta, notas_clinicas FROM Atencion_Medica;" > "$CSV_DIR/g6_atenciones.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_atenciones.csv") - 1 )) registros"

echo -e "${YELLOW}[7/8] Exportando Diagnostico...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT diagnostico_id, atencion_id, codigo_cie10, descripcion, tipo FROM Diagnostico;" > "$CSV_DIR/g6_diagnosticos.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_diagnosticos.csv") - 1 )) registros"

echo -e "${YELLOW}[8/8] Exportando Receta...${NC}"
sqlite3 -header -csv "$SQLITE_DB" "SELECT receta_id, diagnostico_id, medicamento, dosis, frecuencia, duracion, indicaciones FROM Receta;" > "$CSV_DIR/g6_recetas.csv"
echo "      → $(( $(wc -l < "$CSV_DIR/g6_recetas.csv") - 1 )) registros"

# --- Copiar CSVs al contenedor Docker ---
echo -e "${YELLOW}Copiando CSVs al contenedor...${NC}"
CONTAINER=$(docker compose ps -q db)
for f in "$CSV_DIR"/g6_*.csv; do
    docker cp "$f" "$CONTAINER:/tmp/$(basename $f)"
done

# --- Importar en tablas staging ---
echo -e "${YELLOW}Importando a tablas staging...${NC}"
docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo6/01-extract.sql

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}EXTRACCIÓN GRUPO 6 COMPLETADA${NC}"
echo -e "${GREEN}============================================${NC}"
echo "Siguiente paso: docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo6/02-transform.sql"
