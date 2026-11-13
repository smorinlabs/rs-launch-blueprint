# R46 acceptance sequence, revision 3. Execute with Bash from the implementation repository root.
# Same prerequisites, roots and cargo steps as raw/codex.md lines 414-498 and acceptance-v2.sh, with
# one change (audit-codex r2, F1): the bare `cargo metadata --no-deps ... >/dev/null` line becomes an
# assertion that EVERY workspace package resolves license = "MIT OR Apache-2.0"; any divergent package
# is named (name, manifest path, resolved value) on stderr and the sequence exits 1 before any header,
# fmt, test or package step. Requires jq (present on the ubuntu-latest and macos-latest images).
# The header check is the two-layer r46_check_headers from checker-v3.sh (sourced from this script's
# directory; byte-identical to checker-v2.sh).
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
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checker-v3.sh"

# Scope to repository-owned source roots in the generated layout.
# Optional directories need not exist; add any other workspace source roots.
r46_roots=()
for r46_dir in src tests examples benches crates; do
  if [[ -d "$r46_dir" ]]; then
    r46_roots+=("$r46_dir")
  fi
done
if (( ${#r46_roots[@]} > 0 )); then
  find "${r46_roots[@]}" -type f -name '*.rs' -print0 | r46_check_headers
fi

cargo fmt --all -- --check
cargo test --workspace --all-targets
cargo package --workspace --allow-dirty --no-verify
