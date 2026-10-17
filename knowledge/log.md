# Knowledge Bundle Update Log

## 2026-10-17 — замер лимита памяти на телефоне

* **Creation**: `engineering/memory-limit` (Metric): без entitlement потолок ≈3,3 ГБ (3374 МБ на старте), с `increased-memory-limit` ≈6,0 ГБ (6142 МБ); зонд занял и записал 5,75 ГБ без вылета; entitlement выдан бесплатной Personal Team. Исходник зонда — в концепте.
* **Update**: `engineering/on-device-model` — контекст ADR опирается на замер, а не на цифры вендора.

## 2026-10-02 — решения о персонаже, сессии и чёрном ящике

* **Creation**: `product/persona` (подруга, голос девочки; кандидаты — Supertonic 3 F2 и производные; чужой голос не клонируется), `product/session-limit` (мягкие 10 минут), `ops/black-box` (текст и звук каждой сессии, выгрузка только на Mac без облака).
* **Update**: `product/overview` и `ops/child-data` — граница «данные не покидают телефон» уточнена: единственный выход — выгрузка родителем на свой Mac; `engineering/safety-below-model` — журнал нарушений живёт в чёрном ящике.
* **Источник**: решения пользователя 2026-10-02; голоса Supertonic сверены по официальной документации (`supertone-oss-archive/supertonic-py`, `docs/voices.md`).

## 2026-10-02

* **Initialization**: создан OKF v0.2 bundle (`knowledge/`) при развёртывании контура (`okf@1.19`).
* **Preflight**: upstream SPEC сверен через GitHub API (`raw.githubusercontent.com` из песочницы агента недоступен): `**Version 0.2**` совпадает с pinned `0.2`. После сверки канона (2026-07-26) upstream внёс правку #323 (2026-08-21): каждая метка времени — ISO 8601 datetime с явным смещением, `stale_after` — момент, а не дата. Канон `okf@1.19` её не отражает (пример §3.5 записан датой). Bundle пишет метки по upstream; гейты канона это принимают (`okf_sync_gate` ищет дату внутри строки). Правка канона — за его владельцем.
* **Creation**: seed-concept'ы `product/overview`, `ops/child-data`, `engineering/on-device-model`, `engineering/safety-below-model`, `references/repo-map`.
* **Scope**: `KNOWLEDGE.md` не переносился big-bang — остаётся базой исследования. Концепты фиксируют поверх него принятые решения и инварианты; `implementation:` пока есть только у политики детских данных — кода продукта нет.
