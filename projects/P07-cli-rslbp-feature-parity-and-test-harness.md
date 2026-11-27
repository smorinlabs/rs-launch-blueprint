# P07 — CLI rslbp feature parity and test harness

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Spec:** [RS implementation roadmap design](../docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md)
- **Plan:** [Rex serial chain contract](../docs/superpowers/plans/2026-11-27-rex-serial-chain-contract.md)
- **Depends on:** P06
- **Prior art:** [R32 test-harness-and-execution](../research/topics/32-test-harness-and-execution/DECISION.md)
- **Prior art:** [R33 property-and-snapshot-testing](../research/topics/33-property-and-snapshot-testing/DECISION.md)
- **Prior art:** [R60 cli-parsing-framework](../research/topics/60-cli-parsing-framework/DECISION.md)
- **Prior art:** [R66 output-format-surface](../research/topics/66-output-format-surface/DECISION.md)

**Status:** `[ ]` scoped, not started.

### Scope
Build the full `rslbp` CLI in `crates/cli` + `src/main.rs` matching `py-launch-blueprint`'s `plbp` contract and org CLI Design Standard, and establish the full Rust test & coverage harness:
- `clap 4.6.6` derive (`derive`, `env`, `wrap_help`), `clap_complete 4.6.9`, and dependency-free `build.rs` shell completions (`R60`).
- Noun-verb commands (`projects list|get|create|delete`, `config show|get|set|path`, `version`, `diagnostics`) with global flags (`-v`/`-q`/`--debug`, `--log-level`, `--log-format`, `--config`, `--no-input`, `--color`, `--no-pager`, `--copy`, `-o table|json|markdown|name`, `--json`, `--output-file`, `--token-file`).
- Rendering & terminal UX: `tabled =0.22.0` + `serde_json` (`R66`), `anstream`/`anstyle` 4-tier color resolution (`R65`), capability-gated OSC-8 hyperlinks & relative timestamps (`R85`), `inquire 0.9.4` behind `Prompter` trait (`OV-02` declined confirm exits 0, `R61`), `indicatif 0.18` spinner (`R63`), `shlex 2.0.1` 2-tier pager (`R64`), `--copy` via `arboard 3.6.1` behind default-on `clipboard` feature (`R62`).
- `anyhow` binary error boundary (`R67`): precedence signal → broken pipe (exit 0 silent on result stream) → domain error JSON/human envelope (`{"error":{"code","message","hint"?}}`, byte-empty stdout) → unexpected crash record sink (`0600` NDJSON under `state_dir()`).
- Test & coverage harness (`R32`, `R33`, `R35`, `R50`): `.config/nextest.toml` (60s timeout, tier selectors, slow/live ignore rules), `assert_cmd` + `predicates` built-binary tests, `proptest 1.11.0` round-trip invariants, `insta 1.48.0` help/output snapshots, `cargo-llvm-cov 0.9.1` (`just coverage`), and `just install-check` smoke recipe (`R50`).

### Out of scope
- Web server (`crates/web`, `rslbp-serve`, `P08`–`P09`)
- GitHub Actions CI & release workflows (`P10`–`P11`)

### Tests & Tasks
- [ ] [P07-TS01] Add `.config/nextest.toml`, `assert_cmd` built-binary tests (exit codes, JSON/text/markdown/name outputs, broken pipe, error envelopes, `--no-input` prompts), `proptest` config/format properties, and `insta` CLI `--help` snapshots (`R32`, `R33`, `R66`, `R67`)
- [ ] [P07-T01] Implement `clap` derive CLI parser, noun-verb subcommands, global flags, and `clap_complete` generation (`R60`)
- [ ] [P07-T02] Implement output renderers (`table`/`json`/`markdown`/`name` with `tabled =0.22.0`, `--output-file`), `anstream`/`anstyle` color chain, and capability-gated OSC-8/relative-time rich rows (`R65`, `R66`, `R85`)
- [ ] [P07-T03] Implement `Prompter` (`inquire`, `OV-02`), `indicatif` spinner, `shlex` pager, and default-on `clipboard` (`arboard`) integration (`R61`–`R64`)
- [ ] [P07-T04] Implement `src/main.rs` `anyhow` error boundary, signal/broken-pipe handling, crash record sink (`R67`), and wire `just test`, `just coverage` (`R35`), and `just install-check` (`R50`)
- [ ] [P07-T05] Verify full suite green via `just test`, `cargo test --doc`, `just coverage`, `just install-check`, and `just blaze-test` on default workspace

### Deliverable
```bash
just check
just test
just coverage
just install-check
just blaze-test
```

### Automated Verification
- `cargo nextest run --workspace` + `cargo test --doc` + `insta` snapshots + `proptest` pass
- `just coverage` generates LLVM coverage report cleanly (`R35`)
- `just install-check` packages `.crate`, extracts, installs into scratch root, and verifies `rslbp --version` (`R50`)
- `just blaze-test` passes on default workspace

### Manual Verification
- Run `rslbp --help`, `rslbp projects list`, and `rslbp projects list --json` in a terminal to confirm colors, table layout, and clean JSON output
