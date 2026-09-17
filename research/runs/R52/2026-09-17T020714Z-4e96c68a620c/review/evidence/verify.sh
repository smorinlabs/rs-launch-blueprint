#!/usr/bin/env bash
# R52 (toml-crate) empirical check. Verifies the raw reports' load-bearing claims.
# It implements nothing: no template file is created, no config adapter is written,
# no file-I/O or error-mapping code is produced. The only code it compiles is a
# throwaway probe that calls the two candidate crates on three literal strings,
# which is "run the recommended tool against a few sample inputs".
#
# Contract:
#   * `set -uo pipefail` so a failing command inside a pipeline cannot be masked.
#   * Every load-bearing claim goes through assert_has / assert_absent / assert_eq /
#     assert_ge, which compare the CONTENT expected. A check that cannot fail is
#     not evidence.
#   * Volatile figures (download counts, stars, pushed_at, open-issue totals) are
#     RECORDED with endpoint and retrieval date, never asserted on an exact value.
#     They are printed with a `VOLATILE` marker so a rerun diff is readable.
#   * /usr/bin/grep is invoked by absolute path everywhere and named beside counts,
#     because a typed `grep` in an agent shell may be ugrep honouring .gitignore.
#   * Sections that need something absent from a clean `git archive HEAD`
#     extraction (the .git directory, the sibling cli-standards clone, cargo, the
#     network) print `SKIP <name>` and are not counted as failures.
#   * Exit status is the number of failed assertions, so 0 means zero failures.

set -uo pipefail

FAILURES=0
CHECKS=0
SKIPS=0
UA="rs-launch-blueprint-research/1.0 (R52 empirical check)"
RETRIEVED="$(date -u +%Y-%m-%d)"
ROOT="$(cd "$(dirname "$0")/../../../../../.." && pwd)"
RUN="$ROOT/research/runs/R52/2026-09-17T020714Z-4e96c68a620c"
WORK="${TMPDIR:-/tmp}/r52-verify.$$"
STANDARD="/Users/stevemorin/c/cli-standards/cli-design-standard.md"
STANDARD_BLOB="f9de0437baece3383e73ca2c5f48b7ab399b51c7"

# Adopter manifests are read at PINNED commits, never at a moving branch, so a
# rerun reads the same bytes.
CARGO_PIN="495c385d0875c4ba51eb72ea0448a2d4c018b8d4"
UV_PIN="6b40d9e51d246a1492731b59b19659c4b84c82a7"
STARSHIP_PIN="4ff40d066af2dd316dcb4742544254436e7e8190"

TOMLRS_PIN="3b81b06418e14f83d18eea2cbc3aee4d1a30eace"
TOML_VER="1.1.6+spec-1.1.0"
EDIT_VER="0.25.15+spec-1.1.0"

mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

say() { printf '%s\n' "$*"; }
hdr() { printf '\n======== %s ========\n' "$*"; }

fail() {
    FAILURES=$((FAILURES + 1))
    printf 'FAIL %s :: %s\n' "$1" "$2"
}

pass() { printf 'PASS %s :: %s\n' "$1" "$2"; }

skip() {
    SKIPS=$((SKIPS + 1))
    printf 'SKIP %s :: %s\n' "$1" "$2"
}

volatile() { printf 'VOLATILE %s :: %s (endpoint above, retrieved %s)\n' "$1" "$2" "$RETRIEVED"; }

# assert_has <id> <needle> <haystack-file>
assert_has() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qF -- "$2" "$3"; then
        pass "$1" "/usr/bin/grep -F found: $2"
    else
        fail "$1" "/usr/bin/grep -F did NOT find: $2 (in $3)"
    fi
}

# assert_hasre <id> <extended-regex> <haystack-file>
assert_hasre() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qE -- "$2" "$3"; then
        pass "$1" "/usr/bin/grep -E matched: $2"
    else
        fail "$1" "/usr/bin/grep -E did NOT match: $2 (in $3)"
    fi
}

# assert_absent <id> <extended-regex> <haystack-file>
assert_absent() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qE -- "$2" "$3"; then
        fail "$1" "/usr/bin/grep -E unexpectedly matched: $2 (in $3)"
    else
        pass "$1" "/usr/bin/grep -E correctly found no match for: $2"
    fi
}

# assert_eq <id> <expected> <actual>
assert_eq() {
    CHECKS=$((CHECKS + 1))
    if [ "$2" = "$3" ]; then
        pass "$1" "equal: $2"
    else
        fail "$1" "expected [$2] got [$3]"
    fi
}

# assert_ge <id> <floor> <actual-integer>
assert_ge() {
    CHECKS=$((CHECKS + 1))
    case "$3" in
        ''|*[!0-9]*) fail "$1" "not an integer: [$3]"; return ;;
    esac
    if [ "$3" -ge "$2" ]; then
        pass "$1" "$3 >= $2"
    else
        fail "$1" "expected >= $2, got $3"
    fi
}

net_ok=0
if /usr/bin/curl -fsS -m 25 -A "$UA" -o "$WORK/net.json" "https://crates.io/api/v1/crates/toml"; then
    net_ok=1
fi

gh_ok=0
if command -v gh >/dev/null 2>&1 && gh api rate_limit >/dev/null 2>&1; then
    gh_ok=1
fi

cargo_ok=0
if command -v cargo >/dev/null 2>&1; then
    cargo_ok=1
fi

hdr "0  toolchain, host, retrieval date"
say "retrieval date (UTC): $RETRIEVED"
say "uname: $(uname -srm)"
say "sw_vers: $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) $(sw_vers -buildVersion 2>/dev/null)"
if [ "$cargo_ok" = 1 ]; then
    say "rustc: $(rustc --version)"
    say "cargo: $(cargo --version)"
else
    say "rustc/cargo: absent"
fi
say "curl: $(/usr/bin/curl --version | head -1)"
say "grep: $(/usr/bin/grep --version | head -1)"
say "network reachable (crates.io): $net_ok"
say "gh authenticated: $gh_ok"
say "repository root: $ROOT"

hdr "1  repository facts read from files (survive a git archive extraction)"

# 1a — the prompt's Couplings block: `owns:` is empty, `consumes:` names R67.
sed -n '/^## Couplings/,/^## Questions/p' "$RUN/inputs/prompt.md" > "$WORK/couplings.txt"
say "--- inputs/prompt.md '## Couplings' ---"
cat "$WORK/couplings.txt"
assert_hasre S01 '^- owns:[[:space:]]*$' "$WORK/couplings.txt"
assert_has   S02 '- consumes: R67: error-taxonomy-exit-codes' "$WORK/couplings.txt"
assert_has   S03 '- effort: focused' "$WORK/couplings.txt"
assert_has   S04 '- engines: codex, opus' "$WORK/couplings.txt"

# 1b — the five `- assumes` lines this decision must carry, rebuilt from the live
#      registry and byte-compared with the lines in the decision.
UV=""
if command -v uv >/dev/null 2>&1; then
    UV="$(command -v uv)"
elif [ -x "$HOME/.local/bin/uv" ]; then
    UV="$HOME/.local/bin/uv"
fi
if [ -n "$UV" ]; then
    (cd "$ROOT" && "$UV" run --offline --no-project --no-python-downloads --no-cache python3 - <<'PY' > "$WORK/registry-assumes.txt"
import sys
sys.path.insert(0, "scripts")
import research_validation as v
from pathlib import Path
errors = []
registry = v._parse_parameters(Path("."), errors)
if errors:
    raise SystemExit("registry parse errors: %s" % errors)
for name in ("msrv-policy", "rust-edition", "target-os-matrix", "license", "error-taxonomy-exit-codes"):
    print("- assumes %s = %s" % (name, registry[name]["value"]))
PY
    ) && registry_built=1 || registry_built=0
else
    registry_built=0
fi

if [ "$registry_built" = 1 ]; then
    assert_eq S05 "5" "$(/usr/bin/grep -c '^- assumes ' "$WORK/registry-assumes.txt")"
    say "(count above from /usr/bin/grep -c, not a truncated listing)"
    decision="$RUN/review/DECISION.md"
    if [ -f "$decision" ]; then
        /usr/bin/grep '^- assumes ' "$decision" > "$WORK/decision-assumes.txt"
        CHECKS=$((CHECKS + 1))
        if diff -u "$WORK/registry-assumes.txt" "$WORK/decision-assumes.txt" > "$WORK/assumes.diff" 2>&1; then
            pass S06 "all five '- assumes' lines are byte-identical to docs/port/PARAMETERS.md"
        else
            fail S06 "'- assumes' lines differ from the registry:"
            cat "$WORK/assumes.diff"
        fi
        assert_eq S07 "0" "$(/usr/bin/grep -c '^- owns ' "$decision")"
        say "(S07: /usr/bin/grep -c counted the '- owns ' lines; R52 owns no registry parameter)"
        assert_eq S08 "1" "$(/usr/bin/grep -c '^re-verify: ' "$decision")"
        say "(S08: /usr/bin/grep -c counted the 're-verify: ' lines)"
    else
        skip S06 "review/DECISION.md not present yet (first run writes it, rerun compares it)"
        skip S07 "review/DECISION.md not present yet"
        skip S08 "review/DECISION.md not present yet"
    fi
else
    skip S05 "uv not found on PATH or at ~/.local/bin/uv; registry values not rebuilt"
    skip S06 "uv not found"
    skip S07 "uv not found"
    skip S08 "uv not found"
fi

# 1c — the licence ruling the task message cites. The Opus raw could not locate it
#      and asked the synthesizer to resolve the citation; this is that resolution.
assert_has S09 '### 2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)' "$ROOT/docs/port/OWNER-REVIEW.md"
assert_has S10 '## 5. The licence gate'"'"'s reach -- ANSWERED 2026-09-12 (Q7.B)' "$ROOT/docs/planning/p02/owner-decisions.md"
say "--- owner-decisions.md section 7 heading, which the Opus raw reported as the wrong pointer ---"
/usr/bin/grep -n '^## 7\.' "$ROOT/docs/planning/p02/owner-decisions.md"
assert_hasre S11 '^## 7\. The baseline-review questions' "$ROOT/docs/planning/p02/owner-decisions.md"

# 1d — the inherited ledger rows this item must not re-litigate.
say "--- docs/port/COMMONALITY.md rows F224 F225 F226 F227 F243 ---"
/usr/bin/grep -nE '^\| F(224|225|226|227|243) ' "$ROOT/docs/port/COMMONALITY.md" | cut -c1-320 > "$WORK/ledger.txt"
cat "$WORK/ledger.txt"
assert_eq    S12 "5" "$(/usr/bin/grep -cE '^\| F(224|225|226|227|243) ' "$ROOT/docs/port/COMMONALITY.md")"
say "(S12: /usr/bin/grep -c over the whole file, not a head-truncated listing)"
assert_hasre S13 '^[0-9]+:\| F224 .*COMMON . REUSE' "$WORK/ledger.txt"
assert_hasre S14 '^[0-9]+:\| F225 .*DIVERGENT' "$WORK/ledger.txt"
assert_hasre S15 '^[0-9]+:\| F226 .*DIVERGENT' "$WORK/ledger.txt"
assert_hasre S16 '^[0-9]+:\| F243 .*COMMON . REUSE' "$WORK/ledger.txt"

# 1e — the consumed prerequisite is the published, owner-accepted R67 decision.
r67_sha="$(shasum -a 256 "$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md" | cut -d' ' -f1)"
r67_expected="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["R67"]["decision"])' "$RUN/inputs/prerequisites.json")"
say "R67 DECISION.md sha256 on disk:      $r67_sha"
say "R67 sha256 in inputs/prerequisites: $r67_expected"
assert_eq S17 "$r67_expected" "$r67_sha"
assert_has S18 'RSLB202' "$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
assert_has S19 'RSLB104' "$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
assert_has S20 'RSLB203' "$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"

# 1f — the index slug this decision's title must use.
assert_hasre S21 '^\| R52 \| toml-crate \| bundle \| different \| DIVERGENT \| — \|' "$ROOT/research/CLAUDE.md"

hdr "2  org CLI Design Standard v1.4.14 at the pinned blob"
if [ -f "$STANDARD" ] && command -v git >/dev/null 2>&1; then
    actual_blob="$(git -C "$(dirname "$STANDARD")" rev-parse HEAD:cli-design-standard.md 2>/dev/null)"
    say "cli-design-standard.md blob at HEAD: $actual_blob"
    assert_eq  S22 "$STANDARD_BLOB" "$actual_blob"
    assert_has S23 '| **Version** | 1.4.14 |' "$STANDARD"
    say "--- R5.2 (config format) ---"
    /usr/bin/grep -n 'The canonical config format \*\*MUST\*\* be \*\*TOML\*\*' "$STANDARD" | cut -c1-200
    assert_has S24 'The canonical config format **MUST** be **TOML**' "$STANDARD"
    say "--- R5.8 (config validation and shared-state writes) ---"
    /usr/bin/grep -n 'precise file/key diagnostics' "$STANDARD" | cut -c1-260
    assert_has S25 'validate config files with precise file/key diagnostics' "$STANDARD"
    assert_has S26 'back up files before rewriting them' "$STANDARD"
    assert_has S27 'Tools that write shared config/state/cache **SHOULD** use atomic writes' "$STANDARD"
    # Appendix E DOES name Rust crates (clap, figment/config, directories/etcetera).
    # What it never names is a TOML crate, which is why the choice below is this item's.
    say "--- Appendix E, the Rust paragraph ---"
    sed -n '/^\*\*Rust — Clap (derive)\.\*\*/,/^$/p' "$STANDARD" > "$WORK/appendix-rust.txt"
    cat "$WORK/appendix-rust.txt"
    assert_has    S28 'figment'   "$WORK/appendix-rust.txt"
    assert_absent S29 'toml_edit|basic-toml|toml-span|toml = ' "$STANDARD"
    say "(S28 shows the standard DOES name Rust crates for other roles; S29 shows it names"
    say " no Rust TOML crate anywhere, so the crate choice here is not org-locked.)"
else
    skip S22 "cli-standards clone absent at $STANDARD"
    skip S23 "cli-standards clone absent"
    skip S24 "cli-standards clone absent"
    skip S25 "cli-standards clone absent"
    skip S26 "cli-standards clone absent"
    skip S27 "cli-standards clone absent"
    skip S28 "cli-standards clone absent"
    skip S29 "cli-standards clone absent"
fi

hdr "3  crates.io registry figures (endpoint + retrieval date on every line)"
if [ "$net_ok" = 1 ]; then
    for crate in toml toml_edit basic-toml taplo toml-span boml tomling; do
        say "--- GET https://crates.io/api/v1/crates/$crate (retrieved $RETRIEVED) ---"
        /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$crate.json" "https://crates.io/api/v1/crates/$crate" || {
            say "  request failed"
            continue
        }
        jq -r '"  crate.recent_downloads = \(.crate.recent_downloads)\n  crate.downloads       = \(.crate.downloads)\n  crate.max_stable_version = \(.crate.max_stable_version)"' "$WORK/$crate.json"
        volatile "$crate" "download counts above move on every rerun and are not asserted"
        say "--- GET https://crates.io/api/v1/crates/$crate/versions (newest yanked:false) ---"
        /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$crate-versions.json" "https://crates.io/api/v1/crates/$crate/versions" || {
            say "  request failed"
            continue
        }
        jq -r '[.versions[] | select(.yanked == false)][0] | "  num=\(.num) created_at=\(.created_at) rust_version=\(.rust_version) license=\(.license) edition=\(.edition)"' "$WORK/$crate-versions.json"
    done

    toml_num="$(jq -r '[.versions[] | select(.yanked == false)][0].num' "$WORK/toml-versions.json")"
    toml_rv="$(jq -r '[.versions[] | select(.yanked == false)][0].rust_version' "$WORK/toml-versions.json")"
    toml_ed="$(jq -r '[.versions[] | select(.yanked == false)][0].edition' "$WORK/toml-versions.json")"
    edit_num="$(jq -r '[.versions[] | select(.yanked == false)][0].num' "$WORK/toml_edit-versions.json")"
    edit_rv="$(jq -r '[.versions[] | select(.yanked == false)][0].rust_version' "$WORK/toml_edit-versions.json")"
    edit_ed="$(jq -r '[.versions[] | select(.yanked == false)][0].edition' "$WORK/toml_edit-versions.json")"
    basic_rv="$(jq -r '[.versions[] | select(.yanked == false)][0].rust_version' "$WORK/basic-toml-versions.json")"
    basic_num="$(jq -r '[.versions[] | select(.yanked == false)][0].num' "$WORK/basic-toml-versions.json")"

    # The two recommended versions. If upstream publishes a newer one these assertions
    # fail loudly, which is the re-verify trigger doing its job, not a defect in the log.
    assert_eq S30 "$TOML_VER" "$toml_num"
    assert_eq S31 "1.85"      "$toml_rv"
    assert_eq S32 "2024"      "$toml_ed"
    assert_eq S33 "$EDIT_VER" "$edit_num"
    assert_eq S34 "1.85"      "$edit_rv"
    assert_eq S35 "2024"      "$edit_ed"
    # Gate 2's own clause: "declared as rust-version in Cargo.toml". basic-toml declares none.
    assert_eq S36 "null"      "$basic_rv"
    assert_eq S37 "0.1.10"    "$basic_num"
    say "(S36 is the whole gate-2 exclusion of basic-toml: rust_version is null on the versions endpoint)"

    # Every published basic-toml version, not just the newest, declares no rust-version.
    basic_declared="$(jq -r '[.versions[] | select(.rust_version != null)] | length' "$WORK/basic-toml-versions.json")"
    assert_eq S38 "0" "$basic_declared"
    basic_total="$(jq -r '.versions | length' "$WORK/basic-toml-versions.json")"
    say "basic-toml published versions counted by jq: $basic_total; of those declaring rust_version: $basic_declared"
else
    for id in S30 S31 S32 S33 S34 S35 S36 S37 S38; do skip "$id" "crates.io unreachable"; done
fi

hdr "4  GitHub repository metadata and the issue-responsiveness conflict"
if [ "$gh_ok" = 1 ]; then
    for repo in toml-rs/toml dtolnay/basic-toml; do
        say "--- gh api repos/$repo (retrieved $RETRIEVED) ---"
        gh api "repos/$repo" --jq '"  stargazers_count=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)"' > "$WORK/$(echo "$repo" | tr / -).meta"
        cat "$WORK/$(echo "$repo" | tr / -).meta"
        volatile "$repo" "stargazers_count and pushed_at move on every rerun and are not asserted"
    done
    toml_archived="$(gh api repos/toml-rs/toml --jq '.archived')"
    basic_archived="$(gh api repos/dtolnay/basic-toml --jq '.archived')"
    assert_eq S40 "false" "$toml_archived"
    assert_eq S41 "true"  "$basic_archived"

    say "--- open issues via search/issues total_count, never open_issues_count ---"
    open_search="$(gh api "search/issues?q=repo:toml-rs/toml+is:issue+is:open" --jq '.total_count')"
    open_field="$(gh api repos/toml-rs/toml --jq '.open_issues_count')"
    say "  search/issues total_count = $open_search ; repos.open_issues_count = $open_field (the latter counts PRs)"
    volatile "toml-rs/toml" "open-issue totals move; recorded, not asserted"

    # THE ENGINE CONFLICT. Codex reported that none of the 10 most recently opened
    # issues carried a comment whose author_association was OWNER/MEMBER/COLLABORATOR,
    # and therefore recorded 10/10 unanswered. Opus reported median 0.67 days and
    # 3/10 unanswered. Re-query and print every comment's association.
    say "--- author_association of every comment on the ten issues both raws named ---"
    answered=0
    unanswered=0
    : > "$WORK/assoc.txt"
    for n in 1214 1213 1210 1206 1188 1181 1175 1172 1162 1158; do
        gh api "repos/toml-rs/toml/issues/$n/comments?per_page=100" \
            --jq '.[] | "'"issue $n"' \(.user.login) \(.author_association) \(.created_at)"' >> "$WORK/assoc.txt" 2>/dev/null
        hits="$(gh api "repos/toml-rs/toml/issues/$n/comments?per_page=100" \
            --jq '[.[] | select(.author_association == "OWNER" or .author_association == "MEMBER" or .author_association == "COLLABORATOR")] | length' 2>/dev/null)"
        case "$hits" in ''|*[!0-9]*) hits=0 ;; esac
        say "  issue $n : maintainer-association comments = $hits"
        if [ "$hits" -gt 0 ]; then answered=$((answered + 1)); else unanswered=$((unanswered + 1)); fi
    done
    say "--- raw associations ---"
    cat "$WORK/assoc.txt"
    say "issues with at least one OWNER/MEMBER/COLLABORATOR comment: $answered of 10"
    say "issues with none:                                          $unanswered of 10"
    # Codex's claim is that `answered` is 0. Any non-zero count refutes it.
    assert_ge S42 "1" "$answered"
    member_lines="$(/usr/bin/grep -cE ' (OWNER|MEMBER|COLLABORATOR) ' "$WORK/assoc.txt")"
    epage_lines="$(/usr/bin/grep -cE ' epage MEMBER ' "$WORK/assoc.txt")"
    say "maintainer-association comment lines counted by /usr/bin/grep -c: $member_lines"
    say "of those, lines reading ' epage MEMBER ' counted by /usr/bin/grep -c: $epage_lines"
    assert_ge S43 "1" "$member_lines"
    assert_hasre S44 ' epage MEMBER ' "$WORK/assoc.txt"
    # Every maintainer-association comment is epage's, or this fails and the decision's
    # "all of them by epage" sentence is wrong.
    assert_eq S45 "$member_lines" "$epage_lines"
else
    for id in S40 S41 S42 S43 S44 S45; do skip "$id" "gh not authenticated"; done
fi

hdr "5  advisories: RustSec pages, with a known-vulnerable control"
if [ "$net_ok" = 1 ]; then
    for pkg in toml toml_edit basic-toml time; do
        code="$(/usr/bin/curl -s -o "$WORK/rustsec-$pkg.html" -w '%{http_code}' -m 30 -A "$UA" "https://rustsec.org/packages/$pkg.html")"
        say "GET https://rustsec.org/packages/$pkg.html -> HTTP $code (retrieved $RETRIEVED)"
        printf '%s' "$code" > "$WORK/rustsec-$pkg.code"
    done
    # The control is what turns a 404 into evidence: a package WITH advisories returns
    # 200 and lists them, so 404 means "no advisory page exists", not "site is down".
    assert_eq S50 "200" "$(cat "$WORK/rustsec-time.code")"
    assert_has S51 "RUSTSEC-2020-0071" "$WORK/rustsec-time.html"
    assert_eq S52 "404" "$(cat "$WORK/rustsec-toml.code")"
    assert_eq S53 "404" "$(cat "$WORK/rustsec-toml_edit.code")"
    assert_eq S54 "404" "$(cat "$WORK/rustsec-basic-toml.code")"
    say "(S50/S51 are the control. Without them a 404 proves nothing, which is why the"
    say " Codex raw recorded gate 3 as unverified; with them it is evidence.)"
    for pkg in toml toml_edit; do
        say "--- POST https://api.osv.dev/v1/query {\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"crates.io\"}} ---"
        /usr/bin/curl -fsS -m 30 -A "$UA" -H 'Content-Type: application/json' \
            -d "{\"package\":{\"name\":\"$pkg\",\"ecosystem\":\"crates.io\"}}" \
            -o "$WORK/osv-$pkg.json" "https://api.osv.dev/v1/query" && cat "$WORK/osv-$pkg.json" && echo
    done
    osv_toml="$(jq -c '.' "$WORK/osv-toml.json" 2>/dev/null)"
    osv_edit="$(jq -c '.' "$WORK/osv-toml_edit.json" 2>/dev/null)"
    assert_eq S55 "{}" "$osv_toml"
    assert_eq S56 "{}" "$osv_edit"
else
    for id in S50 S51 S52 S53 S54 S55 S56; do skip "$id" "network unreachable"; done
fi

hdr "6  published .crate artifacts: manifests, features, unsafe posture"
if [ "$net_ok" = 1 ]; then
    fetch_crate() {
        name="$1"; version="$2"; enc="$3"
        /usr/bin/curl -fsSL -m 60 -A "$UA" -o "$WORK/$name.crate" \
            "https://static.crates.io/crates/$name/$name-$enc.crate" || return 1
        tar xzf "$WORK/$name.crate" -C "$WORK" || return 1
        say "unpacked $name-$version from https://static.crates.io/crates/$name/$name-$enc.crate (retrieved $RETRIEVED)"
    }
    fetch_crate toml      "$TOML_VER" "1.1.6%2Bspec-1.1.0"
    fetch_crate toml_edit "$EDIT_VER" "0.25.15%2Bspec-1.1.0"

    T="$WORK/toml-$TOML_VER"
    E="$WORK/toml_edit-$EDIT_VER"

    if [ -d "$T" ]; then
        say "--- toml $TOML_VER Cargo.toml (published manifest) ---"
        /usr/bin/grep -nE '^(rust-version|edition|license|name|version)|^default =|^\[dependencies\.' "$T/Cargo.toml" | cut -c1-200
        assert_has S60 'rust-version = "1.85"' "$T/Cargo.toml"
        assert_has S61 'edition = "2024"'      "$T/Cargo.toml"
        assert_has S62 'license = "MIT OR Apache-2.0"' "$T/Cargo.toml"
        sed -n '/^default = \[/,/^\]/p' "$T/Cargo.toml" > "$WORK/toml-default.txt"
        say "--- toml [features] default (published manifest writes it multi-line) ---"
        cat "$WORK/toml-default.txt"
        assert_has S63a '"std"'     "$WORK/toml-default.txt"
        assert_has S63b '"serde"'   "$WORK/toml-default.txt"
        assert_has S63c '"parse"'   "$WORK/toml-default.txt"
        assert_has S63d '"display"' "$WORK/toml-default.txt"
        assert_absent S63e 'preserve_order' "$WORK/toml-default.txt"
        say "(S63e: preserve_order is NOT a default feature of toml; enabling it would pull"
        say " dep:indexmap into toml, which is why this decision leaves it off.)"
        assert_hasre S63f 'preserve_order = \[' "$T/Cargo.toml"
        # The 1.0 restructure: toml no longer depends on toml_edit. This is what
        # dissolves the historical footprint argument for basic-toml.
        assert_absent S64 '^\[dependencies\.toml_edit\]' "$T/Cargo.toml"
        assert_hasre  S65 '^\[dependencies\.(serde_core|toml_parser|toml_writer|toml_datetime|serde_spanned|winnow)\]' "$T/Cargo.toml"
        say "--- toml unsafe posture ---"
        /usr/bin/grep -n 'forbid(unsafe_code)' "$T/src/lib.rs" | cut -c1-160
        assert_has S66 '#![forbid(unsafe_code)]' "$T/src/lib.rs"
        unsafe_toml="$(/usr/bin/grep -rc 'unsafe' "$T/src" | /usr/bin/grep -v ':0$' | wc -l | tr -d ' ')"
        say "files under toml/src containing the token 'unsafe' (/usr/bin/grep -rc, zero-count files removed): $unsafe_toml"
        say "--- toml conformance harnesses wired into the published manifest ---"
        /usr/bin/grep -nE 'toml-test|compliance' "$T/Cargo.toml" | cut -c1-200
        assert_hasre S67 'toml.test.(harness|data)' "$T/Cargo.toml"
    else
        for id in S60 S61 S62 S63a S63b S63c S63d S63e S63f S64 S65 S66 S67; do skip "$id" "toml artifact not unpacked"; done
    fi

    if [ -d "$E" ]; then
        say "--- toml_edit $EDIT_VER Cargo.toml (published manifest) ---"
        /usr/bin/grep -nE '^(rust-version|edition|license|name|version)|^default =|^serde =|^\[dependencies\.' "$E/Cargo.toml" | cut -c1-200
        assert_has S70 'rust-version = "1.85"' "$E/Cargo.toml"
        assert_has S71 'edition = "2024"'      "$E/Cargo.toml"
        assert_has S72 'license = "MIT OR Apache-2.0"' "$E/Cargo.toml"
        sed -n '/^default = \[/,/^\]/p' "$E/Cargo.toml" > "$WORK/edit-default.txt"
        say "--- toml_edit [features] default ---"
        cat "$WORK/edit-default.txt"
        assert_has S73a '"parse"'   "$WORK/edit-default.txt"
        assert_has S73b '"display"' "$WORK/edit-default.txt"
        assert_absent S73c 'serde'  "$WORK/edit-default.txt"
        say "(S73c: serde is NOT default for toml_edit. Cargo enables it; this template does"
        say " not, because toml owns the typed read.)"
        # indexmap is NOT optional, so it enters the tree at any feature selection.
        say "--- toml_edit indexmap dependency block ---"
        sed -n '/^\[dependencies\.indexmap\]/,/^\[/p' "$E/Cargo.toml" | head -12
        assert_hasre  S74 '^\[dependencies\.indexmap\]' "$E/Cargo.toml"
        sed -n '/^\[dependencies\.indexmap\]/,/^\[/p' "$E/Cargo.toml" > "$WORK/indexmap-block.txt"
        assert_absent S76 'optional = true' "$WORK/indexmap-block.txt"
        say "--- toml_edit unsafe posture: observed absence, not a compiler-enforced forbid ---"
        edit_forbid="$(/usr/bin/grep -c 'forbid(unsafe_code)' "$E/src/lib.rs")"
        say "forbid(unsafe_code) occurrences in toml_edit/src/lib.rs (/usr/bin/grep -c): $edit_forbid"
        assert_eq S77 "0" "$edit_forbid"
        unsafe_hits="$(/usr/bin/grep -rlE '\bunsafe\b' "$E/src" | wc -l | tr -d ' ')"
        say "files under toml_edit/src containing the token 'unsafe' (/usr/bin/grep -rl | wc -l): $unsafe_hits"
        assert_eq S78 "0" "$unsafe_hits"
    else
        for id in S70 S71 S72 S73a S73b S73c S74 S76 S77 S78; do skip "$id" "toml_edit artifact not unpacked"; done
    fi
else
    for id in S60 S61 S62 S63a S63b S63c S63d S63e S63f S64 S65 S66 S67 S70 S71 S72 S73a S73b S73c S74 S76 S77 S78; do skip "$id" "network unreachable"; done
fi

hdr "7  behavioural probe: the two crates run on three literal strings"
if [ "$cargo_ok" = 1 ] && [ "$net_ok" = 1 ]; then
    P="$WORK/probe"
    mkdir -p "$P/src"
    cat > "$P/Cargo.toml" <<EOF
[package]
name = "r52probe"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
serde = { version = "1", features = ["derive"] }
toml = "=1.1.6"
toml_edit = "=0.25.15"
EOF
    cat > "$P/src/main.rs" <<'RUST'
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize, Serialize)]
struct Probe { output: Option<Out> }
#[derive(Debug, Deserialize, Serialize)]
struct Out { color: Option<String>, format: Option<String> }

const SRC: &str = "# header comment\n[output]\n# why auto\ncolor = \"auto\"\nformat = \"text\"   # trailing note\n";
const BAD: &str = "[output]\ncolor = \n";

fn main() {
    let typed: Probe = toml::from_str(SRC).expect("typed read");
    println!("P1_TYPED_READ = {typed:?}");

    let re = toml::to_string_pretty(&typed).expect("serialize");
    println!("P2_PLAIN_KEEPS_HEADER = {}", re.contains("# header comment"));
    println!("P2_PLAIN_KEEPS_TRAILING = {}", re.contains("# trailing note"));

    match toml::from_str::<Probe>(BAD) {
        Ok(_) => println!("P3_TOML_DE_ERROR = none"),
        Err(e) => {
            println!("P3_TOML_DE_SPAN = {:?}", e.span());
            println!("P3_TOML_DE_FIRSTLINE = {}", e.to_string().lines().next().unwrap_or(""));
            println!("P3_TOML_DE_MESSAGE = {}", e.message());
        }
    }

    match BAD.parse::<toml_edit::DocumentMut>() {
        Ok(_) => println!("P4_EDIT_ERROR = none"),
        Err(e) => {
            println!("P4_EDIT_SPAN = {:?}", e.span());
            println!("P4_EDIT_FIRSTLINE = {}", e.to_string().lines().next().unwrap_or(""));
        }
    }

    let mut doc: toml_edit::DocumentMut = SRC.parse().expect("doc parse");
    println!("P5_UNMODIFIED_ROUNDTRIP_IDENTICAL = {}", doc.to_string() == SRC);

    let mut naive = doc.clone();
    naive["output"]["format"] = toml_edit::value("json");
    let n = naive.to_string();
    println!("P6_NAIVE_KEEPS_HEADER = {}", n.contains("# header comment"));
    println!("P6_NAIVE_KEEPS_PERKEY = {}", n.contains("# why auto"));
    println!("P6_NAIVE_KEEPS_TRAILING = {}", n.contains("# trailing note"));
    println!("P6_NAIVE_APPLIED = {}", n.contains("format = \"json\""));

    if let toml_edit::Item::Value(v) = &mut doc["output"]["format"] {
        let decor = v.decor().clone();
        *v = toml_edit::Value::from("json");
        *v.decor_mut() = decor;
    }
    let d = doc.to_string();
    println!("P7_DECOR_KEEPS_HEADER = {}", d.contains("# header comment"));
    println!("P7_DECOR_KEEPS_PERKEY = {}", d.contains("# why auto"));
    println!("P7_DECOR_KEEPS_TRAILING = {}", d.contains("# trailing note"));
    println!("P7_DECOR_APPLIED = {}", d.contains("format = \"json\""));

    let reread: Probe = toml::from_str(&d).expect("re-read edited");
    println!("P8_REREAD = {reread:?}");
}
RUST
    say "probe crate: $P (throwaway; nothing is written into the repository)"
    if (cd "$P" && cargo run --quiet > "$WORK/probe.out" 2>"$WORK/probe.err"); then
        cat "$WORK/probe.out"
        assert_has S80 'P1_TYPED_READ = Probe { output: Some(Out { color: Some("auto"), format: Some("text") }) }' "$WORK/probe.out"
        assert_has S81 'P2_PLAIN_KEEPS_HEADER = false'   "$WORK/probe.out"
        assert_has S82 'P2_PLAIN_KEEPS_TRAILING = false' "$WORK/probe.out"
        assert_has S83 'P3_TOML_DE_SPAN = Some(17..17)'  "$WORK/probe.out"
        assert_has S84 'P3_TOML_DE_FIRSTLINE = TOML parse error at line 2, column 9' "$WORK/probe.out"
        assert_has S85 'P4_EDIT_SPAN = Some(17..17)'     "$WORK/probe.out"
        assert_has S86 'P4_EDIT_FIRSTLINE = TOML parse error at line 2, column 9' "$WORK/probe.out"
        assert_has S87 'P5_UNMODIFIED_ROUNDTRIP_IDENTICAL = true' "$WORK/probe.out"
        assert_has S88 'P6_NAIVE_KEEPS_TRAILING = false' "$WORK/probe.out"
        assert_has S89 'P6_NAIVE_APPLIED = true'         "$WORK/probe.out"
        assert_has S90 'P7_DECOR_KEEPS_HEADER = true'    "$WORK/probe.out"
        assert_has S91 'P7_DECOR_KEEPS_PERKEY = true'    "$WORK/probe.out"
        assert_has S92 'P7_DECOR_KEEPS_TRAILING = true'  "$WORK/probe.out"
        assert_has S93 'P7_DECOR_APPLIED = true'         "$WORK/probe.out"
        assert_has S94 'P8_REREAD = Probe { output: Some(Out { color: Some("auto"), format: Some("json") }) }' "$WORK/probe.out"

        say "--- cargo tree -e normal (both members) ---"
        (cd "$P" && cargo tree -e normal 2>/dev/null) | tee "$WORK/tree.txt"
        say "--- cargo tree -e normal -p toml (does toml still pull toml_edit?) ---"
        (cd "$P" && cargo tree -e normal -p toml 2>/dev/null) | tee "$WORK/tree-toml.txt"
        assert_absent S95 'toml_edit' "$WORK/tree-toml.txt"
        # Gate 5's async-coupling clause, asserted rather than merely printed.
        assert_absent S95a 'tokio|async-std|smol |futures|mio|executor' "$WORK/tree.txt"
        say "(S95a is fitness gate 5's async clause: no runtime, executor or futures crate"
        say " appears anywhere in the resolved graph for either member.)"
        added="$(/usr/bin/grep -cE '(toml_edit|indexmap|equivalent|hashbrown) v' "$WORK/tree.txt")"
        say "tree lines naming toml_edit/indexmap/equivalent/hashbrown (/usr/bin/grep -cE): $added"
        assert_hasre S96 'indexmap v2' "$WORK/tree.txt"
        assert_hasre S97 'hashbrown v0' "$WORK/tree.txt"
        assert_hasre S98 'equivalent v1' "$WORK/tree.txt"

        say "--- whole-graph MSRV, excluding the probe package itself ---"
        tree_msrv="$( (cd "$P" && cargo metadata --format-version 1 --offline 2>/dev/null) \
            | jq -r '[.packages[] | select(.name != "r52probe") | select(.rust_version != null) | .rust_version] | max')"
        say "maximum rust_version across the resolved graph = $tree_msrv"
        assert_eq S99 "1.85.0" "$tree_msrv"
        tree_minor="$(printf '%s' "$tree_msrv" | cut -d. -f2)"
        assert_ge S99b "0" "$tree_minor"
        CHECKS=$((CHECKS + 1))
        if [ "$tree_minor" -le 96 ]; then
            pass S99c "graph MSRV minor $tree_minor <= the 1.96 floor"
        else
            fail S99c "graph MSRV minor $tree_minor exceeds the 1.96 floor"
        fi
        say "(policy floor is stable-minus-2; with stable 1.98.x the floor is 1.96, so 1.85 clears it)"
        say "--- current published stable channel ---"
        /usr/bin/curl -fsS -m 30 -A "$UA" "https://raw.githubusercontent.com/rust-lang/rust/stable/src/version" \
            | tee "$WORK/stable.txt"
        assert_hasre S100 '^1\.[0-9]+\.[0-9]+' "$WORK/stable.txt"
    else
        say "probe build failed:"
        cat "$WORK/probe.err"
        for id in S80 S81 S82 S83 S84 S85 S86 S87 S88 S89 S90 S91 S92 S93 S94 S95 S95a S96 S97 S98 S99 S99b S99c S100; do
            fail "$id" "probe crate did not build or run"
        done
    fi
else
    for id in S80 S81 S82 S83 S84 S85 S86 S87 S88 S89 S90 S91 S92 S93 S94 S95 S95a S96 S97 S98 S99 S99b S99c S100; do
        skip "$id" "cargo and/or network unavailable"
    done
fi

hdr "8  adopter manifests, read at pinned commits"
if [ "$gh_ok" = 1 ]; then
    read_manifest() {
        repo="$1"; pin="$2"; out="$3"
        gh api "repos/$repo/contents/Cargo.toml?ref=$pin" --jq '.content' 2>/dev/null | base64 -d > "$out"
        say "--- $repo Cargo.toml @ $pin (retrieved $RETRIEVED) ---"
        /usr/bin/grep -nE '^(toml|toml_edit)[[:space:]]*=' "$out" | cut -c1-200
    }
    read_manifest rust-lang/cargo  "$CARGO_PIN"    "$WORK/cargo.toml"
    read_manifest astral-sh/uv     "$UV_PIN"       "$WORK/uv.toml"
    read_manifest starship/starship "$STARSHIP_PIN" "$WORK/starship.toml"
    assert_hasre S110 '^toml = \{ version = "1\.' "$WORK/cargo.toml"
    assert_hasre S111 '^toml_edit = \{ version = "0\.25\.' "$WORK/cargo.toml"
    assert_hasre S112 '^toml = \{ version = "1\.'  "$WORK/uv.toml"
    assert_hasre S113 '^toml_edit = \{ version = "0\.25\.' "$WORK/uv.toml"
    assert_hasre S114 '^toml = \{ version = "1\.'  "$WORK/starship.toml"
    assert_hasre S115 '^toml_edit = "0\.25\.'      "$WORK/starship.toml"
    say "(All three well-regarded adopters ship BOTH crates. That is the practice"
    say " evidence for the two-member stack, and it is also the compatibility proof.)"
    say "--- the rust-lang/team Cargo roster, which is what makes epage's docs authoritative ---"
    /usr/bin/curl -fsS -m 30 -A "$UA" "https://raw.githubusercontent.com/rust-lang/team/master/teams/cargo.toml" \
        -o "$WORK/cargo-team.toml" && /usr/bin/grep -n 'epage' "$WORK/cargo-team.toml" | cut -c1-120
    assert_has S116 'epage' "$WORK/cargo-team.toml"
else
    for id in S110 S111 S112 S113 S114 S115 S116; do skip "$id" "gh not authenticated"; done
fi

hdr "9  upstream CI: gate 4 (OS matrix) and gate 2's 'tested in CI' clause"
if [ "$gh_ok" = 1 ]; then
    say "--- toml-rs/toml .github/workflows/ci.yml @ $TOMLRS_PIN (retrieved $RETRIEVED) ---"
    gh api "repos/toml-rs/toml/contents/.github/workflows/ci.yml?ref=$TOMLRS_PIN" --jq '.content' 2>/dev/null \
        | base64 -d > "$WORK/tomlrs-ci.yml"
    /usr/bin/grep -nE 'os: \[|^  msrv:|Check MSRV|runs-on' "$WORK/tomlrs-ci.yml" | cut -c1-140
    assert_has S120 'os: ["ubuntu-latest", "windows-latest", "macos-latest"]' "$WORK/tomlrs-ci.yml"
    assert_hasre S121 '^  msrv:' "$WORK/tomlrs-ci.yml"
    assert_has S122 'Check MSRV' "$WORK/tomlrs-ci.yml"
    say "(S120 satisfies gate 4 for BOTH members: one workspace, one workflow, and it"
    say " exceeds the required ubuntu-latest + macos-latest. S121/S122 are the second"
    say " half of the msrv-policy clause, 'tested in CI', met upstream as well as by"
    say " the template's own planned MSRV job.)"
else
    for id in S120 S121 S122; do skip "$id" "gh not authenticated"; done
fi

hdr "summary"
say "assertions run:     $CHECKS"
say "assertions failed:  $FAILURES"
say "sections skipped:   $SKIPS"
say "Exit status is the failure count, so 0 means every assertion above passed."
exit "$FAILURES"
