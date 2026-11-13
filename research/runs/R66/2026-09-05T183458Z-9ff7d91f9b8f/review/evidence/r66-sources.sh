#!/usr/bin/env bash
# R66 — output-format-surface. Deterministic, offline source check.
#
# Proves the source-level claims this decision rests on by reading the two
# pinned source repositories through the programme pins and the org CLI Design
# Standard at its pinned blob. No network. Every check asserts on CONTENT.
#
# Reproducibility: this script reads only (a) itself and files committed in this
# repository, located relative to this script's own path (never `git rev-parse`,
# which fails inside a `git archive` extraction), and (b) three external
# repositories the programme charter already requires:
#     $HOME/c/py-launch-blueprint   at b08bccfb55d05f15e46a83b52c5660b1881d19f5
#     $HOME/c/ts-launch-blueprint   at cb1cbcb2e88b898e8c081b0abbfabc1630079c00
#     $HOME/c/cli-standards         blob f9de0437baece3383e73ca2c5f48b7ab399b51c7
# Those three are pinned by commit/blob, so their content cannot drift without
# the pin assertions (C0a-C0d) failing first.
#
# Usage: bash r66-sources.sh
# Exit 0 = every check passed. Exit 1 = at least one failed.

set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../../../../../.." && pwd)

PY_REPO="$HOME/c/py-launch-blueprint"
TS_REPO="$HOME/c/ts-launch-blueprint"
STD="$HOME/c/cli-standards/cli-design-standard.md"

PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
STD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7

RUN=999
FAIL=0

pass() { RUN=$((RUN + 1)); printf 'PASS %-6s %s\n' "$1" "$2"; }
fail() { RUN=$((RUN + 1)); FAIL=$((FAIL + 1)); printf 'FAIL %-6s %s\n' "$1" "$2"; }
RUN=0

# assert_eq <id> <expected> <actual> <label>
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1" "$4 == $2"; else fail "$1" "$4: expected [$2] got [$3]"; fi
}

# assert_contains <id> <file> <fixed-string> <label>
assert_contains() {
  local n
  n=$(/usr/bin/grep -c -F -- "$3" "$2")
  if [ "${n:-0}" -ge 1 ]; then
    pass "$1" "$4 (/usr/bin/grep -c -F matches=$n)"
  else
    fail "$1" "$4: fixed string not found in $2 -> [$3]"
  fi
}

# assert_absent <id> <file> <fixed-string> <label>
assert_absent() {
  local n
  n=$(/usr/bin/grep -c -F -- "$3" "$2" || true)
  if [ "${n:-0}" -eq 0 ]; then
    pass "$1" "$4 (/usr/bin/grep -c -F matches=0)"
  else
    fail "$1" "$4: fixed string unexpectedly present ($n) in $2 -> [$3]"
  fi
}

WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT

# show <repo> <rev> <path> <outfile> ; separate status test, never a pipeline
show() {
  if git -C "$1" show "$2:$3" >"$4" 2>"$WORK/err"; then return 0; fi
  return 1
}

echo "=== R66 source check — deterministic, offline ==="
echo "host:      $(uname -srm)"
echo "bash:      ${BASH_VERSION}"
echo "git:       $(git --version)"
echo "grep:      /usr/bin/grep -> $(/usr/bin/grep --version 2>&1 | head -1)"
echo "ROOT:      $ROOT"
echo

# ---------------------------------------------------------------- C0: the pins
echo "--- C0 pins ---"
if [ -f "$ROOT/AGENTS.md" ]; then pass C0 "ROOT sentinel AGENTS.md present"; else fail C0 "ROOT sentinel AGENTS.md missing at $ROOT"; fi
assert_eq C0a "$PY_PIN" "$(git -C "$PY_REPO" rev-parse "$PY_PIN^{commit}" 2>/dev/null)" "py pin resolves"
assert_eq C0b "$TS_PIN" "$(git -C "$TS_REPO" rev-parse "$TS_PIN^{commit}" 2>/dev/null)" "ts pin resolves"
assert_eq C0c "$STD_BLOB" "$(git hash-object "$STD" 2>/dev/null)" "CLI Design Standard blob"
assert_eq C0d "| **Version** | 1.4.14 |" "$(sed -n '7p' "$STD")" "standard version line :7"
# The two py ancestors this decision cites must really be ancestors of the pin.
if git -C "$PY_REPO" merge-base --is-ancestor f587e48 "$PY_PIN"; then pass C0e "f587e48 is an ancestor of the py pin"; else fail C0e "f587e48 is NOT an ancestor of the py pin"; fi
if git -C "$PY_REPO" merge-base --is-ancestor fda272d "$PY_PIN"; then pass C0f "fda272d is an ancestor of the py pin"; else fail C0f "fda272d is NOT an ancestor of the py pin"; fi
# Negative control: a commit that is NOT an ancestor must be reported as such,
# so C0e/C0f cannot be passing because --is-ancestor always succeeds here.
if git -C "$PY_REPO" merge-base --is-ancestor "$TS_PIN" "$PY_PIN" 2>/dev/null; then
  fail C0g "negative control: the ts pin was reported as an ancestor of the py pin"
else
  pass C0g "negative control: a foreign commit is correctly not an ancestor"
fi
echo

# ------------------------------------------------- C1: py at the pin (F291/F293)
echo "--- C1 py-launch-blueprint at $PY_PIN ---"
if show "$PY_REPO" "$PY_PIN" src/py_launch_blueprint/cli/output.py "$WORK/py-output.py"; then
  pass C1 "git show py:cli/output.py exit 0 ($(wc -l <"$WORK/py-output.py" | tr -d ' ') lines)"
else
  fail C1 "git show py:cli/output.py failed"
fi
assert_eq C1a "class OutputMode(StrEnum):" "$(sed -n '47p' "$WORK/py-output.py")" "py output.py:47"
assert_contains C1b "$WORK/py-output.py" '    TEXT = "text"' "py OutputMode member TEXT"
assert_contains C1c "$WORK/py-output.py" '    JSON = "json"' "py OutputMode member JSON"
assert_contains C1d "$WORK/py-output.py" '    MARKDOWN = "markdown"' "py OutputMode member MARKDOWN"
assert_absent  C1e "$WORK/py-output.py" 'CSV = "csv"' "py OutputMode has no CSV member"
# py's destination write is a plain truncate-then-write: non-atomic.
assert_contains C1f "$WORK/py-output.py" 'with self.output_file.open("w", encoding="utf-8") as handle:' "py --output-file truncate-then-write (non-atomic)"
assert_contains C1g "$WORK/py-output.py" 'R4: --output-file changes the destination, never the format.' "py records format/destination orthogonality"
# The two renderers read DIFFERENT row accessors: markdown reads the plain
# rows, the human table reads the markup-carrying rows. This is the asymmetry
# this decision carries into Rust, and the reason markdown is a presentation
# format rather than a wire format.
assert_contains C1h "$WORK/py-output.py" '        for row in result.table_rows_rich():' "py text renderer consumes table_rows_rich()"
assert_contains C1i "$WORK/py-output.py" '        for row in result.table_rows():' "py markdown renderer consumes the plain table_rows()"
# py already escapes the GFM cell separator; the two Rust reference renderers
# checked in r66-figures.sh (tabled, hyperfine) do not.
assert_contains C1j "$WORK/py-output.py" '            cells = [cell.replace("|", "\\|") for cell in row]' "py markdown renderer escapes a literal pipe"

if show "$PY_REPO" "$PY_PIN" src/py_launch_blueprint/cli/options.py "$WORK/py-options.py"; then
  pass C2 "git show py:cli/options.py exit 0 ($(wc -l <"$WORK/py-options.py" | tr -d ' ') lines)"
else
  fail C2 "git show py:cli/options.py failed"
fi
assert_eq C2a '        "-o",'        "$(sed -n '57p' "$WORK/py-options.py")" "py options.py:57 short format flag"
assert_eq C2b '        "--output",'  "$(sed -n '58p' "$WORK/py-options.py")" "py options.py:58 long format flag"
assert_eq C2c '        "--json",'    "$(sed -n '66p' "$WORK/py-options.py")" "py options.py:66 --json"
assert_eq C2d '        "--output-file",' "$(sed -n '72p' "$WORK/py-options.py")" "py options.py:72 --output-file"
assert_contains C2e "$WORK/py-options.py" 'help="Shorthand for --output json.",' "py --json documented as shorthand for --output json"
assert_contains C2f "$WORK/py-options.py" 'help="Write results to a file instead of stdout (format set by --output).",' "py --output-file is the destination only"
# py resolves the alias by silent precedence, not by a usage error.
assert_contains C2g "$WORK/py-options.py" 'mode = OutputMode.JSON if json_mode else OutputMode(output_mode or "text")' "py resolves --json by silent precedence"
assert_absent  C2h "$WORK/py-options.py" '"--format"' "py has no --format flag at the pin"

if show "$PY_REPO" "$PY_PIN" docs/design/0001-plbp-cli-conventions.md "$WORK/py-design0001.md"; then
  pass C3 "git show py:docs/design/0001 exit 0"
else
  fail C3 "git show py:docs/design/0001 failed"
fi
assert_contains C3a "$WORK/py-design0001.md" '2. Rename the format flag usage so `--output`/`-o` is the format and' "py design 0001 Appendix D item 2, first line"
assert_contains C3b "$WORK/py-design0001.md" '   and `--output` for a file path — resolve before it spreads across tools).' "py design 0001 states the reason for the rename"

if show "$PY_REPO" "$PY_PIN" docs/adr/0003-keep-markdown-output-mode.md "$WORK/py-adr0003.md"; then
  pass C4 "git show py:docs/adr/0003 exit 0"
else
  fail C4 "git show py:docs/adr/0003 failed"
fi
assert_contains C4a "$WORK/py-adr0003.md" '- **Status:** Accepted' "ADR 0003 accepted"
assert_contains C4b "$WORK/py-adr0003.md" '- **Date:** 2026-06-09' "ADR 0003 dated 2026-06-09"
assert_contains C4c "$WORK/py-adr0003.md" 'as a GitHub-flavored table — useful for pasting into issues/PRs and cheap to' "ADR 0003 states the markdown use case"
assert_contains C4d "$WORK/py-adr0003.md" 'table-shape contract (columns/rows), which is what makes the third format' "ADR 0003 states the shared-contract cost argument"
assert_contains C4e "$WORK/py-adr0003.md" '- **Strict spec compliance (drop markdown)** — rejected' "ADR 0003 records the rejected alternative"
echo

# ------------------------------------------ C5: the legacy py CLI (pre-rewrite)
echo "--- C5 legacy py CLI at ancestor f587e48^ ---"
if show "$PY_REPO" "f587e48^" src/py_launch_blueprint/projects.py "$WORK/py-legacy.py"; then
  pass C5 "git show py f587e48^:projects.py exit 0 ($(wc -l <"$WORK/py-legacy.py" | tr -d ' ') lines)"
else
  fail C5 "git show py f587e48^:projects.py failed"
fi
assert_eq C5a '    "--format",' "$(sed -n '324p' "$WORK/py-legacy.py")" "legacy py :324 --format"
assert_eq C5b '    type=click.Choice(["text", "json", "csv"]),' "$(sed -n '325p' "$WORK/py-legacy.py")" "legacy py :325 text|json|csv"
assert_eq C5c '@click.option("--output", type=click.Path(), help="Write results to file")' "$(sed -n '330p' "$WORK/py-legacy.py")" "legacy py :330 --output is the file sink"
assert_absent C5d "$WORK/py-legacy.py" '"--output-file"' "legacy py has no --output-file"
assert_absent C5e "$WORK/py-legacy.py" '"markdown"' "legacy py has no markdown format"
echo

# ------------------------------------------------- C6: ts at the pin (F291/F293)
echo "--- C6 ts-launch-blueprint at $TS_PIN ---"
if show "$TS_REPO" "$TS_PIN" src/lib/format.ts "$WORK/ts-format.ts"; then
  pass C6 "git show ts:src/lib/format.ts exit 0 ($(wc -l <"$WORK/ts-format.ts" | tr -d ' ') lines)"
else
  fail C6 "git show ts:src/lib/format.ts failed"
fi
assert_eq C6a '// Pure output formatter — port of format_output (projects.py:273-291).' "$(sed -n '1p' "$WORK/ts-format.ts")" "ts format.ts:1 names its source"
assert_eq C6b "//   text -> newline-joined project IDs (not names — shell composability)" "$(sed -n '8p' "$WORK/ts-format.ts")" "ts format.ts:8 text is bare IDs"
assert_eq C6c "export const OUTPUT_FORMATS = ['text', 'json', 'csv'] as const;" "$(sed -n '16p' "$WORK/ts-format.ts")" "ts format.ts:16 enum"
assert_eq C6d "  return projects.map((project) => project.id).join('\\n');" "$(sed -n '39p' "$WORK/ts-format.ts")" "ts format.ts:39 text renderer"
assert_absent C6e "$WORK/ts-format.ts" 'markdown' "ts has no markdown format"

if show "$TS_REPO" "$TS_PIN" src/commands/projects.ts "$WORK/ts-projects.ts"; then
  pass C7 "git show ts:src/commands/projects.ts exit 0 ($(wc -l <"$WORK/ts-projects.ts" | tr -d ' ') lines)"
else
  fail C7 "git show ts:src/commands/projects.ts failed"
fi
assert_contains C7a "$WORK/ts-projects.ts" "new Option('--format <format>', 'output format').choices(OUTPUT_FORMATS).default('text')" "ts --format selects the format"
assert_contains C7b "$WORK/ts-projects.ts" ".addOption(new Option('--json', 'output json (alias for --format json)').conflicts('format'))" "ts --json conflicts with --format"
assert_contains C7c "$WORK/ts-projects.ts" ".option('--output <file>', 'write results to file')" "ts --output is the file sink"
assert_contains C7d "$WORK/ts-projects.ts" "// sink for source parity, so the standard's -o/--output format enum" "ts records the divergence in a source comment"
# ts's destination write is non-atomic too.
assert_contains C7e "$WORK/ts-projects.ts" "writeFileSync(cmdOpts.output, result);" "ts destination write is writeFileSync (non-atomic)"

if show "$TS_REPO" "$TS_PIN" docs/port/TS_PORT_DECISIONS.md "$WORK/ts-decisions.md"; then
  pass C8 "git show ts:docs/port/TS_PORT_DECISIONS.md exit 0"
else
  fail C8 "git show ts:docs/port/TS_PORT_DECISIONS.md failed"
fi
assert_contains C8a "$WORK/ts-decisions.md" '## D-033: Interactive-prompt interrupt → exit 130; machine-mode error envelope (S3b gate adjudication)' "D-033 heading names prompt interrupt, not flag naming"
assert_contains C8b "$WORK/ts-decisions.md" "--output remains the file sink (source parity; documented divergence from cli-standards' -o output-format enum, noted in EXAMPLECLI)." "D-033 carries the flag-naming sentence inside its 'Why'"
# D-033's own Options list offers three prompt-cancellation options and no
# flag-naming option: the naming was never adjudicated against an alternative.
D033_OPTS=$(/usr/bin/grep -n -F '## D-033' "$WORK/ts-decisions.md" | cut -d: -f1)
if [ -n "$D033_OPTS" ]; then
  sed -n "${D033_OPTS},$((D033_OPTS + 4))p" "$WORK/ts-decisions.md" >"$WORK/d033-head.txt"
  assert_contains C8c "$WORK/d033-head.txt" '- Options: (1) catch @inquirer ExitPromptError and exit 130' "D-033 Options (1) is a prompt-cancellation option"
  assert_absent  C8d "$WORK/d033-head.txt" '--output-file' "D-033 Options list contains no flag-naming option"
  assert_absent  C8e "$WORK/d033-head.txt" '-o/--output' "D-033 Options list offers no -o/--output alternative"
else
  fail C8c "could not locate D-033 in TS_PORT_DECISIONS.md"
fi
echo

# --------------------------------------- C9: the org CLI Design Standard, pinned
echo "--- C9 CLI Design Standard v1.4.14 (blob $STD_BLOB) ---"
assert_contains C9a "$STD" 'A destination-file option, if a command has one, **MUST** be a distinct flag — **`--output-file`, long form only** (no short flag, to avoid an `-o`/`-O` case collision) — **MUST NOT** reuse `--output`/`-o` (which selects *format*, R4.1), and **MUST** honor `-` as stdout.' "R3.2 destination-file MUSTs (:194)"
assert_contains C9b "$STD" 'A destination-file option (`--output-file`) **SHOULD** write atomically (temp + rename) and **MAY** overwrite silently (Unix `>` convention); offer `--no-clobber` to refuse an existing file.' "R3.9 atomic write + --no-clobber (:226)"
assert_contains C9c "$STD" '| Result-output | `--output` | `-o` | Output format enum: `table` (default, human), `json`, `jsonl`, `yaml`, `wide`, `name`. |' "R4.1 result-output row (:246-ish)"
assert_contains C9d "$STD" 'For commands that emit formatted result data, `-o`/`--output` **MUST** be the canonical output-format selector, with an extensible enum' "R4.2 selector MUST + extensible enum (:256)"
assert_contains C9e "$STD" '`--json` **MUST** behave identically to `-o json`' "R4.2 --json alias MUST (:256)"
assert_contains C9f "$STD" '**`json`**, **`jsonl`** (JSON Lines / NDJSON: one complete JSON object per line), **`yaml`**, and **`name`** (bare identifiers, one per line) are *machine* formats and **MUST** stay stable within a major version (R7.2).' "R4.2 machine-format class, incl. name (:257)"
assert_contains C9g "$STD" 'The default (`-o table`) is for humans and **MAY** change between releases.' "R7.2 human-format class (:385)"
assert_contains C9h "$STD" 'TTY state **MUST NOT** change the selected output *format*' "R7.3 TTY MUST NOT change format (:391)"
assert_contains C9i "$STD" 'a tool **MUST** flush all streams before exiting on every path' "R7.7 flush MUST (:429)"
assert_contains C9j "$STD" 'Under any machine output format (`-o json`/`--json`, `-o jsonl`, `-o yaml`, or `-o name`), an ordinary command error **MUST** be emitted to stderr as a single JSON object' "R7.8 machine-readable error schema (:431)"
assert_contains C9k "$STD" '`--paginate` and `--no-paginate` are mutually exclusive; using both **MUST** fail with usage error `2`.' "R10.3 mutually-exclusive-pair precedent (:553)"
assert_contains C9l "$STD" '- **Color, theming, terminal styling, and detailed accessibility presentation rules** are governed by a separate standard and are deliberately omitted here.' "colour is out of this standard's scope (:32)"
assert_contains C9m "$STD" 'fd 1 (stdout) carries the command'"'"'s *requested result*; fd 2 (stderr) carries everything else' "R7.1 stream split (:381)"
# Negative control: the standard must NOT contain the ts/Doxa spelling as a rule.
assert_absent C9n "$STD" '`--format` **MUST** be the canonical output-format selector' "standard does not make --format the selector"
echo

# ---------------------------------------------------------------- C10: R60/R67
echo "--- C10 published couplings inside this repository ---"
R67="$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
R60="$ROOT/research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md"
if [ -f "$R67" ]; then pass C10 "R67 decision present"; else fail C10 "R67 decision missing at $R67"; fi
if [ -f "$R60" ]; then pass C10a "R60 decision present"; else fail C10a "R60 decision missing at $R60"; fi
assert_contains C10b "$R67" '(`output-format-surface`) renders `hint` as a distinct field or line and owns the' "R67 assigns the hint rendering and the locked-handle writer to R66"
assert_contains C10c "$R67" 'a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope' "R67 broken-pipe rule on the result stream"
assert_contains C10d "$R67" '`println!`/`print!` are lint-denied in binary crates' "R67 forbids the unlocked print macros"
assert_contains C10e "$R60" 'A format-selection flag that accepts the value `json`.' "R60 compatibility requirement 1"
assert_contains C10f "$R60" '**That flag being declarable on the root command**, so' "R60 compatibility requirement 2"
assert_contains C10g "$R60" '**The spelling**, which is the only part R60 cannot supply.' "R60 compatibility requirement 3"
assert_contains C10h "$R60" 'R66 owns no registry parameter' "R60 records that R66 owns no registry parameter"
# The registry must carry no output-format row: R66 registers nothing.
PARAMS="$ROOT/docs/port/PARAMETERS.md"
assert_absent C10i "$PARAMS" '| output-format' "PARAMETERS.md carries no output-format row"
assert_contains C10j "$PARAMS" '| rust-edition | fixed | owner | 2024 |' "PARAMETERS.md rust-edition row (assumes line source)"
echo

# ----------------------------------------------------- C11: this item's prompt
echo "--- C11 R66 binding prompt ---"
PROMPT="$SCRIPT_DIR/../../inputs/prompt.md"
if [ -f "$PROMPT" ]; then pass C11 "R66 prompt present"; else fail C11 "R66 prompt missing at $PROMPT"; fi
OWNS=$(/usr/bin/grep -c -E '^- owns:[[:space:]]*$' "$PROMPT" || true)
assert_eq C11a "1" "$OWNS" "prompt has exactly one empty '- owns:' line"
CONS=$(/usr/bin/grep -c -E '^- consumes:[[:space:]]*$' "$PROMPT" || true)
assert_eq C11b "1" "$CONS" "prompt has exactly one empty '- consumes:' line"
echo

echo "CHECKS RUN: $RUN   FAILURES: $FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
