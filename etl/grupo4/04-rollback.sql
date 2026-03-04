-- ============================================================================
-- ETL GRUPO 4 - FASE 4: ROLLBACK (REVERSIÓN COMPLETA)
-- ============================================================================
-- Descripción: Revierte TODOS los cambios realizados por el ETL del Grupo 4.
-- Rangos:
--   PERSONA:     700,001-1,000,000 (pac) + 1,000,001-1,300,000 (per) + CI LIKE 'G4-%'
--   CITA_MEDICA: 600,001-900,000
--   DIAGNOSTICO: 600,001-900,000
--
-- Ejecutar:  docker compose exec -T db psql -U clinica_user -d clinica_db < etl/grupo4/04-rollback.sql
--
-- ADVERTENCIA: Esta operación es IRREVERSIBLE. Todos los datos del Grupo 4
--              serán eliminados de la base de datos.
-- ============================================================================

BEGIN;

-- Conteo previo
DO $$
DECLARE
    v_persona_g4 INT; v_cita_g4 INT; v_diag_g4 INT;
BEGIN
    SELECT COUNT(*) INTO v_persona_g4 FROM PERSONA WHERE CI LIKE 'G4-%';
    SELECT COUNT(*) INTO v_cita_g4 FROM CITA_MEDICA WHERE ID_Cita BETWEEN 600001 AND 900000;
    SELECT COUNT(*) INTO v_diag_g4 FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 600001 AND 900000;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'ROLLBACK GRUPO 4 - REGISTROS A ELIMINAR';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA (Grupo 4):     %', v_persona_g4;
    RAISE NOTICE 'CITA_MEDICA (Grupo 4): %', v_cita_g4;
    RAISE NOTICE 'DIAGNOSTICO (Grupo 4): %', v_diag_g4;
    RAISE NOTICE '============================================';
END;
$$;

-- 1. Eliminar DIAGNOSTICO del Grupo 4 (depende de CITA_MEDICA)
DELETE FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 600001 AND 900000;

-- 2. Eliminar CITA_MEDICA del Grupo 4 (depende de PERSONA)
DELETE FROM CITA_MEDICA WHERE ID_Cita BETWEEN 600001 AND 900000;

-- 3. Eliminar HORARIO_MEDICO del Grupo 4 (si existieran)
DELETE FROM HORARIO_MEDICO WHERE ID_Persona IN (
    SELECT ID_Persona FROM PERSONA WHERE CI LIKE 'G4-%'
);

-- 4. Eliminar PERSONA del Grupo 4 (pacientes + personal)
DELETE FROM PERSONA WHERE CI LIKE 'G4-%';

-- 5. Eliminar zona especial del Grupo 4
DELETE FROM ZONA WHERE ID_Zona = 97;

-- 6. Limpiar tablas de transformación
DROP TABLE IF EXISTS tfm_g4_diagnostico CASCADE;
DROP TABLE IF EXISTS tfm_g4_cita_medica CASCADE;
DROP TABLE IF EXISTS tfm_g4_persona_personal CASCADE;
DROP TABLE IF EXISTS tfm_g4_persona_pacientes CASCADE;
DROP TABLE IF EXISTS tfm_g4_mapeo_tipo_diag CASCADE;
DROP TABLE IF EXISTS tfm_g4_mapeo_esp CASCADE;

-- 7. Limpiar tablas de staging
DROP TABLE IF EXISTS stg_g4_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g4_personal CASCADE;
DROP TABLE IF EXISTS stg_g4_pacientes CASCADE;

-- 8. Restaurar secuencias al máximo actual
SELECT setval('persona_id_persona_seq', COALESCE((SELECT MAX(ID_Persona) FROM PERSONA), 1));
SELECT setval('cita_medica_id_cita_seq', COALESCE((SELECT MAX(ID_Cita) FROM CITA_MEDICA), 1));
SELECT setval('diagnostico_id_diagnostico_seq', COALESCE((SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO), 1));

-- Verificación post-rollback
DO $$
DECLARE
    v_persona_total INT; v_persona_g4 INT;
    v_cita_total INT;
    v_diag_total INT;
BEGIN
    SELECT COUNT(*) INTO v_persona_total FROM PERSONA;
    SELECT COUNT(*) INTO v_persona_g4 FROM PERSONA WHERE CI LIKE 'G4-%';
    SELECT COUNT(*) INTO v_cita_total FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_diag_total FROM DIAGNOSTICO;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'ROLLBACK GRUPO 4 - VERIFICACIÓN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total (% del Grupo 4 restantes)', v_persona_total, v_persona_g4;
    RAISE NOTICE 'CITA_MEDICA: % total', v_cita_total;
    RAISE NOTICE 'DIAGNOSTICO: % total', v_diag_total;

    IF v_persona_g4 > 0 THEN
        RAISE WARNING 'ALERTA: Aún quedan % registros del Grupo 4 en PERSONA', v_persona_g4;
    ELSE
        RAISE NOTICE 'OK - Todos los datos del Grupo 4 eliminados correctamente';
    END IF;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;
