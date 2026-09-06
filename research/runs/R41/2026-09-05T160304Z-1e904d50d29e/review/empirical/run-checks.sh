#!/usr/bin/env bash
# run-checks.sh — R41 lockfile-freshness-check acceptance runner (synthesizer, 2026-09-05).
#
# Usage: run-checks.sh LABEL=TOOLCHAIN_BIN_DIR [LABEL=TOOLCHAIN_BIN_DIR ...]
#   TOOLCHAIN_BIN_DIR is prepended to PATH so `cargo` finds its sibling `rustc`
#   (e.g. "$(dirname "$(rustup which --toolchain 1.96.0 cargo)")"). An empty DIR
#   uses whatever cargo/rustc are already first on PATH.
# Env:   WORK_DIR  scratch root for the temporary Git repositories (default: ./.work,
#                  which is git-ignored); must be writable.
# Output: everything on stdout, ending with `summary: PASS=.. FAIL=.. RECORD=..`
#         and `RESULT: PASS|FAIL`. Exit status 0 iff FAIL=0.
#
# Revised 2026-09-05 after judgment audit r1 (finding F1): adds repository D
# (Cargo's own `cargo package` output must not refuse) and case A7 (a staged
# .cargo/config.toml triggers the check).
#
# Every case runs the fixture's scripts/check-cargo-lock.sh either directly or as a
# real .git/hooks/pre-commit driven by `git commit`. CARGO_BIN points at a spy
# wrapper that logs Cargo invocations and execs the real cargo on PATH, so the log
# proves which command the hook ran (or that it ran none).
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
FIXTURE="$HERE/fixture"
WORK_DIR="${WORK_DIR:-$HERE/.work}"
ORIG_PATH="$PATH"
PASS=0; FAIL=0; RECORD=0
OUT=""; STATUS=0; WORK=""

sha256_of() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }
now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
show() { [ -n "$1" ] && printf '%s\n' "$1" | sed 's/^/    | /'; return 0; }
capture() { printf '  $ %s\n' "$*"; OUT=$("$@" 2>&1); STATUS=$?; }
expect() { # CASE DESC EXPECTED ACTUAL
  if [ "$3" = "$4" ]; then PASS=$((PASS+1)); echo "PASS [$1] $2 -> exit $4 (expected $3)"
  else FAIL=$((FAIL+1)); echo "FAIL [$1] $2 -> exit $4 (expected $3)"; fi
}
expect_str() { # CASE DESC NEEDLE HAYSTACK
  if printf '%s' "$4" | grep -qF -- "$3"; then PASS=$((PASS+1)); echo "PASS [$1] $2: output contains '$3'"
  else FAIL=$((FAIL+1)); echo "FAIL [$1] $2: output lacks '$3'"; fi
}
expect_eq() { # CASE DESC A B
  if [ "$3" = "$4" ]; then PASS=$((PASS+1)); echo "PASS [$1] $2: $3 == $4"
  else FAIL=$((FAIL+1)); echo "FAIL [$1] $2: $3 != $4"; fi
}
record() { RECORD=$((RECORD+1)); echo "RECORD [$1] $2"; }
real_seconds() { printf '%s\n' "$1" | awk '/^real /{print $2}' | tail -1; }
spy_log() { cat "$CARGO_SPY_LOG"; }

mk_repo() { # NAME -> prints absolute path of a fresh Git repo containing the fixture, hook installed
  local dir="$WORK/$1"
  rm -rf "$dir"; mkdir -p "$dir"
  (cd "$FIXTURE" && tar --exclude=./target --exclude=./.work -cf - .) | (cd "$dir" && tar -xf -)
  git -C "$dir" init -q -b main
  git -C "$dir" config user.name "R41 synthesizer"
  git -C "$dir" config user.email "synth-fable@example.invalid"
  git -C "$dir" config commit.gpgsign false
  git -C "$dir" add -A
  git -C "$dir" commit -qm "fixture: initial workspace"
  printf '#!/usr/bin/env bash\nexec "$(git rev-parse --show-toplevel)/scripts/check-cargo-lock.sh" "$@"\n' > "$dir/.git/hooks/pre-commit"
  chmod +x "$dir/.git/hooks/pre-commit"
  printf '%s\n' "$dir"
}

mk_spy() {
  mkdir -p "$WORK/bin"
  cat > "$WORK/bin/cargo-spy" <<'EOS'
#!/usr/bin/env bash
printf 'cargo %s\n' "$*" >> "${CARGO_SPY_LOG:?}"
exec cargo "$@"
EOS
  chmod +x "$WORK/bin/cargo-spy"
}

run_toolchain() {
  local label="$1" dir="$2" i A B C lock0 lock1
  if [ -n "$dir" ]; then export PATH="$dir:$ORIG_PATH"; else export PATH="$ORIG_PATH"; fi
  WORK="$WORK_DIR/$label"; rm -rf "$WORK"; mkdir -p "$WORK"
  mk_spy
  export CARGO_BIN="$WORK/bin/cargo-spy"
  export CARGO_SPY_LOG="$WORK/cargo-spy.log"; : > "$CARGO_SPY_LOG"
  echo; echo "=== toolchain $label (PATH prefix: ${dir:-<none>}) started $(now) ==="
  echo "cargo: $(command -v cargo) -> $(cargo --version)"
  echo "rustc: $(command -v rustc) -> $(rustc --version)"
  echo "CARGO_HOME: ${CARGO_HOME:-<unset: default ~/.cargo>}"

  ## Repo A: clean tree, trigger, timing, --all, cold cache, compile at this toolchain
  A=$(mk_repo repo-a); cd "$A"
  echo "--- repo A: $A"
  record "$label/A0" "core.hooksPath in repo A = '$(git config --get core.hooksPath || true)' (empty: .git/hooks/pre-commit is used)"
  capture bash -c '/usr/bin/time -p cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/A1" "clean committed tree: cargo metadata --locked --format-version=1" 0 "$STATUS"; show "$OUT"
  record "$label/A1" "warm direct metadata wall seconds real=$(real_seconds "$OUT")"
  for i in 1 2 3; do
    : > "$CARGO_SPY_LOG"
    printf '# r41 trigger %s\n' "$i" >> crates/core/Cargo.toml
    git add crates/core/Cargo.toml
    capture /usr/bin/time -p git commit -qm "chore: member manifest comment $i"
    expect "$label/A2.$i" "staged member-manifest comment: git commit through pre-commit hook" 0 "$STATUS"; show "$OUT"
    expect_str "$label/A2.$i" "hook ran the recommended command" "cargo metadata --locked --format-version=1" "$(spy_log)"
    record "$label/A2.$i" "warm guarded commit wall seconds real=$(real_seconds "$OUT")"
  done
  : > "$CARGO_SPY_LOG"; printf '# r41 root trigger\n' >> Cargo.toml; git add Cargo.toml
  capture git commit -qm "chore: root manifest comment"
  expect "$label/A3" "staged root-manifest comment: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A3" "root manifest triggers Cargo" "cargo metadata --locked --format-version=1" "$(spy_log)"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/A4" "--all on a clean committed tree with nothing staged" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A4" "--all invoked Cargo unconditionally" "cargo metadata --locked --format-version=1" "$(spy_log)"
  capture bash -c 'CARGO_HOME="$1" /usr/bin/time -p cargo metadata --locked --format-version=1 >/dev/null' _ "$WORK/cold-home"
  expect "$label/A5" "cold empty CARGO_HOME (registry index + crate fetch): cargo metadata --locked" 0 "$STATUS"; show "$OUT"
  record "$label/A5" "cold direct metadata wall seconds real=$(real_seconds "$OUT")"
  capture bash -c '/usr/bin/time -p cargo check --workspace --all-targets --locked'
  expect "$label/A6" "cargo check --workspace --all-targets --locked at this toolchain (rust-version = \"1.96\")" 0 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -6)"
  record "$label/A6" "locked check wall seconds real=$(real_seconds "$OUT")"
  mkdir -p .cargo; printf '[term]\nverbose = false\n' > .cargo/config.toml
  : > "$CARGO_SPY_LOG"; git add .cargo/config.toml
  capture git commit -qm "chore: add resolution-neutral .cargo/config.toml"
  expect "$label/A7" "staged .cargo/config.toml (resolution-neutral key): git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A7" ".cargo/config.toml triggers Cargo" "cargo metadata --locked --format-version=1" "$(spy_log)"

  ## Repo B: stale manifest, controls, repair, index/worktree parity
  B=$(mk_repo repo-b); cd "$B"
  echo "--- repo B: $B"
  lock0=$(sha256_of Cargo.lock)
  record "$label/B0" "committed Cargo.lock sha256=$lock0"
  printf 'serde_json.workspace = true\n' >> crates/core/Cargo.toml
  git add crates/core/Cargo.toml
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/B1" "stale: staged manifest adds serde_json, Cargo.lock untouched: direct check" 101 "$STATUS"; show "$OUT"
  expect_str "$label/B1" "Cargo diagnostic preserved" "cannot update the lock file" "$OUT"
  expect_str "$label/B1" "remediation message present" "run cargo metadata --format-version=1" "$OUT"
  expect_eq "$label/B1" "Cargo.lock bytes unchanged after refusal" "$lock0" "$(sha256_of Cargo.lock)"
  capture /usr/bin/time -p git commit -qm "feat(core): add serde_json (stale lock)"
  expect "$label/B2" "stale: git commit blocked by pre-commit hook" 1 "$STATUS"; show "$OUT"
  expect_eq "$label/B2" "Cargo.lock bytes unchanged after blocked commit" "$lock0" "$(sha256_of Cargo.lock)"
  expect_eq "$label/B2" "no commit was created (rev-list count)" "$(git rev-list --count HEAD)" "1"
  record "$label/B2" "blocked commit wall seconds real=$(real_seconds "$OUT")"
  capture bash -c 'cargo metadata --locked --no-deps --format-version=1 >/dev/null'
  expect "$label/B3a" "false-pass control: --no-deps on the stale tree returns success" 0 "$STATUS"; show "$OUT"
  capture cargo update --locked --dry-run
  expect "$label/B3b" "false-pass control: cargo update --locked --dry-run on the stale tree returns success" 0 "$STATUS"; show "$OUT"
  capture cargo check --workspace --locked
  expect "$label/B3c" "runner-up: cargo check --workspace --locked on the stale tree" 101 "$STATUS"; show "$OUT"
  capture cargo update --workspace --locked
  expect "$label/B3d" "runner-up: cargo update --workspace --locked on the stale tree" 101 "$STATUS"; show "$OUT"
  expect_eq "$label/B3" "Cargo.lock bytes unchanged after all controls and probes" "$lock0" "$(sha256_of Cargo.lock)"
  capture bash -c 'cargo metadata --format-version=1 >/dev/null'
  expect "$label/B4" "repair per remediation: cargo metadata --format-version=1 rewrites Cargo.lock" 0 "$STATUS"; show "$OUT"
  lock1=$(sha256_of Cargo.lock)
  expect_eq "$label/B4" "Cargo.lock changed by the repair" "$([ "$lock0" != "$lock1" ] && echo changed || echo unchanged)" "changed"
  record "$label/B4" "repaired Cargo.lock sha256=$lock1; $(git diff --stat -- Cargo.lock | tail -1 | sed 's/^ *//')"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/B5a" "hazard: bare cargo metadata --locked passes while the repaired lock is unstaged" 0 "$STATUS"; show "$OUT"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/B5b" "parity guard: repaired lock unstaged -> check refuses before Cargo" 1 "$STATUS"; show "$OUT"
  expect_str "$label/B5b" "parity message" "differ from the index" "$OUT"
  expect_eq "$label/B5b" "Cargo not invoked (spy log bytes)" "$(wc -c < "$CARGO_SPY_LOG" | tr -d ' ')" "0"
  capture git commit -qm "feat(core): add serde_json (lock unstaged)"
  expect "$label/B5c" "parity guard: git commit blocked" 1 "$STATUS"; show "$OUT"
  git add Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture /usr/bin/time -p git commit -qm "feat(core): add serde_json"
  expect "$label/B6" "repaired manifest and lockfile both staged: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/B6" "hook ran Cargo on the repaired commit" "cargo metadata --locked --format-version=1" "$(spy_log)"
  record "$label/B6" "repaired commit wall seconds real=$(real_seconds "$OUT"); serde_json entries in Cargo.lock: $(grep -c 'name = "serde_json"' Cargo.lock)"
  printf 'serde_json.workspace = true\n' >> crates/cli/Cargo.toml
  capture bash -c 'cargo metadata --format-version=1 >/dev/null'
  git add Cargo.lock
  capture bash scripts/check-cargo-lock.sh
  expect "$label/B7a" "reverse parity: staged lockfile with unstaged member manifest -> refused" 1 "$STATUS"; show "$OUT"
  capture git commit -qm "chore: lockfile only"
  expect "$label/B7b" "reverse parity: git commit blocked" 1 "$STATUS"; show "$OUT"

  ## Repo C: unrelated commit skip, bypassed hook caught by --all, untracked-manifest guard
  C=$(mk_repo repo-c); cd "$C"
  echo "--- repo C: $C"
  printf '\nUnrelated change.\n' >> README.md; git add README.md
  capture env CARGO_BIN=/nonexistent/r41-cargo /usr/bin/time -p git commit -qm "docs: unrelated"
  expect "$label/C1" "unrelated staged file, CARGO_BIN=/nonexistent: commit succeeds without Cargo" 0 "$STATUS"; show "$OUT"
  expect_str "$label/C1" "skip diagnostic" "SKIP: no staged Cargo resolution inputs" "$OUT"
  record "$label/C1" "skip commit wall seconds real=$(real_seconds "$OUT")"
  printf 'serde_json.workspace = true\n' >> crates/core/Cargo.toml; git add crates/core/Cargo.toml
  capture git commit -q --no-verify -m "feat(core): add serde_json bypassing the hook"
  expect "$label/C2a" "git commit --no-verify commits a stale lock" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/C2b" "clean index, stale committed lock: default mode skips (nothing staged)" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/C2c" "clean index, stale committed lock: --all catches it" 101 "$STATUS"; show "$OUT"
  mkdir -p stray; printf '[package]\nname = "stray"\nversion = "0.1.0"\nedition = "2024"\n' > stray/Cargo.toml
  printf '# trigger\n' >> Cargo.toml; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/C3" "untracked Cargo.toml elsewhere in the repo -> refused before Cargo" 1 "$STATUS"; show "$OUT"
  expect_str "$label/C3" "untracked message" "untracked Cargo resolution inputs" "$OUT"
  rm -rf stray

  ## Repo D: Cargo's own build output (cargo package verification) must not refuse
  D=$(mk_repo repo-d); cd "$D"
  echo "--- repo D: $D"
  capture cargo package -p r41-core --locked
  expect "$label/D1" "cargo package -p r41-core --locked on the clean committed tree (default verification)" 0 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -4)"
  record "$label/D1" "Cargo files under target/package: $(find target/package -maxdepth 2 -type f -name 'Cargo.*' | sort | tr '\n' ' ')"
  expect_eq "$label/D1" "package output is Git-ignored (git status --short line count)" "$(git status --short | wc -l | tr -d ' ')" "0"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/D2" "--all on a clean index with target/package present" 0 "$STATUS"; show "$OUT"
  expect_str "$label/D2" "--all reached Cargo" "cargo metadata --locked --format-version=1" "$(spy_log)"
  printf '# r41 trigger after cargo package\n' >> crates/core/Cargo.toml; git add crates/core/Cargo.toml
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/D3a" "staged manifest comment with target/package present: direct check" 0 "$STATUS"; show "$OUT"
  capture git commit -qm "chore: manifest comment after cargo package"
  expect "$label/D3b" "staged manifest comment with target/package present: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/D3b" "hook reached Cargo" "cargo metadata --locked --format-version=1" "$(spy_log)"
  printf 'serde_json.workspace = true\n' >> crates/core/Cargo.toml; git add crates/core/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/D4" "stale manifest with target/package present: still refused by Cargo" 101 "$STATUS"; show "$OUT"
  expect_str "$label/D4" "refusal came from Cargo, not from the untracked scan" "cannot update the lock file" "$OUT"
  cd "$HERE"
  echo "=== toolchain $label finished $(now) ==="
}

echo "R41 lockfile-freshness-check acceptance run — started $(now)"
echo "runner: $0"
echo "fixture: $FIXTURE"
echo "WORK_DIR: $WORK_DIR"
echo "uname -a: $(uname -a)"
if command -v sw_vers >/dev/null 2>&1; then echo "sw_vers: $(sw_vers | tr '\n' ' ')"; elif [ -f /etc/os-release ]; then echo "os-release: $(. /etc/os-release; echo "$PRETTY_NAME")"; fi
echo "git: $(git --version); bash: $BASH_VERSION; time: /usr/bin/time"
echo "fixture files (sha256  path):"
(cd "$FIXTURE" && find . -type f ! -path './target/*' | sort | while IFS= read -r f; do printf '  %s  %s\n' "$(sha256_of "$f")" "$f"; done)
[ $# -gt 0 ] || { echo "usage: $0 LABEL=TOOLCHAIN_BIN_DIR ..."; exit 2; }
mkdir -p "$WORK_DIR"
for spec in "$@"; do run_toolchain "${spec%%=*}" "${spec#*=}"; done
echo
echo "summary: PASS=$PASS FAIL=$FAIL RECORD=$RECORD"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
