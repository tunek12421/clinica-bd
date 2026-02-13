# Documentacion de la Base de Datos - Clinica Medica

## Como usar este documento

Este documento esta dividido en 7 secciones, una por persona del equipo.
Cada seccion es independiente: si alguien se pierde en cualquier punto de la BD,
puede ir directo a la seccion que necesita.

| Seccion | Tema | Persona |
|---------|------|---------|
| 1 | Tablas catalogo (ESPECIALIDAD, TIPO_DIAGNOSTICO, ZONA) | |
| 2 | Tabla PERSONA (pacientes y medicos) | |
| 3 | Agenda medica (HORARIO_MEDICO, CITA_MEDICA) | |
| 4 | Proceso clinico (DIAGNOSTICO, RECETA) | |
| 5 | Relaciones entre tablas (Foreign Keys) | |
| 6 | Generacion de datos de prueba (seed) | |
| 7 | Documentacion interna, vistas y seguridad | |

---

## Seccion 1: Tablas catalogo

Las tablas catalogo guardan datos que **no cambian seguido**. Son listas fijas
que otras tablas referencian. Son las mas simples de la BD.

### ESPECIALIDAD

Guarda las especialidades medicas que existen en la clinica.

```
ID_Especialidad | Nombre
----------------|------------------
1               | Medicina General
2               | Pediatria
3               | Cardiologia
```

- **ID_Especialidad**: Numero unico que identifica la especialidad. Se genera solo (SERIAL).
- **Nombre**: Nombre de la especialidad. VARCHAR(100), no puede ser NULL.

Para que sirve: Cuando se registra un medico, se le asigna una especialidad
de esta tabla. No se escribe "Cardiologia" cada vez, se guarda el numero (FK).

### TIPO_DIAGNOSTICO

Clasifica los diagnosticos medicos por tipo y categoria.

```
ID_Tipo_Diagnostico | Nombre                | Categoria
--------------------|-----------------------|-----------
1                   | Diagnostico Clinico   | Clinico
2                   | Diagnostico por Imagen| Imagen
3                   | Diagnostico de Lab    | Laboratorio
```

- **ID_Tipo_Diagnostico**: Identificador unico autoincremental.
- **Nombre**: Nombre completo del tipo. VARCHAR(100).
- **Categoria**: Agrupacion general. VARCHAR(100).

Para que sirve: Cuando un medico emite un diagnostico, selecciona el tipo
de esta tabla. Permite clasificar y filtrar diagnosticos por categoria.

### ZONA

Zonas geograficas donde viven las personas.

```
ID_Zona | Nombre      | Ciudad
--------|-------------|------------
1       | Equipetrol  | Santa Cruz
2       | Plan 3000   | Santa Cruz
3       | Zona Sur    | La Paz
```

- **ID_Zona**: Identificador unico autoincremental.
- **Nombre**: Nombre de la zona. VARCHAR(100).
- **Ciudad**: Ciudad a la que pertenece. VARCHAR(100).

Para que sirve: Toda persona (paciente o medico) tiene una zona asignada.
Permite saber de donde viene cada persona y hacer estadisticas por zona.

### Que tienen en comun estas 3 tablas

- Son **tablas padre**: otras tablas las referencian, ellas no referencian a nadie.
- Tienen pocos registros (15 especialidades, 25 tipos, 20 zonas).
- Usan SERIAL como PK (el ID se genera solo, no hay que escribirlo).
- Si se borra un registro que esta referenciado, PostgreSQL lo impide (integridad referencial).

---

## Seccion 2: Tabla PERSONA

Es la tabla mas importante de la BD. Guarda **todas** las personas:
pacientes Y medicos en la misma tabla.

### Estructura

```
ID_Persona | CI      | Nombre              | Fecha_Nacimiento | Sexo | Direccion        | Telefono | Matricula  | ID_Zona | ID_Especialidad
-----------|---------|---------------------|------------------|------|------------------|----------|------------|---------|----------------
1          | 1000001 | Juan Garcia Lopez   | 1975-03-15       | M    | Av. Principal #1 | 71234567 | MAT-00001  | 1       | 3
501        | 2000001 | Ana Torres Mendoza  | 1990-08-22       | F    | Calle Sucre #501 | 61234567 | NULL       | 5       | NULL
```

### Columnas

| Columna | Tipo | NULL? | Descripcion |
|---------|------|-------|-------------|
| ID_Persona | SERIAL | No | Se genera solo. Nunca se escribe manualmente. |
| CI | VARCHAR(20) | No | Carnet de identidad. |
| Nombre | VARCHAR(150) | No | Nombre completo. |
| Fecha_Nacimiento | DATE | No | Formato: YYYY-MM-DD. |
| Sexo | CHAR(1) | No | Solo 'M' o 'F'. |
| Direccion | VARCHAR(255) | No | Direccion de domicilio. |
| Telefono | VARCHAR(20) | No | Telefono de contacto. |
| Matricula | VARCHAR(50) | **Si** | Si tiene matricula = es medico. Si es NULL = es paciente. |
| ID_Zona | INT | No | FK -> ZONA. Donde vive la persona. |
| ID_Especialidad | INT | **Si** | FK -> ESPECIALIDAD. Solo medicos. NULL si es paciente. |

### Como distinguir medico de paciente

No hay una columna "tipo". La regla es:

- **Medico**: Matricula tiene valor (ej: "MAT-00001") Y ID_Especialidad tiene valor.
- **Paciente**: Matricula es NULL Y ID_Especialidad es NULL.

```sql
-- Ver solo medicos
SELECT * FROM persona WHERE matricula IS NOT NULL;

-- Ver solo pacientes
SELECT * FROM persona WHERE matricula IS NULL;

-- Contar cuantos hay de cada uno
SELECT
    CASE WHEN matricula IS NOT NULL THEN 'Medico' ELSE 'Paciente' END AS tipo,
    COUNT(*)
FROM persona
GROUP BY tipo;
```

### Por que una sola tabla y no dos?

Porque medicos y pacientes comparten los mismos datos basicos (CI, nombre,
fecha nacimiento, etc.). Separar en dos tablas duplicaria columnas.
Los campos exclusivos de medicos (Matricula, Especialidad) simplemente
son NULL cuando la persona es paciente.

---

## Seccion 3: Agenda medica

Estas dos tablas manejan la disponibilidad de los medicos y las citas con pacientes.

### HORARIO_MEDICO

Define cuando esta disponible cada medico para atender.

```
ID_Horario | Dia_Semana | Hora_Inicio | Hora_Fin | Cupo_Maximo | ID_Persona
-----------|------------|-------------|----------|-------------|----------
1          | 1          | 08:00       | 12:00    | 15          | 1
2          | 3          | 14:00       | 18:00    | 10          | 1
```

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| ID_Horario | SERIAL | Identificador unico. |
| Dia_Semana | INT | 1=Lunes, 2=Martes, 3=Miercoles, 4=Jueves, 5=Viernes. |
| Hora_Inicio | TIME | Hora en que empieza a atender. |
| Hora_Fin | TIME | Hora en que deja de atender. |
| Cupo_Maximo | INT | Maximo de pacientes que puede ver en ese bloque. |
| ID_Persona | INT | FK -> PERSONA. El medico dueño de este horario. |

Un medico puede tener **varios horarios** (uno por dia, o varios el mismo dia).
El cupo maximo sirve para limitar la cantidad de citas que se pueden agendar.

### CITA_MEDICA

Registro de cada cita entre un paciente y un medico.

```
ID_Cita | Fecha_Registro | Fecha_Cita | Hora  | Numero_Turno | Estado     | ID_Paciente | ID_Medico
--------|----------------|------------|-------|--------------|------------|-------------|----------
1       | 2024-03-01     | 2024-03-05 | 08:00 | 1            | Completada | 501         | 1
2       | 2024-03-01     | 2024-03-05 | 08:30 | 2            | Cancelada  | 502         | 1
```

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| ID_Cita | SERIAL | Identificador unico. |
| Fecha_Registro | DATE | Cuando se solicito la cita. |
| Fecha_Cita | DATE | Cuando esta programada la cita. |
| Hora | TIME | Hora de la cita. |
| Numero_Turno | INT | Turno dentro del dia (1ro, 2do, 3ro...). |
| Estado | VARCHAR(50) | Pendiente, Confirmada, Cancelada, Completada, No asistio. |
| ID_Paciente | INT | FK -> PERSONA. El paciente. |
| ID_Medico | INT | FK -> PERSONA. El medico. |

Nota: ID_Paciente e ID_Medico apuntan a la **misma tabla** (PERSONA).
PostgreSQL sabe a quien refiere por el nombre de la FK:
- `fk_cita_paciente` -> el paciente
- `fk_cita_medico` -> el medico

### Flujo de una cita

```
1. Paciente solicita cita  ->  Estado = 'Pendiente'
2. Se confirma             ->  Estado = 'Confirmada'
3. El dia de la cita:
   a. Asiste               ->  Estado = 'Completada'  ->  Se genera DIAGNOSTICO
   b. No asiste            ->  Estado = 'No asistio'
   c. Cancela antes        ->  Estado = 'Cancelada'
```

---

## Seccion 4: Proceso clinico

Despues de que una cita se completa, el medico emite un diagnostico.
Si es necesario, genera una receta.

### DIAGNOSTICO

Resultado medico de una cita.

```
ID_Diagnostico | Descripcion                    | Observaciones       | Tipo_Procedimiento | ID_Cita | ID_Tipo_Diagnostico
---------------|--------------------------------|---------------------|--------------------|---------|--------------------
1              | Paciente presenta sintomas...  | Reposo por 3 dias   | Consulta           | 1       | 1
2              | Resultados de lab normales     | Control en 1 semana | NULL               | 3       | 3
```

| Columna | Tipo | NULL? | Descripcion |
|---------|------|-------|-------------|
| ID_Diagnostico | SERIAL | No | Identificador unico. |
| Descripcion | TEXT | No | Que encontro el medico. |
| Observaciones | TEXT | No | Recomendaciones para el paciente. |
| Tipo_Procedimiento | VARCHAR(100) | **Si** | Solo si se hizo un procedimiento (Cirugia, Ecografia, etc.). NULL si fue solo consulta. |
| ID_Cita | INT | No | FK -> CITA_MEDICA. La cita que genero este diagnostico. |
| ID_Tipo_Diagnostico | INT | No | FK -> TIPO_DIAGNOSTICO. Clasificacion (Clinico, Imagen, etc.). |

Una cita puede tener **varios diagnosticos** (ej: un diagnostico clinico + uno de imagen).

### RECETA

Receta medica que se genera a partir de un diagnostico.

```
ID_Receta | Medicamentos                         | Indicaciones                    | ID_Diagnostico
----------|--------------------------------------|---------------------------------|---------------
1         | Paracetamol 500mg, Ibuprofeno 400mg  | Tomar cada 8 horas por 7 dias   | 1
2         | Amoxicilina 500mg, Omeprazol 20mg    | Tomar cada 12 horas por 5 dias  | 5
```

| Columna | Tipo | Descripcion |
|---------|------|-------------|
| ID_Receta | SERIAL | Identificador unico. |
| Medicamentos | TEXT | Lista de medicamentos recetados. |
| Indicaciones | TEXT | Como tomar los medicamentos. |
| ID_Diagnostico | INT | FK -> DIAGNOSTICO. El diagnostico que origino la receta. |

Un diagnostico puede tener **varias recetas** (ej: una para antibioticos, otra para analgesicos).

### Flujo completo del proceso clinico

```
CITA_MEDICA (Completada)
    |
    +---> DIAGNOSTICO (puede haber varios por cita)
              |
              +---> RECETA (puede haber varias por diagnostico)
```

---

## Seccion 5: Relaciones entre tablas (Foreign Keys)

Las Foreign Keys (FK) son las conexiones entre tablas.
Garantizan que no se pueda referenciar algo que no existe.

### Mapa completo de relaciones

```
ESPECIALIDAD ──────────┐
                       v
ZONA ────────────> PERSONA <──────── (tabla central)
                       |
           ┌───────────┼───────────┐
           v           v           v
    HORARIO_MEDICO  CITA_MEDICA  CITA_MEDICA
                   (ID_Paciente) (ID_Medico)
                       |
                       v
                  DIAGNOSTICO <──── TIPO_DIAGNOSTICO
                       |
                       v
                    RECETA
```

### Lista de todas las FKs

| FK | Tabla | Columna | Apunta a | Significado |
|----|-------|---------|----------|-------------|
| fk_persona_zona | PERSONA | ID_Zona | ZONA | Donde vive |
| fk_persona_especialidad | PERSONA | ID_Especialidad | ESPECIALIDAD | Que especialidad tiene (medicos) |
| fk_horario_persona | HORARIO_MEDICO | ID_Persona | PERSONA | De que medico es el horario |
| fk_cita_paciente | CITA_MEDICA | ID_Paciente | PERSONA | Quien es el paciente |
| fk_cita_medico | CITA_MEDICA | ID_Medico | PERSONA | Quien es el medico |
| fk_diagnostico_cita | DIAGNOSTICO | ID_Cita | CITA_MEDICA | De que cita salio |
| fk_diagnostico_tipo | DIAGNOSTICO | ID_Tipo_Diagnostico | TIPO_DIAGNOSTICO | Que tipo de diagnostico es |
| fk_receta_diagnostico | RECETA | ID_Diagnostico | DIAGNOSTICO | De que diagnostico salio |

### Que pasa si intento romper una FK

```sql
-- Esto FALLA porque no existe la zona 999:
INSERT INTO persona (ci, nombre, fecha_nacimiento, sexo, direccion, telefono, id_zona)
VALUES ('123', 'Test', '2000-01-01', 'M', 'Dir', '777', 999);
-- ERROR: insert or update on table "persona" violates foreign key constraint

-- Esto FALLA porque hay personas que referencian la zona 1:
DELETE FROM zona WHERE id_zona = 1;
-- ERROR: update or delete on table "zona" violates foreign key constraint
```

### Cardinalidad (cuantos de cada lado)

| Relacion | Lectura |
|----------|---------|
| ZONA 1 : N PERSONA | Una zona tiene muchas personas. Una persona tiene una zona. |
| ESPECIALIDAD 1 : N PERSONA | Una especialidad tiene muchos medicos. Un medico tiene una especialidad. |
| PERSONA 1 : N HORARIO_MEDICO | Un medico tiene muchos horarios. Un horario es de un medico. |
| PERSONA 1 : N CITA_MEDICA | Una persona tiene muchas citas (como paciente o como medico). |
| CITA_MEDICA 1 : N DIAGNOSTICO | Una cita puede tener varios diagnosticos. |
| TIPO_DIAGNOSTICO 1 : N DIAGNOSTICO | Un tipo clasifica muchos diagnosticos. |
| DIAGNOSTICO 1 : N RECETA | Un diagnostico puede generar varias recetas. |

---

## Seccion 6: Generacion de datos de prueba

La BD tiene 50,000 registros generados automaticamente. No se insertaron uno por uno.

### Funcion principal: generate_series

Es una funcion nativa de PostgreSQL que genera filas automaticamente.

```sql
-- Genera numeros del 1 al 5:
SELECT * FROM generate_series(1, 5);
-- Resultado: 1, 2, 3, 4, 5

-- Genera 100 personas sin escribir 100 INSERTs:
INSERT INTO tabla (nombre)
SELECT 'Persona ' || i
FROM generate_series(1, 100) AS i;
```

### Otras funciones usadas

| Funcion | Que hace | Ejemplo |
|---------|----------|---------|
| `generate_series(1, N)` | Genera N filas | `generate_series(1, 5000)` genera 5000 personas |
| `random()` | Numero aleatorio entre 0 y 1 | `random() * 10000` da un numero entre 0 y 10000 |
| `unnest(ARRAY[...])` | Convierte un array en filas | `unnest(ARRAY['a','b','c'])` da 3 filas |
| `LPAD(texto, largo, relleno)` | Rellena con ceros a la izquierda | `LPAD('42', 5, '0')` da '00042' |
| `array_length(arr, 1)` | Largo de un array | Para ciclar sobre arrays con modulo (%) |

### Como se generaron los nombres

Se usan dos arrays (nombres y apellidos) y se combinan con el operador modulo (%).

```sql
-- Arrays de nombres y apellidos
nombres := ARRAY['Juan','Maria','Carlos','Ana',...];
apellidos := ARRAY['Garcia','Rodriguez','Martinez',...];

-- Para cada i de 1 a 5000, se combinan:
nombres[1 + (i % 50)] || ' ' || apellidos[1 + (i % 40)]
-- i=1 -> 'Maria Rodriguez'
-- i=2 -> 'Carlos Martinez'
-- etc.
```

El operador `%` (modulo) hace que los indices ciclen:
si hay 50 nombres, el nombre 51 vuelve al primero.

### Distribucion de los 50,000 registros

| Tabla | Registros | Como se generaron |
|-------|-----------|-------------------|
| ESPECIALIDAD | 15 | Array fijo con `unnest` |
| TIPO_DIAGNOSTICO | 25 | Array fijo con `unnest` |
| ZONA | 20 | Array + `generate_series` para ciudades |
| PERSONA | 5,000 | `generate_series(1, 500)` medicos + `generate_series(1, 4500)` pacientes |
| HORARIO_MEDICO | 2,500 | `generate_series(1, 2500)` con dias y horas calculados |
| CITA_MEDICA | 20,000 | `generate_series(1, 20000)` con fechas aleatorias |
| DIAGNOSTICO | 15,000 | `generate_series(1, 15000)` con descripciones ciclicas |
| RECETA | 7,440 | `generate_series(1, 7440)` con medicamentos combinados |
| **TOTAL** | **50,000** | |

### SERIAL: por que no escribimos IDs

Todas las PKs son `SERIAL`. Esto significa que PostgreSQL genera el numero solo:

```sql
-- NO hacemos esto:
INSERT INTO zona (id_zona, nombre, ciudad) VALUES (1, 'Norte', 'SCZ');

-- Hacemos esto (sin ID):
INSERT INTO zona (nombre, ciudad) VALUES ('Norte', 'SCZ');
-- PostgreSQL asigna id_zona = 1 automaticamente
-- El siguiente INSERT sera id_zona = 2, y asi...
```

---

## Seccion 7: Documentacion interna, vistas y seguridad

### Documentacion dentro de la BD

Toda la documentacion vive dentro de PostgreSQL. No hay archivos externos.
Se usa `COMMENT ON` que es un comando SQL estandar.

```sql
-- Documentar una tabla:
COMMENT ON TABLE persona IS 'Tabla unificada de personas...';

-- Documentar una columna:
COMMENT ON COLUMN persona.matricula IS 'Matricula del medico. NULL si es paciente';

-- Documentar una FK:
COMMENT ON CONSTRAINT fk_persona_zona ON persona IS 'Zona donde vive la persona';
```

Para ver los comentarios:
- `\dt+` muestra tablas con descripcion
- `\d+ persona` muestra columnas con descripcion

### Vistas de documentacion

Son tablas virtuales (no guardan datos, ejecutan una consulta).
Cualquier usuario puede consultarlas.

| Vista | Para que sirve | Como usarla |
|-------|----------------|-------------|
| `v_ayuda` | Punto de entrada. Muestra que vistas existen y como usarlas. | `SELECT * FROM v_ayuda;` |
| `v_resumen` | Panorama general: tablas, descripcion, cantidad de columnas y registros. | `SELECT * FROM v_resumen;` |
| `v_documentacion` | Detalle de cada columna de cada tabla. | `SELECT * FROM v_documentacion WHERE tabla = 'persona';` |
| `v_relaciones` | Mapa de Foreign Keys con descripcion. | `SELECT * FROM v_relaciones;` |
| `v_estadisticas` | Conteo de registros por tabla. | `SELECT * FROM v_estadisticas;` |

Flujo recomendado:
```
v_ayuda  ->  v_resumen  ->  v_documentacion (por tabla)  ->  v_relaciones
```

### De que estan hechas las vistas

Las vistas consultan los **catalogos del sistema** de PostgreSQL:

| Catalogo | Que contiene |
|----------|-------------|
| `information_schema.tables` | Lista de tablas |
| `information_schema.columns` | Lista de columnas con tipos |
| `pg_class` | Metadata de tablas (tamaño, registros) |
| `pg_constraint` | Foreign keys y constraints |
| `pg_description` | Los comentarios que pusimos con COMMENT ON |
| `col_description()` | Funcion que lee el comentario de una columna |
| `obj_description()` | Funcion que lee el comentario de un objeto |

### Seguridad: usuario de solo lectura

La BD tiene dos usuarios:

| Usuario | Password | Permisos |
|---------|----------|----------|
| `clinica_user` | `clinica_pass` | SUPERUSER. Puede hacer todo. |
| `lector` | `lector123` | Solo SELECT. No puede insertar, modificar ni borrar. |

Como se creo el usuario lector:

```sql
-- Crear el rol con password
CREATE ROLE lector WITH LOGIN PASSWORD 'lector123';

-- Darle permiso de conectarse
GRANT CONNECT ON DATABASE clinica_db TO lector;

-- Darle permiso de leer el schema
GRANT USAGE ON SCHEMA public TO lector;

-- Darle SELECT en todas las tablas existentes
GRANT SELECT ON ALL TABLES IN SCHEMA public TO lector;

-- Darle SELECT en tablas que se creen en el futuro
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO lector;
```

### Que puede y que NO puede hacer el usuario lector

| Accion | Permitido? |
|--------|-----------|
| `SELECT * FROM persona` | Si |
| `SELECT * FROM v_ayuda` | Si |
| `\dt+`, `\d+ tabla` | Si |
| `INSERT INTO persona ...` | No - permission denied |
| `UPDATE persona SET ...` | No - permission denied |
| `DELETE FROM persona ...` | No - permission denied |
| `DROP TABLE persona` | No - must be owner |
| `CREATE TABLE ...` | No - permission denied |
| Ver nombres de usuarios (`pg_roles`) | Si (es publico en PostgreSQL) |
| Ver passwords (`pg_shadow`) | No - permission denied |

### Cadena de conexion para compartir

```
postgresql://lector:lector123@<IP_DEL_HOST>:5432/clinica_db
```

### Infraestructura: Docker

La BD corre en un contenedor Docker con PostgreSQL 17.

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: clinica_user
      POSTGRES_PASSWORD: clinica_pass
      POSTGRES_DB: clinica_db
    ports:
      - "5432:5432"    # Expone el puerto a la red
    volumes:
      - pgdata:/var/lib/postgresql/data          # Datos persistentes
      - ./init-scripts:/docker-entrypoint-initdb.d  # Scripts de inicio
```

Los scripts en `init-scripts/` se ejecutan en orden alfabetico **solo la primera vez**
que se crea el volumen:

| Archivo | Que hace |
|---------|----------|
| `01-schema.sql` | Crea las 8 tablas con sus FKs |
| `02-seed.sql` | Inserta los 50,000 registros de prueba |
| `03-readonly-user.sql` | Crea el usuario lector |
| `04-comments.sql` | Agrega comentarios y crea las vistas de documentacion |

Comandos basicos de Docker:
```bash
docker compose up -d      # Levantar la BD
docker compose down        # Apagar (mantiene datos)
docker compose down -v     # Apagar y borrar datos (reinicia todo)
docker compose logs db     # Ver logs
```
