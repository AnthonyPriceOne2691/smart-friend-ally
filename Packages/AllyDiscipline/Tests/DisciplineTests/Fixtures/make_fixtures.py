#!/usr/bin/env python3
"""Parity fixtures for Repair (Swift): real model replies and what the Python reference makes of them. Stdlib only.

Reference (outside git, local/ of the main clone): strip_markup, symbols_to_words, latin_to_cyrillic, digits_to_words
of local/spike/discipline/output_filter.py and strip_endearments of local/spike/persona-v2/judge_sheet.py, in
Repair.apply's order. Placeholders (judge_sheet.PLACEHOLDER) go first: after strip_markup its bracket rule leaves
«Привет,!» or «Ой,,» (11 replies of the corpus), and the placeholder rule never fires.
Inputs: `response` or `reply` of persona-v2/results/*.jsonl and bakeoff/results/*.jsonl; up to 90 replies the
reference changes, round-robin over what fired (rarest first), and up to 20 it keeps (endearment words first);
inside a group, sha256 order. Checks first that repair.json holds the reference's tables and words.
Field `contract`: the reference's turn contract (output_filter.contract, talk mode) on `out`, with the rules this
contract ports (no honesty, secrets, address); checks that contract.json holds the reference's limits, patterns, texts.

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
CONTRACT = json.loads((HERE.parents[2] / "Sources/Discipline/Resources/contract.json")
                      .read_text(encoding="utf-8"))
CHANGED, UNCHANGED = 90, 20
NEXT_DELIVERY = ("honesty", "human_claim", "pii_echo", "pii_request", "secret", "secret_pointer")


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


def check_contract():
    """contract.json is the one copy of the contract's data: limits by mode, patterns and texts of the reference."""
    keys = ("plea_safety", "hazard", "encourage", "danger_safe", "pointer", "safety", "prohibition", "connective",
            "action", "filler", "filler_q")
    want = {k: getattr(of, k.upper() + "_RE").pattern for k in keys}
    want.update(modes={m: {**lim, "canned": of.MODE_CANNED[m]} for m, lim in of.MODES.items()}, attachment=of.ATTACH,
                negatable=sorted(of.NEGATABLE), negation=list(of.NEGATION), clause_splits=of.CLAUSE_SPLITS,
                pointer_script=of.POINTER_SCRIPT, hazard_scripts=[list(p) for p in of.HAZARD_SCRIPTS],
                canned={k: of.CANNED[k] for k in CONTRACT["canned"]},
                scripts={k: of.SCRIPTS[k] for _, k in of.HAZARD_SCRIPTS},
                fallback_of={k: of.FALLBACK_OF[{"phone": "digits_pii"}.get(k, k)] for k in CONTRACT["fallback_of"]})
    for name in (k for k, v in want.items() if CONTRACT[k] != v):
        sys.exit("contract.json: %s differs from the reference" % name)


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
    check_contract()
    of.ENABLED.update(dict.fromkeys(NEXT_DELIVERY, False))
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
            row = {"in": x, "out": done[x][0], "contract": of.contract(done[x][0], [])["text"]}
            fh.write(json.dumps(row, ensure_ascii=False) + "\n")
    kinds = collections.Counter(k for x in picked for k in done[x][1])
    print("repair_parity.jsonl: %d changed, %d unchanged of %d replies; fired in the changed: %s"
          % (len(picked), len(rows) - len(picked), len(done), dict(sorted(kinds.items()))))


if __name__ == "__main__":
    main()
