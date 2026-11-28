# rs-launch-blueprint Level 2 task runner (R42, R27, R28, R30, R02, py P11, Blaze §3.3).
# Level 1 base-toolchain bootstrap (`rustup` + `just`) lives in `Makefile`.
# Every tool invocation follows R42: `cargo <sub>` for `cargo-<sub>` executables
# (including rustup components `rustfmt` and `clippy`), bare `<tool>` on PATH
# otherwise, with no provisioner prefix and no Cargo aliases.

package_name := "rs-launch-blueprint"
app_name := "rslbp"

# Single authoritative declared dev-tool table (R42).
# Adding a tool edits this list only; `check-deps` and `setup` read it directly.
cargo_binstall_version := "1.23.0"
cargo_tools := "cargo-deny@0.20.2"
rustup_components := "rustfmt clippy"

# List all available recipes
[group('help')]
@default:
    just --list --unsorted

# ================================
# SETUP & TOOLCHAIN (R42)
# ================================

# Check whether required dev tools and rustup components are installed
[group('setup'), group('debug')]
check-deps:
    #!/usr/bin/env bash
    set -euo pipefail
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
            if ! grep -q "^${comp}-" <<<"$installed_components"; then
                printf 'MISSING %s -> RUN rustup component add %s\n' "$comp" "$comp"
                missing=$((missing + 1))
            fi
        done
    fi
    for spec in {{cargo_tools}}; do
        tool="${spec%@*}"
        if ! command -v "$tool" >/dev/null 2>&1; then
            printf 'MISSING %s -> RUN just install-tool %s\n' "$tool" "$spec"
            missing=$((missing + 1))
        fi
    done
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
    spec="{{spec}}"
    case "$spec" in
        ubi:*)
            if ! command -v ubi >/dev/null 2>&1; then
                just install-tool "ubi@0.12.0"
            fi
            rest="${spec#ubi:}"
            project="${rest%@*}"
            version="${rest#*@}"
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
    echo "[2/4] Installing declared crates.io dev tools..."
    for spec in {{cargo_tools}}; do
        tool="${spec%@*}"
        if ! command -v "$tool" >/dev/null 2>&1; then
            just install-tool "$spec"
        fi
    done
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo "Installing ShellCheck..."
        bash scripts/install-shellcheck.sh
    fi
    echo "[3/4] Installing git hooks..."
    bash scripts/install-hooks.sh
    echo "[4/4] Verifying tool inventory..."
    just check-deps
    echo "Setup complete. Run \`just check\` to verify the workspace."

# ================================
# FORMAT, LINT, TYPECHECK & TEST
# ================================

# Format every Rust source file in the workspace in place (R27)
[group('dev')]
format:
    cargo fmt --all

alias f := format

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

# Run Clippy check-only across workspace targets with feature off and --features web (R28)
[group('dev')]
lint:
    cargo clippy --workspace --all-targets --locked -- -D warnings
    cargo clippy --workspace --all-targets --locked --features web -- -D warnings

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

# Run workspace unit, integration, and doc tests in default and --all-features configurations
[group('test'), group('dev')]
test *options:
    cargo test --workspace --locked {{options}}
    cargo test --workspace --all-features --locked {{options}}

alias t := test

# Enforce workspace dependency bans, advisories, licenses, and sources across all features (R02)
[group('dev')]
deny:
    cargo deny --all-features check

# Check every tracked shell script with ShellCheck
[group('dev')]
check-shell:
    bash scripts/check-shell.sh

# Run all workspace quality gates in parallel (py P11; format-check listed first per R27)
[group('test'), group('dev'), group('quick start')]
[parallel]
@check: format-check lint typecheck test deny check-shell
    echo "All checks passed!"

alias ca := check

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

# Show Blaze version vs. rust-toolchain.toml and probe default workspace compatibility
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
    echo "Probing default workspace (\`blaze check\`)..."
    if blaze check; then
        echo "  default workspace         : PASS"
    else
        echo "  default workspace         : FAIL (fall back to Cargo)" >&2
        exit 1
    fi
    echo ""
    echo "Optional feature policy:"
    echo "  --features web            : Cargo-authoritative while indexable-inc/blaze#598 (utoipa-gen) is open (re-probed in P09)"
    echo "  --features metrics        : Cargo-authoritative while indexable-inc/blaze#1826 (metrics-util) is open (re-probed in P09)"

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
    echo "- just: $(just --version 2>/dev/null || echo 'not found')"
    echo "- shellcheck: $(shellcheck --version 2>/dev/null | sed -n '2p' || echo 'not found')"
    echo "- blaze (optional): $(blaze --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "### Workspace Manifest"
    echo "- Package: {{package_name}}"
    echo "- Primary binary: {{app_name}}"
    echo "- Toolchain file: $(tr '\n' ' ' < rust-toolchain.toml 2>/dev/null || echo 'missing')"
