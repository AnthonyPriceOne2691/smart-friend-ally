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
contract ports (all but `honesty`: «ты живая?» is the router's) and the signed texts of contract.json for its canned
«alive» and «secret»; checks that contract.json holds the reference's limits, patterns, texts.
contract_probes.jsonl: the reference's probes (output_filter.PROBES) the content rules of router-people change, and
their clean twins (by name), through Repair's order and the contract — `want` is what the reference says.

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
NOT_PORTED, CONTENT = ("honesty",), ("human_claim", "pii_echo", "pii_request", "secret", "secret_pointer")
CLEAN_TWINS = re.compile(r"secret|surprise|address|remember|kindergarten|tell mom|phone friend|alive|house|count words|"
                         r"refuse|guessed")


def content_patterns():
    """contract.json → content: the reference's patterns of the content rules, extract_pii's inline ones composed."""
    n, a = of.NUM_TOKEN, of.ADDR_WORD
    return {"human_claim": [r.pattern for r in of.HUMAN_CLAIM_RES], "pii_ask": [r.pattern for r in of.PII_ASK_RES],
            "pii_request": [of.REQUEST_RE.pattern], "pii_safe_advice": [of.SAFE_ADVICE_RE.pattern],
            "secret": [r.pattern for r in of.SECRET_RES], "secret_refusal": [of.REFUSAL_RE.pattern],
            "secret_encourage": [r.pattern for r in of.SECRET_ENCOURAGE_RES], "surprise": [of.SURPRISE_RE.pattern],
            "pii_advice": [of.PII_ADVICE_RE.pattern], "remember": [of.REMEMBER_RE.pattern],
            "pii_street": [r"(?:улиц[аеуы]|ул\.|проспект\w*|переул\w*)\s+([а-я]{3,})"],
            "pii_numbers": [r"%s\s+(?:номер\s+)?(%s(?:\s+%s)*)" % (a, n, n)],
            "pii_surname": [r"фамили\w*\s+([а-я]{3,})"],
            "pii_run": [r"(?:%s)(?:[\s,-]+(?:%s)){2,}" % (n, n)], "pii_phone": [r"телефон|номер"],
            "pii_address": [r"\bадрес"], "pii_digits": [r"\d{5,}"], "pii_word": [r"\b%s\b" % a],
            "pii_number": [r"\b%s\b" % n], "pii_token": [r"[а-я0-9⟦⟧A-Z]+"]}


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
                content=content_patterns())
    # canned, scripts, fallback_of: the keys the reference has must agree; router-people's texts are the signed ones
    signed = (SPIKE.parent / "checkpoint/router-scripts-basic.json").read_text(encoding="utf-8")
    basic = {k: v[1] for k, v in json.loads(signed).items()}
    shared = {"canned": {**of.CANNED, "fear": basic["fear_fallback"]},
              "scripts": {**basic, **{k: of.SCRIPTS[k] for _, k in of.HAZARD_SCRIPTS}},
              "fallback_of": {{"digits_pii": "phone", "secret": "promise"}.get(k, k): v  # pragma: allowlist secret
                              for k, v in of.FALLBACK_OF.items()}}
    for name in [k for k, v in want.items() if CONTRACT[k] != v] + [
            k for k, ref in shared.items() if any(CONTRACT[k][key] != ref[key] for key in CONTRACT[k] if key in ref)]:
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


def probes():
    """contract_probes.jsonl: probes whose text the content rules change, and their clean twins."""
    rows = []
    for name, reply, heard, want, *mode in of.PROBES:
        mode = (mode or ["talk"])[0]
        on = of.contract(repair(reply)[0], [], mode, reply, heard)["text"]
        of.ENABLED.update(dict.fromkeys(CONTENT, False))
        off = of.contract(repair(reply)[0], [], mode, reply, heard)["text"]
        of.ENABLED.update(dict.fromkeys(CONTENT, True))
        if on != off or want is None and CLEAN_TWINS.search(name):
            rows.append({"reply": reply, "heard": heard, "mode": mode, "want": on})
    with open(HERE / "contract_probes.jsonl", "w", encoding="utf-8") as fh:
        fh.writelines(json.dumps(row, ensure_ascii=False) + "\n" for row in rows)
    print("contract_probes.jsonl: %d of %d probes" % (len(rows), len(of.PROBES)))


def main():
    check_data()
    check_contract()
    of.ENABLED.update(dict.fromkeys(NOT_PORTED, False))
    of.CANNED.update(alive=CONTRACT["scripts"]["alive"], secret=CONTRACT["scripts"]["secret"])  # signed texts
    probes()
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
