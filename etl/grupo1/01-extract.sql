-- ============================================================================
-- ETL GRUPO 1 - FASE 1: EXTRACCIÓN
-- ============================================================================
-- Descripción: Extrae datos crudos de la BD del Grupo 1 (Supabase) y los
--              almacena en tablas staging dentro de nuestra BD.
--
-- Fuente:    PostgreSQL en Supabase (AWS us-west-2)
--            Host: aws-0-us-west-2.pooler.supabase.com (IP: 44.238.118.41)
--            Puerto: 5432 | DB: postgres
--            Usuario: usuario1.fgzrkjkflenmdmyfnkpr
--
-- Destino:   clinica_db (tablas con prefijo stg_g1_)
--
-- MÉTODO: Exportación CSV desde origen → Importación CSV en destino
--         (más confiable que dblink para grandes volúmenes via Supabase pooler)
--
-- Ejecutar:  ./etl/grupo1/01-extract.sh
--            (script shell que orquesta exportación e importación)
--
-- Tablas origen (Grupo 1):
--   pacientes    → 50,000 registros
--   personal     → 50,000 registros
--   atenciones   → 50,000 registros
--   diagnosticos → 68,123 registros
--
-- Total esperado: ~218,123 registros extraídos
-- ============================================================================

-- Este archivo se ejecuta DESPUÉS de que 01-extract.sh haya exportado los CSVs.
-- Crea las tablas staging e importa los datos desde los archivos CSV.

BEGIN;

-- ----------------------------------------------------------------------------
-- PASO 1: Crear tablas staging (réplica exacta del esquema origen)
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS stg_g1_diagnosticos CASCADE;
DROP TABLE IF EXISTS stg_g1_atenciones CASCADE;
DROP TABLE IF EXISTS stg_g1_personal CASCADE;
DROP TABLE IF EXISTS stg_g1_pacientes CASCADE;

-- Tabla: stg_g1_pacientes
CREATE TABLE stg_g1_pacientes (
    paciente_id      INTEGER PRIMARY KEY,
    nombre           VARCHAR(150) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    genero           CHAR(1) NOT NULL
);
COMMENT ON TABLE stg_g1_pacientes IS 'Staging: Pacientes extraídos de BD Grupo 1 (Supabase)';

-- Tabla: stg_g1_personal
CREATE TABLE stg_g1_personal (
    personal_id  INTEGER PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL,
    cargo        VARCHAR(50),
    especialidad VARCHAR(100)
);
COMMENT ON TABLE stg_g1_personal IS 'Staging: Personal médico extraído de BD Grupo 1 (Supabase)';

-- Tabla: stg_g1_atenciones
CREATE TABLE stg_g1_atenciones (
    atencion_id     INTEGER PRIMARY KEY,
    paciente_id     INTEGER NOT NULL,
    personal_id     INTEGER NOT NULL,
    fecha_atencion  TIMESTAMP NOT NULL,
    estado          VARCHAR(20),
    motivo_consulta TEXT
);
COMMENT ON TABLE stg_g1_atenciones IS 'Staging: Atenciones extraídas de BD Grupo 1 (Supabase)';

-- Tabla: stg_g1_diagnosticos
CREATE TABLE stg_g1_diagnosticos (
    diagnostico_id INTEGER PRIMARY KEY,
    atencion_id    INTEGER NOT NULL,
    codigo_cie10   VARCHAR(10),
    descripcion    TEXT,
    severidad      VARCHAR(20)
);
COMMENT ON TABLE stg_g1_diagnosticos IS 'Staging: Diagnósticos extraídos de BD Grupo 1 (Supabase)';

-- ----------------------------------------------------------------------------
-- PASO 2: Importar datos desde CSVs
-- ----------------------------------------------------------------------------
\copy stg_g1_pacientes FROM '/tmp/g1_pacientes.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g1_personal FROM '/tmp/g1_personal.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g1_atenciones FROM '/tmp/g1_atenciones.csv' WITH (FORMAT csv, HEADER true);
\copy stg_g1_diagnosticos FROM '/tmp/g1_diagnosticos.csv' WITH (FORMAT csv, HEADER true);

-- ----------------------------------------------------------------------------
-- PASO 3: Verificación de extracción
-- ----------------------------------------------------------------------------
DO $$
DECLARE
    v_pac INTEGER;
    v_per INTEGER;
    v_ate INTEGER;
    v_dia INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_pac FROM stg_g1_pacientes;
    SELECT COUNT(*) INTO v_per FROM stg_g1_personal;
    SELECT COUNT(*) INTO v_ate FROM stg_g1_atenciones;
    SELECT COUNT(*) INTO v_dia FROM stg_g1_diagnosticos;

    RAISE NOTICE '============================================';
    RAISE NOTICE 'EXTRACCIÓN COMPLETADA - RESUMEN';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'stg_g1_pacientes:    % registros', v_pac;
    RAISE NOTICE 'stg_g1_personal:     % registros', v_per;
    RAISE NOTICE 'stg_g1_atenciones:   % registros', v_ate;
    RAISE NOTICE 'stg_g1_diagnosticos: % registros', v_dia;
    RAISE NOTICE 'TOTAL:               % registros', v_pac + v_per + v_ate + v_dia;
    RAISE NOTICE '============================================';

    IF v_pac = 0 THEN RAISE WARNING 'ALERTA: stg_g1_pacientes está vacía'; END IF;
    IF v_per = 0 THEN RAISE WARNING 'ALERTA: stg_g1_personal está vacía'; END IF;
    IF v_ate = 0 THEN RAISE WARNING 'ALERTA: stg_g1_atenciones está vacía'; END IF;
    IF v_dia = 0 THEN RAISE WARNING 'ALERTA: stg_g1_diagnosticos está vacía'; END IF;
END;
$$;

COMMIT;
