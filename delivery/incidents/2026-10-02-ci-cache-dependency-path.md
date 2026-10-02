# Инцидент: шаблон CI роняет джобу gates на проекте без requirements.txt

- **Дата:** 2026-10-02 · **Нашедший:** agent:claude-code (сессия smart-frend-ally) · **Хозяин:** smart-friend-ally
- **Канон:** `cqg@2.43`, `.github/workflows/quality.yml` (§8.3), шаг `actions/setup-python@v7` джобы `gates`

## Симптом

Первый прогон `quality` (36990914981): `gates` красный за 7 с. Аннотация:
«No file in …/smart-friend-ally matched to [**/requirements.txt or **/pyproject.toml]».

## Что видел нашедший

Охрана шаблона `cache: ${{ hashFiles('**/requirements*.txt', '**/pyproject.toml') != '' && 'pip' || '' }}`
включает pip-кэш, если есть ЛЮБОЙ `requirements*.txt`. А `setup-python` без
`cache-dependency-path` ищет точное `**/requirements.txt`. В проекте только
`requirements-dev.txt`: охрана пропустила, действие упало. Шаги установки и
pre-commit ушли в `skipped`; гейты с `if: always()` отработали — механика §8.3
защитила остальное, как задумано.

## Воспроизведение хозяина

| Прогон | Шаблон | Итог |
|---|---|---|
| 36990914981 | как в каноне | `setup-python` failure, джоба gates красная |
| 36991128518 | + `cache-dependency-path: requirements-dev.txt` | все 11 шагов `success` |

Раскладка: в корне только `requirements-dev.txt`, ни `pyproject.toml`, ни `requirements.txt`.

## Вердикт хозяина

Дефект шаблона, не адаптация: упадёт любой проект, у которого единственный
python-манифест назван не `requirements.txt`. Класс — «шаблон канона несёт
питоновское допущение» (тот же, что канон чинил для Astro, `cqg@1.69`).

## Предложение (решает судья)

Задать `cache-dependency-path` тем же множеством, что и охрана, — многострочным
значением `**/requirements*.txt` и `**/pyproject.toml`. Тогда включённый кэш
всегда находит хотя бы один файл.

## Куда уехало

- `scripts/lint/adapted.json` → `.github/workflows/quality.yml`, `kind: upstream-candidate`;
- сообщение судье (сессия Prepare) после мержа поставки `canon-sync-loop`;
- **судья воспроизвёл по шаблону §8.3** 2026-10-02 (охрана включает pip при `requirements*.txt`, путь для pip не задан, у npm — задан) — очередь судьи, BACKLOG Prepare п.6. Внесение в канон утверждает пользователь; до тех пор `upstream-candidate` в `adapted.json` держится как есть.
