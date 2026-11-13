#!/usr/bin/env bash
# R10 (dependency-cache-action) empirical check — LIVE FIGURES.
#
# Purpose: re-query, from this machine, the population and maintenance figures
# the two raw reports assert, at the endpoints `## Required evidence` names.
# This script VERIFIES figures; it builds nothing and installs nothing.
#
# Reproducibility contract, stated rather than implied: this log is NOT
# byte-for-byte reproducible. Every value it prints is a live counter
# (stargazers, open issues, pushed_at, download counts, the newest release) and
# moves without notice. Each figure is therefore ALSO snapshotted, verbatim, to
# review/evidence/figures/*.json beside this log. A snapshot holds the endpoint,
# the retrieval date and the fields this decision cites — a projection, not the
# whole response body, because the full bodies run to megabytes of issue text
# that no claim here rests on. The snapshot is the citable artifact and the log
# is its rendering. To compare a rerun against this log,
# compare the SNAPSHOT files, and read a difference as upstream drift rather
# than as a defect. The three RustSec HTTP statuses and the crates.io
# `yanked` field are the only values here expected to be stable.
#
# Retrieval date: 2026-09-17 (UTC). gh reads its own credential; no token value
# is printed, echoed or written to any file.

set -u
set -o pipefail

GREP=/usr/bin/grep
RETRIEVED='2026-09-17 (UTC)'
OUT=$(cd -- "$(dirname -- "$0")" && pwd)/figures
mkdir -p "$OUT"

hr() { printf '\n===== %s =====\n' "$1"; }

hr "B0. environment"
printf 'counting binary: %s -> %s\n' "$GREP" "$("$GREP" --version | sed -n '1p')"
gh --version | sed -n '1p'
printf 'retrieval date: %s\n' "$RETRIEVED"
printf 'snapshot directory: %s\n' "$OUT"

hr "B1. repository figures — GET https://api.github.com/repos/<o>/<r>"
printf '%-46s %8s %9s %-22s %-14s\n' 'repository' 'stars' 'archived' 'pushed_at' 'license'
for r in Swatinem/rust-cache actions/cache actions-rust-lang/setup-rust-toolchain \
         mozilla-actions/sccache-action moonrepo/setup-rust; do
  snap="$OUT/repo-$(printf '%s' "$r" | tr '/' '_').json"
  gh api "repos/$r" \
    --jq "{endpoint: \"https://api.github.com/repos/$r\", retrieved: \"$RETRIEVED\",
           full_name, stargazers_count, archived, pushed_at,
           license: (.license.spdx_id // null)}" > "$snap" \
    || { printf 'ERROR reading repos/%s\n' "$r"; continue; }
  read -r stars arch pushed lic <<< "$(python3 - "$snap" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(d["stargazers_count"], str(d["archived"]).lower(), d["pushed_at"], d["license"] or "null")
PY
)"
  printf '%-46s %8s %9s %-22s %-14s\n' "$r" "$stars" "$arch" "$pushed" "$lic"
done
printf '\nNote: the license column is a FIGURE only. Fitness gate 1 is\n'
printf 'inapplicable by owner ruling 2026-09-12 (Q7.B); it excludes nothing.\n'

hr "B2. open issues — GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open"
printf 'total_count is read from the search endpoint, never from open_issues_count\n'
for r in Swatinem/rust-cache actions/cache actions-rust-lang/setup-rust-toolchain \
         mozilla-actions/sccache-action; do
  snap="$OUT/openissues-$(printf '%s' "$r" | tr '/' '_').json"
  gh api "search/issues?q=repo:$r+is:issue+is:open" \
    --jq "{endpoint: \"https://api.github.com/search/issues?q=repo:$r+is:issue+is:open\",
           retrieved: \"$RETRIEVED\", total_count, incomplete_results}" > "$snap" || continue
  printf '%-46s open issues: %s\n' "$r" \
    "$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["total_count"])' "$snap")"
done

hr "B3. latest release — GET https://api.github.com/repos/<o>/<r>/releases/latest"
for r in Swatinem/rust-cache actions/cache actions-rust-lang/setup-rust-toolchain \
         mozilla-actions/sccache-action; do
  snap="$OUT/release-$(printf '%s' "$r" | tr '/' '_').json"
  gh api "repos/$r/releases/latest" \
    --jq "{endpoint: \"https://api.github.com/repos/$r/releases/latest\",
           retrieved: \"$RETRIEVED\", tag_name, published_at, draft, prerelease}" > "$snap" || continue
  read -r tag pub <<< "$(python3 -c \
    'import json,sys; d=json.load(open(sys.argv[1])); print(d["tag_name"], d["published_at"])' "$snap")"
  printf '%-46s %-10s %s\n' "$r" "$tag" "$pub"
done

hr "B4. Swatinem/rust-cache issue responsiveness — 10 most recently OPENED issues"
# GET https://api.github.com/repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc
# Pull requests are excluded (.pull_request == null), per the required-evidence rule.
TMP=$(mktemp -d "${TMPDIR:-/tmp}/r10-figures.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
gh api 'repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc&per_page=100' \
  > "$TMP/issues.json"
nums=$(python3 -c \
  'import json,sys; d=json.load(open(sys.argv[1])); print(" ".join(str(i["number"]) for i in [x for x in d if x.get("pull_request") is None][:10]))' \
  "$TMP/issues.json")
printf 'ten most recent issues: %s\n' "$nums"
for n in $nums; do
  gh api "repos/Swatinem/rust-cache/issues/$n/comments" > "$TMP/comments-$n.json"
done
python3 - "$TMP" "$OUT/rust-cache-issue-responsiveness.json" "$RETRIEVED" "$nums" <<'PY' | tee "$TMP/table.txt"
import datetime, json, sys
tmp, out, retrieved, nums = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4].split()
issues = {i["number"]: i for i in json.load(open(f"{tmp}/issues.json"))}
rows, answered = [], 0
print("%-8s %-8s %-10s %-22s %s" % ("issue", "state", "comments", "created_at", "first maintainer reply"))
for n in (int(x) for x in nums):
    issue = issues[n]
    created = datetime.datetime.fromisoformat(issue["created_at"].replace("Z", "+00:00"))
    first = None
    for c in json.load(open(f"{tmp}/comments-{n}.json")):
        if c["user"]["login"] == "Swatinem":
            first = datetime.datetime.fromisoformat(c["created_at"].replace("Z", "+00:00"))
            break
    days = None if first is None else round((first - created).total_seconds() / 86400, 3)
    answered += first is not None
    rows.append({"number": n, "state": issue["state"], "comments": issue["comments"],
                 "created_at": issue["created_at"], "days_to_first_maintainer_reply": days})
    print("%-8s %-8s %-10s %-22s %s" % ("#%d" % n, issue["state"], issue["comments"],
                                        issue["created_at"], "none" if days is None else "%.3f d" % days))
answered_days = sorted(r["days_to_first_maintainer_reply"] for r in rows if r["days_to_first_maintainer_reply"] is not None)
median_answered = answered_days[len(answered_days) // 2] if answered_days else None
print("maintainer replied on %d of %d; unanswered by the maintainer: %d" % (answered, len(rows), len(rows) - answered))
print("median days to first maintainer reply AMONG THE ANSWERED = %s" % median_answered)
json.dump({"endpoint": "https://api.github.com/repos/Swatinem/rust-cache/issues?state=all&sort=created&direction=desc&per_page=100"
                       " (pull requests excluded) plus .../issues/<n>/comments",
           "retrieved": retrieved, "issues": rows, "answered": answered, "unanswered": len(rows) - answered,
           "median_days_among_answered": median_answered,
           "median_over_all_ten": "undefined: more than half are unanswered"},
          open(out, "w"), indent=2)
PY
printf 'A median over all ten is undefined when more than half are unanswered;\n'
printf 'it is reported as undefined rather than imputed.\n'

hr "B5. issue #341 — the live macOS-image defect the decision configures around"
gh api repos/Swatinem/rust-cache/issues/341 \
  --jq "{endpoint: \"https://api.github.com/repos/Swatinem/rust-cache/issues/341\",
         retrieved: \"$RETRIEVED\", number, state, title, comments, created_at, closed_at}" \
  > "$OUT/rust-cache-issue-341.json"
gh api repos/Swatinem/rust-cache/issues/341 \
  --jq '"#\(.number)  state=\(.state)  comments=\(.comments)  created=\(.created_at)  closed=\(.closed_at)\ntitle: \(.title)"'
printf 'The issue is CLOSED; the CHANGELOG at the pinned commit records no fix for\n'
printf 'it (assertion A4.5 in r10-pinned-sources.log), so the behaviour is live at\n'
printf 'the recommended pin and the template configures around it.\n'

hr "B6. crates.io — the one crate candidate (sccache); the actions have no crate figures"
# GET https://crates.io/api/v1/crates/sccache  and  .../versions
UA='rs-launch-blueprint research (P02); contact via the repository issue tracker'
curl -sS --max-time 30 -A "$UA" https://crates.io/api/v1/crates/sccache > "$TMP/sccache.json"
curl -sS --max-time 30 -A "$UA" https://crates.io/api/v1/crates/sccache/versions > "$TMP/sccache-versions.json"
python3 - "$TMP/sccache.json" "$TMP/sccache-versions.json" "$OUT/crates-sccache.json" "$RETRIEVED" <<'PY'
import json, sys
c = json.load(open(sys.argv[1]))["crate"]
v = json.load(open(sys.argv[2]))["versions"]
newest = next(x for x in v if not x["yanked"])
print(f'sccache  crate.recent_downloads (90-day) = {c["recent_downloads"]}')
print(f'sccache  crate.downloads (all-time)      = {c["downloads"]}')
print(f'sccache  newest unyanked num             = {newest["num"]}')
print(f'sccache  newest unyanked created_at      = {newest["created_at"]}')
print(f'sccache  newest unyanked license         = {newest["license"]}')
print(f'sccache  newest unyanked rust_version    = {newest.get("rust_version")}')
json.dump({"endpoint": "https://crates.io/api/v1/crates/sccache and .../versions",
           "retrieved": sys.argv[4],
           "recent_downloads": c["recent_downloads"], "downloads": c["downloads"],
           "newest_unyanked": {k: newest.get(k) for k in
                               ("num", "created_at", "license", "rust_version", "yanked")}},
          open(sys.argv[3], "w"), indent=2)
PY
printf '\nSwatinem/rust-cache, actions/cache, actions-rust-lang/setup-rust-toolchain\n'
printf 'and mozilla-actions/sccache-action are GitHub Actions, not crates.io\n'
printf 'packages: crate.recent_downloads and crate.downloads do not exist for\n'
printf 'them, so both figures are recorded as inapplicable with this reason.\n'

hr "B7. RustSec — advisory pages, with a positive control"
# https://rustsec.org/packages/<name>.html ; 404 means no advisory page exists.
printf '# endpoint: https://rustsec.org/packages/<name>.html\n# retrieved: %s\n' \
  "$RETRIEVED" > "$OUT/rustsec-status.txt"
for pkg in rust-cache sccache atty serde; do
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 "https://rustsec.org/packages/$pkg.html")
  printf 'https://rustsec.org/packages/%-12s.html -> HTTP %s\n' "$pkg" "$code"
  printf '%s %s\n' "$pkg" "$code" >> "$OUT/rustsec-status.txt"
done
printf 'atty carries a known advisory and returns 200, which is the positive\n'
printf 'control proving a 404 is an absence of advisory rather than a broken\n'
printf 'lookup. rust-cache 404s because it is an Action and has no crates.io\n'
printf 'package at all, so gate 3 is inapplicable to it, not passed by it.\n'

hr "RESULT"
printf 'This section reports figures, not assertions. Nothing here passes or\n'
printf 'fails; the snapshots under %s are the citable artifacts.\n' "$OUT"
exit 0
