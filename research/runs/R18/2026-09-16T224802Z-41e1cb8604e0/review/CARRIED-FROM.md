# Carried-forward run

This run submitted no provider operation and ran no check. It exists only to
republish R18 ai-assisted-review-workflows at the owner-accepted revision
designated 7, because the published run `2026-09-06T043454Z-6f31d86e5b7d` is
immutable (`publication apply` refuses: "published run is immutable; prepare a
new run for another publication").

- source run: `research/runs/R18/2026-09-06T043454Z-6f31d86e5b7d` (state `published`; untouched)
- reason: republication of the owner-accepted revision, DECISION.md sha256 `c9e44318abbdf4131d0d8b575d318c442c8a89ff9fc8c573c8d92c5ecb441f2e`
- owner acceptance: `docs/port/OWNER-ACCEPTANCES.md` Wave 0 row R18, revision 7, accept, 2026-09-15
- REVISION-NUMBER DISCREPANCY, carried forward unchanged: the accepted file titles itself `decision (revision 6)` on its first line while the ledger and the acceptance row designate it revision 7. The judgment audit records the same observation and the controller's ruling on it. The acceptance binds the sha256, not the number, so nothing here was edited.
- superseded published copy: `research/topics/18-ai-assisted-review-workflows/DECISION.md` sha256 `b45a17a342bfa49689c3571e71c14ab55c2fa64e0f9337032876739babdae205`, preserved verbatim under `## Supersedes` in the carried DECISION.md
- audit transcripts, receipts, archived rounds (`audit-*.rN.md`) and provider receipts were NOT copied; they stay in the source run.

## Files copied from the source run (sha256 of the copy)

```
69f367992ab63528a9689ed612dea4bceecda202caf907ec74ac8993e7bbaa14  raw/codex.md
0d053806271b213b15c80df745bd5d7f235e3e6e5bd936bd7b98c5f50a663802  raw/opus.md
0a3653871ed3eba4dbcc1dea3c9bb0fc9b77cc650e3d567cc1714fe83a303c10  raw/doxa.md
606848b468c815e5cf7e42c0aac28e3359536f88f6614b900ed4c6029410e490  raw/doxa.normalized.md
c9e44318abbdf4131d0d8b575d318c442c8a89ff9fc8c573c8d92c5ecb441f2e  review/DECISION.md
b93c79cef543418e3b2d83f18f2a83e5c566227c0bd04af8fe54efff9d87e3c7  review/audit-codex.md
9cd018cc0f374e47d41879f0f380f316eded351a0be2eb185dd1275fc83ef7ac  review/audit-fable.md
5d930871591ca4b13249020fc52039843ec6eaf59dc18ae74f95178b35fdb2de  review/evidence/action-docs-quotes-v1.0.220.log
b8946a36af54dced3f12f9b82b1947ef0e0e6135738ac34aa39f98cd800304f3  review/evidence/action-entrypoint-plugins-v1.0.220.log
07f7e5a355c10cf22932acc028c0650d852875cb3c4d9d14a7b3673471ac60c9  review/evidence/action-guard-source-v1.0.220.log
365e4617059f57beb61f8232d06b5f7917e9b1a5add1f5b9ee9a631e4ab4c672  review/evidence/action-issues.log
641510716c48cf06144ed99bd9515accb1cca2a32dfc438f6b6f76532e0070fa  review/evidence/action-release.log
880eb8534ed5587ff23709c54c92b79e2c21cc78e44ceb9153ac2dbecbde7631  review/evidence/action-source-v1.0.220.log
a3e2e6c4bf57be7748bfdd7d9a98d504c61a66781df0c72ae840ae08daa0babb  review/evidence/action-tags-resolve.log
e8806519058723b2edc3569aa80edcc4d1641156f6221f1f1b8566061193018d  review/evidence/actionlint.log
c4970c2a383c95c821cd71edc5721e84a3a8b659460a0e0324ec120a0b8c598f  review/evidence/audit-ai-assisted-review-workflows-r2.log
ab97f2992278e9747de7ae403c798b337983da682f2085a294cb84d08106e700  review/evidence/audit-ai-assisted-review-workflows-r3.log
f9754fffc89d995161d72a35b840f7f2c6d6ac034045a270ba54d81fb842c6fc  review/evidence/audit-ai-assisted-review-workflows-r5.log
6cfa206bc63bc8913c689d03ddbfbe7e52626d4557d4dd75b673b526e8826751  review/evidence/audit-ai-assisted-review-workflows-r6.log
e2821e136101833126b622e077028d3a2288e172c8b9ef22f3ffc8a3695fc57a  review/evidence/audit-ai-assisted-review-workflows-r7.log
8ccb12bed1827af613a2e28863e0873fee0e2caac0aae21771a0f57f28f653bf  review/evidence/audit-ai-assisted-review-workflows.log
b08b68b7d8a8d9ab5f4a00d18882172dea8da053c40ce15cafb6fdb8f81a6616  review/evidence/candidate-claude-code-review.r3.yml
64c48639453967cdc4c2ab9c68a5f2670682cc54121e48edd020986a3ee7cdab  review/evidence/candidate-claude-code-review.r4.yml
d3c8b712d71b521a7f55853efcf51887cb4f094eb7cbfb13f51999de67d1f3c5  review/evidence/candidate-claude-code-review.r5.yml
c28bf61e371309b80e94e1e6361d50209b122f05ec1b710279db41f14463a31a  review/evidence/candidate-claude-code-review.yml
d7c12c325ed1ec843cc9ac6c5f0de2dff8676d546ff624bae733b9fe835944ee  review/evidence/candidate-claude.r3.yml
50b857c51b93e6d8a091c9ad2d72e7c2807f47808725340704673b121ce395b5  review/evidence/candidate-claude.r4.yml
2c507e7d89133b7f2b1f68c479d5910e5e12d4efe0d658d30066c16f07d0feff  review/evidence/candidate-claude.r5.yml
bc9c061dc580b9e9645a73d8fe20f44af7d5cd39f7eeafeded4f874855139921  review/evidence/candidate-claude.yml
7c612382a48dde064bd0c648e627ac415e26e47bd6a95c67978d96453ae5e019  review/evidence/candidate-secrets-in-job-if-NEGATIVE.yml
2532362dd10c32e64d3bd120dc86e824cd8b2565518cfa482adbba16a662f03a  review/evidence/contexts-availability.log
bd376f261dd894e4a547437c6b48b4658b7d867796dfcbb5ac068c9817f4f27e  review/evidence/flatt-disclosure-2026-06-01.log
0e2fc98f65a468eedec5db2e9cf9d8f63bf19234e56ca321831382d9c498b18c  review/evidence/github-docs-pull-request-ref.log
04bda54f7f0e77152305e2d5e59c62f74f3f8fddc2f59c2fc69bc50099a92b82  review/evidence/issue-1068.log
3307f34747f7bcae8c9304d3f16db449706901b1926bbeea19e919119d655c4b  review/evidence/needs-and-credential-shapes.log
a80aba7ab51929e42a4f7e5f61a4e9b3a98a178730ac951dedec449a350e7a05  review/evidence/protected-regions-r6.log
51a272c0b9bcda3277f92c7a930eca400e249fc0de8f7f56fb2436c5f585d802  review/evidence/source-repos-pinned.log
5e57080a211eb49a6799244b4a97dc1eabb58e25463cd11aab377dcf78a7e324  review/evidence/toolchain.log
```

## review/identities.json

Copied from the source run and NOT edited: the source run's file already
records the current round, because the revisions after the first publication
were made inside that run.

- `audits.empirical` -> `audit-codex-2026-09-06T043454Z-6f31d86e5b7d-r7`, model `gpt-5.6-terra`, family openai: equal to the `actor`, `model` and `family` header lines of the carried `review/audit-codex.md`.
- `audits.judgment` -> `audit-fable-2026-09-06T043454Z-6f31d86e5b7d-r7`, model `claude-opus-5`, family anthropic: equal to the header lines of the carried `review/audit-fable.md`.
- `synthesis.actor` -> `synth-opus-2026-09-06T043454Z-6f31d86e5b7d-r6`, left as recorded: it names the revision the decision file itself bears, and the decision names no other synthesizer.
- `empirical` -> the round-7 executed rerun. `argv` is `actionlint candidate-claude-code-review.r5.yml candidate-claude.r5.yml`, which line 35 of `review/evidence/audit-ai-assisted-review-workflows-r7.log` records verbatim; `cwd`, `toolchain` (including the denied Lima host-state unlink and the macOS fallback) and `output_log` are what that audit's `## Rerun` states.
- `engine_reports` left unchanged: those are the true actors of the copied raw reports.
