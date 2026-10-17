#!/usr/bin/env python3
"""Parity fixtures for Repair (Swift): real model replies and what the Python reference makes of them. Stdlib only.

Reference (outside git, local/ of the main clone): strip_markup, symbols_to_words, latin_to_cyrillic, digits_to_words
of local/spike/discipline/output_filter.py and strip_endearments of local/spike/persona-v2/judge_sheet.py, in
Repair.apply's order. Placeholders (judge_sheet.PLACEHOLDER) go first: after strip_markup its bracket rule leaves
«Привет,!» or «Ой,,» (11 replies of the corpus), and the placeholder rule never fires.
Inputs: `response` or `reply` of persona-v2/results/*.jsonl and bakeoff/results/*.jsonl; up to 90 replies the
reference changes, round-robin over what fired (rarest first), and up to 20 it keeps (endearment words first);
inside a group, sha256 order. Checks first that repair.json holds the reference's tables and words.

  python3 -I Packages/AllyDiscipline/Tests/DisciplineTests/Fixtures/make_fixtures.py
"""
import sys

sys.dont_write_bytecode = True  # the reference sits in local/: no __pycache__ there

import collections  # noqa: E402
import glob  # noqa: E402
import hashlib  # noqa: E402
import json  # noqa: E402
import re  # noqa: E402
from pathlib import Path  # noqa: E402

SPIKE = Path("/Users/anthony/Documents/Smart frend Ally/local/spike")
sys.path[:0] = [str(SPIKE / "discipline"), str(SPIKE / "persona-v2")]
import judge_sheet as js  # noqa: E402
import output_filter as of  # noqa: E402

HERE = Path(__file__).resolve().parent
DATA = json.loads((HERE.parents[2] / "Sources/Discipline/Resources/repair.json").read_text(encoding="utf-8"))
CHANGED, UNCHANGED = 90, 20


def check_data():
    """repair.json is the one copy of the data, so it must hold what the reference holds."""
    e, n = DATA["endearment"], DATA["numbers"]
    own, word = "(?:%s\\s+)?" % e["own_re"], "(?:%s)" % "|".join(e["words"])
    alone = r"(^|(?<=[.!?…]\s))" + e["alone_re"] + own + word + r"\s*[!.…]+\s*"
    tail = r"\s+" + e["own_re"] + r"\s+(?:%s)" % "|".join(e["tail_words"]) + r"\s*(?=[!?.…])"
    checks = {"en_words": (DATA["en_words"], of.EN_WORDS), "homoglyph": (DATA["homoglyph"], of.HOMOGLYPH),
              "translit": ([tuple(p) for p in DATA["translit"]], of.RU_TRANSLIT),
              "symbols": ([tuple(p) for p in DATA["symbols"]], of.SYMBOLS),
              "numbers": ([n["units"], n["teens"], n["tens"], n["hundreds"]], [of.UNITS, of.TEENS, of.TENS, of.HUNDREDS]),
              "endearments": ((own, word, alone, tail), (js.OWN, js.WORD, js.ALONE.pattern, js.TAIL.pattern))}
    for name in (k for k, (got, want) in checks.items() if got != want):
        sys.exit("repair.json: %s differs from the reference" % name)


def repair(text):
    """The reference in Repair.apply's order: the repaired text and what fired (used only for picking)."""
    t = js.PLACEHOLDER.sub("", text)
    fired = {"placeholder"} if t != text else set()
    log = []
    for step in (of.strip_markup, of.symbols_to_words, of.latin_to_cyrillic, of.digits_to_words):
        t = step(t, log)
    fired |= {detail if rule == "markup" else rule for rule, detail in log}
    fired |= {"phone_like"} if "⟦PHONE⟧" in t else set()
    fired |= {"lines"} if "\n" in text.strip() else set()
    fired |= {"endearment"} if js.TAIL.sub("", js.START.sub("", js.MID.sub("", js.ALONE.sub("", t)))) != t else set()
    out = js.strip_endearments(t)
    return out, fired or ({"case"} if out != text else set())


def replies():
    found = set()
    paths = sorted(glob.glob(str(SPIKE / "persona-v2/results/*.jsonl")))
    for path in paths + sorted(glob.glob(str(SPIKE / "bakeoff/results/*.jsonl"))):
        for line in open(path, encoding="utf-8"):
            row = json.loads(line) if line.strip() else {}
            text = row.get("response") or row.get("reply")
            if isinstance(text, str) and text.strip():
                found.add(text)
    return sorted(found, key=lambda s: hashlib.sha256(s.encode()).hexdigest())


def main():
    check_data()
    done = {x: repair(x) for x in replies()}
    queues = collections.defaultdict(list)
    for x, (out, fired) in done.items():
        for kind in fired if out != x else ():
            queues[kind].append(x)
    order = sorted(queues, key=lambda k: (len(queues[k]), k))
    picked = []
    while len(picked) < CHANGED and any(queues.values()):
        for kind in order:
            queue = queues[kind]
            while queue and queue[0] in picked:
                queue.pop(0)
            if queue and len(picked) < CHANGED:
                picked.append(queue.pop(0))
    same = sorted((x for x, (out, _) in done.items() if out == x), key=lambda s: not re.search(js.WORD, s, re.I))
    rows = picked + same[:UNCHANGED]
    with open(HERE / "repair_parity.jsonl", "w", encoding="utf-8") as fh:
        for x in rows:
            fh.write(json.dumps({"in": x, "out": done[x][0]}, ensure_ascii=False) + "\n")
    kinds = collections.Counter(k for x in picked for k in done[x][1])
    print("repair_parity.jsonl: %d changed, %d unchanged of %d replies; fired in the changed: %s"
          % (len(picked), len(rows) - len(picked), len(done), dict(sorted(kinds.items()))))


if __name__ == "__main__":
    main()
