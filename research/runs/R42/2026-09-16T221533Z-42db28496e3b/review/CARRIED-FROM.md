# Carried-forward run

This run submitted no provider operation and ran no check. It exists only to
republish R42 dev-toolchain-provisioning at the owner-accepted revision 10,
because the published run `2026-09-05T155503Z-4141a35b69e0` is immutable
(`publication apply` refuses: "published run is immutable; prepare a new run
for another publication").

- source run: `research/runs/R42/2026-09-05T155503Z-4141a35b69e0` (state `published`; untouched)
- reason: republication of owner-accepted revision 10, DECISION.md sha256 `a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c`
- owner acceptance: `docs/port/OWNER-REVIEW.md` Wave 0 row R42, revision 10, accept, 2026-09-15
- superseded published copy: `research/topics/42-dev-toolchain-provisioning/DECISION.md` sha256 `ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f`, preserved verbatim under `## Supersedes` in the carried DECISION.md
- audit transcripts, receipts, archived rounds (`audit-*.rN.md`) and provider receipts were NOT copied; they stay in the source run.

## Files copied from the source run (sha256 of the copy)

```
b3e8e5204f27a67f06e503c277846a55e38dbae9d30944a7bb37638e07ed998a  raw/codex.md
526782a3888c3da67d2c27697aeb6030b4c211c0b60bb32fa62f37965889a487  raw/opus.md
2594f9973bc7c17cdf448ded71412cb2502b0314ca3e122384eca58fa2478c2e  raw/doxa.md
3d75b20953feb1c10d79720ef9b25b99a65d633a737d218660a1c0fce917eacb  raw/doxa.normalized.md
a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c  review/DECISION.md
be04e6237a59064e506a02e720b9f343f798714e66ea6351d5c3bbe557f2d983  review/audit-codex.md
1755eaa37c2941d86d978f6216fa309ec823763846a16145b53024d724eb5c83  review/audit-fable.md
911a89597c3d0a254d593e8e4e793e353c234c8ac2c37f71f98672d587a4cf82  review/evidence/alias-mechanism.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-dev-toolchain-provisioning-r10-assertions-vs-cited.diff
78b43553d92f598b10a38f829b6115e128989cd076a20877201ffa9270214e03  review/evidence/audit-dev-toolchain-provisioning-r10-citation-spotchecks.log
451094e64b628e271eb11558fb0259bc50cad4e8a566036ebe767a016fc7cfbe  review/evidence/audit-dev-toolchain-provisioning-r10-void-attempt.log
46c6991020bfaa5cc933f94ed0ab039abff517a23a6a2c5d2e9ea4e6fe50aed9  review/evidence/audit-dev-toolchain-provisioning-r10-void-missing-scratch.log
82a65d91231d8f0405f940bcf4106242e5f909cb0db57ed93491543c5633f122  review/evidence/audit-dev-toolchain-provisioning-r10-void-sandbox-home-cache.log
15d152538b6b9e3abedd8d46f3ed3704cb0688839471f8b15794b84c6d768396  review/evidence/audit-dev-toolchain-provisioning-r10-vs-cited.diff
a23bc2a423d622348d5619def692c49a63c92c639502faf0cb66d91ef08ebb70  review/evidence/audit-dev-toolchain-provisioning-r10-vs-cited.normalized.diff
11dfd5a8a2ccfe39bf2e62068950ad6eb1f45c3fb34613489b82b85f918ee30a  review/evidence/audit-dev-toolchain-provisioning-r10.log
1c236203937f80048c92ba5060512ce9f3e386b2236b7061feb7f0690aa20941  review/evidence/audit-dev-toolchain-provisioning-r2.log
29c1b4ed74ec4391de6948d4389e20196cc56e62d46ca45f20ad5a6b6334189c  review/evidence/audit-dev-toolchain-provisioning-r3.log
d23be02aa40f17e644187b9b83be18e14c54c907f6749de73bebd4f89a7cefb7  review/evidence/audit-dev-toolchain-provisioning-r4.log
62502a60d3028f96044fb413c0ff934e32e799fdc5a70127d8e92087bc54c67d  review/evidence/audit-dev-toolchain-provisioning-r5.log
b5fe1c8f04bce54e639c5b68304c10eeff0b902835dbfcbbcdea9e130f1c4f31  review/evidence/audit-dev-toolchain-provisioning-r6.log
076289528cba8568fb8fd27655a02a60222e74db053508422dfb11eb4d44212a  review/evidence/audit-dev-toolchain-provisioning-r7.log
46de91caa03d292286a1c8ab83250ee0f2831e2d27b065a4a013ff0f0183ea9f  review/evidence/audit-dev-toolchain-provisioning-r8-citations.log
566378adac12cdb730d61638668b8901dc9d759646adbddd1babad346c7cafde  review/evidence/audit-dev-toolchain-provisioning-r8.diff
18f8c2223cd6cee2b2f019774264e639473c9c2df862e7a0109df7e303790b56  review/evidence/audit-dev-toolchain-provisioning-r8.log
8baf8e1055c9db8bd6ff76ce3974cf1fc0d7baeaa6e214b0832022cb9d1db8ee  review/evidence/audit-dev-toolchain-provisioning-r9-meta-count.log
5bc0cf5a6897bf2212c9806ead1d199ecb0846bceba40ea4489cb67102df35d1  review/evidence/audit-dev-toolchain-provisioning-r9-void.log
d903c08643792754c9066af58ab2bb7df474c4dd92c113a2637b066d5255d350  review/evidence/audit-dev-toolchain-provisioning-r9.log
0829950b10caee8c2f2216a9e2dbeb5ce5bf828926a3393d0251b38c2508e5bc  review/evidence/audit-dev-toolchain-provisioning.log
d63de1385ea7bf1f76eb93ad3bae4de94b3d2fe3c0c560006f75a9509a90e40b  review/evidence/binstall-assertion-controls.log
28bd9625ea1b7f3ab1d8c15567a82b82d69fe8141dce38d79a485156fb306d5b  review/evidence/binstall-backend.log
c49d217e07a3d8e4046012419404b694240001b4d9927ff5dd9b397060955b49  review/evidence/binstall-signing.log
43f987b89236d43a6dcc697162974ad48f1775cf60b6f5bb715c3d4085c54235  review/evidence/binstall-verifier-impls.log
2f7e1842388e8e89fbcec05e581ab1dc119407cb6fee44afc69b742e35aec726  review/evidence/crates-io.log
1ff23c6e7688db056a2e37303a74dc32e13f0a57566a526d864ef44a7407efc0  review/evidence/github-rustsec.log
ed7f6092d6c41697b541b0beb4df686f4b3681636c7c1efbb5692e317dd42fd4  review/evidence/invocation-mechanism.log
eb0a6ae2504491cd249e017e7ea7b01b89435bea87723ac6ddf04aeaf5405c9c  review/evidence/invocation-sweep.log
c310e122521374777959e953cadb30e9c12ff788c37200db0f4e43d4ae8d2338  review/evidence/presence-test.log
68b8eb28f5f3a94e933bc13e85a0ae0551e8624c77520c946b0a507ca5607a4d  review/evidence/reference-aliases.log
4ccf58781a312948408f038dc17350af8c225ba0e7c3194e093729b9108af480  review/evidence/reference-impls.log
3d386dc274acad7a6244659f8ec4daa40566317d8ad424c93b0a9ac1dd03a0ee  review/evidence/repo-survey.log
c8adc8a1236f8cefb8c3b66b067b705c724fd0a425d8ba1f7ba7ec0b52e34088  review/evidence/rustup-figures.log
840cd00287ad801813fea793763796acd5520e2309b6a52a0a291052823a4800  review/evidence/toolchain.log
```

## review/identities.json

Copied from the source run, then edited for round 10:

- `audits.empirical.actor` -> `audit-codex-2026-09-05T155503Z-4141a35b69e0-r10` (matches `review/audit-codex.md`)
- `audits.judgment.actor` -> `audit-fable-2026-09-05T155503Z-4141a35b69e0-r10` (matches `review/audit-fable.md`)
- `synthesis.actor` -> `synth-opus-2026-09-05T155503Z-4141a35b69e0-r10`, following the r6 naming pattern; revision 10 is dated 2026-09-14 with model `claude-opus-5` in the DECISION.md revision history
- `empirical` -> the round-10 executed rerun, taken from `review/audit-codex.md` `## Rerun` and the `argv=` header of `review/evidence/audit-dev-toolchain-provisioning-r10.log`.
  `argv` reproduces the environment-assignment words and `/bin/bash` exactly as that header records them; no script argument is asserted, because neither the audit nor the log records whether the extracted payload reached bash as a file or on stdin.
  The extraction and setup prose is carried in `cwd` after the literal archive path, following the revision-6 precedent.
  `toolchain` states only what the audit records (`/usr/bin/grep`, the downloaded `cargo-binstall` 1.23.0 release binary, the isolated writable home); the revision-6 `macOS 26.4 arm64` claim was NOT carried forward, because revision 10 records no host.
- `engine_reports` left unchanged: those are the true actors of the copied raw reports.
