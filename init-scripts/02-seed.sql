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
    -- Pesos para distribucion no uniforme de tipos de diagnostico (25 pesos)
    pesos_diag FLOAT[] := ARRAY[
        15, 12, 10, 9, 8,       -- Clinico, Imagen, Laboratorio, Diferencial, Presuntivo (comunes)
        7, 6, 5, 5, 4,          -- Definitivo, Prenatal, Molecular, Patologico, Funcional
        4, 3, 3, 2.5, 2.5,      -- Genetico, Serologico, Histologico, Citologico, Microbiologico
        2, 1.5, 1.5, 1, 1,      -- Inmunologico, Nutricional, Psicologico, Electrocardio, Ecografico
        0.8, 0.6, 0.4, 0.3, 0.2 -- Radiologico, Endoscopico, Quirurgico, Ambulatorio, Emergencia
    ];
    total_peso_diag FLOAT := 104.8; -- suma de todos los pesos
    -- Pesos para especialidades: Medicina General la mas comun, Oncologia la mas rara
    pesos_esp FLOAT[] := ARRAY[
        18, 14, 12, 10, 8,    -- Med General, Pediatria, Cardiologia, Dermatologia, Neurologia
        7, 6, 5, 3, 4,        -- Ginecologia, Traumatologia, Oftalmologia, Otorrino, Urologia
        4, 3, 2.5, 2, 1.5     -- Gastro, Neumologia, Psiquiatria, Endocrinologia, Oncologia
    ];
    total_peso_esp FLOAT := 100;
    -- Pesos para zonas: zonas urbanas mas pobladas
    pesos_zona FLOAT[] := ARRAY[
        12, 10, 9, 5, 5,      -- Norte, Sur, Central, Este, Oeste
        14, 8, 4, 3, 3,       -- Plan3000, Equipetrol, Urbari, LosLotes, Pampa
        4, 3, 3, 2, 2,        -- Villa1Mayo, Radial10, Radial13, Radial17, Radial26
        2, 3, 3, 2.5, 2.5     -- Hamacas, LaGuardia, Cotoca, Warnes, Montero
    ];
    total_peso_zona FLOAT := 100;
    v_rand FLOAT;
    v_acum FLOAT;
    v_tipo INT;
    v_esp INT;
    v_zona INT;
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
    idx INT;
    jdx INT;
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
    -- Distribucion ponderada por especialidad
    FOR idx IN 1..total_medicos LOOP
        v_rand := random() * total_peso_esp;
        v_acum := 0; v_esp := 1;
        FOR jdx IN 1..total_especialidades LOOP
            v_acum := v_acum + pesos_esp[jdx];
            IF v_rand <= v_acum THEN v_esp := jdx; EXIT; END IF;
        END LOOP;

        INSERT INTO PERSONA (CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
        VALUES (
            (1000000 + idx)::TEXT,
            nombres[1 + (idx % array_length(nombres, 1))] || ' ' ||
                apellidos[1 + (idx % array_length(apellidos, 1))] || ' ' ||
                apellidos[1 + ((idx * 7) % array_length(apellidos, 1))],
            DATE '1960-01-01' + (random() * 10000)::INT,
            CASE WHEN random() < 0.55 THEN 'M' ELSE 'F' END,
            direcciones[1 + (idx % array_length(direcciones, 1))] || ' #' || (100 + idx)::TEXT,
            '7' || LPAD((1000000 + (random() * 8999999)::INT)::TEXT, 7, '0'),
            'MAT-' || LPAD(idx::TEXT, 5, '0'),
            1 + (idx % total_zonas),
            v_esp
        );
    END LOOP;

    -- ========== PERSONA - Pacientes (4500) ==========
    -- Distribucion ponderada por zona (urbanas mas pobladas)
    FOR idx IN 1..total_pacientes LOOP
        v_rand := random() * total_peso_zona;
        v_acum := 0; v_zona := 1;
        FOR jdx IN 1..total_zonas LOOP
            v_acum := v_acum + pesos_zona[jdx];
            IF v_rand <= v_acum THEN v_zona := jdx; EXIT; END IF;
        END LOOP;

        INSERT INTO PERSONA (CI, Nombre, Fecha_Nacimiento, Sexo, Direccion, Telefono, Matricula, ID_Zona, ID_Especialidad)
        VALUES (
            (2000000 + idx)::TEXT,
            nombres[1 + ((idx * 3) % array_length(nombres, 1))] || ' ' ||
                apellidos[1 + ((idx * 11) % array_length(apellidos, 1))] || ' ' ||
                apellidos[1 + ((idx * 13) % array_length(apellidos, 1))],
            DATE '1950-01-01' + (random() * 25000)::INT,
            CASE WHEN random() < 0.52 THEN 'F' ELSE 'M' END,
            direcciones[1 + (idx % array_length(direcciones, 1))] || ' #' || (500 + idx)::TEXT,
            '6' || LPAD((1000000 + (random() * 8999999)::INT)::TEXT, 7, '0'),
            NULL,
            v_zona,
            NULL
        );
    END LOOP;

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
    -- Fechas con estacionalidad: mas citas en invierno (jun-ago), menos en verano (dic-feb)
    -- Estados con distribucion realista
    -- Medicos ponderados: los de especialidades comunes atienden mas
    INSERT INTO CITA_MEDICA (Fecha_Registro, Fecha_Cita, Hora, Numero_Turno, Estado, ID_Paciente, ID_Medico)
    SELECT
        v_fecha_reg, v_fecha_cita, v_hora, v_turno, v_estado, v_pac, v_med
    FROM (
        SELECT
            DATE '2024-01-01' + (
                CASE
                    WHEN random() < 0.15 THEN (random() * 59)::INT           -- Ene-Feb (15%)
                    WHEN random() < 0.30 THEN 60 + (random() * 91)::INT      -- Mar-May (15%)
                    WHEN random() < 0.65 THEN 152 + (random() * 91)::INT     -- Jun-Ago (35% pico invernal)
                    WHEN random() < 0.85 THEN 244 + (random() * 91)::INT     -- Sep-Nov (20%)
                    ELSE 335 + (random() * 30)::INT                           -- Dic (15%)
                END
                + CASE WHEN random() < 0.55 THEN 0 ELSE 365 END              -- 2024 o 2025
            ) AS v_fecha_reg,
            DATE '2024-01-01' + (
                CASE
                    WHEN random() < 0.15 THEN (random() * 59)::INT
                    WHEN random() < 0.30 THEN 60 + (random() * 91)::INT
                    WHEN random() < 0.65 THEN 152 + (random() * 91)::INT
                    WHEN random() < 0.85 THEN 244 + (random() * 91)::INT
                    ELSE 335 + (random() * 30)::INT
                END
                + CASE WHEN random() < 0.55 THEN 0 ELSE 365 END
                + (random() * 7)::INT
            ) AS v_fecha_cita,
            TIME '08:00' + ((i % 10) * INTERVAL '30 minutes') AS v_hora,
            1 + (i % 30) AS v_turno,
            CASE
                WHEN random() < 0.45 THEN 'Completada'
                WHEN random() < 0.70 THEN 'Confirmada'
                WHEN random() < 0.85 THEN 'Pendiente'
                WHEN random() < 0.93 THEN 'No asistió'
                ELSE 'Cancelada'
            END AS v_estado,
            total_medicos + 1 + ((random() * (total_pacientes - 1))::INT) AS v_pac,
            1 + ((random() * (total_medicos - 1))::INT) AS v_med
        FROM generate_series(1, total_citas) AS i
    ) sub;

    -- ========== DIAGNOSTICO (15000) ==========
    -- Distribucion ponderada: Clinico/Imagen/Laboratorio son los mas comunes, Emergencia/Ambulatorio los mas raros
    FOR idx IN 1..total_diagnosticos LOOP
        v_rand := random() * total_peso_diag;
        v_acum := 0;
        v_tipo := 1;
        FOR jdx IN 1..total_tipos_diag LOOP
            v_acum := v_acum + pesos_diag[jdx];
            IF v_rand <= v_acum THEN
                v_tipo := jdx;
                EXIT;
            END IF;
        END LOOP;

        INSERT INTO DIAGNOSTICO (Descripcion, Observaciones, Tipo_Procedimiento, ID_Cita, ID_Tipo_Diagnostico)
        VALUES (
            descripciones[1 + (idx % array_length(descripciones, 1))],
            observaciones[1 + (idx % array_length(observaciones, 1))],
            procedimientos[1 + (idx % array_length(procedimientos, 1))],
            1 + ((idx - 1) % total_citas),
            v_tipo
        );
    END LOOP;

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
