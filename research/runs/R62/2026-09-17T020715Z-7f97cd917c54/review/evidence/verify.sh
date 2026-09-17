#!/bin/bash
# R62 clipboard-integration — decision empirical check (revision 1).
#
# Verifies the claims raw/codex.md, raw/opus.md and review/DECISION.md make.
# It IMPLEMENTS NOTHING: no ClipboardPort trait, no --copy flag, no re-exec
# helper, no template scaffold. The one compiled artefact in this run is the
# throwaway dependency-resolution spike, which lives in its own script
# (spike-build.sh) and writes no Rust beyond a one-line `fn main`.
#
# Two output classes:
#   [<id> PASS|FAIL] <what>   assertions. Reproduce byte-for-byte on rerun.
#   FIGURE <name> = <value>   volatile counters (downloads, stars, pushed_at,
#                             open-issue totals). These CHANGE on rerun by
#                             design; each carries its endpoint and the UTC
#                             retrieval date on the same line.
#   [<id> SKIP] <what>        a check whose input is absent from this
#                             extraction (a sibling repository, or .git after
#                             `git archive HEAD`). Counted separately.
# The comparison rule for an auditor: assertion lines, SKIP lines and section
# structure reproduce byte-for-byte; FIGURE lines and the "retrieved" dates do
# not. `grep -v '^FIGURE ' a.log | grep -v '^Run started'` must diff empty
# against the same filter of a rerun.
#
# Pipelines report their LAST command's status, so `set -o pipefail` is on and
# every check asserts on the CONTENT it expected, never on an exit code alone.
#
# No personal data: every git read uses an explicit --format that omits author
# and committer identity, every gh api read is projected with --jq to named
# scalar fields, and section 13 asserts that this script's own accumulated
# output contains no e-mail address.
#
# Usage:
#   bash verify.sh > r62-clipboard-claims.log 2>&1
# Exit status: the number of FAILed assertions (0 = all assertions held).

# shellcheck disable=SC2016  # backticks inside single-quoted needles are literal
# shellcheck disable=SC2329  # cleanup() is invoked by the EXIT trap
set -uo pipefail

UA='rs-launch-blueprint-research/R62'
AR_TAG=v3.6.1
AR_RAW="https://raw.githubusercontent.com/1Password/arboard/${AR_TAG}"
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
PY_REMOVE=f587e48b41bcf6535ba1b62f348147294911c48d
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
PYREPO="$HOME/c/py-launch-blueprint"
TSREPO="$HOME/c/ts-launch-blueprint"
STD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7
RUN_REL=research/runs/R62/2026-09-17T020715Z-7f97cd917c54
GREP=/usr/bin/grep

# Repository root: walk up from this script to the directory that carries the
# parameter registry, so the script works from any extraction depth.
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd) || exit 99
while [ "$REPO" != / ] && [ ! -f "$REPO/docs/port/PARAMETERS.md" ]; do
	REPO=$(dirname -- "$REPO")
done
[ -f "$REPO/docs/port/PARAMETERS.md" ] || {
	printf 'FATAL: could not locate the repository root from %s\n' "${BASH_SOURCE[0]}"
	exit 99
}
W=$(mktemp -d "${TMPDIR:-/tmp}/r62-evidence.XXXXXX") || exit 99
CAP="$W/captured.txt"
: > "$CAP"
cleanup() { rm -rf "$W"; }
trap cleanup EXIT

TODAY=$(date -u +%Y-%m-%d)
FAILURES=0
ASSERTS=0
SKIPS=0

hr() { printf '\n\n========== %s ==========\n' "$1"; }
sub() { printf '\n--- %s ---\n' "$1"; }

_record() { # id verdict text
	ASSERTS=$((ASSERTS + 1))
	printf '[%s %s] %s\n' "$1" "$2" "$3"
	[ "$2" = PASS ] || FAILURES=$((FAILURES + 1))
}
skip() { # id text
	SKIPS=$((SKIPS + 1))
	printf '[%s SKIP] %s\n' "$1" "$2"
}
figure() { # name value endpoint
	printf 'FIGURE %s = %s  [endpoint %s, retrieved %s]\n' "$1" "$2" "$3" "$TODAY"
}

# assert_has <id> <needle> <file> <what>   -- fixed-string presence
assert_has() {
	if "$GREP" -qF -- "$2" "$3"; then
		_record "$1" PASS "$4"
	else
		_record "$1" FAIL "$4 — expected to find (fixed string): $2"
	fi
}
# assert_re <id> <regex> <file> <what>
assert_re() {
	if "$GREP" -qE -- "$2" "$3"; then
		_record "$1" PASS "$4"
	else
		_record "$1" FAIL "$4 — expected to match (ERE): $2"
	fi
}
# assert_absent <id> <regex> <file> <what>
assert_absent() {
	if "$GREP" -qEi -- "$2" "$3"; then
		_record "$1" FAIL "$4 — did NOT expect a match for (ERE, -i): $2"
	else
		_record "$1" PASS "$4"
	fi
}
# assert_eq <id> <expected> <actual> <what>
assert_eq() {
	if [ "$2" = "$3" ]; then
		_record "$1" PASS "$4 = $3"
	else
		_record "$1" FAIL "$4 — expected [$2], observed [$3]"
	fi
}
# assert_count <id> <expected> <needle> <file> <what>
#   counts with /usr/bin/grep, naming the binary beside the count, over a WHOLE
#   file (never a head-truncated stream).
assert_count() {
	local n
	n=$("$GREP" -cF -- "$3" "$4")
	printf '  [%s -cF] count=%s needle=%s file=%s\n' "$GREP" "$n" "$3" "$(basename "$4")"
	assert_eq "$1" "$2" "$n" "$5"
}

# fetch <url> <outfile> -- prints the HTTP status beside the URL and leaves the
# bare status in the global HTTP_CODE. Never treats curl's own exit code as the
# verdict, and never mixes the printed line into a command substitution.
HTTP_CODE=''
fetch() {
	HTTP_CODE=$(curl -sS -A "$UA" -o "$2" -w '%{http_code}' "$1")
	printf '[HTTP %s] %s\n' "$HTTP_CODE" "$1"
}

# capture <text> -- append to the e-mail-audit buffer (section 13)
capture() { printf '%s\n' "$1" >>"$CAP"; }

##############################################################################
hr "0. Run header, toolchain, and what this script does not do"
##############################################################################
printf 'Run started (UTC): %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'Item            : R62 clipboard-integration (bundle, Focused), revision 1\n'
printf 'Run directory   : %s\n' "$RUN_REL"
printf 'Repository root : %s\n' "$REPO"
printf 'Scratch (removed on exit): %s\n' "$W"
printf 'rustc           : %s\n' "$(rustc --version 2>&1)"
printf 'cargo           : %s\n' "$(cargo --version 2>&1)"
printf 'OS              : %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
printf 'curl            : %s\n' "$(curl --version 2>&1 | head -1)"
printf 'grep (absolute) : %s\n' "$("$GREP" --version 2>&1 | head -1)"
printf 'gh              : %s\n' "$(gh --version 2>&1 | head -1)"
printf '\nNothing is implemented here. The template does not exist; P03 builds it.\n'
printf 'GitHub reads use the authenticated gh CLI; no token and no environment\n'
printf 'is printed by this script.\n'

##############################################################################
hr "1. crates.io registry figures (spec 7.6 table rows 1-3)"
##############################################################################
for c in arboard copypasta clipboard-rs; do
	sub "crates.io: $c"
	fetch "https://crates.io/api/v1/crates/$c" "$W/$c.json"
	code=$HTTP_CODE
	assert_eq "A1$c" "200" "$code" "crates.io metadata endpoint status for $c"
	figure "$c.recent_downloads" "$(jq -r '.crate.recent_downloads' "$W/$c.json")" "https://crates.io/api/v1/crates/$c (.crate.recent_downloads)"
	figure "$c.downloads" "$(jq -r '.crate.downloads' "$W/$c.json")" "https://crates.io/api/v1/crates/$c (.crate.downloads)"
	fetch "https://crates.io/api/v1/crates/$c/versions" "$W/$c-versions.json"
	code=$HTTP_CODE
	assert_eq "A2$c" "200" "$code" "crates.io versions endpoint status for $c"
	newest=$(jq -r '[.versions[] | select(.yanked == false)] | .[0].num' "$W/$c-versions.json")
	created=$(jq -r '[.versions[] | select(.yanked == false)] | .[0].created_at' "$W/$c-versions.json")
	figure "$c.newest_unyanked" "$newest ($created)" "https://crates.io/api/v1/crates/$c/versions (newest yanked:false)"
done

sub "arboard 3.6.1 exists, is not yanked, and declares its licence and MSRV floor"
a361=$(jq -r '[.versions[] | select(.num == "3.6.1")] | length' "$W/arboard-versions.json")
assert_eq A01 "1" "$a361" "arboard 3.6.1 present in the versions endpoint"
assert_eq A02 "false" "$(jq -r '.versions[] | select(.num == "3.6.1") | .yanked' "$W/arboard-versions.json")" "arboard 3.6.1 yanked"
assert_eq A03 "MIT OR Apache-2.0" "$(jq -r '.versions[] | select(.num == "3.6.1") | .license' "$W/arboard-versions.json")" "arboard 3.6.1 declared licence"
assert_eq A04 "1.71.0" "$(jq -r '.versions[] | select(.num == "3.6.1") | .rust_version' "$W/arboard-versions.json")" "arboard 3.6.1 declared rust-version"
assert_eq A05 "2021" "$(jq -r '.versions[] | select(.num == "3.6.1") | .edition' "$W/arboard-versions.json")" "arboard 3.6.1 declared edition (a 2021 crate links into a 2024 workspace; editions are per-crate)"

##############################################################################
hr "2. GitHub repository figures (spec 7.6 table rows 4-6)"
##############################################################################
for r in 1Password/arboard alacritty/copypasta ChurchTao/clipboard-rs; do
	sub "GitHub: $r"
	if gh api "repos/$r" --jq '{s:.stargazers_count,a:.archived,p:.pushed_at}' >"$W/gh.json" 2>"$W/gh.err"; then
		figure "${r}.stargazers_count" "$(jq -r '.s' "$W/gh.json")" "https://api.github.com/repos/$r (.stargazers_count)"
		figure "${r}.pushed_at" "$(jq -r '.p' "$W/gh.json")" "https://api.github.com/repos/$r (.pushed_at)"
		assert_eq "A3${r##*/}" "false" "$(jq -r '.a' "$W/gh.json")" "$r .archived"
	else
		skip "A3${r##*/}" "gh api repos/$r unavailable: $(head -1 "$W/gh.err")"
	fi
	if gh api -X GET search/issues -f "q=repo:$r is:issue is:open" --jq '.total_count' >"$W/oi.txt" 2>/dev/null; then
		figure "${r}.open_issues" "$(cat "$W/oi.txt")" "https://api.github.com/search/issues?q=repo:$r+is:issue+is:open (.total_count, never .open_issues_count)"
	else
		printf 'FIGURE %s.open_issues = unavailable  [endpoint search/issues, retrieved %s]\n' "$r" "$TODAY"
	fi
	sleep 21
done

##############################################################################
hr "3. RustSec advisory status, with the paired positive control"
##############################################################################
printf 'A bare 404 proves nothing on its own. It is zero-advisory evidence only\n'
printf 'because the SAME endpoint returns 200 for anyhow, whose page is backed by\n'
printf 'RUSTSEC-2026-0190, and because the advisory-db contents API agrees\n'
printf 'independently. This is R67 Empirical row E4 applied to this item.\n\n'
for p in arboard copypasta clipboard-rs anyhow; do
	code=$(curl -sS -A "$UA" -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/$p.html")
	printf '[HTTP %s] https://rustsec.org/packages/%s.html\n' "$code" "$p"
	printf '%s' "$code" >"$W/rs-$p.txt"
done
assert_eq A06 "404" "$(cat "$W/rs-arboard.txt")" "rustsec.org package page for arboard"
assert_eq A07 "404" "$(cat "$W/rs-copypasta.txt")" "rustsec.org package page for copypasta"
assert_eq A08 "404" "$(cat "$W/rs-clipboard-rs.txt")" "rustsec.org package page for clipboard-rs"
assert_eq A09 "200" "$(cat "$W/rs-anyhow.txt")" "rustsec.org package page for anyhow (POSITIVE CONTROL — the endpoint works)"

if gh api repos/rustsec/advisory-db/contents/crates/anyhow --jq 'length' >"$W/db-anyhow.txt" 2>/dev/null; then
	ctl=$(cat "$W/db-anyhow.txt")
	if [ "$ctl" -ge 1 ] 2>/dev/null; then
		_record A10 PASS "advisory-db lists $ctl advisory file(s) under crates/anyhow (POSITIVE CONTROL — the API works)"
	else
		_record A10 FAIL "advisory-db control for anyhow returned [$ctl]"
	fi
	for p in arboard copypasta clipboard-rs; do
		if gh api "repos/rustsec/advisory-db/contents/crates/$p" >/dev/null 2>&1; then
			_record "A11$p" FAIL "advisory-db HAS a crates/$p directory — an advisory now exists"
		else
			_record "A11$p" PASS "advisory-db has no crates/$p directory (paired with the anyhow control above)"
		fi
	done
else
	skip A10 "gh api repos/rustsec/advisory-db unavailable; the 404 readings above stand unpaired and prove nothing"
fi

##############################################################################
hr "4. arboard at tag ${AR_TAG} — the source behind every behavioural claim"
##############################################################################
printf 'A tag is immutable, so every read in this section is reproducible.\n'
n=0
for f in Cargo.toml README.md src/lib.rs src/common.rs \
	src/platform/linux/mod.rs src/platform/linux/x11.rs \
	src/platform/linux/wayland.rs .github/workflows/test.yml; do
	n=$((n + 1))
	o="$W/ar-$(printf '%s' "$f" | tr '/' '_')"
	fetch "$AR_RAW/$f" "$o"
	code=$HTTP_CODE
	assert_eq "A4f$n" "200" "$code" "arboard $AR_TAG $f fetched"
done
AR_CARGO="$W/ar-Cargo.toml"
AR_README="$W/ar-README.md"
AR_LIB="$W/ar-src_lib.rs"
AR_COMMON="$W/ar-src_common.rs"
AR_LMOD="$W/ar-src_platform_linux_mod.rs"
AR_X11="$W/ar-src_platform_linux_x11.rs"
AR_WL="$W/ar-src_platform_linux_wayland.rs"
AR_CI="$W/ar-.github_workflows_test.yml"

sub "4a. Manifest: licence, MSRV, features, and where each backend comes from"
assert_has A12 'license = "MIT OR Apache-2.0"' "$AR_CARGO" "arboard declares MIT OR Apache-2.0 (gate 1 is inapplicable by owner ruling 2026-09-12 Q7.B; recorded, not used to exclude)"
assert_has A13 'rust-version = "1.71.0"' "$AR_CARGO" "arboard declares rust-version 1.71.0"
assert_has A14 'default = ["image-data"]' "$AR_CARGO" "arboard's DEFAULT feature set is image-data — so default-features = false is load-bearing, not cosmetic"
assert_has A15 'wayland-data-control = ["wl-clipboard-rs"]' "$AR_CARGO" "wayland-data-control is an opt-in feature that pulls wl-clipboard-rs"
assert_has A16 'wl-clipboard-rs = { version = "0.9.0", optional = true }' "$AR_CARGO" "wl-clipboard-rs is optional and lives under the unix-not-macos target table"
assert_has A17 'x11rb = { version = "0.13" }' "$AR_CARGO" "x11rb is an UNCONDITIONAL unix-not-macos dependency — X11 is the Linux default path"
assert_has A18 'objc2-app-kit = { version = "0.3.0"' "$AR_CARGO" "macOS backend is objc2-app-kit (NSPasteboard), not an external binary"
assert_absent A19 '^tokio|^async-std|futures *=' "$AR_CARGO" "no async-runtime coupling in the manifest (gate 5)"

sub "4b. Error type: what the call site can and cannot rely on"
assert_has A20 '#[non_exhaustive]' "$AR_COMMON" "arboard::Error is #[non_exhaustive] — the adapter must not exhaustively match it"
assert_has A21 'impl std::error::Error for Error {}' "$AR_COMMON" "arboard::Error implements std::error::Error — it composes with thiserror #[source] and anyhow with no adapter code (R67 layering)"
assert_has A22 'Unknown { description: String }' "$AR_COMMON" "the catch-all variant is Unknown { description }"
assert_has A23 'should not be relied on as a' "$AR_COMMON" "arboard's own doc comment forbids relying on the description string to identify an error case at runtime"
assert_absent A24 'Headless|NoDisplay|DisplayUnavailable' "$AR_COMMON" "there is NO dedicated headless variant — headlessness is indistinguishable from any other Clipboard::new failure, so the wrapper must supply its own message"

sub "4c. The headless path: does it return, hang, or panic?"
assert_has A25 'std::env::var_os("WAYLAND_DISPLAY")' "$AR_LMOD" "Linux Clipboard::new tests WAYLAND_DISPLAY first when wayland-data-control is enabled"
assert_has A26 'Ok(Self::X11(x11::Clipboard::new()?))' "$AR_LMOD" "it falls through to X11 — Wayland failure is logged and ignored, not propagated"
assert_has A27 'RustConnection::connect(None).map_err(|_| {' "$AR_X11" "the X11 backend calls x11rb RustConnection::connect(None) and maps ANY error"
assert_has A28 'Error::unknown("X11 server connection timed out because it was unreachable")' "$AR_X11" "the message arboard produces is a TIMEOUT message — inaccurate for a machine that never had a display, which is why the wrapper must not forward it (CLI Design Standard R7.6: name the input, state a next step)"
assert_count A29 0 'panic!("' "$AR_LMOD" "no panic! in the Linux Clipboard::new module path"
assert_has A30 'pub(crate) fn new() -> Result<Self, Error> {' "$AR_LMOD" "Clipboard::new returns Result — it does not abort"

sub "4d. Selection ownership: the finding that decides the stack shape"
assert_has A31 'Clipboard Ownership' "$AR_README" "arboard README has a 'Clipboard Ownership' section"
assert_has A32 'vanish' "$AR_README" "README states that values copied on Linux can vanish before anyone pastes them"
assert_has A33 'you must make sure there is a clipboard manager running' "$AR_README" "README: on exit the data is LOST unless something else is listening"
assert_has A34 'std::thread::spawn(move || {' "$AR_X11" "the X11 backend serves paste requests from a THREAD inside the copying process — a thread dies with exit()"
assert_has A35 'opts.foreground(matches!(wait, WaitConfig::Forever));' "$AR_WL" "the Wayland backend passes foreground only for WaitConfig::Forever — the default path also serves from a thread"
assert_has A36 'pub use platform::{ClearExtLinux, GetExtLinux, LinuxClipboardKind, SetExtLinux};' "$AR_LIB" "SetExtLinux and LinuxClipboardKind are re-exported from the crate root (the API the Linux helper needs)"

sub "4e. arboard's own CI is independent corroboration of the headless verdict"
assert_has A37 'os: [macos-latest, windows-latest, ubuntu-latest]' "$AR_CI" "clippy job runs on all three OSes — the crate COMPILES on ubuntu-latest"
assert_has A38 'No Linux test for now as it just fails due to not having a desktop environment.' "$AR_CI" "the maintainers' own comment: the Linux TEST job is disabled because hosted runners have no desktop environment"
assert_has A39 'os: [macos-latest, windows-latest]' "$AR_CI" "the test matrix is macOS and Windows only — gate 4 passes for BUILD on both fixed OSes and does not pass for a Linux end-to-end test"

##############################################################################
hr "5. wl-clipboard-rs and x11rb — the substrate claims"
##############################################################################
fetch "https://raw.githubusercontent.com/YaLTeR/wl-clipboard-rs/master/src/copy.rs" "$W/wlcr.rs"
code=$HTTP_CODE
assert_eq A40 "200" "$code" "wl-clipboard-rs src/copy.rs fetched"
assert_has A41 'Sets the flag for not spawning a separate thread for serving copy requests.' "$W/wlcr.rs" "wl-clipboard-rs documents foreground as a THREAD switch, not a process switch — the Wayland path does not escape ownership either"
assert_has A42 'potentially past a fork (which is how `wl-copy` uses it)' "$W/wlcr.rs" "wl-copy the BINARY forks; the library called in-process does not — this is exactly why pyperclip/clipboardy never faced this problem"

fetch "https://raw.githubusercontent.com/psychon/x11rb/master/x11rb-protocol/src/errors.rs" "$W/x11rb-errors.rs"
code=$HTTP_CODE
assert_eq A43 "200" "$code" "x11rb errors.rs fetched"
assert_has A44 'DisplayNotSet' "$W/x11rb-errors.rs" "x11rb has a DisplayNotSet parsing error — an unset DISPLAY fails at parse time, before any socket, so there is nothing to block on"

##############################################################################
hr "6. copypasta (the ranked runner-up) — the Ubuntu-test claim"
##############################################################################
fetch "https://raw.githubusercontent.com/alacritty/copypasta/v0.10.2/.github/workflows/ci.yml" "$W/cp-ci.yml"
code=$HTTP_CODE
assert_eq A45 "200" "$code" "copypasta v0.10.2 CI workflow fetched"
assert_has A46 'os: [windows-latest, macos-latest]' "$W/cp-ci.yml" "copypasta's CI matrix is Windows and macOS — it shows no ubuntu-latest job, which is half of this template's fixed target-os-matrix"
assert_absent A47 'ubuntu' "$W/cp-ci.yml" "no ubuntu runner anywhere in copypasta's CI (this settles Codex's comparative claim as fact, not impression)"

##############################################################################
hr "7. Adopters, and the defect in the best available reference implementation"
##############################################################################
sub "7a. Three active projects ship the recommended dependency line"
fetch "https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-command/Cargo.toml" "$W/nu.toml"
code=$HTTP_CODE
assert_eq A48 "200" "$code" "nushell nu-command manifest fetched"
assert_has A49 'arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }' "$W/nu.toml" "nushell ships default-features = false + wayland-data-control verbatim"
fetch "https://raw.githubusercontent.com/nushell/reedline/main/Cargo.toml" "$W/reedline.toml"
code=$HTTP_CODE
assert_eq A50 "200" "$code" "reedline manifest fetched"
assert_has A51 'arboard = { version = "3.3.0", optional = true, default-features = false, features = [' "$W/reedline.toml" "reedline ships the OPTIONAL + feature-gated shape this decision recommends"
assert_has A52 'system_clipboard = ["arboard"]' "$W/reedline.toml" "reedline gates arboard behind a named Cargo feature"
fetch "https://raw.githubusercontent.com/mufeedvh/code2prompt/main/crates/code2prompt/Cargo.toml" "$W/c2p.toml"
code=$HTTP_CODE
assert_eq A53 "200" "$code" "code2prompt manifest fetched"
assert_has A54 'wayland = ["arboard/wayland-data-control"]' "$W/c2p.toml" "code2prompt is a short-lived CLI on the same feature configuration"

sub "7b. code2prompt runs the re-exec pattern — and omits the probe"
fetch "https://raw.githubusercontent.com/mufeedvh/code2prompt/main/crates/code2prompt/src/clipboard.rs" "$W/c2p.rs"
code=$HTTP_CODE
assert_eq A55 "200" "$code" "code2prompt clipboard.rs fetched"
assert_has A56 'pub fn serve_clipboard_daemon() -> Result<()> {' "$W/c2p.rs" "the re-exec'd child entry point exists — the pattern has a maintained production instance"
assert_has A57 '"--clipboard-daemon".to_string()' "$W/c2p.rs" "the child is selected by a hidden flag on the binary's own argv"
assert_has A58 '.stdin(Stdio::piped())' "$W/c2p.rs" "the payload is handed over stdin, not argv (CLI Design Standard R5.6: nothing sensitive in a process listing)"
assert_has A59 '.wait()' "$W/c2p.rs" "the child calls SetExtLinux::wait() so the copy outlives the parent"
# The defect: the PARENT-side spawn function must contain no Clipboard::new probe.
awk '/^pub fn spawn_clipboard_daemon/,/^}/' "$W/c2p.rs" >"$W/c2p-spawn.txt"
assert_has A60 'std::env::current_exe()' "$W/c2p-spawn.txt" "isolated the parent-side spawn_clipboard_daemon body"
assert_count A61 0 'Clipboard::new()' "$W/c2p-spawn.txt" "spawn_clipboard_daemon contains NO Clipboard::new probe — on headless Linux code2prompt spawns a child that dies silently and reports success. This is the defect the recommended probe-before-spawn repairs, and the reason Member 3's exact ordering has no production instance."

sub "7c. The ubuntu-latest image has no clipboard binary — with a positive control"
fetch "https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md" "$W/ubu.md"
code=$HTTP_CODE
assert_eq A62 "200" "$code" "ubuntu-latest (24.04) runner-image readme fetched"
assert_re A63 '[Xx]vfb' "$W/ubu.md" "POSITIVE CONTROL: Xvfb IS listed, so this document does enumerate X-related packages"
assert_absent A64 'xclip' "$W/ubu.md" "xclip is NOT installed on ubuntu-latest"
assert_absent A65 'xsel' "$W/ubu.md" "xsel is NOT installed on ubuntu-latest"
assert_absent A66 'wl-clipboard' "$W/ubu.md" "wl-clipboard is NOT installed on ubuntu-latest — the shell-out alternative would need an apt-get step that arboard does not"
printf 'NOTE: this readme tracks the live runner image and is the one volatile\n'
printf 'document asserted on here. Its three absences are meaningful only with the\n'
printf 'Xvfb presence control on the same fetch, which is why A63 runs beside them.\n'

##############################################################################
hr "8. py-launch-blueprint — the prompt-gloss correction"
##############################################################################
printf 'The prompt Context says "py ships no clipboard integration to compare\n'
printf 'against". At the pin that is true. As a statement about the py precedent it\n'
printf 'is not: py shipped --copy via pyperclip until 2026-06-09. The prompt is\n'
printf 'immutable; this is recorded as a finding, not an edit.\n'
printf 'Reads use --format without author/committer fields — see section 13.\n\n'
if [ -d "$PYREPO/.git" ]; then
	git -C "$PYREPO" show -s --format='commit %H%nauthored %ad%nsubject %s' --date=short "$PY_REMOVE" >"$W/py-commit.txt" 2>&1
	cat "$W/py-commit.txt"
	capture "$(cat "$W/py-commit.txt")"
	assert_has A67 "commit $PY_REMOVE" "$W/py-commit.txt" "the removal commit f587e48 resolves in py-launch-blueprint"
	assert_has A68 '2026-06-09' "$W/py-commit.txt" "its authored date is 2026-06-09"

	git -C "$PYREPO" show --stat --format='' "$PY_REMOVE" >"$W/py-stat.txt" 2>&1
	printf '\n--- git show %s --stat (paths only; --format=%s suppresses identity) ---\n' "$PY_REMOVE" "''"
	cat "$W/py-stat.txt"
	capture "$(cat "$W/py-stat.txt")"
	assert_has A69 'src/py_launch_blueprint/projects.py' "$W/py-stat.txt" "the commit deletes src/py_launch_blueprint/projects.py — the file that held --copy"
	assert_has A70 'pyproject.toml' "$W/py-stat.txt" "and touches pyproject.toml, where the pyperclip dependency lived"

	git -C "$PYREPO" show -s --format='%b' "$PY_REMOVE" >"$W/py-body.txt" 2>&1
	assert_has A71 '--copy' "$W/py-body.txt" "the commit message itself names --copy among the dropped legacy flat-flag features"
	assert_has A72 'no `plbp` equivalent and are dropped' "$W/py-body.txt" "its stated reason is an unported feature of a deleted duplicate CLI — collateral, NOT a judgement against clipboard integration"

	git -C "$PYREPO" show "${PY_REMOVE}^:src/py_launch_blueprint/projects.py" >"$W/py-pre.py" 2>&1
	assert_has A73 'pyperclip.copy(result)' "$W/py-pre.py" "before the removal, py called pyperclip.copy(result) — the capability existed"
	assert_count A74 0 'except pyperclip' "$W/py-pre.py" "the write was UNGUARDED: no pyperclip-specific except arm, so headless failure fell through to the generic handler. py had the capability and got the failure path wrong; ts D-016(7) is the repair; rs inherits the repaired shape."

	if git -C "$PYREPO" cat-file -e "${PY_PIN}^{commit}" 2>/dev/null; then
		git -C "$PYREPO" grep -c -i -e pyperclip "$PY_PIN" -- '*.py' pyproject.toml >"$W/py-pin-hits.txt" 2>&1
		hits=$(wc -l <"$W/py-pin-hits.txt" | tr -d ' ')
		assert_eq A75 "0" "$hits" "pyperclip occurrences in *.py and pyproject.toml AT THE PIN $PY_PIN — the ledger's ts-only origin for F281/F282 is correct as recorded, so NO BASELINE-REVIEW line is emitted"
	else
		skip A75 "py pin $PY_PIN not present in this clone"
	fi
else
	for i in A67 A68 A69 A70 A71 A72 A73 A74 A75; do
		skip "$i" "py-launch-blueprint clone absent at $PYREPO (expected after a bare git archive extraction)"
	done
fi

##############################################################################
hr "9. ts-launch-blueprint at pin ${TS_PIN} — the inherited shape"
##############################################################################
if [ -d "$TSREPO/.git" ]; then
	git -C "$TSREPO" show "${TS_PIN}:src/commands/projects.ts" >"$W/ts-projects.ts" 2>&1
	git -C "$TSREPO" show "${TS_PIN}:src/lib/adapters.ts" >"$W/ts-adapters.ts" 2>&1
	assert_has A76 "--copy', 'copy results to clipboard'" "$W/ts-projects.ts" "ts declares --copy on the result command"
	assert_has A77 'export const realClipboard: ClipboardWriter' "$W/ts-adapters.ts" "ts reaches the OS clipboard through an INJECTED ClipboardWriter port, not a direct call — the seam this decision carries across"
	assert_has A78 'CliError' "$W/ts-projects.ts" "the failure becomes a typed CliError rather than an escaping exception"
else
	for i in A76 A77 A78; do
		skip "$i" "ts-launch-blueprint clone absent at $TSREPO (expected after a bare git archive extraction)"
	done
fi

##############################################################################
hr "10. org CLI Design Standard v1.4.14 (blob ${STD_BLOB:0:8}) — the binding rules"
##############################################################################
if git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 && git -C "$REPO" cat-file -e "$STD_BLOB" 2>/dev/null; then
	git -C "$REPO" cat-file blob "$STD_BLOB" >"$W/cli-std.md"
	printf 'blob %s, %s bytes\n' "$STD_BLOB" "$(wc -c <"$W/cli-std.md" | tr -d ' ')"
	assert_has A79 'A tool **MUST** be fully usable without a TTY.' "$W/cli-std.md" "R8.2 exists"
	assert_has A80 'use exit `1` for runtime input failures such as unreadable files' "$W/cli-std.md" "R8.2 routes a RUNTIME environmental failure to exit 1 — not to the exit-2 'required input or consent missing because prompting is disabled' arm. An absent display server is not missing consent, so R67's RSLB205/2 does not fit and RSLB101/1 does."
	assert_has A81 'Errors **MUST** be written to stderr (R7.1) and **SHOULD** be lowercase-first' "$W/cli-std.md" "R7.6 error-message shape"
	assert_has A82 'name the offending input in quotes, and state a next step where possible' "$W/cli-std.md" "R7.6 requires a next step — which arboard's forwarded 'timed out' message cannot supply"
	assert_has A83 'TTY state **MUST NOT** change the selected output *format*' "$W/cli-std.md" "R7.3 separates presentation niceties from requested behaviour: --copy is a requested action, so it must NOT be gated on IsTerminal"
	assert_has A84 'Progress indicators **MUST** go to stderr' "$W/cli-std.md" "R7.1/R7.4 keep stdout data-clean — the 'copied to clipboard' note belongs on stderr"
	assert_has A85 'R5.6 — Secret redaction in output' "$W/cli-std.md" "R5.6 exists — the reason the Linux helper takes its payload on stdin rather than argv"
else
	for i in A79 A80 A81 A82 A83 A84 A85; do
		skip "$i" "repository .git or blob $STD_BLOB unavailable (expected after a bare git archive extraction)"
	done
fi

##############################################################################
hr "11. This item's own couplings and the parameter registry"
##############################################################################
PROMPT="$REPO/$RUN_REL/inputs/prompt.md"
sub "11a. The prompt's Couplings block, quoted"
sed -n '/^## Couplings/,/^## Questions/p' "$PROMPT" | sed -n '1,12p'
assert_re A86 '^- owns:[[:space:]]*$' "$PROMPT" "the prompt's owns: line is EMPTY — this item registers no parameter, so ## Parameters carries no 'owns' line"
assert_re A87 '^- consumes:[[:space:]]*$' "$PROMPT" "the prompt's consumes: line is EMPTY — R67 is listed as 'related (not a registry dependency)', so only the four fixed parameters are assumed"
assert_has A88 'related (not a registry dependency): R67' "$PROMPT" "R67 is explicitly a related item, not a consumed parameter"

sub "11b. The four fixed rows, compared byte-for-byte between the run inputs and the live registry"
REG="$REPO/docs/port/PARAMETERS.md"
INP="$REPO/$RUN_REL/inputs/PARAMETERS.md"
for p in msrv-policy rust-edition target-os-matrix license; do
	a=$("$GREP" -m1 "^| $p | fixed " "$REG")
	b=$("$GREP" -m1 "^| $p | fixed " "$INP")
	if [ -n "$a" ] && [ "$a" = "$b" ]; then
		_record "A89$p" PASS "registry row for $p is byte-identical between docs/port/PARAMETERS.md and inputs/PARAMETERS.md"
	else
		_record "A89$p" FAIL "registry row for $p differs or is missing — live [$a] vs input [$b]"
	fi
	printf '  value: %s\n' "$(printf '%s' "$a" | awk -F'|' '{v = $5; gsub(/^ +| +$/, "", v); print v}')"
done

sub "11c. The assumes-lines this decision publishes, generated from the registry (never typed)"
awk -F'|' '/^\| (msrv-policy|rust-edition|target-os-matrix|license) \| fixed \|/ {n = $2; v = $5; gsub(/^ +| +$/, "", n); gsub(/^ +| +$/, "", v); printf "- assumes %s = %s\n", n, v}' "$REG" >"$W/assumes.txt"
cat "$W/assumes.txt"
assert_count A90 4 '- assumes ' "$W/assumes.txt" "exactly four assumes lines are generated from the registry"
DEC="$REPO/$RUN_REL/review/DECISION.md"
if [ -f "$DEC" ]; then
	miss=0
	while IFS= read -r line; do
		"$GREP" -qxF -- "$line" "$DEC" || { miss=$((miss + 1)); printf '  MISSING from DECISION.md: %s\n' "$line"; }
	done <"$W/assumes.txt"
	assert_eq A91 "0" "$miss" "assumes lines missing from DECISION.md"
else
	skip A91 "DECISION.md not yet written (expected when this script is run before the decision)"
fi

sub "11d. The F281/F282 ledger rows this decision settles"
"$GREP" -n '^| F28[12] ' "$REPO/docs/port/COMMONALITY.md" >"$W/ledger.txt"
cat "$W/ledger.txt"
assert_count A92 2 '| R62 |' "$W/ledger.txt" "both F281 and F282 name R62 as their item"
assert_count A93 2 '| ts-only | DIVERGENT |' "$W/ledger.txt" "both rows are ts-only / DIVERGENT — the origin the section-8 pin read confirms"

##############################################################################
hr "12. The R67 row this item's failure lands on (published, owner-accepted)"
##############################################################################
R67="$REPO/research/topics/67-error-and-exit-code-contract/DECISION.md"
assert_has A94 'RSLB101` I/O → 1' "$R67" "R67's published catalog maps RSLB101 (I/O) to exit 1 — the row a clipboard-write failure expresses. R62 does NOT own this mapping and does not add a catalog row."
assert_has A95 '{"error":{"code","message","hint"?}}' "$R67" "R67 owns the single-object stderr envelope with an optional hint — the hint is where this item's remedy text goes"
assert_has A96 'thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only' "$R67" "R67's layering rule: typed errors in the library, opaque carrier in the binary — which is why ClipboardError is a thiserror type in the library crate"

##############################################################################
hr "13. Self-audit: no personal data in this script's captured git output"
##############################################################################
printf 'Every git read above used an explicit --format that omits %%an/%%ae/%%cn/%%ce,\n'
printf 'and every gh read was projected to named scalar fields with --jq. This\n'
printf 'asserts the result rather than trusting it.\n\n'
if [ -s "$CAP" ]; then
	printf 'captured git output: %s bytes, %s lines\n' "$(wc -c <"$CAP" | tr -d ' ')" "$(wc -l <"$CAP" | tr -d ' ')"
	assert_absent A97 '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' "$CAP" "no e-mail address in any captured git output"
	assert_absent A98 'Author:|Commit:|Signed-off-by:' "$CAP" "no Author/Commit/Signed-off-by identity line in any captured git output"
else
	skip A97 "no git output was captured (the sibling repositories were absent)"
	skip A98 "no git output was captured (the sibling repositories were absent)"
fi

##############################################################################
hr "14. Summary"
##############################################################################
printf 'assertions run : %s\n' "$ASSERTS"
printf 'failures       : %s\n' "$FAILURES"
printf 'skipped        : %s\n' "$SKIPS"
printf '\nWhat this script did NOT and CANNOT establish here:\n'
printf '  - the observed behaviour of arboard on a headless Linux host. This\n'
printf '    machine is macOS; no headless Linux is available in this session.\n'
printf '    Sections 4c and 4e read the code path and the maintainers own CI\n'
printf '    comment; neither is an execution. P03 runs it on ubuntu-latest.\n'
printf '  - that a copy survives process exit under Xvfb (validation A4).\n'
printf '  - that the probe-before-spawn ordering behaves as designed (A2/A5):\n'
printf '    section 7b proves only that the best production instance omits it.\n'
printf '  - whether GNOME/Mutter implements ext-data-control at the version\n'
printf '    Ubuntu ships. It bounds how often XWayland is the live path on a\n'
printf '    desktop; it changes nothing on ubuntu-latest, which has no\n'
printf '    compositor at all.\n'
printf '\nDependency resolution and the compile check are a separate script:\n'
printf '  spike-build.sh -> r62-spike-build.log\n'
printf '\nexit status = failures = %s\n' "$FAILURES"
exit "$FAILURES"
