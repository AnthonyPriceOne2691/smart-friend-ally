# Eval smoke — voice-onnx

Оракулы поставки — примеры V1 спеки (Z1–Z7), после подписи родителя. Факт — по прогону стража в Linux-джобе `quality` и
тестов пакетов на Mac (`swift test --package-path Packages/AllyOnnx` и `Packages/AllyVoice`, ручная джоба `ios`), а не
по ожиданию.

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| Z1 | `scripts/lint/check_single_ort.sh` и отрицательный контроль | один ORT — `binaryTarget` в `Packages/AllyOnnx`; копия с добавленным `onnxruntime-swift-package-manager` / `onnxruntime-libs` / `k2-fsa/sherpa-onnx` — красный с файлом | |
| Z2 | `SupertonicParityTests`, эталоны `~/models/tts/supertonic-parity` | 5 фраз: отсчёты равны, SNR разности ≥ 60 дБ, длительность до 1e-6 с | |
| Z3 | `SupertonicParityTests` | векторы смеси F2+F5:0.5 = среднее до 1e-6; звук ≥ 60 дБ к Python | |
| Z4 | `SupertonicEngineTests` + мутация «пол убран» | 0,84 — ошибка с текстом, 0,85 — звук; мутация красная | |
| Z5 | `SupertonicEngineTests` | отпечаток после загрузки ≤ 100 МБ, пик ≤ 250 МБ; 2 потока, spin 0 | |
| Z6 | `SupertonicEngineTests` | медиана ≤ 1,3 с на фразу 9–10 слов, загрузка ≤ 1 с | |
| Z7 | `SpeechEngineContractTests` | пустой текст — ошибка; фраза — моно float32 44 100 Гц, длительность > 0; двойник и Supertonic — одни проверки | |
