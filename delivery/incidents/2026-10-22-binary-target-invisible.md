# Инцидент: гейт новой зависимости не видит `.binaryTarget` в существующем манифесте SwiftPM

- **Дата:** 2026-10-22 · **Нашедший:** agent:claude-code (сессия smart-frend-ally, поставка `app-voice-loop`) · **Хозяин:** smart-friend-ally
- **Канон:** `scripts/lint/dependency_manifests.py` (`names_swift`), `scripts/lint/check_new_dependency.py` (`cqg@2.70`)

## Симптом

Поставка `app-voice-loop` тянет рантайм модели — llama.cpp b10809 — как `.binaryTarget(name:url:checksum:)` в новом
манифесте `Packages/AllyLlama/Package.swift`. Гейт требует объявления, но только потому, что манифест новый целиком: имя
бинарной зависимости он не извлекает. Тот же `.binaryTarget`, добавленный в уже существующий манифест, прошёл бы гейт
молча — новая внешняя бинарная зависимость без строки `new_dependency` в STATUS.

## Воспроизведение (Ally, 2026-10-22, канонный код без правок)

```text
names_swift(Packages/AllyLlama/Package.swift)                         -> set()
names_swift(тот же текст + .package(url: "https://github.com/x/y.git")) -> {'y'}
```

Разбор `names_swift` ищет только `.package(name:|url:)`; `.binaryTarget(url:)` — ни имени, ни url. У существующего
манифеста гейт сравнивает множества имён базы и HEAD — они равны, и добавленный бинарь не виден.

## Что сделано в Ally (канон не правился)

В STATUS поставки — две строки `new_dependency`: путь нового манифеста (её требует гейт) и отдельная
`llama.cpp-b10809` с причиной, лицензией и sha256 ассета — чтобы бинарь был объявлен по имени, а не через манифест.
Запись `kind: upstream-candidate` в `scripts/lint/adapted.json`.

## Предложение (решает судья)

- `names_swift`: извлекать `.binaryTarget(name:)` (и `url:` как источник); проба канона — `.binaryTarget`, добавленный в
  существующий манифест, краснит гейт без строки в STATUS.

## Куда уехало

- поставка `app-voice-loop` Ally; запись `kind: upstream-candidate` в `scripts/lint/adapted.json`;
- сообщение судье (сессия Prepare) после мержа поставки.
