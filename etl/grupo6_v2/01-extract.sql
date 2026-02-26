-- ============================================================================
-- ETL GRUPO 6 v2 - FASE 1: CREACIÓN DE TABLAS STAGING
-- ============================================================================
-- Crea tablas staging que replican el esquema del Grupo 6 (PostgreSQL 17)
-- para recibir los INSERTs del dump.
-- ============================================================================

BEGIN;

-- Limpieza de staging anterior
DROP TABLE IF EXISTS stg_g6_receta CASCADE;
DROP TABLE IF EXISTS stg_g6_diagnostico CASCADE;
DROP TABLE IF EXISTS stg_g6_cita_medica CASCADE;
DROP TABLE IF EXISTS stg_g6_personal CASCADE;
DROP TABLE IF EXISTS stg_g6_paciente CASCADE;
DROP TABLE IF EXISTS stg_g6_persona CASCADE;
DROP TABLE IF EXISTS stg_g6_tipo_diagnostico CASCADE;
DROP TABLE IF EXISTS stg_g6_especialidad CASCADE;
DROP TABLE IF EXISTS stg_g6_zona CASCADE;

-- Catálogos
CREATE TABLE stg_g6_zona (
    id_zona INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ciudad VARCHAR(100) NOT NULL
);

CREATE TABLE stg_g6_especialidad (
    id_especialidad INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

CREATE TABLE stg_g6_tipo_diagnostico (
    id_tipo_diagnostico INTEGER PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    categoria VARCHAR(100) NOT NULL
);

-- Personas
CREATE TABLE stg_g6_persona (
    id_persona INTEGER PRIMARY KEY,
    ci VARCHAR(20) NOT NULL,
    nombre VARCHAR(200) NOT NULL,
    fecha_nacimiento DATE NOT NULL,
    sexo CHAR(1) NOT NULL,
    direccion VARCHAR(300) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    matricula VARCHAR(50),
    id_zona INTEGER NOT NULL
);

CREATE TABLE stg_g6_paciente (
    id_paciente INTEGER PRIMARY KEY,
    id_persona INTEGER NOT NULL
);

CREATE TABLE stg_g6_personal (
    id_personal INTEGER PRIMARY KEY,
    id_persona INTEGER NOT NULL,
    id_especialidad INTEGER,
    id_cargo SMALLINT NOT NULL,
    id_turno SMALLINT NOT NULL,
    id_estado_disponibilidad SMALLINT NOT NULL
);

-- Operacionales
CREATE TABLE stg_g6_cita_medica (
    id_cita INTEGER PRIMARY KEY,
    fecha_registro DATE NOT NULL,
    fecha_cita DATE NOT NULL,
    hora TIME NOT NULL,
    numero_turno INTEGER NOT NULL,
    estado VARCHAR(50) NOT NULL,
    id_paciente INTEGER NOT NULL,
    id_medico INTEGER NOT NULL
);

CREATE TABLE stg_g6_diagnostico (
    id_diagnostico INTEGER PRIMARY KEY,
    descripcion TEXT NOT NULL,
    observaciones TEXT NOT NULL,
    tipo_procedimiento VARCHAR(100),
    id_cita INTEGER NOT NULL,
    id_tipo_diagnostico INTEGER NOT NULL
);

CREATE TABLE stg_g6_receta (
    id_receta INTEGER PRIMARY KEY,
    medicamentos TEXT NOT NULL,
    indicaciones TEXT NOT NULL,
    id_diagnostico INTEGER NOT NULL
);

COMMIT;
