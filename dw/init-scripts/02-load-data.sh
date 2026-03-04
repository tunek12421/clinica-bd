#!/bin/bash
# ============================================================================
# Carga automatica de datos del Data Warehouse
# Se ejecuta solo en la primera inicializacion del contenedor (volumen vacio)
# ============================================================================

DUMP_FILE="/docker-entrypoint-initdb.d/dw_data.dump"

if [ ! -f "$DUMP_FILE" ]; then
    echo "ADVERTENCIA: No se encontro $DUMP_FILE - DW quedara sin datos"
    exit 0
fi

echo "Cargando datos del Data Warehouse desde $DUMP_FILE ..."

pg_restore \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --data-only \
    --no-owner \
    --no-acl \
    --disable-triggers \
    "$DUMP_FILE" || echo "pg_restore finalizo con advertencias (ignoradas)"

echo "Datos del DW cargados exitosamente"

# Verificacion rapida
psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT 'dim_sucursal' AS tabla, COUNT(*) AS registros FROM dim_sucursal
    UNION ALL SELECT 'dim_paciente', COUNT(*) FROM dim_paciente
    UNION ALL SELECT 'dim_medico', COUNT(*) FROM dim_medico
    UNION ALL SELECT 'fact_atenciones', COUNT(*) FROM fact_atenciones
    ORDER BY tabla;
"
