# Verify report

**Date:** 2026-10-19
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (класс S; документная поставка — четыре справки исследований, тестов в диффе нет)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/39310091174
**Commit:** a297571fa46b093e54d94dd6635b06a2174479c9

## Shape oracles
- [x] PASS — pre-commit на коммитах `1d03ee2` и `a297571` (секреты, данные ребёнка, gate-coverage); в CI — джоба gates:
  `child-data` просмотрел 295 файлов, данных ребёнка нет; secrets — 148 файлов; gate-coverage OK (18 скриптов, подключено
  8, осознанно нет 10); доктор `AUTO 40 · WEAK 12 · ABSENT 4 · TOOL 3 · SKIP 3 · DEAD 0`
- [x] PASS — `okf_validate.py knowledge` 0/0, 39 файлов; `okf_sync_gate.py --base origin/main` OK (3 concept'а с картой
  реализации; новые справки — `type: Reference` без кода)
- [x] PASS — строгий `delivery_check --require-ci --diff-base origin/main` на verify: 0 ошибок; breakers — 2 файла вне
  `knowledge/` и `delivery/`, net 7 строк

## Behavior oracles
- [x] PASS — Builder ≠ Verifier: отчёты писали агенты 18.10; числа справок сверены с отчётами скриптом в обе стороны
  (вне репозитория). Из 1636 вхождений чисел четырёх справок в отчётах не найдены 14, и все — из сверки, а не из
  головы: даты 2026-10-19, дата лицензии Open RAIL-M 18.08.2022, даты смерти 16.03.1942 и 15.11.1953, «CC BY-SA 3.0»,
  279 статей Викидии, год в LICENSE T-one и номера в адресах. Обратно: числа отчётов, которых нет в справках, — только
  номера разделов, «80 WAV» и форма даты архива; таблицы, методы, оговорки и требования M1–M14, E1–E11 перенесены целиком
- [x] PASS — лицензии сверены по первоисточникам (таблица ниже): из ~50 утверждений одно неверно (OpenStax), одно не
  подтвердилось (Space Place и SciJinks), три не проверяемы и помечены `[не проверено]`
- [x] PASS — поиск по затронутым границам (L7, L16): «U+0301», «SpeechTranscriber», «GigaAM», «энциклопед», «BM25»,
  «RUAccent», «Supertonic», «contextualStrings» по `KNOWLEDGE.md`, `CLAUDE.md` и `knowledge/`. Опровергнутая запись
  «U+0301 даёт артефакты» найдена в 4 местах и исправлена во всех; оценка GigaAM ~0,3 ГБ в бюджете §6 — заменена
  замером footprint; справка `character-rendering` с той же оценкой оставлена: она записана как есть, снимок отчёта 17.10

**Сверка лицензий** (2026-10-19; `gh api`, API Hugging Face, файлы LICENSE в архивах моделей `~/models/`, веб):

| Утверждение отчёта | Первоисточник | Вердикт |
|---|---|---|
| Supertonic 3: модель OpenRAIL-M с запретом вреда детям, код MIT, архив 09.09.2026 | LICENSE на HF (BigScience Open RAIL-M от 18.08.2022, приложение A (b) — несовершеннолетние); `gh api` — MIT, `archived`, последний push 2026-09-09 | подтверждено |
| Vosk TTS: код и модель Apache-2.0, ruBert-base Apache-2.0, голоса без происхождения | `gh api` alphacep/vosk-tts; README в архиве модели 0.9; HF ai-forever/ruBert-base | подтверждено |
| Silero Stress MIT, RUAccent MIT, rupostagger GPL-3.0, omogre CC BY-NC-SA 4.0, StressRNN Apache-2.0 | `gh api`, LICENSE omogre, HF ruaccent/accentuator | подтверждено |
| espeak-ng GPL-3.0; данные Piper irina — неизвестно, ruslan — NC; parselmouth GPL-3.0 | `gh api`; MODEL_CARD голосов («Unknown», CC BY-NC-SA 4.0) | подтверждено |
| wav2vec2-xlsr-53-espeak-cv-ft Apache-2.0; Викисловарь CC BY-SA | HF; подвал страниц (4.0) | подтверждено |
| GigaAM-v3 MIT, T-one Apache-2.0, Omnilingual Apache-2.0 | LICENSE в архивах sherpa-onnx, `gh api`, HF | подтверждено |
| Vosk zipformer, small streaming, small-ru-0.22 — Apache-2.0 | HF `alphacep/*`, таблица моделей Vosk | подтверждено |
| Whisper MIT, Parakeet CC BY 4.0, Qwen3-ASR Apache-2.0 (два последних — «не перепроверено») | `gh api`, HF | подтверждено |
| Common Voice CC0, FLEURS CC BY 4.0, Golos — лицензия Сбера | объявление Mozilla 2019; HF; PDF лицензии Golos («not a Creative Commons license») | подтверждено |
| NeMo FastConformer, 10 языков | модель на NGC, на HF нет | **не проверено** |
| факты не охраняются: ГК РФ ст. 1259 п. 5, 17 U.S.C. §102(b) | тексты статей | подтверждено |
| Википедия CC BY-SA 4.0 + GFDL; CC BY-SA 4.0 §4 и §2(a)(5)(C) | Terms of Use §7; legal code | подтверждено |
| Викиданные CC0 | Wikidata:Licensing | подтверждено |
| ГК РФ ст. 1281: 70 лет, +4 года за войну | текст статьи: п. 1 и п. 5 | подтверждено; применимость к М. Ильину — **не проверено** |
| NASA Space Place, NOAA SciJinks — общественное достояние (§105) | Image Use Space Place — только изображения, правила NASA и JPL; SciJinks закрыт; §105 — работы правительства США | **не подтверждено** |
| OpenStax — CC BY 4.0 | справка OpenStax | **неверно: CC BY-NC-SA** |
| Викидия — не проверено | сведения сайта через API | CC BY-SA 3.0, 279 статей; возраст 8–13 — **не проверено** |
| Gemma 4 — Apache 2.0 или Gemma Terms | HF, страница лицензии Gemma 4 | Apache 2.0 |
| доклад Copyright Office 2025 | copyright.gov, выпуск 1060 | подтверждено |
| rubert-tiny2 MIT, multilingual-e5-small MIT, MiniLM-L12 Apache-2.0 | HF | подтверждено |

## Product oracles
- [x] PASS — `delivery/evals/smoke/run.sh` в CI: S1–S4 PASS (4/4), S5 — джоба swift: покрытие 96% (675 из 699 строк),
  отрицательный контроль 101% покраснел; `stack_selftest` 119 блоков, 0 ошибок

## Ревью рисковых мест

- **безопасность и данные ребёнка — риска нет, потому что** в диффе нет записей, транскриптов и имён: справки —
  выжимки отчётов с выдуманными именами (Соня, Тёма, Мурка), протокол шага 3 в `asr-child-speech` держит настоящие
  имена только в `local/` (`vocab/step3_context.txt`, `refs.csv`); правки `KNOWLEDGE` и `CLAUDE` — указатели и поправки
  фактов (знак U+0301 у `Supertonic`, `footprint` GigaAM в `ONNX` Runtime), прав и кода не трогают; `child-data` в CI —
  295 файлов, данных нет.
- **лицензии (продукт может стать платным, `product/overview`) — риск разобран:** справки не дают разрешений, а
  называют лицензии с источником. Два вердикта отчёта исправлены: OpenStax и тексты Space Place и SciJinks — «только
  факты»; приёмка E2 в `kids-encyclopedia` требует поле `license` у каждой карточки. Непроверяемое помечено
  `[не проверено]`, а не перенесено как факт.
- **сеть — риска нет, потому что** ни одна справка не предлагает облака: GigaAM, расстановщики и FTS5 работают на
  телефоне, а системные модели, которые качает ОС (`NLContextualEmbedding`), записаны риском офлайна.

## Spec coverage gaps
- Отчёты промежуточные: часть прогонов не сделана (FLEURS у GigaAM, знак U+0301 на остальных группах списка, блок B2
  в новой сессии, e5-small на v2) — так и записано в справках, разделы «Не доделано».
- На iPhone не мерены: footprint GigaAM в ONNX Runtime, NLTagger и FTS5, Supertonic со знаком на слух.
- Не проверено: лицензия NeMo FastConformer, применимость п. 5 ст. 1281 к М. Ильину, статус текстов Space Place и
  SciJinks, возраст аудитории Викидии.

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED

## Harness metrics (this shipment)

<!-- generated by scripts/delivery_metrics.py --base origin/main -->

| Metric | Value |
|---|---|
| files_touched / loc_diff | 2 code (+15 process docs) / +12/-5 (net +7) |
| commits | 2 |
| time_to_accepted_spec | n/a (no spec.md in history — class S?) |
| rework_after_done | 0 (handoff not declared yet) |
| harness_hardened | no |
| implement_retries | 1 — две справки поправлены после записи, до коммита: источник CC0 у Common Voice (`asr-child-speech`) и статус текстов SciJinks (`kids-encyclopedia`) |
| verify_fails_before_green | 0 — первый прогон CI на PR зелёный (39310091174) |
| est_token_or_cost | n/a |
