Импорт в Roblox — новые монстры и склеп (14 ноября 2026)

Что здесь
- Crypt_V2.glb — art/crypt-optimized-v1/Crypt-optimized.glb с цветами вершин в sRGB (Roblox показывает COLOR_0 как есть).
- monsters/*.glb — 72 монстра (12 семейств x 6 образов). Исходники: art/granny-slender-optimized-v1 (Гренни, Дед,
  Слендермен, Слендерина, Мама Слендерины), longmaw-optimized-v1 и mimic-optimized-v1 (*_Idle), hooded-stranger-optimized-v1,
  srp-optimized-v1 (новые паразиты; Nefor -> Punk, Killer -> Assassin).
- monsters/*.json — опорные точки групп (pivots), габариты и число треугольников, в координатах glTF.
- assets.csv — id загруженных ассетов: модели (Key = имя в ReplicatedStorage.ArtModels) и портреты (modal_monster_*).
- qa_sheet.png — проверочный лист: группы конечностей раскрашены.

Как сделано (tools/)
- rigidify.py (Blender): скиннинговую модель ставит в позу Idle (кадр 0; без анимаций — исходная поза), режет меш по
  самой сильной кости вершины на группы игры Body, Head, ArmL, ArmR, LegL, LegR, TendrilL, TendrilR, переводит цвета в
  sRGB и пишет статичный GLB. Многоногие: передняя пара — «руки», задняя — «ноги», средние — тело. Шея входит в голову.
- srgb_static.py (Blender): то же для статичной модели без разрезания (склеп).
- normalize_v5.lua (Studio, Edit): переносит импорт в ArtModels — плоско, опора на земле, лицом в -Z, цвет детали белый,
  атрибуты Attach и Joint_<группа>.
Загрузка через Open Cloud (Studio MCP open_cloud_invoke), затем insert_asset и normalize_v5.lua.

Кладбище (2026-11-15)
- Cemetery_Round.glb — круглая фиолетовая земля кладбища (ArtModels.Cemetery_Round, ассет 103234943750401): плитки,
  сиреневые камни по краю без камней у входа, косточки и травинки. Цвета взяты из старой модели W_Graveyard, в игре
  деталь подкрашивается тем же оттенком (173,145,204). Генератор: tools/cemetery_round.py (Blender), Cemetery_Round.json
  — центр габаритов в координатах glTF для normalize_v5.lua.
