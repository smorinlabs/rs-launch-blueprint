#!/usr/bin/env bash
# shellcheck disable=SC2016
# R53 revision 2 — the check that answers judgment finding JF-1 and JF-3.
#
# It does NOT replace review/evidence/verify.sh, which stays byte-identical with
# its log. This is a new file, and it adds exactly what revision 1 left unstated:
#
#   * Fitness gate 3, `unsafe` posture limb — for EVERY candidate this item gates,
#     from the PUBLISHED crate source at the exact version, not from documentation
#     and not from a raw report. Each tarball is fetched from crates.io into a
#     $TMPDIR subdirectory, extracted there, and censused with /usr/bin/grep by
#     absolute path. The repository is never written to and nothing is compiled.
#   * Fitness gate 5, default features and async-runtime coupling — for every
#     candidate, from its own crates.io version and dependency records.
#   * JF-3's three container-type claims — `toml::Table`'s backing map, `garde`'s
#     `Report`, `validator`'s `ValidationErrors` — asserted from the same published
#     sources rather than left uncited.
#
# SC2016 is disabled file-wide and deliberately: the needles asserted below are
# Rust source literals containing `$` and backticks, and single quotes are what
# keeps them literal. With that one directive `shellcheck` exits 0 with no finding.
#
# Contract (identical to verify.sh's):
#   * `set -uo pipefail` so a failing command inside a pipeline cannot be masked.
#   * Every claim goes through assert_* comparing the CONTENT expected; a check
#     that cannot fail is not evidence.
#   * /usr/bin/grep is invoked by absolute path and named beside every count; no
#     count is taken from head-truncated output.
#   * Sections needing the network print `SKIP <name>` and are not failures, so
#     the script still runs from a clean `git archive HEAD` extraction.
#   * Exit status is the number of failed assertions.

set -uo pipefail

FAILURES=0
CHECKS=0
SKIPS=0
UA="rs-launch-blueprint-research/1.0 (R53 gate-posture check; https://github.com/smorinlabs/rs-launch-blueprint)"
RETRIEVED="$(date -u +%Y-%m-%d)"
WORK="${TMPDIR:-/tmp}/r53-r2-gate.$$"
VEND="$WORK/vendor"

# Exact published versions. A census is only evidence about the version it read.
SERDE_V="1.0.229"
SERDE_CORE_V="1.0.229"
SERDE_DERIVE_V="1.0.229"
GARDE_V="0.23.0"
GARDE_DERIVE_V="0.23.0"
VALIDATOR_V="0.21.0"
SERDE_VALID_V="3.1.2"
NUTYPE_V="0.7.0"
VALIDIFY_V="2.0.0"
TOML_V="1.1.6+spec-1.1.0"     # R52's selection; read here only for JF-3's Table claim

mkdir -p "$VEND"
trap 'rm -rf "$WORK"' EXIT

say() { printf '%s\n' "$*"; }
hdr() { printf '\n======== %s ========\n' "$*"; }
fail() { FAILURES=$((FAILURES + 1)); printf 'FAIL %s :: %s\n' "$1" "$2"; }
pass() { printf 'PASS %s :: %s\n' "$1" "$2"; }
skip() { SKIPS=$((SKIPS + 1)); printf 'SKIP %s :: %s\n' "$1" "$2"; }

# assert_has <id> <fixed-needle> <haystack-file>
assert_has() {
    CHECKS=$((CHECKS + 1))
    if /usr/bin/grep -qF -- "$2" "$3"; then
        pass "$1" "/usr/bin/grep -F found: $2"
    else
        fail "$1" "/usr/bin/grep -F did NOT find: $2 (in $3)"
    fi
}

# assert_eq <id> <expected> <actual>
assert_eq() {
    CHECKS=$((CHECKS + 1))
    if [ "$2" = "$3" ]; then
        pass "$1" "equal: $2"
    else
        fail "$1" "expected [$2] got [$3]"
    fi
}

net_ok=0
if /usr/bin/curl -fsS -m 25 -A "$UA" -o "$WORK/net.json" "https://crates.io/api/v1/crates/serde"; then
    net_ok=1
fi

hdr "0  toolchain, host, retrieval date"
say "retrieval date (UTC): $RETRIEVED"
say "uname: $(uname -srm)"
say "sw_vers: $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null) $(sw_vers -buildVersion 2>/dev/null)"
say "curl: $(/usr/bin/curl --version | head -1)"
say "grep (the binary every count below is taken with): $(/usr/bin/grep --version | head -1) at /usr/bin/grep"
say "tar: $(tar --version 2>/dev/null | head -1)"
say "jq: $(jq --version 2>/dev/null || echo absent)"
say "network reachable (crates.io): $net_ok"
say "vendor directory (outside the repository, deleted on exit): $VEND"
say "NOTE: nothing is compiled by this script and no file is written into the repository."

if [ "$net_ok" != 1 ]; then
    hdr "no network — every check below is skipped by name"
    for id in G01 G02 G03 G04 G05 G06 G07 G08 G09 G10 G11 G12 G13 G14 G15 \
              G16 G17 G18 G19 G20 G21 G22 G23 G24 G25 G26 G27 G28 G29 G30 \
              G31 G32 G33 G34 G35 G36 G37; do
        skip "$id" "no network: published crate sources could not be fetched"
    done
    hdr "summary"
    say "checks run:  $CHECKS"
    say "failures:    $FAILURES"
    say "skips:       $SKIPS"
    exit "$FAILURES"
fi

hdr "1  fetch and extract the published crate sources at their exact versions"

fetch() {
    # fetch <name> <version> — downloads the published .crate and extracts it.
    name="$1"; ver="$2"
    url="https://crates.io/api/v1/crates/$name/$ver/download"
    if /usr/bin/curl -fsSL -m 90 -A "$UA" -o "$VEND/$name-$ver.crate" "$url" \
       && tar xzf "$VEND/$name-$ver.crate" -C "$VEND"; then
        say "fetched $name $ver from $url -> $VEND/$name-$ver/"
        return 0
    fi
    say "FETCH FAILED $name $ver from $url"
    return 1
}

for spec in "serde $SERDE_V" "serde_core $SERDE_CORE_V" "serde_derive $SERDE_DERIVE_V" \
            "garde $GARDE_V" "garde_derive $GARDE_DERIVE_V" "validator $VALIDATOR_V" \
            "serde_valid $SERDE_VALID_V" "nutype $NUTYPE_V" "validify $VALIDIFY_V" \
            "toml $TOML_V"; do
    # shellcheck disable=SC2086
    set -- $spec
    fetch "$1" "$2"
done

hdr "2  fitness gate 3, the unsafe-posture limb, per candidate"
say "Method: for each extracted crate, /usr/bin/grep -n -w 'unsafe' over every .rs"
say "file found by find(1) under the crate's own src/ (and, for nutype, its whole"
say "tree, whose only .rs file is src/lib.rs). The count is of MATCHING LINES over"
say "the WHOLE tree, never a head-truncated prefix. Every matching line is printed"
say "below the count, so the count can be audited against the listing."
say ""
say "Scope note that goes with every row: R06 (research/topics/06-unsafe-code-policy)"
say "forbids unsafe in the TEMPLATE'S OWN code via [workspace.lints.rust]"
say "unsafe_code = \"forbid\" and makes no claim about the dependency tree, because"
say "Cargo compiles dependencies with --cap-lints allow. So no row below excludes a"
say "candidate; gate 3's unsafe limb is a STATED POSTURE, not a filter."

unsafe_census() {
    # unsafe_census <dir> <subpath> -> prints count, then the matching lines
    dir="$VEND/$1"
    sub="$2"
    if [ ! -d "$dir" ]; then
        say "  (directory absent: $dir)"
        printf '%s' "ABSENT"
        return
    fi
    find "$dir/$sub" -name '*.rs' -print0 2>/dev/null \
        | xargs -0 /usr/bin/grep -n -w 'unsafe' 2>/dev/null \
        | sed "s|^$VEND/||" > "$WORK/unsafe-$1.txt"
    n="$(/usr/bin/grep -c '' "$WORK/unsafe-$1.txt")"
    printf '%s' "$n"
}

for spec in "serde-$SERDE_V src" "serde_core-$SERDE_CORE_V src" \
            "serde_derive-$SERDE_DERIVE_V src" "garde-$GARDE_V src" \
            "garde_derive-$GARDE_DERIVE_V src" "validator-$VALIDATOR_V src" \
            "serde_valid-$SERDE_VALID_V src" "nutype-$NUTYPE_V ." \
            "validify-$VALIDIFY_V src"; do
    # shellcheck disable=SC2086
    set -- $spec
    n="$(unsafe_census "$1" "$2")"
    rs="$(find "$VEND/$1/$2" -name '*.rs' 2>/dev/null | /usr/bin/grep -c '')"
    say ""
    say "--- $1 : .rs files searched = $rs ; lines matching /usr/bin/grep -n -w 'unsafe' = $n"
    if [ -s "$WORK/unsafe-$1.txt" ]; then
        cat "$WORK/unsafe-$1.txt"
    else
        say "    (no matching line anywhere in the searched tree)"
    fi
done

say ""
say "Per-candidate gate 3 unsafe assertions:"
# serde: two unsafe blocks, both str::from_utf8_unchecked, mirrored in serde_core.
assert_eq G01 "2" "$(/usr/bin/grep -c '' "$WORK/unsafe-serde-$SERDE_V.txt")"
assert_has G02 'serde-'"$SERDE_V"'/src/core/format.rs:16:        unsafe { str::from_utf8_unchecked(slice) }' "$WORK/unsafe-serde-$SERDE_V.txt"
assert_eq G03 "2" "$(/usr/bin/grep -c '' "$WORK/unsafe-serde_core-$SERDE_CORE_V.txt")"
assert_eq G04 "0" "$(/usr/bin/grep -c '' "$WORK/unsafe-serde_derive-$SERDE_DERIVE_V.txt")"
# garde: seven matching lines, of which four are inside a wasm32-only module.
assert_eq G05 "7" "$(/usr/bin/grep -c '' "$WORK/unsafe-garde-$GARDE_V.txt")"
assert_eq G06 "2" "$(/usr/bin/grep -c 'src/i18n.rs' "$WORK/unsafe-garde-$GARDE_V.txt")"
assert_eq G07 "4" "$(/usr/bin/grep -c 'src/rules/pattern.rs' "$WORK/unsafe-garde-$GARDE_V.txt")"
assert_eq G08 "1" "$(/usr/bin/grep -c 'src/error/rc_list/mod.rs' "$WORK/unsafe-garde-$GARDE_V.txt")"
assert_has G09 'garde-'"$GARDE_V"'/src/error/rc_list/mod.rs:93:            unsafe { transmute(&next.value) }' "$WORK/unsafe-garde-$GARDE_V.txt"
assert_eq G10 "2" "$(/usr/bin/grep -c '' "$WORK/unsafe-garde_derive-$GARDE_DERIVE_V.txt")"
# validator, serde_valid, validify: none at all.
assert_eq G11 "0" "$(/usr/bin/grep -c '' "$WORK/unsafe-validator-$VALIDATOR_V.txt")"
assert_eq G12 "0" "$(/usr/bin/grep -c '' "$WORK/unsafe-serde_valid-$SERDE_VALID_V.txt")"
assert_eq G13 "0" "$(/usr/bin/grep -c '' "$WORK/unsafe-validify-$VALIDIFY_V.txt")"
# nutype: three matches, all doc-comment text about its opt-in new_unchecked feature.
assert_eq G14 "3" "$(/usr/bin/grep -c '' "$WORK/unsafe-nutype-$NUTYPE_V.txt")"
assert_eq G15 "3" "$(/usr/bin/grep -c '//!' "$WORK/unsafe-nutype-$NUTYPE_V.txt")"

hdr "2b  which of garde's unsafe sites are on a default ubuntu/macos build path"
say "This decides whether the runner-up's unsafe is reachable for this template."
say "A site is on the default path when the module declaring it carries no cfg gate."
/usr/bin/grep -n -B4 'pub mod regex_js_sys' "$VEND/garde-$GARDE_V/src/rules/pattern.rs" > "$WORK/garde-pattern-cfg.txt"
say "--- garde src/rules/pattern.rs, the regex_js_sys module header ---"
cat "$WORK/garde-pattern-cfg.txt"
assert_has G16 'target_arch = "wasm32"' "$WORK/garde-pattern-cfg.txt"
assert_has G17 'target_os = "unknown"' "$WORK/garde-pattern-cfg.txt"

/usr/bin/grep -n 'mod rc_list' "$VEND/garde-$GARDE_V/src/error.rs" > "$WORK/garde-rclist.txt"
say "--- garde src/error.rs, the rc_list module declaration (no cfg attribute above it) ---"
/usr/bin/grep -n -B3 'mod rc_list' "$VEND/garde-$GARDE_V/src/error.rs"
assert_has G18 'mod rc_list;' "$WORK/garde-rclist.txt"
assert_eq G19 "0" "$(/usr/bin/grep -n -B3 'mod rc_list' "$VEND/garde-$GARDE_V/src/error.rs" | /usr/bin/grep -c '#\[cfg')"

/usr/bin/grep -n -B3 '^pub mod i18n;' "$VEND/garde-$GARDE_V/src/lib.rs" > "$WORK/garde-i18n.txt"
say "--- garde src/lib.rs, the i18n module declaration (no cfg attribute above it) ---"
cat "$WORK/garde-i18n.txt"
assert_has G20 'pub mod i18n;' "$WORK/garde-i18n.txt"
assert_eq G21 "0" "$(/usr/bin/grep -c '#\[cfg' "$WORK/garde-i18n.txt")"

hdr "2c  no candidate declares a crate-level unsafe_code lint attribute"
say "Recorded so the absence is stated rather than assumed: a crate that forbids"
say "unsafe in its own source would say so in its lib.rs, and none of these does."
for spec in "serde-$SERDE_V" "garde-$GARDE_V" "validator-$VALIDATOR_V" \
            "serde_valid-$SERDE_VALID_V" "nutype-$NUTYPE_V" "validify-$VALIDIFY_V"; do
    lib="$(find "$VEND/$spec" -name 'lib.rs' -maxdepth 3 2>/dev/null | head -1)"
    if [ -n "$lib" ]; then
        c="$(/usr/bin/grep -c 'unsafe_code' "$lib")"
        say "  $spec : $(printf '%s' "$lib" | sed "s|^$VEND/||") carries $c line(s) matching 'unsafe_code' (/usr/bin/grep -c)"
    else
        say "  $spec : no lib.rs found"
    fi
done
assert_eq G22 "0" "$(/usr/bin/grep -c 'unsafe_code' "$VEND/garde-$GARDE_V/src/lib.rs")"
assert_eq G23 "0" "$(/usr/bin/grep -c 'unsafe_code' "$VEND/validator-$VALIDATOR_V/src/lib.rs")"

hdr "3  fitness gate 5, default features and async-runtime coupling, per candidate"
say "Async-runtime coupling is judged by whether ANY normal dependency — optional"
say "or not — is an async executor or reactor. The pattern searched for is"
say "^(tokio|async-std|smol|futures|futures-.*|async-global-executor|async-io|async-executor|actix-rt)$"
say "over the crate_id list from GET https://crates.io/api/v1/crates/<n>/<v>/dependencies."

ASYNC_RE='^(tokio|async-std|smol|futures|futures-[a-z-]+|async-global-executor|async-io|async-executor|actix-rt)$'
async_total=0
for spec in "serde/$SERDE_V" "garde/$GARDE_V" "validator/$VALIDATOR_V" \
            "serde_valid/$SERDE_VALID_V" "nutype/$NUTYPE_V" "validify/$VALIDIFY_V"; do
    name="${spec%%/*}"
    say ""
    say "--- GET https://crates.io/api/v1/crates/$spec  and  .../dependencies"
    /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$name-ver.json"  "https://crates.io/api/v1/crates/$spec"
    /usr/bin/curl -fsS -m 30 -A "$UA" -o "$WORK/$name-deps.json" "https://crates.io/api/v1/crates/$spec/dependencies"
    hasdef="$(jq -r '.version.features|has("default")' "$WORK/$name-ver.json")"
    defval="$(jq -r 'if (.version.features|has("default")) then (.version.features.default|join(",")) else "<no default key>" end' "$WORK/$name-ver.json")"
    jq -r '[.dependencies[]|select(.kind=="normal")]|map(.crate_id)|sort|.[]' "$WORK/$name-deps.json" > "$WORK/$name-normal.txt"
    ndeps="$(/usr/bin/grep -c '' "$WORK/$name-normal.txt")"
    nasync="$(/usr/bin/grep -c -E "$ASYNC_RE" "$WORK/$name-normal.txt")"
    async_total=$((async_total + nasync))
    say "  default feature key present: $hasdef ; default = [$defval]"
    say "  normal dependencies (optional and non-optional), $ndeps in total from /usr/bin/grep -c over the whole list:"
    sed 's/^/    /' "$WORK/$name-normal.txt"
    say "  async-runtime/reactor dependencies matching the pattern: $nasync"
done
assert_eq G24 "true"  "$(jq -r '.version.features|has("default")' "$WORK/serde-ver.json")"
assert_eq G25 "std"   "$(jq -r '.version.features.default|join(",")' "$WORK/serde-ver.json")"
assert_eq G26 "false" "$(jq -r '.version.features|has("default")' "$WORK/garde-ver.json")"
assert_eq G27 "false" "$(jq -r '.version.features|has("default")' "$WORK/validator-ver.json")"
assert_eq G28 "i128"  "$(jq -r '.version.features.default|join(",")' "$WORK/serde_valid-ver.json")"
assert_eq G29 "std"   "$(jq -r '.version.features.default|join(",")' "$WORK/nutype-ver.json")"
assert_eq G30 "false" "$(jq -r '.version.features|has("default")' "$WORK/validify-ver.json")"
say ""
say "Total async-runtime/reactor dependencies across all six candidates: $async_total"
assert_eq G31 "0" "$async_total"

hdr "4  JF-3: the three container types, read from the published sources"
say "Revision 1 asserted these three shapes with no check id. They are now read"
say "from the same extracted crate sources as section 2."

say "--- toml $TOML_V : src/table.rs and the cfg-selected map backing ---"
/usr/bin/grep -n 'pub type Table' "$VEND/toml-$TOML_V/src/table.rs" > "$WORK/toml-table.txt"
cat "$WORK/toml-table.txt"
/usr/bin/grep -n -A1 'cfg(not(feature = "preserve_order"))' "$VEND/toml-$TOML_V/src/map.rs" > "$WORK/toml-map.txt"
cat "$WORK/toml-map.txt"
assert_has G32 'pub type Table = Map<String, Value>;' "$WORK/toml-table.txt"
assert_has G33 'type MapImpl<K, V> = BTreeMap<K, V>;' "$WORK/toml-map.txt"

say "--- garde $GARDE_V : src/error.rs, the Report container ---"
/usr/bin/grep -n -A3 'pub struct Report {' "$VEND/garde-$GARDE_V/src/error.rs" > "$WORK/garde-report.txt"
/usr/bin/grep -n 'pub fn into_inner(self) -> Vec<(Path, Error)>' "$VEND/garde-$GARDE_V/src/error.rs" >> "$WORK/garde-report.txt"
cat "$WORK/garde-report.txt"
assert_has G34 'errors: Vec<(Path, Error)>,' "$WORK/garde-report.txt"
assert_has G35 'pub fn into_inner(self) -> Vec<(Path, Error)>' "$WORK/garde-report.txt"

say "--- validator $VALIDATOR_V : src/types.rs, the ValidationErrors container ---"
/usr/bin/grep -n 'pub struct ValidationErrors' "$VEND/validator-$VALIDATOR_V/src/types.rs" > "$WORK/validator-errors.txt"
cat "$WORK/validator-errors.txt"
assert_has G36 'pub struct ValidationErrors(pub HashMap<Cow<' "$WORK/validator-errors.txt"
assert_eq G37 "0" "$(/usr/bin/grep -c 'pub struct ValidationErrors(pub BTreeMap' "$VEND/validator-$VALIDATOR_V/src/types.rs")"

hdr "5  summary"
say "checks run:  $CHECKS"
say "failures:    $FAILURES"
say "skips:       $SKIPS"
say ""
say "Reproducibility rule for a rerun diff: every PASS / FAIL / SKIP line and every"
say "count above is reproducible byte-for-byte, because every crate is read at a"
say "pinned published version whose bytes cannot change (crates.io releases are"
say "immutable) and no figure here is a rolling counter. The lines that differ on"
say "every run are the eleven carrying the \$TMPDIR vendor path, which embeds the"
say "shell's PID — the header line and the ten 'fetched ...' lines — plus the"
say "retrieval-date line, which changes daily by construction."
exit "$FAILURES"
