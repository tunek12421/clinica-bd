-- ============================================================================
-- CONSULTAS DE INTELIGENCIA DE NEGOCIOS — DATA WAREHOUSE (modelo estrella)
-- ============================================================================
-- Conexión: psql -h localhost -p 5434 -U dw_user -d dw_clinica
-- ============================================================================


-- ============================================================================
-- CONSULTA 1: Qué área atiende más pacientes
-- ============================================================================
-- Original: JOIN CITA_MEDICA → PERSONA → ESPECIALIDAD (3 tablas)
-- DW:       La especialidad ya está desnormalizada en dim_medico
-- ============================================================================

SELECT
    dm.especialidad,
    COUNT(*) AS total_atenciones
FROM fact_atenciones fa
JOIN dim_medico dm ON dm.medico_key = fa.medico_key
GROUP BY dm.especialidad
ORDER BY total_atenciones DESC;


-- ============================================================================
-- CONSULTA 2: Qué fechas se atienden más pacientes
-- ============================================================================
-- Original: GROUP BY Fecha_Cita sobre CITA_MEDICA
-- DW:       fecha_cita ya está en la fact, no necesita JOIN
-- ============================================================================

SELECT
    fecha_cita,
    COUNT(*) AS total_atenciones
FROM fact_atenciones
GROUP BY fecha_cita
ORDER BY total_atenciones DESC;


-- ============================================================================
-- CONSULTA 3: Qué enfermedad se atiende más
-- ============================================================================
-- Original: JOIN DIAGNOSTICO → TIPO_DIAGNOSTICO (2 tablas)
-- DW:       tipo_diagnostico y categoria están desnormalizados en la fact
-- ============================================================================

SELECT
    tipo_diagnostico,
    categoria,
    COUNT(*) AS total
FROM fact_atenciones
GROUP BY tipo_diagnostico, categoria
ORDER BY total DESC;


-- ============================================================================
-- CONSULTA 4: Diferencia de clientes externos vs internos por mes
-- ============================================================================
-- Original: JOIN CITA_MEDICA → PERSONA, filtrando por ID_Especialidad
-- DW:       Un paciente "interno" es alguien que también está en dim_medico
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
-- CONSULTA 5: Pacientes atendidos por especialidad, por gestión
-- ============================================================================
-- Original: JOIN CITA_MEDICA → PERSONA → ESPECIALIDAD (3 tablas)
-- DW:       Solo 1 JOIN a dim_medico (especialidad desnormalizada)
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
-- CONSULTA 6: Especialidades que diagnosticaron una misma enfermedad, por gestión
-- ============================================================================
-- Original: JOIN DIAGNOSTICO → CITA_MEDICA → PERSONA → ESPECIALIDAD (4 tablas)
-- DW:       Solo 1 JOIN a dim_medico
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
