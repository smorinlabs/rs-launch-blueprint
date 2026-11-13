# Carried-forward run

This run submitted no provider operation and ran no check. It exists only to
republish R33 property-and-snapshot-testing at the owner-accepted revision 6,
because the published run `2026-09-05T164358Z-eae89906c763` is immutable
(`publication apply` refuses: "published run is immutable; prepare a new run
for another publication").

- source run: `research/runs/R33/2026-09-05T164358Z-eae89906c763` (state `published`; untouched)
- reason: republication of owner-accepted revision 6, DECISION.md sha256 `4e0ae20af2cf39baeb60bc66e2890a54f35b6aacb38a0e8aeb75ca0f2ce08012`
- owner acceptance: `docs/port/OWNER-ACCEPTANCES.md` Wave 0 row R33, revision 6, accept, 2026-09-15 re-bound 2026-09-16
- revision 6 is the title-only retitle plus the line-number corrections that depend on it, so that `check_history` accepts the republication: it needs a date-first `# YYYY-MM-DD …` heading before `## Supersedes`. Both round-6 audits re-ran against the retitled bytes and approve.
- superseded published copy: `research/topics/33-property-and-snapshot-testing/DECISION.md` sha256 `1bf96b43e0198e07bccca2ca4ecf0d5a6a2afb939260d896b8eca4814757a068`, preserved verbatim under `## Supersedes` in the carried DECISION.md
- audit transcripts, receipts, archived rounds (`audit-*.rN.md`), `review/empirical/` and provider receipts were NOT copied; they stay in the source run. The empirical entry below therefore names a script path that lives only in the source run, as the R01, R07 and R42 carried-forward runs also do.

## Files copied from the source run (sha256 of the copy)

```
d8dee79aa163ab80036e03ca49810e1fec845b0260a5aec111e50395462b4ee3  raw/codex.md
71864287004f2b77d108fcb5805e3e9aec620fd2882575954fdd91adf6c5cc86  raw/opus.md
4e0ae20af2cf39baeb60bc66e2890a54f35b6aacb38a0e8aeb75ca0f2ce08012  review/DECISION.md
0e8ed4cf1811c891ab0bbf675ca604912673f0372024bcd626a086648876af28  review/audit-codex.md
be87f285d976a57f972abe0ae4efb42084bc969637deefaaeb5cd3cdbe20f928  review/audit-fable.md
226de4671be22108e8a62c72ba1d43554510502ad2fa582d6cb3d95cbc873f95  review/evidence/adoption-figures-2026-09-10.txt
d3a24f5a311d0a433f70cf3b7a66fd09344ad458bf1010015ab89136f0b47337  review/evidence/adoption-figures-2026-09-13.txt
b1533cb611ab1941398619f269dc09a80ad8bf9845fa13a1b199fdf15430670a  review/evidence/audit-property-and-snapshot-testing-r1.log
a2ed227aa71e5d549f0fff7dc3ad5c1592b166b9ee6aad209c87889eaebf0dd3  review/evidence/audit-property-and-snapshot-testing-r2.log
6342b5217b2e9c2ce9c3c31ad6ad46edfc14b0f90a06f02b3bbaab982431dfed  review/evidence/audit-property-and-snapshot-testing-r3.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-property-and-snapshot-testing-r4.exit
93fb18d4f1d6a7054b7541e027b8ba2fc64d5b373cd3f916f6bf6408cebf728d  review/evidence/audit-property-and-snapshot-testing-r4.log
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-property-and-snapshot-testing-r5.exit
b969777d79827faa0f8ea1cee8d4fa8dd6b4c80860e304eb35126e31eae88e44  review/evidence/audit-property-and-snapshot-testing-r5.log
e8b2637f84ef93d0e28fdf9a67405c5e296012a5370574fcad82b0ffa5876382  review/evidence/audit-property-and-snapshot-testing-r6-archive-git-root-path.txt
90516897606ff8462396d84458f506ab56ac5589e4561740edbbdcc569040b3c  review/evidence/audit-property-and-snapshot-testing-r6-archive-git-root-vs-saved.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-property-and-snapshot-testing-r6-archive-git-root-vs-saved.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-property-and-snapshot-testing-r6-archive-git-root.exit
5a631b0f01631b37344475d3bf50d516fd1bfdde444c15a4d5b6303d916a8eb6  review/evidence/audit-property-and-snapshot-testing-r6-archive-git-root.log
50a7ed98582b17cd61fd379a443551bf2b06a0c9e339bb749fd9bddf3f5ea46e  review/evidence/audit-property-and-snapshot-testing-r6-archive-path.txt
be3f9006e595c5d4b29cfb56245e32e35a2d264bb78fc0129670a35c8fb46511  review/evidence/audit-property-and-snapshot-testing-r6-archive-vs-saved.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-property-and-snapshot-testing-r6-archive-vs-saved.exit
f0b5c2c2211c8d67ed15e75e656c7862d086e9245420892a7de62cd9ec582a06  review/evidence/audit-property-and-snapshot-testing-r6-archive.exit
62256c9bf5332c8fd9977ca0f39af76aeb55846d1e2c3c10a1d86f1c4e0ab434  review/evidence/audit-property-and-snapshot-testing-r6-archive.log
9aaa9de1468764ce2a4c0b6e810f2e83e529bc306ef147b1f7c0aca0e3bde54c  review/evidence/audit-property-and-snapshot-testing-r6-vs-saved.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-property-and-snapshot-testing-r6-vs-saved.exit
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-property-and-snapshot-testing-r6.exit
d6d01c1a7219ff1a14d18c99c5eeca131dd9fcd8dfa429bd7d260521d2dfa6a8  review/evidence/audit-property-and-snapshot-testing-r6.log
3825e6de7adaa216e3a560e6271eff217558934f6a3619be00614cf9846b8e83  review/evidence/audit-r3-citation-spot-checks.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r3-normalized-vs-r2.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r3-vs-published-r2.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r3-vs-saved-r3.diff
5cdbdf9dcf50d55f08a0d5d465ac1beb86e9d5e5e22a152aaae1079594d7e9d6  review/evidence/audit-r33-r6-citation-spotchecks.log
b41adba0b9fef5de9152fae3db5d0b3d6c668661573778bcbb89487f644f89ec  review/evidence/audit-r33-r6-integrity.log
1a775f675292b243d574ed53311b3a428e2ff54b3e528c2d231bb318964eed65  review/evidence/audit-r33-r6-preflight.log
2c1a891866a7eff23d30a55c3ca71f1dc387d003e8d32f4e2b75c50129d286ad  review/evidence/audit-r4-citation-spot-checks-pass.log
e94b3485a3417c7f2d83902accca26f0f646396cc577f1406bd6ec576e6908e8  review/evidence/audit-r4-citation-spot-checks.log
625616a4bc734d3e754017f054037671d480bbf1483f86edacb1908b713c7322  review/evidence/audit-r4-inputs-vs-port-parameters.diff
9aaa9de1468764ce2a4c0b6e810f2e83e529bc306ef147b1f7c0aca0e3bde54c  review/evidence/audit-r4-rerun-vs-saved.diff
4355a46b19d348dc2f57c046f8ef63d4538ebb936000f3c9ee954a27460dd865  review/evidence/audit-r4-rerun-vs-saved.exit
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r4-supersedes-vs-published-r2.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r4-vs-published-r2.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/audit-r4-vs-published-r2.exit
c30b146c0246aeb35fd259ad4fcb16a5d4daea657206e726678a5a5274ae1f6f  review/evidence/audit-r5-citation-spot-checks.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/audit-r5-normalized-vs-recorded-r5.diff
a0ed3d655f73889455092560b7f48c5edfaac7583d3dc091a3a0842ca6fec9da  review/evidence/audit-r5-recorded-rerun-vs-saved.raw.diff
9aaa9de1468764ce2a4c0b6e810f2e83e529bc306ef147b1f7c0aca0e3bde54c  review/evidence/audit-r5-rerun-vs-saved.diff
99656fa71f0eabc66288a64c963facbe61b8106cbe01d1b040d83e07f68b7efe  review/evidence/audit-r5-rerun-vs-saved.raw.diff
9179236e38f3e18cc178176b7d8c738a0c8e669ccd0d0a21dae80633c759c2fb  review/evidence/audit-r5-vs-recorded-r5.raw.diff
286889981a60ab12e6d32d2681cc2f6581868b7fbc6e40efedb0de1e764504ac  review/evidence/property-and-snapshot-testing.log
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/r4-postedit-vs-saved.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/r4-rerun-vs-saved.diff
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  review/evidence/r4-vs-published-r2.diff
9a271f2a916b0b6ee6cecb2426f0b3206ef074578be55d9bc94f6f3fe3ab86aa  review/evidence/r5-rerun-2026-09-15.exit
9ff06aef34af5259f878ac6153eae8bd9d9ed438dcd43b55a362f17e8d6dc2bf  review/evidence/r5-rerun-2026-09-15.log
9aaa9de1468764ce2a4c0b6e810f2e83e529bc306ef147b1f7c0aca0e3bde54c  review/evidence/r5-rerun-vs-saved.diff
```

## review/identities.json

Copied from the source run, then edited for round 6:

- `audits.empirical.actor` -> `audit-codex-2026-09-05T164358Z-eae89906c763-r6` (matches `review/audit-codex.md`; model and family were already `gpt-5.6-terra` / openai)
- `audits.judgment.actor` -> `audit-fable-2026-09-05T164358Z-eae89906c763-r6` (matches `review/audit-fable.md`; model and family were already `claude-opus-5` / anthropic)
- `synthesis.actor` -> `synth-opus-2026-09-05T164358Z-eae89906c763-r6`: PATTERN-FOLLOWING, not a quote. The decision names its synthesizer only as "a fresh context that produced none of this item's raw reports", so the source run's recorded prefix and model are kept and only the round suffix is changed.
- `empirical` -> the round-6 executed rerun, taken from `review/audit-codex.md` `## Rerun`, which records argv `bash review/empirical/r33-checks.sh`, the run directory as cwd, exit code 0 and log `review/evidence/audit-property-and-snapshot-testing-r6.log`.
  `cwd` carries the clean-archive leg after the literal path, following the revision-6 precedent set by the R42 pilot.
  `toolchain` states only what the audit records, including the comparator's exit 1 and the reason that audit gives for it, so the exit-0 claim is not read as a claim that every comparison matched.
- `engine_reports` left unchanged: those are the true actors of the copied raw reports.
