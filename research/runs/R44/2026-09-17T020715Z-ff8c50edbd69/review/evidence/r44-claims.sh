#!/usr/bin/env bash
# shellcheck disable=SC2016
#   SC2016 is disabled file-wide and deliberately: the single-quoted strings it
#   flags are literal search patterns and literal section labels that contain
#   backticks (`ubuntu-latest`, `rustup toolchain install`). Nothing in them is
#   a shell expansion, and single quotes are the point rather than an oversight.
#
# R44 devcontainer-environment — synthesizer empirical check.
#
# Verifies the claims the two raw reports make about a devcontainer for
# rs-launch-blueprint. It IMPLEMENTS NOTHING: it writes no
# `.devcontainer/devcontainer.json`, no `post-create.sh`, no CI job and no
# template scaffold, and it never runs a container. Every container fact below
# is read from the registry's HTTP API (manifests, config blob), which needs no
# container runtime and no `docker` binary.
#
# Determinism contract
# --------------------
#   * Every network response is snapshotted once into ./snap/ and read from the
#     snapshot afterwards, because the sources drift: star counts move, tags are
#     added, a runner readme is regenerated. `snap/RETRIEVED.txt` records the
#     UTC date each snapshot was first fetched. Delete ./snap/ to re-fetch.
#   * Registry manifests and blobs are content-addressed, so the image facts
#     reproduce byte-for-byte from the digest whatever the tag later points at.
#     Text files from GitHub are read at a PINNED ref (a tag or a commit sha
#     recorded in snap/RETRIEVED.txt), never at a branch tip, except where the
#     check is explicitly about a repository's current state.
#   * No machine-dependent text reaches stdout: the host toolchain and platform
#     go to ./toolchain.txt. So on a rerun with ./snap/ present,
#     `bash r44-claims.sh > /tmp/out && diff /tmp/out r44-claims.log` is empty.
#   * The script reads repository files relative to its own location, so it runs
#     unchanged inside a `git archive HEAD` extraction. Anything outside that
#     extraction — this repository's .git, the sibling py/ts checkouts, a local
#     rustup, the network with no snapshot — prints `SKIP <name> — <reason>`
#     by name instead of failing silently.
#
# Usage: bash r44-claims.sh          (run from anywhere)

set -uo pipefail

GREP=/usr/bin/grep
WC=/usr/bin/wc
EVID=$(cd -- "$(dirname -- "$0")" && pwd)
SNAP="$EVID/snap"
RUNDIR=$(cd -- "$EVID/../.." && pwd)
REPO=$(cd -- "$RUNDIR/../../../.." && pwd)
PY_REPO="$HOME/c/py-launch-blueprint"
TS_REPO="$HOME/c/ts-launch-blueprint"
PY_PIN=b08bccfb
TS_PIN=cb1cbcb2

# Pinned refs. Recorded here and echoed into snap/RETRIEVED.txt on first fetch.
IMAGE_REPO=devcontainers/rust
IMAGE_TAG=2.1.1-trixie
IMAGE_ALIAS_TAG=2-trixie
IMAGE_DIGEST=sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3
FEATURE_RUST_TAG=feature_rust_1.6.0

FAILED=0
section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }
skip()    { printf 'SKIP %s — %s\n' "$1" "$2"; }

# assert <label> <expected> <actual>
assert() {
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (expected %s, got %s; counting binary: %s)\n' "$1" "$2" "$3" "$GREP"
  else
    printf 'FAIL %s (expected %s, got %s; counting binary: %s)\n' "$1" "$2" "$3" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}

# contains <label> <file> <fixed-string>   — asserts the file contains it
contains() {
  local n
  n=$($GREP -c -F -- "$3" "$2" 2>/dev/null || true)
  if [ "${n:-0}" -ge 1 ]; then
    printf 'PASS %s (>=1 match of %s; counting binary: %s)\n' "$1" "$(printf '%q' "$3")" "$GREP"
  else
    printf 'FAIL %s (0 matches of %s; counting binary: %s)\n' "$1" "$(printf '%q' "$3")" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}

mkdir -p "$SNAP"
RETR="$SNAP/RETRIEVED.txt"
note_retrieval() {
  [ -f "$RETR" ] || {
    {
      printf 'R44 evidence snapshots — first retrieval\n'
      printf 'date-utc: %s\n' "$(date -u +%Y-%m-%d)"
      printf 'image: mcr.microsoft.com/%s tag %s\n' "$IMAGE_REPO" "$IMAGE_TAG"
      printf 'rust-feature ref: %s\n' "$FEATURE_RUST_TAG"
    } > "$RETR"
  }
}

# snap_curl <snapfile> <url> [accept-header]
snap_curl() {
  local f="$SNAP/$1" url="$2" acc="${3:-}"
  if [ ! -s "$f" ]; then
    note_retrieval
    if [ -n "$acc" ]; then
      curl -sSL -H "Accept: $acc" -o "$f" "$url" || return 1
    else
      curl -sSL -o "$f" "$url" || return 1
    fi
  fi
  [ -s "$f" ]
}

# snap_curl_headers <snapfile> <url> <accept-header>
snap_curl_headers() {
  local f="$SNAP/$1"
  if [ ! -s "$f" ]; then
    note_retrieval
    curl -sS -D "$f" -o /dev/null -H "Accept: $3" "$2" || return 1
  fi
  [ -s "$f" ]
}

# snap_gh <snapfile> <endpoint> [accept]   — authenticated GitHub REST.
# The token is never printed: gh reads it from its own config.
snap_gh() {
  local f="$SNAP/$1" ep="$2" acc="${3:-}"
  if [ ! -s "$f" ]; then
    note_retrieval
    if [ -n "$acc" ]; then
      gh api "$ep" -H "Accept: $acc" > "$f" 2>/dev/null || return 1
    else
      gh api "$ep" > "$f" 2>/dev/null || return 1
    fi
  fi
  [ -s "$f" ]
}

have_jq=0
command -v jq > /dev/null 2>&1 && have_jq=1
have_gh=0
command -v gh > /dev/null 2>&1 && have_gh=1

{
  printf 'R44 evidence host record (machine-dependent; deliberately NOT on stdout)\n'
  printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'uname: %s\n' "$(uname -srm)"
  printf 'rustc: %s\n' "$(rustc --version 2>/dev/null || echo 'absent')"
  printf 'cargo: %s\n' "$(cargo --version 2>/dev/null || echo 'absent')"
  printf 'rustup: %s\n' "$(rustup --version 2>/dev/null | head -1 || echo 'absent')"
  printf 'curl: %s\n' "$(curl --version 2>/dev/null | head -1)"
  printf 'jq: %s\n' "$(jq --version 2>/dev/null || echo 'absent')"
  printf 'gh: %s\n' "$(gh --version 2>/dev/null | head -1 || echo 'absent')"
  printf 'repo-root: %s\n' "$REPO"
} > "$EVID/toolchain.txt"

printf 'R44 devcontainer-environment — synthesizer empirical check\n'
printf 'Nothing is built and no container is run. Registry facts come from the\n'
printf 'OCI HTTP API; GitHub facts from the REST API at pinned refs.\n'

###############################################################################
section '1 · The recommended image: identity, portability, size'
###############################################################################
# Settles: HIGH q1 (a canonical first-party Rust devcontainer image exists);
# gate 4 (runs on both cells of target-os-matrix); gate 6 substitute (pull size);
# the digest the recommendation pins; and the F193 finding's factual base
# (the image already contributes the three extensions).

if ! snap_curl_headers image-index-headers.txt \
    "https://mcr.microsoft.com/v2/$IMAGE_REPO/manifests/$IMAGE_TAG" \
    'application/vnd.oci.image.index.v1+json'; then
  skip '1 image-index-headers' 'no network and no snapshot'
else
  claim "1a · mcr.microsoft.com/$IMAGE_REPO:$IMAGE_TAG resolves to the pinned index digest"
  hdr_digest=$($GREP -i '^docker-content-digest:' "$SNAP/image-index-headers.txt" \
    | tr -d '\r' | awk '{print $2}')
  assert 'index digest equals the digest the decision pins' "$IMAGE_DIGEST" "$hdr_digest"
  status=$($GREP -c '^HTTP/2 200' "$SNAP/image-index-headers.txt" || true)
  assert 'registry returned HTTP 200 for the tag' '1' "$status"
fi

if ! snap_curl image-index.json \
    "https://mcr.microsoft.com/v2/$IMAGE_REPO/manifests/$IMAGE_TAG" \
    'application/vnd.oci.image.index.v1+json'; then
  skip '1 image-index' 'no network and no snapshot'
elif [ "$have_jq" = 0 ]; then
  skip '1 image-index parse' 'jq absent'
else
  claim '1b · the index is multi-architecture (the macOS-host fact)'
  mt=$(jq -r '.mediaType' "$SNAP/image-index.json")
  assert 'media type is an OCI image index' 'application/vnd.oci.image.index.v1+json' "$mt"
  arches=$(jq -r '[.manifests[]|select(.platform.os=="linux")|.platform.architecture]|sort|join(",")' \
    "$SNAP/image-index.json")
  assert 'linux platforms present' 'amd64,arm64' "$arches"
  printf 'NOTE an Apple-Silicon macOS host runs the arm64 child natively, not emulated.\n'

  claim '1c · the human-readable rolling tag currently resolves to the same digest'
  if snap_curl_headers image-alias-headers.txt \
      "https://mcr.microsoft.com/v2/$IMAGE_REPO/manifests/$IMAGE_ALIAS_TAG" \
      'application/vnd.oci.image.index.v1+json'; then
    alias_digest=$($GREP -i '^docker-content-digest:' "$SNAP/image-alias-headers.txt" \
      | tr -d '\r' | awk '{print $2}')
    assert "$IMAGE_ALIAS_TAG resolves to the pinned digest" "$IMAGE_DIGEST" "$alias_digest"
    printf 'NOTE this is a CURRENT-STATE check, not a content-addressed one: the alias\n'
    printf '     tag moves when a new 2.x image is published, and this assertion is\n'
    printf '     then expected to fail. That failure is the bump signal, not a defect.\n'
  else
    skip '1c alias tag' 'no network and no snapshot'
  fi

  arm_digest=$(jq -r '.manifests[]|select(.platform.os=="linux" and .platform.architecture=="arm64")|.digest' \
    "$SNAP/image-index.json")
  if snap_curl image-arm64-manifest.json \
      "https://mcr.microsoft.com/v2/$IMAGE_REPO/manifests/$arm_digest" \
      'application/vnd.oci.image.manifest.v1+json'; then
    claim '1d · compressed pull size (gate 6 substitute), arm64'
    layers=$(jq -r '.layers|length' "$SNAP/image-arm64-manifest.json")
    bytes=$(jq -r '[.layers[].size]|add' "$SNAP/image-arm64-manifest.json")
    assert 'layer count' '15' "$layers"
    assert 'summed compressed layer bytes' '871370327' "$bytes"
    printf 'NOTE 871370327 bytes is ~831 MiB COMPRESSED. It is not a duration: no pull\n'
    printf '     and no container create was timed in this item.\n'

    cfg_digest=$(jq -r '.config.digest' "$SNAP/image-arm64-manifest.json")
    if snap_curl image-arm64-config.json \
        "https://mcr.microsoft.com/v2/$IMAGE_REPO/blobs/$cfg_digest"; then
      claim '1e · the image is the Rust project own image, carrying rustup'
      src=$(jq -r '.config.Labels["org.opencontainers.image.source"]' "$SNAP/image-arm64-config.json")
      assert 'org.opencontainers.image.source' \
        'https://github.com/rust-lang/docker-rust' "$src"
      rel=$(jq -r '.config.Labels["dev.containers.release"]' "$SNAP/image-arm64-config.json")
      ts=$(jq -r '.config.Labels["dev.containers.timestamp"]' "$SNAP/image-arm64-config.json")
      printf 'dev.containers.release = %s\ndev.containers.timestamp = %s\n' "$rel" "$ts"
      rv=$(jq -r '.config.Env[]|select(startswith("RUST_VERSION="))' "$SNAP/image-arm64-config.json")
      assert 'baked RUST_VERSION' 'RUST_VERSION=1.98.1' "$rv"
      ch=$(jq -r '.config.Env[]|select(startswith("CARGO_HOME="))' "$SNAP/image-arm64-config.json")
      rh=$(jq -r '.config.Env[]|select(startswith("RUSTUP_HOME="))' "$SNAP/image-arm64-config.json")
      assert 'CARGO_HOME (the cache mount target)' 'CARGO_HOME=/usr/local/cargo' "$ch"
      assert 'RUSTUP_HOME (NOT under that mount)' 'RUSTUP_HOME=/usr/local/rustup' "$rh"

      claim '1f · what the image already contributes, so the template need not'
      ids=$(jq -r '.config.Labels["devcontainer.metadata"]' "$SNAP/image-arm64-config.json" \
        | jq -r '[.[]|.id // empty]|join(",")')
      assert 'baked features' \
        'ghcr.io/devcontainers/features/common-utils:2,ghcr.io/devcontainers/features/git:1,ghcr.io/devcontainers/features/rust:1' \
        "$ids"
      exts=$(jq -r '.config.Labels["devcontainer.metadata"]' "$SNAP/image-arm64-config.json" \
        | jq -r '[.[]|.customizations.vscode.extensions // empty]|flatten|sort|join(",")')
      assert 'VS Code extensions contributed by the image metadata' \
        'rust-lang.rust-analyzer,tamasfe.even-better-toml,vadimcn.vscode-lldb' "$exts"
      ru=$(jq -r '.config.Labels["devcontainer.metadata"]' "$SNAP/image-arm64-config.json" \
        | jq -r '[.[]|.remoteUser // empty]|join(",")')
      assert 'remoteUser baked into the image' 'vscode' "$ru"
      watcher=$(jq -r '.config.Labels["devcontainer.metadata"]' "$SNAP/image-arm64-config.json" \
        | jq -r '[.[]|.customizations.vscode.settings["files.watcherExclude"]|select(.!=null)]|length')
      assert 'files.watcherExclude setting already contributed' '1' "$watcher"
      caps=$(jq -r '.config.Labels["devcontainer.metadata"]' "$SNAP/image-arm64-config.json" \
        | jq -r '[.[]|.capAdd // empty]|flatten|join(",")')
      assert 'capAdd (a DEVELOPMENT container loosening, never a deployment image)' \
        'SYS_PTRACE' "$caps"
    else
      skip '1e/1f image config blob' 'no network and no snapshot'
    fi
  else
    skip '1d arm64 child manifest' 'no network and no snapshot'
  fi
fi

###############################################################################
section '2 · The alternative both engines rejected: universal + rust feature'
###############################################################################
# Settles: why biome architecture (universal:6 + the rust feature) is excluded
# on gate 4 for a fixed target matrix that includes an Apple-Silicon macOS host.

if ! snap_curl universal-index.json \
    'https://mcr.microsoft.com/v2/devcontainers/universal/manifests/6' \
    'application/vnd.oci.image.index.v1+json'; then
  skip '2 universal index' 'no network and no snapshot'
elif [ "$have_jq" = 0 ]; then
  skip '2 universal index parse' 'jq absent'
else
  claim '2a · mcr.microsoft.com/devcontainers/universal:6 architecture coverage'
  uarch=$(jq -r '[.manifests[]|select(.platform.os=="linux")|.platform.architecture]|sort|unique|join(",")' \
    "$SNAP/universal-index.json")
  assert 'linux architectures offered' 'amd64' "$uarch"
  ubytes=$(jq -r '[.manifests[]|select(.platform.os=="linux" and .platform.architecture=="amd64")|.digest]|.[0]' \
    "$SNAP/universal-index.json")
  printf 'amd64 child manifest digest: %s\n' "$ubytes"
  printf 'NOTE amd64-only means an Apple-Silicon host — half the fixed target matrix —\n'
  printf '     runs it under emulation. That is the gate-4 exclusion.\n'
fi

###############################################################################
section '3 · How macOS hosts reach a Linux devcontainer, and where CI proves it'
###############################################################################
# Settles: the target-os-matrix question. The container runs on a macOS host via
# a third-party runtime the template does not ship, or via Codespaces with no
# local runtime; the CI validation job can only run on ubuntu-latest.

if [ "$have_gh" = 0 ]; then
  skip '3 runner images' 'gh absent'
else
  claim '3a · which runner image each -latest label resolves to today'
  if snap_gh runner-images-README.md 'repos/actions/runner-images/contents/README.md' \
      'application/vnd.github.raw'; then
    $GREP -n 'macos-latest`\|`ubuntu-latest`' "$SNAP/runner-images-README.md" \
      | /usr/bin/sed -e 's/!\[Endpoint Badge\][^|]*//' | /usr/bin/cut -c1-200
    contains 'macos-latest maps to the macOS 26 Arm64 image' \
      "$SNAP/runner-images-README.md" '[macOS-26-arm64]'
    contains 'ubuntu-latest maps to the Ubuntu 24.04 image' \
      "$SNAP/runner-images-README.md" '[ubuntu-24.04]'
  else
    skip '3a runner-images README' 'no network and no snapshot'
  fi

  claim '3b · container runtime inventory of those two images (GitHub own inventory)'
  if snap_gh macos-26-arm64-Readme.md \
      'repos/actions/runner-images/contents/images/macos/macos-26-arm64-Readme.md' \
      'application/vnd.github.raw' \
   && snap_gh Ubuntu2404-Readme.md \
      'repos/actions/runner-images/contents/images/ubuntu/Ubuntu2404-Readme.md' \
      'application/vnd.github.raw'; then
    mac_lines=$($WC -l < "$SNAP/macos-26-arm64-Readme.md" | tr -d ' ')
    mac_docker=$($GREP -ci docker "$SNAP/macos-26-arm64-Readme.md" || true)
    printf 'macos-26-arm64 readme: %s lines (whole file read, no head/cut in the count)\n' "$mac_lines"
    assert 'case-insensitive "docker" lines in the macOS runner inventory' '0' "$mac_docker"
    contains 'Ubuntu 24.04 runner ships a Docker server' \
      "$SNAP/Ubuntu2404-Readme.md" 'Docker Server'
    contains 'Ubuntu 24.04 runner ships a Docker client' \
      "$SNAP/Ubuntu2404-Readme.md" 'Docker Client'
    printf 'NOTE this says the CI validation job runs on ubuntu-latest only. It says\n'
    printf '     NOTHING against a developer macOS host: section 1b showed the image\n'
    printf '     has a native arm64 child, reached through a runtime the template does\n'
    printf '     not provision (Docker Desktop, OrbStack, Colima, Podman) or through\n'
    printf '     GitHub Codespaces with no local runtime at all.\n'
  else
    skip '3b runner readmes' 'no network and no snapshot'
  fi
fi

###############################################################################
section '4 · Nothing bumps a pinned image digest (the accepted cost)'
###############################################################################
# Settles: whether R19 should add the `devcontainers` Dependabot ecosystem.

if [ "$have_gh" = 0 ]; then
  skip '4 dependabot' 'gh absent'
else
  claim '4a · dependabot-core devcontainers parser parses FEATURES only'
  db_sha=''
  if snap_gh dependabot-core-main.json 'repos/dependabot/dependabot-core/commits/main'; then
    if [ "$have_jq" = 1 ]; then
      db_sha=$(jq -r '.sha' "$SNAP/dependabot-core-main.json")
      printf 'dependabot-core commit read (pinned for this check): %s\n' "$db_sha"
    fi
  fi
  if [ -n "$db_sha" ] && snap_gh dependabot-devcontainers-file_parser.rb \
      "repos/dependabot/dependabot-core/contents/devcontainers/lib/dependabot/devcontainers/file_parser.rb?ref=$db_sha" \
      'application/vnd.github.raw'; then
    contains 'the parser entry point calls parse_features' \
      "$SNAP/dependabot-devcontainers-file_parser.rb" 'parse_features(config_dependency_file)'
    img_hits=$($GREP -ci 'image' "$SNAP/dependabot-devcontainers-file_parser.rb" || true)
    assert 'references to an image parser in that file' '0' "$img_hits"
  else
    skip '4a dependabot parser' 'no network and no snapshot'
  fi

  claim '4b · the pull request that would have added stale-image detection'
  if snap_gh dependabot-9271.json 'repos/dependabot/dependabot-core/issues/9271'; then
    if [ "$have_jq" = 1 ]; then
      st=$(jq -r '.state' "$SNAP/dependabot-9271.json")
      ca=$(jq -r '.closed_at' "$SNAP/dependabot-9271.json")
      ti=$(jq -r '.title' "$SNAP/dependabot-9271.json")
      assert '#9271 state' 'closed' "$st"
      printf 'title: %s\nclosed_at: %s\n' "$ti" "$ca"
      printf 'NOTE so a features-free devcontainer.json has no automated bumper. The\n'
      printf '     decision carries that as an accepted cost with a re-verify trigger.\n'
    else
      skip '4b parse' 'jq absent'
    fi
  else
    skip '4b #9271' 'no network and no snapshot'
  fi
fi

###############################################################################
section '5 · Installer integrity, and where the Codex defect actually lands'
###############################################################################
# Settles: gate 3 substitute (no RustSec page exists for an OCI image), AND the
# single concrete defect raw/codex.md found. Both are properties of the FEATURE
# (architecture C). Neither touches the image-only architecture recommended.

if [ "$have_gh" = 0 ]; then
  skip '5 installer integrity' 'gh absent'
else
  claim '5a · the rust FEATURE fetch: unversioned rustup-init, checksum from the same host'
  if snap_gh features-rust-install.sh.snapshot \
      "repos/devcontainers/features/contents/src/rust/install.sh?ref=$FEATURE_RUST_TAG" \
      'application/vnd.github.raw'; then
    contains 'fetches an unversioned rustup-init from static.rust-lang.org/rustup/dist' \
      "$SNAP/features-rust-install.sh.snapshot" 'rustup/dist/'
    contains 'fetches its checksum from the SAME host (corruption, not provenance)' \
      "$SNAP/features-rust-install.sh.snapshot" 'rustup-init.sha256'
    hard=$($GREP -c 'rustupSha256=' "$SNAP/features-rust-install.sh.snapshot" || true)
    assert 'hard-coded per-architecture sha256 constants in the feature installer' '0' "$hard"

    claim '5b · the version-resolution defect raw/codex.md reported, at the pinned tag'
    $GREP -n 'grep -o "\."' "$SNAP/features-rust-install.sh.snapshot" | /usr/bin/cut -c1-160
    contains 'the "fully specified version" test uses grep -o "." (matches every character)' \
      "$SNAP/features-rust-install.sh.snapshot" 'grep -o "." | wc -l'
    contains 'so version resolution reaches git ls-remote' \
      "$SNAP/features-rust-install.sh.snapshot" 'git ls-remote --tags'
  else
    skip '5a/5b rust feature installer' 'no network and no snapshot'
  fi

  claim '5c · the same-named issue is open'
  if snap_gh features-1726.json 'repos/devcontainers/features/issues/1726'; then
    if [ "$have_jq" = 1 ]; then
      st=$(jq -r '.state' "$SNAP/features-1726.json")
      ti=$(jq -r '.title' "$SNAP/features-1726.json")
      assert 'devcontainers/features#1726 state' 'open' "$st"
      printf 'title: %s\n' "$ti"
    else
      skip '5c parse' 'jq absent'
    fi
  else
    skip '5c issue 1726' 'no network and no snapshot'
  fi

  claim '5d · the IMAGE upstream pins rustup by version AND by hard-coded checksum'
  dr_sha=''
  if snap_gh docker-rust-master.json 'repos/rust-lang/docker-rust/commits/master' \
     && [ "$have_jq" = 1 ]; then
    dr_sha=$(jq -r '.sha' "$SNAP/docker-rust-master.json")
    printf 'rust-lang/docker-rust commit read (pinned for this check): %s\n' "$dr_sha"
  fi
  if [ -n "$dr_sha" ] && snap_gh docker-rust-trixie-Dockerfile \
      "repos/rust-lang/docker-rust/contents/stable/trixie/Dockerfile?ref=$dr_sha" \
      'application/vnd.github.raw'; then
    contains 'rustup-init fetched from a VERSIONED archive path' \
      "$SNAP/docker-rust-trixie-Dockerfile" 'rustup/archive/1.29.0/'
    n=$($GREP -c 'rustupSha256=' "$SNAP/docker-rust-trixie-Dockerfile" || true)
    assert 'hard-coded per-architecture sha256 constants in the image Dockerfile' '7' "$n"
    contains 'base image is buildpack-deps:trixie (so make/curl/git are present)' \
      "$SNAP/docker-rust-trixie-Dockerfile" 'FROM buildpack-deps:trixie'
    printf 'NOTE gate 3, stated rather than dropped: the image carries provenance\n'
    printf '     pinning the feature lacks. That is a point FOR the image-only shape.\n'
  else
    skip '5d docker-rust Dockerfile' 'no network and no snapshot'
  fi
fi

###############################################################################
section '6 · The one Rust-specific postCreate line, and why it is well-mannered'
###############################################################################

claim '6a · rustup auto-installs the toolchain rust-toolchain.toml names'
if [ "$have_gh" = 1 ] && snap_gh rustup-CHANGELOG.md \
    'repos/rust-lang/rustup/contents/CHANGELOG.md' 'application/vnd.github.raw'; then
  contains 'automatic install restored, opt-out by RUSTUP_AUTO_INSTALL' \
    "$SNAP/rustup-CHANGELOG.md" 'RUSTUP_AUTO_INSTALL'
  contains 'later lower-priority equivalent: rustup set auto-install disable' \
    "$SNAP/rustup-CHANGELOG.md" 'set auto-install disable'
else
  skip '6a rustup CHANGELOG' 'gh absent, or no network and no snapshot'
fi

claim '6b · `rustup toolchain install` with no argument installs the ACTIVE toolchain'
if command -v rustup > /dev/null 2>&1; then
  rustup toolchain install --help 2>&1 \
    | $GREP -m1 'active toolchain' | /usr/bin/sed -e 's/^[[:space:]]*//'
  helpline=$(rustup toolchain install --help 2>&1 \
    | $GREP -c 'or by default the active toolchain' || true)
  assert 'help text states the no-argument behaviour' '1' "$helpline"
  printf 'NOTE the rustup version that produced this is in ./toolchain.txt, not here,\n'
  printf '     so the log stays byte-identical across hosts.\n'
else
  skip '6b rustup toolchain install --help' 'no rustup on this host'
fi

###############################################################################
section '7 · The py and ts precedent, read at their pins (F200 and F193)'
###############################################################################

if [ ! -d "$PY_REPO/.git" ]; then
  skip '7a/7b py precedent' "sibling checkout $PY_REPO absent"
else
  claim "7a · py post-create.sh at $PY_PIN ends in the repository own two-level chain"
  py_pc=$(git -C "$PY_REPO" show "$PY_PIN:.devcontainer/post-create.sh" 2>/dev/null)
  printf '%s\n' "$py_pc" | tail -3
  n=$(printf '%s\n' "$py_pc" | $GREP -c '^make bootstrap$' || true)
  assert 'post-create.sh runs make bootstrap' '1' "$n"
  n=$(printf '%s\n' "$py_pc" | $GREP -c '^just setup$' || true)
  assert 'post-create.sh runs just setup' '1' "$n"
  n=$(printf '%s\n' "$py_pc" | $GREP -c 'apt-get install' || true)
  assert 'apt-get preamble present in py (absent from the Rust recommendation)' '1' "$n"

  claim "7b · py two extension lists at $PY_PIN have already drifted (the F193 finding)"
  if [ "$have_jq" = 1 ]; then
    git -C "$PY_REPO" show "$PY_PIN:.devcontainer/devcontainer.json" \
      | jq -r '.customizations.vscode.extensions[]' | sort > "$SNAP/py-devcontainer-extensions.txt"
    git -C "$PY_REPO" show "$PY_PIN:.vscode/extensions.json" \
      | jq -r '.recommendations[]' | sort > "$SNAP/py-vscode-recommendations.txt"
    a=$($WC -l < "$SNAP/py-devcontainer-extensions.txt" | tr -d ' ')
    b=$($WC -l < "$SNAP/py-vscode-recommendations.txt" | tr -d ' ')
    both=$(comm -12 "$SNAP/py-devcontainer-extensions.txt" "$SNAP/py-vscode-recommendations.txt")
    c=$(printf '%s\n' "$both" | $GREP -c . || true)
    assert 'extensions named in .devcontainer/devcontainer.json' '4' "$a"
    assert 'extensions named in .vscode/extensions.json' '11' "$b"
    assert 'extensions named in BOTH' '3' "$c"
    printf 'in both:\n%s\n' "$both"
    printf 'devcontainer only:\n%s\n' \
      "$(comm -23 "$SNAP/py-devcontainer-extensions.txt" "$SNAP/py-vscode-recommendations.txt")"
    d=$(comm -13 "$SNAP/py-devcontainer-extensions.txt" "$SNAP/py-vscode-recommendations.txt" | $GREP -c . || true)
    assert 'recommended natively but withheld from a container contributor' '8' "$d"
  else
    skip '7b py extension lists' 'jq absent'
  fi
fi

if [ ! -d "$TS_REPO/.git" ]; then
  skip '7c ts precedent' "sibling checkout $TS_REPO absent"
else
  claim "7c · ts at $TS_PIN carries no .devcontainer at all"
  n=$(git -C "$TS_REPO" ls-tree "$TS_PIN" -- .devcontainer | $GREP -c . || true)
  assert 'entries under .devcontainer in the ts pinned tree' '0' "$n"
fi

###############################################################################
section '8 · Practice: how many well-regarded Rust projects ship a devcontainer'
###############################################################################
# Re-probes the survey raw/opus.md reports (31 Rust-primary repositories) and
# the 3 raw/codex.md reports, so the two engines samples are compared on one
# re-executed measurement rather than on each report own assertion.

REPOS="rust-lang/rust rustdesk/rustdesk openai/codex zed-industries/zed \
astral-sh/uv BurntSushi/ripgrep rust-lang/rustlings sharkdp/bat \
starship/starship meilisearch/meilisearch typst/typst helix-editor/helix \
nushell/nushell pola-rs/polars tokio-rs/tokio influxdata/influxdb \
tokio-rs/axum vectordotdev/vector bytecodealliance/wasmtime gfx-rs/wgpu \
rust-lang/rust-analyzer clap-rs/clap rust-lang/cargo serde-rs/serde \
SeaQL/sea-orm rust-lang/rustup paritytech/polkadot-sdk astral-sh/ruff \
biomejs/biome denoland/deno tauri-apps/tauri"

if [ "$have_gh" = 0 ]; then
  skip '8 practice survey' 'gh absent'
else
  claim '8a · .devcontainer directory presence, one HTTP status per repository'
  probe="$SNAP/devcontainer-presence.txt"
  if [ ! -s "$probe" ]; then
    note_retrieval
    : > "$probe"
    for r in $REPOS; do
      code=$(gh api "repos/$r/contents/.devcontainer" --silent -i 2>/dev/null \
        | $GREP -m1 -i '^HTTP/' | awk '{print $2}' | tr -d '\r')
      [ -n "$code" ] || code=404
      printf '%s %s\n' "$r" "$code" >> "$probe"
    done
  fi
  /usr/bin/sort "$probe"
  total=$($GREP -c . "$probe" || true)
  present=$($GREP -c ' 200$' "$probe" || true)
  assert 'repositories probed (whole file counted, no head/cut)' '31' "$total"
  assert 'repositories carrying a .devcontainer directory' '4' "$present"
  printf 'NOTE the direction of this signal is AGAINST adopting: most well-regarded\n'
  printf '     Rust projects ship no devcontainer. The decision carries that as the\n'
  printf '     runner-up case, not as a refutation of the adopters being template-like.\n'
fi

###############################################################################
section '9 · Repository-local facts the decision depends on'
###############################################################################

claim '9a · the four fixed registry rows are byte-identical to this run inputs'
reg="$REPO/docs/port/PARAMETERS.md"
inp="$RUNDIR/inputs/PARAMETERS.md"
if [ ! -f "$reg" ] || [ ! -f "$inp" ]; then
  skip '9a parameter rows' 'registry or run inputs not present in this extraction'
else
  for p in msrv-policy rust-edition target-os-matrix license; do
    a=$($GREP -m1 "^| $p | fixed |" "$reg")
    b=$($GREP -m1 "^| $p | fixed |" "$inp")
    if [ "$a" = "$b" ]; then
      printf 'PASS %s row byte-identical between registry and run inputs (binary: %s)\n' "$p" "$GREP"
    else
      printf 'FAIL %s row differs between registry and run inputs (binary: %s)\n' "$p" "$GREP"
      FAILED=$((FAILED + 1))
    fi
  done
  claim '9b · the four values this decision writes under ## Parameters'
  for p in msrv-policy rust-edition target-os-matrix license; do
    printf -- '- assumes %s = %s\n' "$p" \
      "$($GREP -m1 "^| $p | fixed |" "$reg" | awk -F' \\| ' '{print $4}')"
  done
fi

claim '9c · the prerequisite decision this run was given is the published one'
prereq="$RUNDIR/inputs/prerequisites.json"
r42="$REPO/research/topics/42-dev-toolchain-provisioning/DECISION.md"
if [ ! -f "$prereq" ] || [ ! -f "$r42" ] || [ "$have_jq" = 0 ]; then
  skip '9c prerequisite hash' 'prerequisites.json, R42 DECISION.md or jq absent'
else
  want=$(jq -r '.R42.decision' "$prereq")
  got=$(shasum -a 256 "$r42" | awk '{print $1}')
  assert 'R42 DECISION.md sha256 matches inputs/prerequisites.json' "$want" "$got"
fi

claim '9d · R69 has since published web-extra-surface; it fixes no port number'
if [ ! -f "$reg" ]; then
  skip '9d web-extra-surface' 'registry not present in this extraction'
else
  row=$($GREP -m1 '^| web-extra-surface | researched |' "$reg")
  if printf '%s' "$row" | $GREP -q 'stays an environment variable named by R77'; then
    printf 'PASS web-extra-surface leaves host/port to an R77-named environment variable (binary: %s)\n' "$GREP"
    printf 'NOTE therefore the recommendation declares no forwardPorts key, and the\n'
    printf '     reason is stronger than "R69 is unset": R69 is resolved and fixes no port.\n'
  else
    printf 'FAIL web-extra-surface row does not carry the environment-variable clause (binary: %s)\n' "$GREP"
    FAILED=$((FAILED + 1))
  fi
fi

###############################################################################
section 'Result'
###############################################################################
if [ "$FAILED" -eq 0 ]; then
  printf 'ALL ASSERTIONS PASSED (0 failures)\n'
else
  printf 'FAILURES: %s\n' "$FAILED"
fi
printf 'Host toolchain record: ./toolchain.txt\n'
printf 'Snapshots and their first-retrieval date: ./snap/RETRIEVED.txt\n'
exit "$FAILED"
