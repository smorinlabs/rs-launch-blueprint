#!/usr/bin/env bash
# R84 revision 4 — source claims, each read at a pinned artifact rather than
# carried from a raw report. Revision 4 changes: the A14 census is limited to
# DECISION.md files, so sibling items' evidence logs cannot break it (EF-2).
#   A  this repository: the prompt's couplings, the registry values the
#      decision assumes, the ledger row, R42/R49 (published) and R02/R05/R69
#      (accepted, unpublished) text the decision leans on, the OV-11 allocation
#   B  py-launch-blueprint at the programme pin b08bccfb (local clone)
#   C  the REST API Design Standard v2.0.0 at commit 0850d43e (local clone)
#   D  published crate sources at exact versions (static.crates.io):
#      progenitor-impl 0.15.0, cargo-progenitor 0.15.0, utoipa 5.5.0,
#      openapi-to-rust 0.17.0
#   E  OpenAPI Generator v7.25.0 sources (raw.githubusercontent.com at the tag)
# Every census uses /usr/bin/grep by absolute path and prints what it counted.
# Sections needing something absent (a sibling clone, the network) print SKIP
# by name. The log carries no timestamp or temporary path.

set -uo pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
check() { local label=$1; shift; if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; fi; }
# shellcheck disable=SC2329  # invoked through check "$@"
line_is() { # line_is <file> <n> <exact text>
  test "$(sed -n "$2p" "$1")" = "$3"
}
summary() { echo; echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"; exit "$FAIL"; }

HERE=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(cd "$HERE/../../../../../.." && pwd)
RUN=$(cd "$HERE/../.." && pwd)
UA='rs-launch-blueprint-research (R84 synthesis)'
PY=${R84_PY_REPO:-$HOME/c/py-launch-blueprint}
REST=${R84_REST_REPO:-$HOME/c/rest-standards}
WORK=$(mktemp -d "${TMPDIR:-/tmp}/r84-src.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "R84 source-claims check (revision 4)"
echo "grep: $($GREP --version | head -1)"
echo

# ------------------------------------------------------- A: this repository
PROMPT="$RUN/inputs/prompt.md"
check "A01 the prompt's couplings declare an empty owns line" $GREP -qx -- '- owns:' "$PROMPT"
check "A02 the prompt's couplings consume exactly R69: web-extra-surface" $GREP -qx -- '- consumes: R69: web-extra-surface' "$PROMPT"
check "A03 the prompt pins the three engines muse, opus, doxa" $GREP -qx -- '- engines: muse, opus, doxa' "$PROMPT"
if command -v python3 >/dev/null 2>&1; then
  CMP=$(cd "$ROOT" && python3 - "$RUN/inputs/parameters.json" <<'EOF'
import json, pathlib, sys
sys.path.insert(0, "scripts")
import research_validation as rv
errors = []
live = rv._parse_parameters(pathlib.Path("."), errors)
snap = json.load(open(sys.argv[1]))
for row in snap:
    value = live.get(row["param"], {}).get("value")
    print("%s %s %d" % (row["param"], "identical" if value == row["value"] else "DIFFERENT", len(row["value"].encode())))
EOF
)
  while IFS= read -r l; do echo "      $l"; done <<<"$CMP"
  check "A04 all 5 values in inputs/parameters.json are byte-identical to the live docs/port/PARAMETERS.md registry" \
    test "$($GREP -c ' identical ' <<<"$CMP")" = 5
else
  skip "A04 python3 absent, so the registry comparison could not run"
fi
C335=$($GREP '^| F335 |' "$ROOT/docs/port/COMMONALITY.md")
check "A05 ledger row F335 is 'py-only | DIVERGENT | R84'" $GREP -qF '| web-service | py-only | DIVERGENT | R84 |' <<<"$C335"
R42="$ROOT/research/topics/42-dev-toolchain-provisioning/DECISION.md"
# shellcheck disable=SC2016  # the backticks are literal Markdown, not expansions
check "A06 R42 (published) routes crates.io dev tools through one install-tool recipe: cargo binstall --locked --no-confirm <name>@<version>" \
  $GREP -qF 'whose body is `cargo binstall --locked --no-confirm <name>@<version>`' "$R42"
check "A07 R42's standing rule: prefer a crates.io-published tool; a release-only tool must justify itself" \
  $GREP -qF 'Standing rule for consuming items: prefer a crates.io-published tool; a release-only tool must justify itself.' "$R42"
check "A08 R49's live build-tool-output-shape value carries 'no build.rs and no build-orchestration crate'" \
  $GREP -qF 'no build.rs and no build-orchestration crate' "$ROOT/docs/port/PARAMETERS.md"
R02="$ROOT/research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md"
check "A09 R02 (accepted, unpublished) promotes a fifth member only on a second bounded context, production adapter or installable binary" \
  $GREP -qF 'a second bounded context, a second production adapter or a second installable binary appearing' "$R02"
R05="$ROOT/research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md"
check "A10 R05 (accepted, unpublished) criterion 1: the default build carries no async runtime (cargo tree -i tokio -e normal finds nothing)" \
  $GREP -qF '| 1 | The default build carries no async runtime |' "$R05"
OREF="$RUN/inputs/owner-reference-axum-companion-stack-2026-09-16.md"
check "A11 owner reference line 90 ends 'Run generation in CI and \`git diff --exit-code\` so drift fails the build.'" \
  bash -c "sed -n 90p '$OREF' | $GREP -qF 'Run generation in CI and \`git diff --exit-code\` so drift fails the build.'"
check "A12 owner reference line 426 gates CI on 'OpenAPI/TS-client drift'" \
  bash -c "sed -n 426p '$OREF' | $GREP -qF 'OpenAPI/TS-client drift'"
# The 2026-09-21 allocation line was uncommitted working-tree content when
# revision 1 was written, so a clean `git archive HEAD` extraction lacks it.
if $GREP -qF 'OV allocation: OV-10 to R72, OV-11 to R84' "$ROOT/docs/planning/p02/execution-ledger.md"; then
  ok "A13 the ledger allocates OV-11 to R84 (owner decision 2026-09-21, Q5.A/Q6.A entry)"
else
  skip "A13 this tree's execution-ledger.md lacks the 2026-09-21 'OV-11 to R84' allocation line (not yet committed at this tree's HEAD)"
fi
# The census covers decision files only: a sibling item's evidence log that merely
# mentions an override number is not a declaration (EF-2).
HOLDERS=$(cd "$ROOT" && $GREP -rl --include=DECISION.md 'OVERRIDE (OV-11)' research/topics research/runs 2>/dev/null | $GREP -v '^research/runs/R84/' | LC_ALL=C sort)
echo "      DECISION.md files outside research/runs/R84/ declaring OVERRIDE (OV-11): ${HOLDERS:-none}"
check "A14 no other decision declares OVERRIDE (OV-11) (census over DECISION.md files under research/topics and research/runs)" test -z "$HOLDERS"

# ------------------------------------------------ B: py-launch-blueprint pin
PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
if git -C "$PY" cat-file -e "$PIN^{commit}" 2>/dev/null; then
  git -C "$PY" show "$PIN:Justfile" > "$WORK/py-Justfile"
  check "B01 py Justfile:311 at the pin is '@client-python out=\"clients/python\":'" \
    line_is "$WORK/py-Justfile" 311 '@client-python out="clients/python":'
  check "B02 py Justfile:312 is 'uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite'" \
    line_is "$WORK/py-Justfile" 312 '    uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite'
  check "B03 the recipe sits in [group('build')] (Justfile:310)" line_is "$WORK/py-Justfile" 310 "[group('build')]"
  CL=$(git -C "$PY" ls-tree -r --name-only "$PIN" | $GREP -c '^clients/')
  check "B04 the pinned tree contains $CL paths under clients/ — the generated client is not committed" test "$CL" = 0
  check "B05 the pinned .gitignore mentions neither 'client' nor 'openapi' — the output is not ignored either" \
    bash -c "! git -C '$PY' show '$PIN:.gitignore' | $GREP -q -i -E 'client|openapi'"
  HITS=$(git -C "$PY" grep -n -E 'client-python|openapi-python-client' "$PIN" -- | sed "s/^$PIN://")
  while IFS= read -r l; do echo "      $l"; done <<<"$HITS"
  check "B06 exactly 5 lines at the pin name the recipe or tool, and none is under .github/ — no CI job runs it" \
    bash -c "test \"\$(wc -l <<<\"\$1\" | tr -d ' ')\" = 5 && ! $GREP -q '^\.github/' <<<\"\$1\"" _ "$HITS"
  git -C "$PY" show "$PIN:docs/api/openapi.json" > "$WORK/py-openapi.json"
  check "B07 py's committed snapshot declares openapi 3.1.0" test "$(jq -r .openapi "$WORK/py-openapi.json")" = 3.1.0
  check "B08 its operationIds are the curated tag-function ids ops-healthz ops-readyz projects-list_projects projects-get_project" \
    test "$(jq -r '[.paths[][].operationId] | join(" ")' "$WORK/py-openapi.json")" = "ops-healthz ops-readyz projects-list_projects projects-get_project"
  check "B09 it carries no info.license object (so a generator's licence default would apply)" \
    test "$(jq -r '.info.license // "absent"' "$WORK/py-openapi.json")" = absent
  MUSE=aa5d70154d492a2ac19faaa1bf20cdd01629195a
  if git -C "$PY" cat-file -e "$MUSE^{commit}" 2>/dev/null; then
    check "B10 the Muse raw's 'Justfile:322' is not the pin's line (the recipe is at :312 there); it matches a later py commit such as aa5d7015" \
      bash -c "git -C '$PY' show '$MUSE:Justfile' | sed -n 322p | $GREP -qF 'uvx openapi-python-client generate' && ! sed -n 322p '$WORK/py-Justfile' | $GREP -qF 'openapi-python-client'"
  else
    skip "B10 py commit aa5d7015 is not in the local clone"
  fi
else
  for b in B01 B02 B03 B04 B05 B06 B07 B08 B09 B10; do skip "$b py-launch-blueprint clone with commit $PIN is not available at \$R84_PY_REPO"; done
fi

# ------------------------------------------------ C: REST API Design Standard
RPIN=0850d43e45d919ef5e37f7174c4212b46013c49f
if git -C "$REST" cat-file -e "$RPIN^{commit}" 2>/dev/null; then
  git -C "$REST" show "$RPIN:rest-api-standard.md" > "$WORK/rest.md"
  check "C01 rest-api-standard.md at $RPIN is blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9" \
    test "$(git -C "$REST" rev-parse "$RPIN:rest-api-standard.md")" = 71bd813c1cf61286586b4ee41ed83ff065e5c8d9
  check "C02 :742-743 R4.1 'Every API MUST publish an OpenAPI document as the contract source of truth'" \
    bash -c "sed -n 742,743p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF '**R4.1** Every API MUST publish an OpenAPI document as the contract source of truth'"
  check "C03 :743-744 R4.1 '— version 3.1, or 3.2 only where the team's full toolchain (parser, linter, generator, docs renderer) is verified'" \
    bash -c "sed -n 743,744p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF \"version 3.1, or 3.2 only where the team's full toolchain (parser, linter, generator, docs renderer) is verified against it\""
  check "C04 :826-827 R4.9 enum additions are non-breaking; the client obligation to tolerate unknown values is R12.4" \
    bash -c "sed -n 826,827p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF 'the corresponding client obligation to tolerate unknown values is R12.4'"
  check "C05 :828 R4.9's exception: 'genuinely closed enumerations, documented as closed'" \
    bash -c "sed -n 828p '$WORK/rest.md' | $GREP -qF '**Exception:** genuinely closed enumerations, documented as closed.'"
  check "C06 :1790-1791 R12.3 'Clients MUST set explicit request timeouts'" \
    bash -c "sed -n 1790,1791p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF '**R12.3** Clients MUST set explicit request timeouts, and MUST NOT disable TLS certificate verification'"
  check "C07 :1799-1800 R12.4 'Clients MUST tolerate unknown response fields and unknown enum values'" \
    bash -c "sed -n 1799,1800p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF '**R12.4** Clients MUST tolerate unknown response fields and unknown enum values (R4.9)'"
  check "C08 :1815-1816 R12.6 'Clients SHOULD send \`Accept: application/problem+json\` explicitly'" \
    bash -c "sed -n 1815,1816p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF '**R12.6** Clients SHOULD send \`Accept: application/problem+json\` explicitly when they want problem documents'"
  check "C09 :1819 R12.7 'Clients MUST NOT rely on every error being a problem document'" \
    bash -c "sed -n 1819p '$WORK/rest.md' | $GREP -qF '**R12.7** Clients MUST NOT rely on every error being a problem document:'"
  check "C10 :1777 R12.1 retries only documented-retryable failures; :1784 R12.2 honour Retry-After" \
    bash -c "sed -n 1777p '$WORK/rest.md' | $GREP -qF '**R12.1** Clients MUST retry only failures the API documents as' && sed -n 1784p '$WORK/rest.md' | $GREP -qF '**R12.2** Clients MUST honor \`Retry-After\`'"
  check "C11 :272-273 R1.7 'Every deviation from a **SHOULD** MUST be recorded in the API's conformance note with its reason'" \
    bash -c "sed -n 272,273p '$WORK/rest.md' | tr '\n' ' ' | $GREP -qF \"Every deviation from a **SHOULD** MUST be recorded in the API's conformance note with its reason\""
else
  for c in C01 C02 C03 C04 C05 C06 C07 C08 C09 C10 C11; do skip "$c rest-standards clone with commit $RPIN is not available at \$R84_REST_REPO"; done
fi

# ------------------------------------------------ D: published crate sources
fetch_crate() { # fetch_crate <name> <version> -> extracts into $WORK/<name>-<version>
  curl -sSfL --max-time 60 -A "$UA" -o "$WORK/$1.crate" "https://static.crates.io/crates/$1/$1-$2.crate" \
    && tar xzf "$WORK/$1.crate" -C "$WORK"
}
if fetch_crate progenitor-impl 0.15.0; then
  L="$WORK/progenitor-impl-0.15.0/src/lib.rs"
  echo "      sha256(progenitor-impl-0.15.0.crate) = $(shasum -a 256 "$WORK/progenitor-impl.crate" | cut -d' ' -f1)"
  check "D01 progenitor-impl 0.15.0 src/lib.rs:702 declares fn validate_openapi_spec_version" \
    line_is "$L" 702 'fn validate_openapi_spec_version(spec_version: &str) -> Result<()> {'
  check "D02 :703-704 admits a document only when its version starts_with(\"3.0.\") (comment: 'only support OAS 3.0.x')" \
    bash -c "line_is() { test \"\$(sed -n \"\$2p\" \"\$1\")\" = \"\$3\"; }; line_is '$L' 703 '    // progenitor currenlty only support OAS 3.0.x' && line_is '$L' 704 '    if spec_version.trim().starts_with(\"3.0.\") {'"
  check "D03 :798 progenitor's own unit test expects '... invalid version: 3.1.0'" \
    bash -c "sed -n 798p '$L' | $GREP -qF 'unexpected or unhandled format in the OpenAPI document invalid version: 3.1.0'"
  check "D04 :737 a missing operationId is an error: 'path {} is missing operation ID'" \
    bash -c "sed -n 737p '$L' | $GREP -qF '\"path {} is missing operation ID\",'"
else
  for d in D01 D02 D03 D04; do skip "$d progenitor-impl 0.15.0 could not be fetched from static.crates.io"; done
fi
if fetch_crate cargo-progenitor 0.15.0; then
  M="$WORK/cargo-progenitor-0.15.0/src/main.rs"
  check "D05 cargo-progenitor 0.15.0 src/main.rs:91-92 sets the nightly-only rustfmt options normalize_doc_attributes and wrap_comments" \
    bash -c "line_is() { test \"\$(sed -n \"\$2p\" \"\$1\")\" = \"\$3\"; }; line_is '$M' 91 '        normalize_doc_attributes: Some(true),' && line_is '$M' 92 '        wrap_comments: Some(true),'"
  check "D06 :95 unwraps rustfmt's result, the panic site observed by r84-progenitor-probe.sh P03" \
    line_is "$M" 95 '    space_out_items(rustfmt_wrapper::rustfmt_config(config, input).unwrap()).unwrap()'
else
  for d in D05 D06; do skip "$d cargo-progenitor 0.15.0 could not be fetched"; done
fi
if fetch_crate utoipa 5.5.0; then
  U="$WORK/utoipa-5.5.0/src/openapi.rs"
  NV=$(awk '/^pub enum OpenApiVersion \{/{f=1;next} f&&/^\}/{f=0} f&&/^    [A-Z][A-Za-z0-9]*,$/{n++} END{print n+0}' "$U")
  check "D07 utoipa 5.5.0 OpenApiVersion has exactly one variant (counted: $NV)" test "$NV" = 1
  check "D08 :385-387 that variant is Version31, #[serde(rename = \"3.1.0\")], #[default] — utoipa emits only 3.1.0" \
    bash -c "line_is() { test \"\$(sed -n \"\$2p\" \"\$1\")\" = \"\$3\"; }; line_is '$U' 385 '    #[serde(rename = \"3.1.0\")]' && line_is '$U' 387 '    Version31,'"
else
  for d in D07 D08; do skip "$d utoipa 5.5.0 could not be fetched"; done
fi
if fetch_crate utoipa 6.0.0; then
  U6="$WORK/utoipa-6.0.0/src/openapi.rs"
  check "D16 utoipa 6.0.0 (published 2026-09-22) still defaults to 3.1.0: openapi.rs:484-486 rename \"3.1.0\", #[default], Version31" \
    bash -c "line_is() { test \"\$(sed -n \"\$2p\" \"\$1\")\" = \"\$3\"; }; line_is '$U6' 484 '    #[serde(rename = \"3.1.0\")]' && line_is '$U6' 485 '    #[default]' && line_is '$U6' 486 '    Version31,'"
  check "D17 utoipa 6.0.0 adds an opt-in Version32 (openapi.rs:487-489): 'Opt-in until OpenAPI 3.2 tooling support is widespread'" \
    bash -c "sed -n 487p '$U6' | $GREP -qF 'Opt-in until OpenAPI 3.2 tooling support is widespread' && line_is() { test \"\$(sed -n \"\$2p\" \"\$1\")\" = \"\$3\"; } && line_is '$U6' 489 '    Version32,'"
else
  for d in D16 D17; do skip "$d utoipa 6.0.0 could not be fetched"; done
fi
if fetch_crate openapi-to-rust 0.17.0; then
  O="$WORK/openapi-to-rust-0.17.0"
  echo "      sha256(openapi-to-rust-0.17.0.crate) = $(shasum -a 256 "$WORK/openapi-to-rust.crate" | cut -d' ' -f1)"
  check "D09 openapi-to-rust 0.17.0 was published from gpu-cli/openapi-to-rust commit a968c13d (.cargo_vcs_info.json)" \
    test "$(jq -r .git.sha1 "$O/.cargo_vcs_info.json")" = a968c13de9c1171bbee54f803e72cc914e06b04b
  check "D10 its manifest: edition 2024, rust-version 1.88.0, license MIT, default features [\"cli\"]" \
    bash -c "$GREP -qx 'edition = \"2024\"' '$O/Cargo.toml' && $GREP -qx 'rust-version = \"1.88.0\"' '$O/Cargo.toml' && $GREP -qx 'license = \"MIT\"' '$O/Cargo.toml' && $GREP -qx 'default = \[\"cli\"\]' '$O/Cargo.toml'"
  check "D11 src/config.rs:174-178 documents [extensible_enums]: force a closed string enum to carry a Custom(String) fallback" \
    bash -c "sed -n 174,178p '$O/src/config.rs' | tr '\n' ' ' | $GREP -qF 'Force a closed string-enum schema to be rendered as an extensible enum     /// (with a \`Custom(String)\` fallback variant).'"
  check "D12 src/analysis.rs:7428-7430 an anyOf of enum values plus an open string becomes an ExtensibleEnum with no configuration" \
    bash -c "sed -n 7428,7430p '$O/src/analysis.rs' | tr '\n' ' ' | $GREP -qF 'Has both constants and open string - create an extensible enum'"
  TREF=$($GREP -rn 'timeout_seconds' "$O/src" | sed "s|$O/||" | LC_ALL=C sort)
  while IFS= read -r l; do echo "      $l"; done <<<"$TREF"
  check "D13 timeout_seconds is parsed and validated (config.rs) but client_generator.rs names it only in a //! doc line — it never reaches generated code" \
    bash -c "test \"\$($GREP -c 'timeout_seconds' '$O/src/client_generator.rs')\" = 1 && $GREP -q '^//! timeout_seconds = 30\$' '$O/src/client_generator.rs'"
  check "D14 src/client_generator.rs:1436-1446 skips a caller's 'accept' header and sets Accept to the success media type" \
    bash -c "sed -n 1440p '$O/src/client_generator.rs' | $GREP -qF 'if !name.eq_ignore_ascii_case(\"accept\") {' && sed -n 1446p '$O/src/client_generator.rs' | $GREP -qF 'req = req.header(reqwest::header::ACCEPT, #media_type);'"
  UL=$($GREP -rn -w 'unsafe' "$O/src" | $GREP -v '/snapshots/' | sed "s|$O/||")
  while IFS= read -r l; do echo "      $l"; done <<<"$UL"
  check "D15 the tool's own sources (snapshots excluded) contain the token 'unsafe' only in 2 string literals, no unsafe block" \
    bash -c "test \"\$(wc -l <<<\"\$1\" | tr -d ' ')\" = 2 && ! $GREP -q 'unsafe {\|unsafe fn\|unsafe impl' <<<\"\$1\"" _ "$UL"
else
  for d in D09 D10 D11 D12 D13 D14 D15; do skip "$d openapi-to-rust 0.17.0 could not be fetched"; done
fi

# ------------------------------------------- E: OpenAPI Generator v7.25.0 sources
OG=https://raw.githubusercontent.com/OpenAPITools/openapi-generator/v7.25.0
getog() { curl -sSf --max-time 60 -A "$UA" -o "$WORK/$2" "$OG/$1"; }
if getog modules/openapi-generator/src/main/resources/rust/Cargo.mustache Cargo.mustache \
   && getog modules/openapi-generator/src/main/resources/rust/model.mustache model.mustache \
   && getog modules/openapi-generator/src/main/resources/rust/reqwest/configuration.mustache configuration.mustache \
   && getog modules/openapi-generator/src/main/java/org/openapitools/codegen/languages/RustClientCodegen.java RustClientCodegen.java \
   && getog modules/openapi-generator/src/main/java/org/openapitools/codegen/CodegenConstants.java CodegenConstants.java \
   && getog docs/generators/rust.md rust.md; then
  check "E01 the rust generator's Cargo.mustache hard-codes edition = \"2021\" and declares no rust-version" \
    bash -c "$GREP -qx 'edition = \"2021\"' '$WORK/Cargo.mustache' && ! $GREP -q 'rust-version' '$WORK/Cargo.mustache'"
  check "E02 without an info.license object the generated manifest says license = \"Unlicense\"" \
    $GREP -qx 'license = "Unlicense"' "$WORK/Cargo.mustache"
  check "E03 no 'time' crate is ever declared by the template (Gemini's RUSTSEC-2020-0071 / time 0.1 exclusion has no ground here)" \
    bash -c "! $GREP -q -E '^time *=' '$WORK/Cargo.mustache'"
  EN=$(awk '/for enum schemas/{f=1} f' "$WORK/model.mustache" | $GREP -c -E 'serde\(other\)|Custom\(|Unknown')
  check "E04 string enums derive a closed Deserialize: no #[serde(other)], Custom or Unknown arm in model.mustache (counted: $EN)" test "$EN" = 0
  OPTS=$(awk -F'|' '/^\| Option \|/{f=1;next} f&&/^$/{f=0} f&&/^\|[a-zA-Z]+\|/{print $2}' "$WORK/rust.md" | tr '\n' ' ')
  echo "      rust generator options: $OPTS"
  check "E05 none of the rust generator's documented options concerns unknown enum values" \
    bash -c "! $GREP -q -i 'unknown\|enumUnknown' <<<\"\$1\"" _ "$OPTS"
  check "E06 the generator's own metadata says 'generator stability | STABLE' yet its help text says '(beta)'" \
    bash -c "$GREP -qF '| generator stability | STABLE | |' '$WORK/rust.md' && $GREP -qF 'return \"Generates a Rust client library (beta).\";' '$WORK/RustClientCodegen.java'"
  check "E07 CodegenConstants.java carries the 'OpenAPI 3.1 support is still in beta' warning Opus observed at generation" \
    $GREP -qF 'OpenAPI 3.1 support is still in beta.' "$WORK/CodegenConstants.java"
  check "E08 the reqwest Configuration exposes 'pub client' — a caller can inject a client carrying a timeout (R12.3)" \
    $GREP -q '^    pub client: ' "$WORK/configuration.mustache"
else
  for e in E01 E02 E03 E04 E05 E06 E07 E08; do skip "$e OpenAPI Generator v7.25.0 sources could not be fetched from raw.githubusercontent.com"; done
fi

summary
