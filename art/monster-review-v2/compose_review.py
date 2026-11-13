"""Compose review boards from actual model renders, with no generated imagery."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
R=Path(__file__).resolve().parent
font='/System/Library/Fonts/Supplemental/Arial.ttf'
def f(size):return ImageFont.truetype(font,size)
def board(title,subtitle,panels,out):
    width=1400
    im=Image.new('RGB',(width,1050),'#141D26')
    d=ImageDraw.Draw(im)
    d.text((38,25),title,font=f(36),fill='#F0EEE8')
    d.text((38,76),subtitle,font=f(21),fill='#B9C6CC')
    for index,(filename,label) in enumerate(panels):
        x=24+index*692
        img=Image.open(R/'previews'/filename).convert('RGB')
        img.thumbnail((668,825))
        im.paste(img,(x+(668-img.width)//2,158))
        d.text((x+20,120),label,font=f(27),fill='#E2C69F' if index else '#C0CBD1')
    d.text((40,1010),'ОТДЕЛЬНОЕ ПРЕВЬЮ • В ИГРУ НЕ ДОБАВЛЕНО',font=f(18),fill='#9DACB4')
    im.save(R/'previews'/out)
board('ПАРАЗИТ — СВЕТЛЕЕ ВСЁ ТЕЛО','Одинаковые свет и ракурс. Форма модели сохранена.',
      [('Parasite_Before.png','Исходная модель'),('Parasite_Proposed.png','Предлагаемый цвет')], 'Parasite_Comparison.png')
board('КОЛЬЦЕВИК — ФОРМА ПО РЕФЕРЕНСАМ','Четыре опоры и исходная стойка. Новая пасть и более светлое тело.',
      [('RingMaw_Source.png','Исходная модель из проекта'),('RingMaw_Proposed.png','Новый вариант')], 'RingMaw_Comparison.png')
board('КОЛЬЦЕВИК — ПРОПОРЦИИ И ПАСТЬ','Толстый ржаво-оранжевый обод, тёмная воронка, зубы в глубине.',
      [('RingMaw_Front.png','Вид спереди'),('RingMaw_MawDetail.png','Устройство пасти')], 'RingMaw_Details.png')

board('КОЛЬЦЕВИК — СТОЙКА НА ЧЕТЫРЁХ КОНЕЧНОСТЯХ','Корпус и опоры сохранены от исходной модели. Изменены цвет и пасть.',
      [('RingMaw_Proposed.png','Три четверти'),('RingMaw_Stance.png','Вид сбоку')], 'RingMaw_StanceReview.png')
