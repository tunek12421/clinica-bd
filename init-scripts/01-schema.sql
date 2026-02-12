CREATE TABLE ESPECIALIDAD (
    ID_Especialidad SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL
);

CREATE TABLE TIPO_DIAGNOSTICO (
    ID_Tipo_Diagnostico SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Categoria VARCHAR(100) NOT NULL
);

CREATE TABLE ZONA (
    ID_Zona SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Ciudad VARCHAR(100) NOT NULL
);

CREATE TABLE PERSONA (
    ID_Persona SERIAL PRIMARY KEY,
    CI VARCHAR(20) NOT NULL,
    Nombre VARCHAR(150) NOT NULL,
    Fecha_Nacimiento DATE NOT NULL,
    Sexo CHAR(1) NOT NULL,
    Direccion VARCHAR(255) NOT NULL,
    Telefono VARCHAR(20) NOT NULL,
    Matricula VARCHAR(50),
    ID_Zona INT NOT NULL,
    ID_Especialidad INT,
    CONSTRAINT fk_persona_zona FOREIGN KEY (ID_Zona) REFERENCES ZONA(ID_Zona),
    CONSTRAINT fk_persona_especialidad FOREIGN KEY (ID_Especialidad) REFERENCES ESPECIALIDAD(ID_Especialidad)
);

CREATE TABLE HORARIO_MEDICO (
    ID_Horario SERIAL PRIMARY KEY,
    Dia_Semana INT NOT NULL,
    Hora_Inicio TIME NOT NULL,
    Hora_Fin TIME NOT NULL,
    Cupo_Maximo INT NOT NULL,
    ID_Persona INT NOT NULL,
    CONSTRAINT fk_horario_persona FOREIGN KEY (ID_Persona) REFERENCES PERSONA(ID_Persona)
);

CREATE TABLE CITA_MEDICA (
    ID_Cita SERIAL PRIMARY KEY,
    Fecha_Registro DATE NOT NULL,
    Fecha_Cita DATE NOT NULL,
    Hora TIME NOT NULL,
    Numero_Turno INT NOT NULL,
    Estado VARCHAR(50) NOT NULL,
    ID_Paciente INT NOT NULL,
    ID_Medico INT NOT NULL,
    CONSTRAINT fk_cita_paciente FOREIGN KEY (ID_Paciente) REFERENCES PERSONA(ID_Persona),
    CONSTRAINT fk_cita_medico FOREIGN KEY (ID_Medico) REFERENCES PERSONA(ID_Persona)
);

CREATE TABLE DIAGNOSTICO (
    ID_Diagnostico SERIAL PRIMARY KEY,
    Descripcion TEXT NOT NULL,
    Observaciones TEXT NOT NULL,
    Tipo_Procedimiento VARCHAR(100),
    ID_Cita INT NOT NULL,
    ID_Tipo_Diagnostico INT NOT NULL,
    CONSTRAINT fk_diagnostico_cita FOREIGN KEY (ID_Cita) REFERENCES CITA_MEDICA(ID_Cita),
    CONSTRAINT fk_diagnostico_tipo FOREIGN KEY (ID_Tipo_Diagnostico) REFERENCES TIPO_DIAGNOSTICO(ID_Tipo_Diagnostico)
);

CREATE TABLE RECETA (
    ID_Receta SERIAL PRIMARY KEY,
    Medicamentos TEXT NOT NULL,
    Indicaciones TEXT NOT NULL,
    ID_Diagnostico INT NOT NULL,
    CONSTRAINT fk_receta_diagnostico FOREIGN KEY (ID_Diagnostico) REFERENCES DIAGNOSTICO(ID_Diagnostico)
);
