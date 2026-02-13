# Informe de Migracion de Datos - BD Neon -> BD Clinica

## 1. Objetivo

Extraer datos de la BD del grupo 4 (Neon) e insertarlos en nuestra BD (Docker/PostgreSQL).

## 2. Conexion usada

```
postgresql://usuario_lectura:ClaveSegura123@ep-curly-snow-a8psiq7k-pooler.eastus2.azure.neon.tech:5432/neondb?sslmode=require
```

Usuario de solo lectura. Permite SELECT y pg_dump, no permite modificar nada.

## 3. Herramienta de extraccion

Se uso `dblink` (extension nativa de PostgreSQL) que permite hacer SELECT a una BD remota desde nuestra BD local:

```sql
CREATE EXTENSION dblink;

SELECT * FROM dblink(
    'host=... dbname=neondb user=usuario_lectura password=...',
    'SELECT numero_documento, nombre_completo FROM personas LIMIT 5'
) AS t(documento VARCHAR, nombre VARCHAR);
```

## 4. Diferencias entre las dos estructuras

| Aspecto | Ellos (Neon) | Nosotros (Docker) |
|---------|-------------|-------------------|
| PKs | UUID (gen_random_uuid) | INT (SERIAL autoincremental) |
| Personas | 3 tablas: personas + pacientes + personal_medico | 1 tabla: PERSONA (Matricula distingue medico/paciente) |
| Especialidad | Columna VARCHAR en personal_medico | Tabla separada ESPECIALIDAD |
| Zonas | No tienen | Tabla ZONA |
| Diagnosticos | Tabla catalogo (nombre, CIE-10, flags) | Tabla transaccional (descripcion, observaciones, por cita) |
| Recetas | prescripciones (medicamento, dosis, frecuencia separados) | RECETA (Medicamentos y Indicaciones como TEXT) |
| Validaciones | CHECK constraints (estados, tipos) | Sin CHECK, validacion por texto libre |

## 5. Mapeo de tablas

Como supimos que se podian pasar los datos:

### PERSONA (medicos)

Ellos tienen personas + personal_medico separados. Nosotros todo en una tabla.
El JOIN por `id_persona` los une, y `numero_colegiatura` se convierte en nuestra `Matricula`.

```
personas.numero_documento      -> PERSONA.CI
personas.nombre_completo       -> PERSONA.Nombre
personas.fecha_nacimiento      -> PERSONA.Fecha_Nacimiento
personas.genero (M/F/OTRO)     -> PERSONA.Sexo (M/F)
personas.direccion             -> PERSONA.Direccion
personas.telefono              -> PERSONA.Telefono
personal_medico.colegiatura    -> PERSONA.Matricula (NOT NULL = medico)
personal_medico.especialidad   -> PERSONA.ID_Especialidad (via lookup)
```

### PERSONA (pacientes)

Misma logica pero sin Matricula ni Especialidad.

```
personas.numero_documento      -> PERSONA.CI
personas.nombre_completo       -> PERSONA.Nombre
(campos basicos iguales)
NULL                           -> PERSONA.Matricula
NULL                           -> PERSONA.ID_Especialidad
```

### ESPECIALIDAD

Ellos no tienen tabla de especialidades, es un VARCHAR suelto en personal_medico.
Extrajimos los DISTINCT y los insertamos como catalogo.

```sql
SELECT DISTINCT especialidad FROM personal_medico
-- Resultado: 16 especialidades unicas -> insertadas en nuestra tabla ESPECIALIDAD
```

### ZONA

Ellos no tienen zonas. Se creo una zona generica "Zona Migrada" para no violar la FK.

### CITA_MEDICA

Ellos usan `citas` con UUIDs. Nosotros usamos IDs enteros.
La clave fue hacer JOIN para obtener el `numero_documento` del paciente y medico,
y luego buscarlos en nuestra tabla PERSONA por CI.

```
citas.fecha_solicitud::DATE    -> CITA_MEDICA.Fecha_Registro
citas.fecha_cita               -> CITA_MEDICA.Fecha_Cita
citas.hora_cita                -> CITA_MEDICA.Hora
ROW_NUMBER()                   -> CITA_MEDICA.Numero_Turno (generado)
citas.estado                   -> CITA_MEDICA.Estado
(lookup por CI del paciente)   -> CITA_MEDICA.ID_Paciente
(lookup por CI del medico)     -> CITA_MEDICA.ID_Medico
```

### TIPO_DIAGNOSTICO

Ellos tienen `diagnosticos.categoria`. Extrajimos las categorias unicas.

```
diagnosticos.categoria         -> TIPO_DIAGNOSTICO.Categoria
'Diagnostico ' + categoria     -> TIPO_DIAGNOSTICO.Nombre
```

### DIAGNOSTICO y RECETA

Dependen de que las citas ya existan en nuestra BD. Solo se migran si hay coincidencia exacta de paciente + medico + fecha + hora.

```
atenciones.plan_tratamiento    -> DIAGNOSTICO.Descripcion
atenciones.pronostico          -> DIAGNOSTICO.Observaciones
prescripciones.medicamento     -> RECETA.Medicamentos
prescripciones.frecuencia      -> RECETA.Indicaciones
```

## 6. Resultado de la migracion

| Tabla | Propios | Migrados | Total |
|-------|---------|----------|-------|
| ESPECIALIDAD | 15 | 4 | 19 |
| TIPO_DIAGNOSTICO | 25 | 5 | 30 |
| ZONA | 20 | 1 | 21 |
| PERSONA | 5,000 | 6,000 | 11,000 |
| CITA_MEDICA | 20,000 | 87 | 20,087 |
| DIAGNOSTICO | 15,000 | 0 | 15,000 |
| RECETA | 7,440 | 0 | 7,440 |

## 7. Por que migraron pocos diagnosticos y recetas

Los diagnosticos y recetas dependen de una cadena de JOINs: receta -> diagnostico -> cita -> paciente + medico. Para migrar una receta necesitamos que la cita ya exista en nuestra BD con el mismo paciente, medico, fecha y hora exactos. Como los datos son generados aleatoriamente en ambas BDs, las coincidencias son pocas.

## 8. Conclusion

La migracion fue posible porque:

1. **Ambas BDs modelan el mismo dominio** (clinica medica) con tablas equivalentes
2. **El numero de documento (CI)** es el campo comun que permite vincular personas entre ambos sistemas
3. **dblink** permite consultar la BD remota como si fuera una tabla local
4. **Las FKs se resuelven por lookup**: no copiamos UUIDs, buscamos el registro equivalente por CI y asignamos nuestro ID entero

Lo que complica la migracion:

1. **PKs diferentes** (UUID vs SERIAL): no se pueden copiar directo, hay que resolver por campos naturales
2. **Estructura diferente**: ellos separan personas en 3 tablas, nosotros en 1
3. **Campos que no existen**: ellos no tienen zonas ni horarios, nosotros no tenemos facturacion ni ausencias
4. **Datos dependientes**: migrar diagnosticos y recetas requiere que toda la cadena previa ya exista
