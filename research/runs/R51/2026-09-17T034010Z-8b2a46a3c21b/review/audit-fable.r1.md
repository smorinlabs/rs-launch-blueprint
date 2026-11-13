actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 6a99c4116fd38fb8a3d57eb46e04681c0d48a1aea89851f716dc257bf9340f54
verdict: reject
unresolved-findings:
  1. JF-1/JF-2 — gate 4 (and the per-candidate gate ledger) is claimed for every member but recorded for one
  2. JF-2/JF-3 — HIGH question 2's named alternative, the manifests-first `COPY`-order trick, is never answered

# R51 container-image — judgment audit of DECISION.md revision 2

Auditor: fresh Claude context (seat `fable`, model `claude-opus-5-5`, family
anthropic), independent of the synthesizer. Audit date 2026-09-26. Scope:
reasoning and fidelity only; the empirical audit reruns the scripts.

Target: `research/runs/R51/2026-09-17T034010Z-8b2a46a3c21b/review/DECISION.md`,
revision 2, 1,333 lines. `shasum -a 256` returned
`6a99c4116fd38fb8a3d57eb46e04681c0d48a1aea89851f716dc257bf9340f54`, which
matches the expected hash.

Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §2 and §5;
`raw/opus.md` (sha256 `c74cb6d1…`) and `raw/muse.md` (sha256 `a60d1190…`), both
matching `manifest.json`; the published prerequisite
`research/topics/69-web-framework-stack/DECISION.md` (sha256 `d4507f5b…`) and
its `acceptance.json` (sha256 `48a7dce8…`), both matching
`inputs/prerequisites.json`; and the cited lines of R69 revision 10, R77
revision 3, R80 revision 3, R68 revision 1, published R11 revision 7, published
R19, the execution ledger, `owner-decisions.md` and `docs/port/PARAMETERS.md`.
No `review/audit-*.md` file and no `review/R51-r1-snapshot.md` was opened.

## Verdict in one paragraph

The recommendation is well-founded and follows from the evidence: BuildKit cache
mounts, a digest-pinned `rust:1.98.1-slim-trixie` builder, a
`cc-debian13:nonroot` runtime, a busybox exec-form `HEALTHCHECK`, and a CI-built,
unpublished recipe. The citations I spot-checked hold, and the parameter lines
are byte-identical to the registry. The revision fails on two fidelity points,
and both are cheap to repair. First, the decision states that every member
records gate 4 as `inapplicable` for `macos-latest`, but only member 1 carries a
gate ledger, and it says something different. Second, the prompt's HIGH
question 2 names the manifests-first `COPY`-order trick as the alternative to
weigh, and the decision never mentions it, although both engines do. Neither
repair should move the recommendation.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | Finding 1: lines 895–897 contradict lines 309–311 and 532–534. Minor inconsistencies are listed under the non-blocking observations below |
| JF-2 every question answered, every constraint honored | **fail** | Finding 2: HIGH question 2 is half-answered. Finding 1: the prompt's "state `inapplicable` and the reason … do not omit it silently" rule is not met for members 2, 3 and 5. All other questions are answered: HIGH Q1 (members 1–3), MEDIUM Q3 (member 4), MEDIUM Q4 (member 3, `USER nonroot:nonroot`), LOW Q5 (member 5) |
| JF-3 `## Engines` faithful and adjudicated | **fail (partial)** | E1–E7 are faithful. I checked each cited Muse line: `:17`, `:27`, `:31`, `:66`, `:150` (gate 2 reads "chef ships no code into the template"), `:170`, `:174`, `:220`, `:232`, `:284`, `:291`, `:295`, `:297`. The Opus corrections are faithful: `-T 3` executed at `raw/opus.md:162`/`:924`, `-T 2` in prose at `:921`; "Low-confidence and explicitly unproven" at `:975`; 35,680,357 B at `:651`/`:680`; 50.8 % at `:262`; the tally at `:1234`. One gap: both engines treat the `COPY`-order trick and agree that it is superseded by cargo-chef (Opus `:26`, `:222`, `:304`; Muse `:27`). "Where the two reports agree" omits that agreement (Finding 2) |
| JF-4 load-bearing claims trace to a source | pass | R77 revision 3 (sha256 `5985ee47…`): `:678` gives `127.0.0.1`, `8000`; `:806` is `OV-04`; `:827`–`:828`, `:847` and `:863`–`:864` read as quoted; `:931` gives `RSLBP_WEB_HOST=0.0.0.0` to R51. R11 `:165`, `:270` and `:297` read as quoted. Ledger `:414` is the strict gate-2 ruling, `:1073`/`:1074` allocate `OV-14` to R51, and `:1082`, `:1083`, `:1086` and `:1114` read as cited. `owner-decisions.md:488` is W1-CODEX3. R68 `:69` makes the GNU/Linux triple the single Linux triple; `:74` is the "delivery vehicle" premise; `:94`–`:95` is the profile; `:119` puts `mold` out of scope. R19 `:66` is F053's conditional on R51. R80 `:548` is the "no health … rule" sentence |
| JF-5 couplings hand off rather than decide | pass | R12 (required status) is stated as a requirement on R12's answer. R68 (downloadable web artifact) is a two-door hand-off with no `CONFLICT:`. R19's `docker` entry follows R19's own published condition. `OV-14` is scoped to three lines of R51's artifact and leaves `OV-04` and in-process TLS to R77 and R69. The `/healthz` path and the port are read from R80 and R77, and their movement is a re-verify trigger |
| JF-6 assumes lines byte-identical to the live registry | pass | I parsed `docs/port/PARAMETERS.md` and compared each of the five `- assumes` values. All five are equal, with lengths 2638, 118, 4, 27 and 17 characters |
| JF-7 no conflict with accepted or published prerequisite values | pass, with a note | `inputs/prerequisites.json` pins R69 at the published hashes, which match. The design's `crates/web` paths come from R69 revision 10, which is owner-accepted but unpublished (ledger `:988`, W0-R69c re-bound acceptance to revision 10). They do not come from the registry's revision-9 `src/web/**` key. The decision discloses this at lines 874–891, keeps the registry bytes in its `assumes` line, and makes republication a re-verify trigger (`S10d`). R77 and R80 are `open` and are cited as proposals |
| JF-8 evidence scripts exist; counts match | pass | All four scripts and all cited logs exist. `r51-container.log` reports `PASS=54 FAIL=0 SKIP=0 TOTAL=54`. `r51-registries.log` reports 32/0/0. `r51-sources.log` reports 132/0/0. `r51-sources.r1.log` reports 101/5, and `r51-container.r2-inspect-size.log` reports 52/2, as disclosed. `reproduction.log` ends `reproduction-exit: 0`, and `shellcheck.log` shows `shellcheck-exit: 0`. The measured lines match the prose: 12,302,310 B, 11,489,706 B, 812,604 B, 36,869,229 B, uid 65532, exit 143, `C4b` 0, `C5b` 50, `C13c` exit 1, `GLIBC_2.34`/2.41. Derived figures also hold: 812,604 / 12,302,310 = 6.6 %, and 36,869,229 / 12,302,310 is +199.7 % |
| JF-9 decision shape follows the contract | pass | There are exactly four H2s in RUNBOOK §5 order and no `## Supersedes`. `## Decision` carries the recommendation, pins, settled F223/F336/F337, `### Principles and implementation`, and one `re-verify:` line with 2027-03-18 as its closing date |
| JF-10 recommendation follows from the evidence | pass | Each member's selection is carried by an executed check or an owner ruling. Cache mounts are chosen on `C4b`/`C5b` and gate 2 under ledger `:414`. Distroless is chosen on `C9b`, `C8-*` and `C14a`. The busybox probe is chosen on `C3c` and `C13a`–`C13c`. No publication is chosen on `S15i`/`S15j` and the fit argument. The two findings do not undermine any selection |

## Unresolved findings

### 1. The gate-4 inapplicability is claimed for every member but recorded for one, and members 2, 3 and 5 carry no per-gate answers

**Failed claim** (lines 895–897): "`macos-latest` is recorded as
**`inapplicable` for the image artifact** in every member's gate 4 rather than
as a gap."

**Evidence.** A search for `gate 4`, `gate 3`, `gate 5`, `gate 6` and
`inapplicable` across the decision finds the following:

| Member | Line | What it records |
|---|---|---|
| 1 | 309–311 | "gate 4 **pass in substance**", which is not `inapplicable` |
| 2 | 392 | only the blanket statement "**No candidate in this member fails a gate**"; no gate is named |
| 3 | 406–408 | crate figures and RustSec are marked `inapplicable`; there is no statement for gates 2, 4, 5 or 6 |
| 4 | 532–534 | "gate 4 resolves as members 2 and 3 do", but members 2 and 3 state nothing about gate 4 |
| 5 | — | no gate statement at all |

The prompt requires the fitness gates to be "answered per candidate **before**
popularity is weighed". It also says: "If a metric is inapplicable to this item
kind, state `inapplicable` and the reason in the answer; do not omit it
silently." The self-description at 895–897 is false, and it hides the omission
it describes.

**Repair.** Choose one of the following. Either change any selection.

- Add a one-line gate ledger to members 2, 3 and 5, in the form member 1 uses at
  lines 303–313, covering the selected candidate and the runners-up. Rewrite
  member 1's gate 4 as `inapplicable` for `macos-latest` if that is the intended
  reading.
- Or rewrite lines 895–897 so that they describe exactly what each member
  records.

### 2. HIGH question 2's `COPY`-order alternative is never answered, and both engines' agreement on it is dropped

**Failed claim.** The prompt's HIGH question 2 asks: "Is `cargo-chef` … still
actively maintained and the dominant approach for this pattern, or has a
simpler multi-stage `COPY`-order trick superseded it?" The decision answers the
maintenance half at lines 284–301. It answers "dominant" by adoption at line 247.
It never names the manifests-first `COPY` with stub sources. The only related
word is "skeleton" at line 204, and there it describes cargo-chef.

**Evidence.** Both engines evaluated the trick and agree on it:

- Opus at `raw/opus.md:26`, `:222` and `:304`: "Nobody in the survey
  hand-rolls it; it is what cargo-chef automates. Correctness in a four-package
  workspace requires a stub `lib.rs`/`main.rs` per me[mber]…"
- Muse at `raw/muse.md:27`: "The pre-chef dummy-`COPY Cargo.toml` + stub
  `main.rs` trick is superseded by chef (same effect, manual skeleton, no
  workspace handling)."

Member 1's comparison has three entries: cargo-chef, cache mounts, and no
caching. "Where the two reports agree" (lines 1115–1124) omits this point.

**Repair.**

- Add one or two sentences to member 1 that name the manifests-first `COPY` and
  stub-source trick as a candidate. Give its verdict with both engines'
  citations: superseded by cargo-chef, and brittle in R02's four-package
  workspace because it needs one stub per member.
- Say how it compares with the selected cache mounts.
- Add the agreement to the `## Engines` agreement paragraph.

## Non-blocking observations (not findings; no verdict rests on them)

- **Operation states** (line 1111). The line says "the manifest now holds two
  operations in state `collected`". `manifest.json` shows both operations in
  state `succeeded`, and only the run's own state is `collected`. `S14d` and
  `S14e` log exactly that. The table at lines 1100–1101 is correct.
- **Binary name** (line 55). The line says R69's revision 10 "declares … the
  `rslbp-serve` binary". R69 revision 10 line 1791 says `<app>-serve`, so
  `rslbp-serve` is this template's instantiation. Say so.
- **Embedded `Dockerfile`** (lines 67–98). The embedded block is
  `Dockerfile.candidate` with its comment lines removed. Every instruction line
  is identical: `diff` shows only additions of `#` comment lines and blank lines
  in the fixture. The text says the checks ran against the file "not against a
  transcription of it", which holds. Label the block as a comment-stripped
  rendering.
- **`.dockerignore`**. `dockerignore.candidate` holds exactly `.git`, `target`
  and `**/target`, as line 128 states.
- **Wording at line 647**. The line says "where the same pattern finds 139
  numbered rules". It means the same rule-number pattern without the keyword
  filter. As written, it reads as a contradiction.
- **Ledger inconsistency outside R51**. Ledger `:1114` gives OV-10 and OV-11 to
  R72 and R84 as "free", although `:1074` records both as held. This does not
  touch `OV-14`, which both lines leave with R51. The controller should
  reconcile it.
