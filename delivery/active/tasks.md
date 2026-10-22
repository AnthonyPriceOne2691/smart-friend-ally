# Tasks

## Slice 0 — документы и подпись
- [x] T1: документы D2 первым коммитом ветки `feat/session-core`, до кода (L33): STATUS, spec (примеры, три текста
  с проверкой эталоном и Swift-контрактом), plan, tasks, decisions — коммит `4862a9c`
- [x] T2: подпись родителя 2026-10-22 «Подписываю (Рекомендую)» — три текста и рекомендации 2–7 как есть;
  `ReleaseGate` (S13–S14) перенесён в R решением ведущего по правилу переноса; подпись — отдельным коммитом до кода
- [x] T3: `eval-smoke.md` — строки S1–S12 с оракулом и ожиданием, до кода; `phase: implement`

## Slice 1 — крючок и ход
- [ ] T4: `Routing.swift` — `Route`, `TurnRouting`, `PassThroughRouting`; `TurnRunner.run(_:decision:)` передаёт реплику и
  решение в контракт; тесты D1.1 A1–A6, A14–A18 зелёные без правок; S8, S9; мутация «без `heard`» краснит S9

## Slice 2 — сессия
- [ ] T5: `Resources/session.json`, `SessionData.swift` (тексты с режимами, `goodbye_words`, `misses_before_rest`, ключ
  `session_limit_minutes` с диапазоном), ресурсы в `Package.swift`; S12 — перечень фраз через контракт режима
- [ ] T6: `Session.swift` — состояния и события по таблице спеки, приветствие, промахи и отдых, её прощание, лимит и
  windingDown, ход с темой после лимита, `stop` и ошибка хода; S1–S7, S10; мутации S4 (без проверки лимита) и S10
  (широкий `catch`) краснят тесты
  <!-- замер выше 780 строк — стоп, escalation.md и сразу к ведущему: след S11 в D3 либо подпись предохранителя -->

## Slice 3 — след хода
- [ ] T7: `TurnTrace.swift` — запись, `TraceStamp`, `TraceSink`, строка JSON без слов; сессия пишет ровно одну запись на
  ход, причина конца — у последней; S11

## Slice 4 — знание
- [ ] T8: `session-limit.md` — фраза прощания вместо «давай завтра продолжим?», `implementation:`, читатель ключа;
  `safety-below-model.md` — строка реестра «когда уходит» (исполнитель — сессия), её прощание, реплика в контракте хода
  (`TurnRunner.swift` в `implementation:` — `okf_sync_gate`); концепт `engineering/session.md` с `implementation:`;
  карта репозитория, `engineering/index.md`, `knowledge/log.md`; `okf_validate` зелёный

## Slice 5 — сдача
- [ ] T9: слить `origin/main` с `sync-cqg-2.74`, когда ведущий скажет; `stack:` → cqg@2.74; сразу строгий
  `delivery_check --require-ci --diff-base origin/main` (L14)
- [ ] T10: verify-report — `swift test` и покрытие AllyCore ≥ 70%, сводка утверждений Swift (новые тест-файлы в ней,
  L26), мутации, `mergeable` и ссылка на зелёный CI (L35)
- [ ] T11: сдача — `delivery/archive/<дата>-session-core` в том же PR, `.gitkeep`, строка INDEX (уроки — L50–L52),
  `session-core` в обязательствах CLAUDE.md, `observe_until` 2026-11-30; мерж — ведущий

## Перенесено (не эта поставка)
- `ReleaseGate` (бывшие S13–S14) — в R вместе с `release-gate.json`: правило переноса ведущего, план 725 > 700 (L34).
- D2.2 `app-session`, после мержа D1.2 и D2: тап будит сессию, ход по тапу, как в D1.2; консоль — состояние и лимит;
  след — `Caches/turns.jsonl` вместо журнала D1.2; ключ лимита — `UserDefaults` (на телефоне — аргумент запуска);
  переустановка одной командой со сверкой, что веса и данные в контейнере пережили её (E4) — один рисковый путь.
