# Tasks

Уроки архива: П24/§11 KNOWLEDGE — проверять собранный артефакт (`plutil -p`,
`codesign -d --entitlements`), а не исходники; П25 — одна установка, одна
рисковая правка; П26 — каждый замер несёт версии.

## Slice 1 — лимит памяти приложения на iPhone 17 Pro Max
- [ ] T1: зонд (вне репозитория): `os_proc_available_memory()` на старте и занятие памяти кусками по 128 МБ до запаса 256 МБ — потолок проверяется делом, без убийства процесса
- [ ] T2: две цели: без entitlement и с `com.apple.developer.kernel.increased-memory-limit`; артефакт сверен `plutil -p` и `codesign -d --entitlements`
- [ ] T3: установка и запуск по сети (`devicectl`), вывод снят дословно; замер повторён дважды
- [ ] T4: результат с версиями (iOS, Xcode, модель телефона) — `knowledge/engineering/memory-limit.md` и KNOWLEDGE.md §3; исходник зонда — в концепте
