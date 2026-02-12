-- ============================================================
-- Seed: 50,000 registros generados automáticamente
-- Distribución:
--   ESPECIALIDAD       ->       15
--   TIPO_DIAGNOSTICO   ->       25
--   ZONA               ->       20
--   PERSONA            ->    5,000  (500 médicos + 4,500 pacientes)
--   HORARIO_MEDICO     ->    2,500
--   CITA_MEDICA        ->   20,000
--   DIAGNOSTICO        ->   15,000
--   RECETA             ->    7,440
--                        ----------
--   TOTAL              =   50,000
-- ============================================================

DO $$
DECLARE
    nombres TEXT[] := ARRAY[
        'Juan','María','Carlos','Ana','Pedro','Laura','Miguel','Sofía',
        'Diego','Valentina','Jorge','Camila','Luis','Fernanda','Andrés',
        'Gabriela','José','Isabella','Ricardo','Daniela','Fernando','Natalia',
        'Roberto','Alejandra','Pablo','Carolina','Eduardo','Paola','Sergio',
        'Claudia','Héctor','Mónica','Raúl','Patricia','Gustavo','Verónica',
        'Marco','Lucía','Álvaro','Elena','Óscar','Rosa','Adrián','Teresa',
        'César','Marta','Iván','Beatriz','Tomás','Silvia'
    ];
    apellidos TEXT[] := ARRAY[
        'García','Rodríguez','Martínez','López','González','Hernández',
        'Pérez','Sánchez','Ramírez','Torres','Flores','Rivera','Gómez',
        'Díaz','Cruz','Morales','Reyes','Gutiérrez','Ortiz','Ramos',
        'Vargas','Castillo','Mendoza','Rojas','Herrera','Medina','Aguilar',
        'Vega','Castro','Campos','Delgado','Ríos','Núñez','Ponce',
        'Salazar','Chávez','Contreras','Espinoza','Miranda','Molina'
    ];
    ciudades TEXT[] := ARRAY[
        'Santa Cruz','La Paz','Cochabamba','Sucre','Oruro',
        'Tarija','Potosí','Trinidad','Cobija','El Alto'
    ];
    zonas_nombres TEXT[] := ARRAY[
        'Zona Norte','Zona Sur','Zona Central','Zona Este','Zona Oeste',
        'Plan 3000','Equipetrol','Urbarí','Los Lotes','Pampa de la Isla',
        'Villa 1ro de Mayo','Radial 10','Radial 13','Radial 17','Radial 26',
        'Hamacas','La Guardia','Cotoca','Warnes','Montero'
    ];
    especialidades TEXT[] := ARRAY[
        'Medicina General','Pediatría','Cardiología','Dermatología','Neurología',
        'Ginecología','Traumatología','Oftalmología','Otorrinolaringología',
        'Urología','Gastroenterología','Neumología','Psiquiatría',
        'Endocrinología','Oncología'
    ];
    tipos_diag_nombre TEXT[] := ARRAY[
        'Diagnóstico Clínico','Diagnóstico por Imagen','Diagnóstico de Laboratorio',
        'Diagnóstico Diferencial','Diagnóstico Presuntivo','Diagnóstico Definitivo',
        'Diagnóstico Prenatal','Diagnóstico Molecular','Diagnóstico Patológico',
        'Diagnóstico Funcional','Diagnóstico Genético','Diagnóstico Serológico',
        'Diagnóstico Histológico','Diagnóstico Citológico','Diagnóstico Microbiológico',
        'Diagnóstico Inmunológico','Diagnóstico Nutricional','Diagnóstico Psicológico',
        'Diagnóstico Electrocardiográfico','Diagnóstico Ecográfico',
        'Diagnóstico Radiológico','Diagnóstico Endoscópico','Diagnóstico Quirúrgico',
        'Diagnóstico Ambulatorio','Diagnóstico de Emergencia'
    ];
    tipos_diag_cat TEXT[] := ARRAY[
        'Clínico','Imagen','Laboratorio','Diferencial','Presuntivo','Definitivo',
        'Prenatal','Molecular','Patológico','Funcional','Genético','Serológico',
        'Histológico','Citológico','Microbiológico','Inmunológico','Nutricional',
        'Psicológico','Cardiológico','Ecográfico','Radiológico','Endoscópico',
        'Quirúrgico','Ambulatorio','Emergencia'
    ];
    estados TEXT[] := ARRAY['Pendiente','Confirmada','Cancelada','Completada','No asistió'];
    medicamentos TEXT[] := ARRAY[
        'Paracetamol 500mg','Ibuprofeno 400mg','Amoxicilina 500mg','Omeprazol 20mg',
        'Metformina 850mg','Losartán 50mg','Atorvastatina 20mg','Diclofenaco 50mg',
        'Cetirizina 10mg','Azitromicina 500mg','Ciprofloxacino 500mg','Ranitidina 150mg',
        'Salbutamol inhalador','Prednisona 20mg','Clonazepam 0.5mg','Enalapril 10mg',
        'Amlodipino 5mg','Metoclopramida 10mg','Ketorolaco 10mg','Fluconazol 150mg'
    ];
    procedimientos TEXT[] := ARRAY[
        'Consulta','Cirugía menor','Cirugía mayor','Endoscopía','Biopsia',
        'Ecografía','Radiografía','Resonancia','Tomografía','Electrocardiograma',
        NULL, NULL, NULL, NULL, NULL
    ];
    descripciones TEXT[] := ARRAY[
        'Paciente presenta síntomas leves, se recomienda seguimiento',
        'Se observan signos de infección, se inicia tratamiento antibiótico',
        'Cuadro clínico estable, se mantiene medicación actual',
        'Paciente refiere dolor agudo, se solicitan estudios complementarios',
        'Resultados de laboratorio dentro de parámetros normales',
        'Se detecta anomalía en estudios de imagen, se deriva a especialista',
        'Control post-operatorio satisfactorio',
        'Paciente con evolución favorable, se programa alta',
        'Se ajusta dosis de medicación por efectos secundarios',
        'Evaluación inicial, se solicitan exámenes de rutina'
    ];
    observaciones TEXT[] := ARRAY[
        'Reposo relativo por 3 días','Control en 1 semana','Dieta blanda por 5 días',
        'Evitar esfuerzo físico','Tomar medicación con alimentos','Hidratación abundante',
        'Aplicar compresas frías','Control con resultados de laboratorio',
        'Volver si persisten los síntomas','Derivado a interconsulta'
    ];
    indicaciones TEXT[] := ARRAY[
        'Tomar cada 8 horas por 7 días','Tomar cada 12 horas por 5 días',
        'Tomar en ayunas por 30 días','Aplicar 2 veces al día por 10 días',
        'Tomar cada 6 horas si hay dolor','Una vez al día antes de dormir',
        'Tomar con abundante agua','Cada 24 horas por 14 días',
        'Según necesidad, máximo 3 veces al día','Dosis única, repetir en 7 días si es necesario'
    ];
    direcciones TEXT[] := ARRAY[
        'Av. Principal','Calle Comercio','Av. Libertad','Calle Bolívar',
        'Av. San Martín','Calle Sucre','Av. Independencia','Calle Junín',
        'Av. Brasil','Calle Colón','Av. Busch','Calle Jordán'
    ];

    total_especialidades INT := 15;
    total_tipos_diag INT := 25;
    total_zonas INT := 20;
    total_medicos INT := 500;
    total_pacientes INT := 4500;
    total_personas INT := 5000;
    total_horarios INT := 2500;
    total_citas INT := 20000;
    total_diagnosticos INT := 15000;
    total_recetas INT := 7440;

    v_id_medico INT;
    v_id_paciente INT;
BEGIN
    -- ========== ESPECIALIDAD (15) ==========
    INSERT INTO ESPECIALIDAD (Nombre)
    SELECT unnest(especialidades);

    -- ========== TIPO_DIAGNOSTICO (25) ==========
    INSERT INTO TIPO_DIAGNOSTICO (Nombre, Categoria)
    SELECT unnest(tipos_diag_nombre), unnest(tipos_diag_cat);

    -- ========== ZONA (20) ==========
    INSERT INTO ZONA (Nombre, Ciudad)
    SELECT zonas_nombres[i],
           ciudades[1 + ((i - 1) % array_length(ciudades, 1))]
    FROM generate_series(1, total_zonas) AS i;

    -- ========== PERSONA - Médicos (500) ==========
    INSERT INTO PERSONA (CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
    SELECT
        (1000000 + i)::TEXT,
        nombres[1 + (i % array_length(nombres, 1))] || ' ' ||
            apellidos[1 + (i % array_length(apellidos, 1))] || ' ' ||
            apellidos[1 + ((i * 7) % array_length(apellidos, 1))],
        DATE '1960-01-01' + (random() * 10000)::INT,
        CASE WHEN random() < 0.5 THEN 'M' ELSE 'F' END,
        direcciones[1 + (i % array_length(direcciones, 1))] || ' #' || (100 + i)::TEXT,
        '7' || LPAD((1000000 + (random() * 8999999)::INT)::TEXT, 7, '0'),
        'MAT-' || LPAD(i::TEXT, 5, '0'),
        1 + (i % total_zonas),
        1 + (i % total_especialidades)
    FROM generate_series(1, total_medicos) AS i;

    -- ========== PERSONA - Pacientes (4500) ==========
    INSERT INTO PERSONA (CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
    SELECT
        (2000000 + i)::TEXT,
        nombres[1 + ((i * 3) % array_length(nombres, 1))] || ' ' ||
            apellidos[1 + ((i * 11) % array_length(apellidos, 1))] || ' ' ||
            apellidos[1 + ((i * 13) % array_length(apellidos, 1))],
        DATE '1950-01-01' + (random() * 25000)::INT,
        CASE WHEN random() < 0.5 THEN 'M' ELSE 'F' END,
        direcciones[1 + (i % array_length(direcciones, 1))] || ' #' || (500 + i)::TEXT,
        '6' || LPAD((1000000 + (random() * 8999999)::INT)::TEXT, 7, '0'),
        NULL,
        1 + (i % total_zonas),
        NULL
    FROM generate_series(1, total_pacientes) AS i;

    -- ========== HORARIO_MEDICO (2500) ==========
    INSERT INTO HORARIO_MEDICO (Dia_Semana, Hora_Inicio, Hora_Fin, Cupo_Maximo, ID_Persona)
    SELECT
        1 + (i % 5),
        TIME '07:00' + ((i % 6) * INTERVAL '1 hour'),
        TIME '07:00' + ((i % 6) * INTERVAL '1 hour') + INTERVAL '4 hours',
        10 + (i % 21),
        1 + (i % total_medicos)
    FROM generate_series(1, total_horarios) AS i;

    -- ========== CITA_MEDICA (20000) ==========
    INSERT INTO CITA_MEDICA (Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
    SELECT
        DATE '2024-01-01' + (random() * 700)::INT,
        DATE '2024-01-01' + (random() * 700)::INT + (random() * 7)::INT,
        TIME '08:00' + ((i % 10) * INTERVAL '30 minutes'),
        1 + (i % 30),
        estados[1 + (i % array_length(estados, 1))],
        total_medicos + 1 + (i % total_pacientes),
        1 + (i % total_medicos)
    FROM generate_series(1, total_citas) AS i;

    -- ========== DIAGNOSTICO (15000) ==========
    INSERT INTO DIAGNOSTICO (Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
    SELECT
        descripciones[1 + (i % array_length(descripciones, 1))],
        observaciones[1 + (i % array_length(observaciones, 1))],
        procedimientos[1 + (i % array_length(procedimientos, 1))],
        1 + ((i - 1) % total_citas),
        1 + (i % total_tipos_diag)
    FROM generate_series(1, total_diagnosticos) AS i;

    -- ========== RECETA (7440) ==========
    INSERT INTO RECETA (Medicamentos, Indicaciones, ID_Diagnostico)
    SELECT
        medicamentos[1 + (i % array_length(medicamentos, 1))] || ', ' ||
            medicamentos[1 + ((i * 7) % array_length(medicamentos, 1))],
        indicaciones[1 + (i % array_length(indicaciones, 1))],
        1 + ((i - 1) % total_diagnosticos)
    FROM generate_series(1, total_recetas) AS i;

    RAISE NOTICE '== Seed completado: 50,000 registros insertados ==';
END $$;
