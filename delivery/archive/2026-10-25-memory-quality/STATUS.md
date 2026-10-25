# Active delivery status

- **slug:** memory-quality
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** handoff
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-23, «Подписываю (Рекомендую)» под спекой серии: ожидание M32 и его пороги — дословно в колонке ожидания spec.md)
  <!-- спека серии — коммиты 21d556c и 4a94261, подпись — 37bb5a9 (archive/2026-10-23-memory-core); разрез —
       ведущий 2026-10-23; правило суда в строке «Здесь:» записано агентом до прогонов и коммитом до них (L19), новых
       ожиданий не вводит -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** weak — дёшево: ничего; замер на Mac — результат: числа M32 в eval-smoke и knowledge; стенд вне git (решение ведущего 2026-10-25), его оракулы — правило суда, закоммиченное до прогона, и счётчик со сверкой хэша свежего набора
- **artifact_oracle:** n/a reason=поставка не собирает приложение: замер кода пакета памяти на E4B через llama-server на Mac, стенд вне git
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-memory-quality
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh; параллельно: поставка канона «вариант D»
       (docs/canon уходит из git — после слияния main каталог возвращается копией из основного клона), голос, речь,
       оболочка; конфликты в INDEX.md, OBSERVATIONS.md, knowledge — сложением -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- M32 на свежем наборе ниже порогов (точность 0,696 по эталону, 0,899 после слепого разбора; полнота 0,792) —
       родитель 2026-10-25: «Принять как замер (Рекомендую)», by=human:anthony; вопрос и ответ — escalation.md -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=замер на Mac вне продукта: прогонщик в local/ зовёт llama-server на 127.0.0.1; на телефон ничего не ставится
- **irreversible_surfaces:** none reason=замер пишет только во временные базы прогона и в local/; стирания, отправки наружу, трат, выкатки и публикации нет
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/,Packages/AllyMemory/Sources/Memory/Resources/extract.system.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.user.ru.md,Packages/AllyMemory/Sources/Memory/Resources/extract.json
  <!-- §14.1: поверхность модели разбора меряется, а не меняется; правка промпта по прогону справки — новая
       поверхность, тогда блок «Изменение поверхности модели» в verify-report и повтор прогона справки (L25) -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** числа M32 в eval-smoke; после memory-app в живых сессиях дочери при родителе — в памяти нет ловушек справки (чужих питомцев, вымысла, устаревшего), «не разобрана» редка
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
