-- ============================================================================
-- ETL GRUPO 6 v2 - FASE 4: ROLLBACK
-- ============================================================================
-- Revierte todos los cambios realizados por el ETL del Grupo 6 v2.
-- Elimina datos por rango de IDs y limpia tablas staging.
-- ============================================================================

BEGIN;

-- Eliminar datos de producción (orden por dependencias FK)
DELETE FROM RECETA WHERE ID_Receta >= 300001;
DELETE FROM DIAGNOSTICO WHERE ID_Diagnostico >= 300001;
DELETE FROM CITA_MEDICA WHERE ID_Cita >= 300001;
DELETE FROM PERSONA WHERE ID_Persona >= 300001 AND ID_Persona < 400000;  -- pacientes G6
DELETE FROM PERSONA WHERE ID_Persona >= 600001 AND ID_Persona < 700000;  -- personal G6

-- Eliminar zona G6
DELETE FROM ZONA WHERE ID_Zona = 98;

-- Limpiar tablas de transformación
DROP TABLE IF EXISTS tfm_g6_receta CASCADE;
DROP TABLE IF EXISTS tfm_g6_diagnostico CASCADE;
DROP TABLE IF EXISTS tfm_g6_cita_medica CASCADE;
DROP TABLE IF EXISTS tfm_g6_persona_personal CASCADE;
DROP TABLE IF EXISTS tfm_g6_persona_pacientes CASCADE;
DROP TABLE IF EXISTS tfm_g6_mapeo_especialidad CASCADE;

-- Limpiar tablas staging
DROP TABLE IF EXISTS stg_g6_receta CASCADE;
DROP TABLE IF EXISTS stg_g6_diagnostico CASCADE;
DROP TABLE IF EXISTS stg_g6_cita_medica CASCADE;
DROP TABLE IF EXISTS stg_g6_personal CASCADE;
DROP TABLE IF EXISTS stg_g6_paciente CASCADE;
DROP TABLE IF EXISTS stg_g6_persona CASCADE;
DROP TABLE IF EXISTS stg_g6_tipo_diagnostico CASCADE;
DROP TABLE IF EXISTS stg_g6_especialidad CASCADE;
DROP TABLE IF EXISTS stg_g6_zona CASCADE;

-- Restaurar secuencias (post G1, sin G6)
SELECT setval('persona_id_persona_seq', (SELECT COALESCE(MAX(ID_Persona), 1) FROM PERSONA));
SELECT setval('cita_medica_id_cita_seq', (SELECT COALESCE(MAX(ID_Cita), 1) FROM CITA_MEDICA));
SELECT setval('diagnostico_id_diagnostico_seq', (SELECT COALESCE(MAX(ID_Diagnostico), 1) FROM DIAGNOSTICO));
SELECT setval('receta_id_receta_seq', (SELECT COALESCE(MAX(ID_Receta), 1) FROM RECETA));

DO $$
BEGIN
    RAISE NOTICE 'ROLLBACK G6 v2 completado.';
END $$;

COMMIT;
