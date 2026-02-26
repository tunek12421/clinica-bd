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
