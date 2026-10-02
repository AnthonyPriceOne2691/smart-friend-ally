# Knowledge Bundle Update Log

## 2026-10-02

* **Initialization**: создан OKF v0.2 bundle (`knowledge/`) при развёртывании контура (`okf@1.19`).
* **Preflight**: upstream SPEC сверен через GitHub API (`raw.githubusercontent.com` из песочницы агента недоступен): `**Version 0.2**` совпадает с pinned `0.2`. После сверки канона (2026-07-26) upstream внёс правку #323 (2026-08-21): каждая метка времени — ISO 8601 datetime с явным смещением, `stale_after` — момент, а не дата. Канон `okf@1.19` её не отражает (пример §3.5 записан датой). Bundle пишет метки по upstream; гейты канона это принимают (`okf_sync_gate` ищет дату внутри строки). Правка канона — за его владельцем.
* **Creation**: seed-concept'ы `product/overview`, `ops/child-data`, `engineering/on-device-model`, `engineering/safety-below-model`, `references/repo-map`.
* **Scope**: `KNOWLEDGE.md` не переносился big-bang — остаётся базой исследования. Концепты фиксируют поверх него принятые решения и инварианты; `implementation:` пока есть только у политики детских данных — кода продукта нет.
