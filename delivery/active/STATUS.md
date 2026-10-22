# Active delivery status

- **slug:** black-box
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** specify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** pending
  <!-- спека с примерами B1–B12, ожидания следующих поставок серии (B13–B22) и вопросы 1–8 (decisions.md) ждут подписи родителя до кода (L33); итог передаёт ведущий -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** n/a reason=поставка не собирает приложение: ядро чёрного ящика в пакете SwiftPM проверяют его тесты в CI на Linux, сборка не оракул (§6.5a); проводку в App, сборку и исполнение на телефоне несёт D3.2
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-blackbox
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; на телефон приложение ставится отдельным решением, а не следствием мержа -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- зависимость, а не остановка: ядро D3 опирается только на протоколы D2 в main; проводка в App (D3.2) — после мержа D1.2 app-voice-loop (PR #35) и D2.2 app-session (сессия в App); звук Элли с выхода (D3.3) — после того, как голос зазвучит через движок приложения -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=ядро чёрного ящика — запись хода, предел, стирание и строка консоли над портами диска и ленты голоса в AllyCore, тесты на Linux; хранилище на телефоне (защита файлов, исключение из бэкапа), выгрузка и стирание через devicectl, отвод её буфера у распознавателя — D3.2, запись голоса Элли с выхода движка — D3.3
- **irreversible_surfaces:** none reason=ядро добавляет функцию стирания без вызывающего; команда стирания на Mac и кнопка консоли появляются в D3.2, там поверхность «стирание чёрного ящика на телефоне» объявляется и подписывается пальцем родителя (sign_irreversible.sh, ключ в анклаве); продукт офлайн, отправки и выкатки нет
- **model_surface:** n/a reason=поставка не трогает промпт, реестр модели и пакет модели: чёрный ящик записывает текст модели до и после контракта и версии, а TurnRunner лишь отдаёт уже накопленный текст ответа, не меняя хода
- **rule_enforcers:** n/a reason=model_surface не объявлена списком; реестр «правило → исполнитель» — knowledge/engineering/safety-below-model.md, D3 правит в нём только строку о журнале нарушений (текст модели до контракта теперь в чёрном ящике)
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** B1–B12 и покрытие AllyCore ≥ 70% зелёные в каждом PR; после D3.2 в живых сессиях режима «дочь при родителе» записей ящика столько же, сколько строк следа, её звук есть у каждой услышанной реплики, сессия в 10 минут занимает ≤ 10 МБ
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
