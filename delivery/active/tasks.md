# Tasks

Уроки по путям диффа (§2.2a): L14, L26, L28, L32, L33, L34, L35, L38, L41, L43, L47, L50, L51, L52, L59, L61 — как
применены, сказано в `plan.md`.

## Slice 0 — документы и подпись
- [x] T1: `spec.md` (примеры Z8–Z13 таблицей дословно из спеки серии, коммит 68202f0), `STATUS.md` с подписью родителя
  2026-10-23, `plan.md`, `tasks.md`, `decisions.md`, `eval-smoke.md` — первым коммитом ветки `feat/voice-text`, до кода
  (L33); `phase: implement`

## Slice 1 — слово, таблица, знаки
- [ ] T2: `Package.swift` (Foundation, ресурс), `StressPlacer.swift`, `SpokenWord.swift` (разбор «+», знак, регистр),
  `SpeechTextTable.swift` и `speech-text.json` (разделы, загрузка, проверка числа гласных); двойник расстановщика;
  Z8; мутации «знак на „ё“», «знак на односложных»

## Slice 2 — переписывание
- [ ] T3: `Respelling.swift` — имена, закреплённое, `words`, окончания с вариантом по ударению и исключениями, `parts`;
  Z9, Z10, примеры Z11; мутации «исключение не сработало» (красный на каждом из семи), «словарь под расстановщиком»,
  «вариант окончания без учёта ударения», «таблица без проверки числа гласных»

## Slice 3 — конвейер
- [ ] T4: `SpeechTextPipeline.swift` — `prepare`, `SpeechText` (`shown`, `engine`, `trace`); Z12, Z13; свойство Z11 на
  500 словах с зерном; мутации «переписывание до расстановщика», «знак по номеру буквы», «след несёт слова»

## Slice 4 — CI и знание
- [ ] T5: `LINT_SWIFT_PACKAGES` в `quality.yml`, третий прогон jscpd в `.pre-commit-config.yaml`, `.build` пакета в
  `.swiftlint.yml`; `adapted.json`, строка jscpd в `STACK-ACCEPTANCE.md` (L32); доктор — DEAD 0
- [ ] T6: concept `knowledge/engineering/speech-text.md` (`implementation:`), `engineering/index.md`,
  `references/repo-map.md`, `knowledge/log.md`; поиск мест, где описан текстовый путь к голосу (L16); `okf_validate` и
  `okf_sync_gate` зелёные

## Slice 5 — проверка и сдача
- [ ] T7: слить `origin/main`, сразу строгий `delivery_check --require-ci --diff-base origin/main` (L14)
- [ ] T8: verify-report — `swift test` и покрытие ≥ 70%, мутации, дайджест утверждений и `check_digest_report.py` до пуша
  (L43), предохранитель против плана, `mergeable` и ссылка на зелёный CI (L35)
- [ ] T9: сдача в том же PR — `delivery/archive/2026-10-23-voice-text`, `.gitkeep`, строка INDEX с уроками L92–L94,
  `voice-text` в обязательствах CLAUDE.md, `observe_until` 2026-11-30; мерж — ведущий

## Ждёт данных
- [ ] T10: строки проверенной таблицы второго круга (что → што, коне́шно, немые согласные, сч → щ, -тся/-ться → -ца) и
  запись имени — когда ведущий передаст таблицу: строкой `speech-text.json` и тестом на каждую строку (Z10)
