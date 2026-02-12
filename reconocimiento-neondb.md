# Reconocimiento de Base de Datos - Grupo Benitez Paco Joel

## Datos de Conexion

| Campo | Valor |
|---|---|
| Host | ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech |
| Puerto | 5432 |
| Base de datos | neondb |
| Usuario | usuario_lectura |
| Plataforma | Neon (PostgreSQL serverless en Azure) |

## Resumen General

- **12 tablas** en esquema `public`
- **24 foreign keys** definidas
- **PKs con UUID** (`gen_random_uuid()`) en todas las tablas
- **90,000 registros** totales (45,000 en diagnosticos + 45,000 en servicios, resto vacío)
- Usa **CHECK constraints** para validar estados y tipos enumerados

## Estructura de Tablas

### 1. personas
Tabla central que almacena todas las personas del sistema (pacientes, medicos, admin, enfermeros).

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_persona | UUID | PK | gen_random_uuid() |
| tipo_documento | VARCHAR(20) | Si | |
| numero_documento | VARCHAR(20) | No | UNIQUE |
| nombre_completo | VARCHAR(200) | No | |
| fecha_nacimiento | DATE | Si | |
| genero | VARCHAR(10) | Si | CHECK: M, F, OTRO |
| telefono | VARCHAR(20) | Si | |
| email | VARCHAR(255) | Si | |
| direccion | TEXT | Si | |
| tipo_persona | VARCHAR(20) | Si | CHECK: PACIENTE, MEDICO, ADMIN, ENFERMERO |
| activo | BOOLEAN | Si | default: true |
| fecha_registro | TIMESTAMP | Si | default: CURRENT_TIMESTAMP |

**Registros:** 0

---

### 2. pacientes
Extiende personas con datos clinicos del paciente.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_paciente | UUID | PK | gen_random_uuid() |
| id_persona | UUID | No | FK -> personas, UNIQUE |
| numero_historia_clinica | VARCHAR(50) | No | UNIQUE |
| tipo_seguro | VARCHAR(50) | Si | |
| alergias | TEXT | Si | |
| enfermedades_cronicas | TEXT | Si | |
| antecedentes_quirurgicos | TEXT | Si | |
| fecha_registro | TIMESTAMP | Si | default: CURRENT_TIMESTAMP |

**Registros:** 0

---

### 3. personal_medico
Extiende personas con datos laborales del personal medico.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_personal | UUID | PK | gen_random_uuid() |
| id_persona | UUID | No | FK -> personas, UNIQUE |
| codigo_empleado | VARCHAR(50) | No | UNIQUE |
| especialidad | VARCHAR(150) | Si | |
| cargo | VARCHAR(100) | Si | |
| numero_colegiatura | VARCHAR(50) | Si | |
| fecha_ingreso | DATE | Si | |
| salario_base | NUMERIC(12,2) | Si | |
| activo | BOOLEAN | Si | default: true |

**Registros:** 0

---

### 4. servicios
Catalogo de servicios que ofrece la clinica.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_servicio | UUID | PK | gen_random_uuid() |
| codigo | VARCHAR(50) | No | UNIQUE |
| nombre | VARCHAR(200) | No | |
| tipo | VARCHAR(30) | Si | CHECK: CONSULTA, CIRUGIA, LABORATORIO, IMAGEN, HOSPITALIZACION, EMERGENCIA |
| especialidad | VARCHAR(150) | Si | |
| costo | NUMERIC(12,2) | No | |
| duracion_minutos | INT | Si | |

**Registros:** 45,000

---

### 5. diagnosticos
Catalogo de diagnosticos medicos con clasificacion CIE-10.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_diagnostico | UUID | PK | gen_random_uuid() |
| codigo_cie10 | VARCHAR(20) | Si | |
| nombre | VARCHAR(500) | No | |
| categoria | VARCHAR(100) | Si | Indice: idx_diagnostico_categoria |
| es_cronico | BOOLEAN | Si | default: false |
| es_quirurgico | BOOLEAN | Si | default: false |
| es_infeccioso | BOOLEAN | Si | default: false |

**Registros:** 45,000

---

### 6. citas
Registro de citas medicas programadas.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_cita | UUID | PK | gen_random_uuid() |
| id_paciente | UUID | No | FK -> pacientes |
| id_personal | UUID | No | FK -> personal_medico |
| id_servicio | UUID | No | FK -> servicios |
| fecha_cita | DATE | No | Indice: idx_citas_fecha |
| hora_cita | TIME | No | |
| estado | VARCHAR(20) | Si | CHECK: PROGRAMADA, CONFIRMADA, COMPLETADA, CANCELADA, NO_ASISTIO |
| tipo_cita | VARCHAR(20) | Si | CHECK: PRIMERA_VEZ, CONTROL, EMERGENCIA, CIRUGIA |
| fecha_solicitud | TIMESTAMP | Si | default: CURRENT_TIMESTAMP |
| motivo_consulta | TEXT | Si | |

**Registros:** 0

---

### 7. atenciones
Registro de atenciones medicas realizadas (vinculadas o no a una cita).

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_atencion | UUID | PK | gen_random_uuid() |
| id_cita | UUID | Si | FK -> citas |
| id_paciente | UUID | No | FK -> pacientes |
| id_medico | UUID | No | FK -> personal_medico |
| fecha_atencion | TIMESTAMP | Si | default: CURRENT_TIMESTAMP, Indice: idx_atenciones_fecha |
| diagnostico_principal | UUID | Si | FK -> diagnosticos |
| tipo_diagnostico | VARCHAR(20) | Si | CHECK: PRESUNTIVO, DEFINITIVO |
| plan_tratamiento | TEXT | Si | |
| requiere_cirugia | BOOLEAN | Si | default: false |
| es_emergencia | BOOLEAN | Si | default: false |
| pronostico | VARCHAR(20) | Si | CHECK: FAVORABLE, RESERVADO, GRAVE |

**Registros:** 0

---

### 8. diagnosticos_atencion
Tabla intermedia N:M entre atenciones y diagnosticos.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_atencion | UUID | No | PK compuesta, FK -> atenciones (ON DELETE CASCADE) |
| id_diagnostico | UUID | No | PK compuesta, FK -> diagnosticos |
| tipo | VARCHAR(20) | Si | CHECK: PRINCIPAL, SECUNDARIO, COMPLICACION |

**Registros:** 0

---

### 9. prescripciones
Recetas medicas emitidas durante una atencion.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_prescripcion | UUID | PK | gen_random_uuid() |
| id_atencion | UUID | No | FK -> atenciones |
| id_paciente | UUID | No | FK -> pacientes |
| id_medico | UUID | No | FK -> personal_medico |
| medicamento | VARCHAR(300) | No | |
| dosis | VARCHAR(100) | Si | |
| frecuencia | VARCHAR(100) | Si | |
| duracion_dias | INT | Si | |
| fecha_prescripcion | TIMESTAMP | Si | default: CURRENT_TIMESTAMP |

**Registros:** 0

---

### 10. procedimientos
Procedimientos quirurgicos o medicos realizados.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_procedimiento | UUID | PK | gen_random_uuid() |
| id_atencion | UUID | No | FK -> atenciones |
| id_servicio | UUID | No | FK -> servicios |
| id_paciente | UUID | No | FK -> pacientes |
| id_cirujano | UUID | Si | FK -> personal_medico |
| fecha_procedimiento | TIMESTAMP | Si | default: CURRENT_TIMESTAMP |
| diagnostico_asociado | UUID | Si | FK -> diagnosticos |
| resultado | TEXT | Si | |
| complicaciones | TEXT | Si | |
| tiempo_quirurgico_minutos | INT | Si | |

**Registros:** 0

---

### 11. facturacion
Registro de facturacion por servicios prestados.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_factura | UUID | PK | gen_random_uuid() |
| id_paciente | UUID | No | FK -> pacientes |
| id_atencion | UUID | Si | FK -> atenciones |
| id_servicio | UUID | Si | FK -> servicios |
| fecha_emision | TIMESTAMP | Si | default: CURRENT_TIMESTAMP, Indice: idx_facturacion_fecha |
| monto_total | NUMERIC(12,2) | No | |
| estado_pago | VARCHAR(20) | Si | CHECK: PAGADO, PENDIENTE, ANULADO |
| metodo_pago | VARCHAR(30) | Si | CHECK: EFECTIVO, TARJETA, TRANSFERENCIA |

**Registros:** 0

---

### 12. ausencias
Control de ausencias del personal medico.

| Columna | Tipo | Nullable | Notas |
|---|---|---|---|
| id_ausencia | UUID | PK | gen_random_uuid() |
| id_personal | UUID | No | FK -> personal_medico |
| fecha_inicio | DATE | No | |
| fecha_fin | DATE | No | |
| tipo | VARCHAR(30) | Si | CHECK: INCAPACIDAD, VACACIONES, LICENCIA, PERMISO |
| diagnostico_asociado | UUID | Si | FK -> diagnosticos |
| motivo | TEXT | Si | |
| estado | VARCHAR(20) | Si | CHECK: APROBADO, PENDIENTE, RECHAZADO |

**Registros:** 0

---

## Mapa de Relaciones (Foreign Keys)

```
personas
├── pacientes (id_persona -> personas.id_persona, ON DELETE CASCADE)
│   ├── citas (id_paciente -> pacientes.id_paciente)
│   ├── atenciones (id_paciente -> pacientes.id_paciente)
│   ├── prescripciones (id_paciente -> pacientes.id_paciente)
│   ├── procedimientos (id_paciente -> pacientes.id_paciente)
│   └── facturacion (id_paciente -> pacientes.id_paciente)
│
└── personal_medico (id_persona -> personas.id_persona, ON DELETE CASCADE)
    ├── citas (id_personal -> personal_medico.id_personal)
    ├── atenciones (id_medico -> personal_medico.id_personal)
    ├── prescripciones (id_medico -> personal_medico.id_personal)
    ├── procedimientos (id_cirujano -> personal_medico.id_personal)
    └── ausencias (id_personal -> personal_medico.id_personal)

servicios
├── citas (id_servicio -> servicios.id_servicio)
├── procedimientos (id_servicio -> servicios.id_servicio)
└── facturacion (id_servicio -> servicios.id_servicio)

diagnosticos
├── atenciones (diagnostico_principal -> diagnosticos.id_diagnostico)
├── diagnosticos_atencion (id_diagnostico -> diagnosticos.id_diagnostico)
├── procedimientos (diagnostico_asociado -> diagnosticos.id_diagnostico)
└── ausencias (diagnostico_asociado -> diagnosticos.id_diagnostico)

citas
└── atenciones (id_cita -> citas.id_cita)

atenciones
├── diagnosticos_atencion (id_atencion -> atenciones.id_atencion, ON DELETE CASCADE)
├── prescripciones (id_atencion -> atenciones.id_atencion)
├── procedimientos (id_atencion -> atenciones.id_atencion)
└── facturacion (id_atencion -> atenciones.id_atencion)
```

## Observaciones

1. **Datos incompletos**: Solo las tablas catalogo (`diagnosticos` y `servicios`) tienen datos (45,000 cada una). Las tablas transaccionales (`personas`, `pacientes`, `citas`, `atenciones`, etc.) estan vacias.
2. **Patron de herencia**: Usan el patron tabla-por-subtipo con `personas` como tabla padre y `pacientes`/`personal_medico` como tablas hijas con relacion 1:1 (UNIQUE en id_persona).
3. **UUIDs**: Todas las PKs son UUID con `gen_random_uuid()`, a diferencia de nuestro esquema que usa SERIAL (INT autoincremental).
4. **CHECK constraints**: Usan validaciones CHECK para enumeraciones en lugar de tablas de referencia separadas (ej: estados de cita, tipos de servicio, metodos de pago).
5. **Indices**: Tienen indices en campos de fecha para optimizar consultas temporales (`idx_citas_fecha`, `idx_atenciones_fecha`, `idx_facturacion_fecha`, `idx_diagnostico_categoria`).
6. **CASCADE**: Solo aplican `ON DELETE CASCADE` en las relaciones personas->pacientes, personas->personal_medico, y atenciones->diagnosticos_atencion.
7. **Tabla pivote**: `diagnosticos_atencion` es la unica relacion N:M, con PK compuesta y un campo `tipo` para clasificar el diagnostico (PRINCIPAL, SECUNDARIO, COMPLICACION).
