-- ============================================================================
-- ETL GRUPO 1 - FASE 3: CARGA (LOAD)
-- ============================================================================
-- Descripción: Inserta los datos transformados en las tablas de producción
--              de nuestra base de datos clínica.
--
-- Prerequisito: Haber ejecutado 01-extract.sql y 02-transform.sql exitosamente.
--
-- Ejecutar:  docker compose exec db psql -U clinica_user -d clinica_db -f /etl/grupo1/03-load.sql
--
-- Registros a insertar:
--   PERSONA     ← 100,000 (50,000 pacientes + 50,000 personal)
--   CITA_MEDICA ← 50,000  (atenciones)
--   DIAGNOSTICO ← 68,123  (diagnósticos)
--   TOTAL:        218,123 registros nuevos
--
-- Rangos de IDs (para identificación y rollback):
--   PERSONA:     100,001 - 150,000 (pacientes) + 200,001 - 250,000 (personal)
--   CITA_MEDICA: 100,001 - 150,000
--   DIAGNOSTICO: 100,001 - 168,123
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Verificación pre-carga
-- ----------------------------------------------------------------------------
-- Comprobar que las tablas transformadas existen y tienen datos

DO $$
DECLARE
    v_pac INTEGER;
    v_per INTEGER;
    v_cit INTEGER;
    v_dia INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g1_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g1_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g1_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g1_diagnostico;

    IF v_pac = 0 OR v_per = 0 OR v_cit = 0 OR v_dia = 0 THEN
        RAISE EXCEPTION 'ERROR: Tablas transformadas vacías. Ejecute 02-transform.sql primero.';
    END IF;

    RAISE NOTICE 'Pre-carga OK: % pacientes, % personal, % citas, % diagnósticos',
        v_pac, v_per, v_cit, v_dia;
END;
$$;

-- ----------------------------------------------------------------------------
-- PASO 2: Verificar que no existan datos previos del Grupo 1
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_existing INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_existing
    FROM PERSONA WHERE CI LIKE 'G1-%';

    IF v_existing > 0 THEN
        RAISE EXCEPTION 'ERROR: Ya existen % registros del Grupo 1 en PERSONA. Ejecute 04-rollback.sql primero.', v_existing;
    END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- PASO 3: Insertar PERSONA (pacientes del Grupo 1)
-- ----------------------------------------------------------------------------
-- Rango IDs: 100,001 - 150,000
-- Origen: tfm_g1_persona_pacientes

INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT
    id_persona,
    ci,
    nombre,
    fecha_nacimiento,
    sexo,
    direccion,
    telefono,
    matricula,
    id_zona,
    id_especialidad
FROM tfm_g1_persona_pacientes;

-- ----------------------------------------------------------------------------
-- PASO 4: Insertar PERSONA (personal del Grupo 1)
-- ----------------------------------------------------------------------------
-- Rango IDs: 200,001 - 250,000
-- Origen: tfm_g1_persona_personal

INSERT INTO PERSONA (ID_Persona, CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
SELECT
    id_persona,
    ci,
    nombre,
    fecha_nacimiento,
    sexo,
    direccion,
    telefono,
    matricula,
    id_zona,
    id_especialidad
FROM tfm_g1_persona_personal;

-- ----------------------------------------------------------------------------
-- PASO 5: Insertar CITA_MEDICA (atenciones del Grupo 1)
-- ----------------------------------------------------------------------------
-- Rango IDs: 100,001 - 150,000
-- Origen: tfm_g1_cita_medica

INSERT INTO CITA_MEDICA (ID_Cita, Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
SELECT
    id_cita,
    fecha_registro,
    fecha_cita,
    hora,
    numero_turno,
    estado,
    id_paciente,
    id_medico
FROM tfm_g1_cita_medica;

-- ----------------------------------------------------------------------------
-- PASO 6: Insertar DIAGNOSTICO (diagnósticos del Grupo 1)
-- ----------------------------------------------------------------------------
-- Rango IDs: 100,001 - 168,123
-- Origen: tfm_g1_diagnostico

INSERT INTO DIAGNOSTICO (ID_Diagnostico, Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
SELECT
    id_diagnostico,
    descripcion,
    observaciones,
    tipo_procedimiento,
    id_cita,
    id_tipo_diagnostico
FROM tfm_g1_diagnostico;

-- ----------------------------------------------------------------------------
-- PASO 7: Actualizar secuencias (SERIAL) para futuros INSERT sin ID explícito
-- ----------------------------------------------------------------------------
-- Las secuencias deben apuntar al MAX(id) + 1 para evitar conflictos

SELECT setval('persona_id_persona_seq',
    (SELECT MAX(ID_Persona) FROM PERSONA));

SELECT setval('cita_medica_id_cita_seq',
    (SELECT MAX(ID_Cita) FROM CITA_MEDICA));

SELECT setval('diagnostico_id_diagnostico_seq',
    (SELECT MAX(ID_Diagnostico) FROM DIAGNOSTICO));

-- ----------------------------------------------------------------------------
-- PASO 8: Verificación post-carga
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    v_persona_total INTEGER;
    v_persona_g1 INTEGER;
    v_cita_total INTEGER;
    v_cita_g1 INTEGER;
    v_diag_total INTEGER;
    v_diag_g1 INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_persona_total FROM PERSONA;
    SELECT COUNT(*) INTO v_persona_g1 FROM PERSONA WHERE CI LIKE 'G1-%';
    SELECT COUNT(*) INTO v_cita_total FROM CITA_MEDICA;
    SELECT COUNT(*) INTO v_cita_g1 FROM CITA_MEDICA WHERE ID_Cita BETWEEN 100001 AND 250000;
    SELECT COUNT(*) INTO v_diag_total FROM DIAGNOSTICO;
    SELECT COUNT(*) INTO v_diag_g1 FROM DIAGNOSTICO WHERE ID_Diagnostico BETWEEN 100001 AND 250000;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'CARGA COMPLETADA - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'PERSONA:     % total (% del Grupo 1)', v_persona_total, v_persona_g1;
    RAISE NOTICE 'CITA_MEDICA: % total (% del Grupo 1)', v_cita_total, v_cita_g1;
    RAISE NOTICE 'DIAGNOSTICO: % total (% del Grupo 1)', v_diag_total, v_diag_g1;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Para revertir: ejecutar 04-rollback.sql';
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;

-- ============================================================================
-- CONSULTAS DE VERIFICACIÓN (ejecutar manualmente)
-- ============================================================================
-- Contar registros por origen:
-- SELECT
--     CASE WHEN CI LIKE 'G1-PAC-%' THEN 'Grupo 1 (Pacientes)'
--          WHEN CI LIKE 'G1-PER-%' THEN 'Grupo 1 (Personal)'
--          ELSE 'Propios' END AS origen,
--     COUNT(*) AS total
-- FROM PERSONA GROUP BY 1;
--
-- Verificar integridad referencial:
-- SELECT COUNT(*) FROM CITA_MEDICA c
-- WHERE NOT EXISTS (SELECT 1 FROM PERSONA p WHERE p.ID_Persona = c.ID_Paciente);
--
-- SELECT COUNT(*) FROM CITA_MEDICA c
-- WHERE NOT EXISTS (SELECT 1 FROM PERSONA p WHERE p.ID_Persona = c.ID_Medico);
--
-- SELECT COUNT(*) FROM DIAGNOSTICO d
-- WHERE NOT EXISTS (SELECT 1 FROM CITA_MEDICA c WHERE c.ID_Cita = d.ID_Cita);
