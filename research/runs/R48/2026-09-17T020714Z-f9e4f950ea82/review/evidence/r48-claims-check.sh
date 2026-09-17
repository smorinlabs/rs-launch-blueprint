#!/usr/bin/env bash
# R48 mocking-crates — synthesizer empirical check (revision 1).
#
# Verifies the claims the two raw reports make about the candidate crates and
# about the owner-supplied reference row. It implements nothing: no template is
# scaffolded, no Cargo.toml is written, no Rust code is compiled. The Rust
# template does not exist yet; P03 builds it.
#
# Determinism contract
# --------------------
#   * Every line beginning "# " is volatile (retrieval date, toolchain banner,
#     host). Every PASS / FAIL / SKIP line is asserted on a stable field and
#     reproduces byte-for-byte:
#         bash r48-claims-check.sh > new.log
#         diff <(grep -v '^# ' new.log) <(grep -v '^# ' r48-claims-check.log)
#     must be empty.
#   * No download counter, star count, open-issue count or active repository's
#     pushed_at literal is printed; those drift by the hour.
#   * C13 deliberately asserts a frozen value (LukeMathWalker/wiremock-rs has
#     not been pushed since 2025-08-24). A future FAIL there is the recorded
#     re-verify trigger firing, not a defect in this check.
#   * C18 reads the py source repo at its programme pin. It prints SKIP when
#     that clone is absent (a clean `git archive HEAD` extraction of this
#     repository has no sibling repos and no .git).
#
# Usage: bash r48-claims-check.sh     (runnable from any working directory)

set -uo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# evidence -> review -> <run> -> R48 -> runs -> research -> repository root
REPO=$(CDPATH='' cd -- "$SCRIPT_DIR/../../../../../.." && pwd)
RUN_INPUTS="$SCRIPT_DIR/../../inputs"
DECISION="$SCRIPT_DIR/../DECISION.md"
PY_REPO="$HOME/c/py-launch-blueprint"
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
UA='rs-launch-blueprint-research/1.0'
GREP=/usr/bin/grep

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

FAILED=0
pass() { printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; FAILED=$((FAILED + 1)); }
skip() { printf 'SKIP %s: %s\n' "$1" "$2"; }

# fetch <url> <outfile> -> prints the HTTP status code, returns curl's status
fetch() {
  curl -sS -A "$UA" -o "$2" -w '%{http_code}' "$1"
}

# status_only <url> -> prints the HTTP status code for a body-discarding GET
status_only() {
  curl -sS -A "$UA" -o /dev/null -w '%{http_code}' "$1"
}

printf '# R48 mocking-crates — empirical check, revision 1\n'
printf '# retrieved: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '# host: %s %s\n' "$(uname -s)" "$(uname -m)"
printf '# rustc: %s\n' "$(rustc --version 2>/dev/null || echo 'not installed')"
printf '# cargo: %s\n' "$(cargo --version 2>/dev/null || echo 'not installed')"
printf '# grep binary: %s (%s)\n' "$GREP" "$("$GREP" --version 2>/dev/null | head -n 1)"
printf '# nothing below compiles Rust; the template does not exist (P03 builds it)\n'
printf '#\n'

# ---------------------------------------------------------------------------
# C01-C04 — registry facts: newest non-yanked release, declared rust-version.
# Endpoint: https://crates.io/api/v1/crates/<name>/versions  (field `versions`,
# newest entry with yanked:false -> num, rust_version, license)
# ---------------------------------------------------------------------------
registry_check() { # registry_check <id> <crate> <expected-num> <expected-rust-version-or-NONE>
  local id=$1 crate=$2 want_num=$3 want_msrv=$4 code got
  code=$(fetch "https://crates.io/api/v1/crates/$crate/versions" "$WORK/$crate.json") || {
    fail "$id" "crates.io/api/v1/crates/$crate/versions — curl failed"
    return
  }
  if [ "$code" != "200" ]; then
    fail "$id" "crates.io/api/v1/crates/$crate/versions returned HTTP $code, expected 200"
    return
  fi
  got=$(python3 - "$WORK/$crate.json" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
newest = [v for v in data["versions"] if not v["yanked"]][0]
rv = newest.get("rust_version")
print("%s|%s|%s" % (newest["num"], rv if rv else "NONE", newest.get("license")))
PY
  ) || { fail "$id" "could not parse $crate versions payload"; return; }
  local num msrv lic
  num=${got%%|*}
  lic=${got##*|}
  msrv=${got#*|}
  msrv=${msrv%%|*}
  if [ "$num" = "$want_num" ] && [ "$msrv" = "$want_msrv" ]; then
    pass "$id" "$crate newest non-yanked = $num, declared rust-version = $msrv, licence recorded as $lic (not evaluated — gate 1 inapplicable, owner ruling 2026-09-12 Q7.B)"
  else
    fail "$id" "$crate newest non-yanked = $num, rust-version = $msrv; expected $want_num / $want_msrv"
  fi
}

registry_check C01 mockall 0.15.0 1.77.0
registry_check C02 httpmock 0.8.3 1.88.0
registry_check C03 wiremock 0.6.5 NONE
registry_check C04 mockito 1.7.2 1.70

# ---------------------------------------------------------------------------
# C05 — httpmock 0.8.3 default feature set (the `default-features = false`
# recommendation depends on it). Endpoint: crates.io version metadata.
# ---------------------------------------------------------------------------
code=$(fetch "https://crates.io/api/v1/crates/httpmock/0.8.3" "$WORK/httpmock-0.8.3.json")
if [ "$code" = "200" ]; then
  defaults=$(python3 - "$WORK/httpmock-0.8.3.json" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
print(",".join(data["version"]["features"].get("default", [])))
PY
  )
  if [ "$defaults" = "cookies" ]; then
    pass C05 "httpmock 0.8.3 default feature set is exactly [cookies] — default-features = false is a real change, not a no-op"
  else
    fail C05 "httpmock 0.8.3 default feature set is [$defaults], expected [cookies]"
  fi
else
  fail C05 "crates.io/api/v1/crates/httpmock/0.8.3 returned HTTP $code, expected 200"
fi

# ---------------------------------------------------------------------------
# C06 — unsafe posture: `unsafe_code = "forbid"` is a MASTER-branch (0.9.0)
# fact, NOT a property of the released 0.8.3 manifest. This corrects the opus
# report, which read it from master and attributed it to the recommendation.
# ---------------------------------------------------------------------------
c083=$(fetch "https://raw.githubusercontent.com/httpmock/httpmock/v0.8.3/Cargo.toml" "$WORK/hm-0.8.3.toml")
cmas=$(fetch "https://raw.githubusercontent.com/httpmock/httpmock/master/Cargo.toml" "$WORK/hm-master.toml")
if [ "$c083" = "200" ] && [ "$cmas" = "200" ]; then
  n083=$("$GREP" -c 'unsafe_code' "$WORK/hm-0.8.3.toml")
  nmas=$("$GREP" -c 'unsafe_code' "$WORK/hm-master.toml")
  ed083=$("$GREP" -c '^edition = "2021"' "$WORK/hm-0.8.3.toml")
  if [ "$n083" = "0" ] && [ "$nmas" = "1" ] && [ "$ed083" = "1" ]; then
    pass C06 "tag v0.8.3 Cargo.toml: 0 unsafe_code lines and edition = \"2021\"; master Cargo.toml: 1 unsafe_code line (counts by $GREP -c) — the forbid lint and edition 2024 are unreleased 0.9.0 facts"
  else
    fail C06 "expected v0.8.3 unsafe_code count 0 / edition-2021 count 1 and master unsafe_code count 1; got $n083 / $ed083 / $nmas (counts by $GREP -c)"
  fi
else
  fail C06 "raw.githubusercontent.com httpmock manifests returned HTTP $c083 (v0.8.3) and $cmas (master), expected 200 and 200"
fi

# ---------------------------------------------------------------------------
# C07 — RustSec: HTTP 404 on a package page means "no advisory". Proved by a
# control: lock_api, which carries RUSTSEC-2020-0070, must return 200. Without
# the control a 404 could equally mean the probe is broken.
# ---------------------------------------------------------------------------
ctrl=$(status_only "https://rustsec.org/packages/lock_api.html")
adv_ok=1
adv_detail=""
for crate in mockall httpmock wiremock mockito; do
  st=$(status_only "https://rustsec.org/packages/$crate.html")
  adv_detail="$adv_detail $crate=$st"
  [ "$st" = "404" ] || adv_ok=0
done
if [ "$ctrl" = "200" ] && [ "$adv_ok" = "1" ]; then
  pass C07 "rustsec.org control lock_api = HTTP 200 (RUSTSEC-2020-0070 exists), candidates$adv_detail — the probe distinguishes, so 404 is evidence of no open advisory, gate 3 passes for all four"
else
  fail C07 "rustsec.org control lock_api = HTTP $ctrl (expected 200); candidates$adv_detail (expected 404 each)"
fi

# ---------------------------------------------------------------------------
# C08 — mockall 0.15.0 drags no async runtime into the feature-enabled build.
# Endpoint: crates.io release dependencies (kind == normal, not optional).
# ---------------------------------------------------------------------------
code=$(fetch "https://crates.io/api/v1/crates/mockall/0.15.0/dependencies" "$WORK/mockall-deps.json")
if [ "$code" = "200" ]; then
  deps=$(python3 - "$WORK/mockall-deps.json" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    data = json.load(fh)
req = sorted(d["crate_id"] for d in data["dependencies"]
             if d["kind"] == "normal" and not d["optional"])
print(" ".join(req))
PY
  )
  if [ "$deps" = "cfg-if downcast fragile mockall_derive predicates predicates-tree" ]; then
    pass C08 "mockall 0.15.0 required normal dependencies are exactly: $deps — no tokio, no hyper, no async runtime"
  else
    fail C08 "mockall 0.15.0 required normal dependencies are [$deps]; expected cfg-if downcast fragile mockall_derive predicates predicates-tree"
  fi
else
  fail C08 "crates.io/api/v1/crates/mockall/0.15.0/dependencies returned HTTP $code, expected 200"
fi

# ---------------------------------------------------------------------------
# C09/C10 — gate 4 (`target-os-matrix` = ubuntu-latest, macos-latest) read in
# each project's own CI definition.
# ---------------------------------------------------------------------------
code=$(fetch "https://raw.githubusercontent.com/httpmock/httpmock/master/.github/workflows/platform.yml" "$WORK/hm-platform.yml")
if [ "$code" = "200" ]; then
  n=$("$GREP" -c 'os: \[ubuntu-latest, macos-latest, windows-latest\]' "$WORK/hm-platform.yml")
  if [ "$n" = "1" ]; then
    pass C09 "httpmock .github/workflows/platform.yml carries 1 matrix line 'os: [ubuntu-latest, macos-latest, windows-latest]' (count by $GREP -c) — gate 4 closed on the crate's own CI"
  else
    fail C09 "httpmock platform.yml matched the full three-OS matrix line $n times (count by $GREP -c), expected 1"
  fi
else
  fail C09 "httpmock platform.yml returned HTTP $code, expected 200"
fi

code=$(fetch "https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/.github/workflows/general.yml" "$WORK/wm-general.yml")
if [ "$code" = "200" ]; then
  nmac=$("$GREP" -ci 'macos' "$WORK/wm-general.yml")
  nubu=$("$GREP" -c 'runs-on: ubuntu-latest' "$WORK/wm-general.yml")
  if [ "$nmac" = "0" ] && [ "$nubu" = "5" ]; then
    pass C10 "wiremock-rs .github/workflows/general.yml: 0 macos mentions and 5 'runs-on: ubuntu-latest' jobs (counts by $GREP -ci and $GREP -c) — its own CI does not cover macOS; gate 4 therefore rests on adopter evidence, not on the crate's CI"
  else
    fail C10 "wiremock-rs general.yml macos count $nmac (expected 0), ubuntu-latest job count $nubu (expected 5), counts by $GREP"
  fi
else
  fail C10 "wiremock-rs general.yml returned HTTP $code, expected 200"
fi

# ---------------------------------------------------------------------------
# C11 — the R05 coupling, read in wiremock's OWN comparison table: wiremock is
# async-only, httpmock and mockito expose both. This is the maintainer's own
# statement about its API, not a third-party summary.
# ---------------------------------------------------------------------------
code=$(fetch "https://raw.githubusercontent.com/LukeMathWalker/wiremock-rs/main/README.md" "$WORK/wm-readme.md")
if [ "$code" = "200" ]; then
  nwm=$("$GREP" -c '^| wiremock .*| Async  *|' "$WORK/wm-readme.md")
  nhm=$("$GREP" -c '^| httpmock .*| Async/Sync .*|' "$WORK/wm-readme.md")
  nmk=$("$GREP" -c '^| mockito .*| Async/Sync .*|' "$WORK/wm-readme.md")
  if [ "$nwm" = "1" ] && [ "$nhm" = "1" ] && [ "$nmk" = "1" ]; then
    pass C11 "wiremock's own README comparison table: 1 row 'wiremock … Async', 1 row 'httpmock … Async/Sync', 1 row 'mockito … Async/Sync' (counts by $GREP -c) — choosing wiremock would make the test suite async before R05 decides"
  else
    fail C11 "wiremock README row counts: wiremock-Async $nwm, httpmock-Async/Sync $nhm, mockito-Async/Sync $nmk (counts by $GREP -c), expected 1 1 1"
  fi
else
  fail C11 "wiremock-rs README.md returned HTTP $code, expected 200"
fi

# ---------------------------------------------------------------------------
# C12 — the two httpmock APIs the F121 contract suite needs exist in the
# RELEASED 0.8.3, read on docs.rs for that exact version.
# ---------------------------------------------------------------------------
tcode=$(fetch "https://docs.rs/httpmock/0.8.3/httpmock/struct.Then.html" "$WORK/then.html")
wcode=$(fetch "https://docs.rs/httpmock/0.8.3/httpmock/struct.When.html" "$WORK/when.html")
if [ "$tcode" = "200" ] && [ "$wcode" = "200" ]; then
  nresp=$("$GREP" -c 'method\.respond_with' "$WORK/then.html")
  ntrue=$("$GREP" -c 'method\.is_true' "$WORK/when.html")
  if [ "$nresp" -ge 1 ] && [ "$ntrue" -ge 1 ]; then
    pass C12 "docs.rs httpmock 0.8.3: struct.Then.html carries method.respond_with and struct.When.html carries method.is_true (present, counts by $GREP -c are $nresp and $ntrue) — the dynamic responder and the closure matcher the F121 suite needs are in the released version, not only on master"
  else
    fail C12 "docs.rs httpmock 0.8.3: respond_with anchors $nresp, is_true anchors $ntrue (counts by $GREP -c), expected at least 1 of each"
  fi
else
  fail C12 "docs.rs httpmock 0.8.3 pages returned HTTP $tcode (Then) and $wcode (When), expected 200 and 200"
fi

# ---------------------------------------------------------------------------
# C13 — the maintenance ground for ranking wiremock third, asserted as a frozen
# value. A FAIL here means the repository was pushed again, which is exactly
# the recorded re-verify trigger.
# ---------------------------------------------------------------------------
if command -v gh > /dev/null 2>&1; then
  wm_meta=$(gh api repos/LukeMathWalker/wiremock-rs --jq '[.archived, (.pushed_at | split("T")[0])] | join(" ")' 2> /dev/null)
  if [ -z "$wm_meta" ]; then
    fail C13 "gh api repos/LukeMathWalker/wiremock-rs returned nothing"
  elif [ "$wm_meta" = "false 2025-08-24" ]; then
    pass C13 "api.github.com repos/LukeMathWalker/wiremock-rs: archived = false, pushed_at date = 2025-08-24 — not archived, but not pushed since the 0.6.5 release; at-risk, not dormant"
  else
    fail C13 "repos/LukeMathWalker/wiremock-rs archived/pushed-date = '$wm_meta', expected 'false 2025-08-24' — if the date moved, the maintenance ground for ranking wiremock third has lapsed and this item must be re-verified"
  fi
else
  skip C13 "gh not on PATH; api.github.com repos/LukeMathWalker/wiremock-rs not queried"
fi

# ---------------------------------------------------------------------------
# C14 — the Compatibility claim: one shipping project carries BOTH recommended
# members at EXACTLY the recommended versions, in one manifest.
# ---------------------------------------------------------------------------
code=$(fetch "https://raw.githubusercontent.com/contentauth/c2pa-rs/main/sdk/Cargo.toml" "$WORK/c2pa.toml")
if [ "$code" = "200" ]; then
  nm=$("$GREP" -c '^mockall = "0\.15\.0"$' "$WORK/c2pa.toml")
  nh=$("$GREP" -c '^httpmock = "0\.8\.3"$' "$WORK/c2pa.toml")
  if [ "$nm" = "1" ] && [ "$nh" = "1" ]; then
    pass C14 "contentauth/c2pa-rs sdk/Cargo.toml carries 1 'mockall = \"0.15.0\"' line and 1 'httpmock = \"0.8.3\"' line (counts by $GREP -c) — both members at the recommended versions resolve in one lockfile in a shipping project"
  else
    fail C14 "c2pa-rs sdk/Cargo.toml: mockall-0.15.0 lines $nm, httpmock-0.8.3 lines $nh (counts by $GREP -c), expected 1 and 1"
  fi
else
  fail C14 "c2pa-rs sdk/Cargo.toml returned HTTP $code, expected 200"
fi

# ---------------------------------------------------------------------------
# C15 — the owner-supplied reference row this decision must reconcile.
# ---------------------------------------------------------------------------
REF="$RUN_INPUTS/owner-reference-axum-companion-stack-2026-09-16.md"
if [ -f "$REF" ]; then
  npin=$("$GREP" -c '^wiremock = "0\.6"$' "$REF")
  nrow=$("$GREP" -c '^| C12 | Testing |.*wiremock.*|$' "$REF")
  if [ "$npin" = "1" ] && [ "$nrow" = "1" ]; then
    pass C15 "inputs/owner-reference-axum-companion-stack-2026-09-16.md carries 1 pin line 'wiremock = \"0.6\"' and 1 C12 Testing row naming wiremock (counts by $GREP -c) — the row this decision differs from, with ground"
  else
    fail C15 "owner reference: wiremock pin lines $npin, C12 rows $nrow (counts by $GREP -c), expected 1 and 1"
  fi
else
  fail C15 "owner reference document absent at $REF"
fi

# ---------------------------------------------------------------------------
# C16 — publication guard: every '- assumes <param> = <value>' line in this
# decision must be byte-identical to column 4 of the registry row for that
# parameter. The packaging validator compares exactly this way.
# ---------------------------------------------------------------------------
REGISTRY="$REPO/docs/port/PARAMETERS.md"
if [ -f "$DECISION" ] && [ -f "$REGISTRY" ]; then
  mismatch=0
  checked=0
  while IFS= read -r line; do
    param=${line#- assumes }
    param=${param%% = *}
    value=${line#*= }
    reg=$(awk -F'|' -v p=" $param " '$2 == p { sub(/^ +/, "", $5); sub(/ +$/, "", $5); print $5; exit }' "$REGISTRY")
    checked=$((checked + 1))
    if [ -z "$reg" ]; then
      printf '      registry row not found for parameter: %s\n' "$param"
      mismatch=$((mismatch + 1))
    elif [ "$reg" != "$value" ]; then
      printf '      value differs for parameter: %s\n' "$param"
      mismatch=$((mismatch + 1))
    fi
  done < <("$GREP" '^- assumes ' "$DECISION")
  if [ "$checked" = "5" ] && [ "$mismatch" = "0" ]; then
    pass C16 "all 5 '- assumes' lines in review/DECISION.md are byte-identical to column 4 of the matching docs/port/PARAMETERS.md row (lines selected by $GREP, compared by shell string equality)"
  else
    fail C16 "'- assumes' lines checked $checked (expected 5), mismatches $mismatch (expected 0)"
  fi
else
  fail C16 "missing $DECISION or $REGISTRY"
fi

# ---------------------------------------------------------------------------
# C17 — the prerequisite this decision consumes is the one the run recorded.
# ---------------------------------------------------------------------------
R01_DECISION="$REPO/research/topics/01-ports-and-adapters-seam/DECISION.md"
PREREQ="$RUN_INPUTS/prerequisites.json"
if [ -f "$R01_DECISION" ] && [ -f "$PREREQ" ]; then
  want=$(python3 - "$PREREQ" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    print(json.load(fh)["R01"]["decision"])
PY
  )
  got=$(shasum -a 256 "$R01_DECISION" | awk '{print $1}')
  if [ "$want" = "$got" ]; then
    pass C17 "research/topics/01-ports-and-adapters-seam/DECISION.md sha256 matches inputs/prerequisites.json R01.decision — the published R01 read here is the revision this run pinned"
  else
    fail C17 "R01 DECISION.md sha256 $got does not match the pinned $want"
  fi
else
  fail C17 "missing $R01_DECISION or $PREREQ"
fi

# ---------------------------------------------------------------------------
# C18 — the py-side evidence the BASELINE-REVIEW: F120 finding rests on: the
# port-contract suite runs against the REAL HTTP adapter with its network
# mocked, and the dependency exists for that purpose.
# ---------------------------------------------------------------------------
if [ -d "$PY_REPO/.git" ]; then
  py_dep=$(git -C "$PY_REPO" show "$PY_PIN:pyproject.toml" 2> /dev/null | "$GREP" -c 'responses>=0.25.*HTTP mock for the port-contract suite')
  py_doc=$(git -C "$PY_REPO" show "$PY_PIN:tests/core/test_projects_repository_contract.py" 2> /dev/null | "$GREP" -c 'the in-memory fake and the real HTTP adapter')
  if [ "$py_dep" = "1" ] && [ "$py_doc" = "1" ]; then
    pass C18 "py at pin b08bccfb: 1 pyproject.toml line pairing 'responses>=0.25' with 'HTTP mock for the port-contract suite' and 1 contract-suite docstring line naming 'the in-memory fake and the real HTTP adapter' (counts by $GREP -c) — the contract suite is run against the real adapter over a mocked network"
  else
    fail C18 "py pin evidence: dependency-comment lines $py_dep, docstring lines $py_doc (counts by $GREP -c), expected 1 and 1"
  fi
else
  skip C18 "py-launch-blueprint clone absent at $PY_REPO (expected in a clean git archive extraction); py pin evidence not re-read"
fi

# ---------------------------------------------------------------------------
# C19 — gate 6: the required-normal dependency counts the decision cites for the
# three HTTP candidates. The opus report gives httpmock 26; this check re-reads
# the endpoint and records 25.
# ---------------------------------------------------------------------------
counts=""
c19_ok=1
for spec in wiremock/0.6.5 mockito/1.7.2 httpmock/0.8.3; do
  name=${spec%%/*}
  code=$(fetch "https://crates.io/api/v1/crates/$spec/dependencies" "$WORK/$name-deps.json")
  if [ "$code" != "200" ]; then
    c19_ok=0
    counts="$counts $name=HTTP$code"
    continue
  fi
  n=$(python3 - "$WORK/$name-deps.json" <<'PY'
import json, sys
with open(sys.argv[1]) as fh:
    deps = json.load(fh)["dependencies"]
print(len([d for d in deps if d["kind"] == "normal" and not d["optional"]]))
PY
  )
  counts="$counts $name=$n"
done
if [ "$c19_ok" = "1" ] && [ "$counts" = " wiremock=15 mockito=16 httpmock=25" ]; then
  pass C19 "required normal dependencies at the newest non-yanked version:$counts — httpmock carries the heaviest tree of the three, and the figure is 25, not the 26 the opus report states"
else
  fail C19 "required normal dependency counts are$counts; expected ' wiremock=15 mockito=16 httpmock=25'"
fi

# ---------------------------------------------------------------------------
# C20 — the evidence for wiremock's *effective* MSRV being at least 1.88 even
# though it declares none: a user-reported let-chain compile error against
# 0.6.5, let chains having stabilized in Rust 1.88.0.
# ---------------------------------------------------------------------------
if command -v gh > /dev/null 2>&1; then
  issue=$(gh api repos/LukeMathWalker/wiremock-rs/issues/173 \
    --jq '[.title, (.created_at | split("T")[0]), .state] | join(" | ")' 2> /dev/null)
  if [ -z "$issue" ]; then
    fail C20 "gh api repos/LukeMathWalker/wiremock-rs/issues/173 returned nothing"
  elif [ "$issue" = "Error: \`let\` expressions in this position are unstable | 2025-08-27 | closed" ]; then
    pass C20 "api.github.com repos/LukeMathWalker/wiremock-rs/issues/173: title 'Error: \`let\` expressions in this position are unstable', created 2025-08-27, state closed — a let-chain compile failure reported against 0.6.5, so the crate's effective floor is at least Rust 1.88.0 even though it declares no rust-version"
  else
    fail C20 "repos/LukeMathWalker/wiremock-rs/issues/173 reads '$issue'; expected the let-expressions title, created 2025-08-27, state closed"
  fi
else
  skip C20 "gh not on PATH; api.github.com repos/LukeMathWalker/wiremock-rs/issues/173 not queried"
fi

printf '#\n'
if [ "$FAILED" = "0" ]; then
  printf 'RESULT: all checks passed (0 FAIL)\n'
else
  printf 'RESULT: %s check(s) FAILED\n' "$FAILED"
fi
exit "$FAILED"
