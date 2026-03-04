-- ############################################################################
-- COMPARACIÓN PRÁCTICA: ROLAP vs MOLAP vs HOLAP
-- ############################################################################
-- Usando el Data Warehouse de la Clínica (modelo estrella en PostgreSQL)
--
-- Conexión: psql -h localhost -p 5434 -U clinica_user -d clinica_db
-- ############################################################################


-- ============================================================================
--  1. ROLAP (Relational OLAP) — Lo que YA usamos
-- ============================================================================
-- Los datos están en tablas relacionales (fact_atenciones + dimensiones).
-- Cada consulta calcula los agregados AL MOMENTO de ejecutarse.
-- NO hay nada pre-calculado.
--
-- Ventaja:  datos siempre actualizados, sin duplicación de almacenamiento
-- Desventaja: cada consulta recalcula todo → más lento en cubos grandes
-- ============================================================================

-- ROLAP: Cubo de atenciones por especialidad × sucursal × gestión
-- PostgreSQL calcula las 8 combinaciones CADA VEZ que se ejecuta
EXPLAIN ANALYZE
SELECT
    COALESCE(dm.especialidad, '** TODAS **')   AS especialidad,
    COALESCE(ds.nombre, '** TODAS **')          AS sucursal,
    COALESCE(fa.anio::TEXT, '** TODOS **')      AS gestion,
    COUNT(*)                                    AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY CUBE (dm.especialidad, ds.nombre, fa.anio)
ORDER BY
    GROUPING(dm.especialidad), dm.especialidad,
    GROUPING(ds.nombre), ds.nombre,
    GROUPING(fa.anio), fa.anio;

-- ROLAP: Drill-down temporal (también calcula al vuelo)
EXPLAIN ANALYZE
SELECT
    fa.anio       AS gestion,
    fa.trimestre,
    fa.mes,
    COUNT(*)      AS total_atenciones
FROM fact_atenciones fa
GROUP BY ROLLUP (fa.anio, fa.trimestre, fa.mes)
ORDER BY
    GROUPING(fa.anio), fa.anio,
    GROUPING(fa.trimestre), fa.trimestre,
    GROUPING(fa.mes), fa.mes;


-- ============================================================================
--  2. MOLAP (Multidimensional OLAP) — Simulación con tablas pre-calculadas
-- ============================================================================
-- En un MOLAP real (Essbase, SSAS Multidimensional), los cubos se almacenan
-- en estructuras multidimensionales propietarias en disco.
--
-- En PostgreSQL lo simulamos con TABLAS MATERIALIZADAS que almacenan
-- TODOS los agregados pre-calculados. Las consultas leen directamente
-- de estas tablas sin hacer JOINs ni GROUP BY.
--
-- Ventaja:  consultas instantáneas (solo lectura de tabla)
-- Desventaja: ocupa espacio extra, hay que recalcular al actualizar datos
-- ============================================================================

-- ── Paso 1: Crear las tablas pre-calculadas (simula la "carga del cubo") ────

-- MOLAP Cubo 1: Especialidad × Sucursal × Gestión (todas las combinaciones)
DROP TABLE IF EXISTS molap_cubo_especialidad_sucursal_gestion;
CREATE TABLE molap_cubo_especialidad_sucursal_gestion AS
SELECT
    dm.especialidad,
    ds.nombre                              AS sucursal,
    fa.anio                                AS gestion,
    GROUPING(dm.especialidad)              AS grp_especialidad,
    GROUPING(ds.nombre)                    AS grp_sucursal,
    GROUPING(fa.anio)                      AS grp_gestion,
    COUNT(*)                               AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)        AS pacientes_unicos,
    COUNT(DISTINCT fa.medico_key)          AS medicos_involucrados
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY CUBE (dm.especialidad, ds.nombre, fa.anio);

CREATE INDEX idx_molap_c1_esp ON molap_cubo_especialidad_sucursal_gestion(especialidad);
CREATE INDEX idx_molap_c1_suc ON molap_cubo_especialidad_sucursal_gestion(sucursal);
CREATE INDEX idx_molap_c1_ges ON molap_cubo_especialidad_sucursal_gestion(gestion);

-- MOLAP Cubo 2: Jerarquía temporal (año → trimestre → mes)
DROP TABLE IF EXISTS molap_cubo_temporal;
CREATE TABLE molap_cubo_temporal AS
SELECT
    fa.anio                                AS gestion,
    fa.trimestre,
    fa.mes,
    GROUPING(fa.anio)                      AS grp_gestion,
    GROUPING(fa.trimestre)                 AS grp_trimestre,
    GROUPING(fa.mes)                       AS grp_mes,
    COUNT(*)                               AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)        AS pacientes_unicos
FROM fact_atenciones fa
GROUP BY ROLLUP (fa.anio, fa.trimestre, fa.mes);

CREATE INDEX idx_molap_c2_anio ON molap_cubo_temporal(gestion);

-- MOLAP Cubo 3: Diagnósticos × Especialidad
DROP TABLE IF EXISTS molap_cubo_diagnostico_especialidad;
CREATE TABLE molap_cubo_diagnostico_especialidad AS
SELECT
    fa.tipo_diagnostico,
    fa.categoria,
    dm.especialidad,
    GROUPING(fa.tipo_diagnostico)          AS grp_tipo,
    GROUPING(fa.categoria)                 AS grp_categoria,
    GROUPING(dm.especialidad)              AS grp_especialidad,
    COUNT(*)                               AS total_diagnosticos
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY CUBE (fa.tipo_diagnostico, fa.categoria, dm.especialidad);

CREATE INDEX idx_molap_c3_tipo ON molap_cubo_diagnostico_especialidad(tipo_diagnostico);
CREATE INDEX idx_molap_c3_esp  ON molap_cubo_diagnostico_especialidad(especialidad);


-- ── Paso 2: Consultar el cubo MOLAP (lectura directa, sin cálculos) ─────────

-- MOLAP consulta: Gran total de atenciones (instantáneo)
EXPLAIN ANALYZE
SELECT total_atenciones, pacientes_unicos, medicos_involucrados
FROM molap_cubo_especialidad_sucursal_gestion
WHERE grp_especialidad = 1
  AND grp_sucursal     = 1
  AND grp_gestion      = 1;

-- MOLAP consulta: Atenciones por especialidad (sin GROUP BY, ya pre-calculado)
EXPLAIN ANALYZE
SELECT
    COALESCE(especialidad, '** TODAS **') AS especialidad,
    total_atenciones,
    pacientes_unicos
FROM molap_cubo_especialidad_sucursal_gestion
WHERE grp_especialidad = 0       -- solo filas con especialidad
  AND grp_sucursal     = 1       -- agrupado en sucursal (todas)
  AND grp_gestion      = 1       -- agrupado en gestión (todas)
ORDER BY total_atenciones DESC;

-- MOLAP consulta: Slice → solo Grupo 3 (lectura directa)
EXPLAIN ANALYZE
SELECT
    COALESCE(especialidad, '** TODAS **') AS especialidad,
    total_atenciones
FROM molap_cubo_especialidad_sucursal_gestion
WHERE sucursal = 'Grupo 3'
  AND grp_sucursal     = 0       -- sucursal fija (no agrupada)
  AND grp_especialidad = 0       -- desglose por especialidad
  AND grp_gestion      = 1       -- todas las gestiones
ORDER BY total_atenciones DESC;

-- MOLAP consulta: Drill-down temporal (lectura de tabla pre-calculada)
EXPLAIN ANALYZE
SELECT
    COALESCE(gestion::TEXT, '** TODOS **')    AS gestion,
    COALESCE(trimestre::TEXT, '** TODOS **')  AS trimestre,
    COALESCE(mes::TEXT, '** TODOS **')        AS mes,
    total_atenciones,
    pacientes_unicos
FROM molap_cubo_temporal
ORDER BY
    grp_gestion, gestion,
    grp_trimestre, trimestre,
    grp_mes, mes;


-- ============================================================================
--  3. HOLAP (Hybrid OLAP) — Vistas materializadas + consultas en vivo
-- ============================================================================
-- Combina lo mejor de ambos:
--   • Agregados frecuentes → MATERIALIZED VIEW (pre-calculados, como MOLAP)
--   • Detalle granular     → consulta en vivo sobre fact_atenciones (como ROLAP)
--
-- Las vistas materializadas se refrescan periódicamente con REFRESH.
-- Las consultas de detalle acceden a los datos en vivo.
--
-- Ventaja:  rápido para agregados, flexible para detalle
-- Desventaja: hay que decidir qué pre-calcular y cuándo refrescar
-- ============================================================================

-- ── Capa MOLAP del HOLAP: vistas materializadas para agregados frecuentes ───

-- HOLAP-MOLAP: Resumen por especialidad y sucursal (consulta frecuente)
DROP MATERIALIZED VIEW IF EXISTS holap_mv_especialidad_sucursal;
CREATE MATERIALIZED VIEW holap_mv_especialidad_sucursal AS
SELECT
    dm.especialidad,
    ds.nombre                              AS sucursal,
    COUNT(*)                               AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)        AS pacientes_unicos,
    COUNT(DISTINCT fa.medico_key)          AS medicos_involucrados
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY dm.especialidad, ds.nombre;

CREATE INDEX idx_holap_mv1_esp ON holap_mv_especialidad_sucursal(especialidad);
CREATE INDEX idx_holap_mv1_suc ON holap_mv_especialidad_sucursal(sucursal);

-- HOLAP-MOLAP: Resumen mensual por sucursal (consulta frecuente)
DROP MATERIALIZED VIEW IF EXISTS holap_mv_mensual_sucursal;
CREATE MATERIALIZED VIEW holap_mv_mensual_sucursal AS
SELECT
    fa.anio                                AS gestion,
    fa.mes,
    ds.nombre                              AS sucursal,
    COUNT(*)                               AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)        AS pacientes_unicos
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY fa.anio, fa.mes, ds.nombre;

CREATE INDEX idx_holap_mv2_anio ON holap_mv_mensual_sucursal(gestion, mes);
CREATE INDEX idx_holap_mv2_suc  ON holap_mv_mensual_sucursal(sucursal);


-- ── Consultas HOLAP: capa MOLAP (rápido, pre-calculado) ─────────────────────

-- HOLAP-MOLAP: Ranking de especialidades por sucursal (lectura de vista)
EXPLAIN ANALYZE
SELECT especialidad, sucursal, total_atenciones, pacientes_unicos
FROM holap_mv_especialidad_sucursal
ORDER BY sucursal, total_atenciones DESC;

-- HOLAP-MOLAP: Tendencia mensual por sucursal (lectura de vista)
EXPLAIN ANALYZE
SELECT gestion, mes, sucursal, total_atenciones
FROM holap_mv_mensual_sucursal
ORDER BY gestion, mes, sucursal;


-- ── Consultas HOLAP: capa ROLAP (detalle en vivo, no pre-calculado) ─────────

-- HOLAP-ROLAP: Detalle de atenciones de una especialidad específica (en vivo)
-- Esta consulta necesita datos granulares → va directo a fact_atenciones
EXPLAIN ANALYZE
SELECT
    fa.fecha_cita,
    dp.nombre           AS paciente,
    dm.nombre           AS medico,
    fa.descripcion      AS diagnostico,
    fa.tipo_diagnostico,
    fa.hora
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
WHERE dm.especialidad = 'Pediatria'
  AND fa.anio = 2024
ORDER BY fa.fecha_cita, fa.hora;

-- HOLAP-ROLAP: Búsqueda de un paciente específico (en vivo)
-- Los cubos pre-calculados no tienen este nivel de detalle
EXPLAIN ANALYZE
SELECT
    fa.fecha_cita,
    dm.nombre           AS medico,
    dm.especialidad,
    fa.descripcion      AS diagnostico,
    fa.observaciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
WHERE dp.ci = '12345678'
ORDER BY fa.fecha_cita DESC;


-- ── Mantenimiento HOLAP: refrescar vistas cuando se cargan datos nuevos ─────

-- Después de cada ETL, se ejecuta:
REFRESH MATERIALIZED VIEW holap_mv_especialidad_sucursal;
REFRESH MATERIALIZED VIEW holap_mv_mensual_sucursal;
-- Las tablas base (fact_atenciones) ya están actualizadas por el ETL


-- ############################################################################
--  4. COMPARACIÓN DIRECTA: La misma pregunta en las 3 arquitecturas
-- ############################################################################
-- Pregunta: "¿Cuántas atenciones tiene cada especialidad por sucursal?"
-- ############################################################################

-- ── ROLAP: Calcula al vuelo con JOINs y GROUP BY ────────────────────────────
-- Siempre actualizado | Más lento (3 JOINs + agregación)
EXPLAIN ANALYZE
SELECT
    dm.especialidad,
    ds.nombre          AS sucursal,
    COUNT(*)           AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY dm.especialidad, ds.nombre
ORDER BY dm.especialidad, total_atenciones DESC;

-- ── MOLAP: Lee de tabla pre-calculada (sin JOINs, sin GROUP BY) ─────────────
-- Instantáneo | Puede estar desactualizado si no se recalculó
EXPLAIN ANALYZE
SELECT
    COALESCE(especialidad, '** TODAS **') AS especialidad,
    COALESCE(sucursal, '** TODAS **')     AS sucursal,
    total_atenciones
FROM molap_cubo_especialidad_sucursal_gestion
WHERE grp_especialidad = 0
  AND grp_sucursal     = 0
  AND grp_gestion      = 1
ORDER BY especialidad, total_atenciones DESC;

-- ── HOLAP: Lee de vista materializada (sin JOINs, sin GROUP BY) ─────────────
-- Rápido | Se refresca con REFRESH MATERIALIZED VIEW
EXPLAIN ANALYZE
SELECT especialidad, sucursal, total_atenciones
FROM holap_mv_especialidad_sucursal
ORDER BY especialidad, total_atenciones DESC;


-- ############################################################################
--  5. VERIFICACIÓN DE ESPACIO EN DISCO
-- ############################################################################
-- Compara cuánto almacenamiento usa cada enfoque
-- ############################################################################

-- Tamaño de las tablas base (ROLAP — solo esto se necesita)
SELECT
    'ROLAP' AS enfoque,
    relname AS tabla,
    pg_size_pretty(pg_total_relation_size(oid)) AS tamanio
FROM pg_class
WHERE relname IN ('fact_atenciones', 'dim_medico', 'dim_paciente', 'dim_sucursal')
ORDER BY pg_total_relation_size(oid) DESC;

-- Tamaño de las tablas MOLAP (almacenamiento adicional)
SELECT
    'MOLAP' AS enfoque,
    relname AS tabla,
    pg_size_pretty(pg_total_relation_size(oid)) AS tamanio
FROM pg_class
WHERE relname LIKE 'molap_%'
ORDER BY pg_total_relation_size(oid) DESC;

-- Tamaño de las vistas materializadas HOLAP (almacenamiento adicional)
SELECT
    'HOLAP' AS enfoque,
    relname AS tabla,
    pg_size_pretty(pg_total_relation_size(oid)) AS tamanio
FROM pg_class
WHERE relname LIKE 'holap_%' AND relkind = 'm'
ORDER BY pg_total_relation_size(oid) DESC;

-- Resumen comparativo de almacenamiento total por enfoque
SELECT enfoque, pg_size_pretty(SUM(tamanio_bytes)) AS tamanio_total
FROM (
    SELECT 'ROLAP' AS enfoque, pg_total_relation_size(oid) AS tamanio_bytes
    FROM pg_class WHERE relname IN ('fact_atenciones','dim_medico','dim_paciente','dim_sucursal')
    UNION ALL
    SELECT 'MOLAP (extra)', pg_total_relation_size(oid)
    FROM pg_class WHERE relname LIKE 'molap_%'
    UNION ALL
    SELECT 'HOLAP (extra)', pg_total_relation_size(oid)
    FROM pg_class WHERE relname LIKE 'holap_%' AND relkind = 'm'
) t
GROUP BY enfoque
ORDER BY enfoque;


-- ############################################################################
--  6. CONTEO DE FILAS: Explosión combinatoria del MOLAP
-- ############################################################################
-- Demuestra cómo MOLAP genera muchas más filas que el dato original
-- ############################################################################

SELECT 'fact_atenciones (dato original)'          AS tabla, COUNT(*) AS filas FROM fact_atenciones
UNION ALL
SELECT 'molap_cubo_especialidad_sucursal_gestion', COUNT(*) FROM molap_cubo_especialidad_sucursal_gestion
UNION ALL
SELECT 'molap_cubo_temporal',                      COUNT(*) FROM molap_cubo_temporal
UNION ALL
SELECT 'molap_cubo_diagnostico_especialidad',      COUNT(*) FROM molap_cubo_diagnostico_especialidad
UNION ALL
SELECT 'holap_mv_especialidad_sucursal',           COUNT(*) FROM holap_mv_especialidad_sucursal
UNION ALL
SELECT 'holap_mv_mensual_sucursal',                COUNT(*) FROM holap_mv_mensual_sucursal
ORDER BY filas DESC;


-- ############################################################################
--  RESUMEN COMPARATIVO
-- ############################################################################
--
--  ┌─────────────┬──────────────────────┬───────────────────┬──────────────────┐
--  │  Criterio   │       ROLAP          │      MOLAP        │      HOLAP       │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Almacena-   │ Solo tablas base     │ Tablas pre-       │ Vistas mat. para │
--  │ miento      │ (fact + dims)        │ calculadas (CUBE) │ agregados frec.  │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Velocidad   │ Lenta (calcula       │ Muy rápida        │ Rápida p/agreg.  │
--  │ consulta    │ al vuelo con JOINs)  │ (lectura directa) │ Normal p/detalle │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Actualiza-  │ Siempre actualizado  │ Hay que recrear   │ REFRESH MATERIAL │
--  │ ción        │ (lee datos en vivo)  │ tablas tras ETL   │ VIEW tras ETL    │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Espacio     │ Mínimo               │ Alto (explosión   │ Medio (solo      │
--  │ disco       │                      │ combinatoria)     │ agregados frec.) │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Detalle     │ Acceso completo      │ Solo lo que se    │ Acceso completo  │
--  │ granular    │ a fact_atenciones     │ pre-calculó       │ via fact_atenc.  │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Simulado    │ GROUP BY CUBE/ROLLUP │ CREATE TABLE AS   │ MATERIALIZED     │
--  │ en PgSQL    │ (ejecutar al vuelo)  │ (pre-calcular)    │ VIEW + queries   │
--  ├─────────────┼──────────────────────┼───────────────────┼──────────────────┤
--  │ Herramienta │ PostgreSQL, MySQL,   │ Essbase, SSAS     │ SSAS Hybrid,     │
--  │ real        │ Hive, BigQuery       │ Multidimensional  │ Oracle OLAP      │
--  └─────────────┴──────────────────────┴───────────────────┴──────────────────┘
--
-- ############################################################################


-- ############################################################################
--  LIMPIEZA (opcional): eliminar objetos MOLAP y HOLAP de prueba
-- ############################################################################
-- Descomentar para limpiar:
--
-- DROP TABLE IF EXISTS molap_cubo_especialidad_sucursal_gestion;
-- DROP TABLE IF EXISTS molap_cubo_temporal;
-- DROP TABLE IF EXISTS molap_cubo_diagnostico_especialidad;
-- DROP MATERIALIZED VIEW IF EXISTS holap_mv_especialidad_sucursal;
-- DROP MATERIALIZED VIEW IF EXISTS holap_mv_mensual_sucursal;
-- ############################################################################
