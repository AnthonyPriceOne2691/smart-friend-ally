# Eval smoke — accent-onnx

Оракулы — примеры V3 спеки серии (Z14–Z18, коммит 68202f0). Факт — по прогону тестов `AllyVoice` на Mac, а не по
ожиданию.

| id | Чем | Ожидание | Факт |
|---|---|---|---|
| Z14 | `AccentParityTests`, 163 позиции и 9 фраз страницы | тексты расстановщика равны Python минимум в 162 из 163 | |
| Z15 | `AccentParityTests`, группа Y | 8 из 8, как у Python | |
| Z16 | `AccentParityTests` | «аксолотлик» → «аксоло́тлик» | |
| Z17 | `AccentCostTests` | медиана ≤ 40 мс на фразу, отпечаток ≤ 120 МБ | |
| Z18 | `AccentOnnxParityTests`, 804 вызова моделей | логиты = onnxruntime 1.31 до 1e-4 | |
