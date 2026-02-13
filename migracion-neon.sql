-- ============================================================
-- Script de migracion: BD Neon (grupo 4) -> BD Clinica (nuestra)
--
-- Prerequisito: tener acceso a la BD remota via dblink
-- Ejecutar con: docker compose exec db psql -U clinica_user -d clinica_db -f /docker-entrypoint-initdb.d/migracion-neon.sql
-- ============================================================

-- 1. Instalar extension dblink para conectar a la BD remota
CREATE EXTENSION IF NOT EXISTS dblink;

-- Definir conexion remota
DO $$
DECLARE
    conn TEXT := 'host=ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech port=5432 dbname=neondb user=usuario_lectura password=ClaveSegura123 sslmode=require';
    reg RECORD;
BEGIN

-- ============================================================
-- 2. ESPECIALIDAD
-- Ellos: personal_medico.especialidad (VARCHAR, columna suelta)
-- Nosotros: tabla ESPECIALIDAD (ID, Nombre)
-- Estrategia: extraer DISTINCT especialidad e insertar como catalogo
-- ============================================================
INSERT INTO especialidad (nombre)
SELECT DISTINCT especialidad
FROM dblink(conn, 'SELECT DISTINCT especialidad FROM personal_medico WHERE especialidad IS NOT NULL ORDER BY 1')
    AS t(especialidad VARCHAR)
WHERE especialidad NOT IN (SELECT nombre FROM especialidad)
ON CONFLICT DO NOTHING;

RAISE NOTICE 'Especialidades migradas';

-- ============================================================
-- 3. ZONA
-- Ellos: NO tienen tabla de zonas
-- Nosotros: ZONA (ID, Nombre, Ciudad)
-- Estrategia: extraer ciudades unicas desde direccion (no hay datos de zona)
-- Se crea una zona generica para los datos migrados
-- ============================================================
INSERT INTO zona (nombre, ciudad)
SELECT 'Zona Migrada', 'Sin Ciudad'
WHERE NOT EXISTS (SELECT 1 FROM zona WHERE nombre = 'Zona Migrada');

RAISE NOTICE 'Zona generica creada';

-- ============================================================
-- 4. PERSONA (Medicos)
-- Ellos: personas + personal_medico (2 tablas, JOIN por id_persona)
-- Nosotros: PERSONA (tabla unica, Matricula != NULL = medico)
-- Mapeo:
--   personas.numero_documento   -> CI
--   personas.nombre_completo    -> Nombre
--   personas.fecha_nacimiento   -> Fecha_Nacimiento
--   personas.genero (M/F/OTRO)  -> Sexo (M/F)
--   personas.direccion          -> Direccion
--   personas.telefono           -> Telefono
--   personal_medico.numero_colegiatura -> Matricula
--   'Zona Migrada'              -> ID_Zona
--   personal_medico.especialidad -> ID_Especialidad (via lookup)
-- ============================================================
INSERT INTO persona (ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad)
SELECT
    t.numero_documento,
    t.nombre_completo,
    t.fecha_nacimiento,
    CASE WHEN t.genero IN ('M','F') THEN t.genero ELSE 'M' END,
    COALESCE(t.direccion, 'Sin direccion'),
    COALESCE(t.telefono, '0000000'),
    t.numero_colegiatura,
    (SELECT id_zona FROM zona WHERE nombre = 'Zona Migrada' LIMIT 1),
    (SELECT id_especialidad FROM especialidad WHERE nombre = t.especialidad LIMIT 1)
FROM dblink(conn,
    'SELECT p.numero_documento, p.nombre_completo, p.fecha_nacimiento,
            LEFT(p.genero, 1) AS genero, p.direccion, p.telefono,
            pm.numero_colegiatura, pm.especialidad
     FROM personas p
     JOIN personal_medico pm ON p.id_persona = pm.id_persona
     LIMIT 1000')
AS t(numero_documento VARCHAR, nombre_completo VARCHAR, fecha_nacimiento DATE,
     genero CHAR, direccion VARCHAR, telefono VARCHAR,
     numero_colegiatura VARCHAR, especialidad VARCHAR)
WHERE t.numero_documento NOT IN (SELECT ci FROM persona);

RAISE NOTICE 'Medicos migrados';

-- ============================================================
-- 5. PERSONA (Pacientes)
-- Ellos: personas + pacientes (JOIN por id_persona)
-- Nosotros: PERSONA (Matricula = NULL, ID_Especialidad = NULL)
-- Mapeo:
--   personas.numero_documento   -> CI
--   personas.nombre_completo    -> Nombre
--   personas.fecha_nacimiento   -> Fecha_Nacimiento
--   personas.genero             -> Sexo
--   personas.direccion          -> Direccion
--   personas.telefono           -> Telefono
--   NULL                        -> Matricula
--   'Zona Migrada'              -> ID_Zona
--   NULL                        -> ID_Especialidad
-- ============================================================
INSERT INTO persona (ci, nombre, fecha_nacimiento, sexo, direccion, telefono, matricula, id_zona, id_especialidad)
SELECT
    t.numero_documento,
    t.nombre_completo,
    t.fecha_nacimiento,
    CASE WHEN t.genero IN ('M','F') THEN t.genero ELSE 'M' END,
    COALESCE(t.direccion, 'Sin direccion'),
    COALESCE(t.telefono, '0000000'),
    NULL,
    (SELECT id_zona FROM zona WHERE nombre = 'Zona Migrada' LIMIT 1),
    NULL
FROM dblink(conn,
    'SELECT p.numero_documento, p.nombre_completo, p.fecha_nacimiento,
            LEFT(p.genero, 1) AS genero, p.direccion, p.telefono
     FROM personas p
     JOIN pacientes pa ON p.id_persona = pa.id_persona
     LIMIT 5000')
AS t(numero_documento VARCHAR, nombre_completo VARCHAR, fecha_nacimiento DATE,
     genero CHAR, direccion VARCHAR, telefono VARCHAR)
WHERE t.numero_documento NOT IN (SELECT ci FROM persona);

RAISE NOTICE 'Pacientes migrados';

-- ============================================================
-- 6. TIPO_DIAGNOSTICO
-- Ellos: diagnosticos (tabla catalogo con categoria)
-- Nosotros: TIPO_DIAGNOSTICO (Nombre, Categoria)
-- Mapeo:
--   diagnosticos.categoria -> Categoria (DISTINCT)
--   diagnosticos.categoria -> Nombre (prefijo 'Diagnostico ')
-- ============================================================
INSERT INTO tipo_diagnostico (nombre, categoria)
SELECT DISTINCT
    'Diagnostico ' || categoria,
    categoria
FROM dblink(conn, 'SELECT DISTINCT categoria FROM diagnosticos WHERE categoria IS NOT NULL ORDER BY 1')
    AS t(categoria VARCHAR)
WHERE categoria NOT IN (SELECT categoria FROM tipo_diagnostico)
ON CONFLICT DO NOTHING;

RAISE NOTICE 'Tipos de diagnostico migrados';

-- ============================================================
-- 7. CITA_MEDICA
-- Ellos: citas (id_paciente UUID, id_personal UUID, fecha_cita, hora_cita, estado)
-- Nosotros: CITA_MEDICA (Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
-- Mapeo:
--   citas.fecha_solicitud::DATE -> Fecha_Registro
--   citas.fecha_cita            -> Fecha_Cita
--   citas.hora_cita             -> Hora
--   ROW_NUMBER()                -> Numero_Turno
--   citas.estado                -> Estado
--   (lookup por numero_documento del paciente) -> ID_Paciente
--   (lookup por numero_documento del medico)   -> ID_Medico
-- Nota: solo migramos citas cuyos pacientes y medicos ya estan en nuestra BD
-- ============================================================
INSERT INTO cita_medica (fecha_registro, fecha_cita, hora, numero_turno, estado, id_paciente, id_medico)
SELECT
    t.fecha_solicitud,
    t.fecha_cita,
    t.hora_cita,
    ROW_NUMBER() OVER (PARTITION BY t.fecha_cita, t.doc_medico ORDER BY t.hora_cita)::INT,
    t.estado,
    pac.id_persona,
    med.id_persona
FROM dblink(conn,
    'SELECT c.fecha_solicitud::DATE, c.fecha_cita, c.hora_cita, c.estado,
            pp.numero_documento AS doc_paciente,
            pm_p.numero_documento AS doc_medico
     FROM citas c
     JOIN pacientes pa ON c.id_paciente = pa.id_paciente
     JOIN personas pp ON pa.id_persona = pp.id_persona
     JOIN personal_medico pm ON c.id_personal = pm.id_personal
     JOIN personas pm_p ON pm.id_persona = pm_p.id_persona
     LIMIT 5000')
AS t(fecha_solicitud DATE, fecha_cita DATE, hora_cita TIME, estado VARCHAR,
     doc_paciente VARCHAR, doc_medico VARCHAR)
JOIN persona pac ON pac.ci = t.doc_paciente AND pac.matricula IS NULL
JOIN persona med ON med.ci = t.doc_medico AND med.matricula IS NOT NULL;

RAISE NOTICE 'Citas migradas';

-- ============================================================
-- 8. DIAGNOSTICO
-- Ellos: atenciones (tiene diagnostico_principal UUID -> diagnosticos, tipo_diagnostico)
-- Nosotros: DIAGNOSTICO (Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
-- Mapeo:
--   atenciones.plan_tratamiento -> Descripcion
--   atenciones.pronostico       -> Observaciones
--   CASE requiere_cirugia       -> Tipo_Procedimiento
--   (lookup via cita)           -> ID_Cita
--   diagnosticos.categoria      -> ID_Tipo_Diagnostico (via lookup)
-- Nota: solo para citas que ya migramos
-- ============================================================
INSERT INTO diagnostico (descripcion, observaciones, tipo_procedimiento, id_cita, id_tipo_diagnostico)
SELECT
    COALESCE(LEFT(t.plan_tratamiento, 500), 'Sin descripcion'),
    COALESCE(t.pronostico, 'Sin observaciones'),
    CASE WHEN t.requiere_cirugia THEN 'Cirugia' ELSE NULL END,
    cm.id_cita,
    COALESCE(
        (SELECT td.id_tipo_diagnostico FROM tipo_diagnostico td WHERE td.categoria = t.categoria LIMIT 1),
        (SELECT td.id_tipo_diagnostico FROM tipo_diagnostico td LIMIT 1)
    )
FROM dblink(conn,
    'SELECT a.plan_tratamiento, a.pronostico, a.requiere_cirugia,
            d.categoria,
            pp.numero_documento AS doc_paciente,
            pm_p.numero_documento AS doc_medico,
            c.fecha_cita, c.hora_cita
     FROM atenciones a
     JOIN citas c ON a.id_cita = c.id_cita
     JOIN pacientes pa ON a.id_paciente = pa.id_paciente
     JOIN personas pp ON pa.id_persona = pp.id_persona
     JOIN personal_medico pm ON a.id_medico = pm.id_personal
     JOIN personas pm_p ON pm.id_persona = pm_p.id_persona
     LEFT JOIN diagnosticos d ON a.diagnostico_principal = d.id_diagnostico
     LIMIT 5000')
AS t(plan_tratamiento TEXT, pronostico VARCHAR, requiere_cirugia BOOLEAN,
     categoria VARCHAR, doc_paciente VARCHAR, doc_medico VARCHAR,
     fecha_cita DATE, hora_cita TIME)
JOIN persona pac ON pac.ci = t.doc_paciente AND pac.matricula IS NULL
JOIN persona med ON med.ci = t.doc_medico AND med.matricula IS NOT NULL
JOIN cita_medica cm ON cm.id_paciente = pac.id_persona
    AND cm.id_medico = med.id_persona
    AND cm.fecha_cita = t.fecha_cita
    AND cm.hora = t.hora_cita;

RAISE NOTICE 'Diagnosticos migrados';

-- ============================================================
-- 9. RECETA
-- Ellos: prescripciones (medicamento, dosis, frecuencia, duracion_dias)
-- Nosotros: RECETA (Medicamentos, Indicaciones, ID_Diagnostico)
-- Mapeo:
--   prescripciones.medicamento || dosis -> Medicamentos
--   frecuencia || duracion_dias         -> Indicaciones
--   (lookup via diagnostico)            -> ID_Diagnostico
-- Nota: solo para diagnosticos que ya migramos
-- ============================================================
INSERT INTO receta (medicamentos, indicaciones, id_diagnostico)
SELECT
    t.medicamento || ' ' || COALESCE(t.dosis, ''),
    COALESCE(t.frecuencia, '') || ' por ' || COALESCE(t.duracion_dias::TEXT, '?') || ' dias',
    diag.id_diagnostico
FROM dblink(conn,
    'SELECT pr.medicamento, pr.dosis, pr.frecuencia, pr.duracion_dias,
            pp.numero_documento AS doc_paciente,
            pm_p.numero_documento AS doc_medico,
            c.fecha_cita, c.hora_cita
     FROM prescripciones pr
     JOIN atenciones a ON pr.id_atencion = a.id_atencion
     JOIN citas c ON a.id_cita = c.id_cita
     JOIN pacientes pa ON pr.id_paciente = pa.id_paciente
     JOIN personas pp ON pa.id_persona = pp.id_persona
     JOIN personal_medico pm ON pr.id_medico = pm.id_personal
     JOIN personas pm_p ON pm.id_persona = pm_p.id_persona
     LIMIT 5000')
AS t(medicamento VARCHAR, dosis VARCHAR, frecuencia VARCHAR, duracion_dias INT,
     doc_paciente VARCHAR, doc_medico VARCHAR, fecha_cita DATE, hora_cita TIME)
JOIN persona pac ON pac.ci = t.doc_paciente AND pac.matricula IS NULL
JOIN persona med ON med.ci = t.doc_medico AND med.matricula IS NOT NULL
JOIN cita_medica cm ON cm.id_paciente = pac.id_persona
    AND cm.id_medico = med.id_persona
    AND cm.fecha_cita = t.fecha_cita
    AND cm.hora = t.hora_cita
JOIN diagnostico diag ON diag.id_cita = cm.id_cita
LIMIT 5000;

RAISE NOTICE 'Recetas migradas';
RAISE NOTICE '== Migracion completada ==';

END $$;
