#!/usr/bin/env bash
# Regression suite for scripts/check-research-tree.sh.
# Builds a valid fixture tree, asserts it passes, then applies one mutation per
# rule and asserts exit status 1 AND the expected FAIL message. Exit-status
# assertions exist because the v2 checker printed FAIL from a pipeline subshell
# and still exited 0.
# Usage: scripts/test-check-research-tree.sh
set -u
here="$(cd "$(dirname "$0")" && pwd)"
check="$here/check-research-tree.sh"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
pass=0; failed=0

prompt() {  # prompt ID COUPLING-LINES...
  local id="$1"; shift
  printf '## Objective\nx\n\n## Context\nx\n\n## Out of scope\nx\n\n## Couplings\n- id: %s\n' "$id"
  for l in "$@"; do printf '%s\n' "$l"; done
  printf '\n## Questions\nx\n\n## Required evidence\nx\n\n## Answer template\nx\n\n## Constraints\nx\n'
}

fixture() {  # fixture DIR — write a valid tree
  local d="$1"
  mkdir -p "$d/docs/port" "$d/research/topics/01-async-runtime/prompts" "$d/research/topics/02-web-framework/prompts" "$d/research/topics/03-old-thing/prompts"
  cat > "$d/research/CLAUDE.md" <<'EOF'
# Research index

| id | slug | kind | origin | verdict | owns | prompt | status |
|---|---|---|---|---|---|---|---|
| R01 | async-runtime | crate | same | COMMON → SUBSTITUTE | async-runtime | [prompt](topics/01-async-runtime/prompts/async-runtime.prompt.md) | resolved |
| R02 | web-framework | crate | none | RUST-ONLY | — | [prompt](topics/02-web-framework/prompts/web-framework.prompt.md) | open |
| R03 | old-thing | crate | different | DIVERGENT | — | [prompt](topics/03-old-thing/prompts/old-thing.prompt.md) | dropped |
EOF
  prompt R01 '- owns: async-runtime' '- consumes: owner: msrv-policy' > "$d/research/topics/01-async-runtime/prompts/async-runtime.prompt.md"
  prompt R02 '- consumes: R01: async-runtime; owner: target-os-matrix' > "$d/research/topics/02-web-framework/prompts/web-framework.prompt.md"
  prompt R03 > "$d/research/topics/03-old-thing/prompts/old-thing.prompt.md"
  printf '## Decision\nx\n\n## Parameters\n- owns async-runtime = tokio 1.x\n\n## Empirical check\ncargo build: ok\n' > "$d/research/topics/01-async-runtime/DECISION.md"
  echo ran > "$d/research/topics/01-async-runtime/audit-codex.md"
  echo read > "$d/research/topics/01-async-runtime/audit-fable.md"
  echo '# Runbook' > "$d/research/RUNBOOK.md"
  cat > "$d/docs/port/PARAMETERS.md" <<'EOF'
# Shared parameters

| param | kind | owner | value | description |
|---|---|---|---|---|
| msrv-policy | fixed | owner | stable minus 2 | minimum supported Rust version rule |
| rust-edition | fixed | owner | 2024 | Cargo edition |
| target-os-matrix | fixed | owner | ubuntu, macos, windows | CI runners |
| license | fixed | owner | MIT | repo license |
| async-runtime | researched | R01 | — | the one async runtime every crate uses |
EOF
  cat > "$d/docs/port/COMMONALITY.md" <<'EOF'
# Commonality ledger

| ID | Feature | Area | Origin | Verdict | Item | Notes |
|---|---|---|---|---|---|---|
| F001 | one async model across CLI, lib, web | workspace-architecture | same | COMMON → REUSE | — | rust-ok: yes; live: 2026-08 |
| F002 | async runtime crate | web-service | same | COMMON → SUBSTITUTE | R01 | parent: F001 |
| F003 | web framework | web-service | none | RUST-ONLY | R02 | |
| F004 | release commit style | release-versioning | same | COMMON → OVERRIDE (OV-01) | R01 | bundled into R01 |
| F005 | old thing | docs-system | different | OMIT | — | was R03, dropped 2026-09-01 |
| F006 | ts-only thing | docs-system | ts-only | ADOPT | — | language-neutral |

## Override arguments

### OV-01
**Argument:** Rust-specific reason stated here.
**Options:** keep; change; hybrid.
EOF
  cat > "$d/docs/port/OWNER-REVIEW.md" <<'EOF'
# Owner technology-selection review

| item | disposition | rationale | date |
|---|---|---|---|
| R01 | accept | fine | 2026-09-01 |
| R02 | narrow | only frameworks with tower middleware | 2026-09-01 |
| R03 | drop | not worth a prompt | 2026-09-01 |
EOF
}

run() { "$check" "$@" >"$work/out" 2>&1; echo $?; }

expect_ok() {  # expect_ok NAME [flags]
  local name="$1"; shift
  local rc; rc="$(run "$@" "$work/t")"
  if [ "$rc" = 0 ] && grep -q '^OK:' "$work/out"; then pass=$((pass+1)); printf 'ok   %s\n' "$name"
  else failed=$((failed+1)); printf 'FAIL %s (exit %s)\n' "$name" "$rc"; sed 's/^/     /' "$work/out"; fi
}
expect_fail() {  # expect_fail NAME PATTERN [flags]
  local name="$1" pat="$2"; shift 2
  local rc; rc="$(run "$@" "$work/t")"
  if [ "$rc" = 1 ] && grep -qF -- "$pat" "$work/out"; then pass=$((pass+1)); printf 'ok   %s\n' "$name"
  else failed=$((failed+1)); printf 'FAIL %s (exit %s, wanted 1 + %q)\n' "$name" "$rc" "$pat"; sed 's/^/     /' "$work/out"; fi
}
fresh() { rm -rf "$work/t"; fixture "$work/t"; }
# sub FILE OLD NEW — literal in-place replacement (first occurrence per line)
sub() { python3 - "$1" "$2" "$3" <<'PY'
import sys; p,o,n=sys.argv[1:]; s=open(p).read(); assert o in s, o; open(p,'w').write(s.replace(o,n))
PY
}
t="$work/t"
idx="$t/research/CLAUDE.md"; led="$t/docs/port/COMMONALITY.md"; reg="$t/docs/port/PARAMETERS.md"; rev="$t/docs/port/OWNER-REVIEW.md"
p1="$t/research/topics/01-async-runtime/prompts/async-runtime.prompt.md"
p2="$t/research/topics/02-web-framework/prompts/web-framework.prompt.md"

fresh; expect_ok "valid tree"
fresh; expect_ok "valid tree with owner review" --require-owner-review
fresh; printf '\n```\n## Not a section\n```\n' >> "$p2"; expect_ok "H2 inside a fence is ignored"

# index / prompts
fresh; mkdir -p "$t/research/topics/09-x/prompts"; prompt R09 > "$t/research/topics/09-x/prompts/x.prompt.md"; expect_fail "orphan prompt" "prompt not linked from index"
fresh; rm "$p2"; expect_fail "index links missing prompt" "links missing prompt"
fresh; sub "$idx" "| open |" "| done |"; expect_fail "bad status enum" "status 'done'"
fresh; sub "$idx" "| R02 | web-framework | crate" "| R02 | web-framework | lib"; expect_fail "bad kind enum" "kind 'lib'"
fresh; sub "$p2" "- id: R02" "- id: R05"; expect_fail "prompt id disagrees with index" "declares '- id: R05'"
fresh; sub "$idx" "| R02 | web-framework" "| R01 | web-framework"; expect_fail "duplicate index id" "duplicate id R01"
fresh; printf '# Research index\n\n| id | slug | kind | origin | verdict | owns | prompt | status |\n|---|---|---|---|---|---|---|---|\n' > "$idx"; expect_fail "header-only index" "index: no R## rows"
fresh; rm "$t/research/RUNBOOK.md"; expect_fail "missing runbook" "missing research/RUNBOOK.md"

# sections
fresh; sub "$p2" "## Out of scope" "## Scope"; expect_fail "missing section" "H2 sections are"
fresh; printf '\n## Extra\nx\n' >> "$p2"; expect_fail "extra H2 outside fence" "H2 sections are"
fresh; python3 - "$p2" <<'PY'
import sys; p=sys.argv[1]; s=open(p).read().replace("## Context\nx\n\n## Out of scope\nx\n","## Out of scope\nx\n\n## Context\nx\n"); open(p,'w').write(s)
PY
expect_fail "reordered sections" "H2 sections are"

# registry
fresh; sub "$reg" "| license | fixed | owner | MIT | repo license |" ""; expect_fail "required fixed param missing" "required fixed parameter 'license'"
fresh; sub "$reg" "| async-runtime | researched" "| CI OS matrix | researched"; expect_fail "non-slug parameter" "not a lowercase-kebab slug"
fresh; printf '| tls-backend | researched | R02 | — | tls |\n' >> "$reg"; expect_fail "researched param undeclared by owner" "not declared by '- owns:' in R02"
fresh; printf '| tls-backend | researched | R09 | — | tls |\n' >> "$reg"; expect_fail "researched param owner not in index" "owner R09 is not in the index"
fresh; sub "$reg" "| msrv-policy | fixed | owner | stable minus 2 |" "| msrv-policy | fixed | owner | — |"; expect_fail "fixed param without value" "has no value"
fresh; printf '| msrv-policy | fixed | owner | 1.85 | dup |\n' >> "$reg"; expect_fail "parameter registered twice" "registered twice"

# couplings — the v2 subshell bug lived here: both cases must change the exit status
fresh; sub "$p2" "- id: R02" "- id: R02
- owns: async-runtime"; expect_fail "duplicate owner (exit status)" "owned by more than one prompt: async-runtime"
fresh; sub "$p2" "R01: async-runtime" "R01: tls-backend"; expect_fail "consumes unowned pair (exit status)" "R01 does not own 'tls-backend'"
fresh; sub "$p1" "- owns: async-runtime" "- owns: async-runtime, tls-backend"; expect_fail "owns unregistered parameter" "owns unregistered parameter 'tls-backend'"
fresh; sub "$p1" "- owns: async-runtime" "- owns: async-runtime, msrv-policy"; expect_fail "owns a fixed parameter" "which is a fixed (owner-decided) parameter"
fresh; sub "$p2" "owner: target-os-matrix" "owner: async-runtime"; expect_fail "consumes researched param as fixed" "is not a fixed parameter"
fresh; sub "$p1" "- consumes: owner: msrv-policy" "- consumes: R01: async-runtime"; expect_fail "consumes own parameter" "consumes its own parameter"
fresh; sub "$p2" "- id: R02" "- id: R02
- owns: CI OS matrix"; expect_fail "owned parameter with spaces" "is not a lowercase-kebab slug"

# ledger
fresh; sub "$led" "| RUST-ONLY | R02 |" "| MAYBE | R02 |"; expect_fail "verdict outside closed set" "outside closed set: 'MAYBE'"
fresh; sub "$led" "| none | RUST-ONLY | R02 |" "| none | DIVERGENT | R02 |"; expect_fail "verdict illegal for origin" "not legal for origin 'none'"
fresh; sub "$led" "| RUST-ONLY | R02 |" "| RUST-ONLY | — |"; expect_fail "research verdict without item" "needs an R## item"
fresh; sub "$led" "| COMMON → REUSE | — |" "| COMMON → REUSE | R01 |"; expect_fail "non-research verdict with item" "takes no research item"
fresh; sub "$led" "| RUST-ONLY | R02 |" "| RUST-ONLY | R09 |"; expect_fail "item not in index" "item R09 is not in the index"
fresh; sub "$led" "| RUST-ONLY | R02 |" "| RUST-ONLY | R03 |"; expect_fail "item is dropped" "item R03 is dropped"
fresh; sub "$led" "| F003 | web framework | web-service | none | RUST-ONLY | R02 | |" ""; expect_fail "index item with no ledger row" "index R02: no COMMONALITY.md row"
fresh; sub "$led" "rust-ok: yes; live: 2026-08" "live: 2026-08"; expect_fail "REUSE without rust-ok" "lacks 'rust-ok: yes'"
fresh; sub "$led" "| R01 | parent: F001 |" "| R01 | |"; expect_fail "SUBSTITUTE without parent" "lacks 'parent: F###'"
fresh; sub "$led" "parent: F001" "parent: F099"; expect_fail "parent does not exist" "parent F099 does not exist"
fresh; sub "$led" "(OV-01) | R01 |" "(OV-02) | R01 |"; expect_fail "dangling OV id" "no '### OV-02' section"
fresh; sub "$led" "**Argument:** Rust-specific reason stated here." "**Argument:**"; expect_fail "empty Argument" "lacks a non-empty '**Argument:**'"
fresh; sub "$led" "**Options:** keep; change; hybrid." ""; expect_fail "missing Options" "lacks a non-empty '**Options:**'"
fresh; sub "$led" "| COMMON → SUBSTITUTE | R01 | parent: F001 |" "| COMMON → OVERRIDE (OV-01) | R01 | |"; expect_fail "OV id used twice" "OV-01 used by more than one row"
fresh; sub "$led" "| F006 |" "| F001 |"; expect_fail "duplicate ledger id" "duplicate ID F001"
fresh; sub "$led" "| web-service | none |" "| web | none |"; expect_fail "unknown area" "area 'web' is not one of the 13 areas"
fresh; sub "$led" "| ID | Feature | Area | Origin | Verdict | Item | Notes |" "| Feature | Area | Origin | Verdict | Item | Notes | Extra |"; expect_fail "ledger missing ID column" "table lacks column 'ID'"

# resolved items
fresh; rm "$t/research/topics/01-async-runtime/audit-codex.md"; expect_fail "resolved without audit-codex" "audit-codex.md is missing or empty"
fresh; : > "$t/research/topics/01-async-runtime/DECISION.md"; expect_fail "resolved with empty DECISION" "DECISION.md is missing or empty"
fresh; sub "$t/research/topics/01-async-runtime/DECISION.md" "## Empirical check" "## Checked"; expect_fail "DECISION without empirical section" "lacks '## Empirical check'"

# owner review
fresh; rm "$rev"; expect_fail "owner review file missing" "missing docs/port/OWNER-REVIEW.md" --require-owner-review
fresh; sub "$rev" "| R02 | narrow | only frameworks with tower middleware | 2026-09-01 |" ""; expect_fail "item without review row" "R02 has 0 rows" --require-owner-review
fresh; sub "$rev" "| R03 | drop |" "| R03 | accept |"; expect_fail "dropped item not dropped by owner" "index status is dropped but disposition is 'accept'" --require-owner-review
fresh; sub "$rev" "| R02 | narrow |" "| R02 | drop |"; expect_fail "drop without index status" "disposition drop but index status is 'open'" --require-owner-review
fresh; sub "$rev" "| fine |" "| |"; expect_fail "empty rationale" "empty rationale" --require-owner-review
fresh; sub "$rev" "| 2026-09-01 |" "| yesterday |"; expect_fail "bad review date" "is not YYYY-MM-DD" --require-owner-review

printf '\n%d passed, %d failed\n' "$pass" "$failed"
[ "$failed" -eq 0 ]
