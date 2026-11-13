#!/usr/bin/env bash
# Evaluation (not the acceptance check) of conventional_commits_linter 0.17.1
# against the same fitness gates and the same message fixture the selected
# candidate cleared. Revision 6 runs this because the owner's 2026-09-12 licence
# ruling (Q7.B) makes fitness gate 1 inapplicable, so the sole ground on which
# revision 5 excluded this candidate ("Excluded by gate 1", AGPL-3.0) is void and
# the candidate re-enters the field unevaluated.
#
# Two binaries are compared on the same inputs:
#   ./tools/bin/conventional_commits_linter   the re-entering candidate
#   ../tools/bin/committed                    the selected candidate (control)
# Both are provisioned by this script when absent, with the same `cargo install`
# lines the acceptance runner uses.
#
# Assertion model: every executed case asserts the OBSERVED exit status against
# the status this evaluation recorded, so a rerun that differs fails loudly
# (FAIL>0 => exit 1). Whether an observation MEETS or VIOLATES the commit
# contract is reported separately and counted as VIOLATION; a violation is the
# finding, not a script error. Figures that move between runs are printed under
# [volatile] and are never asserted.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M="$HERE/../messages"
BIN="$HERE/tools/bin/conventional_commits_linter"
CTL="$HERE/../tools/bin/committed"
CTLCFG="$HERE/../committed.toml"
UA="rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)"
VER="0.17.1"
CRATE="conventional_commits_linter"
REPO="DeveloperC286/conventional_commits_linter"
WORK="$HERE/.work"
PASS=0; FAIL=0; VIOL=0

ok(){ # id expected observed description
  local id="$1" exp="$2" obs="$3" desc="$4" v
  if [ "$exp" = "$obs" ]; then v=PASS; PASS=$((PASS+1)); else v=FAIL; FAIL=$((FAIL+1)); fi
  printf '%-8s expected=%-22s observed=%-22s %-4s %s\n' "$id" "$exp" "$obs" "$v" "$desc"
}
verdict(){ # MEETS|VIOLATES description
  [ "$1" = VIOLATES ] && VIOL=$((VIOL+1))
  printf '         contract: %-8s %s\n' "$1" "$2"
}

mkdir -p "$WORK"
echo "conventional_commits_linter evaluation, date (UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)   [volatile line]"
echo "host: $(uname -srm); rustc: $(rustc --version); cargo: $(cargo --version)"

########## A. provisioning ##########
if [ ! -x "$BIN" ]; then
  echo "provisioning $CRATE $VER ..."
  cargo install "$CRATE" --locked --version "$VER" --root "$HERE/tools" > "$HERE/install.log" 2>&1
  echo "cargo install exit=$?  (log: install.log)"
fi
if [ ! -x "$CTL" ]; then
  echo "provisioning the control binary committed 1.1.11 ..."
  cargo install committed --locked --version 1.1.11 --root "$HERE/../tools" >> "$HERE/install.log" 2>&1
  echo "cargo install exit=$?  (log: install.log)"
fi
ok A1 "$CRATE $VER" "$("$BIN" --version 2>&1)" "candidate binary reports its pinned version"
ok A2 "committed 1.1.11" "$("$CTL" --version 2>&1)" "control binary reports the selected pin"
echo "         candidate size: $(wc -c < "$BIN") bytes   [volatile line]"

########## B. capability surface, read from the tool itself ##########
"$BIN" --help > "$WORK/help.txt" 2>&1
ok B1 0 $? "--help exits 0 (full text below)"
sed 's/^/       | /' "$WORK/help.txt"
ok B2 1 "$(grep -c -- '--max-commit-title-length' "$WORK/help.txt")" \
  "exactly one title/header length option exists"
ok B3 0 "$(grep -ciE -- '--(body|footer|line)[-a-z]*length|body-max|footer-max' "$WORK/help.txt")" \
  "NO body-length and NO footer-length option exists anywhere in the CLI surface"
ok B4 1 "$(grep -c 'possible values: any, angular' "$WORK/help.txt")" \
  "--type is a two-valued fixed preset (any|angular), not a user-supplied type list"
"$BIN" --type chore - < "$M/01-valid.txt" > "$WORK/type-probe.txt" 2>&1
ok B5 2 $? "--type chore is rejected by the parser: a declared eleven-member enum cannot be expressed"
sed 's/^/       | /' "$WORK/type-probe.txt"
ok B6 0 "$(grep -c 'config\|\.toml\|\.yaml\|\.yml' "$WORK/help.txt")" \
  "the tool reads no configuration file: the whole contract must be re-stated on every argv"

########## C. the same message fixture, both binaries ##########
# argv: the strictest configuration the tool can express for this contract.
CAND_ARGS=(--type angular --max-commit-title-length 50)
echo "candidate argv: conventional_commits_linter ${CAND_ARGS[*]} -   (strictest expressible form)"
echo "control   argv: committed --config ../committed.toml --commit-file <file>   (11 types, 50/72; the path is explicit because this directory sits inside another git repository, whose root carries no committed.toml)"
case_cmp(){ # id expected_candidate_rc expected_control_rc MEETS|VIOLATES msgfile description
  local id="$1" ec="$2" ek="$3" verd="$4" msg="$5" desc="$6" oc ok_ out
  out="$("$BIN" "${CAND_ARGS[@]}" - < "$M/$msg" 2>&1)"; oc=$?
  "$CTL" --config "$CTLCFG" --commit-file "$M/$msg" >/dev/null 2>&1; ok_=$?
  ok "$id" "$ec" "$oc" "candidate on $msg — $desc"
  ok "$id-ctl" "$ek" "$ok_" "control committed on the same file"
  [ -n "$out" ] && printf '%s\n' "$out" | sed 's/^/       | /'
  verdict "$verd" "$desc"
}
case_cmp C01 0 0 MEETS    01-valid.txt "conforming message accepted by both"
case_cmp C02 1 1 MEETS    02-bad-type.txt "type \`wibble\` rejected by both (angular preset happens to list the same eleven types)"
case_cmp C03 1 1 MEETS    03-long-subject.txt "71-column header rejected by both at 50"
case_cmp C21 1 1 MEETS    21-header-over-50-description-under-50.txt "66-column header (41-column description) rejected by both: the candidate also counts the whole first line (message_length/mod.rs: commit_message.lines().next(), chars().count())"
case_cmp C04 0 1 VIOLATES 04-long-body-line.txt "83-column body line ACCEPTED by the candidate, rejected by committed: the candidate has no body cap at all"
case_cmp C08 0 1 VIOLATES 08-long-footer-line.txt "96-column \`Reviewed-by:\` footer ACCEPTED by the candidate, rejected by committed: the candidate has no footer cap at all"
case_cmp C06 0 1 VIOLATES 06-subject-period.txt "subject ending in a period ACCEPTED by the candidate, rejected by committed (no punctuation rule)"
case_cmp C05 0 0 MEETS    05-url-body-line.txt "bare 116-column permalink accepted by both — but vacuously for the candidate, which caps no body line at any width"
case_cmp C07 0 0 MEETS    07-claude-session-trailer.txt "107-column \`Claude-Session:\` trailer accepted by both — vacuously for the candidate, as C05"
case_cmp C09 0 0 MEETS    09-capitalised-subject.txt "capitalised subject accepted by both (neither enforces subject case)"
case_cmp C10 0 0 MEETS    10-noun-phrase-subject.txt "this repository's real subject \`docs: P01 port research tree (phases 1-5)\` accepted by both"
# Type-vocabulary casing. Both tools match the vocabulary case-insensitively, so
# an upper-case member lands under either; neither lets a non-member land. This
# is a shared tolerance, newly measured here for both binaries, not a candidate
# defect: the candidate's ANGULAR_TYPE regex is compiled with (?i)
# (constants/mod.rs) and committed's allowed_types comparison behaves the same.
printf 'FEAT(cli): add --json output flag\n' > "$WORK/upper.txt"
printf 'WIBBLE(cli): add --json output flag\n' > "$WORK/upper-bad.txt"
out=$("$BIN" "${CAND_ARGS[@]}" - < "$WORK/upper.txt" 2>&1); rc=$?
ok C22 0 "$rc" "candidate on \`FEAT(cli): …\` — an upper-case MEMBER of the vocabulary is accepted"
"$CTL" --config "$CTLCFG" --commit-file "$WORK/upper.txt" >/dev/null 2>&1
ok C22-ctl 0 $? "control committed on the same message — accepted as well: the same tolerance"
verdict MEETS "the vocabulary is matched case-insensitively by BOTH tools; a shared tolerance, recorded as a finding about the selected tool too"
out=$("$BIN" "${CAND_ARGS[@]}" - < "$WORK/upper-bad.txt" 2>&1); rc=$?
ok C23 1 "$rc" "candidate on \`WIBBLE(cli): …\` — an upper-case NON-member is still rejected"
# The control's diagnostic ECHOES BACK the path it was given, so passing the
# absolute `$WORK/upper-bad.txt` made this one printed line carry the location of
# whatever copy of this fixture was running — the revision-6 auditor's rerun from
# `/private/tmp/...` differed here, and revision 6's byte-for-byte claim did not
# account for it. Invoking from inside `$WORK` with a bare relative file name
# makes the diagnostic location-independent; `--config` stays absolute, so the
# configuration read is unchanged, and the asserted exit status is unchanged.
( cd "$WORK" && "$CTL" --config "$CTLCFG" --commit-file upper-bad.txt ) > "$WORK/wibble.txt" 2>&1
ok C23-ctl 1 $? "control committed on the same message — rejected as well (invoked from inside the work directory with a relative file name, so the diagnostic quotes no absolute path)"
sed 's/^/       | /' "$WORK/wibble.txt"
verdict MEETS "neither tool lets a type outside the vocabulary land, in any casing"
# Missing-binary posture (essential behavior 5).
env PATH=/nonexistent conventional_commits_linter --type angular - < "$M/01-valid.txt" > "$WORK/missing.txt" 2>&1
ok C16 127 $? "missing binary fails loudly (127), as committed does"
sed 's/^/       | /' "$WORK/missing.txt"
verdict MEETS "fails loudly when absent"

########## D. fitness gates 2, 3, 4 on live sources ##########
curl -sS -H "User-Agent: $UA" "https://crates.io/api/v1/crates/$CRATE/versions" -o "$WORK/versions.json"
ok D0 0 $? "GET crates.io /versions"
python3 - "$WORK/versions.json" > "$WORK/versions.txt" <<'PY'
import json,sys
d=json.load(open(sys.argv[1]))
vs=sorted((v for v in d["versions"] if not v["yanked"]), key=lambda v: v["created_at"], reverse=True)
n=vs[0]
print("newest_unyanked=%s created_at=%s license=%s rust_version=%s edition=%s" % (
    n["num"], n["created_at"], n["license"], n["rust_version"], n.get("edition")))
PY
sed 's/^/       | /' "$WORK/versions.txt"
ok D1 "newest_unyanked=$VER" "$(cut -d' ' -f1 < "$WORK/versions.txt")" "0.17.1 is the newest unyanked release"
ok D2 "rust_version=None" "$(tr ' ' '\n' < "$WORK/versions.txt" | grep '^rust_version=')" \
  "GATE 2 FAILS: crates.io records no declared rust-version for 0.17.1"
ok D3 "license=AGPL-3.0" "$(tr ' ' '\n' < "$WORK/versions.txt" | grep '^license=')" \
  "licence recorded as a fact only; GATE 1 is inapplicable under the owner ruling of 2026-09-12"
# The same question read from the crate's own manifests at the published version.
curl -sSL -H "User-Agent: $UA" "https://static.crates.io/crates/$CRATE/$CRATE-$VER.crate" -o "$WORK/c.crate"
ok D4 0 $? "download the published .crate"
rm -rf "$WORK/src" && mkdir -p "$WORK/src" && tar xzf "$WORK/c.crate" -C "$WORK/src"
ok D5 0 $? "unpack the published .crate"
CT="$WORK/src/$CRATE-$VER/Cargo.toml"
ok D6 0 "$(grep -c '^rust-version' "$CT" "$WORK/src/$CRATE-$VER/Cargo.toml.orig" | awk -F: '{s+=$2} END{print s+0}')" \
  "GATE 2 FAILS at the source: neither Cargo.toml nor Cargo.toml.orig at 0.17.1 declares rust-version"
ok D7 'edition = "2021"' "$(grep -m1 '^edition' "$CT")" "the crate is edition 2021 (its own build, not the template's)"
ok D8 0 "$(grep -c 'unsafe' "$WORK/src/$CRATE-$VER/src/main.rs")" "unsafe posture: none in main.rs"
ok D9 0 "$(grep -rl 'unsafe ' "$WORK/src/$CRATE-$VER/src" | wc -l | tr -d ' ')" "unsafe posture: no source file uses an \`unsafe\` block"
# Gate 4: prebuilt artifacts for both runners in target-os-matrix (ubuntu-latest, macos-latest).
gh api "repos/$REPO/releases/tags/v$VER" --jq '[.assets[].name]|sort|join(" ")' > "$WORK/assets.txt" 2>&1
ok D10 0 $? "GET the v$VER release"
sed 's/^/       | /' "$WORK/assets.txt"
ok D11 "aarch64-unknown-linux-musl.tar.gz x86_64-unknown-linux-musl.tar.gz" "$(cat "$WORK/assets.txt")" \
  "GATE 4 FAILS: the release ships Linux musl assets only"
ok D12 0 "$(grep -ci 'apple-darwin\|macos\|darwin' "$WORK/assets.txt")" \
  "GATE 4 FAILS: no macOS prebuilt binary exists for macos-latest"
curl -sSL -H "User-Agent: $UA" "https://raw.githubusercontent.com/$REPO/v$VER/.github/workflows/continuous-integration.yml" -o "$WORK/ci.yml"
ok D13 0 $? "GET the upstream CI workflow at tag v$VER"
ok D14 "architecture: [ubuntu-24.04, ubuntu-24.04-arm]" "$(grep -m1 'architecture: \[' "$WORK/ci.yml" | sed 's/^ *//')" \
  "GATE 4 FAILS: upstream CI runs on Ubuntu x86_64 and Ubuntu arm only"
ok D15 0 "$(grep -ci 'macos' "$WORK/ci.yml")" "GATE 4 FAILS: no macOS job anywhere in the upstream CI workflow"
# Gate 3.
ok D16 404 "$(curl -sS -o /dev/null -w '%{http_code}' -H "User-Agent: $UA" "https://rustsec.org/packages/$CRATE.html")" \
  "GATE 3: no RustSec advisory page for the crate itself"
rm -rf "$HERE/.audit-cargo-home" && mkdir -p "$HERE/.audit-cargo-home"
cp "$WORK/src/$CRATE-$VER/Cargo.lock" "$WORK/Cargo.lock"
( cd "$WORK" && CARGO_HOME="$HERE/.audit-cargo-home" cargo audit --file Cargo.lock ) > "$WORK/audit.txt" 2>&1
ok D17 0 $? "GATE 3: cargo audit on the published lockfile, isolated advisory database (default policy: vulnerabilities fail, warnings warn)"
grep -E '^(Crate|Version|Warning|Title|ID|    Scanning|warning:|error:)' "$WORK/audit.txt" | sed 's/^/       | /'
ok D18 0 "$(grep -c '^Vulnerability' "$WORK/audit.txt")" "GATE 3: zero vulnerability-class advisories"
ok D19 1 "$(grep -c '^ID:.*RUSTSEC-2021-0139' "$WORK/audit.txt")" \
  "GATE 3 note: ansi_term, a DIRECT dependency of the crate, carries the unmaintained advisory RUSTSEC-2021-0139"
rm -rf "$HERE/.audit-cargo-home"

########## E. figures — never asserted; every line moves between runs ##########
echo "--- figures [volatile section: every line below can change without any change upstream]"
curl -sS -H "User-Agent: $UA" "https://crates.io/api/v1/crates/$CRATE" -o "$WORK/crate.json"
python3 - "$WORK/crate.json" <<'PY' | sed 's/^/       | /'
import json,sys
c=json.load(open(sys.argv[1]))["crate"]
print("crates.io recent_downloads=%s downloads=%s max_stable_version=%s" % (
    c["recent_downloads"], c["downloads"], c["max_stable_version"]))
PY
gh api "repos/$REPO" --jq '"github stargazers_count=\(.stargazers_count) forks=\(.forks_count) archived=\(.archived) pushed_at=\(.pushed_at)"' | sed 's/^/       | /'
gh api "search/issues?q=repo:$REPO+is:issue+is:open" --jq '"open issues total_count=\(.total_count)"' | sed 's/^/       | /'
gh api "search/issues?q=repo:$REPO+is:issue&sort=created&order=desc&per_page=10" \
  --jq '"ten most recently opened issues, author and comment count: " + ([.items[]|"#\(.number) \(.user.login)/\(.comments)"]|join(", "))' | sed 's/^/       | /'
curl -sS -H "User-Agent: $UA" "https://crates.io/api/v1/crates/$CRATE/reverse_dependencies?per_page=1" \
  | python3 -c 'import json,sys; print("crates.io reverse dependencies total=%s" % json.load(sys.stdin)["meta"]["total"])' | sed 's/^/       | /'
gh api "search/code?q=$CRATE+path:.github/workflows" --jq '"github code search, repositories naming the tool in a workflow: \(.total_count)"' | sed 's/^/       | /'

echo "summary: PASS=$PASS FAIL=$FAIL CONTRACT_VIOLATIONS=$VIOL"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS (every observation reproduced; the $VIOL contract violations above are the finding)"; else echo "RESULT: FAIL"; exit 1; fi
