# Tasks — D6.1 duplex-audio

- [x] T0: подписи родителя под X18, X19 и планом — ведущий пачкой; отдельным коммитом (`human_ok_spec`, `human_ok_plan`)
  — 2026-10-25 «Подписываю (Рекомендую)», by=human:anthony
- [ ] T1: дождаться мержа V4b2 `voice-app` и D7.3 `gigaam-asr`, влить main; сверить план с тем, как V4b2 построила
  player голоса (стык «движок снаружи»), поправить бюджет
- [x] T2: ядро — `OverlapCounter`, `VoiceRing`, ключи реестра слуха `overlap` и `voice_processing`; тесты X18, X19, X11
  — до мержа V4b2 (слово ведущего 2026-10-25); без вызывающего ядро отдельно не сдаётся (L50): мерж — после проводки.
    Сделано: `Overlap.swift`, ключи в `Hearing` и `hearing.json` (`lead` 0,8 с — правка после подписи, decisions);
    X18, X11, X19 зелёные; 7 мутаций ядра краснят свои примеры; знания ядра — `turn-detector`, `voice-loop`, `log`
- [ ] T3: движок звука — `AudioIO` на сессию: `.voiceChat`, граф голоса до voice processing, AGC, тап на сессию, раздача
  кадров; player V4b2 в общий движок
- [ ] T4: проводка — слушание с кольца, этапы `overlap` и `started_over_voice`, один движок на две сессии, строка
  консоли, версия `audio`; Milena — полудуплекс
- [ ] T5: знания — `voice-loop`, `turn-detector`, `knowledge/log.md`
- [ ] T6: сборка `.app` без подписи и оракул артефакта; телефон — X9, X10, X12, телефонная часть X11 — в общую сессию
  теста (постоянное решение родителя); eval-smoke, verify-report (L43), строгий `delivery_check`, CI; архив в том же PR
  с уроками L98, L99; slug `duplex-audio` — строкой в конец `delivery/OBSERVATIONS.md`; мерж — ведущий
