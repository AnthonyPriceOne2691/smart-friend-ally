---
type: Metric
title: Лимит памяти приложения на iPhone 17 Pro Max — замер
description: Сколько памяти iOS даёт одному приложению на нашем телефоне — без entitlement ≈3,3 ГБ, с increased-memory-limit ≈6,0 ГБ; замер делом, а не обещанием системы.
status: stable
tags: [hardware, memory, ios, spike]
generated:
  by: claude_code/opus-5.5
  at: 2026-10-17T12:30:00Z
# Число зависит от версии iOS (П26): перемерить после крупного обновления системы.
stale_after: 2027-04-17T00:00:00Z
# Зонд не код продукта и в дереве не лежит — исходник ниже, для повтора замера.
implementation: []
---

# Purpose

Лимит памяти на приложение — главный ограничитель выбора модели (KNOWLEDGE.md §3):
LLM, распознавание и синтез внутри процесса делят один бюджет, а при превышении iOS
закрывает приложение без ошибки (jetsam). До 2026-10-17 цифры были чужими —
от вендоров и с форумов.

# Значение

| Сборка | `os_proc_available_memory()` на старте | Занято и записано зондом | Остаток | Потолок |
|---|---|---|---|---|
| без entitlement | 3374 МБ | 3200 МБ | 172 МБ | **≈3,3 ГБ** |
| `com.apple.developer.kernel.increased-memory-limit` | 6142 МБ | 5888 МБ | 250 МБ | **≈6,0 ГБ** |

Каждая сборка запущена дважды, числа совпали до мегабайта. Приложение действительно
заняло и записало 5,75 ГБ и не было закрыто — потолок проверен делом.

# Условия замера (П26)

- Телефон: iPhone 17 Pro Max (`iPhone18,2`), физической памяти 11 695 МБ; iOS 27.0.1 (24A446).
- Сборка: Xcode 27.0 (27A266a), Swift 6, deployment target iOS 26.0, Debug.
- Подпись: бесплатная Personal Team; entitlement `increased-memory-limit` выдан профилем
  автоматически — в подписанном артефакте `codesign -d --entitlements` показывает `true`.
- Установка и запуск по локальной сети (`devicectl`, Wi-Fi), без кабеля; дата — 2026-10-17.

# Что это значит для Ally

- **Entitlement обязателен:** без него на всё — LLM, синтез, приложение — 3,3 ГБ.
- **С entitlement бюджет ~6 ГБ подтверждён:** Gemma 4 E4B через LiteRT-LM (1–2 ГБ, не
  замерено) вместе с Supertonic 3 (~1 ГБ) помещаются с запасом; 1-bit Bonsai 27B (пик
  5,2 ГБ) формально помещается, но оставляет меньше 1 ГБ — под синтез внутри процесса
  этого мало (KNOWLEDGE.md §4, §6).
- **Платный аккаунт ради памяти не нужен** — entitlement работает с бесплатной подписью;
  ограничение бесплатной подписи другое: приложение живёт 7 дней (KNOWLEDGE.md §11).

# Как повторить

Каталог зонда — вне репозитория; `xcodegen generate`, затем сборка и запуск:

```bash
xcodebuild -project AllyMemProbe.xcodeproj -scheme MemProbeBig -destination "id=<UDID>" \
  -derivedDataPath build -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
xcrun devicectl device install app --device <UDID> build/Build/Products/Debug-iphoneos/MemProbeBig.app
xcrun devicectl device process launch --device <UDID> --console --terminate-existing com.anthonypriceone.allyprobe.big
```

Первый запуск приложения с бесплатной подписью требует доверия сертификату на телефоне:
Настройки → Основные → VPN и управление устройством.

`project.yml`:

```yaml
name: AllyMemProbe
options:
  bundleIdPrefix: com.anthonypriceone
  deploymentTarget:
    iOS: "26.0"
settings:
  base:
    DEVELOPMENT_TEAM: WSY96FHNM2
    CODE_SIGN_STYLE: Automatic
    SWIFT_VERSION: "6.0"
    GENERATE_INFOPLIST_FILE: YES
    INFOPLIST_KEY_UILaunchScreen_Generation: YES
    TARGETED_DEVICE_FAMILY: "1"
    MARKETING_VERSION: "1.0"
    CURRENT_PROJECT_VERSION: "1"
targets:
  MemProbe:
    type: application
    platform: iOS
    sources: [Sources]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.anthonypriceone.allyprobe
        INFOPLIST_KEY_CFBundleDisplayName: "Ally Probe"
  MemProbeBig:
    type: application
    platform: iOS
    sources: [Sources]
    entitlements:
      path: Big.entitlements
      properties:
        com.apple.developer.kernel.increased-memory-limit: true
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.anthonypriceone.allyprobe.big
        SWIFT_ACTIVE_COMPILATION_CONDITIONS: BIG_MEMORY
        INFOPLIST_KEY_CFBundleDisplayName: "Ally Probe Big"
```

`Sources/MemProbe.swift`:

```text
// Зонд лимита памяти приложения (спайк Smart Friend Ally, KNOWLEDGE.md §3).
// Не код продукта: печатает os_proc_available_memory() и проверяет потолок делом —
// занимает и записывает память кусками по 128 МБ, пока система обещает больше 256 МБ.
import SwiftUI
import os

@main
struct MemProbeApp: App {
    init() { Probe.run() }
    var body: some Scene { WindowGroup { Text("Ally memory probe — см. консоль").padding() } }
}

enum Probe {
    #if BIG_MEMORY
    static let entitlement = "increased-memory-limit"
    #else
    static let entitlement = "none"
    #endif
    nonisolated(unsafe) static var held: [UnsafeMutableRawPointer] = []

    static func mb(_ bytes: Int) -> Int { bytes / (1024 * 1024) }

    static func run() {
        let info = ProcessInfo.processInfo
        let start = os_proc_available_memory()
        print("PROBE start entitlement=\(entitlement) ios=\(info.operatingSystemVersionString) "
              + "physical_mb=\(mb(Int(info.physicalMemory))) available_mb=\(mb(start))")
        let chunk = 128 * 1024 * 1024
        let reserve = 256 * 1024 * 1024
        var taken = 0
        while os_proc_available_memory() > reserve {
            guard let p = malloc(chunk) else { print("PROBE malloc_failed taken_mb=\(mb(taken))"); break }
            memset(p, 0xA5, chunk)          // записать каждую страницу — память занята по-настоящему
            held.append(p)
            taken += chunk
        }
        let left = os_proc_available_memory()
        print("PROBE done entitlement=\(entitlement) taken_mb=\(mb(taken)) left_mb=\(mb(left)) "
              + "ceiling_mb=\(mb(taken + left)) start_available_mb=\(mb(start))")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { exit(0) }
    }
}
```

# Related

- [On-device model](/engineering/on-device-model.md) — выбор модели внутри этого бюджета.

# Sources

- Замер 2026-10-17 (поставка `spike-memory-limit`); KNOWLEDGE.md §3, §12.
