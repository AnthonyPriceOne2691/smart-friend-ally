#!/usr/bin/env python3
"""Router data and parity fixtures from the Python reference (local/spike/router-proto/router_core.py). Stdlib only.

  python3 -I make_router.py exact    # router.json: exact_only and exact_hash for the current lexicon and noise model
  python3 -I make_router.py parity   # router_parity.jsonl: open-set utterances and the reference's decisions

exact: a word of ~/models/router/wordfreq/ru_50k.txt (hermitdave/FrequencyWords 2018, OpenSubtitles, content
CC BY-SA 4.0; normalized, letters only — router3's KNOWN) is a double of a concept when it reaches the concept only
through the noise model; one line per concept. parity: the open sets of local/spike/router-proto/sets.py (never the
holdouts); utterances with a decision or a rule, round-robin over the topic of their first rule (sha256 order inside a
topic), up to ROWS - PLAIN, then PLAIN plain passes; an utterance with a personal name other than the fictional Соня,
Тёма, Мурка is skipped (router3's list of names is read here, never shipped).
"""
import sys

sys.dont_write_bytecode = True  # the reference sits in local/: no __pycache__ there

import hashlib  # noqa: E402
import json  # noqa: E402
import os  # noqa: E402
import re  # noqa: E402
from pathlib import Path  # noqa: E402

PROTO = Path("/Users/anthony/Documents/Smart frend Ally/local/spike/router-proto")
HERE = Path(__file__).resolve().parent
DATA = HERE.parents[2] / "Sources/Discipline/Resources/router.json"
os.environ["ROUTER_JSON"] = str(DATA)
sys.path[:0] = [str(PROTO)]
import router_core as rc  # noqa: E402
import sets  # noqa: E402

ROWS, PLAIN, FICTIONAL = 80, 6, ("сон", "тем", "мурк")


def exact():
    text = DATA.read_text(encoding="utf-8")
    raw = json.loads(text)
    fuzzy = rc.Data(raw, "-", off={"known_exact"})
    freq = Path.home() / "models/router/wordfreq/ru_50k.txt"
    words = sorted({w for w in (rc.normalize(line.split()[0]) for line in open(freq, encoding="utf-8")) if w.isalpha()})
    found = {}
    for concept, entries in sorted(fuzzy.lex.items()):
        hit = [w for w in words if not any(w.startswith(s) and e.fullmatch(w, len(s)) for s, e in entries)
               and any(rc.stem_match(s, e, w, fuzzy) is not None for s, e in entries)]
        if hit:
            found[concept] = hit
    block = ",\n".join("    %s: %s" % (json.dumps(c), json.dumps(w, ensure_ascii=False)) for c, w in found.items())
    text = re.sub(r'  "exact_only": \{.*?\n?  \},?\n|  "exact_only": \{\},\n', '  "exact_only": {\n%s\n  },\n' % block,
                  text, count=1, flags=re.S)
    DATA.write_text(re.sub(r'"exact_hash": "[^"]*"', '"exact_hash": "%s"' % rc.lexicon_hash(raw), text, count=1),
                    encoding="utf-8")
    print("router.json: %d doubles over %d concepts, healthy %s" % (
        sum(map(len, found.values())), len(found), rc.load(str(DATA)).healthy))


def parity():
    d = rc.load(str(DATA))
    assert d.healthy, "router.json fails its self-test: %s" % d.selftest_failures()
    names = [rc.normalize(n) for n in json.load(open(PROTO / "router3.json", encoding="utf-8"))["sets"]["names"]]
    rows, seen = [], set()
    for it in sorted(sets.all_open() + sets.hazard_dev(), key=lambda it: hashlib.sha256(it["text"].encode()).digest()):
        toks = re.findall(r"[а-я]+", rc.normalize(it["text"]))
        if it["text"] in seen or any(t.startswith(n) and re.fullmatch(r"(а|я|и|е|у|ю|ей|ой|ом|)", t[len(n):])
                                     and n not in FICTIONAL for t in toks for n in names):
            continue
        seen.add(it["text"])
        r = rc.route(it["text"], {"game": it["game"]}, d)
        rows.append(({"text": it["text"], "game": it["game"], **r}, r["kind"] != "pass" or bool(r["rules"])))
    topics = {}
    for row, busy in rows:
        topics.setdefault(row["rules"][0].split(".")[0], []).append(row) if busy else None
    picked = []
    while len(picked) < ROWS - PLAIN and any(topics.values()):
        picked += [queue.pop(0) for queue in topics.values() if queue][:ROWS - PLAIN - len(picked)]
    picked += [row for row, busy in rows if not busy][:PLAIN]
    with open(HERE / "router_parity.jsonl", "w", encoding="utf-8") as fh:
        fh.writelines(json.dumps(row, ensure_ascii=False) + "\n" for row in picked)
    print("router_parity.jsonl: %d rows (%d with a decision or rule over %d topics) of %d utterances" % (
        len(picked), sum(busy for _, busy in rows), len(topics), len(rows)))


if __name__ == "__main__":
    {"exact": exact, "parity": parity}[sys.argv[1] if len(sys.argv) > 1 else "parity"]()
