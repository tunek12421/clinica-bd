"""
Genera el informe de la Actividad 6:
Preparacion de la herramienta de analisis de datos para graficos de toma de decisiones
"""
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml.ns import qn
from docx.oxml import OxmlElement

doc = Document()

# ============================================================
# ESTILOS
# ============================================================
style = doc.styles['Normal']
style.font.name = 'Calibri'
style.font.size = Pt(11)
style.paragraph_format.space_after = Pt(6)
style.paragraph_format.line_spacing = 1.15

for level in range(1, 4):
    h = doc.styles[f'Heading {level}']
    h.font.color.rgb = RGBColor(0, 0, 0)

def add_table(headers, rows):
    table = doc.add_table(rows=1 + len(rows), cols=len(headers))
    table.style = 'Table Grid'
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    for i, h in enumerate(headers):
        cell = table.rows[0].cells[i]
        cell.text = h
        for p in cell.paragraphs:
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER
            for run in p.runs:
                run.bold = True
                run.font.size = Pt(10)
    for r_idx, row in enumerate(rows):
        for c_idx, val in enumerate(row):
            cell = table.rows[r_idx + 1].cells[c_idx]
            cell.text = str(val)
            if cell.paragraphs[0].runs:
                cell.paragraphs[0].runs[0].font.size = Pt(10)
    return table

def add_code(text):
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Pt(18)
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(3)
    run = p.add_run(text)
    run.font.name = 'Consolas'
    run.font.size = Pt(9)

def add_screenshot_placeholder(label):
    table = doc.add_table(rows=1, cols=1)
    table.style = 'Table Grid'
    cell = table.rows[0].cells[0]
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(f'[ CAPTURA: {label} ]')
    run.italic = True
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(128, 128, 128)
    trPr = table.rows[0]._tr.get_or_add_trPr()
    trHeight = OxmlElement('w:trHeight')
    trHeight.set(qn('w:val'), '1800')
    trPr.append(trHeight)
    doc.add_paragraph()

# ============================================================
# PORTADA
# ============================================================
for _ in range(3):
    doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('UNIVERSIDAD PRIVADA DOMINGO SAVIO')
run.bold = True; run.font.size = Pt(14)

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('FACULTAD DE INGENIERIA\nCARRERA DE INGENIERIA DE SISTEMAS')
run.font.size = Pt(12)

for _ in range(3):
    doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('PREPARACION DE LA HERRAMIENTA DE ANALISIS\nDE DATOS PARA GRAFICOS DE TOMA DE DECISIONES')
run.bold = True; run.font.size = Pt(16)

doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('Aplicada al Data Warehouse de la Clinica')
run.font.size = Pt(12)

for _ in range(2):
    doc.add_paragraph()

for nombre in [
    'Argote Gonzales Marco Ariel',
    'Benavides Arancibia Jorge Enrique',
    'Lujan Arispe Enrique',
    'Lujan Arispe William',
    'Mejillones Iraizos Rebeca',
    'Valencia Vidaurre Marcos Daniel',
    'Villarroel Espinoza Gustavo Ernesto',
]:
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run(nombre)
    run.font.size = Pt(11)

for _ in range(3):
    doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('Cochabamba - Bolivia\n2026')
run.bold = True; run.font.size = Pt(12)

doc.add_page_break()

# ============================================================
# 1. INTRODUCCION
# ============================================================
doc.add_heading('1. INTRODUCCION', level=1)
doc.add_paragraph(
    'El presente informe documenta la preparacion de la herramienta de analisis de datos '
    'seleccionada para la visualizacion y toma de decisiones sobre el Data Warehouse (DW) '
    'de la Clinica. El DW integra datos de tres fuentes heterogeneas (Grupo 1, Grupo 3 y '
    'Grupo 6) bajo un esquema estrella con snowflake parcial, consolidando 123,257 atenciones '
    'medicas, 126,487 pacientes y 14,668 medicos.'
)
doc.add_paragraph(
    'La herramienta seleccionada permite conectarse directamente al DW PostgreSQL, '
    'construir consultas analiticas y generar visualizaciones interactivas que apoyan '
    'la toma de decisiones en el ambito clinico y administrativo.'
)

# ============================================================
# 2. JUSTIFICACION DE LA HERRAMIENTA
# ============================================================
doc.add_heading('2. JUSTIFICACION DE LA HERRAMIENTA: METABASE', level=1)

doc.add_heading('2.1. Que es Metabase?', level=2)
doc.add_paragraph(
    'Metabase es una herramienta de inteligencia de negocios (BI) de codigo abierto que '
    'permite conectarse a bases de datos relacionales, ejecutar consultas analiticas y '
    'generar visualizaciones interactivas sin necesidad de conocimientos avanzados de programacion. '
    'Se despliega como contenedor Docker y expone una interfaz web accesible desde el navegador.'
)

doc.add_heading('2.2. Comparacion con alternativas', level=2)
add_table(
    ['Criterio', 'Metabase', 'Power BI', 'Tableau'],
    [
        ['Sistema operativo', 'Linux, Windows, Mac', 'Solo Windows (nativo)', 'Windows, Mac'],
        ['Costo', 'Gratuito (Open Source)', 'Requiere licencia', 'Requiere licencia'],
        ['Despliegue', 'Docker (local)', 'Instalacion nativa', 'Instalacion nativa'],
        ['Conexion PostgreSQL', 'Nativa y directa', 'Requiere conector', 'Requiere conector'],
        ['Curva de aprendizaje', 'Baja', 'Media', 'Alta'],
        ['Dashboards interactivos', 'Si', 'Si', 'Si'],
        ['Consultas SQL directas', 'Si', 'Limitado', 'Si'],
    ]
)

doc.add_paragraph()
doc.add_heading('2.3. Razones de seleccion', level=2)
razones = [
    'Compatibilidad con Linux: el entorno de desarrollo del equipo utiliza Linux, '
    'donde Power BI no esta disponible de forma nativa.',
    'Integracion directa con PostgreSQL: se conecta al contenedor DW (puerto 5434) '
    'sin configuraciones adicionales.',
    'Despliegue en Docker: se levanta con un unico comando y se integra a la misma '
    'red Docker del proyecto (bd-clinica_default).',
    'Gratuito y open source: no requiere licencias pagas.',
    'Soporte para SQL nativo: permite escribir consultas SQL directamente sobre '
    'las tablas del DW (fact_atenciones, dim_medico, dim_paciente, dim_sucursal).',
    'Dashboards interactivos: agrupa multiples graficos en un panel de control unificado.',
]
for r in razones:
    p = doc.add_paragraph(r, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_paragraph()
add_screenshot_placeholder('Metabase - Vista general de la base de datos DATA WAREHOUSE')

# ============================================================
# 3. MODELADO DE LOS DIAGRAMAS
# ============================================================
doc.add_heading('3. MODELADO DE LOS DIAGRAMAS', level=1)

doc.add_heading('3.1. Esquema del Data Warehouse', level=2)
doc.add_paragraph(
    'El DW utiliza un modelo estrella con snowflake parcial. '
    'Las consultas para los graficos se construyen sobre este esquema:'
)
add_table(
    ['Tabla', 'Tipo', 'Registros', 'Rol en los graficos'],
    [
        ['dim_sucursal', 'Subdimenion', '3', 'Segmentacion por grupo (G1, G3, G6)'],
        ['dim_paciente', 'Dimension', '126,487', 'Datos demograficos de pacientes'],
        ['dim_medico', 'Dimension', '14,668', 'Especialidades y distribucion de medicos'],
        ['fact_atenciones', 'Hechos', '123,257', 'Base de todos los indicadores analiticos'],
    ]
)

doc.add_paragraph()
doc.add_heading('3.2. Diagrama del modelo estrella en Metabase', level=2)
doc.add_paragraph(
    'Metabase detecta automaticamente las relaciones entre tablas (foreign keys) '
    'del esquema estrella, permitiendo navegar entre dimensiones y hechos de forma visual:'
)
add_screenshot_placeholder('Diagrama del modelo en Metabase - relaciones entre tablas')

doc.add_heading('3.3. Estructura del Dashboard', level=2)
doc.add_paragraph(
    'El panel de control agrupa las 6 visualizaciones en un dashboard denominado '
    '"Analitica Clinica - Toma de Decisiones". Cada grafico responde a una pregunta '
    'de negocio orientada a la gestion clinica y administrativa:'
)
add_table(
    ['#', 'Nombre del grafico', 'Tipo', 'Tablas involucradas'],
    [
        ['1', 'Atenciones por especialidad medica', 'Barras', 'fact_atenciones + dim_medico'],
        ['2', 'Distribucion de atenciones por grupo', 'Torta', 'fact_atenciones + dim_sucursal'],
        ['3', 'Tendencia mensual de atenciones', 'Linea', 'fact_atenciones'],
        ['4', 'Top 10 diagnosticos mas frecuentes', 'Barras', 'fact_atenciones'],
        ['5', 'Atenciones por dia de la semana', 'Barras', 'fact_atenciones'],
        ['6', 'Medicos registrados por especialidad', 'Barras', 'dim_medico'],
    ]
)
doc.add_paragraph()
add_screenshot_placeholder('Dashboard completo en Metabase - Panel Analitica Clinica')

doc.add_page_break()

# ============================================================
# 4. LAS 6 CONSULTAS
# ============================================================
doc.add_heading('4. CONSULTAS PARA GRAFICOS DE TOMA DE DECISIONES', level=1)

consultas = [
    {
        'num': '4.1',
        'titulo': 'Atenciones por Especialidad Medica',
        'tipo': 'Barras horizontales',
        'dimension': 'dim_medico (especialidad)',
        'sql': (
            "SELECT dm.especialidad, COUNT(*) AS total_atenciones\n"
            "FROM fact_atenciones fa\n"
            "JOIN dim_medico dm ON dm.medico_key = fa.medico_key\n"
            "GROUP BY dm.especialidad\n"
            "ORDER BY total_atenciones DESC;"
        ),
        'decision': (
            'Identifica que especialidades medicas concentran mayor demanda de atenciones. '
            'Permite a la administracion clinica decidir donde reforzar el personal medico, '
            'ampliar consultorios o priorizar inversion en equipamiento. '
            'Una especialidad con alta demanda y pocos medicos indica una brecha de capacidad.'
        ),
    },
    {
        'num': '4.2',
        'titulo': 'Distribucion de Atenciones por Grupo (Sucursal)',
        'tipo': 'Torta (Pie)',
        'dimension': 'dim_sucursal',
        'sql': (
            "SELECT ds.nombre AS sucursal, COUNT(*) AS total_atenciones\n"
            "FROM fact_atenciones fa\n"
            "JOIN dim_paciente dp ON dp.paciente_key = fa.paciente_key\n"
            "JOIN dim_sucursal ds ON ds.sucursal_key = dp.sucursal_key\n"
            "GROUP BY ds.nombre\n"
            "ORDER BY total_atenciones DESC;"
        ),
        'decision': (
            'Muestra como se distribuyen las atenciones entre las tres fuentes de datos '
            '(Grupo 1, Grupo 3 y Grupo 6). Permite identificar que sucursal genera mayor '
            'volumen de actividad clinica y comparar la contribucion proporcional de cada '
            'una al sistema integrado de informacion.'
        ),
    },
    {
        'num': '4.3',
        'titulo': 'Tendencia Mensual de Atenciones',
        'tipo': 'Linea temporal',
        'dimension': 'fact_atenciones (anio, mes)',
        'sql': (
            "SELECT anio, mes, COUNT(*) AS total_atenciones\n"
            "FROM fact_atenciones\n"
            "GROUP BY anio, mes\n"
            "ORDER BY anio, mes;"
        ),
        'decision': (
            'Revela la evolucion temporal de la demanda clinica. '
            'Permite identificar meses de alta y baja actividad, detectar estacionalidades '
            'y planificar la disponibilidad de personal con anticipacion. '
            'Picos inusuales pueden indicar brotes epidemicos o eventos especiales.'
        ),
    },
    {
        'num': '4.4',
        'titulo': 'Top 10 Diagnosticos Mas Frecuentes',
        'tipo': 'Barras verticales',
        'dimension': 'fact_atenciones (tipo_diagnostico)',
        'sql': (
            "SELECT tipo_diagnostico, COUNT(*) AS total\n"
            "FROM fact_atenciones\n"
            "WHERE tipo_diagnostico IS NOT NULL\n"
            "GROUP BY tipo_diagnostico\n"
            "ORDER BY total DESC\n"
            "LIMIT 10;"
        ),
        'decision': (
            'Identifica las enfermedades y tipos de diagnostico mas recurrentes. '
            'Informacion critica para definir protocolos de atencion prioritarios, '
            'asegurar disponibilidad de medicamentos e insumos, y orientar campanas '
            'de prevencion hacia las patologias mas frecuentes en la poblacion atendida.'
        ),
    },
    {
        'num': '4.5',
        'titulo': 'Atenciones por Dia de la Semana',
        'tipo': 'Barras verticales',
        'dimension': 'fact_atenciones (dia_semana)',
        'sql': (
            "SELECT dia_semana, COUNT(*) AS total_atenciones\n"
            "FROM fact_atenciones\n"
            "GROUP BY dia_semana\n"
            "ORDER BY total_atenciones DESC;"
        ),
        'decision': (
            'Determina que dias de la semana concentran mayor numero de atenciones. '
            'Permite optimizar la distribucion de turnos medicos, asignar mas personal '
            'en los dias de alta demanda y reducir tiempos de espera para los pacientes.'
        ),
    },
    {
        'num': '4.6',
        'titulo': 'Medicos Registrados por Especialidad',
        'tipo': 'Barras horizontales',
        'dimension': 'dim_medico (especialidad)',
        'sql': (
            "SELECT especialidad, COUNT(*) AS total_medicos\n"
            "FROM dim_medico\n"
            "GROUP BY especialidad\n"
            "ORDER BY total_medicos DESC;"
        ),
        'decision': (
            'Muestra la distribucion del personal medico por especialidad. '
            'Cruzado con el grafico de atenciones por especialidad (consulta 4.1), '
            'permite detectar desbalances: especialidades con alta demanda y pocos medicos '
            'indican necesidad de contratacion; con muchos medicos y baja demanda '
            'sugieren redistribucion de recursos humanos.'
        ),
    },
]

for c in consultas:
    doc.add_heading(f'{c["num"]}. {c["titulo"]}', level=2)
    add_table(
        ['Tipo de grafico', 'Dimension principal'],
        [[c['tipo'], c['dimension']]]
    )
    doc.add_paragraph()
    doc.add_paragraph('Consulta SQL:')
    add_code(c['sql'])
    doc.add_paragraph()
    p = doc.add_paragraph()
    rb = p.add_run('Toma de decision: ')
    rb.bold = True
    rb.font.size = Pt(11)
    p.add_run(c['decision']).font.size = Pt(11)
    doc.add_paragraph()
    add_screenshot_placeholder(f'Grafico {c["num"][-1]}: {c["titulo"]} en Metabase')
    doc.add_paragraph()

doc.add_page_break()

# ============================================================
# 5. CONCLUSIONES
# ============================================================
doc.add_heading('5. CONCLUSIONES', level=1)

conclusiones = [
    'Metabase demostro ser una alternativa viable y eficiente a Power BI en entornos Linux, '
    'permitiendo conectarse directamente al DW PostgreSQL mediante Docker sin configuraciones '
    'adicionales ni costos de licencia.',
    'Las 6 consultas identificadas cubren las dimensiones clave del DW (especialidad, sucursal, '
    'tiempo, diagnostico) y responden a preguntas concretas de gestion clinica y administrativa.',
    'La integracion del modelo estrella con Metabase permite explorar los datos de forma '
    'interactiva, combinando las tres fuentes de informacion (Grupo 1, Grupo 3 y Grupo 6) '
    'en un unico panel de control.',
    'El dashboard centraliza los indicadores mas relevantes para la toma de decisiones, '
    'reduciendo el tiempo necesario para obtener informacion estrategica del sistema clinico.',
    'La consulta de tendencia mensual y la distribucion por dia de la semana son especialmente '
    'utiles para la planificacion operativa, mientras que el analisis de especialidades '
    'apoya decisiones de contratacion y asignacion de recursos.',
]

for texto in conclusiones:
    p = doc.add_paragraph(texto, style='List Bullet')
    p.runs[0].font.size = Pt(11)

# ============================================================
# 6. REFERENCIAS
# ============================================================
doc.add_heading('6. REFERENCIAS', level=1)
refs = [
    'Metabase. (2024). Metabase Open Source Documentation. https://www.metabase.com/docs/latest/',
    'PostgreSQL Global Development Group. (2024). PostgreSQL 17 Documentation. https://www.postgresql.org/docs/17/',
    'Kimball, R., & Ross, M. (2013). The Data Warehouse Toolkit (3rd ed.). Wiley.',
    'Cepymenews. (2024). Importancia de la inteligencia de negocios, el market research y el CX. https://cepymenews.es/',
]
for ref in refs:
    p = doc.add_paragraph(ref, style='List Bullet')
    p.runs[0].font.size = Pt(10)

# ============================================================
# GUARDAR
# ============================================================
out = '/home/tunek/Universidad/MATERIAS/bd-clinica/Informe_Actividad6_Metabase.docx'
doc.save(out)
print(f'Documento generado: {out}')
