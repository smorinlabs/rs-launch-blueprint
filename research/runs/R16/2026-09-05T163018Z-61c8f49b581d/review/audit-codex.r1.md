decision-sha256: 7e25bcea76449edc291109f04a0c282d4a900a0427d77344c1406622c848b665
actor: audit-codex-2026-09-05T163018Z-61c8f49b581d
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: the recommended workflow pins github/codeql-action/init@v4.37.0, which resolves CodeQL 2.26.0, while the dynamic empirical check ran only CodeQL 2.26.4 from v4.37.9

## Rerun

I copied `review/empirical/fixture/` into a fresh temporary directory, excluding its generated `target/` directory. The copy used its committed `.github/codeql/codeql-config.yml` unchanged. The requested bundle archive's SHA-256 was `546ab3318398602ca1861253ea3b772a3f76512476938e8f03a0c0adf07e0ef7`, equal to the published release-asset digest; the reused CLI reports version 2.26.4.

At Rust 1.98.0 and again with `PATH="$(rustup run 1.96.0 rustc --print sysroot)/bin:$PATH"`, I ran `codeql resolve queries` for `rust-code-scanning.qls` and `rust-security-extended.qls`; `codeql database create <db> --language=rust --build-mode=none --source-root=. --codescanning-config=.github/codeql/codeql-config.yml --overwrite`; and `codeql database analyze <db> --format=sarif-latest --output=<sarif> --rerun`. Every database-create and database-analyze command exited 0. The Linux aarch64 Lima copy passed `cargo build --workspace --all-targets` and `cargo test --workspace` at both toolchains; it correctly had no `codeql` command.

The v2.26.4 outputs match the decision: the default and extended suites resolve to 16 and 18 security queries respectively, with `LogInjection.ql` and `AccessAfterLifetime.ql` as the delta. Each configured scan extracted five Rust files and produced the same seven SARIF results: five `rust/access-after-lifetime-ended` results in shipped, nested-workspace, docs/example, and `src` unit-test locations, plus `rust/access-invalid-pointer` and `rust/cleartext-logging` in `src/lib.rs`. No result came from root or nested `tests/` or `benches/`. `actionlint` and the parsed workflow guard also exited 0. Complete output: `review/evidence/audit-codeql-config-customization.log`.

## Findings

1. The empirical claim is not bound to the recommended workflow's version pin. The decision calls 2.26.4 the bundle pinned by `github/codeql-action` v4.37.9 (`review/DECISION.md:7`), but its prescribed Init step pins `github/codeql-action/init@v4.37.0` (`review/DECISION.md:42`). The decision itself records that v4.37.0 resolves 2.26.0 and that 2.26.0 was checked only by static derivation (`review/DECISION.md:106`, `review/DECISION.md:217`). The fresh dynamic rerun likewise executed 2.26.4. This contradicts the statement that the check used the exact CLI of the pinned Action (`review/DECISION.md:125`). Static query metadata cannot establish that the configuration is consumed and analyzed successfully by the shipped action bundle.

2. No further decision-changing defect was observed. The pinned 2.26.4 bundle, configuration, query resolution, path exclusions, MSRV floor, Linux cargo-only leg, workflow syntax, and five cited-source curl checks all succeeded as recorded.

## Assessment

Reject pending reconciliation of the action/bundle version. Either update the inherited workflow pin through its owner to a release that supplies 2.26.4, or dynamically rerun the full configuration check using the bundle supplied by `init@v4.37.0` and revise the decision to state the actual verified version. The present static 2.26.0 comparison may support query-set continuity, but it does not meet the required empirical execution claim.
