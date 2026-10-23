# Eval smoke — voice-config (V4b1)

Оракулы поставки — примеры Z19, Z20, Z29, Z30 спеки. Факт — по тестам пакетов на Linux (джоба `swift`), smoke S8 в
джобе `delivery` и стенду на Mac (Z30), а не по ожиданию.

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| Z19 | `VoiceSettingsTests` | «Совсем малышка» разобрана; правка строки меняет пресет; 0,80 → строка консоли и 0,85 | |
| Z20 | `VoiceSettingsTests`; smoke S8 `voice_copy_check.sh` | три строки `VoiceCheck`; команда: стоп до копии на чужом sha256, `.gz` распакован | |
| Z29 | `VoiceEQTests` | «light» и «ref» ± 0,1 дБ к scipy стенда | |
| Z30 | стенд `local/spike/voice-fx` (Mac), `--eq light` | порт против p9f5: пороги дребезга; контроль `psola_c` не проходит | |
