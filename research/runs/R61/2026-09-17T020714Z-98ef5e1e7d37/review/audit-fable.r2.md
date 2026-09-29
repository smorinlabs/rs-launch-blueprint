actor: audit-fable-r61r2-2026-09-22
model: claude-opus-5-5
family: anthropic
decision-sha256: 3e4e126cc0ffdba61a7e2368dec0183414e3f3908a7316ffc4ccdc550d18da9a
verdict: reject
unresolved-findings:
  1. JF-1/JF-4 — `--dry-run` ordering misstated against the cited py pin, and self-contradictory (DECISION.md:86)

# Judgment audit — R61 interactive-prompts, DECISION.md revision 2

Audit date 2026-09-22 (Pacific). This is a judgment audit of the decision's reasoning and fidelity; the empirical rerun belongs to the separate empirical audit. This auditor did not read `review/audit-fable.md`, `review/audit-claude.md`, `review/audit-claude.r2.md` or `review/R61-r1-snapshot.md`. It made no git writes, ran no `scripts/research_runner.py` command, and called no paid API.

**Hash.** `shasum -a 256 review/DECISION.md` → `3e4e126cc0ffdba61a7e2368dec0183414e3f3908a7316ffc4ccdc550d18da9a`, equal to the expected value.

**Inputs read.** `inputs/prompt.md`; `research/RUNBOOK.md` §5 (decision shape and the auditor contract); `raw/codex.md` (sha256 `a22fcc08…4f2e`) and `raw/opus.md` (sha256 `162d21ed…a7`), both matching the hashes the decision names and the pinned files under `raw/`; the prerequisite `research/topics/67-error-and-exit-code-contract/DECISION.md` (sha256 `16947ab1…9497`) and its `acceptance.json` (`b13d6e80…422`), both equal to `inputs/prerequisites.json`; `docs/port/PARAMETERS.md`; `docs/port/COMMONALITY.md` rows F275–F280 and F360; `research/topics/60-cli-parsing-framework/DECISION.md`; `research/topics/65-color-enablement-chain/DECISION.md`; the evidence directory `review/evidence/`; the CLI Design Standard blob `f9de0437…` from `/Users/stevemorin/c/cli-standards`; the py pin `b08bccfb` and the ts pin `cb1cbcb2` from the local checkouts.

## Checks

| Check | Result |
|---|---|
| JF-1 internal consistency | **fail** — finding 1 |
| JF-2 every question answered, every constraint honored | pass, with the LOW question's answer defective through finding 1 |
| JF-3 `## Engines` fidelity and adjudication | pass |
| JF-4 load-bearing claims trace to sources | **fail** — finding 1 |
| JF-5 couplings hand over owned choices | pass |
| JF-6 `assumes` lines byte-identical to the live registry | pass |
| JF-7 no conflict with accepted or published prerequisite values | pass |
| JF-8 evidence scripts exist; claimed counts match the files | pass |
| JF-9 decision shape follows the published contract | pass |
| JF-10 recommendation follows from the evidence | pass |

### JF-1 — internal consistency: fail

Finding 1 contains the contradiction: DECISION.md:86 states that `--dry-run` is evaluated "**after** consent is obtained", and the same paragraph concludes that "Both flags compose by the prompt never being reached". Under the stated ordering, `config set --dry-run` without `--yes` does reach the confirm prompt.

The rest of the decision is consistent. The class table at :92–96 agrees with the outcome table at :124–134, including the class-scoped `NotTTY` arm. The OV-02 argument at :108–118 matches P6, criterion 7 and the outcome table. The 24-package figure matches 35 − 11, both from check `C12`. The 1.96 floor and 1.85.0 tree maximum give the "eleven minors of headroom" stated at :295 and :308.

### JF-2 — prompt questions and constraints: pass, with a defect carried in from finding 1

- HIGH, single crate: answered. One crate, `inquire`, covers all three shapes (:23–40), and architecture C, the split design, is explicitly rejected (:196).
- HIGH, name/value pairs and stream override: answered at :249–250. `inquire` returns `Vec<T>` and is stderr-only by construction. `dialoguer` returns indices and accepts an explicit `Term`.
- HIGH, principles and agreement levels: answered by the P1–P6 table at :152–159, with "must agree" separated from "may vary". The `DIVERGENCE-ANALYSIS.md:199` `harmonize = partly` scope is cited.
- MEDIUM, non-TTY: answered at :62–76. Detection is the template's job, because the back-ends open `/dev/tty`.
- MEDIUM, defaults and validation: answered at :202; both are native to the crate.
- LOW, `--dry-run`/`--yes` composition: answered at :78–86. The `--dry-run` half of the answer is defective; see finding 1.
- MEDIUM, one `--no-input` behaviour for all three repositories: answered with the class rule at :98.
- Constraints: the four-step landscape survey is present at :165–188. Fitness gates are answered per candidate before popularity is weighed (:204–215). Gate 1 is recorded as `inapplicable` under the owner ruling. Figures carry endpoints and a retrieval date. Stable Rust, edition 2024 and the OS matrix are honored. Out-of-scope items are respected: no cancellation exit code is invented, since R67's `RSLB903` is consumed rather than decided, and no prior-art Rust repository is cited.

### JF-3 — `## Engines`: pass

Every disputed sentence was located in the raws:
- Codex recommends `dialoguer` (codex.md:31).
- Codex says "`dialoguer` itself also rejects a nonterminal `Term`" (codex.md:17).
- Codex records the RustSec 404 as a "blocking evidence gap" (codex.md:95, :119) and makes its recommendation conditional on `cargo deny` (codex.md:31).
- Codex excludes `cliclack` at the declared-MSRV and platform gates (codex.md:59).
- Codex emits the `BASELINE-REVIEW: F360` line (codex.md:25).
- Opus records `Excluded by gate` as "**None**" (opus.md:477–482).
- Opus numbers its override OV-01 (opus.md:236).
- Opus reports 32 packages against 8 (opus.md:473, :1079).
- Opus records `demand` at 257 stars (opus.md:462).

Each of the five disagreements is adjudicated with evidence the synthesizer re-ran: checks `C4`/`C5`/`C6`, case B of section 13, checks `C9-*`, and checks `C7-*`. The Codex raw's field and member counts are 10 H3 fields and one member (`dialoguer`), as stated. The Opus raw has 10 H3 fields and three members (`inquire`, `crossterm`, the interactivity gate), as stated.

The Codex quote at :374 is described as carried "verbatim", but its markdown links are rendered as plain text, the backticks around `--yes` are dropped, and the trailing "(retrieved 2026-09-16)" is omitted. The content is faithful. This is a non-blocking note.

### JF-4 — claims trace to sources: fail

Finding 1 is the failure. The spot-checks below passed:
- **R67 rows:** `RSLB205` wording, `RSLB903 → 130`, `RSLB501 → 5`, `RSLB101`, `RSLB000` (R67 DECISION.md:383). Also R67's "product question for R61" passage and the no-prompt-local-handler rule (:302–306), and the "wired to a typed variant or retired" trigger (:379).
- **CLI Design Standard:** the blob's content hash is `9fb05d3d…463f`, as asserted. Lines :253, :381, :456 (including "Under `--no-input` with no required bypass flag, the command **MUST** fail rather than guess."), :461 and :472 each carry the quoted clause.
- **ts pin `cb1cbcb2`:** `projects.ts:146` computes `opts.input !== false && deps.stdinIsTTY && deps.stderrIsTTY`, and lines 169–173 implement the empty-selection no-op.
- **py pin `b08bccfb`:** `options.py:265-278` (the `--yes` short-circuit, the `--no-input` `ConfigError`, `err=True`); `config.py:82-83` (`if assume_yes: chosen = current`); `config.py:196-203` (`confirm` → `SystemExit(int(ExitCode.INTERRUPT))`); `errors.py:45,55` (`INTERRUPT = 5`, `PLBP004`).
- **Registry figures:** the figures table at :226–231 equals `r61-claims-r1.log` section 10 line for line. That section's header records `executed at 2026-09-17T05:43:30Z`, which matches the corrected **Dates** paragraph.

### JF-5 — couplings: pass

- **R60:** R61 adds `no_input` to R60's `GlobalArgs`. R60's decision never mentions `--no-input` or F275; a grep for `no.input|F275` returns zero hits. F275 is `COMMON → REUSE` and has no owning item (COMMONALITY.md:279), and R60's F270 row (R60 DECISION.md:512) fixes the pattern that global flags live on the flattened `GlobalArgs`. R61 therefore follows R60's published pattern and does not decide any R60 choice.
- **R65:** R65's colour decision is consumed through an explicit `RenderConfig`, and R65's value is not changed (:142).
- **R67:** R67's catalogue is bound to without new rows. Option (d), adding a "declined" row, is correctly left as a `CONFLICT:` escalation the decision does not need.
- **F277/F278:** the rows are preserved as `ADOPT` flags.
- **Codex `BASELINE-REVIEW: F360`:** the line is disposed of inside R61's own scope. F360 is `DIVERGENT` and owned by R61 (COMMONALITY.md:364), and no py, ts or ledger file is changed.

### JF-6 — `assumes` lines: pass

The four `- assumes` lines at DECISION.md:301–304 were regenerated from `docs/port/PARAMETERS.md` rows 7–10 and compared by `diff`. The result is byte-identical, in registry order. No accepted-but-unpublished revision is asserted in an `assumes` line.

### JF-7 — prerequisite values: pass

R67's prerequisite hashes equal `inputs/prerequisites.json`. Every outcome in the table at :124–134 maps onto an existing R67 row or onto exit `0`. The OV-02 choice deliberately avoids R67's exit `5` meaning. No fixed parameter is contradicted.

### JF-8 — evidence: pass

- `review/evidence/r61-claims.sh` exists. `shellcheck` on it is clean, which confirms the "shellcheck-clean" claim at :9.
- `r61-claims.log` ends `TOTAL  pass=93  fail=0  skip=4`, and the four SKIPs are `C13c`–`C13f` with the `openpty` `EPERM` reason. `r61-claims-r1.log` ends `pass=97 fail=0 skip=0`.
- Section 12 prints `C12a`/`C12b`/`C12c` as `[= 9]`, `[= 35]` and `[= 11]`. `C5f` is `[= 0]`, `C9-ctl` is `[= 200]`, `C15a` is `[= 0]` and `C16a` is `[= 0]`.
- `r61-claims-rerun.diff` has 36 lines and exactly five changed lines, as claimed at :353: `run directory`, `executed at`, two `$TMPDIR` paths and section 14's `generated from`.
- The claim at :11 that `review/audit-claude.md` approved revision 1 and that its rerun "exited 5" is **unverified by this auditor**, because the auditor-blindness rule forbids reading that file.

### JF-9 — decision shape: pass

The four required H2s appear in order: `## Decision` (:19), `## Parameters` (:297), `## Empirical check` (:312) and `## Engines` (:359). `### Principles and implementation` (:144) and a `re-verify:` line (:295) sit under `## Decision`. There is no `## Supersedes`, which is correct because this is not a reversal. The recommendation, pinned versions, settled rows F276/F279/F280/F360 and the re-verify triggers are all present.

### JF-10 — recommendation follows the evidence: pass

The field is reported as having no dominant choice (:233). The runner-up's strongest argument, a 24-package gap measured like-for-like, is stated against the recommendation rather than minimized (:245). Three specific grounds carry the choice: the typed `^C` needed for `RSLB903`, the value-returning multi-select, and stderr-only output. Uncertainty and the flip conditions are explicit (:253, :366). The architecture alternatives A–E are compared before libraries.

## Finding 1 — `--dry-run` ordering misstated against the cited py pin, and self-contradictory

**Failed claim** (DECISION.md:86): "`--dry-run` (F277) is evaluated by the command **after** consent is obtained and before the write, exactly as py does at the pin (`py: src/py_launch_blueprint/cli/commands/config.py:180-183`, which renders `[dry-run] would set …` and returns). Both flags compose by the prompt never being reached; neither needs a crate-side bypass."

**Evidence.** At py pin `b08bccfb`, `config_set` checks `if dry_run:` at `config.py:181`, renders `[dry-run] would set {key} = …`, and `return`s at :184. That happens *before* the existing value is read (:188) and *before* the overwrite `confirm(` call at :196. In py, `--dry-run` therefore bypasses the confirm without any consent. The decision's own citation shows the opposite of "after consent is obtained".

The paragraph's closing sentence, "the prompt never being reached", is true of py's order and false of the order the paragraph asserts. The difference is observable. Take `config set k v2 --dry-run --no-input` without `--yes`, with `k` already set to a different value. py exits `0` with a preview. The decision's ordering sends the command through the precedence ladder at :80–83, which never mentions `--dry-run`, to the consent-class refusal: `RSLB205`, exit `2`.

The error is inherited from the Opus raw (opus.md:192, :1035). This decision answers the prompt's LOW question, whether `--dry-run` composes by skipping the confirm call entirely. Acceptance criterion 4 (:286) tests only `--dry-run --yes`, which hides the difference.

For completeness: `config init`'s `--dry-run` check sits at `config.py:101`, *after* the guided `click.prompt` values are collected. So in py the order differs by command, and a blanket "after consent" or "never reached" claim is wrong for one command or the other.

**Repair.** Choose one of the two edits below and apply it everywhere it matters:
1. **Match py.** Restate :86 as follows. `config set` evaluates `--dry-run` before the overwrite confirm (py `config.py:181-184` precedes `:196`), so the confirm is never reached and no consent is needed. `config init` evaluates `--dry-run` after the guided values (py `config.py:101`), so the guided prompts still run and are gated like any other. Add `--dry-run` to the precedence ladder at :80–83 for `config set`, ahead of the gate. Add an acceptance criterion for `config set --dry-run --no-input` without `--yes`: exit `0`, the preview on stderr, no write.
2. **Keep consent-before-dry-run.** Declare it as a departure from py under `OVERRIDE (OV-nn)` with `**Argument:**` and `**Options:**`. Delete "exactly as py does" and "the prompt never being reached". State the `--dry-run --no-input` outcome, `RSLB205`/2, explicitly.

Neither edit changes the crate recommendation.

## Notes (non-blocking; no repair required for approval)

- The section-1 row of the table at :331 still reads `rustc 1.98.0`, `cargo 1.98.0`. The retained revision-2 log that the table cites reads `rustc 1.98.1` and `cargo 1.98.1`. The 1.98.1 rerun is disclosed at :314, so this is stale text rather than a contradiction. Updating the row would be tidier.
- The precedence sketch at :81 reads `global.yes`. The prompt attaches `--yes` via `mutation_options` to `config init`/`config set`, and :279 adds only `no_input` to `GlobalArgs`, so this is illustrative naming rather than a decision.
- The adopter rows for bitwarden, tauri, sqlx and wasm-pack (:182–186) cite only the reverse-dependency listing. The prompt's figure table asks for the listing plus the project's `Cargo.toml`. The load-bearing adopter, ast-grep, is manifest-verified by checks `C11a`/`C11b`, so the compatibility proof does not depend on the others.
- `dialoguer`'s issue-responsiveness median, roughly 0.2 days in both raws, supports the claim at :31 that `dialoguer` wins on maintainer activity, but the decision does not tabulate it.
- The "verbatim" wording at :372 is discussed under JF-3.
