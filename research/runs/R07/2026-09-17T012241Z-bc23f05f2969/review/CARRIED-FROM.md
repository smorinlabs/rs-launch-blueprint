# Carried-forward run

This run submitted no provider operation and ran no check. It exists only to
republish R07 contributors-bot-trigger-cadence at the owner-accepted revision 4,
because the published run `2026-09-05T162400Z-58ba22bff8ca` is immutable
(`publication apply` refuses: "published run is immutable; prepare a new run
for another publication").

- source run: `research/runs/R07/2026-09-05T162400Z-58ba22bff8ca` (state `published`; untouched)
- reason: republication of owner-accepted revision 4, DECISION.md sha256 `cb183382237157405fc09b00fd67a2f60475b52959df078f7fe2e830730dde27`
- owner acceptance: `docs/port/OWNER-ACCEPTANCES.md` Wave 0 row R07, revision 4, accept, 2026-09-15 re-bound 2026-09-16
- revision 4 changes the H1 title line and nothing else, so that `check_history` accepts the republication: it needs a date-first `# YYYY-MM-DD …` heading before `## Supersedes`. Both round-4 audits re-ran against the retitled bytes and approve.
- superseded published copy: `research/topics/07-contributors-bot-trigger-cadence/DECISION.md` sha256 `0b3dde8f9a15f22e60a01542065c53c122881e8c48bf3ee6c172ba5b70499346`, preserved verbatim under `## Supersedes` in the carried DECISION.md
- audit transcripts, receipts, archived rounds (`audit-*.rN.md`), `review/empirical/` and provider receipts were NOT copied; they stay in the source run. The empirical entry below therefore names a script path that lives only in the source run, as the R01 and R42 carried-forward runs also do.

## Files copied from the source run (sha256 of the copy)

```
fec48e36bb5a3183da6f2a133cdccc223fcaf722a49a3410e30fe1c45501af04  raw/codex.md
a2f5e9a652105d01d0256b1aa06390692282bedf6bce4823a7bf24224cc7dbfc  raw/opus.md
cb183382237157405fc09b00fd67a2f60475b52959df078f7fe2e830730dde27  review/DECISION.md
66af11cfeb276905354713788ad090ba793672811b613cc525862e4fd14394fa  review/audit-codex.md
68f3a4ef104b0facde23f2fbedf4c03b30b94dbe04cc204cadeb81e323a5c018  review/audit-fable.md
48a8e0b73220836f9539a970d8bda5f731eeffe23f213076af6f7e0b8d3537fb  review/evidence/audit-contributors-bot-trigger-cadence-r2.log
7675260fca5ea7164ece073a403840a3d5d94a6e5de58318c08302e6484ae01c  review/evidence/audit-contributors-bot-trigger-cadence-r3-citation-probes.log
1fa7b5f3f5327a9ad109cc8c25e5257c547388bae358302804ce9a324cf34646  review/evidence/audit-contributors-bot-trigger-cadence-r3-falsification-rerun.log
159f0d56a60607b5348ac547356f4f616b2b4520e4d7bc17eb2b617838d48c47  review/evidence/audit-contributors-bot-trigger-cadence-r3-falsification.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-contributors-bot-trigger-cadence-r3-reproducibility.diff
745f9cd93f5f9eb8f6a4e54942677e6c8aad69eff3922bbfddc22a380adbd0e8  review/evidence/audit-contributors-bot-trigger-cadence-r3-rerun.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-contributors-bot-trigger-cadence-r3-vs-recorded.diff
e77a0276111fe30c5b093f89bae1d8ec271c9cc98a89bed31a9f006c79970fab  review/evidence/audit-contributors-bot-trigger-cadence-r3.log
64abb4750ef9ca014db3c63cf9bb3caf1a4db5f305d4d79d779d5ab5a85e0fc8  review/evidence/audit-contributors-bot-trigger-cadence-r4-archive-path.txt
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-contributors-bot-trigger-cadence-r4-archive.exit
1d9849708e05d584e7a45f29a3f121ab2521696d3ceee628fc103f8bdfb62f03  review/evidence/audit-contributors-bot-trigger-cadence-r4-archive.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4-citation-probes.exit
63f3fa470cbb58fcfdd9c9ecff769812ae40b3bb55214a98153050024ea0d17b  review/evidence/audit-contributors-bot-trigger-cadence-r4-citation-probes.log
1849388ff3845c2ff75c5e5571942d2c2e70f1c52835c81a6eca850a43155340  review/evidence/audit-contributors-bot-trigger-cadence-r4-full-archive-path.txt
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4-full-archive.exit
a2d4211480e56756bc3fdff073aaabd9ac9639f4da3cd5d74a3148a414a1003a  review/evidence/audit-contributors-bot-trigger-cadence-r4-full-archive.log
2c8cf5fbfcdecc715a9aa0f8735c306837e47d5580a5b82fe2b5e3153cdb3fe3  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-full-archive.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-full-archive.exit
32be491ebb69d66842b0fe0f127b105c29a9737b3e70d465934836d41644bf57  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-full-archive.log
cb3bac63f2e3b05429fa4d1bcfe65d63b8f987dd0ab288bfcb10535b27c4d166  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-full-archive.pid
c441505cc4ebeabf36069ae4bccef6da3f21775db66c2cb8cb7705e25107fc77  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-inplace.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-inplace.exit
d11c625c9c50b74c0878742e48f04bf8d3c3a7ffbb94ee908a3fa45550519b64  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-inplace.log
90b4108b273c1905c2bf809e7caa5b0e21cd444bc3a965faa0a365b6d63af9cc  review/evidence/audit-contributors-bot-trigger-cadence-r4-r1-inplace.pid
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-contributors-bot-trigger-cadence-r4-r2-archive.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4-r2-r3.exit
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-contributors-bot-trigger-cadence-r4-r3-archive.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-contributors-bot-trigger-cadence-r4.exit
342e70bf1e455e220a5b03cd5984c103c5773c747790c239ca792fc8462c3545  review/evidence/audit-contributors-bot-trigger-cadence-r4.log
327ff85a7fedfa38a775962ffe9dd80034537817f9b712e466c59454614d2afb  review/evidence/audit-contributors-bot-trigger-cadence.log
6152b6f23520654762f563f31471d3cc5a4d997c5decf4c40969bc8b831cebdc  review/evidence/py-paths-verdicts.json
c0f13f4f57dbcc656e70746edb1ee41a91bffaae3b697d784ddb7fe82e4faa87  review/evidence/py-update-contributors-runs.json
ce043ac619ec491d7e55f74d3a9a875a70405e7365fb62188af59a97085bd4a7  review/evidence/r07-empirical-r2.log
5c2665d93a025cc316a5a8f298ed1eac891b173d4e8ce9cb220f4a0445a5d71a  review/evidence/r07-empirical-r3.log
424c5180cb71648ba4fb97f4485ca1cdba07f1b880c5c4086d8c4c9c433eb92e  review/evidence/r07-empirical.log
3d6e63dca00870b4a3246af4d18273389fb9ac81340d79811e3ce142402a20d3  review/evidence/r2-disable-and-enable-workflows.txt
9a01c777a7fdbeb7f45b0190de850412d6e8b35fb7767396669c3c134ec533eb  review/evidence/r2-workflow-state-enum.json
d84d0b04c7803e88fcbd389efb7c186a2c4388d5d33be90a7725b1a83ce37c20  review/evidence/ts-paths-verdicts.json
f89965fb0c05efb5b4582af89e9cd7de4820ab5fb2255b7e1cedc4a0f0d63e8a  review/evidence/ts-update-contributors-runs.json
```

## review/identities.json

Copied from the source run, then edited for round 4:

- `audits.empirical.actor` -> `audit-codex-2026-09-05T162400Z-58ba22bff8ca-r4` (matches `review/audit-codex.md`; model and family were already `gpt-5.6-terra` / openai)
- `audits.judgment.actor` -> `audit-fable-2026-09-05T162400Z-58ba22bff8ca-r4` and `audits.judgment.model` -> `claude-opus-5` (both match `review/audit-fable.md`; the source run recorded the round-1 judgment auditor, model `claude-fable-5-1`)
- `synthesis.actor` -> `synth-fable-2026-09-05T162400Z-58ba22bff8ca-r4`: PATTERN-FOLLOWING, not a quote. Neither the decision nor any record in the run names a synthesizer actor for revision 4, so the source run's recorded prefix and model are kept and only the round suffix is appended.
- `empirical` -> the round-4 executed rerun, taken from `review/audit-codex.md` `## Rerun`.
  `argv` is the revision-3 check, the current substantive check, which that section writes as `(cd review/empirical/r3 && ./run-check-r3.sh)`; the parenthesised `cd` is transcribed into `cwd`, and `cwd` also names the clean-archive leg and the other two checks the same audit ran.
  `toolchain` states only what the audit records, including `act` absent and the resulting form (b).
  `output_log` is `review/evidence/audit-contributors-bot-trigger-cadence-r4.log`, the in-place round-4 transcript, which ends `overall failed assertions: 0`, `RESULT: PASS` and `revision-3-exit: 0`.
- `engine_reports` left unchanged: those are the true actors of the copied raw reports.
