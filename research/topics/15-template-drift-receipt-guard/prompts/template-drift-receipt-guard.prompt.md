# Deep-research prompt — Template drift/receipt guard (R15, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint` carries py's template-press/receipt-guard machinery — a hermetic self-press check that verifies the template can re-generate itself, and a workflow that rejects a committed press receipt artifact — or whether that machinery has no place in a template that is not itself rebrandable via a `template-press`-style tool. Item kind: `pattern`. Value test: if this answer is wrong, `rs-launch-blueprint` either ships two workflow files (`press-verify.yml`, `template-receipt-guard.yml`) with no corresponding press tool to exercise them, or silently lacks a guard that would have caught a template-rebranding regression the owner did intend to support.

## Context
- Inherited pattern (spec §2, presumption of reuse): py-launch-blueprint is itself a `template-press`-rebrandable template — a separate tool can stamp out a renamed, re-branded copy of the repository — and carries two workflows to protect that capability: `press-verify.yml` runs a hermetic self-press check confirming the template can regenerate itself correctly, and `template-receipt-guard.yml` rejects a PR that accidentally commits a press-tool receipt artifact (a byproduct of running the press tool that should never be checked in). ts, a same-family port of py, did not carry either workflow forward, and its own port-decision record contains no entry discussing them — the concept was dropped, not evaluated and rejected. Evidence: py `.github/workflows/press-verify.yml:10` — hermetic self-press check; py `.github/workflows/template-receipt-guard.yml:6` — rejects a committed press receipt; ts: none (no equivalent concept found; ts's own port decisions carry no D-0xx adopting it either). Ledger row: F044 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: none of the fixed parameters bear directly on this item beyond the standard ones. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts silently dropped both workflows with no decision record; the area evidence note is the only documented rationale available ("ts's own port decisions carry no D-0xx adopting it either").
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): You should be using template-press just the way PyLaunch Blueprint does, and the same thing for TypeScript. We should all be using the same mechanism.

## Out of scope
- Whether `rs-launch-blueprint` itself is designed to be rebrandable via a `template-press`-style tool at all — that is a project-identity question upstream of this item's scope, decided by the owner outside the research program, not re-derived here; this item's answer is conditioned on whichever answer to that question the owner has already given (or, if undetermined, the item must state that dependency explicitly rather than assume an answer).
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R15
- owns:
- consumes:
- related (not a registry dependency): none.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships a hermetic self-press verification workflow and a committed-receipt rejection guard, matching py's template-press machinery, or omits both, matching ts's silent drop.
- HIGH: Is `rs-launch-blueprint` itself designed to be rebrandable via a `template-press`-style tool (an owner-level project-identity fact this research must surface rather than assume) — and if that fact is not yet settled, what does each answer imply for whether this item's recommendation is `ADOPT` or `OMIT`?
- HIGH: If rebrandability is a design goal, what is the current-state Rust equivalent of a `template-press`-style tool the self-press workflow would exercise — is there an established Rust project-templating tool (e.g., `cargo-generate`) whose own regeneration/verification story this pattern should mirror, and does that tool's ecosystem have a precedent for a "does the template still generate a working project" CI check?
- MEDIUM: If rebrandability is not a design goal, does the receipt-guard half of the pattern (rejecting an accidentally committed build/tool byproduct) have independent merit as a general "no stray tool-output files" hygiene check, worth keeping in a simplified form even without the press-verify half?
- LOW: Given ts (a same-family port with the same origin repository) dropped this pattern with no recorded rationale, does that silence itself constitute evidence the pattern was judged not worth porting, or is it simply an undocumented gap in the ts port that should not be treated as a decision?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). The divergence analysis marked this item harmonize: no; the owner asked for the cross-repo answer anyway, so answer it in full.

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Fit for this template
Argues per target shape — CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
