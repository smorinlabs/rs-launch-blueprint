# R46 acceptance sequence, revision 4. Execute with Bash from the implementation repository root.
# Executable lines are identical to acceptance-v3.sh (proven by diff in run-checks-v4.sh S0); only the
# comments changed, to state exactly what each prerequisite enforces (audit-codex r3, F1):
#   - `test -s LICENSE-MIT` / `test -s LICENSE-APACHE` check that the two root license files EXIST and are
#     NON-EMPTY, as raw/codex.md lines 417-418 wrote them. They do not verify the files' content. The content
#     of the root texts is ledger row F206 (COMMON -> REUSE; produced by the Task 18 LICENSE update), which the
#     R46 prompt places out of scope; a non-empty but wrong root text therefore passes this sequence by design
#     (run-checks-v4.sh S4 executes that boundary), and no acceptance sequence in the tree verifies root-text
#     content today — R46 records that gap for F206/Task 18 in its decision.
#   - the metadata assertion requires every `cargo metadata --no-deps` package to resolve
#     license = "MIT OR Apache-2.0" (audit-codex r2, F1); requires jq.
#   - the header check is the two-layer r46_check_headers from checker-v4.sh (sourced from this script's
#     directory; function byte-identical to checker-v2.sh and checker-v3.sh).
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
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/checker-v4.sh"

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
