# Deep-research prompt — <item title> (<R##>, <kind>)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver <a named crate with a version range | a named pattern with a reference implementation | a named stack of crates with versions> for: <the decision in one sentence>. Item kind: `<crate|pattern|bundle>`. Value test: if this answer is wrong, <what in the template changes — files, CI jobs, public API>.

## Context
- Inherited pattern (spec §2, presumption of reuse): <pattern text>. Evidence: py `<path:line>` — <how>; ts `<path:line>` — <how>. Ledger rows: <F###, F###> (`docs/port/COMMONALITY.md`), verdict `<verdict>`.
- Already decided, do not re-open: <values from the area tables / fixed parameters relevant here, each with its source>.
- <OVERRIDE items only:> The default is to keep pattern <X>. Argue whether Rust specifically justifies deviating; if not, say so.
- Prior decisions of the TypeScript port that explain the current shape: <D-### refs or "none">.

## Out of scope
- <what the search must not spend budget on, one bullet each — e.g. "no async runtime comparison; R0n owns `async-runtime`">
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: <R##>
- owns: <param, param | —>
- consumes: <R##: param; owner: param | —>
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: <one sentence>.
- HIGH: <question whose answer is scarce or decisive>
- HIGH: <…>
- MEDIUM: <…>
- LOW: <…>

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
1. license compatible with `<license value>`;
2. crate and dependency-tree MSRV within `<msrv-policy value>`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on Windows;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

<crate:>
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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

<pattern:> as `crate`, except *Qualified shortlist* is replaced by
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns; and *Fit for this template* argues per target shape.

<bundle:>
### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
then *Parameters*, *Migration implications*, *Validation strategy*, *Confidence & re-verify trigger*, *Sources* as above.

<OVERRIDE items append:>
### Inherited default
### Rust-specific argument
### Options rejected
### Override justified
`yes` or `no`.
### Resulting verdict

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `<rust-edition value>`; MSRV policy `<msrv-policy value>`; license `<license value>`.
- CI on `<target-os-matrix value>` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
