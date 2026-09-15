decision-sha256: 3620897e85a288ea76b071bc5383694802420920dcf8cf335866bbc60a69f045
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0-r9
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

`argv`: I extracted the three complete recorded payloads, `check16.sh`,
`check16b.sh`, and `check16-controls.sh`, from their evidence logs to a fresh
directory under `/private/tmp`, then ran the third payload with `LEG1` and
`LEG2` set to the extracted first and second payloads. The third payload ran
each clean leg twice, all thirteen one-input perturbations, and each required
post-perturbation clean leg. I also ran each leg standalone before that complete
replay.

`cwd`: `research/runs/R42/2026-09-05T155503Z-4141a35b69e0`.

`toolchain`: Darwin arm64; the published `cargo-binstall` 1.23.0 arm64 release
binary fetched by the recorded payload; Homebrew Cargo; Bash; curl; tar; unzip;
shasum; grep; and diff. I set `CARGO_HOME` to an empty directory under
`/private/tmp`: the sandbox rejects `cargo-binstall` reading the host mutable
Cargo cache otherwise. The payload still hashes the recorded `~/.cargo/bin`
listing before and after, and every `cargo binstall` invocation retains
`--dry-run`.

`exit code`: 0 for the complete three-leg replay. Leg 1 passed 45/45 assertions,
leg 2 passed 23/23, and leg 3 passed 37/37 with 13/13 controls demonstrated.

`log path`: `review/evidence/audit-dev-toolchain-provisioning-r9.log`
(sha256 `d903c08643792754c9066af58ab2bb7df474c4dd92c113a2637b066d5255d350`).

`matches the decision`: Yes for every asserted fact and claimed control. The
only replay-specific textual variance is the permitted elapsed-time output plus
scratch and isolated-`CARGO_HOME` paths; the source hashes, five live raw-source
fetches, published-manifest verdicts, 7a zero count, 7b fallback, 7c one count,
7d status 76, eight-file tree hashes, digest sweep, and all controls reproduce.

## Findings

None. The first and second legs make their stated content checks actual
assertions; their meta-assertions work. In a separate one-input probe, changing
only each copied leg's expected count from 45 to 46 and 23 to 24 produced its
own `ASSERT-FAIL assertion-count` and exit 1. Evidence:
`review/evidence/audit-dev-toolchain-provisioning-r9-meta-count.log`.

The third leg requires both a non-zero result and its named `ASSERT-FAIL` line.
Its 13 real perturbations reproduced, including `main.rs` in the `args.rs` slot,
a signed crate where `ABSENT` is expected, both signature-count swaps, the 7d
resolvable-spec status mismatch, a second `Sha256Digest::new` site, and the
injected `Blake3Digest` line. It also proves 8/8 of the check inputs are byte
identical at v1.22.0 and v1.23.0, while v1.21.0's `args.rs` differs. A synthetic
HTTP-429 leg was reported `VOID` 13 times and exited 2 rather than passing:
`review/evidence/audit-dev-toolchain-provisioning-r9-void.log`.

Check 15's log is unchanged from revision 8. Its active table row and the
revision-7 history now accurately say its status was printed rather than
asserted; no other active statement gives that old script failure-control credit.
The active text contains all six grammatical gates: gate 1 is correctly struck
by the 2026-09-12 owner ruling, gate 3 retains its parenthetical label, and gate
5 remains inapplicable because nothing is linked. The owner-facing integrity
comparison and its three options remain an unanswered owner ask.

The `## Supersedes` preserved revision-6 payload is byte-identical to the
published topic decision: both hash to
`ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f`.
The active parameter and acceptance-contract lines are byte-identical to
revision 8.

## Assessment

Approve. Revision 9 repairs the round-8 blocking defect with executable,
counted assertions and demonstrated discriminatory controls; the decision states
the one tree-control conclusion that changed without moving the signing result.
