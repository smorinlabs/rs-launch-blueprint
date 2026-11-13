#!/usr/bin/env bash
# Fetches the cargo-semver-checks v0.50.0 prebuilt binaries that run-checks.sh
# expects under .tools/{macos,linux}/ (git-ignored). Asset names were listed via
# GET https://api.github.com/repos/obi1kenobi/cargo-semver-checks/releases/tags/v0.50.0
# on 2026-09-05. Override TAG to pin a different release.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TAG="${TAG:-v0.50.0}"
BASE="https://github.com/obi1kenobi/cargo-semver-checks/releases/download/$TAG"

fetch() { # <subdir> <asset>
  mkdir -p "$HERE/.tools/$1"
  curl -sSL --retry 3 "$BASE/$2" | tar -xzf - -C "$HERE/.tools/$1"
  "$HERE/.tools/$1/cargo-semver-checks" --version 2>/dev/null \
    || echo "$1: fetched $2 (not runnable on this host)"
}

fetch macos cargo-semver-checks-aarch64-apple-darwin.tar.gz
fetch linux cargo-semver-checks-aarch64-unknown-linux-gnu.tar.gz
