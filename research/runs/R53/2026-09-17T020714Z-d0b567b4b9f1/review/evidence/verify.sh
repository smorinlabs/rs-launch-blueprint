#!/usr/bin/env bash
# R53 (config-schema-validation) empirical check. Verifies the load-bearing claims
# of raw/codex.md and raw/opus.md, and settles the one disagreement between them.
#
# It implements nothing. No template file is created, no config module is written,
# no schema or loader is scaffolded. The only code it compiles is a throwaway
# probe built under $TMPDIR (section 8), outside the repository, which runs the
# candidate crates over six literal TOML strings — "run the recommended tool
# against a few sample inputs". The probe directory is deleted on exit.
#
# Contract:
#   * `set -uo pipefail` so a failing command inside a pipeline cannot be masked
#     by a succeeding one.
#   * Every load-bearing claim goes through assert_has / assert_hasre /
#     assert_absent / assert_eq / assert_ge, which compare the CONTENT expected.
#     A check that cannot fail is not evidence.
#   * Volatile figures (download counts, stars, pushed_at, open-issue totals) are
#     RECORDED with endpoint and retrieval date and asserted only against a floor,
#     never against an exact value. They print with a `VOLATILE` marker so that a
#     rerun diff is readable: VOLATILE lines drift, PASS/FAIL/SKIP lines do not.
#   * /usr/bin/grep is invoked by absolute path everywhere and is named beside
#     every count, because a typed `grep` in an agent shell may be ugrep, which
#     honours .gitignore and would turn a census into a subset.
#   * Sections needing something absent from a clean `git archive HEAD`
#     extraction (the sibling cli-standards clone, cargo, gh, the network) print
#     `SKIP <name>` and are not counted as failures.
#   * Adopter manifests and lockfiles are read at PINNED commits, never at a
#     moving branch, so a rerun reads the same bytes.
#   * Exit status is the number of failed assertions, so 0 means zero failures.

# shellcheck disable=SC2016
# SC2016 ("expressions don't expand in single quotes") is disabled file-wide and
# deliberately: the needles asserted below are Markdown and Rust literals that
# contain backticks and `$`, and single quotes are exactly what keeps them literal.
# With this one directive `shellcheck verify.sh` exits 0 with no other finding.

set -uo pipefail

FAILURES=0
CHECKS=0
SKIPS=0
UA="rs-launch-blueprint-research/1.0 (R53 empirical check)"
RETRIEVED="$(date -u +%Y-%m-%d)"
ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
RUN="$ROOT/research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1"
WORK="${TMPDIR:-/tmp}/r53-verify.$$"
STANDARD_REPO="/Users/stevemorin/c/cli-standards"
STANDARD_BLOB="f9de0437baece3383e73ca2c5f48b7ab399b51c7"

# Sibling run directories this decision must not contradict.
R52_RUN="$ROOT/research/runs/R52/2026-09-17T020714Z-4e96c68a620c"
R55_RUN="$ROOT/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1"

# Exact versions the probe pins, so a rerun resolves the same crates.
SERDE_VER="1.0.229"
TOML_VER="1.1.6"
GARDE_VER="0.23.0"
VALIDATOR_VER="0.21.0"
SERDE_VALID_VER="3.1.2"

mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

say() { printf '%s\n' "$*"; }
hdr() { printf '\n======== %s ========\n' "$*"; }

fail() {
    FAILURES=$((FAILURES + 1))
    printf 'FAIL %s :: %s\n' "$1" "$2"
}

pass() { printf 'PASS %s :: %s\n' "$1" "$2"; }

skip() {
    SKIPS=$((SKIPS + 1))
    printf 'SKIP %s :: %s\n' "$1" "$2"
}

volatile() { printf 'VOLATILE %s :: %s (endpoint above, retrieved %s)\n' "$1" "$2" "$RETRIEVED"; }

# assert_has <id> <fixed-needle> <haystack-file>
assert_has() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qF -- "$2" "$3"; then
        pass "$1" "/usr/bin/grep -F found: $2"
    else
        fail "$1" "/usr/bin/grep -F did NOT find: $2 (in $3)"
    fi
}

# assert_hasre <id> <extended-regex> <haystack-file>
assert_hasre() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qE -- "$2" "$3"; then
        pass "$1" "/usr/bin/grep -E matched: $2"
    else
        fail "$1" "/usr/bin/grep -E did NOT match: $2 (in $3)"
    fi
}

# assert_absent <id> <extended-regex> <haystack-file>
assert_absent() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qE -- "$2" "$3"; then
        fail "$1" "/usr/bin/grep -E unexpectedly matched: $2 (in $3)"
    else
        pass "$1" "/usr/bin/grep -E correctly found no match for: $2"
    fi
}

# assert_eq <id> <expected> <actual>
assert_eq() {
    CHECKS=$((CHECKS + 1))
    if [ "$2" = "$3" ]; then
        pass "$1" "equal: $2"
    else
        fail "$1" "expected [$2] got [$3]"
    fi
}

# assert_ge <id> <floor> <actual-integer>
assert_ge() {
    CHECKS=$((CHECKS + 1))
    case "$3" in
        ''|*[!0-9]*) fail "$1" "not an integer: [$3]"; return ;;
    esac
    if [ "$3" -ge "$2" ]; then
        pass "$1" "$3 >= $2"
    else
        fail "$1" "expected >= $2, got $3"
    fi
}

net_ok=0
if /usr/bin/curl -fsS -m 25 -A "$UA" -o "$WORK/net.json" "https://crates.io/api/v1/crates/serde"; then
    net_ok=1
fi

gh_ok=0
if command -v gh >/dev/null 2>&1 && gh api rate_limit >/dev/null 2>&1; then
    gh_ok=1
fi

cargo_ok=0
if command -v cargo >/dev/null 2>&1; then
    cargo_ok=1
fi

hdr "0  toolchain, host, retrieval date"
say "retrieval date (UTC): $RETRIEVED"
say "uname: $(uname -srm)"
say "sw_vers: $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) $(sw_vers -buildVersion 2>/dev/null)"
if [ "$cargo_ok" = 1 ]; then
    say "rustc: $(rustc --version)"
    say "cargo: $(cargo --version)"
else
    say "rustc/cargo: absent"
fi
say "curl: $(/usr/bin/curl --version | head -1)"
say "grep: $(/usr/bin/grep --version | head -1)"
say "jq: $(jq --version 2>/dev/null || echo absent)"
say "gh: $(gh --version 2>/dev/null | head -1 || echo absent)"
say "network reachable (crates.io): $net_ok"
say "gh authenticated: $gh_ok"
say "repository root: $ROOT"

hdr "1  the binding prompt's Couplings block"

sed -n '/^## Couplings/,/^## Questions/p' "$RUN/inputs/prompt.md" > "$WORK/couplings.txt"
say "--- inputs/prompt.md '## Couplings' ---"
cat "$WORK/couplings.txt"
assert_hasre S01 '^- owns:[[:space:]]*$'                        "$WORK/couplings.txt"
assert_has   S02 '- consumes: R67: error-taxonomy-exit-codes'   "$WORK/couplings.txt"
assert_has   S03 '- effort: focused'                            "$WORK/couplings.txt"
assert_has   S04 '- engines: codex, opus'                       "$WORK/couplings.txt"

hdr "2  the five '- assumes' lines, rebuilt from the live registry"

# The registry's error-taxonomy-exit-codes value is ~4000 characters. It is
# generated here from docs/port/PARAMETERS.md and byte-compared with the lines in
# DECISION.md, because retyping it by hand is how a publication-blocking
# one-character drift happens.
UV=""
if command -v uv >/dev/null 2>&1; then
    UV="$(command -v uv)"
elif [ -x "$HOME/.local/bin/uv" ]; then
    UV="$HOME/.local/bin/uv"
fi
registry_built=0
if [ -n "$UV" ] && [ -f "$ROOT/scripts/research_validation.py" ]; then
    if (cd "$ROOT" && "$UV" run --offline --no-project --no-python-downloads --no-cache python3 - <<'PY' > "$WORK/registry-assumes.txt" 2>"$WORK/registry-assumes.err"
import sys
sys.path.insert(0, "scripts")
import research_validation as v
from pathlib import Path
errors = []
registry = v._parse_parameters(Path("."), errors)
if errors:
    raise SystemExit("registry parse errors: %s" % errors)
for name in ("msrv-policy", "rust-edition", "target-os-matrix", "license", "error-taxonomy-exit-codes"):
    print("- assumes %s = %s" % (name, registry[name]["value"]))
PY
    ); then
        registry_built=1
    fi
fi

if [ "$registry_built" = 1 ]; then
    assert_eq S05 "5" "$(/usr/bin/grep -c '^- assumes ' "$WORK/registry-assumes.txt")"
    say "(count above from /usr/bin/grep -c over the whole file, not a truncated listing)"
    decision="$RUN/review/DECISION.md"
    if [ -f "$decision" ]; then
        /usr/bin/grep '^- assumes ' "$decision" > "$WORK/decision-assumes.txt"
        CHECKS=$((CHECKS + 1))
        if diff -u "$WORK/registry-assumes.txt" "$WORK/decision-assumes.txt" > "$WORK/assumes.diff" 2>&1; then
            pass S06 "all five '- assumes' lines are byte-identical to docs/port/PARAMETERS.md"
        else
            fail S06 "'- assumes' lines differ from the registry:"
            cat "$WORK/assumes.diff"
        fi
        # The prompt's `owns:` line is empty, so the decision must carry no owned
        # parameter at all.
        assert_eq S07 "0" "$(/usr/bin/grep -c '^- owns ' "$decision")"
        assert_eq S08 "0" "$(/usr/bin/grep -c '^CONFLICT:' "$decision")"
    else
        skip S06 "review/DECISION.md not written yet"
        skip S07 "review/DECISION.md not written yet"
        skip S08 "review/DECISION.md not written yet"
    fi
else
    skip S05 "uv or scripts/research_validation.py unavailable"
    skip S06 "uv or scripts/research_validation.py unavailable"
    skip S07 "uv or scripts/research_validation.py unavailable"
    skip S08 "uv or scripts/research_validation.py unavailable"
fi

hdr "3  ledger and baseline-review rows this item settles"

/usr/bin/grep -n '^| F228 \|^| F229 ' "$ROOT/docs/port/COMMONALITY.md" > "$WORK/rows.txt"
say "--- docs/port/COMMONALITY.md F228 / F229 (row count: $(/usr/bin/grep -c . "$WORK/rows.txt") from /usr/bin/grep -c) ---"
cut -c1-220 "$WORK/rows.txt"
assert_has   S09 '| F228 | config schema validation library | config-env-logging | different | DIVERGENT | R53 |' "$WORK/rows.txt"
assert_has   S10 '| F229 | typed config schema with per-key validation | config-env-logging | same | COMMON → REUSE | — |' "$WORK/rows.txt"
assert_has   S11 "validation-before-use with constrained types or explicit checks, and representative rejected values, are acceptance criteria whose mechanism R53 selects" "$WORK/rows.txt"
assert_has   S12 "serde's typed deserialization preserves this same pattern, so this is a substitution in spirit, not an override" "$WORK/rows.txt"

/usr/bin/grep -n '^| F229 \|^BASELINE-REVIEW: F229' "$ROOT/docs/port/BASELINE-REVIEW.md" > "$WORK/br229.txt"
say "--- docs/port/BASELINE-REVIEW.md F229 (line count: $(/usr/bin/grep -c . "$WORK/br229.txt") from /usr/bin/grep -c) ---"
cut -c1-300 "$WORK/br229.txt"
assert_has   S13 'R53 (mechanism), R55 (per-key failure tolerance, F238) | retained' "$WORK/br229.txt"
assert_has   S14 'BASELINE-REVIEW: F229 — configuration is validated before use' "$WORK/br229.txt"
assert_has   S15 'a derived integer accepts values ts config.ts:40 rejects with .positive()' "$WORK/br229.txt"

# Fitness gate 1 (licence) is inapplicable by owner ruling. Nothing below is
# excluded on licence; licence strings are reported as metadata only.
assert_has   S16 '### 2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)' "$ROOT/docs/port/OWNER-REVIEW.md"
assert_has   S17 "we don't need to check the licensing for any tool we use" "$ROOT/docs/port/OWNER-REVIEW.md"

hdr "4  the consumed prerequisite (R67) and the two siblings in flight (R52, R55)"

R67_DECISION="$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
expected_r67="$(jq -r '.R67.decision' "$RUN/inputs/prerequisites.json" 2>/dev/null)"
actual_r67="$(shasum -a 256 "$R67_DECISION" 2>/dev/null | cut -d' ' -f1)"
say "inputs/prerequisites.json .R67.decision = $expected_r67"
say "sha256 research/topics/67-.../DECISION.md = $actual_r67"
assert_eq S18 "$expected_r67" "$actual_r67"

assert_has S19 '`RSLB202` config document unparsable → 2' "$R67_DECISION"
assert_has S20 '`RSLB203` config value invalid → 2' "$R67_DECISION"
assert_has S21 '| `RSLB203` config value invalid | 2 | **This template'"'"'s choice.**' "$R67_DECISION"
assert_has S22 '`{"error":{"code","message","hint"?}}`' "$R67_DECISION"
assert_has S23 'must be able to name the offending input per R7.6' "$R67_DECISION"
assert_has S24 '`thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only' "$R67_DECISION"

# R52 (toml-crate) was synthesized the same day. This item states a coupling to it
# and must not restate or contradict its crate choice.
R52_DECISION="$R52_RUN/review/DECISION.md"
if [ -f "$R52_DECISION" ]; then
    sed -n '/^## Decision/,/^### Principles and implementation/p' "$R52_DECISION" > "$WORK/r52-head.txt"
    say "--- R52 '## Decision' head (first 40 lines) ---"
    head -40 "$WORK/r52-head.txt"
    assert_hasre S25 '\| `toml` \| `1\.1\.6`' "$WORK/r52-head.txt"
    assert_hasre S26 '\| `toml_edit` \| `0\.25\.15`' "$WORK/r52-head.txt"
    # No preserve_order => toml::Table is BTreeMap-backed => deterministic key order.
    assert_has   S27 '**not** `preserve_order`' "$WORK/r52-head.txt"
    # R52 re-verify trigger 6 names this item; record that it is not tripped.
    assert_has   S28 'R53 concludes it needs per-field byte spans beyond `serde_spanned` and' "$R52_DECISION"
else
    skip S25 "R52 review/DECISION.md absent"
    skip S26 "R52 review/DECISION.md absent"
    skip S27 "R52 review/DECISION.md absent"
    skip S28 "R52 review/DECISION.md absent"
fi

# R55 (config-error-tolerance) is being synthesized in parallel. Its Codex raw
# raised a CONFLICT against R67's RSLB203 row, which is the same row this item's
# aggregate report feeds. Carry the line; do not adjudicate it here.
R55_CODEX="$R55_RUN/raw/codex.md"
if [ -f "$R55_CODEX" ]; then
    /usr/bin/grep -o 'CONFLICT: R67 .*cross-field invariant\.' "$R55_CODEX" | head -1 > "$WORK/r55-conflict.txt"
    say "--- R55 raw/codex.md CONFLICT line ---"
    cat "$WORK/r55-conflict.txt"
    assert_has S29 'CONFLICT: R67 error-taxonomy-exit-codes' "$WORK/r55-conflict.txt"
    assert_has S30 'R55 requires an individually invalid declared config value to warn-and-drop' "$WORK/r55-conflict.txt"
    # R55's Codex raw also states what it assumes of THIS item.
    assert_has S31 'assumes R53 validation = independently callable declared-field validation plus a separately classified cross-field invariant result' "$R55_CODEX"
else
    skip S29 "R55 raw/codex.md absent"
    skip S30 "R55 raw/codex.md absent"
    skip S31 "R55 raw/codex.md absent"
fi

hdr "5  sibling decisions the recommendation reuses rather than re-deciding"

assert_has S32 '| Result data contract (wire shape) | `serde` | `1.0.229` | `features = ["derive"]` | library crate |' "$ROOT/research/topics/66-output-format-surface/DECISION.md"
assert_has S33 '`-o <table|json|markdown|name>`, default **`table`**' "$ROOT/research/topics/66-output-format-surface/DECISION.md"
assert_has S34 'unsafe_code' "$ROOT/research/topics/06-unsafe-code-policy/DECISION.md"

hdr "6  the org CLI Design Standard v1.4.14 at its pinned blob"

if [ -d "$STANDARD_REPO/.git" ] && git -C "$STANDARD_REPO" cat-file -e "$STANDARD_BLOB" 2>/dev/null; then
    git -C "$STANDARD_REPO" cat-file blob "$STANDARD_BLOB" > "$WORK/standard.md"
    say "blob $STANDARD_BLOB size: $(wc -c < "$WORK/standard.md") bytes"
    assert_has   S35 'A tool with project/user config **SHOULD** validate config files with precise file/key diagnostics and **SHOULD** provide `acme config validate`' "$WORK/standard.md"
    assert_has   S36 "acme config validate\` reports \`.acme/acme_config.toml:12 unknown key 'default-region'" "$WORK/standard.md"
    assert_has   S37 'name the offending input in quotes, and state a next step where possible' "$WORK/standard.md"
    assert_has   S38 '`{"error":{"code":"<stable-string>","message":"<human-readable>"}}`' "$WORK/standard.md"
    assert_has   S39 'R7.12 — Error code catalog' "$WORK/standard.md"
    # The standard names Rust config LOADERS but no validation crate anywhere, so
    # this item's crate choice is the template's to make and is not org-locked.
    assert_has   S40 'Pair with `figment`/`config` crates for the precedence chain' "$WORK/standard.md"
    assert_absent S41 '(garde|serde_valid|validify|nutype|pydantic|zod)' "$WORK/standard.md"
    say "(occurrences of the word 'validator' in the standard, /usr/bin/grep -c -i: $(/usr/bin/grep -c -i 'validator' "$WORK/standard.md"))"
    assert_eq    S42 "0" "$(/usr/bin/grep -c -i 'validator' "$WORK/standard.md")"
else
    for id in S35 S36 S37 S38 S39 S40 S41 S42; do
        skip "$id" "cli-standards clone absent at $STANDARD_REPO (not in a git archive extraction)"
    done
fi

hdr "7  registry, repository and advisory figures"

if [ "$net_ok" = 1 ]; then
    for crate in serde garde validator serde_valid nutype validify; do
        say "--- GET https://crates.io/api/v1/crates/$crate ---"
        if /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$crate.json" "https://crates.io/api/v1/crates/$crate"; then
            volatile "$crate" "recent_downloads=$(jq -r '.crate.recent_downloads' "$WORK/$crate.json") downloads=$(jq -r '.crate.downloads' "$WORK/$crate.json") max_stable_version=$(jq -r '.crate.max_stable_version' "$WORK/$crate.json")"
        else
            say "(fetch failed for $crate)"
        fi
        say "--- GET https://crates.io/api/v1/crates/$crate/versions ---"
        if /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$crate-versions.json" "https://crates.io/api/v1/crates/$crate/versions"; then
            jq -r '[.versions[]|select(.yanked==false)][0]|"newest non-yanked: num=\(.num) created_at=\(.created_at) rust_version=\(.rust_version) license=\(.license)"' "$WORK/$crate-versions.json"
        fi
    done

    # Stable, assertable facts (these do not drift between reruns of the same day
    # and change only when the crate publishes).
    assert_eq S43 "$SERDE_VER"       "$(jq -r '[.versions[]|select(.yanked==false)][0].num' "$WORK/serde-versions.json")"
    assert_eq S44 "$GARDE_VER"       "$(jq -r '[.versions[]|select(.yanked==false)][0].num' "$WORK/garde-versions.json")"
    assert_eq S45 "$VALIDATOR_VER"   "$(jq -r '[.versions[]|select(.yanked==false)][0].num' "$WORK/validator-versions.json")"
    assert_eq S46 "$SERDE_VALID_VER" "$(jq -r '[.versions[]|select(.yanked==false)][0].num' "$WORK/serde_valid-versions.json")"

    # Gate 2. The floor is stable-minus-2. A DEPENDENCY passes when its declared
    # rust_version is at or BELOW the floor; a declared version below the floor is
    # a pass, not a failure. serde 1.56, garde 1.87, validator 1.88 all pass a 1.96
    # floor. serde_valid and nutype declare none, which is an evidence gap.
    say "--- GET https://static.rust-lang.org/dist/channel-rust-stable.toml ([pkg.rust] version) ---"
    if /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/channel.toml" "https://static.rust-lang.org/dist/channel-rust-stable.toml"; then
        stable_line="$(/usr/bin/grep -m1 -A2 '^\[pkg.rust\]' "$WORK/channel.toml" | /usr/bin/grep -m1 '^version = ')"
        say "current Rust stable: $stable_line"
        volatile "rust-stable" "$stable_line"
    fi
    assert_eq S47 "1.56"  "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$WORK/serde-versions.json")"
    assert_eq S48 "1.87"  "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$WORK/garde-versions.json")"
    assert_eq S49 "1.88"  "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$WORK/validator-versions.json")"
    assert_eq S50 "null"  "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$WORK/serde_valid-versions.json")"
    assert_eq S51 "null"  "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$WORK/validify-versions.json")"

    # Licence strings are recorded as metadata only; gate 1 is inapplicable (S16).
    for crate in serde garde validator serde_valid nutype validify; do
        say "licence (metadata only, nothing excluded on it): $crate = $(jq -r '[.versions[]|select(.yanked==false)][0].license' "$WORK/$crate-versions.json")"
    done

    # Dependency trees: the gate-6 cost argument, and the thiserror collision.
    for crate in "serde/$SERDE_VER" "garde/$GARDE_VER" "validator/$VALIDATOR_VER" "serde_valid/$SERDE_VALID_VER"; do
        name="${crate%%/*}"
        say "--- GET https://crates.io/api/v1/crates/$crate/dependencies (kind=normal, optional=false) ---"
        if /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$name-deps.json" "https://crates.io/api/v1/crates/$crate/dependencies"; then
            jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false)]|sort_by(.crate_id)|.[]|"  \(.crate_id) \(.req)"' "$WORK/$name-deps.json"
            say "  non-optional normal count: $(jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false)]|length' "$WORK/$name-deps.json")"
        fi
    done
    assert_eq S52 "serde_core" "$(jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false)]|map(.crate_id)|join(",")' "$WORK/serde-deps.json")"
    assert_eq S53 "compact_str,smallvec" "$(jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false)]|map(.crate_id)|sort|join(",")' "$WORK/garde-deps.json")"
    assert_eq S54 "6" "$(jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false)]|length' "$WORK/validator-deps.json")"
    assert_hasre S55 '"crate_id": ?"regex"' "$WORK/validator-deps.json"
    # serde_valid pulls thiserror ^1.0, semver-incompatible with R67's library-crate
    # thiserror 2.x, so a library crate would compile two majors of its error derive.
    assert_eq S56 "1" "$(jq -r '[.dependencies[]|select(.kind=="normal" and .optional==false and .crate_id=="thiserror" and (.req|startswith("^1")))]|length' "$WORK/serde_valid-deps.json")"

    # Feature surfaces: garde declares no `default` key, so features=["derive"] is
    # the whole surface; serde's default is ["std"], so ["derive"] is additive.
    say "--- GET https://crates.io/api/v1/crates/garde/$GARDE_VER (features) ---"
    if /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/garde-ver.json" "https://crates.io/api/v1/crates/garde/$GARDE_VER"; then
        jq -r '.version.features|keys|join(", ")' "$WORK/garde-ver.json"
    fi
    assert_eq S57 "false" "$(jq -r '.version.features|has("default")' "$WORK/garde-ver.json")"
    assert_eq S58 "true"  "$(jq -r '.version.features|has("derive")'  "$WORK/garde-ver.json")"

    # Gate 3. RustSec answers 404 for a package with no advisory. That is only
    # evidence if 404 is distinguishable from an outage, so three known-advisory
    # controls must answer 200 in the SAME run, and a nonexistent name must 404.
    hdr "7b  RustSec advisory pages, with 200/404 controls in the same run"
    for pkg in serde garde validator serde_valid nutype validify; do
        code="$(/usr/bin/curl -s -o "$WORK/rustsec-$pkg.html" -w '%{http_code}' -m 30 -A "$UA" "https://rustsec.org/packages/$pkg.html")"
        say "https://rustsec.org/packages/$pkg.html -> HTTP $code"
        assert_eq "S59-$pkg" "404" "$code"
    done
    for ctl in atty time openssl; do
        code="$(/usr/bin/curl -s -o "$WORK/rustsec-ctl-$ctl.html" -w '%{http_code}' -m 30 -A "$UA" "https://rustsec.org/packages/$ctl.html")"
        say "CONTROL https://rustsec.org/packages/$ctl.html -> HTTP $code"
        assert_eq "S60-$ctl" "200" "$code"
    done
    code="$(/usr/bin/curl -s -o /dev/null -w '%{http_code}' -m 30 -A "$UA" "https://rustsec.org/packages/zzz-not-a-real-crate-r53.html")"
    say "CONTROL nonexistent crate name -> HTTP $code"
    assert_eq S61 "404" "$code"
    say "NOTE: 404 is the no-advisory response for a real crate name, but it cannot"
    say "      be distinguished from 'name unknown to RustSec'. Recorded, not glossed."
else
    for id in S43 S44 S45 S46 S47 S48 S49 S50 S51 S52 S53 S54 S55 S56 S57 S58 S61; do
        skip "$id" "no network"
    done
    skip S59 "no network"
    skip S60 "no network"
fi

hdr "8  GitHub repository state and the garde maintenance signal"

if [ "$gh_ok" = 1 ]; then
    for repo in serde-rs/serde jprochazk/garde Keats/validator ya7010/serde_valid; do
        say "--- gh api repos/$repo ---"
        gh api "repos/$repo" --jq '"stargazers_count=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)"' > "$WORK/gh-${repo//\//-}.txt"
        cat "$WORK/gh-${repo//\//-}.txt"
        volatile "$repo" "$(cat "$WORK/gh-${repo//\//-}.txt")"
        assert_has "S62-${repo//\//-}" 'archived=false' "$WORK/gh-${repo//\//-}.txt"
    done

    say "--- gh api search/issues (total_count, never open_issues_count) ---"
    for repo in serde-rs/serde jprochazk/garde Keats/validator; do
        n="$(gh api "search/issues?q=repo:$repo+is:issue+is:open" --jq '.total_count')"
        say "$repo open issues (total_count) = $n"
        volatile "$repo-open-issues" "$n"
        assert_ge "S63-${repo//\//-}" 0 "$n"
        sleep 3
    done

    # The concrete at-risk signal for garde is NOT the release age (0.23.0 was
    # 3.8 months old on 2026-09-17, so the 6-month trigger has not fired). It is
    # that the only default-branch commits since the release are a Dependabot
    # Actions bump and its merge.
    say "--- gh api repos/jprochazk/garde/commits?since=2026-05-23T16:00:00Z ---"
    gh api "repos/jprochazk/garde/commits?since=2026-05-23T16:00:00Z&per_page=100" \
        --jq '.[]|"\(.commit.author.date) \(.author.login // "unknown") \(.commit.message|split("\n")[0])"' > "$WORK/garde-commits.txt"
    cat "$WORK/garde-commits.txt"
    total="$(/usr/bin/grep -c . "$WORK/garde-commits.txt")"
    bots="$(/usr/bin/grep -c -E 'dependabot|Bump |github-actions' "$WORK/garde-commits.txt")"
    say "commits after the 0.23.0 release: $total (from /usr/bin/grep -c over the whole file); dependabot-related: $bots"
    assert_eq S64 "2" "$total"
    assert_eq S65 "2" "$bots"

    say "--- gh api repos/serde-rs/serde/pulls/2891 (the project's own validation-hook proposal) ---"
    gh api repos/serde-rs/serde/pulls/2891 --jq '"state=\(.state) merged=\(.merged) created_at=\(.created_at) title=\(.title)"' > "$WORK/pr2891.txt"
    cat "$WORK/pr2891.txt"
    assert_has S66 'state=open merged=false created_at=2025-02-11' "$WORK/pr2891.txt"
    assert_has S67 'Support `#[serde(validate = "function")]`' "$WORK/pr2891.txt"

    hdr "8b  practice evidence: seven pinned Rust CLI lockfiles"
    # Read Cargo.lock, not Cargo.toml: a lockfile covers every workspace member and
    # every transitive dependency, so absence there is a strictly stronger claim
    # than absence from a root manifest. Each is read at a PINNED commit.
    printf '%s\n' \
        "alacritty/alacritty d692748d3f61253ebe9f5094320120d22f6a046f" \
        "starship/starship 4ff40d066af2dd316dcb4742544254436e7e8190" \
        "helix-editor/helix 079a789e8cb08ead67f19e1971a1b7438b37354b" \
        "zellij-org/zellij 474ea0cef620c83d6ec05a7c28c7f80c4f63bbbb" \
        "jj-vcs/jj e6dd2c0d60f22ef8d21d171b5fb8e4178f0af1d9" \
        "rust-lang/mdBook afe6eb8836bf49bf6e23d15ccf1b87d8a5395ca4" \
        "EmbarkStudios/cargo-deny 79d7f54dc1bfd8cc8105fac917d3dcc7675eb026" > "$WORK/pins.txt"
    total_pkgs=0
    total_validation=0
    surveyed=0
    while read -r repo sha; do
        [ -n "$repo" ] || continue
        if gh api "repos/$repo/contents/Cargo.lock?ref=$sha" -H 'Accept: application/vnd.github.raw' > "$WORK/lock.toml" 2>/dev/null; then
            pkgs="$(/usr/bin/grep -c '^name = ' "$WORK/lock.toml")"
            vhits="$(/usr/bin/grep -c -E '^name = "(validator|validator_derive|garde|garde_derive|serde_valid|nutype|validify)"$' "$WORK/lock.toml")"
            serdeh="$(/usr/bin/grep -c '^name = "serde"$' "$WORK/lock.toml")"
            tomls="$(/usr/bin/grep -oE '^name = "(toml|toml_edit|toml-span|basic-toml)"$' "$WORK/lock.toml" | sort -u | tr '\n' ' ')"
            say "$repo@${sha:0:12} resolved_packages=$pkgs serde=$serdeh toml_family=[$tomls] validation_crates=$vhits"
            say "  (all four counts from /usr/bin/grep -c / -oE over the whole lockfile, never a truncated prefix)"
            total_pkgs=$((total_pkgs + pkgs))
            total_validation=$((total_validation + vhits))
            surveyed=$((surveyed + 1))
            assert_eq "S68-${repo//\//-}" "0" "$vhits"
            assert_ge "S69-${repo//\//-}" 1 "$serdeh"
        else
            skip "S68-${repo//\//-}" "lockfile unavailable at the pinned commit"
            skip "S69-${repo//\//-}" "lockfile unavailable at the pinned commit"
        fi
    done < "$WORK/pins.txt"
    say "surveyed lockfiles: $surveyed; total resolved packages: $total_pkgs; total validation-crate occurrences: $total_validation"
    assert_eq S70 "7" "$surveyed"
    assert_eq S71 "0" "$total_validation"
else
    for id in S62 S63 S64 S65 S66 S67 S68 S69 S70 S71; do
        skip "$id" "gh absent or unauthenticated"
    done
fi

hdr "9  behavioural probe: the candidate mechanisms on six literal TOML strings"

# This is the check that settles the engines' one disagreement. Codex recommends
# serde + garde; Opus recommends serde alone plus a per-key loop, on the ground
# that a serde-layered validator never runs when a type error is present. The
# probe runs both and counts what each reports. Nothing is written into the
# repository; $P is under $TMPDIR and is deleted by the EXIT trap.
if [ "$cargo_ok" = 1 ] && [ "$net_ok" = 1 ]; then
    P="$WORK/probe"
    mkdir -p "$P/src"
    cat > "$P/Cargo.toml" <<EOF
[package]
name = "r53probe"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
serde = { version = "=$SERDE_VER", features = ["derive"] }
toml = "=$TOML_VER"
garde = { version = "=$GARDE_VER", default-features = false, features = ["derive"] }
EOF
    cat > "$P/src/main.rs" <<'RUST'
// Throwaway verification probe for R53. Not template code; never committed as
// Rust source; compiled outside the repository and deleted after the run.
use serde::Deserialize;
use std::num::NonZeroU32;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
enum OutputFormat { #[default] Table, Json, Markdown, Name }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
enum ColorChoice { #[default] Auto, Always, Never }

#[derive(Debug, Default, Deserialize)]
#[serde(default)]
struct OutputSettings { format: OutputFormat, color: ColorChoice, limit: Option<NonZeroU32> }

#[derive(Debug, Default, Deserialize)]
#[serde(default)]
struct ConfigFile { output: OutputSettings }

#[derive(Debug, Default, Deserialize, garde::Validate)]
#[serde(default)]
struct GardeOutput {
    #[garde(skip)] format: OutputFormat,
    #[garde(range(min = 1))] limit: u32,
    #[garde(length(min = 1))] workspace: String,
}

const SYNTAX_BAD: &str = "[output\nformat = \"json\"\n";
const TYPE_AND_VALUE_BAD: &str = "[output]\nformat = \"yaml\"\nlimit = \"abc\"\ncolor = \"rainbow\"\n";
const GARDE_TYPE_BAD: &str = "format = \"yaml\"\nlimit = 0\nworkspace = \"\"\n";
const GARDE_TYPES_OK: &str = "format = \"json\"\nlimit = 0\nworkspace = \"\"\n";
const ZERO_LIMIT: &str = "[output]\nlimit = 0\n";

fn main() {
    // P1 — derived Deserialize is fail-fast: one error for a document with three bad keys.
    match toml::from_str::<ConfigFile>(TYPE_AND_VALUE_BAD) {
        Ok(v) => println!("P1_SERDE_DERIVE = UNEXPECTED_OK {v:?}"),
        Err(e) => {
            println!("P1_SERDE_DERIVE_ERROR_COUNT = 1");
            println!("P1_SERDE_DERIVE_MSG = {}", e.message());
            println!("P1_SERDE_DERIVE_DISPLAY_FIRSTLINE = {}", e.to_string().lines().next().unwrap_or(""));
        }
    }

    // P2 — a serde-layered validator never runs when a type error is present.
    match toml::from_str::<GardeOutput>(GARDE_TYPE_BAD) {
        Ok(v) => {
            let n = match garde::Validate::validate(&v) { Ok(()) => 0, Err(r) => r.iter().count() };
            println!("P2_GARDE_REACHED = true P2_GARDE_REPORT_ENTRIES = {n}");
        }
        Err(e) => {
            println!("P2_GARDE_REACHED = false");
            println!("P2_GARDE_REPORT_ENTRIES = 0");
            println!("P2_SERDE_FAILED_FIRST_MSG = {}", e.message());
        }
    }

    // P3 — garde DOES aggregate CONSTRAINT errors once every type is accepted.
    match toml::from_str::<GardeOutput>(GARDE_TYPES_OK) {
        Ok(v) => match garde::Validate::validate(&v) {
            Ok(()) => println!("P3_GARDE_CONSTRAINT_ENTRIES = 0"),
            Err(r) => {
                println!("P3_GARDE_CONSTRAINT_ENTRIES = {}", r.iter().count());
                for (p, e) in r.iter() { println!("P3_GARDE_ENTRY = {p}: {e}"); }
            }
        },
        Err(e) => println!("P3_GARDE_DESERIALIZE_FAILED = {}", e.message()),
    }

    // P4 — a per-key loop over toml::Table aggregates BOTH type and value errors,
    //      and yields the surviving partial value alongside the issue list.
    let table: toml::Table = toml::from_str(TYPE_AND_VALUE_BAD).expect("P4 table parse");
    let mut issues: Vec<(String, String)> = Vec::new();
    let mut cfg = ConfigFile::default();
    if let Some(t) = table.get("output").and_then(toml::Value::as_table) {
        println!("P4_TABLE_KEY_ORDER = {:?}", t.keys().collect::<Vec<_>>());
        if let Some(v) = field::<OutputFormat>(t, "output", "format", &mut issues) { cfg.output.format = v; }
        if let Some(v) = field::<ColorChoice>(t, "output", "color", &mut issues) { cfg.output.color = v; }
        if let Some(v) = field::<NonZeroU32>(t, "output", "limit", &mut issues) { cfg.output.limit = Some(v); }
    }
    println!("P4_PERKEY_ISSUE_COUNT = {}", issues.len());
    for (p, m) in &issues { println!("P4_ISSUE = {p}: {m}"); }
    println!("P4_PARTIAL_VALUE = {cfg:?}");

    // P5 — the two representative rejected values F229's acceptance criterion names.
    let mut zero_issues: Vec<(String, String)> = Vec::new();
    let zt: toml::Table = toml::from_str(ZERO_LIMIT).expect("P5 table parse");
    if let Some(t) = zt.get("output").and_then(toml::Value::as_table) {
        field::<NonZeroU32>(t, "output", "limit", &mut zero_issues);
    }
    for (p, m) in &zero_issues { println!("P5_NONZERO_ISSUE = {p}: {m}"); }
    let mut enum_issues: Vec<(String, String)> = Vec::new();
    if let Some(t) = table.get("output").and_then(toml::Value::as_table) {
        field::<OutputFormat>(t, "output", "format", &mut enum_issues);
    }
    for (p, m) in &enum_issues { println!("P5_ENUM_ISSUE = {p}: {m}"); }

    // P6 — the RSLB202 / RSLB203 split decided structurally, not by string matching.
    println!("P6_SYNTAX_AS_TABLE_OK = {}", toml::from_str::<toml::Table>(SYNTAX_BAD).is_ok());
    println!("P6_BADVALUES_AS_TABLE_OK = {}", toml::from_str::<toml::Table>(TYPE_AND_VALUE_BAD).is_ok());
    println!("P6_BADVALUES_AS_STRUCT_OK = {}", toml::from_str::<ConfigFile>(TYPE_AND_VALUE_BAD).is_ok());
}

fn field<T: serde::de::DeserializeOwned>(
    table: &toml::Table, section: &str, key: &str, issues: &mut Vec<(String, String)>,
) -> Option<T> {
    let value = table.get(key)?.clone();
    match T::deserialize(value) {
        Ok(v) => Some(v),
        Err(e) => { issues.push((format!("{section}.{key}"), e.message().to_string())); None }
    }
}
RUST
    say "probe crate: $P (throwaway; nothing is written into the repository)"
    if (cd "$P" && cargo run --quiet > "$WORK/probe.out" 2>"$WORK/probe.err"); then
        say "--- probe stdout ---"
        cat "$WORK/probe.out"
        # P1/P2: serde derive is fail-fast, and garde never runs behind it.
        assert_has S72 'P1_SERDE_DERIVE_ERROR_COUNT = 1' "$WORK/probe.out"
        assert_has S73 'P1_SERDE_DERIVE_MSG = unknown variant `rainbow`, expected one of `auto`, `always`, `never`' "$WORK/probe.out"
        assert_has S74 'P2_GARDE_REACHED = false' "$WORK/probe.out"
        assert_has S75 'P2_GARDE_REPORT_ENTRIES = 0' "$WORK/probe.out"
        assert_has S76 'P2_SERDE_FAILED_FIRST_MSG = unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`' "$WORK/probe.out"
        # P3: garde's real capability, recorded in its favour.
        assert_has S77 'P3_GARDE_CONSTRAINT_ENTRIES = 2' "$WORK/probe.out"
        assert_has S78 'P3_GARDE_ENTRY = limit: lower than 1' "$WORK/probe.out"
        assert_has S79 'P3_GARDE_ENTRY = workspace: length is lower than 1' "$WORK/probe.out"
        # P4: the recommended mechanism reports all three, with dotted paths, and
        #     hands back a partial value so the fatal-vs-drop policy stays R55's.
        assert_has S80 'P4_PERKEY_ISSUE_COUNT = 3' "$WORK/probe.out"
        assert_has S81 'P4_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`' "$WORK/probe.out"
        assert_has S82 'P4_ISSUE = output.color: unknown variant `rainbow`, expected one of `auto`, `always`, `never`' "$WORK/probe.out"
        assert_has S83 'P4_ISSUE = output.limit: invalid type: string "abc", expected a nonzero u32' "$WORK/probe.out"
        assert_has S84 'P4_PARTIAL_VALUE = ConfigFile { output: OutputSettings { format: Table, color: Auto, limit: None } }' "$WORK/probe.out"
        # Deterministic key order (toml without preserve_order is BTreeMap-backed),
        # so the issue list is snapshot-testable.
        assert_has S85 'P4_TABLE_KEY_ORDER = ["color", "format", "limit"]' "$WORK/probe.out"
        # P5: the two representative rejected values.
        assert_has S86 'P5_NONZERO_ISSUE = output.limit: invalid value: integer `0`, expected a nonzero u32' "$WORK/probe.out"
        assert_has S87 'P5_ENUM_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`' "$WORK/probe.out"
        # P6: RSLB202 vs RSLB203, separated by structure rather than by message text.
        assert_has S88 'P6_SYNTAX_AS_TABLE_OK = false' "$WORK/probe.out"
        assert_has S89 'P6_BADVALUES_AS_TABLE_OK = true' "$WORK/probe.out"
        assert_has S90 'P6_BADVALUES_AS_STRUCT_OK = false' "$WORK/probe.out"

        say "--- cargo tree -e normal (the probe's resolved graph) ---"
        (cd "$P" && cargo tree -e normal 2>/dev/null) | tee "$WORK/tree.txt"
        assert_hasre S91 'serde v1\.0\.229'  "$WORK/tree.txt"
        assert_hasre S92 'toml v1\.1\.6'     "$WORK/tree.txt"
        assert_hasre S93 'garde v0\.23\.0'   "$WORK/tree.txt"
        say "probe resolved packages (cargo tree lines, /usr/bin/grep -c): $(/usr/bin/grep -c . "$WORK/tree.txt")"
    else
        fail S72 "probe failed to build or run; stderr follows"
        cat "$WORK/probe.err"
    fi
else
    for id in S72 S73 S74 S75 S76 S77 S78 S79 S80 S81 S82 S83 S84 S85 S86 S87 S88 S89 S90 S91 S92 S93; do
        skip "$id" "cargo or network unavailable"
    done
fi

hdr "10  summary"
say "checks run:  $CHECKS"
say "failures:    $FAILURES"
say "skips:       $SKIPS"
say ""
say "Reproducibility rule for a rerun diff: every PASS / FAIL / SKIP line, every"
say "count and every probe output line is reproducible byte-for-byte on the same"
say "host with network, gh and cargo available. Two lines always differ between"
say "runs: the probe crate's \$TMPDIR path embeds the shell's PID. Every VOLATILE"
say "line carries a live figure (download counts, stars, pushed_at, open-issue"
say "totals, the current stable Rust version) that drifts on any longer interval"
say "and is asserted only against a floor, never an exact value. The retrieval"
say "date on line 2 changes daily by construction."
exit "$FAILURES"
