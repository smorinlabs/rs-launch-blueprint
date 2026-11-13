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
