-- ============================================================================
-- ETL GRUPO 4 - FASE 3: CARGA (LOAD)
-- ============================================================================
-- Rangos de IDs:
--   PERSONA:     700,001-1,000,000 (pacientes) + 1,000,001-1,300,000 (personal)
--   CITA_MEDICA: 600,001-900,000
--   DIAGNOSTICO: 600,001-900,000
-- ============================================================================

BEGIN;

-- Verificación pre-carga
DO $$
DECLARE v_existing INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existing FROM PERSONA WHERE CI LIKE 'G4-%';
    IF v_existing > 0 THEN
        RAISE EXCEPTION 'Ya existen % registros del Grupo 4. Ejecute 04-rollback.sql primero.', v_existing;
    END IF;
END;
$$;

-- Insertar PERSONA (pacientes)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g4_persona_pacientes;

-- Insertar PERSONA (personal)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g4_persona_personal;

-- Insertar CITA_MEDICA
INSERT INTO CITA_MEDICA (ID_Cita, Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
SELECT id_cita, fecha_registro, fecha_cita, hora, numero_turno, estado, id_paciente, id_medico
FROM tfm_g4_cita_medica
WHERE id_paciente IS NOT NULL;

-- Insertar DIAGNOSTICO
INSERT INTO DIAGNOSTICO (ID_Diagnostico, Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
SELECT d.id_diagnostico, d.descripcion, d.observaciones, d.tipo_procedimiento, d.id_cita, d.id_tipo_diagnostico
FROM tfm_g4_diagnostico d
WHERE EXISTS (SELECT 1 FROM CITA_MEDICA c WHERE c.ID_Cita = d.id_cita);

-- Actualizar secuencias
SELECT setval('persona_id_persona_seq', (SELECT MAX(ID_Persona) FROM PERSONA));
SELECT setval('cita_medica_id_cita_seq', (SELECT MAX(ID_Cita) FROM CITA_MEDICA));
SELECT setval('diagnostico_id_diagnostico_seq', (SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO));

-- Verificación post-carga
DO $$
DECLARE
    v_p_total INT; v_p_g4 INT;
    v_c_total INT; v_c_g4 INT;
    v_d_total INT; v_d_g4 INT;
BEGIN
    SELECT COUNT(*) INTO v_p_total FROM PERSONA;
    SELECT COUNT(*) INTO v_p_g4 FROM PERSONA WHERE CI LIKE 'G4-%';
    SELECT COUNT(*) INTO v_c_total FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_c_g4 FROM CITA_MEDICA WHERE ID_Cita BETWEEN 600001 AND 900000;
    SELECT COUNT(*) INTO v_d_total FROM DIAGNOSTICO;
    SELECT COUNT(*) INTO v_d_g4 FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 600001 AND 900000;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA GRUPO 4 COMPLETADA - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total (% del Grupo 4)', v_p_total, v_p_g4;
    RAISE NOTICE 'CITA_MEDICA: % total (% del Grupo 4)', v_c_total, v_c_g4;
    RAISE NOTICE 'DIAGNOSTICO: % total (% del Grupo 4)', v_d_total, v_d_g4;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Para revertir: ejecutar 04-rollback.sql';
END;
$$;

COMMIT;
