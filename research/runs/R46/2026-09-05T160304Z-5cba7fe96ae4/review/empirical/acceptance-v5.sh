# R46 acceptance sequence, revision 5. Execute with Bash from the implementation repository root.
# Prerequisites, metadata assertion and cargo steps are unchanged from acceptance-v4.sh. What changed
# (audit-fable r4, F1): the header check no longer scans a fixed list of directories
# (`src tests examples benches crates`); it scans the set of REPOSITORY-OWNED `.rs` FILES, defined as
#   every regular file named `*.rs` under the Cargo workspace root (`cargo metadata --no-deps`
#   `.workspace_root`) or under the directory of any workspace package manifest that lies outside that
#   root (`.packages[].manifest_path`), symbolic links followed, excluding the Cargo target directory
#   (`.target_directory`, matched by file identity with `find -samefile`, so path spelling and symlinks
#   do not matter) and any directory named `.git`.
# The set follows the workspace: a root `build.rs`, a member outside `crates/`, a member outside the
# workspace root and a symlinked `.rs` file are all scanned; generated sources under the target directory
# are not; a dangling symlink is not a regular file and is skipped (cargo package then refuses to archive it). Requires jq and a `find` with `-L` and `-samefile` (GNU findutils and BSD find both have them).
#   - `test -s LICENSE-MIT` / `test -s LICENSE-APACHE`: the two root license files EXIST and are NON-EMPTY
#     (raw/codex.md lines 417-418). Their content is ledger row F206 (COMMON -> REUSE; Task 18), out of
#     R46's scope by the prompt; a non-empty wrong root text passes this sequence by design.
#   - the metadata assertion: every `cargo metadata --no-deps` package (workspace members only) resolves
#     license = "MIT OR Apache-2.0" (audit-codex r2, F1). A package under the root that is not a workspace
#     member is outside this assertion (its `.rs` files are still scanned).
#   - the header check is the two-layer r46_check_headers from checker-v5.sh (sourced from this script's
#     directory; function byte-identical to checker-v2.sh).
set -euo pipefail

test -s LICENSE-MIT
test -s LICENSE-APACHE
grep -Fx 'license = "MIT OR Apache-2.0"' Cargo.toml

# Every workspace package must resolve the fixed expression, whether inherited through
# `license.workspace = true` or declared directly. `.license` is null for a package that
# sets only `license-file`, so that case is divergent too. Zero packages is a failure.
r46_metadata=$(cargo metadata --no-deps --format-version 1)
r46_package_count=$(jq -r '.packages | length' <<<"$r46_metadata")
r46_divergent=$(jq -r '.packages[] | select(.license != "MIT OR Apache-2.0")
  | "\(.name) \(.manifest_path) license=\(.license)"' <<<"$r46_metadata")
if (( r46_package_count == 0 )) || [[ -n "$r46_divergent" ]]; then
  if [[ -n "$r46_divergent" ]]; then printf '%s\n' "$r46_divergent" >&2; fi
  echo "workspace package license is not \"MIT OR Apache-2.0\" (packages: $r46_package_count)" >&2
  exit 1
fi
jq -r '.packages[] | "package \(.name) license=\(.license)"' <<<"$r46_metadata"

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checker-v5.sh"

# The scan roots: the workspace root, plus the manifest directory of every workspace package that lies
# outside it (members inside the root are reached by the root walk). Cargo reports canonical paths.
r46_root=$(jq -r '.workspace_root' <<<"$r46_metadata")
r46_target=$(jq -r '.target_directory' <<<"$r46_metadata")
r46_scan_dirs=("$r46_root")
while IFS= read -r r46_manifest; do
  r46_dir=$(cd "$(dirname "$r46_manifest")" && pwd -P)
  case "$r46_dir/" in "$r46_root/"*) continue ;; esac
  r46_scan_dirs+=("$r46_dir")
done < <(jq -r '.packages[].manifest_path' <<<"$r46_metadata")
r46_prune=( -name .git )
if [[ -d "$r46_target" ]]; then r46_prune+=( -o -samefile "$r46_target" ); fi
r46_list_rs() {
  find -L "${r46_scan_dirs[@]}" \( -type d \( "${r46_prune[@]}" \) -prune \) -o -type f -name '*.rs' -print0 | sort -z -u
}
r46_rs_count=$(r46_list_rs | tr -cd '\000' | wc -c | tr -d ' ')
if (( r46_rs_count == 0 )); then
  echo "no repository-owned .rs files found under ${r46_scan_dirs[*]}" >&2
  exit 1
fi
echo "header check: $r46_rs_count repository-owned .rs file(s) under ${r46_scan_dirs[*]}"
r46_list_rs | r46_check_headers

cargo fmt --all -- --check
cargo test --workspace --all-targets
cargo package --workspace --allow-dirty --no-verify
