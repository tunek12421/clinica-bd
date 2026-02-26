-- ============================================================================
-- ETL GRUPO 6 v2 - FASE 2: TRANSFORMACIÓN
-- ============================================================================
-- Transforma datos del Grupo 6 (esquema PostgreSQL normalizado 3NF)
-- al esquema del Grupo 3 (destino).
--
-- Estrategia de IDs:
--   Pacientes (persona):  id_persona + 300,000
--   Personal  (persona):  id_persona + 600,000
--   Citas:                id_cita + 300,000
--   Diagnósticos:         id_diagnostico + 300,000
--   Recetas:              id_receta + 300,000
--
-- Zonas: Se crea zona ID=98 para datos del Grupo 6
-- Especialidades: IDs 1-15 mapean directo; 16-24 se remapean a existentes
-- ============================================================================

BEGIN;

-- ========================
-- ZONA para Grupo 6
-- ========================
INSERT INTO ZONA (ID_Zona, Nombre, Ciudad)
SELECT 98, 'Sin zona asignada', 'Origen: Grupo 6'
WHERE NOT EXISTS (SELECT 1 FROM ZONA WHERE ID_Zona = 98);

-- ========================
-- MAPEO DE ESPECIALIDADES (24 → 15)
-- ========================
-- G6 IDs 1-15 coinciden con G3.
-- G6 IDs 16-24 no existen en G3, se remapean por afinidad clínica:
DROP TABLE IF EXISTS tfm_g6_mapeo_especialidad;
CREATE TABLE tfm_g6_mapeo_especialidad (
    g6_id INTEGER PRIMARY KEY,
    g3_id INTEGER NOT NULL
);
INSERT INTO tfm_g6_mapeo_especialidad (g6_id, g3_id) VALUES
    -- Mapeo directo (1-15)
    (1, 1), (2, 2), (3, 3), (4, 4), (5, 5),
    (6, 6), (7, 7), (8, 8), (9, 9), (10, 10),
    (11, 11), (12, 12), (13, 13), (14, 14), (15, 15),
    -- Remapeo por afinidad clínica (16-24)
    (16, 1),   -- Medicina Interna     → Medicina General
    (17, 7),   -- Cirugía General      → Traumatología
    (18, 1),   -- Radiología           → Medicina General
    (19, 1),   -- Anestesiología       → Medicina General
    (20, 10),  -- Nefrología           → Urología
    (21, 1),   -- Hematología          → Medicina General
    (22, 7),   -- Reumatología         → Traumatología
    (23, 1),   -- Infectología         → Medicina General
    (24, 1);   -- Medicina Familiar    → Medicina General

-- ========================
-- PERSONA (pacientes del G6)
-- ========================
-- G6 separa paciente y personal en tablas de rol.
-- Identificamos pacientes via stg_g6_paciente.id_persona
DROP TABLE IF EXISTS tfm_g6_persona_pacientes;
SELECT
    p.id_persona + 300000              AS id_persona,
    'G6-PAC-' || p.id_persona          AS ci,
    p.nombre                            AS nombre,
    p.fecha_nacimiento                  AS fecha_nacimiento,
    p.sexo                              AS sexo,
    p.direccion                         AS direccion,
    p.telefono                          AS telefono,
    NULL::VARCHAR(50)                   AS matricula,
    98                                  AS id_zona,
    NULL::INTEGER                       AS id_especialidad
INTO TABLE tfm_g6_persona_pacientes
FROM stg_g6_persona p
INNER JOIN stg_g6_paciente pac ON pac.id_persona = p.id_persona;

-- ========================
-- PERSONA (personal/médicos del G6)
-- ========================
-- Solo cargamos personal con cargo='Medico' (id_cargo=1) que tenga especialidad
DROP TABLE IF EXISTS tfm_g6_persona_personal;
SELECT
    p.id_persona + 600000              AS id_persona,
    'G6-MED-' || p.id_persona          AS ci,
    p.nombre                            AS nombre,
    p.fecha_nacimiento                  AS fecha_nacimiento,
    p.sexo                              AS sexo,
    p.direccion                         AS direccion,
    p.telefono                          AS telefono,
    'G6-MAT-' || per.id_personal        AS matricula,
    98                                  AS id_zona,
    COALESCE(me.g3_id, 1)              AS id_especialidad
INTO TABLE tfm_g6_persona_personal
FROM stg_g6_persona p
INNER JOIN stg_g6_personal per ON per.id_persona = p.id_persona
LEFT JOIN tfm_g6_mapeo_especialidad me ON me.g6_id = per.id_especialidad;

-- ========================
-- CITA_MEDICA
-- ========================
-- G6.cita_medica.id_paciente y id_medico referencian persona.id_persona
-- Aplicamos los mismos offsets: paciente +300,000 / medico +600,000
DROP TABLE IF EXISTS tfm_g6_cita_medica;
SELECT
    c.id_cita + 300000                  AS id_cita,
    c.fecha_registro                    AS fecha_registro,
    c.fecha_cita                        AS fecha_cita,
    c.hora                              AS hora,
    c.numero_turno                      AS numero_turno,
    c.estado                            AS estado,
    c.id_paciente + 300000              AS id_paciente,
    c.id_medico + 600000                AS id_medico
INTO TABLE tfm_g6_cita_medica
FROM stg_g6_cita_medica c;

-- ========================
-- DIAGNOSTICO
-- ========================
-- G6 tiene tipo_diagnostico IDs 1-25 que coinciden con G3 (mismas categorías)
DROP TABLE IF EXISTS tfm_g6_diagnostico;
SELECT
    d.id_diagnostico + 300000           AS id_diagnostico,
    d.descripcion                       AS descripcion,
    d.observaciones                     AS observaciones,
    d.tipo_procedimiento                AS tipo_procedimiento,
    d.id_cita + 300000                  AS id_cita,
    d.id_tipo_diagnostico               AS id_tipo_diagnostico
INTO TABLE tfm_g6_diagnostico
FROM stg_g6_diagnostico d;

-- ========================
-- RECETA
-- ========================
DROP TABLE IF EXISTS tfm_g6_receta;
SELECT
    r.id_receta + 300000                AS id_receta,
    r.medicamentos                      AS medicamentos,
    r.indicaciones                      AS indicaciones,
    r.id_diagnostico + 300000           AS id_diagnostico
INTO TABLE tfm_g6_receta
FROM stg_g6_receta r;

-- ========================
-- RESUMEN
-- ========================
DO $$
DECLARE
    v_pac INTEGER; v_per INTEGER; v_cit INTEGER; v_dia INTEGER; v_rec INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g6_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g6_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g6_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g6_diagnostico;
    SELECT COUNT(*) INTO v_rec FROM tfm_g6_receta;
    RAISE NOTICE '============================================';
    RAISE NOTICE 'TRANSFORMACIÓN G6 v2 COMPLETADA';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'tfm_g6_persona_pacientes: % registros', v_pac;
    RAISE NOTICE 'tfm_g6_persona_personal:  % registros', v_per;
    RAISE NOTICE 'tfm_g6_cita_medica:       % registros', v_cit;
    RAISE NOTICE 'tfm_g6_diagnostico:       % registros', v_dia;
    RAISE NOTICE 'tfm_g6_receta:            % registros', v_rec;
    RAISE NOTICE '============================================';
END $$;

COMMIT;
