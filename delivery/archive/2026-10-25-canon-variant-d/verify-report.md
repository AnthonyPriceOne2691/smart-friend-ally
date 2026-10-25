# Verify report

**Date:** 2026-10-25
**Verifier:** process:ci
**asserts_reviewed_by:** n/a (класс S; перевод раскладки канона на вариант D — тестов поставка не добавляет и не меняет, дайджест ниже, asserts_without_example: 0)
**CI run:** https://github.com/AnthonyPriceOne2691/smart-friend-ally/actions/runs/40216496375 (PR #71, коммит 5cee52e: `gates`, `delivery`, `swift` — зелёные; `mergeable: true`, `clean` — проверено до ссылки, L35)
**Commit:** 5cee52e (вариант D — 364f499, слияние main — e0a32ac, находка о докторе — 7190539, слияние main — 5cee52e; сдача — следующим коммитом, PR #71)

## Shape oracles
- [x] PASS — чистый checkout головы ветки (`git worktree add --detach`, каталога `docs/` нет): `pre-commit run --all-files
  --verbose` exit 0 за 5,4 с; `file-length` просмотрел 192 файла, secrets — 75 файлов на пачку, child-data — 748 файлов,
  данных ребёнка нет; ратчет SwiftLint — 180 файлов, находок 0; хук `canon-texts-stay-out` — «no files to check»
- [x] PASS — `check_gate_coverage.sh` (STRICT=1): OK — 21 скрипт, подключено 11, осознанно нет 10. Первый коммит с
  рецептом хука §7.1a дословно мета-гейт отклонил: «незаполненный шаблон в конфиге контура — `<путь>`». Сообщение
  хука — команда снятия, после этого OK (находка `2026-10-25-variant-d-hook-reads-as-template`)
- [x] PASS — `okf_validate.py knowledge/`: 0 ошибок, 0 предупреждений (52 файла); `okf_sync_gate.py --base origin/main`:
  OK (18 концептов с картой реализации)
- [x] PASS — CI (прогон выше), где `docs/canon/` нет: toolchain — `detect-secrets swiftlint jscpd`; `file-length` — 200
  файлов, child-data — 772, SwiftLint — 188, находок 0; хук `canon-texts-stay-out` — «no files to check»; `gate-coverage`
  OK; доктор `AUTO 42 · WEAK 10 · ABSENT 8 · TOOL 3 · SKIP 6 · DEAD 0` (main до перевода, 4bccc39 — `AUTO 46 · WEAK 12 ·
  ABSENT 4 · TOOL 3 · SKIP 5 · DEAD 0`; разница — четыре канона `AUTO → ABSENT`, провенанс `AUTO → SKIP`, две строки
  сверки конфигов пропали, плюс строки активной поставки); джоба delivery — `delivery_check` 0/0, smoke `6 PASS · пропуск:
  S3 …`, шаг selftest — «каноны вне репо — вариант B/D; объявление найдено»; джоба swift — покрытие пакетов 84–99%
- [x] PASS — ссылки на `docs/canon` (≈34 отслеживаемых файла) — упоминания в бэктиках, markdown-ссылок на канон нет;
  `okf_validate` судит только ссылки вида `](/…md)` внутри `knowledge/` (мягко), `okf_sync_gate` — `implementation:`,
  линк-чекеров в контуре нет — ни один гейт их не судит, правок не нужно
- [x] PASS — доктор с env джобы `gates`: ворктри со снимком — `AUTO 47 · WEAK 13 · ABSENT 4 · TOOL 3 · SKIP 4 · DEAD 0`;
  чистый checkout — `AUTO 42 · WEAK 11 · ABSENT 8 · TOOL 3 · SKIP 5 · DEAD 0`. Шаг CI роняет только `DEAD`, ратчета или
  снимка на счёт доктора нет. Разница — цена D: четыре канона `ABSENT` («слой не развёрнут»), провенанс `SKIP`, две
  строки сверки конфигов с каноном пропали; состав по замку — `AUTO 56 из 57` (находка
  `2026-10-25-doctor-variant-d-reads-as-absent`)

## Behavior oracles
- [x] PASS — `extract_payload.py --check-local "<ворктри>"`: **отслеживается 0, без игнора 0**. Обратные прогоны:
  основной клон до мержа — отслеживается 9; свежий клон без строки в `exclude` и с разложенным снимком — без игнора 1,
  exit 1; та же копия со строкой `/docs/canon/` — 0 и 0
- [x] PASS — хук в свежем клоне (своё `.git/info/exclude` без строки): снимок `git add -A` встаёт в индекс, `pre-commit
  run canon-texts-stay-out` — exit 1, названы все 9 файлов и команда снятия; после `git reset` — «no files to check»
- [x] PASS — smoke в чистом checkout (`CI=1`): `smoke: 6 PASS · пропуск: S3 — снимка docs/canon/ нет: вариант D…`,
  exit 0. Обратные прогоны: без строки `stack-selftest:` в STACK-ACCEPTANCE — «FAIL S3 … вариант не объявлен», exit 1;
  прежний `run.sh` из `origin/main` в том же checkout — «FAIL S3», exit 1 (безусловный S3 ронял бы шаг smoke в CI)
- [x] PASS — шаг CI «Canon payload selftest», вынутый из `quality.yml` и прогнанный в чистом checkout: «каноны вне репо
  — вариант B/D; объявление найдено, инвариант назван», exit 0; без объявления — `::error::снимка канонов в репо нет`,
  exit 1
- [x] PASS — строгий `delivery_check --diff-base origin/main` в ворктри и в чистом checkout: 0 ошибок, 0 предупреждений
  (breakers: 1 файл вне исключений — `CLAUDE.md`, +1/−1)
- [x] PASS — слияние перевода в другой копии: свежий клон main (в git 9 файлов `docs/canon/`) со строкой в `exclude`,
  `git merge --squash` ветки и коммит — `docs/canon/` удалён. `git restore --source=<коммит удаления>^ --worktree --
  docs/canon` вернул 9 файлов: `git status` чист, `git ls-files docs/canon` пуст, sha256 7 из 7, `--check-local` 0 и 0

## Product oracles
- [x] PASS — `stack_selftest.py docs/canon` по локальному снимку: 121 блок, 51 пропущен, 0 ошибок (`cqg@2.74`);
  `SHA256SUMS` снимка — 7 из 7
- [x] PASS — smoke: S1, S2, S4, S6, S7, S8 зелёные, S3 — названный пропуск без снимка (выше); S5 в CI — джоба swift. Код
  продукта поставка не трогает (`Packages/`, `App/` — только из слияния main)

## Ревью рисковых мест

- **цепочка гейтов — риск разобран:** `.pre-commit-config.yaml` получил один локальный хук `language: fail` с маской
  текстов контура — продуктовых файлов маска не ловит (рецепт и его оракул согласия канона); у
  `check-added-large-files` снято исключение `^docs/canon/` — других исключений не было, снимка в git нет. Состав
  гейтов и строки вызова не тронуты; мета-гейт и pre-commit по всему дереву в чистом checkout зелёные (выше). Smoke S3
  судит код возврата самопроверки, а пропуск только при объявлении варианта, оба обратных прогона красные.
- **безопасность — риска нет, потому что** поставка ничего не добавляет в публичный репозиторий: тексты канона уходят
  из индекса, база секретов не менялась, `detect-secrets` в чистом checkout — 0 находок. Старые версии текстов
  остаются в истории (её не переписываем — решение родителя), это остаток в STACK-ACCEPTANCE.

## Spec coverage gaps
- Самопроверка канонов, провенанс снимка, версии в шапках канонов и сверка `.pre-commit-config.yaml` и `quality.yml` с
  шаблоном в CI не судятся — цена варианта D (§7.1a), остаток записан в STACK-ACCEPTANCE; локально их судят S3 и
  доктор со снимком.
- `git add -f` игнор обходит, исключение в новый клон не приезжает — компенсация: хук и `pre-commit run --all-files` в
  CI (остаток в STACK-ACCEPTANCE).
- После мержа основной клон теряет локальный снимок — восстановление одной командой (PR #71); у остальных ворктри
  снимок пропадёт при слиянии main, нужен он только для чтения канона и локального S3.

## Assertion digest (ревью ожиданий, не кода)

База: `origin/main` · сгенерировано `assert_digest.sh`

**Новых утверждений нет.**

Это либо тесты не добавлялись (тогда чем закрыт DoD?), либо изменения
только в реализации. Второе законно; первое — повод спросить.

asserts_without_example: 0

Тестов поставка не добавляла: перевод раскладки канона, DoD закрыт пробами исполнением и гейтами (разделы выше).

## Verdict
- [x] READY FOR HANDOFF
- [ ] NEED CONVERGE (new tasks)
- [ ] BLOCKED

## Harness metrics (this shipment)

| Metric | Value |
|---|---|
| files_touched / loc_diff | 16 файлов вне `docs/canon/` (+386/−17 против `origin/main`, со сдачей и архивом), 9 файлов `docs/canon/` сняты с индекса (−26 394, на диске остаются); вне исключений breaker'а — 1 файл (`CLAUDE.md`), +1/−1 |
| commits | 4 до verify (вариант D, находка о докторе, два слияния main) |
| rework_after_done | 0 |
| harness_hardened | yes — хук `canon-texts-stay-out` (запрет, который едет с клоном) и S3, который судит объявление варианта вместо безусловного прогона; две находки наверх |
| implement_retries | 1 — первый коммит отклонил мета-гейт: рецепт хука §7.1a с путём в угловых скобках |
| verify_fails_before_green | 1 — PR #71 не получил прогона: GitHub считал его `dirty` из-за `knowledge/log.md`, который локально сливает `merge=union`, пока ветка не слила main (L35); первый прогон — на 5cee52e, зелёный |
| est_token_or_cost | n/a |
