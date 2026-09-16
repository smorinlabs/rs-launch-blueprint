# Carried-forward run

This run submitted no provider operation and ran no check. It exists only to
republish R38 commit-message-linter at the owner-accepted revision 9, because
the published run `2026-09-05T151356Z-c46d732f98ed` is immutable
(`publication apply` refuses: "published run is immutable; prepare a new run
for another publication").

- source run: `research/runs/R38/2026-09-05T151356Z-c46d732f98ed` (state `published`; untouched)
- reason: republication of owner-accepted revision 9, DECISION.md sha256 `c2e9b6e1f1cf096b640ecd2925c8f79010bf7e875a9ce91d18a1d3ad84b3ce24`
- owner acceptance: `docs/port/OWNER-ACCEPTANCES.md` Wave 0 row R38, revision 9, accept, 2026-09-15 re-bound 2026-09-16
- superseded published copy: `research/topics/38-commit-message-linter/DECISION.md` sha256 `97da7f169f26fce8f9b43c3d6c2eb0971b991f45b0d00ae2a91c5ddc3cbe4437`, preserved verbatim under `## Supersedes` in the carried DECISION.md
- audit transcripts, receipts, archived rounds (`audit-*.rN.md`) and provider receipts were NOT copied; they stay in the source run.

## Files copied from the source run (sha256 of the copy)

```
a018928b40ee1238d29c05911d08288b34cc06ee594be162892976b48dce08e2  raw/codex.md
a3f2978639bc460b15067242a41a45c812fad8b08789bd4657ef149690f3c491  raw/opus.md
90f4e6a76ec66ea66823fa01ed8aeb395c31b2220d6c9f8925a215bb9cf5dbb7  raw/doxa.md
bbe72675e8d3d6a9daa966978805f30a9f3d8d2f24fac2169595da2299b5624e  raw/doxa.normalized.md
c2e9b6e1f1cf096b640ecd2925c8f79010bf7e875a9ce91d18a1d3ad84b3ce24  review/DECISION.md
a0e7528824d0d88d14640f2a9c253682d2ae82991f106128dec8b84746fb35c9  review/audit-codex.md
cf98049f9a6d9002c40c365dc4c7121c024269b56fe72dc18352cca6bc9443fa  review/audit-fable.md
ab707e6c9a0d736e35ba05b31dad9a4b2d77f0fee1dd05be063799a5e5d34285  review/evidence/audit-codex-r4.log
3951b6209d0638a5cafeedfa1675c10d23608515a1c46a0a51d9be22ae6c9ca0  review/evidence/audit-codex-r8.log
796d8b76eec49b1536c8db6cdfd8c52c4349a06c387d29ff7befe546c6022438  review/evidence/audit-commit-message-linter-r2.log
252140fd74e2feb23d71a3d525d1746b8bbc6926ab0e24da6e1d1a50d1e70a5e  review/evidence/audit-commit-message-linter-r3.log
030a037952fe4e99c751bef95b2f9eda384b6c21cd33f14c1442df0e790e70dd  review/evidence/audit-commit-message-linter-r5.log
1467aca88d84d0e2c1bd02e64593583f7384c1c4e69f7523d3ca7457fe949a56  review/evidence/audit-commit-message-linter-r6.fixture-path
6da4e6e09983e7ab326dcb2cba0ca184ceb431b71377cb24c6c8fde1d1d0e190  review/evidence/audit-commit-message-linter-r6.log
27dad78ee0b30ae9be2bb9715ddfd7cf2a09634d248abfb152162f3ab8bac2a2  review/evidence/audit-commit-message-linter-r7.log
8a0ff2c23411ac428694a1f2c78508b8e419e081b3118007b2fc78a0b02f0f73  review/evidence/audit-commit-message-linter-r9-archive-path.txt
94eb828d48ee484255a75af10fcd4c0413af0b3a114b38848bb28bbfd3bb05e1  review/evidence/audit-commit-message-linter-r9-archive.log
eca23d4217411b5c42eaf78afb46f2a750280ab547f6cee1ee2b8367c48c148e  review/evidence/audit-commit-message-linter-r9.log
dae0862e4f46b6874e931cb7205955227ca1e22e52be270ef6de6a366a56ebc4  review/evidence/audit-commit-message-linter.log
f4b05470dcaff89e8e12f8265bb2ea7cdeb76ed8e2f3b680d309c7ae2c61feca  review/evidence/audit-r6-acceptance.log
d3c309b9ccae61f51a6f422d41b7f3c966f4b4d8ddf10a0e682c25455659d85f  review/evidence/audit-r6-citation-checks.log
e9e985868c0ba278f452e2122724bda05ae81db94bf6cc34ef59e6beff8e620b  review/evidence/audit-r6-evaluation-stable.diff
f7354e50185bdf695702b205655918ede2113cc1f17969d66ac1895f36ca73da  review/evidence/audit-r6-recorded-normalized.log
fb36c6c036e0b5c875f9432285dc1aa15a2fe07081ffa8b07a502b68efe1b96a  review/evidence/audit-r6-rerun-normalized.log
c598d2398b4d39d7c1e2ea4997ffd3a3e8c7ee248eeedc40a797b9bbf75b5d87  review/evidence/audit-r6-selected-discovery.log
97da7f169f26fce8f9b43c3d6c2eb0971b991f45b0d00ae2a91c5ddc3cbe4437  review/evidence/audit-r6-supersedes-extracted.md
03978625e7b3781c1c78b65f9d310e1d894b35a77fe142ebe90180a8450e631e  review/evidence/audit-r6-supersedes.log
1d6624c87d4a964c42cece87a51e993f3af10188281aad91d3c9e886e729cbcb  review/evidence/audit-r7-archive-acceptance.log
7e0139c3d966b58a91cf885fac5cae46a7e8e9106b8628e9d78c2579a3bd60db  review/evidence/audit-r7-archive-evaluation.log
c73e64d9fd87af72f47ee7058eeb39a31b7d89d9cdbfbfa33e4ed076ca566573  review/evidence/audit-r7-citation-checks.log
6530561d4cac8c14369f339f0c0b70fd9cb6932b5be982dbe012a85d855fa558  review/evidence/audit-r7-cited-vs-archive.diff
8c1bbb217a53fbf1056a75a36207fd2a0f7da7ad212b7ca03052deabc17005a0  review/evidence/audit-r7-cited-vs-inplace.diff
bba778bf9313e02d54d17e1c58432cf04963775860fdd482245d9f8f83a7079d  review/evidence/audit-r7-cited-vs-pure-archive.diff
b1ee9c0056f6a875bfbf0848a2332691ffc8924325bd1fdc337e55e4d91401bc  review/evidence/audit-r7-crossrun-compare.log
e08bb22cc43a0eeb92ec6a2aa2d562520ecd32fce7b873035ff558399a0d42e9  review/evidence/audit-r7-inplace-evaluation.log
6cbae562c7ce69371d479d73949fd48ea13e5d67ba5793c46970723679bf02f5  review/evidence/audit-r7-pure-archive-evaluation.log
1c59ad0568c4c0c73a588b776a1181b86c47470760a49148b1b524ab89d2214b  review/evidence/audit-r8-acceptance-vs-cited.diff
b3395eed3cc2577f13241d04d331c223c9b7693d6863e8da4ec47c69d6f23b36  review/evidence/audit-r8-citation-checks.log
eff897a9e83965f8a77a93b166c4a80ab466e4ef2f5e1ee9be20fa608b6a9a43  review/evidence/audit-r8-crossrun-compare.log
f5b1e039b0e1184f37b3f63760cfc5b47efc0d87c6701f4d26ecc2966ab0fe7d  review/evidence/audit-r9-archive-mutation-path.txt
3b36ad3c5b73ddacf4eb04ed69b8083d8ad617257ca3d80b26165cd972bbf29d  review/evidence/audit-r9-archive-mutation.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r9-archive-postcommit-vs-audit.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r9-archive-vs-cited.diff
ecbafd93397844fffab5e607a70c386fd200c669ee28155228606883246df5a8  review/evidence/audit-r9-citation-checks.log
858092db44d1c42a4f25674e6389cc38d8d861f73ffedc3b8c305e0e16adc19d  review/evidence/audit-r9-claim-checks.log
0bad633bfb0b3682d11212bd33d641504ef95634737bd3ae8cbd4e34b7ee5b3e  review/evidence/audit-r9-history-invariants.log
8d7539b8229240af8eaa11f2da2ef8454cd9ba2d8a588a307fcbdc97d982d1a6  review/evidence/audit-r9-repository-mutation-path.txt
25af53ed47c4bcde050f8a8c0c18de5d606d657991afd500af417c6ad2172bed  review/evidence/audit-r9-repository-mutation.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r9-repository-vs-cited.diff
8f63fd41c8be4c304e35036a53c89a14f505e206fc51c9be92c78f5dbd573648  review/evidence/cargo-commitlint-2.1.0-cargo-audit.log
fd5ea6d0357ca2e1a1be7c1e634cf74c15b335087008fddf660b62660fd83915  review/evidence/cargo-commitlint-2.1.0-comparison.log
c1a95dcf45d0198b40865f684855f642b07a48b36ed110365d42b2952d891a71  review/evidence/commitlint-21.0.2-comparison.log
54ca84c641c2ab0de53d5b13f579b5b118c0eea03665e3c1dace2c4a5e316014  review/evidence/committed-1.1.11-acceptance-r2.log
7898edf22dab63e5bc4a3a47f3a82253bd0d98c0992cf19ebbdb5ae4ac7230ab  review/evidence/committed-1.1.11-acceptance-r4-linux-aarch64.log
4ab7bb3f834a35a1930beadf1476bb3d097ad19b4f86be8d15d2bfb988115f53  review/evidence/committed-1.1.11-acceptance-r4.log
015061611b3d91d146e72a0a61c565c262823feecf4a05d08e82956fc3836a91  review/evidence/committed-1.1.11-acceptance.log
f8ff353bda568dc161d19a9a8952d552d17c5f1cbbeef4e0d1b92de36f6e7190  review/evidence/committed-1.1.11-cargo-audit-isolated-cache.log
799ab6f8b5d7e3e9cebabb3504f6ac800782baf5282e21d5f15cae13dc521cbc  review/evidence/committed-1.1.11-cargo-audit.log
d5520f9d1bd2c8825e616b7993e6d542160945edc846d0c43376e1c2ed0bd57f  review/evidence/conventional_commits_linter-0.17.1-evaluation.log
89f2a14a1cb74e6c3669775795e3925c9ed933998b06cd3181229dd2196ee094  review/evidence/conventional_commits_linter-0.17.1-evaluation.r6.log
eff897a9e83965f8a77a93b166c4a80ab466e4ef2f5e1ee9be20fa608b6a9a43  review/evidence/r38-crossrun-compare-r7-in-archive.log
b1ee9c0056f6a875bfbf0848a2332691ffc8924325bd1fdc337e55e4d91401bc  review/evidence/r38-crossrun-compare-r7-in-repository-r9.log
94eb828d48ee484255a75af10fcd4c0413af0b3a114b38848bb28bbfd3bb05e1  review/evidence/r38-crossrun-compare-r9-archive-postcommit.log
94eb828d48ee484255a75af10fcd4c0413af0b3a114b38848bb28bbfd3bb05e1  review/evidence/r38-crossrun-compare-r9-archive.log
eca23d4217411b5c42eaf78afb46f2a750280ab547f6cee1ee2b8367c48c148e  review/evidence/r38-crossrun-compare-r9.log
bf56784902077d169ae37a31143c7e694a3d91646d0dab4efcf3bc424936c1c9  review/evidence/r38-crossrun-compare-r9.sh
8a35722857f73f8144f1484baea8a1b6ebf787599c5a5cec34bf3cd19c003274  review/evidence/r38-crossrun-compare.log
c8ee2c861b9cd8d4d93b19ee4af18e925b6affedd6a438632001cc26786544a5  review/evidence/r38-crossrun-compare.sh
cf9ffcb2b84383c2fc797a86539612e3aaeff22753384f68d04cc2204eb501fa  review/evidence/rev6-evaluate.sh
```

## review/identities.json

Copied from the source run, then edited for round 9:

- `audits.empirical.actor` -> `audit-codex-2026-09-05T151356Z-c46d732f98ed-r9` (matches `review/audit-codex.md`)
- `audits.judgment.actor` -> `audit-fable-2026-09-05T151356Z-c46d732f98ed-r9` and `audits.judgment.model` -> `claude-opus-5` (both match `review/audit-fable.md`; the source run recorded the revision-5 judgment auditor, model `claude-fable-5-1`)
- `synthesis` -> `synth-opus-2026-09-05T151356Z-c46d732f98ed-r9`, model `claude-opus-5[1m]`, family anthropic, named in line 3 of the carried `review/DECISION.md`
- `empirical` -> the round-9 executed rerun, taken from `review/audit-codex.md` `## Rerun`.
  `argv` reproduces that section's `argv:` line exactly. `cwd` states the repository cwd that section records, then names the clean-archive leg it also ran, because the audit records two legs and only the argv leg is asserted here.
  `toolchain` states only what the audit records (macOS 26.4 arm64, Rust 1.98.0, Cargo 1.98.0, Git 2.50.1) together with its counted outcome.
- `engine_reports` left unchanged: those are the true actors of the copied raw reports.
