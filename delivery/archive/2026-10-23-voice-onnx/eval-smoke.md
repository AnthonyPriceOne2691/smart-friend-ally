# Eval smoke — voice-onnx (V1a)

Оракул поставки — пример Z1 спеки, подписанной родителем 2026-10-23. Факт — по прогону стража и его отрицательного
контроля в Linux-джобе `swift` и тестов `AllyOnnx` на Mac (`swift test --package-path Packages/AllyOnnx`), а не по
ожиданию. Z2–Z7 переехали в V1b `voice-engine` (разрез ведущего 2026-10-23).

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| Z1 | `scripts/lint/check_single_ort.sh` и отрицательный контроль | один ORT — `binaryTarget` в `Packages/AllyOnnx`; пакеты `onnxruntime-swift-package-manager` / `onnxruntime-libs` / `k2-fsa/sherpa-onnx` — красный с файлом; binaryTarget sherpa из releases — зелёный | локально 2026-10-23: дерево ветки — «one ONNX Runtime — pod-archive-onnxruntime-c-1.28.0»; три пакета-зонда — красный с файлом `Packages/Probe/Package.swift`; binaryTarget sherpa с условием платформы — зелёный; в CI — шаги джобы `swift` |
