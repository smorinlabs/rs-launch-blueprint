# P02 validation RED/GREEN evidence

Run on 2026-09-04 in `rs-launch-blueprint-p02-plan`. The checks below use the
frozen pre-change answer checker from `HEAD` and the new compatibility wrapper.
They establish a difference in behavior, not a claim that recorded files prove
remote research or empirical execution happened.

| Case | Frozen checker | New validator | Evidence |
|---|---:|---:|---|
| All required crate H3 headings have empty bodies | pass (exit 0) | fail (exit 1) | The frozen script only used `grep -qx`; the new result named each empty field. |
| All required crate H3 headings are inside one fenced code block | pass (exit 0) | fail (exit 1) | The new parser excludes fenced lines before checking ordered headings. |
| Resolved topic has no `acceptance.json`, or an audit says `REJECT` | pass if legacy `DECISION.md` and audit files are nonempty | fail | The accepted-fixture regression first proves a valid bundle passes, then independently rejects a missing bundle and an empirical audit whose body says `verdict: REJECT` while its manifest still says `approve`. |
| Existing structural regression suite | 53 pre-existing cases | 53 passed | `scripts/test-check-research-tree.sh` passed without weakening its original assertions; its valid fixture now carries policy and acceptance evidence. |
| New validator regression suite | not applicable | 10 passed | `scripts/test-research-validation.py` proves an accepted topic first, then independently mutates decision content, raw answer shape, actor identity, parameters, missing/rejecting audits, policy types, and dependency cycles. |
| JSON failure stream | not applicable | pass | A missing answer file returned exit 1, empty stdout, and one parseable JSON object on stderr. |

The exact validation command was:

```bash
UV_CACHE_DIR=/private/tmp/rs-p02-uv-cache uv run --offline --no-project --no-python-downloads --no-cache --python /usr/bin/python3 scripts/test-research-validation.py
scripts/test-check-research-tree.sh
```

It completed with `Ran 10 tests ... OK` and `53 passed, 0 failed`.

Root integration adds nine passing Markdown/history regressions in
`scripts/test-research-answer-parser.py`: tilde and mismatched fences, empty
code bodies, misplaced/duplicate/incomplete bundle members, and historical or
misplaced decision fields. The resolved fixture now records all fixed assumptions
in its current Parameters section. Historical entries cannot satisfy current
owned or assumed values. These checks supplement the original accepted-bundle
mutations; they do not prove the truth of a claimed external research result.
