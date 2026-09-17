decision-sha256: eab34b2d2c121b6c5a59f13b1e7b5f7f2383333cbc6c04f0fe27bb1a8e76bf6a
actor: audit-fable-2026-09-17T020714Z-62a04ad8fee1-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

Judgment auditor for R55 (`config-error-tolerance`, kind `bundle`, Focused tier, owning no
parameter), revision 1, run `2026-09-17T020714Z-62a04ad8fee1`. I produced none of this item's
artifacts. The hash above was taken before I opened the decision and re-taken immediately
before writing this file; it was unchanged across the audit, so this report binds one version.
The empirical (Codex) audit is deferred — the Codex account is out of usage — so this is the
only audit on the decision, and I ran the citation and source checks an empirical lane would
otherwise duplicate: the org CLI Design Standard at its pinned blob, the py source at
`b08bccfb`, the ts source at `cb1cbcb2`, the ledger, the registry, R67's published text and
both raw reports. I did not rerun `evidence/check.sh`.

## Principle and agreement level

The four principles are stated at the right level and each carries pinned evidence.

P1 — "A configuration fault must never leave the user unable to repair it" — is declared at
**policy** level ("all three repos must satisfy it; the mechanism may differ"), which is the
correct level and not a level chosen for convenience: the decision then spends a paragraph
showing that py's own stated rationale for P1 (`config set` needs a writable target) does
**not** carry into Rust, and replaces it with a narrower one that does (an env-supplied path
fixed in a shell profile, container image or CI job). That is the opposite of preserving a
principle by asserting it. The py citation is exact. `b08bccfb:src/py_launch_blueprint/core/settings.py`
lines 141-145 are the `settings_from_layers` docstring, reading "Invalid values are **dropped
with a warning** rather than raised: config must never brick the CLI — the user needs
``config set``/``config path`` working in order to repair the file."

P2 — "A degraded load is never silent, and the warning names the file and the key" — is
declared as an **observable acceptance criterion** and is the place the decision departs from
py deliberately and says so: py's `_read_explicit` returns `{}` for a missing explicit path
with no warning (`config.py:114-115`, verified: `if not path.exists():` / `return {}`), and
this decision warns. The standard half of P2 is verified at the pinned blob — R5.8 requires
"validate config files with precise file/key diagnostics" and its anti-pattern line is
"❌ silently ignoring bad config; corrupting config during parallel writes".

P3 (document-level judged by provenance, value-level by granularity) is declared **derived**
and labelled as such rather than attributed to a source. P4 (library decides, binary prints)
is declared an **architectural pattern** with the type difference between `list[str]` and
`Vec<ConfigWarning>` named as permitted variation. The "must agree / may vary" split is
substantive: what must agree is the three-way classification (missing, unparsable,
invalid-value are distinct cases with distinct answers) — "the thing ts collapsed and py did
not" — and what may vary is drop granularity, warning carrier and mechanism. The ecosystem
difference is argued from a real capability asymmetry (pydantic's `ValidationError.errors()`
and zod's `safeParse(...).error.issues` return a collection from one pass; serde's derive
returns the first error and no value) and is correctly classified as a mechanism difference
at a level where agreement is not required, not as a capability gap.

Ledger handling is right. F235, F236 and F238 are settled; F237 is explicitly **not** reopened,
and I confirmed the ground the decision gives for that: `docs/port/COMMONALITY.md:241` carries
F237 as origin `same`, `COMMON → REUSE`, with `—` in the `Item` column. Clause 2's explicit
limb is the Rust behavior that keeps that row true rather than a re-decision of it.

## Design and evidence

**The `CONFLICT:` ruling is correct, and rejecting it was the right call.** codex's line is
quoted verbatim — I diffed it against `raw/codex.md:155` character by character and the block
at `:437` is identical, including the inner backticks. The rejection rests on R67's own text,
not on the decision's preference between engines. R67 publishes, three paragraphs above the
catalogue, the sentence the decision quotes: "Each case gets its own catalog entry so R54–R56
can route to any of them without inventing a code. R55 and R56 own whether a given condition
is tolerated, warned about, or fatal; this item only guarantees the entry and the code exist."
I read it in `research/topics/67-error-and-exit-code-contract/DECISION.md` at lines 272-274 and
the decision reproduces it exactly. That sentence is dispositive: codex read a catalogue entry
as a mandate about when the fault is raised, and R67 says in terms that it is not one. Carrying
the `CONFLICT:` forward would have reopened an owner-accepted prerequisite to obtain a
narrowing R67 had already delegated. Two further things make the ruling sound rather than
merely convenient. First, the *substance* of codex's ask is granted, not discarded: the
decision reserves `RSLB203` for the non-localizable case and tolerates the localizable one,
which is exactly the narrowing codex wanted, taken under R55's own ownership. Second, the
decision checks the other direction too — the strict alternative to clause 1 would route to
`RSLB201`, whose published row covers "usage/parse (including the CLI parser's own errors)" —
so neither branch of the open question needs a new row. Nothing in the decision's design
requires an R67 revision.

**The five engine splits are settled on grounds, and two go against the engine that executed
more.** Disagreement 2 (a bad *value* in an explicit layer) is settled for codex against
opus's rule, on three pieces of evidence, and the decision names it as "the one place in this
decision an owner could reasonably decide the other way" with the cost stated as one branch.
I checked the evidence independently and it holds, more strongly than the decision claims.
`COMMONALITY.md:242` carries F238 with no layer qualifier. py's `_discovery_paths` docstring
reads "``--config`` collapses discovery to that single file; otherwise the system → user →
project layers apply", and its body is `if config_file: target = Path(config_file); return
target, [target]` — so the explicit file is the sole file layer and `settings_from_layers`
tolerates a bad value inside it, which is what the decision asserts. Decisively, py's own
`load_config` docstring states the whole rule this decision derives: "Tolerant by design —
with one exception: an *explicit* ``--config`` file that exists but cannot be parsed raises
:class:`ConfigError`. Discovered layers and invalid values degrade to warnings." That is
py drawing the document-level/value-level line exactly where clause 2 and clause 3 draw it.
The decision does not quote it (JF-4). Disagreement 3 (mechanism) is settled for opus by
execution rather than argument; Disagreement 4 (where warnings are emitted) keeps codex's
outcome and takes opus's stronger reason, with `cargo` doing the same thing; Disagreement 5
(warn on a missing explicit path) is settled for opus on the standard, and R5.7's anti-pattern
line at the pinned blob does read "❌ no way to see why a setting took the value it did".

**The synthesis corrected a raw claim rather than carrying it.** opus's rule 5 was a blanket
prohibition — `raw/opus.md:174`, "must not use `#[serde(flatten)]`". Re-measurement narrowed
it to fallible fields inside the flattened target (H1) and showed a leaf outside it keeps a
prunable path (H2), and the decision carries the narrower rule and says which claim it
corrected. That is the behavior the role doc asks for and it is rare enough to note.

**The spike is recorded with enough provenance to count as evidence.** `cargo 1.98.0
(797e8a9bc 2026-08-05)` and `rustc 1.98.0 (88d9e12ae 2026-08-18)`, `Darwin arm64`, package
`r55-spike` at edition 2024, source committed as `evidence/spike/` as the check's *input* and
copied to a temporary directory to build, with the log printing "spike: r55-spike, edition
2024, built outside the repository". Nothing was scaffolded in-tree and the decision says so.
The lockfile resolutions the decision cites (`serde` 1.0.229, `toml` 1.1.6+spec-1.1.0,
`serde_path_to_error` 0.1.20, `serde_ignored` 0.1.14) are printed in the log. The sixteen
assertions in the decision's table match the log's sixteen `PASS` lines one for one:
A1–A4, B1, C1, D1, E1–E2, F1, H1–H2, M1–M3, N1.

**M1/N1 and H1/H2 are stated within what was measured**, with one calibration exception
covered by JF-1. M1 (`output.format = Json`, the lower layer's valid value surviving) and N1
(`output.format = Text`, the built-in default, losing it) are exactly what the log prints, and
the decision's claim about them is the modest one: sanitize-then-merge keeps the value and
merge-then-drop loses it, on identical two-layer inputs. The decision does not inherit opus's
stronger "that final pass cannot fail by construction"; it reports M3, that the pass did not
fail. H1 and H2 are stated as measured and the rule drawn from them ("no **fallible** field
inside a `flatten` target") is the narrow one the measurement supports.

**The contingency on R53 is a coupling, not a decision for R53.** The recommendation says
`serde_ignored` is adopted "**contingent on R53**, which owns schema validation and may decide
unknown-key handling itself; nothing else here depends on it", and unproven row 10 records the
question as "genuinely open" with "No load-bearing claim rests on it". The constraints on
sibling items are collected under a heading that declares their status — "stated as constraints
rather than as assumptions, because none of them is a parameter yet" — and each has its
consequence recorded as a `re-verify:` trigger rather than as an instruction. That is the
correct form.

**Practice and alternatives.** Five architectural alternatives are compared on four columns
before any library is named, and B is selected on a discriminator (per-key drop *with* a
machine-readable key name, leaving R52/R53/R54 free) rather than on popularity. E (`figment`)
is kept as the ranked runner-up architecture with its condition stated, and its two-year push
gap is explicitly called "a maintenance **trigger**, not a verdict" that was not investigated
to a verdict because the design does not select it — an honest statement of an unfinished
investigation rather than a disguised exclusion. The four reference implementations are
chosen with a stated reason each, and the decision does the harder thing with the split it
finds: cargo errors on a missing `--config` path where ripgrep warns, and the decision explains
cargo's behavior away as an artifact of `--config` also accepting `KEY=VALUE` rather than
counting it as a vote.

## Completeness

The H2 set is exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, in
that order, with `### Principles and implementation` nested inside `## Decision` and no
`## Supersedes` (correct for a first revision). `re-verify: 2027-03-17, or earlier on any of —`
is the last line of `## Decision`, with nine named events.

The `## Parameters` grammar is right and I checked it mechanically rather than by eye. Five
`- assumes` lines, zero `- owns` lines (matching the prompt's empty `owns:` field), and each
value byte-identical to its `docs/port/PARAMETERS.md` row: `msrv-policy` 118 bytes,
`rust-edition` 4, `target-os-matrix` 27, `license` 17, `error-taxonomy-exit-codes` 4057. I
parsed the registry table and compared the strings; all five are equal, so the packaging
validator's byte-for-byte comparison will pass. No value is wrapped in backticks and no line
carries commentary; `error-taxonomy-exit-codes` begins with `` `error-contract/v1` `` because
the registry value itself does. The prose on how each parameter bears on the decision sits
after the list, where the role doc puts it.

Fitness gates are answered per member with gate 1 recorded as `inapplicable — owner ruling
2026-09-12 (Q7.B)` for every candidate, which matches `docs/port/OWNER-REVIEW.md`'s
"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by
Q7.B)". Nothing is excluded on licence and the SPDX strings are reported as figures only. I
raise no licence finding. The two fitness exclusions (`serde_with`'s `DefaultOnError`,
`figment`) are labelled as exclusions on fitness rather than by gate, which is the distinction
the prompt requires. Maintenance state is `stable-quiet` for both members with the release gap
treated as a trigger and then investigated — `pushed_at` on both repositories, neither
archived, no advisory, builds on current stable, and cargo's own pin — and the rubric's
`at-risk`/`dormant` conditions are checked and found absent rather than assumed.

Figures carry endpoint and retrieval date. crates.io versions, `created_at`, `license` and
`rust_version` come from `GET https://crates.io/api/v1/crates/<name>/versions` retrieved
2026-09-17 and are asserted against committed snapshots rather than the live endpoint;
download counts come from `GET https://crates.io/api/v1/crates/<name>` and are explicitly
"reported, never asserted" because they move daily; GitHub figures name
`GET https://api.github.com/repos/<owner>/<repo>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, with the reason
they are outside the script stated (the script must not require a token). The
issue-responsiveness rubric is answered `inapplicable — fewer than 10 issues exist` rather
than silently omitted, and `open_issues_count` is explicitly not used.

The log supports the counts the decision cites. `evidence/check.log` ends `PASS=25 FAIL=0
SKIP=0`, every check asserts on content, and `C06-cli-standard-absent` is described as skipping
by name on a machine without the standard rather than passing vacuously. `evidence/rerun.diff`
is a one-line diff in the `date (UTC)` header, and the decision states the reproducibility
claim at exactly that width — "Every assertion line, every count and every figure is
byte-identical across the two runs" — rather than claiming a byte-identical file. The volatile
sources are snapshotted into the evidence directory and read from there, which is what makes
that claim keepable.

The ten unproven rows are honest and each carries what would prove it, including two that cut
against the decision's own convenience: `ubuntu-latest` was not exercised and the claim is
labelled "structural, not measured"; the `unsafe` posture is "**carried from the opus raw
report, not re-audited here**", and the same words appear in the gate-3 cells rather than only
in the unproven list. The RustSec 404s are labelled "interpreted, not asserted" with the
`anyhow` control named. No performance number is claimed, and the row says so in terms.

## Findings

**No unresolved findings.** The six below are recorded observations that do not block
acceptance. None changes a gate result, a ledger disposition, a parameter, the `CONFLICT:`
ruling or the recommendation.

1. **JF-1 (non-blocking) — the F1 case that keeps `RSLB203` from being orphaned is a
   constructed value, not one a TOML file can produce, and the decision states its reach a
   little past that.** Clause 3 reads, at `:53`–`:55`: "Measured non-localizable cases are a
   root-level shape fault (`## Empirical check`, F1) and a leaf inside a `#[serde(flatten)]`
   target (H1)." The spike table at `:413` reads: "| F1 | a root-level shape fault | not
   localizable to a prunable leaf → fatal `RSLB203`; this is the branch that keeps `RSLB203`
   from being orphaned |", and Disagreement 1 at `:453` says "`RSLB203` keeps a real target
   (measured: case F1, and R53's cross-field invariants)". I read the spike. Case F does not
   parse a document: `evidence/spike/src/main.rs:259` is `let doc: toml::Value =
   toml::Value::Integer(5);`, where every neighbouring case parses TOML text — case E at
   `:241` is `parse("output = 5\nverbose = true\n", "e.toml")`. A parsed TOML document always
   has a table at its root, so F1 bounds what `sanitize()` does with a root that is not a
   table rather than exhibiting a fault a user's file can cause; and H1, the other listed
   case, is forbidden by the decision's own rule two paragraphs earlier. Within the
   recommended design the file-reachable `RSLB203` target is therefore the one the same
   sentence already names — R53's cross-field invariants, "they route to `RSLB203` when R53
   makes them fatal" — which is contingent on R53 and stated as such. **The `CONFLICT:` ruling
   is untouched by this**: it rests on R67's delegation sentence, and R67 guarantees the entry
   exists whether or not this item reaches it, so an under-exercised row is not an argument for
   codex's reading. Nor does any routing rule change. **What resolves it:** label F1 a
   synthetic bound on the sanitizer rather than a measured fault class, and say that
   `RSLB203`'s practical target under this design is R53's invariants.

2. **JF-2 (non-blocking) — two figures are asserted from artifacts the committed log does not
   print.** First, the archive rerun, at `:352`–`:357`: "It locates the repository root by
   looking for `docs/port/PARAMETERS.md` rather than `.git`, so it reruns from a clean `git
   archive HEAD` extraction. That was executed, not assumed: `git archive HEAD | tar -x -C
   "$(mktemp -d)"` followed by the extracted copy of the script produced the same `PASS=25
   FAIL=0 SKIP=0` and exit `0`." `review/evidence/` holds one run log and `rerun.diff`, whose
   own header describes it as `diff evidence/check.log <rerun>` of an immediate in-place
   rerun; neither is the archive run. I could not falsify the claim and it is self-consistent
   — `evidence/check.sh` was committed in `3475e71` at 21:44:37 local, before the logged run's
   own header time of `2026-09-17T04:46:58Z` (21:46:58 local), so a `git archive HEAD` at that
   point would have contained both the script and `evidence/spike/`. Second, gate 6 at `:240`
   ("the spike lockfile holds 20 packages") and `:404` ("in a 20-package graph"): the log
   prints the four resolved dependency versions but no package count. I counted the committed
   `evidence/spike/Cargo.lock` myself — exactly 20 `[[package]]` stanzas, so the figure is
   right. **What resolves it:** save the archive run as `evidence/check-archive.log`, and add
   the lockfile package count to the script's printed output so the figure is read rather than
   recomputed by a reader.

3. **JF-3 (non-blocking) — a check citation covers only the first half of the sentence it is
   attached to.** Disagreement 5, at `:497`–`:499`, reads: "**Settled for opus**, on the
   standard: R5.8 names `❌ silently ignoring bad config` as the anti-pattern and R5.7 exists
   so a user can see why a setting took the value it did (verified, C06d)." Check `C06d`
   asserts only the R5.8 anti-pattern line; `C06` has no R5.7 assertion, and no other check
   reads R5.7. I verified the R5.7 half at the pinned blob `f9de0437…`, where the rule's
   anti-pattern line reads "❌ no way to see why a setting took the value it did" — so the
   claim is true and the settlement stands. **What resolves it:** add an R5.7 needle to `C06`
   or move the citation onto the clause it covers.

4. **JF-4 (non-blocking) — the branch the decision itself flags as the owner's most reasonable
   place to differ rests partly on an uncited claim, and stronger evidence for it was left
   out.** Disagreement 2, at `:464`–`:466`: "F238's ledger row carries **no layer qualifier**
   (verified, C04d), and py's `settings_from_layers` validates the **merged** dictionary —
   under py's own `--config` handling the explicit file *is* the sole file layer, so py
   demonstrably tolerates a bad value in an explicit file". The ledger half is checked; the
   `--config` collapse half carries no file:line anywhere in the decision, although it is the
   step that turns a fact about merged validation into a fact about explicit files. It is true:
   `b08bccfb:src/py_launch_blueprint/core/config.py:124-139`, docstring "``--config`` collapses
   discovery to that single file", body `if config_file: … return target, [target]`. The same
   file at `:147-150` carries the better citation the decision never uses — py's `load_config`
   docstring, "Tolerant by design — with one exception: an *explicit* ``--config`` file that
   exists but cannot be parsed raises :class:`ConfigError`. Discovered layers and invalid
   values degrade to warnings" — which states clause 2 and clause 3's division in py's own
   words and would close the disagreement outright. **What resolves it:** cite `config.py:124-139`
   for the collapse and quote `config.py:147-150` beside it.

5. **JF-5 (non-blocking) — three citation slips, none altering a conclusion.** (i) At `:130`–
   `:131` the decision writes "its code comment claims `click.Path(exists=True)` parity
   (`ts: src/lib/config.ts:153`)"; at `cb1cbcb2` that comment is line **154**, and `:153` is
   the `if (!fs.existsSync(options.configPathFlag)) {` it sits inside. The underlying point is
   sound and I verified the part the decision relays second-hand from
   `docs/port/DIVERGENCE-ANALYSIS.md:297` (which asks R55 to re-check rather than rely on the
   note): py's option is declared `type=click.Path(dir_okay=False)` at
   `b08bccfb:src/py_launch_blueprint/cli/options.py:102-109`, with no `exists=True`. (ii) At
   `:98`, `core/config.py:102` is cited for where py returns a warning string for an
   unparsable discovered layer; `:102` is the `except` clause and `:103` is the return that
   carries the warning. (iii) At `:480`–`:481` codex is quoted as admitting "assumes R53
   validation = independently callable declared-field validation", where `raw/codex.md:155`
   continues "plus a separately classified cross-field invariant result"; the truncation
   carries no ellipsis and drops the clause that shows codex also separated the invariant case.
   **What resolves it:** correct the two line numbers and close the codex quotation with an
   ellipsis. A fourth, smaller point of the same kind: the four reference implementations'
   file citations are pinned to each repository's default branch ("file contents read at
   default branch through `gh api repos/<o>/<r>/contents/<path>` the same day", `:170`–`:171`),
   so the line ranges will drift; a commit sha would make them re-readable later.

6. **JF-6 (non-blocking) — both `BASELINE-REVIEW:` lines are rendered in the decision's own
   words while formatted as the literal finding.** codex's line at `raw/codex.md:17` reads
   "validate each layer's leaves before precedence merge rather than Python's merge-then-pop —
   pinned Python code merges before removing the invalid key, while toml::Value supplies the
   required leaf boundary"; the decision at `:209`–`:213` reads "validate each layer's leaves
   before the precedence merge rather than py's merge-then-pop — pinned py code merges before
   removing the invalid key, while an untyped document supplies the required leaf boundary".
   The substitution of "an untyped document" for `toml::Value` is defensible — R52 owns the
   representation — and generalizing is the safer direction, but the line is the artifact that
   travels to `docs/port/BASELINE-REVIEW.md`. opus's F237 line is reworded the same way
   (`git -C ~/c/py-launch-blueprint show b08bccfb:…` shortened to `b08bccfb:…`, "owner-accepted,
   consumed here" to "owner-accepted and consumed here"). Feature IDs, dispositions, evidence
   and affected-item lists are preserved in both, and both are correctly marked accepted and
   carried. **What resolves it:** quote each raw's line verbatim and put the generalization in
   the disposition sentence underneath.

**A forward coupling, recorded here only so the owner sequences two acceptances rather than
taking them as independent.** This is not a defect in the decision: R53's decision did not
exist when R55's was written. R55's `review/DECISION.md` was committed at `3475e71` 21:44:37
and corrected at `52e5525` 21:47:21; R53's was committed at `9b5cdbc` **21:57:33**, thirteen
minutes later, and R55's prompt directs it to treat R53 as open. R53 revision 1 recommends
"A per-key deserialization loop over R52's `toml::Table` — each known key deserialized
independently, failures pushed onto `Vec<Issue>`, survivors written into the config value",
and its log shows that loop producing leaf-level dotted paths in a single pass — `S81`
`output.format`, `S82` `output.color`, `S83` `output.limit`, with `S84` a surviving partial
value — and it adds "Under the per-key loop, unknown-key *detection* is free". That is close to
the shape R55 rejects as alternative D, on the ground at `:141` that it "drifts from whatever
R53 selects". Three things follow. R55's only stated constraint on R53 — "**R53** must validate
through `serde::Deserialize` for the prune loop to localize failures" — is satisfied by R53's
per-key `Deserialize` calls, so there is no contradiction to resolve. R55's four-clause rule is
untouched, including clause 4: R53's loop over a *merged* table is exactly the N1 order R55
measured as lossy, so the per-layer sequence R55 fixes is still needed and is still R55's to
fix. What may move is the two-crate member list, since a per-key loop supplies the key path
that `serde_path_to_error` is adopted for and the unknown-key detection that `serde_ignored` is
adopted for. R55 already armed the trigger for exactly this: its `re-verify:` line names "R53
publishing (whether validation runs through `serde::Deserialize`, whether it owns unknown-key
policy and therefore whether `serde_ignored` belongs to this item…)". The trigger has fired on
schedule; it is due, not overdue, and it is the decision's own mechanism working. I also
checked R52, accepted today: it selects `toml` 1.1.6 for the typed read path and `toml_edit`
0.25.15 for the `config set` write path only, so the intermediate R55's prune loop runs over is
`toml::Value`, which R55 verified — R55's R52 constraint is met and unproven row 6
(`toml_edit::DocumentMut`) is moot for the read path. No contradiction with either sibling.

## Assessment

Approve. The recommendation follows from the evidence as written. The rule is derived from the
ledger's own split rather than from either engine's preference, and every clause is tied to a
row it settles; the library selection comes last, after five architectures are compared on a
discriminator declared before the comparison, and the selected one was executed rather than
reasoned about. codex's `CONFLICT:` against `RSLB203` is correctly rejected and correctly
*not* carried, on R67's published sentence delegating tolerated-versus-fatal to R55 and R56 —
which I read at the source rather than taking from the decision — while the narrowing codex
actually wanted is granted under this item's own ownership, so nothing about R67 needs
revising. The five engine splits are each settled on evidence, two of them against the engine
that supplied the spike, and one raw claim was measured and narrowed rather than inherited.
The spike carries toolchain, OS, edition, lockfile resolutions and an out-of-tree build
location, and its sixteen assertions match the decision's table line for line; M1/N1 and
H1/H2 are stated within what they measured. `PASS=25 FAIL=0 SKIP=0` is what the log ends with,
and the reproducibility sentence is stated at the width the one-line `rerun.diff` supports.
The contingency on R53 is a coupling with its consequence in the `re-verify:` line, not an
instruction to R53. The `## Parameters` grammar and the H2 set are correct, the five
`- assumes` values are byte-identical to the registry by mechanical comparison, and the ten
unproven rows are honest — two of them conceding that a gate cell rests on carried rather than
reproduced work. The six findings are presentational, or concern supporting clauses whose
substance I verified true by going to the py source, the ts source and the pinned standard
blob. **The recommendation does not move under any finding**: `serde_path_to_error` 0.1.20 and
`serde_ignored` 0.1.14 with R67's `thiserror`, the provenance-aware two-phase loader, the
four clauses and the routing to `RSLB104`/`RSLB202`/`RSLB203` all stand exactly as written.
The one thing that may move it is R53's publication thirteen minutes after this decision was
written, through the trigger this decision itself names.
