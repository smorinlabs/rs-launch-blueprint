#!/usr/bin/env bash
# R56 evidence — assert that DECISION.md's `## Parameters` section satisfies the rule
# publication actually enforces: no `- owns` line, exactly the four fixed parameters plus
# every consumed one as `- assumes`, and each value byte-for-byte equal to its cell in the
# CURRENT docs/port/PARAMETERS.md. The comparison is a `diff` against lines regenerated
# from the registry by the same parser scripts/research_validation.py uses, so it cannot
# drift from the validator. Repo-internal: no network, no .git needed.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../../../../../.." && pwd)"
decision="$here/../DECISION.md"
cd "$root"

fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
want() { if [ "$2" = "$3" ]; then ok "$1" "$3"; else bad "$1" "expected [$2], got [$3]"; fi; }

printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'decision: %s\n' "$decision"
printf 'decision sha256: %s\n' "$(shasum -a 256 "$decision" | cut -d' ' -f1)"

work="$(mktemp -d "${TMPDIR:-/tmp}/r56params-XXXXXX")"
trap 'rm -rf "$work"' EXIT

# 1. Regenerate the expected lines from the registry, with the validator's own table parser.
python3 - "$work/expected.txt" <<'PY'
import sys, pathlib
text = pathlib.Path("docs/port/PARAMETERS.md").read_text()
header, values = None, {}
for line in text.splitlines():
    cells = [p.strip() for p in line.strip().strip("|").split("|")]
    if {"param", "kind", "owner", "value"}.issubset(cells):
        header = {n: i for i, n in enumerate(cells)}
    elif header is not None and len(cells) >= len(header) and cells[header["param"]]:
        values[cells[header["param"]]] = {n: cells[i] for n, i in header.items()}
fixed = [p for p, r in values.items() if r["kind"] == "fixed"]
consumed = ["error-taxonomy-exit-codes"]   # the prompt's only `- consumes:` entry
order = ["msrv-policy", "rust-edition", "target-os-matrix", "license"] + consumed
assert sorted(fixed) == sorted(order[:4]), "the registry's fixed set moved: %s" % sorted(fixed)
pathlib.Path(sys.argv[1]).write_text(
    "".join("- assumes %s = %s\n" % (p, values[p]["value"]) for p in order))
PY

# 2. Extract the decision's own `- assumes` lines, in file order.
/usr/bin/grep '^- assumes ' "$decision" > "$work/actual.txt"

want 'PA1 assumes-line-count' '5' "$(/usr/bin/wc -l < "$work/actual.txt" | tr -d ' ')"
if diff -u "$work/expected.txt" "$work/actual.txt" > "$work/params.diff"; then
  ok 'PA2 assumes-byte-identical-to-registry' 'diff against lines regenerated from docs/port/PARAMETERS.md is empty'
else
  bad 'PA2 assumes-byte-identical-to-registry' "$(cat "$work/params.diff")"
fi

# 3. This item owns nothing, so `## Parameters` must carry no `- owns` line at all.
want 'PA3 no-owns-line' '0' "$(/usr/bin/grep -c '^- owns ' "$decision" || true)"

# 4. The H2 set the packaging validator requires, in order, and nothing else.
/usr/bin/grep '^## ' "$decision" > "$work/h2.txt"
printf '## Decision\n## Parameters\n## Empirical check\n## Engines\n' > "$work/h2-expected.txt"
if diff -u "$work/h2-expected.txt" "$work/h2.txt" > "$work/h2.diff"; then
  ok 'PA4 h2-set' 'Decision, Parameters, Empirical check, Engines — in order, with no Supersedes'
else
  bad 'PA4 h2-set' "$(cat "$work/h2.diff")"
fi
want 'PA5 principles-h3' '1' "$(/usr/bin/grep -c '^### Principles and implementation$' "$decision" || true)"
want 'PA6 title' '1' \
  "$(/usr/bin/grep -c '^# 2026-09-17 — R56 — config-secret-policy (bundle, Deep) — decision (revision 1)$' "$decision" || true)"
want 'PA7 one-re-verify-line' '1' "$(/usr/bin/grep -c '^re-verify: ' "$decision" || true)"

# 5. No personal email and no real credential bytes anywhere in the committed review tree.
#    The synthetic probe fixture is a separate rule: it is not a credential, but it must
#    appear in NO log, which is what "no credential bytes in any log" actually asks.
leak=0
# The assertion ids are numbered rather than named, and the messages never echo the
# pattern, so THIS script's own log can never match its own search on a later rerun —
# a self-reference that would otherwise make the check fail the second time it is run.
i=0
for pattern in 'steve@conceptm.com' 'ghp_' 'github_pat_' 'AKIA' 'xox'; do
  i=$((i + 1))
  hits="$(/usr/bin/grep -rl -- "$pattern" "$here/.." 2> /dev/null | /usr/bin/grep -v 'check-parameters.sh' || true)"
  n="$(printf '%s' "$hits" | /usr/bin/grep -c . || true)"
  if [ "$n" = "0" ]; then
    ok "PA8.${i} sensitive-pattern-absent" 'no file under review/ contains it, excluding this script, which names the patterns it searches for (binary /usr/bin/grep)'
  else
    bad "PA8.${i} sensitive-pattern-absent" "$n file(s) under review/ contain pattern ${i}: $hits"
    leak=$((leak + 1))
  fi
done

# The probe fixture string. It is a synthetic value invented for this run, never a real
# credential, and it is legitimately present in exactly three non-log files: the probe
# source that defines it, the check script that runs the leak census for it, and the
# decision sentence that quotes that census command. It must be in no log at all.
fixture='sk_live_R56PROBE_DO_NOT_LOG'
log_hits="$(/usr/bin/grep -rl -- "$fixture" "$here"/*.log 2> /dev/null || true)"
log_n="$(printf '%s' "$log_hits" | /usr/bin/grep -c . || true)"
want 'PA9 fixture-absent-from-every-log' '0' "$log_n"
fixture_files="$(/usr/bin/grep -rl -- "$fixture" "$here/.." 2> /dev/null | /usr/bin/grep -v 'check-parameters.sh' | sed -e "s|/evidence/\.\./|/|" -e "s|.*/review/||" | sort | tr '\n' ' ')"
want 'PA10 fixture-only-in-the-three-expected-files' \
  'DECISION.md evidence/check-probe.sh evidence/probe/src/main.rs ' "$fixture_files"
want 'PA11 no-leaks' '0' "$leak"

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
