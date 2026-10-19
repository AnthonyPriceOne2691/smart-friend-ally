# Инцидент: `assert_digest.sh` не видит тестов на Swift — `asserts_reviewed_by: n/a` проходит на пустоте

- **Дата:** 2026-10-18 · **Нашедший:** agent:claude-code (сессия smart-frend-ally) · **Хозяин:** smart-friend-ally
- **Канон:** `cqg@2.63` §3 (`scripts/lint/assert_digest.sh`); `delivery@2.04` §3.1d уровень 3, DoD §3.2.7

## Симптом

Первая поставка Ally с кодом (`swift-contour`) добавляет тесты на Swift. Канонная сводка утверждений печатает
«Новых утверждений нет» и `asserts_without_example: 0`, хотя в диффе 12 утверждений `XCTAssert…` (своя
сводка ниже видит все 12). По §3.1d при N = 0
`asserts_reviewed_by: n/a` законен, и `delivery_check` его принимает: ревью ожиданий снято там, где ожидания писал
исполнитель.

## Что видел нашедший

В `assert_digest.sh` три места знают только Python, TS и Go:

- маска диффа `'*test*.py' '*test*.ts' '*test*.tsx' '*_test.go'` — файлы `*Tests.swift` в неё не попадают;
- шаблон утверждения `(assert[a-zA-Z_]*|expect|require|should)[ (]` чувствителен к регистру: `XCTAssertEqual(` не
  совпадает (`#expect(` шаблон берёт — поправка судьи 2026-10-18: в пробе его не было видно из-за маски файлов, а не
  шаблона);
- граница тест-блока `def test|it(|test(|func Test` — Swift-тест `func testX()` блок не открывает.

## Воспроизведение хозяина

Временный репозиторий, ветка от `main` с двумя тестами — `RepairTests.swift`
(`XCTAssertEqual(2 + 2, 5)` и `#expect(1 == 2)`) и `test_probe.py` (`assert 2 + 2 == 5`).
`BASE=main bash scripts/lint/assert_digest.sh`: «утверждений **1**» — только питоновское, `asserts_without_example: 1`.
Без файла на Python тот же прогон дал бы `asserts_without_example: 0` при двух ложных ожиданиях в Swift.

## Вердикт хозяина

Класс тот же, что у гейтов до `cqg@1.67`: проверка, неприменимая к стеку, молчит, а не говорит «не мой язык».
Молчание здесь — разрешение: N = 0 открывает `n/a`.

## Что сделано в Ally (канон не правился)

- `scripts/lint/assert_digest_swift.py` — Swift-половина с тем же договором: только добавленные строки, привязка по
  тест-блоку (id `C<n>` комментарием на строке `func`), последняя строка `asserts_without_example: N`. Режим
  `--check` краснит, когда `verify-report.md` заявляет `asserts_reviewed_by: n/a`, а непривязанные утверждения в
  Swift есть. Подключено в CI (джоба `delivery`).
- Пробы: два ложных утверждения в Swift — `asserts_without_example: 2`; `n/a` над ними — exit 1, подпись
  `human:… at=…` — exit 0.
- В `scripts/lint/adapted.json` — запись `kind: upstream-candidate` у `assert_digest.sh`.

## Предложение (решает судья)

Канонной сводке — либо маски и шаблоны для Swift (`*Tests.swift`, `XCTAssert\w*(`, `XCTFail(`, `#expect(`,
`#require(`, блок `func test`), либо отказ вслух: «в диффе есть тесты на языке, которого сводка не знает» с
`asserts_without_example: unknown`, при котором `delivery_check` не принимает `n/a`.

## Куда уехало

- поставка `swift-contour` Ally;
- сообщение судье (сессия Prepare) после мержа поставки.

## Итог

Судья `prepare-ae` записал находку в BACKLOG канона (Prepare `0c642c2`, 2026-10-18) и сверил с кодом; правка канона —
следующей партией. Поправки судьи: `#expect(` шаблон утверждения берёт, дыра — в населении (файлы `*Tests.swift` до
разбора не доходят), а `XCTAssert…` и блоки `func test…` / `@Test func` не берутся; шапка `assert_digest.sh` обещает
настройку `LINT_TEST_GLOB`, но в коде её нет — расширить маску проектом нельзя. Направление для канона: ноль должен
отличаться от «не видел» (`asserts_without_example: unknown` при тест-файлах на неразбираемом языке, `n/a` не
принимается). `assert_digest_swift.py --check` записан образцом.

Канон впитал находку в `cqg@2.68` + `delivery@2.06` (Prepare `9a8f592`): маски из `LINT_TEST_GLOB` (по умолчанию и
`*Tests.swift`, `*Test.swift`), разбор `XCTAssert…`, `XCTFail`, блоков `func test…` и `@Test`, тест-файл вне масок —
`asserts_without_example: unknown`, и `delivery_check` не принимает над ним `n/a`. Накат в Ally — поставка
`sync-cqg-2.70` (Prepare `76c42c3`): свой `assert_digest_swift.py`, его шаг CI и запись `upstream-candidate` сняты.
Проверено исполнением на временной ветке: `XCTAssertEqual(2 + 2, 5)` в `ProbeTests.swift` — канонная сводка «1, без
ссылки на пример 1», `asserts_without_example: 1` (сводка до наката на том же коммите — «Новых утверждений нет», 0);
тест-файл `DigestSpec.swift` вне масок — `unknown` со списком; `delivery_check` отказывает `n/a` и при `2`, и при
`unknown`. Маски проекта не понадобились: раскладка SwiftPM видна по умолчанию. Остаток (решает человек): CI больше не
пересчитывает сводку сам, как делал `--check`, — `delivery_check` судит строку, вставленную в verify-report.
