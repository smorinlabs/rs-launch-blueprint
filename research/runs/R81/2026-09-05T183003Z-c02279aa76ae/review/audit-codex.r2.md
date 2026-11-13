decision-sha256: 5ab7479c7d5e0485fa1c05aef9a894f4c36b56de3692bef89c17efc33a09404e
actor: audit-codex-2026-09-05T183003Z-c02279aa76ae-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/docs-delivery-claims.sh`
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R81/2026-09-05T183003Z-c02279aa76ae`, a Git worktree. Check 12 read revision-1 blob `f098d011723244c43e9673ce9633ce562829681d` successfully and verified its SHA-256 `204949689ccc0c3190c2479ca80d5c18f9fd9753931cffcf78706190d75ff21d`.
- toolchain: macOS 26.4; Darwin 25.4.0 arm64; `rustc 1.98.0`; `cargo 1.98.0`; `gh 2.98.0`. `/opt/homebrew/bin/limactl` was callable, but `limactl shell ubuntu -- ...` could not run because the `ubuntu` instance is stopped; its output directed `limactl start ubuntu`. No VM was started, so the recorded reruns are macOS reruns.
- exit: 0 on each of two reruns; 92 `PASS` lines plus 8 gated `ASSERT ...=True` lines, for 100 failure gates; 0 `FAIL` lines and `failed assertions: 0`.
- log: `review/evidence/audit-docs-delivery-model-r2.log`.
- match: yes. The two reruns are byte-identical, and each is byte-identical to `review/evidence/docs-delivery-claims.log`; all have SHA-256 `2da86bff14dde7678e93bd642e9219ca90ef26e4f5f6bf26234556c3c3975216`.

## Findings

None. The four revision-1 findings are corrected and reproduced.

1. **Licence walk.** Check 8 reports equal 218-entry lock and snapshot key sets, and its live 16-package sample matches the snapshot. It prints and asserts exactly these four conjunctions: `elasticlunr-rs 3.1.0 = (MIT OR Apache-2.0) AND MIT`; `font-awesome-as-a-crate 0.3.1 = CC-BY-4.0 AND MIT`; `matchit 0.8.4 = MIT AND BSD-3-Clause`; and `unicode-ident 1.0.24 = (MIT OR Apache-2.0) AND Unicode-3.0`. The asserted partition is `218 = 8 + 4 + 2 + 8 + 196`. `DECISION.md:116-139` distinguishes the three notice-retention conjunctions from Font Awesome's content-attribution licence; restricts that attribution question to branch-A assets if the default theme emits them; and separately states that none of the 218 packages is linked into the template. The corpus is unconditionally decided while the generator remains branch-conditional (`DECISION.md:33-39`, `:131-139`).
2. **Release assets.** Check 11 queries `GET /repos/rust-lang/mdBook/releases/tags/v0.5.4`, asserts all six assets by name, and asserts zero `aarch64-unknown-linux-gnu` assets. `DECISION.md:324-342` maps Linux x86_64 glibc and musl, Linux aarch64 musl only, macOS x86_64 and aarch64, and Windows x86_64; it does not imply the absent glibc aarch64 variant.
3. **Branch delta.** The complete four-item branch-A delta, including all four `justfile` recipes, appears at all three transition descriptions: `DECISION.md:51-59`, `:183`, and `:515-518`. Check 12 confirms the two formerly incomplete F3 regions changed and now carry the delta reference.
4. **Gated versus recorded output.** `DECISION.md:419-445` now distinguishes failure-gated facts from intentionally unasserted recorded output. The reruns confirm the stated count: 81 shell helper `PASS` lines, 11 check-12 Python `PASS` lines, and 8 `ASSERT ...=True` gates.

## Assessment

Revision 2 resolves all four blocking findings without broadening the claims. The licence correction preserves the unconditional corpus and conditional generator model; the release mapping and branch delta are exact; and every cited fact is now failure-gated while non-load-bearing output is explicitly labeled recorded. Approve.
