#!/usr/bin/env bash
# shellcheck disable=SC2016
#   SC2016 is disabled file-wide and deliberately: the search strings below are
#   literal quotations of the standard and of the crate sources, and several of
#   them contain `$XDG_STATE_HOME`, `$XDG_RUNTIME_DIR` and `$HOME` as text that
#   must NOT expand. Single quotes are the point, not an oversight.
#
# R57 xdg-directory-set — synthesizer empirical check.
#
# Verifies the claims the two raw reports make. Implements nothing: no template
# module, no paths accessor, no acceptance harness and no fixture beyond the
# throwaway spike in section 8, which is built outside this repository.
#
# Determinism contract
# --------------------
#   * Crate sources are the published .crate tarballs at pinned versions from
#     static.crates.io. A published version is immutable; each tarball's sha256
#     is asserted against a constant below, so every printed source extract is
#     reproducible byte-for-byte.
#   * The org CLI Design Standard is read at the pinned blob object
#     f9de0437baece3383e73ca2c5f48b7ab399b51c7, never at a branch tip. A blob
#     sha is not a commit, so it is read with `git cat-file -p <blob>`;
#     `git show <blob>:<path>` fails on it.
#   * Repository files are read relative to this script's own location, so the
#     script runs unchanged inside a `git archive HEAD` extraction. The three
#     sections that need something outside that extraction — the cli-standards
#     repository, the network, a Rust toolchain — print `SKIP <name>` with the
#     reason instead of failing.
#   * HTTP JSON and HTTP status codes that drift (download counters, endpoint
#     availability) are snapshotted once into ./snap/ and read from the
#     snapshot afterwards. The macOS spike's observed output is snapshotted the
#     same way. Delete ./snap/ to re-fetch and re-execute.
#   * No machine-dependent text reaches stdout: the toolchain and platform are
#     written to ./toolchain.txt instead. So
#     `bash r57-claims.sh | diff - r57-claims.log` is empty on any rerun.
#
# Usage: bash r57-claims.sh            (run from anywhere)

set -uo pipefail

GREP=/usr/bin/grep
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
EVID="$HERE"
SNAP="$EVID/snap"
RUN=$(cd -- "$EVID/../.." && pwd)
REPO=$(cd -- "$RUN/../../../.." && pwd)
STD_REPO=/Users/stevemorin/c/cli-standards
STD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
UA='rs-launch-blueprint-research/1.0'

ETCETERA_SHA=de48cc4d1c1d97a20fd819def54b890cadde72ed3ad0c614822a0a433361be96
DIRECTORIES_SHA=16f5094c54661b38d03bd7e50df373292118db60b585c08a411c6d840017fe7d

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$SNAP"

FAILED=0
section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }
skip()    { printf 'SKIP %s — %s\n' "$1" "$2"; }

# assert <label> <expected-count> <actual-count>
assert() {
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
  else
    printf 'FAIL %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}

# count <file> <fixed-string>  — prints the match count, binary named by assert
count() { $GREP -c -F -- "$2" "$1" 2>/dev/null || true; }

snap_json() { # snap_json <snapfile> <url>
  local f="$SNAP/$1"
  if [ ! -s "$f" ]; then
    curl -sS -H "User-Agent: $UA" -o "$f" "$2" || return 1
  fi
  [ -s "$f" ]
}

snap_status() { # snap_status <snapfile> <url>
  local f="$SNAP/$1"
  if [ ! -s "$f" ]; then
    curl -sS -o /dev/null -w '%{http_code}\n' "$2" > "$f" || return 1
  fi
  [ -s "$f" ]
}

# ---------------------------------------------------------------- toolchain --
{
  printf 'Machine-dependent facts for this run, deliberately kept out of the\n'
  printf 'diffed log. Section 8 was executed with this toolchain.\n\n'
  rustc --version 2>/dev/null || printf 'rustc: not installed\n'
  cargo --version 2>/dev/null || printf 'cargo: not installed\n'
  uname -sm
} > "$EVID/toolchain.txt"

# ======================================================= 1. the org standard ==
section "1. org CLI Design Standard v1.4.14 — R5.3 at the pinned blob"
STD="$WORK/cli-design-standard.md"
if [ ! -d "$STD_REPO/.git" ] || ! git -C "$STD_REPO" cat-file -t "$STD_BLOB" > /dev/null 2>&1; then
  skip "org-standard" "$STD_REPO is not a git repository holding blob $STD_BLOB"
else
  git -C "$STD_REPO" cat-file -p "$STD_BLOB" > "$STD"
  claim "R5.3, verbatim"
  sed -n '/^\*\*R5\.3 — Filesystem locations (XDG)\. (MUST)\*\*$/,/^❌ writing config/p' "$STD"
  claim "provenance row 10, verbatim"
  $GREP -n -F '| 10 | Filesystem paths |' "$STD"
  claim "Appendix E — the Rust sentence that names the two candidate crates"
  $GREP -o -F 'Pair with `figment`/`config` crates for the precedence chain and `directories`/`etcetera` for XDG paths.' "$STD"
  claim "assertions"
  assert "R5.3 carries the MUST conformance keyword" 1 \
    "$(count "$STD" '**R5.3 — Filesystem locations (XDG). (MUST)**')"
  assert "R5.3 purpose table has a State (logs, history) row" 1 \
    "$(count "$STD" '| State (logs, history) | `$XDG_STATE_HOME/acme/` |')"
  assert "R5.3 purpose table has a Runtime (sockets) row" 1 \
    "$(count "$STD" '| Runtime (sockets) | `$XDG_RUNTIME_DIR/acme/` |')"
  assert "provenance row 10 marks filesystem paths org-locked" 1 \
    "$(count "$STD" '| 10 | Filesystem paths | XDG Base Directory Specification | Modern standard; predictable | org-locked |')"
  assert "the document states version 1.4.14" 1 "$(count "$STD" '| **Version** | 1.4.14 |')"
  assert "R5.9 makes documenting a cache location a SHOULD" 1 \
    "$(count "$STD" '**R5.9 — Cache and offline controls. (MAY / SHOULD)**')"
  assert "R10.1 places a stored credential under \$XDG_STATE_HOME" 1 \
    "$(count "$STD" 'falling back to a `0600` file under `$XDG_STATE_HOME/acme/` (R5.3)')"
fi

# ======================================== 2. prerequisite and ledger citations ==
section "2. prerequisite decisions and ledger rows, read in this repository"
R67="$REPO/research/topics/67-error-and-exit-code-contract/DECISION.md"
R06="$REPO/research/topics/06-unsafe-code-policy/DECISION.md"
LEDGER="$REPO/docs/port/COMMONALITY.md"

claim "R67 DECISION.md:33 — the crash record defers its location to R57"
sed -n '33p' "$R67"
claim "R67 DECISION.md:126 — acceptance criterion AC7"
sed -n '126p' "$R67"
claim "R67 DECISION.md:587 — the RSLB104 catalogue row and its basis"
sed -n '587p' "$R67"
claim "R67 — every line naming RSLB101 outside the parameter blob"
$GREP -n -F 'RSLB101' "$R67" | $GREP -v -F '- owns error-taxonomy-exit-codes'
claim "COMMONALITY.md:253 — ledger row F249, the row this item settles"
sed -n '253p' "$LEDGER"
claim "COMMONALITY.md:251 — ledger row F247, named out of scope by the prompt"
sed -n '251p' "$LEDGER"
claim "R06 DECISION.md:24 — the workspace lint this item's accessor shape turns on"
sed -n '24p' "$R06"

claim "assertions"
assert "R67 defers the crash-record location to R57" 1 \
  "$(count "$R67" '**location deferred to R57**')"
assert "R67 AC7 leaves the exit code and envelope unchanged on a write failure" 1 \
  "$(count "$R67" '| AC7 | A crash-record write failure leaves the exit code and the envelope unchanged |')"
assert "R67 maps a config layer that cannot be read to RSLB104 and exit 1" 1 \
  "$(count "$R67" '| `RSLB104` config layer unreadable | 1 |')"
assert "F249 still carries the contingency clause this decision replaces" 1 \
  "$(count "$LEDGER" 'contingent on whether a file log sink (R59) or a crash log (see F302) end up needing a state/cache path')"
assert "R06 states unsafe_code = \"forbid\", at 6 places in its decision" 6 \
  "$(count "$R06" 'unsafe_code = "forbid"')"
assert "R06 puts that lint in the workspace table every member inherits, at 5 places" 5 \
  "$(count "$R06" '[workspace.lints.rust]')"
claim "R67 prerequisite hash recorded in inputs/prerequisites.json vs the file on disk"
printf 'recorded: %s\n' "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["R67"]["decision"])' "$RUN/inputs/prerequisites.json")"
printf 'on disk : %s\n' "$(shasum -a 256 "$R67" | cut -d" " -f1)"
assert "the recorded R67 decision hash matches the file on disk" 1 \
  "$([ "$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["R67"]["decision"])' "$RUN/inputs/prerequisites.json")" = "$(shasum -a 256 "$R67" | cut -d' ' -f1)" ] && echo 1 || echo 0)"

# ================================================ 3. parameters and couplings ==
section "3. parameter registry rows and this item's couplings"
claim "the four fixed rows, inputs/PARAMETERS.md against docs/port/PARAMETERS.md"
if diff <(sed -n '7,10p' "$RUN/inputs/PARAMETERS.md") <(sed -n '7,10p' "$REPO/docs/port/PARAMETERS.md"); then
  printf 'PASS fixed rows are byte-identical between the run input and the registry\n'
else
  printf 'FAIL fixed rows differ between the run input and the registry\n'
  FAILED=$((FAILED + 1))
fi
claim "the prompt's owns and consumes lines"
$GREP -n -E '^- (owns|consumes):' "$RUN/inputs/prompt.md"
assert "the prompt declares no owned parameter" 1 "$(count "$RUN/inputs/prompt.md" '- owns:')"
assert "the prompt declares no consumed parameter" 1 "$(count "$RUN/inputs/prompt.md" '- consumes:')"

# ================================================= 4. etcetera 0.11.0 source ==
section "4. etcetera 0.11.0 — the published artifact, read at a pinned sha256"
ETC_CRATE="$SNAP/etcetera-0.11.0.crate"
if [ ! -s "$ETC_CRATE" ] && ! curl -sS -L -H "User-Agent: $UA" -o "$ETC_CRATE" \
     https://static.crates.io/crates/etcetera/etcetera-0.11.0.crate; then
  skip "etcetera-source" "https://static.crates.io is unreachable and ./snap/etcetera-0.11.0.crate is absent"
else
  GOT=$(shasum -a 256 "$ETC_CRATE" | cut -d' ' -f1)
  claim "tarball identity"
  printf 'expected sha256: %s\n' "$ETCETERA_SHA"
  printf 'observed sha256: %s\n' "$GOT"
  if [ "$GOT" != "$ETCETERA_SHA" ]; then
    printf 'FAIL etcetera tarball sha256 mismatch — refusing to read it\n'
    FAILED=$((FAILED + 1))
  else
    printf 'PASS etcetera tarball sha256 matches the pin\n'
    tar xzf "$ETC_CRATE" -C "$WORK"
    E="$WORK/etcetera-0.11.0"
    claim "Cargo.toml — package metadata and the whole dependency set"
    sed -n '/^\[package\]/,$p' "$E/Cargo.toml"
    claim "src/base_strategy.rs — the trait and the per-OS dispatch"
    sed -n '/^pub trait BaseStrategy {/,/^}/p' "$E/src/base_strategy.rs"
    sed -n '/^cfg_if::cfg_if! {/,/^}/p' "$E/src/base_strategy.rs"
    claim "src/base_strategy/xdg.rs — the constructor, the absoluteness check, the fallbacks"
    sed -n '/^impl Xdg {/,/^}/p' "$E/src/base_strategy/xdg.rs"
    sed -n '/^impl super::BaseStrategy for Xdg {/,/^}/p' "$E/src/base_strategy/xdg.rs"
    claim "src/lib.rs — what home_dir() actually resolves"
    sed -n '111,126p' "$E/src/lib.rs"
    claim ".github/workflows/ci.yaml — the matrix shipped with 0.11.0 itself"
    sed -n '50,60p' "$E/.github/workflows/ci.yaml"
    claim "assertions"
    assert "0.11.0 declares rust-version 1.87.0" 1 "$(count "$E/Cargo.toml" 'rust-version = "1.87.0"')"
    assert "0.11.0 declares license MIT OR Apache-2.0" 1 "$(count "$E/Cargo.toml" 'license = "MIT OR Apache-2.0"')"
    assert "0.11.0 is edition 2024" 1 "$(count "$E/Cargo.toml" 'edition = "2024"')"
    assert "cfg-if is the only unconditional dependency" 1 "$(count "$E/Cargo.toml" '[dependencies.cfg-if]')"
    assert "windows-sys is target-gated to cfg(windows)" 1 \
      "$(count "$E/Cargo.toml" '[target."cfg(windows)".dependencies.windows-sys]')"
    assert "0.11.0 declares no Cargo feature table" 0 "$(count "$E/Cargo.toml" '[features]')"
    assert "choose_base_strategy picks Xdg on macOS and iOS" 1 \
      "$(count "$E/src/base_strategy.rs" 'create_strategies!(Apple, Xdg);')"
    assert "BaseStrategy::state_dir returns an Option" 1 \
      "$(count "$E/src/base_strategy.rs" 'fn state_dir(&self) -> Option<PathBuf>;')"
    assert "BaseStrategy is a plain public trait, not sealed" 1 \
      "$(count "$E/src/base_strategy.rs" 'pub trait BaseStrategy {')"
    assert "the Xdg strategy ignores a non-absolute override" 1 \
      "$(count "$E/src/base_strategy/xdg.rs" 'if path.is_absolute() { Some(path) } else { None }')"
    assert "XDG_STATE_HOME falls back to .local/state/" 1 \
      "$(count "$E/src/base_strategy/xdg.rs" 'self.env_var_or_default("XDG_STATE_HOME", ".local/state/")')"
    assert "XDG_RUNTIME_DIR has no fallback at all" 1 \
      "$(count "$E/src/base_strategy/xdg.rs" 'Self::env_var_or_none("XDG_RUNTIME_DIR")')"
    assert "the runtime_dir doc records the unchecked ownership contract" 1 \
      "$(count "$E/src/base_strategy.rs" 'This library does not check')"
    assert "Xdg::new is the sole constructor and is fallible" 1 \
      "$(count "$E/src/base_strategy/xdg.rs" 'pub fn new() -> Result<Self, HomeDirError> {')"
    assert "etcetera::home_dir wraps std::env::home_dir" 1 \
      "$(count "$E/src/lib.rs" 'std::env::home_dir().ok_or(HomeDirError)')"
    assert "the 0.11.0 CI matrix names macos-latest and ubuntu-latest" 1 \
      "$(count "$E/.github/workflows/ci.yaml" 'os: [macos-latest, ubuntu-latest, windows-latest]')"
    assert "the 0.11.0 CI matrix pins its MSRV row at 1.87.0" 1 \
      "$(count "$E/.github/workflows/ci.yaml" 'toolchain: [beta, stable, 1.87.0]')"
  fi
fi

# ============================================= 5. directories 6.0.0 source ==
section "5. directories 6.0.0 — the macOS capability gap, read at its own source"
DIR_CRATE="$SNAP/directories-6.0.0.crate"
if [ ! -s "$DIR_CRATE" ] && ! curl -sS -L -H "User-Agent: $UA" -o "$DIR_CRATE" \
     https://static.crates.io/crates/directories/directories-6.0.0.crate; then
  skip "directories-source" "https://static.crates.io is unreachable and ./snap/directories-6.0.0.crate is absent"
else
  GOT=$(shasum -a 256 "$DIR_CRATE" | cut -d' ' -f1)
  claim "tarball identity"
  printf 'expected sha256: %s\n' "$DIRECTORIES_SHA"
  printf 'observed sha256: %s\n' "$GOT"
  if [ "$GOT" != "$DIRECTORIES_SHA" ]; then
    printf 'FAIL directories tarball sha256 mismatch — refusing to read it\n'
    FAILED=$((FAILED + 1))
  else
    printf 'PASS directories tarball sha256 matches the pin\n'
    tar xzf "$DIR_CRATE" -C "$WORK"
    D="$WORK/directories-6.0.0"
    claim "Cargo.toml — package metadata and the whole dependency set"
    sed -n '/^\[package\]/,$p' "$D/Cargo.toml"
    claim "src/mac.rs — every state_dir assignment on the macOS path"
    $GREP -n -F 'state_dir:' "$D/src/mac.rs"
    claim "src/mac.rs — what config_dir and data_dir resolve to on macOS"
    $GREP -n -E 'let (config_dir|data_dir|cache_dir) ' "$D/src/mac.rs"
    claim "assertions"
    assert "macOS assigns state_dir None at both construction sites" 2 \
      "$(count "$D/src/mac.rs" 'state_dir:        None')"
    assert "macOS config_dir is Library/Application Support, not an XDG path" 1 \
      "$(count "$D/src/mac.rs" 'let config_dir       = home_dir.join("Library/Application Support");')"
    assert "no XDG environment variable is read anywhere on the macOS path" 0 \
      "$(count "$D/src/mac.rs" 'XDG_')"
    assert "directories 6.0.0 declares no rust-version, so its MSRV floor is unstated" 0 \
      "$(count "$D/Cargo.toml" 'rust-version')"
    assert "directories 6.0.0 depends on dirs-sys" 1 "$(count "$D/Cargo.toml" '[dependencies.dirs-sys]')"
  fi
fi

# ============================================================== 6. figures ==
section "6. crates.io figures — endpoint, retrieved 2026-09-16"
if ! snap_json etcetera-crate.json https://crates.io/api/v1/crates/etcetera \
   || ! snap_json etcetera-versions.json https://crates.io/api/v1/crates/etcetera/versions \
   || ! snap_json etcetera-deps.json https://crates.io/api/v1/crates/etcetera/0.11.0/dependencies; then
  skip "crates-io-figures" "https://crates.io is unreachable and ./snap/ holds no response"
else
  claim "GET https://crates.io/api/v1/crates/etcetera — crate.recent_downloads, crate.downloads"
  python3 - "$SNAP/etcetera-crate.json" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))["crate"]
print("recent_downloads (90-day) =", c["recent_downloads"])
print("downloads (all-time)      =", c["downloads"])
print("max_stable_version        =", c["max_stable_version"])
PY
  claim "GET https://crates.io/api/v1/crates/etcetera/versions — newest with yanked: false"
  python3 - "$SNAP/etcetera-versions.json" <<'PY'
import json, sys
v = [x for x in json.load(open(sys.argv[1]))["versions"] if not x["yanked"]][0]
print("num =", v["num"], "| created_at =", v["created_at"])
print("rust_version =", v.get("rust_version"), "| license =", v["license"])
PY
  claim "GET https://crates.io/api/v1/crates/etcetera/0.11.0/dependencies"
  python3 - "$SNAP/etcetera-deps.json" <<'PY'
import json, sys
for d in json.load(open(sys.argv[1]))["dependencies"]:
    print("%-12s %-8s kind=%-6s optional=%-5s target=%s"
          % (d["crate_id"], d["req"], d["kind"], d["optional"], d["target"]))
PY
fi

# =========================================================== 7. advisories ==
section "7. RustSec — advisory status with a live positive control"
if ! snap_status rustsec-etcetera.txt https://rustsec.org/packages/etcetera.html \
   || ! snap_status rustsec-anyhow.txt https://rustsec.org/packages/anyhow.html \
   || ! snap_status rustsec-directories.txt https://rustsec.org/packages/directories.html; then
  skip "rustsec-status" "https://rustsec.org is unreachable and ./snap/ holds no status"
else
  claim "HTTP status of https://rustsec.org/packages/<name>.html"
  printf 'etcetera    %s\n' "$(cat "$SNAP/rustsec-etcetera.txt")"
  printf 'directories %s\n' "$(cat "$SNAP/rustsec-directories.txt")"
  printf 'anyhow      %s   <- live positive control: a crate known to carry an advisory\n' \
    "$(cat "$SNAP/rustsec-anyhow.txt")"
  claim "assertions"
  assert "etcetera has no RustSec package page" 404 "$(cat "$SNAP/rustsec-etcetera.txt")"
  assert "the control returns 200, so the 404 is absence and not a broken endpoint" 200 \
    "$(cat "$SNAP/rustsec-anyhow.txt")"
fi

if [ ! -s "$SNAP/advisory-directories.md" ] || [ ! -s "$SNAP/advisory-dirs.md" ]; then
  gh api repos/rustsec/advisory-db/contents/crates/directories/RUSTSEC-2020-0054.md --jq '.content' \
    2>/dev/null | base64 -d > "$SNAP/advisory-directories.md"
  gh api repos/rustsec/advisory-db/contents/crates/dirs/RUSTSEC-2020-0053.md --jq '.content' \
    2>/dev/null | base64 -d > "$SNAP/advisory-dirs.md"
fi
if [ ! -s "$SNAP/advisory-directories.md" ]; then
  skip "rustsec-advisory-db" "the GitHub API is unreachable and ./snap/ holds no advisory"
else
  claim "the two advisories the directories family's 200 pages carry"
  for f in advisory-directories advisory-dirs; do
    printf '%s: ' "$f"
    $GREP -h -E '^(id|informational|withdrawn|patched) ' "$SNAP/$f.md" | tr '\n' ' '
    printf '\n'
  done
  claim "assertions"
  assert "the directories advisory is withdrawn" 1 \
    "$(count "$SNAP/advisory-directories.md" 'withdrawn = "2021-04-19"')"
  assert "the dirs advisory is withdrawn" 1 \
    "$(count "$SNAP/advisory-dirs.md" 'withdrawn = "2021-04-19"')"
fi

# ================================================== 8. the throwaway spike ==
section "8. throwaway macOS spike — observed behaviour of choose_base_strategy()"
printf 'A ~14-line binary built OUTSIDE this repository, depending on the\n'
printf 'sha256-pinned etcetera 0.11.0 source extracted in section 4, run under\n'
printf '`env -i` with a fixed fake HOME. It builds nothing this decision\n'
printf 'recommends: it prints what the crate resolves, so the macOS behaviour\n'
printf 'the two engines disagree about is observed rather than inferred. The\n'
printf 'toolchain that produced it is in ./toolchain.txt.\n'
SPIKE_OUT="$SNAP/spike-macos-arm64.txt"
if [ ! -s "$SPIKE_OUT" ]; then
  if ! command -v cargo > /dev/null 2>&1; then
    skip "macos-spike" "cargo is not installed and ./snap/spike-macos-arm64.txt is absent"
  elif [ ! -d "$WORK/etcetera-0.11.0" ]; then
    skip "macos-spike" "section 4 did not extract the pinned etcetera source"
  elif [ "$(uname -s)" != "Darwin" ]; then
    skip "macos-spike" "this host is not macOS and ./snap/spike-macos-arm64.txt is absent"
  else
    S="$WORK/r57spike"
    mkdir -p "$S/src"
    {
      printf '[package]\nname = "r57spike"\nversion = "0.0.0"\nedition = "2024"\n\n'
      printf '[dependencies]\netcetera = { path = "%s" }\n\n[workspace]\n' "$WORK/etcetera-0.11.0"
    } > "$S/Cargo.toml"
    cat > "$S/src/main.rs" <<'RS'
use etcetera::base_strategy::{BaseStrategy, choose_base_strategy};
fn main() {
    match choose_base_strategy() {
        Ok(s) => {
            println!("config = {}", s.config_dir().display());
            println!("data   = {}", s.data_dir().display());
            println!("state  = {:?}", s.state_dir().map(|p| p.display().to_string()));
            println!("cache  = {}", s.cache_dir().display());
            println!("runtime= {:?}", s.runtime_dir().map(|p| p.display().to_string()));
        }
        Err(e) => println!("ERR = {e}"),
    }
}
RS
    if (cd "$S" && cargo build --quiet > /dev/null 2>&1); then
      B="$S/target/debug/r57spike"
      {
        printf 'case 1 — HOME=/fixed/fake, no XDG_* set\n'
        env -i HOME=/fixed/fake "$B"
        printf '\ncase 2 — HOME=/fixed/fake, XDG_STATE_HOME=/abs/state (absolute)\n'
        env -i HOME=/fixed/fake XDG_STATE_HOME=/abs/state "$B"
        printf '\ncase 3 — HOME=/fixed/fake, XDG_STATE_HOME= (empty)\n'
        env -i HOME=/fixed/fake XDG_STATE_HOME= "$B"
        printf '\ncase 4 — HOME=/fixed/fake, XDG_STATE_HOME=rel/ative (relative)\n'
        env -i HOME=/fixed/fake XDG_STATE_HOME=rel/ative "$B"
        printf '\ncase 5 — no HOME and no XDG_* at all. The absolute paths are this\n'
        printf 'machine passwd entry home, so only the shape is printed:\n'
        env -i "$B" | sed -e "s#$HOME#<passwd-home>#g"
      } > "$SPIKE_OUT"
    else
      skip "macos-spike" "cargo build failed"
    fi
  fi
fi
if [ -s "$SPIKE_OUT" ]; then
  claim "observed output"
  cat "$SPIKE_OUT"
  claim "assertions"
  assert "macOS resolves a state directory at all, in the 3 cases with no usable override" 3 \
    "$(count "$SPIKE_OUT" 'state  = Some("/fixed/fake/.local/state/")')"
  assert "an absolute XDG_STATE_HOME is honoured on macOS" 1 \
    "$(count "$SPIKE_OUT" 'state  = Some("/abs/state")')"
  assert "macOS config_dir is the XDG default, not Library/Application Support" 4 \
    "$(count "$SPIKE_OUT" 'config = /fixed/fake/.config/')"
  assert "no XDG_RUNTIME_DIR fallback is invented" 5 "$(count "$SPIKE_OUT" 'runtime= None')"
  assert "removing HOME does NOT produce HomeDirError on this platform" 0 \
    "$(count "$SPIKE_OUT" 'ERR = ')"
  assert "with HOME removed the passwd entry supplies the home directory" 1 \
    "$(count "$SPIKE_OUT" 'config = <passwd-home>/.config/')"
fi

section "result"
printf 'failed assertions: %s\n' "$FAILED"
[ "$FAILED" -eq 0 ] || exit 1
