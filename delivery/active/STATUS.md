# Active delivery status

- **slug:** app-glass
- **stack:** delivery@2.07, cqg@2.74, okf@1.21
- **class:** M
- **kind:** feature
- **repro_test:** n/a reason=не bugfix
- **diagnosis:** n/a reason=не bugfix
- **phase:** implement
- **builder:** agent:claude-code
- **verifier:** process:ci
  <!-- облик судит родитель на глаз по снимкам на Mac (П32); стекло — по снимкам окна, снимков экрана телефона нет (L46) -->
- **human_ok_spec:** yes (by=human:anthony, at=2026-10-27, «Подписываю (Рекомендую)» через ведущего: примеры F1–F5 и вид мок-снимков local/checkpoint/glass-mockups/)
  <!-- вопрос дословно: «Новый дизайн: жидкое стекло и розовое небо, страница „было / стало“ — local/checkpoint/glass-mockups/index.html. Небо идёт от голубизны через сиреневый и розовый к персику. Кнопки — прозрачные стеклянные капсулы. Элли, венок и пузырьки прежние, контраст проверен. Подписываешь вид и пять проверок дизайна?» Варианты: «Подписываю (Рекомендую)» / «Поправить». Ответ: «Подписываю (Рекомендую)». До вопроса ведущий назвал белую подложку под сроком внутри стекла и окно стенда на секунду на экране Mac -->
- **human_ok_plan:** n/a
- **shape-oracles:** cqg-deployed
- **behavior-oracles:** tests-present
- **artifact_oracle:** check_app_artifact.sh
  <!-- F5: MinimumOSVersion 27.0 в собранном .app — ручная macOS-джоба по метке -->
- **ci-oracles:** tooling
- **worktree:** ../Smart frend Ally-wt-glass
- **parallel_sessions:** merge-guard,manual-deploy
  <!-- §5.1a: интеграция в main только через scripts/merge_guard.sh (мержит ведущий); на телефон — в общую сессию теста -->
- **hooks:** not-deployed
- **blockers:** none
  <!-- до мержа — слово родителя о пороге дня V36 0,85 → 0,75 под подписанное небо (поправка в spec.md, decisions.md) -->
- **waivers:** none
- **new_dependency:** none
- **runtime_paths:** none reason=облик: палитра, стекло и стиль кнопок — рисунок SwiftUI с тестами на Mac; вид на телефоне — общая сессия теста
- **irreversible_surfaces:** none reason=продукт офлайн; поставка не добавляет ни отправки, ни трат, ни выкатки, ни публикации
- **model_surface:** App/Resources/persona.v2.4.ru.md,App/Resources/model.json,Packages/AllyLlama/
  <!-- облик поверхность модели не трогает -->
- **rule_enforcers:** knowledge/engineering/safety-below-model.md
- **canon_drift_waiver:** no
- **baseline_growth_waiver:** no
- **observability:** 1
- **observe_signal:** в общей сессии теста родитель видит розовое небо, стеклянную зону взрослых и стеклянные кнопки консоли, надписи читаются днём и ночью; до неё F1–F4 зелёные в каждом PR и на Mac
- **observe_until:** 2026-11-30
- **circuit_breakers:** defaults from AGENT_DELIVERY_HARNESS.md §3.4
