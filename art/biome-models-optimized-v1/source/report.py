from pathlib import Path
import json,hashlib,zipfile,html
ROOT=Path(__file__).resolve().parents[1];SRC=ROOT.parent/'biome-models-review-v1'
a=json.loads((SRC/'catalog.json').read_text())['assets'];b=json.loads((ROOT/'catalog.json').read_text())['assets']
assert set(a)==set(b)
rows=[]
for name in a:
 for key in ['placement','pivot','front_axis','up_axis','default_collision','biomes']:
  assert a[name][key]==b[name][key],(name,key)
 assert [p['part'] for p in a[name]['parts']]==[p['part'] for p in b[name]['parts']]
 assert [p['offset'] for p in a[name]['parts'] if p['material']=='Neon']==[p['offset'] for p in b[name]['parts'] if p['material']=='Neon']
 delta=max(abs(x-y) for x,y in zip(a[name]['bounds']['size'],b[name]['bounds']['size']))
 assert delta<.04
 rows.append(dict(name=name,before_triangles=a[name]['triangles'],after_triangles=b[name]['triangles'],before_bytes=(SRC/a[name]['file']).stat().st_size,after_bytes=(ROOT/b[name]['file']).stat().st_size,max_bounds_delta_studs=round(delta,4)))
checksums=json.loads((SRC/'checksums.json').read_text())
assert all(hashlib.sha256((SRC/p).read_bytes()).hexdigest()==h for p,h in checksums.items())
assert json.loads((ROOT/'blender-reimport-validation.json').read_text())['status']=='PASS'
before={k:sum(r['before_'+k] for r in rows) for k in ['triangles','bytes']};after={k:sum(r['after_'+k] for r in rows) for k in ['triangles','bytes']}
report=dict(status='PASS',before=before,after=after,reduction_percent={k:round((1-after[k]/before[k])*100,2) for k in before},models=rows,source_files_unchanged=True,icons_untouched=True,game_untouched=True,roblox_loading_time_measured=False)
(ROOT/'optimization-report.json').write_text(json.dumps(report,indent=2))
readme=f'''Оптимизированные модели биомов v1 — отдельная версия для согласования.

34 модели / 38 мешей. Иконки не затрагивались по просьбе пользователя.
Треугольники: {before['triangles']} -> {after['triangles']} (-{report['reduction_percent']['triangles']}%).
Суммарный размер отдельных GLB: {before['bytes']} -> {after['bytes']} байт (-{report['reduction_percent']['bytes']}%).

Удалены только фаски у тонких деталей толщиной до 0,85 stud: рамы, доски,
крепления, декоративные накладки. Модели со светящимися деталями оставлены исходными. Крупные поверхности и силуэты сохранены.
Габариты четырёх предметов изменились не более чем на 0,032 stud.
Имена, pivots, светящиеся части, классы размещения и запрет щупалец на дороге сохранены.
Цвета встроены в GLB; внешних текстур и специальных декодеров сжатия нет.

models/ содержит индивидуальные GLB, catalog.json — размеры и метаданные.
Числовые единицы рассчитаны на studs, Y вверх, лицом в -Z.
При импорте после согласования сверить размер с catalog.json.
Не объединять светящиеся части с корпусом при назначении материалов.
Это декоративные модели: игровой свет и коллизии отдельно настраиваются при интеграции.

Проверки: структура 39 GLB, нормали, индексы, отсутствие нулевых треугольников,
повторный импорт 34 моделей в Blender, габариты, иерархии, метаданные и рендеры.
Контрольные суммы всех файлов исходного пакета совпали: исходники не изменены.
В игру ничего не установлено. Фактическое время загрузки в Roblox не измерено.
Размер импортируемых GLB не равен размеру ассетов после обработки сервером Roblox.

В облегчённом ZIP находятся модели и документация. Рендеры, исходник Blender,
геометрия JSON и воспроизводимые скрипты доступны в полной локальной папке,
но не включены в импортируемый архив, чтобы не дублировать рабочие файлы.
'''
(ROOT/'README.txt').write_text(readme)
titles={'backrooms':'Backrooms','blood_mine':'Кровавая шахта','village':'Заброшенная деревня','city':'Заброшенный город','parasitown':'Паразитаун'}
sections=[]
for key,title in titles.items():
 sections.append(f'<section><h2>{title}</h2><div class="pair"><figure><figcaption>До</figcaption><a href="../{SRC.name}/previews/{key}.png"><img src="../{SRC.name}/previews/{key}.png"></a></figure><figure><figcaption>После</figcaption><a href="previews/{key}.png"><img src="previews/{key}.png"></a></figure></div></section>')
trs=''.join(f'<tr><td>{r["name"]}</td><td>{r["before_triangles"]} → {r["after_triangles"]}</td><td>{r["before_bytes"]/1000:.1f} → {r["after_bytes"]/1000:.1f} КБ</td></tr>' for r in rows)
page='''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Оптимизация моделей биомов</title><style>body{margin:30px auto;padding:0 24px;max-width:1500px;font:16px/1.6 system-ui;background:#f4f3ee;color:#29342f}h1{font-size:38px}section{margin:36px 0}a{color:#316747}.pair{display:grid;grid-template-columns:1fr 1fr;gap:16px}figure{margin:0}img{width:100%;border-radius:8px}figcaption{font-weight:bold}table{border-collapse:collapse;width:100%}td,th{text-align:left;padding:9px;border-bottom:1px solid #ddd}.stats{font-size:23px;font-weight:600}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style><h1>Оптимизация 34 моделей биомов</h1>'''
page+=f'<p class="stats">Треугольники: {before["triangles"]:,} → {after["triangles"]:,} (−{report["reduction_percent"]["triangles"]}%)<br>GLB: {before["bytes"]/1e6:.2f} → {after["bytes"]/1e6:.2f} МБ (−{report["reduction_percent"]["bytes"]}%)</p>'
page+='<p>Убраны мелкие фаски на тонких деталях. В игре ничего не изменено, иконки не затронуты. Проверен повторный импорт в Blender. Фактическое ускорение загрузки в Roblox пока не измерено.</p><p><a href="Biome_Models_Optimized_v1.zip">Скачать облегчённый пакет GLB</a> · <a href="Biomes_Optimized_v1.blend">Blender</a> · <a href="README.txt">Описание</a></p>'
page+=''.join(sections)+'<h2>По моделям</h2><table><tr><th>Модель</th><th>Треугольники</th><th>GLB</th></tr>'+trs+'</table></html>'
(ROOT/'COMPARE.html').write_text(page)
files=list((ROOT/'models').glob('*.glb'))+[ROOT/n for n in ['catalog.json','README.txt','optimization-report.json','validation.json','blender-reimport-validation.json']]
with zipfile.ZipFile(ROOT/'Biome_Models_Optimized_v1.zip','w',zipfile.ZIP_DEFLATED) as z:
 for p in files:z.write(p,p.relative_to(ROOT))
with zipfile.ZipFile(ROOT/'Biome_Models_Optimized_v1.zip') as z:assert z.testzip() is None
print(json.dumps({k:v for k,v in report.items() if k!='models'},indent=2))
print('zip bytes',(ROOT/'Biome_Models_Optimized_v1.zip').stat().st_size)
