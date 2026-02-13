-- ============================================================
-- Documentacion interna de la base de datos
-- Visible con:
--   \dt+                -> descripcion de tablas
--   \d+ nombre_tabla    -> descripcion de columnas
--   SELECT * FROM v_documentacion;          -> todo junto
--   SELECT * FROM v_relaciones;             -> mapa de FKs
--   SELECT * FROM v_estadisticas;           -> conteos
-- ============================================================

-- ESPECIALIDAD
COMMENT ON TABLE ESPECIALIDAD IS 'Catalogo de especialidades medicas (ej: Cardiologia, Pediatria)';
COMMENT ON COLUMN ESPECIALIDAD.ID_Especialidad IS 'Identificador unico autoincremental';
COMMENT ON COLUMN ESPECIALIDAD.Nombre IS 'Nombre de la especialidad medica';

-- TIPO_DIAGNOSTICO
COMMENT ON TABLE TIPO_DIAGNOSTICO IS 'Catalogo de tipos de diagnostico con su categoria (ej: Clinico, Imagen, Laboratorio)';
COMMENT ON COLUMN TIPO_DIAGNOSTICO.ID_Tipo_Diagnostico IS 'Identificador unico autoincremental';
COMMENT ON COLUMN TIPO_DIAGNOSTICO.Nombre IS 'Nombre del tipo de diagnostico';
COMMENT ON COLUMN TIPO_DIAGNOSTICO.Categoria IS 'Categoria general a la que pertenece el tipo';

-- ZONA
COMMENT ON TABLE ZONA IS 'Zonas geograficas donde residen las personas';
COMMENT ON COLUMN ZONA.ID_Zona IS 'Identificador unico autoincremental';
COMMENT ON COLUMN ZONA.Nombre IS 'Nombre de la zona (ej: Equipetrol, Plan 3000)';
COMMENT ON COLUMN ZONA.Ciudad IS 'Ciudad a la que pertenece la zona';

-- PERSONA
COMMENT ON TABLE PERSONA IS 'Tabla unificada de personas. Representa tanto pacientes (Matricula NULL) como medicos (Matricula NOT NULL con Especialidad asignada)';
COMMENT ON COLUMN PERSONA.ID_Persona IS 'Identificador unico autoincremental';
COMMENT ON COLUMN PERSONA.CI IS 'Carnet de identidad';
COMMENT ON COLUMN PERSONA.Nombre IS 'Nombre completo de la persona';
COMMENT ON COLUMN PERSONA.Fecha_Nacimiento IS 'Fecha de nacimiento';
COMMENT ON COLUMN PERSONA.Sexo IS 'Sexo: M (masculino) o F (femenino)';
COMMENT ON COLUMN PERSONA.Direccion IS 'Direccion de domicilio';
COMMENT ON COLUMN PERSONA.Telefono IS 'Numero de telefono de contacto';
COMMENT ON COLUMN PERSONA.Matricula IS 'Matricula profesional del medico. NULL si es paciente';
COMMENT ON COLUMN PERSONA.ID_Zona IS 'FK -> ZONA. Zona donde reside la persona';
COMMENT ON COLUMN PERSONA.ID_Especialidad IS 'FK -> ESPECIALIDAD. Solo aplica a medicos, NULL si es paciente';

-- HORARIO_MEDICO
COMMENT ON TABLE HORARIO_MEDICO IS 'Horarios de disponibilidad de los medicos para atencion';
COMMENT ON COLUMN HORARIO_MEDICO.ID_Horario IS 'Identificador unico autoincremental';
COMMENT ON COLUMN HORARIO_MEDICO.Dia_Semana IS 'Dia de la semana: 1=Lunes, 2=Martes, 3=Miercoles, 4=Jueves, 5=Viernes';
COMMENT ON COLUMN HORARIO_MEDICO.Hora_Inicio IS 'Hora de inicio de atencion';
COMMENT ON COLUMN HORARIO_MEDICO.Hora_Fin IS 'Hora de fin de atencion';
COMMENT ON COLUMN HORARIO_MEDICO.Cupo_Maximo IS 'Cantidad maxima de pacientes que puede atender en ese horario';
COMMENT ON COLUMN HORARIO_MEDICO.ID_Persona IS 'FK -> PERSONA. Medico al que pertenece el horario';

-- CITA_MEDICA
COMMENT ON TABLE CITA_MEDICA IS 'Registro de citas medicas entre pacientes y medicos';
COMMENT ON COLUMN CITA_MEDICA.ID_Cita IS 'Identificador unico autoincremental';
COMMENT ON COLUMN CITA_MEDICA.Fecha_Registro IS 'Fecha en que se registro/solicito la cita';
COMMENT ON COLUMN CITA_MEDICA.Fecha_Cita IS 'Fecha programada para la cita';
COMMENT ON COLUMN CITA_MEDICA.Hora IS 'Hora programada para la cita';
COMMENT ON COLUMN CITA_MEDICA.Numero_Turno IS 'Numero de turno asignado al paciente';
COMMENT ON COLUMN CITA_MEDICA.Estado IS 'Estado de la cita: Pendiente, Confirmada, Cancelada, Completada, No asistio';
COMMENT ON COLUMN CITA_MEDICA.ID_Paciente IS 'FK -> PERSONA. Paciente que reserva la cita';
COMMENT ON COLUMN CITA_MEDICA.ID_Medico IS 'FK -> PERSONA. Medico que atiende la cita';

-- DIAGNOSTICO
COMMENT ON TABLE DIAGNOSTICO IS 'Diagnosticos emitidos durante una cita medica';
COMMENT ON COLUMN DIAGNOSTICO.ID_Diagnostico IS 'Identificador unico autoincremental';
COMMENT ON COLUMN DIAGNOSTICO.Descripcion IS 'Descripcion detallada del diagnostico';
COMMENT ON COLUMN DIAGNOSTICO.Observaciones IS 'Observaciones adicionales del medico';
COMMENT ON COLUMN DIAGNOSTICO.Tipo_Procedimiento IS 'Tipo de procedimiento realizado (si aplica). NULL si no hubo procedimiento';
COMMENT ON COLUMN DIAGNOSTICO.ID_Cita IS 'FK -> CITA_MEDICA. Cita en la que se emitio el diagnostico';
COMMENT ON COLUMN DIAGNOSTICO.ID_Tipo_Diagnostico IS 'FK -> TIPO_DIAGNOSTICO. Clasificacion del diagnostico';

-- RECETA
COMMENT ON TABLE RECETA IS 'Recetas medicas generadas a partir de un diagnostico';
COMMENT ON COLUMN RECETA.ID_Receta IS 'Identificador unico autoincremental';
COMMENT ON COLUMN RECETA.Medicamentos IS 'Lista de medicamentos recetados';
COMMENT ON COLUMN RECETA.Indicaciones IS 'Indicaciones de uso (dosis, frecuencia, duracion)';
COMMENT ON COLUMN RECETA.ID_Diagnostico IS 'FK -> DIAGNOSTICO. Diagnostico que origino la receta';

-- ============================================================
-- Comentarios en constraints (FKs)
-- ============================================================
COMMENT ON CONSTRAINT fk_persona_zona ON PERSONA IS 'Cada persona pertenece a una zona geografica';
COMMENT ON CONSTRAINT fk_persona_especialidad ON PERSONA IS 'Especialidad del medico. NULL si la persona es paciente';
COMMENT ON CONSTRAINT fk_horario_persona ON HORARIO_MEDICO IS 'Medico al que pertenece este horario de atencion';
COMMENT ON CONSTRAINT fk_cita_paciente ON CITA_MEDICA IS 'Paciente que solicita/reserva la cita';
COMMENT ON CONSTRAINT fk_cita_medico ON CITA_MEDICA IS 'Medico asignado para atender la cita';
COMMENT ON CONSTRAINT fk_diagnostico_cita ON DIAGNOSTICO IS 'Cita medica en la que se emitio este diagnostico';
COMMENT ON CONSTRAINT fk_diagnostico_tipo ON DIAGNOSTICO IS 'Clasificacion del diagnostico segun catalogo';
COMMENT ON CONSTRAINT fk_receta_diagnostico ON RECETA IS 'Diagnostico que origino esta receta medica';

-- ============================================================
-- Vista: v_documentacion
-- Muestra tabla, columna, tipo de dato y descripcion
-- Uso: SELECT * FROM v_documentacion;
-- ============================================================
CREATE OR REPLACE VIEW v_documentacion AS
SELECT
    t.table_name                                         AS tabla,
    COALESCE(c.column_name, '-')                         AS columna,
    COALESCE(
        UPPER(c.data_type) ||
        CASE
            WHEN c.character_maximum_length IS NOT NULL
                THEN '(' || c.character_maximum_length || ')'
            ELSE ''
        END,
        ''
    )                                                     AS tipo,
    CASE WHEN c.is_nullable = 'NO' THEN 'NO' ELSE 'SI' END AS nullable,
    CASE
        WHEN pk.column_name IS NOT NULL THEN 'PK'
        WHEN fk.column_name IS NOT NULL THEN 'FK -> ' || fk.ref_table
        ELSE ''
    END                                                   AS clave,
    COALESCE(
        col_description(cls.oid, c.ordinal_position),
        obj_description(cls.oid, 'pg_class'),
        ''
    )                                                     AS descripcion
FROM information_schema.tables t
JOIN pg_class cls ON cls.relname = t.table_name
LEFT JOIN information_schema.columns c
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
LEFT JOIN (
    SELECT kcu.table_name, kcu.column_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.constraint_type = 'PRIMARY KEY'
) pk ON pk.table_name = c.table_name AND pk.column_name = c.column_name
LEFT JOIN (
    SELECT
        kcu.table_name,
        kcu.column_name,
        ccu.table_name AS ref_table
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
) fk ON fk.table_name = c.table_name AND fk.column_name = c.column_name
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- ============================================================
-- Vista: v_relaciones
-- Muestra todas las foreign keys con descripcion
-- Uso: SELECT * FROM v_relaciones;
-- ============================================================
CREATE OR REPLACE VIEW v_relaciones AS
SELECT
    con.conname                    AS restriccion,
    con.conrelid::regclass::text   AS tabla_origen,
    a_orig.attname                 AS columna_origen,
    con.confrelid::regclass::text  AS tabla_destino,
    a_dest.attname                 AS columna_destino,
    COALESCE(d.description, '')    AS descripcion
FROM pg_constraint con
JOIN pg_attribute a_orig
    ON a_orig.attnum = ANY(con.conkey) AND a_orig.attrelid = con.conrelid
JOIN pg_attribute a_dest
    ON a_dest.attnum = ANY(con.confkey) AND a_dest.attrelid = con.confrelid
LEFT JOIN pg_description d
    ON d.objoid = con.oid
WHERE con.contype = 'f'
ORDER BY con.conrelid::regclass::text, con.conname;

-- ============================================================
-- Vista: v_estadisticas
-- Muestra conteo de registros por tabla
-- Uso: SELECT * FROM v_estadisticas;
-- ============================================================
CREATE OR REPLACE VIEW v_estadisticas AS
SELECT
    relname                                   AS tabla,
    obj_description(oid, 'pg_class')          AS descripcion,
    reltuples::BIGINT                         AS registros_aprox
FROM pg_class
WHERE relkind = 'r'
    AND relnamespace = 'public'::regnamespace
ORDER BY relname;

-- ============================================================
-- Vista: v_resumen
-- Punto de entrada: muestra las tablas con descripcion,
-- cantidad de columnas y registros.
-- Uso: SELECT * FROM v_resumen;
-- Luego para ver detalle: SELECT * FROM v_documentacion WHERE tabla = 'persona';
-- ============================================================
CREATE OR REPLACE VIEW v_resumen AS
SELECT
    t.table_name                           AS tabla,
    obj_description(cls.oid, 'pg_class')   AS descripcion,
    COUNT(c.column_name)::INT              AS columnas,
    cls.reltuples::BIGINT                  AS registros_aprox
FROM information_schema.tables t
JOIN pg_class cls ON cls.relname = t.table_name
    AND cls.relnamespace = 'public'::regnamespace
LEFT JOIN information_schema.columns c
    ON c.table_name = t.table_name AND c.table_schema = t.table_schema
WHERE t.table_schema = 'public' AND t.table_type = 'BASE TABLE'
GROUP BY t.table_name, cls.oid, cls.reltuples
ORDER BY t.table_name;

-- ============================================================
-- Comentario en la base de datos: punto de entrada
-- Visible con: \l+ (lista bases con descripcion)
-- ============================================================
COMMENT ON DATABASE clinica_db IS 'Sistema de gestion de clinica medica. Para explorar la documentacion ejecute: SELECT * FROM v_ayuda;';

-- ============================================================
-- Vista: v_ayuda
-- Guia de uso para quien se conecte por primera vez
-- ============================================================
CREATE OR REPLACE VIEW v_ayuda AS
SELECT unnest(ARRAY[
    '1. SELECT * FROM v_resumen;                              -- Ver tablas con descripcion y cantidad de registros',
    '2. SELECT * FROM v_documentacion WHERE tabla = ''persona''; -- Ver columnas, tipos y descripcion de una tabla',
    '3. SELECT * FROM v_relaciones;                            -- Ver todas las foreign keys entre tablas',
    '4. SELECT * FROM v_estadisticas;                          -- Ver registros por tabla',
    '5. \dt+                                                   -- Ver tablas con descripcion (psql)',
    '6. \d+ nombre_tabla                                       -- Ver columnas con descripcion (psql)'
]) AS "Comandos disponibles para explorar la base de datos";

COMMENT ON VIEW v_ayuda IS 'Guia de comandos para explorar la documentacion de la base de datos';
COMMENT ON VIEW v_resumen IS 'Resumen de tablas: descripcion, cantidad de columnas y registros';
COMMENT ON VIEW v_documentacion IS 'Detalle de cada columna: tipo, nullable, clave y descripcion. Filtrar con WHERE tabla = ''nombre''';
COMMENT ON VIEW v_relaciones IS 'Mapa de foreign keys: tabla origen, columna, tabla destino y descripcion';
COMMENT ON VIEW v_estadisticas IS 'Conteo aproximado de registros por tabla';

-- Permisos de lectura para el usuario lector
GRANT SELECT ON v_ayuda TO lector;
GRANT SELECT ON v_resumen TO lector;
GRANT SELECT ON v_documentacion TO lector;
GRANT SELECT ON v_relaciones TO lector;
GRANT SELECT ON v_estadisticas TO lector;
