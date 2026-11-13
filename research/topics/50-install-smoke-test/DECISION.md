# 2026-09-17 — R50 — install-smoke-test (bundle, Focused) — decision (revision 7)

**Revision note, revision 7.** Revision 7 answers the judgment audit of
revision 6 (`review/audit-fable.r6.md`, verdict `reject`, one finding) and
changes **nothing in the recommendation**. The procedure is still
`cargo package --no-verify` → extract the `.crate` outside the repository →
`cargo install --path … --root <scratch> --locked --debug --no-track
--target-dir …` → run `<scratch>/bin/rslbp --version`. It is still one `just`
recipe `install-check` and one `install-smoke` job on **`ubuntu-latest` only**,
with option B as the ranked runner-up. AC4's equality form, `OVERRIDE (OV-13)`
and the endorsed F222 `BASELINE-REVIEW` all stand, with its repair scope of four
records. No parameter value moved and no gate disposition was reversed. The
empirical audit of revision 6 (`review/audit-codex.r6.md`) approved; this
synthesis did not read that file, and its verdict is recorded as given by the job
specification. No evidence file was touched and no check was rerun. The finding
is a text repair to one clause in the `BASELINE-REVIEW: F222` paragraph. That
clause said `:182` "is not asserted by any retained script", while the phase-L
description under `## Empirical check` says phase L asserts `:182`'s harmonize
cell (`r50-r4-delta.log:46`). The clause now names only the two cells no script
asserts. No `re-verify:` trigger was added, removed or reworded; the count stays
thirteen.

| Finding | Disposition in this revision |
|---|---|
| **Finding 1 (JF-1, with a JF-8 edge)** — `## Decision`, `BASELINE-REVIEW: F222` paragraph: "`:182` is not asserted by any retained script" contradicts the phase-L description, which says phase L asserts `:182`'s harmonize cell (`r50-r4-delta.log:46`, `PASS div/f222-harmonize-no`) | **Accepted; the audit's repair applied verbatim.** The clause now reads "`:182`'s ts and inferred cells are not asserted by any retained script (phase L asserts only its harmonize cell, `r50-r4-delta.log:46`) and were read directly for revision 6". It now agrees with the phase-L description under `## Empirical check` and with phase-table row D, which were already scoped correctly and are unchanged. No script, log or recommendation changed. |
| **Observations O-1, O-2, O-3** (non-blocking) — R11's resolution exists only in the uncommitted tree; `execution-ledger.md:1211` records "R50 r4 DUAL APPROVE"; `COVERAGE.md:91` is derived from the ledger | **Not changed.** Each concerns a controller-owned commit or file, not this decision's text, and O-3 confirms the count of four. The round rules limit this revision to the listed finding. |

**Revision history.** Revision 1 — sha256
`a1ad3736d627f6038a86564dc5c9a0dcc314a0bb5a10fdec825aa1cb795053dd`, commits
`6fbad22` (first write) and `a38493e` (`re-verify:` collapsed onto one physical
line for the packager, two cargo-install URLs added, the spike's `--offline` use
recorded); rejected by the round-1 judgment audit (`review/audit-fable.md`, commit
`a6e402e`) on JF-1, with JF-2 and JF-3 non-blocking. The round-1 empirical audit
did not run. Revision 2 — sha256
`316dd29d9681948a8e82623093b0aa450fde7c09c9aadbeeae7652cb0882c461`, commit
`cca20fe`, preserved byte-identical at `review/R50-r2-snapshot.md`; approved by
the round-2 judgment audit and rejected by the round-2 empirical audit on E-1.
Revision 3 — sha256
`1b6b178bfaf9a7ba12ed38f21d8c86e7e34a867fa305964cbe76b6a277fc005a`, no commit
made, preserved byte-identical at `review/R50-r3-snapshot.md`; approved by the
round-3 empirical audit and rejected by the round-3 judgment audit on three
findings. Revision 4 — sha256
`c244472e6188c3192b826e36d423e1e9520dedd9dbb096a581c6244538d7b109`, no commit
made, preserved byte-identical at `review/R50-r4-snapshot.md`: AC4 tightened to
equality per R60, R11 picked up as resolved, `OVERRIDE (OV-13)` recorded for B3,
and the `r50-r4-delta` evidence added; approved by its empirical audit
(`review/audit-claude.r4.md`) and rejected by its judgment audit
(`review/audit-fable.r4.md`) on two findings. Revision 5 — sha256
`04fb97c18a166643d98757189d350ce57758f3b217b09ad1118ff55bfb759df5`, no commit
made, preserved byte-identical at `review/R50-r5-snapshot.md`: AC6 and
Disagreement 5 reworded to the two demonstrated binary behaviours, the
library-surface ground rebased on the observed Cargo rule and R04, trigger (7)
restated, and a cargo 1.98.1 library probe recorded under `## Empirical check`;
approved by its empirical audit (`review/audit-claude.r5.md`) and rejected by
its judgment audit (`review/audit-fable.r5.md`) on one finding. Revision 6 —
sha256 `69d95763ce82d90480ca2e17a9a0836f6ca39c8040625350f719e2c6aabdab38`, no
commit made, preserved byte-identical at `review/R50-r6-snapshot.md`: the F222
`BASELINE-REVIEW` repair scope widened from three records to four with
`DIVERGENCE-ANALYSIS.md:182`'s ts and inferred cells quoted, OV-13's closing
sentence given the language-bound clause, and the Opus-raw library-surface
correction recorded under `## Engines`; approved by its empirical audit
(`review/audit-codex.r6.md`) and rejected by its judgment audit
(`review/audit-fable.r6.md`) on the one finding this revision answers.
Revision 7 — this file. No evidence script or retained log changed:
`r50-check.sh` is still sha256
`bdd7bc3c3c0e7fb025b92382342403cd32250da074c150496537a90ad6d55a39`,
`r50-check.log` still
`4cc2f81a41e01c4f35dcaa8c9f17295bb1331c34a3d31f1b1feddd2fbb7fbe21` (213 lines),
`r50-r2-archive-rerun.log` still
`508ee472ff9dab3c698232671794ccefb56d8fd352dd41c00eb126d55cb48e34` (220 lines),
and `r50-r4-delta.log` still
`ae1a2a49d17757c9cabdbe64be91f48b1f9e420ceb22e484f21864e3b5ace5e7` (86 lines).
The two unlogged scripts are unchanged too: `r50-r4-delta.sh` is sha256
`b2b9bfa3a7becde70d55d2797c0d0ac69a38e19389594096081b22fd042a4dc9` and
`r50-r2-archive-rerun.sh` is
`3df01af40c01c5f71253067858d52640cbd487ce58d27bc6c149a557cd1d5bd1`. No commit
was made for revision 7.

**Mechanical enumeration performed before editing** (`/usr/bin/grep -n -E` over
revision 6 as preserved in `review/R50-r6-snapshot.md`, every location touching
the finding's subject, edited from the list rather than by re-reading):
`:182|not asserted|asserted by any|read directly` matched lines 18, 22, 27, 78,
84, 88, 200, 209, 210, 296, 300, 723, 724, 726, 827 and 954. Edited: 1 (title);
3–103 (revision note, findings table, history, this enumeration and the actor
line, replaced — this covers 18, 22, 27, 78, 84 and 88); and 209–210 (the
finding's clause, replaced by the audit's repair wording). Correctly untouched:
200 (names the row — accurate); 296 and 300 (OV-13's language-bound clause —
accurate); 723–726 (the phase-L description, already scoped to `:182`'s harmonize
cell, which the repaired clause now matches); 827 (phase-table row D, scoped to
phase D — accurate, as the revision-6 judgment audit confirmed); and 954 (the
`## Engines` disposition — accurate). Also untouched: the `re-verify:` line
(still one physical line, thirteen triggers) and the four `- assumes` lines.

Actor `synth-opus-2026-09-17T020715Z-b7ef95f12806-r7`, model `claude-opus-5-5`
(family `anthropic`); revision 6's synthesis actor was
`synth-opus-2026-09-17T020715Z-b7ef95f12806-r6`, model `claude-opus-5-5`
(family `anthropic`). Item kind `bundle`, effort tier `focused` (two engines, no
Doxa). Nothing has been published for R50, so there is no `## Supersedes`.

## Decision

**Recommendation — one stack, entirely first-party, adding no crate, no GitHub
Action and no dependency to the template.** Build the publishable archive, install
it from a copy extracted outside the repository into a throwaway root, and execute
the resulting command:

```sh
cargo package -p rs-launch-blueprint --locked --no-verify
# extract target/package/rs-launch-blueprint-<ver>.crate into $(mktemp -d)
cargo install --path "<scratch>/rs-launch-blueprint-<ver>" --root "<scratch>/root" \
    --locked --debug --no-track --target-dir "<target_directory>/install-check"
test -x "<scratch>/root/bin/rslbp"
"<scratch>/root/bin/rslbp" --version    # exit 0, stdout is exactly `rslbp <ver>`
```

Hold the whole procedure in **one `just` recipe named `install-check`**, attributes
`[group('build'), group('releases')]`, **no alias**, and wire that one recipe into
pull-request CI as **one job named `install-smoke` on `ubuntu-latest` only**, gated
by R11's code-change path filter. The optional web surface is a second, step-level
leg (`just install-check web`) in the same job, conditioned on R11's web filter.
Under R11's published gate that condition is currently vacuous — `web` equals
`code`, so the step runs whenever the job runs (R11 `DECISION.md:202`) — until a
narrowing lands; the mechanism stands and the cost is stated honestly under
Principles.

**This decision is a proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. The empirical check
below was executed against throwaway fixture crates, never against the template,
which does not exist. What P03 must validate is listed under `## Engines`. A
decision that does not survive implementation is revised against this recorded
research, not researched again from scratch.

**Ledger rows settled.** `F221` (`docs/port/COMMONALITY.md:225`,
`packaging-distribution`, origin `different`, verdict `DIVERGENT`) — the *cadence*
of a CI-wired build-and-install smoke test: **rs adopts py's cadence**, a
path-filtered pull-request gate, not ts's local-only recipe. `F222` (`:226`,
origin recorded as `py-only`) — the *mechanism*, an ephemeral install-and-run of
the just-built artifact: **rs realizes it as pack → extract → `cargo install
--root` → run**, and the row's own recorded guess (`cargo install --path . --root
<tmp>`) is the **runner-up**, not the recommendation, for the reason measured in
`## Empirical check`.

**Which runner the smoke job uses, and why: `ubuntu-latest` only.** Three grounds,
and one of them is an observation rather than an argument.

1. *The artifact under test has no per-OS variant.* A `.crate` is a **source**
   archive — there is no platform tag as there is on a wheel — so what this check
   exercises (the `[package] include` allow-list's completeness, the manifest
   metadata, the install verb, and the fact that a command called `rslbp` is
   produced and runs) is OS-independent in Cargo. A macOS-only *compile* break in
   the tree is caught by the ordinary test job, which does run on `macos-latest`.
2. *This is py's cadence, not a narrowing of it.* py's own `build-smoke` runs on
   **one** runner (`runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`,
   `.github/workflows/ci.yml:204-224` at pin `b08bccfb`, read by the Opus engine
   2026-09-17) despite py testing on three operating systems. Adopting py's
   cadence therefore means one runner, and the "path-filtered subset" the prompt
   offers as a third option is what py already does (`needs: changes`,
   `if: needs.changes.outputs.code == 'true'`).
3. *The macOS half of `target-os-matrix` is satisfied at the level the parameter
   states.* The registry describes `target-os-matrix` as "CI runners; every tool
   must run on all of them" — a compatibility requirement on the tool, which the
   recipe meets: the complete pack → extract → install → run composition was
   **executed on macOS 26.4 (Darwin arm64) in this synthesis** (`## Empirical
   check`, phases F and G), and contributors run `just install-check` on macOS
   locally. What is *not* covered is a macOS-only failure of the packaged tree
   appearing first in CI; that residual gap is stated here rather than closed, and
   widening the job to a two-runner matrix is a one-line change.

Codex recommended the two-runner matrix; the disagreement and its grounds are
recorded under `## Engines`.

**BASELINE-REVIEW: F222 — the artifact that reaches a consumer is installed as a
consumer installs it and then executed — proposed change: give F222 the origin
`different` with a ts evidence cell, and correct the four places that record ts
as having no install-and-run step — evidence:** `ts-launch-blueprint`'s
`pack-check` recipe at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` ends in
exactly that check. Verified here, mechanically, by
`git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:Justfile`
(`review/evidence/r50-check.sh` phase C, 14 assertions, log lines 32–54):
`Justfile:299` `SCRATCH=$(mktemp -d /private/tmp/ts-pack-check.XXXXXX)`; `:302`
`npm pack --ignore-scripts --pack-destination "$SCRATCH"`; `:304`
`npm install --no-save --no-package-lock "$SCRATCH/$TARBALL"`; `:306` runs
`"$SCRATCH/node_modules/.bin/{{command_name}}" --version`; `:307` **assigns** the
expected string, `EXPECTED="{{command_name}} $VERSION"`, and `:308-310` compare
the two for equality (`if [ "$BIN_VERSION" != "$EXPECTED" ]; then … fi`); `:312`
imports the installed
package and asserts `VERSION`. The recipe's own header comment says so at
`:268-269`: *"then pack + install into a /private/tmp scratch project and
smoke-test the bin + ESM lib import"*. The four statements contradicted are
`docs/port/COMMONALITY.md:226` (origin `py-only`),
`docs/port/areas/packaging-distribution.md:20` (ts cell `—`), this item's own
binding prompt, `## Context` (*"ts: none (py-only; ts's `pack-check` recipe covers
packed-content assertion, not an install-and-run step…)"*), and the F222 sub-row
of `docs/port/DIVERGENCE-ANALYSIS.md` (`:182`). That row carries the claim in two
cells: its ts cell (*"absent — ts's `pack-check` validates the tarball's
contents/exports but has no distinct "install into a throwaway env, run it" step
captured as its own fact"*) and its inferred cell (*"… the JS ecosystem has no
equally trivial equivalent, so ts folded partial coverage into `pack-check`
instead"*). The proposed change corrects the ts cell to present-in-`pack-check`
steps 5–6 and the inferred cell's "partial coverage" to a complete
install-and-run; its `harmonize: no` stands, on the language-bound mechanism
(see `OVERRIDE (OV-13)` below). All four still carry the contradicted wording.
Phase D of the check asserts the first three (log lines 57–59); `:182`'s ts and
inferred cells are not asserted by any retained script (phase L asserts only its
harmonize cell, `r50-r4-delta.log:46`) and were read directly for revision 6 — the two
cells above are quoted from the working tree, whose copy of the file is
unchanged from `HEAD`. The packed-content assertion the prompt names is `pack-check` **step 4**,
the `npm pack --dry-run --json` file-list assertion, which is genuinely R26's
F039/F078 subject; **steps 5–6 are a separate install-and-run half that the row
drops.** Affected items: **R50** (this
item — the correction strengthens the case for the capability, moving ts's
contribution from "absent" to "present, and stronger than py's on the assertion");
**R26**, informationally only, its F039/F078 scope unchanged.

**Disposition of that finding: carried forward and endorsed.** The Opus engine
raised it; every line citation it made was re-read here at the pin and every one
held, including its `:306-310` for the run-and-compare pair — revision 1 narrowed
that to `:307` for the comparison, which was one line off and is corrected above;
the raw was right and the imprecision was this synthesis's. The evidence script's
assertion is unaffected and is carried into this revision byte-identical: it
matches the literal `EXPECTED="{{command_name}} $VERSION"` inside the `:299-312`
slice, which is exactly the `:307` assignment. The finding
is recorded for the ledger's owner to apply — a ledger
wording change is a *disposition*, not an edit — and **no ledger row, area file,
index row, prompt, divergence-analysis row or registry file was modified by this
synthesis.** F221's own
evidence is untouched and stands: no workflow at the ts pin invokes the recipe, by
a `/usr/bin/grep -c -F` count of **0** across all **8** workflow files (log lines
44–54).

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`**
throughout, and **nothing was excluded on licence grounds**. The recommendation
adds no crate, so gates 2 (dependency-tree MSRV), 3 (RustSec advisories) and 5
(default features / async-runtime coupling of an added dependency) are likewise
`inapplicable`, each for the stated reason rather than omitted. Gate 4 is answered
by the macOS execution above plus Cargo's presence on both runner images; gate 6
(compile-time cost) is the whole substance of the cadence question and is treated
in `### Principles and implementation` with its levers, honestly labelled a model
rather than a measurement.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** *The artifact that ships is installed the way a consumer installs it,
into a location that is not the developer's environment, and the resulting command
is executed.* Source: both source repositories, read at the programme pins — py
`.github/workflows/ci.yml:222` and `:224` at `b08bccfb` — the wheel step
(`uvx --from "$(ls dist/*.whl)" plbp --version`) and the sdist step that repeats it
against `dist/*.tar.gz` — and
ts `Justfile:299-312` at `cb1cbcb2`. Agreement level: **capability** for the check
existing at all, and **architectural pattern** for the artifact under test being
the *packaged* one rather than the working tree. Both are present in **both**
sources, which is the strongest available evidence that the capability is the
shared principle and the mechanism is the free variable.

| # | Behavior | py at `b08bccfb` | ts at `cb1cbcb2` | Level | Must agree? |
|---|---|---|---|---|---|
| B1 | the packaged artifact is installed into a throwaway location and the command is executed | `ci.yml:222` (wheel) and `:224` (sdist) | `Justfile:299-312` | capability | **yes** |
| B2 | the subject is the packaged artifact, not the working tree | `uv build` (`ci.yml:216`), then `dist/*.whl` and `dist/*.tar.gz` | the `npm pack` tarball (`Justfile:302`) | architectural pattern | **yes** |
| B3 | what a failure blocks | a required CI job | only a developer who runs the recipe | policy | **no — this is F221, kept by `OVERRIDE (OV-13)` below** |
| B4 | how strong the assertion is | `--version` exits 0, output unchecked | `--version` output compared for equality, plus a library-surface import | policy | **no — may vary** |

rs follows **py on B3** and **ts on B4's version-equality half** (the
library-surface import stays recorded hardening, not bound — see below).

**`OVERRIDE (OV-13)` — B3's cadence need not agree at policy level, against
`DIVERGENCE-ANALYSIS.md`'s `harmonize: yes` for F221.** The recorded pattern: the
F221 sub-row (`docs/port/DIVERGENCE-ANALYSIS.md:181`) is class A with `harmonize:
yes`, which by `:50` and `:60` means one value for all three repos; the item row
(`:180`) infers ts's local-only wiring is *circumstantial*, and the analyst note
(`:268`) confirms the item-level class-A reading. B3 keeps `no` against that
record.

**Argument:** the `harmonize: yes` rests on an inference from silence — `:181`
records "no stated reason ts left it local-only" and treats the absence of a
reason as drift. HIGH-3 demands better: distinguish accidental drift from
justified difference *on evidence*, and "recommend a shared low-level value only
when … evidence supports the same tradeoff in all affected ecosystems". Three
pieces of evidence cut against one cadence value. First, gating cost is
structurally per-repo — rs pays a full crate compile per code-touching pull
request, py pays seconds for a `uvx` one-liner, ts pays an `npm pack` plus
install — and the prompt's own HIGH-2 frames exactly this cost question; a
must-agree cadence would prejudge for ts a tradeoff this item researched only
for rs. Second, ts's `pack-check` bundles two scopes in one recipe: step 4 is
R26's packed-content assertion while steps 5–6 are this item's install-and-run
half (the `BASELINE-REVIEW` finding above), so CI-wiring ts's recipe as-is would
drag publish-time content gating into pull-request CI, a scope coupling neither
py's job nor rs's recipe carries. Third, the surveyed sources record no
org-level requirement that every repo CI-gate this check. The departure is
narrow: capability (B1) and architectural pattern (B2) still agree across all
three repos, consistent with the F222 sub-row's own `harmonize: no` (`:182`) —
the mechanism varies while the principle holds. That `no` holds because the
*mechanism* is language-bound — an npm tarball installed by `npm install`, a
wheel run by `uvx`, a `.crate` installed by `cargo install` — and not for the
reason `:182` records, that ts lacks the step: `:182`'s ts cell is the fourth
record the `BASELINE-REVIEW` above corrects. Its inferred cell's observation that
the JS ecosystem has no one-line `uvx` equivalent supports the language-bound
reading; only its "partial coverage" conclusion is refuted.

**Options:** (a) mark B3 must-agree per the recorded `harmonize: yes`, classify
ts's local-only wiring as accidental drift, and prescribe wiring `pack-check`
into ts CI on a path-filtered job as the follow-on — *rejected*: it upgrades an
inference from silence into a cross-repo mandate and decides ts's cost and scope
tradeoffs without ts-side evidence. (b) Keep "need not agree" under this
override — *adopted.*

**The py/ts rationale HIGH-3 requires, as follow-on input.** py keeps its
CI-gated `build-smoke` — no change; it already conforms to the agreed
capability. ts keeps local-only `pack-check` as a justified policy difference —
no forced wiring; if the ts follow-on project splits the recipe's R26 half from
its install-and-run half, py's path-filtered job is the shape to copy and this
decision's cost model is the analysis to redo with ts's numbers. rs adopts py's
cadence now, on the cost model above. OV-13 is the free-pool number (released at
`docs/planning/p02/execution-ledger.md:1140`; phase N of the new evidence script
censuses every current `DECISION.md` and finds no other `OVERRIDE (OV-13)`
declaration), claimed here subject to controller confirmation at packaging, since
numbers are allocated by the controller.

**Essential behaviors and observable acceptance criteria.** Numbered so
`## Empirical check` and `## Engines` can point at them. AC1–AC7 are **proposed for
P03**; the parenthetical notes say which of them this synthesis has already
demonstrated on a fixture crate rather than on the template.

- **AC1** — `cargo package -p rs-launch-blueprint --locked --no-verify` exits 0 and
  `<target_directory>/package/rs-launch-blueprint-<ver>.crate` exists, where
  `<ver>` and `<target_directory>` both come from
  `cargo metadata --no-deps --format-version 1`. *(Demonstrated on a fixture.)*
- **AC2** — the archive carries `Cargo.toml` and a minimized `Cargo.lock`, which is
  what makes `--locked` meaningful on the install step. *(Demonstrated.)*
- **AC3** — `cargo install --path <extracted> --root <root> --locked --debug` exits
  0 **and** `<root>/bin/rslbp` exists and is executable. **The two halves are
  separate assertions**, and that is not defensive padding: with every binary
  behind an unmet `required-features` and no `--bin` flag, `cargo install` prints
  *"none of the package's binaries are available for install using the selected
  features"*, **exits 0, and installs nothing**. *(Demonstrated — see
  `## Empirical check`, phase H.)*
- **AC4** — `<root>/bin/rslbp --version` exits 0 and its stdout is exactly one
  line, `rslbp <ver>`, with no leading `v`, where `<ver>` is the version AC1 read
  from the manifest. *(Demonstrated in the equality form on a fixture — new
  evidence script, phase M.)*
- **AC5** — nothing is left behind: the scratch root and the extracted tree are
  removed on every exit path, and no binary is written to `$CARGO_HOME/bin`.
  *(The `$CARGO_HOME` half demonstrated.)*
- **AC6** *(web leg, conditional on R69's `web` feature)* — with `--features web`
  the install creates **two** executables, `rslbp` and R69's serve binary, and each
  exits 0 for `--version`. The default-feature install creates exactly **one**;
  an install that creates two on the default leg means the feature gate leaked.
  *(Two parts are demonstrated, and the composition is not. Demonstrated: the
  default install creates exactly one binary (`r50-check.log:145`, phase F3),
  and a single `[[bin]]` carrying `required-features = ["web"]` installs zero
  binaries with the feature off and one with it on (`r50-check.log:188-205`,
  phase H). Not demonstrated: the AC6 composition itself — an ungated `rslbp`
  plus a gated serve binary, one installed on the default leg and two on the
  `web` leg — because every fixture in the evidence declares exactly one
  `[[bin]]` (`evidence/r50-check.sh:220`, the only `[[bin]]` in
  `make_fixture`; `evidence/r50-r4-delta.sh:199`, the phase-M fixture's only
  one). That composition stays unproven until R69's serve target exists
  and P03 builds it (`What P03 must validate`, item 5). R69's concrete binary
  name is not this item's — see below.)*
- **AC7** — *(the criterion that distinguishes the recommendation from its
  runner-up)* deleting a file the build needs from the `[package] include`
  allow-list makes AC3 **fail**. A template that cannot demonstrate AC7 is not
  running the recommended procedure. *(Demonstrated — phase G.)*

**Architectural alternatives, compared before any tool was chosen.** All five
operate on the same binary and differ only in what they put under test.

| Option | Procedure | Exercises R49's `include`? | Exercises a consumer's install path? | Executes the command? | Verdict |
|---|---|---|---|---|---|
| **A** | `cargo run --locked -- --version` | no | no | yes, from the working tree | **Reject.** It cannot fail for any reason F222 exists to catch |
| **B** | `cargo install --path . --root <tmp> --locked` | **no** | partly | yes | **Runner-up.** The ledger's own guess and `sharkdp/bat`'s live CI pattern; blind to the packaging half — **measured**, see below |
| **C** | pack → extract outside the repository → `cargo install --path <extracted> --root <tmp>` → run | **yes** | yes | yes | **Recommended** |
| **D** | build a local directory registry (`cargo-local-registry`) and install through it | yes | most faithfully | yes | **Reject on cost.** A third-party tool plus a registry fixture and a checksum/index step, to close a gap one indirection wide |
| **E** | `cargo publish --dry-run --locked` | yes | no | **no** | **Reject as a substitute; already adopted elsewhere.** It never runs the command, and it is **R26's element 3** |

**Why C over B, as an observation rather than an argument.** The two options were
run against the same deliberately broken fixture: a package whose `src/main.rs`
needs `src/helper.rs`, with `include` listing only `/src/main.rs` and
`/Cargo.toml`. Option C **failed** at the install step with
`error[E0583]: file not found for module 'helper'`, exit **101**. Option B, given
the identical package, **succeeded** with exit 0 and installed a working binary,
because `--path .` builds the directory as it stands and the omitted file is still
on disk (`## Empirical check`, phase G; log lines 151–186). That is AC7, executed.

**Why that gap is not already covered.** R26 (`packed-artifact-content-guard`,
resolved) owns the packed-content question, and its own decision places elements
1–4 **on the publish workflow's verify job, before the upload** — a pull-request
copy of element 1 is recorded there as "recommended hardening, **not bound
here**", deferred to R11 (whose published value adds no packed-content
pull-request gate — asserted absent in phase K of the new evidence script). So
at pull-request time the template as currently
decided checks **nothing** about the packaged file set, and this item's marginal
coverage is real: it moves the packaging failure from release-tag time to review
time and adds the one step neither R26 element performs — the installed `rslbp` is
**executed**. A claim of more than that would be overselling it.

**Why the extraction goes to a scratch directory, and the ground that did *not*
survive.** The Opus engine argued that installing from an in-tree
`target/package/<pkg>-<ver>` invites a workspace-membership failure, because
Cargo's own verification path manufactures an ephemeral workspace to avoid exactly
that. **That claim was tested here and not reproduced**: on cargo 1.98.0,
`cargo install --path target/package/r50spike-0.4.2` succeeded, exit 0, with no
workspace error, in **both** live layouts — a root package carrying `[workspace]`,
and a virtual workspace root with `members = ["crates/*"]` (R02, which crate hosts
the binary targets, is still open, so both shapes were run). The recommendation
keeps the scratch extraction on a **different and observed** ground: with
`--no-verify` — the cost lever that removes a duplicated compile — **cargo leaves
no extracted copy in the tree at all**. The extracted directory is a by-product of
the verification build, not of packaging: with `--no-verify` the directory does
not exist, and with verification it does, at the price of a second full compile of
the same tree the install is about to compile again. Extracting the archive to
`$(mktemp -d)` and deleting it on exit is therefore not a workaround for a Cargo
defect; it is the only form the `--no-verify` lever permits, and it makes AC5's
cleanup assertion true by construction.

**Cost, with its workload and its levers, stated as a model and not as a
measurement.** No timing transfers from this synthesis: the fixtures are
zero-dependency crates that compile in well under a second, which proves the
composition works and proves nothing whatever about the template's cost. The real
workload is one compile of `rs-launch-blueprint`'s dependency tree plus the crate,
on a GitHub-hosted `ubuntu-latest` runner. The levers, each with its documented
source in the cargo-install reference
(`https://doc.rust-lang.org/cargo/commands/cargo-install.html`, retrieved
2026-09-17):

| Driver | Default | Lever | Effect |
|---|---|---|---|
| Profile | release | `--debug` | dev-profile compile, and the stricter smoke profile — `debug-assertions` and `overflow-checks` are on, so a startup path that trips an assertion fails loudly |
| Target directory | a new temporary folder | `--target-dir <target_directory>/install-check` | lets R10's cache action cover the smoke build; the docs name CI caching as the reason the flag exists |
| Duplicate verification build | `cargo package` verifies by compiling the extracted tree | `--no-verify` | removes one of two compiles of the same tree |
| Install tracking | tracked | `--no-track` | no tracking state written for a root deleted on exit |
| Feature set | default (`web` off) | `--features web` as a second, path-gated step | a second dependency tree; the step's condition (R11's `web` output) is currently vacuous, so this cost is paid on every job run until the key narrows |

With `--debug`, a cached `--target-dir` and `--no-verify`, the marginal cost over
the ordinary test job is recompiling the crate itself against already-cached
dependencies. That is the basis for answering the prompt's HIGH-2 **no** — Rust's
compile time does not argue for ts's local-only cadence — with the caveat carried
in every direction: it is a cost model backed by documented behaviour and by
well-regarded projects running compile-heavy packaging checks on pull requests
(`astral-sh/uv` gates `cargo publish --workspace --dry-run` on a path-filtered PR
job; `sharkdp/bat` runs `cargo install --locked --path .` in CI), **not a
measurement**, and `## Engines` records it as unproven.

**Lockfile handling.** `--locked` on the pull-request lane. The cargo-install
reference (`https://doc.rust-lang.org/cargo/commands/cargo-install.html`,
retrieved 2026-09-17)
states that the packaged `Cargo.lock` is ignored by default and that
`--locked` forces its use; the unlocked form is the literal behavioural twin of
`uvx`, which resolves fresh against the index, but it is also network-coupled and
non-deterministic — a dependency published an hour ago can turn an unrelated pull
request red. This decision trades that twinhood for determinism and
**recommends to R34, without changing it**, that its `canary.yml` `latest-deps`
leg run the same recipe with `--locked` dropped. That is R34's and R11's call.

**What the check asserts, and what it deliberately does not.** Exit 0, **plus**
the installed file exists (AC3's second half, grounded in the measured
`required-features` behaviour), **plus** `--version`'s stdout is exactly one
line, `rslbp <ver>`, with `<ver>` from `cargo metadata` (AC4) — ts's equality
form, not a substring. The equality is fully determined by published decisions:
R49 fixes the binary name `rslbp` (registry `build-tool-output-shape`), R60 AC2
fixes the single-line `<tool> <semver>` format with no leading `v` (R60
`DECISION.md:1086`), and the semver is `CARGO_PKG_VERSION`, which mirrors the
manifest (`:1260`, `:1278`). What **R22** (`runtime-version-accessor`, still
open) owns is only the accessor's source — compile-time `env!` versus a runtime
lookup — which cannot change the asserted string. Revision 3's substring rested
on R60 being open; R60 was published (commit `1bc131d`,
`OWNER-ACCEPTANCES.md:55`) before this run was prepared, and the run's own
`inputs/CLAUDE.md` snapshot already marked it `resolved` — the premise was false
when written and is corrected here, not merely tightened. The **library-surface**
check ts also performs
(`Justfile:312`) is recorded as hardening and **not bound**, on two grounds.
*First, a broken library already fails AC3, by a Cargo rule rather than a layout
choice.* Cargo compiles a package's library before every binary target in that
package, whether or not `src/main.rs` references the library. The revision-5
probe under `## Empirical check` shows it on cargo 1.98.1: with a syntax error
in `src/lib.rs` and a `src/main.rs` that never names the library, both
`cargo build --bin` and `cargo install --path … --root …` exit 101 on
``could not compile `probe` (lib)``, and no `bin/` directory is created. The
same probe was run independently by the judgment audit of revision 4
(`review/audit-fable.r4.md:102-116`). Because the extracted `.crate` is what
AC3 compiles, a packaging hole that strips a library module also fails AC3.
*Second, what no compile covers, under any layout, is the library's
consumer-facing surface*: whether an external crate can depend on the library
and name its public API, which is what ts's ESM import checks. In rs that
surface belongs to **R04** (`public-api-surface-enforcement`, `resolved`,
`research/CLAUDE.md:10`). R04 enforces it with private modules and one root
`pub use` block, two `compile_fail,E0603` doctests, and a `cargo-semver-checks`
CI gate (R04 `DECISION.md:7`). R04's proposed template change also makes
`src/main.rs` import the library only through its root path (`:51`). Revision 4
attributed a "thin CLI over the library crate" layout to R49 and said the `[lib]`
is "compiled transitively"; both are withdrawn. R49 fixes only the
`[lib]`/`[[bin]]` split (R49 `DECISION.md:692-693`, `:1005-1010`) and states no
dependency of `main.rs` on the library, and the transitive-compile mechanism is
not how Cargo works. The flip condition is explicit and is `re-verify:` trigger
(7): a scratch consumer crate against the extracted library becomes necessary
rather than optional **if R04 drops or weakens its consumer-surface
enforcement, if R04 or P03 requires an external-consumer check against the
packaged library, or if a Cargo release stops building a package's library for
its binary targets**.

**Recipe vocabulary (the prompt's LOW-5).** Yes, it belongs to the F176–F178
vocabulary, which is `just` + `[group(…)]` attributes + short aliases — not a
fixed list of recipe names. Recipe **`install-check`**, attributes
`[group('build'), group('releases')]`, **no alias**; CI job **`install-smoke`**.
Grounds, verified at the pin: ts's closest recipe carries
`[group('releases'), group('build')]` (`Justfile:275`) and has no alias
(`/usr/bin/grep -c -E '^alias [a-z]+ := pack-check$'` = **0**), and in both sources
aliases are reserved for the daily loop. The name deliberately differs from ts's
`pack-check` because in rs the packed-content half is R26's and lives in the
publish workflow, so a recipe called `pack-check` would promise a check it does
not perform; the job name echoes py's `build-smoke` family while naming what it
does.

**Reference implementations.** Each half of the stack has a live, well-regarded
adopter, and the composition as a whole does not — stated rather than papered
over. `sharkdp/bat` runs `cargo install --locked --path .` inside GitHub Actions
and then runs the installed command (`.github/workflows/CICD.yml:99`, `:103`,
`:129`; 60 472 stars, `archived: false`, `pushed_at` `2026-09-04T19:10:30Z`, 330
open issues — `GET https://api.github.com/repos/sharkdp/bat` and
`GET https://api.github.com/search/issues?q=repo:sharkdp/bat+is:issue+is:open`,
retrieved 2026-09-17). `astral-sh/uv` — the authors of the very `uvx` F222 records
py using — gates a compile-heavy packaging check on a path-filtered pull-request
job (`.github/workflows/check-publish.yml` plus `ci.yml:58-61`; 89 890 stars,
`archived: false`, `pushed_at` `2026-09-17T02:33:02Z`, 2 360 open issues, same
endpoints, retrieved 2026-09-17). `ts-launch-blueprint` at pin `cb1cbcb2` is the
shared adopter of (task runner × pack-install-run smoke). But a GitHub code search
for the literal `"cargo install --path target/package"`
(`GET https://api.github.com/search/code`, retrieved 2026-09-17) returned
`total_count: 7`, all documents or fixtures in small repositories — **no
well-regarded project installs from an extracted `.crate`**, so the recommendation
rests on first-party primitives plus the measured AC7 result, not on adoption.
`just` 1.58.0 is the recipe host and is settled upstream by F176 (`COMMON →
REUSE`), re-verified rather than re-opened here: 533 628 90-day downloads,
2 597 663 all-time (`GET https://crates.io/api/v1/crates/just` →
`crate.recent_downloads`, `crate.downloads`), newest un-yanked `1.58.0`
`created_at` `2026-08-03T20:29:15Z` (`…/versions`), 35 828 stars, `archived:
false`, `pushed_at` `2026-09-01T20:47:57Z`, 171 open issues, median first
maintainer response **0.53 days with 0 unanswered** across the ten most recently
opened issues, and no RustSec page (`https://rustsec.org/packages/just.html` →
HTTP 404, against a `time` → HTTP 200 control) — maintenance state **`active`**.
All retrieved 2026-09-17 by the Opus engine.

**Migration implications for P03.** All additive: `Justfile` gains one recipe;
`.github/workflows/ci.yml` gains one job whose body is a single
`run: just install-check` plus the conditional web step; `Cargo.toml`, `.gitignore`
and `just check-deps` are unchanged — the recipe adds no tool (`tar` and `jq` are
already required by R26's element 2, `cargo` and `just` by R42). One portability
correction when porting ts's recipe shape: ts hardcodes
`mktemp -d /private/tmp/ts-pack-check.XXXXXX` (`Justfile:299`), a macOS-only path;
the Rust recipe uses a bare `mktemp -d`, which works on both runner images. The
job needs outbound network (`cargo install` resolves and downloads dependencies) —
the same note R26 recorded for its publish-time verify job, handed to **R08**
rather than settled here. The recipe derives both the `.crate` path and its
`--target-dir` from `cargo metadata`'s `target_directory` rather than from the
literal string `target/`, because R49's `build-tool-output-shape` states the
directory is relocatable; a hardcoded `target/` would break the recipe in the very
job that invokes it.

re-verify: 2027-03-17, or earlier on any of — (1) a Cargo release that changes `cargo install`'s default lockfile handling, its default target directory, or the semantics of `--root`, `--debug`, `--no-track` or `--target-dir`; (2) a Cargo release that changes `cargo package`'s output path, its default verification, or `--no-verify` semantics — in particular, if `--no-verify` ever leaves an extracted copy in the tree, the ground for the scratch extraction moves; (3) R49 changing the binary name `rslbp`, the single `[[bin]]`, or the `[package] include` allow-list; (4) R11 narrowing its `web` key, or the controller acting on R11's `web`-equals-`code` flag (R11 DECISION:202,316), at which point the web step's condition turns load-bearing rather than vacuous; (5) R69 resolving its serve binary's placeholder name to a literal, or changing its `required-features` gate; (6) R22 resolving its accessor's source (compile-time versus runtime), confirming the equality assertion still reads the manifest version — R60's AC2 already fixed the output format, so no tightening remains; (7) R04 (`public-api-surface-enforcement`) dropping or weakening its doctest or `cargo-semver-checks` enforcement of the library's consumer surface, R04 or P03 requiring an external-consumer check against the packaged library, or a Cargo release that stops building a package's library for its binary targets — any of which makes the scratch-consumer library check necessary; (8) a macOS-only packaging failure being observed, which widens the job to the two-runner matrix; (9) R26's elements moving from the publish workflow to pull-request CI, which changes this item's marginal coverage; (10) R34 accepting or declining the unlocked `latest-deps` leg recommended above; (11) the F222 ledger correction above being applied or rejected; (12) the first execution of the recipe against the real template in P03, which is when every cost figure in this decision first becomes measurable; or (13) R68 (`release-binary-artifacts`) resolving, which fixes where the template's only release-profile compile lives and therefore what the `--debug` trade costs

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

No `CONFLICT:` line: no consumed or read parameter needs to change for this
recommendation to hold, and neither raw report raised one.

**Why the list has exactly four lines.** R50's binding prompt carries an empty
`- owns:` line and an empty `- consumes:` line (asserted mechanically — `## Empirical
check`, phase B, log lines 28–29), so the item owns no parameter and registers no
consumption. The four fixed registry parameters are therefore the complete set of
`- assumes` declarations, and each value above is the **current**
`docs/port/PARAMETERS.md` row, byte-compared against this run's
`inputs/PARAMETERS.md` snapshot for all four (log lines 18–25).

**How the `web-extra-surface` snapshot discrepancy was handled.** This run was
prepared before R69 published: `inputs/PARAMETERS.md` shows
`web-extra-surface = —` while the live registry now carries R69's value. Both
states were asserted rather than assumed — the snapshot row still reads `—` (count
1) and the live row no longer does (count 0), log lines 26–27. The discrepancy
changes nothing that can be written here, because **R50's prompt registers no
consumption of `web-extra-surface`**: an `- assumes web-extra-surface = …` line
would be outside the prompt's coupling set and would fail publication either way,
against the snapshot's `—` or against R69's live value. The parameter is instead
read as context for AC6 and the web leg, both written conditionally, and the fact
that R69's value arrived **after** this run was prepared is stated here as the
task requires. R69's decision is published and owner-facing; note that the second
binary's name is a **placeholder** in R69's own text, so this decision names R49's
`rslbp` for the smoke test and treats the serve binary's concrete name as R69's
and P03's to fix.

**How the other parameters bear on the decision, read but not registered.**
`build-tool-output-shape` (R49, owner-accepted, decision sha256
`86b7f925ef89ac682ea00bb0b6fea8a809c1abc712d9e0e0ced8e5082990d948`) binds this
item through the prerequisite, and the prompt's `## Couplings` deliberately
registers no consumption of it because the test procedure does not vary by the
target's exact name — only by whether a `[[bin]]` target exists. Three of its
values are read: the single `[[bin]]` named **`rslbp`**, the package name
`rs-launch-blueprint` (so `cargo install rs-launch-blueprint` installs the command
`rslbp` with no `--bin` flag, and integration tests resolve it through
`CARGO_BIN_EXE_rslbp`), and the `[package] include` allow-list whose completeness
AC7 exercises. `ci-job-structure` (R11) is **resolved in the live tree**
(`research/CLAUDE.md:17`; it was `open` in this run's `inputs` snapshot, so it
resolved after preparation), and its owned value already encodes this item's job
— 'install-smoke, R50's one ubuntu-latest job, whose web leg is a step
conditioned on the web output' (`docs/port/PARAMETERS.md:12`). The job as written
matches that shape: a dedicated job gated on `code`, its web leg a step on
`web`, its body a single `just install-check`, and the skip gate R11's mechanism
rather than a second one invented here. Two consequences are recorded, not
decided: with `web` equal to `code` the step condition is currently vacuous (R11
`DECISION.md:202`) — the cost prose above says so — and this revision fires
R11's own re-verify trigger ('R50 revising its revision 2', R11
`DECISION.md:316`), whose re-check belongs to R11 and the controller.
`package-manager-invocation`
(R42, resolved) fixes how the recipe names its commands — `cargo package`,
`cargo install` and `cargo metadata` written as Cargo's own built-in subcommands,
`just`, `tar` and `jq` as bare executables resolved on `PATH`. `license` bears on
the decision only through R49's `include` allow-list, which must carry both
`LICENSE-MIT` and `LICENSE-APACHE` or the published artifact carries neither text;
it was **not** evaluated as a fitness gate, per the owner ruling of 2026-09-12.

## Empirical check

**Toolchain and host.** `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`;
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`; `just 1.57.0` (via the pinned
`/Users/stevemorin/bin/just` in the archive rerun — see below); `Darwin arm64`,
macOS `26.4` (build `25E246`).

**Command and working directory.**

```
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/evidence/r50-check.sh
```

Exit status **0**. Full output:
`review/evidence/r50-check.log` (213 lines; sha256
`4cc2f81a41e01c4f35dcaa8c9f17295bb1331c34a3d31f1b1feddd2fbb7fbe21`). Script:
`review/evidence/r50-check.sh`, `shellcheck`-clean, `set -o pipefail` at the top,
`/usr/bin/grep` by absolute path with the binary named beside every count.
**68 `PASS`, 0 `FAIL`, 0 `SKIP`.** Revision 3 refreshes this log for one drifted
fact and nothing else: Homebrew moved cargo/rustc from 1.98.0 to 1.98.1, so
`diff` against the revision-2 log shows exactly two changed lines — the Phase-A
cargo and rustc identity lines — with all counts, all assertions and all line
numbers unchanged.

**Reproducibility, having just shown it.** The script was run twice in succession
and the two outputs `diff`ed byte-for-byte before this sentence was written: they
are **identical**, and the saved log is run 1 of that pair. Reproducibility is not
free here — Cargo prints absolute paths, elapsed times, archive file counts and
byte sizes, and an occasional package-cache lock notice, none of which is stable —
so the script normalizes exactly those: the scratch directory (in both its logical
and its `/private`-resolved macOS form) to `<SCRATCH>`, `$HOME` to `<HOME>`,
` in N.NNs` to ` in <T>s`, archive `N files, SIZE` to `<N> files, <SIZE>`, and it
drops any `Blocking waiting for file lock` line. Two values that a reader might
expect to vary do **not**, and are asserted on directly rather than normalized: the
observed exit statuses, and the `0.4.2` the installed fixture binary prints.

**Rerunnable from a clean extraction, with the rerun retained.** The repository
root is derived from the script's own path, never from `git rev-parse`, and no
phase reads this repository's git history. Revision 1 asserted this rerun without
keeping its output; revision 2 keeps it, and revision 3 fixes it. A second,
separate wrapper, `review/evidence/r50-r2-archive-rerun.sh`, extracts
`git archive HEAD` into a scratch directory, confirms the extraction carries no
`.git` entry, confirms the archived `r50-check.sh` is byte-identical to the one
in the working tree
(`sha256 bdd7bc3c3c0e7fb025b92382342403cd32250da074c150496537a90ad6d55a39`),
resolves the first `just` on `PATH` that answers `--version` under an empty home
(`INFO archive/just-direct-binary`, here `/Users/stevemorin/bin/just`), asserts
that resolution and the clean-home `--version` exit status (2 `PASS` lines), runs
**that archived copy** with `$HOME` pointed at an empty directory and the resolved
binary pinned at the head of its `PATH`, and asserts the counts rather than
reporting them. Its output is
`review/evidence/r50-r2-archive-rerun.log` (220 lines; sha256
`508ee472ff9dab3c698232671794ccefb56d8fd352dd41c00eb126d55cb48e34`), exit **0**,
**12 `PASS` of its own** and 0 `FAIL`, recording the inner run at exit **0**,
**54 `PASS`, 0 `FAIL`, 1 `SKIP`**. The wrapper echoes the inner run's normalised
output into its own log, so `/usr/bin/grep -c '^PASS'` over that log returns
**66** — the wrapper's 12 plus the inner run's 54 — and `^PASS archive` returns
the wrapper's 12. The inner run's one skip names its own phase
(`SKIP ts-pin/all — checkout absent at …`), and the wrapper asserts **0**
`PASS ts-pin/` lines in it — so the 54 is 68 minus phase C's 14 ts-pin
assertions and nothing else. That wrapper
was itself run twice and the outputs `diff`ed byte-identical before this
paragraph was written. It needs `git archive`, so it announces
`SKIP archive-rerun/all` by name when no `.git` entry is present at the
repository root. **Why the wrapper changed and the inner script did not:** the
empty-home run broke only on the `just` the ambient `PATH` happened to resolve —
a mise shim whose config trust does not survive the emptied home — while the
archived inner check itself is sound; pinning a probed binary in the wrapper
restores the retained `just 1.57.0` line without touching a script two revisions
and one empirical rerun have already verified. `r50-check.sh` is therefore still
byte-identical to revision 1. Both logs are refreshed in revision 3: the wrapper
log for this fix (plus the toolchain drift above), and `r50-check.log` for the
toolchain drift alone.

**Revision-4 delta evidence.** The three round-3 findings turn on
published-state facts no earlier phase asserts, so revision 4 adds a second
script, `review/evidence/r50-r4-delta.sh` (`shellcheck`-clean, `set -o pipefail`,
`/usr/bin/grep` by absolute path), with its retained log
`review/evidence/r50-r4-delta.log` (86 lines; sha256
`ae1a2a49d17757c9cabdbe64be91f48b1f9e420ceb22e484f21864e3b5ace5e7`), exit **0**,
**45 `PASS`, 0 `FAIL`, 0 `SKIP`**. Phase J asserts the version-string citations
(log lines 18–27): R60 AC2's byte-identical one-line format with no leading `v`
(`:1086`), the `CARGO_PKG_VERSION` version row (`:1260`) and its manifest mirror
(`:1278`), R60's publication record (`OWNER-ACCEPTANCES.md:55`) and its
`resolved` state in this run's own snapshot, R49's `rslbp` name in the live
registry, and R22 still `open`. Phase K asserts the R11 citations (lines 30–39):
`resolved` in the live index, the registry's install-smoke passage
(`PARAMETERS.md:12`), the `web`-equals-`code` (3 lines) and always-true passages
(R11 `DECISION.md:202`), R11's re-verify line naming both this revision and the
web flag (`:316`), R11's `open` state in the run snapshot, its acceptance
artifact, and the absence of any packed-content gate in its registry row. Phase
L asserts the `DIVERGENCE-ANALYSIS.md` rows the override answers (lines 42–49):
`:180` circumstantial/partly, `:181` F221 `yes` with "no stated reason", `:182`
F222 `no`, `:50`, `:60`, `:268`. For `:182` it asserts only the harmonize cell
(`r50-r4-delta.log:46`, the `| no |` match), not the row's ts or inferred cell;
those two were read directly for revision 6. Phase M demonstrates AC4's equality end to end
on a fresh zero-dependency fixture — pack `--no-verify`, extract outside the
tree, install, run (lines 52–74): the installed command prints exactly
`rslbpspike 0.4.2` (line 68), one line, exit 0, no leading `v`. Phase N takes
the OV-13 census — no `OVERRIDE (OV-13)` in any current `DECISION.md` outside
this run, the ledger's free-pool release (`:1140`) — and pins `AGENTS.md`'s
`**Argument:**` / `**Options:**` shape (lines 77–82). The script was run twice
under a private `CARGO_HOME=/tmp/cargo-r50r4` and the outputs are byte-identical;
the retained log is run 1 of the pair. Its cargo invocations pass `--offline` on
the zero-dependency fixture, exactly like the spike, and the recommended recipe
still does not.

**O-1, and why `r50-check.sh` does not carry the unset.** The round-3 empirical
audit suggested unsetting `CARGO_TARGET_DIR` / `CARGO_BUILD_TARGET_DIR` at the
top of `r50-check.sh` (observation O-1, non-blocking). That edit would change a
script two revisions and repeated empirical reruns have verified byte-for-byte,
and would break the archive wrapper's byte-identity assertion against HEAD's
copy — for an environment the decision's stated conditions (recorded command,
cwd, toolchain, clean environment) already exclude, and under which the script
reproduces exactly. The unset is instead carried by the new `r50-r4-delta.sh`,
which hardens nothing already pinned. Revision 4 re-ran `r50-check.sh` twice
under `env -u CARGO_TARGET_DIR` with the same private `CARGO_HOME`: both runs
exit 0, 68 `PASS`, 0 `FAIL`, 0 `SKIP`, byte-identical to the retained log and to
each other; the archive wrapper was re-run once more with the same result (exit
0, 220 lines, byte-identical).

**Revision-5 probe: a package's binaries always build its library.** This
probe grounds the library-surface paragraph under `## Decision`. It is
recorded here verbatim and is **not retained as a script or log**, because the
revision-5 job permits no file write other than this decision and its snapshot.
The retained evidence scripts and logs are unchanged. Conditions: cargo 1.98.1
(as above), private `CARGO_HOME=/tmp/cargo-r50r5`, `CARGO_TARGET_DIR` and
`CARGO_BUILD_TARGET_DIR` unset, every `cargo` call `--offline`, a
zero-dependency fixture in a `mktemp -d` scratch directory (normalised to
`<SCRATCH>`) deleted afterwards. The fixture:

```
# Cargo.toml
[package]
name = "probe"
version = "0.1.0"
edition = "2024"

[lib]
path = "src/lib.rs"

[[bin]]
name = "probebin"
path = "src/main.rs"

# src/main.rs — never names the library (grep -c probe src/main.rs = 0)
fn main() { println!("hi"); }

# src/lib.rs — a syntax error
pub fn f( {
```

Observed. `cargo build --offline --bin probebin` exits **101**, ending
``error: could not compile `probe` (lib) due to 1 previous error``.
`cargo install --offline --path . --root <SCRATCH>/root --debug --no-track
--target-dir <SCRATCH>/t2` exits **101**; its full output is:

```
  Installing probe v0.1.0 (<SCRATCH>)
   Compiling probe v0.1.0 (<SCRATCH>)
error: this file contains an unclosed delimiter
 --> src/lib.rs:1:13
  |
1 | pub fn f( {
  |         - -^
  |         | |
  |         | unclosed delimiter
  |         unclosed delimiter

error: could not compile `probe` (lib) due to 1 previous error
error: failed to compile `probe v0.1.0 (<SCRATCH>)`, intermediate artifacts can be found at `<SCRATCH>/t2`.
To reuse those artifacts with a future compilation, set the environment variable `CARGO_BUILD_BUILD_DIR` to that path.
```

`<SCRATCH>/root/bin` does not exist afterwards. The control: with `src/lib.rs`
repaired to `pub fn f() {}`, the same `cargo build --bin probebin` finishes,
exit 0. The judgment audit of revision 4 records the same result from its own
run (`review/audit-fable.r4.md:102-116`).

**What was checked, and the result.** Nothing was built in this repository and the
template was not scaffolded: every compile below is a throwaway fixture crate with
**zero dependencies**, created under a `mktemp -d` scratch root and deleted on
exit, and `cargo publish` was never invoked in any form (asserted, log line 209).
One deliberate difference between the spike and the recommended recipe: every
`cargo` command in the check passes **`--offline`**, which the fixtures permit
because they have no dependencies to resolve and which keeps the spike provably
network-free. **The recipe this decision recommends does not pass `--offline`** —
`cargo install` must resolve and download the template's real dependency tree —
so the spike is evidence about the composition's mechanics, not about its network
behaviour on a runner.

| Phase | Check | Result |
|---|---|---|
| A | toolchain and host identity | as above (log lines 6–12) |
| B | the four fixed registry values, live versus this run's snapshot; the `web-extra-surface` discrepancy; the prompt's empty `owns`/`consumes` lines | 8 `PASS` (lines 18–29) |
| C | ts `pack-check` at pin `cb1cbcb2`: the header comment, the group attributes, the absence of an alias, the six install-and-run lines, and all 8 workflow files grepped for the recipe name | 14 `PASS`, 0 matches for `pack-check` in any workflow (lines 32–54) |
| D | three of the four records the `BASELINE-REVIEW` contradicts still carry their recorded wording; the fourth, `DIVERGENCE-ANALYSIS.md:182`, was read directly for revision 6 (see `## Decision`) and is not asserted by this phase | 3 `PASS` (lines 57–59) |
| E | `cargo install --help`: every flag the recipe uses is present; `--dry-run` is marked *unstable* and is therefore not used | 9 `PASS` (lines 62–70) |
| F | the recommended composition, end to end, on a workspace-rooted fixture | 22 `PASS` (lines 78–148) |
| G | **AC7** — option C versus option B against the same hole in `include` | 5 `PASS` (lines 151–186) |
| H | **`required-features`** — the ground for asserting the installed file exists | 5 `PASS` (lines 192–205) |
| I | nothing installed outside the scratch root; no `cargo publish` in the script | 2 `PASS` (lines 208–209) |

**The four results the decision turns on, quoted from the log.**

1. **AC7, the discriminator (phase G).** Against a fixture whose `src/main.rs`
   needs `src/helper.rs` while `include` lists only `/src/main.rs` and
   `/Cargo.toml`: the packaged archive omits the file
   (`AC7/packaged-set-omits-helper`, 0 matches for
   `r50spike-0.4.2/src/helper.rs`); **option C fails** —
   `error[E0583]: file not found for module 'helper'`, then
   `error: could not compile 'r50spike' (bin "rslbpspike") due to 1 previous error`,
   `PASS AC7/optionC-fails-on-the-hole (exit 101)`; and **option B passes on the
   identical package** — `PASS AC7/optionB-passes-on-the-same-hole (exit 0)`,
   `PASS AC7/optionB-installed-a-binary-from-the-unpackaged-tree`.
2. **`required-features` (phase H).** With the only `[[bin]]` carrying
   `required-features = ["web"]` and the feature off:
   `warning: none of the package's binaries are available for install using the
   selected features`, `PASS reqfeat/exit-is-zero (exit 0)`,
   `PASS reqfeat/nothing-was-installed`. With `--features web` on the same
   package: exit 0 and the binary is installed. An exit status alone cannot carry
   AC3.
3. **The `--no-verify` fact that places the extraction (phase F).**
   `PASS optionC/package/no-verify-skips-the-second-compile` (0 matches for
   `Verifying`) and `PASS optionC/package/no-verify-leaves-no-extracted-copy`;
   with verification instead, `PASS optionC/package-with-verify/verifies`,
   `PASS optionC/package-with-verify/second-compile` and
   `PASS optionC/package-with-verify/extracted-copy-exists`.
4. **The workspace claim that did not reproduce (phase F, F2a and F2b).**
   `PASS in-tree/root-package-workspace/install (exit 0)` and
   `PASS in-tree/virtual-workspace/install (exit 0)`, each with 0 matches for
   `member of the wrong workspace`. Recorded as a correction to the Opus raw under
   `## Engines`.

The end-to-end composition itself (phase F3) ran clean:
`Finished 'dev' profile [unoptimized + debuginfo] target(s)`, exactly one binary
installed under the scratch root, `r50spike 0.4.2` printed by the installed
command, exit 0 — and the archive was confirmed to carry both `Cargo.toml` and a
`Cargo.lock`, which is what makes `--locked` meaningful on the install step.

**What this check does not establish**, stated here rather than left to be
inferred: it did not run the recommendation against `rs-launch-blueprint` (there
is no such package), it produced no transferable timing, and it ran only on macOS.
Those limits are carried into `## Engines` as unproven rows.

## Engines

- Codex (gpt-5.6-terra) — `raw/codex.md`
  (`raw/codex-8d50eb6746d64ddc1011b7a4e471004d01d1bf2b82e8971274eb5e82e355b2d3.md`),
  10 `###` sections, two members, no `BASELINE-REVIEW:` finding.
- Claude Opus 5 — `raw/opus.md`
  (`raw/opus-266a269202b7053dca0cf3b0339558f689748d463dc537ac83b2c25abda0efbf.md`),
  10 `###` sections, three members, one `BASELINE-REVIEW:` finding on F222.

No Doxa engine ran; this is a Focused two-engine item.

**Disagreement 1 — the mechanism: option B or option C.** Codex recommended
option B, `cargo install --path . --root <mktemp-root> --locked`, the ledger's own
recorded guess; Opus recommended option C, pack → extract → install → run.
**Settled for option C, by measurement plus a scope fact.** The measurement is
phase G: given the same package with a hole in its `include` allow-list, option C
failed with exit 101 and option B succeeded with exit 0 and installed a working
binary. The scope fact is that nothing else in the template covers that gap at
pull-request time — R26's decision places its elements 1–4 on the **publish**
workflow's verify job and records a pull-request copy as unbound hardening
deferred to R11. Codex's argument for B is not wrong about B; it simply describes
a weaker test, and it is retained as the **runner-up** with a live adopter
(`sharkdp/bat`) for P03 to fall back to if the extract-and-install step proves
fragile.

**Disagreement 2 — the ground for extracting outside the repository.** Opus
asserted that an in-tree `target/package/<pkg>-<ver>` install "invites exactly the
workspace-membership problem" Cargo's verification path bypasses, and labelled it
unverified. **Corrected here: the claim does not reproduce on cargo 1.98.0.** The
in-tree install succeeded, exit 0, in a root-package workspace and in a virtual
workspace with `members = ["crates/*"]` — both shapes run because R02 is open
(phase F, F2a/F2b). The recommendation is unchanged but its ground is replaced by
an observed one: with `--no-verify` there is **no in-tree extracted copy at all**,
so the scratch extraction is the only form that lever permits. This also narrows
the re-verify trigger: what would move the decision is `--no-verify` gaining an
extraction, not a workspace-membership regression.

**Disagreement 3 — how many runners.** Codex recommended a matrix over
`ubuntu-latest` and `macos-latest`, reading `target-os-matrix` as a per-job
mandate; Opus recommended `ubuntu-latest` only. **Settled for `ubuntu-latest`
only**, on the three grounds given in `## Decision`, the strongest of which is that
py's own `build-smoke` uses one runner despite py's three-OS test matrix, so this
is py's cadence rather than a narrowing of it, and the second of which is that the
macOS half of the recipe was **executed in this synthesis** on macOS 26.4 arm64.
Codex's reading is the safer one and its cost is one extra cold compile per
code-touching pull request; the widen trigger is named in `re-verify:` (8).

**Disagreement 4 — the recipe's name and the assertion's strength.** Codex named
one recipe `install-smoke` and asserted exit 0 plus a version string; Opus named
the recipe `install-check` and the job `install-smoke`, and asserted exit 0 **plus**
the installed file's existence **plus** a version substring (tightened to equality
in revision 4 — see the closing sentence). **Settled for Opus's
split and Opus's assertion**, the latter because phase H reproduced the
status-0-installed-nothing outcome that makes the file-existence assertion load-
bearing rather than decorative, and the former because ts's analogous recipe's
group attributes and alias-free form were verified at the pin (`Justfile:275`,
alias count 0) and because a recipe named `pack-check` would promise R26's check.
Revision 4 tightens the version half of Opus's assertion from a substring to
ts's equality form per R60's published AC2; the recipe/job split and the
file-existence half stand.

**Disagreement 5 — whether the web surface is in scope.** Codex told P03 not to
add a web-service lifecycle check; Opus added AC6, a second `--features web` leg.
**Both are honoured, because they are about different things**: no web-service
*lifecycle* test is added (starting a server and probing it is R80's and R69's),
and the web leg asserts only what this item asserts about any binary — that it
installs and answers `--version`. Of the behaviour that leg depends on, two
parts were reproduced on fixtures: exactly one binary on the default install
(phase F3, `r50-check.log:145`), and zero-versus-one gating of a single
`required-features` binary (phase H, `r50-check.log:188-205`). The two-binary
composition — ungated `rslbp` plus a gated serve binary — was **not** built by
any fixture (each fixture script emits one `[[bin]]`: `evidence/r50-check.sh:220`,
`evidence/r50-r4-delta.sh:199`) and is deferred to P03 (`What P03 must validate`, item 5).

**`BASELINE-REVIEW: F222` disposition.** Carried forward and **endorsed**, with
every line citation re-verified at the ts pin by phase C of the check. Its
repair scope is four records, not the three the Opus raw (`raw/opus.md:105`,
"correct the three places") and revisions 1–5 named: revision 6 adds the F222 sub-row of `docs/port/DIVERGENCE-ANALYSIS.md`
(`:182`), whose ts and inferred cells record the same absence (see `## Decision`).
It is recorded for the ledger owner to apply; no ledger, area, index, prompt,
divergence-analysis or registry file was edited by this synthesis. Codex emitted
no `BASELINE-REVIEW:` finding and did not examine ts's `pack-check` beyond the
prompt's summary of it, so there is no engine disagreement to settle on this
point — only a gap that Opus filled and that this synthesis independently
confirmed.

**A second correction to the Opus raw — the library-surface ground.** The
withdrawn "thin CLI over the library crate … `[lib]` is compiled transitively"
ground, and its original flip condition "if `src/main.rs` ever stops depending on
the library crate", originated in the Opus raw (`raw/opus.md:264-270`);
revisions 1–4 carried them forward. Revision 5 replaced both with the observed
Cargo rule (`## Decision`, library-surface ground; `re-verify:` (7)). Codex was
silent on the library surface, so this is a correction, not an adjudicated
disagreement.

**Unproven, with what would prove it.**

| Claim | Status | What would prove it |
|---|---|---|
| The composition works on the real `rs-launch-blueprint` package | **unproven** — the template does not exist; fixtures are zero-dependency crates | P03 runs `just install-check` against the built template |
| Any cost figure, cold or warm | **unproven** — no timing was measured and none is invented; a zero-dependency fixture proves nothing about a real dependency tree | P03 records wall time, cache hit/miss, runner OS and Rust version for the first cold and warm runs |
| `ubuntu-latest` alone suffices | **partly proven** — the composition ran on macOS here, but the Linux leg the job actually uses was **not** run, and no macOS-specific packaging failure was searched for | the first CI runs, plus any observed macOS-only packaging failure (widen trigger) |
| The exact `--version` output | **settled in revision 4 by R60's publication** — R60 AC2 fixes one line `<tool> <semver>`, no leading `v` (`:1086`); AC4 now asserts equality, demonstrated on a fixture (new evidence script, phase M) | R22 resolving confirms the accessor reads the same manifest version |
| R69's serve binary's concrete name | **not this item's** — R69's own text carries the placeholder `<app>-serve`; this decision names only R49's `rslbp` | R69/P03 fix the literal |
| A well-regarded project installing from an extracted `.crate` | **none found** — GitHub code search for `"cargo install --path target/package"` returned `total_count: 7`, all documents or fixtures (retrieved 2026-09-17) | a future survey, or P03's own experience standing in for it |
| `--debug` installs a profile a consumer does not get, and **no release-profile compile happens at pull-request time** | **acknowledged trade, not a defect — with narrower coverage than revision 1 claimed.** The dev profile is also the stricter smoke profile (`debug-assertions`, `overflow-checks`). But `cargo publish --dry-run` does **not** exercise the release path: it runs the same packaging-and-verification build this run measured, and that build compiles with the **dev** profile — `r50-check.log:89-91`, `Verifying r50spike v0.4.2` → `Compiling …` → ``Finished `dev` profile [unoptimized + debuginfo] target(s)``. That leaves R68's release build as the only release-profile compile the template is currently expected to perform, and **R68 (`release-binary-artifacts`) is `open`** in `research/CLAUDE.md`, so no resolved item covers it today. Superseded wording, revision 1: *"the release path is exercised by R68's release build and R26's publish-time `cargo publish --dry-run`"* — the second half is refuted by this run's own log and the first half is unresolved | if a release-only failure is ever observed, the leg switches to the release profile and pays the compile; and R68 resolving is what fixes where the release-profile compile lives (`re-verify:` (13)) |
| The AC7 negative control in the real template | **proven on a fixture, unproven on the template** | P03 removes an `include` entry, confirms `install-check` fails, restores it |

**What P03 must validate.** (1) The recipe runs green against the real template on
both `ubuntu-latest` and a developer's macOS machine. (2) The AC7 negative control
fails, which is the only way to tell the recommendation from its runner-up by
looking at a green check. (3) The job is skipped on a documentation-only pull
request under R11's filter and red on a broken one. (4) First cold and warm
timings, which convert this decision's cost model into a measurement and which
decide whether the `--target-dir` cache and `--no-verify` levers are sufficient.
(5) The default-feature install produces exactly one binary, and the `--features
web` leg exactly two, once R69's serve target is named.
