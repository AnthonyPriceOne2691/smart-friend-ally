# Active delivery status

- **slug:** story-mode
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-30, «Подписываю: три мостика по кругу (Рекомендую)» через ведущего: мостики, слова префикса сказки, пределы и примеры T1, T2, T4 spec.md)
  <!-- спека и STATUS — коммит ffa26d6 до кода (L33); строку подписи вписал ведущий, вопрос дословно — spec.md «Подпись» -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
  <!-- T1–T8, T10, T11, T14 — тесты Discipline и AllyCore на Linux (двойник модели, виртуальные часы, корпус фикстур);
       T9, T12, T13, паритет T8 и A23 — в следующей поставке story-model (AllyLlama с весами и прогон на Mac по «можно»
       ведущего); правило суда прогона — spec.md, записано до прогона -->
- **artifact_oracle:** scripts/lint/check_app_artifact.sh — собранный .app без подписи (сеть, ключи Info, права подписи)
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-story-mode
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: в main только через scripts/merge_guard.sh; на телефон — отдельным решением родителя. Параллельно:
       sim-app, background-music, app-icon (App/, ShellCore), отбор моделей (стенд bakeoff2 вне git — не трогаю, беру
       копии). Общие файлы: VoiceLoop.swift, Session.swift, TurnTrace.swift, knowledge — правки минимальные, слияние
       сложением, перед финальным пушем — свежий main; канон — вариант D, docs/canon копией под exclude -->
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=меняются только ядра Discipline и AllyCore (судятся на Linux в CI); приложение и пакет модели не трогаю — модель сказки сессия получит в следующей поставке story-model, там же рисковый путь App/Sources/
- **irreversible_surfaces:** none reason=продукт офлайн; режим сказки только читает данные из бандла пакета: отправки, трат, стирания, выкатки и публикации нет; установка на телефон — отдельным решением родителя
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.ru.jsonl,Packages/AllyCore/Sources/AllyCore/Resources/encyclopedia.json,Packages/AllyCore/Sources/AllyCore/Knowledge.swift,Packages/AllyCore/Sources/AllyCore/Encyclopedia.swift,Packages/AllyMemory/Sources/Memory/Resources/memory.json,Packages/AllyMemory/Sources/Memory/MemoryBlock.swift,Packages/AllyMemory/Sources/Memory/BlockLines.swift
  <!-- §14.1: список снимка main без изменений: в этой поставке вход модели в приложении прежний (модели сказки у
       сессии нет, T14). Слова префикса сказки, story.json и правило намерения войдут в поверхность в story-model, где
       они начнут решать, какой префикс получит модель -->

- **rule_enforcers:** knowledge/engineering/safety-below-model.md
  <!-- §14.2a: правила слов сказки («пять–восемь предложений», «без страшного») — строки реестра: пределы держит режим
       story контракта, страшное — advisory, как у персоны -->
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** T1–T8, T10, T11, T14 и покрытие Discipline и AllyCore ≥ 70% зелёные в каждом PR; после story-model в чёрном ящике — доля ходов `story`, ходы сказки без правила `limits`, тишина `story_first_sound − bridge_end`, ходы с `story.fresh`
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
