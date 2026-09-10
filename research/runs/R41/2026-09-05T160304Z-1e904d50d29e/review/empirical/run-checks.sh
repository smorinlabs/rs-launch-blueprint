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
# Revised 2026-09-09 after judgment audit r2 (finding F1): the script now runs a
# conservative unlocked resolve (`cargo update --workspace`) and compares every
# Cargo.lock with the index, restoring it afterwards. Every earlier case is kept;
# the expectations that the design changed are: the spy asserts the new command
# (A2, A3, A4, A7, B6, D2, D3b), a stale lock is refused by the script with exit 1
# and the "out of date" message instead of Cargo's 101 (B1, C2c, D4), and the
# repair uses the new remediation (B4). New: A1b/A5b (warm and cold cost of the
# recommended command), B3e (unlocked `cargo metadata` as the alternative,
# compared by diff stat), B5a2 (the unstaged-repair hazard is command-independent),
# repository E (leaf workspace-member removal in both forms, the `--no-verify`
# bypass with `--all` and the lock-only repair commit, lockfile normalization,
# a `version = 3` lockfile, a repository with no lockfile) and repository F
# (requirement change, member version bump, registry-edge removal, malformed manifest).
# Revised 2026-09-09 after empirical audit r3 (finding F1): the script discovers
# every independent workspace root and resolves each; repository G (nested
# workspace with its own [workspace] table, vendored non-member package with a
# lock, excluded standalone package, unparsable template manifest) and A4b
# (whole-script timing) are added.
# Revised 2026-09-09 after judgment audit r4 (finding F1, observations O1 and O5):
# the script resolves each root from its own directory so that root's
# .cargo/config* applies; the spy now records the working directory; repository H
# (a nested root with its own .cargo/config.toml [patch.crates-io] in the stale
# and the freshly-resolved state, a nested root whose Cargo.lock is Git-ignored,
# a .cargo/config.toml below a workspace root) and F5 (a manifest-level
# [patch.crates-io] at the top level) are added; a stub `anyhow` crate outside
# the repository backs the [patch] cases.
#
# Every case runs the fixture's scripts/check-cargo-lock.sh either directly or as a
# real .git/hooks/pre-commit driven by `git commit`. CARGO_BIN points at a spy
# wrapper that logs Cargo invocations and execs the real cargo on PATH, so the log
# proves which command the hook ran (or that it ran none). No `sed -i` is used
# (BSD and GNU sed differ); files are rewritten through a temporary copy.
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
FIXTURE="$HERE/fixture"
WORK_DIR="${WORK_DIR:-$HERE/.work}"
ORIG_PATH="$PATH"
PASS=0; FAIL=0; RECORD=0
OUT=""; STATUS=0; WORK=""
CMD='cargo update --workspace'   # what the spy log must show for the recommended design

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
expect_not_str() { # CASE DESC NEEDLE HAYSTACK
  if printf '%s' "$4" | grep -qF -- "$3"; then FAIL=$((FAIL+1)); echo "FAIL [$1] $2: output contains '$3'"
  else PASS=$((PASS+1)); echo "PASS [$1] $2: output lacks '$3'"; fi
}
expect_eq() { # CASE DESC A B
  if [ "$3" = "$4" ]; then PASS=$((PASS+1)); echo "PASS [$1] $2: $3 == $4"
  else FAIL=$((FAIL+1)); echo "FAIL [$1] $2: $3 != $4"; fi
}
record() { RECORD=$((RECORD+1)); echo "RECORD [$1] $2"; }
real_seconds() { printf '%s\n' "$1" | awk '/^real /{print $2}' | tail -1; }
spy_log() { cat "$CARGO_SPY_LOG"; }
lock_stat() { git diff --stat --no-ext-diff -- Cargo.lock | tail -1 | sed 's/^ *//'; }
rewrite() { # FILE SED_EXPR — portable in-place edit
  sed "$2" "$1" > "$1.r41tmp" && mv "$1.r41tmp" "$1"
}
drop_web_member() { rewrite Cargo.toml 's/, "crates\/web"//'; }

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
printf 'cargo %s (cwd %s)\n' "$*" "$PWD" >> "${CARGO_SPY_LOG:?}"
exec cargo "$@"
EOS
  chmod +x "$WORK/bin/cargo-spy"
}

# alt_vs_pick CASE — on the current (stale) worktree, run the unlocked `cargo metadata`
# alternative and the recommended `cargo update --workspace`, each followed by a
# restore of Cargo.lock, and compare their diff stats. Leaves the lock restored.
alt_vs_pick() {
  local case="$1" stat_alt stat_pick
  capture bash -c 'cargo metadata --format-version=1 >/dev/null'
  expect "$case.alt" "alternative: unlocked cargo metadata --format-version=1 rewrites the lock" 0 "$STATUS"; show "$OUT"
  stat_alt=$(lock_stat); record "$case.alt" "unlocked metadata diff stat: ${stat_alt:-<no change>}"
  git checkout --quiet -- Cargo.lock
  capture cargo update --workspace
  expect "$case.pick" "recommended: cargo update --workspace rewrites the lock" 0 "$STATUS"; show "$OUT"
  stat_pick=$(lock_stat); record "$case.pick" "cargo update --workspace diff stat: ${stat_pick:-<no change>}"
  git checkout --quiet -- Cargo.lock
  expect_eq "$case" "both unlocked commands produce the same lock change" "${stat_alt:-<no change>}" "${stat_pick:-<no change>}"
}

run_toolchain() {
  local label="$1" dir="$2" i A B C D E E2 E3 F G H Gp Hp STUB lock0 lock1 lock2 lock3 stat0
  if [ -n "$dir" ]; then export PATH="$dir:$ORIG_PATH"; else export PATH="$ORIG_PATH"; fi
  WORK="$WORK_DIR/$label"; rm -rf "$WORK"; mkdir -p "$WORK"
  mk_spy
  mkdir -p "$WORK/stub-anyhow/src"; printf '[package]\nname = "anyhow"\nversion = "1.0.104"\nedition = "2021"\n' > "$WORK/stub-anyhow/Cargo.toml"; : > "$WORK/stub-anyhow/src/lib.rs"
  STUB=$(cd "$WORK/stub-anyhow" && pwd -P)
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
  lock0=$(sha256_of Cargo.lock)
  capture bash -c '/usr/bin/time -p cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/A1" "clean committed tree: cargo metadata --locked --format-version=1 (revision-2 command, control)" 0 "$STATUS"; show "$OUT"
  record "$label/A1" "warm direct locked metadata wall seconds real=$(real_seconds "$OUT")"
  capture bash -c '/usr/bin/time -p cargo update --workspace'
  expect "$label/A1b" "clean committed tree: cargo update --workspace (recommended resolve)" 0 "$STATUS"; show "$OUT"
  record "$label/A1b" "warm direct recommended resolve wall seconds real=$(real_seconds "$OUT")"
  capture git diff --quiet --no-ext-diff -- Cargo.lock
  expect "$label/A1b" "fresh lock not rewritten by the unlocked resolve (git diff --quiet -- Cargo.lock)" 0 "$STATUS"
  expect_eq "$label/A1b" "Cargo.lock bytes unchanged" "$lock0" "$(sha256_of Cargo.lock)"
  for i in 1 2 3; do
    : > "$CARGO_SPY_LOG"
    printf '# r41 trigger %s\n' "$i" >> crates/core/Cargo.toml
    git add crates/core/Cargo.toml
    capture /usr/bin/time -p git commit -qm "chore: member manifest comment $i"
    expect "$label/A2.$i" "staged member-manifest comment: git commit through pre-commit hook" 0 "$STATUS"; show "$OUT"
    expect_str "$label/A2.$i" "hook ran the recommended command" "$CMD" "$(spy_log)"
    record "$label/A2.$i" "warm guarded commit wall seconds real=$(real_seconds "$OUT")"
  done
  : > "$CARGO_SPY_LOG"; printf '# r41 root trigger\n' >> Cargo.toml; git add Cargo.toml
  capture git commit -qm "chore: root manifest comment"
  expect "$label/A3" "staged root-manifest comment: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A3" "root manifest triggers Cargo" "$CMD" "$(spy_log)"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/A4" "--all on a clean committed tree with nothing staged" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A4" "--all invoked Cargo unconditionally" "$CMD" "$(spy_log)"
  expect_not_str "$label/A4" "single-workspace repository: no locate-project call" "cargo locate-project" "$(spy_log)"
  capture bash -c '/usr/bin/time -p bash scripts/check-cargo-lock.sh --all'
  expect "$label/A4b" "--all on the clean tree, whole script timed (discovery + resolve + compare)" 0 "$STATUS"; show "$OUT"
  record "$label/A4b" "warm whole-script --all wall seconds real=$(real_seconds "$OUT")"
  capture bash -c 'CARGO_HOME="$1" /usr/bin/time -p cargo metadata --locked --format-version=1 >/dev/null' _ "$WORK/cold-home"
  expect "$label/A5" "cold empty CARGO_HOME (registry index + crate fetch): cargo metadata --locked (control)" 0 "$STATUS"; show "$OUT"
  record "$label/A5" "cold direct locked metadata wall seconds real=$(real_seconds "$OUT")"
  capture bash -c 'CARGO_HOME="$1" /usr/bin/time -p cargo update --workspace' _ "$WORK/cold-home-update"
  expect "$label/A5b" "cold empty CARGO_HOME: cargo update --workspace (recommended resolve; index only)" 0 "$STATUS"; show "$OUT"
  record "$label/A5b" "cold direct recommended resolve wall seconds real=$(real_seconds "$OUT"); crate archives fetched into the cold home: $(find "$WORK/cold-home-update" -name '*.crate' 2>/dev/null | wc -l | tr -d ' ') (locked metadata control fetched: $(find "$WORK/cold-home" -name '*.crate' 2>/dev/null | wc -l | tr -d ' '))"
  expect_eq "$label/A5b" "Cargo.lock bytes unchanged after the cold resolve" "$lock0" "$(sha256_of Cargo.lock)"
  capture bash -c '/usr/bin/time -p cargo check --workspace --all-targets --locked'
  expect "$label/A6" "cargo check --workspace --all-targets --locked at this toolchain (rust-version = \"1.96\")" 0 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -6)"
  record "$label/A6" "locked check wall seconds real=$(real_seconds "$OUT")"
  mkdir -p .cargo; printf '[term]\nverbose = false\n' > .cargo/config.toml
  : > "$CARGO_SPY_LOG"; git add .cargo/config.toml
  capture git commit -qm "chore: add resolution-neutral .cargo/config.toml"
  expect "$label/A7" "staged .cargo/config.toml (resolution-neutral key): git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/A7" ".cargo/config.toml triggers Cargo" "$CMD" "$(spy_log)"

  ## Repo B: stale manifest, controls, repair, index/worktree parity
  B=$(mk_repo repo-b); cd "$B"
  echo "--- repo B: $B"
  lock0=$(sha256_of Cargo.lock)
  record "$label/B0" "committed Cargo.lock sha256=$lock0"
  printf 'serde_json.workspace = true\n' >> crates/core/Cargo.toml
  git add crates/core/Cargo.toml
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/B1" "stale: staged manifest adds serde_json, Cargo.lock untouched: direct check" 1 "$STATUS"; show "$OUT"
  expect_str "$label/B1" "Cargo's own resolve summary shown" "Adding serde_json" "$OUT"
  expect_str "$label/B1" "lock diff stat shown" "Cargo.lock |" "$OUT"
  expect_str "$label/B1" "remediation message present" "out of date" "$OUT"
  expect_str "$label/B1" "hook ran the recommended command" "$CMD" "$(spy_log)"
  expect_eq "$label/B1" "Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of Cargo.lock)"
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
  expect "$label/B3c" "runner-up (locked compile): cargo check --workspace --locked on the stale tree" 101 "$STATUS"; show "$OUT"
  capture cargo update --workspace --locked
  expect "$label/B3d" "locked form of the recommended command: cargo update --workspace --locked on the stale tree" 101 "$STATUS"; show "$OUT"
  expect_eq "$label/B3" "Cargo.lock bytes unchanged after all controls and probes" "$lock0" "$(sha256_of Cargo.lock)"
  capture bash -c 'cargo metadata --format-version=1 >/dev/null'
  expect "$label/B3e" "alternative: unlocked cargo metadata --format-version=1 rewrites the lock" 0 "$STATUS"; show "$OUT"
  stat0=$(lock_stat); record "$label/B3e" "unlocked metadata diff stat: $stat0; sha256=$(sha256_of Cargo.lock)"
  git checkout --quiet -- Cargo.lock
  expect_eq "$label/B3e" "lock restored from the index" "$lock0" "$(sha256_of Cargo.lock)"
  capture cargo update --workspace
  expect "$label/B4" "repair per remediation: cargo update --workspace rewrites Cargo.lock" 0 "$STATUS"; show "$OUT"
  lock1=$(sha256_of Cargo.lock)
  expect_eq "$label/B4" "Cargo.lock changed by the repair" "$([ "$lock0" != "$lock1" ] && echo changed || echo unchanged)" "changed"
  record "$label/B4" "repaired Cargo.lock sha256=$lock1; $(lock_stat)"
  expect_eq "$label/B4" "repair diff stat equals the unlocked-metadata alternative's" "$stat0" "$(lock_stat)"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/B5a" "hazard: bare cargo metadata --locked passes while the repaired lock is unstaged" 0 "$STATUS"; show "$OUT"
  capture cargo update --workspace
  expect "$label/B5a2" "hazard is command-independent: bare cargo update --workspace also passes with the repaired lock unstaged" 0 "$STATUS"; show "$OUT"
  expect_eq "$label/B5a2" "repaired lock untouched by the bare resolve" "$lock1" "$(sha256_of Cargo.lock)"
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
  expect_str "$label/B6" "hook ran Cargo on the repaired commit" "$CMD" "$(spy_log)"
  record "$label/B6" "repaired commit wall seconds real=$(real_seconds "$OUT"); serde_json entries in Cargo.lock: $(grep -c 'name = "serde_json"' Cargo.lock)"
  printf 'serde_json.workspace = true\n' >> crates/cli/Cargo.toml
  capture cargo update --workspace
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
  lock0=$(sha256_of Cargo.lock)
  capture bash scripts/check-cargo-lock.sh
  expect "$label/C2b" "clean index, stale committed lock: default mode skips (nothing staged)" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/C2c" "clean index, stale committed lock: --all catches it" 1 "$STATUS"; show "$OUT"
  expect_str "$label/C2c" "out-of-date message" "out of date" "$OUT"
  expect_eq "$label/C2c" "committed lock left unchanged on disk (restored)" "$lock0" "$(sha256_of Cargo.lock)"
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
  expect_str "$label/D2" "--all reached Cargo" "$CMD" "$(spy_log)"
  printf '# r41 trigger after cargo package\n' >> crates/core/Cargo.toml; git add crates/core/Cargo.toml
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/D3a" "staged manifest comment with target/package present: direct check" 0 "$STATUS"; show "$OUT"
  capture git commit -qm "chore: manifest comment after cargo package"
  expect "$label/D3b" "staged manifest comment with target/package present: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/D3b" "hook reached Cargo" "$CMD" "$(spy_log)"
  printf 'serde_json.workspace = true\n' >> crates/core/Cargo.toml; git add crates/core/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/D4" "stale manifest with target/package present: still refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/D4" "refusal came from the lock comparison, not from the untracked scan" "out of date" "$OUT"
  expect_not_str "$label/D4" "no untracked-input refusal" "untracked Cargo resolution inputs" "$OUT"

  ## Repo E: leaf workspace-member removal, form 1 (members list edited; directory left on disk)
  E=$(mk_repo repo-e); cd "$E"
  echo "--- repo E: $E"
  lock0=$(sha256_of Cargo.lock)
  expect_eq "$label/E0" "committed lock carries the r41-web entry" "$(grep -c 'name = "r41-web"' Cargo.lock)" "1"
  drop_web_member; git add Cargo.toml
  record "$label/E0" "staged: $(git diff --cached --stat | tail -1 | sed 's/^ *//'); members now: $(grep '^members' Cargo.toml)"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/E1a" "revision-2 command: cargo metadata --locked passes the orphan lock entry (false pass)" 0 "$STATUS"; show "$OUT"
  capture cargo update --workspace --locked
  expect "$label/E1b" "cargo update --workspace --locked passes the orphan (false pass)" 0 "$STATUS"; show "$OUT"
  capture cargo generate-lockfile --locked
  record "$label/E1c" "cargo generate-lockfile --locked on the orphan tree -> exit $STATUS (0 = false pass; 101 would mean only that a newer registry version exists, since this command re-resolves to latest)"; show "$OUT"
  capture cargo check --workspace --locked
  expect "$label/E1d" "cargo check --workspace --locked passes the orphan (false pass)" 0 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -2)"
  expect_eq "$label/E1" "Cargo.lock bytes unchanged after the four --locked probes" "$lock0" "$(sha256_of Cargo.lock)"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/E1e" "leaf member removed (members list only): direct check refuses" 1 "$STATUS"; show "$OUT"
  expect_str "$label/E1e" "out-of-date message" "out of date" "$OUT"
  expect_str "$label/E1e" "lock diff stat shown" "Cargo.lock |" "$OUT"
  expect_str "$label/E1e" "hook ran the recommended command" "$CMD" "$(spy_log)"
  expect_eq "$label/E1e" "Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of Cargo.lock)"
  capture /usr/bin/time -p git commit -qm "refactor: drop the web member"
  expect "$label/E1f" "leaf member removed: git commit blocked by pre-commit hook" 1 "$STATUS"; show "$OUT"
  expect_eq "$label/E1f" "no commit was created (rev-list count)" "$(git rev-list --count HEAD)" "1"
  expect_eq "$label/E1f" "Cargo.lock bytes unchanged after blocked commit" "$lock0" "$(sha256_of Cargo.lock)"
  record "$label/E1f" "blocked commit wall seconds real=$(real_seconds "$OUT")"
  alt_vs_pick "$label/E1g"
  capture cargo update --workspace
  expect "$label/E1h" "repair per remediation: cargo update --workspace prunes the orphan" 0 "$STATUS"; show "$OUT"
  lock1=$(sha256_of Cargo.lock)
  record "$label/E1h" "repaired Cargo.lock sha256=$lock1; $(lock_stat)"
  expect_eq "$label/E1h" "orphan r41-web entry gone from the repaired lock" "$(grep -c 'name = "r41-web"' Cargo.lock)" "0"
  git add Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture /usr/bin/time -p git commit -qm "refactor: drop the web member"
  expect "$label/E1i" "manifest and pruned lock both staged: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/E1i" "hook ran Cargo on the repaired commit" "$CMD" "$(spy_log)"
  record "$label/E1i" "repaired commit wall seconds real=$(real_seconds "$OUT")"

  ## Repo E2: leaf workspace-member removal, form 2 (git rm -r crates/web, deletions staged)
  E2=$(mk_repo repo-e2); cd "$E2"
  echo "--- repo E2: $E2"
  lock0=$(sha256_of Cargo.lock)
  drop_web_member; git rm -rq crates/web; git add Cargo.toml
  record "$label/E2.0" "staged (name-status): $(git diff --cached --name-status | tr '\t' ' ' | tr '\n' ';')"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/E2a" "revision-2 command: cargo metadata --locked passes with the member deleted (false pass)" 0 "$STATUS"; show "$OUT"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/E2b" "member deleted with git rm: direct check refuses (trigger sees the staged deletion)" 1 "$STATUS"; show "$OUT"
  expect_str "$label/E2b" "out-of-date message" "out of date" "$OUT"
  expect_not_str "$label/E2b" "trigger did not skip" "SKIP" "$OUT"
  expect_eq "$label/E2b" "Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of Cargo.lock)"
  capture git commit -qm "refactor: delete the web member"
  expect "$label/E2c" "member deleted with git rm: git commit blocked" 1 "$STATUS"; show "$OUT"
  expect_eq "$label/E2c" "no commit was created (rev-list count)" "$(git rev-list --count HEAD)" "1"
  capture cargo update --workspace
  expect "$label/E2d" "repair: cargo update --workspace" 0 "$STATUS"; show "$OUT"
  git add Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture git commit -qm "refactor: delete the web member"
  expect "$label/E2e" "manifest, deletions and pruned lock all staged: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/E2e" "hook ran Cargo on the repaired commit" "$CMD" "$(spy_log)"
  expect_eq "$label/E2e" "crates/web no longer in the tree" "$([ -e crates/web ] && echo present || echo absent)" "absent"
  expect_eq "$label/E2e" "orphan r41-web entry gone from the committed lock" "$(git show HEAD:Cargo.lock | grep -c 'name = "r41-web"')" "0"

  ## Repo E3: --no-verify bypass of the removal, --all, the lock-only repair commit, normalization, version = 3
  E3=$(mk_repo repo-e3); cd "$E3"
  echo "--- repo E3: $E3"
  drop_web_member; git add Cargo.toml
  capture git commit -q --no-verify -m "refactor: drop the web member bypassing the hook"
  expect "$label/E3a" "git commit --no-verify commits the orphan lock entry" 0 "$STATUS"; show "$OUT"
  lock0=$(sha256_of Cargo.lock)
  capture bash scripts/check-cargo-lock.sh
  expect "$label/E3b" "clean index, committed orphan: default mode skips (nothing staged)" 0 "$STATUS"; show "$OUT"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/E3c" "revision-2 CI command: cargo metadata --locked passes the committed orphan (false pass)" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/E3c2" "clean index, committed orphan: --all catches it" 1 "$STATUS"; show "$OUT"
  expect_str "$label/E3c2" "out-of-date message" "out of date" "$OUT"
  expect_eq "$label/E3c2" "committed lock left unchanged on disk (restored)" "$lock0" "$(sha256_of Cargo.lock)"
  capture cargo update --workspace
  expect "$label/E3d" "lock-only repair: cargo update --workspace prunes the committed orphan" 0 "$STATUS"; show "$OUT"
  record "$label/E3d" "$(lock_stat)"
  git add Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture git commit -qm "chore: prune Cargo.lock"
  expect "$label/E3d" "lock-only repair commit is accepted (it is the repair, not churn past the hook)" 0 "$STATUS"; show "$OUT"
  expect_str "$label/E3d" "hook ran Cargo on the lock-only commit" "$CMD" "$(spy_log)"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/E3e" "--all after the repair commit" 0 "$STATUS"; show "$OUT"
  printf '\n' >> Cargo.lock; git add Cargo.lock
  lock2=$(sha256_of Cargo.lock)
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/E4a" "normalization: lock with an extra trailing blank line passes --locked (parsed resolves equal)" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/E4b" "normalization: the script refuses it (Cargo would rewrite the file)" 1 "$STATUS"; show "$OUT"
  expect_str "$label/E4b" "one-line stat" "1 deletion(-)" "$OUT"
  expect_eq "$label/E4b" "staged lock bytes unchanged after refusal (restored from the index)" "$lock2" "$(sha256_of Cargo.lock)"
  git reset -q --hard HEAD
  rewrite Cargo.lock 's/^version = 4$/version = 3/'; git add Cargo.lock
  expect_eq "$label/E5" "lockfile rewritten to version = 3 and staged" "$(grep -c '^version = 3$' Cargo.lock)" "1"
  : > "$CARGO_SPY_LOG"
  capture git commit -qm "chore: lockfile version 3"
  expect "$label/E5" "version = 3 lockfile on a fresh graph: git commit (no false refusal from format migration)" 0 "$STATUS"; show "$OUT"
  expect_str "$label/E5" "hook ran Cargo" "$CMD" "$(spy_log)"
  expect_eq "$label/E5" "version line preserved after the guarded commit" "$(grep -c '^version = 3$' Cargo.lock)" "1"
  git rm -q Cargo.lock
  capture git commit -q --no-verify -m "chore: drop Cargo.lock bypassing the hook"
  expect "$label/E6" "no Cargo.lock in the repository (removed with --no-verify)" 0 "$STATUS"; show "$OUT"
  printf '# r41 trigger without a lockfile\n' >> Cargo.toml; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/E6a" "staged manifest with no lockfile: the resolve would create Cargo.lock -> refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/E6a" "created-lock message" "would create: Cargo.lock" "$OUT"
  expect_eq "$label/E6a" "created Cargo.lock removed again" "$([ -e Cargo.lock ] && echo present || echo absent)" "absent"
  expect_eq "$label/E6a" "worktree otherwise untouched (git status --short)" "$(git status --short | tr '\n' ';')" "M  Cargo.toml;"
  git reset -q --hard HEAD
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/E6b" "--all with no lockfile in the repository -> refused" 1 "$STATUS"; show "$OUT"
  expect_eq "$label/E6b" "created Cargo.lock removed again" "$([ -e Cargo.lock ] && echo present || echo absent)" "absent"

  ## Repo F: other change classes a build resolve would catch (each refused; alternatives compared)
  F=$(mk_repo repo-f); cd "$F"
  echo "--- repo F: $F"
  lock0=$(sha256_of Cargo.lock)
  rewrite Cargo.toml 's/^anyhow = "1"$/anyhow = "=1.0.100"/'; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/F1" "requirement change anyhow = \"=1.0.100\" (locked 1.0.104): refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/F1" "Cargo names the change" "Downgrading anyhow" "$OUT"
  expect_eq "$label/F1" "Cargo.lock bytes unchanged after refusal" "$lock0" "$(sha256_of Cargo.lock)"
  alt_vs_pick "$label/F1"
  git reset -q --hard HEAD
  rewrite Cargo.toml 's/^version = "0.1.0"$/version = "0.2.0"/'; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/F2" "workspace.package version bump 0.1.0 -> 0.2.0 (R23 case): refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/F2" "Cargo names the change" "Updating r41-core" "$OUT"
  expect_eq "$label/F2" "Cargo.lock bytes unchanged after refusal" "$lock0" "$(sha256_of Cargo.lock)"
  alt_vs_pick "$label/F2"
  git reset -q --hard HEAD
  rewrite crates/cli/Cargo.toml '/^anyhow.workspace = true$/d'; git add crates/cli/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/F3" "registry edge anyhow removed from crates/cli: refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/F3" "Cargo names the change" "Removing anyhow" "$OUT"
  expect_eq "$label/F3" "Cargo.lock bytes unchanged after refusal" "$lock0" "$(sha256_of Cargo.lock)"
  alt_vs_pick "$label/F3"
  git reset -q --hard HEAD
  printf 'this is not toml [\n' >> crates/cli/Cargo.toml; git add crates/cli/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/F4" "malformed member manifest: Cargo fails, its status propagates (validation could not complete)" 101 "$STATUS"; show "$OUT"
  expect_str "$label/F4" "Cargo diagnostic preserved" "failed to load manifest" "$OUT"
  expect_str "$label/F4" "could-not-complete message, not out-of-date" "could not complete" "$OUT"
  expect_not_str "$label/F4" "no out-of-date verdict on a Cargo failure" "out of date" "$OUT"
  expect_eq "$label/F4" "Cargo.lock bytes unchanged" "$lock0" "$(sha256_of Cargo.lock)"
  capture git commit -qm "chore: malformed manifest"
  expect "$label/F4" "malformed member manifest: git commit blocked" 1 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -2)"
  git reset -q --hard HEAD
  printf '\n[patch.crates-io]\nanyhow = { path = "%s" }\n' "$STUB" >> Cargo.toml; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/F5" "manifest-level [patch.crates-io] at the top level (stub anyhow outside the repository): refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/F5" "Cargo names the change" "Adding anyhow v1.0.104 (" "$OUT"
  expect_str "$label/F5" "lock diff stat shown" "Cargo.lock | 2 --" "$OUT"
  expect_eq "$label/F5" "Cargo.lock bytes unchanged after refusal" "$lock0" "$(sha256_of Cargo.lock)"
  capture cargo update --workspace
  expect "$label/F5" "repair: cargo update --workspace" 0 "$STATUS"; show "$OUT"
  git add Cargo.lock
  capture git commit -qm "chore: patch anyhow from a path"
  expect "$label/F5" "patched manifest and lock both staged: git commit" 0 "$STATUS"; show "$OUT"
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/F5" "--all after the patched commit" 0 "$STATUS"; show "$OUT"

  ## Repo G: independent workspaces beneath the top level (empirical audit r3, F1)
  G=$(mk_repo repo-g); cd "$G"; Gp=$(pwd -P)
  echo "--- repo G: $G"
  mkdir -p nested/src; printf '[package]\nname = "nested"\nversion = "0.1.0"\nedition = "2024"\n\n[dependencies]\nanyhow = "1"\n\n[workspace]\n' > nested/Cargo.toml; echo 'fn main() {}' > nested/src/main.rs
  capture bash -c 'cd nested && cargo update --workspace'
  expect "$label/G0" "setup: nested independent workspace (own [workspace] table) gets its own Cargo.lock" 0 "$STATUS"; show "$OUT"
  mkdir -p vendored/foo/src; printf '[package]\nname = "foo"\nversion = "0.1.0"\nedition = "2021"\n' > vendored/foo/Cargo.toml; echo 'pub fn f() {}' > vendored/foo/src/lib.rs
  printf '# This file is automatically @generated by Cargo.\n# It is not intended for manual editing.\nversion = 4\n\n[[package]]\nname = "foo"\nversion = "0.1.0"\n' > vendored/foo/Cargo.lock
  mkdir -p tools/standalone/src; printf '[package]\nname = "standalone"\nversion = "0.1.0"\nedition = "2024"\n\n[dependencies]\nanyhow = "1"\n' > tools/standalone/Cargo.toml; echo 'fn main() {}' > tools/standalone/src/main.rs
  rewrite Cargo.toml 's/^resolver = "3"$/resolver = "3"\
exclude = ["tools\/standalone"]/'
  capture bash -c 'cd tools/standalone && cargo update --workspace'
  expect "$label/G0" "setup: excluded standalone package gets its own Cargo.lock" 0 "$STATUS"; show "$OUT"
  mkdir -p tmpl; printf '[package]\nname = "{{project-name}}"\nversion = "0.1.0"\n\n[workspace]\n' > tmpl/Cargo.toml
  git add -A
  record "$label/G0" "tracked lockfiles: $(git ls-files --cached -- ':(glob)**/Cargo.lock' | tr '\n' ' '); exclude line: $(grep '^exclude' Cargo.toml)"
  : > "$CARGO_SPY_LOG"
  capture /usr/bin/time -p git commit -qm "chore: add nested, vendored, excluded and template manifests"
  expect "$label/G0" "setup commit through the hook (three workspace roots, two skipped candidates)" 0 "$STATUS"; show "$OUT"
  expect_str "$label/G0" "vendored non-member and template manifest skipped" "note: 2 candidate manifest(s) skipped" "$OUT"
  expect_str "$label/G0" "nested root resolved from its own directory" "cargo update --workspace (cwd $Gp/nested)" "$(spy_log)"
  expect_str "$label/G0" "excluded standalone root resolved from its own directory" "cargo update --workspace (cwd $Gp/tools/standalone)" "$(spy_log)"
  expect_not_str "$label/G0" "vendored package not resolved (locate-project only)" "cargo update --workspace (cwd $Gp/vendored/foo)" "$(spy_log)"
  expect_not_str "$label/G0" "template manifest not resolved (locate-project only)" "cargo update --workspace (cwd $Gp/tmpl)" "$(spy_log)"
  expect_str "$label/G0" "vendored candidate was asked, and rejected by, Cargo" "cargo locate-project --workspace --message-format plain --manifest-path vendored/foo/Cargo.toml" "$(spy_log)"
  expect_eq "$label/G0" "resolves run (update --workspace invocations)" "$(grep -c 'cargo update --workspace' "$CARGO_SPY_LOG")" "3"
  record "$label/G0" "guarded setup commit wall seconds real=$(real_seconds "$OUT") (three roots resolved, four locate-project calls)"
  lock0=$(sha256_of nested/Cargo.lock); lock2=$(sha256_of vendored/foo/Cargo.lock)
  rewrite nested/Cargo.toml 's/^anyhow = "1"$/anyhow = "=1.0.100"/'; git add nested/Cargo.toml
  capture cargo update --workspace
  expect "$label/G1a" "revision-3 command from the top level: root-only cargo update --workspace passes" 0 "$STATUS"; show "$OUT"
  capture git diff --quiet --no-ext-diff -- nested/Cargo.lock
  expect "$label/G1a" "nested Cargo.lock untouched by the root resolve (the false pass)" 0 "$STATUS"
  capture bash -c 'cargo metadata --locked --format-version=1 >/dev/null'
  expect "$label/G1b" "cargo metadata --locked from the top level passes the stale nested workspace" 0 "$STATUS"; show "$OUT"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/G1c" "stale nested independent workspace (anyhow = \"=1.0.100\", lock at 1.0.104): direct check refuses" 1 "$STATUS"; show "$OUT"
  expect_str "$label/G1c" "Cargo names the change" "Downgrading anyhow" "$OUT"
  expect_str "$label/G1c" "nested lock diff stat shown" "nested/Cargo.lock |" "$OUT"
  expect_str "$label/G1c" "nested root resolved from its own directory" "cargo update --workspace (cwd $Gp/nested)" "$(spy_log)"
  expect_eq "$label/G1c" "nested Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of nested/Cargo.lock)"
  capture git commit -qm "chore: pin anyhow in nested"
  expect "$label/G1d" "stale nested workspace: git commit blocked" 1 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -1)"
  expect_eq "$label/G1d" "no commit was created (rev-list count)" "$(git rev-list --count HEAD)" "2"
  capture bash -c 'cd nested && cargo update --workspace'
  expect "$label/G1e" "repair in the nested workspace: cargo update --workspace" 0 "$STATUS"; show "$OUT"
  record "$label/G1e" "$(git diff --stat --no-ext-diff -- nested/Cargo.lock | tail -1 | sed 's/^ *//')"
  git add nested/Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture git commit -qm "chore: pin anyhow in nested"
  expect "$label/G1f" "nested manifest and lock both staged: git commit" 0 "$STATUS"; show "$OUT"
  expect_str "$label/G1f" "top-level root resolved from the top level" "cargo update --workspace (cwd $Gp)" "$(spy_log)"
  expect_str "$label/G1f" "nested root resolved from its own directory" "cargo update --workspace (cwd $Gp/nested)" "$(spy_log)"
  printf '# r41 root trigger with vendored lock present\n' >> Cargo.toml; git add Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/G2" "vendored non-member package with its own Cargo.lock: no false refusal" 0 "$STATUS"; show "$OUT"
  expect_eq "$label/G2" "vendored Cargo.lock bytes unchanged" "$lock2" "$(sha256_of vendored/foo/Cargo.lock)"
  git reset -q --hard HEAD
  lock0=$(sha256_of tools/standalone/Cargo.lock)
  rewrite tools/standalone/Cargo.toml 's/^anyhow = "1"$/anyhow = "=1.0.100"/'; git add tools/standalone/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/G3" "stale excluded standalone package: refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/G3" "standalone lock diff stat shown" "tools/standalone/Cargo.lock |" "$OUT"
  expect_eq "$label/G3" "standalone Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of tools/standalone/Cargo.lock)"
  git reset -q --hard HEAD

  ## Repo H: configuration context of nested roots (judgment audit r4, F1 and O1) and a config below a root
  H=$(mk_repo repo-h); cd "$H"; Hp=$(pwd -P)
  echo "--- repo H: $H"
  mkdir -p nested/src; printf '[package]\nname = "nested"\nversion = "0.1.0"\nedition = "2024"\n\n[dependencies]\nanyhow = "1"\n\n[workspace]\n' > nested/Cargo.toml; echo 'fn main() {}' > nested/src/main.rs
  capture bash -c 'cd nested && cargo update --workspace'
  expect "$label/H0" "setup: nested independent workspace gets its own Cargo.lock" 0 "$STATUS"; show "$OUT"
  git add -A
  capture git commit -qm "chore: add nested workspace"
  expect "$label/H0" "setup commit through the hook" 0 "$STATUS"; show "$OUT"
  lock0=$(sha256_of nested/Cargo.lock)
  mkdir -p nested/.cargo; printf '[patch.crates-io]\nanyhow = { path = "%s" }\n' "$STUB" > nested/.cargo/config.toml; git add nested/.cargo/config.toml
  capture cargo update --workspace --manifest-path nested/Cargo.toml
  expect "$label/H1a" "revision-4 resolve (top-level cwd, --manifest-path): passes the stale nested lock, config not applied" 0 "$STATUS"; show "$OUT"
  expect_eq "$label/H1a" "nested Cargo.lock untouched by the top-level-cwd resolve (the false pass)" "$lock0" "$(sha256_of nested/Cargo.lock)"
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/H1b" "nested/.cargo/config.toml with [patch.crates-io] staged, nested lock in registry form: refused" 1 "$STATUS"; show "$OUT"
  expect_str "$label/H1b" "Cargo names the change" "Adding anyhow v1.0.104 (" "$OUT"
  expect_str "$label/H1b" "nested lock diff stat shown" "nested/Cargo.lock | 2 --" "$OUT"
  expect_str "$label/H1b" "nested root resolved from its own directory" "cargo update --workspace (cwd $Hp/nested)" "$(spy_log)"
  expect_eq "$label/H1b" "nested Cargo.lock bytes unchanged after refusal (restored)" "$lock0" "$(sha256_of nested/Cargo.lock)"
  capture git commit -qm "chore: patch anyhow in nested"
  expect "$label/H1c" "stale state: git commit blocked" 1 "$STATUS"; show "$(printf '%s\n' "$OUT" | tail -1)"
  expect_eq "$label/H1c" "no commit was created (rev-list count)" "$(git rev-list --count HEAD)" "2"
  capture bash -c 'cd nested && cargo update --workspace'
  expect "$label/H2a" "repair per remediation, in the nested directory" 0 "$STATUS"; show "$OUT"
  lock1=$(sha256_of nested/Cargo.lock)
  record "$label/H2a" "$(git diff --stat --no-ext-diff -- nested/Cargo.lock | tail -1 | sed 's/^ *//'); patched nested lock sha256=$lock1"
  git add nested/Cargo.lock
  : > "$CARGO_SPY_LOG"
  capture bash scripts/check-cargo-lock.sh
  expect "$label/H2b" "freshly-resolved state (config and patched lock staged): accepted" 0 "$STATUS"; show "$OUT"
  expect_str "$label/H2b" "nested root resolved from its own directory" "cargo update --workspace (cwd $Hp/nested)" "$(spy_log)"
  expect_eq "$label/H2b" "patched nested lock untouched" "$lock1" "$(sha256_of nested/Cargo.lock)"
  capture git commit -qm "chore: patch anyhow in nested"
  expect "$label/H2c" "freshly-resolved state: git commit" 0 "$STATUS"; show "$OUT"
  capture cargo update --workspace --manifest-path nested/Cargo.toml
  expect "$label/H2d" "revision-4 resolve on the committed patched state: config not applied, lock rewritten (the false refusal)" 0 "$STATUS"; show "$OUT"
  record "$label/H2d" "$(git diff --stat --no-ext-diff -- nested/Cargo.lock | tail -1 | sed 's/^ *//')"
  expect_eq "$label/H2d" "top-level-cwd resolve changed the patched nested lock" "$([ "$lock1" != "$(sha256_of nested/Cargo.lock)" ] && echo changed || echo unchanged)" "changed"
  git checkout --quiet -- nested/Cargo.lock
  capture bash scripts/check-cargo-lock.sh --all
  expect "$label/H2e" "--all on the committed patched state" 0 "$STATUS"; show "$OUT"
  mkdir -p ignored/src; printf '[package]\nname = "ignored"\nversion = "0.1.0"\nedition = "2024"\n\n[dependencies]\nanyhow = "1"\n\n[workspace]\n' > ignored/Cargo.toml; echo 'fn main() {}' > ignored/src/main.rs; printf 'Cargo.lock\n' > ignored/.gitignore
  capture bash -c 'cd ignored && cargo update --workspace'
  expect "$label/H3" "setup: nested root whose Cargo.lock is Git-ignored" 0 "$STATUS"; show "$OUT"
  git add ignored
  : > "$CARGO_SPY_LOG"
  capture git commit -qm "chore: add a workspace with an ignored lockfile"
  expect "$label/H3a" "setup commit through the hook" 0 "$STATUS"; show "$OUT"
  expect_str "$label/H3a" "ignored-lock note" "ignored/Cargo.lock is Git-ignored; that workspace is not checked" "$OUT"
  expect_not_str "$label/H3a" "ignored root not resolved" "cargo update --workspace (cwd $Hp/ignored)" "$(spy_log)"
  lock2=$(sha256_of ignored/Cargo.lock)
  rewrite ignored/Cargo.toml 's/^anyhow = "1"$/anyhow = "=1.0.100"/'; git add ignored/Cargo.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/H3b" "stale manifest of the ignored-lock workspace: passes vacuously (no lockfile in the repository)" 0 "$STATUS"; show "$OUT"
  expect_eq "$label/H3b" "ignored Cargo.lock bytes unchanged on disk (no resolve ran, nothing written)" "$lock2" "$(sha256_of ignored/Cargo.lock)"
  git reset -q --hard HEAD
  lock3=$(sha256_of Cargo.lock)
  mkdir -p crates/cli/.cargo; printf '[patch.crates-io]\nanyhow = { path = "%s" }\n' "$STUB" > crates/cli/.cargo/config.toml; git add crates/cli/.cargo/config.toml
  capture bash scripts/check-cargo-lock.sh
  expect "$label/H4a" "crates/cli/.cargo/config.toml with [patch.crates-io] (below the root): not applied, passes with a note" 0 "$STATUS"; show "$OUT"
  expect_str "$label/H4a" "unapplied-config note names the file" "not applied by this check (Cargo reads it only for commands run inside that directory): crates/cli/.cargo/config.toml" "$OUT"
  expect_eq "$label/H4a" "root Cargo.lock bytes unchanged" "$lock3" "$(sha256_of Cargo.lock)"
  capture bash -c 'cd crates/cli && cargo update --workspace'
  expect "$label/H4b" "disclosed limit: the same resolve run inside crates/cli applies the config and rewrites the root lock" 0 "$STATUS"; show "$OUT"
  record "$label/H4b" "$(git diff --stat --no-ext-diff -- Cargo.lock | tail -1 | sed 's/^ *//')"
  expect_eq "$label/H4b" "root Cargo.lock changed by the in-member resolve" "$([ "$lock3" != "$(sha256_of Cargo.lock)" ] && echo changed || echo unchanged)" "changed"
  git reset -q --hard HEAD
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
