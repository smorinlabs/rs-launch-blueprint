decision-sha256: d7946ed6a687834ee19530f49c27dad033f06eebd571aa77d30d0f2b7a3b9ca2
actor: audit-fable-2026-09-05T163018Z-61c8f49b581d-r4
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged from revision 3 and still correct. The shared requirement — the scan
must be broad enough to cover the classes the codebase can exhibit and pointed
at code that ships — is sourced in py's own `.github/codeql/codeql-config.yml`
at `b08bccf` and in ts's untouched starter-template placeholder at `cb1cbcb`,
both of which I re-read from the pinned clones: py's file carries
`queries: - uses: security-extended`, `paths-ignore: tests/**, docs/**` and the
quoted "Scan shipped code only" comment, referenced from
`.github/workflows/codeql.yml:63`; ts's workflow has no `config-file:` and
carries `# queries: security-extended,security-and-quality` commented out at
`:115`. The agreement level is set at **policy, not low-level values**, before
the implementations are judged, and spec §2's test is then applied rather than
asserted: a shared low-level value needs an explicit owner requirement or
same-tradeoff evidence in every ecosystem, which holds for `security-extended`
(language-independent suite selectors, byte-identical at `codeql-cli/v2.26.0`
and `v2.26.4`) and does not hold for the path list.

Revision 4 adds the one thing my predecessor recorded as missing here:
disagreement 8 now records the engines' own split on the level (codex at
capability/standard, `raw/codex.md:13`; opus at policy, `raw/opus.md:105`),
states that the outcome is unaffected because the decision applies the stricter
evidence-before-shared-value test under either label, and says why it is worth
recording anyway — the ledger's C5 finding (`docs/port/BASELINE-REVIEW.md:479`,
verified at that line) makes agreement-level assignment a live question. That is
the right disposition: the split is disclosed, not resolved by fiat.

Nothing is drawn from repository agreement. The engines split on the decisive
question (codex: no `paths-ignore`; opus: three globs, conditional) and the
decision settles against codex on the bundle's own `rust/codeql-extractor.yml`
declaring `build_modes: [none]` as the sole mode, which is codex's own stated
precondition.

## Design and evidence

**The repair is verified, not assumed.** I re-retrieved every citation the
correction touches on 2026-09-09 and each one reads as revision 4 states it:

| Project | What the file actually shows | Decision's description |
|---|---|---|
| `surrealdb/surrealdb` config | `name`, `paths-ignore`, `query-filters` (`exclude: tags contain: experimental`); **no `queries` key** | matches, including the longer path list it quotes partially and names as partial |
| `surrealdb/surrealdb` workflow | `runs-on: ubuntu-latest` (`:34`), `config-file:` at `:68`, `queries: security-extended` at `:70`, same Init step | matches exactly, line numbers included |
| `wasmCloud/wasmCloud` | inline `queries: security-extended`, no `config-file:`, `github/codeql-action@cdf488f595d80d6e07e03d4674febd5ab45fa938 # v4.37.9` | matches |
| `copper-project/copper-rs` | `build-mode: none`, `queries: security-extended,security-and-quality` | matches |
| `xelis-project/xelis-blockchain` | `build-mode: none`, `queries: +security-extended,security-and-quality` | matches |
| `open-telemetry/opentelemetry-rust` | neither `queries:` nor `config-file:` | matches |
| py CodeQL job at `b08bccf` | `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}` (`:32`, `:51`) | matches; the "bare `ubuntu-latest` in both repositories" claim is correctly narrowed to Ubuntu-only |

The provenance sentence that explains why `raw/codex.md` under-reported xelis's
suite also holds: `gh api` shows `.github/workflows/security.yml` last modified
`2026-07-10T16:33:18Z`, before codex's 2026-09-05 retrieval, so the raw was
incomplete rather than the file having changed.

**The two narrowed citations are now described precisely.** copper-rs and xelis
are called "Alt-B's mechanism with Alt-D's suite", with each suite string quoted
verbatim, and the decision says plainly that revision 3 called both plain Alt-B
adopters and that `raw/opus.md` and `raw/codex.md` each carried only half of the
correction. wasmCloud is left as the single adopter practising Alt-B as the
alternatives table defines it. That is the record.

**The gap is stated at full strength and given its weight.** The dedicated
paragraph says the selected shape — `queries` inside the file, no inline input —
has **no** surveyed Rust practitioner, enumerates why each of the five adopters
fails to be one, and states that the only file carrying a `queries` key anywhere
in the item's evidence is py's own, which is precedent rather than independent
practice. It then concedes what follows: Alt-B's case as runner-up is *stronger*
than revision 3 presented it. That is the honest direction of the concession —
against the recommendation, not around it.

**The recommendation survives on the evidence that never depended on SurrealDB.**
Alt-C over Alt-B turns on B2, and the mechanism is decisive rather than
rhetorical: `paths-ignore` exists only in the configuration file, so an inline
selection cannot express it at all. That leg is executed evidence (8 fixture
files archived bare, 5 with the config; `tests/`, `benches/` and
`crates/inner/tests/` unextracted at extraction time), not practice evidence,
and it is untouched by the correction. Alt-C over Alt-A turns on the suite
delta, also executed. What the correction removes is a practice endorsement the
selected shape never needed for either comparison, and the decision now says so
in those terms.

**The query-count delta is established and its materiality is stated at its
true size.** `codeql resolve queries` was run against both suite files and
diffed at two bundles — 16 default, 18 extended, delta exactly
`CWE-117/LogInjection.ql` and `CWE-825/AccessAfterLifetime.ql` — reproduced at
pack 0.1.37 and 0.1.41 and replayed by the empirical auditor. Materiality is
argued at near-zero cost (two queries of sixteen; extraction dominated by 5,831
standard-library files no filter reaches) rather than inflated, and revision 4
tightens it further in the direction that costs the recommendation: the CWE-117
half is already recorded as an unverified value claim (U6), and the new R06
caveat — carried faithfully from `raw/opus.md:233-235` — states that under
R06's resolved `unsafe_code = "forbid"` proposal the CWE-825 half can fire on
**no** first-party code the template ships, leaving its value prospective (forks
that relax the lint, template users who copy the file, future query growth
through the suite name). The decision then places that consequence correctly: it
bears on Alt-A versus the rest, not on Alt-C versus Alt-B, both of which select
the same suite. U6 gains the joint-failure row and `re-verify:` gains an R06
trigger. This is the opposite of leaning on the criteria that survived.

**The path exclusions are justified for Rust specifically.** The decision's own
extractor finding — `rust/extractor/src/config.rs` seeds `enabled_cfgs` with
`test`, so no glob reaches a `#[cfg(test)]` unit test inside `src/` — is carried
into the shipped artifact's own comment, into B2, into the "must agree versus
may vary" paragraph, and is observed in the record (`src/lib.rs:47` keeps its
alert with the config in force). The exclusion is then justified on what it does
reach: Cargo integration tests, benches and fuzz targets, which hold
deliberately hostile inputs. `**/` anchoring is justified by workspace layout
and observed working in the nested member; `**/fuzz/**` ships with its inertness
observed and its real effect carried to U5; py's `docs/**` is dropped on a
corrected ground (a `.rs` file under `docs/` *was* extracted and did alert), and
the "docs is inert" claim is scoped to non-`.rs` content in the reading of
results.

**Bookkeeping self-claims check out**, which matters because revisions 2 and 3
were each rejected for a self-referential statement the record contradicted.
Revision 4 claims sixteen changed passages and sixteen `git diff -U0` hunks:
`git diff -U0 5e56197 bd6c70c` reports exactly 16, and it explains why the hunk
boundaries do not align one-to-one with its own list. The three prior-revision
hashes it quotes all reproduce from the objects themselves (`7e25bcea…`,
`75fe6f20…`, `0128ff74…`).

**One place the comparison is thinner than the table shows** (observation, not a
finding). The configuration-file-plus-inline-`queries` hybrid that SurrealDB
actually runs satisfies B1 and B2, is the only config-file shape any surveyed
Rust adopter practises, and does not raise U9 at all, since inline selection is
Action-proven by every adopter. It is dismissed at `:108` in one clause — "the
shape A3 forbids rather than a third contender" — where A3 is the acceptance
criterion of the selected design, so that clause read alone is self-referential.
The grounding does exist and is not circular: B3 is stated up front among the
essential behaviors, is evidenced by the `init/action.yml` override text quoted
verbatim at `v4.37.9`, is applied consistently (Alt-G is excluded on the same
ground), and `:102` states the concrete consequence — a single `queries` key
added to SurrealDB's file would be silently overridden by its own inline input.
The decision also never claims the hybrid is worse in *outcome*, only that it
splits the selection across two artifacts and sits next to a live override trap.
So the recommendation is unaffected and I do not fault it; but the closest
practical competitor is excluded on a design principle the decision authored
rather than on anything the evidence shows about results, and that is the most
that "the recommendation survives its reduced adopter evidence" can honestly
mean here.

## Completeness

Structure and fields match the synthesizer contract: the four H2s in order
(`## Decision`, `## Parameters`, `## Empirical check`, `## Engines`), the
`### Principles and implementation` H3 inside the first, no `## Supersedes`, and
`re-verify:` as the last line of `## Decision`. The status paragraph states that
this is a proposal, that P02 does not implement its recommendation, and that
P03's CI is what proves it. Revision 4 re-executes no CodeQL command by design;
I do not fault that, and the empirical auditor did not either.

Parameters: `owns: none` matches the prompt's empty `- owns:` line; all four
fixed parameters appear as `assumes` and quote `docs/port/PARAMETERS.md` exactly
(`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, lines 7-10), each
with a compatibility statement. The `target-os-matrix` entry is narrowed the
same way as the fitness gate and now carries the retrieval date of the adopter
`runs-on:` check. Consumed parameters: none, matching the empty `- consumes:`
line; no `CONFLICT:` in either raw and none invented.

Fitness gates: all six answered with `inapplicable` reasons for a pattern item,
including the corrected OS-matrix sentence.

`BASELINE-REVIEW:` handling is correct. Both engines' F027 lines are carried in
the required `F### — principle — proposed change — evidence` form, verbatim
against `raw/opus.md:317` and `raw/codex.md:21` (codex's trailing "Affected
items" sentence is its own prose, outside the required form, and the decision's
synthesizer paragraph names R16 and F027's implementation anyway), under a
heading stating the ledger is unchanged and the controller adjudicates per
RUNBOOK §4 — which §4 does say. The synthesizer's own finding supports resolving
the ledger's open B3 question (`docs/port/BASELINE-REVIEW.md:189`) as option (b)
and makes the decision explicitly conditional on that adjudication. The ledger
is untouched: `:307` still reads "CodeQL Rust matrix left as an owner question",
and `git status` shows no modification anywhere under `docs/`.

The unproven list is honest and now complete. U9 is the row my predecessor named
as missing: it records both the practice gap and the `config-file:` →
`--codescanning-config` limit that had no numbered row, states that the local
proof came from invoking the CLI directly and never from an Action run, and
names the P03 run that would close it. The preamble's scoping was updated to
match (U1, U2, U3 and U9 settle together, plus U4's passing half). U8 correctly
notes that SurrealDB's `**/` practice is the half of its shape the correction
leaves standing. `codeql-bundle-v2.27.0` is explicitly not a P03 item but a
`re-verify:` trigger.

The empirical audit `review/audit-codex.md` (actor `…-r4`, approve, no findings)
is consistent with the decision: it verified the same corrected citations by
live retrieval, confirmed the inverse checks (no configuration file for the four
non-SurrealDB adopters), confirmed the runner narrowing at both pinned commits,
re-checked the twenty flagship repositories as negative for an advanced-setup
CodeQL workflow, and recorded that no CodeQL command or bundle operation ran. Its
one added nuance — `rust-lang/crates.io` uploads SARIF from zizmor but runs no
CodeQL Init/Analyze — does not contradict the decision's explicitly scoped
"advanced-setup CodeQL workflow" wording.

## Findings

No unresolved finding.

Three observations, none blocking, each self-qualifying where it appears:

1. `:108` says the override hazard "is now observed in production". What is
   observed in production is the *configuration in which the hazard applies* —
   SurrealDB's file declares no `queries` key, so no override is occurring. The
   same sentence supplies the qualification ("a single `queries` key away"), and
   `:102` states it precisely and conditionally, so the reader is not misled.
   The looseness also runs against the recommendation, not for it.
2. `:100` says the template "will receive" `rust/command-line-injection` at the
   next pin bump; the following sentence retracts the specific case ("Whether
   that query is in the `security-extended` set at 2.27.0 was not resolved").
   The general mechanism claim — a suite name picks up queries added to that
   suite — is sound; only the specific arrival is unestablished, and it is
   labelled in place.
3. The hybrid's exclusion at `:108`, discussed under `## Design and evidence`:
   grounded in B3 and the quoted `init/action.yml` text at `:102`, applied
   consistently with Alt-G, but stated in that one clause by appeal to the
   decision's own guard.

## Assessment

Approve. The repair I asked for was made, and made in the harder direction:
revision 4 does not merely correct the SurrealDB sentence, it re-enumerates
every adopter citation in the document, finds two more that revision 3 had
described too generously (copper-rs and xelis, both selecting `security-and-
quality` alongside `security-extended`), narrows a runner claim that no auditor
had challenged (py's variable-indirected `runs-on:`), adds the R06 caveat that
weakens the surviving half of its own suite argument, adds the engines'
agreement-level split it had omitted, and gives the practice gap a numbered
unproven row rather than a paragraph. I verified all of it against the live
files, the pinned clones, the raws and the git objects; every statement reads as
the document says it reads, including the sixteen-hunk claim about itself.

On the question I was asked to weigh: the recommendation does survive its
reduced adopter evidence, and the decision argues that rather than assuming it.
Alt-C over Alt-B was never a practice argument — it is the mechanism fact that
`paths-ignore` exists only in the configuration file — and Alt-C over Alt-A
rests on an executed suite diff whose value the decision now states as partly
prospective rather than demonstrated. What the correction genuinely costs is
recorded: the queries-in-file leg has mechanism support and no practice support,
the runner-up is the shape everyone actually runs, and the one Rust project that
ships a config file sits one key away from the hazard B3 exists to prevent. The
thinnest remaining seam is that the hybrid — which satisfies B1 and B2 and is
the only practised config-file shape — is excluded on B3, a principle the
decision authored, in a clause that names its own guard rather than the hazard
underneath it. That is a reviewability judgment stated with its reason, not an
evidence claim, and it does not block: B3 predates the correction, is evidenced
by the `init/action.yml` override text, is applied consistently, and the decision
nowhere claims the hybrid produces worse results.

P02 is research. I did not fault the decision for declining to implement its
recommendation, and I did not fault revision 4 for executing nothing: it is
documentary by direction, and its own record confirms it added and altered no
evidence log and changed no configuration value, parameter, observed result or
verdict.
