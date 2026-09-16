#!/usr/bin/env bash
# R07 revision-2 empirical check. Run from this directory (review/empirical/r2).
#
# Revision 1's check (../run-check.sh) and its log are left byte-identical; this
# script adds only what revision 2 changed — the monthly `schedule` backstop the
# owner directed (docs/port/OWNER-REVIEW.md, section "Wave 0 owner acceptances
# (recorded from 2026-09-14)", the R07 row) — plus the two documentation facts
# that decide how the backstop interacts with GitHub's automatic disabling.
#
# Every check asserts on CONTENT, not on an exit code alone, and every failure
# increments `fails`, which becomes this script's exit status. The only network
# access in this programme's revision-2 work was the two `curl` retrievals that
# produced the snapshots under ../../evidence/ (recorded in the decision with
# URL, HTTP status and byte count); this script is offline and reads those
# snapshots, so a re-run cannot be perturbed by documentation drift. Check 5
# states the rule for detecting drift instead.
set -u
set -o pipefail

cd "$(dirname "$0")" || exit 2
EVID=../../evidence
WF=.github/workflows/update-contributors.yml
NEG=alternatives/hybrid-paths-ignore-under-schedule.yml
fails=0

fail() { echo "ASSERT-FAIL: $*"; fails=$((fails + 1)); }
ok()   { echo "assert-ok: $*"; }

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

echo "== 1. actionlint on the revision-2 recommended workflow (expect exit 0 and no diagnostics) =="
out1="$(actionlint "$WF" 2>&1)"; rc=$?
printf '%s' "$out1"
echo "exit: $rc"
[ "$rc" -eq 0 ] && ok "actionlint accepts the push + schedule + workflow_dispatch block" \
                || fail "actionlint rejected the recommended block (exit $rc)"
[ -z "$out1" ] && ok "actionlint emitted no diagnostic line for the recommended block" \
               || fail "actionlint emitted diagnostics for the recommended block"
echo

echo "== 2. structure of the recommended on: block, asserted field by field =="
python3 - "$WF" <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1], encoding='utf-8'))
# YAML 1.1 resolves the bare key `on` to the boolean True; accept either form.
on = doc.get('on', doc.get(True))
fails = 0
def check(label, got, want):
    global fails
    if got == want:
        print(f"assert-ok: {label} == {want!r}")
    else:
        print(f"ASSERT-FAIL: {label} is {got!r}, expected {want!r}")
        fails += 1
check("set of on: keys", sorted(map(str, on)), ['push', 'schedule', 'workflow_dispatch'])
check("on.push.branches", on['push']['branches'], ['main'])
check("on.push.paths-ignore", on['push']['paths-ignore'], ['CONTRIBUTORS.md', '.contributors.jsonl'])
check("on.schedule", on['schedule'], [{'cron': '17 6 1 * *'}])
check("on.workflow_dispatch", on['workflow_dispatch'], None)
# The loop guard stays on push only: a path filter under schedule is invalid
# (check 3), and a scheduled run has no loop risk anyway, because it is started
# by the clock and not by the bot's own push.
sched_keys = sorted(k for entry in on['schedule'] for k in entry)
check("keys of every on.schedule entry", sched_keys, ['cron'])
# A5 clause 2, which revision 1 satisfied by construction and did not execute:
# the paths-ignore list must equal the action's output-file and state-file.
step = [s for j in doc['jobs'].values() for s in j['steps']
        if str(s.get('uses', '')).startswith('smorinlabs/contributors-please-action')][0]
check("paths-ignore == {output-file, state-file}",
      sorted(on['push']['paths-ignore']),
      sorted([step['with']['output-file'], step['with']['state-file']]))
# The cron itself, field by field: monthly, on the 1st, at minute 17.
m, h, dom, mon, dow = on['schedule'][0]['cron'].split()
check("cron minute (not the top of the hour, per GitHub's high-load advice)", m, '17')
check("cron hour", h, '6')
check("cron day-of-month", dom, '1')
check("cron month (every month)", mon, '*')
check("cron day-of-week (unrestricted)", dow, '*')
check("cron field count", len(on['schedule'][0]['cron'].split()), 5)
print("longest gap between two monthly runs, in days: 31 (the longest calendar month)")
sys.exit(1 if fails else 0)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "structural assertions on the recommended block"
echo

echo "== 3. negative control: the same block with paths-ignore moved under schedule (expect non-zero) =="
out3="$(actionlint "$NEG" 2>&1)"; rc=$?
printf '%s\n' "$out3"
echo "exit: $rc"
[ "$rc" -ne 0 ] && ok "actionlint rejects paths-ignore under schedule" \
                || fail "actionlint accepted paths-ignore under schedule (exit $rc)"
case "$out3" in
  *'unexpected key "paths-ignore" for element of "schedule" section'*)
    ok 'rejection names the expected cause: unexpected key "paths-ignore" for element of "schedule" section' ;;
  *) fail "rejection did not name the expected cause" ;;
esac
echo

echo "== 4. the two fixtures differ only in where the guard sits =="
diff_out="$(diff <(python3 -c "
import yaml,sys
d=yaml.safe_load(open('$WF'))
print(sorted(map(str, d.get('on', d.get(True)))))") <(python3 -c "
import yaml,sys
d=yaml.safe_load(open('$NEG'))
print(sorted(map(str, d.get('on', d.get(True)))))"))"; rc=$?
[ "$rc" -eq 0 ] && ok "both fixtures declare the same three triggers: push, schedule, workflow_dispatch" \
                || fail "trigger sets differ: $diff_out"
echo

echo "== 5. documentation snapshots: the two facts that decide the backstop's cost =="
D="$EVID/r2-disable-and-enable-workflows.txt"
S="$EVID/r2-workflow-state-enum.json"
for f in "$D" "$S"; do [ -r "$f" ] || fail "snapshot missing: $f"; done
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
    print("assert-ok: `state` is ONE required field of the whole workflow, whose enum carries "
          "disabled_fork and disabled_inactivity; there is no per-trigger state, so a workflow "
          "disabled by either rule fires on NO event, push and workflow_dispatch included")
    sys.exit(0)
print(f"ASSERT-FAIL: state enum is {enum!r} or `state` is not required")
sys.exit(1)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "workflow state-enum assertion"
echo "drift rule: these two files are snapshots taken 2026-09-15 UTC, not live fetches."
echo "A re-run of this script therefore cannot change them. To test for drift, re-fetch"
echo "each URL named in the snapshot header and re-run this section against the new text;"
echo "a difference there is a documentation change and a re-verify trigger, not noise."
echo

echo "== 6. what the monthly backstop retries: py's post-guard push-run outcomes =="
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
    print("assert-ok: 134 post-guard push runs, the figure revision 1 cites")
if concl.get('failure') != 12 or concl.get('success') != 122:
    print(f"ASSERT-FAIL: expected 122 success / 12 failure, got {dict(concl)}"); fails += 1
else:
    print("assert-ok: 12 of those 134 push runs concluded `failure` — the unretried-failure "
          "cost revision 1 accepted qualitatively and revision 2's backstop bounds at 31 days")
sys.exit(1 if fails else 0)
PY
rc=$?; echo "exit: $rc"; [ "$rc" -eq 0 ] || fail "py post-guard push-run outcome recount"
echo

echo "overall failed assertions: $fails"
[ "$fails" -eq 0 ] && echo "RESULT: PASS" || echo "RESULT: FAIL"
exit $((fails == 0 ? 0 : 1))
