"""
Genera el informe de la Actividad 7:
Informe del Panel de control para la toma de decisiones
"""
from docx import Document
from docx.shared import Pt, RGBColor
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
run.bold = True
run.font.size = Pt(14)

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('FACULTAD DE INGENIERIA\nCARRERA DE INGENIERIA DE SISTEMAS')
run.font.size = Pt(12)

for _ in range(3):
    doc.add_paragraph()

p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run(
    'INFORME DEL PANEL DE CONTROL\nPARA LA TOMA DE DECISIONES')
run.bold = True
run.font.size = Pt(16)

doc.add_paragraph()
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('Aplicado al Data Warehouse de la Clinica')
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
run.bold = True
run.font.size = Pt(12)

doc.add_page_break()

# ============================================================
# 1. OBJETIVOS
# ============================================================
doc.add_heading('1. OBJETIVOS', level=1)

doc.add_heading('1.1. Objetivo general', level=2)
doc.add_paragraph(
    'Disenar e implementar un panel de control (dashboard) basado en inteligencia de '
    'negocios que permita la toma de decisiones informadas sobre la gestion clinica '
    'y administrativa de las sucursales de la Clinica, utilizando los datos consolidados '
    'en el Data Warehouse.'
)

doc.add_heading('1.2. Objetivos especificos', level=2)
objetivos = [
    'Integrar datos de cuatro fuentes heterogeneas (Grupo 1, Grupo 3, Grupo 4 y Grupo 6) '
    'en un modelo de Data Warehouse bajo esquema estrella.',
    'Identificar indicadores clave de desempeno (KPIs) relevantes para la gestion clinica: '
    'carga laboral, evolucion historica, especialidades saturadas, perfil diagnostico, '
    'distribucion semanal y estado operativo.',
    'Construir consultas analiticas SQL con filtros temporales dinamicos que permitan '
    'comparar el rendimiento entre las 4 sucursales de forma objetiva.',
    'Generar visualizaciones interactivas mediante Metabase que faciliten la interpretacion '
    'de los datos por parte de la gerencia y el personal administrativo.',
    'Elaborar un reporte de decisiones basado en los hallazgos del panel de control, '
    'con recomendaciones accionables para la mejora operativa.',
]
for obj in objetivos:
    p = doc.add_paragraph(obj, style='List Bullet')
    p.runs[0].font.size = Pt(11)

# ============================================================
# 2. ALCANCE
# ============================================================
doc.add_heading('2. ALCANCE', level=1)

doc.add_heading('2.1. Alcance del sistema', level=2)
doc.add_paragraph(
    'El panel de control abarca la totalidad de los datos clinicos integrados en el '
    'Data Warehouse, provenientes de cuatro sucursales con diferentes origenes tecnologicos:'
)
add_table(
    ['Sucursal', 'Fuente', 'Periodo de datos', 'Atenciones'],
    [
        ['Grupo 1', 'Supabase (AWS)', '2021 - 2025', '68,123'],
        ['Grupo 3', 'PostgreSQL local', '2024 - 2026', '15,000'],
        ['Grupo 4', 'Neon (Azure)', '2015 - 2026', '301,112'],
        ['Grupo 6', 'Dump PostgreSQL', '2024 - 2026', '40,134'],
    ]
)
doc.add_paragraph()
doc.add_paragraph(
    'En total, el DW consolida 424,369 atenciones medicas, 426,487 pacientes y '
    '314,668 medicos bajo un esquema estrella unificado.'
)

doc.add_heading('2.2. Alcance del analisis', level=2)
doc.add_paragraph(
    'El analisis se centra en seis dimensiones clave para la toma de decisiones:'
)
dimensiones = [
    'Carga laboral: ratio de atenciones por medico en cada sucursal.',
    'Evolucion historica: volumen de atenciones anuales por sucursal a lo largo del tiempo.',
    'Especialidades saturadas: combinaciones sucursal-especialidad con mayor presion asistencial.',
    'Perfil diagnostico: distribucion de tipos de diagnostico por sucursal.',
    'Distribucion semanal: patrones de demanda por dia de la semana.',
    'Estado operativo: proporcion de atenciones completadas, pendientes, canceladas, etc.',
]
for d in dimensiones:
    p = doc.add_paragraph(d, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_paragraph()
doc.add_paragraph(
    'Las consultas utilizan filtros temporales dinamicos (ultima gestion completa, '
    'gestiones completas) que se actualizan automaticamente conforme se incorporan '
    'nuevos datos al DW, garantizando la vigencia del panel de control.'
)

doc.add_heading('2.3. Limitaciones', level=2)
limitaciones = [
    'Los datos de cada grupo provienen de periodos diferentes, lo que limita la '
    'comparacion directa en terminos absolutos. Se mitiga este sesgo mediante '
    'visualizaciones apiladas al 100% que comparan proporciones.',
    'La calidad y completitud de los datos varia entre grupos, ya que cada uno '
    'registro la informacion de forma independiente con diferentes criterios.',
    'El panel de control no incluye datos financieros ni de costos, por lo que '
    'las recomendaciones se limitan al ambito operativo y asistencial.',
]
for lim in limitaciones:
    p = doc.add_paragraph(lim, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_page_break()

# ============================================================
# 3. DESARROLLO
# ============================================================
doc.add_heading('3. DESARROLLO', level=1)

# --- 3.1 Fuentes ---
doc.add_heading('3.1. Fuentes de extraccion de la informacion', level=2)
doc.add_paragraph(
    'Los datos del Data Warehouse provienen de cuatro fuentes heterogeneas, '
    'cada una correspondiente a un grupo de trabajo que implemento de forma '
    'independiente el sistema operacional de la clinica:'
)
add_table(
    ['Fuente', 'Tecnologia', 'Conexion', 'Tipo de extraccion'],
    [
        ['Grupo 1', 'Supabase (PostgreSQL en AWS)', 'Remota via pooler', 'ETL directo con psql COPY'],
        ['Grupo 3', 'PostgreSQL 17 local', 'localhost:5432', 'ETL directo con psql COPY'],
        ['Grupo 4', 'Neon (PostgreSQL en Azure)', 'Remota via pooler', 'ETL directo con psql COPY'],
        ['Grupo 6', 'Dump SQL (PostgreSQL 17)', 'Importacion local', 'Restauracion de dump + ETL'],
    ]
)
doc.add_paragraph()
doc.add_paragraph(
    'Todas las fuentes comparten el mismo esquema relacional operacional '
    '(PERSONA, CITA_MEDICA, DIAGNOSTICO, TIPO_DIAGNOSTICO, ESPECIALIDAD, ZONA), '
    'lo que permite aplicar un proceso ETL unificado.'
)

# --- 3.2 Transformacion ---
doc.add_heading('3.2. Transformacion de la informacion', level=2)
doc.add_paragraph(
    'El proceso ETL (Extract, Transform, Load) transforma los datos operacionales '
    'en un modelo dimensional optimizado para el analisis:'
)

doc.add_heading('Extraccion', level=3)
doc.add_paragraph(
    'Se extraen los datos de la base operacional (puerto 5432) utilizando '
    'comandos COPY de PostgreSQL, que exportan los resultados de consultas '
    'SQL a archivos CSV temporales. La extraccion aplica las siguientes '
    'transformaciones iniciales:'
)
extracciones = [
    'Clasificacion por grupo de origen: se asigna un identificador (G1, G3, G4, G6) '
    'a cada registro basado en el patron del CI o el rango de ID_Persona.',
    'Separacion de pacientes y medicos: se distinguen por la presencia del campo Matricula.',
    'Derivacion de campos temporales: se calculan anio, mes, trimestre y dia_semana '
    'a partir de la fecha de cita.',
]
for e in extracciones:
    p = doc.add_paragraph(e, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_heading('Transformacion', level=3)
doc.add_paragraph(
    'Los datos extraidos se cargan en una tabla de staging temporal donde se realizan '
    'los JOINs de integridad referencial con las dimensiones del DW:'
)
transformaciones = [
    'Resolucion de claves subrogadas: se reemplazan los CI de paciente y medico por '
    'sus respectivas paciente_key y medico_key del DW.',
    'Asignacion de sucursal: cada paciente se vincula a su sucursal (dim_sucursal) '
    'a traves de la subdimension dim_paciente, formando el snowflake parcial.',
    'Limpieza de texto: se eliminan saltos de linea en campos de descripcion y '
    'observaciones para garantizar la integridad del formato CSV.',
]
for t in transformaciones:
    p = doc.add_paragraph(t, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_heading('Carga', level=3)
doc.add_paragraph(
    'Los datos transformados se insertan en la tabla de hechos fact_atenciones del DW '
    '(puerto 5434) mediante INSERT ... SELECT desde la tabla de staging. El proceso '
    'completo se ejecuta con el script etl-load.sh y tarda aproximadamente 2 minutos '
    'para los 424,369 registros.'
)

doc.add_paragraph()
doc.add_paragraph(
    'El esquema resultante sigue el modelo estrella con snowflake parcial:'
)
add_table(
    ['Tabla', 'Tipo', 'Registros', 'Descripcion'],
    [
        ['dim_sucursal', 'Subdimension', '4', 'Identifica las 4 sucursales (grupos)'],
        ['dim_paciente', 'Dimension', '426,487', 'Datos demograficos, vinculado a sucursal'],
        ['dim_medico', 'Dimension', '314,668', 'Especialidad, matricula, ubicacion'],
        ['fact_atenciones', 'Hechos', '424,369', 'Cada atencion medica con metricas temporales'],
    ]
)

# --- 3.3 Metodos y modelos ---
doc.add_heading('3.3. Metodos y modelos usados', level=2)

doc.add_heading('Modelo dimensional: Esquema estrella', level=3)
doc.add_paragraph(
    'Se utiliza el modelo estrella (Star Schema) propuesto por Kimball, donde la tabla '
    'de hechos fact_atenciones se conecta a tres dimensiones (dim_paciente, dim_medico, '
    'dim_sucursal). La variante snowflake parcial surge porque dim_paciente contiene '
    'una referencia a dim_sucursal, permitiendo segmentar los datos por grupo de origen '
    'sin duplicar informacion.'
)

doc.add_heading('Metodo de analisis: ROLAP', level=3)
doc.add_paragraph(
    'Las consultas del panel de control operan bajo el paradigma ROLAP (Relational OLAP), '
    'donde el analisis multidimensional se realiza directamente mediante consultas SQL '
    'sobre las tablas relacionales del DW. Este enfoque ofrece flexibilidad para crear '
    'nuevas consultas sin necesidad de precalcular cubos, y aprovecha la capacidad de '
    'PostgreSQL para ejecutar agregaciones, JOINs y subconsultas de forma eficiente.'
)

doc.add_heading('Herramienta de visualizacion: Metabase', level=3)
doc.add_paragraph(
    'Metabase es una plataforma de inteligencia de negocios (BI) de codigo abierto que '
    'permite conectarse a bases de datos PostgreSQL, ejecutar consultas nativas SQL y '
    'generar visualizaciones interactivas. Se despliega como contenedor Docker dentro '
    'de la misma red del proyecto, conectandose directamente al DW sin configuraciones '
    'adicionales.'
)

doc.add_heading('Tecnicas de visualizacion aplicadas', level=3)
tecnicas = [
    'Barras agrupadas: para comparar valores absolutos entre sucursales '
    '(carga laboral, evolucion historica).',
    'Barras apiladas al 100%: para comparar distribuciones porcentuales entre '
    'sucursales con volumenes muy diferentes, eliminando el sesgo por escala '
    '(diagnosticos, dias de semana, estados).',
    'Tabla ordenada: para mostrar rankings detallados con multiples indicadores '
    '(especialidades saturadas).',
    'Filtros temporales dinamicos: subconsultas que seleccionan automaticamente '
    'la ultima gestion completa o las gestiones sin datos parciales.',
]
for t in tecnicas:
    p = doc.add_paragraph(t, style='List Bullet')
    p.runs[0].font.size = Pt(11)

doc.add_page_break()

# --- 3.4 Reporte de toma de decisiones ---
doc.add_heading('3.4. Reporte de la toma de decisiones', level=2)
doc.add_paragraph(
    'A continuacion se presentan los hallazgos obtenidos del panel de control '
    'y las decisiones que cada uno sustenta. Los datos corresponden a la gestion '
    '2025 (ultima gestion completa disponible en el DW).'
)

# Hallazgo 1: Carga laboral
doc.add_heading('Hallazgo 1: Desbalance critico en la carga laboral', level=3)
add_table(
    ['Sucursal', 'Atenciones', 'Medicos activos', 'Carga/medico'],
    [
        ['Grupo 6', '19,370', '831', '23.3'],
        ['Grupo 3', '6,845', '500', '13.7'],
        ['Grupo 1', '5,085', '1,032', '4.9'],
        ['Grupo 4', '24,773', '23,747', '1.0'],
    ]
)
doc.add_paragraph()
p = doc.add_paragraph()
rb = p.add_run('Analisis: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Grupo 6 presenta la mayor sobrecarga con 23.3 atenciones por medico, '
    'casi 5 veces mas que Grupo 1 (4.9) y 23 veces mas que Grupo 4 (1.0). '
    'Esto indica que Grupo 6 opera con un numero insuficiente de medicos '
    'para su volumen de demanda, mientras que Grupo 4 tiene una dotacion '
    'de personal significativamente mayor.'
).font.size = Pt(11)

p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Reasignar medicos desde Grupo 4 (con excedente) hacia Grupo 6 y Grupo 3. '
    'Alternativamente, contratar personal adicional para Grupo 6 y evaluar la '
    'redistribucion de pacientes entre sedes para equilibrar la carga.'
).font.size = Pt(11)

# Hallazgo 2: Evolucion historica
doc.add_heading('Hallazgo 2: Incorporacion progresiva de sucursales', level=3)
doc.add_paragraph(
    'El analisis historico revela que Grupo 4 opera desde 2015 con un volumen '
    'constante de ~25,000 atenciones anuales. Grupo 1 se incorporo en 2021 con '
    '~16,000 atenciones/ano. Grupo 3 y Grupo 6 son los mas recientes, iniciando '
    'en 2024. Esta diferencia en antiguedad explica parcialmente las diferencias '
    'de volumen total entre sucursales.'
)
p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Las comparaciones absolutas entre sucursales deben considerar el periodo de '
    'operacion. Para decisiones de inversion, priorizar las sucursales mas nuevas '
    '(Grupo 3 y Grupo 6) que estan en fase de crecimiento y necesitan recursos '
    'para consolidarse.'
).font.size = Pt(11)

# Hallazgo 3: Especialidades saturadas
doc.add_heading('Hallazgo 3: Especialidades con saturacion critica', level=3)
add_table(
    ['Sucursal', 'Especialidad', 'Carga/medico'],
    [
        ['Grupo 6', 'Oncologia', '71.4'],
        ['Grupo 1', 'Urologia', '63.0'],
        ['Grupo 6', 'Urologia', '62.6'],
        ['Grupo 1', 'Neurologia', '62.5'],
        ['Grupo 1', 'Ginecologia', '62.1'],
    ]
)
doc.add_paragraph()
p = doc.add_paragraph()
rb = p.add_run('Analisis: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Oncologia en Grupo 6 lidera la saturacion con 71.4 atenciones por medico, '
    'seguida de Urologia en ambos Grupo 1 y Grupo 6. Estas cifras superan '
    'ampliamente el promedio general, indicando que pocos medicos concentran '
    'una carga desproporcionada en estas especialidades.'
).font.size = Pt(11)

p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Contratar oncologos adicionales para Grupo 6 como prioridad inmediata. '
    'Reforzar Urologia en Grupo 1 y Grupo 6, y Neurologia/Ginecologia en '
    'Grupo 1. Considerar la derivacion de pacientes hacia sedes con menor '
    'carga en estas especialidades.'
).font.size = Pt(11)

# Hallazgo 4: Perfil diagnostico
doc.add_heading('Hallazgo 4: Diferencias en el perfil diagnostico', level=3)
doc.add_paragraph(
    'El analisis porcentual de tipos de diagnostico revela que los tres primeros '
    'tipos (Clinico, Laboratorio e Imagen) concentran las atenciones de todos los '
    'grupos, pero con proporciones diferentes. Grupo 4 domina en diagnosticos '
    'especializados (Diferencial, Presuntivo, Definitivo, Prenatal, Patologico, '
    'Molecular, Genetico, Funcional) que los demas grupos practicamente no registran.'
)
p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Estandarizar la clasificacion de diagnosticos entre sucursales para permitir '
    'una comparacion mas precisa. Evaluar si Grupo 1, 3 y 6 necesitan capacitacion '
    'o equipamiento para ampliar su oferta diagnostica a los tipos especializados '
    'que actualmente solo ofrece Grupo 4.'
).font.size = Pt(11)

# Hallazgo 5: Distribucion semanal
doc.add_heading('Hallazgo 5: Distribucion uniforme de la demanda semanal', level=3)
doc.add_paragraph(
    'El analisis por dia de la semana muestra una distribucion practicamente uniforme '
    'en todas las sucursales: cada dia concentra entre 13% y 15% del total semanal. '
    'No se observan picos significativos en ningun dia especifico, lo que sugiere '
    'que la demanda es constante a lo largo de la semana.'
)
p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Mantener una dotacion de personal uniforme durante todos los dias de la semana. '
    'No se justifica reducir turnos en fines de semana ni reforzar dias especificos, '
    'dado que la demanda es homogenea.'
).font.size = Pt(11)

# Hallazgo 6: Estado operativo
doc.add_heading('Hallazgo 6: Diferencias en la gestion operativa', level=3)
doc.add_paragraph(
    'La distribucion de estados de atencion varia significativamente entre sucursales '
    'en la ultima gestion:'
)
estados = [
    'Grupo 4 presenta una distribucion equilibrada entre Finalizado (25%), '
    'Pendiente (25%), Alta (25%) y Control (25%), indicando un flujo operativo '
    'completo y sistematico.',
    'Grupo 6 concentra el 99% de sus atenciones en estado "Atendida", '
    'sugiriendo que utiliza un sistema de estados simplificado.',
    'Grupo 3 opera con estados "Confirmada" y "Completada" principalmente, '
    'con un volumen significativamente menor en la gestion actual.',
]
for est in estados:
    p = doc.add_paragraph(est, style='List Bullet')
    p.runs[0].font.size = Pt(11)

p = doc.add_paragraph()
rb = p.add_run('Decision: ')
rb.bold = True
rb.font.size = Pt(11)
p.add_run(
    'Estandarizar los estados de atencion entre todas las sucursales, adoptando '
    'el modelo de Grupo 4 (Pendiente -> Atendida -> Finalizado -> Alta/Control) '
    'como referencia. Capacitar al personal de Grupo 6 y Grupo 3 en el uso '
    'correcto de los estados para mejorar la trazabilidad del ciclo de atencion.'
).font.size = Pt(11)

doc.add_paragraph()
add_screenshot_placeholder('Dashboard completo - Panel de Toma de Decisiones en Metabase')

doc.add_page_break()

# ============================================================
# 4. CONCLUSIONES
# ============================================================
doc.add_heading('4. CONCLUSIONES', level=1)

conclusiones = [
    'La inteligencia de negocios aplicada al Data Warehouse de la Clinica permitio '
    'identificar hallazgos concretos y accionables que no serian visibles con reportes '
    'operacionales tradicionales. La consolidacion de datos de 4 fuentes heterogeneas '
    'en un modelo dimensional unificado habilita la comparacion objetiva entre sucursales.',

    'El hallazgo mas critico es el desbalance en la carga laboral: Grupo 6 tiene una '
    'carga 23 veces mayor que Grupo 4 por medico, lo que representa un riesgo operativo '
    'inmediato que requiere intervencion. Las especialidades mas afectadas son Oncologia '
    '(71.4 atenciones/medico) y Urologia (63.0 atenciones/medico).',

    'Las diferencias en el perfil diagnostico y los estados de atencion revelan una falta '
    'de estandarizacion entre sucursales. Grupo 4 ofrece diagnosticos especializados que '
    'los demas grupos no registran, y cada sucursal utiliza los estados de atencion de '
    'forma diferente, dificultando la comparacion directa.',

    'El uso de filtros temporales dinamicos y visualizaciones apiladas al 100% resuelve '
    'el desafio de comparar sucursales con volumenes y periodos de datos muy diferentes, '
    'permitiendo un analisis proporcional justo.',

    'El panel de control implementado en Metabase cumple con los principios de la '
    'inteligencia de negocios: transforma datos crudos en informacion estructurada, '
    'y esta informacion en conocimiento accionable para la toma de decisiones '
    'gerenciales y administrativas.',
]

for texto in conclusiones:
    p = doc.add_paragraph(texto, style='List Bullet')
    p.runs[0].font.size = Pt(11)

# ============================================================
# 5. RECOMENDACIONES
# ============================================================
doc.add_heading('5. RECOMENDACIONES', level=1)

recomendaciones = [
    ('Redistribucion de personal medico',
     'Implementar un plan de redistribucion de medicos entre sucursales, priorizando '
     'Grupo 6 (carga: 23.3) y Grupo 3 (carga: 13.7). Evaluar la posibilidad de '
     'reasignar medicos desde Grupo 4 (carga: 1.0), que cuenta con excedente de personal.'),

    ('Refuerzo de especialidades criticas',
     'Contratar oncologos, urologos y neurologos adicionales para las sucursales con '
     'mayor saturacion. Oncologia en Grupo 6 (71.4 atenciones/medico) requiere atencion '
     'inmediata.'),

    ('Estandarizacion de procesos',
     'Unificar los criterios de clasificacion de diagnosticos y estados de atencion '
     'entre todas las sucursales, utilizando el modelo de Grupo 4 como referencia. '
     'Esto mejorara la comparabilidad de los datos y la trazabilidad del ciclo de atencion.'),

    ('Actualizacion periodica del DW',
     'Establecer un proceso de actualizacion periodica (mensual o trimestral) del '
     'Data Warehouse para mantener vigente el panel de control. Los filtros temporales '
     'dinamicos garantizan que las visualizaciones se adapten automaticamente.'),

    ('Ampliacion del panel de control',
     'Incorporar indicadores financieros (costo por atencion, facturacion por sucursal) '
     'y de satisfaccion del paciente en futuras versiones del dashboard, para complementar '
     'el analisis operativo con la perspectiva economica y de calidad de servicio.'),

    ('Capacitacion del personal',
     'Capacitar al personal administrativo en el uso de Metabase para que puedan consultar '
     'el panel de control de forma autonoma, reduciendo la dependencia del equipo tecnico '
     'para la generacion de reportes.'),
]

for titulo, texto in recomendaciones:
    p = doc.add_paragraph()
    rb = p.add_run(f'{titulo}: ')
    rb.bold = True
    rb.font.size = Pt(11)
    p.add_run(texto).font.size = Pt(11)

# ============================================================
# 6. REFERENCIAS
# ============================================================
doc.add_heading('6. REFERENCIAS', level=1)
refs = [
    'Cepymenews. (2024). Importancia de la inteligencia de negocios, el market '
    'research y el CX. https://cepymenews.es/',
    'Kimball, R., & Ross, M. (2013). The Data Warehouse Toolkit: The Definitive '
    'Guide to Dimensional Modeling (3rd ed.). Wiley.',
    'Metabase. (2024). Metabase Open Source Documentation. '
    'https://www.metabase.com/docs/latest/',
    'PostgreSQL Global Development Group. (2024). PostgreSQL 17 Documentation. '
    'https://www.postgresql.org/docs/17/',
    'Laudon, K. C., & Laudon, J. P. (2020). Management Information Systems: '
    'Managing the Digital Firm (16th ed.). Pearson.',
]
for ref in refs:
    p = doc.add_paragraph(ref, style='List Bullet')
    p.runs[0].font.size = Pt(10)

# ============================================================
# GUARDAR
# ============================================================
out = '/home/tunek/Universidad/MATERIAS/bd-clinica/Informe_Actividad7_PanelControl.docx'
doc.save(out)
print(f'Documento generado: {out}')
