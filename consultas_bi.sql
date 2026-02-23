-- ============================================================================
-- CONSULTAS DE INTELIGENCIA DE NEGOCIOS
-- Base de datos consolidada: Grupo 3 + Grupo 1 + Grupo 6
-- ============================================================================

-- ============================================================================
-- CONSULTA 1: Diferencia de cantidad de clientes externos vs internos
--             (personal que trabaja en el recinto), por mes de una gestión
-- ============================================================================
-- Lógica:
--   - Cliente EXTERNO = paciente que NO es personal (PERSONA sin especialidad)
--   - Cliente INTERNO = personal del recinto que también se atiende como paciente
--     (PERSONA con especialidad, es decir, es médico/personal)
-- ============================================================================

SELECT
    EXTRACT(YEAR FROM c.Fecha_Cita)::INT          AS gestion,
    EXTRACT(MONTH FROM c.Fecha_Cita)::INT         AS mes,
    TO_CHAR(c.Fecha_Cita, 'TMMonth')              AS nombre_mes,
    COUNT(*) FILTER (WHERE p.ID_Especialidad IS NULL)     AS clientes_externos,
    COUNT(*) FILTER (WHERE p.ID_Especialidad IS NOT NULL) AS clientes_internos,
    COUNT(*) FILTER (WHERE p.ID_Especialidad IS NULL)
      - COUNT(*) FILTER (WHERE p.ID_Especialidad IS NOT NULL) AS diferencia
FROM CITA_MEDICA c
JOIN PERSONA p ON p.ID_Persona = c.ID_Paciente
GROUP BY gestion, mes, nombre_mes
ORDER BY gestion, mes;


-- ============================================================================
-- CONSULTA 2: Cantidades de pacientes atendidos por especialidad,
--             diferenciados por gestión
-- ============================================================================
-- Lógica:
--   - La especialidad se toma del MÉDICO que atiende la cita
--   - Se cuenta la cantidad de pacientes DISTINTOS atendidos
-- ============================================================================

SELECT
    EXTRACT(YEAR FROM c.Fecha_Cita)::INT  AS gestion,
    e.Nombre                               AS especialidad,
    COUNT(DISTINCT c.ID_Paciente)          AS pacientes_atendidos
FROM CITA_MEDICA c
JOIN PERSONA med ON med.ID_Persona = c.ID_Medico
JOIN ESPECIALIDAD e ON e.ID_Especialidad = med.ID_Especialidad
GROUP BY gestion, e.Nombre
ORDER BY gestion, pacientes_atendidos DESC;


-- ============================================================================
-- CONSULTA 3: Mostrar qué especialidades diagnosticaron una misma enfermedad,
--             por gestión
-- ============================================================================
-- Lógica:
--   - Se agrupa por descripción del diagnóstico (enfermedad) y gestión
--   - Se muestran solo enfermedades diagnosticadas por MÁS DE UNA especialidad
--   - Se lista qué especialidades la diagnosticaron y cuántas veces cada una
-- ============================================================================

SELECT
    EXTRACT(YEAR FROM c.Fecha_Cita)::INT   AS gestion,
    d.Descripcion                           AS enfermedad,
    COUNT(*)                                AS total_diagnosticos,
    COUNT(DISTINCT e.ID_Especialidad)       AS num_especialidades,
    STRING_AGG(DISTINCT e.Nombre, ', ' ORDER BY e.Nombre) AS especialidades
FROM DIAGNOSTICO d
JOIN CITA_MEDICA c ON c.ID_Cita = d.ID_Cita
JOIN PERSONA med ON med.ID_Persona = c.ID_Medico
JOIN ESPECIALIDAD e ON e.ID_Especialidad = med.ID_Especialidad
GROUP BY gestion, d.Descripcion
HAVING COUNT(DISTINCT e.ID_Especialidad) > 1
ORDER BY gestion, num_especialidades DESC, total_diagnosticos DESC;
