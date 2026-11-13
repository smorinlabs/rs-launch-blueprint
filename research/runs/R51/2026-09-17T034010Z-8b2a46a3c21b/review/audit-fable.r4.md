actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 35620b8ed243da9dff00b7f236521093e71a59209f435b7fd2790b9e33d37cfe
verdict: reject
unresolved-findings:
- F1 (JF-1, JF-2, JF-3): member 4's selected mechanism, a static `busybox` applet copied into the distroless runtime, has no maintained reference implementation. The decision does not state that gap, and it words its member-1 gap as if member 1 were the only member without one.

# R51 container-image — judgment audit of revision 4

**Target.** `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md`,
revision 4. `shasum -a 256` printed
`35620b8ed243da9dff00b7f236521093e71a59209f435b7fd2790b9e33d37cfe`, which
equals the expected hash. I read the decision in full, and also
`inputs/prompt.md`, `inputs/prerequisites.json`, `manifest.json`,
`research/RUNBOOK.md` §2 and §5, both raw reports at the cited lines, and the
prerequisite and sibling decisions at the cited lines. I read no `audit-*.md`
file and no `R51-r*-snapshot.md` file. I ran no script and made no git write.

**Verdict: reject, on one finding.** The recommendation itself is sound and
well evidenced, and nothing in this audit moves it. The finding is a fidelity
repair of about three sentences. It is the same class of defect that
revision 4 repaired for member 1.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (F1) | Otherwise consistent. The member-5 gate, member 1's up-and-comer sentence, gate 6 in member 5's ledger, and P03 item 2 all restate the fail-closed gate the same way. The size arithmetic holds: 812,604 / 12,302,310 = 6.6 %; 36,869,229 / 12,302,310 = +199.7 %; 36,869,229 − 12,302,310 = 24,566,919. The reference-architecture tally is 4 + 5 + 2 + 1 = 12 rows, which I recounted row by row. The fixture's instruction lines equal the embedded block: `diff` after stripping comments and blank lines prints nothing. The inconsistency is at `:340`, where member 1 is worded as the only member without adopter corroboration (see F1) |
| JF-2 prompt questions and constraints | **fail** (F1) | All five questions are answered. HIGH 1 is answered in `### Principles and implementation` and members 1–3. HIGH 2 is answered in terms at `:360`–`:382`. MEDIUM 3 is answered in member 4. MEDIUM 4 is answered in member 3. LOW 5 is answered in member 5. Out-of-scope items are respected: R69's surface, R80's endpoint, and no prior art from the owner's repositories. Q7.B is applied to gate 1 as ruled. The failed constraint is `prompt.md:44`: "For every recommendation cite a maintained reference implementation, or state the evidence gap." Member 4 does neither for its selected mechanism (F1) |
| JF-3 `## Engines` fidelity and adjudication | **fail** (F1) | Both reports are listed with hashes that match the files (`c74cb6d1…`, `a60d1190…`, byte-identical to their hash-named copies). E1–E7 quote Muse at the cited lines, and I checked `:27`, `:150` ("chef ships no code into the template"), `:170`, `:174`, `:220`, `:232`, `:284`, `:291` and `:297`. The Opus corrections 1–5 hold: `raw/opus.md:51` and `:232` (uv mounts serve apt only) against `:1209`; the `-T 3` in the executed image at `:162` against `-T 2` in the prose at `:916`. The failure is that Opus's own recorded member-4 evidence gap, at `raw/opus.md:894`, is carried nowhere, and E4 re-labels Muse's `:220` gap instead of recording it (F1) |
| JF-4 load-bearing claims trace to sources | pass | Spot-checked lines, all holding: R11 revision 7 `:61`, `:165`, `:184`, `:197`–`:198`, `:202`, `:270` and `:297`; R69 revision 10 `:1608` and `:1791` ("path-based skip-gating keys on crates/web/**, the serve binary's source file and the web test files"); `R77-r3-snapshot.md` (sha256 `5985ee47…`, equal to ledger `:1082`) at `:678`, `:806`, `:827`–`:828`, `:840`, `:847`, `:863`–`:864` and `:931`; `R80-r3-snapshot.md` (sha256 `184d2b17…`, equal to `git show 53b13f45:` of R80's decision) at `:548`, with 0 lines naming R8.6, 32 lines naming `/healthz`, and 0 lines declaring `OVERRIDE (OV-04)`; `R68-r1-snapshot.md` (sha256 `070b7ae1…`, equal to ledger `:981`) at `:27`, `:32` and `:77`; R02 revision 2 at `:22`; ledger `:414`, `:1073`, `:1074`, `:1080`, `:1082`, `:1083`, `:1086` and `:1114`; `owner-decisions.md:488`. The manifest shows two `succeeded` operations, state `collected`, and the codex→muse migration event at 2026-09-21T23:06:19Z |
| JF-5 couplings hand over owned choices without deciding them | pass | Four couplings are handed over without being decided. R77's `OV-04` and in-process TLS stay R77's. R80's route and the R8.6 row stay R80's. R12's required-status choice is stated as a condition on R51's own gate form, not decided. R19's `docker` ecosystem is R19's published condition being met. The member-5 gate consumes R11's skip-list as its single source rather than re-deciding it. The R68 hand-off names two doors and opens neither. The illustrative `CONFLICT:` text at `:697` is explicitly not raised |
| JF-6 `assumes` lines byte-identical to the live registry | pass | A script diff of all five `- assumes` values against the working-tree `docs/port/PARAMETERS.md` found every one identical: `web-extra-surface` from R69, and the four `fixed` rows. No registry row names R51 as owner. The registry has one uncommitted change, and it touches only R11's `ci-job-structure` row, which R51 does not consume |
| JF-7 no conflict with accepted or published prerequisite values | pass | `prerequisites.json` pins R69 at `d4507f5b…`, which equals the published `research/topics/69-…/DECISION.md` (revision 9). Revision 10 (`d34ab6e8…`) is owner-accepted (re-bound at ledger `:988`) and unpublished. The design uses revision 10's paths, and the `assumes` line keeps revision 9's bytes, as the prompt requires. The image command `cargo build --release --locked --features web --bin rslbp-serve` is valid under both revisions. The fail-closed gate contains every skip-gating key of both revisions. R69's "nothing beyond it" clause is honoured, because option C is not taken |
| JF-8 evidence scripts exist and counts match | pass | The four scripts, `Dockerfile.candidate` and `dockerignore.candidate` all exist. The `SUMMARY` lines match the decision: `r51-container.log` 54/0/0; `r51-registries.log` 32/0/0; `r51-sources.log` 162/0/0 (162 verdict lines, 0 `FAIL`); `r51-sources.r3.log` 147; `r51-sources.r1.log` 101/5; `r51-sources.r2.log` 132; `r3-nodocker` 14/0/14; `r3-nonetwork` 10/0/22; `r2-inspect-size` 52/2. `reproduction.log` ends `reproduction-exit: 0`, and `shellcheck.log` ends `shellcheck-exit: 0`. Spot-checked the container verdicts `C3a` (65532), `C4b` (0), `C5b` (50), `C6a` (143), `C9a`, `C9b`, `C11a`, `C11b`, `C12a` and `C13a`–`C13c` (exit 1), and the source verdicts `S18a`–`S18m`, `S10a`–`S10d`, `S10g`, `S10j`, `S10x`, `S12c`, `S4c`/`S4d`, `S2c` and `S3b`/`S3g`. All match the prose |
| JF-9 decision shape follows the published contract | pass | The file has exactly the four H2s required by RUNBOOK §5, in order: `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`. It has no `## Supersedes`, which is correct because the recommendation is not reversed. `## Decision` carries the settled rows (F223, F336, F337), `### Principles and implementation`, and one `re-verify:` line. `S3g` checks the H2 list against published R11 |
| JF-10 recommendation follows from the evidence | pass | Each member follows. Member 1 follows from the strict gate-2 ruling plus the executed 0-against-50 counts. Member 3 follows from the measured size and surface, with the capability shown equal. Member 4 follows from the executed healthy path and failure path. Member 5 follows from py's actual behavior (`S15i`/`S15j`) plus R11 `:270` and R11's fail-closed rule. F1 does not move any selection |

## Unresolved finding

### F1 — member 4's missing reference implementation is neither cited nor stated as a gap (JF-1, JF-2, JF-3)

**The failed claims, quoted.**

- `DECISION.md:338`–`:342`: "Neither adopter composes all five selections … **For
  member 1 there is no adopter corroboration at all**: neither engine cites a
  surveyed project that applies BuildKit cache mounts to the Cargo registry or
  `target/` (member 1 states the gap)."
- `DECISION.md:1482` (E4): "Muse's gap was a survey gap; this run's fixture is the
  implementation."
- `DECISION.md:1598`: "**Member 1's selection has no maintained reference
  implementation** …". This paragraph is the decision's whole list of
  evidence gaps, and it names no member-4 gap.

**Evidence.**

1. The prompt requires "For every recommendation cite a maintained
   reference implementation, or state the evidence gap" (`inputs/prompt.md:44`).
2. Member 4's recommendation is a mechanism: `COPY --from=probe /bin/busybox`
   into `cc-debian13:nonroot`, plus an exec-form `busybox wget` `HEALTHCHECK`.
   Neither engine cites a surveyed project that uses this mechanism.
   - Muse says so in terms at `raw/muse.md:220`: pairing distroless with a probe
     has "no surveyed reference or maintained implementation … (evidence gap, not
     a recommendation)".
   - Opus names no such adopter. Its own member-4 section records a further
     gap at `raw/opus.md:894`: "this run did not survey whether a
     distroless-compatible single-purpose HTTP probe image has emerged that is
     smaller than busybox."
3. The decision's one member-4 reference is `atuinsh/atuin` (`:324`–`:327`).
   Atuin's probe is a shell-form `curl` on `debian-slim`, which is option B
   in member 4's own table (`:680`, "atuin's and py's shape"). Atuin therefore
   corroborates the *principle*, an in-image `HEALTHCHECK` on `/healthz`. It
   does not corroborate the *mechanism*.
4. The decision draws exactly this distinction for uv and member 1 at
   `:332`–`:338`: uv "corroborates members 2 and 3's pinning and
   minimal-runtime principles, **not** member 1's mechanism".
5. Revision 4 accepted that "the committed fixture … is the only
   implementation" must be stated as a gap for member 1 (`:467`–`:482`).
   Applying the same test to member 4 gives the same result.

**Why it fails three checks.**

- **JF-2.** The `prompt.md:44` constraint is unmet for member 4.
- **JF-1.** The words "for member 1 … at all" and the member-1-only gap
  paragraph tell a reader that the other four members have reference
  corroboration. Member 4 does not.
- **JF-3.** E4 turns Muse's recorded gap into a rebuttal ("a survey gap; this
  run's fixture is the implementation") instead of recording it. Opus's
  `:894` gap is dropped entirely.

**Repair.** The recommendation does not change.

1. In member 4, after the options table or in the busybox-cost paragraph at
   `:713`, add one paragraph. It should say that neither engine cites a
   surveyed project that copies a static `busybox` applet into a distroless
   runtime for `HEALTHCHECK`. It should say that `atuinsh/atuin` corroborates
   the in-image `/healthz` probe only, with `curl` on `debian-slim`, which is
   option B. It should say that the committed `Dockerfile.candidate` is the
   only implementation, and that the selection rests on the Dockerfile
   reference's exit-code contract and the executed `C3c`–`C3f` and
   `C13a`–`C13c`, not on adoption. Cite `raw/muse.md:220` and
   `raw/opus.md:894`.
2. Rewrite `:340` so it does not imply that member 1 is unique. For example:
   "For members 1 and 4 there is no adopter corroboration of the selected
   mechanism."
3. In E4, record Muse's `:220` gap as agreed and still open, rather than
   dissolved by the fixture.
4. In the `## Engines` evidence-gaps paragraph (`:1598`), add member 4's
   missing reference implementation and Opus's `:894` unsurveyed
   probe-image category.
5. Optionally, add a `r51-sources.sh` check that asserts the member-4 gap
   sentence and the two raw lines, in the style of `S18i`–`S18m`.

## Non-blocking observations (not findings)

- **Licence asymmetry.** Member 1 records `cargo-chef`'s declared licence as a
  fact. Member 4 records no licence for `busybox`, which is GPL-2.0 and, unlike
  cargo-chef, ships inside the image. This is not a gate defect: Q7.B strikes
  gate 1 entirely and knowingly, including for shipped content (ledger `:505`).
  A one-clause fact line would still help a fork that later publishes the image.
- **Stale comment.** The comment in the `## Empirical check` code block at
  `:1251` reads "revision 2's runs, carried unchanged into revision 3", while
  `:1192` says "revisions 3 and 4".
- **Unused macOS evidence.** Every container check actually ran on a macOS
  (`Darwin 25.4.0 arm64`) Docker host. Saying so would strengthen the gate-4
  and `target-os-matrix` discussion: the recipe builds on a `macos-latest`-class
  developer host, even though CI builds it on `ubuntu-latest` only.
- **Literal `CONFLICT:` text.** Line `:697` carries a literal
  `` `CONFLICT: R69 web-extra-surface — …` `` inside a code span, beside
  `:1113` "`CONFLICT:` lines: none". No script under `scripts/` parses
  `CONFLICT`, and the Opus raw report carries the same literal at `:879` and
  validated clean, so this is harmless today. If a future parser matches
  `CONFLICT:` without anchoring it to the start of a line, it would misread
  this line.
