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

Дорога (2026-11-15)
- biomes/*.glb — 34 декоративные модели локаций из art/biome-models-optimized-v1/models с цветами вершин, переведёнными
  в sRGB (tools/biome_srgb.py). В Studio лежат в ReplicatedStorage.ArtModels под теми же именами (AC_, AV_, BM_, BR_,
  PT_, SH_), развёрнуты лицом в -Z, опора как в catalog.json; светящиеся части (Light, Flame, OreGlow) — Neon.
  Id ассетов в assets.csv.
- monsters/<Семейство>.glb (Granny, Longmaw, Dredge и др., 12 шт.) — базовые формы без образов для дороги, нарезаны
  тем же rigidify.py из базовых моделей паков (granny-slender/hooded-stranger/longmaw/mimic-optimized-v1,
  srp-monsters-v2, srp-dredge-v1). В ArtModels под именами семейств.

Облегчённые монстры (2026-11-15, телефоны грелись)
- monsters-lite/*.glb — те же 84 модели (72 образа + 12 базовых форм), упрощённые tools/decimate_monsters.py (Blender,
  Decimate Collapse): в среднем 6 909 -> 3 517 треугольников. Мелкие детали (до 150 треугольников) и текстурное лицо
  Незнакомца не трогаются; часть, которая теряет больше 14% площади или 5% габарита (тонкие ноги Длиннорота),
  упрощается мягче. Цвета вершин и имена частей прежние. decimate_report.json — треугольники до и после.
- monsters-lite/*.json — JSON конвертации с габаритами упрощённого меша (опорные точки те же).
- Загружены заново и заменили модели в ArtModels под теми же именами; новые id — в assets.csv.
