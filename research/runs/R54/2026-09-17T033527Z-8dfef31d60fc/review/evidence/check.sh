#!/usr/bin/env bash
# R54 — config-discovery-tiers — evidence checks for review/DECISION.md (revision 1).
#
# Every check asserts on CONTENT, never on an exit code alone, and prints one
# stable `PASS`/`FAIL`/`SKIP` line per check id. Volatile bodies (registry and API
# JSON, fetched manifests and documents) are snapshotted under
# review/evidence/snapshots/ and cited from the decision with their retrieval date;
# the log itself carries only assertions, so it is comparable across runs.
#
# Reruns from a clean `git archive HEAD` extraction: checks that need a git
# repository this tarball does not carry (the org CLI Design Standard clone, the
# pinned py source repository) print `SKIP <id>` by name instead of failing.
#
# Network is required for the S*/E*/X*/C*/F*/G*/R*/U*/Z* groups.
# `gh` must be authenticated; no token is printed or inspected.
#
# Nothing is written into the repository except this directory's own log files.
# The Rust probe is compiled and run inside a $TMPDIR directory the script creates
# and deletes.

# shellcheck disable=SC2016  # the needles are literal quotations; `$` and backticks inside them must NOT expand.
# shellcheck disable=SC2329  # cleanup() is invoked indirectly, by the EXIT trap below.

set -u
set -o pipefail

GREP=/usr/bin/grep
FAILURES=0
SKIPPED=0

EVIDENCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$EVIDENCE_DIR/snapshots"
REPO_ROOT="$(cd "$EVIDENCE_DIR/../../../../../.." && pwd)"
RUN_DIR="$(cd "$EVIDENCE_DIR/../.." && pwd)"
STANDARD_REPO=/Users/stevemorin/c/cli-standards
STANDARD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
PY_REPO=/Users/stevemorin/c/py-launch-blueprint
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5

mkdir -p "$SNAP"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r54-check-XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass() { echo "PASS $1 $2"; }
fail() { echo "FAIL $1 $2"; FAILURES=$((FAILURES + 1)); }
skip() { echo "SKIP $1 $2"; SKIPPED=$((SKIPPED + 1)); }

# assert_contains <id> <file> <needle> <label>
assert_contains() {
  local id="$1" file="$2" needle="$3" label="$4" n
  if [ ! -s "$file" ]; then
    fail "$id" "$label (missing or empty input)"
    return
  fi
  n="$("$GREP" -c -F -- "$needle" "$file")"
  if [ "$n" -ge 1 ]; then
    pass "$id" "$label (/usr/bin/grep -c -F matches=$n)"
  else
    fail "$id" "$label (/usr/bin/grep -c -F matches=0)"
  fi
}

# assert_absent <id> <dir-or-file> <pattern> <label>  (recursive, count must be 0)
assert_absent() {
  local id="$1" target="$2" pat="$3" label="$4" n
  n="$("$GREP" -rc -E -- "$pat" "$target" 2>/dev/null | awk -F: '{s+=$NF} END {print s+0}')"
  if [ "$n" -eq 0 ]; then
    pass "$id" "$label (/usr/bin/grep -rc -E total=0)"
  else
    fail "$id" "$label (/usr/bin/grep -rc -E total=$n)"
  fi
}

fetch() { # fetch <url> <outfile>
  curl -sS -L --fail --max-time 60 -A "rs-launch-blueprint-research/R54" -o "$2" "$1"
}

echo "=== R54 evidence checks ==="
echo "repo-root  $REPO_ROOT"
echo "run-dir    ${RUN_DIR#"$REPO_ROOT"/}"
echo "toolchain  $(rustc --version) | $(cargo --version) | $(uname -sr)"
echo "grep       $GREP ($($GREP --version | head -1))"
echo

# ---------------------------------------------------------------------------
# S — the org CLI Design Standard v1.4.14 at blob f9de0437…, quoted verbatim.
# ---------------------------------------------------------------------------
STD="$WORK/cli-design-standard.md"
if [ -d "$STANDARD_REPO/.git" ] && git -C "$STANDARD_REPO" cat-file -e "$STANDARD_BLOB" 2>/dev/null; then
  git -C "$STANDARD_REPO" cat-file blob "$STANDARD_BLOB" > "$STD"
  cp "$STD" "$SNAP/cli-design-standard-f9de0437.md"
  assert_contains S01 "$STD" '**R5.1 — Precedence chain. (MUST)**' 'R5.1 exists and is a MUST'
  assert_contains S02 "$STD" '3. Project/local config file: nearest `.<tool>/<tool>_config.toml`, discovered by walking up from the working directory' 'R5.1 rung 3 is a dot-DIRECTORY walked up'
  assert_contains S03 "$STD" '5. System config file: each `$XDG_CONFIG_DIRS/<tool>/<tool>_config.toml`' 'R5.1 rung 5 enumerates XDG_CONFIG_DIRS'
  assert_contains S04 "$STD" 'maps/tables **MUST** merge recursively by default. Scalar values replace scalar values, arrays **replace** arrays (not concatenate), and the nearer scope wins' 'R5.1 merge semantics'
  assert_contains S05 "$STD" 'An explicit `--config <path>` **MUST** **replace** the discovered project/user/system config files' 'R5.2 --config replaces discovery'
  assert_contains S06 "$STD" 'Project discovery **SHOULD** stop at a repository/workspace boundary when detectable' 'R5.2 boundary stop'
  assert_contains S07 "$STD" 'System-wide config search uses `$XDG_CONFIG_DIRS` (default `/etc/xdg`)' 'R5.3 system search path and default'
  assert_contains S08 "$STD" 'the tool **MUST NOT** auto-expose every flag as an env var' 'R5.4 curated env subset'
  assert_contains S09 "$STD" '`ACME_CONFIG`' 'R5.4 names the config path in the curated subset'
else
  for id in S01 S02 S03 S04 S05 S06 S07 S08 S09; do
    skip "$id" "org CLI Design Standard repo or blob $STANDARD_BLOB not present at $STANDARD_REPO"
  done
fi

# ---------------------------------------------------------------------------
# E / X / C — published crate sources read at exact versions.
# ---------------------------------------------------------------------------
SRC="$WORK/src"
mkdir -p "$SRC"
get_crate() { # get_crate <name> <version>
  local name="$1" ver="$2"
  fetch "https://static.crates.io/crates/${name}/${name}-${ver}.crate" "$WORK/${name}-${ver}.crate" \
    && tar -xzf "$WORK/${name}-${ver}.crate" -C "$SRC"
}

if get_crate etcetera 0.11.0; then
  ET="$SRC/etcetera-0.11.0"
  assert_absent E01 "$ET/src" 'CONFIG_DIRS|DATA_DIRS' 'etcetera 0.11.0 source has no XDG_CONFIG_DIRS support at all'
  assert_contains E02 "$ET/src/base_strategy/xdg.rs" 'if path.is_absolute() { Some(path) } else { None }' 'etcetera honours the XDG absoluteness rule (F247)'
  assert_contains E03 "$ET/src/base_strategy.rs" 'create_strategies!(Apple, Xdg);' 'choose_base_strategy() is XDG on macOS (F247 on macos-latest)'
  assert_contains E04 "$ET/Cargo.toml" 'rust-version = "1.87.0"' 'etcetera 0.11.0 declared MSRV'
  assert_contains E05 "$ET/src/base_strategy.rs" 'fn config_dir(&self) -> PathBuf;' 'BaseStrategy exposes a singular config_dir only'
else
  for id in E01 E02 E03 E04 E05; do skip "$id" "could not download etcetera-0.11.0.crate"; done
fi

if get_crate xdg 3.0.0; then
  XD="$SRC/xdg-3.0.0"
  assert_contains X01 "$XD/src/lib.rs" '#![cfg(any(unix, target_os = "redox"))]' 'xdg 3.0.0 compiles to an empty crate off Unix'
  assert_contains X02 "$XD/src/base_directories.rs" 'pub fn get_config_dirs(&self)' 'xdg 3.0.0 is the one surveyed crate that enumerates the system tier'
  assert_contains X03 "$XD/src/base_directories.rs" 'unwrap_or(vec![PathBuf::from("/etc/xdg")])' 'xdg 3.0.0 applies the /etc/xdg default'
  assert_contains X04 "$XD/src/base_directories.rs" 'env::split_paths(&paths)' 'xdg 3.0.0 splits XDG_CONFIG_DIRS with std::env::split_paths'
else
  for id in X01 X02 X03 X04; do skip "$id" "could not download xdg-3.0.0.crate"; done
fi

if get_crate clap_builder 4.6.6; then
  CB="$SRC/clap_builder-4.6.6"
  assert_contains C01 "$CB/src/parser/parser.rs" '// Use env only if the arg was absent among command line args,' 'clap applies env only when the flag is absent (flag beats env)'
  assert_contains C02 "$CB/src/parser/parser.rs" 'if let Some((_, Some(ref val))) = arg.env {' 'clap tests env PRESENCE only — an empty value is not filtered'
  assert_contains C03 "$CB/src/builder/arg.rs" 'let value = env::var_os(&name);' 'Arg::env snapshots the variable with no emptiness check'
else
  for id in C01 C02 C03; do skip "$id" "could not download clap_builder-4.6.6.crate"; done
fi

# A — the layering crate the three Doxa providers add, read at the version they name.
if get_crate config 0.15.25; then
  assert_contains A01 "$SRC/config-0.15.25/src/env.rs" 'Optional prefix that will limit access to the environment to only keys that' 'config::Environment binds every variable carrying the prefix, not a curated subset (R5.4)'
  assert_contains A02 "$SRC/config-0.15.25/src/env.rs" 'pub fn with_prefix(s: &str) -> Self {' 'with_prefix is the constructor both providers name'
else
  for id in A01 A02; do skip "$id" "could not download config-0.15.25.crate"; done
fi

# ---------------------------------------------------------------------------
# F — crates.io figures. Bodies are snapshotted; assertions are on stable fields.
# ---------------------------------------------------------------------------
if fetch "https://crates.io/api/v1/crates/etcetera" "$SNAP/crates-etcetera.json"; then
  MAXV="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["crate"]["max_stable_version"])' "$SNAP/crates-etcetera.json" 2>/dev/null)"
  if [ "$MAXV" = "0.11.0" ]; then
    pass F01 "crates.io etcetera max_stable_version=0.11.0 — no 0.12 is published"
  else
    fail F01 "crates.io etcetera max_stable_version=$MAXV (expected 0.11.0)"
  fi
else
  skip F01 "crates.io/api/v1/crates/etcetera unreachable"
fi

if fetch "https://crates.io/api/v1/crates/etcetera/versions" "$SNAP/crates-etcetera-versions.json"; then
  if python3 - "$SNAP/crates-etcetera-versions.json" <<'PY'
import json, sys
vs = json.load(open(sys.argv[1]))["versions"]
ok = any(v["num"] == "0.11.0" and not v["yanked"] for v in vs)
twelve = [v["num"] for v in vs if v["num"].startswith("0.12")]
sys.exit(0 if (ok and not twelve) else 1)
PY
  then
    pass F02 "etcetera 0.11.0 is published and unyanked; no 0.12.x version exists"
  else
    fail F02 "etcetera 0.11.0 unyanked / no-0.12 assertion did not hold"
  fi
else
  skip F02 "crates.io etcetera versions endpoint unreachable"
fi

http_code() { curl -sS -L -o "$2" -w '%{http_code}' --max-time 60 -A "rs-launch-blueprint-research/R54" "$1"; }

# The two crates the Doxa/Perplexity provider recommends in place of `etcetera`.
# Both exist; the question the assertion settles is adoption, not existence, so it
# compares their all-time download counts against `etcetera`'s on the same endpoint.
adoption_lt() { # adoption_lt <id> <crate> <ceiling> <label>
  local id="$1" name="$2" ceiling="$3" label="$4" n
  if ! fetch "https://crates.io/api/v1/crates/$name" "$SNAP/crates-$name.json"; then
    skip "$id" "crates.io/api/v1/crates/$name unreachable"
    return
  fi
  n="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["crate"]["downloads"])' "$SNAP/crates-$name.json" 2>/dev/null)"
  case "$n" in
    '' | *[!0-9]*)
      fail "$id" "$label (crate.downloads not readable)"
      return
      ;;
  esac
  if [ "$n" -lt "$ceiling" ]; then
    pass "$id" "$label (crate.downloads=$n, under $ceiling)"
  else
    fail "$id" "$label (crate.downloads=$n, expected under $ceiling)"
  fi
}
adoption_lt F03 cfgmatic-paths 100000 'cfgmatic-paths exists but carries no adoption evidence'
adoption_lt F04 cfg-rs 1000000 'cfg-rs exists but carries no adoption evidence'
if fetch "https://crates.io/api/v1/crates/etcetera" "$SNAP/crates-etcetera.json"; then
  ETDL="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["crate"]["downloads"])' "$SNAP/crates-etcetera.json" 2>/dev/null)"
  if [ "${ETDL:-0}" -gt 100000000 ]; then
    pass F06 "etcetera crate.downloads=$ETDL, three orders of magnitude above either (same endpoint, same run)"
  else
    fail F06 "etcetera crate.downloads=${ETDL:-unreadable} (expected above 100,000,000)"
  fi
else
  skip F06 "crates.io etcetera endpoint unreachable"
fi

if fetch "https://crates.io/api/v1/crates/xdg" "$SNAP/crates-xdg.json"; then
  assert_contains F05 "$SNAP/crates-xdg.json" '"max_stable_version":"3.0.0"' 'crates.io xdg max_stable_version is 3.0.0'
else
  skip F05 "crates.io xdg endpoint unreachable"
fi

# ---------------------------------------------------------------------------
# G — GitHub repository state (authenticated gh; no token printed).
# ---------------------------------------------------------------------------
if command -v gh > /dev/null 2>&1; then
  if gh api repos/lunacookies/etcetera > "$SNAP/gh-lunacookies-etcetera.json" 2>/dev/null; then
    assert_contains G01 "$SNAP/gh-lunacookies-etcetera.json" '"archived":false' 'lunacookies/etcetera is not archived'
  else
    skip G01 "gh api repos/lunacookies/etcetera failed"
  fi
  if gh api repos/soc/directories-rs > "$SNAP/gh-soc-directories-rs.json" 2>/dev/null; then
    assert_contains G02 "$SNAP/gh-soc-directories-rs.json" '"archived":true' 'soc/directories-rs IS archived'
  else
    skip G02 "gh api repos/soc/directories-rs failed"
  fi
else
  skip G01 "gh not on PATH"
  skip G02 "gh not on PATH"
fi

CODE="$(http_code "https://rustsec.org/packages/etcetera.html" "$WORK/rustsec-etcetera.html")"
if [ "$CODE" = "404" ]; then
  pass R01 "rustsec.org publishes no advisory page for etcetera (HTTP 404)"
else
  fail R01 "rustsec.org/packages/etcetera.html returned HTTP $CODE (expected 404)"
fi
CODE="$(http_code "https://rustsec.org/packages/anyhow.html" "$WORK/rustsec-anyhow.html")"
if [ "$CODE" = "404" ]; then
  pass R02 "control: rustsec.org also 404s for anyhow, so R01's 404 is the no-advisory result and not a site outage"
else
  pass R02 "control: rustsec.org/packages/anyhow.html returned HTTP $CODE, so the site serves pages and R01's 404 means no advisory"
fi

# ---------------------------------------------------------------------------
# Z — the XDG Base Directory Specification, read from the DocBook source.
# ---------------------------------------------------------------------------
if fetch "https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml" "$SNAP/xdg-basedir-spec.xml"; then
  assert_contains Z01 "$SNAP/xdg-basedir-spec.xml" 'All paths set in these environment variables must be' 'XDG spec requires absolute paths in the XDG_* variables'
  assert_contains Z02 "$SNAP/xdg-basedir-spec.xml" '/etc/xdg should be used.' 'XDG spec names /etc/xdg as the XDG_CONFIG_DIRS default'
  assert_contains Z03 "$SNAP/xdg-basedir-spec.xml" 'directory listed is the most important.' 'XDG spec fixes the intra-system-tier order'
  assert_contains Z04 "$SNAP/xdg-basedir-spec.xml" 'by <literal>$XDG_CONFIG_HOME</literal> is considered more important than' 'XDG spec puts the user tier above every system directory'
else
  for id in Z01 Z02 Z03 Z04; do skip "$id" "XDG spec source unreachable"; done
fi

# ---------------------------------------------------------------------------
# U — adopters shipping this exact composition (etcetera + a hand-rolled system tier).
# ---------------------------------------------------------------------------
if fetch "https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml" "$SNAP/uv-Cargo.toml"; then
  assert_contains U01 "$SNAP/uv-Cargo.toml" 'etcetera = { version = "0.11.0"' 'uv depends on etcetera 0.11.0'
else
  skip U01 "uv Cargo.toml unreachable"
fi
if fetch "https://raw.githubusercontent.com/astral-sh/uv/main/docs/concepts/configuration-files.md" "$SNAP/uv-configuration-files.md"; then
  assert_contains U02 "$SNAP/uv-configuration-files.md" 'XDG_CONFIG_DIRS' 'uv documents an $XDG_CONFIG_DIRS system tier that etcetera cannot supply'
  assert_contains U03 "$SNAP/uv-configuration-files.md" 'in the nearest parent directory' 'uv documents an upward project search'
else
  skip U02 "uv configuration-files.md unreachable"
  skip U03 "uv configuration-files.md unreachable"
fi
if fetch "https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml" "$SNAP/ruff-Cargo.toml"; then
  assert_contains U04 "$SNAP/ruff-Cargo.toml" 'etcetera = { version = "0.11.0" }' 'ruff depends on etcetera 0.11.0'
else
  skip U04 "ruff Cargo.toml unreachable"
fi

# ---------------------------------------------------------------------------
# D — the sibling decisions this synthesis must not contradict.
# ---------------------------------------------------------------------------
R53_DEC="$REPO_ROOT/research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md"
R55_DEC="$REPO_ROOT/research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md"
R57_DEC="$REPO_ROOT/research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md"
R67_DEC="$REPO_ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"

sha_of() { shasum -a 256 "$1" | awk '{print $1}'; }

for pair in "D00a:$R53_DEC" "D00b:$R55_DEC" "D00c:$R57_DEC" "D00d:$R67_DEC"; do
  id="${pair%%:*}"; f="${pair#*:}"
  if [ -f "$f" ]; then
    pass "$id" "$(sha_of "$f")  ${f#"$REPO_ROOT"/}"
  else
    fail "$id" "missing ${f#"$REPO_ROOT"/}"
  fi
done

assert_contains D01 "$R55_DEC" 'the merge over sanitized tables in R54'"'"'s order followed by' 'R55 already fixes the loader sequence: sanitize per layer, THEN merge'
assert_contains D02 "$R55_DEC" 'owns merge depth and precedence order' 'R55 assigns merge depth and precedence order to R54'
assert_contains D03 "$R55_DEC" 'validate each layer'"'"'s leaves before precedence merge' 'R55 BASELINE-REVIEW F238 requires per-layer validation before the merge'
assert_contains D04 "$R57_DEC" 'accessor and no free-function surface.' 'R57 fixes the Paths accessor set at four'
assert_contains D05 "$R57_DEC" 'This item supplies `config_dir()` as the single resolver so R54 does not resolve it a second time' 'R57 hands config_dir() to R54'
assert_contains D06 "$R53_DEC" 'A per-key deserialization loop over R52'"'"'s `toml::Table`' 'R53 revision 2 validates per key over a toml::Table, not via a generated partial struct'
assert_contains D07 "$REPO_ROOT/research/topics/52-toml-crate/DECISION.md" '1.1.6+spec-1.1.0' 'R52 is published and pins toml 1.1.6+spec-1.1.0'

# The ground for Engines disagreement 1: the Opus raw read R55 at revision 1.
assert_contains D08 "$RUN_DIR/raw/opus.md" '(revision 1, `## Decision`, clauses 1–3)' 'raw/opus.md cites R55 at revision 1, before the sanitize-then-merge sequence was published'

# ---------------------------------------------------------------------------
# P — the five `- assumes` lines are byte-identical to docs/port/PARAMETERS.md.
# ---------------------------------------------------------------------------
REG="$REPO_ROOT/docs/port/PARAMETERS.md"
DEC="$EVIDENCE_DIR/../DECISION.md"
i=0
for param in msrv-policy rust-edition target-os-matrix license error-taxonomy-exit-codes; do
  i=$((i + 1))
  want="$(awk -F' \\| ' -v p="$param" '$0 ~ "^\\| " p " \\|" {print $4}' "$REG")"
  got="$(awk -v p="$param" 'index($0, "- assumes " p " = ") == 1 {print substr($0, length("- assumes " p " = ") + 1)}' "$DEC")"
  if [ -n "$want" ] && [ "$want" = "$got" ]; then
    pass "P0$i" "- assumes $param is byte-identical to docs/port/PARAMETERS.md (${#want} bytes)"
  else
    fail "P0$i" "- assumes $param differs from the registry (registry ${#want} bytes, decision ${#got} bytes)"
  fi
done

# The run's inputs/PARAMETERS.md differs from the current registry in exactly one row.
REGDIFF="$WORK/parameters.diff"
diff "$REG" "$RUN_DIR/inputs/PARAMETERS.md" > "$REGDIFF"
DIFFROWS="$("$GREP" -c '^[<>]' "$REGDIFF")"
DIFFROWS_WES="$("$GREP" -c '^[<>] | web-extra-surface |' "$REGDIFF")"
if [ "$DIFFROWS" = "2" ] && [ "$DIFFROWS_WES" = "2" ]; then
  pass P06 "inputs/PARAMETERS.md differs from the current registry only in the web-extra-surface row (R69, not consumed here)"
else
  fail P06 "inputs/PARAMETERS.md differs from the current registry beyond the web-extra-surface row ($DIFFROWS changed lines, $DIFFROWS_WES of them web-extra-surface)"
fi

# ---------------------------------------------------------------------------
# Y — the pinned py source: the shape this decision departs from (F232).
# ---------------------------------------------------------------------------
if [ -d "$PY_REPO/.git" ] && git -C "$PY_REPO" cat-file -e "$PY_PIN" 2>/dev/null; then
  git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/paths.py" > "$WORK/paths.py"
  cp "$WORK/paths.py" "$SNAP/py-paths-b08bccfb.py"
  assert_contains Y01 "$WORK/paths.py" 'def project_config_file(start: Path | None = None) -> Path:' 'py has a project_config_file'
  if sed -n '/def project_config_file/,/^def /p' "$WORK/paths.py" | "$GREP" -qE 'parents|ancestors|while |\.parent'; then
    fail Y02 "py project_config_file appears to walk up after all"
  else
    pass Y02 "py project_config_file inspects only the cwd — no parent walk (F232: py's shape is not adoptable)"
  fi
  assert_contains Y03 "$WORK/paths.py" 'def config_dirs() -> list[Path]:' 'py enumerates XDG_CONFIG_DIRS, which is the tier this item must reproduce'
else
  for id in Y01 Y02 Y03; do skip "$id" "pinned py source repo not present at $PY_REPO"; done
fi

# ---------------------------------------------------------------------------
# PR — the bounded walk-up probe (throwaway, $TMPDIR only, deleted on exit).
# ---------------------------------------------------------------------------
PROBE_SRC="$EVIDENCE_DIR/walkup_probe.rs"
PROBE_BIN="$WORK/walkup_probe"
PROBE_TREE="$WORK/tree"
mkdir -p "$PROBE_TREE"
if rustc --edition 2024 -O -o "$PROBE_BIN" "$PROBE_SRC" 2> "$WORK/rustc.err"; then
  if "$PROBE_BIN" "$PROBE_TREE" > "$WORK/probe.out" 2>&1; then
    sed 's/^/  /' "$WORK/probe.out"
    pass PR1 "walk-up probe: every case passed ($("$GREP" -c '^PASS ' "$WORK/probe.out") cases)"
  else
    sed 's/^/  /' "$WORK/probe.out"
    fail PR1 "walk-up probe reported a failing case"
  fi
else
  sed 's/^/  /' "$WORK/rustc.err"
  fail PR1 "walk-up probe did not compile"
fi

# ---------------------------------------------------------------------------
# H — raw report digests, for `## Engines`.
# ---------------------------------------------------------------------------
for f in opus.md doxa.md doxa.normalized.md doxa-openai.normalized.md doxa-perplexity.normalized.md doxa-gemini.normalized.md; do
  if [ -f "$RUN_DIR/raw/$f" ]; then
    echo "SHA256 raw/$f $(sha_of "$RUN_DIR/raw/$f")"
  else
    echo "SHA256 raw/$f MISSING"
  fi
done
if [ -f "$RUN_DIR/raw/codex-exit.txt" ]; then
  assert_contains H01 "$RUN_DIR/raw/codex-transcript.txt" "You've hit your usage limit" 'the Codex engine is absent because its provider refused the run'
else
  skip H01 "no codex-exit.txt in the run"
fi

echo
echo "failures=$FAILURES skipped=$SKIPPED"
if [ "$FAILURES" -ne 0 ]; then
  exit 1
fi
exit 0
