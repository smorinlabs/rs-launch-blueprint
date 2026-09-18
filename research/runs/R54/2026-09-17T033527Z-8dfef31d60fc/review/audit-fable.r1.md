decision-sha256: b0fb750daeabd9697002d5dd3eebd5b6efd67f2d7cb2eb78e4e8b3f6fe964797
actor: audit-fable-2026-09-17T033527Z-8dfef31d60fc-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 (blocking) the decision states R55 is at revision 2 while R55 reached revision 3 before this synthesis and the decision's own check `D00b` pins revision 3's sha256; JF-2 (blocking) the R57 coupling bullet says the fifth-`Paths`-accessor dissent "is recorded under `## Engines` as a disagreement" and `## Engines` carries no such disagreement; JF-3 (non-blocking) "Doxa/OpenAI declares four owned parameters" miscounts and misnames that twin's declaration, which is eight parameters and does not include `project-search`; JF-4 (non-blocking) the sentence the decision quotes as the open owner question at `docs/port/BASELINE-REVIEW.md:113` is verbatim from `:193`, not from `:113`

# Judgment audit — R54 config-discovery-tiers, revision 1

Empirical (Codex) audit deferred under `W1-CODEX` (`docs/planning/p02/owner-decisions.md`
section 12, "Let's skip codex for now", 2026-09-16), so this audit ran alone and
acceptance still needs a second approving verdict. I produced none of this item's
artifacts and read them cold.

Every load-bearing claim below was checked against the primary artifact rather
than against the decision's report of it: the org CLI Design Standard at its
pinned blob read by me with `git cat-file blob`, the ledger and review documents
at their current bytes, the four sibling decisions at their current bytes, the
pinned py source, `raw/opus.md` and the three Doxa twins, and
`review/evidence/check.sh`, `check.log` and `walkup_probe.rs` read (not rerun).

## Principle and agreement level

The decision states the shared requirement as a user capability — put a setting
at the scope matching your authority, and get one published deterministic rule
for conflicts — and then binds it at the level the owner's own normative document
sets rather than at the level the ledger row happened to record. That ordering is
right, and the source supports it. Read by me at blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7` of `/Users/stevemorin/c/cli-standards`
(the document's changelog row 54 names it `v1.4.14`), `R5.1` reads:

```
**R5.1 — Precedence chain. (MUST)**
Configuration **MUST** resolve in this order, highest priority first, and the tool **MUST** document it verbatim:

1. Command-line flags
2. Environment variables (`TOOL_*`)
3. Project/local config file: nearest `.<tool>/<tool>_config.toml`, discovered by walking up from the working directory
4. User config file: `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`
5. System config file: each `$XDG_CONFIG_DIRS/<tool>/<tool>_config.toml`
6. Built-in defaults
```

and its composition sentence:

```
Where more than one config file in the chain sets the same key, maps/tables **MUST** merge recursively by default. Scalar values replace scalar values, arrays **replace** arrays (not concatenate), and the nearer scope wins. A tool **MAY** use a different merge strategy (e.g., array concatenation, cargo-style) where its domain requires it, but **MUST** document the strategy clearly.
```

and `R5.2`, quoted by the decision from "The canonical discovered config filename"
onward, reads in the blob:

```
The canonical discovered config filename **SHOULD** be `<tool>_config.toml` for findability: project/local discovery looks for `.<tool>/<tool>_config.toml` in the current directory and then each parent directory, user config is `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`, and system config is searched under each `$XDG_CONFIG_DIRS` entry as `<tool>/<tool>_config.toml`. Project discovery **SHOULD** stop at a repository/workspace boundary when detectable — for example a `.git` directory or a language/workspace root marker such as `Cargo.toml`, `go.mod`, `package.json`, or `pyproject.toml` (a non-exhaustive baseline) — otherwise at the filesystem root. An explicit `--config <path>` **MUST** **replace** the discovered project/user/system config files — it becomes the sole config file in the chain — while command-line flags and environment variables still layer above it and built-in defaults below it (R5.1). It does **not** merge with the files it overrides.
```

Both blocks are byte-identical to the decision's quotations, and the decision's
partial quotation of `R5.2` is contiguous and is introduced as covering "the
filenames, the boundary stop and the override semantics" rather than the whole
rule, so nothing is hidden by the trim. `J1`'s force label — **MUST, org-locked,
not a research finding** — is therefore correct, and the C1–C6 agreement table
assigns each principle a level the source can carry: C1/C2/C6 to the standard,
C3 to capability plus standard (F247 and `R5.3`), C4 to the already-agreed
architectural pattern F233, C5 to policy with the spelling free to vary. The
research mandate (spec §2, amendment A5) is honoured in the strong direction: py
is treated as evidence and then explicitly refused as the source of the shape,
with the refusal grounded in py's own pinned code rather than in preference.

## Design and evidence

**The architecture was compared before the library.** A1–A5 name five genuinely
different shapes, and the rejections are on fit rather than on popularity: A1
because a layering engine takes ownership of the parse (R52), the typed pass
(R53) and the per-layer sanitize step (R55); A2 because it is what R55 already
rejected for the whole stack; A4 because neither `confique` nor `twelf`
implements *discovery*, which is the hard half; A5 because it violates a `MUST`.
A2′ is chosen as the composition R55 already published rather than as a new
design, which is the correct relationship between a consumer item and a
published sibling.

**The decisive mechanism finding holds.** `E01` asserts zero `CONFIG_DIRS` or
`DATA_DIRS` matches across `etcetera` 0.11.0's whole `src` tree and `E05` the
singular `fn config_dir(&self) -> PathBuf;`, so rung 5 genuinely has no crate in
the recommended stack behind it. `X01`–`X04` record the runner-up honestly: `xdg`
3.0.0 does the job correctly and fails **no** gate, and `J3` labels its rejection
a judgement rather than an exclusion. That is the right treatment, and the
decision's own sentence — "recording it as an exclusion would misstate why it was
not chosen" — is the sentence an auditor would otherwise have to write.

**The walk-up boundary rule is grounded, and its limit is stated.** The probe at
`review/evidence/walkup_probe.rs` implements both policies and prints ten cases
over eight trees (`A`, `B`, `C`, `D`, `D2`, `E`, `F`, `G`). `P2` is the material
case: under "any `Cargo.toml` stops", a walk from `A/crates/foo/src` returns
`None` and the workspace-root `.rslbp/rslbp_config.toml` is unreachable, while
`P1` finds it under the workspace-qualified rule. That is the naive rule's defect
executed rather than asserted, and it is the defect that actually threatens this
template, whose own repository is a Cargo workspace. The `[workspace]`
line-matching limit is declared in the probe's own source — "Approximation of
'the document has a top-level `workspace` table'. P03 detects this with R52's
`toml` parser, not by line matching" — and repeated in `## Empirical check` and
in P03's validation list. `P5`/`P6b` exercise `.git` as a *file* in both
directions, matching AC7's wording.

**The six settlements are on grounds, and I checked each ground at its source.**

| # | Settlement | Ground, verified |
|---|---|---|
| 1 | Opus's A3 fold rejected | `raw/opus.md:1219` does cite R55 at "(revision 1, `## Decision`, clauses 1–3)", and R55's published loader removes both of A3's premises. Correct — but see JF-1 for the decision's own citation of R55 |
| 2 | All three Doxa layering crates rejected | Scope, plus `R5.4`'s curated-subset `MUST` against `config::Environment::with_prefix` read at `config-0.15.25/src/env.rs` (`A01`, `A02`). Both grounds are real and the second is independent of the sibling decisions |
| 3 | `etcetera` kept for rung 4 | R57 is owner-accepted at revision 2 (`44e94504…`, `W1-R57`, 2026-09-16); Doxa/OpenAI's stated defect is conceded as correct and is why rung 5 gets a `std` member |
| 4 | Gemini's `etcetera` 0.12 | `F01`/`F02`: `max_stable_version` is `0.11.0` and `/versions` lists no `0.12`. Empirical and decisive |
| 5 | Unbounded bare-filename walks closed | `R5.1` rung 3 and `R5.2` both specify the dot-directory and the boundary stop. I re-read all three twins: Doxa/OpenAI's "toward the filesystem root", Doxa/Perplexity's "when it finds one or when it reaches the filesystem root", and Doxa/Gemini's self-contradicting pair ("until a project marker is identified" and "terminating only when the root of the filesystem is reached") each occur exactly once, as quoted |
| 6 | Perplexity's fifth tier, OpenAI's owned parameters | `R5.1` enumerates six rungs and no `local` tier; the prompt's `## Couplings` carries an empty `- owns:` line and `docs/port/PARAMETERS.md` has no `R54` owner row, so the registry half is right. The ordering string `system < local < user < project < env < CLI` occurs verbatim in the Perplexity twin. See JF-3 for the count |

**The `BASELINE-REVIEW:` dispositions are legitimate.** Both carried lines are
byte-identical to `raw/opus.md:201` and `:232` — I diffed them, not eyeballed
them. F232's substance re-verifies: the ledger row at `docs/port/COMMONALITY.md:236`
does carry the parenthetical the line asks to replace, and py's
`project_config_file` at the pin has no parent walk (`Y02`). F247's disposition is
the careful one: accepted, offered as the owner's answer, with "it remains the
owner's ruling to make" and the ledger untouched, which is what an item that
cannot close an owner question is supposed to do. The four Doxa lines are
rejected on a rule I checked myself: `docs/port/README.md`'s verdict table makes
`same` the only legal origin for every `COMMON → *` verdict, and F230, F231, F232
and F234 carry origin `py-only` at `docs/port/COMMONALITY.md:234`, `:235`, `:236`
and `:238` because ts implements none of them. The underlying observation is not
discarded — it is rerouted to the C1–C6 table and the follow-on project. The
three Doxa F247 lines are subsumed with the reason stated.

**Couplings are stated as constraints, and R57 is left unopened correctly.** The
decision consumes `Paths::config_dir()` and declares no `etcetera` dependency of
its own, and it names the gap rather than papering it: R57's four accessors carry
no `$XDG_CONFIG_DIRS` list, and R57 "exposes no runtime-directory accessor and no
free-function surface" (verified at R57's lines 49–50; the `config_dir()`
handover verified at its line 66). Owning the system list in R54's own discovery
module is the better disposition on the decision's own three grounds, and the
third is the strongest: `XDG_CONFIG_DIRS` is a different environment variable
from `XDG_CONFIG_HOME`, so no second authority for R57's variable is created and
an owner-accepted decision stays shut. `raw/opus.md:1019` itself calls the choice
R57's and records it "as a coupling rather than a decision", so the decision
represents its strongest raw report faithfully. What it does not do is put that
dissent where it says it puts it (JF-2).

## Completeness

**Fields and structure.** The four H2 sections — `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines` — match the accepted siblings R53 and R55
exactly, `### Principles and implementation` is present and nonempty, and the
`re-verify:` line is a single unfenced line with seven named triggers. The
`### Members` H3 requirement in `docs/planning/p02/acceptance-schema.md` governs
*raw answers*, not `DECISION.md`, so its absence here is not a defect.

**Parameters.** I recomputed the byte-identity independently of `check.sh`, by
extracting each registry value from `docs/port/PARAMETERS.md` and each `- assumes`
value from the decision and comparing them as strings: all five match exactly, at
118, 4, 27, 17 and 4057 bytes — the same byte counts `P01`–`P05` print. R54 owns
no parameter, which the prompt's empty `- owns:` line, the registry's owner column
and `research/CLAUDE.md`'s `owns: —` all confirm. The single consumed parameter is
R67's, as the prompt's `- consumes:` line requires. The `No CONFLICT:` paragraph
is accurate down to the distinction it draws: Opus says "No `CONFLICT:` line",
Doxa/OpenAI "No `CONFLICT:` identified", Doxa/Perplexity "no `CONFLICT:` lines are
required", and the Gemini twin contains no such string, recorded as an absence
rather than a statement. I verified all four.

**Fitness gates.** Gate 1 is `inapplicable` under the owner ruling of 2026-09-12,
whose text I read at `docs/port/OWNER-REVIEW.md:47-59` ("Fitness gate 1 … is
struck from every item's evaluation"), so the decision's handling is correct and
not a silent omission. Gates 2–6 are marked `inapplicable — no crate is added by
this member` for the two `std` members, deferred to R57 for `etcetera` with the
F247-relevant parts re-verified here (`E02`–`E04`), and deferred to R60 for
`clap` 4.6.6, which R60's decision does pin. `directories` 6.0.0 is the one
gate exclusion and the reason is stated twice over.

**The empirical section claims what the log shows.** I counted the log's
top-level `PASS` lines: 64, against `failures=0 skipped=0`, and the group table's
own arithmetic (9+5+4+3+2+6+4+4+4+12+6+3+1+1) reaches the same 64. Thirteen
snapshot files are named in the decision and thirteen exist in
`review/evidence/snapshots/`. `check.sh` has no check that cannot fail: `pass`,
`fail` and `skip` are called in the enclosing shell, no assertion is fed from the
tail of a pipeline, `FAILURES` gates the exit status, and the one pipeline in the
script (`Y02`) is a condition rather than a counter. The reproducibility claim is
stated narrower than "reproduces forever", names the three live-counter lines
(`F03`, `F04`, `F06`) that will move, and states the comparison rule. Every figure
in both tables carries its endpoint and the retrieval date 2026-09-17, and the
`cfgmatic-paths` GitHub figures are `inapplicable — not hosted on GitHub` with the
GitLab URL given.

**Carried and unproven material is labelled.** The six-project layering-crate
census, the adopter manifest line numbers, `etcetera`'s issue responsiveness
(median 0.27 days over three answered, one unanswered), its maintenance verdict,
its `unsafe` posture, its `cfg-if`-only closure, `config` 0.15.20's default
feature list and five other maintenance verdicts are listed as carried from
`raw/opus.md` and not re-derived, and I confirmed each is that report's own claim
at its stated date. The "no binary-size or compile-time measurement was taken by
any engine" sentence is true of all four reports. `## Engines` marks Codex
**ABSENT** with the owner direction (`W1-CODEX`) *and* the mechanical cause
(`raw/codex-exit.txt` is `1`; the transcript ends "You've hit your usage limit"),
and states the resulting loss of confidence on `J3` and `J4` specifically. That is
an honest absence, not a quiet one.

## Findings

**JF-1 (blocking) — the decision states a false revision for the sibling its
central settlement depends on.** `## Decision` says "R55 (two-phase loader, no
added crate, revision 2 under judgment)" and Disagreement 1 says "R55 is at
revision 2, which publishes the loader as …". R55 is at **revision 3**: its
decision's first line reads "(bundle, Focused) — decision (revision 3)", and that
revision landed as commit `439da7d` at 2026-09-17T08:23:21-07:00, thirteen minutes
before this item's synthesis commit `0bf66ee` at 08:36:01. The decision's own
check `D00b` pins `5d358c1fda2a5ff2782b916f3ca81cf52bbbafd75748774b114345c72a6edd9b`,
which is revision 3's current sha256 — so the synthesis hashed revision 3 and
described it as revision 2. Two further consequences are recorded wrongly: the
`re-verify:` trigger "**R55 being revised** in a way that changes the
sanitize-then-merge sequence" had already fired before publication, and
Disagreement 1 settles against Opus on the ground that its inputs were "one
revision stale", which is the same defect this sentence commits. The substance
survives — I read revision 3: it states "**The recommendation does not move**",
and the three sentences `D01`–`D03` assert are present in it verbatim (its lines
483, 560 and the F238 finding) — so nothing downstream of the sequence changes.
The repair is to name revision 3, say that its revision note preserves revision
2's recommendation and the three cited sentences, and restate the trigger as a
future revision past revision 3.

**JF-2 (blocking) — a promised record of a live architectural dissent does not
exist.** The R57 coupling bullet says of the fifth-`Paths`-accessor disposition:
"`raw/opus.md` prefers the other disposition — a fifth `Paths` accessor — on a
single-authority argument; that is recorded under `## Engines` as a disagreement."
`## Engines` carries six numbered disagreements — the merge location, a layering
crate, which crate resolves the user tier, the `etcetera` version, the project
tier's shape, and extra tiers and owned parameters — and none of them is this one.
The word "accessor" does not occur anywhere in `## Engines`; the only "fifth" in
that section is Doxa/Perplexity's fifth *file tier*, which is a different subject.
The dissent is disclosed in the bullet itself, so this is a broken cross-reference
rather than a suppression, but the reference is load-bearing: it tells the owner
where to find the argument for the disposition the decision declines, on a choice
the decision itself says is R57's to make. The repair is either a seventh
disagreement in `## Engines` or a correction of the sentence to say the dissent is
recorded here, in this bullet.

**JF-3 (non-blocking) — the Doxa/OpenAI parameter declaration is miscounted and
misnamed.** Disagreement 6 says "Doxa/OpenAI declares four owned parameters
(`config-discovery-scopes`, `config-selector-precedence`, `project-search`,
`project-config-path`)". That twin's answer-level `### Parameters` section
declares **eight**: `config-discovery-scopes`, `system-config-path`,
`system-config-order`, `user-config-path`, `project-config-path`,
`merge-semantics`, `config-selector-env-alias` and `config-selector-precedence`
(`raw/doxa-openai.normalized.md:745-759`), and `project-search` is not among them
— it appears only as a member-level line at `:401`, alongside seven further
member-level `owns` lines. The disposition is unaffected and if anything
understated: eight registry parameters from an item whose prompt carries an empty
`- owns:` line are more out of contract, not less. The repair is the count and the
list.

**JF-4 (non-blocking) — a quotation is attributed to the wrong line of
`docs/port/BASELINE-REVIEW.md`.** The F247 disposition paragraph reads:
"offered to the owner as the answer to the open question at
`docs/port/BASELINE-REVIEW.md:113` — 'whether py's absoluteness check
(`src/py_launch_blueprint/core/paths.py:73`) is part of the inherited contract or
a py-only nuance'". That sentence is verbatim from **`:193`**, in the owner-questions
discussion of which item carries the XDG constraint. Line `:113` is the F247
adjudication row; it cites py at `paths.py:65-75`, contains neither the quoted
sentence nor the `:73` pin, and its status column reads "blocked pending R54". The
citation is defensible as the row where the disposition is pending; the quotation
attached to it is not. The carried Opus `BASELINE-REVIEW:` line also says `:113`
and must **not** be edited — it is required to be byte-identical to
`raw/opus.md:232`, and it is. The repair is confined to the decision's own prose:
attribute the sentence to `:193` and keep `:113` for the pending row.

## Assessment

The recommendation does **not** move under any finding. Nothing here touches the
six-rung chain, `etcetera` 0.11.0 reached through R57's `Paths`, the two `std`
resolvers, the `clap` `env` attribute plus emptiness filter, or the recursive
merge over R55's per-layer-sanitized `toml::Table`s. JF-1 corrects a revision
label whose underlying sequence is unchanged in the newer revision; JF-2 moves or
corrects a cross-reference; JF-3 and JF-4 correct a count and a line citation.
All four are text repairs against artifacts already in the run.

The decision is, on everything else I checked, unusually well grounded: the
standard's text is quoted exactly, the one architectural judgement that a
reasonable owner could weigh differently is flagged as a judgement with its
runner-up conceded to be correct, the boundary rule was executed rather than
asserted with its approximation disclosed, the sibling quotations are real, the
carried material is labelled, and the missing adversarial engine is recorded with
both its owner direction and its mechanical cause. What fails is the same class of
thing in all four findings — a stated fact about another document that the other
document does not carry — and in a programme whose settlements turn on exactly
that kind of precision (Disagreement 1 is won on it), the bar has to be the same
in both directions.

One observation, not a finding: A1's secondary ground says "`config`'s default
feature set pulls four parsers the template will never use" while naming `config`
0.15.25 as the candidate, and the feature-list reading it rests on is carried from
`raw/opus.md`'s reading of **0.15.20**'s manifest, as the unproven list states.
The decision already calls the ground "secondary and real but not decisive" and
A1's rejection stands on scope alone, so nothing depends on it; naming the version
at A1 would close the gap.
