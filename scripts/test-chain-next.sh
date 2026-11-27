#!/usr/bin/env bash
# Offline regression suite for scripts/chain-next.sh.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${REPO_ROOT}/scripts/chain-next.sh"

PASS=0
FAIL=0

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

assert_exit() {
    local name="$1" expected="$2" actual="$3" output="$4"
    if [ "$actual" -eq "$expected" ]; then
        echo "PASS: ${name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${name} (expected exit ${expected}, got ${actual})" >&2
        echo "$output" >&2
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local name="$1" needle="$2" haystack="$3"
    if printf '%s\n' "$haystack" | grep -Fq -- "$needle"; then
        echo "PASS: ${name}"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ${name} (missing '${needle}')" >&2
        echo "$haystack" >&2
        FAIL=$((FAIL + 1))
    fi
}

make_fixture() {
    local dir="$1"
    mkdir -p "${dir}/projects"
    git -C "$dir" init -b main --quiet
    git -C "$dir" config user.email "test@example.com"
    git -C "$dir" config user.name "Test User"
    cat > "${dir}/PROJECTS.md" <<'EOF'
# Projects

## Project index

- [x] **P01** — [Alpha](projects/P01-alpha.md) — done
- [~] **P02** — [Beta](projects/P02-beta.md) — in progress
- [ ] **P03** — [Gamma](projects/P03-gamma.md) — scoped
EOF
    cat > "${dir}/projects/P01-alpha.md" <<'EOF'
# P01 — Alpha

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
EOF
    cat > "${dir}/projects/P02-beta.md" <<'EOF'
# P02 — Beta

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Depends on:** P01
EOF
    cat > "${dir}/projects/P03-gamma.md" <<'EOF'
# P03 — Gamma

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Depends on:** P02
EOF
    git -C "$dir" add -A
    git -C "$dir" commit -m "chore: init fixture" --quiet
}

# Case 1: pause sentinel exits 0 cleanly
f1="${TMP_ROOT}/f1"
make_fixture "$f1"
touch "${f1}/.chain-pause"
set +e
out="$(bash "$SCRIPT" --repo "$f1" --session session:test --worktree-root "${TMP_ROOT}/wt1" --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "pause sentinel exits 0" 0 "$rc" "$out"
assert_contains "pause sentinel prints PAUSED" "PAUSED:" "$out"

# Case 2: dirty main checkout refused with exit 2
f2="${TMP_ROOT}/f2"
make_fixture "$f2"
echo "dirty" >> "${f2}/PROJECTS.md"
set +e
out="$(bash "$SCRIPT" --repo "$f2" --session session:test --worktree-root "${TMP_ROOT}/wt2" --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "dirty main refused" 2 "$rc" "$out"
assert_contains "dirty main message" "uncommitted changes" "$out"

# Case 3: auto-selects P02 ([~]) when P01 is [x]
f3="${TMP_ROOT}/f3"
make_fixture "$f3"
set +e
out="$(bash "$SCRIPT" --repo "$f3" --session session:test123 --worktree-root "${TMP_ROOT}/wt3" --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "dry-run P02 exits 0" 0 "$rc" "$out"
assert_contains "selects P02" "P02 — Beta" "$out"
assert_contains "uses agy --dangerously-skip-permissions" "agy --dangerously-skip-permissions" "$out"
assert_contains "uses provided session" "session:test123" "$out"

# Case 4: explicit P03 refused because Depends on P02 is still [~]
set +e
out="$(bash "$SCRIPT" --repo "$f3" --session session:test123 --worktree-root "${TMP_ROOT}/wt3" --project P03 --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "unmet dependency refused" 2 "$rc" "$out"
assert_contains "mentions unmet P02" "P02 (glyph [~])" "$out"

# Case 5: when all projects are [x], exits 0 with COMPLETE
f5="${TMP_ROOT}/f5"
make_fixture "$f5"
cat > "${f5}/PROJECTS.md" <<'EOF'
# Projects

## Project index

- [x] **P01** — [Alpha](projects/P01-alpha.md) — done
- [x] **P02** — [Beta](projects/P02-beta.md) — done
- [x] **P03** — [Gamma](projects/P03-gamma.md) — done
EOF
git -C "$f5" add PROJECTS.md
git -C "$f5" commit -m "docs: mark all done" --quiet
set +e
out="$(bash "$SCRIPT" --repo "$f5" --session session:test123 --worktree-root "${TMP_ROOT}/wt5" --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "all done exits 0" 0 "$rc" "$out"
assert_contains "prints COMPLETE" "COMPLETE:" "$out"

# Case 6: P03 branch convention (ci/difftree-pr-comment) when P02 is [x]
f6="${TMP_ROOT}/f6"
make_fixture "$f6"
cat > "${f6}/PROJECTS.md" <<'EOF'
# Projects

## Project index

- [x] **P01** — [Alpha](projects/P01-alpha.md) — done
- [x] **P02** — [Beta](projects/P02-beta.md) — done
- [ ] **P03** — [Gamma](projects/P03-gamma.md) — scoped
EOF
git -C "$f6" add PROJECTS.md
git -C "$f6" commit -m "docs: mark P02 done" --quiet
set +e
out="$(bash "$SCRIPT" --repo "$f6" --session session:test123 --worktree-root "${TMP_ROOT}/wt6" --dry-run --skip-remote-check 2>&1)"
rc=$?
set -e
assert_exit "P03 ready exits 0" 0 "$rc" "$out"
assert_contains "P03 uses ci/difftree-pr-comment branch" "branch:   ci/difftree-pr-comment" "$out"

echo "${PASS} passed, ${FAIL} failed"
[ "$FAIL" -eq 0 ]
