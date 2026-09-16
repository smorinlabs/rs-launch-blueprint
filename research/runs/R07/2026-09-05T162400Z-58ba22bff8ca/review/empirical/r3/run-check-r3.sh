#!/usr/bin/env bash
# R07 revision-3 empirical check. Run from this directory (review/empirical/r3).
#
# Revision 1's check (../run-check.sh) and revision 2's (../r2/run-check-r2.sh),
# and both of their logs, are left byte-identical. This script adds only what
# revision 3 changed: the recommended `on:` block loses the monthly `schedule`
# backstop revision 2 added and is again revision 1's block, on owner ruling
# W0-R07b (docs/planning/p02/owner-decisions.md, section "10. The Wave 0 review
# walk -- IN PROGRESS from 2026-09-14", row W0-R07b; docs/port/OWNER-REVIEW.md,
# the R07 row).
#
# Five checks:
#   1  the revision-3 fixture is byte-identical to revision 1's, and actionlint
#      accepts it with no diagnostic line;
#   2  the block's structure field by field — the key set is {push,
#      workflow_dispatch} and carries NO `schedule` key, no cron string appears
#      anywhere in the file, and criterion A5's second clause holds;
#   3  py's post-guard push-run outcomes, recounted independently of revision 2:
#      the lag the declined backstop would have retried;
#   4  the two documentation facts that decided the decline, re-asserted against
#      revision 2's snapshots (this script does not fetch them again);
#   5  `## Supersedes` ends with the published revision-1 bytes, which is the
#      finding review/audit-codex.md raised against revision 2.
#
# Every check asserts on CONTENT, not on an exit code alone, and every failure
# increments `fails`, which becomes this script's exit status. The script is
# offline: it reads only files inside this repository, so a re-run cannot be
# perturbed by documentation drift. Check 4 states the rule for detecting drift.
set -u
set -o pipefail

cd "$(dirname "$0")" || exit 2
EVID=../../evidence
WF=.github/workflows/update-contributors.yml           # revision 3 = revision 1
R1WF=../.github/workflows/update-contributors.yml      # revision 1's fixture
R2WF=../r2/.github/workflows/update-contributors.yml   # the declined option E
DEC=../../DECISION.md
PUB=../../../../../../topics/07-contributors-bot-trigger-cadence/DECISION.md
PUBSHA=0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346
PUBBYTES=26203
fails=0

fail() { echo "ASSERT-FAIL: $*"; fails=$((fails + 1)); }
ok()   { echo "assert-ok: $*"; }
sha()  { shasum -a 256 | cut -d' ' -f1; }

echo "== toolchain =="
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "os: $(sw_vers -productName) $(sw_vers -productVersion) $(uname -m)"
rustc --version
cargo --version
echo "actionlint: $(actionlint --version | head -1)"
python3 --version
python3 -c 'import yaml; print("pyyaml", yaml.__version__)'
echo "act: $(command -v act || echo 'not installed -> form (b)')"
echo "cwd: $(pwd | sed 's#.*/research/#research/#')"
echo

echo "== 1. the recommended fixture is revision 1's, restored byte for byte, and actionlint accepts it =="
h3="$(sha < "$WF")"; h1="$(sha < "$R1WF")"
echo "sha256 revision-3 fixture: $h3"
echo "sha256 revision-1 fixture: $h1"
[ "$h3" = "$h1" ] && ok "the revision-3 fixture is byte-identical to revision 1's fixture, so the block is restored and not retyped" \
                  || fail "the revision-3 fixture differs from revision 1's ($h3 vs $h1)"
out1="$(actionlint "$WF" 2>&1)"; rc=$?
printf '%s' "$out1"
echo "exit: $rc"
[ "$rc" -eq 0 ] && ok "actionlint accepts the push + workflow_dispatch block (A5 clause 1)" \
                || fail "actionlint rejected the recommended block (exit $rc)"
[ -z "$out1" ] && ok "actionlint emitted no diagnostic line for the recommended block" \
               || fail "actionlint emitted diagnostics for the recommended block"
echo

echo "== 2. structure of the recommended on: block, asserted field by field =="
python3 - "$WF" "$R2WF" <<'PY'
import sys, yaml
def triggers(path):
    doc = yaml.safe_load(open(path, encoding='utf-8'))
    # YAML 1.1 resolves the bare key `on` to the boolean True; accept either form.
    return doc, doc.get('on', doc.get(True))
doc, on = triggers(sys.argv[1])
_, on_e = triggers(sys.argv[2])
fails = 0
def check(label, got, want):
    global fails
    if got == want:
        print(f"assert-ok: {label} == {want!r}")
    else:
        print(f"ASSERT-FAIL: {label} is {got!r}, expected {want!r}")
        fails += 1
check("set of on: keys", sorted(map(str, on)), ['push', 'workflow_dispatch'])
# The decision this revision records: no schedule key, stated as its own assertion
# rather than left implicit in the key set above.
if 'schedule' in set(map(str, on)):
    print("ASSERT-FAIL: the recommended block carries a `schedule` key"); fails += 1
else:
    print("assert-ok: the recommended block carries NO `schedule` key, so neither "
          "disabled_inactivity nor disabled_fork has a precondition this workflow "
          "can meet (owner ruling W0-R07b)")
check("on.push.branches", on['push']['branches'], ['main'])
check("on.push.paths-ignore", on['push']['paths-ignore'], ['CONTRIBUTORS.md', '.contributors.jsonl'])
check("on.workflow_dispatch", on['workflow_dispatch'], None)
# A5 clause 2, which revision 1 satisfied by construction and did not execute
# (the revision-1 judgment audit's observation O3): the paths-ignore list must
# equal the action's output-file and state-file inputs.
step = [s for j in doc['jobs'].values() for s in j['steps']
        if str(s.get('uses', '')).startswith('smorinlabs/contributors-please-action')][0]
check("paths-ignore == {output-file, state-file}",
      sorted(on['push']['paths-ignore']),
      sorted([step['with']['output-file'], step['with']['state-file']]))
# The declined option E, for contrast: the only difference is the key that
# would have carried the cost.
diff = sorted(set(map(str, on_e)) - set(map(str, on)))
check("keys option E adds to the recommendation", diff, ['schedule'])
check("keys the recommendation adds to option E",
      sorted(set(map(str, on)) - set(map(str, on_e))), [])
sys.exit(1 if fails else 0)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "structural assertions on the recommended block"
# No cron anywhere in the file, comments included: the fixture must not leave a
# commented-out backstop behind for an integrator to re-enable by accident.
if /usr/bin/grep -qiE 'cron|schedule' "$WF"; then
  fail "/usr/bin/grep: the recommended fixture still mentions cron or schedule"
else
  ok '/usr/bin/grep: the string `cron` and the string `schedule` appear nowhere in the recommended fixture, comments included'
fi
echo

echo "== 3. the lag the declined backstop would have retried: py's post-guard push-run outcomes =="
python3 - "$EVID/py-update-contributors-runs.json" "$EVID/py-paths-verdicts.json" <<'PY'
import sys, json, collections
GUARD = '40aa691910238b8ad1cfcc3e3c29b25746415680'   # rev-1 log step 5b
runs = [r for r in json.load(open(sys.argv[1], encoding='utf-8')) if r['event'] == 'push']
commits = list(reversed(json.load(open(sys.argv[2], encoding='utf-8'))['commits']))  # oldest first
idx = {c['sha']: i for i, c in enumerate(commits)}
heads = {r['head_sha']: r for r in runs if r['head_sha'] in idx}
post = commits[idx[GUARD] + 1:]
ranges, cur = [], []
for c in post:
    cur.append(c)
    if c['sha'] in heads:
        ranges.append(cur); cur = []
concl = collections.Counter(heads[r[-1]['sha']]['conclusion'] for r in ranges)
print(f"post-guard push runs (same scoping as revision 1 step 5b): {len(ranges)}")
print("conclusions: " + json.dumps(dict(sorted(concl.items()))))
ts = collections.Counter(r['conclusion'] for r in json.load(open(sys.argv[1].replace('py-', 'ts-'), encoding='utf-8')))
print("ts scheduled runs for comparison: " + json.dumps(dict(sorted(ts.items()))))
fails = 0
if len(ranges) != 134:
    print(f"ASSERT-FAIL: expected 134 post-guard push runs, got {len(ranges)}"); fails += 1
else:
    print("assert-ok: 134 post-guard push runs, the figure revisions 1 and 2 cite")
if concl.get('failure') != 12 or concl.get('success') != 122:
    print(f"ASSERT-FAIL: expected 122 success / 12 failure, got {dict(concl)}"); fails += 1
else:
    print("assert-ok: 12 of those 134 push runs concluded `failure` — the bounded lag "
          "revision 3 accepts on owner ruling W0-R07b: each is a red run on a merge "
          "commit, recoverable with one `workflow_dispatch`, and no scheduled retry "
          "attempt is claimed to bound it")
sys.exit(1 if fails else 0)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "py post-guard push-run outcome recount"
echo

echo "== 4. the two documentation facts that decided the decline, re-asserted against revision 2's snapshots =="
D="$EVID/r2-disable-and-enable-workflows.txt"
S="$EVID/r2-workflow-state-enum.json"
for f in "$D" "$S"; do [ -r "$f" ] || fail "snapshot missing: $f"; done
/usr/bin/grep -q 'Disabling a workflow allows you to stop a workflow from being triggered without having to delete the file from the repo' "$D" \
  && ok '/usr/bin/grep: snapshot carries the sentence defining what disabling does — stop the workflow from being TRIGGERED, no trigger named or excepted' \
  || fail '/usr/bin/grep: snapshot lacks the definition of disabling'
/usr/bin/grep -q 'In a public repository, scheduled workflows are automatically disabled when no repository activity has occurred in 60 days' "$D" \
  && ok '/usr/bin/grep: snapshot carries the 60-day inactivity sentence' \
  || fail '/usr/bin/grep: snapshot lacks the 60-day inactivity sentence'
/usr/bin/grep -q 'When a public repository is forked, scheduled workflows are disabled by default' "$D" \
  && ok '/usr/bin/grep: snapshot carries the fork-default sentence' \
  || fail '/usr/bin/grep: snapshot lacks the fork-default sentence'
/usr/bin/grep -q 'gh workflow enable WORKFLOW' "$D" \
  && ok '/usr/bin/grep: snapshot carries the documented re-enable command' \
  || fail '/usr/bin/grep: snapshot lacks the re-enable command'
echo "-- the REST Workflow schema's state field, printed from the snapshot --"
python3 - "$S" <<'PY'
import sys, json
d = json.load(open(sys.argv[1], encoding='utf-8'))
enum = d['workflow_schema']['properties']['state']['enum']
print(json.dumps(enum))
want = ["active", "deleted", "disabled_fork", "disabled_inactivity", "disabled_manually"]
if enum == want and 'state' in d['workflow_schema']['required']:
    print("assert-ok: `state` is ONE required field of the whole workflow file, whose enum "
          "carries disabled_fork and disabled_inactivity; there is no per-trigger state, so a "
          "`schedule` key would expose the push trigger to both rules. This is the fact the "
          "owner ruled on (W0-R07b) and the reason option E is declined rather than selected; "
          "the recommended block, having no `schedule` key, meets neither rule's precondition")
    sys.exit(0)
print(f"ASSERT-FAIL: state enum is {enum!r} or `state` is not required")
sys.exit(1)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "workflow state-enum assertion"
echo "drift rule: these two files are snapshots taken 2026-09-16 UTC (2026-09-15 local) by"
echo "revision 2, not live fetches, and revision 3 left them byte-identical."
echo "A re-run of this script therefore cannot change them. To test for drift, re-fetch"
echo "each URL named in the snapshot header and re-run this section against the new text;"
echo "a difference there is a documentation change and a re-verify trigger, not noise."
echo

echo "== 5. ## Supersedes ends with the published revision-1 bytes (audit-codex.md finding 1) =="
[ -r "$PUB" ] || fail "published decision not readable at $PUB"
pubsha="$(sha < "$PUB")"
pubsize="$(wc -c < "$PUB" | tr -d ' ')"
tailsha="$(tail -c "$PUBBYTES" "$DEC" | sha)"
echo "published file:        $PUB"
echo "published sha256:      $pubsha  ($pubsize bytes)"
echo "tail -c $PUBBYTES of DECISION.md: $tailsha"
[ "$pubsha" = "$PUBSHA" ] && ok "the published file still hashes to the sha256 the owner acceptance and both revision-1 audits cite" \
                          || fail "the published file hashes to $pubsha, not $PUBSHA"
[ "$pubsize" = "$PUBBYTES" ] && ok "the published file is $PUBBYTES bytes" \
                             || fail "the published file is $pubsize bytes, not $PUBBYTES"
[ "$tailsha" = "$PUBSHA" ] && ok "the last $PUBBYTES bytes of this run's DECISION.md are the published revision 1, byte for byte and with nothing after them — unfenced and unwrapped, which is what revision 2 failed" \
                           || fail "the tail of DECISION.md hashes to $tailsha, not $PUBSHA"
/usr/bin/grep -q '^## Supersedes$' "$DEC" \
  && ok '/usr/bin/grep: DECISION.md carries the `## Supersedes` heading that opens those bytes' \
  || fail '/usr/bin/grep: DECISION.md has no `## Supersedes` heading'
echo

echo "overall failed assertions: $fails"
[ "$fails" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit $((fails == 0 ? 0 : 1))
