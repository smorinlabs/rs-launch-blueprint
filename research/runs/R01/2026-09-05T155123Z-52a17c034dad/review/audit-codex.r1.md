decision-sha256: 45b2de2a6149a7796db38a30f3daf52cfb69a550af818a137e7ddd9174be4da9
actor: audit-codex-2026-09-05T155123Z-52a17c034dad
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: production-composition-root-not-executed

## Rerun

Fresh copies passed `cargo clean && cargo test --locked && cargo run --locked --quiet -- --in-memory alpha` on macOS with rustc 1.98.0 and 1.96.0, and in the VM-local Linux copy with rustc 1.98.1 and 1.96.0; every `cargo test` run passed 12 checks. The Linux VM has stable 1.98.1 and 1.96.0 installed, not 1.98.0. `cargo fmt --check` and `cargo clippy --locked --all-targets -- -D warnings` passed on macOS 1.98.0. `cargo audit` initially could not lock the sandbox's read-only shared advisory cache; the same command with a temporary copy supplied by `--db` scanned 53 locked dependencies and exited 0. The outputs match the decision's reported test count, CLI JSON, toolchain distinction, and passing quality gates. Full argv, cwd, toolchain output, exits, source searches, and five citation curl checks are in `review/evidence/audit-ports-and-adapters-seam.log`.

## Findings

1. **production-composition-root-not-executed — reject.** The owned value says the composition root erases the *production adapter* into `Arc<dyn ProjectsPort>` and hands that single erased service to the CLI and web layer (`review/DECISION.md:132`). `production_service` is the only code that constructs `HttpProjectsPort` and performs that erasure (`review/empirical/seam_fixture/src/composition.rs:16-18`). No test calls it: the HTTP-contract test constructs `HttpProjectsPort::new(...)` directly after using `build_projects_service` only for the in-memory upstream (`review/empirical/seam_fixture/tests/port_contract.rs:28-33`), the web request path also builds only an in-memory erased service (`review/empirical/seam_fixture/tests/web_request_path.rs:30-32`), and the recorded CLI command selects `--in-memory` (`review/DECISION.md:167-170`). The fixture therefore executes dynamic dispatch at the root for a fake and proves the raw HTTP adapter's contract, but it does not execute the owned production-root route. Add an integration test that starts the fixture listener, builds the client-facing service through `production_service(authority)`, and exercises it via both the CLI-facing service call and the web router. The repaired test must fail if `production_service` stops erasing `HttpProjectsPort` to `Arc<dyn ProjectsPort>`.

## Assessment

The fixture supplies meaningful behavioral evidence beyond compilation: the erased fake is invoked by a live Axum listener through a raw HTTP GET, the generic contract suite runs against three call sites, serde values round-trip, and both negative doctests compile-fail. That proves the trait-object-at-the-root principle for the fake/web route, not merely type-checking. However, it does not fully execute the owned parameter because its production composition-root branch remains compilation-only. The decision must repair the empirical check before acceptance.
