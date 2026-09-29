actor: audit-fable-R27-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 89824ad9c99c6de6b1594456e15f17235118ae22f2208860f2a84de2e50ae2ad
verdict: reject
unresolved-findings:
1. JF-3: the `## Engines` section and the channel discussion misstate the Muse leg's channel position.
2. JF-2: the LOW hook-mode question's template sub-question is unanswered.

# R27 judgment audit — revision 1

**Scope.** This audit judges the reasoning and fidelity of `review/DECISION.md` revision 1. It does not judge execution; the empirical audit reruns the scripts. The recomputed sha256 matches the expected value. Files read: the decision; `inputs/prompt.md`, `inputs/prerequisites.json`, `inputs/EXECUTION.json` and `manifest.json`; `raw/muse.md` and `raw/opus.md`; the five scripts and logs under `review/evidence/`; `research/RUNBOOK.md`, in both the working tree and `HEAD`; `docs/port/PARAMETERS.md`; `docs/port/DIVERGENCE-ANALYSIS.md`, R27 rows only; and the decisions of R11, R42 and R19. No other seat's audit file and no snapshot file was read. Audit date: 2026-09-26.

**Verdict: reject.** The engineering recommendation holds. Every load-bearing technical claim I spot-checked traces to a log line or source that says what the decision says it does. The rejection rests on two fidelity defects that the contract makes blocking: a misstated engine position on the widest disagreement, and one prompt sub-question left unanswered. Both repairs are text-only. Neither needs a new check or a change to the recommendation.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass, with a note | The recommendation (`DECISION.md:13`), the file bodies (`:19-73`), the settled-rows table (`:79-90`), the handoffs (`:189-196`) and `re-verify:` (`:198`) agree on the tool, the five keys, `channel = "1.98.1"`, the empty exclude list, the hook without a glob, and `format-check` as the first composite step. The C1–C4 claims in the check table (`:239-242`) match the logs. Note: acceptance criterion 7 (`:114`) says the hook, the composite and CI give "the same formatting verdict". The composite and CI are stricter than the hook because they add the ignored-key and reachability guards. The hook can also block where CI passes (A-H6, which `:177` records). Neither case is a false pass, so this is a wording note, not a finding. |
| JF-2 prompt questions and constraints | **fail** (Finding 2) | HIGH-1: rustfmt uncontested, with alternatives named (`:121`, F9). HIGH-2: each key with its stable or unstable status (`:84-85`, `:122`, C1.3). HIGH-3: agreement levels and cross-repo drift (`:98-104`, `:185`). MEDIUM exclude-scope question: both R28 outcomes stated (`:170`). MEDIUM composite question and its cost (`:181`, C2.8). LOW pin question (`:147-157`). LOW hook question: the mode is answered (`:172-179`), but "what do popular Rust project templates default to?" is not (Finding 2). Constraints: stable-only is honoured (C1.1–C1.3); edition 2024 is honoured; the OS gate is stated as a gap (see the notes below). |
| JF-3 engine fidelity and adjudication | **fail** (Finding 1) | 14 of the 15 disagreement rows (`:258-274`) cite raw lines that say what the row claims. I checked `muse.md:127-129`, `:213-215`, `:419`, `:481`, `:989-990`, `:1100-1102`, `:276-283` and `opus.md:242-249`, `:263-265`, `:474-478`, `:593`, `:642-645`, `:782-784`, `:831-837`, `:1044-1052`. Row 13, "Muse measured Homebrew's build", is supported, although the decision does not show why. Muse prints a bare `rustfmt 1.9.0` (`muse.md:7`), which is Homebrew's version format (`DECISION.md:221`); rustup builds print `-stable (…)`. Muse also cites "the installed `1.96.0`" toolchain (`muse.md:10`), which is on this host's rustup list (`r27-channel-pin.log:2`). Row 1 and the body at `:147-149` misstate Muse's channel position (Finding 1). |
| JF-4 load-bearing claims trace | pass, with a note | Spot-checked sources: R42 `DECISION.md:26` (profile and components) and `:302-305` (8 of 9 surveyed repositories pin an exact version); R11 `DECISION.md:93`, `:259`, `:268` (`-D warnings`), `:286` (the `hygiene` slot) and `:383` (the `hygiene` rustup download is unmeasured); R19 `DECISION.md:66`, `:351` (the `rust-toolchain` ecosystem is deferred until R27 fixes a numeric channel). The figures log F1–F10 matches every figure quoted. An independent read-only crates.io query for `rustfmt-nightly` confirmed that 1.4.20 (created 2020-09-06T02:12:50Z) is newer by `created_at` than 1.4.21 (created 02:08:44Z), as the decision's correction at `:276` says. Note: `research/RUNBOOK.md:83` and `:178` are off target in both the working tree (line 88 is the synthesizer row; line 182 is the `BASELINE-REVIEW:` adjudication rule) and `HEAD`. The runbook is edited in the working tree, so the drift is not the synthesizer's fault, and the substance of both citations is correct. |
| JF-5 couplings hand over owned choices | pass | R42 keeps `profile` and `components`, and R27 supplies only the `channel` value, which R42 `DECISION.md:26` assigns to R27. The CI step is placed in R11's `hygiene` slot, and its phrasing is left to R11 and R42 (`:75`). The `.github/dependabot.yml` entry is handed to R19 (`:193`), consistent with R19's deferral (`DECISION.md:66`). The composite recipe's name and its other members are left to their owners (`:37`). R28 gets both outcomes (`:170`). R37 gets the hook assumption (`:195`). R29 gets the TOML layout (`:196`). No coupling decides another item's value. |
| JF-6 assumes lines byte-identical | pass | A script compared all six `assumes` values with the live `docs/port/PARAMETERS.md`. All six match exactly (`ci-job-structure`: 8,093 characters; `package-manager-invocation`: 667). Note: at `HEAD`, the `ci-job-structure` value is `—`. The working-tree registry carries R11's value, and R11's `DECISION.md` and `acceptance.json` hash to the values in `inputs/prerequisites.json`. |
| JF-7 no conflict with accepted prerequisite values | pass | R11 and R42 decision and acceptance hashes match `inputs/prerequisites.json`. `channel = "1.98.1"` fills the slot R42 left open and fires R19's recorded trigger; it contradicts no published value. |
| JF-8 evidence scripts exist; counts match | pass | All five scripts and logs are present. PASS lines per log: config-surface 65, workspace-scope 14, hook 13, channel-pin 9. FAIL lines: 0 in every log. The total is 101, as `:235` states. The figures log contains no assertions, as stated. Spot-checked observations: C2.2 (from `crates/core`, the plain form exits 0 and `--all` exits 1); A-H4 rejected and B-H4 accepted; C-H6 rewrote `web.rs` outside the commit; C4.2 `stable` resolves to 1.94.0; C4.6 six new warn-by-default lints. |
| JF-9 decision shape | pass | The four required H2s are present in order. `## Supersedes` is absent, which is correct for a first synthesis. `### Principles and implementation` sits under `## Decision`. `re-verify:` is present with a date and events. The settled `F###` rows are present. |
| JF-10 recommendation follows from evidence | pass | The exact channel over `stable` follows from C4.2 (`stable` names a different toolchain on each machine), C4.6 with R11 `:268` (clippy's warn set changes under `-D warnings`), F5, and R42 `:302-305`. The decision concedes C4.5 honestly. Rejecting the glob follows from A-H4 against B-H4. The empty exclude list with a reachability guard follows from C1.3b and C2.3–C2.5. Check-and-block follows from W1, W2 and C-H6. |

## Findings

### Finding 1 — JF-3: the Muse leg's channel position is misstated

**The failed claims.** The disagreement table row 1 (`DECISION.md:260`) gives Muse's position as:

> `stable`; "no version number exists" (`raw/muse.md:801-802`)

The body (`DECISION.md:147-149`) says Muse "argues that no version number exists to pin" and then concludes:

> The Muse leg's premise is false.

**The evidence.**

- The quoted phrase is not in the raw report. `raw/muse.md:801-805` reads: "There is no version number to float or pin: `cargo fmt --version` reports the component build of the active toolchain, and the only selectors rustup offers are the channel (`stable`, `beta`, `nightly`, or a dated/archive version) and the component set."
- In that passage, Muse names a dated or archive version as an available selector.
- Muse evaluates the exact pin and excludes it on stated grounds at `raw/muse.md:834-837`: "A dated or version-pinned channel (e.g., `1.98.1`): fails on maintenance fit — it freezes the whole toolchain (compiler, cargo, clippy, rustfmt) for the sake of a formatter whose formatting rules the template already constrains via `style_edition`; no surveyed project does this for formatting. Rejected as unneeded rigidity."
- The decision never cites `:834-837`. Its C4.1 rebuttal therefore answers a position Muse did not take: Muse never said an exact channel cannot be pinned.
- The decision's evidence does answer Muse's real argument. C4.6 with R11 `:268` answers "for the sake of a formatter": the channel also fixes clippy's lint set. F5 and R42 `:302-305` answer the claim that no project pins for formatting. F8 answers the upkeep cost. C4.5 concedes the `style_edition` point. The outcome therefore stands; only the representation is wrong.

This is the widest disagreement between the legs, and JF-3 requires each engine's position to be stated faithfully.

**The repair.**

1. In row 1, replace the quoted phrase with Muse's verbatim words from `raw/muse.md:801-805`, and add the citation `raw/muse.md:834-837`.
2. In `DECISION.md:147-149`, replace "The Muse leg's premise is false" with wording such as: "Muse's point that rustfmt has no version separate from its toolchain is correct. Muse rejects an exact channel as unneeded rigidity for a formatter (`raw/muse.md:834-837`). C4.6 answers that the channel also fixes clippy's lint set under R11's `-D warnings`; F5 and R42's survey answer the claim about field practice; F8 answers the upkeep cost; C4.5 concedes the formatter-only point."
3. Keep C4.1 as evidence that the pin mechanism works, not as a refutation of Muse.

### Finding 2 — JF-2: the LOW hook question's template sub-question is unanswered

**The failed claim.** The prompt's LOW question (`inputs/prompt.md:42`) ends: "what do popular Rust project templates default to?" The decision's hook-mode section (`DECISION.md:172-179`) and settled row F104 (`:89`) justify check-and-block with the executed checks. They say nothing about Rust hook templates. A search of the decision for `husky`, `template default` and `templates` returns no match.

**The evidence.** The Opus leg answered the sub-question with sourced figures that the decision does not carry:

- `raw/opus.md:123-127`: `cargo-husky` (3,630,801 crates.io downloads) generates `cargo fmt` with `--check` under its `run-cargo-fmt` feature (`rhysd/cargo-husky` `build.rs:141-142`). `doublify/pre-commit-rust` (204 stars) defines a write-mode `entry: cargo fmt`, which fails the commit when the hook changes a file.
- `raw/opus.md:778-782`: the three hook modes found in the field.
- `raw/opus.md:801-802`: "Among Rust hook templates, check mode (cargo-husky) or write-and-fail (pre-commit framework hooks). None restages."

Every prompt question must be answered. This one has evidence available in a raw report.

**The repair.** Add one sentence to the hook-mode section, citing `raw/opus.md:123-127` and `:801-802`. It should state that Rust hook templates default to check mode (cargo-husky) or write-and-fail (pre-commit-rust), that none restages, and that the recommended check-and-block job therefore matches the template field. Mark the figures as carried from the Opus leg and not re-fetched, as the decision does for its other carried figures.

## Notes (recorded, not findings)

- **Gate 4, OS coverage.** The checks ran on macOS only; `ubuntu-latest` was never run (`:134`, `:245`). The prompt allows a stated evidence gap, and `re-verify:` names the first `ubuntu-latest` run. Muse cites tokio's CI installing rustfmt on `ubuntu-latest` (`raw/muse.md:349-351`). Citing it would close the gate with a source.
- **Pin value not executed under rustup.** `RUNBOOK.md` §5 says version-pin recommendations must execute. The mechanism executed with `1.93.0` and `1.96` (C4.1). The value `1.98.1` was covered only by Homebrew's rustfmt build (C4.3). The decision discloses this (`:155`, `:245`) and lists it for P03 (`:280`). Whether the gap is acceptable is a question of execution truth, which belongs to the empirical audit.
- **`BASELINE-REVIEW:` demotion.** The decision's reason for recording the Opus leg's two lines (F102, F089) as follow-on rationale is that `RUNBOOK.md:18-22` "scopes that form to REUSE and ADOPT baselines". That reads too much into the runbook: those lines describe P02-T01's review scope, and `inputs/prompt.md:7` applies the form to any challenged baseline. The outcome is still defensible for three reasons. `DIVERGENCE-ANALYSIS.md` marks these rows `harmonize: yes`. Prompt question HIGH-3 asks for exactly this rationale. The decision invites the controller to raise either line (`:185`). No script in `scripts/` routes on the `BASELINE-REVIEW` prefix. If the decision is revised, restate the reason without the scoping claim.
- **Provenance, for the controller.** The decision itself flags that the synthesizer ran on the Opus seat and that Muse filled the Codex seat without an `engine_overrides` entry in the run snapshot (`:5`). The live `research/EXECUTION.json` now lists `R27: ["muse", "opus"]`. The working-tree runbook records owner decisions Q9.B and Q17.A (2026-09-27), which extend the substitution to R27. These are controller matters, not fidelity defects.
