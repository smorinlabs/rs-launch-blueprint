#!/usr/bin/env bash
# R20 empirical check — verify raw-report claims about action pinning.
# Verification only: reads pinned sources, resolves refs, queries recorded endpoints.
# It does not build a workflow, a scaffold or a fixture.
set -u

PY=~/c/py-launch-blueprint
TS=~/c/ts-launch-blueprint
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
PY_HEAD=c1216c6089f768ae0a3f3a465460d2d384f5fa44
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
UA='rs-launch-blueprint-research (steve@conceptm.com)'

hr() { printf '\n===== %s =====\n' "$1"; }

hr "0. toolchain and environment"
date -u +'UTC now: %Y-%m-%dT%H:%M:%SZ'
rustc --version
cargo --version
printf 'OS: macOS %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
gh --version | head -1
printf 'current stable per channel manifest: '
curl -sS --max-time 30 https://static.rust-lang.org/dist/channel-rust-stable.toml \
  | awk '/^\[pkg.rust\]/{f=1} f&&/^version/{print; exit}'
curl -sS --max-time 30 https://static.rust-lang.org/dist/channel-rust-stable.toml \
  | awk '/^date =/{print "manifest date: " $0; exit}'

hr "1. py-launch-blueprint inventory AT THE PROGRAMME PIN ($PY_PIN)"
git -C "$PY" cat-file -t "$PY_PIN"
echo "-- workflow files at the pin --"
git -C "$PY" ls-tree -r --name-only "$PY_PIN" .github/workflows/
echo "-- every uses: clause at the pin (file:line: clause) --"
for f in $(git -C "$PY" ls-tree -r --name-only "$PY_PIN" .github/workflows/); do
  git -C "$PY" show "$PY_PIN:$f" | grep -nE '^\s*#?\s*-?\s*uses:' | sed "s|^|$f:|"
done
echo "-- classification at the pin: any 40-hex SHA pin? --"
for f in $(git -C "$PY" ls-tree -r --name-only "$PY_PIN" .github/workflows/); do
  git -C "$PY" show "$PY_PIN:$f" | grep -nE '^\s*#?\s*-?\s*uses:.*@[0-9a-f]{40}' | sed "s|^|$f:|"
done
echo "(empty above = no SHA pin anywhere at the pin)"
echo "-- publish-container.yml present at the pin? --"
git -C "$PY" ls-tree -r --name-only "$PY_PIN" .github/workflows/ | grep -c 'publish-container' || true

hr "2. py-launch-blueprint AT THE CLONE HEAD ($PY_HEAD) — labelled, not the pin"
git -C "$PY" rev-parse HEAD
git -C "$PY" merge-base --is-ancestor "$PY_PIN" HEAD && echo "pin IS an ancestor of HEAD"
echo "-- SHA-pinned clauses at HEAD only --"
git -C "$PY" grep -nE '^\s*#?\s*-?\s*uses:.*@[0-9a-f]{40}' "$PY_HEAD" -- .github/workflows/ || echo "(none)"
echo "-- every astral-sh/setup-uv shape at HEAD --"
git -C "$PY" grep -nE 'setup-uv@' "$PY_HEAD" -- .github/workflows/ || echo "(none)"

hr "3. ts-launch-blueprint inventory AT THE PROGRAMME PIN ($TS_PIN)"
git -C "$TS" cat-file -t "$TS_PIN"
echo "-- every uses: clause at the pin (including commented-out) --"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -nE '^\s*#?\s*-?\s*uses:' | sed "s|^|$f:|"
done
echo "-- third-party (non actions/, non github/) clauses NOT SHA-pinned, at the pin --"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -nE '^\s*-?\s*uses:' | grep -vE 'uses:\s*\./' \
    | grep -vE 'uses:\s*(actions|github)/' | grep -vE '@[0-9a-f]{40}' | sed "s|^|$f:|"
done
echo "-- official actions/* clauses that ARE SHA-pinned, at the pin --"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -nE '^\s*-?\s*uses:\s*(actions|github)/.*@[0-9a-f]{40}' | sed "s|^|$f:|"
done
echo "-- zizmor config or workflow at the ts pin? --"
git -C "$TS" ls-tree -r --name-only "$TS_PIN" | grep -i zizmor || echo "(no zizmor file at the ts pin)"
echo "-- workflow comments citing zizmor audits at the ts pin --"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -niE 'zizmor' | sed "s|^|$f:|"
done

hr "4. resolve what the pins actually refer to"
echo "-- smorinlabs/contributors-please-action tag v1.3.9 -> commit? --"
gh api "repos/smorinlabs/contributors-please-action/git/ref/tags/v1.3.9" \
  --jq '{ref:.ref, type:.object.type, sha:.object.sha}' 2>&1
gh api "repos/smorinlabs/contributors-please-action/git/matching-refs/tags/v1" \
  --jq '.[] | {ref:.ref, sha:.object.sha}' 2>&1
echo "-- ts pins contributors-please-action at which sha? --"
git -C "$TS" show "$TS_PIN:.github/workflows/update-contributors.yml" | grep -nE 'contributors-please-action@'
echo "-- actions/dependency-review-action: does a v5 major tag exist TODAY? --"
gh api "repos/actions/dependency-review-action/git/matching-refs/tags/v5" --jq '.[] | .ref' 2>&1
echo "-- ...and all its tags (first 40) --"
gh api "repos/actions/dependency-review-action/git/matching-refs/tags" --jq '.[].ref' 2>&1 | head -40
echo "-- smorinlabs/difftree-action: does a v0 major tag exist? --"
gh api "repos/smorinlabs/difftree-action/git/matching-refs/tags" --jq '.[] | {ref:.ref, sha:.object.sha}' 2>&1 | head -20

hr "5. F062 precondition: is the difftree workflow byte-identical to the vendor canonical file?"
mkdir -p /tmp/r20chk
gh api "repos/smorinlabs/difftree-action/contents/examples/difftree-pr-comment.yml" --jq '.content' 2>&1 \
  | base64 --decode > /tmp/r20chk/vendor-canonical.yml 2>/dev/null
echo "vendor canonical bytes: $(wc -c < /tmp/r20chk/vendor-canonical.yml 2>/dev/null || echo 'FETCH FAILED')"
head -5 /tmp/r20chk/vendor-canonical.yml 2>/dev/null
git -C "$PY" show "$PY_PIN:.github/workflows/difftree-pr-comment.yml" > /tmp/r20chk/py-pin.yml 2>/dev/null \
  && echo "py at pin bytes: $(wc -c < /tmp/r20chk/py-pin.yml)" || echo "py: file absent at pin"
git -C "$TS" show "$TS_PIN:.github/workflows/difftree-pr-comment.yml" > /tmp/r20chk/ts-pin.yml 2>/dev/null \
  && echo "ts at pin bytes: $(wc -c < /tmp/r20chk/ts-pin.yml)" || echo "ts: file absent at pin"
echo "-- diff py(pin) vs ts(pin) --"
diff /tmp/r20chk/py-pin.yml /tmp/r20chk/ts-pin.yml && echo "IDENTICAL"
echo "-- diff vendor canonical vs ts(pin) --"
diff /tmp/r20chk/vendor-canonical.yml /tmp/r20chk/ts-pin.yml && echo "IDENTICAL"
echo "-- does the vendor publish a SHA-pinned variant of the example? --"
gh api "repos/smorinlabs/difftree-action/contents/examples" --jq '.[].name' 2>&1
echo "-- the uses: clauses inside the vendor canonical file --"
grep -nE '^\s*-?\s*uses:' /tmp/r20chk/vendor-canonical.yml 2>/dev/null

hr "6. zizmor: figures, gates, and the policy grammar claim"
curl -sS --max-time 30 -A "$UA" https://crates.io/api/v1/crates/zizmor \
  | python3 -c 'import sys,json; d=json.load(sys.stdin)["crate"]; print("recent_downloads(90d):", d["recent_downloads"], "| downloads(all):", d["downloads"], "| max_stable_version:", d["max_stable_version"])'
curl -sS --max-time 30 -A "$UA" https://crates.io/api/v1/crates/zizmor/versions \
  | python3 -c 'import sys,json; vs=[v for v in json.load(sys.stdin)["versions"] if not v["yanked"]]; v=vs[0]; print("newest unyanked:", v["num"], v["created_at"], "license:", v["license"])'
echo "-- Cargo.toml rust-version / edition / license (main) --"
curl -sS --max-time 30 https://raw.githubusercontent.com/zizmorcore/zizmor/main/Cargo.toml \
  | grep -nE '^(edition|rust-version|license|version)' | head -8
echo "-- repo standing --"
gh api repos/zizmorcore/zizmor --jq '{stars:.stargazers_count, archived:.archived, pushed_at:.pushed_at, license:.license.spdx_id}' 2>&1
gh api "search/issues?q=repo:zizmorcore/zizmor+is:issue+is:open" --jq '.total_count' 2>&1
echo "-- release assets (OS gate) --"
gh api repos/zizmorcore/zizmor/releases/latest --jq '{tag:.tag_name, published:.published_at, assets:[.assets[].name]}' 2>&1
echo "-- RustSec: 404 must discriminate. zizmor (expect 404) vs a crate with a known advisory (expect 200) --"
printf 'rustsec zizmor:  '; curl -sS -o /dev/null -w '%{http_code}\n' --max-time 30 https://rustsec.org/packages/zizmor.html
printf 'rustsec openssl: '; curl -sS -o /dev/null -w '%{http_code}\n' --max-time 30 https://rustsec.org/packages/openssl.html
printf 'rustsec time:    '; curl -sS -o /dev/null -w '%{http_code}\n' --max-time 30 https://rustsec.org/packages/time.html
echo "-- GitHub advisory DB, rust ecosystem, affects zizmor --"
gh api "advisories?ecosystem=rust&affects=zizmor" --jq 'length' 2>&1
echo "-- unpinned-uses policy grammar and the v1.20.0 default change, from maintainer docs --"
curl -sS --max-time 30 https://raw.githubusercontent.com/zizmorcore/zizmor/main/docs/audits.md > /tmp/r20chk/audits.md
echo "audits.md bytes: $(wc -c < /tmp/r20chk/audits.md)"
grep -nE 'v1\.20\.0|hash-pin|ref-pin|unpinned-uses' /tmp/r20chk/audits.md | head -40

hr "7. Dependabot: comment idiom and the open comment-drift issues"
for n in 7912 13466 14716; do
  gh api "repos/dependabot/dependabot-core/issues/$n" \
    --jq '{number:.number, state:.state, created_at:.created_at, title:.title}' 2>&1
done

hr "8. GitHub secure-use guidance: does the SHA recommendation carve out actions/*?"
curl -sSL --max-time 30 -A "$UA" https://docs.github.com/en/actions/reference/security/secure-use \
  > /tmp/r20chk/secure-use.html
echo "secure-use bytes: $(wc -c < /tmp/r20chk/secure-use.html)"
python3 - <<'PY'
import re,html
t=open('/tmp/r20chk/secure-use.html',encoding='utf-8',errors='replace').read()
t=re.sub(r'<script.*?</script>','',t,flags=re.S)
t=re.sub(r'<style.*?</style>','',t,flags=re.S)
t=re.sub(r'<[^>]+>',' ',t)
t=html.unescape(t)
t=re.sub(r'\s+',' ',t)
for kw in ['full-length commit SHA','third-party','immutable release','tag can be moved','Pinning an action']:
    for m in re.finditer(re.escape(kw),t):
        print(f'[{kw}] ...{t[max(0,m.start()-260):m.start()+260]}...')
        print('---')
PY

hr "9. Opus lead 2 spot-check: advisories on anthropics/claude-code-action"
gh api "repos/anthropics/claude-code-action/security-advisories" --jq '[.[] | {ghsa:.ghsa_id, cve:.cve_id, published:.published_at, summary:.summary}]' 2>&1
gh api "advisories?ecosystem=actions&affects=anthropics/claude-code-action" --jq '[.[] | {ghsa:.ghsa_id, cve:.cve_id, published:.published_at}]' 2>&1

hr "done"

# ---------------------------------------------------------------------------
# Addenda 1-4 were appended to the revision-1 log by follow-up commands in the
# same session; they are folded back in here, with their original headings and
# framing restored, so that a re-run emits every command and every
# interpretation line the revision-1 log carries.
# Addendum 1 corrects a false negative: git grep -E does not honour \s.
# ---------------------------------------------------------------------------
hr "ADDENDUM 1"
echo "-- CORRECTION to section 2: git grep -E does not honour \\s, so that pattern was a false negative."
echo "-- re-run with a POSIX class: SHA-pinned clauses at py HEAD ${PY_HEAD:0:8} --"
git -C "$PY" grep -nE 'uses:[[:space:]]*[^[:space:]]+@[0-9a-f]{40}' "$PY_HEAD" -- .github/workflows/
echo "-- same pattern at the py PIN ${PY_PIN:0:8} (expect no rows) --"
git -C "$PY" grep -nE 'uses:[[:space:]]*[^[:space:]]+@[0-9a-f]{40}' "$PY_PIN" -- .github/workflows/ \
  || echo "(no rows: py is entirely ref-pinned at the pin)"
echo
echo "-- actions/dependency-review-action: bare major tags v4 / v5 --"
gh api "repos/actions/dependency-review-action/git/matching-refs/tags/v4" --jq '.[].ref' 2>&1 | head
echo "(matching-refs/tags/v5 returned only refs/tags/v5.0.0 in section 4: no bare v5 ref exists)"
echo "-- py at its pin references dependency-review-action how? --"
git -C "$PY" show "$PY_PIN:.github/workflows/dependency-review.yml" | grep -nE 'dependency-review-action'
echo
echo "-- OpenSSF Scorecard Pinned-Dependencies: does it distinguish GitHub-owned from third-party? --"
curl -sS --max-time 40 https://raw.githubusercontent.com/ossf/scorecard/main/docs/checks.md > /tmp/r20chk/scorecard.md
printf 'checks.md bytes: %s\n' "$(wc -c < /tmp/r20chk/scorecard.md)"
grep -h '^## Pinned-Dependencies' /tmp/r20chk/scorecard.md
echo
echo "-- zizmor: is a per-file / per-line suppression available (needed for the F062 exemption)? --"
curl -sS --max-time 40 https://raw.githubusercontent.com/zizmorcore/zizmor/main/docs/usage.md > /tmp/r20chk/usage.md
printf 'usage.md bytes: %s\n' "$(wc -c < /tmp/r20chk/usage.md)"
grep -nE 'zizmor: ignore|ignore\[|Ignoring|ignore rules' /tmp/r20chk/usage.md | head -20
echo
echo "-- zizmor unpinned-uses config grammar, verbatim --"
sed -n '2229,2300p' /tmp/r20chk/audits.md

hr "ADDENDUM 2"
echo "-- OpenSSF Scorecard Pinned-Dependencies section, verbatim (awk in addendum 1 mis-matched the heading) --"
grep -n '^## Pinned-Dependencies' /tmp/r20chk/scorecard.md
start=$(grep -n '^## Pinned-Dependencies' /tmp/r20chk/scorecard.md | cut -d: -f1)
end=$(awk -v s="$start" 'NR>s && /^## /{print NR; exit}' /tmp/r20chk/scorecard.md)
sed -n "${start},$((end-1))p" /tmp/r20chk/scorecard.md
grep -inE 'GitHub-owned|third.party' /tmp/r20chk/scorecard.md | awk -F: -v s="$start" -v e="$end" '$1>=s && $1<e' \
  || echo "(no official/third-party distinction anywhere in the Pinned-Dependencies section)"
echo
echo "-- zizmor path-scoped ignore rules in zizmor.yml (the only exemption form that preserves byte-identity of a vendor file) --"
sed -n '880,935p' /tmp/r20chk/usage.md

hr "ADDENDUM 3"
echo "-- counts, py at the pin --"
for f in $(git -C "$PY" ls-tree -r --name-only "$PY_PIN" .github/workflows/); do git -C "$PY" show "$PY_PIN:$f"; done \
 | grep -oE 'uses:[[:space:]]*[^[:space:]]+' | sed 's/uses:[[:space:]]*//' | grep -vE '^(actions|github)/' | sort > /tmp/r20chk/py-3p.txt
printf 'third-party uses: clauses (total occurrences): %s\n' "$(wc -l < /tmp/r20chk/py-3p.txt)"
printf 'distinct third-party uses: values: %s\n' "$(sort -u /tmp/r20chk/py-3p.txt | wc -l)"
sort -u /tmp/r20chk/py-3p.txt
printf 'distinct third-party action repos: %s\n' "$(sed 's/@.*//' /tmp/r20chk/py-3p.txt | sort -u | wc -l)"
printf 'SHA-pinned among them: %s\n' "$(grep -cE '@[0-9a-f]{40}' /tmp/r20chk/py-3p.txt || true)"
echo
echo "-- counts, ts at the pin (live clauses only; commented-out excluded) --"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do git -C "$TS" show "$TS_PIN:$f"; done \
 | grep -E '^[[:space:]]*-?[[:space:]]*uses:' | grep -oE 'uses:[[:space:]]*[^[:space:]]+' | sed 's/uses:[[:space:]]*//' \
 | grep -vE '^(actions|github)/' | sort > /tmp/r20chk/ts-3p.txt
printf 'live third-party uses: clauses: %s\n' "$(wc -l < /tmp/r20chk/ts-3p.txt)"
printf 'SHA-pinned among them: %s\n' "$(grep -cE '@[0-9a-f]{40}' /tmp/r20chk/ts-3p.txt || true)"
echo "NOT SHA-pinned among them:"
grep -vE '@[0-9a-f]{40}' /tmp/r20chk/ts-3p.txt || echo "(all SHA-pinned)"
echo "commented-out uses: clauses at the ts pin:"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -nE '^[[:space:]]*#[[:space:]]*-?[[:space:]]*uses:' | sed "s|^|$f:|"
done
echo
echo "-- is actions/dependency-review-action@v5 resolvable at all? (tag checked already; check branches) --"
gh api "repos/actions/dependency-review-action/git/matching-refs/heads/v5" --jq 'length' 2>&1
gh api "repos/actions/dependency-review-action/git/matching-refs/heads" --jq '.[].ref' 2>&1 | head -10

hr "ADDENDUM 4"
echo "-- which head matched the v5 prefix? (matching-refs is a PREFIX match, so length 1 is not proof of a bare v5 branch) --"
gh api "repos/actions/dependency-review-action/git/matching-refs/heads/v5" --jq '.[] | {ref:.ref, sha:.object.sha}' 2>&1
echo "-- exact ref lookups: tag v5, head v5 (404 = does not exist) --"
gh api "repos/actions/dependency-review-action/git/ref/tags/v5" 2>&1 | head -3
gh api "repos/actions/dependency-review-action/git/ref/heads/v5" 2>&1 | head -3

# ---------------------------------------------------------------------------
# Section 10, added for revision 2, answers the revision-1 audit's finding F1:
# what does the declared `zizmor .github/` invocation actually enforce about
# the version comment, and does the proposed comment-grammar check work?
# Docs and test data are read at the PINNED tag v1.30.1, not at main.
# Nothing is installed and no tree is scaffolded: the only thing executed is a
# grep-based text check over sample `uses:` lines.
# ---------------------------------------------------------------------------
ZTAG=v1.30.1
ZRAW="https://raw.githubusercontent.com/zizmorcore/zizmor/$ZTAG"

hr "10. what zizmor enforces about the version comment (docs+test data at $ZTAG)"
for d in usage audits configuration; do
  curl -sS --max-time 40 "$ZRAW/docs/$d.md" > "/tmp/r20chk/z-$d.md"
  printf '%s.md @ %s bytes: %s\n' "$d" "$ZTAG" "$(wc -c < /tmp/r20chk/z-$d.md)"
done
curl -sS --max-time 40 "$ZRAW/crates/zizmor/tests/integration/test-data/ref-version-mismatch.yml" \
  > /tmp/r20chk/ref-version-mismatch.yml
printf 'ref-version-mismatch.yml @ %s bytes: %s\n' "$ZTAG" "$(wc -c < /tmp/r20chk/ref-version-mismatch.yml)"

echo
echo "-- 10a. which persona is the default? (usage.md @ $ZTAG) --"
grep -n 'persona' /tmp/r20chk/z-usage.md | sed -n '1,12p'
sed -n '616,640p' /tmp/r20chk/z-usage.md

echo
echo "-- 10b. does unpinned-uses say anything about version comments? (audits.md @ $ZTAG) --"
awk '/^## `unpinned-uses`/{f=1} f&&/^## /&&!/unpinned-uses/{exit} f' /tmp/r20chk/z-audits.md \
  | grep -niE 'comment' || echo "(no occurrence of \"comment\" in the whole unpinned-uses section)"

echo
echo "-- 10c. ref-version-mismatch: what it detects and in which persona (audits.md @ $ZTAG) --"
sed -n '1427,1455p' /tmp/r20chk/z-audits.md

echo
echo "-- 10d. the audit's own test data: which shapes are findings, and in which persona --"
cat -n /tmp/r20chk/ref-version-mismatch.yml

echo
echo "-- 10e. is there a per-audit persona setting? (configuration.md @ $ZTAG settings list) --"
grep -nE '^### `rules\.|^#### `rules\.|^## ' /tmp/r20chk/z-configuration.md
grep -niE 'persona' /tmp/r20chk/z-configuration.md || echo "(configuration.md @ $ZTAG contains no per-audit persona setting)"

echo
echo "-- 10f. what --persona=pedantic costs: it is a global sensitivity switch --"
sed -n '635,672p' /tmp/r20chk/z-usage.md

hr "11. the proposed comment-grammar check, run against sample uses: lines"
# The contract: every SHA-pinned `uses:` line in .github/workflows/ ends with a
# trailing version comment. ERE, quoted verbatim in DECISION.md:
GRAMMAR='@[0-9a-f]{40}[[:space:]]+#[[:space:]]v?[0-9]+(\.[0-9]+)*[[:space:]]*$'
SHAPIN='uses:[[:space:]]*[^[:space:]]+@[0-9a-f]{40}'
echo "grammar ERE: $GRAMMAR"
echo "sha-pinned-line ERE: $SHAPIN"

# check() reads candidate lines on stdin and mimics the proposed CI step:
# print every SHA-pinned line lacking a conforming trailing comment, exit 1 if any.
check() {
  local offenders
  offenders=$(grep -E "$SHAPIN" | grep -vE "$GRAMMAR" || true)
  if [ -n "$offenders" ]; then printf '%s\n' "$offenders"; return 1; fi
  return 0
}

echo
echo "-- 11a. PASS case: EVERY SHA-pinned uses: line of ts at $TS_PIN --"
echo "   (12 lines: the 11 third-party clauses plus the one SHA-pinned official clause,"
echo "    actions/dependency-review-action at dependency-review.yml:66 — the check is"
echo "    scoped to SHA-pinned clauses of any owner, not to the third-party subset.)"
for f in $(git -C "$TS" ls-tree -r --name-only "$TS_PIN" .github/workflows/); do
  git -C "$TS" show "$TS_PIN:$f" | grep -nE '^[[:space:]]*-?[[:space:]]*uses:' | sed "s|^|$f:|"
done | grep -E "$SHAPIN" > /tmp/r20chk/ts-shapinned.txt
printf 'SHA-pinned lines fed to the check: %s\n' "$(wc -l < /tmp/r20chk/ts-shapinned.txt)"
cat /tmp/r20chk/ts-shapinned.txt
check < /tmp/r20chk/ts-shapinned.txt && echo "check exit 0 (PASS as expected)" || echo "check exit 1 (UNEXPECTED)"

echo
echo "-- 11b. PASS case: py at HEAD $PY_HEAD, whose comments include a bare major (# v7) --"
git -C "$PY" grep -nE "$SHAPIN" "$PY_HEAD" -- .github/workflows/ > /tmp/r20chk/py-shapinned.txt
printf 'SHA-pinned lines fed to the check: %s\n' "$(wc -l < /tmp/r20chk/py-shapinned.txt)"
check < /tmp/r20chk/py-shapinned.txt && echo "check exit 0 (PASS as expected)" || echo "check exit 1 (UNEXPECTED)"

echo
echo "-- 11c. FAIL cases: four synthetic lines, one per non-conforming shape --"
cat > /tmp/r20chk/fail-cases.txt <<'EOF'
      - uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1
      - uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # pinned by hand
      - uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 #v1.3.9 no space
      - uses: smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # release 1.3.9
EOF
cat /tmp/r20chk/fail-cases.txt
check < /tmp/r20chk/fail-cases.txt && echo "check exit 0 (UNEXPECTED)" || echo "check exit 1 (FAIL as expected; the four lines above are the report)"

echo
echo "-- 11d. shapes the grammar deliberately ACCEPTS (upstream tags are not all v-prefixed 3-component semver) --"
cat > /tmp/r20chk/accept-cases.txt <<'EOF'
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7
      - uses: actions/dependency-review-action@a1d282b36b6f3519aa1f3fc636f609c47dddb294 # v5.0.0
      - uses: canonical/charming-actions/check-libraries@1753e0803f70445132e92acd45c905aba6473225 # 2.7.0
EOF
cat /tmp/r20chk/accept-cases.txt
check < /tmp/r20chk/accept-cases.txt && echo "check exit 0 (ACCEPT as expected)" || echo "check exit 1 (UNEXPECTED)"

echo
echo "-- 11e. the check is blind to whether the comment RESOLVES to the pinned commit --"
cat > /tmp/r20chk/blind-case.txt <<'EOF'
      - uses: actions/setup-node@1a4442cacd436585916779262731d5b162bc6ec7 # v3.8.1
EOF
cat /tmp/r20chk/blind-case.txt
check < /tmp/r20chk/blind-case.txt \
  && echo "check exit 0 — grammar conforms, yet zizmor's own test data (line 25) marks this exact line a ref-version-mismatch finding: the two checks are complementary, not redundant" \
  || echo "check exit 1 (UNEXPECTED)"

hr "done (revision 2)"
