-- ============================================================================
-- DATA WAREHOUSE - ESQUEMA ESTRELLA: Clínica
-- ============================================================================
-- Estructura:
--   dim_paciente ── fact_atenciones ── dim_medico
--
-- fact_atenciones combina datos de CITA_MEDICA + DIAGNOSTICO + TIPO_DIAGNOSTICO
-- Cada fila = un evento de diagnóstico dentro de una cita
-- ============================================================================

-- ========================
-- DIMENSIONES
-- ========================

CREATE TABLE dim_paciente (
    paciente_key     SERIAL PRIMARY KEY,
    ci               VARCHAR(20) NOT NULL,
    nombre           VARCHAR(150) NOT NULL,
    fecha_nacimiento DATE,
    sexo             CHAR(1),
    direccion        VARCHAR(255),
    telefono         VARCHAR(20),
    zona             VARCHAR(100),
    ciudad           VARCHAR(100),
    grupo_origen     VARCHAR(10) NOT NULL
);

CREATE TABLE dim_medico (
    medico_key       SERIAL PRIMARY KEY,
    ci               VARCHAR(20) NOT NULL,
    nombre           VARCHAR(150) NOT NULL,
    matricula        VARCHAR(50),
    sexo             CHAR(1),
    especialidad     VARCHAR(100),
    zona             VARCHAR(100),
    ciudad           VARCHAR(100),
    grupo_origen     VARCHAR(10) NOT NULL
);

-- ========================
-- TABLA DE HECHOS
-- ========================

CREATE TABLE fact_atenciones (
    atencion_key       SERIAL PRIMARY KEY,
    paciente_key       INT NOT NULL REFERENCES dim_paciente(paciente_key),
    medico_key         INT NOT NULL REFERENCES dim_medico(medico_key),
    fecha_cita         DATE NOT NULL,
    anio               INT NOT NULL,
    mes                INT NOT NULL,
    trimestre          INT NOT NULL,
    dia_semana         VARCHAR(15) NOT NULL,
    hora               TIME,
    estado             VARCHAR(50),
    numero_turno       INT,
    descripcion        TEXT,
    observaciones      TEXT,
    tipo_procedimiento VARCHAR(100),
    tipo_diagnostico   VARCHAR(100),
    categoria          VARCHAR(100),
    grupo_origen       VARCHAR(10) NOT NULL
);

-- ========================
-- INDICES
-- ========================
CREATE INDEX idx_fact_paciente ON fact_atenciones(paciente_key);
CREATE INDEX idx_fact_medico ON fact_atenciones(medico_key);
CREATE INDEX idx_fact_fecha ON fact_atenciones(fecha_cita);
CREATE INDEX idx_fact_anio_mes ON fact_atenciones(anio, mes);
CREATE INDEX idx_fact_grupo ON fact_atenciones(grupo_origen);
CREATE INDEX idx_dim_paciente_grupo ON dim_paciente(grupo_origen);
CREATE INDEX idx_dim_medico_esp ON dim_medico(especialidad);
