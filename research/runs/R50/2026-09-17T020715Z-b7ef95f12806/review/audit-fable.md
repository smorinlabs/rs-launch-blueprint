decision-sha256: a1ad3736d627f6038a86564dc5c9a0dcc314a0bb5a10fdec825aa1cb795053dd
actor: audit-fable-2026-09-17T020715Z-b7ef95f12806-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 (blocking) — the `--debug` trade names `cargo publish --dry-run` as exercising the release path, which the run's own log refutes, and its surviving ground is an open item; JF-2 (non-blocking) — two line citations name the line before the behaviour they describe; JF-3 (non-blocking) — the archive rerun's counts are asserted without a retained log

Empirical (Codex) audit deferred by the task message; this is a single-auditor pass, so `review/audit-codex.md` was neither read nor expected. No `audit-fable.md` existed before this one.

## Principle and agreement level

The shared requirement is stated at the level the evidence supports and not above it:
*the artifact that ships is installed the way a consumer installs it, into a location
that is not the developer's environment, and the resulting command is executed.* I
re-read both pins rather than taking the decision's word. py
`.github/workflows/ci.yml` at `b08bccfb` carries `build-smoke` at `:204`, `uv build` at
`:216`, and the two `uvx --from … plbp --version` steps at `:222` (wheel) and `:224`
(sdist). ts `Justfile` at `cb1cbcb2` carries the pack-install-run half at `:299-312`.
Both sources have the capability; the mechanisms differ. `capability` for the check
existing and `architectural pattern` for the subject being the *packaged* artifact are
therefore the right levels, and the B1–B4 table separates them from what may vary
(cadence, which is F221's policy question, and assertion strength, which is B4's) rather
than asserting agreement where none is required.

The native design is justified rather than inherited. rs follows py on cadence and ts
one step short on assertion strength, and each of those is argued from a fact, not from
repository agreement: the cadence from py's own path-filtered gate, the assertion from
the measured `required-features` behaviour, and the one-step-short position from R22 and
R60 still owning the exact `--version` string. Declining `uvx`'s literal twin (a fresh,
unlocked resolution) in favour of `--locked` is argued on determinism and handed to R34
as a recommendation rather than taken from it — correct handling of another item's
parameter.

## Design and evidence

**The alternatives were genuinely compared, and the winner was measured.** Five options
(A–E) are compared on what each puts under test before any tool is named, and the
discriminator between the recommendation and its runner-up is an executed result, not a
preference: against one fixture with a hole in `[package] include`, option C fails with
`error[E0583]: file not found for module 'helper'`, exit 101, and option B succeeds with
exit 0 and installs a working binary (`review/evidence/r50-check.log:162-186`). The
ledger's own recorded guess (`cargo install --path . --root <tmp>`) is demoted to
runner-up *with* a live adopter retained for P03 to fall back to. That is the required
posture: a recorded pattern treated as evidence rather than as the winner.

**The figures are the raw report's, carried without inflation.** I traced every number
in `## Decision` to `raw/opus.md`: `sharkdp/bat` 60 472 stars / 330 open issues and
`astral-sh/uv` 89 890 stars / 2 360 open issues (opus.md:60-61); `just` 533 628 90-day
and 2 597 663 all-time downloads, `1.58.0` `created_at` `2026-08-03T20:29:15Z`, 35 828
stars, 171 open issues, median 0.53 days with 0 unanswered (opus.md:544-553); the
RustSec 404-with-a-`time`-200-control (opus.md:43-47); and the GitHub code search
`total_count: 7` (opus.md:1060). Each carries its endpoint and its 2026-09-17 retrieval
date in the decision. No figure was invented and none was rounded into a stronger claim.

**The `ubuntu-latest`-only choice is grounded, and its trigger is named.** Two of the
three grounds I verified independently. py's `build-smoke` does run on one runner —
`.github/workflows/ci.yml:206`, `runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`,
with `needs: changes` and `if: needs.changes.outputs.code == 'true'` at `:207-208` —
while py's test matrix is `os: [ubuntu, macos, windows]` at `:155`, so "py's cadence is
one runner despite a three-OS test matrix" holds exactly as stated. The macOS execution
is in the log's phase A (Darwin arm64, macOS 26.4) and phase F. Ground 1 is correct and
correctly bounded: a `.crate` genuinely has no per-OS variant, and the decision does not
over-extend that into a claim that the *compile* is OS-independent — it says the
opposite, names the residual (a macOS-only failure of the packaged tree appearing first
in CI), declines to close it, and records the widen trigger at `re-verify:` (8). The
unproven table then marks `ubuntu-latest` alone as **partly proven**, noting that the
Linux leg the job actually uses was never run. That is the honest form of this claim.

**The disagreements are settled on grounds, not by authority.** Disagreement 1 by the
phase G measurement plus the scope fact that R26 binds its elements to the publish
workflow — which I confirmed in `research/topics/26-packed-artifact-content-guard/DECISION.md`
(elements 1–4 "bound to the publish workflow's verify job"; a pull-request copy of
element 1 recorded as "recommended hardening, **not bound here**", deferred to R11).
Disagreement 2 is the strongest piece of work in the run: the Opus engine's
workspace-membership ground was tested, did not reproduce on cargo 1.98.0 in either live
layout (log `:104-125`), and the recommendation's ground was replaced by an observed
fact — with `--no-verify` there is no in-tree extracted copy at all (log `:79-81` against
`:92-95`) — and the re-verify trigger narrowed to match. Disagreement 4's assertion
strength rests on the reproduced `required-features` outcome (exit 0, nothing installed,
log `:192-197`), which is what makes AC3's second half load-bearing. Disagreement 5
separates a lifecycle test from an install-and-run assertion rather than splitting the
difference.

**The F222 disposition is a legitimate ledger disposition.** The finding is recorded for
the ledger's owner and nothing was applied. I re-verified *every* Opus line citation at
the pin myself, not two: `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:Justfile` gives
the header comment at `:268-269`, `[group('releases'), group('build')]` at `:275`,
`mktemp -d /private/tmp/ts-pack-check.XXXXXX` at `:299`, `npm pack … --pack-destination
"$SCRATCH"` at `:302`, `npm install --no-save --no-package-lock` at `:304`, the installed
bin's `--version` at `:306`, `EXPECTED="{{command_name}} $VERSION"` at `:307`, and the
ESM import asserting `VERSION` at `:312`. All held. I also re-ran the three contradicted
statements against the live tree: `docs/port/COMMONALITY.md:226` still records origin
`py-only`, `docs/port/areas/packaging-distribution.md:20` still carries `—` in the ts
cell, and `inputs/prompt.md:9` still carries the "ts: none" gloss — so the decision's
claim that no ledger, area, index, prompt or registry file was edited is supported, and
the prompt's gloss is disputed in the answer rather than silently overridden. The
proposed origin `different` (rather than `same`) is the right proposal on the evidence:
both repositories have the capability, and the mechanism, cadence and assertion strength
all differ. F221's own evidence is untouched, and its 0-matches-across-8-workflow-files
count is in the log at `:44-54`.

**The web surface is handled honestly.** The snapshot/live discrepancy is asserted in
both directions mechanically (log `:26-27`), the reason no `- assumes web-extra-surface`
line can be written is the prompt's empty `- consumes:` line rather than a preference,
and R69's second binary is correctly treated as a placeholder — `research/topics/69-web-framework-stack/DECISION.md`
does carry `src/bin/<app>-serve.rs` and `[[bin]] required-features = ["web"]`, so AC6's
one-versus-two expectation is anchored in R69's actual shape while its literal name is
left to R69 and P03.

**The cost treatment is a model and says so.** Every lever carries its documented source,
and the `--target-dir` caching rationale traces to the Cargo Book text quoted in
`raw/opus.md:241` and `:1047` ("this can be useful for caching build artifacts on
continuous integration systems"). The HIGH-2 answer (no, Rust's compile time does not
argue for ts's local-only cadence) is labelled a cost model backed by documented
behaviour and two compile-heavy PR gates, "**not** a measurement", and the unproven table
repeats it. The one place where this discipline slips is JF-1.

## Completeness

Every required field is present and correct.

- **Fitness gates.** All six answered, none omitted. Gate 1 is `inapplicable` under the
  owner ruling recorded at `docs/port/OWNER-REVIEW.md:47` ("2026-09-12 — no licence check
  for anything the template uses (Q4, superseded and widened by Q7.B)"), and the decision
  states that nothing was excluded on licence grounds. Gates 2, 3 and 5 are `inapplicable`
  each with its reason (no crate added). Gate 4 is answered by the macOS execution plus
  Cargo's presence on both images. Gate 6 is the cadence question itself.
- **Parameters.** Exactly four `- assumes` lines, and I byte-compared all four rows
  against the live `docs/port/PARAMETERS.md`: `msrv-policy`, `rust-edition`,
  `target-os-matrix` and `license` are identical. The prompt's `- owns:` and `- consumes:`
  lines are empty (`inputs/prompt.md:20-21`), so four is the complete set and the absence
  of a `CONFLICT:` line is correct rather than an omission. The prerequisite R49 is
  bound at the sha the decision quotes — `shasum -a 256` of
  `research/topics/49-build-target-declaration/DECISION.md` is
  `86b7f925ef89ac682ea00bb0b6fea8a809c1abc712d9e0e0ced8e5082990d948`, and its binary is
  `rslbp`.
- **The empirical check verifies what it is cited for.** `review/evidence/r50-check.log`
  hashes to `310e9f612c085f79d76d543e481f6da31098595986805b7d9377fd636316cfa4` and is 213
  lines, both as stated. I counted the PASS lines by phase rather than trusting the
  summary: B 8, C 14, D 3, E 9, F 22, G 5, H 5, I 2 — 68, with no `FAIL` and no `SKIP`
  line anywhere in the file. Every per-phase line range the decision cites resolves to the
  assertions it names, and the four quoted results (AC7, `required-features`, the
  `--no-verify` fact, the workspace claim that did not reproduce) are quoted accurately
  from the log, including the exit statuses 101 and 0.
- **Unproven rows are honest.** macOS-only execution, no transferable timing, no
  well-regarded adopter of the composition (with the search that establishes it), AC7
  proven on a fixture and not on the template, the exact `--version` string assigned to
  R22/R60, and R69's placeholder binary are each recorded with what would prove them.
  The decision does not implement its own recommendation and is not faulted for that; the
  P03 validation list is specific enough to be executed.

## Findings

**JF-1 — blocking. The `--debug` trade's coverage claim is refuted by this run's own
log, and its surviving ground is an open item.** The unproven table's row reads:
"`--debug` installs a profile a consumer does not get | **acknowledged trade, not a
defect** — the release path is exercised by R68's release build and R26's publish-time
`cargo publish --dry-run`". Cargo's verification build compiles with the **dev** profile,
which this run measured: `review/evidence/r50-check.log:89-91` shows `Verifying r50spike
v0.4.2` followed by `Finished 'dev' profile [unoptimized + debuginfo] target(s)`.
`cargo publish --dry-run` performs that same packaging-and-verification path, so it does
not exercise the release profile at all. The clause is carried verbatim from
`raw/opus.md:975` — the one place where the synthesis accepted an engine claim it
elsewhere insisted on testing (Disagreement 2 corrected precisely this class of
inherited assertion). Removing the refuted clause leaves R68's release build as the only
exerciser, and R68 is `open` in `research/CLAUDE.md`, which the row does not say. The
consequence is narrow but real: a reader of the unproven table is told the release path
is covered twice when it is covered at most once, by an unresolved item. The trade's
flip condition ("if a release-only failure is ever observed, the leg switches to the
release profile and pays the compile") is correctly stated and is not at issue. Repair is
a clause: drop `cargo publish --dry-run`, say that R68's release build is the only
release-profile compile the template is currently expected to perform and that R68 is
open, or record the release profile as unexercised at pull-request time.

**JF-2 — non-blocking. Two citations name the line before the behaviour described.** The
`BASELINE-REVIEW` paragraph says "`:307` compares it for equality against
`"{{command_name}} $VERSION"`"; at the pin, `:307` is the assignment of that expected
string and the comparison is `:308-310` (`if [ "$BIN_VERSION" != "$EXPECTED" ]` … `fi`).
The Opus raw cited this correctly as `:306-310` (`raw/opus.md:105`), so the imprecision
was introduced by the synthesis, not carried. Similarly, `## Principles and
implementation` cites py `ci.yml:220-223` for "`uvx --from "$(ls dist/*.whl)" plbp
--version`, and the same for the sdist", but the sdist invocation is at `:224`; the same
range appears in the B1 table row. The quoted text is right in both cases and the F222
disposition does not turn on either, so this is precision, not substance.

**JF-3 — non-blocking, observation. The archive rerun's counts have no retained
artifact.** "54 `PASS`, 0 `FAIL`" with `SKIP ts-pin/all — checkout absent at …`, and the
twice-run byte-identical `diff`, are stated as executed but no second log is archived;
only run 1 is saved, which the decision does say. Both claims are corroborated as far as
the repository allows: `review/evidence/r50-check.sh:139` contains
`skip "ts-pin/all" "checkout absent at $TS_REPO"` with `TS_REPO="$HOME/c/ts-launch-blueprint"`,
so pointing `$HOME` at an empty directory does skip exactly that phase, and 68 minus
phase C's 14 assertions is 54. I did not rerun anything. No repair is required; retaining
the second log would make the claim checkable rather than merely consistent.

## Assessment

Rejected at revision 1 on JF-1 alone. The research is strong and the reasoning is
unusually well disciplined about the difference between what was argued and what was
measured: the option C/B choice, the assertion strength, the placement of the extraction,
and the correction of the engine's own unreproduced ground are each settled by an
executed result, and the limits (no timing, macOS-only, no adopter of the composition)
are stated where a weaker decision would have implied coverage. JF-1 is the single place
that discipline lapses, and it lapses in the table whose whole purpose is to state
coverage honestly.

**The recommendation does not move under any finding.** Under JF-1 the procedure, the
`--debug` lever, the recipe and job names, the single `ubuntu-latest` runner and the
cadence are all unchanged; what changes is one clause of justification and, with it, the
honest description of what the release profile costs the template today. JF-2 changes two
line numbers and JF-3 changes nothing. A revision 2 repairing JF-1, and preferably JF-2,
should be approvable as it stands otherwise.
