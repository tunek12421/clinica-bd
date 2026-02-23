-- ============================================================================
-- ETL GRUPO 6 - FASE 1: EXTRACCIÓN (Importación de CSVs a staging)
-- ============================================================================
-- Fuente: SQLite hospital.db (9 tablas, ~960,000 registros)
-- Destino: clinica_db (tablas con prefijo stg_g6_)
-- ============================================================================

BEGIN;

DROP TABLE IF EXISTS stg_g6_recetas CASCADE;
DROP TABLE IF EXISTS stg_g6_diagnosticos CASCADE;
DROP TABLE IF EXISTS stg_g6_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g6_historias CASCADE;
DROP TABLE IF EXISTS stg_g6_citas CASCADE;
DROP TABLE IF EXISTS stg_g6_personal CASCADE;
DROP TABLE IF EXISTS stg_g6_especialidades CASCADE;
DROP TABLE IF EXISTS stg_g6_pacientes CASCADE;

CREATE TABLE stg_g6_pacientes (
    paciente_id INTEGER PRIMARY KEY, nombres TEXT, apellidos TEXT,
    telefono TEXT, correo TEXT, direccion TEXT,
    fecha_nacimiento DATE, fecha_registro TIMESTAMP
);

CREATE TABLE stg_g6_especialidades (
    especialidad_id INTEGER PRIMARY KEY, nombre TEXT, descripcion TEXT
);

CREATE TABLE stg_g6_personal (
    personal_id INTEGER PRIMARY KEY, nombres TEXT, apellidos TEXT,
    rol TEXT, especialidad_id INTEGER, fecha_contratacion DATE
);

CREATE TABLE stg_g6_citas (
    cita_id INTEGER PRIMARY KEY, paciente_id INTEGER, medico_id INTEGER,
    fecha DATE, hora TIME, estado TEXT, fecha_creacion TIMESTAMP
);

CREATE TABLE stg_g6_historias (
    historia_id INTEGER PRIMARY KEY, paciente_id INTEGER,
    fecha_apertura DATE, estado TEXT
);

CREATE TABLE stg_g6_atenciones (
    atencion_id INTEGER PRIMARY KEY, historia_id INTEGER, cita_id INTEGER,
    fecha_hora TIMESTAMP, motivo_consulta TEXT, notas_clinicas TEXT
);

CREATE TABLE stg_g6_diagnosticos (
    diagnostico_id INTEGER PRIMARY KEY, atencion_id INTEGER,
    codigo_cie10 TEXT, descripcion TEXT, tipo TEXT
);

CREATE TABLE stg_g6_recetas (
    receta_id INTEGER PRIMARY KEY, diagnostico_id INTEGER,
    medicamento TEXT, dosis TEXT, frecuencia TEXT, duracion TEXT, indicaciones TEXT
);

\copy stg_g6_pacientes FROM '/tmp/g6_pacientes.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_especialidades FROM '/tmp/g6_especialidades.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_personal FROM '/tmp/g6_personal.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_citas FROM '/tmp/g6_citas.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_historias FROM '/tmp/g6_historias.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_atenciones FROM '/tmp/g6_atenciones.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_diagnosticos FROM '/tmp/g6_diagnosticos.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g6_recetas FROM '/tmp/g6_recetas.csv' WITH (FORMAT csv, HEADER true);

DO $$
DECLARE
    v_total INTEGER := 0;
    v_count INTEGER;
    v_tables TEXT[] := ARRAY['stg_g6_pacientes','stg_g6_especialidades','stg_g6_personal',
        'stg_g6_citas','stg_g6_historias','stg_g6_atenciones','stg_g6_diagnosticos','stg_g6_recetas'];
    t TEXT;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXTRACCIÓN GRUPO 6 - RESUMEN';
    RAISE NOTICE '============================================';
    FOREACH t IN ARRAY v_tables LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', t) INTO v_count;
        RAISE NOTICE '%: % registros', t, v_count;
        v_total := v_total + v_count;
    END LOOP;
    RAISE NOTICE 'TOTAL: % registros', v_total;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;
