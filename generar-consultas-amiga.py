"""
Genera PDF con 6 consultas alternativas para Metabase + instrucciones de visualización
"""
from reportlab.lib.pagesizes import LETTER
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.colors import HexColor
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Preformatted
from reportlab.lib.units import inch
from reportlab.lib.enums import TA_LEFT, TA_CENTER

out = '/home/tunek/Universidad/MATERIAS/bd-clinica/consultas_metabase_alternativas.pdf'
doc = SimpleDocTemplate(out, pagesize=LETTER, topMargin=0.7*inch, bottomMargin=0.7*inch)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name='TituloConsulta', fontSize=13, leading=16, spaceAfter=6,
                          textColor=HexColor('#1a3a5c'), fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='Subtitulo', fontSize=11, leading=14, spaceAfter=4,
                          textColor=HexColor('#2a5a8c'), fontName='Helvetica-Bold'))
styles.add(ParagraphStyle(name='Instruccion', fontSize=10, leading=13, spaceAfter=3,
                          leftIndent=20, fontName='Helvetica'))
styles.add(ParagraphStyle(name='SQL', fontSize=8.5, leading=11, spaceAfter=6,
                          leftIndent=15, fontName='Courier', backColor=HexColor('#f0f0f0')))
styles.add(ParagraphStyle(name='Titulo', fontSize=16, leading=20, spaceAfter=12,
                          textColor=HexColor('#0a2a4c'), fontName='Helvetica-Bold',
                          alignment=TA_CENTER))
styles.add(ParagraphStyle(name='Descripcion', fontSize=10, leading=13, spaceAfter=8,
                          fontName='Helvetica'))

story = []

story.append(Spacer(1, 30))
story.append(Paragraph('6 Consultas para Metabase — Panel de Toma de Decisiones', styles['Titulo']))
story.append(Paragraph('Instrucciones paso a paso para configurar cada consulta y visualización',
                       ParagraphStyle('sub', parent=styles['Normal'], alignment=TA_CENTER, fontSize=11,
                                     textColor=HexColor('#555555'))))
story.append(Spacer(1, 10))

# Tabla resumen
data = [
    ['#', 'Consulta', 'Tipo gráfico', 'Apilado'],
    ['1', 'Pacientes por sexo y sucursal', 'Barra', 'Apilado 100%'],
    ['2', 'Atenciones por hora del día', 'Línea', 'No'],
    ['3', 'Top especialidades demandadas', 'Barra', 'Apilado normal'],
    ['4', 'Tasa de incumplimiento', 'Barra', 'No'],
    ['5', 'Evolución trimestral', 'Línea', 'No'],
    ['6', 'Procedimientos frecuentes', 'Tabla', '—'],
]
t = Table(data, colWidths=[30, 220, 100, 100])
t.setStyle(TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), HexColor('#1a3a5c')),
    ('TEXTCOLOR', (0, 0), (-1, 0), HexColor('#ffffff')),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, -1), 9),
    ('GRID', (0, 0), (-1, -1), 0.5, HexColor('#cccccc')),
    ('ROWBACKGROUNDS', (0, 1), (-1, -1), [HexColor('#f8f8f8'), HexColor('#ffffff')]),
    ('ALIGN', (0, 0), (-1, -1), 'CENTER'),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('TOPPADDING', (0, 0), (-1, -1), 4),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 4),
]))
story.append(t)
story.append(Spacer(1, 20))

# ============================================================
# CONSULTAS
# ============================================================
consultas = [
    {
        'titulo': 'Consulta 1 — Distribución de pacientes por sexo y sucursal',
        'descripcion': (
            'Compara la proporción de pacientes masculinos y femeninos entre las 4 sucursales. '
            'Permite identificar si alguna sucursal atiende una población con sesgo demográfico '
            'y adaptar servicios (ej: ginecología, urología) según la composición.'
        ),
        'sql': (
            'SELECT\n'
            '    ds.nombre AS sucursal,\n'
            '    dp.sexo,\n'
            '    COUNT(DISTINCT dp.paciente_key) AS total_pacientes\n'
            'FROM dim_paciente dp\n'
            'JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n'
            'GROUP BY ds.nombre, dp.sexo\n'
            'ORDER BY ds.nombre, dp.sexo'
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Barra',
            'Pestaña Datos → Eje-X: sucursal',
            'Agrupar por: sexo (debería aparecer automáticamente)',
            'Eje-Y: total_pacientes',
            'Pestaña Visualización → Apilado: seleccionar "Apilado - 100%"',
            'Guardar con nombre: "Distribución de pacientes por sexo y sucursal"',
        ],
    },
    {
        'titulo': 'Consulta 2 — Atenciones por hora del día — Última gestión completa',
        'descripcion': (
            'Muestra en qué horas del día se concentran más atenciones por sucursal. '
            'Permite optimizar los horarios de atención y la asignación de turnos médicos '
            'según los picos de demanda de cada sede.'
        ),
        'sql': (
            'SELECT\n'
            '    EXTRACT(HOUR FROM fa.hora)::int AS hora_del_dia,\n'
            '    ds.nombre AS sucursal,\n'
            '    COUNT(*) AS total_atenciones\n'
            'FROM fact_atenciones fa\n'
            'JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n'
            'JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n'
            'WHERE fa.hora IS NOT NULL\n'
            '  AND fa.anio = (SELECT MAX(anio) - 1 FROM fact_atenciones)\n'
            'GROUP BY EXTRACT(HOUR FROM fa.hora), ds.nombre\n'
            'ORDER BY hora_del_dia'
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Línea',
            'Pestaña Datos → Eje-X: hora_del_dia',
            'Eje-Y: total_atenciones',
            'Agrupar por: sucursal (cada sucursal será una línea de color diferente)',
            'Pestaña Visualización → Apilado: "No Apilado"',
            'Guardar con nombre: "Atenciones por hora del día — Última gestión completa"',
        ],
    },
    {
        'titulo': 'Consulta 3 — Top especialidades más demandadas — Última gestión completa',
        'descripcion': (
            'Identifica las especialidades médicas con mayor demanda por sucursal. '
            'Permite planificar la contratación de especialistas y la distribución de '
            'recursos según las necesidades reales de cada sede.'
        ),
        'sql': (
            'SELECT\n'
            '    dm.especialidad,\n'
            '    ds.nombre AS sucursal,\n'
            '    COUNT(*) AS total_atenciones\n'
            'FROM fact_atenciones fa\n'
            'JOIN dim_medico dm ON dm.medico_key = fa.medico_key\n'
            'JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n'
            'JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n'
            'WHERE fa.anio = (SELECT MAX(anio) - 1 FROM fact_atenciones)\n'
            'GROUP BY dm.especialidad, ds.nombre\n'
            'ORDER BY total_atenciones DESC\n'
            'LIMIT 20'
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Barra',
            'Pestaña Datos → Eje-X: especialidad',
            'Eje-Y: total_atenciones',
            'Agrupar por: sucursal',
            'Pestaña Visualización → Apilado: seleccionar "Apilar" (apilado normal, NO 100%)',
            'Guardar con nombre: "Top especialidades más demandadas — Última gestión completa"',
        ],
    },
    {
        'titulo': 'Consulta 4 — Tasa de incumplimiento por sucursal',
        'descripcion': (
            'Calcula el porcentaje de citas canceladas o donde el paciente no asistió. '
            'Una tasa alta de incumplimiento indica problemas de gestión de citas que '
            'afectan la productividad de los médicos y la eficiencia operativa.'
        ),
        'sql': (
            "SELECT\n"
            "    ds.nombre AS sucursal,\n"
            "    ROUND(\n"
            "        COUNT(*) FILTER (\n"
            "            WHERE fa.estado IN ('Cancelada', 'No asistió')\n"
            "        )::numeric\n"
            "        / NULLIF(COUNT(*), 0) * 100, 2\n"
            "    ) AS tasa_incumplimiento,\n"
            "    COUNT(*) FILTER (WHERE fa.estado = 'Cancelada')\n"
            "        AS canceladas,\n"
            "    COUNT(*) FILTER (WHERE fa.estado = 'No asistió')\n"
            "        AS no_asistio,\n"
            "    COUNT(*) AS total\n"
            "FROM fact_atenciones fa\n"
            "JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n"
            "JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n"
            "GROUP BY ds.nombre\n"
            "ORDER BY tasa_incumplimiento DESC"
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Barra',
            'Pestaña Datos → Eje-X: sucursal',
            'Eje-Y: tasa_incumplimiento (quitar canceladas, no_asistio y total del eje Y)',
            'Pestaña Visualización → Apilado: "No Apilado"',
            'Activar: "Mostrar valores en puntos de datos" para ver los porcentajes',
            'Guardar con nombre: "Tasa de incumplimiento por sucursal"',
        ],
    },
    {
        'titulo': 'Consulta 5 — Evolución trimestral de atenciones — Últimos 2 años completos',
        'descripcion': (
            'Muestra la tendencia de atenciones por trimestre para cada sucursal '
            'durante los últimos 2 años completos. Permite detectar estacionalidades '
            'y patrones de crecimiento o decrecimiento a nivel trimestral.'
        ),
        'sql': (
            "SELECT\n"
            "    fa.anio || '-T' || fa.trimestre AS periodo,\n"
            "    ds.nombre AS sucursal,\n"
            "    COUNT(*) AS total_atenciones\n"
            "FROM fact_atenciones fa\n"
            "JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n"
            "JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n"
            "WHERE fa.anio >= (SELECT MAX(anio) - 2 FROM fact_atenciones)\n"
            "  AND fa.anio < (SELECT MAX(anio) FROM fact_atenciones)\n"
            "GROUP BY fa.anio, fa.trimestre, ds.nombre\n"
            "ORDER BY fa.anio, fa.trimestre, ds.nombre"
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Línea',
            'Pestaña Datos → Eje-X: periodo',
            'Eje-Y: total_atenciones',
            'Agrupar por: sucursal (cada sucursal será una línea)',
            'Pestaña Visualización → Apilado: "No Apilado"',
            'Guardar con nombre: "Evolución trimestral — Últimos 2 años completos"',
        ],
    },
    {
        'titulo': 'Consulta 6 — Procedimientos más frecuentes por sucursal — Última gestión completa',
        'descripcion': (
            'Lista los tipos de procedimiento más realizados en cada sucursal, '
            'incluyendo el porcentaje que representa cada uno. Permite identificar '
            'el perfil operativo de cada sede y planificar la adquisición de '
            'equipamiento e insumos de forma dirigida.'
        ),
        'sql': (
            "SELECT\n"
            "    ds.nombre AS sucursal,\n"
            "    fa.tipo_procedimiento,\n"
            "    COUNT(*) AS total,\n"
            "    ROUND(\n"
            "        COUNT(*)::numeric /\n"
            "        SUM(COUNT(*)) OVER (PARTITION BY ds.nombre) * 100, 1\n"
            "    ) AS porcentaje\n"
            "FROM fact_atenciones fa\n"
            "JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n"
            "JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n"
            "WHERE fa.tipo_procedimiento IS NOT NULL\n"
            "  AND fa.anio = (SELECT MAX(anio) - 1 FROM fact_atenciones)\n"
            "GROUP BY ds.nombre, fa.tipo_procedimiento\n"
            "ORDER BY ds.nombre, total DESC"
        ),
        'instrucciones': [
            'En Metabase: + Nuevo → Consulta SQL → pegar el SQL → Ejecutar',
            'Clic en Visualización → seleccionar tipo: Tabla',
            'La tabla se muestra automáticamente con las columnas: sucursal, tipo_procedimiento, total, porcentaje',
            'Clic en la cabecera "total" para ordenar descendente',
            'Guardar con nombre: "Procedimientos frecuentes por sucursal — Última gestión completa"',
        ],
    },
]

for c in consultas:
    story.append(Paragraph(c['titulo'], styles['TituloConsulta']))
    story.append(Paragraph(c['descripcion'], styles['Descripcion']))

    story.append(Paragraph('SQL:', styles['Subtitulo']))
    # SQL as preformatted
    for line in c['sql'].split('\n'):
        story.append(Paragraph(line.replace(' ', '&nbsp;').replace('<', '&lt;').replace('>', '&gt;'),
                               styles['SQL']))
    story.append(Spacer(1, 6))

    story.append(Paragraph('Pasos en Metabase:', styles['Subtitulo']))
    for i, inst in enumerate(c['instrucciones'], 1):
        story.append(Paragraph(f'{i}. {inst}', styles['Instruccion']))

    story.append(Spacer(1, 15))

# Nota final
story.append(Spacer(1, 10))
story.append(Paragraph(
    '<b>Nota:</b> Después de guardar las 6 consultas, crear un Dashboard: '
    '+ Nuevo → Dashboard → agregar las 6 consultas guardadas → acomodar y guardar.',
    ParagraphStyle('nota', parent=styles['Normal'], fontSize=10,
                  textColor=HexColor('#666666'), backColor=HexColor('#f5f5f5'),
                  borderPadding=8)
))

doc.build(story)
print(f'PDF generado: {out}')
