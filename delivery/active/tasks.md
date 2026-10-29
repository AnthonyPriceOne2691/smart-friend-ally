# Tasks

Уроки (§2.2a) — в `plan.md`.

## Slice 0 — кандидаты и документы
- [x] T1: семь кандидатов на странице `local/checkpoint/music/index.html` (вне git): лицензии сверены на страницах
  источников, sha256 скачанного; свой вариант — генератор `local/spike/music/gen/music_box.py`
- [x] T2: выбор родителя — №4, затем №7 «Шкатулка Элли» (дословно в `decisions.md`)
- [x] T3: документы первым коммитом ветки, до кода (L33, L62): STATUS (`deferred`), spec (Y1–Y11), plan, tasks,
  decisions; ведущему — строка подписи

## Slice 1 — код
- [x] T4: `eval-smoke.md` — строки Y1–Y11 до кода; `phase: implement`
- [ ] T5: `MusicBox` — порт генератора на детерминированных операциях; расхождение со звуком страницы; Y10; мутации
- [ ] T6: `MusicLine`, `MusicCue`, `MusicFader`; Y1–Y9; мутации
- [ ] T7: `BackgroundMusic` и проводка `VoiceLoop`, `AllyApp`, `music.json`; второй тап во время ожидания не будит
- [ ] T8: стенд Y11 на Mac (время — по слову ведущего); при провале — цифры ведущему до кода сдачи

## Slice 2 — знание и сдача
- [ ] T9: `product/look-and-feel` (правило 14 словами родителя, раздел «Музыка»), `engineering/voice-loop`,
  `ops/test-session`, `knowledge/log.md`; поиск мест границы (L7, L70)
- [ ] T10: сборка `.app` без подписи и оракул артефакта — по слову ведущего; слить свежий `origin/main`; строгий
  `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI
- [ ] T11: verify-report, `check_digest_report.py`; архив, строка INDEX (L163–L166), `OBSERVATIONS.md`; доклад ведущему
