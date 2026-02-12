-- ============================================================
-- Documentacion de tablas y columnas
-- Visible con: \dt+ (tablas) y \d+ nombre_tabla (columnas)
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
