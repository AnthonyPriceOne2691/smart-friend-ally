# Tasks

Уроки по путям диффа (§2.2a): L33, L34, L36, L47, L50, L51, L52 (серия и бюджет), L22, L23, L44 (`App/`, замеры
телефона) — как применены, сказано в `plan.md`.

## V1 `voice-onnx` — эта ветка

### Slice 0 — документы и подпись
- [x] T1: `spec.md` (серия V1–V4, примеры Z1–Z26: таблица V1, списки V2–V4) и `STATUS.md` первым коммитом ветки
  `feat/voice-supertonic`, до кода (L33) — коммит 68202f0
- [x] T2: `plan.md`, `tasks.md`, `decisions.md`, `eval-smoke.md` — вторым коммитом, до кода — коммит bbcd6b3
- [x] T3: подпись родителя под спекой и планом — отдельным коммитом до кода; `human_ok_spec`, `human_ok_plan` → `yes`,
  `phase: implement` (родитель 2026-10-23 «Подписываю (Рекомендую)»: вопросы 3–5 по рекомендациям, 1–2 ждут второй круг;
  ведущий: строки V1 — вариант (а))

### Slice 1 — `Packages/AllyOnnx` (V1a, эта поставка)
- [x] T4: `Package.swift` — `binaryTarget` ORT 1.28.0 (URL и checksum), `COnnxRuntime`, `AllyOnnx`, `linkerSettings`
  (c++, CoreML) — коммит b7399c0
- [x] T5: `Onnx.swift` — окружение, опции, сессия, тензоры, запуск, ошибка; `AllyOnnxTests` (версия и API, нет файла,
  `add.onnx`) — 7 из 7 на Mac
- [x] T6: `scripts/lint/check_single_ort.sh` и отрицательный контроль в джобе `swift` (Z1): пакеты со своим ORT —
  красный, binaryTarget sherpa из releases с условием платформы — зелёный (стык слуха, 2026-10-23)
- [x] T7: шаг тестов AllyOnnx в ручной джобе `ios`

### Slice 2 — проверка и передача V1a
- [x] T8: разрез V1 по готовым коммитам (вариант A ведущего): спека — таблица Z1, Z2–Z7 списком для V1b
- [x] T9: `verify-report.md`, OKF — concept `engineering/onnx-runtime`, `index.md`, `log.md`; PR и CI — ссылка в отчёте
- [x] T10: handoff — архив поставки, строка `INDEX.md` с уроком L53; мерж — ведущий (`merge_guard.sh`)

## V1b `voice-engine` — ветка `feat/voice-supertonic` после мержа V1a

Код и тесты готовы (коммит dbd34be): Z2–Z5, Z7 зелёные на Mac, Z6 — в тихое окно Mac, которое устроит ведущий. Свои
документы, перенос Z2–Z7 таблицей со ссылкой на 68202f0.

## V2–V4 — свои ветки (V2 — отдельный исполнитель, `feat/voice-text`)

Задачи — в их `tasks.md`; примеры — Z8–Z26 этой спеки.
