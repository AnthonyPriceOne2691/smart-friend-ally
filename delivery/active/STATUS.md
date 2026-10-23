# Active delivery status

- **slug:** memory-extract
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии: ожидания M26–M28 — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разрез остатка
       memory-extract на memory-extract (M26–M28), memory-sense (M30, M31) и memory-quality (M32) — решение ведущего
       2026-10-23, «подписанное то же»; входы и строки «Здесь:» — вымышленный пример агента к подписанным ожиданиям,
       ведущий 2026-10-23: такой пример родителю показывать не нужно -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- M26–M28 — тесты пакета Packages/AllyMemory (ExtractTests) с двойником модели, на Linux (CI, джоба swift) и на
       Mac -->
- **artifact_oracle:** n/a reason=поставка не собирает приложение: пакет памяти на Linux судят его тесты в CI, сборка не оракул (§6.5a); модель E4B на разборе — memory-quality и memory-app
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: энциклопедия (общий AllySQLite не
       трогается), голос, речь, оболочка; AllyCore не трогается; конфликты в INDEX.md, OBSERVATIONS.md, knowledge —
       сложением -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=пакет памяти на Linux и Mac (база во временном каталоге теста, модель — двойник); вызов E4B на телефоне и файлы памяти — memory-app, там пути объявляются (вопрос 9 спеки серии)
- **irreversible_surfaces:** none reason=разбор пишет только факты памяти через memory-core; стирания, отправки наружу, трат, выкатки и публикации нет, продукт офлайн
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json
  <!-- §14.1: промпт разбора (системный текст, шаблон запроса), шаблон ответа, пример и параметры сэмплирования (0,2,
       seed 42, грамматика JSON) — новая поверхность; до модели на телефоне она дойдёт в memory-app, на E4B её меряет
       memory-quality (M32) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: раздел «правило промпта разбора → исполнитель»: «только её слова» и «не выдумывай» — опора (M28),
       «не записывай запретное» — memory-guard (M29), вымысел, чужие питомцы, отрицание и любимое — advisory до
       memory-sense (M30, M31) -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** M26–M28 и покрытие AllyMemory ≥ 70% зелёные в каждом PR; на E4B — доля «без опоры» и разборов с первой попытки в memory-quality (M32); после memory-app в живых сессиях дочери при родителе — «не разобрана» видна родителю, а не молча
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
