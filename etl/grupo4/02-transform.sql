-- ============================================================================
-- ETL GRUPO 4 - FASE 2: TRANSFORMACIÓN
-- ============================================================================
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO DE TABLAS: GRUPO 4 (modelo estrella) → NUESTRO ESQUEMA           │
-- ├──────────────────────┬───────────────────────────────────────────────────┤
-- │ ORIGEN (Grupo 4)     │ DESTINO (Grupo 3)                               │
-- ├──────────────────────┼───────────────────────────────────────────────────┤
-- │ dim_paciente         │ PERSONA (como pacientes)                        │
-- │ dim_personal_medico  │ PERSONA (como staff/médicos)                    │
-- │ fact_atenciones      │ CITA_MEDICA + DIAGNOSTICO                      │
-- │  + dim_tiempo        │  (fecha, año, mes, trimestre)                   │
-- │  + dim_diagnostico   │  (descripción, CIE-10, categoría)              │
-- └──────────────────────┴───────────────────────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ ESTRATEGIA DE IDs (OFFSET) — Grupo 4 usa rangos 600,000+/700,000+     │
-- ├──────────────────────┬──────────────────────┬───────────────────────────┤
-- │ Entidad              │ Rango IDs            │ Offset aplicado           │
-- ├──────────────────────┼──────────────────────┼───────────────────────────┤
-- │ Pacientes → PERSONA  │ 700,001 - 1,000,000  │ +700,000                 │
-- │ Personal  → PERSONA  │ 1,000,001 - 1,300,000│ +1,000,000               │
-- │ Atenciones→ CITA_MED │ 600,001 - 900,000    │ +600,000                 │
-- │ Diagnóst. → DIAGNOST │ 600,001 - 900,000    │ +600,000                 │
-- └──────────────────────┴──────────────────────┴───────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CAMPOS FALTANTES Y DECISIONES                                           │
-- ├────────────────────┬──────────────────┬──────────────────────────────────┤
-- │ Campo destino      │ ¿Disponible?     │ Estrategia                      │
-- ├────────────────────┼──────────────────┼──────────────────────────────────┤
-- │ PERSONA.CI (pac)   │ Sí               │ Directo desde dim_paciente.ci   │
-- │ PERSONA.CI (per)   │ NO               │ 'G4-PER-{sk}'                   │
-- │ PERSONA.Nombre     │ nombre_completo  │ Directo                         │
-- │ PERSONA.Sexo       │ Femenino/Masc.   │ LEFT(sexo,1) → 'F'/'M'         │
-- │ PERSONA.Sexo (per) │ NO               │ 'X' (no disponible)             │
-- │ PERSONA.Direccion  │ Sí (pacientes)   │ Directo / 'Sin dato' (personal) │
-- │ PERSONA.Telefono   │ NO               │ 'Sin dato (Grupo 4)'            │
-- │ PERSONA.ID_Zona    │ NO               │ Zona especial ID=97             │
-- │ CITA.Hora          │ NO               │ NULL                             │
-- │ CITA.Numero_Turno  │ NO               │ ROW_NUMBER() por día+médico     │
-- │ DIAG.Observaciones │ categoria+CIE-10 │ 'CIE-10: {cod} | Cat: {cat}'   │
-- │ DIAG.Tipo_Proced.  │ tipo_atencion    │ Directo                          │
-- └────────────────────┴──────────────────┴──────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO ESPECIALIDADES GRUPO 4 → NUESTRAS (15)                           │
-- │ De las 13 del G4, 9 coinciden. Las 4 restantes → más cercana.          │
-- ├────────────────────────────┬────────────────────────────────────────────-┤
-- │ Grupo 4                    │ → Nuestra ESPECIALIDAD (ID)               │
-- ├────────────────────────────┼────────────────────────────────────────────-┤
-- │ Medicina General           │ → Medicina General (1)                    │
-- │ Pediatría                  │ → Pediatría (2)                           │
-- │ Cardiología                │ → Cardiología (3)                         │
-- │ Dermatología               │ → Dermatología (4)                        │
-- │ Neurología                 │ → Neurología (5)                          │
-- │ Oftalmología               │ → Oftalmología (8)                        │
-- │ Traumatología              │ → Traumatología (7)                       │
-- │ Urología                   │ → Urología (10)                           │
-- │ Endocrinología             │ → Endocrinología (14)                     │
-- │ Ginecología y Obstetricia  │ → Ginecología (6)                         │
-- │ Cirugía General            │ → Traumatología (7)                       │
-- │ Medicina Interna           │ → Medicina General (1)                    │
-- │ Anestesiología             │ → Medicina General (1)                    │
-- └────────────────────────────┴────────────────────────────────────────────-┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO CATEGORÍAS DIAGNÓSTICO GRUPO 4 → NUESTRO TIPO_DIAGNOSTICO        │
-- ├─────────────────────────────┬───────────────────────────────────────────-┤
-- │ Grupo 4 (categoria_cie10)   │ → Nuestro TIPO_DIAGNOSTICO (ID)          │
-- ├─────────────────────────────┼───────────────────────────────────────────-┤
-- │ Cardiovasculares            │ → Diagnóstico Clínico (1)                │
-- │ Embarazo y parto            │ → Diagnóstico Clínico (1)                │
-- │ Endocrinas                  │ → Diagnóstico de Laboratorio (3)         │
-- │ Enfermedades digestivas     │ → Diagnóstico Endoscópico (22)           │
-- │ Enfermedades genitourinarias│ → Diagnóstico de Laboratorio (3)         │
-- │ Enfermedades respiratorias  │ → Diagnóstico Clínico (1)                │
-- │ Infecciosas intestinales    │ → Diagnóstico Microbiológico (15)        │
-- │ Respiratorio                │ → Diagnóstico Clínico (1)                │
-- │ Traumatismos                │ → Diagnóstico por Imagen (2)             │
-- └─────────────────────────────┴───────────────────────────────────────────-┘
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Zona especial para Grupo 4
-- ----------------------------------------------------------------------------
INSERT INTO ZONA (ID_Zona, Nombre, Ciudad)
VALUES (97, 'Sin zona asignada', 'Origen: Grupo 4')
ON CONFLICT (ID_Zona) DO NOTHING;

-- ----------------------------------------------------------------------------
-- PASO 2: Tabla de mapeo especialidades Grupo 4 → nuestras
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_mapeo_esp;
CREATE TABLE tfm_g4_mapeo_esp (
    nombre_g4 TEXT PRIMARY KEY,
    id_especialidad_destino INTEGER NOT NULL
);

INSERT INTO tfm_g4_mapeo_esp VALUES
    ('Medicina General', 1),
    ('Pediatría', 2),
    ('Cardiología', 3),
    ('Dermatología', 4),
    ('Neurología', 5),
    ('Ginecología y Obstetricia', 6),
    ('Traumatología', 7),
    ('Oftalmología', 8),
    ('Urología', 10),
    ('Endocrinología', 14),
    ('Cirugía General', 7),
    ('Medicina Interna', 1),
    ('Anestesiología', 1);

-- ----------------------------------------------------------------------------
-- PASO 3: Tabla de mapeo categorías diagnóstico G4 → nuestro TIPO_DIAGNOSTICO
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_mapeo_tipo_diag;
CREATE TABLE tfm_g4_mapeo_tipo_diag (
    categoria_g4 TEXT PRIMARY KEY,
    id_tipo_diagnostico INTEGER NOT NULL
);

INSERT INTO tfm_g4_mapeo_tipo_diag VALUES
    ('Cardiovasculares', 1),
    ('Embarazo y parto', 1),
    ('Endocrinas', 3),
    ('Enfermedades digestivas', 22),
    ('Enfermedades genitourinarias', 3),
    ('Enfermedades respiratorias', 1),
    ('Infecciosas intestinales', 15),
    ('Respiratorio', 1),
    ('Traumatismos', 2);

-- ----------------------------------------------------------------------------
-- PASO 4: Transformar dim_paciente → PERSONA (pacientes)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_persona_pacientes;
CREATE TABLE tfm_g4_persona_pacientes AS
SELECT
    p.paciente_sk + 700000                          AS id_persona,
    p.ci                                             AS ci,
    p.nombre_completo                                AS nombre,
    p.fecha_nacimiento                               AS fecha_nacimiento,
    LEFT(p.sexo, 1)                                  AS sexo,
    COALESCE(NULLIF(p.direccion,''), 'Sin dato (Grupo 4)') AS direccion,
    'Sin dato (Grupo 4)'                             AS telefono,
    NULL::VARCHAR(50)                                AS matricula,
    97                                               AS id_zona,
    NULL::INTEGER                                    AS id_especialidad
FROM stg_g4_pacientes p;

COMMENT ON TABLE tfm_g4_persona_pacientes IS 'Transformado: Pacientes Grupo 4 → PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 5: Transformar dim_personal_medico → PERSONA (médicos)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_persona_personal;
CREATE TABLE tfm_g4_persona_personal AS
SELECT
    p.personal_sk + 1000000                          AS id_persona,
    'G4-PER-' || p.personal_sk                       AS ci,
    p.nombre_completo                                AS nombre,
    '1900-01-01'::DATE                               AS fecha_nacimiento,
    'X'                                              AS sexo,
    'Sin dato (Grupo 4)'                             AS direccion,
    'Sin dato (Grupo 4)'                             AS telefono,
    p.colegiatura::VARCHAR(50)                       AS matricula,
    97                                               AS id_zona,
    COALESCE(m.id_especialidad_destino, 1)           AS id_especialidad
FROM stg_g4_personal p
LEFT JOIN tfm_g4_mapeo_esp m ON p.especialidad = m.nombre_g4;

COMMENT ON TABLE tfm_g4_persona_personal IS 'Transformado: Personal Grupo 4 → PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 6: Transformar fact_atenciones → CITA_MEDICA
-- Cada atención del G4 se convierte en una cita médica
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_cita_medica;
CREATE TABLE tfm_g4_cita_medica AS
SELECT
    a.atencion_sk + 600000                           AS id_cita,
    a.fecha                                          AS fecha_registro,
    a.fecha                                          AS fecha_cita,
    '08:00:00'::TIME                                  AS hora,
    ROW_NUMBER() OVER (
        PARTITION BY a.fecha, a.personal_sk ORDER BY a.atencion_sk
    )::INTEGER                                       AS numero_turno,
    COALESCE(a.estado, 'Sin estado')                 AS estado,
    sp.paciente_sk + 700000                          AS id_paciente,
    a.personal_sk + 1000000                          AS id_medico
FROM stg_g4_atenciones a
JOIN (SELECT DISTINCT ON (ci) ci, paciente_sk FROM stg_g4_pacientes ORDER BY ci, paciente_sk) sp
    ON sp.ci = a.paciente_ci;

COMMENT ON TABLE tfm_g4_cita_medica IS 'Transformado: Atenciones Grupo 4 → CITA_MEDICA';

-- ----------------------------------------------------------------------------
-- PASO 7: Transformar fact_atenciones → DIAGNOSTICO
-- Cada atención también genera un diagnóstico
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS tfm_g4_diagnostico;
CREATE TABLE tfm_g4_diagnostico AS
SELECT
    a.atencion_sk + 600000                           AS id_diagnostico,
    COALESCE(a.diagnostico, 'Sin descripción')       AS descripcion,
    'CIE-10: ' || COALESCE(a.codigo_cie10, 'N/A')
        || ' | Cat: ' || COALESCE(a.categoria_cie10, 'N/A')
        || ' | Grupo: ' || COALESCE(a.grupo_enfermedad, 'N/A')
        || ' | Origen: Grupo 4'                      AS observaciones,
    a.tipo_atencion                                  AS tipo_procedimiento,
    a.atencion_sk + 600000                           AS id_cita,
    COALESCE(m.id_tipo_diagnostico, 1)               AS id_tipo_diagnostico
FROM stg_g4_atenciones a
LEFT JOIN tfm_g4_mapeo_tipo_diag m ON a.categoria_cie10 = m.categoria_g4;

COMMENT ON TABLE tfm_g4_diagnostico IS 'Transformado: Diagnósticos Grupo 4 → DIAGNOSTICO';

-- ----------------------------------------------------------------------------
-- PASO 8: Verificación
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_pac INTEGER; v_per INTEGER; v_cit INTEGER;
    v_dia INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g4_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g4_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g4_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g4_diagnostico;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'TRANSFORMACIÓN GRUPO 4 - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'tfm_g4_persona_pacientes: % registros', v_pac;
    RAISE NOTICE 'tfm_g4_persona_personal:  % registros', v_per;
    RAISE NOTICE 'tfm_g4_cita_medica:       % registros', v_cit;
    RAISE NOTICE 'tfm_g4_diagnostico:       % registros', v_dia;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;
