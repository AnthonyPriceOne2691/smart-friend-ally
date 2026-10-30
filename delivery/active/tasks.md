# Tasks

Уроки — в `plan.md`.

## Slice 0 — спека и страница выбора
- [x] T1: стенд `local/spike/voice-tuning/` (вне git): настоящие текст и Supertonic, ядро стенда со `stretch` и `range`
- [x] T2: страница `local/checkpoint/voice-tuning/index.html`, 8 вариантов; страница паузы `pause.html`
- [x] T3: спека и STATUS первым коммитом ветки
- [x] T4: выбор родителя — вариант 6, пауза около секунды; подпись вписал ведущий

## Slice 1 — обрезка, пауза, слух
- [x] T5: `SilenceTrim`, ключ `gap`, `SpokenVoice.settle`; тесты G1–G9; мутации 8 из 8

## Slice 2 — вариант 6
- [x] T6: ядро `AllyVoiceFX`: `stretch`, `range`; тесты S1–S3
- [x] T7: ключи строки, S4; строка `voice.json`, V1
- [x] T8: таблица ударений, T1–T8
- [x] T9: стенд: V2, G10, цена `voice_fx` в Debug

## Slice 3 — знание и сдача
- [x] T10: концепты, `knowledge/log.md`
- [ ] T11: слить свежий `origin/main`; строгий `delivery_check --require-ci --diff-base origin/main`; пуш, PR, CI
- [ ] T12: verify-report, архив в том же PR, строка INDEX (уроки L181–L184), slug — в конец `delivery/OBSERVATIONS.md`
