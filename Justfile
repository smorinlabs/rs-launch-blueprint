# rs-launch-blueprint Level 2 task runner (R42, R27, R28, R29, R30, R31, R37, R38, R39, R40, R41, R02, py P11, Blaze §3.3).
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
rustup_components := "rustfmt clippy"
cargo_tools := "cargo-deny:cargo-deny@0.20.2 dprint:dprint@0.57.4 ast-grep:ast-grep@0.45.3 committed:committed@1.1.11 typos:typos-cli@1.50.3 ryl:ryl@0.22.0"
ubi_tools := "lefthook:ubi:evilmartians/lefthook@v2.1.14 gitleaks:ubi:gitleaks/gitleaks@v8.30.1 editorconfig-checker:ubi:editorconfig-checker/editorconfig-checker@v4.0.2 actionlint:ubi:rhysd/actionlint@v1.7.12"

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
            if ! grep -q "^${comp}-" <<<"$installed_components"; then
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

# Run all read-only workspace quality gates in parallel (py P11; format-check then check-files first per R27/R29)
[group('test'), group('dev'), group('quick start')]
[parallel]
@check: format-check check-files security check-hygiene check-shell lint typecheck test deny
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
    echo "Optional feature & test policy:"
    echo "  --features web            : Cargo-authoritative while indexable-inc/blaze#598 (utoipa-gen) is open (re-probed in P09)"
    echo "  --features metrics        : Cargo-authoritative while indexable-inc/blaze#1826 (metrics-util) is open (re-probed in P09)"
    echo "  http_adapter_boundary     : Cargo-authoritative while blaze hits async-lock easy_wrapper! macro resolution (use \`just blaze-test -- --skip http_\`)"

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
    echo "- shellcheck: $(shellcheck --version 2>/dev/null | sed -n '2p' || echo 'not found')"
    echo "- blaze (optional): $(blaze --version 2>/dev/null || echo 'not installed')"
    echo ""
    echo "### Workspace Manifest"
    echo "- Package: {{package_name}}"
    echo "- Primary binary: {{app_name}}"
    echo "- Toolchain file: $(tr '\n' ' ' < rust-toolchain.toml 2>/dev/null || echo 'missing')"
