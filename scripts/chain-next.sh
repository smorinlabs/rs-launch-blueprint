#!/usr/bin/env bash
# Launch the next incomplete project in PROJECTS.md as a serial agy session
# inside the shared rs-launch-blueprint Rex session.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/chain-next.sh [options]

Options:
  --repo DIR            Canonical main checkout path (default: current git common repo root)
  --session ID          Rex session ID (default: $REX_SESSION, else session labeled rs-launch-blueprint)
  --worktree-root DIR   Parent directory for phase worktrees (default: $HOME/wt/rs-launch-blueprint)
  --project PNN         Explicit project ID to launch (default: first [~] or [ ] row in PROJECTS.md)
  --branch NAME         Override git branch name for the new worktree
  --pause-file PATH     Pause sentinel path (default: <repo>/.chain-pause)
  --effort LEVEL        Optional agy --effort flag (low|medium|high|xhigh|max)
  --model NAME          Optional agy --model flag
  --dry-run             Run all guards and print the launch plan without mutating git or Rex
  --skip-remote-check   Skip gh open-PR check and git fetch (for offline tests only)
  -h, --help            Show this help message
EOF
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

refuse() {
    echo "REFUSED: $*" >&2
    exit 2
}

resolve_default_repo() {
    local common_dir
    if common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"; then
        dirname "$common_dir"
    else
        pwd
    fi
}

resolve_rex_session() {
    if [ -n "${REX_SESSION:-}" ]; then
        printf '%s\n' "$REX_SESSION"
        return 0
    fi
    command -v rex >/dev/null 2>&1 || die "rex CLI not found on PATH; pass --session explicitly"
    python3 - <<'PY'
import json, subprocess, sys
proc = subprocess.run(["rex", "ls", "--json"], capture_output=True, text=True)
if proc.returncode != 0:
    sys.stderr.write(proc.stderr or "rex ls --json failed\n")
    sys.exit(1)
data = json.loads(proc.stdout)
for s in data.get("sessions", []):
    if s.get("label") == "rs-launch-blueprint":
        print(s["session_id"])
        sys.exit(0)
sys.stderr.write("no Rex session labeled 'rs-launch-blueprint' found; pass --session explicitly\n")
sys.exit(1)
PY
}

REPO=""
SESSION=""
WORKTREE_ROOT="${HOME}/wt/rs-launch-blueprint"
EXPLICIT_PROJECT=""
EXPLICIT_BRANCH=""
PAUSE_FILE=""
EFFORT=""
MODEL=""
DRY_RUN=0
SKIP_REMOTE=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --repo)
            [ "$#" -ge 2 ] || die "--repo requires a value"
            REPO="$2"
            shift 2
            ;;
        --session)
            [ "$#" -ge 2 ] || die "--session requires a value"
            SESSION="$2"
            shift 2
            ;;
        --worktree-root)
            [ "$#" -ge 2 ] || die "--worktree-root requires a value"
            WORKTREE_ROOT="$2"
            shift 2
            ;;
        --project)
            [ "$#" -ge 2 ] || die "--project requires a value"
            EXPLICIT_PROJECT="$2"
            shift 2
            ;;
        --branch)
            [ "$#" -ge 2 ] || die "--branch requires a value"
            EXPLICIT_BRANCH="$2"
            shift 2
            ;;
        --pause-file)
            [ "$#" -ge 2 ] || die "--pause-file requires a value"
            PAUSE_FILE="$2"
            shift 2
            ;;
        --effort)
            [ "$#" -ge 2 ] || die "--effort requires a value"
            EFFORT="$2"
            shift 2
            ;;
        --model)
            [ "$#" -ge 2 ] || die "--model requires a value"
            MODEL="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --skip-remote-check)
            SKIP_REMOTE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[ -n "$REPO" ] || REPO="$(resolve_default_repo)"
[ -d "$REPO" ] || die "repo directory does not exist: $REPO"
REPO="$(cd "$REPO" && pwd -P)"
[ -n "$PAUSE_FILE" ] || PAUSE_FILE="${REPO}/.chain-pause"

# 1. Pause sentinel check (clean exit 0 so callers know the chain paused intentionally)
if [ -e "$PAUSE_FILE" ]; then
    echo "PAUSED: sentinel exists at ${PAUSE_FILE}; not launching next phase."
    exit 0
fi

# 2. Verify canonical checkout is clean and on main
current_branch="$(git -C "$REPO" rev-parse --abbrev-ref HEAD)"
[ "$current_branch" = "main" ] || refuse "main checkout ${REPO} is on '${current_branch}', expected 'main'"

dirty="$(git -C "$REPO" status --porcelain)"
[ -z "$dirty" ] || refuse "main checkout ${REPO} has uncommitted changes"

if [ "$SKIP_REMOTE" -eq 0 ]; then
    command -v gh >/dev/null 2>&1 || die "gh CLI not found on PATH"
    # Single-flight guard: refuse if any PR is currently open
    open_prs="$(gh pr list --repo smorinlabs/rs-launch-blueprint --state open --json number,title,headRefName --jq 'length')"
    if [ "$open_prs" -gt 0 ]; then
        gh pr list --repo smorinlabs/rs-launch-blueprint --state open >&2
        refuse "${open_prs} open PR(s) exist on smorinlabs/rs-launch-blueprint; finish/merge before advancing chain"
    fi

    git -C "$REPO" fetch origin main --quiet
    local_sha="$(git -C "$REPO" rev-parse HEAD)"
    remote_sha="$(git -C "$REPO" rev-parse origin/main)"
    if [ "$local_sha" != "$remote_sha" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            if git -C "$REPO" merge-base --is-ancestor "$local_sha" "$remote_sha"; then
                echo "NOTE: main (${local_sha:0:8}) is behind origin/main (${remote_sha:0:8}) and can fast-forward."
            else
                refuse "main (${local_sha:0:8}) has diverged from origin/main (${remote_sha:0:8})"
            fi
        else
            git -C "$REPO" pull --ff-only origin main --quiet || refuse "failed to fast-forward main to origin/main"
        fi
    fi
fi

# 3. Parse PROJECTS.md to pick target project and verify dependencies
PROJECTS_MD="${REPO}/PROJECTS.md"
[ -f "$PROJECTS_MD" ] || die "PROJECTS.md not found at ${PROJECTS_MD}"

eval_output="$(
python3 - "$REPO" "$EXPLICIT_PROJECT" <<'PY'
import pathlib, re, shlex, sys

repo = pathlib.Path(sys.argv[1])
explicit = sys.argv[2]
trunk_text = (repo / "PROJECTS.md").read_text(encoding="utf-8")

row_re = re.compile(
    r"^- \[(?P<glyph>[ x~?>-])\] \*\*(?P<pid>P\d+[a-z]?)\*\* — \[(?P<title>[^\]]+)\]\((?P<rel>[^)]+)\)"
)

rows = []
by_id = {}
for line in trunk_text.splitlines():
    m = row_re.match(line.strip())
    if m:
        entry = m.groupdict()
        rows.append(entry)
        by_id[entry["pid"]] = entry

if not rows:
    sys.stderr.write("ERROR: no project rows parsed from PROJECTS.md\n")
    sys.exit(1)

target = None
if explicit:
    if explicit not in by_id:
        sys.stderr.write(f"ERROR: project {explicit} not found in PROJECTS.md\n")
        sys.exit(1)
    target = by_id[explicit]
    if target["glyph"] in ("x", "-", ">"):
        sys.stderr.write(f"REFUSED: project {explicit} already has terminal glyph [{target['glyph']}]\n")
        sys.exit(2)
else:
    for r in rows:
        if r["glyph"] in ("~", " "):
            target = r
            break

if target is None:
    print("CHAIN_STATUS=COMPLETE")
    sys.exit(0)

pfile = repo / target["rel"]
if not pfile.is_file():
    sys.stderr.write(f"ERROR: project file missing: {pfile}\n")
    sys.exit(1)

ptext = pfile.read_text(encoding="utf-8")
unmet = []
for line in ptext.splitlines():
    m = re.match(r"^- \*\*Depends on:\*\*\s*(.+)$", line.strip())
    if m:
        for dep in re.findall(r"P\d+[a-z]?", m.group(1)):
            if dep not in by_id:
                unmet.append(f"{dep} (missing from PROJECTS.md)")
            elif by_id[dep]["glyph"] != "x":
                unmet.append(f"{dep} (glyph [{by_id[dep]['glyph']}])")

if unmet:
    sys.stderr.write(
        f"REFUSED: {target['pid']} has unmet dependencies: {', '.join(unmet)}\n"
    )
    sys.exit(2)

slug = re.sub(r"^P\d+[a-z]?-", "", pathlib.Path(target["rel"]).stem)
pid_lower = target["pid"].lower()

if target["pid"] == "P02":
    default_branch = "docs/p02-research-closeout"
elif target["pid"] == "P03":
    default_branch = "ci/difftree-pr-comment"
else:
    short_slug = "-".join(slug.split("-")[:4])
    default_branch = f"feat/{pid_lower}-{short_slug}"

wt_dir_name = default_branch.replace("/", "-")
tab_label = f"{target['pid']}-{'-'.join(slug.split('-')[:2])}"

print("CHAIN_STATUS=READY")
print(f"TARGET_PID={shlex.quote(target['pid'])}")
print(f"TARGET_GLYPH={shlex.quote(target['glyph'])}")
print(f"TARGET_TITLE={shlex.quote(target['title'])}")
print(f"TARGET_REL={shlex.quote(target['rel'])}")
print(f"DEFAULT_BRANCH={shlex.quote(default_branch)}")
print(f"WT_DIR_NAME={shlex.quote(wt_dir_name)}")
print(f"TAB_LABEL={shlex.quote(tab_label)}")
PY
)" || exit "$?"

eval "$eval_output"

if [ "${CHAIN_STATUS:-}" = "COMPLETE" ]; then
    echo "COMPLETE: all scoped projects in ${PROJECTS_MD} are done."
    exit 0
fi

BRANCH="${EXPLICIT_BRANCH:-$DEFAULT_BRANCH}"
if [ -n "$EXPLICIT_BRANCH" ]; then
    WT_DIR_NAME="${EXPLICIT_BRANCH//\//-}"
fi
WORKTREE_PATH="${WORKTREE_ROOT}/${WT_DIR_NAME}"

# 4. Guard against existing worktree or branch collision
if [ -e "$WORKTREE_PATH" ]; then
    refuse "worktree path already exists: ${WORKTREE_PATH}"
fi
if git -C "$REPO" show-ref --verify --quiet "refs/heads/${BRANCH}"; then
    refuse "local branch already exists: ${BRANCH}"
fi

# 5. Resolve Rex session
if [ -z "$SESSION" ]; then
    if [ "$DRY_RUN" -eq 1 ] && ! command -v rex >/dev/null 2>&1; then
        SESSION="session:unresolved-dry-run"
    else
        SESSION="$(resolve_rex_session)"
    fi
fi

# 6. Build self-contained phase brief for agy
read -r -d '' BRIEF <<EOF || true
Execute ${TARGET_PID} — ${TARGET_TITLE} in the rs-launch-blueprint serial Rex chain.

Context & locations:
- Project ID: ${TARGET_PID} (current glyph: [${TARGET_GLYPH}])
- Project file: ${TARGET_REL}
- Worktree (your cwd): ${WORKTREE_PATH}
- Branch: ${BRANCH} (branched from origin/main)
- Canonical main checkout: ${REPO}
- Shared Rex session: ${SESSION}

Mandatory first reads (in order):
1. AGENTS.md
2. docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md
3. docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md
4. ${TARGET_REL}
5. Every research/topics/*/DECISION.md item referenced by ${TARGET_REL}

Execution protocol (follow the Rex Serial Chain Execution Contract strictly):
1. Complete every [TS] and [T] task in ${TARGET_REL} using TDD where applicable, flipping each task checkbox to [x] as it lands.
2. Run all applicable repo validation gates (bash scripts/check-shell.sh, bash scripts/test-check-shell.sh, bash scripts/test-chain-next.sh, bash scripts/check-research-tree.sh --require-owner-review, plus just check / cargo gates once P04 lands) and verify all 11 project-audit checks pass.
3. Flip ${TARGET_PID} in PROJECTS.md to [x], commit cleanly with Conventional Commits, push ${BRANCH}, and open a PR targeting main.
4. Run full pr-merge-flow (--auto mode): wait for CI and reviewer bots, triage and resolve every review thread with verification evidence, fix in-scope findings, and merge with --merge --match-head-commit (NEVER --squash; repo ruleset forbids squash merges). Verify gh pr view reports state MERGED.
5. cd ${REPO}, verify clean main, run git pull --ff-only origin main, confirm the merge commit is in HEAD and PROJECTS.md marks ${TARGET_PID} as [x], remove worktree ${WORKTREE_PATH}, and delete local and remote branch ${BRANCH}.
6. ONLY AFTER verified merge, sync, and cleanup, advance the chain by running:
   bash ${REPO}/scripts/chain-next.sh --repo ${REPO} --session ${SESSION}
7. Hard-stop rule: if you hit an unrecoverable CI failure, escalated architectural thread, missing human-only prerequisite, or unapproved OVERRIDE, write a handoff note to docs/handoffs/ and STOP without merging or calling chain-next.sh.
EOF

USER_SHELL="${SHELL:-/bin/zsh}"
# Literal inner-shell command passed to `$USER_SHELL -ilc` so "$@" runs the agent
# and then drops into an interactive login shell instead of closing the Rex tab.
# shellcheck disable=SC2016
SHELL_FALLBACK='"$@"; exec "$0" -il'
AGY_CMD=(agy --dangerously-skip-permissions)
if [ -n "$EFFORT" ]; then
    AGY_CMD+=(--effort "$EFFORT")
fi
if [ -n "$MODEL" ]; then
    AGY_CMD+=(--model "$MODEL")
fi
AGY_CMD+=(-i "$BRIEF")

BASE_REF="origin/main"
if [ "$SKIP_REMOTE" -eq 1 ] && ! git -C "$REPO" rev-parse --verify --quiet origin/main >/dev/null; then
    BASE_REF="main"
fi

if [ "$DRY_RUN" -eq 1 ]; then
    echo "DRY-RUN: next phase ready"
    echo "  project:  ${TARGET_PID} — ${TARGET_TITLE} (${TARGET_REL})"
    echo "  base:     ${BASE_REF}"
    echo "  branch:   ${BRANCH}"
    echo "  worktree: ${WORKTREE_PATH}"
    echo "  session:  ${SESSION}"
    echo "  tab:      ${TAB_LABEL}"
    printf '  git cmd:  git -C %q worktree add -b %q %q %q\n' "$REPO" "$BRANCH" "$WORKTREE_PATH" "$BASE_REF"
    printf '  rex cmd:  rex window new -s %q %q -c %q --focus=false --shell=none --json -- %q -ilc %q %q' \
        "$SESSION" "$TAB_LABEL" "$WORKTREE_PATH" "$USER_SHELL" "$SHELL_FALLBACK" "$USER_SHELL"
    for tok in "${AGY_CMD[@]}"; do
        if [ "$tok" = "$BRIEF" ]; then
            printf ' <BRIEF:%d-chars>' "${#BRIEF}"
        else
            printf ' %q' "$tok"
        fi
    done
    printf '\n'
    exit 0
fi

command -v rex >/dev/null 2>&1 || die "rex CLI not found on PATH"
command -v agy >/dev/null 2>&1 || die "agy CLI not found on PATH"

mkdir -p "$WORKTREE_ROOT"
git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE_PATH" "$BASE_REF"

launch_json="$(
    rex window new \
        -s "$SESSION" \
        "$TAB_LABEL" \
        -c "$WORKTREE_PATH" \
        --focus=false \
        --shell=none \
        --json -- \
        "$USER_SHELL" -ilc "$SHELL_FALLBACK" "$USER_SHELL" \
        "${AGY_CMD[@]}"
)"

echo "LAUNCHED: ${TARGET_PID} — ${TARGET_TITLE}"
echo "  worktree: ${WORKTREE_PATH}"
echo "  branch:   ${BRANCH}"
echo "  session:  ${SESSION}"
echo "  tab:      ${TAB_LABEL}"
echo "  rex:      ${launch_json}"
