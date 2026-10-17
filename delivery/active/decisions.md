# Decisions

- 2026-10-17 · выбрал держать стенд бейк-офта (`rules.py`, `run.py`, сырые ответы) в `local/spike/bakeoff/` вне git, а входы (персону и 40 реплик) — в `knowledge/references/research/model-bakeoff-inputs.md`, вместо Python-кода в дереве — потому что Python-роли гейтов объявлены n/a для продукта на Swift, а стенд — одноразовый спайк, как зонд памяти; повторяемость держат входы байт в байт и хэши (`knowledge/engineering/model-bakeoff.md`)
- 2026-10-17 · выбрал отклонить Ternary Bonsai 8B, хотя по безопасному содержанию он лучше E2B (15/30 против 8/30), — потому что язык ломаный почти в каждом ответе («не съмай», «Такие ребёнки»), а безопасность E2B чинится маршрутизацией до модели, язык Bonsai — нет (`knowledge/engineering/on-device-model.md`)
