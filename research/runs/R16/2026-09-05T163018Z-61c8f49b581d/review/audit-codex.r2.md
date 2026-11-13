decision-sha256: 75fe6f20a06dcafbf8c057e3a6710a0fdc27a04526d04ad3e2bedf12936af979
actor: audit-codex-2026-09-05T163018Z-61c8f49b581d-r2
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: DECISION.md:56 incorrectly says every CodeQL command in this run executed 2.26.4, despite the documented and rerun supplementary 2.26.0 commands

## Rerun

I copied `review/empirical/fixture/` to `/private/tmp/r16-audit-r2.i0yzuH/fixture`, excluding its generated `target/` directory. From that copy I ran the recorded configured `database create` argv with `--language=rust --build-mode=none --source-root=<copy> --codescanning-config=<copy>/.github/codeql/codeql-config.yml --overwrite`, followed by `database analyze <db> --format=sarif-latest --output=<sarif> --rerun`, using `review/empirical/tools/codeql/codeql` (2.26.4) at rustc 1.98.0 and with `PATH="$(rustup run 1.96.0 rustc --print sysroot)/bin:$PATH"` at rustc 1.96.0. Both configured scans exited 0 and produced the recorded five extracted fixture files, 27 Rust rules, and seven results. I repeated that argv with `review/empirical/tools/bundle-2.26.0/codeql/codeql` (2.26.0); its checksum passed and both toolchain legs exited 0 with the recorded six results. `actionlint` plus the local YAML A3 and pin guards passed. The decision's first YAML fence is byte-identical to the fixture configuration (sha256 `cb9e6f6e4e904c0829233064631160db2c57f3592c717d6ea7ffb4862f062734`).

I also ran the cargo-only Lima aarch64 leg from its own temporary fixture copy: `cargo build --workspace --all-targets` and `cargo test --workspace` exited 0 at rustc 1.98.1 and 1.96.0; `codeql` was unavailable there, as the decision records. Five cited primary sources were fetched again: the v4.37.9 defaults, v4.37.9 `src/codeql.ts`, v2.26.4 Rust extractor metadata, v4.37.9 Init override documentation, and v2.27.0 `CommandInjection.ql` metadata. They supported their cited claims. Complete output: `review/evidence/audit-codeql-config-customization-r2.log`. Rerun exit code: 0. The empirical outputs, prescribed/fixture pins, and cited-log claims otherwise match the decision.

## Findings

1. `review/DECISION.md:56` overstates the pin evidence. Its first rationale says `v4.37.9` resolves 2.26.4, “the bundle every CodeQL command in this run and in the auditor's rerun executed.” This is contradicted by the same decision at lines 213–221 and by the independent replay: the supplementary commands executed CodeQL 2.26.0 at both toolchains, yielding six results. The v4.37.9 prescribed and fixture steps do correctly resolve to, and the primary rerun correctly executes, 2.26.4; the false universal claim must be narrowed, for example to the commands intended to validate the v4.37.9 pin.

## Assessment

Revision 2 resolves revision 1's material pin mismatch: all prescribed and fixture `github/codeql-action` steps are at `v4.37.9`, its tagged `src/defaults.json` resolves bundle/CLI 2.26.4, and the primary configured checks execute 2.26.4. The decision also correctly labels the GitHub runner, SARIF upload, CI-guard, fuzz-directory, query-value, wall-clock, and root-glob gaps as P03 work. However, the new universal statement at line 56 claims more than the evidence allows, so this revision cannot be approved until it is corrected.
