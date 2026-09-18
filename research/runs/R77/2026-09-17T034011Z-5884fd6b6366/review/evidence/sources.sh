#!/usr/bin/env bash
# R77 — empirical check, part 2 of 3: every quoted source and cited line.
#
# Asserts on CONTENT at a named line or in a named file. Three groups:
#   IN-REPO    — always available; a failure here is a real failure.
#   PINNED-EXT — the org CLI Design Standard blob, the py and ts pins, and the
#                local Cargo registry cache. These live outside this repository,
#                so a missing one is a named SKIP, never a FAIL.
#   PARAMETERS — every `- assumes` line in DECISION.md is compared byte-for-byte
#                with the value column of the live docs/port/PARAMETERS.md row.
#
# No personal email address and no token byte is read, printed or written by
# this script: the registry-cache checks read src/ files only, never a
# Cargo.toml authors field.
set -euo pipefail
set -o pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
run="$here/../.."                      # research/runs/R77/<run-id>
root="$run/../../../.."                # repository root
decision="$here/../DECISION.md"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }

# line_has <label> <file> <line-number> <expected substring>
line_has() {
  if [ ! -f "$2" ]; then sk "$1 — $2 not present"; return; fi
  got=$(/usr/bin/sed -n "${3}p" "$2")
  if printf '%s' "$got" | /usr/bin/grep -qF -- "$4"; then ok "$1"; else
    no "$1"; printf '     %s:%s expected to contain: %s\n     actual: %s\n' "$2" "$3" "$4" "$got"; fi
}
# file_has <label> <file> <expected substring>
file_has() {
  if [ ! -f "$2" ]; then sk "$1 — $2 not present"; return; fi
  if /usr/bin/grep -qF -- "$3" "$2"; then ok "$1"; else
    no "$1"; printf '     %s does not contain: %s\n' "$2" "$3"; fi
}
count_is() { # <label> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}

printf '# R77 sources — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# /usr/bin/grep version: %s\n' "$(/usr/bin/grep --version | head -1)"

# The repository root must resolve, in place and in a `git archive HEAD`
# extraction alike; if it does not, every IN-REPO check below would SKIP and
# the run would look clean while proving nothing.
if [ -f "$root/docs/port/PARAMETERS.md" ] && [ -f "$root/research/CLAUDE.md" ]; then
  ok "repository root resolves from this script's own location"
else
  no "repository root did not resolve from this script's location (tried $root)"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  exit 1
fi

############################################################################
echo '## IN-REPO — ledger, index, owner rulings, prompt'
line_has "COMMONALITY F324 is this item's row, DIVERGENT, py-only" \
  "$root/docs/port/COMMONALITY.md" 328 "| F324 | typed env settings with an app-derived env-var prefix | web-service | py-only | DIVERGENT | R77 |"
line_has "COMMONALITY F330 is R69's row (the lazy-load fallback)" \
  "$root/docs/port/COMMONALITY.md" 334 "| F330 | config loads once at startup, with a lazy-load fallback dependency | web-service | py-only | DIVERGENT | R69 |"
line_has "COMMONALITY F303 records that ts has no web service" \
  "$root/docs/port/COMMONALITY.md" 307 "| F303 | web service exists at all | web-service | py-only | DIVERGENT | R69 |"
file_has "research index R77 row: crate, py-only, DIVERGENT, owns —" \
  "$root/research/CLAUDE.md" "| R77 | web-env-settings | crate | py-only | DIVERGENT | — |"
file_has "OWNER-REVIEW carries the 2026-09-12 licence ruling heading" \
  "$root/docs/port/OWNER-REVIEW.md" "### 2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)"
file_has "owner-decisions records the withdrawal of the lenient MSRV-gate reading" \
  "$root/docs/planning/p02/owner-decisions.md" "The ruling is withdrawn. One item's exclusions stand; the other must switch to"
file_has "owner-decisions section 11 makes the reference architecture a standing input" \
  "$root/docs/planning/p02/owner-decisions.md" "## 11. Owner-supplied reference architecture (2026-09-16) -- STANDING INPUT"
file_has "the binding prompt's owns line is empty (R77 owns no parameter)" \
  "$run/inputs/prompt.md" "- owns:"
file_has "the binding prompt's consumes line is empty" \
  "$run/inputs/prompt.md" "- consumes:"

echo
echo '## IN-REPO — the owner-supplied reference architecture rows this decision answers'
ref="$run/inputs/owner-reference-axum-companion-stack-2026-09-16.md"
line_has "reference line 16 assigns C9 (config and secrets) to R77" "$ref" 16 "R77 — config and secrets (C9)"
line_has "reference C9 Config row names figment 0.10.x over config-rs"  "$ref" 66 "| C9 | Config | shared | **figment** | 0.10.x | config-rs | config-rs less ergonomic layering |"
line_has "reference C9 prose: layered defaults -> TOML file -> env"     "$ref" 108 "**figment 0.10** for layered config (defaults → TOML file → env)."
line_has "reference C9 secrets: --set-secrets env-var injection is the default" "$ref" 108 "\`--set-secrets\` env-var injection from Secret Manager"
line_has "reference C13: AppState holds config; FromRef hands sub-state to extractors" "$ref" 120 "\`AppState\` holds \`PgPool\`, config, and shared clients; use \`FromRef\` to hand sub-state to extractors."
line_has "reference C13: dependency injection via traits behind concrete types" "$ref" 120 "Dependency injection via **traits behind concrete types**"
line_has "reference sample Cargo.toml puts figment in the manifest" "$ref" 174 "figment = { version = \"0.10\", features = [\"toml\",\"env\"] }"
line_has "reference sample layout has src/config.rs as figment layered config" "$ref" 237 "config.rs                # figment layered config"
line_has "reference sample main.rs loads once at startup" "$ref" 325 "let cfg = config::load()?;                 // figment: defaults → file → env"
file_has "reference C15 runbook: SIGTERM then a 10 second period then SIGKILL" "$ref" "indicating the start of a 10 second period before the ac"

echo
echo '## IN-REPO — accepted-but-unpublished decisions this answer is designed against'
r69="$root/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
line_has "R69 revision 10 owns web-extra-surface with the crates/web tree" "$r69" 1791 "- owns web-extra-surface = one additive, off-by-default Cargo feature named web, declared on the root package rs-launch-blueprint"
file_has "R69 revision 10 reserves the AppState slot this item fills" "$r69" "pub config:   Arc<WebConfig>,                 // the typed settings struct is R77's"
file_has "R69 revision 10 declares FromRef for that slot" "$r69" "impl FromRef<AppState> for Arc<WebConfig>"
file_has "R69 revision 10 hands R77 the Cloud Run drain datum" "$r69" "a drain deadline is honoured only if it is strictly shorter than 10 seconds"
file_has "R69 revision 10 carries BASELINE-REVIEW: F330 (drop py's lazy-load fallback)" "$r69" "BASELINE-REVIEW: F330 — validated configuration is available to every caller of the app object"
file_has "R69's owned value makes every service knob an environment variable named by R77" "$r69" "stays an environment variable named by R77"
file_has "R57 revision 2 fixes the single namespace segment this prefix derives from" \
  "$root/research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md" 'pub const TOOL_NAME: &str = "rslbp";'
file_has "R54 revision 3's recorded ground for rejecting a layering engine (quoted in alternative A1)" \
  "$root/research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md" \
  "It takes ownership of three things already decided elsewhere: the parse (R52's \`toml\` 1.1.6), the typed pass (R53's per-key loop over \`toml::Table\`, \`D06\`), and the per-layer sanitize step and warning list (R55, \`D01\`, \`D03\`)"
file_has "R56 revision 2 fixes the credential chain that keeps the token out of WebSettings" \
  "$root/research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md" \
  "\`RSLBP_TOKEN\` > stored credential"
file_has "R53 revision 2 chose serde with no validation crate — the house shape argument" \
  "$root/research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md" "no validation crate"
file_has "R67 requires hint to be able to name the offending input" \
  "$root/research/runs/R67/2026-09-05T155124Z-2271e140a7ef/review/DECISION.md" \
  "must be able to name the offending input per R7.6"

echo
echo '## IN-REPO — items researched in parallel, whose knobs this item only names'
file_has "R76 (cors) states that R77 owns the variable name and the parse" \
  "$root/research/runs/R76/2026-09-17T034010Z-d958540e8834/raw/opus.md" "owns the environment-variable name and the parse"
file_has "R76 wants a possibly-empty ordered collection of allowed origins" \
  "$root/research/runs/R76/2026-09-17T034010Z-d958540e8834/raw/opus.md" "a possibly-empty ordered collection of allowed origins reaches the"
file_has "R80 (probes) states that R77 owns the shutdown window's value" \
  "$root/research/runs/R80/2026-09-17T034011Z-74765d801b92/raw/opus.md" "R77 owns the window's value, and the mechanism is inert if that"
file_has "R80 requires the window to hold BOTH the readiness delay and the drain" \
  "$root/research/runs/R80/2026-09-17T034011Z-74765d801b92/raw/opus.md" "Whatever window R77 chooses must hold *both* the readiness-propagation"
file_has "R79 (metrics) needs no environment knob of its own" \
  "$root/research/runs/R79/2026-09-17T034011Z-2e1043da0e00/raw/opus.md" "this design needs **no** environment knob"

############################################################################
echo
echo '## PINNED-EXT — the org CLI Design Standard v1.4.14 at its blob'
STD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
STD_REPO="$HOME/c/cli-standards"
if [ -e "$STD_REPO/.git" ] && git -C "$STD_REPO" cat-file -e "$STD_BLOB" 2>/dev/null; then
  std=$(mktemp "${TMPDIR:-/tmp}/r77-std.XXXXXX")
  git -C "$STD_REPO" cat-file -p "$STD_BLOB" > "$std"
  line_has "standard R5.1 heading at line 287" "$std" 287 "**R5.1 — Precedence chain. (MUST)**"
  line_has "standard R5.2 heading at line 302" "$std" 302 "**R5.2 — Config file format & discovery. (MUST / SHOULD)**"
  line_has "standard R5.4 heading at line 321" "$std" 321 "**R5.4 — Environment variables. (MUST)**"
  line_has "standard R5.4 requires the uppercase TOOL_* prefix and a deterministic mapping" "$std" 322 \
    "Environment variables **MUST** use the uppercase \`TOOL_*\` prefix with a deterministic mapping"
  line_has "standard R5.4 forbids auto-exposing every flag as an env var" "$std" 322 \
    "the tool **MUST NOT** auto-expose every flag as an env var."
  line_has "standard R5.4 limits environment reading to a curated subset" "$std" 322 \
    "Only a **curated subset** of settings **SHOULD** read from the environment"
  line_has "standard R5.5 forbids secrets in argv" "$std" 326 "**R5.5 — Secrets. (MUST)**"
  line_has "standard R5.6 requires secret redaction in output" "$std" 331 "**R5.6 — Secret redaction in output. (MUST)**"
  line_has "standard required-global-core row for --config at line 246" "$std" 246 \
    "| Required global core | \`--config\` | — | Path to a config file, overriding discovery (R5.2). |"
  rm -f "$std"
else
  sk "org CLI Design Standard blob $STD_BLOB — $STD_REPO absent or blob unknown (9 checks)"
fi

echo
echo '## PINNED-EXT — the py and ts source pins'
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
PY_REPO="$HOME/c/py-launch-blueprint"
if [ -e "$PY_REPO/.git" ] && git -C "$PY_REPO" cat-file -e "$PY_PIN" 2>/dev/null; then
  t=$(mktemp -d "${TMPDIR:-/tmp}/r77-py.XXXXXX")
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/web/settings.py" > "$t/settings.py"
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/paths.py"   > "$t/paths.py"
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/web/deps.py"     > "$t/deps.py"
  line_has "py settings.py:38 derives the prefix from APP_NAME" "$t/settings.py" 38 \
    'ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"'
  line_has "py paths.py:58 is the single app-name source" "$t/paths.py" 58 'APP_NAME = "plbp"'
  file_has "py docstring states the fork-rename and fail-loudly-at-boot intent" "$t/settings.py" \
    "so a fork's"
  file_has "py docstring fixes JSON as py's list encoding" "$t/settings.py" \
    "List values parse from JSON"
  file_has "py default host is loopback" "$t/settings.py" 'host: str = "127.0.0.1"'
  file_has "py default port is 8000"     "$t/settings.py" "port: int = 8000"
  file_has "py drain default is 10 seconds — the value this item departs from" \
    "$t/settings.py" "graceful_shutdown_seconds: int = 10"
  file_has "py has the lazy-load fallback R69's BASELINE-REVIEW F330 drops" "$t/deps.py" \
    "Falls back to loading lazily when the lifespan hasn't run"
  fields=$({ /usr/bin/grep -cE '^    [a-z_]+: ' "$t/settings.py" || true; })
  count_is "py WebSettings declares 12 fields — the set this item renames" 12 "$fields"
  rm -rf "$t"
else
  sk "py-launch-blueprint pin $PY_PIN — repository or pin absent (9 checks)"
fi

TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
TS_REPO="$HOME/c/ts-launch-blueprint"
TMPTS=$(mktemp "${TMPDIR:-/tmp}/r77-ts.XXXXXX")
trap 'rm -f "$TMPTS"' EXIT
if [ -e "$TS_REPO/.git" ] && git -C "$TS_REPO" cat-file -e "$TS_PIN" 2>/dev/null; then
  n=$(git -C "$TS_REPO" ls-tree -r --name-only "$TS_PIN" > "$TMPTS"; { /usr/bin/grep -icE '(^|/)(web|server)/' "$TMPTS" || true; })
  count_is "ts pin has no web/ or server/ source tree (F303) — ts is not a harmonization target" 0 "$n"
else
  sk "ts-launch-blueprint pin $TS_PIN — repository or pin absent (1 check)"
fi

echo
echo '## PINNED-EXT — candidate sources at their exact published versions'
CACHE="$HOME/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f"
if [ -d "$CACHE" ]; then
  line_has "figment 0.10.19 Env::raw takes no source argument" \
    "$CACHE/figment-0.10.19/src/providers/env.rs" 171 "pub fn raw() -> Self {"
  line_has "figment 0.10.19 Env::prefixed takes only a prefix" \
    "$CACHE/figment-0.10.19/src/providers/env.rs" 198 "pub fn prefixed(prefix: &str) -> Self {"
  line_has "figment 0.10.19 reads the real process environment and offers no injection point" \
    "$CACHE/figment-0.10.19/src/providers/env.rs" 505 "std::env::vars_os()"
  line_has "figment 0.10.19 Jail mutates the process environment (the edition-2024 hazard)" \
    "$CACHE/figment-0.10.19/src/jail.rs" 353 "std::env::set_var(key, v.to_string());"
  line_has "envy 0.4.2 splits sequences on a comma" \
    "$CACHE/envy-0.4.2/src/lib.rs" 153 "let values = self.1.split(',')"
  line_has "envy 0.4.2 has a free from_iter injection seam" \
    "$CACHE/envy-0.4.2/src/lib.rs" 301 "pub fn from_iter<Iter, T>(iter: Iter) -> Result<T>"
  line_has "envy 0.4.2 has a prefixed from_iter injection seam" \
    "$CACHE/envy-0.4.2/src/lib.rs" 324 "pub fn from_iter<Iter, T>("
  line_has "confique 0.4.0 builder().env() takes no argument — no injection seam" \
    "$CACHE/confique-0.4.0/src/builder.rs" 38 "pub fn env(mut self) -> Self {"
  line_has "confique 0.4.0 generated code calls std::env::var directly" \
    "$CACHE/confique-0.4.0/src/internal.rs" 54 "match std::env::var(\$key) {"
  # unsafe posture, gate 3b — src/ trees only, never a manifest
  for c in config-0.15.25 confique-0.4.0 envy-0.4.2 figment-0.10.19 \
           envconfig-0.11.1 serde-env-0.3.0 envious-0.3.0; do
    if [ -d "$CACHE/$c/src" ]; then
      n=$({ /usr/bin/grep -rc 'unsafe' "$CACHE/$c/src" 2>/dev/null || true; } | awk -F: '{s+=$NF} END {print s+0}')
      count_is "gate 3b: $c has no unsafe in src/" 0 "$n"
    else
      sk "gate 3b: $c not in the local registry cache"
    fi
  done
  if [ -d "$CACHE/serde-1.0.229/src" ]; then
    n=$({ /usr/bin/grep -rc 'unsafe' "$CACHE/serde-1.0.229/src" 2>/dev/null || true; } | awk -F: '{s+=$NF} END {print s+0}')
    count_is "gate 3b: serde 1.0.229 has exactly 2 unsafe blocks (R53 revision 2's figure, re-audited here)" 2 "$n"
    u=$({ /usr/bin/grep -rho 'str::from_utf8_unchecked' "$CACHE/serde-1.0.229/src" || true; } | sort -u)
    count_is "gate 3b: both serde unsafe blocks are str::from_utf8_unchecked" "str::from_utf8_unchecked" "$u"
  else
    sk "gate 3b: serde 1.0.229 not in the local registry cache (2 checks)"
  fi
else
  sk "local Cargo registry cache absent — candidate source and unsafe checks (18 checks)"
fi

############################################################################
echo
echo '## PARAMETERS — every assumes line byte-identical to the live registry row'
if [ ! -f "$decision" ]; then
  sk "DECISION.md not present beside this script — parameter comparison"
else
  for p in msrv-policy rust-edition target-os-matrix license web-extra-surface error-taxonomy-exit-codes; do
    reg=$(python3 - "$root" "$p" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from pathlib import Path
from research_validation import _parse_parameters
v = _parse_parameters(Path(sys.argv[1]), [])
row = v.get(sys.argv[2])
print("- assumes %s = %s" % (sys.argv[2], row["value"] if row else "!!MISSING!!"))
PY
)
    dec=$(/usr/bin/grep -m1 "^- assumes $p = " "$decision" || true)
    if [ "$reg" = "$dec" ]; then
      ok "assumes $p is byte-identical to docs/port/PARAMETERS.md (${#reg} bytes)"
    else
      no "assumes $p differs from the registry row"
      printf '     registry: %s\n     decision: %s\n' "$reg" "$dec"
    fi
  done
  n=$(/usr/bin/grep -c '^- owns ' "$decision" || true)
  count_is "DECISION.md declares no owned parameter (the prompt's owns line is empty)" 0 "$n"
  n=$(/usr/bin/grep -c '^- assumes ' "$decision" || true)
  count_is "DECISION.md declares exactly 6 assumes lines" 6 "$n"
  file_has "DECISION.md records fitness gate 1 with the owner's exact ruling string" "$decision" \
    "inapplicable — owner ruling 2026-09-12 (Q7.B)"
  n=$(/usr/bin/grep -c '^re-verify: ' "$decision" || true)
  count_is "DECISION.md carries exactly one re-verify: line" 1 "$n"
  n=$(/usr/bin/grep -c '^## Supersedes' "$decision" || true)
  count_is "DECISION.md has no Supersedes section (this is revision 1)" 0 "$n"
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
