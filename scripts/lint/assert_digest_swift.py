#!/usr/bin/env python3
"""Assertion digest for Swift tests — the Swift half of the canon `assert_digest.sh` (CQG §3, Delivery §3.1d).

The canon digest reads only `*test*.py`, `*test*.ts(x)` and `*_test.go`, and its assertion pattern is lower-case
`assert…`, so `XCTAssertEqual(2 + 2, 5)` and `#expect(1 == 2)` in a Swift test are invisible to it: with Swift tests
only it prints «no new assertions», and `asserts_reviewed_by: n/a` passes on emptiness
(delivery/incidents/2026-10-18-assert-digest-swift.md, kind upstream-candidate in adapted.json).

Same contract as the canon script: only ADDED lines of test files against the base; binding to a spec example is
judged PER TEST BLOCK (the id `C2` sits in a comment on the `func` line or inside the block, never glued to the
name — `testC2` does not count; the assertion itself does not carry it); the
last line `asserts_without_example: N` is the input of the decision (`n/a` is lawful only at N = 0).

  python3 scripts/lint/assert_digest_swift.py                  # base origin/main
  BASE=main python3 scripts/lint/assert_digest_swift.py >> delivery/active/verify-report.md
  python3 scripts/lint/assert_digest_swift.py --check          # CI: red when verify-report says n/a over bare asserts
"""
import os
import re
import subprocess
import sys

BLOCK = re.compile(r"\bfunc\s+test\w*\s*\(|@Test\b")
EXAMPLE_ID = re.compile(r"(?<![A-Za-z0-9_])[A-Z][0-9]+(?![A-Za-z0-9_])")
VERIFY_REPORT = "delivery/active/verify-report.md"
ASSERTION = re.compile(r"\bXCT(Assert\w*|Fail|Unwrap)\s*\(|#(expect|require)\s*\(")


def added_test_lines(base):
    out = subprocess.run(["git", "diff", "%s...HEAD" % base, "--", "*Tests.swift", "*Test.swift"],
                         capture_output=True, text=True, check=False)
    if out.returncode != 0:
        sys.stderr.write("assert_digest_swift: git diff against '%s' failed: %s\n" % (base, out.stderr.strip()))
        sys.exit(0)
    return [ln[1:] for ln in out.stdout.splitlines() if ln.startswith("+") and not ln.startswith("+++")]


def classify(lines):
    rows, cur = [], ""
    for line in lines:
        if BLOCK.search(line):
            cur = ""
        m = EXAMPLE_ID.search(line)
        if m:
            cur = m.group(0)
        if ASSERTION.search(line):
            rows.append((cur or "-", line.strip()))
    return rows


def main():
    top = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=False)
    if top.returncode == 0:
        os.chdir(top.stdout.strip())
    base = os.environ.get("BASE", "origin/main")
    rows = classify(added_test_lines(base))
    bare = sum(1 for tag, _ in rows if tag == "-")
    print("## Assertion digest — Swift (`assert_digest_swift.py`)\n")
    print("База: `%s`. Новых/изменённых утверждений: **%d**, без ссылки на пример спеки: **%d**.\n" % (
        base, len(rows), bare))
    if rows:
        print("```")
        for tag, line in rows:
            print("%s\t%s" % (tag, line))
        print("```\n")
    if rows and bare == 0:
        print("Все утверждения ведут к примерам спеки: `asserts_reviewed_by: n/a` законен, когда примеры подписаны.\n")
    elif bare:
        print("Строки с `-` в первой колонке не подписаны никем: `asserts_reviewed_by: human:… at=…`.\n")
    print("asserts_without_example: %d" % bare)
    if "--check" in sys.argv[1:] and bare and os.path.isfile(VERIFY_REPORT):
        field = re.search(r"asserts_reviewed_by:\*{0,2}\s*(.*)", open(VERIFY_REPORT, encoding="utf-8").read())
        if field and field.group(1).strip().lower().startswith("n/a"):
            sys.stderr.write("assert_digest_swift: %s claims asserts_reviewed_by n/a, but %d Swift assertion(s) "
                             "lead to no spec example — sign them (human:… at=…) or bind each test to its example "
                             "id with `// C<n>` on the func line\n" % (VERIFY_REPORT, bare))
            sys.exit(1)


if __name__ == "__main__":
    main()
