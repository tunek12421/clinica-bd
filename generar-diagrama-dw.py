"""
Genera diagrama ER del esquema estrella del Data Warehouse
"""
from PIL import Image, ImageDraw, ImageFont

W, H = 1200, 700
img = Image.new('RGB', (W, H), '#1e1e2e')
draw = ImageDraw.Draw(img)

try:
    font_title = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 16)
    font_col = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 12)
    font_header = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 13)
    font_label = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", 11)
except:
    font_title = ImageFont.load_default()
    font_col = font_title
    font_header = font_title
    font_label = font_title

# Colors
BG_DIM = '#2d2d44'
BG_FACT = '#3d2d44'
BORDER_DIM = '#7c7cff'
BORDER_FACT = '#ff7c7c'
TEXT = '#e0e0e0'
PK = '#ffd700'
FK = '#7cffb2'
TITLE_BG_DIM = '#4a4a7a'
TITLE_BG_FACT = '#7a4a5a'

def draw_table(x, y, w, title, columns, is_fact=False):
    h = 30 + len(columns) * 22 + 10
    bg = BG_FACT if is_fact else BG_DIM
    border = BORDER_FACT if is_fact else BORDER_DIM
    title_bg = TITLE_BG_FACT if is_fact else TITLE_BG_DIM

    # Shadow
    draw.rounded_rectangle([x+3, y+3, x+w+3, y+h+3], radius=8, fill='#111122')
    # Box
    draw.rounded_rectangle([x, y, x+w, y+h], radius=8, fill=bg, outline=border, width=2)
    # Title bar
    draw.rounded_rectangle([x, y, x+w, y+28], radius=8, fill=title_bg)
    draw.rectangle([x, y+20, x+w, y+28], fill=title_bg)
    draw.text((x + w//2, y + 6), title, fill=TEXT, font=font_header, anchor='mt')
    # Line under title
    draw.line([x+1, y+28, x+w-1, y+28], fill=border, width=1)

    for i, (col, tipo, is_pk, is_fk) in enumerate(columns):
        cy = y + 34 + i * 22
        color = PK if is_pk else (FK if is_fk else TEXT)
        prefix = 'PK ' if is_pk else ('FK ' if is_fk else '   ')
        draw.text((x + 12, cy), prefix, fill=color, font=font_col)
        draw.text((x + 42, cy), col, fill=color, font=font_col)
        draw.text((x + w - 10, cy), tipo, fill='#888899', font=font_label, anchor='rt')

    return x, y, w, h

# --- Tables ---
# dim_sucursal (top left)
x1, y1, w1, h1 = draw_table(30, 50, 250, 'dim_sucursal', [
    ('sucursal_key', 'SERIAL', True, False),
    ('nombre', 'VARCHAR(100)', False, False),
    ('host', 'VARCHAR(200)', False, False),
])

# dim_paciente (top center)
x2, y2, w2, h2 = draw_table(340, 30, 280, 'dim_paciente', [
    ('paciente_key', 'SERIAL', True, False),
    ('sucursal_key', 'INT', False, True),
    ('ci', 'VARCHAR(20)', False, False),
    ('nombre', 'VARCHAR(150)', False, False),
    ('fecha_nacimiento', 'DATE', False, False),
    ('sexo', 'CHAR(1)', False, False),
    ('direccion', 'VARCHAR(255)', False, False),
    ('telefono', 'VARCHAR(20)', False, False),
    ('zona', 'VARCHAR(100)', False, False),
    ('ciudad', 'VARCHAR(100)', False, False),
    ('grupo_origen', 'VARCHAR(10)', False, False),
])

# fact_atenciones (center)
x3, y3, w3, h3 = draw_table(340, 330, 280, 'fact_atenciones', [
    ('atencion_key', 'SERIAL', True, False),
    ('paciente_key', 'INT', False, True),
    ('medico_key', 'INT', False, True),
    ('fecha_cita', 'DATE', False, False),
    ('anio', 'INT', False, False),
    ('mes', 'INT', False, False),
    ('trimestre', 'INT', False, False),
    ('dia_semana', 'VARCHAR(15)', False, False),
    ('estado', 'VARCHAR(50)', False, False),
    ('tipo_diagnostico', 'VARCHAR(100)', False, False),
    ('grupo_origen', 'VARCHAR(10)', False, False),
])

# dim_medico (right)
x4, y4, w4, h4 = draw_table(700, 180, 280, 'dim_medico', [
    ('medico_key', 'SERIAL', True, False),
    ('ci', 'VARCHAR(20)', False, False),
    ('nombre', 'VARCHAR(150)', False, False),
    ('matricula', 'VARCHAR(50)', False, False),
    ('sexo', 'CHAR(1)', False, False),
    ('especialidad', 'VARCHAR(100)', False, False),
    ('zona', 'VARCHAR(100)', False, False),
    ('ciudad', 'VARCHAR(100)', False, False),
    ('grupo_origen', 'VARCHAR(10)', False, False),
])

# --- Relations ---
def draw_relation(x1, y1, x2, y2, label='', color='#7cffb2'):
    draw.line([x1, y1, x2, y2], fill=color, width=2)
    # Arrow head
    import math
    angle = math.atan2(y2-y1, x2-x1)
    ax = x2 - 12*math.cos(angle) + 6*math.sin(angle)
    ay = y2 - 12*math.sin(angle) - 6*math.cos(angle)
    bx = x2 - 12*math.cos(angle) - 6*math.sin(angle)
    by = y2 - 12*math.sin(angle) + 6*math.cos(angle)
    draw.polygon([(x2, y2), (int(ax), int(ay)), (int(bx), int(by))], fill=color)
    if label:
        mx, my = (x1+x2)//2, (y1+y2)//2 - 10
        draw.text((mx, my), label, fill='#aaaacc', font=font_label, anchor='mm')

# dim_sucursal -> dim_paciente (snowflake)
draw_relation(30+250, 50+40, 340, 30+56, 'sucursal_key', '#7c7cff')

# dim_paciente -> fact_atenciones
draw_relation(340+140, 30+h2, 340+100, 330, 'paciente_key')

# dim_medico -> fact_atenciones
draw_relation(700, 180+56, 340+280, 330+56, 'medico_key')

# Title
draw.text((W//2, 12), 'Esquema Estrella - Data Warehouse Clinica', fill='#ffffff', font=font_title, anchor='mt')

# Legend
ly = H - 40
draw.rectangle([20, ly-5, W-20, H-5], fill='#1a1a2a')
draw.text((40, ly), 'PK', fill=PK, font=font_col)
draw.text((70, ly), '= Primary Key', fill='#888899', font=font_label)
draw.text((200, ly), 'FK', fill=FK, font=font_col)
draw.text((230, ly), '= Foreign Key', fill='#888899', font=font_label)
draw.text((390, ly), 'Snowflake parcial: dim_sucursal es subdimension de dim_paciente', fill='#aaaacc', font=font_label)

out = '/home/tunek/Universidad/MATERIAS/bd-clinica/diagrama_dw_estrella.png'
img.save(out, 'PNG')
print(f'Diagrama generado: {out}')
