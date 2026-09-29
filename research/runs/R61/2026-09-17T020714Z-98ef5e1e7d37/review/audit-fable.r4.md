actor: audit-fable-r61r4-2026-09-22
model: claude-opus-5-5
family: anthropic
decision-sha256: 11c34834970a0eaaa92efa161bc788694ff0973979efc6af20367d8393bc0c91
verdict: reject
unresolved-findings:
- F1 (JF-1, internal consistency): the decision says py needs no change, but its own P3 requires exit `2` in py and its own log shows py exits `1`
- F2 (JF-5, couplings): the decision fixes a multi-manifest workspace layout that belongs to R02, and never names R02

# Judgment audit — R61 interactive-prompts, DECISION.md revision 4

**Scope.** This audit judges the reasoning and fidelity of
`research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md`, revision 4.
Its sha256 is `11c34834970a0eaaa92efa161bc788694ff0973979efc6af20367d8393bc0c91`,
recomputed with `shasum -a 256` before reading. This audit reran no scripts; the
empirical audit reruns them.

**Inputs read.**
- The decision.
- `inputs/prompt.md`, `inputs/prerequisites.json` and `inputs/parameters.json`.
- `research/RUNBOOK.md` §3–§5: the auditor roles, the decision H2 contract and the acceptance rule.
- `raw/codex.md` (sha256 `a22fcc08…4f2e`) and `raw/opus.md` (sha256 `162d21ed…fa7`). Both hashes were recomputed and match the pinned file names.
- Prerequisite R67: `research/topics/67-error-and-exit-code-contract/DECISION.md` (sha256 `16947ab1…9497`) and its `acceptance.json` (sha256 `b13d6e80…f422`). Both match `inputs/prerequisites.json`.
- For the coupling checks: the live registry `docs/port/PARAMETERS.md`, R49's published decision, R02's prompt, and the R63 and R65 decisions.
- The evidence files `review/evidence/r61-claims.log`, `r61-claims-rerun.diff` and `r61-claims.sh` (its header only).
- The py pin `b08bccfb` and the ts pin `cb1cbcb2`, read with `git show` in the local checkouts.

I read no prior `audit-fable*.md`, no `audit-claude*.md` and no `R61-r*-snapshot.md`.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | See F1. Everything else I spot-checked agrees. The rev-4 `**Dates.**` paragraph now names exactly the two re-retrieved sets. The 113 assertions stated under `**Evidence.**` equal the log's 109 pass + 4 skip. The marginal package counts (+26 and +2) give the stated 24-package gap. The `--dry-run` ladder agrees with criteria 4 and 10, with the outcome table's first row, and with the Consent row. The OV-02 "py exits `5`" (`config.py:203`, `SystemExit(int(ExitCode.INTERRUPT))`, `INTERRUPT = 5`, both read at the pin) is a different path from the `--no-input` `ConfigError` exit `1`, and the decision keeps the two apart. |
| JF-2 prompt questions and constraints | pass | All seven prompt questions are answered. HIGH single crate: the `## Decision` table and architecture D. HIGH name/value and stream: numbered points 1–2. HIGH principles: P1–P6 and the must-agree / may-vary table, although F1 affects its py column. MEDIUM TTY: the gate and the observations from sections 3 and 13. MEDIUM defaults and retry: the paragraph on native defaults and retry. LOW `--dry-run`/`--yes`: the precedence ladder. MEDIUM F360: the class table. Every fitness gate is applied, with gate 1 marked `inapplicable` under the owner ruling. The landscape uses three bins, and authority and practice evidence are present. Performance is explicitly not claimed, and the reason is stated. |
| JF-3 `## Engines` fidelity | pass | Each position was checked against its raw. Codex recommends `dialoguer` (`raw/codex.md:31`). Codex says "`dialoguer` itself also rejects a nonterminal `Term`" (`:17`). The Codex `BASELINE-REVIEW: F360` line (`:25`) matches the quoted text, with the stated rendering changes. Codex excludes `cliclack` on the MSRV and platform gates (`:59`). Opus records `OV-01` (`raw/opus.md:236`), "**None.**" excluded by gate (`:479`), `--dry-run` "after consent" (`:192`, `:1035`), and the `bitwarden/clients` row (`:74`). All five disagreements are adjudicated with named checks. The rev-4 bitwarden correction was re-verified read-only on 2026-09-23. `crates.io` gives `bitwarden-cli` → repository `https://github.com/bitwarden/sdk-internal`, max version 3.0.0. `api.github.com/repos/bitwarden/sdk-internal` gives 111 stars, language Rust. The `sdk-internal` `crates/bitwarden-cli/Cargo.toml` declares `inquire = "0.7.0"`. |
| JF-4 load-bearing claims trace | pass | The py pin matches the decision. `options.py:265-278` refuses under `no_input` with the hint "pass --yes to confirm non-interactively". `config.py:82-83` sets `if assume_yes: chosen = current`. `config.py:181-184` handles dry-run and returns before `:196` `not confirm(`. The ts pin matches: `projects.ts:147` computes `opts.input !== false && deps.stdinIsTTY && deps.stderrIsTTY`. Its `:166-168` is the select-all `else` branch, and its `:170-174` is the empty-selection notice and return. The standard's blob line `:461` matches when read. The R67 rows and rules match: `RSLB205`/2, `RSLB903`/130, `RSLB501`/5, `RSLB101`/1, `RSLB000`/1, the no-prompt-local-handler rule, "a product question for R61", and "wired to a typed variant or retired". R67's `signal-hook = { version = "0.4.4", default-features = false }` and R63's `indicatif = "0.18"` match their decisions. The R01 seam matches the registry. |
| JF-5 couplings | **fail** | See F2. The R65, R67 and R60 handoffs are otherwise correct: R65's chain is unconsulted, the `RSLB` rows are consumed without edits, and `GlobalArgs` takes F275's existing flag. The Codex `BASELINE-REVIEW:` line is kept out of the ledger with a reason. |
| JF-6 `- assumes` lines | pass | The four lines are byte-identical to the `docs/port/PARAMETERS.md` value column. They match `inputs/parameters.json`, and log checks `C14b`/`C14c` pass. There are no `- owns` lines and no `CONFLICT:` lines, which is correct for the empty `owns:` and `consumes:` lines in the prompt. |
| JF-7 prerequisite values | pass | R67 is the only prerequisite, and its hashes are current. No R67 value is contradicted. OV-02 maps a declined confirm to exit `0` with no catalogue row, which requires no R67 change. |
| JF-8 evidence scripts and counts | pass | The per-section PASS counts in `r61-claims.log` agree with the prose. §3 has 6, §5 has 13, §6 has 4, §8 has 7 and §18 has 16. §13 has 2 PASS and 4 SKIP, and the SKIPs are `C13c`–`C13f`. The sections sum to 109 PASS + 4 SKIP. The `TOTAL  pass=109  fail=0  skip=4` line also appears in `r61-claims-r3.log`, and `r61-claims-r1.log` shows `pass=97 … skip=0`. `r61-claims-rerun.diff` is 36 lines, and exactly five content lines changed, as stated: the timestamp, two `$TMPDIR` lines, `run directory` and `generated from`. The script header names revision 4. The log confirms `C12a`–`C12c` (9 / 35 / 11), `C15a` (0), `C16a` (0) and `C10d`/`C10e`. |
| JF-9 decision shape | pass | The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in the contract's order, with no `## Supersedes`, which is correct for a non-reversal. `### Principles and implementation` is under `## Decision`, and a `re-verify:` line is present at line 305. The settled F rows are F276, F279, F280 and F360. |
| JF-10 recommendation follows evidence | pass | The fitness gates come before the figures. Architectures A–E are compared before the libraries. The runner-up's advantages are stated and kept, not dismissed: the +24 packages, the maintainer activity, and the absence of a duplicate. The choice is argued from three enumerated axes, each backed by a check (`C4a`/`C4b`, `C5b`, `C5g`/`C6a`, `C5f`/`C5l`/`C5m`). |

## Findings

### F1 — JF-1: "neither repo needs a behaviour change" contradicts P3 and the decision's own py observation

**Failed claims.**
- Line 108: "py implements the first two classes and has no third; ts implements the third and has no first two; **neither repo needs a behaviour change to satisfy the rule**".
- Line 166, table row P3, in the column "**Must agree across py / ts / rs**": "that a headless run terminates with a defined outcome, **and that the outcome is exit `2` when required non-auth input or consent is missing**".
- Line 104, the Consent row, in the column "Rule for py, ts and rs": "**Refuse.** No mutation; exit `2`; `RSLB205`". The Required value row on line 105 says the same.

**Evidence.**
- The decision's own log records py exiting `1` on exactly this case. `C18k` reads "config set --no-input without --dry-run: py's ConfigError exit 1 (rs maps this class to 2) [= 1]". `C18n` reads "config init --dry-run --no-input … py's ConfigError exit 1".
- At the pin, `core/errors.py` defines `ConfigError.exit_code = ExitCode.CONFIG` with `CONFIG = 1`. In py, `2` means `AUTH`.
- The standard at `:461` says: "Use exit `2` when required non-auth input or consent is missing because prompting is disabled/unavailable".
- So py does not meet the value the decision says must agree across all three repos. The prompt's HIGH question asks the decision to "distinguish missing capability or accidental drift from justified ecosystem differences". The decision labels py compliant instead.
- A second gap points the same way. py's `confirm()` (`options.py:271-278`) tests only `app.no_input`, never stdin's TTY state, and then calls `click.confirm`. So py also lacks the stdin half of the gate that the decision's shared requirement demands: "only when a human is demonstrably there". This is my reading of the pin, not an executed observation.

**Repair.** Choose one option and make lines 104–108 and 166 agree.
- **Option (a):** narrow P3's must-agree cell to "a headless run fails rather than guesses, with a defined non-zero outcome". Move "exit `2`" to the may-vary column, or mark it rs-specific under R67 and the standard. Make the "Rule for py, ts and rs" cells say "exit `2` in rs (R67 `RSLB205`); py's `ConfigError` exit `1`".
- **Option (b):** keep exit `2` as must-agree. Then replace "neither repo needs a behaviour change" with an explicit drift record: py's refusal exits `1` against R8.2's `2`, and py's confirm has no stdin-TTY test. Both go to the py follow-on project.

Neither option changes the recommendation, a parameter or a check.

### F2 — JF-5: the decision fixes R02's workspace topology and names paths that R49's published layout lacks

**Failed claims.**
- Line 29, the member table's "Where it goes" cell: "the CLI binary crate's `[dependencies]`, **and nowhere else**".
- Line 173: "the prompt crate never appears in the library crate's dependency graph".
- Line 288: "One dependency line in `crates/cli/Cargo.toml`; **nothing added to the library crate's manifest or the web surface's**".
- Lines 275–281 put the minimal example under `crates/cli/src/…`.

**Evidence.**
- R02 (`crate-boundary-enforcement`) is `open`. Its prompt asks whether "a single crate with module-visibility" or "a genuine multi-crate Cargo workspace (separate `core`, `composition`, `cli`, `web` crates)" is the answer, which is F021.
- R49 is published (revision 8, 2026-09-16), before this run. Its registered `build-tool-output-shape` value is one package with exactly one `[lib]` (`src/lib.rs`) and exactly one `[[bin]]` (`src/main.rs`, `rslbp`). R49 records the workspace split as "a trigger owned by R02" (R49 DECISION.md:112, 909–911).
- R69's registered `web-extra-surface` value places the `web` feature "on whichever crate hosts the binary targets (R02 decides which)". There is no separate web-surface manifest.
- Under the layout published today, the library and binary targets share one `[dependencies]` table. So "nowhere else" and "never appears in the library crate's dependency graph" cannot be enforced by Cargo. They would need `optional = true`, a feature, and `required-features` on R49's `[[bin]]`, or R02 resolving to a workspace.
- The decision never mentions R02 or R49 (confirmed by search).
- Counter-evidence, acknowledged: R67 (accepted) uses the same "library crate / binary crates" layering vocabulary. The *intent* of isolating the prompt crate from the library therefore has accepted precedent. The defect is the concrete multi-manifest paths and the unhedged "nowhere else", presented without naming the item that owns the choice.

**Repair.** Word the placement the way R69 does: "declared on whichever crate hosts the CLI binary target (R02 decides which)". Mark `crates/cli/…` as illustrative and contingent on R02. Add one sentence covering the single-package case under R49's current layout. In that case the dependency is `optional` behind a CLI-only feature, or isolation from the library holds by convention, and the benefit on line 173 is weakened accordingly. Add "R02 resolving the workspace topology" to the `re-verify:` triggers. The crate choice, the gate, the ladder and the outcome mapping are unaffected.

## Non-blocking notes (not findings)

1. Line 64 cites `ts: src/commands/projects.ts:146` for the gate's conjunction. At the pin, `:146` is the comment and `:147` is the `const interactive = …` line. The prompt itself cites `:146`.
2. Line 152 says "R65's parameter value is unchanged". R65 owns no registry parameter (index `owns` is `—`). "R65's decision" would be exact.
3. The rev-4 heading labels its date "2026-09-23 Pacific". The worktree rerun at `06:59:22Z` was 2026-09-22 Pacific, and the extraction rerun and the edits fall on 2026-09-23 Pacific. The label is defensible.
