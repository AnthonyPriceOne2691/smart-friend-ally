# Active delivery status

- **slug:** contour-bootstrap
- **stack:** delivery@1.98, cqg@2.43, okf@1.19
- **class:** M
- **kind:** bootstrap
- **repro_test:** n/a reason=не bugfix: развёртывание контура, кода продукта нет
- **diagnosis:** n/a reason=не bugfix
- **phase:** verify
- **builder:** agent:claude-code
- **verifier:** process:ci
- **human_ok_spec:** deferred (reason=цель «обязательно развернуть контур» дана устно 2026-10-02, примеры A1–A7 человек ещё не видел; на handoff нужна подпись, at=2026-10-02)
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
  <!-- гейты подключены и судят (доктор: DEAD 0); Swift-роли объявлены n/a до первого кода -->
- **behavior-oracles:** weak — дёшево: канарейка гейта детских данных (доктор, `canaries.json`); тестов продукта нет, потому что нет кода
- **artifact_oracle:** n/a reason=проект пока ничего не собирает: Xcode-проекта нет
- **ci-oracles:** tooling
  <!-- по факту прогона 36991128518 (success, все шаги исполнены). Гейт мержа — merge_guard.sh в репозитории; серверной защиты ветки нет: приватный репо на бесплатном тарифе. Остаток: force-push и обход админом не закрыты -->
- **worktree:** none (bootstrap трогает дерево контура целиком, §7.2 шаг 6)
- **hooks:** not-deployed
- **blockers:** none
- **waivers:** none
- **new_dependency:** requirements-dev.txt reason=новый манифест инструментов контура: pre-commit (оркестратор гейтов, CQG §4), detect-secrets (secrets-гейт §2.7), PyYAML (stack_selftest без парсера молчит); отвергнуты голые git-хуки и gitleaks — канон и доктор читают .pre-commit-config.yaml и .secrets.baseline by=agent:claude-code
- **runtime_paths:** none reason=кода продукта нет; пути (микрофон, права, аудиосессия, entitlement памяти) объявляются первой поставкой с iOS-кодом — KNOWLEDGE.md §11
- **irreversible_surfaces:** none reason=продукт офлайн: отправки наружу, денег, прода и публикации нет; приватный репозиторий GitHub создаётся с согласия пользователя 2026-10-02 и данных ребёнка не содержит
- **model_surface:** n/a reason=модель продукта ещё не вызывается: промптов, пина и параметров нет; появятся с первой поставкой голосового цикла (KNOWLEDGE.md П10)
- **rule_enforcers:** n/a reason=model_surface не объявлена списком: правил промпта ещё нет
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** A2, A4 держатся в использовании: следующая поставка проходит merge_guard без обходов, доктор в CI — DEAD 0; ни одного коммита с аудио или базой (child-data в CI на main)
- **observe_until:** 2026-10-16
- **circuit_breakers:** exempt (kind: bootstrap, §3.4 — развёртывание трогает всё дерево контура и не режется на части)
