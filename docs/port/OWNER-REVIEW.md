# Owner review — research items (spec §6.5)

Every index item has a disposition, with the effects spec §6.5 defines: `accept` = no effect on the tree; `narrow` = the prompt's `## Out of scope` and `## Questions` are edited to the owner's rationale, ledger row unchanged; `force <tool>` = the prompt is rewritten as a fitness check of the named tool, `## Objective` states the choice is forced; `drop` = index status `dropped`, every ledger row that pointed at the item re-verdicted to a non-research verdict with Item `—`, prompt kept as history.

Collected 2026-09-04 through a codesign page (`html-codesign` skill; the page and the export are kept outside the repo). Each of the 84 sections (R36 was vacated at the Task 10 reconciliation; ids are never reused) offered five choices that map onto the four dispositions: `a` accept, Rust alone; `b` accept plus one cross-repo question appended to the prompt; `c` narrow; `d` force; `e` drop. Every section pre-selected the recommendation argued from `DIVERGENCE-ANALYSIS.md`; the owner confirmed 69 and overrode 15. Result: 84 × `accept` (60 × b, 24 × a); no narrow, force or drop, so no index or ledger row changed. Sub-choice `b` appends one cross-repo question to the prompt's `## Questions` and every owner note lands in `## Context`; that is the owner's extension of §6.5 decided on 2026-09-02 (harmonize items stay `accept` and gain one question), recorded here because the checker sees only `accept`.

## Owner direction (2026-09-04, verbatim)

> Pardon the comparison between the repos. PyLaunch Blueprint has a more mature repo and examples, and all three should have the three different types of examples: CLI and web app. They are separate and sample examples, but they're supposed to have best practices in them.
>
> PyLaunch Blueprint is a much more mature example codebase. Where Python and TypeScript differ, whether it's more mature or just arbitrarily different, they should be made the same. Where PyLaunch Blueprint and the Python project are more mature, we should not, obviously, use the same libraries and the same architecture and code patterns, but take the principles.
>
> If the principles have multiple layers of configuration, we should use that. If it supports OTel, we should find the best libraries for OTel and do the same. For each one of these principles, we should look at the portion that's most mature and apply it to the next one.

## Later owner clarification (2026-09-04, verbatim excerpts)

> As we research each point and where there's drift, we want to take the best architectural principles and patterns, not the specific implementation, and apply the best patterns and practices that keep those principles.

> The principles should be there. For example, the best principle for OTel is that we're using OTel and all of them use it, but we use the best library and implementation pattern for each one.

> There is a push for agreement, but the agreement needs to be careful about what level is involved. For example, multi-level config may include custom implementations with user- and project-level configs, etc., or global configs. That's the principle.

> We need to make sure we've captured the principle and applied it correctly, and not mistaken something too low-level for it. In some cases, it may be an architectural pattern, and then we need to see if that pattern is still correct in that other language.

Current binding interpretation for P02 (spec §2, amendment A5). This replaces the earlier interpretation that every difference must yield one value:

- Agreement at an explicit level. Capture the shared capability, standard, architectural pattern or policy and its source before choosing a library or mechanism. OpenTelemetry use is a shared requirement, not merely a suggestion to provide generic observability. Layered configuration requires the intended scopes and precedence, not a copy of a source library's API.
- Preserve principles through native designs. Existing implementations and their research supply lessons and evidence; maturity alone does not make one repo authoritative. Research significant alternatives and the best-supported implementation pattern in each ecosystem. If the architectural pattern itself is shared, test whether it remains appropriate in the other language.
- Classify differences by level. Distinguish missing capability, violation of the shared principle, accidental drift and justified ecosystem adaptation. Converge where the shared contract requires it; permit different libraries and mechanisms when they preserve that contract. Changes to py and ts remain a follow-on project. The 60 `b` questions now request this analysis instead of one value for every difference.
- Require evidence of application. Each answer maps the shared principle and agreement level to the recommended architecture, libraries, reference examples and observable acceptance checks. A crate name, popularity ranking or structurally valid answer alone is insufficient.
- All three repos ship all three example shapes (CLI, library, web service). This answers the cross-repo scope question parked on R69 (`web-extra-surface`): the ts repo should also ship the web tier.
- Follow-on work in the ts repo, recorded here and not research items of this program: tRPC as the ts web equivalent (R69 note); template-press for ts (R15 note); a Bandit-class security analyzer for ts if one exists (R31 note).
- Six items chosen `a` carry cross-repo notes (R22, R31, R42, R58, R71, R73). The note binds through the prompt's `## Context`; no cross-repo question was added, honoring the pick.
- Every owner note is reproduced verbatim in its prompt's `## Context` as the last bullet and in the rationale column below.
- Survey method, forest before trees (2026-09-04): every prompt's `## Required evidence` opens with four steps — landscape in three bins (built-in or first-party · industry standard · up-and-comer), authority established not assumed, practice evidence from well-regarded projects, fit over abstract best — and every answer opens with a `Landscape` field (spec §13 A1).
- Multi-engine research (2026-09-04): every item runs on Claude Opus, Codex and Doxa deep research in parallel, each as its own subagent; a non-producer synthesizes the decision; at most 4 Claude subagents at once, out-of-process engines uncounted (spec §13 A2, `research/RUNBOOK.md` §2).
- Dependency waves (2026-09-04): keystone decisions such as the web framework (R69) are researched before the items that hang off them, independent items run in parallel (spec §13 A3, `research/RUNBOOK.md` §1).

## Later owner rulings that bind every item (recorded after the 2026-09-04 codesign)

The dispositions table below records one 2026-09-04 codesign choice per item. The
rulings in this section came later, bind items regardless of their disposition,
and are recorded here because `docs/port/` is the port's durable record; the
reasoning and blast radius for each is in `docs/planning/p02/owner-decisions.md`
and `docs/planning/p02/execution-ledger.md`.

### 2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)

Owner ruling, verbatim:

> Here, we don't need to check the licensing for any tool we use. Zero license
> check. That accounts for other tools and libraries we're including. The license
> we have only applies to the source code in the repo itself directly, not
> anything it includes or depends on.

Q7.B extended this knowingly to crates compiled into the shipped artifact, after
the owner was shown that a linked crate's terms travel into every downstream
binary. **Fitness gate 1 ("license compatible with `MIT OR Apache-2.0`") is
struck from every item's evaluation.** It appears in 85 of the 86 binding
prompts; this is an owner *interpretation* of that gate, not a prompt edit,
because editing the prompts would invalidate the prompt hashes that published
acceptance records cite. Decisions record gate 1 as `inapplicable` with the
ruling named, rather than deleting the row.

What the ruling does **not** touch: the repository's own declared
`license = MIT OR Apache-2.0` and its per-file licence headers (R46); any rule
against committing third-party copyleft files *into* this repository; a tool's
usage terms restricting where it may lawfully run (R16), which is a functional
availability constraint rather than a compatibility check; and an
attribution notice owed on shipped content (R81), which is a distribution duty.

### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused

The owner confirmed that `/Users/stevemorin/c/cli-standards/cli-design-standard.md`
(version 1.4.14, blob `f9de0437`) governs this template. Its own header states
"Applies to: All new CLIs, any language", and R67 is published relying on its
rule R6.1 for the entire exit-code taxonomy.

**Override OV-01 is REFUSED.** It was requested on 2026-09-12 as a waiver of
R4.6 `(SHOULD)`, which says `--version`/`-V` should print a single line
`acme <semver>`. R60 had recommended printing a target-triple line and a rustc
line on every build. The owner instead selected R60's own conformant option (b):
both spellings print the single line, and extended build data moves behind a
JSON output flag, which R4.6 explicitly permits.

**Consequence for conformance: the template waives no `SHOULD`.** The standard's
conformance clause (`:50`) requires a waiver to name the rule ID, describe the
deviation, explain the rationale, and record the owner and date. No waiver record
exists because none is owed. R60 carries zero overrides; OV-01 is retired as
refused rather than deleted, its argument and options table kept as the record of
how the choice was reached.

### 2026-09-15 — R42 install-integrity posture: record signedness per tool (W0-R42i)

R42 revision 10 recorded three integrity postures for the `cargo binstall`
recipe "rather than chosen" and asked the owner to choose. The owner chose the
decision's **option 3**: the recipe body stays `cargo binstall --locked
--no-confirm <name>@<version>` with no extra flag, and P03 adds a signed/unsigned
column to the declared tool table so a tool whose author publishes no signing
key is a deliberate entry rather than an invisible one. Options 1 (recipe as
written, no column) and 2 (`--only-signed`) were declined. The choice rests on
two unmeasured facts the decision records as unproven — the signed fraction of
the real tool table and the time cost of a source build — and is to be
re-put if P03's measurement shows a signed fraction high enough to make
`--only-signed` nearly free. R42's republication revision cites this ruling.

### 2026-09-15 — R49 binary name: `rslbp` (W0-R49n)

R49 revision 7 kept the template's command name equal to its crate name,
`rs-launch-blueprint`, and marked the choice owner-reviewable. The owner chose
a short command name: **`rslbp`** (the Opus engine's proposal). The crate and
distribution name stay `rs-launch-blueprint`; `cargo install rs-launch-blueprint`
installs the command `rslbp`. Consequences the decision itself recorded for a
divergent pair: the `[[bin]] name` row changes; R32 resolves the built binary
through `env!("CARGO_BIN_EXE_rslbp")`; R68 uploads `target/release/rslbp`; and if
R68 later adopts `cargo-binstall` metadata, the `bin-dir` template must
interpolate `{ bin }` rather than `{ name }`. Five of the nine cross-platform
CLIs R49 surveyed use a shorter command than their crate name. R49 revision 8
implements this ruling.

### 2026-09-15 — R17 secret scanner: TruffleHog CLI, pinned binary (W0-R17b)

The owner directed that the template use the secret scanner the sibling
projects use. Validated at the programme pins: py (`b08bccfb`) runs TruffleHog
in CI (`.github/workflows/secret-scan.yml`, `trufflesecurity/trufflehog@v3.95.9`
on `ubuntu-latest`, `--only-verified`); ts (`cb1cbcb2`) has no secret-scan CI.
R17 revision 6 recommended the Kingfisher CLI with the TruffleHog CLI as its
ranked runner-up. The owner chose the **TruffleHog OSS CLI, `>= 3.97.0, < 4.0.0`,
installed as a pinned release binary in a `run:` step with `--only-verified
--fail`** — the runner-up's form, which runs on both owner-fixed runners — over
py's Action form, which is `docker`-based, `ubuntu-latest`-only and carries the
`BASE and HEAD commits are the same` first-push failure. Part 1 of R17 (one job
on `pull_request` and `push` to `main` that fails on a live credential) stands;
Kingfisher becomes the runner-up. R17 revision 7 implements this ruling.

### 2026-09-16 — Release build profile ownership: R68 (W0-R69p)

R69's revision 9 found, by a census over all 85 binding prompts and the
commonality ledger, that no research item names the Cargo release build
profile (`[profile.release]`: `lto`, `codegen-units`, `opt-level`, `strip`).
The owner rules that **R68 `release-binary-artifacts` owns it**: R68's prompt
is amended before the item is prepared to admit `[profile.*]` keys, evaluated
against binary size, build time and the fixed target matrix and MSRV policy.
R49 `build-target-declaration` keeps the manifest's target declarations and is
not reopened. The owner's reference architecture's `[profile.release]` row
(`lto = "thin"`, `codegen-units = 1`) is an input to R68 under section 11 of
`docs/planning/p02/owner-decisions.md`, not a pre-decision. Options declined:
adding the subject to R49 (reopens an accepted, published decision), a new
item (an extra research cycle), leaving Cargo's defaults to P03.

### 2026-09-17 — R69 `web-extra-surface` revised to name the optional web member (W1-R02)

R02 `crate-boundary-enforcement` (accepted at revision 1, judgment-only under
W1-CODEX) recommends a four-package Cargo workspace — the root facade
`rs-launch-blueprint` carrying the `rslbp` and `rslbp-serve` binaries and the
composition root, `crates/core`, `crates/cli`, and `crates/web` as an optional
dependency of the facade (`OVERRIDE (OV-03)` against F021) — and raised a
`CONFLICT:` against R69's owner-accepted value `web-extra-surface`, whose
feature body assumes `axum` and `tokio` are dependencies of the declaring
package. The owner rules for R02's option 1: **R69 is revised** so that the
feature reads `web = ["dep:rs-launch-blueprint-web"]` with `axum` 0.8.9 and
`tokio` 1.53.1 declared inside `crates/web`, the gated tree reads
`crates/web/src/`, the web integration tests live in `crates/web/tests/` with
no file-level `#![cfg(feature = "web")]`, and the skip-gating paths read
`crates/web/**`; every other clause of R69's value is unchanged, and R02's
topology stands. Options declined: keeping R69 byte-for-byte and dropping
`crates/web` (R02's check `H` built that shape and observed `src/web/` naming
the CLI crate with no error, so the web-to-cli boundary would fall back to
convention or a `cargo-deny` row), and folding both front ends into the facade.
The seven prepared Wave 2 runs that pin R69 (R51, R70, R76, R77, R79, R80, R83)
are re-prepared after R69 republishes.

### 2026-09-17 — R67's byte-empty-stdout clause read as before-result failures only (W1-R62)

R62 `clipboard-integration` (accepted at revision 2, judgment-only under
W1-CODEX) makes a failed `--copy` a post-result partial failure: stdout carries
the result byte-identical to the same command without `--copy`, stderr carries
the single `RSLB101` envelope, and the exit code is 1. R67's accepted text says
a machine-mode error "leaves stdout byte-empty" (AC2) and that "stdout stays
byte-empty on the error path". The owner ratifies R62's reading: the clause
covers failures before a result exists, not a failure after the result has
already been written. R67's registered text does not change now; it carries
R62's written-out substitute wording at R67's next revision, and R62 records
the open end as a re-verify trigger. Option declined: revising R67 immediately
(a carried-forward run and both audits for an editorial change).

## Wave 0 owner acceptances

Recorded from 2026-09-14 in `docs/port/OWNER-ACCEPTANCES.md` (moved there on
2026-09-16 so that this file keeps the single disposition table the tree
checker validates). Each acceptance binds a `DECISION.md` sha256; the re-bind
and stale rules are stated at the top of that file.

## Dispositions

| item | disposition | rationale | date |
|---|---|---|---|
| R01 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R01 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R02 | accept | Codesign `b`, confirms the recommendation. Class C (language-bound mechanic), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R02 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R03 | accept | Codesign `b`, owner override of the recommended `ch-03-a` (accept, Rust alone). Class F (genuine design disagreement), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R03 rows). Owner: This is a hex pattern that we've used before in the other repo. It would make sense to have a similar best practice pattern across all three. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R04 | accept | Codesign `a`, confirms the recommendation. Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R04 rows). Effect: none; runs as written. | 2026-09-04 |
| R05 | accept | Codesign `a`, confirms the recommendation. Class F (genuine design disagreement), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R05 rows). Effect: none; runs as written. | 2026-09-04 |
| R06 | accept | Codesign `a`, confirms the recommendation. Class G (Rust-only), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R06 rows). Effect: none; runs as written. | 2026-09-04 |
| R07 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R07 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R08 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R08 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R09 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R09 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R10 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R10 rows). Effect: none; runs as written. | 2026-09-04 |
| R11 | accept | Codesign `b`, owner override of the recommended `ch-11-a` (accept, Rust alone). Class E (one-sided, language-specific), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R11 rows). Effect: cross-repo question appended to the prompt, answered in full. | 2026-09-04 |
| R12 | accept | Codesign `b`, owner override of the recommended `ch-12-a` (accept, Rust alone). Class E (one-sided, language-specific), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R12 rows). Effect: cross-repo question appended to the prompt, answered in full. | 2026-09-04 |
| R13 | accept | Codesign `b`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R13 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R14 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R14 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R15 | accept | Codesign `b`, owner override of the recommended `ch-15-a` (accept, Rust alone). Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R15 rows). Owner: You should be using template-press just the way PyLaunch Blueprint does, and the same thing for TypeScript. We should all be using the same mechanism. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R16 | accept | Codesign `b`, owner override of the recommended `ch-16-a` (accept, Rust alone). Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R16 rows). Effect: cross-repo question appended to the prompt, answered in full. | 2026-09-04 |
| R17 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R17 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R18 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R18 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R19 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R19 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R20 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R20 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R21 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R21 rows). Owner: For this one, we should model it on what PyLaunch Blueprint does. Effect: cross-repo question appended to the prompt; owner direction appended to the prompt Context. | 2026-09-04 |
| R22 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R22 rows). Owner: We want to use the same principle. The principle is that all versions have a single source of truth. Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R23 | accept | Codesign `a`, owner override of the recommended `ch-23-c` (narrow). Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R23 rows). Effect: none; runs as written in full, no narrowed copy. | 2026-09-04 |
| R24 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R24 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R25 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R25 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R26 | accept | Codesign `a`, confirms the recommendation. Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R26 rows). Effect: none; runs as written. | 2026-09-04 |
| R27 | accept | Codesign `b`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R27 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R28 | accept | Codesign `b`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R28 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R29 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R29 rows). Effect: none; runs as written. | 2026-09-04 |
| R30 | accept | Codesign `b`, confirms the recommendation. Class C (language-bound mechanic), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R30 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R31 | accept | Codesign `a`, confirms the recommendation. Class E (one-sided, language-specific), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R31 rows). Owner: Make sure there's a security scanner. I don't know if Bandit serves the TypeScript ecosystem, but if it does, we should add it across the board. Same thing with Rust Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R32 | accept | Codesign `b`, confirms the recommendation. Class M (mixed), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R32 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R33 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R33 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R34 | accept | Codesign `b`, confirms the recommendation. Class M (mixed), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R34 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R35 | accept | Codesign `b`, confirms the recommendation. Class M (mixed), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R35 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R37 | accept | Codesign `b`, confirms the recommendation. Class C (language-bound mechanic), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R37 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R38 | accept | Codesign `b`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R38 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R39 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R39 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R40 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R40 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R41 | accept | Codesign `a`, confirms the recommendation. Class E (one-sided, language-specific), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R41 rows). Effect: none; runs as written. | 2026-09-04 |
| R42 | accept | Codesign `a`, confirms the recommendation. Class E (one-sided, language-specific), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R42 rows). Owner: Against the existing solutions and follow a similar pattern Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R43 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R43 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R44 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R44 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R45 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R45 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R46 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R46 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R47 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R47 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R48 | accept | Codesign `b`, confirms the recommendation. Class M (mixed), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R48 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R49 | accept | Codesign `a`, confirms the recommendation. Class C (language-bound mechanic), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R49 rows). Effect: none; runs as written. | 2026-09-04 |
| R50 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R50 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R51 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R51 rows). Effect: none; runs as written. | 2026-09-04 |
| R52 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R52 rows). Effect: none; runs as written. | 2026-09-04 |
| R53 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R53 rows). Effect: none; runs as written. | 2026-09-04 |
| R54 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R54 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R55 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R55 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R56 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R56 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R57 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R57 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R58 | accept | Codesign `a`, confirms the recommendation. Class F (genuine design disagreement), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R58 rows). Owner: Look at the best practices and principles from the Python logging and see what applies to best architectural practices for both TypeScript and Rust. There should be a specific research item here. Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R59 | accept | Codesign `b`, owner override of the recommended `ch-59-a` (accept, Rust alone). Class F (genuine design disagreement), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R59 rows). Owner: Implementation, but this is about the design pattern. Things like this are about making sure we have best-in-class logging, best practices, and configurations, and that we research the appropriate libraries for Python. We should take the same principles and apply them to TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R60 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R60 rows). Effect: none; runs as written. | 2026-09-04 |
| R61 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R61 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R62 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R62 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R63 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R63 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R64 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R64 rows). Owner: Looking at architectural pattern, not the exact library. We'd like a similar pager pattern for TypeScript and Rust. Effect: cross-repo question appended to the prompt, scoped to the shared part; owner direction appended to the prompt Context. | 2026-09-04 |
| R65 | accept | Codesign `b`, confirms the recommendation. Class A (setting drift), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R65 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R66 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R66 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R67 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R67 rows). Effect: cross-repo question appended to the prompt, scoped to the shared part. | 2026-09-04 |
| R68 | accept | Codesign `a`, confirms the recommendation. Class G (Rust-only), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R68 rows). Effect: none; runs as written. | 2026-09-04 |
| R69 | accept | Codesign `b`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize partly (`docs/port/DIVERGENCE-ANALYSIS.md`, R69 rows). Owner: We should look at Hono because that's what we've settled upon, and tRPC as the equivalent for the TypeScript repo should be added. We should copy the same architectural principles and patterns, and have equivalents for a base there. We need to find the equivalent for Rust as a specific research item. Effect: cross-repo question appended to the prompt, scoped to the shared part; owner direction appended to the prompt Context. | 2026-09-04 |
| R70 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R70 rows). Effect: none; runs as written. | 2026-09-04 |
| R71 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R71 rows). Owner: This one, I'd look at the principle of what Py Launch Blueprint is doing and if we should do the same at all. Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R72 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R72 rows). Effect: none; runs as written. | 2026-09-04 |
| R73 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R73 rows). Owner: We should do the research for both the equivalency and best practice for TypeScript and Rust using the same principles as the PyLaunch template. Effect: none; runs as written; owner direction appended to the prompt Context. | 2026-09-04 |
| R74 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R74 rows). Effect: none; runs as written. | 2026-09-04 |
| R75 | accept | Codesign `b`, owner override of the recommended `ch-75-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R75 rows). Owner: Looking at architectural principles, we see a state-of-the-art pattern that we want to replicate with good security practices and middleware. It's not about the same exact implementation, but about the best practice for the equivalent principles in TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R76 | accept | Codesign `b`, owner override of the recommended `ch-76-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R76 rows). Owner: Same thing. We would like to take the principles from the implementation in PyLunch blueprint and have an equivalent for using Hono and TypeScript, and whatever the best framework is to use in Rust. Looking for maturity, stability, and speed. HoNo is known for speed, which is why we're using it in best practice. We use FastAPI in Python, not so much for its speed, but for its good quality and reliability. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R77 | accept | Codesign `b`, owner override of the recommended `ch-77-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R77 rows). Owner: We should take the principles from the Python implementation and make sure there are equivalents in TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R78 | accept | Codesign `b`, owner override of the recommended `ch-78-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R78 rows). Owner: Take the principles of using Otel and find the best Otel libraries and equivalents for TypeScript and Rust. Implement them there. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R79 | accept | Codesign `b`, owner override of the recommended `ch-79-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R79 rows). Owner: Again, there's a good architecture in PyLaunch Blueprint. We should find that architecture and implement the same principles and the same versions for TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R80 | accept | Codesign `b`, owner override of the recommended `ch-80-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R80 rows). Owner: Again, taking the same principles, we need to find the appropriate implementation and best practices for both TypeScript and Rust. For individual research items, we found the best practices and architecture specifically for PyLaunch Blueprint. We'd like to have the same for TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R81 | accept | Codesign `b`, confirms the recommendation. Class F (genuine design disagreement), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R81 rows). Effect: cross-repo question appended to the prompt. | 2026-09-04 |
| R82 | accept | Codesign `a`, confirms the recommendation. Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R82 rows). Effect: none; runs as written. | 2026-09-04 |
| R83 | accept | Codesign `b`, owner override of the recommended `ch-83-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R83 rows). Owner: Should take the principles and architectural pattern from PyLaunch Blueprint, the Python version, and see what the equivalents would be for TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R84 | accept | Codesign `b`, owner override of the recommended `ch-84-a` (accept, Rust alone). Class B (same pattern, language-bound tool), harmonize no (`docs/port/DIVERGENCE-ANALYSIS.md`, R84 rows). Owner: Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust. Effect: cross-repo question appended to the prompt, answered in full; owner direction appended to the prompt Context. | 2026-09-04 |
| R85 | accept | Codesign `b`, confirms the recommendation. Class D (one-sided, language-neutral), harmonize yes (`docs/port/DIVERGENCE-ANALYSIS.md`, R85 rows). Owner: Again, this is a more mature version for Python. We should find the equivalencies and best practices for TypeScript and Rust. Effect: cross-repo question appended to the prompt; owner direction appended to the prompt Context. | 2026-09-04 |
| R86 | accept | **Not from the 2026-09-04 codesign; this item did not exist then.** R86 was created on 2026-09-12 by the owner's direct instruction during the R18 review: "I would also like the Codex variant of these to exist." The disposition is therefore `accept` by the direction that created the item, not by a codesign selection, and no recommendation was pre-selected for the owner to confirm or override. Class: none assigned (`docs/port/DIVERGENCE-ANALYSIS.md` predates the item and carries no R86 rows), so the harmonize question does not arise. Effect: none on the index or the ledger, as for every other `accept`. Recorded by the controller so that publication is not blocked by a missing row; the owner should confirm the wording, and only the wording, since the disposition follows from the instruction quoted above. | 2026-09-12 |
