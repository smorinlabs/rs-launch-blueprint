#!/usr/bin/env bash
# R69 evidence, the assertion script. Every figure, gate answer and
# published-artifact fact this decision cites is asserted here, on CONTENT.
#
# Two input sets, treated differently on purpose:
#  * review/evidence/snapshots/ -- reduced crates.io / GitHub / RustSec figures,
#    COMMITTED, refreshed only by fetch-figures.sh. Download counters and
#    pushed_at move hourly, so reading a frozen snapshot is what lets this log
#    reproduce byte-for-byte.
#  * review/evidence/sources/  -- upstream files read at an immutable version,
#    tag or commit. NOT committed (third-party source, one of it AGPL-3.0), and
#    fetched automatically below when absent, since an immutable coordinate
#    re-fetches identically.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../evidence/snapshots"
SRC="$HERE/../evidence/sources"
rc=0; pass=0; fail=0
ok()  { echo "OK   $*"; pass=$((pass+1)); }
bad() { echo "FAIL $*"; fail=$((fail+1)); }
eq()  { [ "$2" = "$3" ] && ok "$1 = $2" || bad "$1: expected '$2', got '$3'"; }

[ -d "$S" ] || { echo "FAIL: no snapshots. Run fetch-figures.sh first."; exit 1; }
if [ ! -f "$SRC/cratesio-router.rs" ] || [ ! -d "$SRC/artifacts/axum-0.8.9" ]; then
  echo "sources absent -- fetching them (immutable coordinates, so this reproduces)"
  bash "$HERE/fetch-sources.sh" >/dev/null 2>&1 || { echo "FAIL: fetch-sources.sh failed"; exit 1; }
fi

cv()   { jq -r --arg f "$2" 'if has($f) and (.[$f] != null) then (.[$f]|tostring) else "null" end' "$S/crate-$1.json"; }
nv()   { jq -r --arg f "$2" '.newest_non_yanked | if has($f) and (.[$f] != null) then (.[$f]|tostring) else "null" end' "$S/crate-$1.json"; }
repo() { jq -r --arg f "$2" 'if has($f) and (.[$f] != null) then (.[$f]|tostring) else "null" end' "$S/gh-repo-$1.json"; }
iss()  { jq -r '.open_issues' "$S/gh-issues-$1.json"; }
sec()  { jq -r --arg f "$2" '.[$f]|tostring' "$S/rustsec-$1.json"; }

echo "snapshot $(cat "$S/RETRIEVED-AT.txt")"
echo "field rules (prompt, Required evidence): crates.io crate.recent_downloads"
echo "and crate.downloads; the newest non-yanked /versions entry for num,"
echo "created_at, rust_version and license; the GitHub repos endpoint for"
echo "stargazers_count, archived and pushed_at; the search endpoint's"
echo "total_count for open issues, never open_issues_count."
echo
echo "GATE 1 (licence compatibility) IS NOT ASSERTED ANYWHERE IN THIS SCRIPT."
echo "Owner ruling 2026-09-12 (Q7.B) makes it inapplicable to every dependency"
echo "and tool. Licences are printed below as published metadata, not as a gate."

echo; echo "### A. the three recommended compiled members"
eq "axum newest non-yanked"  "0.8.9"  "$(nv axum num)"
eq "axum rust_version"       "1.80"   "$(nv axum rust_version)"
eq "axum archived"           "false"  "$(repo axum archived)"
eq "tokio newest non-yanked" "1.53.1" "$(nv tokio num)"
eq "tokio rust_version"      "1.71"   "$(nv tokio rust_version)"
eq "tokio archived"          "false"  "$(repo tokio archived)"
eq "tower newest non-yanked" "0.5.3"  "$(nv tower num)"
eq "tower rust_version"      "1.64.0" "$(nv tower rust_version)"
for c in axum tokio tower; do
  printf '  %-6s 90-day=%s all-time=%s released=%s stars=%s pushed=%s open-issues=%s licence=%s\n' \
    "$c" "$(cv $c recent_downloads)" "$(cv $c downloads)" "$(nv $c created_at)" \
    "$(repo $c stargazers_count)" "$(repo $c pushed_at)" "$(iss $c)" "$(nv $c license)"
done
echo "  reverse dependencies: axum $(jq -r .reverse_dependencies "$S/revdeps-axum.json"), tokio $(jq -r .reverse_dependencies "$S/revdeps-tokio.json")"

echo; echo "### B. the dev-reload sub-field -- the one answer the licence ruling changes"
eq "bacon newest non-yanked"                       "3.25.0"     "$(nv bacon num)"
eq "bacon rust_version (gate 2: PASS)"             "1.85"       "$(nv bacon rust_version)"
eq "bacon archived"                                "false"      "$(repo bacon archived)"
eq "bacon licence (reported, NOT gated)"           "AGPL-3.0"   "$(nv bacon license)"
eq "watchexec-cli newest non-yanked"               "2.7.2"      "$(nv watchexec-cli num)"
eq "watchexec-cli rust_version (gate 2: FAIL, none declared)" "null" "$(nv watchexec-cli rust_version)"
eq "cargo-watch newest non-yanked"                 "8.5.3"      "$(nv cargo-watch num)"
eq "cargo-watch rust_version (gate 2: PASS -- it is excluded on MAINTENANCE, not a gate)" "1.75.0" "$(nv cargo-watch rust_version)"
eq "cargo-watch archived (the maintenance exclusion)" "true"    "$(repo cargo-watch archived)"
grep -q 'life support' "$SRC/cargo-watch-README.md" \
  && ok "cargo-watch README at tag v8.5.3 carries the maintainer's own end-of-life notice" \
  || bad "cargo-watch end-of-life notice not found in the pinned README"
grep -q 'Bacon' "$SRC/cargo-watch-README.md" \
  && ok "that notice names Bacon as a recommended successor" \
  || bad "successor recommendation not found in the pinned README"
for c in bacon watchexec-cli cargo-watch; do
  printf '  %-13s 90-day=%s all-time=%s released=%s licence=%s\n' \
    "$c" "$(cv $c recent_downloads)" "$(cv $c downloads)" "$(nv $c created_at)" "$(nv $c license)"
done
printf '  repos: bacon stars=%s pushed=%s issues=%s | watchexec stars=%s pushed=%s issues=%s | cargo-watch stars=%s pushed=%s\n' \
  "$(repo bacon stargazers_count)" "$(repo bacon pushed_at)" "$(iss bacon)" \
  "$(repo watchexec stargazers_count)" "$(repo watchexec pushed_at)" "$(iss watchexec)" \
  "$(repo cargo-watch stargazers_count)" "$(repo cargo-watch pushed_at)"
echo "  bacon CI runners (Canop/bacon .github/workflows/tests.yml @ tag v3.25.0):"
grep -E 'runs-on' "$SRC/ci-bacon-v3.25.0.yml" | sed 's/^/     /'
grep -qi 'macos' "$SRC/ci-bacon-v3.25.0.yml" \
  && bad "bacon CI unexpectedly names a macOS runner" \
  || ok "bacon CI names no macOS runner -- gate 4's macOS leg is closed instead by the executed cargo install in bacon-install-check.log"

echo; echo "### C. framework candidates -- gate 2 (declared MSRV), answered before popularity"
echo "    floor = 1.96 (stable 1.98.x minus two minors)"
for c in actix-web warp poem salvo rocket ntex xitca-web pavex viz tide loco-rs dropshot; do
  printf '  %-12s newest=%-18s released=%-28s rust_version=%-8s licence=%s\n' \
    "$c" "$(nv $c num)" "$(nv $c created_at)" "$(nv $c rust_version)" "$(nv $c license)"
done
for c in warp viz pavex tide; do eq "$c declares no rust_version (gate 2 FAIL)" "null" "$(nv $c rust_version)"; done
eq "xitca-web rust_version is above the 1.96 floor (gate 2 FAIL)" "1.98" "$(nv xitca-web rust_version)"
eq "actix-web rust_version (gate 2 pass; excluded on fit)"        "1.88" "$(nv actix-web rust_version)"
eq "salvo rust_version (gate 2 pass; excluded on MSRV-policy fit)" "1.94" "$(nv salvo rust_version)"
eq "poem rust_version (gate 2 pass; excluded on maintenance)"      "1.85" "$(nv poem rust_version)"
echo "  rocket MSRV: the gemini raw says 1.89.0, the opus raw says 1.64 -- the registry settles it:"
eq "rocket rust_version"                                           "1.64" "$(nv rocket rust_version)"
echo "  rocket last release $(nv rocket created_at), repo pushed_at $(repo rocket pushed_at) -- the maintenance exclusion"
echo "  poem   last release $(nv poem created_at), repo pushed_at $(repo poem pushed_at), open issues $(iss poem)"
echo "  ntex   newest non-yanked is a prerelease: $(nv ntex num) -- the opus raw cited 3.12.3 / 1.88"
echo "  tide   newest non-yanked is $(nv tide num) ($(nv tide created_at)) -- the opus raw cited 0.16.0 (2021-01-29)"

echo; echo "### D. gate 3, advisories (RustSec package pages)"
for c in axum tower bacon watchexec-cli; do
  eq "rustsec/packages/$c.html status (404 = no advisory)" "404" "$(sec $c http_status)"
done
for c in tokio hyper; do
  eq "rustsec/packages/$c.html status (page exists)" "200" "$(sec $c http_status)"
  echo "    historic advisory ids listed: $(jq -r '.advisories_listed | join(" ")' "$S/rustsec-$c.json")"
done
echo "  the decisive check is executed, not read: cargo audit over the resolved"
echo "  --features web lockfile is check 8 of feature-shape-check.log."

echo; echo "### E. gate 4, platform CI read from the upstream workflow at each pinned tag"
echo "  axum  (tag axum-v0.8.9):  $(grep -oE 'runs-on: [^ ]+' "$SRC/ci-axum-v0.8.9.yml" | sort -u | tr '\n' ' ')"
grep -qi 'macos' "$SRC/ci-axum-v0.8.9.yml" \
  && bad "axum CI unexpectedly names a macOS runner" \
  || ok "axum CI names no macOS runner -- a gate 4 gap, closed for this version only by this run's macOS resolve-and-build"
echo "  tokio (tag tokio-1.53.1): $(grep -oE '(ubuntu|macos|windows)-latest' "$SRC/ci-tokio-1.53.1.yml" | sort -u | tr '\n' ' ')"
for os in ubuntu-latest macos-latest; do
  grep -q "$os" "$SRC/ci-tokio-1.53.1.yml" && ok "tokio CI covers $os" || bad "tokio CI does not cover $os"
done

echo; echo "### F. the reference implementation, rust-lang/crates.io at commit 3df99c2"
grep -qE 'axum = \{ version = "=0\.8\.9"'  "$SRC/cratesio-Cargo.toml" && ok "pins axum =0.8.9"  || bad "axum pin not found"
grep -qE 'tokio = \{ version = "=1\.53\.1"' "$SRC/cratesio-Cargo.toml" && ok "pins tokio =1.53.1" || bad "tokio pin not found"
grep -qE 'edition = "2024"'                 "$SRC/cratesio-Cargo.toml" && ok "uses edition 2024, this template's fixed rust-edition" || bad "edition not found"
grep -q 'with_state(state)' "$SRC/cratesio-router.rs" \
  && ok "builds its router with .with_state(state) -- the F330 mechanism" || bad "with_state not found"
grep -qE 'for (router|r) in|ROUTERS' "$SRC/cratesio-router.rs" \
  && bad "router.rs appears to iterate a registry after all -- the F331 finding would not hold" \
  || ok "router.rs has no ROUTERS registry and no registration loop -- the F331 finding holds"
grep -q 'with_graceful_shutdown' "$SRC/cratesio-server.rs" && ok "serves with axum::serve(..).with_graceful_shutdown(..)" || bad "with_graceful_shutdown not found"
grep -q 'SignalKind::terminate' "$SRC/cratesio-server.rs" && ok "selects over SIGTERM via tokio::signal::unix" || bad "SIGTERM handling not found"
grep -qE '^\s*\.with_graceful_shutdown\(shutdown_signal\(\)\)' "$SRC/cratesio-server.rs" \
  && grep -qE '^\s*\.await$' "$SRC/cratesio-server.rs" \
  && ok "awaits the serve future directly -- the drain is NOT wrapped in a timeout" \
  || bad "the drain call site does not have the expected unwrapped shape"
grep -q 'Duration::from_secs(secs)' "$SRC/cratesio-server.rs" \
  && ok "the only Duration in that file is a metrics logging interval, not a drain deadline" \
  || bad "unexpected Duration use in crates.io server.rs"
grep -q 'SignalKind::terminate' "$SRC/axum-graceful-shutdown-example.rs" \
  && ok "axum's own graceful-shutdown example at tag axum-v0.8.9 also handles SIGTERM" || bad "axum example SIGTERM not found"

echo; echo "### G. published-artifact facts this decision rests on"
A="$SRC/artifacts/axum-0.8.9"; T="$SRC/artifacts/tokio-1.53.1"
B="$SRC/artifacts/bacon-3.25.0"; W="$SRC/artifacts/watchexec-cli-2.7.2"
grep -q 'S: Clone + Send + Sync' "$A/src/routing/mod.rs" \
  && ok "axum's state-carrying impl<S> Router<S> is bounded S: Clone + Send + Sync + 'static" \
  || bad "axum state bound not found where expected"
grep -q 'pub fn with_state<S2>' "$A/src/routing/mod.rs" \
  && ok "with_state is what turns a Router<S> into a Router<S2> -- no state, no service" || bad "with_state signature not found"
grep -q 'you can use \[`FromRef`\] to extract "substates"' "$A/src/extract/state.rs" \
  && ok "axum documents FromRef substates on one State type" || bad "FromRef substate doc not found"
grep -q 'close_tx.closed().await' "$A/src/serve/mod.rs" \
  && ok "the graceful drain awaits close_tx.closed()" || bad "drain await not found"
eq "occurrences of 'timeout' or 'deadline' in axum src/serve/mod.rs (the drain is unbounded)" \
   "0" "$(grep -ciE '\btimeout\b|\bdeadline\b' "$A/src/serve/mod.rs")"
grep -q '#\[cfg(all(feature = "tokio", any(feature = "http1", feature = "http2")))\]' "$A/src/serve/mod.rs" \
  && ok "axum::serve exists only with the tokio feature plus http1 or http2" || bad "serve cfg not found"
grep -q 'unsafe_code = "forbid"' "$A/Cargo.toml" && ok "axum declares [lints.rust] unsafe_code = \"forbid\"" || bad "axum unsafe lint not found"
eq "occurrences of 'unsafe' in axum src/" "0" \
   "$(grep -rEc '\bunsafe\b' "$A/src" 2>/dev/null | awk -F: '{s+=$2} END{print s+0}')"
echo "  axum default features: $(sed -n '/^default = \[/,/^\]/p' "$A/Cargo.toml" | tr -d ' "\n' | sed 's/default=\[//; s/,\]//')"
grep -q '^default = \[\]' "$T/Cargo.toml" && ok "tokio default = [] -- every feature is opted into explicitly" || bad "tokio default not empty"
# The correct drain deadline starts its clock at the signal, which needs
# tokio::sync::oneshot. Is `sync` implied by any feature already selected?
for f in signal net rt-multi-thread time macros; do
  awk -v f="$f" '$0 ~ "^"f" = \\[" {p=1} p {print} p && /\]/ {exit}' "$T/Cargo.toml" | grep -q '"sync"' \
    && bad "tokio feature '$f' enables sync (the feature list could then omit it)" \
    || ok "tokio feature '$f' does NOT enable sync"
done
grep -qE '^sync = \[\]' "$T/Cargo.toml" && ok "tokio 'sync' is its own leaf feature, so it must be listed explicitly" || bad "tokio sync feature shape unexpected"
eq "bacon declared rust-version in its published manifest" "1.85" "$(grep -m1 '^rust-version' "$B/Cargo.toml" | sed 's/.*= *"//; s/"//')"
eq "watchexec-cli rust-version lines in its published manifest (gate 2 FAIL)" "0" "$(grep -c '^rust-version' "$W/Cargo.toml")"
grep -q 'on_change_strategy = "kill_then_restart"' "$B/defaults/default-bacon.toml" \
  && ok "bacon ships a run-long job that restarts on change (kill_then_restart)" || bad "run-long strategy not found"
grep -q 'need_stdout = true' "$B/defaults/default-bacon.toml" \
  && ok "that job captures the child's stdout" || bad "need_stdout not found"
grep -q 'SIGKILL' "$B/website/src/config.md" \
  && ok "bacon's DEFAULT job interruption on unix is SIGKILL -- so a bacon.toml 'kill' override is required for a dev restart to run the production drain" \
  || bad "bacon's SIGKILL default not documented where expected"
grep -q 'CommandStream::StdOut => print!' "$B/src/tui/app.rs" \
  && ok "in --headless mode bacon prints the child's stdout/stderr straight to the terminal, not into a TUI pane" \
  || bad "bacon headless passthrough not found"
grep -q 'command.arg("--features")' "$B/src/mission.rs" \
  && ok "bacon plumbs its --features flag into the cargo command" || bad "bacon --features plumbing not found"
grep -q 'tokens.chain(&self.settings.additional_job_args)' "$B/src/mission.rs" \
  && ok "arguments after -- are appended to the job's command tokens" || bad "additional_job_args plumbing not found"

echo; echo "### H. control -- an assertion that MUST report FAIL, proving these checks can fail"
eq "deliberate control (expected to FAIL)" "0.0.0-not-a-real-version" "$(nv axum num)"
echo "  -> the line above must read FAIL. If it reads OK, the harness is broken"
echo "     and every OK above is worthless."
expected_ctl=1
[ "$fail" -eq "$expected_ctl" ] || rc=1
echo
echo "assertions passed: $pass   failures: $fail (exactly $expected_ctl expected: the control)"
echo "assert-figures rc=$rc"
exit $rc
