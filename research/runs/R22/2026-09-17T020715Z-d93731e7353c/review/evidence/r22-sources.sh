#!/usr/bin/env bash
# R22 runtime-version-accessor -- deterministic source assertions.
#
# Reads only files committed in this repository: the hash-verified snapshots in
# ./snapshots (each one fetched once, provenance in snapshots/MANIFEST.txt), the
# shared parameter registry, the two ledgers, the two published decisions this
# item is coupled to, and this run's raw report. Nothing here touches the
# network, so its log reproduces byte-for-byte; the volatile live re-checks live
# in r22-live-recheck.sh instead.
#
# Locates the repository root by walking up for docs/port/PARAMETERS.md rather
# than for .git, because in a worktree .git is a FILE and in a `git archive`
# extraction it is absent entirely.
set -euo pipefail

GREP=/usr/bin/grep
PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s -- %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s -- %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s -- %s\n' "$1" "$2"; }

assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1" "$4: got [$3]"
  else
    fail "$1" "$4: expected [$2] got [$3]"
  fi
}

# rel <absolute-path> -- print the path relative to the repository root, so no
# log line carries this machine's home directory and two runs from different
# extraction directories produce identical output.
rel() { printf '%s' "${1#"$ROOT"/}"; }

# assert_grep <id> <file> <basic-regex> <expected-count> <what>
assert_grep() {
  local n
  n="$($GREP -c -- "$3" "$2" || true)"
  if [ "$n" = "$4" ]; then
    pass "$1" "$5 (matches=$n)"
  else
    fail "$1" "$5: expected $4 matches of [$3] in $(rel "$2"), got $n"
  fi
}

# assert_line <id> <file> <line-number> <fixed-string> <what>
assert_line() {
  local got
  got="$(sed -n "${3}p" "$2")"
  case "$got" in
    *"$4"*) pass "$1" "$5 ($(rel "$2"):$3)" ;;
    *) fail "$1" "$5: $(rel "$2"):$3 is [$got], which does not contain [$4]" ;;
  esac
}

# assert_numbered <id> <numbered-excerpt> <original-line-number> <fixed-string> <what>
# The excerpt carries each kept line as "<original line number><tab><verbatim text>".
assert_numbered() {
  local got
  got="$($GREP "^$3	" "$2" || true)"
  case "$got" in
    *"$4"*) pass "$1" "$5 ($(rel "$2") -> original line $3)" ;;
    *) fail "$1" "$5: original line $3 of $(rel "$2") is [$got], which does not contain [$4]" ;;
  esac
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$SCRIPT_DIR/snapshots"

ROOT="$SCRIPT_DIR"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT="$(dirname "$ROOT")"
done

echo "=== R22 source assertions (deterministic) ==="
echo "run-started-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "uname: $(uname -sm)"
echo

# A0 -- the tree this script is reading.
if [ -f "$ROOT/docs/port/PARAMETERS.md" ]; then
  pass A0a "repository root located at a path holding docs/port/PARAMETERS.md"
else
  fail A0a "could not locate docs/port/PARAMETERS.md above $SCRIPT_DIR"
  echo "RESULT: FAIL"
  exit 1
fi
if [ -e "$ROOT/.git" ]; then
  if [ -d "$ROOT/.git" ]; then
    pass A0b "reading a checkout whose .git is a directory"
  else
    pass A0b "reading a worktree whose .git is a FILE (tested with -e, not -d)"
  fi
else
  pass A0b "reading an extraction with no .git at all (git archive); every path below is tracked content"
fi

# ---------------------------------------------------------------------------
# A1 -- snapshot integrity. Every later assertion rests on these bytes.
# ---------------------------------------------------------------------------
if (cd "$SNAP" && shasum -a 256 -c SHA256SUMS.txt > /dev/null 2>&1); then
  pass A1a "all $(wc -l < "$SNAP/SHA256SUMS.txt" | tr -d ' ') snapshots match snapshots/SHA256SUMS.txt"
else
  fail A1a "a snapshot does not match snapshots/SHA256SUMS.txt"
fi
assert_grep A1b "$SNAP/MANIFEST.txt" "^crates-built.json | 2026-09-18 | GET https" 1 \
  "MANIFEST.txt records each snapshot's retrieval date and endpoint"

# ---------------------------------------------------------------------------
# A2 -- the MSRV floor, and the DIRECTION of fitness gate 2.
# ---------------------------------------------------------------------------
STABLE="$($GREP -m1 '^version = ' "$SNAP/channel-rust-stable-excerpt.toml" | sed 's/^version = "//; s/ .*//')"
assert_eq A2a "1.98.1" "$STABLE" "current Rust stable, from the release channel manifest"
CHANNEL_DATE="$($GREP -m1 '^date = ' "$SNAP/channel-rust-stable-excerpt.toml" | sed 's/^date = "//; s/"$//')"
assert_eq A2b "2026-09-03" "$CHANNEL_DATE" "the stable channel's own date"
STABLE_MINOR="$(echo "$STABLE" | cut -d. -f2)"
FLOOR_MINOR=$((STABLE_MINOR - 2))
assert_eq A2c "96" "$FLOOR_MINOR" "the msrv-policy floor derived as stable minus 2 minor versions -> 1.$FLOOR_MINOR"

# A2d/A2e -- the gate reads one way only: a crate whose declared rust-version is
# AT OR BELOW the floor builds on the floor toolchain and passes. A crate whose
# declared rust-version is ABOVE the floor fails. The raw report inverted this.
BUILT_RV="$(python3 -c "
import json;print(json.load(open('$SNAP/crates-built-versions.json'))['versions'][0].get('rust_version'))")"
assert_eq A2d "1.87" "$BUILT_RV" "built's newest published version declares rust-version"
BUILT_RV_MINOR="$(echo "$BUILT_RV" | cut -d. -f2)"
if [ "$BUILT_RV_MINOR" -le "$FLOOR_MINOR" ]; then
  pass A2e "built's declared 1.$BUILT_RV_MINOR is at or below the 1.$FLOOR_MINOR floor, so gate 2 PASSES for it"
else
  fail A2e "built's declared 1.$BUILT_RV_MINOR is above the 1.$FLOOR_MINOR floor"
fi

VG_RV="$(python3 -c "
import json;print(json.load(open('$SNAP/crates-vergen-gix-versions.json'))['versions'][0].get('rust_version'))")"
assert_eq A2f "1.96.0" "$VG_RV" "vergen-gix's newest published version declares rust-version"
SR_RV="$(python3 -c "
import json;print(json.load(open('$SNAP/crates-shadow-rs-versions.json'))['versions'][0].get('rust_version'))")"
assert_eq A2g "None" "$SR_RV" "shadow-rs's newest published version declares NO rust-version"

# ---------------------------------------------------------------------------
# A3 -- the published figures each candidate's row cites.
# ---------------------------------------------------------------------------
python3 - "$SNAP" > "$SCRIPT_DIR/.a3.tmp" <<'PY'
import json, sys
snap = sys.argv[1]
for name in ("built", "shadow-rs", "vergen-gix"):
    c = json.load(open(f"{snap}/crates-{name}.json"))["crate"]
    v = json.load(open(f"{snap}/crates-{name}-versions.json"))["versions"]
    newest = next(x for x in v if not x["yanked"])
    print(f"{name}|{c['recent_downloads']}|{c['downloads']}|{newest['num']}|"
          f"{newest['created_at'][:10]}|{newest.get('license')}")
PY
while IFS='|' read -r n recent all num created lic; do
  printf 'FIGURE %s: recent_downloads=%s downloads=%s newest_non_yanked=%s created_at=%s license=%s\n' \
    "$n" "$recent" "$all" "$num" "$created" "$lic"
done < "$SCRIPT_DIR/.a3.tmp"
assert_grep A3a "$SCRIPT_DIR/.a3.tmp" "^built|.*|0.8.1|2026-05-21|MIT$" 1 \
  "built's newest non-yanked version is 0.8.1, created 2026-05-21, licensed MIT"
assert_grep A3b "$SCRIPT_DIR/.a3.tmp" "^shadow-rs|.*|2.0.0|2026-04-23|MIT AND Apache-2.0$" 1 \
  "shadow-rs 2.0.0 is licensed MIT AND Apache-2.0, not MIT as the raw report recorded"
assert_grep A3c "$SCRIPT_DIR/.a3.tmp" "^vergen-gix|.*|10.0.3|2026-08-24|MIT OR Apache-2.0$" 1 \
  "vergen-gix's newest non-yanked version is 10.0.3, created 2026-08-24"
rm -f "$SCRIPT_DIR/.a3.tmp"

# ---------------------------------------------------------------------------
# A4 -- advisories. rustsec.org publishes a /packages/<name>.html page only for
# a crate that has at least one advisory, so the 404s the raw report recorded
# are a NEGATIVE result, not an unverified one. git2 is the positive control.
# ---------------------------------------------------------------------------
assert_grep A4a "$SNAP/rustsec-git2.html" "RUSTSEC-2026-0183" 2 \
  "rustsec.org/packages/git2.html lists RUSTSEC-2026-0183"
assert_grep A4b "$SNAP/rustsec-git2.html" "RUSTSEC-2026-0184" 2 \
  "rustsec.org/packages/git2.html lists RUSTSEC-2026-0184"
ISSUE_STATE="$(python3 -c "
import json;print(json.load(open('$SNAP/gh-shadow-rs-issue-262.json'))['state'])")"
assert_eq A4c "open" "$ISSUE_STATE" "shadow-rs issue #262 is open"
assert_grep A4d "$SNAP/gh-shadow-rs-issue-262.json" "Upgrade git2 to >= 0.21 to fix RUSTSEC-2026-0183/0184" 1 \
  "issue #262's title names the git2 upgrade that clears both advisories"
assert_grep A4e "$SNAP/gh-shadow-rs-issue-262.json" "shadow-rs 2.0.0 depends on .git2 ^0.20.0" 1 \
  "issue #262 records that shadow-rs 2.0.0 pins git2 ^0.20.0, which is the advisoried range"

# ---------------------------------------------------------------------------
# A5 -- practice evidence, at pinned commits rather than at a moving branch.
# ---------------------------------------------------------------------------
ARROW_SHA="$(cat "$SNAP/arrow-rs-main.sha")"
RAV1E_SHA="$(cat "$SNAP/rav1e-master.sha")"
CLAP_SHA="$(cat "$SNAP/clap-main.sha")"
echo "PIN apache/arrow-rs main = $ARROW_SHA"
echo "PIN xiph/rav1e master    = $RAV1E_SHA"
echo "PIN clap-rs/clap main    = $CLAP_SHA"
assert_grep A5a "$SNAP/arrow-rs-main.sha" "^[0-9a-f]\{40\}$" 1 "the arrow-rs pin is a full 40-hex commit id"
assert_line A5b "$SNAP/arrow-lib.rs.txt" 412 \
  'pub const ARROW_VERSION: &str = env!("CARGO_PKG_VERSION");' \
  "Apache Arrow exports its public version constant straight from env!"
assert_grep A5c "$SNAP/arrow-lib.rs.txt" 'CARGO_PKG_VERSION' 1 \
  "arrow/src/lib.rs mentions CARGO_PKG_VERSION exactly once, at that constant"

assert_line A5d "$SNAP/rav1e-lib.rs.txt" 216 \
  'env!("CARGO_PKG_VERSION").to_string()' \
  "rav1e's version::short() is the base version, straight from env!"
assert_grep A5e "$SNAP/rav1e-lib.rs.txt" 'CARGO_PKG_VERSION_MAJOR' 1 \
  "rav1e also reads Cargo's split version components"
assert_line A5f "$SNAP/rav1e-lib.rs.txt" 54 \
  'include!(concat!(env!("OUT_DIR"), "/built.rs"));' \
  "rav1e's git/build provenance comes from a SEPARATE generated module"
assert_grep A5g "$SNAP/rav1e-lib.rs.txt" 'cfg(feature="git_version")' 1 \
  "and that provenance is behind its own Cargo feature, layered beside the base version"

# A5h/A5i -- the raw report's line citations for these two files are wrong. The
# claims are right; the line numbers name lines that say something else.
assert_grep A5h "$SNAP/arrow-lib.rs.txt" 'CARGO_PKG_VERSION' 1 \
  "arrow: the raw report cited L1822-1824; the single occurrence is at :412 (see A5b)"
ARROW_LINES="$(wc -l < "$SNAP/arrow-lib.rs.txt" | tr -d ' ')"
if [ "$ARROW_LINES" -lt 1822 ]; then
  pass A5i "arrow/src/lib.rs has only $ARROW_LINES lines, so the cited L1822-1824 does not exist"
else
  fail A5i "arrow/src/lib.rs has $ARROW_LINES lines; re-check the L1822-1824 citation"
fi
RAV1E_937="$(sed -n '937,943p' "$SNAP/rav1e-lib.rs.txt" | $GREP -c 'CARGO_PKG_VERSION' || true)"
assert_eq A5j "0" "$RAV1E_937" "rav1e L937-943, one of the two ranges the raw report cited, holds no CARGO_PKG_VERSION"
RAV1E_1223="$(sed -n '1223,1233p' "$SNAP/rav1e-lib.rs.txt" | $GREP -c 'CARGO_PKG_VERSION' || true)"
assert_eq A5k "0" "$RAV1E_1223" "rav1e L1223-1233, the other cited range, holds none either"

# A5l -- the OpenTelemetry citation is weaker than the raw report presented it.
assert_grep A5l "$SNAP/otel-sdk-lib.rs.txt" 'CARGO_PKG_VERSION' 0 \
  "opentelemetry-sdk/src/lib.rs exports no version constant"
assert_line A5m "$SNAP/otel-zipkin-lib.rs.txt" 203 \
  'with_version(env!("CARGO_PKG_VERSION"))' \
  "the OpenTelemetry occurrence is inside a doc-comment example, not a shipped constant"

# ---------------------------------------------------------------------------
# A6 -- both clap version paths reduce to CARGO_PKG_VERSION, so clap is a
# spelling of the recommendation rather than an alternative to it.
# ---------------------------------------------------------------------------
assert_line A6a "$SNAP/clap-builder-macros.rs.txt" 16 'macro_rules! crate_version' \
  "clap::crate_version! is declared here"
assert_line A6b "$SNAP/clap-builder-macros.rs.txt" 18 'env!("CARGO_PKG_VERSION")' \
  "and its entire body is env!(\"CARGO_PKG_VERSION\")"
assert_line A6c "$SNAP/clap-builder-macros.rs.txt" 14 '#[cfg(feature = "cargo")]' \
  "crate_version! is gated on clap's cargo feature, which R60's selected feature set does not enable"
assert_numbered A6d "$SNAP/clap-derive-item-excerpt.txt" 554 \
  'Method::from_env(attr.name.clone(), "CARGO_PKG_VERSION")' \
  "#[command(version)] in clap_derive resolves CARGO_PKG_VERSION at macro-expansion time"
assert_numbered A6e "$SNAP/clap-derive-item-excerpt.txt" 1272 'match env::var(env_var)' \
  "from_env reads that variable in the proc-macro process and bakes in a literal"
NO_EMAIL="$($GREP -c -E '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z][A-Za-z]' "$SNAP/clap-derive-item-excerpt.txt" || true)"
assert_eq A6e2 "0" "$NO_EMAIL" \
  "the clap_derive excerpt carries no email address; the file's copyright header is deliberately not committed"

# ---------------------------------------------------------------------------
# A6b2 -- what the Cargo Book actually says, checked because the raw report
# attributed a sentence to it that it does not contain.
# ---------------------------------------------------------------------------
CARGO_DOC="$SNAP/cargo-book-excerpts.txt"
assert_grep A6f "$CARGO_DOC" 'Cargo exposes these environment variables to your crate when it is compiled' 1 \
  "environment-variables.html: Cargo injects these variables AT COMPILE TIME"
assert_grep A6g "$CARGO_DOC" 'let version = env!("CARGO_PKG_VERSION");' 1 \
  "and shows env!(\"CARGO_PKG_VERSION\") as the documented way to read the package version"
assert_grep A6h "$CARGO_DOC" 'The value can be then retrieved by the env! macro in the compiled crate' 1 \
  "build-scripts.html: a build script's cargo::rustc-env output is ALSO read with env!, so a generated module is compile-time too, not a runtime lookup"
assert_grep A6i "$CARGO_DOC" 'Depending on this behavior is discouraged' 1 \
  "the word 'discouraged' appears on build-scripts.html once, about dynamic-library search paths"
# The snapshot's own '#' lines are this repository's annotations, not Cargo's
# words, so they are excluded before the quoted text is searched.
DISCOURAGE_RUNTIME="$($GREP -v '^#' "$CARGO_DOC" | $GREP -c 'runtime' || true)"
assert_eq A6j "0" "$DISCOURAGE_RUNTIME" \
  "no quoted Cargo Book line contains the word 'runtime', so the raw report's 'runtime checking ... is discouraged' sentence is not the Cargo Book's"
CARGO_QUOTED_LINES="$($GREP -c -v '^#' "$CARGO_DOC" || true)"
if [ "$CARGO_QUOTED_LINES" -ge 3 ]; then
  pass A6k "the excerpt file carries $CARGO_QUOTED_LINES quoted lines, so A6j is searching real text"
else
  fail A6k "only $CARGO_QUOTED_LINES quoted lines in the excerpt file; A6j would be vacuous"
fi

# ---------------------------------------------------------------------------
# A7 -- the org CLI Design Standard rules this decision's acceptance criteria
# are written against (v1.4.14, blob f9de0437baece3383e73ca2c5f48b7ab399b51c7).
# ---------------------------------------------------------------------------
assert_grep A7a "$SNAP/cli-design-standard-v1.4.14-excerpt.md" \
  "Required global core | \`--version\` | \`-V\`" 1 \
  "R4.1 (MUST) puts --version/-V in the required global core"
assert_grep A7b "$SNAP/cli-design-standard-v1.4.14-excerpt.md" \
  "\`version\` \*\*MUST\*\* be SemVer without a leading \`v\`" 1 \
  "R4.6 requires the version value to be SemVer with no leading v"

# ---------------------------------------------------------------------------
# A8 -- the ledger rows this decision settles and confirms.
# ---------------------------------------------------------------------------
LEDGER="$ROOT/docs/port/COMMONALITY.md"
BASELINE="$ROOT/docs/port/BASELINE-REVIEW.md"
assert_grep A8a "$LEDGER" "^| F064 | runtime version accessor | release-versioning | different | DIVERGENT | R22 |" 1 \
  "F064 is the DIVERGENT row R22 owns"
assert_grep A8b "$LEDGER" "^| F063 | version source of truth | release-versioning | same | COMMON . REUSE | . |" 1 \
  "F063 (the manifest field itself) is COMMON -> REUSE and belongs to no item"
assert_grep A8c "$LEDGER" "^| F133 | test asserting the version stays single-sourced across manifests |" 1 \
  "F133 is the version-consistency-test row"
assert_grep A8d "$LEDGER" "the accessor-equality assertion stays" 1 \
  "F133's note already records that the accessor assertion is retained and that its mechanism follows R22"
assert_grep A8e "$BASELINE" "F133 finding unsupported (accessor test cannot fail) | Accepted" 1 \
  "the 2026-09-04 baseline review already rejected the 'cannot fail' challenge to F133"
assert_grep A8f "$LEDGER" "^| F267 | Extended version output (runtime/platform info) | cli-framework-ux | py-only | DIVERGENT | R60 |" 1 \
  "F267, the extended CLI version surface, is R60's and is out of this item's scope"

# ---------------------------------------------------------------------------
# A9 -- the five parameter lines, byte-compared against the live registry.
# The expected block below is what this decision's ## Parameters section writes.
# ---------------------------------------------------------------------------
python3 - "$ROOT/docs/port/PARAMETERS.md" > "$SCRIPT_DIR/.a9.tmp" <<'PY'
import sys
rows = {}
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("| ") and line.count("|") >= 6:
        parts = [p.strip() for p in line.strip().strip("|").split("|")]
        if len(parts) >= 5:
            rows[parts[0]] = parts[3]
for key in ("msrv-policy", "rust-edition", "target-os-matrix", "license",
            "build-tool-output-shape"):
    print(f"- assumes {key} = {rows[key]}")
PY
A9_COUNT="$(wc -l < "$SCRIPT_DIR/.a9.tmp" | tr -d ' ')"
assert_eq A9a "5" "$A9_COUNT" "five parameter lines were rendered from the registry rows"
assert_grep A9b "$SCRIPT_DIR/.a9.tmp" "^- assumes rust-edition = 2024$" 1 \
  "rust-edition's line is bare, with no backticks and no commentary"
assert_grep A9c "$SCRIPT_DIR/.a9.tmp" "^- assumes license = MIT OR Apache-2.0$" 1 \
  "license's line is bare"
assert_grep A9d "$SCRIPT_DIR/.a9.tmp" "^- assumes target-os-matrix = ubuntu-latest, macos-latest$" 1 \
  "target-os-matrix's line is bare"
assert_grep A9e "$SCRIPT_DIR/.a9.tmp" "^- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI$" 1 \
  "msrv-policy's line is bare"
assert_grep A9f "$SCRIPT_DIR/.a9.tmp" "^- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface\." 1 \
  "build-tool-output-shape's line carries R49's published value verbatim from its first byte"
BTOS_BYTES="$($GREP '^- assumes build-tool-output-shape = ' "$SCRIPT_DIR/.a9.tmp" | wc -c | tr -d ' ')"
echo "RENDERED build-tool-output-shape line length: $BTOS_BYTES bytes"
echo "--- the five lines this decision must carry verbatim ---"
cat "$SCRIPT_DIR/.a9.tmp"
echo "--- end ---"

# A9g -- R22 owns no parameter, so there is no `- owns` line.
PROMPT="$SCRIPT_DIR/../../inputs/prompt.md"
assert_grep A9g "$PROMPT" "^- owns:$" 1 "the prompt's Couplings block names no owned parameter"
assert_grep A9h "$PROMPT" "^- consumes: R49: build-tool-output-shape$" 1 \
  "and names exactly one consumed parameter, R49's build-tool-output-shape"
assert_grep A9i "$PROMPT" "^- effort: light$" 1 "the prompt records the light effort tier"
assert_grep A9j "$PROMPT" "^- engines: codex$" 1 "and codex as the only research engine"

# A9k -- web-extra-surface is NOT consumed by R22; the raw report added it.
WEB_IN_PROMPT="$($GREP -c 'consumes: .*web-extra-surface' "$PROMPT" || true)"
assert_eq A9k "0" "$WEB_IN_PROMPT" \
  "the prompt does not consume web-extra-surface, so the raw report's assumes line for it is dropped"
rm -f "$SCRIPT_DIR/.a9.tmp"

# ---------------------------------------------------------------------------
# A10 -- the two published decisions this item is coupled to.
# ---------------------------------------------------------------------------
R49="$ROOT/research/topics/49-build-target-declaration/DECISION.md"
R60="$ROOT/research/topics/60-cli-parsing-framework/DECISION.md"
assert_grep A10a "$R49" "^- owns build-tool-output-shape = no build backend or bundler crate;" 1 \
  "R49's published decision owns build-tool-output-shape"
assert_grep A10b "$R49" "no build.rs and no build-orchestration crate" 1 \
  "R49's value already forbids a build script for the package's own targets"
assert_grep A10d "$R60" "lookup supplies the value is \*\*R22's\*\* decision, not this item's; both satisfy" 1 \
  "R60 states that the version VALUE is R22's decision and that either outcome satisfies R4.6"
assert_grep A10e "$R60" "the template serializes .*from \`CARGO_PKG_VERSION\` and the two \`build.rs\` values" 1 \
  "R60's JSON version object already sources its version field from CARGO_PKG_VERSION"
assert_grep A10f "$R60" "R22 (\`runtime-version-accessor\`) resolving and changing where the version value comes from" 1 \
  "R60 carries a re-verify trigger that fires only if R22 CHANGES that source"

# ---------------------------------------------------------------------------
# A11 -- this run's only raw report is the one the manifest registered.
# ---------------------------------------------------------------------------
RAWDIR="$SCRIPT_DIR/../../raw"
RAW_SHA="$(shasum -a 256 "$RAWDIR/codex.md" | cut -d' ' -f1)"
assert_eq A11a "6ebf723a4e5b801e2c787bc388779e68a2c714c9377c4f9407a7e211bae32915" "$RAW_SHA" \
  "raw/codex.md hashes to the sha256 the run manifest registered"
if [ -f "$RAWDIR/codex-$RAW_SHA.md" ]; then
  pass A11b "the registered copy raw/codex-<sha256>.md is present"
else
  fail A11b "raw/codex-$RAW_SHA.md is missing"
fi
assert_grep A11c "$SCRIPT_DIR/../../manifest.json" '"actual_model": "gpt-5.6-luna"' 3 \
  "the manifest records gpt-5.6-luna as the model that produced it"
RAW_ENGINES="$(find "$RAWDIR" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
assert_eq A11d "2" "$RAW_ENGINES" \
  "exactly two .md files in raw/ -- codex.md and its registered sha-named copy; no second engine ran"

# A11e -- the inverted gate-2 sentence is really in the raw report, so the
# correction recorded under ## Engines is attributable rather than asserted.
assert_grep A11e "$RAWDIR/codex.md" 'below the current policy floor of Rust 1.96' 1 \
  "the raw report's gate-2 exclusion of built rests on the inverted comparison"
assert_grep A11f "$RAWDIR/codex.md" 'assumes web-extra-surface' 1 \
  "the raw report emitted an assumes line for a parameter this item does not consume"
assert_grep A11g "$RAWDIR/codex.md" 'Its license is MIT, default features are empty' 1 \
  "the raw report recorded built's licence; licence is not evaluated under the 2026-09-12 ruling"

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
if [ "$SKIP" -ne 0 ]; then
  echo "NOTE: skips above are named on their SKIP lines."
fi
if [ "$FAIL" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
