#!/usr/bin/env bash
# R10 (dependency-cache-action) empirical check — PINNED SOURCES ONLY.
#
# Purpose: verify, against immutable refs and against files committed in this
# repository, every claim the R10 decision rests on. This script VERIFIES; it
# builds nothing. No workflow, no template, no fixture, no cache is created and
# no CI is run (none is possible from this machine).
#
# Reproducibility contract: every remote read in this script is pinned to a
# commit SHA or to an immutable tag object, and every local read is of a file
# tracked in this repository, so the log this script writes is intended to be
# byte-for-byte reproducible apart from the four lines of section A0 that report
# the local toolchain and CLI versions. Volatile figures (stars, issue counts,
# push dates) are NOT read here; they live in r10-live-figures.sh.
#
# Checks that need this repository's .git directory print "SKIP <name>" and are
# not counted as failures, so the script also runs from a clean
# `git archive HEAD` extraction.
#
# Retrieval date for every remote read: 2026-09-17 (UTC).

set -u
set -o pipefail

GREP=/usr/bin/grep
RETRIEVED='2026-09-17 (UTC)'

RUST_CACHE_PIN=6323deb102c322ba6fcbdcafc7e3dddab59af2b6   # Swatinem/rust-cache v2.9.2
RUST_CACHE_TAGOBJ=63fed3e2fecf6f7b51dc6f043341b79ef82a9ae7 # annotated tag object for v2.9.2
SRT_PIN=ecabd13d1c56bd1345c230e542e9144811ad706f           # actions-rust-lang/setup-rust-toolchain v2.0.0
CACHE_PIN=55cc8345863c7cc4c66a329aec7e433d2d1c52a9         # actions/cache v6.1.0

# review/evidence -> review -> <run> -> R10 -> runs -> research -> repository root
REPO_ROOT=$(cd -- "$(dirname -- "$0")/../../../../../.." && pwd)
WORK=$(mktemp -d "${TMPDIR:-/tmp}/r10-pinned.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

pass=0
fail=0
skip=0

hr() { printf '\n===== %s =====\n' "$1"; }

# expect_count FILE PATTERN EXPECTED LABEL
# Asserts on CONTENT: the number of lines in FILE matching the extended regular
# expression PATTERN must equal EXPECTED. The counting binary is named on the
# result line. grep exits 1 when it matches nothing, which is a legitimate
# expected result here, so its status is not used as the verdict.
expect_count() {
  local file="$1" pat="$2" want="$3" label="$4" got
  got=$("$GREP" -c -E -- "$pat" "$file" 2>/dev/null || true)
  [ -n "$got" ] || got=0
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'PASS  [%s -c -E] got=%s want=%s  %s\n' "$GREP" "$got" "$want" "$label"
  else
    fail=$((fail + 1))
    printf 'FAIL  [%s -c -E] got=%s want=%s  %s\n' "$GREP" "$got" "$want" "$label"
  fi
}

# expect_equal ACTUAL EXPECTED LABEL
expect_equal() {
  local got="$1" want="$2" label="$3"
  if [ "$got" = "$want" ]; then
    pass=$((pass + 1))
    printf 'PASS  got=%s want=%s  %s\n' "$got" "$want" "$label"
  else
    fail=$((fail + 1))
    printf 'FAIL  got=%s want=%s  %s\n' "$got" "$want" "$label"
  fi
}

skipped() {
  skip=$((skip + 1))
  printf 'SKIP  %s\n' "$1"
}

# raw_get PATH_WITH_REF OUTFILE — authenticated GitHub contents read, raw bytes.
# gh reads its own credential; no token value is printed or recorded anywhere.
raw_get() {
  gh api -H 'Accept: application/vnd.github.raw' "$1" > "$2"
}

sha256_of() {
  if command -v sha256sum > /dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

hr "A0. environment (these four lines are the only volatile lines in this log)"
rustc --version
cargo --version
printf 'OS: macOS %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
gh --version | sed -n '1p'
printf 'counting binary: %s -> %s\n' "$GREP" "$("$GREP" --version | sed -n '1p')"
printf 'retrieval date for every remote read below: %s\n' "$RETRIEVED"
printf 'repository root: %s\n' "$REPO_ROOT"

hr "A1. Swatinem/rust-cache v2.9.2 tag dereferences to the recommended commit"
# Endpoint: GET https://api.github.com/repos/Swatinem/rust-cache/git/ref/tags/v2.9.2
#           GET https://api.github.com/repos/Swatinem/rust-cache/git/tags/<tag object>
ref_type=$(gh api repos/Swatinem/rust-cache/git/ref/tags/v2.9.2 --jq '.object.type')
ref_sha=$(gh api repos/Swatinem/rust-cache/git/ref/tags/v2.9.2 --jq '.object.sha')
expect_equal "$ref_type" "tag" "A1.1 v2.9.2 is an annotated tag object (git/ref/tags/v2.9.2 .object.type)"
expect_equal "$ref_sha" "$RUST_CACHE_TAGOBJ" "A1.2 tag object sha (git/ref/tags/v2.9.2 .object.sha)"
tgt_type=$(gh api "repos/Swatinem/rust-cache/git/tags/$RUST_CACHE_TAGOBJ" --jq '.object.type')
tgt_sha=$(gh api "repos/Swatinem/rust-cache/git/tags/$RUST_CACHE_TAGOBJ" --jq '.object.sha')
expect_equal "$tgt_type" "commit" "A1.3 tag object points at a commit (git/tags/<obj> .object.type)"
expect_equal "$tgt_sha" "$RUST_CACHE_PIN" "A1.4 v2.9.2 = commit 6323deb102c322ba6fcbdcafc7e3dddab59af2b6 — the SHA the decision pins"

hr "A2. Swatinem/rust-cache action.yml at $RUST_CACHE_PIN — input defaults and post condition"
# Endpoint: GET https://api.github.com/repos/Swatinem/rust-cache/contents/action.yml?ref=<pin>
raw_get "repos/Swatinem/rust-cache/contents/action.yml?ref=$RUST_CACHE_PIN" "$WORK/action.yml"
printf 'bytes: %s\n' "$(wc -c < "$WORK/action.yml" | tr -d ' ')"
expect_count "$WORK/action.yml" '^  using: "node24"$' 1 \
  "A2.1 runs.using is node24 (a Node action; no Rust is compiled into the template)"
expect_count "$WORK/action.yml" "^  post-if: \"success\\(\\) \\|\\| env\\.CACHE_ON_FAILURE == 'true'\"\$" 1 \
  "A2.2 post-if honours CACHE_ON_FAILURE — cache-on-failure is implemented, not documentation"
expect_count "$WORK/action.yml" '^    default: "v0-rust"$' 1 \
  "A2.3 prefix-key default is v0-rust (the decision overrides it to v1-rslbp)"
expect_count "$WORK/action.yml" '^  env-vars:$' 1 \
  "A2.4 env-vars input exists"
expect_count "$WORK/action.yml" '^  cache-on-failure:$' 1 \
  "A2.5 cache-on-failure input exists"
expect_count "$WORK/action.yml" '"Cache even if the build fails\. Defaults to false\."' 1 \
  "A2.6 cache-on-failure documents its default as false — the decision must set it explicitly"
# Defaults that the decision deliberately KEEPS. Each is asserted against the
# input block it belongs to, not against a bare 'default:' line.
for pair in 'add-job-id-key:true' 'add-rust-environment-hash-key:true' 'cache-targets:true' \
            'cache-all-crates:false' 'cache-workspace-crates:false' 'save-if:true' \
            'cache-bin:true' 'cache-provider:github'; do
  name=${pair%%:*}
  want=${pair##*:}
  block=$(awk -v n="  $name:" '$0 == n {f=1; next} f && /^  [a-z-]+:$/ {exit} f {print}' "$WORK/action.yml")
  got=$(printf '%s\n' "$block" | "$GREP" -E '^    default: ' | sed 's/^    default: "\(.*\)"$/\1/')
  expect_equal "$got" "$want" "A2.7 default for input $name"
done

hr "A3. Swatinem/rust-cache src/config.ts at $RUST_CACHE_PIN — the key derivation"
# Endpoint: GET https://api.github.com/repos/Swatinem/rust-cache/contents/src/config.ts?ref=<pin>
raw_get "repos/Swatinem/rust-cache/contents/src/config.ts?ref=$RUST_CACHE_PIN" "$WORK/config.ts"
printf 'bytes: %s\n' "$(wc -c < "$WORK/config.ts" | tr -d ' ')"
expect_count "$WORK/config.ts" 'const envPrefixes = \["CARGO", "CC", "CFLAGS", "CXX", "CMAKE", "RUST"\];' 1 \
  "A3.1 built-in env-var prefix list is CARGO CC CFLAGS CXX CMAKE RUST"
expect_count "$WORK/config.ts" 'envPrefixes\.push\(\.\.\.core\.getInput\("env-vars"\)' 1 \
  "A3.2 the env-vars input is APPENDED to that list, not a replacement — 'ImageOS' adds exactly one variable"
expect_count "$WORK/config.ts" 'envPrefixes\.some\(\(prefix\) => key\.startsWith\(prefix\)\) && value' 1 \
  "A3.3 matching is a case-sensitive startsWith AND the value must be non-empty — an empty ImageOS contributes nothing"
expect_count "$WORK/config.ts" 'const runnerOS = os\.type\(\);' 1 \
  "A3.4 the key carries os.type() ..."
expect_count "$WORK/config.ts" 'const runnerArch = os\.arch\(\);' 1 \
  "A3.5 ... and os.arch() — but no runner IMAGE identifier, which is the #341 defect"
expect_count "$WORK/config.ts" 'const job = process\.env\.GITHUB_JOB;' 1 \
  "A3.6 add-job-id-key reads GITHUB_JOB — the YAML job id, which does NOT include matrix values"
expect_count "$WORK/config.ts" 'self\.restoreKey = key;' 1 \
  "A3.7 the restore key is snapshotted BEFORE the lockfile digest is appended (the two-key split)"
expect_count "$WORK/config.ts" '"source" in p \|\| "checksum" in p' 1 \
  "A3.8 the Cargo.lock digest keeps only packages with source/checksum — workspace-own crates are excluded"

hr "A4. Swatinem/rust-cache CHANGELOG.md at $RUST_CACHE_PIN — why the range floor is 2.9.1"
# Endpoint: GET https://api.github.com/repos/Swatinem/rust-cache/contents/CHANGELOG.md?ref=<pin>
raw_get "repos/Swatinem/rust-cache/contents/CHANGELOG.md?ref=$RUST_CACHE_PIN" "$WORK/CHANGELOG.md"
sed -n '1,22p' "$WORK/CHANGELOG.md"
expect_count "$WORK/CHANGELOG.md" '^## 2\.9\.2$' 1 "A4.1 2.9.2 is the newest section — the pinned release"
expect_count "$WORK/CHANGELOG.md" '^- Fix regression in hash calculation$' 1 \
  "A4.2 2.9.1's sole entry is the hash-calculation regression fix — the reason the floor is 2.9.1, not 2.9.0"
expect_count "$WORK/CHANGELOG.md" '^- Consider all installed toolchains for cache key$' 1 \
  "A4.3 2.9.0 added all-installed-toolchains keying, which the MSRV floor job needs"
# shellcheck disable=SC2016  # the $ is a regex anchor, not a shell expansion
expect_count "$WORK/CHANGELOG.md" '^- Update to `node24`$' 1 \
  "A4.4 2.9.0 moved to the node24 runtime"
expect_count "$WORK/CHANGELOG.md" 'macos|ImageOS|image' 0 \
  "A4.5 NO entry at or below 2.9.2 mentions a macOS image or ImageOS fix — issue #341 is unfixed at the pin"

hr "A5. Swatinem/rust-cache LICENSE at $RUST_CACHE_PIN — recorded as a FIGURE only"
# Fitness gate 1 is 'inapplicable — owner ruling 2026-09-12 (Q7.B)'. The licence
# is read so the figure is on the record; it excludes nothing.
# Endpoint: GET https://api.github.com/repos/Swatinem/rust-cache/contents/LICENSE?ref=<pin>
raw_get "repos/Swatinem/rust-cache/contents/LICENSE?ref=$RUST_CACHE_PIN" "$WORK/LICENSE"
sed -n '1,2p' "$WORK/LICENSE"
expect_count "$WORK/LICENSE" 'GNU LESSER GENERAL PUBLIC LICENSE' 1 \
  "A5.1 the bundled LICENSE is the LGPL — figure recorded, gate 1 inapplicable by owner ruling, excludes nothing"

hr "A6. actions-rust-lang/setup-rust-toolchain action.yml at $SRT_PIN — it IS the same engine"
# Endpoint: GET https://api.github.com/repos/actions-rust-lang/setup-rust-toolchain/contents/action.yml?ref=<pin>
raw_get "repos/actions-rust-lang/setup-rust-toolchain/contents/action.yml?ref=$SRT_PIN" "$WORK/srt.yml"
"$GREP" -n -E 'Swatinem/rust-cache@' "$WORK/srt.yml" || true
expect_count "$WORK/srt.yml" "uses: Swatinem/rust-cache@$RUST_CACHE_PIN # v2\\.9\\.2" 1 \
  "A6.1 the setup-integrated action delegates to rust-cache at the IDENTICAL commit this decision pins"
srt_cache_default=$(awk '$0 == "  cache:" {f=1; next} f && /^  [a-z-]+:$/ {exit} f {print}' "$WORK/srt.yml" \
  | "$GREP" -E '^    default: ' | sed 's/^    default: "\(.*\)"$/\1/')
expect_equal "$srt_cache_default" "true" "A6.2 its cache input defaults to true"
expect_count "$WORK/srt.yml" '^  env-vars:$' 0 \
  "A6.3 it exposes NO env-vars passthrough — the ImageOS remedy cannot be expressed through the runner-up"

hr "A7. actions/cache examples.md at $CACHE_PIN — GitHub's own published Rust recipe"
# Endpoint: GET https://api.github.com/repos/actions/cache/contents/examples.md?ref=<pin>
raw_get "repos/actions/cache/contents/examples.md?ref=$CACHE_PIN" "$WORK/examples.md"
start=$("$GREP" -n -E '^## Rust - Cargo$' "$WORK/examples.md" | cut -d: -f1)
printf 'Rust recipe starts at examples.md line %s; block reproduced verbatim:\n' "$start"
sed -n "${start},$((start + 12))p" "$WORK/examples.md" | sed 's/^/  | /'
sed -n "${start},$((start + 12))p" "$WORK/examples.md" > "$WORK/rust-recipe.txt"
expect_count "$WORK/rust-recipe.txt" "key: \\\$\\{\\{ runner\\.os \\}\\}-cargo-\\\$\\{\\{ hashFiles\\('\\*\\*/Cargo\\.lock'\\) \\}\\}" 1 \
  "A7.1 the published key is runner.os + hashFiles(Cargo.lock) and nothing else"
expect_count "$WORK/rust-recipe.txt" 'restore-keys' 0 \
  "A7.2 the published recipe has NO restore-keys — one lockfile edit is a total miss (fails P1)"
expect_count "$WORK/rust-recipe.txt" 'rustc|runner\.arch|ImageOS' 0 \
  "A7.3 it carries no compiler identity, no runner arch and no image identity"

hr "A8. actions/runner-images — how ImageOS reaches a job, and how the two OSes differ"
# Endpoints: GET https://api.github.com/repos/actions/runner-images/contents/images/ubuntu/scripts/build/configure-environment.sh
#            GET https://api.github.com/repos/actions/runner-images/contents/images/macos/scripts/build/configure-preimagedata.sh
# Read on the default branch (these paths are not pinned): this section's two
# result lines are the one place in this script where upstream could drift.
raw_get "repos/actions/runner-images/contents/images/ubuntu/scripts/build/configure-environment.sh" "$WORK/ubuntu-env.sh"
raw_get "repos/actions/runner-images/contents/images/macos/scripts/build/configure-preimagedata.sh" "$WORK/macos-pre.sh"
"$GREP" -n -E 'ImageOS' "$WORK/ubuntu-env.sh" || true
"$GREP" -n -E 'ImageOS' "$WORK/macos-pre.sh" || true
expect_count "$WORK/ubuntu-env.sh" 'set_etc_environment_variable "ImageOS" "\$\{IMAGE_OS\}"' 1 \
  "A8.1 Ubuntu: ImageOS is written to /etc/environment, so every process on the runner inherits it"
# shellcheck disable=SC2016  # \$IMAGE_OS and \$HOME are escaped regex literals matching the upstream file
expect_count "$WORK/macos-pre.sh" 'echo "export ImageOS=\$IMAGE_OS" >> \$HOME/\.bashrc' 1 \
  "A8.2 macOS: ImageOS is appended to \$HOME/.bashrc ONLY — a shell-scoped export, not a process-wide one"

hr "A9. this repository — prerequisite integrity and the standing rules the decision cites"
cd "$REPO_ROOT" || exit 2
r42_want=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["R42"]["decision"])' \
  research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/inputs/prerequisites.json)
r42_got=$(sha256_of research/topics/42-dev-toolchain-provisioning/DECISION.md)
expect_equal "$r42_got" "$r42_want" \
  "A9.1 the published R42 DECISION.md is byte-identical to the prerequisite this run was bound to"
expect_count research/topics/42-dev-toolchain-provisioning/DECISION.md \
  'dtolnay|actions-rust-lang|setup-rust-toolchain|Swatinem|rust-cache' 0 \
  "A9.2 R42 names NO CI toolchain-install action — the hand-off Opus raised, confirmed here"
expect_count research/topics/42-dev-toolchain-provisioning/DECISION.md \
  'cargo binstall --locked --no-confirm <name>@<version>' 4 \
  "A9.3 R42 does fix how dev tools are installed (4 occurrences of the recipe body), which is what makes cache-bin load-bearing"
expect_count research/topics/20-third-party-action-pinning-policy/DECISION.md \
  'is pinned to a full 40-character commit SHA' 1 \
  "A9.4 R20 requires a full-SHA pin for a non-actions/non-github owner such as Swatinem"
expect_count docs/port/OWNER-REVIEW.md \
  'Fitness gate 1 \(.license compatible with' 1 \
  "A9.5 the 2026-09-12 (Q7.B) ruling strikes fitness gate 1 from every item"
expect_count docs/port/COMMONALITY.md '^\| F035 \| Dependency caching integrated into the language-setup step \(pattern\)' 1 \
  "A9.6 ledger row F035 is present and is the parent pattern row"
expect_count docs/port/COMMONALITY.md '^\| F036 \| Dependency caching built into the language-setup action \(tool\) \| ci-workflows \| same \| COMMON . SUBSTITUTE \| R10 \|' 1 \
  "A9.7 ledger row F036 is assigned to R10 with verdict COMMON to SUBSTITUTE"

hr "A10. the four fixed parameters — run inputs against the live registry"
RUN_PARAMS=research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/inputs/PARAMETERS.md
for p in msrv-policy rust-edition target-os-matrix license; do
  a=$("$GREP" -E "^\| $p \| fixed \| owner \|" "$RUN_PARAMS" || true)
  b=$("$GREP" -E "^\| $p \| fixed \| owner \|" docs/port/PARAMETERS.md || true)
  if [ -n "$a" ] && [ "$a" = "$b" ]; then
    pass=$((pass + 1))
    printf 'PASS  row identical in run inputs and live registry  A10 %s\n' "$p"
    printf '      %s\n' "$a"
  else
    fail=$((fail + 1))
    printf 'FAIL  row differs or is missing  A10 %s\n' "$p"
  fi
done

hr "A11. raw report integrity — content hash equals the filename hash"
RAW=research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/raw
for f in "$RAW"/codex-*.md "$RAW"/opus-*.md; do
  base=$(basename "$f" .md)
  want=${base#*-}
  got=$(sha256_of "$f")
  expect_equal "$got" "$want" "A11 $(basename "$f") content sha256 equals its filename"
done

hr "A12. source precedent (requires a local clone with .git — SKIPs without one)"
for pair in 'py:b08bccfb55d05f15e46a83b52c5660b1881d19f5' 'ts:cb1cbcb2e88b898e8c081b0abbfabc1630079c00'; do
  which=${pair%%:*}
  pin=${pair##*:}
  repo="$HOME/c/${which}-launch-blueprint"
  if [ ! -d "$repo/.git" ]; then
    skipped "A12.$which — no .git at $repo; source-precedent read not attempted"
    continue
  fi
  if ! git -C "$repo" cat-file -e "$pin^{commit}" 2>/dev/null; then
    skipped "A12.$which — programme pin $pin not present in $repo"
    continue
  fi
  git -C "$repo" show "$pin:.github/workflows/ci.yml" > "$WORK/$which-ci.yml"
  if [ "$which" = py ]; then
    expect_count "$WORK/$which-ci.yml" 'uses: astral-sh/setup-uv@' 6 \
      "A12.py setup-uv supplies py's cache with no cache input at the programme pin"
  else
    expect_count "$WORK/$which-ci.yml" "cache: 'pnpm'" 2 \
      "A12.ts setup-node supplies ts's cache through cache: 'pnpm' at the programme pin"
  fi
done

hr "A13. negative controls — the assertions above can fail, demonstrated"
# A check that cannot fail is not evidence. Each control repeats one assertion
# with exactly one input perturbed and requires the perturbed form to MISMATCH.
control_mismatch() {
  local got="$1" want="$2" label="$3"
  if [ "$got" != "$want" ]; then
    pass=$((pass + 1))
    printf 'PASS  control fired: got=%s != perturbed-want=%s  %s\n' "$got" "$want" "$label"
  else
    fail=$((fail + 1))
    printf 'FAIL  control did NOT fire: got=%s == perturbed-want=%s  %s\n' "$got" "$want" "$label"
  fi
}
control_mismatch "$tgt_sha" "6323deb102c322ba6fcbdcafc7e3dddab59af2b6x" \
  "A13.1 A1.4 discriminates: one extra character in the expected commit breaks the match"
c1=$("$GREP" -c -E 'restore-keys' "$WORK/rust-recipe.txt" 2>/dev/null || true)
control_mismatch "${c1:-0}" "1" \
  "A13.2 A7.2 discriminates: the Rust recipe really contains zero restore-keys lines, not one"
c2=$("$GREP" -c -E '^  env-vars:$' "$WORK/action.yml" 2>/dev/null || true)
c3=$("$GREP" -c -E '^  env-vars:$' "$WORK/srt.yml" 2>/dev/null || true)
control_mismatch "$c2" "$c3" \
  "A13.3 A6.3 discriminates: the same pattern finds env-vars in rust-cache ($c2) and not in setup-rust-toolchain ($c3)"
c4=$("$GREP" -c -E 'dtolnay|actions-rust-lang|setup-rust-toolchain|Swatinem|rust-cache' \
  research/topics/20-third-party-action-pinning-policy/DECISION.md 2>/dev/null || true)
control_mismatch "${c4:-0}" "0" \
  "A13.4 A9.2 discriminates: the same action-name pattern is non-zero in R20 ($c4), so zero in R42 is a real absence"

hr "RESULT"
printf 'checks: %s passed, %s failed, %s skipped\n' "$pass" "$fail" "$skip"
if [ "$fail" -ne 0 ]; then
  printf 'VERDICT: FAIL\n'
  exit 1
fi
printf 'VERDICT: PASS\n'
exit 0
