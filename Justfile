# rs-launch-blueprint Level 2 task runner (R42, R27–R35, R37–R41, R50, R02, py P11, Blaze §3.3).
# Level 1 base-toolchain bootstrap (`rustup` + `just`) lives in `Makefile`.
# Every tool invocation follows R42: `cargo <sub>` for `cargo-<sub>` executables
# (including rustup components `rustfmt` and `clippy`), bare `<tool>` on PATH
# otherwise, with no provisioner prefix and no Cargo aliases.

package_name := "rs-launch-blueprint"
app_name := "rslbp"

# Single authoritative declared dev-tool table (R42).
# Format: <executable>:<install-tool spec>
# Adding a tool edits this list only; `check-deps` and `setup` read it directly.
cargo_binstall_version := "1.23.0"
ubi_cli_version := "0.12.0"
lefthook_version := "2.1.14"
committed_version := "1.1.11"
openapi_to_rust_version := "0.17.0"
oasdiff_version := "v1.32.1"
rustup_components := "rustfmt clippy llvm-tools-preview"
cargo_tools := "cargo-deny:cargo-deny@0.20.2 cargo-audit:cargo-audit@0.22.2 cargo-nextest:cargo-nextest@0.9.146 cargo-insta:cargo-insta@1.48.0 cargo-llvm-cov:cargo-llvm-cov@0.9.1 dprint:dprint@0.57.4 ast-grep:ast-grep@0.45.3 committed:committed@1.1.11 typos:typos-cli@1.50.3 ryl:ryl@0.22.0"
ubi_tools := "lefthook:ubi:evilmartians/lefthook@v2.1.14 gitleaks:ubi:gitleaks/gitleaks@v8.30.1 editorconfig-checker:ubi:editorconfig-checker/editorconfig-checker@v4.0.2 actionlint:ubi:rhysd/actionlint@v1.7.12 zizmor:ubi:zizmorcore/zizmor@v1.30.1"

# Coverage floors (LLVM metrics). The ONLY place the threshold values live (R35).
coverage_fail_under := "--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90"

# List all available recipes
[group('help')]
@default:
    just --list --unsorted

# ================================
# SETUP & TOOLCHAIN (R42, R37)
# ================================

# Check whether required dev tools and rustup components are installed
[group('setup'), group('debug')]
check-deps:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    missing=0
    for cmd in rustup cargo just; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf 'MISSING %s -> RUN make bootstrap\n' "$cmd"
            missing=$((missing + 1))
        fi
    done
    if command -v rustup >/dev/null 2>&1; then
        installed_components=$(rustup component list --installed)
        for comp in {{rustup_components}}; do
            prefix="${comp%-preview}"
            if ! grep -q "^${prefix}-" <<<"$installed_components"; then
                printf 'MISSING %s -> RUN rustup component add %s\n' "$comp" "$comp"
                missing=$((missing + 1))
            fi
        done
    fi
    for entry in {{cargo_tools}} {{ubi_tools}}; do
        tool="${entry%%:*}"
        spec="${entry#*:}"
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf 'MISSING %s -> RUN just install-tool %s\n' "$tool" "$spec"
            missing=$((missing + 1))
        fi
    done
    if command -v lefthook >/dev/null 2>&1; then
        got_lh=$(lefthook version 2>/dev/null || true)
        if [ "$got_lh" != "{{lefthook_version}}" ]; then
            printf 'PIN MISMATCH lefthook (got %s, want %s) -> RUN just install-tool ubi:evilmartians/lefthook@v%s\n' "$got_lh" "{{lefthook_version}}" "{{lefthook_version}}"
            missing=$((missing + 1))
        fi
    fi
    if command -v committed >/dev/null 2>&1; then
        got_cm=$(committed --version 2>/dev/null | awk '{print $2}' || true)
        if [ "$got_cm" != "{{committed_version}}" ]; then
            printf 'PIN MISMATCH committed (got %s, want %s) -> RUN just install-tool committed@%s\n' "$got_cm" "{{committed_version}}" "{{committed_version}}"
            missing=$((missing + 1))
        fi
    fi
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf 'MISSING shellcheck -> RUN bash scripts/install-shellcheck.sh\n'
        missing=$((missing + 1))
    fi
    if [ "$missing" -ne 0 ]; then
        exit 1
    fi
    echo "All required tools and rustup components are installed."

alias c := check-deps

# Install a pinned dev tool from crates.io via cargo-binstall (R42) or ubi:<project>@<version>
[group('setup'), group('install')]
install-tool spec:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    spec="{{spec}}"
    case "$spec" in
        ubi:*)
            if ! command -v ubi >/dev/null 2>&1; then
                just install-tool "ubi-cli@{{ubi_cli_version}}"
            fi
            rest="${spec#ubi:}"
            project="${rest%@*}"
            version="${rest#*@}"
            mkdir -p "${HOME}/.local/bin"
            ubi --project "$project" --tag "$version" --in "${HOME}/.local/bin"
            ;;
        *)
            if ! command -v cargo-binstall >/dev/null 2>&1; then
                echo "Installing cargo-binstall@{{cargo_binstall_version}}..."
                cargo install --locked cargo-binstall --version "{{cargo_binstall_version}}"
            fi
            cargo binstall --locked --no-confirm "$spec"
            ;;
    esac

# Assert the pinned lefthook version is on PATH before writing any git hook (R37)
_lefthook-pin:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    if ! command -v lefthook >/dev/null 2>&1 || [ "$(lefthook version 2>/dev/null || true)" != "{{lefthook_version}}" ]; then
        echo "lefthook {{lefthook_version}} required; run: just install-tool ubi:evilmartians/lefthook@v{{lefthook_version}}" >&2
        exit 1
    fi

# Re-wire git hooks via lefthook and set the Conventional Commits template (F145, F159, R37)
[group('setup')]
hooks-install: _lefthook-pin
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    lefthook install
    if [ -f .gitmessage ]; then
        git config commit.template .gitmessage
    fi

# Run the pre-commit hook suite over the whole tree without wiring hooks (F175, R37)
[group('dev'), group('test')]
hooks-run:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    lefthook run pre-commit --all-files --no-auto-install

# Report-only hook-toolchain readiness doctor (F186, R37)
[group('setup'), group('debug')]
hook-check:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v make >/dev/null 2>&1; then
        make --no-print-directory hook-check
    else
        export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
        for tool in lefthook dprint ast-grep committed gitleaks editorconfig-checker ryl typos actionlint shellcheck; do
            if command -v "$tool" >/dev/null 2>&1; then
                printf '[ok] %s\n' "$tool"
            else
                printf '[missing] %s\n' "$tool"
            fi
        done
    fi

# Level 2 project setup — verify base toolchain, install pinned dev tools, and wire git hooks
[group('setup'), group('quick start')]
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v make >/dev/null 2>&1; then
        make --no-print-directory check
    else
        for cmd in rustup cargo just; do
            if ! command -v "$cmd" >/dev/null 2>&1; then
                echo "error: $cmd not found — run \`make bootstrap\` first." >&2
                exit 1
            fi
        done
    fi
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    echo "[1/4] Activating pinned toolchain from rust-toolchain.toml..."
    rustc --version
    echo "[2/4] Installing declared crates.io and release dev tools..."
    for entry in {{cargo_tools}} {{ubi_tools}}; do
        tool="${entry%%:*}"
        spec="${entry#*:}"
        need_install=0
        if ! command -v "$tool" >/dev/null 2>&1; then
            need_install=1
        elif [ "$tool" = "lefthook" ] && [ "$(lefthook version 2>/dev/null || true)" != "{{lefthook_version}}" ]; then
            need_install=1
        elif [ "$tool" = "committed" ] && [ "$(committed --version 2>/dev/null | awk '{print $2}' || true)" != "{{committed_version}}" ]; then
            need_install=1
        fi
        if [ "$need_install" -eq 1 ]; then
            just install-tool "$spec"
        fi
    done
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo "Installing ShellCheck..."
        bash scripts/install-shellcheck.sh
    fi
    echo "[3/4] Installing git hooks and commit template..."
    just hooks-install
    echo "[4/4] Verifying tool inventory..."
    just check-deps
    echo "Setup complete. Run \`just check\` to verify the workspace."

# ================================
# FORMAT, LINT, TYPECHECK, SECURITY & TEST
# ================================

# Format every Rust and non-code file in the repository in place (R27, R29)
[group('dev')]
format:
    cargo fmt --all
    dprint fmt

alias f := format

# Format non-Rust files (TOML, YAML, JSON/JSONC, Markdown) with dprint (R29)
[group('dev')]
format-files:
    dprint fmt

# Check Rust formatting without writing; also fail on ignored rustfmt.toml keys or unreached tracked .rs files (R27)
[group('dev')]
format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    rc=0
    out=$(cargo fmt --all -- --check --verbose 2>&1) || rc=$?
    grep -v -e '^Formatting ' -e '^Using rustfmt config file ' -e '^Spent ' <<<"$out" || true
    if [ "$rc" -ne 0 ]; then
        exit "$rc"
    fi
    if grep -q "can't set" <<<"$out"; then
        echo "error: rustfmt.toml sets a key this toolchain ignores" >&2
        exit 1
    fi
    root=$(pwd -P)
    # Exclude archived P01/P02 research fixtures under research/ (stripped in stamped child repos).
    unreached=$(LC_ALL=C comm -23 \
        <(git ls-files -- '*.rs' ':!research/' | LC_ALL=C sort) \
        <(sed -n "s|^Formatting $root/||p" <<<"$out" | LC_ALL=C sort -u))
    if [ -n "$unreached" ]; then
        printf 'error: tracked .rs files that cargo fmt does not reach:\n%s\n' "$unreached" >&2
        exit 1
    fi

# Check Rust formatting (shorthand alias recipe for format-check)
[group('dev')]
@fmt: format-check

# Check non-Rust file formatting with dprint (R29)
[group('dev')]
check-files:
    dprint check

# Run ast-grep security rule self-tests and full-tree scan with zero-file / zero-rule guards (R31)
[group('dev')]
security:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    ast-grep test --skip-snapshot-tests
    summary=$(ast-grep scan --error --inspect summary 2>&1 >/dev/null) || { ast-grep scan --error; exit 1; }
    files=$(printf '%s\n' "$summary" | sed -n 's/.*scannedFileCount=\([0-9]*\).*/\1/p')
    rules=$(printf '%s\n' "$summary" | sed -n 's/.*effectiveRuleCount=\([0-9]*\).*/\1/p')
    if [ "${files:-0}" -eq 0 ]; then echo "security: scanned 0 files" >&2; exit 1; fi
    if [ "${rules:-0}" -eq 0 ]; then echo "security: loaded 0 rules" >&2; exit 1; fi
    echo "security: ${files} files, ${rules} rules, 0 findings"

# Run auxiliary non-compiling hygiene gates: editorconfig, YAML lint, spell check, workflow lint (R40)
[group('dev')]
check-hygiene:
    editorconfig-checker
    ryl .
    typos
    actionlint

# Check staged blobs against the 1 MiB large-file guard (R14)
[group('dev')]
check-large-files:
    sh scripts/check-large-files.sh --staged

# Check Cargo.lock freshness across every workspace root (R41)
[group('dev')]
check-lockfile:
    bash scripts/check-cargo-lock.sh --all

# Run Clippy check-only across workspace targets with default, --features web, and --all-features (R28)
[group('dev')]
lint:
    cargo clippy --workspace --all-targets --locked -- -D warnings
    cargo clippy --workspace --all-targets --locked --features web -- -D warnings
    cargo clippy --workspace --all-targets --locked --all-features -- -D warnings

alias l := lint

# Apply machine-applicable Clippy fixes on a clean working tree (opt-in, R28)
[group('dev')]
lint-fix:
    cargo clippy --fix --workspace --all-targets

# Type-check every target in both default and --all-features configurations; workspace warnings fail (R30)
[group('dev')]
typecheck:
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going

alias tc := typecheck

# Run workspace unit, integration, and doc tests with cargo-nextest (R32 rev 3; covers web-only and all-features)
[group('test'), group('dev')]
test *options:
    cargo nextest run --locked --workspace --features web {{options}}
    cargo nextest run --locked --workspace --all-features {{options}}
    cargo test --doc --locked --workspace --all-features

alias t := test

# Run ignored slow tests only (R32 M5)
[group('test')]
test-slow:
    cargo nextest run --locked --workspace --features web --run-ignored only -E 'test(/(^|::)slow::/)'

# Run R83 OpenAPI 3.1 contract-fuzzing proptest suite (excluded from default fast run)
[group('test'), group('web')]
test-contract:
    cargo nextest run --locked --workspace --features web --test contract_fuzz --run-ignored all

# Run ignored live tests only (R32 M5)
[group('test')]
test-live:
    cargo nextest run --locked --workspace --features web --run-ignored only -E 'test(/(^|::)live::/)'

# Run all workspace tests including slow, live, and doc tests (R32 rev 3)
[group('test')]
test-all:
    cargo nextest run --locked --workspace --all-features --run-ignored all
    cargo test --doc --locked --workspace --all-features

# One instrumented run, three reports, gate last so the reports exist when it fails (R35).
# Every report line carries --workspace: without it, report measures the root package only.
[group('test'), group('dev')]
coverage:
    cargo llvm-cov clean --workspace
    cargo llvm-cov --no-report --locked --workspace --all-features
    cargo llvm-cov report --workspace --html
    cargo llvm-cov report --workspace --lcov --output-path target/llvm-cov/lcov.info
    cargo llvm-cov report --workspace --show-missing-lines {{coverage_fail_under}}

# Package .crate archives, extract outside the repo, install into a throwaway root, and verify --version (R50)
[group('build'), group('releases')]
install-check mode="":
    #!/usr/bin/env bash
    set -euo pipefail
    mode="{{mode}}"
    if [ -n "$mode" ] && [ "$mode" != "web" ]; then
        echo "usage: just install-check [web]" >&2
        exit 2
    fi
    meta=$(cargo metadata --no-deps --format-version 1)
    ver=$(python3 -c 'import json,sys; m=json.load(sys.stdin); print(next(p["version"] for p in m["packages"] if p["name"]=="rs-launch-blueprint"))' <<<"$meta")
    target_dir=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["target_directory"])' <<<"$meta")
    scratch=$(mktemp -d)
    trap 'rm -rf "$scratch"' EXIT

    cargo package --workspace --locked --no-verify
    for pkg in rs-launch-blueprint-core rs-launch-blueprint-cli rs-launch-blueprint-web rs-launch-blueprint; do
        archive="${target_dir}/package/${pkg}-${ver}.crate"
        test -f "$archive"
        tar -xzf "$archive" -C "$scratch"
    done

    cat > "${scratch}/patch.toml" <<EOF
    [patch.crates-io]
    rs-launch-blueprint-core = { path = "${scratch}/rs-launch-blueprint-core-${ver}" }
    rs-launch-blueprint-cli = { path = "${scratch}/rs-launch-blueprint-cli-${ver}" }
    rs-launch-blueprint-web = { path = "${scratch}/rs-launch-blueprint-web-${ver}" }
    EOF

    install_args=(
        --path "${scratch}/rs-launch-blueprint-${ver}"
        --root "${scratch}/root"
        --locked
        --debug
        --no-track
        --target-dir "${target_dir}/install-check"
        --config "${scratch}/patch.toml"
    )
    if [ "$mode" = "web" ]; then
        install_args+=(--features web)
    fi

    cargo install "${install_args[@]}"

    test -x "${scratch}/root/bin/{{app_name}}"
    got=$("${scratch}/root/bin/{{app_name}}" --version)
    want="{{app_name}} ${ver}"
    if [ "$got" != "$want" ]; then
        echo "install-check: expected '${want}', got '${got}'" >&2
        exit 1
    fi

    if [ "$mode" = "web" ]; then
        test -x "${scratch}/root/bin/{{app_name}}-serve"
        "${scratch}/root/bin/{{app_name}}-serve" --version
    else
        if [ -e "${scratch}/root/bin/{{app_name}}-serve" ]; then
            echo "install-check: web feature gate leaked rslbp-serve into default install" >&2
            exit 1
        fi
    fi
    echo "install-check (${mode:-default}) passed: ${got}"

# Enforce workspace dependency bans, advisories, licenses, and sources across all features (R02)
[group('dev')]
deny:
    cargo deny --all-features check

# Run RustSec advisory audit against Cargo.lock with warnings denied (R13)
[group('dev')]
audit:
    cargo audit --deny warnings

# Check every tracked shell script with ShellCheck
[group('dev')]
check-shell:
    bash scripts/check-shell.sh

# Validate GitHub Actions workflows with actionlint, zizmor, R08 permissions, and R20 SHA-pin comments
[group('dev')]
check-workflows:
    actionlint
    zizmor .github/
    bash scripts/check-workflow-permissions.sh
    bash scripts/check-action-pin-comments.sh

# Run all read-only workspace quality gates in parallel (py P11; format-check then check-files first per R27/R29)
[group('test'), group('dev'), group('quick start')]
[parallel]
@check: format-check check-files security check-hygiene check-shell lint typecheck test deny
    echo "All checks passed!"

alias ca := check

# ================================
# OPTIONAL WEB SERVICE DEV LOOP (R69 F339)
# ================================

# Run the optional web service with bacon live-reload and graceful SIGTERM drain (R69)
[group('web'), group('dev')]
serve:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v bacon >/dev/null 2>&1; then
        echo "bacon not found on PATH — install with \`cargo binstall --locked bacon\` or run \`just serve-once\`" >&2
        exit 1
    fi
    exec bacon --job run-long

# Run the optional web service once via cargo without a file watcher (R69)
[group('web'), group('dev')]
[positional-arguments]
serve-once *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "$#" -gt 0 ]; then
        exec cargo run --features web --bin {{app_name}}-serve -- "$@"
    fi
    exec cargo run --features web --bin {{app_name}}-serve

# ================================
# OPENAPI CONTRACTS, CLIENT GEN & CONTAINER IMAGE (R51, R71, R84)
# ================================

# Regenerate the committed OpenAPI 3.1 contract snapshot at openapi/openapi.json (R71 F332)
[group('web'), group('build')]
export-openapi:
    mkdir -p openapi
    EXPECTORATE=overwrite cargo test --locked --workspace --features web --test openapi openapi_snapshot_is_current

# Verify zero drift between code and committed openapi/openapi.json plus F307/F312 invariants (R71)
[group('web'), group('test')]
check-openapi:
    cargo nextest run --locked --workspace --features web --test openapi

# Compare working openapi/openapi.json against a base ref with oasdiff (R71 F333)
[group('web'), group('test')]
api-breaking base="origin/main":
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v oasdiff >/dev/null 2>&1; then
        echo "oasdiff {{oasdiff_version}} not found on PATH — install from https://github.com/oasdiff/oasdiff/releases/tag/{{oasdiff_version}}" >&2
        exit 1
    fi
    if ! git rev-parse --verify --quiet "{{base}}^{commit}" >/dev/null; then
        echo "error: base ref '{{base}}' does not resolve to a commit (fetch it first or pass a valid ref)" >&2
        exit 1
    fi
    if ! git cat-file -e "{{base}}:openapi/openapi.json" 2>/dev/null; then
        echo "base ref {{base}} has no openapi/openapi.json; this branch introduces the contract"
        exit 0
    fi
    mkdir -p target
    git show "{{base}}:openapi/openapi.json" > target/openapi.base.json
    oasdiff breaking target/openapi.base.json openapi/openapi.json \
        --allow-external-refs=false \
        --fail-on ERR \
        --severity-levels openapi/oasdiff-levels.txt \
        --err-ignore openapi/breaking-accepted.txt

# Generate a standalone typed async Rust client from openapi/openapi.json using pinned openapi-to-rust (R84, OV-11)
[group('web'), group('build')]
generate-client:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v openapi-to-rust >/dev/null 2>&1; then
        echo "openapi-to-rust {{openapi_to_rust_version}} not found on PATH — install with: just install-tool openapi-to-rust@{{openapi_to_rust_version}}" >&2
        exit 1
    fi
    rm -rf clients/rust
    openapi-to-rust generate --config openapi-to-rust.toml --quiet
    printf '%s\n' \
        '[package]' \
        'name = "rs-launch-blueprint-client"' \
        'version = "0.0.0"' \
        'edition = "2024"' \
        'rust-version = "1.98"' \
        'license = "MIT OR Apache-2.0"' \
        'publish = false' \
        '' \
        '[lib]' \
        'path = "src/mod.rs"' \
        '' \
        '[workspace]' \
        '' > clients/rust/Cargo.toml
    sed -n '/^\[dependencies\]/,$p' clients/rust/src/REQUIRED_DEPS.toml >> clients/rust/Cargo.toml
    echo "client written to clients/rust"

alias client-rust := generate-client

# Build the production multi-stage container image for rslbp-serve (R51; GHCR publish via owner 1a-A override in P11)
[group('web'), group('build')]
docker-web tag="rslbp-web:dev":
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v docker >/dev/null 2>&1; then
        echo "docker not found on PATH — install Docker or OrbStack/Colima to build {{tag}}" >&2
        exit 1
    fi
    docker build -t "{{tag}}" .

# ================================
# BLAZE LOCAL ACCELERATOR (OPT-IN)
# ================================

# Fast local edit-loop check on default workspace via Blaze, falling back cleanly to Cargo
[group('blaze')]
blaze-check:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v blaze >/dev/null 2>&1; then
        exec blaze check
    fi
    echo "blaze not found on PATH — falling back to cargo check (install: just install-blaze)" >&2
    exec cargo check --workspace --all-targets --locked

# Fast local edit-loop test on default workspace via Blaze, falling back cleanly to Cargo
[group('blaze')]
[positional-arguments]
blaze-test *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v blaze >/dev/null 2>&1; then
        if [ "$#" -gt 0 ]; then
            exec blaze test "$@"
        fi
        exec blaze test
    fi
    echo "blaze not found on PATH — falling back to cargo test (install: just install-blaze)" >&2
    if [ "$#" -gt 0 ]; then
        exec cargo test --workspace --locked "$@"
    fi
    exec cargo test --workspace --locked

# Fast local run of the rslbp CLI binary via Blaze, falling back cleanly to Cargo
[group('blaze')]
[positional-arguments]
blaze-run *args:
    #!/usr/bin/env bash
    set -euo pipefail
    if command -v blaze >/dev/null 2>&1; then
        if [ "$#" -gt 0 ]; then
            exec blaze run --bin {{app_name}} -- "$@"
        fi
        exec blaze run --bin {{app_name}}
    fi
    echo "blaze not found on PATH — falling back to cargo run (install: just install-blaze)" >&2
    if [ "$#" -gt 0 ]; then
        exec cargo run --bin {{app_name}} -- "$@"
    fi
    exec cargo run --bin {{app_name}}

# Show Blaze version vs. rust-toolchain.toml and probe default + optional feature compatibility (P09)
[group('blaze'), group('debug')]
blaze-status:
    #!/usr/bin/env bash
    set -euo pipefail
    channel=$(sed -n 's/^channel[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' rust-toolchain.toml 2>/dev/null || echo "unknown")
    echo "=== Blaze Local Accelerator Status ==="
    echo "rust-toolchain.toml channel : ${channel} (Cargo-authoritative for CI, MSRV, clippy, rustfmt, releases)"
    if ! command -v blaze >/dev/null 2>&1; then
        echo "blaze                       : not installed (optional; run \`just install-blaze\` for instructions)"
        exit 0
    fi
    blaze_ver=$(blaze --version 2>&1 || echo "unknown")
    echo "blaze                       : ${blaze_ver}"
    echo ""
    probe_blaze() {
        local label="$1"
        shift
        local out rc
        rc=0
        out=$(blaze "$@" 2>&1) || rc=$?
        if [ "$rc" -eq 0 ]; then
            printf '  %-25s : PASS\n' "$label"
        elif grep -q "unknown flag \`--features\`" <<<"$out"; then
            printf '  %-25s : UNSUPPORTED BY CLI (blaze rejects --features; Cargo-authoritative)\n' "$label"
        elif grep -q "crate :: routes" <<<"$out"; then
            printf '  %-25s : BLOCKED (utoipa-axum routes! macro-call-failed in crates/web; Cargo-authoritative)\n' "$label"
        else
            local first_err
            first_err=$(grep -m1 "error" <<<"$out" || printf 'exit %d' "$rc")
            printf '  %-25s : FAIL (%s; fall back to Cargo)\n' "$label" "$first_err"
        fi
    }
    echo "Live compatibility probes:"
    probe_blaze "default workspace" check
    probe_blaze "--features web" check --features web
    probe_blaze "--features metrics" check --features metrics
    probe_blaze "--features otel" check --features otel
    echo ""
    echo "Upstream issue & feature policy (re-probed in P09 on blaze 0.20261127.0):"
    echo "  #598 (utoipa-gen 6.0.1)   : RESOLVED in isolated probe; workspace check still blocked by utoipa-axum 0.3.0 routes! macro"
    echo "  #1826 (metrics-util/prom) : RESOLVED in isolated probe (metrics 0.24.6 + metrics-exporter-prometheus 0.18.3 pass)"
    echo "  otel (0.33 / t-otel 0.34) : PASS in isolated probe; CLI lacks --features so Cargo remains authoritative"
    echo "  core package loop         : \`blaze test -p rs-launch-blueprint-core\` and \`blaze build -p rs-launch-blueprint --bin rslbp\` pass"
    echo "  http_adapter_boundary     : Cargo-authoritative while blaze hits async-lock easy_wrapper! macro resolution"
    echo "  cli binary/insta/proptest : Cargo-authoritative while blaze skips ring C objs and virtualizes CARGO_MANIFEST_DIR"

# Print official Blaze installer instructions and caveats (pass `apply` to run the installer)
[group('blaze'), group('install')]
install-blaze mode="":
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Blaze (https://github.com/indexable-inc/blaze) is an OPTIONAL local edit-loop accelerator."
    echo ""
    echo "Official installer:"
    echo "  curl -fsSL https://ix.dev/blaze | sh"
    echo ""
    echo "Caveats:"
    echo "  - Supported platforms: macOS Apple Silicon (arm64) and Linux (x86_64 / arm64, glibc >= 2.34)."
    echo "  - Builds with Blaze's own pinned nightly toolchain (ignores rust-toolchain.toml and MSRV)."
    echo "  - Cargo remains authoritative for CI, MSRV, clippy, rustfmt, coverage, deny, and releases."
    echo "  - Optional web/metrics features stay on Cargo while upstream #598 and #1826 remain open."
    if [ "{{mode}}" = "apply" ] || [ "{{mode}}" = "--apply" ]; then
        echo ""
        echo "Running official Blaze installer..."
        curl -fsSL https://ix.dev/blaze | sh
        if [ ! -d "${BLAZE_HOME:-$HOME/.blaze}/v2/toolchain" ]; then
            echo ""
            echo "Note: upstream indexable-inc/blaze#2465 — if \`blaze check\` reports a missing" >&2
            echo "toolchain manifest under ~/.blaze/v2/toolchain, extract the \`toolchain/\`" >&2
            echo "directory from the matching release tarball into ~/.blaze/v2/toolchain/." >&2
        fi
    else
        echo ""
        echo "Run \`just install-blaze apply\` to execute the installer directly."
    fi

# ================================
# DEBUG & DIAGNOSTICS
# ================================

# Collect system, toolchain, and workspace information for debugging
[group('debug')]
debug-info:
    #!/usr/bin/env bash
    set -euo pipefail
    export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"
    echo "## Debug Information"
    echo ""
    echo "### System"
    echo "- Date: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "- OS: $(uname -s) $(uname -r)"
    echo "- Arch: $(uname -m)"
    echo "- Git branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')"
    echo ""
    echo "### Rust & Dev Tools"
    echo "- rustc: $(rustc --version 2>/dev/null || echo 'not found')"
    echo "- cargo: $(cargo --version 2>/dev/null || echo 'not found')"
    echo "- active toolchain: $(rustup show active-toolchain 2>/dev/null || echo 'not found')"
    echo "- clippy: $(cargo clippy --version 2>/dev/null || echo 'not found')"
    echo "- rustfmt: $(cargo fmt --version 2>/dev/null || echo 'not found')"
    echo "- cargo-deny: $(cargo deny --version 2>/dev/null || echo 'not found')"
    echo "- cargo-audit: $(cargo audit --version 2>/dev/null || echo 'not found')"
    echo "- cargo-nextest: $(cargo nextest --version 2>/dev/null | head -n 1 || echo 'not found')"
    echo "- cargo-insta: $(cargo insta --version 2>/dev/null || echo 'not found')"
    echo "- cargo-llvm-cov: $(cargo llvm-cov --version 2>/dev/null || echo 'not found')"
    echo "- just: $(just --version 2>/dev/null || echo 'not found')"
    echo "- lefthook: $(lefthook version 2>/dev/null || echo 'not found')"
    echo "- dprint: $(dprint --version 2>/dev/null || echo 'not found')"
    echo "- ast-grep: $(ast-grep --version 2>/dev/null || echo 'not found')"
    echo "- committed: $(committed --version 2>/dev/null || echo 'not found')"
    echo "- gitleaks: $(gitleaks --version 2>/dev/null || echo 'not found')"
    echo "- editorconfig-checker: $(editorconfig-checker --version 2>/dev/null || echo 'not found')"
    echo "- ryl: $(ryl --version 2>/dev/null || echo 'not found')"
    echo "- typos: $(typos --version 2>/dev/null || echo 'not found')"
    echo "- actionlint: $(actionlint --version 2>/dev/null | head -n 1 || echo 'not found')"
    echo "- zizmor: $(zizmor --version 2>/dev/null || echo 'not found')"
    echo "- shellcheck: $(shellcheck --version 2>/dev/null | sed -n '2p' || echo 'not found')"
    echo "- blaze (optional): $(blaze --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "### Workspace Manifest"
    echo "- Package: {{package_name}}"
    echo "- Primary binary: {{app_name}}"
    echo "- Toolchain file: $(tr '\n' ' ' < rust-toolchain.toml 2>/dev/null || echo 'missing')"
