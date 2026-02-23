-- ============================================================================
-- ETL GRUPO 6 - FASE 3: CARGA (LOAD)
-- ============================================================================
-- Rangos de IDs:
--   PERSONA:     300,001-600,000 (pacientes) + 600,001-603,000 (personal)
--   CITA_MEDICA: 300,001-500,000
--   DIAGNOSTICO: 300,001-385,390
--   RECETA:      300,001-530,696
-- ============================================================================

BEGIN;

-- Verificación pre-carga
DO $$
DECLARE v_existing INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existing FROM PERSONA WHERE CI LIKE 'G6-%';
    IF v_existing > 0 THEN
        RAISE EXCEPTION 'Ya existen % registros del Grupo 6. Ejecute 04-rollback.sql primero.', v_existing;
    END IF;
END;
$$;

-- Insertar PERSONA (pacientes)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g6_persona_pacientes;

-- Insertar PERSONA (personal)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g6_persona_personal;

-- Insertar CITA_MEDICA
INSERT INTO CITA_MEDICA (ID_Cita, Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
SELECT id_cita, fecha_registro, fecha_cita, hora, numero_turno, estado, id_paciente, id_medico
FROM tfm_g6_cita_medica;

-- Insertar DIAGNOSTICO
INSERT INTO DIAGNOSTICO (ID_Diagnostico, Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
SELECT id_diagnostico, descripcion, observaciones, tipo_procedimiento, id_cita, id_tipo_diagnostico
FROM tfm_g6_diagnostico;

-- Insertar RECETA
INSERT INTO RECETA (ID_Receta, Medicamentos, Indicaciones, ID_Diagnostico)
SELECT id_receta, medicamentos, indicaciones, id_diagnostico
FROM tfm_g6_receta;

-- Actualizar secuencias
SELECT setval('persona_id_persona_seq', (SELECT MAX(ID_Persona) FROM PERSONA));
SELECT setval('cita_medica_id_cita_seq', (SELECT MAX(ID_Cita) FROM CITA_MEDICA));
SELECT setval('diagnostico_id_diagnostico_seq', (SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO));
SELECT setval('receta_id_receta_seq', (SELECT MAX(ID_Receta) FROM RECETA));

-- Verificación post-carga
DO $$
DECLARE
    v_p_total INT; v_p_g6 INT;
    v_c_total INT; v_c_g6 INT;
    v_d_total INT; v_d_g6 INT;
    v_r_total INT; v_r_g6 INT;
BEGIN
    SELECT COUNT(*) INTO v_p_total FROM PERSONA;
    SELECT COUNT(*) INTO v_p_g6 FROM PERSONA WHERE CI LIKE 'G6-%';
    SELECT COUNT(*) INTO v_c_total FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_c_g6 FROM CITA_MEDICA WHERE ID_Cita BETWEEN 300001 AND 600000;
    SELECT COUNT(*) INTO v_d_total FROM DIAGNOSTICO;
    SELECT COUNT(*) INTO v_d_g6 FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 300001 AND 600000;
    SELECT COUNT(*) INTO v_r_total FROM RECETA;
    SELECT COUNT(*) INTO v_r_g6 FROM RECETA WHERE ID_Receta BETWEEN 300001 AND 600000;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA GRUPO 6 COMPLETADA - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total (% del Grupo 6)', v_p_total, v_p_g6;
    RAISE NOTICE 'CITA_MEDICA: % total (% del Grupo 6)', v_c_total, v_c_g6;
    RAISE NOTICE 'DIAGNOSTICO: % total (% del Grupo 6)', v_d_total, v_d_g6;
    RAISE NOTICE 'RECETA:      % total (% del Grupo 6)', v_r_total, v_r_g6;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Para revertir: ejecutar 04-rollback.sql';
END;
$$;

COMMIT;
