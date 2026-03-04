-- ============================================================================
-- CONSULTAS DE INTELIGENCIA DE NEGOCIOS — DATA WAREHOUSE (modelo estrella)
-- ============================================================================
-- Conexión: psql -h localhost -p 5434 -U clinica_user -d clinica_db
-- ============================================================================


-- ============================================================================
-- CONSULTA 1: ¿Qué área/especialidad atiende más pacientes?
-- ============================================================================
-- DW: La especialidad ya está desnormalizada en dim_medico (1 JOIN)
-- ============================================================================

SELECT
    dm.especialidad,
    COUNT(*) AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY dm.especialidad
ORDER BY total_atenciones DESC;


-- ============================================================================
-- CONSULTA 2: ¿En qué fechas se atienden más pacientes?
-- ============================================================================
-- DW: fecha_cita ya está en la fact, no necesita JOIN
-- ============================================================================

SELECT
    fecha_cita,
    COUNT(*) AS total_atenciones
FROM fact_atenciones
GROUP BY fecha_cita
ORDER BY total_atenciones DESC;


-- ============================================================================
-- CONSULTA 3: ¿Qué enfermedad/diagnóstico se atiende con más frecuencia?
-- ============================================================================
-- DW: tipo_diagnostico y categoria están desnormalizados en la fact
-- ============================================================================

SELECT
    tipo_diagnostico,
    categoria,
    COUNT(*) AS total
FROM fact_atenciones
GROUP BY tipo_diagnostico, categoria
ORDER BY total DESC;


-- ============================================================================
-- CONSULTA 4: ¿Cuál es la diferencia de clientes externos vs internos por mes?
-- ============================================================================
-- DW: Un paciente "interno" es alguien que también está en dim_medico
-- ============================================================================

SELECT
    fa.anio                                          AS gestion,
    fa.mes,
    COUNT(*) FILTER (WHERE dm_pac.medico_key IS NULL)     AS clientes_externos,
    COUNT(*) FILTER (WHERE dm_pac.medico_key IS NOT NULL) AS clientes_internos,
    COUNT(*) FILTER (WHERE dm_pac.medico_key IS NULL)
      - COUNT(*) FILTER (WHERE dm_pac.medico_key IS NOT NULL) AS diferencia
FROM fact_atenciones fa
JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key
LEFT JOIN dim_medico dm_pac ON dm_pac.ci = dp.ci
GROUP BY fa.anio, fa.mes
ORDER BY fa.anio, fa.mes;


-- ============================================================================
-- CONSULTA 5: ¿Cuántos pacientes se atienden por especialidad y gestión?
-- ============================================================================
-- DW: Solo 1 JOIN a dim_medico (especialidad desnormalizada)
-- ============================================================================

SELECT
    fa.anio                          AS gestion,
    dm.especialidad,
    COUNT(DISTINCT fa.paciente_key)  AS pacientes_atendidos
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY fa.anio, dm.especialidad
ORDER BY fa.anio, pacientes_atendidos DESC;


-- ============================================================================
-- CONSULTA 6: ¿Qué especialidades diagnosticaron una misma enfermedad?
-- ============================================================================
-- DW: Solo 1 JOIN a dim_medico
-- ============================================================================

SELECT
    fa.anio                                                    AS gestion,
    fa.descripcion                                             AS enfermedad,
    COUNT(*)                                                   AS total_diagnosticos,
    COUNT(DISTINCT dm.especialidad)                            AS num_especialidades,
    STRING_AGG(DISTINCT dm.especialidad, ', ' ORDER BY dm.especialidad) AS especialidades
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY fa.anio, fa.descripcion
HAVING COUNT(DISTINCT dm.especialidad) > 1
ORDER BY fa.anio, num_especialidades DESC, total_diagnosticos DESC;


-- ============================================================================
-- CONSULTA 7: ¿Cuántas atenciones aporta cada sucursal/grupo?
-- ============================================================================
-- DW: JOIN dim_paciente → dim_sucursal (snowflake)
-- ============================================================================

SELECT
    ds.nombre        AS sucursal,
    ds.host,
    COUNT(*)         AS total_atenciones
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY ds.nombre, ds.host
ORDER BY total_atenciones DESC;


-- ============================================================================
-- CONSULTA 8: ¿Qué especialidad atiende más pacientes en cada sucursal?
-- ============================================================================
-- DW: Combina dim_medico (especialidad) con dim_sucursal (origen)
-- ============================================================================

SELECT
    ds.nombre        AS sucursal,
    dm.especialidad,
    COUNT(*)         AS total_atenciones
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
JOIN dim_medico dm    ON dm.medico_key = fa.medico_key
GROUP BY ds.nombre, dm.especialidad
ORDER BY ds.nombre, total_atenciones DESC;


-- ============================================================================
-- CONSULTA 9: ¿Cuál es el diagnóstico más frecuente por sucursal?
-- ============================================================================
-- DW: tipo_diagnostico desnormalizado en fact + dim_sucursal via dim_paciente
-- ============================================================================

SELECT
    ds.nombre            AS sucursal,
    fa.tipo_diagnostico,
    fa.categoria,
    COUNT(*)             AS total
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY ds.nombre, fa.tipo_diagnostico, fa.categoria
ORDER BY ds.nombre, total DESC;


-- ============================================================================
-- CONSULTA 10: ¿Cómo se distribuyen las atenciones por mes y sucursal?
-- ============================================================================
-- DW: Comparación temporal entre fuentes de datos
-- ============================================================================

SELECT
    fa.anio              AS gestion,
    fa.mes,
    ds.nombre            AS sucursal,
    COUNT(*)             AS total_atenciones
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY fa.anio, fa.mes, ds.nombre
ORDER BY fa.anio, fa.mes, ds.nombre;


-- ============================================================================
-- CONSULTA 11: ¿Cuántos pacientes únicos tiene cada sucursal?
-- ============================================================================
-- DW: Conteo directo sobre dim_paciente agrupado por sucursal
-- ============================================================================

SELECT
    ds.nombre            AS sucursal,
    COUNT(*)             AS total_pacientes
FROM dim_paciente dp
JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key
GROUP BY ds.nombre
ORDER BY total_pacientes DESC;


-- ============================================================================
-- CONSULTA 12: ¿Cuántos médicos hay por sucursal y especialidad?
-- ============================================================================
-- DW: Cruza dim_medico con dim_sucursal via fact_atenciones
-- ============================================================================

SELECT
    ds.nombre            AS sucursal,
    dm.especialidad,
    COUNT(DISTINCT dm.medico_key) AS total_medicos
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY ds.nombre, dm.especialidad
ORDER BY ds.nombre, total_medicos DESC;


-- ############################################################################
-- CUBOS OLAP — Análisis multidimensional con CUBE, ROLLUP y GROUPING SETS
-- ############################################################################


-- ============================================================================
-- CUBO 1: Atenciones por especialidad, gestión y sucursal (CUBE completo)
-- ============================================================================
-- Genera TODAS las combinaciones posibles de subtotales entre las 3 dimensiones
-- (2^3 = 8 agrupaciones): cada combo + subtotales parciales + gran total
-- ============================================================================

SELECT
    COALESCE(dm.especialidad, '** TODAS **')    AS especialidad,
    COALESCE(fa.anio::TEXT, '** TODOS **')       AS gestion,
    COALESCE(ds.nombre, '** TODAS **')           AS sucursal,
    COUNT(*)                                     AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY CUBE (dm.especialidad, fa.anio, ds.nombre)
ORDER BY
    GROUPING(dm.especialidad), dm.especialidad,
    GROUPING(fa.anio), fa.anio,
    GROUPING(ds.nombre), ds.nombre;


-- ============================================================================
-- CUBO 2: Atenciones por gestión → trimestre → mes (ROLLUP jerárquico)
-- ============================================================================
-- Subtotales jerárquicos: año+trimestre+mes → año+trimestre → año → gran total
-- Ideal para drill-down temporal
-- ============================================================================

SELECT
    COALESCE(fa.anio::TEXT, '** TODOS **')          AS gestion,
    COALESCE(fa.trimestre::TEXT, '** TODOS **')      AS trimestre,
    COALESCE(fa.mes::TEXT, '** TODOS **')            AS mes,
    COUNT(*)                                         AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)                  AS pacientes_unicos
FROM fact_atenciones fa
GROUP BY ROLLUP (fa.anio, fa.trimestre, fa.mes)
ORDER BY
    GROUPING(fa.anio), fa.anio,
    GROUPING(fa.trimestre), fa.trimestre,
    GROUPING(fa.mes), fa.mes;


-- ============================================================================
-- CUBO 3: Diagnósticos por categoría y especialidad (CUBE)
-- ============================================================================
-- Analiza la intersección entre tipo de diagnóstico y especialidad médica
-- con todos los subtotales cruzados
-- ============================================================================

SELECT
    COALESCE(fa.tipo_diagnostico, '** TODOS **')    AS tipo_diagnostico,
    COALESCE(fa.categoria, '** TODAS **')            AS categoria,
    COALESCE(dm.especialidad, '** TODAS **')         AS especialidad,
    COUNT(*)                                         AS total_diagnosticos
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY CUBE (fa.tipo_diagnostico, fa.categoria, dm.especialidad)
ORDER BY
    GROUPING(fa.tipo_diagnostico), fa.tipo_diagnostico,
    GROUPING(fa.categoria), fa.categoria,
    GROUPING(dm.especialidad), dm.especialidad;


-- ============================================================================
-- CUBO 4: Sucursal → especialidad (ROLLUP jerárquico)
-- ============================================================================
-- Drill-down: gran total → por sucursal → por sucursal+especialidad
-- ============================================================================

SELECT
    COALESCE(ds.nombre, '** TODAS **')              AS sucursal,
    COALESCE(dm.especialidad, '** TODAS **')         AS especialidad,
    COUNT(*)                                         AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)                  AS pacientes_unicos,
    COUNT(DISTINCT fa.medico_key)                    AS medicos_involucrados
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY ROLLUP (ds.nombre, dm.especialidad)
ORDER BY
    GROUPING(ds.nombre), ds.nombre,
    GROUPING(dm.especialidad), total_atenciones DESC;


-- ============================================================================
-- CUBO 5: Análisis por día de semana y especialidad (GROUPING SETS selectivo)
-- ============================================================================
-- Solo genera las agrupaciones que nos interesan, no todas las combinaciones
-- ============================================================================

SELECT
    CASE
        WHEN GROUPING(fa.dia_semana) = 1 THEN '** TODOS **'
        ELSE fa.dia_semana
    END                                             AS dia_semana,
    COALESCE(dm.especialidad, '** TODAS **')         AS especialidad,
    COUNT(*)                                         AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY GROUPING SETS (
    (fa.dia_semana, dm.especialidad),   -- detalle completo
    (fa.dia_semana),                    -- subtotal por día
    (dm.especialidad),                  -- subtotal por especialidad
    ()                                  -- gran total
)
ORDER BY
    GROUPING(fa.dia_semana), fa.dia_semana,
    GROUPING(dm.especialidad), total_atenciones DESC;


-- ============================================================================
-- CUBO 6: Pacientes por sexo, ciudad y gestión (CUBE demográfico)
-- ============================================================================
-- Cubo multidimensional sobre características demográficas de los pacientes
-- ============================================================================

SELECT
    COALESCE(dp.sexo, '*')                          AS sexo,
    COALESCE(dp.ciudad, '** TODAS **')               AS ciudad,
    COALESCE(fa.anio::TEXT, '** TODOS **')            AS gestion,
    COUNT(*)                                         AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key)                  AS pacientes_unicos
FROM fact_atenciones fa
JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key
GROUP BY CUBE (dp.sexo, dp.ciudad, fa.anio)
ORDER BY
    GROUPING(dp.sexo), dp.sexo,
    GROUPING(dp.ciudad), dp.ciudad,
    GROUPING(fa.anio), fa.anio;


-- ============================================================================
-- CUBO 7: Gestión → sucursal → categoría diagnóstico (ROLLUP 3 niveles)
-- ============================================================================
-- Drill-down jerárquico de 3 niveles para análisis de diagnósticos por origen
-- ============================================================================

SELECT
    COALESCE(fa.anio::TEXT, '** TODOS **')           AS gestion,
    COALESCE(ds.nombre, '** TODAS **')               AS sucursal,
    COALESCE(fa.categoria, '** TODAS **')             AS categoria,
    COUNT(*)                                         AS total_diagnosticos,
    COUNT(DISTINCT fa.descripcion)                   AS enfermedades_distintas
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY ROLLUP (fa.anio, ds.nombre, fa.categoria)
ORDER BY
    GROUPING(fa.anio), fa.anio,
    GROUPING(ds.nombre), ds.nombre,
    GROUPING(fa.categoria), total_diagnosticos DESC;


-- ############################################################################
-- OPERACIONES OLAP BÁSICAS — Slice, Dice, Drill-Down, Roll-Up, Pivot
-- ############################################################################


-- ============================================================================
-- SLICE (Rebanada) — Fijar UNA dimensión y ver el resto
-- ============================================================================
-- Corta el cubo por un valor específico de una dimensión.
-- Ejemplo: "Solo quiero ver los datos de la especialidad Pediatría"
-- ============================================================================

-- Slice por especialidad = 'Pediatria'
SELECT
    fa.anio            AS gestion,
    fa.mes,
    ds.nombre          AS sucursal,
    COUNT(*)           AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
WHERE dm.especialidad = 'Pediatria'          -- ← SLICE: fija la dimensión
GROUP BY fa.anio, fa.mes, ds.nombre
ORDER BY fa.anio, fa.mes, ds.nombre;

-- Slice por gestión = 2024
SELECT
    dm.especialidad,
    ds.nombre          AS sucursal,
    fa.categoria,
    COUNT(*)           AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
WHERE fa.anio = 2024                         -- ← SLICE: fija la dimensión
GROUP BY dm.especialidad, ds.nombre, fa.categoria
ORDER BY dm.especialidad, ds.nombre, total_atenciones DESC;


-- ============================================================================
-- DICE (Dado) — Fijar DOS o más dimensiones con rangos/conjuntos
-- ============================================================================
-- Recorta un sub-cubo seleccionando valores específicos en varias dimensiones.
-- Ejemplo: "Quiero Pediatría y Cardiología, solo en 2024, solo Grupo 3"
-- ============================================================================

-- Dice: especialidades específicas + gestión específica + sucursal específica
SELECT
    dm.especialidad,
    fa.mes,
    fa.tipo_diagnostico,
    COUNT(*)           AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
WHERE dm.especialidad IN ('Pediatria', 'Cardiologia')  -- ← DICE dim 1
  AND fa.anio = 2024                                    -- ← DICE dim 2
  AND ds.nombre = 'Grupo 3'                              -- ← DICE dim 3
GROUP BY dm.especialidad, fa.mes, fa.tipo_diagnostico
ORDER BY dm.especialidad, fa.mes;

-- Dice: rango temporal + ciudades específicas
SELECT
    dp.ciudad,
    fa.trimestre,
    dm.especialidad,
    COUNT(*)                        AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key) AS pacientes_unicos
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
WHERE fa.mes BETWEEN 1 AND 6                            -- ← DICE dim 1 (rango)
  AND dp.ciudad IN ('La Paz', 'Cochabamba', 'Santa Cruz') -- ← DICE dim 2
GROUP BY dp.ciudad, fa.trimestre, dm.especialidad
ORDER BY dp.ciudad, fa.trimestre;


-- ============================================================================
-- DRILL-DOWN (Desglosar) — Ir de un nivel general a uno más detallado
-- ============================================================================
-- Navegar hacia abajo en la jerarquía: año → trimestre → mes → día
-- Ejemplo: "Veo que 2024 tiene muchas atenciones, quiero ver por trimestre"
-- ============================================================================

-- Nivel 1: Vista general por gestión (nivel más alto)
SELECT
    fa.anio              AS gestion,
    COUNT(*)             AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key) AS pacientes_unicos
FROM fact_atenciones fa
GROUP BY fa.anio
ORDER BY fa.anio;

-- Nivel 2: DRILL-DOWN → de gestión a trimestres de un año específico
SELECT
    fa.anio              AS gestion,
    fa.trimestre,
    COUNT(*)             AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key) AS pacientes_unicos
FROM fact_atenciones fa
WHERE fa.anio = 2024                          -- ← fija el nivel superior
GROUP BY fa.anio, fa.trimestre
ORDER BY fa.trimestre;

-- Nivel 3: DRILL-DOWN → de trimestre a meses
SELECT
    fa.anio              AS gestion,
    fa.trimestre,
    fa.mes,
    COUNT(*)             AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key) AS pacientes_unicos
FROM fact_atenciones fa
WHERE fa.anio = 2024 AND fa.trimestre = 1     -- ← fija niveles superiores
GROUP BY fa.anio, fa.trimestre, fa.mes
ORDER BY fa.mes;

-- Nivel 4: DRILL-DOWN → de mes a días específicos
SELECT
    fa.fecha_cita,
    fa.dia_semana,
    COUNT(*)             AS total_atenciones,
    COUNT(DISTINCT fa.paciente_key) AS pacientes_unicos
FROM fact_atenciones fa
WHERE fa.anio = 2024 AND fa.mes = 3           -- ← fija niveles superiores
GROUP BY fa.fecha_cita, fa.dia_semana
ORDER BY fa.fecha_cita;


-- ============================================================================
-- ROLL-UP (Agregar) — Ir de un nivel detallado a uno más general
-- ============================================================================
-- Navegar hacia arriba: día → mes → trimestre → año (inverso del drill-down)
-- Ejemplo: "Tengo datos por día, quiero resumirlos por mes, luego por año"
-- ============================================================================

-- Nivel detallado: atenciones por fecha exacta (punto de partida)
SELECT
    fa.fecha_cita,
    dm.especialidad,
    COUNT(*)             AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
WHERE fa.anio = 2024 AND fa.mes = 3
GROUP BY fa.fecha_cita, dm.especialidad
ORDER BY fa.fecha_cita, dm.especialidad;

-- ROLL-UP nivel 1: agregar días → mes
SELECT
    fa.anio              AS gestion,
    fa.mes,
    dm.especialidad,
    COUNT(*)             AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
WHERE fa.anio = 2024
GROUP BY fa.anio, fa.mes, dm.especialidad
ORDER BY fa.mes, total_atenciones DESC;

-- ROLL-UP nivel 2: agregar meses → trimestre
SELECT
    fa.anio              AS gestion,
    fa.trimestre,
    dm.especialidad,
    COUNT(*)             AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
WHERE fa.anio = 2024
GROUP BY fa.anio, fa.trimestre, dm.especialidad
ORDER BY fa.trimestre, total_atenciones DESC;

-- ROLL-UP nivel 3: agregar trimestres → año (máxima agregación)
SELECT
    fa.anio              AS gestion,
    dm.especialidad,
    COUNT(*)             AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY fa.anio, dm.especialidad
ORDER BY fa.anio, total_atenciones DESC;


-- ============================================================================
-- PIVOT (Rotación) — Convertir valores de filas en columnas
-- ============================================================================
-- Rota una dimensión para que sus valores se conviertan en columnas.
-- PostgreSQL no tiene PIVOT nativo, se usa FILTER o crosstab.
-- ============================================================================

-- Pivot: atenciones por especialidad (filas) × sucursal (columnas)
SELECT
    dm.especialidad,
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 1') AS "Grupo 1",
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 3') AS "Grupo 3",
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 6') AS "Grupo 6",
    COUNT(*)                                       AS "TOTAL"
FROM fact_atenciones fa
JOIN dim_medico dm    ON dm.medico_key   = fa.medico_key
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY dm.especialidad
ORDER BY "TOTAL" DESC;

-- Pivot: atenciones por trimestre (filas) × sucursal (columnas)
SELECT
    fa.anio                                         AS gestion,
    fa.trimestre,
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 1') AS "Grupo 1",
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 3') AS "Grupo 3",
    COUNT(*) FILTER (WHERE ds.nombre = 'Grupo 6') AS "Grupo 6",
    COUNT(*)                                       AS "TOTAL"
FROM fact_atenciones fa
JOIN dim_paciente dp  ON dp.paciente_key = fa.paciente_key
JOIN dim_sucursal ds  ON ds.sucursal_key = dp.sucursal_key
GROUP BY fa.anio, fa.trimestre
ORDER BY fa.anio, fa.trimestre;

-- Pivot: diagnósticos por categoría (filas) × gestión (columnas)
SELECT
    fa.categoria,
    COUNT(*) FILTER (WHERE fa.anio = 2023) AS "2023",
    COUNT(*) FILTER (WHERE fa.anio = 2024) AS "2024",
    COUNT(*) FILTER (WHERE fa.anio = 2025) AS "2025",
    COUNT(*)                                AS "TOTAL"
FROM fact_atenciones fa
GROUP BY fa.categoria
ORDER BY "TOTAL" DESC;
