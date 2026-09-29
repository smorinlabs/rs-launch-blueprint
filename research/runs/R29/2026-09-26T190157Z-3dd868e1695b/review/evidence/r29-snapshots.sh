#!/usr/bin/env bash
# R29 revision 1 — capture every source this decision adjudicates from, once,
# into snapshots/, with its endpoint and UTC retrieval time in PROVENANCE.tsv.
# Network: crates.io API, api.github.com (through `gh api`), rustsec.org only —
# the three endpoints the R29 prompt names. Every other r29-*.sh reads these
# snapshots offline. Re-running this script refreshes them (figures may move).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots"
mkdir -p "$snap"
prov="$snap/PROVENANCE.tsv"
printf 'file\tendpoint\tretrieved_utc\tstatus\n' >"$prov"
ua='rs-launch-blueprint-R29-synthesis'

record() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$(date -u +%FT%TZ)" "$3" >>"$prov"; }

crate() { # crates.io JSON
  local name="$1" out="$snap/crates-$1.json" code
  code=$(curl -sS -A "$ua" -o "$out" -w '%{http_code}' "https://crates.io/api/v1/crates/$name")
  record "crates-$name.json" "GET https://crates.io/api/v1/crates/$name" "$code"
}

gh_json() { # api.github.com JSON: <file> <path>
  local out="$snap/$1" code=0
  gh api -H 'Accept: application/vnd.github+json' "$2" >"$out" 2>"$out.err" || code=$?
  record "$1" "GET https://api.github.com/$2" "gh-exit-$code"
  rm -f "$out.err"
}

gh_raw() { # api.github.com contents, raw media type: <file> <path>
  local out="$snap/$1" code=0
  gh api -H 'Accept: application/vnd.github.raw' "$2" >"$out" 2>"$out.err" || code=$?
  record "$1" "GET https://api.github.com/$2 (Accept: application/vnd.github.raw)" "gh-exit-$code"
  rm -f "$out.err"
}

rustsec() {
  local code
  code=$(curl -sS -A "$ua" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/$1.html")
  record "rustsec-$1" "GET https://rustsec.org/packages/$1.html" "$code"
}

for c in dprint dprint-plugin-json dprint-plugin-markdown dprint-plugin-toml pretty_yaml \
         taplo-cli taplo tombi-cli rumdl yamlfmt dprint-plugin-yaml; do
  crate "$c"
done

gh_json repo-tamasfe-taplo.json repos/tamasfe/taplo
gh_json repo-dprint-dprint.json repos/dprint/dprint
gh_json repo-g-plane-pretty_yaml.json repos/g-plane/pretty_yaml
gh_json repo-dprint-dprint-plugin-toml.json repos/dprint/dprint-plugin-toml
gh_json repo-tombi-toml-tombi.json repos/tombi-toml/tombi
gh_json taplo-issue-715.json repos/tamasfe/taplo/issues/715
gh_json taplo-issue-715-comments.json "repos/tamasfe/taplo/issues/715/comments?per_page=100"
gh_json taplo-release-0.10.0.json repos/tamasfe/taplo/releases/tags/0.10.0
gh_json dprint-release-0.57.4.json repos/dprint/dprint/releases/tags/0.57.4
gh_json pretty_yaml-issue-4.json repos/g-plane/pretty_yaml/issues/4
gh_json pretty_yaml-issue-4-comments.json repos/g-plane/pretty_yaml/issues/4/comments
gh_json pretty_yaml-release-v0.6.0.json repos/g-plane/pretty_yaml/releases/tags/v0.6.0

gh_json dprint-plugin-json-release-0.24.0.json repos/dprint/dprint-plugin-json/releases/tags/0.24.0
gh_json dprint-plugin-markdown-release-0.24.0.json repos/dprint/dprint-plugin-markdown/releases/tags/0.24.0
gh_json dprint-plugin-toml-release-0.8.0.json repos/dprint/dprint-plugin-toml/releases/tags/0.8.0

gh_raw binstall-hosting.rs "repos/cargo-bins/cargo-binstall/contents/crates/binstalk-fetchers/src/gh_crate_meta/hosting.rs?ref=v1.23.0"
gh_raw release-please-CHANGELOG.md repos/googleapis/release-please/contents/CHANGELOG.md
gh_raw dprint-dprint.json repos/dprint/dprint/contents/dprint.json
gh_raw dprint-cli.md repos/dprint/dprint/contents/website/src/cli.md
gh_raw dprint-config.md repos/dprint/dprint/contents/website/src/config.md
gh_raw dprint-crate-Cargo.toml repos/dprint/dprint/contents/crates/dprint/Cargo.toml
gh_raw dprint-rust-toolchain.toml repos/dprint/dprint/contents/rust-toolchain.toml
gh_raw deno-dprint.json repos/denoland/deno/contents/.dprint.json
gh_raw rustup-ci.yaml repos/rust-lang/rustup/contents/.github/workflows/ci.yaml
gh_raw style-guide-cargo.md repos/rust-lang/rust/contents/src/doc/style-guide/src/cargo.md
gh_raw dprint-plugin-toml-resolve_config.rs "repos/dprint/dprint-plugin-toml/contents/src/configuration/resolve_config.rs?ref=0.8.0"
gh_raw dprint-plugin-toml-cargo.rs "repos/dprint/dprint-plugin-toml/contents/src/cargo.rs?ref=0.8.0"
gh_raw pretty_yaml-dprint_plugin-Cargo.toml "repos/g-plane/pretty_yaml/contents/dprint_plugin/Cargo.toml?ref=v0.6.0"
gh_raw pretty_yaml-dprint_plugin-lib.rs "repos/g-plane/pretty_yaml/contents/dprint_plugin/src/lib.rs?ref=v0.6.0"
gh_raw pretty_yaml-dprint_plugin-config.rs "repos/g-plane/pretty_yaml/contents/dprint_plugin/src/config.rs?ref=v0.6.0"
gh_raw pretty_yaml-LICENSE "repos/g-plane/pretty_yaml/contents/LICENSE?ref=v0.6.0"
gh_raw pretty_yaml-workspace-Cargo.toml "repos/g-plane/pretty_yaml/contents/Cargo.toml?ref=v0.6.0"

for p in dprint dprint-plugin-json dprint-plugin-markdown dprint-plugin-toml pretty_yaml \
         taplo taplo-cli time; do
  rustsec "$p"
done

echo "snapshots: $(($(wc -l <"$prov") - 1)) entries"
awk -F'\t' 'NR>1 && $4 !~ /^(200|404|gh-exit-0)$/ {bad=1; print "UNEXPECTED:", $0} END {exit bad}' "$prov"
echo "r29-snapshots: OK"
