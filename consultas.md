# Consultas SQL

## Conexion a la base de datos

```bash
docker compose exec db psql -U clinica_user -d clinica_db
```

## 1. Que area atiende mas pacientes

```sql
SELECT e.Nombre AS especialidad, COUNT(c.ID_Cita) AS total_citas
FROM CITA_MEDICA c
JOIN PERSONA m ON c.ID_Medico = m.ID_Persona
JOIN ESPECIALIDAD e ON m.ID_Especialidad = e.ID_Especialidad
GROUP BY e.Nombre
ORDER BY total_citas DESC;
```

## 2. Que fechas se atienden mas pacientes

```sql
SELECT Fecha_Cita, COUNT(*) AS total_citas
FROM CITA_MEDICA
GROUP BY Fecha_Cita
ORDER BY total_citas DESC;
```

## 3. Que enfermedad se atiende mas

```sql
SELECT td.Nombre AS tipo_diagnostico, td.Categoria, COUNT(d.ID_Diagnostico) AS total
FROM DIAGNOSTICO d
JOIN TIPO_DIAGNOSTICO td ON d.ID_Tipo_Diagnostico = td.ID_Tipo_Diagnostico
GROUP BY td.Nombre, td.Categoria
ORDER BY total DESC;
```
