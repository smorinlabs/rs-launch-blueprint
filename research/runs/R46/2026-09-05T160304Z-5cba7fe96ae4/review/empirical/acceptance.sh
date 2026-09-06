# Execute with Bash from the implementation repository root.
set -euo pipefail

test -s LICENSE-MIT
test -s LICENSE-APACHE
grep -Fx 'license = "MIT OR Apache-2.0"' Cargo.toml
cargo metadata --no-deps --format-version 1 >/dev/null

# Consume NUL-delimited source paths on stdin. Do not invert this contract.
#
# The detector is exactly the five-form migration policy above: it is
# case-sensitive and scans anywhere in the first 40 lines. It emits the first
# matching form per line; any match rejects the input. It does not reject other
# license prose.
r46_check_headers() {
  if ! xargs -0 awk '
      function check_file( i, j, line) {
        for (i = 1; i <= line_count; i++) {
          line = lines[i]
          if (line ~ /SPDX-License-Identifier:/) {
            print current_file ":" i ":(a) SPDX-License-Identifier:"
            found = 1
          } else if (line ~ /Permission is hereby granted, free of charge/) {
            print current_file ":" i ":(b) MIT boilerplate first line"
            found = 1
          } else if (line ~ /Licensed under the Apache License, Version 2\.0/) {
            print current_file ":" i ":(c) Apache appendix boilerplate line"
            found = 1
          } else if (line ~ /Apache License/) {
            for (j = i + 1; j <= i + 3 && j <= line_count; j++) {
              if (lines[j] ~ /Version 2\.0, January 2004/) {
                print current_file ":" i ":(d) Apache full-text title form"
                found = 1
                break
              }
            }
          } else if (line ~ /MIT License/) {
            for (j = i + 1; j <= i + 2 && j <= line_count; j++) {
              if (lines[j] ~ /Copyright \(c\)/) {
                print current_file ":" i ":(e) MIT title form"
                found = 1
                break
              }
            }
          }
        }
      }
      FILENAME != current_file {
        if (current_file != "") {
          check_file()
          for (i = 1; i <= line_count; i++) delete lines[i]
        }
        current_file = FILENAME
        line_count = 0
      }
      FNR <= 40 {
        lines[FNR] = $0
        line_count = FNR
      }
      END {
        if (current_file != "") check_file()
        exit found ? 1 : 0
      }
    '; then
    echo 'unexpected prohibited per-file license form or header-check failure' >&2
    return 1
  fi
  return 0
}

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
