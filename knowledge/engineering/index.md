# Engineering

* [On-device model](on-device-model.md) - ADR: модель только на телефоне, за протоколом, выбор замером
* [Safety below the model](safety-below-model.md) - правила безопасности держит механика до синтеза, а не промпт
* [Memory limit](memory-limit.md) - замер: ≈3,3 ГБ без entitlement, ≈6,0 ГБ с increased-memory-limit
* [Model bake-off](model-bakeoff.md) - спайк, шаг 2 на Mac: E4B лучшая по содержанию, E2B — только с маршрутизацией до модели, Bonsai отклонены
* [Model on phone](model-on-phone.md) - спайк, шаг 2 на телефоне: E4B и E2B в llama.cpp — 0,3–0,5 ГБ из 6 ГБ, первый звук p95 1,9 и 1,3 с, детали разговора 7 из 7; русский — у DictationTranscriber
* [Character rendering](character-rendering.md) - ADR (proposed): Rive «2.5D» основным, RealityKit запасным, клипы резервом; решает зонд
* [Persona eval](persona-eval.md) - персона v2: семь кругов на двойнике телефона, итог v2.4 — родитель выбрал живее в 21 паре из 24, безопасность 33 из 45 против 9; частоту и гарантии держит код
