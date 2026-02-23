-- ============================================================================
-- ETL GRUPO 1 - FASE 4: ROLLBACK (REVERSIÓN COMPLETA)
-- ============================================================================
-- Descripción: Revierte TODOS los cambios realizados por el ETL del Grupo 1.
--              Elimina datos cargados, tablas transformadas y tablas staging.
--              Deja la BD en el estado exacto previo a la ejecución del ETL.
--
-- Ejecutar:  docker compose exec db psql -U clinica_user -d clinica_db -f /etl/grupo1/04-rollback.sql
--
-- ADVERTENCIA: Esta operación es IRREVERSIBLE. Todos los datos del Grupo 1
--              serán eliminados permanentemente de las tablas de producción.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Conteo pre-rollback (para verificación)
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_persona_g1 INTEGER;
    v_cita_g1 INTEGER;
    v_diag_g1 INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_persona_g1 FROM PERSONA WHERE CI LIKE 'G1-%';
    SELECT COUNT(*) INTO v_cita_g1 FROM CITA_MEDICA WHERE ID_Cita BETWEEN 100001 AND 250000;
    SELECT COUNT(*) INTO v_diag_g1 FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 100001 AND 250000;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'ROLLBACK - REGISTROS A ELIMINAR';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA (Grupo 1):     %', v_persona_g1;
    RAISE NOTICE 'CITA_MEDICA (Grupo 1): %', v_cita_g1;
    RAISE NOTICE 'DIAGNOSTICO (Grupo 1): %', v_diag_g1;
    RAISE NOTICE '============================================';
END;
$$;

-- ----------------------------------------------------------------------------
-- PASO 2: Eliminar datos de producción (orden inverso por FKs)
-- ----------------------------------------------------------------------------

-- 2a. Eliminar DIAGNOSTICO del Grupo 1 (depende de CITA_MEDICA)
DELETE FROM DIAGNOSTICO
WHERE ID_Diagnostico BETWEEN 100001 AND 250000;

-- 2b. Eliminar RECETAS asociadas a diagnósticos del Grupo 1 (si existieran)
-- No se crearon recetas en el ETL, pero por seguridad:
DELETE FROM RECETA
WHERE ID_Diagnostico BETWEEN 100001 AND 250000;

-- 2c. Eliminar CITA_MEDICA del Grupo 1 (depende de PERSONA)
DELETE FROM CITA_MEDICA
WHERE ID_Cita BETWEEN 100001 AND 250000;

-- 2d. Eliminar HORARIO_MEDICO del Grupo 1 (si existieran)
DELETE FROM HORARIO_MEDICO
WHERE ID_Persona BETWEEN 100001 AND 250000;

-- 2e. Eliminar PERSONA del Grupo 1 (pacientes + personal)
DELETE FROM PERSONA
WHERE CI LIKE 'G1-%';

-- 2f. Eliminar zona especial del Grupo 1
DELETE FROM ZONA WHERE ID_Zona = 99;

-- ----------------------------------------------------------------------------
-- PASO 3: Eliminar tablas de transformación
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g1_diagnostico CASCADE;
DROP TABLE IF EXISTS tfm_g1_cita_medica CASCADE;
DROP TABLE IF EXISTS tfm_g1_persona_personal CASCADE;
DROP TABLE IF EXISTS tfm_g1_persona_pacientes CASCADE;
DROP TABLE IF EXISTS tfm_g1_mapeo_cie10 CASCADE;

-- ----------------------------------------------------------------------------
-- PASO 4: Eliminar tablas staging
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_g1_diagnosticos CASCADE;
DROP TABLE IF EXISTS stg_g1_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g1_personal CASCADE;
DROP TABLE IF EXISTS stg_g1_pacientes CASCADE;

-- ----------------------------------------------------------------------------
-- PASO 5: Restaurar secuencias a valores originales
-- ----------------------------------------------------------------------------
-- Los valores originales corresponden al MAX(id) de nuestros datos propios

SELECT setval('persona_id_persona_seq',
    COALESCE((SELECT MAX(ID_Persona) FROM PERSONA), 1));

SELECT setval('cita_medica_id_cita_seq',
    COALESCE((SELECT MAX(ID_Cita) FROM CITA_MEDICA), 1));

SELECT setval('diagnostico_id_diagnostico_seq',
    COALESCE((SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO), 1));

-- ----------------------------------------------------------------------------
-- PASO 6: Verificación post-rollback
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_persona_total INTEGER;
    v_persona_g1 INTEGER;
    v_cita_total INTEGER;
    v_diag_total INTEGER;
    v_stg_exist BOOLEAN;
    v_tfm_exist BOOLEAN;
BEGIN
    SELECT COUNT(*) INTO v_persona_total FROM PERSONA;
    SELECT COUNT(*) INTO v_persona_g1 FROM PERSONA WHERE CI LIKE 'G1-%';
    SELECT COUNT(*) INTO v_cita_total FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_diag_total FROM DIAGNOSTICO;

    -- Verificar que no quedan tablas auxiliares
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name LIKE 'stg_g1_%'
    ) INTO v_stg_exist;

    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name LIKE 'tfm_g1_%'
    ) INTO v_tfm_exist;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'ROLLBACK COMPLETADO - VERIFICACIÓN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total (% del Grupo 1 restantes)', v_persona_total, v_persona_g1;
    RAISE NOTICE 'CITA_MEDICA: % total', v_cita_total;
    RAISE NOTICE 'DIAGNOSTICO: % total', v_diag_total;
    RAISE NOTICE 'Tablas staging restantes:  %', v_stg_exist;
    RAISE NOTICE 'Tablas transform restantes: %', v_tfm_exist;
    RAISE NOTICE '============================================';

    IF v_persona_g1 > 0 THEN
        RAISE WARNING 'ALERTA: Aún quedan % registros del Grupo 1 en PERSONA', v_persona_g1;
    END IF;
    IF v_stg_exist THEN
        RAISE WARNING 'ALERTA: Aún existen tablas staging (stg_g1_*)';
    END IF;
    IF v_tfm_exist THEN
        RAISE WARNING 'ALERTA: Aún existen tablas de transformación (tfm_g1_*)';
    END IF;

    IF v_persona_g1 = 0 AND NOT v_stg_exist AND NOT v_tfm_exist THEN
        RAISE NOTICE 'Estado: LIMPIO - BD restaurada al estado original';
    END IF;
END;
$$;

COMMIT;
