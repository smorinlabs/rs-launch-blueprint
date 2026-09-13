#!/usr/bin/env bash
# R69 evidence: the prompt's "issue responsiveness" figure, which the codex raw
# recorded as unverified (it noted that the ten-newest listing mixes issues with
# pull requests and that maintainer attribution needs comment sampling).
#
# Rule applied, from the prompt's figure table: over the 10 most recently OPENED
# ISSUES, the median days to a first maintainer response and the unanswered
# count. "Maintainer response" = the earliest comment whose author_association
# is OWNER, MEMBER or COLLABORATOR, excluding bots and the issue author.
#
# Reads the committed, reduced snapshots, so it reproduces byte-for-byte.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../evidence/snapshots"
rc=0

echo "snapshot $(cat "$S/RETRIEVED-AT.txt")"
jq -r '.rule' "$S/gh-newest-issues-axum.json" | sed 's/^/rule: /'

python3 - "$S" <<'PY'
import json, sys, datetime, statistics, pathlib
S = pathlib.Path(sys.argv[1])
rc = 0
for key in ("axum", "bacon", "tokio"):
    f = S / f"gh-newest-issues-{key}.json"
    if not f.exists():
        print(f"FAIL: missing {f.name}"); rc = 1; continue
    d = json.loads(f.read_text())
    issues = d["issues"]
    print()
    print(f"=== {d['repo']} ===")
    if len(issues) != 10:
        print(f"FAIL: expected 10 issues, got {len(issues)}"); rc = 1
    order = sorted(i["created_at"] for i in issues)
    print(f"window: {order[0]} -> {order[-1]}")
    delays, unanswered = [], 0
    for it in sorted(issues, key=lambda i: -i["number"]):
        opened = datetime.datetime.fromisoformat(it["created_at"].replace("Z", "+00:00"))
        resp = [c for c in it["comments"]
                if c.get("type") != "Bot"
                and c.get("author") != it["author"]
                and c.get("assoc") in ("OWNER", "MEMBER", "COLLABORATOR")]
        if not resp:
            unanswered += 1
            print(f"  #{it['number']:<7} opened {it['created_at']} by {it['author']:<22} "
                  f"first maintainer response: NONE")
            continue
        first = min(datetime.datetime.fromisoformat(c["created_at"].replace("Z", "+00:00"))
                    for c in resp)
        days = (first - opened).total_seconds() / 86400
        delays.append(days)
        print(f"  #{it['number']:<7} opened {it['created_at']} by {it['author']:<22} "
              f"first maintainer response: {first.strftime('%Y-%m-%dT%H:%M:%SZ')} ({days:.2f} days)")
    med = f"{statistics.median(delays):.2f}" if delays else "n/a"
    print(f"  -> answered: {len(delays)}   unanswered: {unanswered}   "
          f"median days to first maintainer response (answered only): {med}")
    if len(delays) + unanswered != len(issues):
        print(f"FAIL: answered + unanswered != {len(issues)}"); rc = 1

print()
print("controls -- these assertions must be able to fail:")
if not [c for c in [] if c.get("assoc") == "OWNER"]:
    print("OK   an empty comment list yields no maintainer response")
else:
    print("FAIL an empty comment list produced a response"); rc = 1
cs = [{"assoc": "OWNER", "author": "alice", "type": "User"},
      {"assoc": "OWNER", "author": "bot",   "type": "Bot"},
      {"assoc": "NONE",  "author": "carol", "type": "User"}]
kept = [c for c in cs if c["type"] != "Bot" and c["author"] != "alice"
        and c["assoc"] in ("OWNER", "MEMBER", "COLLABORATOR")]
if not kept:
    print("OK   the issue author, a bot and a non-maintainer are all excluded")
else:
    print(f"FAIL the filter kept {kept}"); rc = 1
sys.exit(rc)
PY
rc=$?

echo "issue-responsiveness rc=$rc"
exit $rc
