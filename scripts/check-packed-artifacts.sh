#!/usr/bin/env bash
# check-packed-artifacts.sh — enforce all four R26 packed `.crate` content guards plus OV-18
# publish-boundary verification.
#
# For each publishable workspace package (`rs-launch-blueprint-core`, `rs-launch-blueprint`,
# `rs-launch-blueprint-cli`):
#   Guard 4 (manifest allow-list): `[package] include` is declared and `exclude` is absent.
#   Guard 1 (F039 file-set diff): `cargo package -p <pkg> --list --no-verify --offline --locked`
#           matches byte-sorted `ci/expected-packed-files/<pkg>.txt`.
#   Guard 2 (F078 packaged-metadata): `cargo package` aborts on nonzero exit
#           (preventing stale-archive reads), then verifies:
#           (a) scoped stderr grep detects pruned lib/bin/build targets or include+exclude;
#           (b) extracted `.crate` target set `{name, kind}` matches
#               `ci/expected-packaged-targets/<pkg>.json`;
#           (c) source `Cargo.toml` is byte-identical (`cmp`) to extracted `Cargo.toml.orig`;
#           (d) publish-facing metadata projection from source equals extracted archive.
#   (Guard 3, `cargo publish --workspace --dry-run --locked`, runs as the final verify
#    step in `.github/workflows/publish.yml`.)
#
# Also asserts that private deployment crates (`rs-launch-blueprint-web`) declare `publish = false`
# (`publish == []` in `cargo metadata`).
set -euo pipefail

allow_dirty=0
no_verify=0
offline=0
packages=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --allow-dirty)
      allow_dirty=1
      shift
      ;;
    --no-verify)
      no_verify=1
      shift
      ;;
    --offline)
      offline=1
      shift
      ;;
    -p | --package)
      if [ "$#" -lt 2 ]; then
        echo "error: $1 requires a package name" >&2
        exit 2
      fi
      packages+=("$2")
      shift 2
      ;;
    *)
      echo "usage: $0 [--allow-dirty] [--no-verify] [--offline] [-p <pkg>]..." >&2
      exit 2
      ;;
  esac
done

publishable_workspace_packages=(
  rs-launch-blueprint-core
  rs-launch-blueprint
  rs-launch-blueprint-cli
)

non_publishable_workspace_packages=(
  rs-launch-blueprint-web
)

if [ "${#packages[@]}" -eq 0 ]; then
  packages=("${publishable_workspace_packages[@]}")
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required by check-packed-artifacts.sh" >&2
  exit 2
fi

meta_json=$(cargo metadata --no-deps --format-version 1 --offline --locked)
target_dir=$(jq -r '.target_directory' <<<"$meta_json")

# Verify private deployment crates declare `publish = false` (`publish == []` in cargo metadata).
for private_pkg in "${non_publishable_workspace_packages[@]}"; do
  pub_field=$(jq -c --arg pkg "$private_pkg" '.packages[] | select(.name == $pkg) | .publish' <<<"$meta_json")
  if [ "$pub_field" != "[]" ]; then
    echo "FAIL [OV-18]: private deployment crate '${private_pkg}' must declare publish = false (got publish=${pub_field})" >&2
    exit 1
  fi
done

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

projection_filter='{
  name,
  version,
  description,
  license,
  license_file,
  repository,
  homepage,
  documentation,
  readme,
  keywords,
  categories,
  rust_version,
  edition,
  links,
  publish,
  default_run
}'

# Pre-pack guards: Guard 4 (include allow-list, no exclude) and Guard 1 (F039 file-set diff).
for pkg in "${packages[@]}"; do
  expected_files="ci/expected-packed-files/${pkg}.txt"
  expected_targets="ci/expected-packaged-targets/${pkg}.json"
  if [ ! -f "$expected_files" ]; then
    echo "FAIL [R26]: missing expectation file $expected_files" >&2
    exit 1
  fi
  if [ ! -f "$expected_targets" ]; then
    echo "FAIL [R26]: missing expectation file $expected_targets" >&2
    exit 1
  fi

  manifest_path=$(jq -r --arg pkg "$pkg" '.packages[] | select(.name == $pkg) | .manifest_path' <<<"$meta_json")
  pkg_version=$(jq -r --arg pkg "$pkg" '.packages[] | select(.name == $pkg) | .version' <<<"$meta_json")
  if [ -z "$manifest_path" ] || [ -z "$pkg_version" ]; then
    echo "FAIL [R26]: package '$pkg' not found in workspace metadata" >&2
    exit 1
  fi

  # Guard 4: [package] include must be declared and never alongside exclude.
  python3 - "$manifest_path" "$pkg" <<'PY'
import sys, tomllib
manifest_path, pkg = sys.argv[1], sys.argv[2]
with open(manifest_path, "rb") as fh:
    data = tomllib.load(fh)
package = data.get("package", {})
if not isinstance(package.get("include"), list) or not package["include"]:
    sys.stderr.write(f"FAIL [R26 element 4]: {pkg} must declare non-empty [package] include\n")
    sys.exit(1)
if "exclude" in package:
    sys.stderr.write(f"FAIL [R26 element 4]: {pkg} must not declare [package] exclude alongside include\n")
    sys.exit(1)
PY

  # Guard 1 (F039): byte-order packed file-set comparison.
  list_args=(package -p "$pkg" --list --no-verify --offline --locked)
  if [ "$allow_dirty" -eq 1 ]; then
    list_args+=(--allow-dirty)
  fi
  actual_list="${workdir}/${pkg}.files.txt"
  cargo "${list_args[@]}" >"$actual_list"
  if ! LC_ALL=C diff -u "$expected_files" "$actual_list"; then
    echo "FAIL [R26 F039]: packed file set for ${pkg} drifted from ${expected_files}" >&2
    exit 1
  fi
done

# Guard 2 (F078): remove any prior `.crate` archives so a failed pack can never leave a stale
# archive behind (R26 row 10), then pack all publishable workspace crates together so Cargo
# resolves sibling workspace path+version dependencies locally even before first crates.io release.
for pkg in "${publishable_workspace_packages[@]}"; do
  pkg_version=$(jq -r --arg pkg "$pkg" '.packages[] | select(.name == $pkg) | .version' <<<"$meta_json")
  if [ -n "$pkg_version" ]; then
    rm -f "${target_dir}/package/${pkg}-${pkg_version}.crate"
  fi
done

pack_args=(package --locked)
for pkg in "${publishable_workspace_packages[@]}"; do
  pack_args+=(-p "$pkg")
done
if [ "$allow_dirty" -eq 1 ]; then
  pack_args+=(--allow-dirty)
fi
if [ "$no_verify" -eq 1 ]; then
  pack_args+=(--no-verify)
fi
if [ "$offline" -eq 1 ]; then
  pack_args+=(--offline)
fi

stderr_log="${workdir}/workspace-package.stderr.log"
if ! cargo "${pack_args[@]}" 2>"$stderr_log"; then
  cat "$stderr_log" >&2
  echo "FAIL [R26]: cargo package failed; aborting before archive inspection" >&2
  exit 1
fi

# Guard 2(a): scoped stderr grep for silent target pruning or include+exclude warning.
# Deliberately ignores `ignoring test ...` because integration tests are outside [package] include.
# shellcheck disable=SC2016
if grep -Eq 'ignoring (library|binary) .* is not included in the published package|ignoring `package\.build`|both package\.include and package\.exclude are specified; the exclude list will be ignored' "$stderr_log"; then
  cat "$stderr_log" >&2
  echo "FAIL [R26 F078]: cargo package emitted a target-pruning or include/exclude warning" >&2
  exit 1
fi

for pkg in "${packages[@]}"; do
  expected_targets="ci/expected-packaged-targets/${pkg}.json"
  manifest_path=$(jq -r --arg pkg "$pkg" '.packages[] | select(.name == $pkg) | .manifest_path' <<<"$meta_json")
  pkg_version=$(jq -r --arg pkg "$pkg" '.packages[] | select(.name == $pkg) | .version' <<<"$meta_json")
  archive="${target_dir}/package/${pkg}-${pkg_version}.crate"

  if [ ! -f "$archive" ]; then
    echo "FAIL [R26]: expected packed archive not found at ${archive}" >&2
    exit 1
  fi

  extract_dir="${workdir}/extract-${pkg}"
  mkdir -p "$extract_dir"
  tar -xzf "$archive" -C "$extract_dir"
  extracted_root="${extract_dir}/${pkg}-${pkg_version}"
  extracted_manifest="${extracted_root}/Cargo.toml"
  extracted_orig="${extracted_root}/Cargo.toml.orig"

  if [ ! -f "$extracted_manifest" ] || [ ! -f "$extracted_orig" ]; then
    echo "FAIL [R26]: extracted archive for ${pkg} missing Cargo.toml or Cargo.toml.orig" >&2
    exit 1
  fi

  extracted_meta=$(cargo metadata --no-deps --format-version 1 --offline --manifest-path "$extracted_manifest")

  # Guard 2(b): authoritative target-set diff against checked-in expectation.
  expected_targets_norm="${workdir}/${pkg}.expected-targets.json"
  actual_targets_norm="${workdir}/${pkg}.actual-targets.json"
  jq -S 'sort_by(.name, .kind)' "$expected_targets" >"$expected_targets_norm"
  jq -S '[.packages[0].targets[] | {name, kind}] | sort_by(.name, .kind)' <<<"$extracted_meta" >"$actual_targets_norm"
  if ! diff -u "$expected_targets_norm" "$actual_targets_norm"; then
    echo "FAIL [R26 F078]: packaged targets for ${pkg} drifted from ${expected_targets}" >&2
    exit 1
  fi

  # Guard 2(c): source Cargo.toml survives unmodified as Cargo.toml.orig.
  if ! cmp -s "$manifest_path" "$extracted_orig"; then
    echo "FAIL [R26 F078]: ${pkg} source Cargo.toml differs from archived Cargo.toml.orig" >&2
    exit 1
  fi

  # Guard 2(d): publish-facing metadata semantic projection matches between source and archive.
  source_proj="${workdir}/${pkg}.source-meta.json"
  archive_proj="${workdir}/${pkg}.archive-meta.json"
  jq -S --arg pkg "$pkg" ".packages[] | select(.name == \$pkg) | ${projection_filter}" <<<"$meta_json" >"$source_proj"
  jq -S ".packages[0] | ${projection_filter}" <<<"$extracted_meta" >"$archive_proj"
  if ! diff -u "$source_proj" "$archive_proj"; then
    echo "FAIL [R26 F078]: publish-facing metadata projection for ${pkg} drifted in packed archive" >&2
    exit 1
  fi

  echo "PASS [R26]: ${pkg} ${pkg_version} packed files, targets, Cargo.toml.orig, and metadata verified"
done
