decision-sha256: 6a26da1a9ef708d28c922c3fb8530e58649f4d2f5699fb1ba10800f8bb28df49
actor: audit-codex-2026-09-05T163018Z-d7ade3a111f8-r11
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I ran `mutations-r11.sh` four times against the available pinned sibling repositories: ordinary ambient `PATH` and the required no-credential, scratch-`HOME`, mise-first form; each from this run directory and from a clean `git archive HEAD` extraction. The no-credential runs unset `GH_TOKEN`, `GITHUB_TOKEN`, `R17_GH_TOKEN`, and `GH_BIN`. All four exited `0`; their complete outputs are `review/evidence/audit-codex-r11-worktree-ordinary.log`, `review/evidence/audit-codex-r11-worktree-noauth.log`, `review/evidence/audit-codex-r11-archive-ordinary.log`, and `review/evidence/audit-codex-r11-archive-noauth.log`. Each ends `mutation-harness failures: 0` and the specified passing result.

The two mutants exit `1` as required. Mutation 1 has only `08h`, `08i`, and `08j` in its observed failing set; mutation 2 has only `08e`. Every rerun prints the matching `MUTATION CHECK failing-set` result. The no-token runs name `04g`, `04h`, and `13q` as skips; archive runs also name the no-`.git` `13q` skip. The live anonymous core reading was `60 20` before and after each of my reruns. That differs from the recorded historical `60 0`, but satisfies the decision's stated rerun rule: equality within the run, rather than a mutable remaining-budget value.

Toolchain: `/usr/bin/grep`, `/usr/bin/curl`, Bash, Python 3.14.7, and the pinned local py and ts Git repositories. Five cited primary-source URLs returned HTTP 200 through `/usr/bin/curl`; full command output and verification evidence are in `review/evidence/audit-codex-r11-verification.log`.

## Findings

- `run-checks-r8.sh` has exactly the stated request sites: one of its two `/rate_limit` branches at lines 218/221 and four `api_fetch` calls at lines 353, 842, 843, and 884. Section 08 has zero API request lines. The mutation proof therefore still executes its target section live.
- The installed shim boundary is effective: an unrecorded GitHub API path exits 22 with an empty body and `no recorded fixture`; a non-GitHub Rust-host request passes through to the real curl. All four rerun logs contain zero `no recorded fixture` and zero `mise ERROR` occurrences.
- The fixture sweep found no credential-shaped value. The lexical word `token` occurs only in manifest prose and public JSON field names, including empty `temp_clone_token` fields; it is not a credential value. The committed revision-11 mutation logs contain zero `stargazers_count` fixture-counter fields.
- The unchanged digests match: `mutations-r9.sh` `774eb8d4cdb1693a5168196c8082d5af0d04b3e72b2f72970b96125ce06ecb61`, `mutations-r8.sh` `0663adc43b52b35a88008865944604306850ecadfce9ba9899b4a628cd088fcb`, and `run-checks-r8.sh` `697ea3b1d47e0284e494a6c7279e994370ba0ad0ddca168cdb8b4a78a0a540bd`. `git diff f7367c6^ f7367c6 -- review/evidence` reports no changed r8/r9 log. The four `- assumes` lines equal the corresponding `docs/port/PARAMETERS.md` values.

## Assessment

Revision 11 repairs round-10 F1/JF-7: the target-only falsifiability check no longer depends on the anonymous GitHub API budget. JF-8's section-00 explanation correctly names both `run-checks-r7.sh` and `run-checks-r8.sh`. The decision accurately limits the fixture boundary and does not treat the fixture-fed, non-target labels as proof for section 08.
