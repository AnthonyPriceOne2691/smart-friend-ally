# Active delivery status

- **slug:** child-lock
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)»: примеры G1–G11 и ответы 1–9 подписаны в спеке D2.2 + R — delivery/archive/2026-10-22-app-session/spec.md, коммиты 0ffd2df и 371a374)
  <!-- таблица G1–G11 перенесена дословно со столбцом оракула; спека, подпись и eval-smoke — раньше кода (L33) -->
- **human_ok_plan:** yes (родитель 2026-10-22 «Подписываю (Рекомендую)» — план R в delivery/archive/2026-10-22-app-session/plan.md; стыки утверждены ведущим 2026-10-22 и 2026-10-23)
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- G1–G6, G9 — тесты AllyCore на Linux; G7 — проверка подписи на Mac (CryptoKit); G8, G10, G11 — телефон и Mac с
       родителем в сессии теста (T7) -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app (сеть, ключи Info, права подписи); CryptoKit — системный фреймворк, сети не тянет
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-childlock
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: D3 black-box (поле `audience`,
       `SessionParts`, `TurnTrace.swift`), «оболочка» (тело `ChildScreen`, консоль), contract-fixes, поставка голоса
       (`VoiceLoop.swift`); конфликты при слиянии main — сложением -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: ключ родителя (T2) пришлёт ведущий — до него `.github/allowed_signers` без ключа и
       приложение пишет «в сборке нет ключа родителя» (G4); G8, G10, G11 — сессия теста с родителем (T7) -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** scripts/child_mode.sh
  <!-- §12.6, один путь: подпись касанием и копирование исключения в контейнер телефона; приложение читает его на
       телефоне — это исполняется в сессии теста (G10, G11) -->
- **irreversible_surfaces:** none reason=продукт офлайн; исключение копируется на телефон родителя отдельным его решением и гаснет само (≤ 7 дней) или кнопкой; отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- §14.1: поверхность модели не меняется — замок читает sha256 персоны и вес «файл:байты» для поверхности исключения -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** G8, G10, G11 в первой сессии теста с родителем; затем у каждой детской сессии записи следа с `audience: supervised`, у консольной — `parent`; строка замка в консоли совпадает со сроком подписанного исключения; до неё G1–G7, G9 и покрытие AllyCore ≥ 70% зелёные в каждом PR
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
