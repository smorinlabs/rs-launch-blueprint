# Carried-forward run — PREPARED, NOT PUBLISHED

This run submitted no provider operation and ran no check. It was prepared to
publish R69 web-framework-stack at the owner-accepted revision 9. **`publication
apply` refused it.** The run is kept, unpublished, so the attempt can be
completed once the refusal below is resolved.

## The refusal, verbatim

```
error: staged publication invalid: R69 engine_reports[2]: answer: bundle H5
member field is outside a named member in '### Members'
```

(the same sentence sixty times, once per offending line). It comes from the
staged-copy validation in `scripts/research_runner.py:508`, which runs
`validate_topic` against a temporary tree before any live file is written, and
the rule is `scripts/research_validation.py:251-253`: every unfenced `##### `
line must lie strictly between the first `#### ` member heading and the end of
the `### Members` section.

`engine_reports[2]` is the Doxa report. The defect is in the source run's own
Doxa bytes and neither candidate file passes:

| file | `### Members` at line | section ends | named `####` members | unfenced `##### ` outside the section |
|---|---|---|---|---|
| `raw/doxa.normalized.md` (the bytes the packager stages) | 615 | 1331 | 9 | 60, first at line 1338 |
| `raw/doxa.md` (the collected raw) | 108 | 109 | 0 | 195, first at line 740 |

`research_package.py`'s `source_file` prefers a `.normalized.md` twin beside the
raw, so the staged Doxa report is `raw/doxa.normalized.md` whichever of the two
`engine_reports.doxa.file` names. This run's Doxa normalization is also missing
the `raw/doxa-perplexity.normalized.md` twin that the sibling `openai` and
`gemini` twins imply. Resolving this needs a re-normalization of the Doxa report
in the source run, or an owner decision; it is not something a publication
operator may repair, because the raw reports are provenance.

Nothing was published: no journal was written, `research/topics/69-web-framework-stack/`
has no `DECISION.md`, this run's manifest is still `ready`, and the source run is
byte-identical to what it was (`manifest.json` sha256 `bf3d87b269065f02e19674d9fc26dc1bb7d395fded8c0f6a505b1dd8a69b4e92`, state `collected`).

## Why a new run at all

The source run is NOT published and is not immutable. It is carried forward
because its `inputs/prerequisites.json` snapshots R01 at the pre-republication
hashes (decision `8025fd5b…`, acceptance `4d46366d…`), taken before R01 was
republished at revision 3 on 2026-09-16. `publication apply` refuses that with
`stale prerequisite snapshot: R01` (`scripts/research_runner.py:182`). This run
re-snapshots R01 at its current published hashes, decision
`44bf9ae9f55060ed56256dbad4d9a0814b3bd63112602dabe932acb7bfb12d82` and
acceptance `74f520128e313e5964582b99a23d2f43c05234fbd722f0ce2755563d44f22f10`,
which is confirmed in `inputs/prerequisites.json`. That refusal is therefore
cleared; the Members-shape refusal above is a second, independent one.

- source run: `research/runs/R69/2026-09-12T204004Z-d02022bf6f42` (state `collected`; UNPUBLISHED and untouched)
- decision: revision 9, DECISION.md sha256 `d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d`
- owner acceptance: `docs/port/OWNER-ACCEPTANCES.md` Wave 0 row R69, revision 9, accept, 2026-09-16 (W0-R69b)
- both round-9 audits bind that sha with `verdict: approve` and `unresolved-findings: none`
- when it succeeds this will be R69's FIRST publication: the topic has no `DECISION.md`, so `check_history` returns early and the date-first heading rule does not apply. A later revision of the published decision WILL need the date-first `# YYYY-MM-DD …` form; this file titles itself `# R69 web-framework-stack — decision (revision 9, 2026-09-16)`.
- the build that preceded the refusal produced 120 changes: 4 topic files, 111 evidence logs, 3 raw reports, `research/CLAUDE.md` and `docs/port/PARAMETERS.md`, whose `web-extra-surface` cell fills from the decision's single `- owns` line.

## What was copied, and two deliberate exceptions

`review/.gitignore` was carried from the source run. It is not in the recipe's
copy table, and without it this run would commit 925 further files, including
the third-party `review/evidence/sources/` tree — upstream sources read at
pinned versions, among them bacon 3.25.0, which is AGPL-3.0. That ignore file
states the rule those files sit under, so carrying the evidence without it would
have broken it. With it, git sees 320 files here and no third-party source.

`review/evidence/audit-r8-rev7-to-rev8-U0.diff` and
`review/evidence/audit-r8-rev7-to-rev8-default.diff` were NOT copied: both were
untracked in the source run at copy time, are referenced by neither the decision
nor either round-9 audit, and are `.diff` files the packager never stages.

`review/empirical/`, audit transcripts, receipts and archived rounds were not
copied; they stay in the source run.

Every file carried here that git will commit was verified byte-identical to its
blob in HEAD at the source-run path: 320 files, 0 differing, 0 absent from HEAD.

## Files copied from the source run (sha256 of the copy; top level of review/evidence/)

```
6f1d03df7be0ab3afc4c1fc2bed545d0ad0ab55f30b138c10750346e7f9e21fd  raw/codex.md
161fcbb42aadb8752c59d36a7ba337e1b69e717429110ad94c548ce649e0f91d  raw/opus.md
356ae5aa488bc6dac1201523f8163351729b3791e848a7a38f7f76939ffe2f82  raw/doxa.md
9107171aa1c02fef325a2f63b5bdb27d16b0e2d8c99fab63bb15fcecdc0adea8  raw/doxa.normalized.md
274d455381e59b7c406668d72932d5816e78544f67320cd5002e4a9e6a696a0c  review/.gitignore
d4507f5b2ca4201d9837caf013de16f30070cb3e2f5558eb66f7ded9dfd2c10d  review/DECISION.md
ce7e97e85bc35772d534bff96ec816c3b03d5bf8cbe4a646810712edcdbdbeb3  review/audit-codex.md
d6a20bd6e9c515c6802eb344089c879e5b011e9ea443220f46633b337d70901a  review/audit-fable.md
8803b1f6c661f83809cb1aec7500f67fb69dd38387948f73ba3c73ba0b758799  review/evidence/assert-figures.log
8803b1f6c661f83809cb1aec7500f67fb69dd38387948f73ba3c73ba0b758799  review/evidence/audit-assert-figures-r3.log
e4d25cbb6bfcb30a010b56ab4ad9d1fd402a107168f7e095160df9252abef21a  review/evidence/audit-assert-figures-r4.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-assert-figures-r5.diff
6b9179dfc44c87ec7456adfec17f150cf24fdc6aa8e2b3d46fefd84b094d5df6  review/evidence/audit-assert-figures-r5.exit.txt
8803b1f6c661f83809cb1aec7500f67fb69dd38387948f73ba3c73ba0b758799  review/evidence/audit-assert-figures-r5.log
58c6e4bfa1f2e87af3f0b14fa1910ab0bd961fd25a6381f26788f3f5e6e4e964  review/evidence/audit-bacon-install-check-r3.log
1c973b9220328cbd58911d511addd8e9f453140a527e19bc741418f8e077971d  review/evidence/audit-bacon-install-check-r4.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-bacon-install-check-r5.diff
e0726887864aafffdd3b2357f48fe96904e2f80fe444a76222b15c792f179f77  review/evidence/audit-bacon-install-check-r5.exit.txt
58c6e4bfa1f2e87af3f0b14fa1910ab0bd961fd25a6381f26788f3f5e6e4e964  review/evidence/audit-bacon-install-check-r5.log
8803b1f6c661f83809cb1aec7500f67fb69dd38387948f73ba3c73ba0b758799  review/evidence/audit-codex-r2-assert-figures.log
58c6e4bfa1f2e87af3f0b14fa1910ab0bd961fd25a6381f26788f3f5e6e4e964  review/evidence/audit-codex-r2-bacon-install-check.log
d313e3ab0804940373b7ba5681f7166321cd3c596d37ede86b82471c01f91275  review/evidence/audit-codex-r2-feature-shape-check-private-cargo.log
087c33e4d5be367c3a530ab55ed724c7d5c44de52454305f6bdf009d8f2cf3ac  review/evidence/audit-codex-r2-feature-shape-check.log
1e3294f5af9de271fa04b71b6f8c99eb52fff0cb4d8381b023386efe754f1f8c  review/evidence/audit-codex-r2-issue-responsiveness.log
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-codex-r2-parameters-check.log
f984bb8461bdefea8d09e79dba31bae7ec0e5a76d786b3d178698bd827a9a2ea  review/evidence/audit-codex-r2-state-bound-check.log
22eb44036859c06d6af61839b7072671ab7f2546475fc23cd01d4bbca9a12e2c  review/evidence/audit-codex-r2.log
14ce04915cb945f3831e7199b40c44f078a1f136c0a67f5a4cd526a7107f72ad  review/evidence/audit-codex-r4-archive-lock-summary.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-bacon.diff
60da71be1032b26f5d062a2c9d11320c5b6fc4213f745fd1415907932c775631  review/evidence/audit-codex-r4-citations-rerun.log
c31be8dc4456ab52f9474736255a692d43f99d882ee7adb4661779879ab62cb6  review/evidence/audit-codex-r4-citations.log
c25abc946add141410f7ae48a5067f8a906a8762d7ebd48a797f6a19f626148f  review/evidence/audit-codex-r4-diffs-final.log
5f95dad34c4265bc785d4be7e8f623f187f30c7e3641b65937d42cdca3ca6919  review/evidence/audit-codex-r4-diffs.log
beff4ea9d5650bd9b4c196f87fa8ac6e17910884fdce05911aca7550c5df3b16  review/evidence/audit-codex-r4-empty-cargo-home-yanked.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-figures.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-issues.diff
c879c36a4ea1cdf9b210b581097afdc0b44e63ba55a08b8a444f3bd5c9c5a2d4  review/evidence/audit-codex-r4-package-cache-rw-open.stderr
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-parameters.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-retained-inputs-final.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-retained-inputs.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-flock.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-head-archive.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-inplace-1.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-inplace-2.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-inplace-3.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-shape-temp-index-archive.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-codex-r4-state.diff
0c609338454ef6dd7a8e925fff6c307e7b71c60b9e9d9419f4072fed2bfc25f3  review/evidence/audit-codex-r4.log
30d3f3a68bd9d365c680bef1af9e788b41366c0a6e94b1985988a13676ec6635  review/evidence/audit-codex-r5-citations.log
4cfc6ed0035b5a8d8a8a68d0443158c79fd364bdabba100eb9635352b4e37f5d  review/evidence/audit-codex-r5-integrity.log
3d3107bc87d7904d458c3bdb2ab08501f8a2c787362739cc3557650aebe58c3f  review/evidence/audit-codex-r5-revision-diff.log
1248ba1e2ac6810477f1ee904e5218fe5c2db3b3ff4d940db4c96cc38ac9ce51  review/evidence/audit-codex-r5-revision-paths.log
48e763e4b81f4d331c59782c779699a886f64905f3bd4e9ae8164f59c6402b3f  review/evidence/audit-codex-r5-yanked-shellcheck-without-directive.log
dc4e60215fd0fcbc39c54a14a8e4466fc938fdd46a0e857c4c3bc141d9abe1ac  review/evidence/audit-codex.log
e46c8b4a2df92daaec54bfd8a0c3e56cf045f830f7b57f0a9ff4321885ccf65a  review/evidence/audit-feature-shape-check-r3-archive.log
fbe62cf1431d40cbbfe34d362abd84ebc6adfb5537b241187764d0eed873f47c  review/evidence/audit-feature-shape-check-r3-hash-mismatch.log
e46c8b4a2df92daaec54bfd8a0c3e56cf045f830f7b57f0a9ff4321885ccf65a  review/evidence/audit-feature-shape-check-r3-inplace-1.log
e46c8b4a2df92daaec54bfd8a0c3e56cf045f830f7b57f0a9ff4321885ccf65a  review/evidence/audit-feature-shape-check-r3-inplace-2.log
e46c8b4a2df92daaec54bfd8a0c3e56cf045f830f7b57f0a9ff4321885ccf65a  review/evidence/audit-feature-shape-check-r3-inplace-3.log
2b9d1cfd82cca9f5515d518fa8fcbd4f8c04b350dfb51863431b403dc6a90f5e  review/evidence/audit-feature-shape-check-r3-local-mirror.log
ab8e34852def6615e5461ae65f3e4f21578a789903da141b2ad6a46f92fae586  review/evidence/audit-feature-shape-check-r3-mutation-skip.log
fc07729f54ae0fa066122abb91d136d03e58b2284376aa92c947e389840e6f7a  review/evidence/audit-feature-shape-check-r3-unreachable.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-feature-shape-check-r4-flock-control-holder-rerun.log
ace58fe27eae9d8b271ea1be6b50e4370b690e54e452cd962703f70deb2d480e  review/evidence/audit-feature-shape-check-r4-flock-control-holder.log
c7389b0e14d670538ffbe59b02f56069d59374e7b565d2d93a7b91845ee5f81a  review/evidence/audit-feature-shape-check-r4-flock-control-rerun.log
c7389b0e14d670538ffbe59b02f56069d59374e7b565d2d93a7b91845ee5f81a  review/evidence/audit-feature-shape-check-r4-flock-control.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-feature-shape-check-r4-flock-holder-rerun.log
ace58fe27eae9d8b271ea1be6b50e4370b690e54e452cd962703f70deb2d480e  review/evidence/audit-feature-shape-check-r4-flock-holder.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-flock-rerun.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-flock.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-head-archive-rerun.log
0e47279703c03a9f386caa6d786874b22b39697ad6baef1ecc108cfb10f31538  review/evidence/audit-feature-shape-check-r4-head-archive.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-inplace-1.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-inplace-2.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-inplace-3.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-feature-shape-check-r4-r5.diff
d04b1661147cffe27633959574205354f22ce1d0971598d6b536dc65d8f905cc  review/evidence/audit-feature-shape-check-r4-r5.exit.txt
f9bec8b0ea550e0a176eecdf201c18bd6bd3cdf94e366f952785d106ccfb555d  review/evidence/audit-feature-shape-check-r4-r5.log
d1543f7be07454ab0c967c2bc105e17bb3adec8a61d157390e953c8763696ac5  review/evidence/audit-feature-shape-check-r4-temp-index-archive-rerun.log
db9e97d8d2d86b60db4b2fff910ccccedecec4408d3e2a80e968cd72cfe8092b  review/evidence/audit-feature-shape-check-r4-temp-index-archive.log
1e3294f5af9de271fa04b71b6f8c99eb52fff0cb4d8381b023386efe754f1f8c  review/evidence/audit-issue-responsiveness-r3.log
febacf138a850f36fa1c59b55500ef2cc1732124ee944c20fec313453daf5b89  review/evidence/audit-issue-responsiveness-r4.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-issue-responsiveness-r5.diff
b194328f1f8106714fab69eaab06ad094dc8686b54160f1160c32d547b93f733  review/evidence/audit-issue-responsiveness-r5.exit.txt
1e3294f5af9de271fa04b71b6f8c99eb52fff0cb4d8381b023386efe754f1f8c  review/evidence/audit-issue-responsiveness-r5.log
72eedee816da8d3ec1166d5afc6698eae2aaede7c4aabf29af895e4f6223ac77  review/evidence/audit-owner-reference-check-r6-head-archive-path.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r6-head-archive.diff
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/audit-owner-reference-check-r6-head-archive.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r6-inplace.diff
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/audit-owner-reference-check-r6-inplace.log
66d22b850c44ab9b517210262da5662b920febc535feaeb69ae49b3f2889c35f  review/evidence/audit-owner-reference-check-r6-mutation-path.txt
824be65da197fb2263afe32d82fc28a3a50c7415451182993b16b4a209edb9bd  review/evidence/audit-owner-reference-check-r6-mutation-status.txt
ae8d6b67383e3bc4debb3cb16af5e3858799399eeddbeee707ef45f95ba6df95  review/evidence/audit-owner-reference-check-r6-mutation-workspace-path.txt
5220683b41bd14128056a29d35adb52a909b47d2da92792d51fea18df5baa0ea  review/evidence/audit-owner-reference-check-r6-mutation.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r6-r9-inplace.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r6-r9-inplace.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r6-r9-inplace.exit
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/audit-owner-reference-check-r6-r9-inplace.log
53956cd28d6ba900c0c61c34918ff8eb1032a7bd284bca30fc42acec52f15514  review/evidence/audit-owner-reference-check-r6-status.txt
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/audit-owner-reference-check-r8-archive.log
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/audit-owner-reference-check-r8-inplace.log
713e8d44eb3a3c004cbf643884c9b5d4658afcc06893f6c32b761b0a81c8e50e  review/evidence/audit-owner-reference-check-r9-archive-path.txt
8d93ff27b8ab1f5039756586c4cfe5388920c6adb33d7cf0ddc521ae98ed33d9  review/evidence/audit-owner-reference-check-r9-archive-root-path.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-archive-root.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-archive-root.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-archive-root.exit
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-archive-root.log
c890ea3cab9b5fdeb36b89654698665e30823a36ce7f4d2a710867f2aba9f488  review/evidence/audit-owner-reference-check-r9-archive.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-owner-reference-check-r9-archive.diff.exit
743c7850cccfba5e53a9002663ec1ddd1079315a98bdbfdde10e6044f56abefe  review/evidence/audit-owner-reference-check-r9-archive.exit
7f8779922f04ffc5283a356d2ff6884effe650a3e996897c0c7c2ccddcad3b60  review/evidence/audit-owner-reference-check-r9-archive.log
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-inplace-2.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-inplace-2.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace-2.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace-2.log.exit
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-inplace-3.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-inplace-3.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace-3.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace-3.log.exit
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-inplace.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-inplace.exit
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-inplace.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-mutation-failure.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-mutation-rerun-failure.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-mutation-rerun.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-mutation-rerun.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-mutation-rerun.exit
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-mutation-rerun.log
39b29421827a4d8993c1f36c8f4a7f8e61fada5df51f34627b469220278e897a  review/evidence/audit-owner-reference-check-r9-mutation-verified-failure.txt
1f10fa6598c3d3a3a9f13782ca0c92cc0b70b111626a64a24447ca74eb7f4d40  review/evidence/audit-owner-reference-check-r9-mutation-verified.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-owner-reference-check-r9-mutation-verified.diff.exit
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-owner-reference-check-r9-mutation-verified.exit
e77e4c7e705a6d846fd9538ea3f665e42e7b114949c01abcbb805b2107822270  review/evidence/audit-owner-reference-check-r9-mutation-verified.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-owner-reference-check-r9-mutation.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-mutation.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-owner-reference-check-r9-mutation.exit
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/audit-owner-reference-check-r9-mutation.log
912fdbefc8873478adef394db2ee2b9cd98f47005c9f89d701c7bd6c517768a9  review/evidence/audit-owner-reference-r6-live-fetch.log
0ef5dcf5309a6e996f0bd5e581526742e0f2555027d1ffa6022008e32edaead5  review/evidence/audit-owner-reference-r6-live-path.txt
73e40c2427f7caa06c85ee5f4a2152fe98d4e467bde0ffa079e0e88325c591a9  review/evidence/audit-owner-reference-r6-live-status.txt
fe35a4aba7ebb4c56059dd1515c2db43481c9390fb85efe83648df9dfe3315e4  review/evidence/audit-owner-reference-r6-live.log
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-parameters-check-r3.log
effe3ebfd1d71faa24a2eb1a9eaef0627a0f309c74940b8991d994693e0b15de  review/evidence/audit-parameters-check-r4.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-parameters-check-r5.diff
ab565c71d3bd2c8b7502cd6b7f21fea956e19a3f89287264d71aa0d0ec6fb735  review/evidence/audit-parameters-check-r5.exit.txt
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-parameters-check-r5.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-parameters-check-r6.diff
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-parameters-check-r6.log
ce82eeae27160d0a98d7005c8b4ea33ceb7b8b12362f4c4ab5934ea2f1a5870b  review/evidence/audit-parameters-check-r8-archive.log
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-parameters-check-r8-inplace.log
f4ed8ba008282a5bbf0463cd330e446b40dad5f37979c26fbd92db8f20771482  review/evidence/audit-r6-decision-diff.txt
8a97368fafe8ed1e3158ae25f832a08d54a47e91333c34d85e75a4b44909c3d2  review/evidence/audit-r6-empirical-section.txt
8803b1f6c661f83809cb1aec7500f67fb69dd38387948f73ba3c73ba0b758799  review/evidence/audit-r69-r9-assert-figures.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-assert-figures.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-assert-figures.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-assert-figures.log.exit
58c6e4bfa1f2e87af3f0b14fa1910ab0bd961fd25a6381f26788f3f5e6e4e964  review/evidence/audit-r69-r9-bacon-install.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-bacon-install.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-bacon-install.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-bacon-install.log.exit
de1339b474f05b6eb574ab822b12e3ffcbf858855f561439dc9f701d4d695fe3  review/evidence/audit-r69-r9-control-hits.txt
f9bec8b0ea550e0a176eecdf201c18bd6bd3cdf94e366f952785d106ccfb555d  review/evidence/audit-r69-r9-feature-shape.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-feature-shape.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-feature-shape.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-feature-shape.log.exit
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-h2-lines.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-independent-census.exit
d6bc995384815816be4d4387ba7d84ff2d5eef78f7f6f5a93ff295e21e6b21d1  review/evidence/audit-r69-r9-independent-census.log
1e3294f5af9de271fa04b71b6f8c99eb52fff0cb4d8381b023386efe754f1f8c  review/evidence/audit-r69-r9-issue-responsiveness.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-issue-responsiveness.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-issue-responsiveness.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-issue-responsiveness.log.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-ledger-count.txt
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-live-registry-authenticated.exit
97cbe27f603e7ef77bd11cb6d7f4802ec28fb3ef5edb6beb06f2d3244af10b5c  review/evidence/audit-r69-r9-live-registry-authenticated.log
53c234e5e8472b6ac51c1ae1cab3fe06fad053beb8ebfd8977b010655bfdd3c3  review/evidence/audit-r69-r9-live-registry.exit
5475c122848225a3a0efc2a32509183e2fffd9df920bb82365d3ded3d1db89a6  review/evidence/audit-r69-r9-live-registry.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-parameter-lines.diff
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/audit-r69-r9-parameters.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-parameters.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-parameters.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-parameters.log.exit
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-profile-hits.txt
de1339b474f05b6eb574ab822b12e3ffcbf858855f561439dc9f701d4d695fe3  review/evidence/audit-r69-r9-prompt-files.txt
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-revision-integrity-rerun.exit
4db187bd97b1cf9bf33e413cd2f1c68c8bb56568852d660369bc58fe257515fb  review/evidence/audit-r69-r9-revision-integrity-rerun.log
01ba4719c80b6fe911b091a7c05124b64eeece964e09c058ef8f9805daca546b  review/evidence/audit-r69-r9-revision-integrity.exit
00c5731f867a28c176e09abd2087623d9f9ac2760189581ff4eb5c5dc7819661  review/evidence/audit-r69-r9-revision-integrity.log
f984bb8461bdefea8d09e79dba31bae7ec0e5a76d786b3d178698bd827a9a2ea  review/evidence/audit-r69-r9-state-bound.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r69-r9-state-bound.log.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-state-bound.log.diff.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r69-r9-state-bound.log.exit
138594fc86e08d92aaf7aa252c89f88a05f05aaf158ce67e41171392e63c6745  review/evidence/audit-r8-rev6-to-rev7-default.diff
c9d61428adbab21ad7bb00c17090bbb712ebcd6eaa6f365e9259edec0e230fb2  review/evidence/audit-r8-rev6-to-rev7-U0.diff
a86649d9bfacd1046ab1096e52115fd64d505c0bad50632e5ee05bb03ffe985a  review/evidence/audit-r8-rev6-to-rev8-default.diff
512e7eda65ae7de11c3f8a95876562b2c099e9820d9027cd834ef5ebb417a853  review/evidence/audit-retained-evidence-r6-status.txt
e69259a88507d49522799da9f8bb03f17707af305b77d18f9e30a77596fea567  review/evidence/audit-retained-evidence-r6.log
f984bb8461bdefea8d09e79dba31bae7ec0e5a76d786b3d178698bd827a9a2ea  review/evidence/audit-state-bound-check-r3.log
e49ece4c85e1d08770780540cc8e2a50ed55ef77fc55f21cffa5927777c6dcd4  review/evidence/audit-state-bound-check-r4.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-state-bound-check-r5.diff
7b91cbb14c4d1c3b71e57f45bf65395c815947dcb3d7f5fb13ef9dbaefdfa999  review/evidence/audit-state-bound-check-r5.exit.txt
f984bb8461bdefea8d09e79dba31bae7ec0e5a76d786b3d178698bd827a9a2ea  review/evidence/audit-state-bound-check-r5.log
10789cf5e51f1cd1b9b951c39ee95680bc98edd03f91e94538c4cc58a9563467  review/evidence/audit-web-framework-stack-r7.log
8b823ee052fbdd8600a30febf40425297cf79bb44f820b88cbf7c7178ff5efe5  review/evidence/audit-web-framework-stack-r8.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-web-framework-stack-r9.exit
b805c5ce7d4d1c215b3655caa6f366df7ad26edd48f7628e00efd02fac0ef1c6  review/evidence/audit-web-framework-stack-r9.log
254631c5630c9958991caf3cae3f0f37060e9ec1c618b4500b83f35b3d67d641  review/evidence/audit-yanked-control-r5-archive-path.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-yanked-control-r5-archive.diff
357ccbd58c77483aaef388f97d7226977c063c81d6fc6520c391b6044d281b86  review/evidence/audit-yanked-control-r5-archive.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-yanked-control-r5-inplace-1.diff
357ccbd58c77483aaef388f97d7226977c063c81d6fc6520c391b6044d281b86  review/evidence/audit-yanked-control-r5-inplace-1.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-yanked-control-r5-inplace-2.diff
357ccbd58c77483aaef388f97d7226977c063c81d6fc6520c391b6044d281b86  review/evidence/audit-yanked-control-r5-inplace-2.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-yanked-control-r5-inplace-3.diff
357ccbd58c77483aaef388f97d7226977c063c81d6fc6520c391b6044d281b86  review/evidence/audit-yanked-control-r5-inplace-3.log
e4dcbeed691a909724dcac85ede06238eb4381f166f18a0faed04921d62f08b4  review/evidence/audit-yanked-control-r5-own-count.txt
ec962fed4d53bb7dfc42266aa61a469794b96e9a0036d27e339c425035a5f8c6  review/evidence/audit-yanked-control-r5-own-raw.log
58c6e4bfa1f2e87af3f0b14fa1910ab0bd961fd25a6381f26788f3f5e6e4e964  review/evidence/bacon-install-check.log
ab19d0cb482bc52bc0ab929c952320d245401080ca546139ce01d4746b34ecdd  review/evidence/feature-shape-check-r3.log
024c0d1a902dcc9c9c0ac70528d965077022a6f62eb55b9fec3ca44972d2df0e  review/evidence/feature-shape-check-r3.sh
f9bec8b0ea550e0a176eecdf201c18bd6bd3cdf94e366f952785d106ccfb555d  review/evidence/feature-shape-check-r4.log
5a5d8b89006001ee584e9d124c2b1e1e9c800e122d837df919e46d3005828965  review/evidence/feature-shape-check-r4.sh
de5080779a2823308386037f6ae1fdbe17b9259e08ad73791b61d30091d09437  review/evidence/feature-shape-check.log
5a82bbbe9e0cc24bba6a3d419ba833b2cf49c2ca12e72a9695bb13bbcd036e3d  review/evidence/fetch-owner-reference-r6.sh
7798ac727edd1bdc3ce126772b85a496c267cf8222841bc3ef8b92ef0fec31c7  review/evidence/fetch-owner-reference-r9.sh
1e3294f5af9de271fa04b71b6f8c99eb52fff0cb4d8381b023386efe754f1f8c  review/evidence/issue-responsiveness.log
8b38a428d196f2151315087d9722281eca4db7863363210e73250e8de51bdce2  review/evidence/owner-reference-check-r6.log
af160dd58338661f731649f1cb2976fe66fe673bac36dabf6f90b8aaf933b08a  review/evidence/owner-reference-check-r6.sh
a2af42207bf97fa17f33470a516c24628ae34822ccc9705dc8ce49b872058d78  review/evidence/owner-reference-check-r9.log
a27b1af4ef95ebdeca8de19f266ed2288f01a3c13126573d3420c498bb297410  review/evidence/owner-reference-check-r9.sh
89b2e1cc04919e0423932f61ccbc8b6b3492654efb11fdc10526c73a3b79cba1  review/evidence/parameters-check-r2.log
39a18be9016eca52c6f6e37e64ff98b9998214854d03d744ddce8ce6f346cc90  review/evidence/parameters-check.log
f984bb8461bdefea8d09e79dba31bae7ec0e5a76d786b3d178698bd827a9a2ea  review/evidence/state-bound-check.log
357ccbd58c77483aaef388f97d7226977c063c81d6fc6520c391b6044d281b86  review/evidence/yanked-control-r5.log
f762307359c2b49405d818434178b47abf9d5bddd1fcd5965faac6ab7f8821ce  review/evidence/yanked-control-r5.sh
```

The three copied subdirectories under `review/evidence/` hold 1005 further files, none of them staged by the packager and most of them ignored by the carried `review/.gitignore`.

## review/identities.json

The source run carried none; this file is new, written the way the seven written
earlier today were. `research_package.py build` accepts it — the refusal came
later, at publication-time validation of the staged Doxa bytes, not from this
file.

- `engine_reports` from the source run manifest's `operations` records: the three actors, their models and the Doxa operation id are quoted from it. `doxa.file` names `raw/doxa.md`; the packager stages the `.normalized.md` twin beside it. `codex` and `opus` have no twin, so their own bytes are staged.
- `audits` from the two round-9 audit headers.
- `synthesis.actor` -> `synth-opus-2026-09-12T204004Z-d02022bf6f42-r9`: PATTERN-FOLLOWING, not a quote, and it names the SOURCE run, the run in which the work was done. The decision names its synthesizer only as "fresh Claude Opus 5 context"; no record in either run gives an actor string. This is the convention used for R60 earlier today.
- `empirical` -> the first rerun the round-9 empirical audit's `## Rerun` states, which is exit 0: the decision's six empirical scripts, each exiting 0, whose complete combined output is `review/evidence/audit-web-framework-stack-r9.log` with aggregate exit code 0 recorded in `review/evidence/audit-web-framework-stack-r9.exit`. `argv` is the first of those six as the combined log's own `== argv:` header records it; `cwd` names the other five, so the single argv is not read as the whole rerun.
  `toolchain` states what that audit records, plus the per-script toolchain headers inside the combined log, and notes the separately recorded `owner-reference-check-r9.sh` runs and the mutation control that exited 1.
