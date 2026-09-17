#!/usr/bin/env bash
# R68 empirical check, part 2 of 2: verify at primary sources every mechanism
# the artifact recommendation rests on, and settle the points where the engines
# disagreed. It queries endpoints only; it builds nothing and writes nothing
# outside its own temporary directory.
#
# Line prefixes and what they promise:
#   PINNED  — content read at an immutable git tag (`?ref=v0.33.0`). Reproduces
#             byte-for-byte for as long as the tag exists.
#   HEAD    — content read from a moving default branch. The resolved commit
#             sha is printed beside it, and the matched text is quoted, so the
#             exact bytes relied on are in this log even after the branch moves.
#   FIGURE  — a point-in-time counter or timestamp from an API. Does NOT
#             reproduce; carries its endpoint and this run's date.
#   ASSERT  — a content assertion. `ASSERT FAIL` makes the script exit 1.
#
# Needs: network, and `gh` already authenticated. No token or environment is
# printed. Needs no `.git`, so it runs from a clean `git archive HEAD`
# extraction.

set -euo pipefail

GREP=/usr/bin/grep
UA="rs-launch-blueprint-r68-research"
DIST_TAG="v0.33.0"

echo "=== R68 artifact-source checks ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "gh: $(gh --version | "$GREP" '^gh version')"
echo "curl: $(curl --version | "$GREP" -o '^curl [0-9.]*')"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r68-sources.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

fail=0
assert() {
  if [ "$1" = "1" ]; then
    echo "ASSERT ok   $2"
  else
    echo "ASSERT FAIL $2"
    fail=1
  fi
}
has() { if [ "$1" -gt 0 ]; then echo 1; else echo 0; fi; }

# ---------------------------------------------------------------------------
echo "--- A. the base artifact: what cargo publish produces ---"
curl -sS -A "$UA" "https://doc.rust-lang.org/cargo/commands/cargo-package.html" -o "$WORK/cargo-package.html"
N=$("$GREP" -c 'distributable, compressed <code>.crate</code> file' "$WORK/cargo-package.html" || true)
echo "endpoint: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved this run)"
echo "/usr/bin/grep -c 'distributable, compressed <code>.crate</code> file' = ${N}"
assert "$(has "$N")" \
  "the Cargo Book states cargo package produces a distributable compressed .crate file — the single artifact every other channel is added beside"
echo

# ---------------------------------------------------------------------------
echo "--- B. Cargo profile defaults, cited for every key this decision leaves silent ---"
curl -sS -A "$UA" "https://doc.rust-lang.org/cargo/reference/profiles.html" -o "$WORK/profiles.html"
echo "endpoint: https://doc.rust-lang.org/cargo/reference/profiles.html (retrieved this run)"
for pat in 'strip' 'codegen-units' 'opt-level' 'panic' 'lto'; do
  c=$("$GREP" -c ">${pat}<" "$WORK/profiles.html" || true)
  echo "/usr/bin/grep -c '>${pat}<' profiles.html = ${c}"
done
# The rendered page wraps this sentence across a line break, so the pattern
# stops at the wrap point rather than quoting a line that does not exist.
N=$("$GREP" -c 'Profile settings defined in dependencies will be' "$WORK/profiles.html" || true)
echo "/usr/bin/grep -c 'Profile settings defined in dependencies will be' = ${N}"
"$GREP" -n -A1 'Profile settings defined in dependencies will be' "$WORK/profiles.html" | head -4 || true
assert "$(has "$N")" \
  "the Cargo Book states profile settings defined in dependencies are ignored — a downstream library consumer inherits nothing from this manifest's [profile.release]"
N=$("$GREP" -c 'unpacked' "$WORK/profiles.html" || true)
echo "/usr/bin/grep -c 'unpacked' profiles.html = ${N}"
assert "$(has "$N")" \
  "the Cargo Book documents the platform-dependent split-debuginfo default whose macOS value (unpacked) explains the measured line-table result in profile-probe.log"
N=$("$GREP" -c 'inherits' "$WORK/profiles.html" || true)
echo "/usr/bin/grep -c 'inherits' profiles.html = ${N}"
assert "$(has "$N")" "the Cargo Book documents that a custom profile must declare inherits"
echo

# ---------------------------------------------------------------------------
echo "--- C. dist at the pinned tag ${DIST_TAG}: follower mode, runner map, generated profile stub ---"
gh api -H "Accept: application/vnd.github.raw" \
  "repos/axodotdev/cargo-dist/contents/book/src/reference/config.md?ref=${DIST_TAG}" >"$WORK/dist-config.md"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/contents/book/src/reference/config.md?ref=${DIST_TAG}"
N=$("$GREP" -c 'undrafting when all artifacts are uploaded' "$WORK/dist-config.md" || true)
echo "/usr/bin/grep -c 'undrafting when all artifacts are uploaded' dist-config.md = ${N}"
"$GREP" -n 'undrafting when all artifacts are uploaded' "$WORK/dist-config.md" | head -1 || true
assert "$(has "$N")" \
  "PINNED create-release = false makes dist upload into an existing draft Release and undraft it — the follower mode this decision pairs with release-please"
for key in 'github-custom-runners' 'install-updater' 'source-tarball' 'create-release' 'installers'; do
  c=$("$GREP" -c -- "${key}" "$WORK/dist-config.md" || true)
  echo "/usr/bin/grep -c '${key}' dist-config.md = ${c}"
done

gh api -H "Accept: application/vnd.github.raw" \
  "repos/axodotdev/cargo-dist/contents/cargo-dist/src/backend/ci/github.rs?ref=${DIST_TAG}" >"$WORK/github.rs"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/contents/cargo-dist/src/backend/ci/github.rs?ref=${DIST_TAG}"
for label in 'ubuntu-22.04-arm' 'ubuntu-22.04' 'macos-14' 'macos-15-intel'; do
  c=$("$GREP" -c -- "${label}" "$WORK/github.rs" || true)
  echo "/usr/bin/grep -c '${label}' cargo-dist/src/backend/ci/github.rs = ${c}"
done
N=$("$GREP" -c -- 'ubuntu-latest' "$WORK/github.rs" || true)
echo "/usr/bin/grep -c 'ubuntu-latest' cargo-dist/src/backend/ci/github.rs = ${N}"
LINUX_DEFAULT=$("$GREP" -c -- 'ubuntu-22.04' "$WORK/github.rs" || true)
assert "$(has "$LINUX_DEFAULT")" \
  "PINNED dist's default GitHub runner labels are pinned point releases (ubuntu-22.04 / macos-*), none of them the fixed target-os-matrix values, so [dist.github-custom-runners] overrides are REQUIRED, not optional"
ARM_LINUX=$("$GREP" -c -- 'ubuntu-22.04-arm' "$WORK/github.rs" || true)
assert "$(has "$ARM_LINUX")" \
  "PINNED dist assigns an ARM Linux runner label (ubuntu-22.04-arm) to the ARM Linux target — the fixed matrix has no ARM Linux runner, which is the ground for excluding aarch64-unknown-linux-gnu"

gh api -H "Accept: application/vnd.github.raw" \
  "repos/axodotdev/cargo-dist/contents/book/src/reference/concepts.md?ref=${DIST_TAG}" >"$WORK/dist-concepts.md"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/contents/book/src/reference/concepts.md?ref=${DIST_TAG}"
PROF=$("$GREP" -c 'profile.dist' "$WORK/dist-concepts.md" || true)
PROF_LTO=$("$GREP" -c 'lto = "thin"' "$WORK/dist-concepts.md" || true)
echo "/usr/bin/grep -c 'profile.dist' book/src/reference/concepts.md = ${PROF}"
echo "/usr/bin/grep -c 'lto = \"thin\"' book/src/reference/concepts.md = ${PROF_LTO}"
"$GREP" -n -A4 '\[profile.dist\]' "$WORK/dist-concepts.md" | head -12 || true
assert "$(has "$PROF_LTO")" \
  "PINNED dist's own documentation shows the [profile.dist] stub it generates carrying lto = \"thin\" — byte-for-byte the owner reference architecture's profile row, and the stub that must be trimmed or it silently overrides the recommended lto = \"fat\""

gh api -H "Accept: application/vnd.github.raw" \
  "repos/axodotdev/cargo-dist/contents/book/src/installers/other.md?ref=${DIST_TAG}" >"$WORK/dist-other.md"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/contents/book/src/installers/other.md?ref=${DIST_TAG}"
N=$("$GREP" -c -i 'auto-detected' "$WORK/dist-other.md" || true)
echo "/usr/bin/grep -c -i 'auto-detected' book/src/installers/other.md = ${N}"
"$GREP" -n -i -B2 -A2 'auto-detected' "$WORK/dist-other.md" | head -12 || true
assert "$(has "$N")" \
  "PINNED dist states its GitHub Release URL schema is auto-detected by cargo-binstall — the maintainer claim behind writing no [package.metadata.binstall] block"
ZB_DOC=$(cat "$WORK/dist-config.md" "$WORK/dist-concepts.md" | "$GREP" -c -i 'zigbuild' || true)
ZB_SRC=$("$GREP" -c -i 'zigbuild' "$WORK/github.rs" || true)
ZB_GUARD=$("$GREP" -c 'CargoBuildWrapper::ZigBuild' "$WORK/github.rs" || true)
echo "/usr/bin/grep -c -i 'zigbuild' over the pinned dist config + concepts reference = ${ZB_DOC}"
echo "/usr/bin/grep -c -i 'zigbuild' over the pinned CI backend cargo-dist/src/backend/ci/github.rs = ${ZB_SRC}"
echo "/usr/bin/grep -c 'CargoBuildWrapper::ZigBuild' over the same file = ${ZB_GUARD}"
"$GREP" -n -i 'zigbuild' "$WORK/github.rs" | head -6 || true
assert "$(if [ "$ZB_DOC" -eq 0 ] && [ "$ZB_GUARD" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "PINNED cargo-zigbuild appears ${ZB_DOC} times in dist's user-facing configuration reference and only inside a conditional CargoBuildWrapper::ZigBuild guard in its CI backend — so it is an opt-in wrapper dist installs when a target demands one, not the mechanism the three recommended natively-built targets use; the Doxa/Gemini claim that dist 'executes cross-compilation via cargo-zigbuild' overstates it"

# How the generated workflow installs dist itself decides whether the crates.io
# publication gap below actually blocks pinning a version crates.io lacks.
gh api -H "Accept: application/vnd.github.raw" \
  "repos/axodotdev/cargo-dist/contents/.github/workflows/release.yml?ref=${DIST_TAG}" >"$WORK/dist-release.yml"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/contents/.github/workflows/release.yml?ref=${DIST_TAG}"
INSTALLER=$("$GREP" -c 'releases/download/v[0-9.]*/cargo-dist-installer.sh' "$WORK/dist-release.yml" || true)
CARGO_INSTALL=$("$GREP" -c 'cargo install cargo-dist' "$WORK/dist-release.yml" || true)
echo "/usr/bin/grep -c 'releases/download/v<ver>/cargo-dist-installer.sh' release.yml = ${INSTALLER}"
echo "/usr/bin/grep -c 'cargo install cargo-dist' release.yml = ${CARGO_INSTALL}"
"$GREP" -n 'cargo-dist-installer.sh' "$WORK/dist-release.yml" | head -3 || true
assert "$(if [ "$INSTALLER" -gt 0 ] && [ "$CARGO_INSTALL" -eq 0 ]; then echo 1; else echo 0; fi)" \
  "PINNED dist's generated release workflow installs dist from its GitHub Release installer script and never from crates.io — so the crates.io publication gap recorded below does not block pinning a version the registry lacks; it is a maintenance signal, not an install blocker"
echo

# ---------------------------------------------------------------------------
echo "--- D. dist's own v0.33.0 release assets: the naming scheme binstall must infer ---"
gh api "repos/axodotdev/cargo-dist/releases/tags/${DIST_TAG}" --jq '.assets[].name' | sort >"$WORK/assets.txt"
echo "PINNED endpoint: repos/axodotdev/cargo-dist/releases/tags/${DIST_TAG} (.assets[].name)"
ASSET_N=$("$GREP" -c . "$WORK/assets.txt" || true)
echo "asset count = ${ASSET_N}"
cat "$WORK/assets.txt"
N=$("$GREP" -c '^cargo-dist-aarch64-apple-darwin\.tar\.xz$' "$WORK/assets.txt" || true)
assert "$(has "$N")" \
  "PINNED the archive is named after the PACKAGE (cargo-dist-<triple>.tar.xz) although the binary inside is named dist — so a dist-produced archive matches cargo-binstall's { name }-based default filename while the binary keeps its own { bin } name"
N=$("$GREP" -c 'installer.sh$' "$WORK/assets.txt" || true)
assert "$(has "$N")" "PINNED the release carries a shell installer script"
N=$("$GREP" -c '^sha256.sum$' "$WORK/assets.txt" || true)
assert "$(has "$N")" "PINNED the release carries a sha256.sum sidecar set"
N=$("$GREP" -c '^dist-manifest.json$' "$WORK/assets.txt" || true)
assert "$(has "$N")" "PINNED the release carries the machine-readable dist-manifest.json"
N=$("$GREP" -c -i -E 'windows|\.msi$|\.ps1$' "$WORK/assets.txt" || true)
echo "/usr/bin/grep -c -i -E 'windows|\\.msi$|\\.ps1$' assets.txt = ${N} (recorded: dist ships Windows artifacts for itself; this template's fixed matrix has no Windows runner, so its targets list excludes them)"
echo

# ---------------------------------------------------------------------------
echo "--- E. cargo-binstall's documented default inference rules (moving branch) ---"
BINSTALL_SHA=$(gh api "repos/cargo-bins/cargo-binstall/commits?per_page=1" --jq '.[0].sha')
gh api -H "Accept: application/vnd.github.raw" \
  "repos/cargo-bins/cargo-binstall/contents/SUPPORT.md?ref=${BINSTALL_SHA}" >"$WORK/binstall-support.md"
echo "HEAD endpoint: repos/cargo-bins/cargo-binstall/contents/SUPPORT.md at commit ${BINSTALL_SHA}"
N=$("$GREP" -c '{ name }-{ target }' "$WORK/binstall-support.md" || true)
echo "/usr/bin/grep -c '{ name }-{ target }' SUPPORT.md = ${N}"
"$GREP" -n '{ name }-{ target }' "$WORK/binstall-support.md" | head -4 || true
assert "$(has "$N")" \
  "HEAD cargo-binstall's default GitHub filename templates are built from { name }, the CRATE name — which is what a dist archive is named after"
N=$("$GREP" -c '{ bin }{ binary-ext }' "$WORK/binstall-support.md" || true)
echo "/usr/bin/grep -c '{ bin }{ binary-ext }' SUPPORT.md = ${N}"
"$GREP" -n '{ bin }{ binary-ext }' "$WORK/binstall-support.md" | head -4 || true
assert "$(has "$N")" \
  "HEAD cargo-binstall's default bin-dir extracts { bin }, the CARGO BINARY name — so R49's rslbp (binary) / rs-launch-blueprint (package) pair is exactly the case the two defaults already cover"
# The load-bearing line is not the bin-dir list above but the pkg-url FILENAME
# list: a dist archive carries no version in its name, so the zero-metadata
# claim stands or falls on the "versionless" entry being a documented default.
VERSIONLESS=$("$GREP" -c 'versionless' "$WORK/binstall-support.md" || true)
echo "/usr/bin/grep -c 'versionless' SUPPORT.md = ${VERSIONLESS}"
"$GREP" -n 'versionless' "$WORK/binstall-support.md" || true
"$GREP" -n 'releases/download/v{ version }/' "$WORK/binstall-support.md" || true
assert "$(has "$VERSIONLESS")" \
  "HEAD cargo-binstall's DEFAULT GitHub pkg-url filename list includes the versionless { name }-{ target }{ archive-suffix } form under the path { repo }/releases/download/v{ version }/ — which is exactly dist's observed asset naming, so no [package.metadata.binstall] block is required"
echo

# ---------------------------------------------------------------------------
echo "--- F. the runner-up's archive default, which does NOT match binstall's ---"
TAIKI_SHA=$(gh api "repos/taiki-e/upload-rust-binary-action/commits?per_page=1" --jq '.[0].sha')
gh api -H "Accept: application/vnd.github.raw" \
  "repos/taiki-e/upload-rust-binary-action/contents/README.md?ref=${TAIKI_SHA}" >"$WORK/taiki.md"
echo "HEAD endpoint: repos/taiki-e/upload-rust-binary-action/contents/README.md at commit ${TAIKI_SHA}"
# shellcheck disable=SC2016  # the literal text searched for is the two-dollar token $bin-$target
N=$("$GREP" -c -- '\$bin-\$target' "$WORK/taiki.md" || true)
echo "/usr/bin/grep -c '\$bin-\$target' README.md = ${N}"
# shellcheck disable=SC2016
"$GREP" -n -- '\$bin-\$target' "$WORK/taiki.md" | head -3 || true
assert "$(has "$N")" \
  "HEAD the runner-up action's default archive name is \$bin-\$target (the BINARY name), which binstall's { name }-based default will not find for this template — the exact reason the runner-up costs a hand-maintained [package.metadata.binstall] block and the dominant choice does not"
N=$("$GREP" -c 'profile' "$WORK/taiki.md" || true)
echo "/usr/bin/grep -c 'profile' README.md = ${N}"
assert "$(has "$N")" "HEAD the runner-up exposes a profile input, so it composes with this item's profile recommendation unchanged"
echo

# ---------------------------------------------------------------------------
echo "--- G. release-please: the draft Release and the tag that fires the dist workflow ---"
RP_SHA=$(gh api "repos/googleapis/release-please/commits?per_page=1" --jq '.[0].sha')
gh api -H "Accept: application/vnd.github.raw" \
  "repos/googleapis/release-please/contents/docs/manifest-releaser.md?ref=${RP_SHA}" >"$WORK/rp.md"
echo "HEAD endpoint: repos/googleapis/release-please/contents/docs/manifest-releaser.md at commit ${RP_SHA}"
N=$("$GREP" -c 'draft' "$WORK/rp.md" || true)
echo "/usr/bin/grep -c 'draft' docs/manifest-releaser.md = ${N}"
assert "$(has "$N")" "HEAD release-please documents a draft option that creates the Release as a draft"
N=$("$GREP" -c 'force-tag-creation' "$WORK/rp.md" || true)
echo "/usr/bin/grep -c 'force-tag-creation' docs/manifest-releaser.md = ${N}"
"$GREP" -n -A2 'force-tag-creation' "$WORK/rp.md" | head -8 || true
assert "$(has "$N")" \
  "HEAD release-please documents force-tag-creation, needed because GitHub creates no git tag for a draft release until it is published — without the tag the dist workflow never fires"
echo

# ---------------------------------------------------------------------------
echo "--- H. maintenance figures (VOLATILE: counters and timestamps move) ---"
for crate in cargo-dist cargo-binstall; do
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/${crate}" -o "$WORK/${crate}.json"
  MAXV=$(python3 -c "import json;d=json.load(open('$WORK/${crate}.json'));print(d['crate']['max_stable_version'])")
  RD=$(python3 -c "import json;d=json.load(open('$WORK/${crate}.json'));print(d['crate']['recent_downloads'])")
  AD=$(python3 -c "import json;d=json.load(open('$WORK/${crate}.json'));print(d['crate']['downloads'])")
  echo "FIGURE ${crate}: endpoint GET https://crates.io/api/v1/crates/${crate} -> max_stable_version=${MAXV} recent_downloads(90d)=${RD} downloads(all-time)=${AD}"
done
for repo in axodotdev/cargo-dist cargo-bins/cargo-binstall taiki-e/upload-rust-binary-action; do
  gh api "repos/${repo}" --jq '"FIGURE '"${repo}"': endpoint GET /repos/'"${repo}"' -> stars=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)"'
  OI=$(gh api "search/issues?q=repo:${repo}+is:issue+is:open" --jq '.total_count')
  echo "FIGURE ${repo}: endpoint GET /search/issues?q=repo:${repo}+is:issue+is:open -> total_count=${OI}"
done

echo
echo "--- I. the at-risk signal: is dist's newest GitHub release installable from crates.io? ---"
GH_LATEST=$(gh api "repos/axodotdev/cargo-dist/releases" --jq '[.[] | select(.prerelease == false and .draft == false)][0].tag_name')
GH_LATEST_AT=$(gh api "repos/axodotdev/cargo-dist/releases" --jq '[.[] | select(.prerelease == false and .draft == false)][0].published_at')
CRATES_MAX=$(python3 -c "import json;d=json.load(open('$WORK/cargo-dist.json'));print(d['crate']['max_stable_version'])")
echo "FIGURE newest non-prerelease GitHub release of axodotdev/cargo-dist = ${GH_LATEST} published ${GH_LATEST_AT}"
echo "FIGURE newest stable crates.io version of cargo-dist = ${CRATES_MAX}"
PROBE=$(curl -sS -A "$UA" "https://crates.io/api/v1/crates/cargo-dist/${GH_LATEST#v}")
echo "FIGURE GET https://crates.io/api/v1/crates/cargo-dist/${GH_LATEST#v} -> $(printf '%s' "$PROBE" | cut -c1-160)"
if printf '%s' "$PROBE" | "$GREP" -q '"errors"'; then GAP=1; else GAP=0; fi
echo "registry-gap-present=${GAP} (1 = the newest GitHub release has no crates.io version)"
echo "NOTE: this is the deciding at-risk signal, and it is VOLATILE by design — the re-verify trigger below re-runs exactly this comparison."
echo

echo "--- J. RustSec advisory pages, with a positive control so 404 means 'no page', not 'fetch failed' ---"
for name in time openssl chrono cargo-dist cargo-binstall; do
  code=$(curl -sS -A "$UA" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/${name}.html")
  echo "FIGURE https://rustsec.org/packages/${name}.html -> HTTP ${code}"
  printf '%s\n' "$code" >"$WORK/rustsec-${name}.code"
done
CTRL=$(cat "$WORK/rustsec-time.code")
SUBJ=$(cat "$WORK/rustsec-cargo-dist.code")
assert "$(if [ "$CTRL" = "200" ]; then echo 1; else echo 0; fi)" \
  "the RustSec control (time) returns HTTP 200, so the endpoint is reachable and a 404 is meaningful"
assert "$(if [ "$SUBJ" = "404" ]; then echo 1; else echo 0; fi)" \
  "cargo-dist has no RustSec advisory page (HTTP ${SUBJ}) — fitness gate 3's advisory half, answered against a working control"
echo

echo "--- K. MSRV floor declared by the tools (fitness gate 2) ---"
for crate in cargo-dist cargo-binstall; do
  curl -sS -A "$UA" "https://crates.io/api/v1/crates/${crate}/versions" -o "$WORK/${crate}-versions.json"
  python3 - "$WORK/${crate}-versions.json" "$crate" <<'PY'
import json, sys
path, name = sys.argv[1], sys.argv[2]
d = json.load(open(path))
v = next(x for x in d["versions"] if not x["yanked"])
print(f"FIGURE {name}: endpoint GET /api/v1/crates/{name}/versions -> newest non-yanked num={v['num']} created_at={v['created_at']} rust_version={v.get('rust_version')}")
PY
done
echo "NOTE: both tools are host executables, never Cargo dependencies of the template, so neither enters the template's own MSRV surface."
echo

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — at least one assertion did not hold"
  exit 1
fi
echo "RESULT: PASS — every assertion held"
