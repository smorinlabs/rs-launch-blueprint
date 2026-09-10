decision-sha256: 2cc1bce4f2e8504fb36e31d9b1296b58eae3b4bb1490023bd3f6edea476c6c70
actor: audit-codex-2026-09-05T165440Z-3a8ca31664c3-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: `## Engines`, disagreement 2 falsely says issue #22425 never mentions `companyAnnouncements` and does not support a historical visibility report; its issue body explicitly says that `companyAnnouncements` does not display visibly.

## Rerun

- argv: `bash research/runs/R43/2026-09-05T165440Z-3a8ca31664c3/review/evidence/r43-claims-check.sh`
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`
- toolchain: macOS host; `rustc 1.98.0`, `cargo 1.98.0`, `curl 8.7.1`, `jq-1.8.2`, `git 2.50.1`, and `gh 2.98.0` (recorded in the rerun log). The requested Lima guest was stopped; `limactl` was callable but its attempted start was denied by its host log-file permission, so this is the permitted macOS fallback.
- exit code: `0`
- log path: `review/evidence/audit-r43-r1.log`
- output matches the decision's cited log substantively: 37 `PASS`, 0 `FAIL`, `failed checks: 0`, and the same observed values. The only byte differences are the two run timestamps and the random `mktemp` pathname printed by the script.

The rerun fetched and checked six cited first-party endpoints, including Cursor Rules, Devin Desktop memories and `AGENTS.md`, Devin CLI rules, Claude Code settings reference, and Cargo's manifest reference. Each returned HTTP 200. It did not install or launch a vendor product, author assistant files, or scaffold a repository.

## Findings

### F1 — the rejection of Codex's historical visibility caution misreads its cited issue

`review/DECISION.md` §`## Engines`, disagreement 2, says `anthropics/claude-code#22425` is only a feature request, was closed by its reporter within five minutes, "never mentions `companyAnnouncements`", and therefore does not support Codex's statement that a user reported a historical visibility failure.

My direct `gh api` read confirms the procedural facts: the issue is titled "Feature request: Project-specific startup menu/message for onboarding new users", was opened at `2026-02-01T18:58:49Z`, and was closed `completed` at `2026-02-01T19:03:37Z` by the reporter. But the original issue body also states, under `## Current Behavior`, "`companyAnnouncements` also doesn't display visibly" and identifies Claude Code `v2.1.21`. Its later comment says `SessionStart` output became context for Claude and that a user-visible terminal message could still be valuable; it does not withdraw the `companyAnnouncements` report.

The raw Codex report's narrower statement—"a user report has alleged a visibility failure in one past version"—is therefore supported by the cited issue. The decision may still retain Tier D and P03's direct display test, and it may weigh this one historical report as limited evidence. It must not dismiss the report by asserting that the issue never names the mechanism.

## Assessment

The tier assignment is otherwise honest. Tier V is confined to fetched documentation text, pinned-tree contents, redirects, census subset observations, and JSON-shape assertions. The decision repeatedly labels actual product loading of root `AGENTS.md` and human display of project-scope `companyAnnouncements` as Tier D documentation claims and Tier P unproven behaviour, with explicit P03 observations that would prove each. It does not treat a documentation statement as an observed client outcome.

The four fixed assumptions were regenerated from `inputs/PARAMETERS.md` rows 7–10 as `- assumes <param> = <value>` and compared with the four decision lines using `diff -u`; the comparison exited `0`, so their bytes match. The saved empirical script also reproduced its cited result. F1 nevertheless requires a decision revision because it overturns a raw report's confidence qualification using a factual assertion that the cited issue contradicts.
