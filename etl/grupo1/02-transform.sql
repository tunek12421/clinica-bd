-- ============================================================================
-- ETL GRUPO 1 - FASE 2: TRANSFORMACIÓN
-- ============================================================================
-- Descripción: Transforma los datos extraídos (staging) al formato compatible
--              con nuestro esquema de producción.
--
-- Prerequisito: Haber ejecutado 01-extract.sql exitosamente.
--
-- Ejecutar:  docker compose exec db psql -U clinica_user -d clinica_db -f /etl/grupo1/02-transform.sql
--
-- ============================================================================
-- DOCUMENTACIÓN DE MAPEO
-- ============================================================================
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO DE TABLAS: GRUPO 1 → NUESTRO ESQUEMA                             │
-- ├──────────────────────┬───────────────────────────────────────────────────┤
-- │ ORIGEN (Grupo 1)     │ DESTINO (Nuestro esquema)                       │
-- ├──────────────────────┼───────────────────────────────────────────────────┤
-- │ pacientes            │ PERSONA (como pacientes, sin especialidad)      │
-- │ personal             │ PERSONA (como staff, con especialidad/cargo)    │
-- │ atenciones           │ CITA_MEDICA                                     │
-- │ diagnosticos         │ DIAGNOSTICO                                     │
-- │ (no existe)          │ HORARIO_MEDICO — no se puede derivar            │
-- │ (no existe)          │ RECETA — no se puede derivar                    │
-- └──────────────────────┴───────────────────────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ ESTRATEGIA DE IDs (OFFSET)                                              │
-- │ Evita colisión con datos existentes (max actual: PERSONA=5000)          │
-- ├──────────────────────┬──────────────────────┬──────────────────────────-─┤
-- │ Entidad              │ Rango IDs            │ Offset aplicado            │
-- ├──────────────────────┼──────────────────────┼────────────────────────────┤
-- │ Pacientes → PERSONA  │ 100,001 - 150,000    │ +100,000                  │
-- │ Personal  → PERSONA  │ 200,001 - 250,000    │ +200,000                  │
-- │ Atenciones→ CITA     │ 100,001 - 150,000    │ +100,000                  │
-- │ Diagnóst. → DIAGNOST │ 100,001 - 168,123    │ +100,000                  │
-- └──────────────────────┴──────────────────────┴────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CAMPOS FALTANTES Y DECISIONES DE TRANSFORMACIÓN                         │
-- ├────────────────────┬──────────────────┬──────────────────────────────────┤
-- │ Campo destino      │ ¿Disponible?     │ Estrategia                      │
-- ├────────────────────┼──────────────────┼──────────────────────────────────┤
-- │ PERSONA.CI         │ NO               │ 'G1-PAC-{id}' / 'G1-PER-{id}'  │
-- │ PERSONA.Direccion  │ NO               │ 'Sin dato (Grupo 1)'            │
-- │ PERSONA.Telefono   │ NO               │ 'Sin dato (Grupo 1)'            │
-- │ PERSONA.ID_Zona    │ NO               │ Zona especial ID=99             │
-- │ PERSONA.Fecha_Nac  │ Solo pacientes   │ Staff: '1900-01-01' (marcador)  │
-- │ PERSONA.Sexo       │ Solo pacientes   │ Staff: 'X' (no disponible)      │
-- │ PERSONA.Matricula  │ NO (parcial)     │ Doctores: 'G1-MAT-{id}'        │
-- │ CITA.Fecha_Registro│ NO               │ = fecha_atencion::DATE          │
-- │ CITA.Numero_Turno  │ NO               │ ROW_NUMBER() por día+médico     │
-- │ CITA.Hora          │ Sí (en timestamp)│ fecha_atencion::TIME            │
-- │ DIAG.Observaciones │ NO (directo)     │ 'CIE-10: {cod} | Sev: {sev}'   │
-- │ DIAG.Tipo_Proced.  │ NO               │ NULL                            │
-- │ DIAG.ID_Tipo_Diag  │ NO (directo)     │ Mapeo CIE-10 → categoría       │
-- └────────────────────┴──────────────────┴──────────────────────────────────┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO CIE-10 → TIPO_DIAGNOSTICO                                        │
-- │ Basado en el método diagnóstico clínico típico para cada patología      │
-- ├──────────────┬───────────────────────────────┬──────────────────────────-┤
-- │ Código CIE10 │ Diagnóstico                   │ → Tipo (ID)              │
-- ├──────────────┼───────────────────────────────┼──────────────────────────-┤
-- │ I10          │ Hipertensión esencial         │ → Clínico (1)            │
-- │ R10.9        │ Dolor abdominal               │ → Clínico (1)            │
-- │ M54.5        │ Dolor lumbar bajo             │ → Por Imagen (2)         │
-- │ J02.9        │ Faringitis aguda              │ → Clínico (1)            │
-- │ R51          │ Cefalea                       │ → Clínico (1)            │
-- │ L30.9        │ Dermatitis                    │ → Clínico (1)            │
-- │ J06.9        │ Infección resp. superior      │ → Clínico (1)            │
-- │ J20.9        │ Bronquitis aguda              │ → Clínico (1)            │
-- │ E78.5        │ Hiperlipidemia                │ → Laboratorio (3)        │
-- │ E11.9        │ Diabetes mellitus tipo 2      │ → Laboratorio (3)        │
-- │ N39.0        │ Infección urinaria            │ → Laboratorio (3)        │
-- │ E66.9        │ Obesidad                      │ → Nutricional (17)       │
-- │ K29.5        │ Gastritis crónica             │ → Endoscópico (22)       │
-- │ Z00.0        │ Examen general                │ → Ambulatorio (24)       │
-- │ Z71.1        │ Consulta orientación          │ → Ambulatorio (24)       │
-- └──────────────┴───────────────────────────────┴──────────────────────────-┘
--
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MAPEO ESPECIALIDADES (texto → ID)                                       │
-- │ Las 8 especialidades del Grupo 1 existen en nuestro catálogo            │
-- ├────────────────────┬────────────────────────────────────────────────────-┤
-- │ Texto Grupo 1      │ → ID en nuestra BD                                │
-- ├────────────────────┼────────────────────────────────────────────────────-┤
-- │ Medicina General   │ → 1                                               │
-- │ Pediatría          │ → 2                                               │
-- │ Cardiología        │ → 3                                               │
-- │ Dermatología       │ → 4                                               │
-- │ Neurología         │ → 5                                               │
-- │ Ginecología        │ → 6                                               │
-- │ Traumatología      │ → 7                                               │
-- │ Urología           │ → 10                                              │
-- └────────────────────┴────────────────────────────────────────────────────-┘
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Crear zona especial para datos del Grupo 1 (sin zona de origen)
-- ----------------------------------------------------------------------------
-- El Grupo 1 no tiene información geográfica de sus pacientes/personal.
-- Se crea una zona marcadora para cumplir el NOT NULL sin inventar datos.

INSERT INTO ZONA (ID_Zona, Nombre, Ciudad)
VALUES (99, 'Sin zona asignada', 'Origen: Grupo 1')
ON CONFLICT (ID_Zona) DO NOTHING;

-- ----------------------------------------------------------------------------
-- PASO 2: Tabla de mapeo CIE-10 → TIPO_DIAGNOSTICO
-- ----------------------------------------------------------------------------
-- Tabla auxiliar para la transformación de diagnósticos.

DROP TABLE IF EXISTS tfm_g1_mapeo_cie10;

CREATE TABLE tfm_g1_mapeo_cie10 (
    codigo_cie10        VARCHAR(10) PRIMARY KEY,
    id_tipo_diagnostico INTEGER NOT NULL
);

COMMENT ON TABLE tfm_g1_mapeo_cie10 IS 'Auxiliar: Mapeo CIE-10 a TIPO_DIAGNOSTICO para ETL Grupo 1';

INSERT INTO tfm_g1_mapeo_cie10 (codigo_cie10, id_tipo_diagnostico) VALUES
    ('I10',   1),   -- Hipertensión → Clínico
    ('R10.9', 1),   -- Dolor abdominal → Clínico
    ('M54.5', 2),   -- Dolor lumbar → Imagen
    ('J02.9', 1),   -- Faringitis → Clínico
    ('R51',   1),   -- Cefalea → Clínico
    ('L30.9', 1),   -- Dermatitis → Clínico
    ('J06.9', 1),   -- Infección resp. → Clínico
    ('J20.9', 1),   -- Bronquitis → Clínico
    ('E78.5', 3),   -- Hiperlipidemia → Laboratorio
    ('E11.9', 3),   -- Diabetes tipo 2 → Laboratorio
    ('N39.0', 3),   -- Infección urinaria → Laboratorio
    ('E66.9', 17),  -- Obesidad → Nutricional
    ('K29.5', 22),  -- Gastritis → Endoscópico
    ('Z00.0', 24),  -- Examen general → Ambulatorio
    ('Z71.1', 24);  -- Consulta orientación → Ambulatorio

-- ----------------------------------------------------------------------------
-- PASO 3: Transformar PACIENTES → formato PERSONA
-- ----------------------------------------------------------------------------
-- Datos disponibles: nombre, fecha_nacimiento, genero
-- Datos faltantes:   CI, direccion, telefono, zona

DROP TABLE IF EXISTS tfm_g1_persona_pacientes;

CREATE TABLE tfm_g1_persona_pacientes AS
SELECT
    p.paciente_id + 100000              AS id_persona,
    'G1-PAC-' || p.paciente_id          AS ci,
    p.nombre                            AS nombre,
    p.fecha_nacimiento                  AS fecha_nacimiento,
    p.genero                            AS sexo,
    'Sin dato (Grupo 1)'                AS direccion,
    'Sin dato (Grupo 1)'                AS telefono,
    NULL::VARCHAR(50)                   AS matricula,
    99                                  AS id_zona,
    NULL::INTEGER                       AS id_especialidad
FROM stg_g1_pacientes p;

COMMENT ON TABLE tfm_g1_persona_pacientes IS 'Transformado: Pacientes Grupo 1 → formato PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 4: Transformar PERSONAL → formato PERSONA
-- ----------------------------------------------------------------------------
-- Datos disponibles: nombre, cargo, especialidad (texto)
-- Datos faltantes:   CI, fecha_nacimiento, sexo, direccion, telefono, zona
-- Decisiones:
--   - fecha_nacimiento = '1900-01-01' (marcador: dato no disponible)
--   - sexo = 'X' (marcador: dato no disponible)
--   - Matricula solo para cargo = 'Doctor'
--   - ID_Especialidad mapeado desde texto usando tabla ESPECIALIDAD

DROP TABLE IF EXISTS tfm_g1_persona_personal;

CREATE TABLE tfm_g1_persona_personal AS
SELECT
    p.personal_id + 200000              AS id_persona,
    'G1-PER-' || p.personal_id          AS ci,
    p.nombre                            AS nombre,
    '1900-01-01'::DATE                  AS fecha_nacimiento,
    'X'                                 AS sexo,
    'Sin dato (Grupo 1)'                AS direccion,
    'Sin dato (Grupo 1)'                AS telefono,
    CASE
        WHEN p.cargo = 'Doctor'
        THEN 'G1-MAT-' || p.personal_id
        ELSE NULL
    END::VARCHAR(50)                    AS matricula,
    99                                  AS id_zona,
    e.ID_Especialidad                   AS id_especialidad
FROM stg_g1_personal p
LEFT JOIN ESPECIALIDAD e ON LOWER(TRIM(p.especialidad)) = LOWER(TRIM(e.Nombre));

COMMENT ON TABLE tfm_g1_persona_personal IS 'Transformado: Personal Grupo 1 → formato PERSONA';

-- ----------------------------------------------------------------------------
-- PASO 5: Transformar ATENCIONES → formato CITA_MEDICA
-- ----------------------------------------------------------------------------
-- Datos disponibles: fecha_atencion (timestamp), estado, paciente_id, personal_id
-- Datos faltantes:   Fecha_Registro, Numero_Turno
-- Transformaciones:
--   - fecha_atencion::DATE → Fecha_Cita
--   - fecha_atencion::TIME → Hora
--   - Fecha_Registro = Fecha_Cita (mejor aproximación disponible)
--   - Numero_Turno = secuencial por día + médico (derivado del orden temporal)
--   - IDs offset: paciente_id+100000, personal_id+200000

DROP TABLE IF EXISTS tfm_g1_cita_medica;

CREATE TABLE tfm_g1_cita_medica AS
SELECT
    a.atencion_id + 100000                  AS id_cita,
    a.fecha_atencion::DATE                  AS fecha_registro,
    a.fecha_atencion::DATE                  AS fecha_cita,
    a.fecha_atencion::TIME                  AS hora,
    ROW_NUMBER() OVER (
        PARTITION BY a.fecha_atencion::DATE, a.personal_id
        ORDER BY a.fecha_atencion
    )::INTEGER                              AS numero_turno,
    COALESCE(a.estado, 'Sin estado')        AS estado,
    a.paciente_id + 100000                  AS id_paciente,
    a.personal_id + 200000                  AS id_medico
FROM stg_g1_atenciones a;

COMMENT ON TABLE tfm_g1_cita_medica IS 'Transformado: Atenciones Grupo 1 → formato CITA_MEDICA';

-- ----------------------------------------------------------------------------
-- PASO 6: Transformar DIAGNOSTICOS → formato DIAGNOSTICO
-- ----------------------------------------------------------------------------
-- Datos disponibles: descripcion, codigo_cie10, severidad, atencion_id
-- Datos faltantes:   Observaciones, ID_Tipo_Diagnostico (directo), Tipo_Procedimiento
-- Transformaciones:
--   - Observaciones = construido con CIE-10 + severidad (datos reales del origen)
--   - ID_Tipo_Diagnostico = mapeo CIE-10 → tipo (tabla tfm_g1_mapeo_cie10)
--   - Tipo_Procedimiento = NULL (no disponible)
--   - ID_Cita = atencion_id + 100000

DROP TABLE IF EXISTS tfm_g1_diagnostico;

CREATE TABLE tfm_g1_diagnostico AS
SELECT
    d.diagnostico_id + 100000                           AS id_diagnostico,
    COALESCE(d.descripcion, 'Sin descripción')          AS descripcion,
    'CIE-10: ' || COALESCE(d.codigo_cie10, 'N/A')
        || ' | Severidad: ' || COALESCE(d.severidad, 'No especificada')
        || ' | Origen: Grupo 1'                         AS observaciones,
    NULL::VARCHAR(100)                                  AS tipo_procedimiento,
    d.atencion_id + 100000                              AS id_cita,
    COALESCE(m.id_tipo_diagnostico, 1)                  AS id_tipo_diagnostico
FROM stg_g1_diagnosticos d
LEFT JOIN tfm_g1_mapeo_cie10 m ON d.codigo_cie10 = m.codigo_cie10;

COMMENT ON TABLE tfm_g1_diagnostico IS 'Transformado: Diagnósticos Grupo 1 → formato DIAGNOSTICO';

-- ----------------------------------------------------------------------------
-- PASO 7: Verificación de transformación
-- ----------------------------------------------------------------------------

DO $$
DECLARE
    v_pac INTEGER;
    v_per INTEGER;
    v_cit INTEGER;
    v_dia INTEGER;
    v_esp_null INTEGER;
    v_cie_sin INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM tfm_g1_persona_pacientes;
    SELECT COUNT(*) INTO v_per FROM tfm_g1_persona_personal;
    SELECT COUNT(*) INTO v_cit FROM tfm_g1_cita_medica;
    SELECT COUNT(*) INTO v_dia FROM tfm_g1_diagnostico;

    -- Verificar personal sin especialidad mapeada
    SELECT COUNT(*) INTO v_esp_null
    FROM tfm_g1_persona_personal WHERE id_especialidad IS NULL;

    -- Verificar diagnósticos sin mapeo CIE-10 (usaron default=1)
    SELECT COUNT(*) INTO v_cie_sin
    FROM stg_g1_diagnosticos d
    LEFT JOIN tfm_g1_mapeo_cie10 m ON d.codigo_cie10 = m.codigo_cie10
    WHERE m.codigo_cie10 IS NULL;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'TRANSFORMACIÓN COMPLETADA - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'tfm_g1_persona_pacientes: % registros', v_pac;
    RAISE NOTICE 'tfm_g1_persona_personal:  % registros', v_per;
    RAISE NOTICE 'tfm_g1_cita_medica:       % registros', v_cit;
    RAISE NOTICE 'tfm_g1_diagnostico:       % registros', v_dia;
    RAISE NOTICE '--------------------------------------------';
    RAISE NOTICE 'Personal sin especialidad mapeada: %', v_esp_null;
    RAISE NOTICE 'Diagnósticos sin mapeo CIE-10:     % (default → Clínico)', v_cie_sin;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;

-- ============================================================================
-- CONSULTAS DE AUDITORÍA (ejecutar manualmente)
-- ============================================================================
-- Verificar mapeo de especialidades:
-- SELECT id_especialidad, COUNT(*) FROM tfm_g1_persona_personal GROUP BY id_especialidad ORDER BY 1;
--
-- Verificar distribución de tipos diagnóstico:
-- SELECT id_tipo_diagnostico, COUNT(*) FROM tfm_g1_diagnostico GROUP BY id_tipo_diagnostico ORDER BY 2 DESC;
--
-- Muestra de transformaciones:
-- SELECT * FROM tfm_g1_persona_pacientes LIMIT 5;
-- SELECT * FROM tfm_g1_persona_personal LIMIT 5;
-- SELECT * FROM tfm_g1_cita_medica LIMIT 5;
-- SELECT * FROM tfm_g1_diagnostico LIMIT 5;
