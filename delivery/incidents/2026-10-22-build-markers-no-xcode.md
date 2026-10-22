# Инцидент: правило §6.5a «у артефакта сборки есть оракул» молчит у iOS-проекта

- **Дата:** 2026-10-22 · **Нашедший:** agent:claude-code (сессия smart-frend-ally, поставка `app-voice-loop`) · **Хозяин:** smart-friend-ally
- **Канон:** `scripts/delivery_artifact.py` (`BUILD_MARKERS`, `declares_build`, `check_artifact_oracle`; `delivery@2.07`)

## Симптом

Ally собирает `.app` (XcodeGen `App/project.yml` → Xcode), и именно артефакт решает, уедет ли на телефон сеть или лишнее
право (П24: сборка — не оракул). Правило §6.5a спрашивает `artifact_oracle` только у проекта, который «объявляет шаг
сборки», а маркеры знают три формы: `scripts.build` в `package.json`, цель `build:` в `Makefile` и `justfile`. У
iOS-проекта ни одной — правило не применяется даже на handoff, и объявленный оракул не сверяется с деревом.

## Воспроизведение (Ally, 2026-10-22, канонный код без правок)

```text
declares_build(<корень Ally с App/project.yml и Packages/*/Package.swift>) -> ''
```

Пустая строка — «проект ничего не собирает»: `check_artifact_oracle` выходит до чтения поля. Строка
`artifact_oracle: scripts/lint/check_app_artifact.sh` в STATUS поставки стоит по плану, но гейт её не судит — удаление
скрипта прошло бы молча.

## Что сделано в Ally (канон не правился)

Оракул артефакта — свой гейт `scripts/lint/check_app_artifact.sh` (Info, `nm -u`/`otool -L`, права подписи) с
канарейкой доктора (ключ ATS в бандле) и шагом ручной macOS-джобы `ios.yml`; поле `artifact_oracle` объявлено в STATUS.
Запись `kind: upstream-candidate` в `scripts/lint/adapted.json`.

## Предложение (решает судья)

- `BUILD_MARKERS`: `project.yml` XcodeGen, `*.xcodeproj`/`*.xcworkspace`, `Package.swift` с `.executableTarget` — либо
  поле стека «собирает артефакт» в STATUS, которое правило читает вместо угадывания; проба — iOS-раскладка без
  `artifact_oracle` краснит handoff класса M/L.

## Куда уехало

- поставка `app-voice-loop` Ally; запись `kind: upstream-candidate` в `scripts/lint/adapted.json`;
- сообщение судье (сессия Prepare) после мержа поставки.
