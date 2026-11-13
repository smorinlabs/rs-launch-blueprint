# R46 header check, revision 2 (synthesizer synth-fable-2026-09-05T160304Z-5cba7fe96ae4, 2026-09-05).
# Layer 1: the five canonical license-text forms anywhere in the first 40 lines —
#          `check_file` below is byte-identical to raw/codex.md lines 430-460 (the r4 report).
# Layer 2: `check_leading` (synthesizer-authored) — the leading plain-comment block of a file
#          (blank lines, `//` non-doc line comments, `/* */` non-doc block comments, after an
#          optional first-line `#!` shebang; ends at the first `//!`/`///` or `/*!`/`/**` doc
#          comment, attribute or code line) must contain no license, copyright or SPDX term:
#          case-insensitive `licen[cs]`, `copyright`, `spdx`, `(c)`, `©`, `ⓒ`, or a license name
#          `mit`, `apache`, `bsd`, `gpl`, `lgpl`, `agpl`, `mpl`, `isc`, `zlib` bounded by
#          non-alphanumerics (so `commit`, `template`, `misc`, `simple` do not match). Applied
#          within the same first 40 lines. Diagnostics: layer 1 first, then layer 2 as form (f).
# Contract: consumes NUL-delimited paths on stdin; exit 0 = no prohibited form; exit 1 = a
# prohibited form in any file, or any awk/xargs error (including an unreadable path).
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
      function term_hit(line,  low) {
        low = " " tolower(line) " "
        if (low ~ /licen[cs]|copyright|spdx|\(c\)|©|ⓒ/) return 1
        return low ~ /[^a-z0-9](mit|apache|bsd|gpl|lgpl|agpl|mpl|isc|zlib)[^a-z0-9]/
      }
      function flag_leading(i) {
        print current_file ":" i ":(f) license, copyright or SPDX term in the leading comment block"
        found = 1
      }
      function check_leading( i, start, line, in_block) {
        start = 1
        if (line_count >= 1 && lines[1] ~ /^#!/ && lines[1] !~ /^#!\[/) start = 2
        in_block = 0
        for (i = start; i <= line_count; i++) {
          line = lines[i]
          if (in_block) {
            if (term_hit(line)) flag_leading(i)
            if (line ~ /\*\//) in_block = 0
            continue
          }
          if (line ~ /^[ \t]*$/) continue
          if (line ~ /^[ \t]*\/\/[!\/]/ && line !~ /^[ \t]*\/\/\/\//) break
          if (line ~ /^[ \t]*\/\//) {
            if (term_hit(line)) flag_leading(i)
            continue
          }
          if (line ~ /^[ \t]*\/\*[!*]/ && line !~ /^[ \t]*\/\*\*\//) break
          if (line ~ /^[ \t]*\/\*/) {
            if (term_hit(line)) flag_leading(i)
            if (line !~ /\*\//) in_block = 1
            continue
          }
          break
        }
      }
      FILENAME != current_file {
        if (current_file != "") {
          check_file()
          check_leading()
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
        if (current_file != "") {
          check_file()
          check_leading()
        }
        exit found ? 1 : 0
      }
    '; then
    echo 'unexpected prohibited per-file license form or header-check failure' >&2
    return 1
  fi
  return 0
}
