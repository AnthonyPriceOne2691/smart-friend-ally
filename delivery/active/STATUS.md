# Active delivery status

- **slug:** child-shell-light
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик судит родитель на глаз по снимкам на Mac (П32); снимков экрана телефона нет никогда (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» через ведущего — одной подписью с Ш3: примеры V30–V36; V34 — у Ш2в по точке разреза спеки)
  <!-- спека серии — коммит 4c61d3c, подпись — 48b39f7 (в main — сквош a868735); здесь примеры таблицей (L51) -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=Ш2б не трогает приложение: пакет SwiftPM судят его тесты (ядро — Linux CI, кадры — снимки на Mac), сборка не оракул (§6.5a)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-shell-light
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — в общую сессию теста -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** max_loc_diff=850 reason=свет и пузырьки Ш2б целиком — факт net 803 при пределе 800, вариант B escalation.md; только для Ш2б, на серию не распространяется by=human:anthony (2026-10-25 «Исключение до 850 (Рекомендую)», через ведущего)
  <!-- вопрос ведущего дословно: «Экран дочки, часть 2б (ночь, „думает“, свечение, пузырьки, покачивание), готов, и тесты зелёные. Но вышло 803 строки при пределе 800, на три строки больше. Разрешить для этой части исключение до 850 строк, как у первой части было до 1000? Или вынуть пузырьки неба и воды (около 145 строк уже проверенного кода) в следующую часть?» Варианты: «Исключение до 850 (Рекомендую)» и «Вынуть пузырьки». Ответ: «Исключение до 850 (Рекомендую)». -->
- **new_dependency:** none
- **runtime_paths:** none reason=Ш2б — пакет SwiftPM: свет и пузырьки — значения кадра и генераторы с тестами на Linux, кадры — снимки на Mac; приложение не тронуто, экран на телефоне — общая сессия теста
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- оболочка поверхность модели не трогает: экран рисует фазу сессии и ничего не говорит -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста ночь во сне, рассвет при пробуждении, оттенок «думает», свечение и жемчужинки «слушает», пузырьки и «Z» видны и не дёргаются (на глаз родителя); до неё V30–V33, V35, V36 зелёные в каждом PR, покрытие ShellCore ≥ 70%
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
