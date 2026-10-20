# Tasks

## Slice 0 — документы
- [ ] T1: документы D1.1 первым коммитом ветки (подпись родителя 2026-10-20; A25–A27 — уточнение ведущего); `eval-smoke.md` до кода

## Slice 1 — ход
- [ ] T2: `Packages/AllyCore`: `Package.swift`, протоколы и часы, нарезка первой фразы, `TurnRunner` со сторожем и отменой
- [ ] T3: двойники (модель по сценарию, голос с записью, виртуальные часы) и тесты A1–A6; мутация «catch глотает отмену» краснит A5

## Slice 2 — конец речи и вспомогательное
- [ ] T4: `TurnDetector` — порог зонда, хвост типа хода, «возможно, конец», предзапись, предел хода; тесты A17, A25–A27
- [ ] T5: журнал хода, сборщик текста, реестр и проверка весов, срок профиля подписи; тесты A14–A16, A18

## Slice 3 — CI и знание
- [ ] T6: `LINT_SWIFT_PACKAGES`, вторая половина jscpd, `.swiftlint.yml` (`.build` пакета); `check_digest_report.py` шагом
  джобы `delivery`, канарейка, `adapted.json`; проба красного на подложенном отчёте (A19); доктор DEAD 0
- [ ] T7: `safety-below-model.md` (исполнитель и `implementation:`), концепт `turn-detector.md`, карта репозитория, `knowledge/log.md`

## Slice 4 — сдача
- [ ] T8: verify-report — тесты и покрытие, дайджест, `mergeable` и ссылка на зелёный CI (L35), метрики; строгий
  `delivery_check --require-ci --diff-base origin/main` (L14)
- [ ] T9: сдача — `delivery/archive/2026-10-20-voice-core`, `.gitkeep`, строка INDEX (уроки — L40–L41), `voice-core` в
  обязательствах CLAUDE.md, `observe_until` 2026-11-30; PR зелёный; мерж — ведущий
