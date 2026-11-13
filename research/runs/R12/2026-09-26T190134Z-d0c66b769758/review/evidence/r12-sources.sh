#!/usr/bin/env bash
# R12 revision-1 evidence: every external fact the DECISION depends on is
# fetched fresh here (Phase A) and asserted offline against snapshots (Phase B).
set -euo pipefail
export PATH="/Users/stevemorin/.local/bin:/opt/homebrew/bin:$PATH"

EV="$(cd "$(dirname "$0")" && pwd)"
SNAP="$EV/snapshots"
PROV="$SNAP/PROVENANCE.md"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/r12-sources.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "PASS $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL $1 -- $2"; }
info() { echo "INFO $1"; }

command -v gh >/dev/null || { bad "S-setup" "gh not on PATH"; exit 1; }
command -v curl >/dev/null || { bad "S-setup" "curl not on PATH"; exit 1; }
: >"$PROV"
echo "# Provenance — fetched fresh by S11 $(date -u +%FT%TZ)" >>"$PROV"

get_api() { # $1 snapshot-name, rest: gh api args (endpoint first)
  local name="$1"; shift
  gh api "$@" >"$SNAP/$name"
  echo "- $name <= gh api $* @ $(date -u +%FT%TZ)" >>"$PROV"
}
get_raw() { # $1 snapshot-name $2 url
  curl -fsSL --retry 2 --max-time 90 "$2" -o "$SNAP/$1"
  echo "- $1 <= $2 @ $(date -u +%FT%TZ)" >>"$PROV"
}

# ---------- Phase A1: docs pin + platform docs ----------
DOCS_SHA="$(gh api repos/github/docs/commits/main --jq .sha)"
info "github/docs@main = $DOCS_SHA"
echo "docs pin: $DOCS_SHA" >>"$PROV"
D="https://raw.githubusercontent.com/github/docs/$DOCS_SHA"
get_raw r12-troubleshooting-required-status-checks.md "$D/content/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks.md"
get_raw r12-about-protected-branches.md "$D/content/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches.md"
get_raw r12-available-rules-for-rulesets.md "$D/content/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets.md"
get_raw r12-status-checks-ref.md "$D/content/pull-requests/reference/status-checks.md"
get_raw r12-expressions.md "$D/content/actions/reference/workflows-and-actions/expressions.md"
get_raw r12-reusable-needs.md "$D/data/reusables/actions/jobs/section-using-jobs-in-a-workflow-needs.md"
get_raw r12-reusable-skipped.md "$D/data/reusables/actions/workflows/skipped-job-status-checks-passing.md"
get_raw r12-reusable-merge-group.md "$D/data/reusables/actions/merge-group-event-with-required-checks.md"
get_api r12-app-github-actions.json apps/github-actions

# ---------- Phase A2: runner inventory ----------
RI_SHA="$(gh api repos/actions/runner-images/commits/main --jq .sha)"
info "runner-images@main = $RI_SHA"
get_raw r12-Ubuntu2404-Readme.md "https://raw.githubusercontent.com/actions/runner-images/$RI_SHA/images/ubuntu/Ubuntu2404-Readme.md"

# ---------- Phase A3: third-party aggregator ----------
get_api r12-alls-green-repo.json repos/re-actors/alls-green
get_api r12-alls-green-release.json repos/re-actors/alls-green/releases/latest
get_api r12-alls-green-issues.json 'search/issues?q=repo:re-actors/alls-green+is:issue+is:open'
AG_REF="$(jq -r .default_branch "$SNAP/r12-alls-green-repo.json")"
A="https://raw.githubusercontent.com/re-actors/alls-green/$AG_REF"
get_raw r12-alls-green-README.md "$A/README.md"
get_raw r12-alls-green-action.yml "$A/action.yml"
get_raw r12-alls-green-job_outcome.py "$A/src/job_outcome.py"

# ---------- Phase A4: Rust practice (workflows at pinned shas + live rules) ----------
pin() { # $1 owner/repo -> prints "sha branch"
  local r="$1" b s
  b="$(gh api "repos/$r" --jq .default_branch)"
  s="$(gh api "repos/$r/commits/$b" --jq .sha)"
  echo "$s $b"
}
read -r CARGO_SHA CARGO_BR <<< "$(pin rust-lang/cargo)"
read -r RA_SHA RA_BR <<< "$(pin rust-lang/rust-analyzer)"
read -r UV_SHA UV_BR <<< "$(pin astral-sh/uv)"
read -r RUFF_SHA RUFF_BR <<< "$(pin astral-sh/ruff)"
read -r CLAP_SHA CLAP_BR <<< "$(pin clap-rs/clap)"
read -r TOKIO_SHA TOKIO_BR <<< "$(pin tokio-rs/tokio)"
read -r CLIPPY_SHA CLIPPY_BR <<< "$(pin rust-lang/rust-clippy)"
info "pins: cargo=$CARGO_SHA ra=$RA_SHA uv=$UV_SHA ruff=$RUFF_SHA clap=$CLAP_SHA tokio=$TOKIO_SHA clippy=$CLIPPY_SHA"
{
  echo "cargo $CARGO_SHA $CARGO_BR"; echo "rust-analyzer $RA_SHA $RA_BR"
  echo "uv $UV_SHA $UV_BR"; echo "ruff $RUFF_SHA $RUFF_BR"; echo "clap $CLAP_SHA $CLAP_BR"
  echo "tokio $TOKIO_SHA $TOKIO_BR"; echo "clippy $CLIPPY_SHA $CLIPPY_BR"
} >>"$PROV"
get_raw r12-cargo-main.yml "https://raw.githubusercontent.com/rust-lang/cargo/$CARGO_SHA/.github/workflows/main.yml"
get_raw r12-rust-analyzer-ci.yaml "https://raw.githubusercontent.com/rust-lang/rust-analyzer/$RA_SHA/.github/workflows/ci.yaml"
get_raw r12-uv-ci.yml "https://raw.githubusercontent.com/astral-sh/uv/$UV_SHA/.github/workflows/ci.yml"
get_raw r12-ruff-ci.yaml "https://raw.githubusercontent.com/astral-sh/ruff/$RUFF_SHA/.github/workflows/ci.yaml"
get_raw r12-clap-ci.yml "https://raw.githubusercontent.com/clap-rs/clap/$CLAP_SHA/.github/workflows/ci.yml"
get_api r12-cargo-repo.json "repos/rust-lang/cargo"
get_api r12-ra-repo.json "repos/rust-lang/rust-analyzer"
get_api r12-uv-repo.json "repos/astral-sh/uv"
get_api r12-tokio-repo.json "repos/tokio-rs/tokio"
get_api r12-cargo-rules.json "repos/rust-lang/cargo/rules/branches/$CARGO_BR"
get_api r12-ra-rules.json "repos/rust-lang/rust-analyzer/rules/branches/$RA_BR"
get_api r12-uv-rules.json "repos/astral-sh/uv/rules/branches/$UV_BR"
get_api r12-clippy-rules.json "repos/rust-lang/rust-clippy/rules/branches/$CLIPPY_BR"
get_api r12-tokio-branch.json "repos/tokio-rs/tokio/branches/$TOKIO_BR"
get_api r12-clap-branch.json "repos/clap-rs/clap/branches/$CLAP_BR"

# ---------- Phase A5: tokio list-sync on the latest merged PR ----------
TOKIO_PR_SHA="$(gh api "repos/tokio-rs/tokio/pulls?state=closed&sort=updated&direction=desc&per_page=10" --jq '[.[] | select(.merged_at != null)][0] | .head.sha')"
TOKIO_PR_NUM="$(gh api "repos/tokio-rs/tokio/pulls?state=closed&sort=updated&direction=desc&per_page=10" --jq '[.[] | select(.merged_at != null)][0] | .number')"
info "tokio latest merged PR #$TOKIO_PR_NUM head $TOKIO_PR_SHA"
echo "tokio sample: PR #$TOKIO_PR_NUM head $TOKIO_PR_SHA" >>"$PROV"
get_api r12-tokio-check-runs-p1.json "repos/tokio-rs/tokio/commits/$TOKIO_PR_SHA/check-runs?per_page=100"
TOTAL="$(jq -r .total_count "$SNAP/r12-tokio-check-runs-p1.json")"
if [ "$TOTAL" -gt 100 ]; then
  get_api r12-tokio-check-runs-p2.json "repos/tokio-rs/tokio/commits/$TOKIO_PR_SHA/check-runs?per_page=100&page=2"
fi

# ---------- Phase A6: cancelled-run behavior (3 runs x 3 repos) ----------
sample_cancelled() { # $1 tag $2 repo $3 workflow-file
  local tag="$1" repo="$2" wf="$3" ids id n=0
  ids="$(gh api "repos/$repo/actions/workflows/$wf/runs?status=cancelled&per_page=3" --jq '.workflow_runs[].id')"
  for id in $ids; do
    n=$((n+1))
    get_api "r12-cancelled-$tag-$n.json" "repos/$repo/actions/runs/$id/jobs?per_page=100&filter=latest"
    echo "cancelled sample $tag-$n: run $id" >>"$PROV"
  done
  [ "$n" -gt 0 ] || { bad "S-fetch-$tag" "no cancelled runs returned"; return 1; }
}
sample_cancelled cargo rust-lang/cargo main.yml
sample_cancelled ra rust-lang/rust-analyzer ci.yaml
sample_cancelled uv astral-sh/uv ci.yml

# ---------- Phase A7: source precedent (local pins, snapshotted) ----------
PY="$HOME/c/py-launch-blueprint"; TS="$HOME/c/ts-launch-blueprint"
git -C "$PY" show 'b55b8c2:.github/workflows/ci.yml' >"$SNAP/r12-py-ci.yml"
git -C "$PY" show 'b55b8c2:docs/research/0004-template-press-dogfood-log.md' >"$SNAP/r12-py-dogfood.md"
git -C "$TS" show 'e5100b4:.github/workflows/ci.yml' >"$SNAP/r12-ts-ci.yml"
{
  echo "- r12-py-ci.yml <= $PY @ b55b8c2 .github/workflows/ci.yml"
  echo "- r12-py-dogfood.md <= $PY @ b55b8c2 docs/research/0004-template-press-dogfood-log.md"
  echo "- r12-ts-ci.yml <= $TS @ e5100b4 .github/workflows/ci.yml"
} >>"$PROV"
# py history: every revision of ci.yml containing ci-ok, needs-completeness each.
git -C "$PY" log --format=%H 'b55b8c2' -- .github/workflows/ci.yml >"$TMP/py-hist.txt"
python3 - "$PY" "$TMP/py-hist.txt" "$TMP/py-hist-result.txt" <<'EOF'
import subprocess, sys, yaml
repo, hist, out = sys.argv[1], sys.argv[2], sys.argv[3]
revs = [l.strip() for l in open(hist) if l.strip()]
checked, drift = 0, []
for c in revs:
    text = subprocess.run(["git", "-C", repo, "show", f"{c}:.github/workflows/ci.yml"],
                          capture_output=True, text=True).stdout
    try:
        jobs = (yaml.safe_load(text) or {}).get("jobs", {})
    except Exception:
        continue
    if "ci-ok" not in jobs:
        continue
    checked += 1
    needs = jobs["ci-ok"].get("needs", [])
    if isinstance(needs, str):
        needs = [needs]
    missing = sorted(set(jobs) - set(needs) - {"ci-ok"})
    if missing:
        drift.append(f"{c[:12]}: missing {missing}")
open(out, "w").write(f"checked={checked}\n")
open(out, "a").write("\n".join(drift) + ("\n" if drift else ""))
print(f"checked={checked} drift={len(drift)}")
EOF
cp "$TMP/py-hist-result.txt" "$SNAP/r12-py-history.txt"
cp "$TMP/py-hist.txt" "$SNAP/r12-py-history-commits.txt"

# ---------- Phase A8: live source settings + SHAs ----------
set +e
gh api "repos/smorinlabs/ts-launch-blueprint/branches/main/protection" >"$SNAP/r12-ts-protection.json" 2>"$TMP/ts-prot.err"
TS_PROT_CODE=$?
set -e
echo "ts protection exit: $TS_PROT_CODE; stderr: $(head -c 300 "$TMP/ts-prot.err")" >>"$PROV"
cp "$TMP/ts-prot.err" "$SNAP/r12-ts-protection.err"
get_api r12-ts-rules.json "repos/smorinlabs/ts-launch-blueprint/rules/branches/main"
get_api r12-py-protection.json "repos/smorinlabs/py-launch-blueprint/branches/main/protection"

# ---------- Phase A9: integrity manifest ----------
(cd "$EV" && sha256sum ci.candidate.yml snapshots/r12-*.md snapshots/r12-*.json snapshots/r12-*.yml snapshots/r12-*.yaml snapshots/r12-*.py snapshots/r12-*.txt snapshots/r12-*.err >SHA256SUMS)
_n=("$SNAP"/*); info "snapshots: ${#_n[@]} files"

# ================= Phase B: offline assertions =================
has() { # $1 id $2 file $3 fixed-string
  if grep -qF "$3" "$SNAP/$2"; then ok "S-$1"; else bad "S-$1" "$2 lacks: $3"; fi
}

# Docs: the platform facts the recommendation rests on.
has "docs-success" "r12-troubleshooting-required-status-checks.md" "Successful check statuses are \`success\`, \`skipped\`, and \`neutral\`"
has "docs-skipped" "r12-troubleshooting-required-status-checks.md" 'A job is skipped by a conditional'
has "docs-skipped-success" "r12-reusable-skipped.md" 'will report its status as "Success"'
has "docs-always" "r12-troubleshooting-required-status-checks.md" "Use \`always()\` with \`needs\` for required checks that depend on other jobs"
has "docs-pathfilter" "r12-troubleshooting-required-status-checks.md" 'A workflow is skipped by [path filtering]'
has "docs-pending" "r12-troubleshooting-required-status-checks.md" 'Pending'
has "docs-mergegroup" "r12-reusable-merge-group.md" "include the \`merge_group\` event"
has "docs-unique" "r12-about-protected-branches.md" 'make sure that job names are unique across all workflows'
has "docs-appsource" "r12-about-protected-branches.md" 'you can select an app'
has "docs-skipprop" "r12-reusable-needs.md" 'If a job fails or is skipped, all jobs that need it are skipped'
has "docs-needscont" "r12-reusable-needs.md" "use the \`always()\` conditional expression"
has "docs-expr-always" "r12-expressions.md" 'even when canceled'
has "docs-expr-cancelled" "r12-expressions.md" "!cancelled()"
has "docs-ruleset-org" "r12-available-rules-for-rulesets.md" 'Require workflows to pass before merging'
has "docs-checks-skipped" "r12-status-checks-ref.md" 'treated as a success for dependent checks'

# App identity.
if [ "$(jq -r .id "$SNAP/r12-app-github-actions.json")" = "15368" ]; then
  ok "S-app-id Actions app is 15368"
else bad "S-app-id" "unexpected app id"; fi

# Runner inventory.
has "runner-jq" "r12-Ubuntu2404-Readme.md" 'jq '
has "runner-yq" "r12-Ubuntu2404-Readme.md" 'yq '
JQV="$(grep -o 'jq [0-9][0-9.]*' "$SNAP/r12-Ubuntu2404-Readme.md" | head -1)"
YQV="$(grep -o 'yq [0-9][0-9.]*' "$SNAP/r12-Ubuntu2404-Readme.md" | head -1)"
info "runner ships $JQV + $YQV"

# alls-green figures + verdict semantics.
AG_STARS="$(jq -r .stargazers_count "$SNAP/r12-alls-green-repo.json")"
AG_PUSH="$(jq -r .pushed_at "$SNAP/r12-alls-green-repo.json")"
AG_ARCH="$(jq -r .archived "$SNAP/r12-alls-green-repo.json")"
AG_LIC="$(jq -r .license.spdx_id "$SNAP/r12-alls-green-repo.json")"
AG_OPEN="$(jq -r .total_count "$SNAP/r12-alls-green-issues.json")"
AG_REL="$(jq -r .tag_name "$SNAP/r12-alls-green-release.json")"
info "alls-green: stars=$AG_STARS pushed=$AG_PUSH archived=$AG_ARCH lic=$AG_LIC open=$AG_OPEN rel=$AG_REL"
if [ "$AG_ARCH" = "false" ]; then ok "S-ag-notarchived"; else bad "S-ag-notarchived" "archived=$AG_ARCH"; fi
has "ag-required" "r12-alls-green-job_outcome.py" "REQUIRED"
if grep -q "frozenset({'success'})" "$SNAP/r12-alls-green-job_outcome.py" || grep -q 'frozenset({"success"})' "$SNAP/r12-alls-green-job_outcome.py"; then
  ok "S-ag-success-only REQUIRED accepts only success"
else bad "S-ag-success-only" "REQUIRED frozenset not as expected"; fi
has "ag-always" "r12-alls-green-README.md" 'always'
has "ag-allowed-skips" "r12-alls-green-action.yml" 'allowed-skips'

# cargo: aggregate + app-pinned ruleset.
has "cargo-conclusion" "r12-cargo-main.yml" 'conclusion'
if jq -e '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(select(.context == "conclusion" and .integration_id == 15368)) | length == 1' "$SNAP/r12-cargo-rules.json" >/dev/null; then
  ok "S-cargo-ruleset requires conclusion from app 15368"
else bad "S-cargo-ruleset" "ruleset shape unexpected"; fi

# rust-analyzer: aggregate omits its detector (the drift exhibit).
if python3 - "$SNAP/r12-rust-analyzer-ci.yaml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
needs = jobs["conclusion"].get("needs", [])
needs = [needs] if isinstance(needs, str) else list(needs)
ts_gate = jobs["typescript"].get("needs", [])
print("conclusion needs:", needs)
print("typescript needs:", ts_gate)
assert "changes" in jobs, "no changes job"
assert "changes" not in needs, "changes IS in conclusion needs"
assert "changes" in (ts_gate if isinstance(ts_gate, list) else [ts_gate]), "typescript not gated on changes"
print("RUST_ANALYZER_DRIFT_CONFIRMED")
EOF
then ok "S-ra-drift conclusion omits changes while typescript is gated on it"; else bad "S-ra-drift" "exhibit did not reproduce"; fi
if jq -e '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(select(.context == "conclusion" and .integration_id == 15368)) | length == 1' "$SNAP/r12-ra-rules.json" >/dev/null; then
  ok "S-ra-ruleset requires conclusion from app 15368"
else bad "S-ra-ruleset" "ruleset shape unexpected"; fi

# uv: aggregate folds in its detector + app-pinned ruleset.
if python3 - "$SNAP/r12-uv-ci.yml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
agg = [j for j, b in jobs.items() if (b.get("name") or j) == "all required jobs passed"]
assert len(agg) == 1, f"aggregate not found: {agg}"
needs = jobs[agg[0]].get("needs", [])
print("uv aggregate:", agg[0], "needs:", needs)
assert "plan" in needs, "plan not in uv aggregate needs"
assert "always()" in str(jobs[agg[0]].get("if", "")), "no always() on uv aggregate"
print("UV_FOLD_CONFIRMED")
EOF
then ok "S-uv-fold uv aggregate folds plan with always()"; else bad "S-uv-fold" "exhibit did not reproduce"; fi
if jq -e '.[] | select(.type == "required_status_checks") | .parameters.required_status_checks | map(select(.integration_id == 15368)) | length >= 1' "$SNAP/r12-uv-rules.json" >/dev/null; then
  ok "S-uv-ruleset app-pinned required check"
else bad "S-uv-ruleset" "ruleset shape unexpected"; fi

# clippy: one aggregate per workflow file.
N_CLIPPY="$(jq -r '[.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context] | unique | length' "$SNAP/r12-clippy-rules.json")"
info "clippy required contexts: $(jq -r '[.[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context] | unique | join(", ")' "$SNAP/r12-clippy-rules.json")"
if [ "$N_CLIPPY" -ge 2 ]; then ok "S-clippy-multi clippy requires $N_CLIPPY aggregate contexts (per-workflow)"; else bad "S-clippy-multi" "only $N_CLIPPY"; fi

# ruff: aggregate folds in its detector.
if python3 - "$SNAP/r12-ruff-ci.yaml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
agg = [j for j, b in jobs.items() if "required" in (b.get("name") or j).lower().replace("-", " ").replace("_", " ")]
print("ruff aggregate candidates:", agg)
assert len(agg) == 1, f"ruff aggregate not found: {agg}"
needs = jobs[agg[0]].get("needs", [])
assert "determine_changes" in needs, "determine_changes not folded in"
assert "always()" in str(jobs[agg[0]].get("if", "")), "no always() on ruff aggregate"
print("RUFF_FOLD_CONFIRMED")
EOF
then ok "S-ruff-fold ruff aggregate folds determine_changes with always()"; else bad "S-ruff-fold" "exhibit did not reproduce"; fi

# clap: aggregate job with contains() verdict over failure/cancelled/skipped.
if python3 - "$SNAP/r12-clap-ci.yml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
needs = jobs["ci"].get("needs", [])
print("clap ci needs:", len(needs))
assert len(needs) >= 10, "clap ci needs too short"
assert "always()" in str(jobs["ci"].get("if", "")), "no always() on clap ci"
print("CLAP_FOLD_CONFIRMED")
EOF
then ok "S-clap-fold clap ci folds 10+ jobs with always()"; else bad "S-clap-fold" "exhibit did not reproduce"; fi
has "clap-contains" "r12-clap-ci.yml" 'contains(needs'

# tokio: long individual list + sync on one merged PR.
N_TOKIO="$(jq -r '.protection.required_status_checks.contexts | length' "$SNAP/r12-tokio-branch.json")"
info "tokio requires $N_TOKIO individual contexts"
if [ "$N_TOKIO" -ge 40 ]; then ok "S-tokio-long tokio requires $N_TOKIO contexts"; else bad "S-tokio-long" "only $N_TOKIO"; fi
jq -r '.check_runs[].name' "$SNAP"/r12-tokio-check-runs-p*.json | sort -u >"$TMP/tokio-ran.txt"
jq -r '.protection.required_status_checks.contexts[]' "$SNAP/r12-tokio-branch.json" | sort -u >"$TMP/tokio-req.txt"
if comm -23 "$TMP/tokio-req.txt" "$TMP/tokio-ran.txt" >"$TMP/tokio-missing.txt" && [ ! -s "$TMP/tokio-missing.txt" ]; then
  ok "S-tokio-sync every required context reported on the sampled PR"
else bad "S-tokio-sync" "missing: $(cat "$TMP/tokio-missing.txt")"; fi

# clap: aggregate plus one context per other workflow.
N_CLAP="$(jq -r '.protection.required_status_checks.contexts | length' "$SNAP/r12-clap-branch.json")"
info "clap requires: $(jq -r '.protection.required_status_checks.contexts | join(" | ")' "$SNAP/r12-clap-branch.json")"
if jq -e '.protection.required_status_checks.contexts | map(select(. == "CI")) | length == 1' "$SNAP/r12-clap-branch.json" >/dev/null && [ "$N_CLAP" -ge 2 ]; then
  ok "S-clap-perwf clap requires CI aggregate plus $N_CLAP total contexts"
else bad "S-clap-perwf" "unexpected clap shape"; fi

# Cancelled runs: !cancelled() aggregates conclude cancelled; always() aggregates run.
for f in "$SNAP"/r12-cancelled-cargo-*.json "$SNAP"/r12-cancelled-ra-*.json; do
  C="$(jq -r '.jobs[] | select(.name == "conclusion") | .conclusion' "$f" | head -1)"
  if [ "$C" = "cancelled" ]; then ok "S-cancelled-$(basename "$f" .json) conclusion=$C"; else bad "S-cancelled-$(basename "$f" .json)" "conclusion=$C"; fi
done
for f in "$SNAP"/r12-cancelled-uv-*.json; do
  C="$(jq -r '.jobs[] | select(.name == "all required jobs passed") | .conclusion' "$f" | head -1)"
  case "$C" in success|failure) ok "S-cancelled-$(basename "$f" .json) ran to $C";; *) bad "S-cancelled-$(basename "$f" .json)" "conclusion=$C";; esac
done

# py at pin: hardened aggregate covering every job, always(), no perms.
if python3 - "$SNAP/r12-py-ci.yml" <<'EOF'
import sys, yaml
jobs = yaml.safe_load(open(sys.argv[1]))["jobs"]
agg = jobs["ci-ok"]
needs = agg.get("needs", [])
print("py jobs:", len(jobs), "ci-ok needs:", len(needs))
assert set(jobs) - set(needs) - {"ci-ok"} == set(), "py drift at pin"
assert "always()" in str(agg.get("if", "")), "no always()"
assert agg.get("permissions") == {}, "permissions not empty"
print("PY_COVER_CONFIRMED")
EOF
then ok "S-py-cover py ci-ok covers all jobs with always() + {}"; else bad "S-py-cover" "exhibit failed"; fi
has "py-header" "r12-py-ci.yml" 'single required status for branch protection'
has "py-mergegroup" "r12-py-ci.yml" 'merge_group'
HIST_CHECKED="$(grep -o 'checked=[0-9]*' "$SNAP/r12-py-history.txt" | cut -d= -f2)"
HIST_DRIFT="$(grep -c . "$SNAP/r12-py-history.txt")"
info "py history: $HIST_CHECKED revisions with ci-ok, drift lines: $((HIST_DRIFT - 1))"
if [ "$HIST_CHECKED" -ge 20 ] && [ "$HIST_DRIFT" -eq 1 ]; then
  ok "S-py-history zero drift across $HIST_CHECKED revisions"
else bad "S-py-history" "checked=$HIST_CHECKED lines=$HIST_DRIFT"; fi
has "py-problem15" "r12-py-dogfood.md" 'PROBLEM-15'
has "py-problem15-body" "r12-py-dogfood.md" 'blueprint-only jobs'

# ts at pin: matrixed single gating job, no merge_group.
if python3 - "$SNAP/r12-ts-ci.yml" <<'EOF'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
jobs = doc["jobs"]
print("ts jobs:", list(jobs))
assert "merge_group" not in (doc.get(True, {}) or {}), "merge_group present"
EOF
then ok "S-ts-nomergegroup ts triggers lack merge_group"; else bad "S-ts-nomergegroup" "unexpected"; fi
has "ts-matrix" "r12-ts-ci.yml" 'node-version'
if grep -q 'merge_group' "$SNAP/r12-ts-ci.yml"; then bad "S-ts-nomg2" "merge_group found"; else ok "S-ts-nomg2 no merge_group string in ts ci.yml"; fi

# Live source settings.
if [ "$TS_PROT_CODE" -ne 0 ] && grep -q '404' "$SNAP/r12-ts-protection.err"; then
  ok "S-ts-unprotected ts main protection returns 404"
else bad "S-ts-unprotected" "exit=$TS_PROT_CODE"; fi
if jq -e '[.[] | select(.type == "required_status_checks")] | length == 0' "$SNAP/r12-ts-rules.json" >/dev/null; then
  ok "S-ts-norule ts has no required_status_checks rule"
else bad "S-ts-norule" "a required rule exists"; fi
N_PYCTX="$(jq -r '.required_status_checks.contexts | length' "$SNAP/r12-py-protection.json")"
info "py requires $N_PYCTX contexts: $(jq -r '.required_status_checks.contexts | join(", ")' "$SNAP/r12-py-protection.json")"
if jq -e '.required_status_checks.contexts | map(select(. == "ci-ok")) | length == 1' "$SNAP/r12-py-protection.json" >/dev/null; then
  ok "S-py-live py requires ci-ok"
else bad "S-py-live" "ci-ok not required"; fi
if jq -e '.required_status_checks.checks | map(select(.context == "ci-ok" and .app_id == 15368)) | length == 1' "$SNAP/r12-py-protection.json" >/dev/null; then
  ok "S-py-live-app py ci-ok pinned to app 15368"
else bad "S-py-live-app" "pin shape unexpected"; fi

# S0: integrity over every snapshot + the fixture.
if (cd "$EV" && sha256sum -c SHA256SUMS >/dev/null 2>&1); then
  ok "S0 SHA256SUMS verifies ($(grep -c . "$EV/SHA256SUMS") files)"
else bad "S0" "integrity failure"; fi

echo "RESULT PASS=$PASS FAIL=$FAIL SKIP=0"
[ "$FAIL" -eq 0 ]
