#!/usr/bin/env bash
# R58 empirical check B - the binding rules quoted at their lines, the
# tracing-subscriber 0.3.23 source facts the design turns on, and the parameter
# lines compared byte-for-byte with the live registry.
#
# Nothing here is fetched: every source is a pinned git blob, a vendored crate
# source in the local Cargo registry, or a file in this repository. Sources that
# are absent on a given machine are reported as a NAMED skip, never silently.
# The quoted rule texts below contain backticks and $ signs because the
# standards' own prose does. They are literal single-quoted strings and must
# not be expanded, so SC2016 is disabled for the whole file deliberately.
# shellcheck disable=SC2016
set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }

# Repository root: walk up until docs/port/PARAMETERS.md is found. A worktree's
# .git is a FILE, not a directory, so -e is the correct test and is used below
# only to report which shape this checkout has.
ROOT="$HERE"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT="$(dirname "$ROOT")"
done

CLI_REPO=/Users/stevemorin/c/cli-standards
CLI_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
REST_REPO=/Users/stevemorin/c/rest-standards
REST_BLOB=71bd813c1cf61286586b4ee41ed83ff065e5c8d9
REG=/Users/stevemorin/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f
TS="$REG/tracing-subscriber-0.3.23"

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r58std.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "== environment =="
echo "repo root:      $ROOT"
if [ -e "$ROOT/.git" ]; then
  if [ -d "$ROOT/.git" ]; then echo "checkout shape: .git is a directory"
  else echo "checkout shape: .git is a file (git worktree)"; fi
else
  echo "checkout shape: no .git present (git archive extraction)"
fi
echo "$GREP version: $("$GREP" --version | head -1)"
echo

# quote_at <label> <file> <line> <fixed-string>
# Asserts that the named line of the named file contains the fixed string, and
# prints the line. An assertion on line NUMBER as well as content is what makes
# a re-quote at a moved line fail instead of passing quietly.
quote_at() {
  label="$1"; file="$2"; line="$3"; want="$4"
  got="$(sed -n "${line}p" "$file")"
  printf '      %s:%s | %s\n' "$(basename "$file")" "$line" "${got:0:150}"
  case "$got" in
    *"$want"*) ok "$label" ;;
    *) bad "$label (line $line of $(basename "$file") does not contain: $want)" ;;
  esac
}

echo "== the org CLI Design Standard v1.4.14, blob $CLI_BLOB =="
if [ ! -d "$CLI_REPO" ]; then
  skip "cli-standards clone absent at $CLI_REPO - eight CLI rule quotations skipped"
else
  if git -C "$CLI_REPO" cat-file -e "$CLI_BLOB" 2>/dev/null &&
     git -C "$CLI_REPO" show "$CLI_BLOB" > "$WORK/cli.md"; then
    ok "CLI standard blob $CLI_BLOB resolves and is readable"
    quote_at "R4.1 requires -v/--verbose in the required global core" \
      "$WORK/cli.md" 244 '| Required global core | `--verbose` | `-v` | Increase diagnostic detail (repeatable; see R4.4). |'
    quote_at "R4.1 requires -q/--quiet in the required global core" \
      "$WORK/cli.md" 245 '| Required global core | `--quiet` | `-q` | Suppress non-essential output. |'
    quote_at "R4.4 (MUST) is the one-ladder rule and admits --log-level" \
      "$WORK/cli.md" 266 'These three controls **MUST NOT** overlap ambiguously — define one ladder.'
    quote_at "R4.4 (MUST) --debug overrides --quiet" \
      "$WORK/cli.md" 266 'an explicit `--debug`, however, **MUST** override `--quiet`'
    quote_at "R5.4 (MUST) deterministic flag-to-environment mapping" \
      "$WORK/cli.md" 322 'Environment variables **MUST** use the uppercase `TOOL_*` prefix with a deterministic mapping'
    quote_at "R5.6 (MUST) secret masking reaches --debug/request logs" \
      "$WORK/cli.md" 332 'Secret values (tokens, passwords, keys) **MUST** be masked in all output'
    quote_at "R7.1 (MUST) stdout carries the result, stderr the diagnostics" \
      "$WORK/cli.md" 381 'fd 1 (stdout) carries the command'"'"'s *requested result*; fd 2 (stderr) carries everything else'
    quote_at "R7.3 (MUST) TTY state must not change the selected output FORMAT" \
      "$WORK/cli.md" 390 'TTY state **MUST NOT** change the selected output *format*'
    quote_at "R7.8 (MUST) the machine error object may carry request_id" \
      "$WORK/cli.md" 432 'the object **MAY** carry `details`, `request_id`, or other documented fields'
  else
    bad "CLI standard blob $CLI_BLOB does not resolve in $CLI_REPO"
  fi
fi

echo
echo "== the org REST API Design Standard v2.0.0, blob $REST_BLOB =="
if [ ! -d "$REST_REPO" ]; then
  skip "rest-standards clone absent at $REST_REPO - seven REST rule quotations skipped"
else
  if git -C "$REST_REPO" cat-file -e "$REST_BLOB" 2>/dev/null &&
     git -C "$REST_REPO" show "$REST_BLOB" > "$WORK/rest.md"; then
    ok "REST standard blob $REST_BLOB resolves and is readable"
    quote_at "R1.7 no silent deviation; a deviation is recorded or it is nonconformance" \
      "$WORK/rest.md" 271 '**R1.7 — No silent deviation.**'
    quote_at "1.10 reserves the response header name request-id" \
      "$WORK/rest.md" 348 '| `request-id` | Response | Correlation ID, emitted on every response including errors.'
    quote_at "R2.10 (MUST) PII never in a URI, because URIs land in access logs" \
      "$WORK/rest.md" 533 '**R2.10** Personally identifiable information MUST NOT appear in any URI'
    quote_at "R3.3 logging side effects do not violate method safety" \
      "$WORK/rest.md" 599 'logging and metrics side effects do not violate safety'
    quote_at "R8.2 (MUST) access tokens never in URI query parameters" \
      "$WORK/rest.md" 1323 '**R8.2** Access tokens MUST NOT be accepted or emitted in URI'
    quote_at "R8.12 (MUST) 8.5 Redaction binds RESPONSE CONTENT" \
      "$WORK/rest.md" 1422 '**R8.12** Secrets, credentials, and PII MUST NOT appear in problem'
    quote_at "R8.12 provenance names CLI-R5.6, the rule that reaches logs" \
      "$WORK/rest.md" 1427 'gap review item CLI-R5.6'
    quote_at "R11.7 (MUST) every response carries the request-id header" \
      "$WORK/rest.md" 1752 '**R11.7** Every response, including errors, MUST carry the `request-id`'
    quote_at "R11.8 (MUST) traceparent is propagated" \
      "$WORK/rest.md" 1759 '**R11.8** W3C Trace Context `traceparent` MUST be propagated'
  else
    bad "REST standard blob $REST_BLOB does not resolve in $REST_REPO"
  fi
fi

echo
echo "== tracing-subscriber 0.3.23 source, read in the local Cargo registry =="
if [ ! -d "$TS" ]; then
  skip "tracing-subscriber-0.3.23 not vendored at $TS - nine source assertions skipped"
else
  ok "tracing-subscriber-0.3.23 source present at $TS"
  quote_at "Format<Json> parses span fields as JSON and panics on failure" \
    "$TS/src/fmt/format/json.rs" 175 'match serde_json::from_str::<serde_json::Value>(data) {'
  quote_at "the panic message a non-JSON FormatFields triggers" \
    "$TS/src/fmt/format/json.rs" 200 "had malformed fields! this is a bug."
  quote_at "N: FormatFields is reduced to a PhantomData marker" \
    "$TS/src/fmt/format/json.rs" 253 'let format_field_marker: std::marker::PhantomData<N> = std::marker::PhantomData;'
  quote_at "flattened branch serialises EVENT fields through tracing_serde, not N" \
    "$TS/src/fmt/format/json.rs" 266 'let mut visitor = tracing_serde::SerdeMapVisitor::new(serializer);'
  quote_at "non-flattened branch also bypasses N, via event.field_map()" \
    "$TS/src/fmt/format/json.rs" 272 'serializer.serialize_entry("fields", &event.field_map())?;'
  quote_at "set_default ignores the log-bridge error (scoped path)" \
    "$TS/src/util.rs" 43 'let _ = tracing_log::LogTracer::init();'
  quote_at "try_init installs the global dispatcher first" \
    "$TS/src/util.rs" 62 'dispatcher::set_global_default(self.into()).map_err(TryInitError::new)?;'
  quote_at "try_init then installs the log bridge with the max-level hint" \
    "$TS/src/util.rs" 69 'tracing_log::LogTracer::builder()'
  quote_at "init() is try_init().expect(..), which is why template code calls try_init" \
    "$TS/src/util.rs" 94 '.expect("failed to set global default subscriber")'
  quote_at "RecordFields is a sealed trait" \
    "$TS/src/field/mod.rs" 88 'pub trait RecordFields: crate::sealed::Sealed<RecordFieldsMarker> {'
  quote_at "DefaultFields DOES implement MakeVisitor, so a thin wrapper works" \
    "$TS/src/fmt/format/mod.rs" 1228 "impl<'a> MakeVisitor<Writer<'a>> for DefaultFields {"
  quote_at "LocalTime's own doc: determining the offset may be unsound or fail" \
    "$TS/src/fmt/time/time_crate.rs" 53 'which may be unsound or fail'
  if "$GREP" -qF 'status = "experimental"' "$TS/Cargo.toml"; then
    ok "tracing-subscriber 0.3.23 declares [badges.maintenance] status = experimental"
  else
    bad "expected [badges.maintenance] status = experimental in $TS/Cargo.toml"
  fi
  if "$GREP" -qF 'json = [' "$TS/Cargo.toml" && "$GREP" -qF '"tracing-serde",' "$TS/Cargo.toml"; then
    ok "the json feature pulls tracing-serde, serde and serde_json"
  else
    bad "expected the json feature block naming tracing-serde in $TS/Cargo.toml"
  fi
  # JsonFields must NOT have a MakeVisitor impl - the crate's own doc comment at
  # json.rs:422 says it does, and the compiler says it does not. The absence is
  # asserted here; the compiler diagnostic is reproduced in the decision text.
  if "$GREP" -qE '^impl( <.*>)? *MakeVisitor.* for JsonFields' "$TS/src/fmt/format/json.rs"; then
    bad "JsonFields unexpectedly implements MakeVisitor - the design's premise has changed"
  else
    ok "JsonFields has NO MakeVisitor impl, so its visitor cannot be decorated"
  fi
fi

echo
echo "== parameter lines against the live registry =="
PARAMS="$ROOT/docs/port/PARAMETERS.md"
DEC="$HERE/../DECISION.md"
if [ ! -f "$PARAMS" ]; then
  skip "docs/port/PARAMETERS.md not found from $HERE - parameter comparison skipped"
elif [ ! -f "$DEC" ]; then
  skip "review/DECISION.md not written yet - parameter comparison skipped"
else
  python3 "$HERE/r58-param-lines.py" "$PARAMS" > "$WORK/expected.txt"
  "$GREP" '^- assumes ' "$DEC" > "$WORK/actual.txt" || true
  if diff -u "$WORK/expected.txt" "$WORK/actual.txt" > "$WORK/param.diff"; then
    ok "all five '- assumes' lines are byte-identical to docs/port/PARAMETERS.md"
  else
    bad "'- assumes' lines differ from the registry"
    cat "$WORK/param.diff"
  fi
  n_owns=$("$GREP" -c '^- owns ' "$DEC" || true)
  if [ "$n_owns" = "1" ]; then
    ok "exactly one '- owns' line is declared"
  else
    bad "expected exactly 1 '- owns' line, found $n_owns"
  fi
  if "$GREP" -q '^- owns logging-pipeline-contract = ' "$DEC"; then
    ok "the owned parameter is logging-pipeline-contract, as research/CLAUDE.md's R58 row says"
  else
    bad "the '- owns' line does not name logging-pipeline-contract"
  fi
  if "$GREP" -qE '^- owns logging-pipeline-contract = .*[`|]' "$DEC"; then
    bad "the '- owns' value contains a backtick or a pipe, which publication rejects"
  else
    ok "the '- owns' value carries no backtick and no pipe"
  fi
fi

echo
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"
[ "$FAIL" -eq 0 ] || exit 1
