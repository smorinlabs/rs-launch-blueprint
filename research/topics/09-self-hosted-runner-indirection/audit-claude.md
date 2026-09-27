actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 13c727034f25b4e0c245f5ff402661ac79d7e9469416b0ff3a6810fcc95184e5
verdict: approve
unresolved-findings: none

# R09 empirical audit — revision 4

This audit checks R09 `review/DECISION.md` revision 4. Before reading anything else, I ran `shasum -a 256` on it. The result, `13c727034f25b4e0c245f5ff402661ac79d7e9469416b0ff3a6810fcc95184e5`, matches the expected hash. The audit judges only two things: whether the evidence actually executes as claimed, and whether that evidence supports the decision's claims. It does not judge the recommendation's merit.

I ran this audit on 2026-09-27 from `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. The host was `Darwin 25.4.0 arm64` with `bash` 5.3.20, `actionlint` 1.7.12 at `/opt/homebrew/bin/actionlint`, and `python3` 3.14.7. I made no network calls. I read no `audit-*.md` file for any seat or revision, no `R09-r*-snapshot.md` file, and nothing under `research/topics/*/raw/`. My only writes were this file and scratch files under `/tmp/r09-audit-r4/`.

## 1. Evidence integrity

Command, run from `review/evidence/`: `shasum -a 256 -c SHA256SUMS`

Observed: `r09-actionlint.sh: OK`, `r09-inputs.sh: OK`, `r09-sources.sh: OK`, `r09-scratch.sh: OK`, `actionlint.candidate.yml: OK`.

## 2. Reruns and byte comparison

Each script ran from the repository root with its output redirected to `/tmp/r09-audit-r4/<name>.log`. Nothing under `evidence/` was overwritten. For each script:

- Command: `bash research/runs/R09/2026-09-26T190130Z-c43fa5d1b102/review/evidence/<name>.sh > /tmp/r09-audit-r4/<name>.log 2>&1`
- Comparison: `cmp` against the committed `evidence/<name>.log`. On a mismatch, I ran `diff` and then a second diff with the `INFO: date-utc` lines excluded.

| Script | Exit | Observed summary | `cmp` result | First differing line (committed → fresh) | Diff with `date-utc` excluded |
|---|---|---|---|---|---|
| `r09-actionlint.sh` | 0 | `SUMMARY: PASS=24 FAIL=0 SKIP=0` | differ: char 127, line 3 | `INFO: date-utc 2026-09-27T15:50:27Z` → `INFO: date-utc 2026-09-27T16:08:12Z` | identical |
| `r09-inputs.sh` | 0 | `SUMMARY: PASS=21 FAIL=0 SKIP=0` | differ: char 28, line 1 | `INFO: date-utc 2026-09-27T15:50:29Z` → `INFO: date-utc 2026-09-27T16:08:14Z` | identical |
| `r09-sources.sh` | 0 | `SUMMARY: PASS=10 FAIL=0 SKIP=0` | differ: char 28, line 1 | `INFO: date-utc 2026-09-27T15:50:29Z` → `INFO: date-utc 2026-09-27T16:08:15Z` | identical |
| `r09-scratch.sh` | 0 | `SUMMARY: PASS=3 FAIL=0 SKIP=0` | differ: char 28, line 1 | `INFO: date-utc 2026-09-27T15:50:30Z` → `INFO: date-utc 2026-09-27T16:08:16Z` | identical |
| **total** | | **PASS=58 FAIL=0 SKIP=0** | | | |

The only byte difference in any log is the wall-clock timestamp line that each script prints. Every `PASS` line, every `INFO` value (hashes, counts, pins, the `A8` raw diagnostics, the `A6d` paths and the `A6e` names) and every summary matches the committed log exactly. This reproduces the decision's table: 24 + 21 + 10 + 3 = 58, with 0 failures.

**Scratch hygiene.** Before and after my reruns, `$TMPDIR` held the same 7 `r09*` entries: the 6 disclosed `r09-sources.*-ts` leaks and `r09-opus.s7PN65`. The fresh `X1` log shows `before=0 after=0`, and the fresh `X2` log shows `before=6 after=6`. Both agree with the gaps paragraph in `## Engines`.

## 3. Load-bearing figures re-derived at source

**3.1 The completeness of the MEDIUM list (fix for JF-4-1), checked independently.**
I copied R18's two accepted fixtures, `candidate-claude-code-review.r5.yml` and `candidate-claude.r5.yml`, into a fresh `git init` tree at `/tmp/r09-audit-r4/ind.*`. I then ran bare `actionlint` under four configurations:

| Configuration | Observed |
|---|---|
| No config | exit 0, no output |
| Four-name list (without `ANTHROPIC_SERVICE_ACCOUNT_ID`) | exit 1, exactly two diagnostics: `candidate-claude-code-review.r5.yml:210:45` and `candidate-claude.r5.yml:207:45` `undefined configuration variable "anthropic_service_account_id"` |
| Five-name list | exit 0, no output |
| `config-variables: []` | 10 diagnostics, which is 5 reads × 2 fixtures |

These results confirm the `A6c`, `A6d` and `A7` claims on the real accepted fixtures, not only on the inline fixture.

**3.2 The R18 citations.**
`grep -n 'vars\.'` finds these reads outside comments:

- `candidate-claude-code-review.r5.yml`: lines 129–130 and 208–210.
- `candidate-claude.r5.yml`: lines 129–130 and 205–207.

The three distinct names are `ANTHROPIC_FEDERATION_RULE_ID`, `ANTHROPIC_ORGANIZATION_ID` and `ANTHROPIC_SERVICE_ACCOUNT_ID`. These match the decision's line citations and the `A6e` claim exactly. `research/topics/18-ai-assisted-review-workflows/DECISION.md:26` names the first two as required and `ANTHROPIC_SERVICE_ACCOUNT_ID` as optional, which supports `S7`. The topic `DECISION.md` sha256 is `c9e44318…41f2e`. It equals `acceptance.json` `decision_sha256`.

**3.3 The recursive `vars.` search, which the decision says it did not script.**
Command: `find research \( -name '*.yml' -o -name '*.yaml' \) -type f -print0 | xargs -0 /usr/bin/grep -l 'vars\.'`

Observed hits:

| Location | Files | What they are |
|---|---|---|
| R18 runs `2026-09-06T043454Z-6f31d86e5b7d` and `2026-09-16T224802Z-41e1cb8604e0` | 8 each | R18 fixture generations |
| R11 `snapshots/r2/py-ci.yml`, `py-lint.yml` | 2 | py source snapshots |
| R12 `snapshots/r12-py-ci.yml` | 1 | py source snapshot |
| R35 `wf-starship_starship-workflow.yml` | 1 | third-party workflow |
| R72 `api-bones-6.12.0/.cds/workflows/*` | 4 | third-party workflows |
| `research/topics/` | 0 | — |

This matches the decision's sentence exactly.

**3.4 The `re-verify:` line (fix for JF-9-1).**
- `grep -c '^re-verify: '` returns 1, and `grep -c '^re-verify:'` returns 1.
- Command: `python3 -B`, importing `scripts/research_package.py` and calling `reverify_of(text)` read-only.
- Observed: it returned the trigger text, beginning `an actionlint release after 1.7.12, or closure of \`rhysd/actionlint#648\``, with no error.

**3.5 Other citations.**
- `raw/opus.md:262-273` is the Opus leg's five-name snippet, which includes `ANTHROPIC_SERVICE_ACCOUNT_ID   # R18 (optional variable)`.
- `research/RUNBOOK.md:73` dates Q17.A `(2026-09-27)` and lists R09 in the research wave. The decision already discloses this date gap.

## 4. Non-blocking observations

These observations require no change and do not affect the verdict.

1. **Two R18 run paths.** The decision cites R18's fixtures under run `2026-09-16T224802Z-41e1cb8604e0`. R18's `acceptance.json` `empirical.cwd` names run `2026-09-06T043454Z-6f31d86e5b7d`. I hashed both copies of each fixture, and each pair is byte-identical:

   | Fixture | sha256 |
   |---|---|
   | `candidate-claude-code-review.r5.yml` | `d3c8b712…c1f3c5` |
   | `candidate-claude.r5.yml` | `2c507e7d…d0feff` |

   The `A6d` `INFO` lines already disclose both paths. The citation is therefore correct in substance.

2. **Timestamps prevent byte-exact reproduction.** Each log embeds an `INFO: date-utc` timestamp, so a raw `cmp` can never report identical logs. All other bytes reproduce exactly.

## Verdict

**Approve.** All four scripts rerun green: 58 PASS, 0 FAIL, 0 SKIP. Each fresh log is identical to its committed log apart from the timestamp line. The two fixes in revision 4 (JF-9-1 and JF-4-1) hold under independent execution at source.
