-- ============================================================================
-- ETL GRUPO 6 v2 - FASE 3: CARGA
-- ============================================================================
-- Inserta datos transformados del Grupo 6 en las tablas de producción.
--
-- Rangos de IDs:
--   PERSONA (pacientes): 300,001 - 334,500
--   PERSONA (personal):  600,001 - 600,831
--   CITA_MEDICA:         300,001 - 370,000
--   DIAGNOSTICO:         300,001 - 340,134
--   RECETA:              300,001 - 340,134
-- ============================================================================

BEGIN;

-- Verificación pre-carga
DO $$
DECLARE
    v_pac INTEGER; v_per INTEGER; v_cit INTEGER; v_dia INTEGER; v_rec INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g6_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g6_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g6_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g6_diagnostico;
    SELECT COUNT(*) INTO v_rec FROM tfm_g6_receta;
    RAISE NOTICE 'Pre-carga: % pacientes, % personal, % citas, % diagnosticos, % recetas',
        v_pac, v_per, v_cit, v_dia, v_rec;
END $$;

-- PERSONA (pacientes)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g6_persona_pacientes;

-- PERSONA (personal)
INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT id_persona, ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad
FROM tfm_g6_persona_personal;

-- CITA_MEDICA
INSERT INTO CITA_MEDICA (ID_Cita, Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
SELECT id_cita, fecha_registro, fecha_cita, hora, numero_turno, estado, id_paciente, id_medico
FROM tfm_g6_cita_medica;

-- DIAGNOSTICO
INSERT INTO DIAGNOSTICO (ID_Diagnostico, Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
SELECT id_diagnostico, descripcion, observaciones, tipo_procedimiento, id_cita, id_tipo_diagnostico
FROM tfm_g6_diagnostico;

-- RECETA
INSERT INTO RECETA (ID_Receta, Medicamentos, Indicaciones, ID_Diagnostico)
SELECT id_receta, medicamentos, indicaciones, id_diagnostico
FROM tfm_g6_receta;

-- Actualizar secuencias para evitar conflictos futuros
SELECT setval('persona_id_persona_seq', (SELECT MAX(ID_Persona) FROM PERSONA));
SELECT setval('cita_medica_id_cita_seq', (SELECT MAX(ID_Cita) FROM CITA_MEDICA));
SELECT setval('diagnostico_id_diagnostico_seq', (SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO));
SELECT setval('receta_id_receta_seq', (SELECT MAX(ID_Receta) FROM RECETA));

-- Resumen post-carga
DO $$
DECLARE
    v_per INTEGER; v_cit INTEGER; v_dia INTEGER; v_rec INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_per FROM PERSONA;
    SELECT COUNT(*) INTO v_cit FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_dia FROM DIAGNOSTICO;
    SELECT COUNT(*) INTO v_rec FROM RECETA;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA G6 v2 COMPLETADA';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total', v_per;
    RAISE NOTICE 'CITA_MEDICA: % total', v_cit;
    RAISE NOTICE 'DIAGNOSTICO: % total', v_dia;
    RAISE NOTICE 'RECETA:      % total', v_rec;
    RAISE NOTICE '============================================';
END $$;

COMMIT;
