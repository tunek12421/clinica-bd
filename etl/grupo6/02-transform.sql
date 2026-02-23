-- ============================================================================
-- ETL GRUPO 6 - FASE 2: TRANSFORMACIÓN
-- ============================================================================
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO DE TABLAS: GRUPO 6 → NUESTRO ESQUEMA                             │
-- ├──────────────────────┬───────────────────────────────────────────────────┤
-- │ ORIGEN (Grupo 6)     │ DESTINO (Grupo 3)                               │
-- ├──────────────────────┼───────────────────────────────────────────────────┤
-- │ Paciente             │ PERSONA (como pacientes)                        │
-- │ Personal             │ PERSONA (como staff/médicos)                    │
-- │ Cita                 │ CITA_MEDICA                                     │
-- │ Diagnostico          │ DIAGNOSTICO                                     │
-- │ Receta               │ RECETA                                          │
-- │ Especialidad         │ (mapeo a ESPECIALIDAD existente)                │
-- │ Historia_Clinica     │ (no tiene equivalente directo)                  │
-- │ Atencion_Medica      │ (datos usados para enriquecer CITA)            │
-- │ Signos_Vitales       │ (no extraído - sin equivalente)                │
-- └──────────────────────┴───────────────────────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ ESTRATEGIA DE IDs (OFFSET) — Grupo 6 usa rangos 300,000+               │
-- ├──────────────────────┬──────────────────────┬───────────────────────────-┤
-- │ Entidad              │ Rango IDs            │ Offset aplicado            │
-- ├──────────────────────┼──────────────────────┼────────────────────────────┤
-- │ Pacientes → PERSONA  │ 300,001 - 600,000    │ +300,000                  │
-- │ Personal  → PERSONA  │ 600,001 - 603,000    │ +600,000                  │
-- │ Citas → CITA_MEDICA  │ 300,001 - 500,000    │ +300,000                  │
-- │ Diagnóst.→ DIAGNOST  │ 300,001 - 385,390    │ +300,000                  │
-- │ Recetas → RECETA     │ 300,001 - 530,696    │ +300,000                  │
-- └──────────────────────┴──────────────────────┴────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CAMPOS FALTANTES Y DECISIONES                                           │
-- ├────────────────────┬──────────────────┬──────────────────────────────────┤
-- │ Campo destino      │ ¿Disponible?     │ Estrategia                      │
-- ├────────────────────┼──────────────────┼──────────────────────────────────┤
-- │ PERSONA.CI         │ NO               │ 'G6-PAC-{id}' / 'G6-PER-{id}'  │
-- │ PERSONA.Nombre     │ nombres+apellidos│ Concatenar con espacio          │
-- │ PERSONA.Sexo       │ NO               │ 'X' (no disponible)            │
-- │ PERSONA.Direccion  │ Sí (pacientes)   │ Directo / 'Sin dato' (personal)│
-- │ PERSONA.Telefono   │ Sí (pacientes)   │ Directo / 'Sin dato' (personal)│
-- │ PERSONA.ID_Zona    │ NO               │ Zona especial ID=98            │
-- │ PERSONA.Fecha_Nac  │ Sí (pacientes)   │ Personal: '1900-01-01'         │
-- │ CITA.Numero_Turno  │ NO               │ ROW_NUMBER() por día+médico    │
-- │ DIAG.Observaciones │ NO (directo)     │ 'CIE-10: {cod} | Tipo: {tipo}' │
-- │ DIAG.ID_Tipo_Diag  │ tipo (texto)     │ Mapeo tipo → ID                │
-- └────────────────────┴──────────────────┴──────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO ESPECIALIDADES GRUPO 6 → NUESTRAS (15)                           │
-- │ De las 24 del G6, 11 coinciden. Las 13 restantes → más cercana.        │
-- ├────────────────────────┬────────────────────────────────────────────────-┤
-- │ Grupo 6                │ → Nuestra ESPECIALIDAD (ID)                   │
-- ├────────────────────────┼────────────────────────────────────────────────-┤
-- │ Medicina Interna       │ → Medicina General (1)                        │
-- │ Cardiología            │ → Cardiología (3)                             │
-- │ Neurología             │ → Neurología (5)                              │
-- │ Pediatría              │ → Pediatría (2)                               │
-- │ Ginecología            │ → Ginecología (6)                             │
-- │ Dermatología           │ → Dermatología (4)                            │
-- │ Traumatología          │ → Traumatología (7)                           │
-- │ Oftalmología           │ → Oftalmología (8)                            │
-- │ Otorrinolaringología   │ → Otorrinolaringología (9)                    │
-- │ Urología               │ → Urología (10)                               │
-- │ Endocrinología         │ → Endocrinología (14)                         │
-- │ Psiquiatría            │ → Psiquiatría (13)                            │
-- │ Oncología              │ → Oncología (15)                              │
-- │ Cirugía General        │ → Traumatología (7)                           │
-- │ Anestesiología         │ → Medicina General (1)                        │
-- │ Radiología             │ → Medicina General (1)                        │
-- │ Hematología            │ → Medicina General (1)                        │
-- │ Infectología           │ → Medicina General (1)                        │
-- │ Medicina Familiar      │ → Medicina General (1)                        │
-- │ Medicina Preventiva    │ → Medicina General (1)                        │
-- │ Medicina de Emergencias│ → Medicina General (1)                        │
-- │ Nefrología             │ → Urología (10)                               │
-- │ Patología              │ → Medicina General (1)                        │
-- │ Reumatología           │ → Traumatología (7)                           │
-- └────────────────────────┴────────────────────────────────────────────────-┘
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Zona especial para Grupo 6
-- ----------------------------------------------------------------------------
INSERT INTO ZONA (ID_Zona, Nombre, Ciudad)
VALUES (98, 'Sin zona asignada', 'Origen: Grupo 6')
ON CONFLICT (ID_Zona) DO NOTHING;

-- ----------------------------------------------------------------------------
-- PASO 2: Tabla de mapeo especialidades Grupo 6 → nuestras
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_mapeo_esp;
CREATE TABLE tfm_g6_mapeo_esp (
    nombre_g6 TEXT PRIMARY KEY,
    id_especialidad_destino INTEGER NOT NULL
);

INSERT INTO tfm_g6_mapeo_esp VALUES
    ('Medicina Interna', 1), ('Cardiología', 3), ('Neurología', 5),
    ('Pediatría', 2), ('Ginecología', 6), ('Dermatología', 4),
    ('Traumatología', 7), ('Oftalmología', 8), ('Otorrinolaringología', 9),
    ('Urología', 10), ('Endocrinología', 14), ('Psiquiatría', 13),
    ('Oncología', 15), ('Cirugía General', 7), ('Anestesiología', 1),
    ('Radiología', 1), ('Hematología', 1), ('Infectología', 1),
    ('Medicina Familiar', 1), ('Medicina Preventiva', 1),
    ('Medicina de Emergencias', 1), ('Nefrología', 10),
    ('Patología', 1), ('Reumatología', 7);

-- ----------------------------------------------------------------------------
-- PASO 3: Mapeo tipo diagnóstico G6 → nuestro TIPO_DIAGNOSTICO
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_mapeo_tipo_diag;
CREATE TABLE tfm_g6_mapeo_tipo_diag (
    tipo_g6 TEXT PRIMARY KEY,
    id_tipo_diagnostico INTEGER NOT NULL
);

INSERT INTO tfm_g6_mapeo_tipo_diag VALUES
    ('Presuntivo', 5),   -- → Diagnóstico Presuntivo
    ('Confirmado', 6);   -- → Diagnóstico Definitivo

-- ----------------------------------------------------------------------------
-- PASO 4: Transformar Pacientes → PERSONA
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_persona_pacientes;
CREATE TABLE tfm_g6_persona_pacientes AS
SELECT
    p.paciente_id + 300000                          AS id_persona,
    'G6-PAC-' || p.paciente_id                      AS ci,
    COALESCE(p.nombres,'') || ' ' || COALESCE(p.apellidos,'') AS nombre,
    p.fecha_nacimiento                               AS fecha_nacimiento,
    'X'                                              AS sexo,
    COALESCE(NULLIF(p.direccion,''), 'Sin dato (Grupo 6)') AS direccion,
    COALESCE(NULLIF(p.telefono,''), 'Sin dato (Grupo 6)')  AS telefono,
    NULL::VARCHAR(50)                                AS matricula,
    98                                               AS id_zona,
    NULL::INTEGER                                    AS id_especialidad
FROM stg_g6_pacientes p;

COMMENT ON TABLE tfm_g6_persona_pacientes IS 'Transformado: Pacientes Grupo 6 → PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 5: Transformar Personal → PERSONA
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_persona_personal;
CREATE TABLE tfm_g6_persona_personal AS
SELECT
    p.personal_id + 600000                           AS id_persona,
    'G6-PER-' || p.personal_id                       AS ci,
    COALESCE(p.nombres,'') || ' ' || COALESCE(p.apellidos,'') AS nombre,
    '1900-01-01'::DATE                               AS fecha_nacimiento,
    'X'                                              AS sexo,
    'Sin dato (Grupo 6)'                             AS direccion,
    'Sin dato (Grupo 6)'                             AS telefono,
    CASE WHEN p.rol = 'Médico' THEN 'G6-MAT-' || p.personal_id
         ELSE NULL END::VARCHAR(50)                  AS matricula,
    98                                               AS id_zona,
    m.id_especialidad_destino                        AS id_especialidad
FROM stg_g6_personal p
LEFT JOIN stg_g6_especialidades e ON p.especialidad_id = e.especialidad_id
LEFT JOIN tfm_g6_mapeo_esp m ON e.nombre = m.nombre_g6;

COMMENT ON TABLE tfm_g6_persona_personal IS 'Transformado: Personal Grupo 6 → PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 6: Transformar Citas → CITA_MEDICA
-- Solo citas que tienen atención médica asociada (con datos completos)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_cita_medica;
CREATE TABLE tfm_g6_cita_medica AS
SELECT
    c.cita_id + 300000                               AS id_cita,
    COALESCE(c.fecha_creacion::DATE, c.fecha)        AS fecha_registro,
    c.fecha                                          AS fecha_cita,
    c.hora                                           AS hora,
    ROW_NUMBER() OVER (
        PARTITION BY c.fecha, c.medico_id ORDER BY c.hora
    )::INTEGER                                       AS numero_turno,
    COALESCE(c.estado, 'Sin estado')                 AS estado,
    c.paciente_id + 300000                           AS id_paciente,
    c.medico_id + 600000                             AS id_medico
FROM stg_g6_citas c;

COMMENT ON TABLE tfm_g6_cita_medica IS 'Transformado: Citas Grupo 6 → CITA_MEDICA';

-- ----------------------------------------------------------------------------
-- PASO 7: Transformar Diagnosticos → DIAGNOSTICO
-- Necesita mapear atencion → cita para obtener ID_Cita
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_diagnostico;
CREATE TABLE tfm_g6_diagnostico AS
SELECT
    d.diagnostico_id + 300000                        AS id_diagnostico,
    COALESCE(d.descripcion, 'Sin descripción')       AS descripcion,
    'CIE-10: ' || COALESCE(d.codigo_cie10, 'N/A')
        || ' | Tipo: ' || COALESCE(d.tipo, 'N/A')
        || ' | Origen: Grupo 6'                      AS observaciones,
    NULL::VARCHAR(100)                               AS tipo_procedimiento,
    a.cita_id + 300000                               AS id_cita,
    COALESCE(m.id_tipo_diagnostico, 1)               AS id_tipo_diagnostico
FROM stg_g6_diagnosticos d
JOIN stg_g6_atenciones a ON d.atencion_id = a.atencion_id
LEFT JOIN tfm_g6_mapeo_tipo_diag m ON d.tipo = m.tipo_g6;

COMMENT ON TABLE tfm_g6_diagnostico IS 'Transformado: Diagnósticos Grupo 6 → DIAGNOSTICO';

-- ----------------------------------------------------------------------------
-- PASO 8: Transformar Recetas → RECETA
-- Necesita mapear diagnostico_id al nuevo rango
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g6_receta;
CREATE TABLE tfm_g6_receta AS
SELECT
    r.receta_id + 300000                             AS id_receta,
    r.medicamento || ' - ' || r.dosis                AS medicamentos,
    'Frecuencia: ' || COALESCE(r.frecuencia, 'N/A')
        || ' | Duración: ' || COALESCE(r.duracion, 'N/A')
        || CASE WHEN r.indicaciones IS NOT NULL
            THEN ' | ' || r.indicaciones ELSE '' END AS indicaciones,
    r.diagnostico_id + 300000                        AS id_diagnostico
FROM stg_g6_recetas r;

COMMENT ON TABLE tfm_g6_receta IS 'Transformado: Recetas Grupo 6 → RECETA';

-- ----------------------------------------------------------------------------
-- PASO 9: Verificación
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_pac INTEGER; v_per INTEGER; v_cit INTEGER;
    v_dia INTEGER; v_rec INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g6_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g6_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g6_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g6_diagnostico;
    SELECT COUNT(*) INTO v_rec FROM tfm_g6_receta;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'TRANSFORMACIÓN GRUPO 6 - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'tfm_g6_persona_pacientes: % registros', v_pac;
    RAISE NOTICE 'tfm_g6_persona_personal:  % registros', v_per;
    RAISE NOTICE 'tfm_g6_cita_medica:       % registros', v_cit;
    RAISE NOTICE 'tfm_g6_diagnostico:       % registros', v_dia;
    RAISE NOTICE 'tfm_g6_receta:            % registros', v_rec;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;
