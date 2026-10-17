---
type: Reference
title: "Исследование: путь производства персонажа"
description: "Вторая часть отчёта агента 2026-10-17 об облике персонажа: пути производства (концепт-арт локально, ИИ-3D, Rive, художник) с ценами, сроками и правами, пошаговый план, источники S1–S70. Ключевые утверждения сверены; выжимка — в product/look-and-feel."
status: draft
tags: [research, character, production]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-17T12:59:50Z
stale_after: 2027-04-17T00:00:00Z
---

> Вторая часть отчёта; первая — облик, анимации и брифы: [Character design](character-design.md).

# Персонаж Ally: путь производства

## 4. Пути производства: сравнение

### 4.1. Сводная таблица

Цифры без ссылок — моя оценка `[оценка]`, остальные — по источникам из 4.2–4.6.

| Путь | Качество | Кто делает и сколько труда | Деньги | Срок | Где работает | Права для платной версии | Нагрузка на телефон |
|---|---|---|---|---|---|---|---|
| (d) Концепт-арт на Mac | хорошие эскизы; это не анимируемый ассет | агент пишет промпты и генерирует; родитель ставит программу; дочь выбирает | $0 | 1–2 вечера | локально | у моделей Apache-2.0 нет ограничений на выход (S61–S63); но чистая ИИ-картинка в США не охраняется (S29) | — |
| (a1) ИИ-3D в облаке → Blender → RealityKit | меш за минуты, анимация без опыта выходит «любительской» | родитель или агент: 40–80 ч у умелого любителя, у новичка в 2–3 раза больше | $20–90: месяц тарифа Pro и Auto-Rig Pro | 2–6 недель по вечерам | облако (Meshy, Tripo, Rodin), Blender — локально | только на платных тарифах (S34–S36) | средняя: GPU на 3D, 10–50 МБ текстур |
| (a2) ИИ-3D локально → Blender → RealityKit | меш хуже облачного; у Hunyuan на Mac текстуры строятся по видам всего 256 px | как (a1) и ещё полдня–день на настройку портов | $0–50 | как (a1) | локально, 15–30 ГБ весов | TRELLIS.2 — MIT, но порт тянет ограниченные зависимости (S38); у Hunyuan3D — территориальный запрет (S37) | средняя |
| (a3) 3D из примитивов: агент собирает скриптом в Blender | «виниловая игрушка»: просто, но топология чистая | агент: 1–3 дня | $0 | дни | локально | целиком наши | средняя |
| (b1) Rive, нанятый аниматор | высокое для 2.5D; плавно и интерактивно | художник: 30–60 ч; агент встраивает; родитель нанимает и принимает | $1,5–4,5 тыс. | 3–6 недель | редактор Rive работает через облачный аккаунт `[оценка]`; рантайм — офлайн | по договору о передаче прав | низкая |
| (b2) Rive своими силами | среднее: родитель не иллюстратор | родитель: 30–80 ч на обучение и работу | Cadet — $108 в год (S54) | 1–2 месяца по вечерам | как (b1) | целиком наши | низкая |
| (b3) Готовый Rive-файл из сообщества | персонаж чужой | агент: часы | $0 | день | — | CC BY: можно с указанием автора, но персонаж не уникален (S55) | годится для замера |
| (c) 3D-художник под ключ | высокое | художник; родитель нанимает; агент пишет бриф и встраивает | $2–6 тыс. | 4–8 недель | — | по договору | средняя |
| (c') Готовые 3D-клипы (HEVC с альфой) — способ показа для (a) и (c) | лучший рендер | агент рендерит и кодирует | сверху $0 | ещё несколько дней | локально | — | низкая `[оценка]`: это видео через AVPlayer (S51); но переходы только на стыках петель, липсинка нет |

### 4.2. (a) ИИ image-to-3D → чистка → риг → анимация → USDZ или клипы

**Генераторы**

| Генератор | Где работает | Цена | Mac | Права на результат |
|---|---|---|---|---|
| **Meshy** | облако | **Free:** 100–200 кредитов в месяц (в источниках самой Meshy цифры расходятся). **Pro:** $20 в месяц. **Расход (API, meshy-7.1):** Image-to-3D — 20–30 кредитов, ремеш — 5, авториг — 0–5, анимация — 3 (S34) | — | **Free:** CC BY 4.0, указывать Meshy обязательно. **Платный:** «you own all assets you create» (S34) |
| **Tripo** | облако | **Free:** 200 кредитов в месяц. **Professional:** 3000 кредитов в месяц, до 200 моделей (S35). Около $20 в месяц, агрегаторы расходятся (S35 `[?]`) | — | **Free:** публично. Блог Tripo говорит о CC BY 4.0, а справка Tripo со ссылкой на п. 5.2.1 условий — что на выходы бесплатных пользователей все права у Tripo. **Платные тарифы:** права у пользователя (S35) |
| **Rodin (Hyper3D)** | облако | **Free:** $0, кредит — $1,5. **Creator:** $24 в месяц при оплате за год, $30 помесячно, ~60 моделей. **Business:** $96 / $120, ~416 моделей (S36) | — | **Free:** «Public gallery publishing». **Creator:** «Unlimited export and any use». В FAQ: у платных тарифов права шире (S36) |
| **Hunyuan3D-2.1** (Tencent, открытые веса) | локально | $0 | Для Mac не поставлялся. **Порт сообщества на M4 Pro 24 ГБ:** меш — 344 с, PBR-текстура — 512 с при пресете «Safe» (6 видов по 256 px); загрузка ~30 ГБ (S37 `[замер, автор порта]`) | Tencent не претендует на выходы. Но лицензия не действует в ЕС, Великобритании и Южной Корее и запрещает использовать и показывать выходы вне «Территории» (S37) — платному приложению в этих витринах она не подходит. Hunyuan3D 3.0, по сообщениям, доступен только через облачный API (S37 `[?]`) |
| **TRELLIS.2** (Microsoft, 4B) | локально | $0 | Официально — только Linux и NVIDIA с памятью от 24 ГБ (S38). **Порт trellis-mac на M4 Pro 24 ГБ:** ~5 мин 13 с, из них ~1 мин 45 с — загрузка; меш на 400K+ вершин с PBR-текстурами. Рекомендует от 24 ГБ памяти, ~15 ГБ весов (S38 `[замер, автор порта]`). На нашем MacBook Air M5 32 ГБ, вероятно, 6–12 мин `[оценка]` | Модель и код — MIT (S38). Порт тянет закрытые (gated) модели: DINOv3 под лицензией Meta и RMBG-2.0 под некоммерческой CC BY-NC 4.0 (S38 `[?]`). Для платной версии фон вырезать самим и сверить лицензии |
| **Stable Fast 3D / SPAR3D** (Stability) | локально | $0 | MPS — экспериментально. **SF3D:** проверен на M1 Max 64 ГБ; при памяти меньше 32 ГБ советуют CPU; ~6 ГБ VRAM. **SPAR3D:** macOS 15.2+, проверен на M4 Max 36 ГБ, 10,5 ГБ VRAM (S39) | Stability AI Community License: бесплатно, в том числе коммерчески, пока выручка меньше $1 млн в год (S39) |

**Качество** `[оценка]`: облачные Rodin, Tripo и Meshy — лучше всех; TRELLIS.2 и Hunyuan3D-2.1 — примерно наравне; SPAR3D хуже, SF3D — ещё хуже. Для простого круглого стилизованного персонажа разница меньше, чем кажется. Все генераторы выдают плотную треугольную сетку с «запечённым» в текстуру светом, и её всё равно чинить.

**Чистка и ретопология**
- **Meshy Remesh:** квадовая топология, целевой полигонаж — от 100 до 300 000, стоит 5 кредитов (S34).
- **SF3D:** встроенный ремеш в квады на основе Instant Meshes (S39).
- **Blender:** встроенные Voxel Remesh и QuadriFlow (S45).
- **Лицо** `[оценка]`: мимике нужны кольца рёбер вокруг глаз и рта. Автоматический ремеш их не строит, поэтому лицо ретопологизируют руками или собирают из отдельных деталей.
- **Цвет** `[оценка]`: пастельного персонажа проще перекрасить плоскими материалами, чем вычищать из ИИ-текстуры запечённый свет.

**Риг четвероногого с крыльями и лицом**
- **Mixamo** ригует только гуманоидов, а крылья и хвосты могут сломать авториг (S42). **AccuRIG** — только двуногих, и четвероногих в нём не планируют (S43). Оба не подходят.
- **Авториг Meshy** берёт гуманоидов и четвероногих, но у четвероногих меньше готовых анимаций (S34). **Tripo rig v2** поддерживает семь типов существ, включая четвероногих (S35). Ни один не соберёт сразу хобот, крылья и мимику `[оценка]`.
- **Rigify** — бесплатный, встроен в Blender. Готовые мета-риги: Basic Quadruped, Cat, Wolf, Horse, Shark; птичьего нет (S41). Хобот, уши и крылья — дополнительные цепочки костей `[оценка]`.
- **Auto-Rig Pro:** полный пакет — $50, ядро — $25. Риги для двуногих и четвероногих, лицевой риг, экспорт FBX и glTF с пресетами под Unity, Unreal и Godot, Blender 2.93–5.1 (S40 `[вендор]`).
- **Лицо — три варианта** `[оценка]`:
  1. **Shape keys** — моргание, улыбка, рот «а» и «о», брови. Они экспортируются в блендшейпы USD, а в RealityKit ими управляет `BlendShapeWeightsComponent` (iOS 18+) (S48). Инженер Apple советует включать Shape Keys в экспорт USD из Blender 4.2 (S48).
  2. **Лицо текстурой:** глаза и рот — кадры атласа, которые переключает код. Надёжно и хорошо читается.
  3. **Глаза-шары** и веки на костях.

**Анимация и экспорт**
- Экспортёр USD в Blender пишет арматуры как скелеты USD, а shape keys — как блендшейпы. Чтобы получить `.usdz`, достаточно сменить расширение файла (S44).
- RealityKit проигрывает анимации из `availableAnimations` с плавным переходом `transitionDuration` (S49). Может ли один USDZ нести несколько клипов, на форуме Apple выясняют до сих пор (S49), — на проверку стоит заложить время `[оценка]`.
- С WWDC 2025 SceneKit только поддерживается, Apple ведёт разработчиков к RealityKit (S50 `[?]`). Новый код — на RealityKit.
- **Агент в Blender.** MCP-сервер mcp-for-blender (MIT, ~31 тыс. звёзд) даёт LLM управлять Blender (S46). Агент может собрать персонажа из примитивов, сделать shape keys и процедурные циклы (дыхание, взмахи), выгрузить результат. Актёрскую игру персонажа он не заменит `[оценка]`.
- **Заранее отрисованные клипы.** HEVC с альфой играет на iOS 13+ через AVPlayer и AVPlayerLayer с прозрачным фоном. У SwiftUI `VideoPlayer` фон непрозрачный, поэтому нужна своя обёртка над UIView (S51).
- **Ещё вариант 3D — Spline.** Нативный рантайм на Metal для SwiftUI (iOS 16+, чип A13+). Файл `.splineswift` лежит в ресурсах приложения и работает без интернета; через API доступны события, свойства и переходы (S53). Для персонажа с ригом и мимикой он, вероятно, слабее связки Blender + RealityKit — надо проверять `[оценка]`.
- **Бонус:** по 3D-модели можно напечатать фигурку подруги для дочери `[оценка]`.

### 4.3. (b) Rive — 2D/2.5D-вектор с машиной состояний

**Как работает дизайнер** `[оценка, по документации]`:
1. рисует вектор в режиме Design;
2. в режиме Animate строит кости и сетки и делает клипы;
3. в State Machine связывает клипы с входами (bool, number, trigger) и настраивает смешивание.

**Рантайм.** На iOS входы ставятся из кода через `RiveViewModel.setInput` и `triggerInput`, а новый механизм управления — Data Binding (S57). Рантайм rive-ios — MIT, версия 6.28.1 от 2026-10-08, проект живой (S57).

**Мягкий «объём».** Растушёвка вектора (vector feathering, 2025) даёт мягкие тени, свечение и свет без размытия (S56). Так 2.5D выглядит как мягкая игрушка.

**Цена инструмента.**
- С 20 октября 2025 года экспорт в рантайм есть только на платных тарифах. Уже выгруженные файлы работают всегда, платы за рантайм нет (S54).
- Cadet — $17 за место в месяц или $108 за место в год, до трёх мест. Voyager — $32 в месяц при оплате за год или $49 помесячно (S54 `[вендор]`).
- Если файл делает нанятый аниматор, экспорт идёт с его тарифа.

**Готовые файлы.** Файлы сообщества и маркетплейса Rive лицензированы под CC BY (S55). Для прототипа и замера они годятся (с указанием автора), но своим персонажем не станут.

**Цены аниматоров.**
- На Contra: $75 в час, минимум 10 часов. Интерактивный компонент обычно занимает 10–25 часов. Проект — от $750 и примерно 2 недель. Фонемный липсинк — надбавка $500–2000. Помесячный ретейнер — от $4000 за ≤40 часов (S58 `[вендор: объявления исполнителей]`).
- Медианная ставка аниматора на Upwork — $20–38 в час, без отдельной статистики по Rive (S58).
- Наш объём — 30–60 часов, то есть $1,5–4,5 тыс. `[оценка]`. Липсинк по громкости проще фонемного `[оценка]`.

**Требования к исполнителю** `[оценка]`:
- все ассеты встроены в `.riv`, ничего не грузится из сети;
- входы — по контракту из 3.3;
- слои рта и моргания работают параллельно с телом;
- заказчику — исходник или доступ к рабочему файлу;
- финальную графику рисует человек, ИИ — только референс.

### 4.4. (c) 3D-художник на заказ

**Рынок** `[вендор: объявления]`:
- Fiverr: входные цены на моделинг и риг — от $20–80 (S59).
- Freelancehunt: исполнитель называет «персонаж — $100–300, риг — от $100» (S59).
- Dribbble: пакет «скульпт, текстуры, риг и анимация» — $3000 за 3 недели (S59).
- Риг: стандартный персонаж — $100–120 (CadCrowd); лицевой риг — $300–1000 базовый и $1000–5000+ детальный (Animost) (S47).

**Наш объём** — модель, нестандартный риг (хобот, уши, крылья), мимика на блендшейпах, 10–12 клипов и проверка USDZ. Это $2–6 тыс. и 4–8 недель `[оценка]`. Исполнители из СНГ дешевле, и платить им из РФ проще (4.6) `[оценка]`.

**Что передать исполнителю:**
- этот бриф;
- выбранные картинки и развороты;
- список анимаций (3.1);
- контракт входов (3.3);
- меш из пути (a), если он уже есть, — как черновик формы.

### 4.5. (d) Концепт-арт локально на Mac

Наш Mac — MacBook Air M5, 32 ГБ памяти, macOS 27.0.1, свободно 188 ГБ. uv и Homebrew уже стоят (проверено 2026-10-17).

**Модели**

| Модель | Лицензия | Размер и скорость | Где запускать | Зачем |
|---|---|---|---|---|
| **FLUX.2 [klein] 4B** (январь 2026) | Apache-2.0 (S61) | ~15 ГБ весов, 4 шага. На M1 Max с `-q 4` при 1024×1024 — 6,8 с на шаг (S60 `[вендор]`); на M5 — примерно 15–40 с на картинку `[оценка]` | mflux, Draw Things | основная: быстрая, умеет редактировать по референсу — развороты и эмоции |
| **Z-Image-Turbo** (Alibaba Tongyi, ноябрь 2025, 6B) | Apache-2.0 (S62) | 9 шагов. На M1 Max с `-q 4` — 10,7 с на шаг (S60); на M5 — примерно 45–120 с на картинку `[оценка]` | mflux, Draw Things | качество и реализм |
| FLUX.1 [schnell] (2024, 12B) | Apache-2.0 (S63) | ~34 ГБ, 2–4 шага; mflux называет FLUX.1 устаревшей (S60) | mflux, Draw Things | запасная |
| SDXL | CreativeML Open RAIL++-M: коммерческое использование с ограничениями (S65) | легче; огромная экосистема LoRA, но у LoRA свои лицензии | Draw Things | не нужна |
| FLUX.2 [klein] 9B | FLUX Non-Commercial (S61) | — | — | **не брать** для платной версии |
| Qwen-Image 2.1 (сентябрь 2026) | Qwen Research License, некоммерческая (S64 `[?]`) | ~78 с на M5 Max (S60) | mflux | **не брать** |
| FLUX 3 Image Klein (октябрь 2026) | FLUX Kommunity: коммерческие выходы разрешены при выручке до $5 млн (S60) | ~105 с на M4 Pro (S60) | mflux | можно, но модель новая и тяжелее |

- **Скорость на M5.** По данным Apple, MLX на M5 генерирует картинку 1024×1024 моделью FLUX-dev-4bit более чем в 3,8 раза быстрее, чем на M4 (S67 `[вендор]`). Draw Things заявляет ускорение до 4,6 раза на M5 с нейроускорителями (S66 `[вендор]`).
- **Нагрев.** MacBook Air охлаждается без вентилятора, и на длинных сериях генераций возможен троттлинг `[оценка]`.

**Установка, вариант А: Draw Things (без командной строки)**
1. В Mac App Store найти «Draw Things: Offline AI Art» и нажать «Получить». Приложение бесплатное, генерирует локально, без интернета и подписок. Облачные вычисления в нём необязательны — их не включаем (S66).
2. В приложении выбрать модель FLUX.2 [klein] 4B или Z-Image Turbo и один раз скачать. Поддержка обеих моделей заявлена в описании (S66).
3. Настройки: размер 1024×1024; шагов — 4 для klein и 9 для Z-Image Turbo; seed фиксированный, чтобы получать вариации. Названия пунктов меню могут отличаться — сверять по приложению.

**Установка, вариант Б: mflux (агент может вести сам).** Лицензия MIT, версия 0.23.0 от 2026-10-16 (S60).

```sh
# uv уже есть: /opt/homebrew/bin/uv
uv tool install --upgrade mflux

# Концепты на FLUX.2 [klein] 4B (Apache-2.0); первая загрузка ~15 ГБ
mflux-generate-flux2 --model flux2-klein-4b --steps 4 --seed 1 \
  --width 1024 --height 1024 -q 8 --prompt "<промпт из раздела 2>"

# То же на Z-Image-Turbo (Apache-2.0)
mflux-generate-z-image-turbo --steps 9 --seed 1 \
  --width 1024 --height 1024 -q 8 --prompt "<промпт>"

# Разворот и лист эмоций по выбранной картинке (редактирование с референсом)
mflux-generate-flux2-edit --model flux2-klein-4b --image-paths chosen.png --steps 4 --seed 1 \
  --prompt "Character turnaround sheet of the same character: front, three-quarter, side and back views, neutral pose, same colors and proportions, plain white background"

mflux-generate-flux2-edit --model flux2-klein-4b --image-paths chosen.png --steps 4 --seed 2 \
  --prompt "Expression sheet of the same character, six headshots: laughing, listening with ears up, thinking and looking up, surprised, sleepy yawning, waving hello; same style and colors, white background"

# Запасная: FLUX.1 [schnell] (Apache-2.0, ~34 ГБ)
mflux-generate --model schnell --steps 2 --seed 2 -q 8 --width 1024 --height 1024 --prompt "<промпт>"
```

- Флаги взяты из README mflux (S60).
- Если модель на Hugging Face закрыта соглашением, его нужно принять на странице модели и выполнить `hf auth login` (S60).
- Картинки, промпты и seed хранить вне репозитория. Данных ребёнка в них нет, но и в канон они не входят.

### 4.6. Лицензии и права

| Что | В платном приложении | Условие |
|---|---|---|
| Meshy Free | формально можно, с указанием Meshy (CC BY 4.0) (S34) | модель публична: любой может взять «вашего» персонажа, поэтому для маскота — нет `[оценка]` |
| Meshy, платный тариф | да | «you own all assets» (S34) |
| Tripo Free | нет | источники Tripo противоречат друг другу: CC BY или все права у Tripo по п. 5.2.1 (S35) |
| Tripo, платный тариф | да | права у пользователя (S35) |
| Rodin Free | неясно | публикация в публичной галерее (S36) |
| Rodin Creator и выше | да | «any use» (S36) |
| Hunyuan3D-2.1 | только без ЕС, Великобритании и Южной Кореи | выходы запрещено показывать вне Территории (S37) |
| TRELLIS.2 | модель — да (MIT) | зависимости Mac-порта (RMBG-2.0 — некоммерческая, DINOv3) сверить (S38) |
| SF3D, SPAR3D | да, пока выручка меньше $1 млн | Community License (S39) |
| FLUX.2 [klein] 4B, Z-Image-Turbo, FLUX.1 [schnell] | да | Apache-2.0 (S61–S63) |
| FLUX.2 [klein] 9B, Qwen-Image 2.1 | нет | некоммерческие лицензии (S61, S64) |
| Файлы сообщества Rive | с указанием автора | CC BY, персонаж не уникален (S55) |
| Нанятый художник | да | письменная передача исключительного права (S69) |

**Авторское право на ИИ-картинки**
- **США.**
  - Бюро авторского права (январь 2025): выход ИИ охраняется, только если человек определил достаточно выразительных элементов. Это заметный человеческий вклад, творческая компоновка или переработка; одних промптов мало (S29).
  - 2 марта 2026 года Верховный суд отказался пересматривать дело Thaler v. Perlmutter, и требование автора-человека осталось в силе (S30).
- **Россия.**
  - Суды видят в нейросети инструмент. Автор по ГК — гражданин, чьим творческим трудом создано произведение, ст. 1257 (S31).
  - Девятый арбитражный апелляционный суд в апреле 2024 года (дело А40-200471/2023) признал объектом авторского права ролик, сделанный с дипфейком, — благодаря человеческой работе над ним (S31).
  - Прямой практики по картинкам из нейросети, по данным обзора, нет (S31).
- **Вывод** `[оценка, не юридическая консультация]`:
  - чистая ИИ-картинка может оказаться вовсе не охраняемой;
  - в платной версии финального персонажа должен нарисовать или смоделировать человек, а права — перейти по договору об отчуждении исключительного права (ГК РФ, ст. 1234) (S69);
  - имя и образ стоит закрепить товарным знаком.
- **App Store, правило 5.2.1:** нельзя без разрешения использовать чужие товарные знаки и защищённые произведения; приложение подаёт тот, кто владеет правами или получил лицензию (S32).

**Чек-лист оригинальности** `[оценка]`
1. Летает на крыльях, а не на ушах (Дамбо, Cinnamoroll).
2. Уши маленькие, палитра не серая.
3. Нет цирковых атрибутов и бантика на ухе.
4. Нет сочетания «розовый слон на синем».
5. В промптах нет названий студий и имён художников.
6. Выбранный концепт прогнан через обратный поиск по картинке (Google Lens, Яндекс Картинки).
7. Имя проверено по базам товарных знаков (S33).

**Оплата из России.** Зарубежные сервисы — Meshy, Tripo, Rodin, Rive, Contra — обычно оплачивают иностранной или виртуальной картой либо через посредников, у каждого способа свои комиссии и риски (S68). Это довод в пользу локальных инструментов и исполнителей, которым можно платить в рублях `[оценка]`.

---

## 5. Пошаговый план (рекомендуемый путь)

Кто делает: **[родитель]**, **[дочь]**, **[агент]**, **[художник]**; шаги, за которые нужно платить, — **[платно]**.

**Этап 0. Решения — сегодня**
1. **[родитель]** Прочитать TL;DR и выбрать: Rive в 2.5D (рекомендую) или настоящее 3D.
2. **[родитель]** Разрешить установить Draw Things или mflux и скачать ~15 ГБ весов.

**Этап 1. Концепты — 1–2 вечера, $0**
1. **[родитель]** — или **[агент]** с его разрешения — поставить mflux (`uv tool install --upgrade mflux`) или Draw Things.
2. **[агент]** Сделать по 8–12 генераций на каждый из четырёх концептов: стиль один, seed фиксированные. Отобрать по две лучшие. Для каждой — вариант «3D-игрушка» и вариант «2.5D-вектор».
3. **[дочь + родитель]** Выбор парами (2.7): сначала концепт, потом вариант, потом имя (2.6).
4. **[агент]** По выбранной картинке сделать разворот и лист эмоций (редактирование в FLUX.2 klein). Собрать бриф на 1–2 страницы: образ, палитра, анимации (3.1), контракт входов (3.3), требования к исполнителю (4.3).
5. **[агент]** Проверить оригинальность по чек-листу (4.6).
6. **[родитель]** Если платная версия реальна — проверить имя по базам товарных знаков.

**Этап 2. Спайк: плейсхолдер и замер** — поставкой по контуру `delivery/`, одна рисковая правка на установку (П25).
1. **[агент]** Собрать три пробы показа на телефоне:
   - Rive с готовым персонажем из сообщества (CC BY, S55);
   - RealityKit с персонажем из примитивов, собранным скриптом в Blender (два клипа и один блендшейп);
   - петля HEVC с альфой.
2. **[агент]** Замерить каждую пробу рядом с работающей Gemma 4 E4B: токены в секунду с рендером и без, кадры, память, нагрев за 10 минут — по гейту из 3.5. **[родитель]** ставит сборку на телефон. Каждый замер записывает версию iOS, версию рантайма и хэш модели (П26).
3. **[агент]** Написать ADR «как рисовать персонажа» и внести его в `look-and-feel.md`. **[родитель]** подтверждает решение.

**Этап 3. Производство в Rive — 3–6 недель**
1. **[родитель]** Найти Rive-аниматора на Contra, в сообществе Rive или на FL.ru. В портфолио должны быть машины состояний и липсинк.
2. **[родитель] [платно]** Дать пробное задание: ожидание, моргание и «слушает». Стоит $150–400 `[оценка]`.
3. **[родитель] [платно]** Заключить договор. Цена фиксированная, оплата по этапам. Договор передаёт исключительное право и исходник. В нём же — встроенные ассеты и графика, нарисованная человеком.
4. **[художник]** Работает по этапам:
   - M1 — вектор по выбранному концепту;
   - M2 — риг, ожидание, «слушает», «думает»;
   - M3 — «говорит» (рот управляется входом `mouthOpen`), привет, прощание;
   - M4 — радость, удивление, касание, сон, полировка.
5. **[агент]** После каждого этапа:
   - встраивает `.riv` через RiveRuntime (SPM);
   - подключает входы к оркестратору;
   - добавляет проверку контракта входов при старте;
   - подаёт огибающую громкости во вход `mouthOpen`;
   - замеряет всё на телефоне.

   **[дочь]** смотрит и реагирует. Этап принят, только если замер на телефоне проходит.
6. **[агент]** Обновить OKF: в `look-and-feel.md` вписать пути ассета и контракта в `implementation:`, затем обновить `log.md` и индекс.

**Если выбрано настоящее 3D.** Вместо Rive-аниматора на шагах 1–4 — 3D-художник (4.4). Контракт входов тот же. Показ — RealityKit, а если замер покажет, что GPU нагружается слишком сильно, — готовые клипы.

**Если хочется сделать самим (путь a):**
1. **[родитель] [платно]** Купить месяц Tripo или Meshy Pro (~$20), чтобы получить права на выход.
2. Сгенерировать модель по развороту (image-to-3D). У Meshy можно подать несколько картинок сразу (S34).
3. Сделать ремеш и перекрасить материалы.
4. Собрать риг в Rigify или Auto-Rig Pro (**[платно]**, $50).
5. Сделать shape keys лица и клипы, экспортировать в USDZ и проверить в RealityKit.

Механическую часть агент берёт на себя через mcp-for-blender (S46). Без художника — 40–80+ часов `[оценка]`.

**Бюджет** `[оценка]`

| Вариант | Стоимость |
|---|---|
| Концепты | $0 |
| Рекомендуемый путь (Rive) | $1,5–4,5 тыс.; плюс $108 в год, если родитель хочет сам править `.riv` |
| 3D под ключ | $2–6 тыс. |
| Самим (путь a) | $20–90 плюс время |

**Бонус** `[оценка]`: по выбранному концепту ИИ-3D может сделать модель для печати фигурки — подарок дочери при любом пути.

---

## 6. Источники

**Детское восприятие и анимация**
- S1. Borgi et al., 2014. Baby schema in human and animal faces induces cuteness perception and gaze allocation in children. *Frontiers in Psychology*, 5:411. https://frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2014.00411/text
- S2. Glocker et al., 2009. Baby Schema in Infant Faces Induces Cuteness Perception and Motivation for Caretaking in Adults. *Ethology*. https://www.cceb.upenn.edu/csa/assets/user-content/documents/BabySchemainInfantFacesInducesCutenessPerceptionandMotivationforCaretakinginAdults.pdf
- S3. LoBue & DeLoache, 2011. Pretty in pink. https://bps.org.uk/research-digest/what-age-do-girls-prefer-pink ; https://www.researchwithrutgers.com/en/publications/pretty-in-pink-the-early-development-of-gender-stereotyped-colour/
- S4. Brink, Gray & Wellman, 2019. Creepiness Creeps In: Uncanny Valley Feelings Are Acquired in Childhood. *Child Development* 90(4). https://deepblue.lib.umich.edu/bitstream/handle/2027.42/150519/cdev12999_am.pdf?sequence=1
- S5. Cantor. Children's Fright Responses to Television and Films. https://www.kidsfirst.org/articles-info/fright.htm ; пересказ книги: https://rarestkindofbest.com/2011/07/30/what-scares-your-child/
- S6. Wilson, Hoffner & Cantor. Children's perceptions of the effectiveness of techniques to reduce fear (вынужденный выбор снимает склонность отвечать «да»). https://iro.uiowa.edu/esploro/outputs/journalArticle/Childrens-perceptions-of-the-effectiveness-of/9984105918302771
- S7. Mitchell, Francke & Eng, 2007. Illustrative Rendering in Team Fortress 2 (NPAR). https://www.cs.princeton.edu/courses/archive/fall07/cos597B/papers/mitchell-team-fortress.pdf ; слайды: https://cdn.fastly.steamstatic.com/apps/valve/2007/NPAR07_IllustrativeRenderingInTeamFortress2_Slides.pdf
- S8. Язык форм в дизайне персонажей. https://dreamfarmstudios.com/shape-language-in-character-design/ ; https://binus.ac.id/bandung/dkv/2025/11/04/character-design-101-turning-simple-shapes-into-personality/
- S9. Twelve basic principles of animation. https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation
- S10. Cozmo, анимация Карлоса Баэны (Pixar). https://www.fortune.com/2016/06/27/anki-pixar-dreamworks-robot-games ; https://www.engadget.com/2016-10-14-anki-cozmo-robot.html
- S11. Park, Gelsomini, Lee & Breazeal, 2017. Telling Stories to Robots: The Effect of Backchanneling on a Child's Storytelling (HRI). https://robots.media.mit.edu/wp-content/uploads/sites/7/2017/01/park2017hri-backchannel.pdf
- S12. Andrist, Tan, Gleicher & Mutlu, 2014. Conversational Gaze Aversion for Humanlike Robots (HRI). https://peopleandrobots.wisc.edu/publications/conversational-gaze-aversion-for-humanlike-robots-inproceedings/
- S13. Anthony et al. — касания детей на сенсорных экранах. https://lisa-anthony.com/wp-content/uploads/2013/04/anthony-et-al-jpuc2013.pdf ; Chen et al., ICMI 2020 (4–7 лет): https://init.cise.ufl.edu/wp-content/uploads/sites/378/2017/03/chen-et-al-ICMI2020.pdf
- S14. WCAG 2.1 — контраст нетекстовых элементов и относительная яркость. https://www.w3.org/WAI/WCAG21/Understanding/non-text-contrast.html ; https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
- S15. Duolingo — визем-пайплайн персонажей. https://blog.duolingo.com/world-character-visemes ; кейс Rive: https://rive.app/blog/duolingo-s-ai-powered-video-call-brings-lily-to-life
- S16. SupertonicTTS (arXiv 2503.23108): длительность на уровне фразы, cross-attention вместо выравнивателя. https://arxiv.org/abs/2503.23108v2

**Оригинальность и имена**
- S17. Pink Elephants on Parade (Dumbo, 1941). https://en.wikipedia.org/wiki/Pink_Elephants_on_Parade
- S18. Seeing pink elephants. https://en.wikipedia.org/wiki/Seeing_pink_elephants
- S19. Cinnamoroll (Sanrio). https://bornlicensing.com/license/cinnamoroll
- S20. Товарные знаки Delirium (Huyghe), решение WIPO. https://www.wipo.int/amc/en/domains/decisions/html/2007/dnu2007-0003.html ; https://en.wikipedia.org/wiki/Huyghe_Brewery
- S21. Плюшевый слоник с крыльями Dreamsicles «Angel Hugs», 1998 (объявление на eBay). https://www.ebay.de/itm/317311193332
- S22. Hello Kitty. https://en.wikipedia.org/wiki/Hello_Kitty
- S23. Персонажи «Смешариков» (Нюша, Совунья, Дракоша). https://t-j.ru/smeshariki-best-hero/ ; https://cyclowiki.org/wiki/%D0%92%D1%82%D0%BE%D1%80%D0%BE%D1%81%D1%82%D0%B5%D0%BF%D0%B5%D0%BD%D0%BD%D1%8B%D0%B5_%D0%BF%D0%B5%D1%80%D1%81%D0%BE%D0%BD%D0%B0%D0%B6%D0%B8_%C2%AB%D0%A1%D0%BC%D0%B5%D1%88%D0%B0%D1%80%D0%B8%D0%BA%D0%BE%D0%B2%C2%BB
- S24. Аксолотль в Minecraft. https://minecraft.wiki/w/Axolotl
- S25. Wooper (Pokémon). https://bulbapedia.bulbagarden.net/wiki/Wooper_(Pok%C3%A9mon)
- S26. Беззубик и Spyro. https://en.wikipedia.org/wiki/Toothless_(How_to_Train_Your_Dragon) ; https://en.wikipedia.org/wiki/Spyro_(character)
- S27. Голосовые помощники: Алиса — https://alice.yandex.ru ; Маруся — https://marusia.mail.ru ; Салют (Сбер, Афина, Джой) — https://salute.sber.ru
- S28. Возрастные нормы звукопроизношения. https://ds101.centerstart.ru/sites/ds101.centerstart.ru/files/archive/%D0%9D%D0%BE%D1%80%D0%BC%D1%8B%20%D0%BF%D0%BE%D1%8F%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F%20%D0%B7%D0%B2%D1%83%D0%BA%D0%BE%D0%B2%20%D1%80%D0%B5%D1%87%D0%B8.pdf ; https://riamo.ru/news/zdravoohranenie/logoped-podmoskovja-rasskazala-o-normah-pojavlenija-zvukov-v-rechi-rebenka/

**Право**
- S29. Бюро авторского права США, отчёт об ИИ, часть 2 (29.01.2025). https://copyrightalliance.org/ai-report-part-2-copyrightability/ ; https://www.hoganlovells.com/en/publications/us-copyright-office-issues-report-on-copyrightability-of-ai-assisted-and-generated-works
- S30. Thaler v. Perlmutter: Верховный суд отказал в пересмотре (02.03.2026). https://www.bakerdonelson.com/supreme-court-denies-certiorari-in-thaler-v-perlmutter-ai-cannot-be-an-author-under-the-copyright-act ; https://www.jonesday.com/de/insights/2026/03/jones-day-talks-women-in-ip--supreme-court-denies-review-of-thaler-v-perlmutter-ai-authorship-questions-remain
- S31. Россия: права на контент от нейросетей, дело А40-200471/2023. https://harant.ru/blog/urist-term/avtorskie-prava-na-kontent-sozdannyj-nejrosetyami-problemy-i-perspektivy/ ; https://companies.rbc.ru/news/sZfxks5HSp/ii-i-avtorskoe-pravo-komu-prinadlezhat-prava-na-nejrokontent/ ; https://ppt.ru/columns/rosco/sud-otkazal-v-zashchite-avtorskikh-prav-na-izobrazheniya-sozdannye-neyrosetyu
- S32. App Store Review Guidelines, 5.2 Intellectual Property. https://developer.apple.com/app-store/review/guidelines/#intellectual-property ; пример применения: https://developer.apple.com/forums/thread/697240
- S33. Базы товарных знаков: WIPO — https://branddb.wipo.int ; ФИПС — https://fips.ru/registers-web/ ; USPTO — https://tmsearch.uspto.gov

**Генераторы 3D**
- S34. Meshy. Коммерческое использование: https://intercom.help/meshy/en/articles/16102098-can-i-use-meshy-assets-commercially ; FAQ: https://docs.meshy.ai/faq ; тарифы: https://meshy.ai/pricing ; расход кредитов в API: https://docs.meshy.ai/en/api/pricing ; ремеш: https://docs.meshy.ai/en/api/remesh ; риг: https://docs.meshy.ai/en/webapp/guides/3d-model/rigging ; анимации четвероногих: https://www.meshy.ai/ja/tutorials/character-auto-rigging-workflow ; несколько картинок на входе: https://docs.meshy.ai/en/api/multi-image-to-3d
- S35. Tripo. Права: https://www.tripo3d.ai/help/privacy-policy/how-to-use-tripo-models-commercially ; https://www.tripo3d.ai/blog/commercial-use-ai-3d-models ; тарифы: https://www.tripo3d.ai/help/billing/which-tripo-ai-plan-is-right-for-me ; риг: https://developers.tripo3d.com/en/models/rig ; агрегаторы: https://costbench.com/software/ai-3d-generation/tripo-ai/ ; https://pricingsaas.com/companies/tripo3d
- S36. Rodin (Hyper3D), тарифы (страница прочитана 2026-10-17). https://hyper3d.ai/pricing
- S37. Hunyuan3D-2.1. Лицензия: https://github.com/Tencent-Hunyuan/Hunyuan3D-2.1/blob/main/LICENSE ; порт для Mac: https://github.com/VladimirTalyzin/hunyuan3d-2.1-mac-rocm ; о 3.0: https://toolnavs.com/ko/article/275-hunyuan3d-30-is-coming-ai-triple-accuracy-and-15363-resolution-3d-dit-reconstruc
- S38. TRELLIS.2: https://github.com/microsoft/TRELLIS.2 ; https://huggingface.co/microsoft/TRELLIS.2-4B ; порт для Mac: https://github.com/shivampkumar/trellis-mac ; лицензии зависимостей: https://lilting.ch/en/articles/trellis2-apple-silicon-mps-cuda-free
- S39. Stable Fast 3D: https://github.com/Stability-AI/stable-fast-3d ; SPAR3D: https://github.com/Stability-AI/stable-point-aware-3d ; лицензия Stability: https://stability.ai/license ; https://huggingface.co/stabilityai/stable-fast-3d

**Blender, риг, Apple**
- S40. Auto-Rig Pro (Superhive). https://superhivemarket.com/products/auto-rig-pro
- S41. Rigify, базовое использование. https://docs.blender.org/manual/en/dev/addons/rigify/basics.html
- S42. Mixamo FAQ. https://helpx.adobe.com/creative-cloud/faq/mixamo-faq.html
- S43. AccuRIG и животные (форум Reallusion). https://forum.reallusion.com/523069/Animals
- S44. Blender — экспорт USD. https://docs.blender.org/manual/en/4.1/files/import_export/usd.html
- S45. Blender — ретопология (Voxel Remesh, QuadriFlow). https://docs.blender.org/manual/en/latest/modeling/meshes/retopology.html
- S46. mcp-for-blender. https://github.com/ahujasid/mcp-for-blender
- S47. Стоимость рига. https://www.cadcrowd.com/blog/?p=31182 ; https://animost.com/industry-updates/how-much-does-it-cost-to-rig-a-3d-character/
- S48. RealityKit BlendShapeWeightsComponent (iOS 18). https://developer.apple.com/documentation/realitykit/blendshapeweightscomponent ; экспорт shape keys из Blender: https://developer.apple.com/forums/thread/766484
- S49. RealityKit playAnimation и transitionDuration. https://developer.apple.com/documentation/realitykit/entity/playanimation(_:transitionduration:blendlayeroffset:separateanimatedvalue:startspaused:clock:handofftype:) ; https://www.createwithswift.com/play-an-animation-in-realitykit/ ; несколько анимаций в одном USDZ: https://developer.apple.com/forums/thread/724145
- S50. SceneKit после WWDC 2025. https://fatbobman.com/en/weekly/issue-090/ ; https://dev.to/arshtechpro/wwdc-2025-scenekit-deprecation-and-realitykit-migration-a-comprehensive-guide-for-ios-developers-o26
- S51. HEVC с альфой. https://developer.apple.com/videos/play/wwdc2019/506/ ; VideoPlayer в SwiftUI: https://developer.apple.com/forums/thread/709700
- S52. Характеристики iPhone 17 Pro и Pro Max (ProMotion до 120 Гц). https://www.apple.com/iphone-17-pro/specs/
- S53. Spline — нативный рантайм для iOS. https://docs.spline.design/native-3d-embeds-for-ios

**Rive**
- S54. Тарифы: https://rive.app/docs/account-admin/pricing ; экспорт только на платных тарифах с 20.10.2025: https://community.rive.app/c/announcements/rive-s-new-9-mo-plan ; https://rive.app/docs/editor/exporting/exporting-for-runtime
- S55. Сообщество и маркетплейс под CC BY. https://rive.app/docs/community/marketplace-overview ; https://rive.app/docs/community/community-overview
- S56. Vector feathering. https://rive.app/blog/introducing-vector-feathering
- S57. rive-ios (MIT, 6.28.1): https://github.com/rive-app/rive-ios ; входы: https://rive.app/docs/runtimes/apple/inputs
- S58. Ставки Rive-аниматоров. https://contra.com/s/7WXo7bMv-interactive-rive-animation-for-apps-and-web ; https://contra.com/s/MQAbkAqL-b2-b-monthly-retainer ; https://contra.com/s/UPrAm6lm-animated-mascot ; https://www.upwork.com/hire/animators/cost/

**3D-художники**
- S59. https://fiverr.com/aymonblanc/create-stylized-3d-character-modeling-and-rigging-for-games-and-animation ; https://dribbble.com/services/257933-Character-3D-Modelling-and-Animation ; https://freelancehunt.com/en/project/3d-personazh/539060.html ; https://www.fl.ru/uslugi-freelancera/hudozhnik-3d-personazhej-3d-grafika/

**Генерация картинок на Mac**
- S60. mflux (README v0.23.0 и README моделей: z_image, flux2, flux, flux3, qwen21, common). https://github.com/mflux-community/mflux
- S61. Лицензии FLUX.2 [klein]: 4B — Apache-2.0, 9B — некоммерческая. https://venturebeat.com/technology/black-forest-labs-launches-open-source-flux-2-klein-to-generate-ai-images-in ; https://huggingface.co/black-forest-labs/FLUX.2-klein-4B
- S62. Z-Image-Turbo, Apache-2.0. https://huggingface.co/Tongyi-MAI/Z-Image-Turbo ; https://www.datalearner.com/en/ai-models/pretrained-models/z-image-turbo
- S63. FLUX.1 [schnell], Apache-2.0. https://huggingface.co/black-forest-labs/FLUX.1-schnell ; https://discuss.huggingface.co/t/copyright-flux-1-schnell/122631
- S64. Qwen-Image 2.1, исследовательская лицензия. https://aiweekly.co/alerts/qwen-ships-image-21-turbo-as-8-step-7b-research-license-model ; https://wikidocs.net/blog/@openwiki/33027/
- S65. SDXL, CreativeML Open RAIL++-M. https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 ; зеркало карточки: https://huggingface.co/YuCollection/sdxl-1.0-base-diffusers/blob/main/README.md
- S66. Draw Things. https://apps.apple.com/us/app/draw-things-offline-ai-art/id6444050820 ; релизы и ускорение на M5: https://releases.drawthings.ai/ ; о памяти: https://discuss.huggingface.co/t/which-model-to-use/176186
- S67. Apple Machine Learning Research — MLX и нейроускорители M5. https://machinelearning.apple.com/research/exploring-llms-mlx-m5

**Прочее**
- S68. Оплата зарубежных сервисов из России в 2026 году. https://vc.ru/services/2873894-kak-oplachivat-zarubezhnye-podpiski ; https://bankiros.ru/news/kak-oplatit-zarubezhnye-servisy-i-podpiski-iz-rossii-v-2026-godu-rabochie-sposoby
- S69. Гражданский кодекс РФ, часть 4 (ст. 1234 — отчуждение исключительного права, ст. 1257 — автор). https://www.consultant.ru/document/cons_doc_LAW_64629/
- S70. Rhubarb Lip Sync. https://github.com/DanielSWolf/rhubarb-lip-sync

**Внутренние документы проекта**
- `knowledge/product/look-and-feel.md` — пожелания родителя, ограничения памяти и GPU, открытые вопросы.
- `knowledge/product/persona.md` — подруга, женский род, ударения в Supertonic.
- `knowledge/product/session-limit.md` — мягкие 10 минут и прощание.
- `knowledge/product/overview.md` — задержка, игры держит код, направление на платную версию.
- `KNOWLEDGE.md` §3 (память, нагрев), §6 (синтез, распознавание), §10 (детская безопасность), П23, П25, П26.

**Что проверено вне сети** (2026-10-17): GitHub API — версии, лицензии и README mflux, rive-ios, TRELLIS.2, trellis-mac, Hunyuan3D-2.1 (LICENSE) и порта, SF3D, SPAR3D, mcp-for-blender; параметры Mac — `system_profiler`; контраст палитр — скрипт по формуле WCAG.
