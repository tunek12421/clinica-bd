-- ============================================================================
-- ETL GRUPO 4 - FASE 1: EXTRACCIÓN (Importación de CSVs a staging)
-- ============================================================================
-- Fuente: Neon (modelo estrella DW - 7 tablas, ~1,800,000 registros)
-- Destino: clinica_db (tablas con prefijo stg_g4_)
--
-- El Grupo 4 migró su BD transaccional a un modelo estrella.
-- Extraemos: dim_paciente, dim_personal_medico, fact_atenciones (con JOINs)
-- ============================================================================

BEGIN;

DROP TABLE IF EXISTS stg_g4_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g4_personal CASCADE;
DROP TABLE IF EXISTS stg_g4_pacientes CASCADE;

CREATE TABLE stg_g4_pacientes (
    paciente_sk      INTEGER PRIMARY KEY,
    ci               VARCHAR(15),
    nombre_completo  VARCHAR(150),
    sexo             VARCHAR(10),
    fecha_nacimiento DATE,
    direccion        TEXT,
    zona             VARCHAR(50),
    municipio        VARCHAR(50)
);

CREATE TABLE stg_g4_personal (
    personal_sk      INTEGER PRIMARY KEY,
    nombre_completo  VARCHAR(150),
    especialidad     VARCHAR(100),
    cargo            VARCHAR(50),
    colegiatura      VARCHAR(50)
);

CREATE TABLE stg_g4_atenciones (
    atencion_sk      INTEGER PRIMARY KEY,
    paciente_ci      VARCHAR(15),
    personal_sk      INTEGER,
    fecha            DATE,
    anio             INTEGER,
    mes              INTEGER,
    trimestre        INTEGER,
    nombre_dia       VARCHAR(15),
    tipo_atencion    VARCHAR(50),
    estado           VARCHAR(30),
    diagnostico      VARCHAR(255),
    codigo_cie10     VARCHAR(10),
    categoria_cie10  VARCHAR(100),
    grupo_enfermedad VARCHAR(100),
    tipo_diagnostico VARCHAR(50)
);

\copy stg_g4_pacientes FROM '/tmp/g4_pacientes.csv' WITH (FORMAT csv);
\copy stg_g4_personal FROM '/tmp/g4_personal.csv' WITH (FORMAT csv);
\copy stg_g4_atenciones FROM '/tmp/g4_atenciones.csv' WITH (FORMAT csv);

DO $$
DECLARE
    v_pac INTEGER;
    v_per INTEGER;
    v_ate INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM stg_g4_pacientes;
    SELECT COUNT(*) INTO v_per FROM stg_g4_personal;
    SELECT COUNT(*) INTO v_ate FROM stg_g4_atenciones;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXTRACCIÓN GRUPO 4 - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'stg_g4_pacientes:  % registros', v_pac;
    RAISE NOTICE 'stg_g4_personal:   % registros', v_per;
    RAISE NOTICE 'stg_g4_atenciones: % registros', v_ate;
    RAISE NOTICE 'TOTAL: % registros', v_pac + v_per + v_ate;
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;
