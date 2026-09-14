decision-sha256: 3a3c3d434f117e1b47adbd13d736e44897ae3e72d4baf595dc70c65c9dbb0550
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0-r8
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1 check 16 does not assert its signing, fallback, negative-control, or digest-sweep content, so its claimed failure controls do not make the check fail

## Rerun

`argv`: I extracted and executed the complete recorded `check16.sh` and
`check16b.sh` payloads from `evidence/binstall-signing.log` and
`evidence/binstall-verifier-impls.log`. The script bodies, tags, URLs, specs,
flags, and dry-run calls were unchanged. `CARGO_HOME` alone was redirected to a
fresh audit scratch directory because this sandbox cannot write the owner's
mutable Cargo cache; the scripts still hashed the real `~/.cargo/bin` listing
before and after.

`cwd`: `research/runs/R42/2026-09-05T155503Z-4141a35b69e0`.

`toolchain`: macOS arm64; the published `cargo-binstall` 1.23.0 release binary;
Homebrew Cargo; Bash; curl; tar; unzip; shasum; and ripgrep. No template or
permanent binary was written. Every binstall call used `--dry-run`.

`exit code`: 0 for each replayed leg.

`log path`: `review/evidence/audit-dev-toolchain-provisioning-r8.log`.

`matches the decision`: The observed signing facts reproduce. The normalized
diff is limited to the three installation-root paths introduced by the isolated
`CARGO_HOME`; it is recorded at
`review/evidence/audit-dev-toolchain-provisioning-r8.diff`. The rerun printed
both unsigned verdicts, the `cargo-binstall` positive control's one verified
signature, the `--only-signed` fallback to `cargo install --locked`, the
negative control's exit 76, all three `DataVerifier` implementations, one
`Sha256Digest` construction site, and no digest term in
`binstalk-fetchers/src`.

Five live citation checks match the recorded immutable-tag SHA-256 values for
`args.rs`, `gh_crate_meta.rs`, `quickinstall.rs`, `resolution.rs`, and
`SIGNING.md`; the published `cargo-shear@1.13.1` manifest again has no signing
stanza. Evidence: `review/evidence/audit-dev-toolchain-provisioning-r8-citations.log`.
The current decision's bytes are exactly commit `6f2bbc6`, not `ec5bccc`.
The active fitness section contains all six gates; gate 1 is correctly struck
by the owner ruling, gate 3 is scoped to the probed candidates, and gate 5 is
present and grammatical.

## Findings

F1 (blocking): Check 16 does not make its claimed controls or integrity results
assertions. In `binstall-signing.log`'s recorded `check16.sh`, each critical
command is followed by `echo` of its status: the 7a, 7b, 7c, and 7d calls are
at extracted lines 78, 85, 90, and 97, while the two verified-signature counts
are only command substitutions at lines 80 and 92. The final
`[ "$BEFORE" = "$AFTER" ] && echo ... || echo ...` always exits zero. In
`binstall-verifier-impls.log`'s `check16b.sh`, the tree-hash mismatch at line 26
is the only explicit failure; the purported positive/negative controls and the
no-digest sweep at lines 47, 49, and 53 only print status. `set -o pipefail`
does not turn a failed standalone command, or an unexpected count, into a
failure. Therefore the decision's statements that the 7d control means the
first leg "can fail" and that the second leg carries three failure modes are
false. More importantly, the program rule requires content assertions, not a
successful final `echo`, so the decision cannot treat these unasserted scripts
as sufficient proof of the owner-facing integrity claims.

Repair the recorded payloads to assert the required output and expected status:
zero 7a verified-signature lines; one 7c line; 7b's exact Cargo fallback;
7d exit 76; exactly three `DataVerifier` implementations; exactly one
`Sha256Digest` construction; and a no-hit digest sweep. Rerun the repaired
payloads and update the decision's claims about failure controls before the
integrity tradeoff can be accepted.

## Assessment

Reject. The substantive observations reproduced and the second leg fully
accounts for the registry-only `Sha256Digest`, so the decision no longer makes
the deleted-gate or draft-checksum overreach. Its current evidence programs,
however, do not enforce the observations on which the new signing conclusion is
based.
