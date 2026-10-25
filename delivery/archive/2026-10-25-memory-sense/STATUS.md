# Active delivery status

- **slug:** memory-sense
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии: ожидания M30 и M31 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разрез остатка
       memory-extract на memory-extract (M26–M28), memory-sense (M30, M31) и memory-quality (M32) — решение ведущего
       2026-10-23, «подписанное то же»; входы и строки «Здесь:» — вымышленный пример агента к подписанным ожиданиям,
       ведущий 2026-10-23: такой пример родителю показывать не нужно -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M30, M31 — тесты пакета Packages/AllyMemory (SenseTests) с двойником модели, на Linux (CI, джоба swift) и на Mac -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет памяти на Linux судят его тесты в CI, сборка не оракул (§6.5a); модель E4B на разборе — memory-quality и memory-app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-sense
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: поставка канона «вариант D»
       (docs/canon уходит из git — после слияния main каталог возвращается копией из основного клона, в git не идёт),
       голос, речь, оболочка, энциклопедия; общий AllySQLite не трогается; конфликты в INDEX.md, OBSERVATIONS.md,
       knowledge — сложением -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=пакет памяти на Linux и Mac (база во временном каталоге теста, модель — двойник); вызов E4B на телефоне и файлы памяти — memory-app, там пути объявляются (вопрос 9 спеки серии)
- **irreversible_surfaces:** none reason=снятие «любит» уводит факт в историю базы, не стирает; стирания, отправки наружу, трат, выкатки и публикации нет, продукт офлайн
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json
  <!-- §14.1: поверхность не меняется — слова окна вымысла, хозяина, отрицания и маркеров любимого живут в sense.json,
       который читает код после ответа модели, а не модель -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: раздел «правило промпта разбора → исполнитель»: вымысел, чужие питомцы, отрицание (правила 4–6) и
       маркеры любимого с «больше не люблю» (правила 3, 7) переходят из advisory в «исполняется» -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M30, M31 и покрытие AllyMemory ≥ 70% зелёные в каждом PR; на E4B — ловушки 0 и обновления 3 из 3 в memory-quality (M32); после memory-app в живых сессиях дочери при родителе — в памяти нет питомцев из игр и снов, «больше не люблю» убирает строку «Любит»
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
