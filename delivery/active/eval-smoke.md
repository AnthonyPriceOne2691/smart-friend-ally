# Eval smoke — sim-app (Элли на Mac)

Оракул поставки — примеры спеки N1–N10, подписанные родителем 2026-10-29. Факт — по прогону smoke S9
(`delivery/evals/smoke/mac_files_check.sh`, в `run.sh`), тестов `AllyCore` (`swift test --package-path
Packages/AllyCore`: Linux — CI джоба `swift`, Mac — локально), мутациям, прогону скрипта на этом Mac и первому ходу
на Mac (N9: родитель жмёт ⌘R и «Разбудить», агент говорит синтетикой `say`, строки — `log show`). Время до голоса
N9 — в чистое окно, без отбора моделей на GPU (слово ведущего); снятое под нагрузкой помечается и перемеряется.

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| N1 | `python3 scripts/mac_files.py` на Mac, `df`; smoke S9 | `~/models/ally-mac`: `Models/` 2 файла, `Voice/` 26, `manifest.json` 28 строк; sha256 весов = пин; клоны — место убывает ≤ 50 МБ; «готово: 28 файлов, 5,50 ГБ …», код 0 | ожидает |
| N2 | повтор N1; smoke S9 | «без изменений: 28», время изменения файлов то же, код 0 | ожидает |
| N3 | smoke S9 | не тот sha256 — стоп с именем, код 1, папка не изменилась; `--out` в `~/Library/Containers` — отказ до сверки, код 1 | ожидает |
| N4 | `MacImportTests` | план 28 копий: байты — реестры, sha256 голоса — `voice.json`, весов и Silero — список | ожидает |
| N5 | `MacImportTests` | отказы: не тот размер весов, чужой путь (`Memory/…`, `../Caches/…`, `Ally/…`), не тот sha256 голоса, нечитаемый список — ничего не скопировано | ожидает |
| N6 | `MacImportTests` (Linux — подменный хэш, Mac — CryptoKit) | копия под временным именем, сверка, замена; несошедшийся — старый цел, временного нет, дальше стоп; `Memory/memory.sqlite` не тронут | ожидает |
| N7 | `MacImportTests` | телефон — кнопки нет никогда; Mac — только когда Элли спит | ожидает |
| N8 | `TraceLineTests` | строка = `jsonLine()` файла следа, без слов хода и кириллицы; мутация «пишет и слова» — красная | ожидает |
| N9 | первый ход на Mac, `log show … category == "turn"` | консоль: диктовка готова, микрофон, Supertonic, дуплекс vp+agc, «модель: Metal — Apple M5»; `speech_end_to_sound` p50 ≤ 2,5 с, худший ≤ 3,0 с; «пока» → `goodbye_word`; `overlap` 0 без речи поверх, фраза поверх перебивает | ожидает |
| N10 | сборка `generic/platform=iOS` без подписи, `check_app_artifact.sh`, `git diff --stat origin/main` | BUILD SUCCEEDED, оракул OK; пакет модели, `reinstall_app.sh`, `model.json` не тронуты | ожидает |
