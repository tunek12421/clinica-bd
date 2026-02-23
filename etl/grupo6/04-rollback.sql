-- ============================================================================
-- ETL GRUPO 6 - FASE 4: ROLLBACK
-- ============================================================================

BEGIN;

DO $$
DECLARE v_p INT; v_c INT; v_d INT; v_r INT;
BEGIN
    SELECT COUNT(*) INTO v_p FROM PERSONA WHERE CI LIKE 'G6-%';
    SELECT COUNT(*) INTO v_c FROM CITA_MEDICA WHERE ID_Cita BETWEEN 300001 AND 600000;
    SELECT COUNT(*) INTO v_d FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 300001 AND 600000;
    SELECT COUNT(*) INTO v_r FROM RECETA WHERE ID_Receta BETWEEN 300001 AND 600000;
    RAISE NOTICE 'ROLLBACK G6: % personas, % citas, % diagnósticos, % recetas a eliminar', v_p, v_c, v_d, v_r;
END;
$$;

-- Eliminar datos de producción (orden inverso por FKs)
DELETE FROM RECETA WHERE ID_Receta BETWEEN 300001 AND 600000;
DELETE FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 300001 AND 600000;
DELETE FROM CITA_MEDICA WHERE ID_Cita BETWEEN 300001 AND 600000;
DELETE FROM HORARIO_MEDICO WHERE ID_Persona BETWEEN 300001 AND 700000;
DELETE FROM PERSONA WHERE CI LIKE 'G6-%';
DELETE FROM ZONA WHERE ID_Zona = 98;

-- Eliminar tablas de transformación
DROP TABLE IF EXISTS tfm_g6_receta CASCADE;
DROP TABLE IF EXISTS tfm_g6_diagnostico CASCADE;
DROP TABLE IF EXISTS tfm_g6_cita_medica CASCADE;
DROP TABLE IF EXISTS tfm_g6_persona_personal CASCADE;
DROP TABLE IF EXISTS tfm_g6_persona_pacientes CASCADE;
DROP TABLE IF EXISTS tfm_g6_mapeo_tipo_diag CASCADE;
DROP TABLE IF EXISTS tfm_g6_mapeo_esp CASCADE;

-- Eliminar tablas staging
DROP TABLE IF EXISTS stg_g6_recetas CASCADE;
DROP TABLE IF EXISTS stg_g6_diagnosticos CASCADE;
DROP TABLE IF EXISTS stg_g6_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g6_historias CASCADE;
DROP TABLE IF EXISTS stg_g6_citas CASCADE;
DROP TABLE IF EXISTS stg_g6_personal CASCADE;
DROP TABLE IF EXISTS stg_g6_especialidades CASCADE;
DROP TABLE IF EXISTS stg_g6_pacientes CASCADE;

-- Restaurar secuencias
SELECT setval('persona_id_persona_seq', COALESCE((SELECT MAX(ID_Persona) FROM PERSONA), 1));
SELECT setval('cita_medica_id_cita_seq', COALESCE((SELECT MAX(ID_Cita) FROM CITA_MEDICA), 1));
SELECT setval('diagnostico_id_diagnostico_seq', COALESCE((SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO), 1));
SELECT setval('receta_id_receta_seq', COALESCE((SELECT MAX(ID_Receta) FROM RECETA), 1));

DO $$
DECLARE v_p INT;
BEGIN
    SELECT COUNT(*) INTO v_p FROM PERSONA WHERE CI LIKE 'G6-%';
    IF v_p = 0 THEN
        RAISE NOTICE 'ROLLBACK GRUPO 6 COMPLETADO - BD restaurada';
    ELSE
        RAISE WARNING 'Aún quedan % registros del Grupo 6', v_p;
    END IF;
END;
$$;

COMMIT;
