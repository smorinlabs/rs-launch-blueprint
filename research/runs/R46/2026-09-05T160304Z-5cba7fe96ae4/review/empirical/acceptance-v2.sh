# R46 acceptance sequence, revision 2. Execute with Bash from the implementation repository root.
# Same prerequisites, roots and cargo steps as raw/codex.md lines 414-498; the header check is
# the two-layer r46_check_headers from checker-v2.sh (sourced from this script's directory).
set -euo pipefail

test -s LICENSE-MIT
test -s LICENSE-APACHE
grep -Fx 'license = "MIT OR Apache-2.0"' Cargo.toml
cargo metadata --no-deps --format-version 1 >/dev/null

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checker-v2.sh"

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
