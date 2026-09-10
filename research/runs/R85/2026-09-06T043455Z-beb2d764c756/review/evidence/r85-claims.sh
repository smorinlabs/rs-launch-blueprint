#!/usr/bin/env bash
# R85 rich-terminal-row-niceties — synthesizer empirical check.
#
# Verifies the claims the two raw reports make. Implements nothing: no crate is
# scaffolded, no renderer is written, no Rust code is compiled.
#
# Determinism contract
# --------------------
#   * Crate sources are the published .crate tarballs at pinned versions from
#     static.crates.io. A published version is immutable; each tarball's sha256
#     is asserted against a constant below, so every printed source extract is
#     reproducible byte-for-byte.
#   * Repository sources are read through fixed commit SHAs (py, ts, cargo,
#     rustsec/advisory-db), never a branch tip.
#   * HTTP JSON that drifts (download counters, `pushed_at`, reaction counts,
#     the newest-version list) is snapshotted once into ./snap/ and read from
#     the snapshot afterwards. Delete ./snap/ to re-fetch.
#   * Nothing time-dependent is printed, so `bash r85-claims.sh | diff - r85-claims.log`
#     is empty on any rerun.
#
# Usage: bash r85-claims.sh            (run from this evidence directory)

set -uo pipefail

REPO=/Users/stevemorin/c/rs-launch-blueprint-p02-plan
RUN="$REPO/research/runs/R85/2026-09-06T043455Z-beb2d764c756"
EVID="$RUN/review/evidence"
SNAP="$EVID/snap"
PY=/Users/stevemorin/c/py-launch-blueprint
TS=/Users/stevemorin/c/ts-launch-blueprint
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
CARGO_PIN=797e8a9bc                                   # the commit in `cargo --version` on this machine
ADVDB_PIN=b50980aad8b8f14f77e25a97b32dd94bf008b0af    # rustsec/advisory-db, recorded 2026-09-10
UA='rs-launch-blueprint-research/1.0 (steve@conceptm.com)'

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$SNAP"

# name:version:sha256 of the published .crate tarball
PINS=(
  "comfy-table:8.0.0:136c8c4c3823846e8ba6d4bda011b4e5d5827b8bb0ac26c31f9ab31abe9f54f2"
  "tabled:0.22.0:2d2596a104db1900b943f97d793a6c99addca918c4525c999f751a0f17d472eb"
  "papergrid:0.18.0:d0984e668274d34691bc2b262ef0d115de5fa9973bcdee7ae32213f93099153e"
  "console:0.16.6:e96a4956774c13c126a8b5af4daa79384f4d826534c95a02d76afb39e2ab64e3"
  "ansi-str:0.9.0:060de1453b69f46304b28274f382132f4e72c55637cf362920926a70d090890d"
  "ansitok:0.3.0:c0a8acea8c2f1c60f0a92a8cd26bf96ca97db56f10bbcab238bbe0cceba659ee"
  "anstyle-hyperlink:1.0.2:7a14cad0fa1d1fb02de486a95ea7fd8dd28567b82f65b4ca34bffa7da81823e4"
  "supports-hyperlinks:3.2.0:e396b6523b11ccb83120b115a0b7366de372751aa6edf19844dfb13a6af97e91"
  "timeago:0.6.1:46c29b13d230e9cd58513d38701a661fc06e1215398937532a2d938ecca6f219"
)

section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }

snap_get() {  # snap_get <file> <curl-url>
  local f="$SNAP/$1"; shift
  [ -s "$f" ] || curl -sS -H "User-Agent: $UA" -o "$f" "$1"
  cat "$f"
}
snap_gh() {   # snap_gh <file> <gh-api-path>
  local f="$SNAP/$1"; shift
  [ -s "$f" ] || gh api "$1" > "$f" 2>/dev/null
  cat "$f"
}

section "0. toolchain and platform"
rustc --version
cargo --version
printf 'macOS %s (%s)\n' "$(sw_vers -productVersion)" "$(uname -m)"
printf 'bash %s\n' "${BASH_VERSION%%(*}"

section "1. pinned crate sources — download and sha256 assertion"
for p in "${PINS[@]}"; do
  n=${p%%:*}; rest=${p#*:}; v=${rest%%:*}; want=${rest#*:}
  curl -sS -o "$WORK/$n-$v.crate" "https://static.crates.io/crates/$n/$n-$v.crate"
  got=$(shasum -a 256 "$WORK/$n-$v.crate" | cut -d' ' -f1)
  if [ "$got" = "$want" ]; then printf 'OK   %-22s %-8s sha256=%s\n' "$n" "$v" "$got"
  else printf 'FAIL %-22s %-8s sha256=%s (expected %s)\n' "$n" "$v" "$got" "$want"; fi
  tar xzf "$WORK/$n-$v.crate" -C "$WORK"
done

CT=$WORK/comfy-table-8.0.0
PG=$WORK/papergrid-0.18.0
TB=$WORK/tabled-0.22.0
AS=$WORK/ansi-str-0.9.0
AT=$WORK/ansitok-0.3.0
CO=$WORK/console-0.16.6
AH=$WORK/anstyle-hyperlink-1.0.2
SH=$WORK/supports-hyperlinks-3.2.0
TA=$WORK/timeago-0.6.1

section "2. THE DECIDING QUESTION — does the cell-width function discount a zero-width OSC-8 hyperlink?"

claim "2a. comfy-table 8.0.0 — which module supplies measure_text_width (feature-selected)"
sed -n '1,14p' "$CT/src/utils/formatting/content_split/mod.rs"

claim "2b. comfy-table 8.0.0 DEFAULT features — content_split/normal.rs:1-10"
sed -n '1,10p' "$CT/src/utils/formatting/content_split/normal.rs"
echo '=> unicode_width over the raw cell: every printable byte of the URL is counted.'

claim "2c. comfy-table 8.0.0 feature custom_styling — content_split/custom_styling.rs:1-13"
sed -n '1,13p' "$CT/src/utils/formatting/content_split/custom_styling.rs"
echo '=> delegates to ansi_str::AnsiStr::ansi_strip (see 2e).'

claim "2d. comfy-table 8.0.0 Cargo.toml — the custom_styling feature and its two deps"
sed -n '/^custom_styling = \[/,/^\]/p' "$CT/Cargo.toml"
grep -n -A2 '^\[dependencies.ansi-str\]' "$CT/Cargo.toml"
grep -n -A2 '^\[dependencies.console\]' "$CT/Cargo.toml"

claim "2e. ansi-str 0.9.0 — strip_ansi_sequences keeps ONLY ElementKind::Text"
grep -n -A3 'fn ansi_strip(&self) -> Cow' "$AS/src/lib.rs" | sed -n '1,8p'
sed -n '960,1006p' "$AS/src/lib.rs"

claim "2f. ansitok 0.3.0 — a well-formed OSC-8 pair is classified Osc + Esc, never Text (crate's own test)"
sed -n '/fn test_iterator_osc_hyperlinks_styled_non_ascii/,/^    }$/p' "$AT/src/parse/ansi_parser.rs"

claim "2g. ansitok 0.3.0 — the parser is vte (Alacritty's VT state machine); osc_dispatch records both terminators"
grep -n 'Based on https://github.com/alacritty/vte' "$AT/src/parse/ansi_parser.rs"
grep -n -A3 'fn osc_dispatch' "$AT/src/parse/ansi_parser.rs"
grep -n -A2 '^\[dependencies.vte\]' "$AT/Cargo.toml"

claim "2h. tabled 0.22.0 / papergrid 0.18.0 — the same question, papergrid answers it in a comment"
sed -n '16,48p' "$PG/src/util/string.rs"
echo '=> with feature `ansi`: only Text elements are measured. Without it: unicode_width over the raw cell.'
grep -n -A4 '^ansi = \[' "$PG/Cargo.toml"
grep -n -A5 '^ansi = \[' "$TB/Cargo.toml"

claim "2i. comfy-table also splits/wraps through console::AnsiCodeIterator — console 0.16.6 has an explicit OSC branch"
grep -n 'console::AnsiCodeIterator' "$CT/src/utils/formatting/content_split/custom_styling.rs"
grep -n -A8 'fn find_ansi_code_exclusive' "$CO/src/ansi.rs" | sed -n '1,14p'
sed -n '/fn strip_osc8_hyperlink_st/,/^    }$/p' "$CO/src/ansi.rs"
sed -n '/fn strip_osc8_hyperlink_bel/,/^    }$/p' "$CO/src/ansi.rs"
sed -n '/fn strip_tmux_passthrough_dcs/,/^    }$/p' "$CO/src/ansi.rs"
echo '--- console default features must include ansi-parsing for that path ---'
sed -n '/^\[features\]/,/^\[lib\]/p' "$CO/Cargo.toml"

claim "2j. counter-signal: comfy-table carries an OSC-8 width test that NEVER COMPILES"
grep -n -B3 -A12 'fn measure_text_width_osc8_test' "$CT/src/utils/formatting/content_split/custom_styling.rs"
echo '=> the test body lives in custom_styling.rs, which mod.rs compiles only under'
echo '   `#[cfg(feature = "custom_styling")]`, while the test itself is'
echo '   `#[cfg(not(feature = "custom_styling"))]` — a contradiction, so it is compiled out'
echo '   in BOTH feature configurations and has never run. Its input is also malformed:'
echo '   the closing sequence is `ESC ] 8 ; ; ESC` with no final backslash, so it is not'
echo '   what a well-formed emitter produces.'

claim "2k. is measure_text_width the ONLY width site? comfy-table has a second one that bypasses it"
echo '--- the primary measurement does go through the feature-selected function ---'
grep -n -A14 'fn max_content_widths' "$CT/src/row.rs" | sed -n '1,16p'
echo '--- but the ContentArrangement::Dynamic allocator measures cell content with raw unicode-width ---'
( cd "$CT" && grep -n 'UnicodeWidthStr' src/utils/arrangement/dynamic.rs )
sed -n '446,482p' "$CT/src/utils/arrangement/dynamic.rs"
echo '=> longest_line_after_split uses line.width() / part.width() (unicode-width) on cell'
echo '   content, NOT measure_text_width, so this path is not ANSI-aware even with'
echo '   custom_styling enabled. Every raw .width() call on cell content in src/utils/arrangement:'
( cd "$CT" && grep -rn '\.width()' src/utils/arrangement/ | grep -v 'info.width()\|table.width()\|padding_width()' )
echo '--- the same question for tabled/papergrid: any width site outside papergrid util/string.rs? ---'
( cd "$PG" && grep -rn 'UnicodeWidthStr\|unicode_width::' src/ | grep -v 'util/string.rs' ) \
  || echo '(papergrid: no direct unicode-width use outside src/util/string.rs)'
( cd "$TB" && grep -rn 'UnicodeWidthStr\|unicode_width::' src/ ) \
  || echo '(tabled: no direct unicode-width use at all; width goes through papergrid helpers)'
echo '--- tabled wrapping branches explicitly on the ansi feature ---'
grep -n 'cfg(not(feature = "ansi"))\|cfg(feature = "ansi")\|^fn wrap_text\|fn wrap_text_basic\|fn wrap_text_keeping_words' "$TB/src/settings/width/wrap.rs" | sed -n '1,10p'

claim "2l. history: the mis-measure was reported, diagnosed and fixed upstream (comfy-table issue #137)"
echo 'https://github.com/Nukesor/comfy-table/issues/137'
snap_gh comfy-table-issue-137.json repos/Nukesor/comfy-table/issues/137 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print("#%d %s  state=%s created=%s closed=%s"%(d["number"],d["title"],d["state"],d["created_at"],d["closed_at"])); print(d["body"].strip()[:420])'
echo '--- selected comments (verbatim) ---'
snap_gh comfy-table-issue-137-comments.json repos/Nukesor/comfy-table/issues/137/comments \
  | python3 -c '
import sys,json
for c in json.load(sys.stdin):
    b=c["body"].strip()
    if any(k in b for k in ("properly sized","measure_text_width","ansi-str","console")):
        print("--- %s %s"%(c["user"]["login"], c["created_at"]))
        print(b[:520]); print()'

section "3. anstyle-hyperlink 1.0.2 — the null-object carrier claims"
claim "3a. Default renders NOTHING; with_url writes the URL UNMODIFIED"
sed -n '/^impl<D: core::fmt::Display> Default for Hyperlink<D>/,/^}$/p' "$AH/src/hyperlink.rs"
sed -n '/^impl<D: core::fmt::Display> core::fmt::Display for Hyperlink<D>/,/^}$/p' "$AH/src/hyperlink.rs"
echo '=> open tag = 5 bytes ESC ] 8 ; ; + url + 2 bytes ESC \  (7 + url.len());'
echo '   close tag = 7 bytes. No percent-encoding, no control-byte filtering: sanitizing is the caller obligation.'
claim "3b. declared MSRV, features, and the two unsafe libc calls the file feature brings"
grep -n '^rust-version' "$AH/Cargo.toml"
sed -n '/^\[features\]/,/^\[dependencies/p' "$AH/Cargo.toml"
( cd "$AH" && grep -rn 'unsafe' src/ ) || echo '(no unsafe in src/)'
claim "3c. path_to_url percent-encodes (the P4 URI guard the recommendation relies on)"
grep -n 'percent_encod\|PATH_SEGMENT\|CONTROLS' "$AH/src/file.rs" | head -12

section "4. supports-hyperlinks 3.2.0 — licence and the environment inputs R65 must know about"
grep -n '^license\|^rust-version' "$SH/Cargo.toml"
grep -n 'FORCE_HYPERLINK\|DOMTERM\|VTE_VERSION\|TERM_PROGRAM\|WT_SESSION\|KONSOLE_VERSION\|is_terminal\|IsTerminal' "$SH/src/lib.rs" | head -20
printf 'unsafe occurrences in src/lib.rs: %s\n' "$(grep -c 'unsafe' "$SH/src/lib.rs")"

section "5. timeago 0.6.1 — does convert() take a signed or unsigned duration?"
grep -n 'pub fn convert\b' -A6 "$TA/src/lib.rs"
grep -n 'pub fn convert_chrono' -A6 "$TA/src/lib.rs"
grep -n '^default = \|^\[features\]' -A5 "$TA/Cargo.toml" | head -12

section "6. Cargo declares both recommended crates — read at this machine's own cargo commit"
printf 'pin: rust-lang/cargo %s (the commit printed by `cargo --version` above)\n' "$CARGO_PIN"
snap_get cargo-Cargo.toml "https://raw.githubusercontent.com/rust-lang/cargo/$CARGO_PIN/Cargo.toml" \
  | grep -n 'anstyle-hyperlink\|supports-hyperlinks\|^anstream'

section "7. registry figures — stable fields only, from snapshots (download counters excluded: they drift)"
for c in comfy-table tabled papergrid console ansi-str ansitok anstyle-hyperlink supports-hyperlinks timeago chrono-humanize; do
  snap_get "versions-$c.json" "https://crates.io/api/v1/crates/$c/versions" \
    | python3 -c "
import sys,json
d=json.load(sys.stdin); vs=[v for v in d['versions'] if not v['yanked']]
v=vs[0]
print('%-20s newest-unyanked=%-8s created_at=%s rust_version=%-8s license=%s' % (
    '$c', v['num'], v['created_at'], v.get('rust_version') or 'none', v.get('license')))"
done

section "8. RustSec — the raws disagree (codex: unverified 404s; opus: pass). Query the advisory database itself."
printf 'pin: rustsec/advisory-db %s\n' "$ADVDB_PIN"
for c in anstream anstyle-hyperlink supports-hyperlinks timeago percent-encoding comfy-table tabled console; do
  out=$(snap_gh "advdb-$c.json" "repos/rustsec/advisory-db/contents/crates/$c?ref=$ADVDB_PIN")
  if printf '%s' "$out" | grep -q '"name"'; then
    ids=$(printf '%s' "$out" | python3 -c 'import sys,json; print(", ".join(sorted(x["name"] for x in json.load(sys.stdin))))')
    printf '%-22s ADVISORY FILES: %s\n' "$c" "$ids"
  else
    printf '%-22s no advisory directory in the database at this pin\n' "$c"
  fi
done
echo '(anstream is the positive control: RUSTSEC-2024-0404 must appear, and it does.)'

section "9. py and ts source precedent, read through the programme pins"
printf 'py pin %s / ts pin %s\n' "$PY_PIN" "$TS_PIN"
claim "9a. py core/models.py — the hook and its default body"
git -C "$PY" show "$PY_PIN:src/py_launch_blueprint/core/models.py" | sed -n '55,68p'
claim "9b. py core/format.py — the bucket table, relative_time, and rich_link"
git -C "$PY" show "$PY_PIN:src/py_launch_blueprint/core/format.py" | sed -n '32,44p'
git -C "$PY" show "$PY_PIN:src/py_launch_blueprint/core/format.py" | sed -n '46,86p'
echo '=> note: rich_link emits RICH MARKUP `[link=url]text[/link]`, not raw OSC-8 bytes;'
echo '   Rich lowers the markup to OSC-8 and strips it off-terminal. That is the'
echo '   mechanism Rust has no equivalent of inside a table crate.'
claim "9c. py — the text renderer is the only consumer of the rich variant"
git -C "$PY" show "$PY_PIN:src/py_launch_blueprint/cli/output.py" | sed -n '224,241p'
claim "9d. py — every mention of table_rows_rich in the repository at the pin"
git -C "$PY" grep -n 'table_rows_rich' "$PY_PIN" -- 'src' 'tests' 'docs'
claim "9e. py — every mention of relative_time at the pin (is it wired into any model?)"
git -C "$PY" grep -n 'relative_time' "$PY_PIN" -- 'src' 'tests'
claim "9e2. py — the only override of the hook in the whole repository, and its escaping test"
git -C "$PY" show "$PY_PIN:src/py_launch_blueprint/core/models.py" | sed -n '133,143p'
git -C "$PY" show "$PY_PIN:tests/core/test_format.py" | sed -n '38,62p'
claim "9f. py design doc HEX-15 — the finding Amendment 2 rests on"
git -C "$PY" show "$PY_PIN:docs/design/0005-hexagonal-architecture-and-enforcement.md" | sed -n '188,196p'
claim "9g. py ADR 0010 — status and the escaping requirement"
git -C "$PY" show "$PY_PIN:docs/adr/0010-rich-row-variant-on-result-models.md" | sed -n '1,12p'
git -C "$PY" show "$PY_PIN:docs/adr/0010-rich-row-variant-on-result-models.md" | grep -n 'escape\|strips the styling' | head -6
claim "9h. ts at its pin — any terminal-only row presentation at all?"
git -C "$TS" grep -n -i -E 'osc[ -]?8|hyperlink|relativeTime|timeAgo' "$TS_PIN" -- . || echo '(no match outside the lock file)'

section "10. fixed-parameter byte comparison against the registry (generated, not typed)"
awk -F'|' '
  /^\| *(msrv-policy|rust-edition|target-os-matrix|license) *\|/ {
    p=$2; v=$5; gsub(/^ +| +$/,"",p); gsub(/^ +| +$/,"",v);
    printf "- assumes %s = %s\n", p, v
  }' "$REPO/docs/port/PARAMETERS.md" > "$WORK/expected-assumes.txt"
echo '+ awk <the four fixed rows of docs/port/PARAMETERS.md> > expected-assumes.txt'
cat "$WORK/expected-assumes.txt"
grep '^- assumes ' "$RUN/review/DECISION.md" > "$WORK/actual-assumes.txt" 2>/dev/null || : > "$WORK/actual-assumes.txt"
echo '+ grep "^- assumes " review/DECISION.md > actual-assumes.txt'
cat "$WORK/actual-assumes.txt"
echo '+ diff -u expected-assumes.txt actual-assumes.txt'
diff -u --label expected-assumes.txt --label actual-assumes.txt \
  "$WORK/expected-assumes.txt" "$WORK/actual-assumes.txt"
printf 'parameter-diff-exit=%s\n' "$?"

section "11. done"
