# 2026-09-17 — R55 — config-error-tolerance (bundle, Focused) — decision (revision 3)

## Decision

**Revision note (revision 3).** Revision 2 (sha256 `b4ad24de…`) was **rejected**
by its round-2 judgment audit (`review/audit-fable.md`) on one blocking finding.
**The recommendation does not move**: the provenance-aware two-phase loader with
no R55-added crate, the four clauses, the `RSLB203` reservation, the `CONFLICT:`
rejection, the no-`flatten` rule, the R8a requirement, the ten acceptance criteria
and the five parameter lines all stand exactly as revision 2 wrote them. The audit
found the crate drop grounded and confirmed the R8a reading at R53's own source.
What failed was the harness.

**JF-7 (blocking)** — "four of revision 2's checks cannot fail the run, and the
summary the decision cites undercounts its own script by four". Granted, and
reproduced here rather than accepted on report: `evidence/check-r2.sh` fed four
checks (`JF4a`, `JF4b`, `JF5a`, `JF5b`) from the tail of a pipeline, whose last
element bash runs in a subshell, so their `ok`/`no` incremented a copy of
`pass`/`fail`. The counters lost four increments — the log's 22 script-level
`PASS` lines against a printed `PASS=18` — and, the real defect, a **failing** one
of the four would print `FAIL` and still leave `fail=0`, so the closing
`[ "$fail" -eq 0 ]` could not trip. That is "a check that cannot fail is not
evidence", and two of the four underwrite the evidence revision 2 uses to narrow
Disagreement 2. Repair: a **new** `evidence/check-r3.sh` feeds `assert_stream`
from a here-string. `evidence/check-r2.sh` and `evidence/check-r2.log` are **not
edited**; they stay as the record of what revision 2 ran. The repair is
demonstrated, not asserted: check `JF7` proves at run time that the pipeline form
loses both counters and the here-string form keeps both, and
`evidence/check-r3-negative-control.log` forces one of the four checks to fail in
both scripts — revision 2's reports `FAIL=0` and exits `0`, revision 3's reports
`FAIL=1` and exits `1`. **JF-8 (non-blocking)** — "the sentence routing R8a denies
more than it should". Granted; the sentence is narrowed in both places it appears,
below and under `## Parameters`. **JF-9 (non-blocking)** — "two claims new to
revision 2 carry no pin of their own". Granted; the unknown-key precedent now
carries py and ts file:line pins checked as `JF9a`/`JF9b`, and the probe's helper
provenance is corrected from `:650-657` to `:649-657`, checked as `JF9c`.
**JF-10 (non-blocking)** — a stray `**` in the restored F237 line. Granted;
deleted, and the line re-diffed against `raw/opus.md:227`.

**Revision note (revision 2).** Revision 1 (sha256 `eab34b2d…`) was **approved** by its round-1
judgment audit (`review/audit-fable.md`, `verdict: approve`, `unresolved-findings:
none`). This revision exists for the forward coupling that audit recorded, and it
**moves the recommendation**. R53 (`config-schema-validation`) published thirteen
minutes after revision 1 was written and is now at revision 2
(`research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md`, sha256
`be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9`,
judgment-approved). It selects a **per-key deserialization loop over R52's
`toml::Table`**, publishing `Unvalidated::validate(self) -> (ConfigFile,
Vec<Issue>)` where `Issue { path, message, span }` carries a leaf-level dotted
path, and it states that under that loop "unknown-key *detection* is free (any key
in the table the loop did not consume)". Those are precisely the two jobs revision
1's two crate members were adopted to do. Revision 1's own `re-verify:` line named
this trigger; it has fired. Measured (`## Empirical check`, checks D05a–D05b and
probe cases R1–R4), R53's loop reports **the same unknown-key set as
`serde_ignored`, at both nesting depths**, and its `Issue.path` **addresses a
prunable leaf in the same `toml::Table`**, so neither crate adds information R53's
mechanism does not already produce. **The member list therefore moves from two
crates to none.** The four-clause rule is unchanged and was re-measured on R53's
mechanism (R5, R6). Two new constraints on how P03 writes that loop are added, both
measured (R7, R8).

The six non-blocking findings of the round-1 audit are folded in as follows.
**JF-1** — "label F1 a synthetic bound on the sanitizer rather than a measured
fault class": done in clause 3, and the point is now moot for the recommended
design, which no longer has a prune-and-retry pass to bound. **JF-2** — "save the
archive run as `evidence/check-archive.log`, and add the lockfile package count to
the script's printed output": the archive run is saved, and the package count is
asserted by the new script (`JF2a`, `JF2b`); revision 1's `check.sh` is not edited,
per the revision rules. **JF-3** — "add an R5.7 needle to `C06`": added to the new
script as `JF3`, and the Disagreement-5 sentence is split so each half carries its
own citation. **JF-4** — "cite `config.py:124-139` for the collapse and quote
`config.py:147-150` beside it": both are now cited and quoted, at the ranges this
revision verified through the pin (`:127-128` and `:148-150`), and checked as
`JF4a`/`JF4b`. **JF-5** — "correct the two line numbers and close the codex
quotation with an ellipsis": `ts: src/lib/config.ts` `:153` → `:154` and py
`core/config.py` `:102` → `:103`, both checked (`JF5a`, `JF5b`); the codex
quotation now runs to the end of its clause; and the four reference
implementations now carry commit shas rather than a bare default-branch
reference. **JF-6** — "quote each raw's line verbatim and put the generalization in
the disposition sentence underneath": both `BASELINE-REVIEW:` lines are restored
verbatim from the raws, with every change moved into the disposition beneath.

*History.* Revision 1, 2026-09-17: first synthesis from `raw/codex.md` and
`raw/opus.md`; recommended `serde_path_to_error` 0.1.20 + `serde_ignored` 0.1.14 +
R67's `thiserror`; rejected codex's `RSLB203` `CONFLICT:`; approved by
`review/audit-fable.md` with six non-blocking findings. Revision 2, 2026-09-17:
reconciled against R53 revision 2; member list moved to no R55-added crate; two
measured constraints added; JF-1 through JF-6 folded in; rejected by
`review/audit-fable.md` round 2 on JF-7. Revision 3, 2026-09-17: the evidence
harness repaired in a new `evidence/check-r3.sh` and its gate demonstrated by a
negative control; the counts restated to what the repaired run prints; JF-8
through JF-10 folded in. Across all three revisions the `CONFLICT:` ruling, the
four-clause rule, the parameter lines and the ledger dispositions are
unchanged, and the recommendation moved exactly once, at revision 2.

**Recommendation — one stack, and R55 adds no crate of its own.** The
**provenance-aware two-phase config loader** is a pattern in the template's own
library code, composed over dependencies other items select and gate:
`toml` 1.1.6+spec-1.1.0 (R52, the untyped `toml::Table`), `serde` 1.0.229 with
`derive` (R53, the typed leaf pass), and `thiserror` 2.0.20 (R67, the library error
type). The leaf pass is R53's published `Unvalidated::validate(self) ->
(ConfigFile, Vec<Issue>)`; R55 supplies the provenance tagging, the
tolerate-versus-fatal routing, and the sanitize-per-layer step that consumes
`Issue.path`.

> Superseded wording, revision 1: "Adopt `serde_path_to_error` 0.1.20 and
> `serde_ignored` 0.1.14 in the library crate, composed with the `thiserror` 2.0.20
> that R67 already fixes, as a **provenance-aware two-phase config loader**. The
> policy itself needs no crate: R55 adds exactly those two small crates, and both
> are pure data transformations with no I/O, no global state and no async coupling.
> `serde_ignored` is recommended **contingent on R53**, which owns schema
> validation and may decide unknown-key handling itself; nothing else here depends
> on it."

The contingency resolved against adoption. `serde_path_to_error` existed to turn a
fail-fast whole-struct error into a machine-readable key path; R53's loop
deserializes one leaf at a time and knows the leaf's name at the call site, so it
never produces an unlocated error and there is nothing to locate.
`serde_ignored` existed to report keys the typed struct ignored; R53's loop already
enumerates the known keys at each level it descends, so the unconsumed set is the
complement of a list that has to exist anyway. Adding a crate to re-derive
information the selected mechanism already produces is not justified, and the
marginal dependency cost of R55 is now **zero**.

This decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends.
P03 builds the template and its CI proves the recommendation; a recommendation
that does not survive implementation is revised against this recorded research,
not researched again from scratch. What P03 must validate is listed under
`## Engines`.

**Ledger rows settled:** `F235` (explicit `--config` pointing at a missing file),
`F236` (unparsable *discovered* layer), `F238` (invalid config *value*). `F237`
(unparsable *explicit* file, `COMMON → REUSE`) is **not** reopened; this decision
records one `BASELINE-REVIEW:` against it, in `### Principles and implementation`.

**The rule, in four clauses — unchanged from revision 1, and re-measured on R53's
mechanism.** Every one of the four ledger rows follows from the first three; the
fourth is the composition order they force.

1. **Absence is not a fault.** An explicit config path (`--config`, or an
   env-supplied path) that does not exist — `std::io::ErrorKind::NotFound` — is an
   **empty layer plus a warning naming the path**, never an error. Under the org
   CLI Design Standard R5.2 an explicit `--config <path>` *replaces* the
   discovered project/user/system files and "becomes the sole config file in the
   chain", so the outcome is well-defined: the file layer contributes nothing, and
   flags, environment variables and built-in defaults still resolve normally
   (R5.1). No discovered file silently reappears. This settles **F235** to py's
   outcome.
2. **A document-level fault is judged by provenance.** "Document-level" means the
   layer could not be turned into a `toml::Table` at all: an `io::Error` whose kind
   is **not** `NotFound` (permissions, a directory where a file was named, a device
   error), or a TOML parse failure. R53 makes this boundary structural rather than
   a matter of string-matching an error message — `toml::from_str::<toml::Table>`
   succeeds or it does not — and routes the two stages to the two codes.
   - *Explicit* layer → **fatal**. Unreadable is `RSLB104` at exit `1`;
     unparsable is `RSLB202` at exit `2`. This **preserves F237**, which this item
     does not own and does not settle: F237's `Item` column is `—`, it is already
     `COMMON → REUSE`, and this clause is the Rust behavior that keeps it true.
   - *Discovered* layer → **one warning naming the file, the layer skipped, the
     exit code unchanged**. This settles **F236**, and applies only if R54 adopts
     a discovered (non-explicit) tier; if R54 adopts none, this clause has no
     target and F236 has no Rust instance.
3. **A value-level fault is judged by granularity, not provenance.** A leaf that
   R53's per-key loop rejects — right TOML, wrong value — is **dropped from its own
   layer with a warning naming the file and the dotted `Issue.path`**, in explicit
   and discovered layers alike. The load continues and the exit code is unchanged.
   This settles **F238** to py's outcome and answers the prompt's HIGH question:
   serde's derived `Deserialize` is fail-fast and cannot itself drop a key, but it
   does not force an all-or-nothing outcome — R53's loop deserializes each declared
   leaf independently, so a rejected leaf is named, not fatal, and its siblings and
   the surviving partial value come back in the same call. Three sub-clauses:
   - **Unknown keys warn and never fail, in every layer.** R53 hands this policy to
     R55 in terms ("*Whether unknown keys are tolerated* — also R55's… That tension
     is R55's to resolve, not this item's") and supplies the detection. Decided for
     warn-and-continue on three grounds: both sources tolerate unknown keys (py
     sets `model_config = {"extra": "ignore"}` on all three models,
     `b08bccfb:src/py_launch_blueprint/core/settings.py:43,52,63`; ts declares
     `z.object({…})` at `cb1cbcb2:src/lib/config.ts:37-41` with neither
     `.strict()` nor `.passthrough()`, so zod strips unknown keys by default —
     both verified at their pins, checks `JF9a` and `JF9b`), so
     failing would be a new strictness neither precedent supports; a config file
     written by a newer version of the template must not brick an older binary; and
     the standard's R5.8 example *diagnoses* an unknown key
     (`` `acme config validate` reports `.acme/acme_config.toml:12 unknown key 'default-region'` ``),
     which is a report, not an exit. Silence is what P2 forbids, and a warning is
     what removes it.
   - **A section key that is present but is not a table is a value-level fault at
     the section's own path.** Measured: R53's loop as published skips such a
     section silently, returning built-in defaults with no issue and no unconsumed
     entry (`## Empirical check`, R8a). The gap is in R53's **published loop shape** —
     it reaches a section through
     `table.get("output").and_then(toml::Value::as_table)`
     (`R53 review/evidence/verify.sh:620`, check `JF8b`), and a non-table value
     makes `as_table()` return `None`, so the body never runs and no `Issue` is
     pushed — and it bears on a row in **R53's own must-agree table**: "A value
     outside a key's allowed set is rejected, never silently coerced"
     (`R53 DECISION.md:184`, check `JF8a`), which `output = 5` under the loop as
     published does not satisfy. It also violates this item's P2. The **repair
     belongs to P03**, one line inside R53's own module, so **R53 need not
     revise** and no `CONFLICT:` arises — R53 owns no parameter to conflict with:
     the loop must push an `Issue` at the section's path when the key exists and
     is not a table. With that repair the fault becomes localizable, prunable and
     reported (R8b).

     > Superseded wording, revision 2: "That violates P2, so this is a
     > requirement R55 places on how P03 writes the loop, **not an observation
     > about R53's decision**". **JF-8 is granted**: the destination was right,
     > but the denial obscured where the gap sits, and a reader of R53 told this
     > was "not an observation about R53's decision" would not go looking.
   - **The fatal branch is `RSLB203` at exit `2`, reserved and currently
     unreached.** Under R53's loop every leaf fault is addressed by name at the
     call site, so nothing the leaf pass produces is non-localizable. The reachable
     target is a **cross-field invariant** — not leaf-local by construction — which
     R53 says is "vacuous for the current schema" and watches under its own
     re-verify trigger 1. `RSLB203` is therefore kept reserved for the first such
     rule, and for the merged-document pass failing, which by construction it
     should not. **This does not revive codex's `CONFLICT:`**: R67 guarantees the
     entry exists whether or not this item reaches it, and R67 delegates
     tolerated-versus-fatal to R55 (`## Engines`, Disagreement 1).

   > Superseded wording, revision 1: "The fatal branch is narrow and real: when the
   > fault cannot be localized to a prunable leaf, the layer fails with `RSLB203`
   > at exit `2`. Measured non-localizable cases are a root-level shape fault
   > (`## Empirical check`, F1) and a leaf inside a `#[serde(flatten)]` target
   > (H1)." **JF-1 is granted**: revision 1's case F constructed
   > `toml::Value::Integer(5)` directly rather than parsing it, and a parsed TOML
   > document always has a table at its root, so F1 bounded what the sanitizer does
   > with a non-table root rather than exhibiting a fault a user's file can cause.
   > H1 belonged to a mechanism this revision no longer uses. Neither is claimed as
   > a measured fault class now.

4. **Layers compose as sanitize untyped → merge in R54's order → one typed pass.**
   Each layer is read to a `toml::Table`, passed once through R53's loop, and
   sanitized by removing each reported `Issue.path` and each unconsumed key from
   that layer's own table; the sanitized tables are merged in R54's precedence
   order; and R53's loop runs **once more** over the merged table, where it should
   report nothing. Merging *typed* values is not available: with `#[serde(default)]`
   on every field, a `limit = 0` produced by `Default` is indistinguishable from a
   written `limit = 0`, so a lower layer's default would overwrite a higher layer's
   value with no way to tell which keys were present — which is exactly why R53's
   loop returns the partial value *and* the issue list as independent results
   rather than one or the other. Measured on R53's mechanism: sanitize-then-merge
   keeps a lower layer's valid value where merge-first falls back to the built-in
   default and loses it (R5, R6).

**Two rules this design imposes on code P03 writes.** The config struct carries
`#[serde(default)]` on every field — R53 already declares this — and **the schema
must not use `#[serde(flatten)]`**, because the per-key loop's hand-written key
list and the derive must agree about nesting. Measured (R7): leaves at a nesting
level the key list does not enumerate come back as *unknown keys*, never validated
— so a flattened field would be silently unvalidated and loudly reported as
unrecognized, the worst of both. This restores opus's original blanket rule on a
new ground.

> Superseded wording, revision 1: "**no fallible field may sit inside a
> `#[serde(flatten)]` target** — measured, not documented: when the failing leaf is
> inside the flattened target the tracked path collapses to `"."` and addresses
> nothing prunable". That narrowing was correct for `serde_path_to_error`'s tracked
> path, which this revision no longer uses. The constraint survives on the
> different ground measured above, and is no longer narrow.

**Warnings are returned, never printed.** The loader's signature is
`Result<(Config, Vec<ConfigWarning>), ConfigError>` with
`ConfigWarning { source: ConfigSource, key: Option<String>, kind: ConfigWarningKind }`.
Two independent reasons, and the second is the stronger one: R67's Layering clause
forbids the library crate from writing to any process stream, and **config loading
precedes logger initialization** — R58 has not published, and a `tracing::warn!`
emitted before a subscriber exists is discarded. The binary renders the returned
warnings once, after the logger exists, to **stderr** (R7.1), naming the offending
input (R7.6). R53's `Issue.span` can carry a byte offset for R67's optional `hint`
field; whether P03 populates it is R53's and R67's to settle, and this decision
neither requires nor forbids it.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** Four principles, each with the pinned evidence that states it.

| # | Principle | Source | Agreement level |
|---|---|---|---|
| P1 | A configuration fault must never leave the user unable to repair it | py states it in code: `b08bccfb:src/py_launch_blueprint/core/settings.py:141-145` — "Invalid values are dropped with a warning rather than raised: config must never brick the CLI — the user needs `config set`/`config path` working in order to repair the file" | **policy** — all three repos must satisfy it; the mechanism may differ |
| P2 | A degraded load is never silent, and the warning names the file and the key | py returns warning strings for the unparsable-discovered and invalid-value cases (`core/config.py:103`, `core/settings.py:169`); the org CLI Design Standard R5.8 requires "precise file/key diagnostics" and names `❌ silently ignoring bad config` as the anti-pattern | **observable acceptance criterion** |
| P3 | The fate of a fault is decided by what the fault is, not by how the code happens to be organized | derived: the ledger's four rows split cleanly into *document-level* (provenance decides) and *value-level* (granularity decides); see the rule above | **architectural pattern** |
| P4 | The library crate decides, the binary prints | R67's Layering clause (the library writes to no process stream) plus R01's composition-root shape | **architectural pattern** — py and rs agree on shape and differ in type: py returns `list[str]`, rs returns a typed `Vec<ConfigWarning>` |

P2 is where py itself falls short and rs should not: py's `_read_explicit` returns
`{}` for a missing explicit path with **no warning at all**
(`b08bccfb:src/py_launch_blueprint/core/config.py:114-115`). This decision warns.
P2 is also what the R8a measurement is about: R53's loop as published is silent for
a section key that is not a table, which is why clause 3 makes reporting it a
requirement rather than a preference.

**py states this decision's own document-level / value-level split, in py's own
words.** `b08bccfb:src/py_launch_blueprint/core/config.py:148-150`, the `load_config`
docstring: "Tolerant by design — with one exception: an *explicit* ``--config``
file that exists but cannot be parsed raises :class:`ConfigError`. Discovered
layers and invalid values degrade to warnings (see ``Config.warnings``)." That is
clause 2's explicit limb and clause 3 drawn exactly where this decision draws
them, by the source repository itself. Revision 1 argued the split without this
citation; **JF-4** is granted and it is quoted here (verified, `JF4b`).

**What must agree, and what may vary.** Must agree: P1–P4, and the three-way
classification itself — missing, unparsable and invalid-value are *distinct* cases
with distinct answers. That is the thing ts collapsed and py did not. May vary:
the granularity of the drop (per key in py and rs, per file in ts today), the
warning carrier (`list[str]`, an injected callback, a typed `Vec<ConfigWarning>`),
and the mechanism. The ecosystem difference is real and justified: `pydantic`
(`ValidationError.errors()`) and `zod` (`safeParse(...).error.issues`) both return
a *collection* of per-field errors from one pass, while serde's derived
`Deserialize` returns the first error and no value. Rust recovers the collection by
writing the loop out — roughly sixty lines, which R53 owns and accepted — rather
than by configuring a library. That is a mechanism difference at a level where
agreement is not required, not a capability gap.

**py's stated rationale for F235 does not carry into Rust; a narrower one does.**
py justifies tolerating a missing explicit path as "a valid target for `config
set`" (`core/config.py:109-112`). In Rust `config set` and `config path` operate
on the path and the document through a round-trip editor — R52 selected
`toml_edit` 0.25.15 for exactly that write path — not on the typed loader, so they
keep working whether or not the typed load tolerates absence, exactly as they keep
working when a value is invalid. The rationale that does carry is narrower: an
**env-supplied** explicit path is set once in a shell profile, a container image or
a CI job, and a hard failure there makes every invocation fail until a file exists.
`ripgrep` handles precisely that case and warns rather than failing
(`BurntSushi/ripgrep` at `3fce3b5bb0236da2df6d99672afb8a719642eca7`,
`crates/core/flags/config.rs:32-40`, retrieved 2026-09-17). ts's contrary behavior
additionally rests on a premise the ledger has already flagged as false: its code
comment claims `click.Path(exists=True)` parity
(`ts@cb1cbcb2:src/lib/config.ts:154` — the line number corrected under **JF-5**
and verified as `JF5b`; `:153` is the `if (!fs.existsSync(...))` the comment sits
inside), but the pinned py commit's `--config` option is declared
`type=click.Path(dir_okay=False)` with no `exists=True`
(`b08bccfb:src/py_launch_blueprint/cli/options.py:102-109`;
`docs/port/DIVERGENCE-ANALYSIS.md:297` asks R55 to re-check rather than rely on
the note, which is what this citation does).

**Architectural alternatives for the value-level case — the comparison, and how
R53's publication resolved it.**

| Alternative | Mechanism | Per-key drop | Names the key | Cost / status |
|---|---|---|---|---|
| **A. All-or-nothing typed deserialize** (ts's shape) | `toml::from_str::<ConfigFile>(text)?` | no | only in the fatal message | zero cost, but loses P1. Rejected |
| **B. Prune-and-retry over the untyped document** | typed pass through `serde_path_to_error::Deserializer`; on error remove the leaf the tracked path names; retry; bound the loop by leaf count | yes | yes, by dotted key path | ~60 lines and two crates. **Correct as a mechanism R55 could own alone; superseded by D, which R53 selected and which needs no crate and no retry** |
| **C. Per-field `deserialize_with` wrapper or a project derive** (`alacritty`'s shape) | every field deserializes through a wrapper that falls back to `Default` | yes | only if the wrapper can reach a collector | a macro to maintain. `serde_with`'s `DefaultOnError` is the version with **no** reporting, so it fails P2. Rejected |
| **D. Per-key extraction over an intermediate table** | no whole-struct derive pass; deserialize each declared key independently out of `toml::Table`, pushing `(path, message)` per failure | yes | yes | **selected — this is R53's published mechanism.** One pass rather than N; boilerplate proportional to the schema, a cost R53 weighed and accepted |
| **E. `figment`** | providers plus `Metadata` provenance; `figment::Error` accumulates several failures | **no** — extraction is still all-or-nothing | yes, with file provenance | adopts a whole config framework, pre-empting R52, R53 and R54. Ranked runner-up *architecture* only |

> Superseded wording, revision 1: "**B is selected** because it is the only option
> that delivers per-key drop *with* a machine-readable key name while leaving R52,
> R53 and R54 free… D is what a `toml::Value::get` plus per-leaf `try_into` design
> becomes in practice: it needs the schema's leaves enumerated independently of the
> derive."

That description of D was accurate and its rejection ground — that it "drifts from
whatever R53 selects" — dissolved when R53 selected it. D's remaining cost,
boilerplate proportional to the schema, is R53's to carry and R53 carried it
knowingly, in exchange for aggregate reporting that no serde-layered validation
crate can give. B is strictly worse than D once D exists: B runs N typed passes for
N bad keys and needs a crate to recover a key name that D knows at the call site.
E's repository `SergioBenitez/Figment` shows `pushed_at` `2024-09-13T04:51:49Z`
(retrieved 2026-09-17), a two-year push gap that is a maintenance **trigger**, not
a verdict — it was not investigated to a verdict because the design does not select
it.

**Reference implementations — what well-regarded Rust projects actually do.** Each
file was read at the commit named, so the line ranges stay re-readable (**JF-5**,
fourth point); repository figures were retrieved 2026-09-17 from
`GET https://api.github.com/repos/<owner>/<repo>`.

| Project | Commit read | Why it is a relevant reference | What it does with a config fault |
|---|---|---|---|
| `cargo` (`rust-lang/cargo`, 15,484 stars) | `495c385d0875c4ba51eb72ea0448a2d4c018b8d4` | the toolchain's own CLI and the highest-stakes TOML consumer in the ecosystem | two-phase load — untyped `toml::de::DeTable`, then a typed deserialize from it (`src/workspace/parser/mod.rs:186-203`); unknown keys become warnings through `serde_ignored` (`:198`); **warnings accumulate as data and are attached to the manifest** (`:148-152`), not logged at the point of degradation |
| `ripgrep` (`BurntSushi/ripgrep`, 68,336 stars) | `3fce3b5bb0236da2df6d99672afb8a719642eca7` | the reference Rust CLI | an explicit path that cannot be read, including missing → warn and continue (`crates/core/flags/config.rs:32-40`); bad *lines* inside a readable explicit config → report each, keep the good ones (`:41-45`) |
| `starship` (`starship/starship`, 59,920 stars) | `4ff40d066af2dd316dcb4742544254436e7e8190` | very large, very current adoption, and its tolerance posture is deliberate | every fault degrades: unparsable → `log::error!` and `None` (`src/config.rs:139-149`); missing or unreadable → log and `None` (`:151-165`, level chosen from `ErrorKind::NotFound`); **invalid value → per-unit drop with a warning and a default** (`:31-39`); unknown key → warn, then re-deserialize leniently (`:53-62`) |
| `axum` (`tokio-rs/axum`, 27,156 stars) | `3f46d25e9274d485a99905d3734d37828112bc31` | the dominant Rust web framework; this template ships a web surface | uses `serde_path_to_error` in its `Json`/`Form` extractors so a deserialization failure can name the offending field (`axum/Cargo.toml:139`) |

Practice is unanimous on the discovered-layer and value-level cases — degrade with
a visible warning, keep what parsed — and split on the missing explicit path:
ripgrep tolerates, cargo errors. The split is explained rather than left open:
cargo's `--config` is not a pure path flag, so a non-existent path falls through
to its `KEY=VALUE` branch and fails as `failed to parse value from --config
argument` (`src/context/mod.rs:1553-1566`). Note that `cargo` reaches its
unknown-key warnings through `serde_ignored` because it deserializes the whole
typed manifest in one pass; R53's per-key loop reaches the same warnings without a
crate because it enumerates the keys itself. Both are the same policy; only the
mechanism differs, and the mechanism follows from the shape of the typed pass.

**Observable acceptance criteria.** P03's CI proves the recommendation by
asserting each of these:

1. `--config <path-that-does-not-exist>` exits `0`, applies defaults, environment
   variables and flags, and writes exactly one warning naming that path to stderr;
   stdout is byte-empty of diagnostics.
2. `--config <unparsable>` exits `2` with an `RSLB202` envelope on stderr and
   byte-empty stdout (R67's envelope clause).
3. `--config <unreadable, not NotFound>` exits `1` with an `RSLB104` envelope.
4. A corrupt *discovered* layer exits `0`, emits one warning naming that file, and
   leaves the other layers active.
5. One invalid leaf in any layer exits `0`, emits one warning naming that file and
   that `Issue.path`, preserves sibling keys and the other tables, and falls back
   to the next valid lower-precedence value, or to the built-in default when none
   exists.
6. An unknown key in any layer exits `0` and emits one warning naming it.
7. A section key whose value is not a table exits `0`, emits one warning naming the
   section, and is dropped — never silently defaulted.
8. The library crate writes nothing to any process stream on any of these paths.
9. No tolerated branch returns `Err`.
10. `RSLB203` is unreachable from any of the above; the first cross-field rule R53
    adds is the test that reaches it.

**`BASELINE-REVIEW: F237 — a corrupt config file the user explicitly named is a hard failure, not a degraded load — keep the row inherited but record that "inherited as-is" cannot be literal in `rs-launch-blueprint`: the single `ConfigError` both sources raise becomes two catalogue rows, `RSLB104` (config layer unreadable → exit 1) and `RSLB202` (config document unparsable → exit 2); affected items: R55 (this item, which routes to both rows) and R52/R53, which must not assume one error type covers both faults — evidence: py raises one `ConfigError` for both `tomllib.TOMLDecodeError` and `OSError` (`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/config.py`, `_read_explicit` lines 114-120, retrieved 2026-09-17) and ts throws one `ConfigError` for both a failed `readFileSync` and a failed `parse` (`git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/config.ts`, read catch at lines 109-115, parse catch at 117-123, retrieved 2026-09-17), while R67 — owner-accepted, consumed here — assigns the two faults different exit codes (`research/topics/67-error-and-exit-code-contract/DECISION.md:258-263`). The split is R67's, not a new proposal by this item; it is recorded so F237's "inherited as-is" is not read as a promise that one error type survives the port.`**
Raised by the opus raw report (`raw/opus.md:227`) and restored verbatim here under
**JF-6**; revision 1 paraphrased it. **Accepted and carried.** Disposition: the
split is already published in R67 and is not a new proposal by this item; this
decision routes to both rows, and R53 has since made the boundary structural rather
than message-dependent, so the "R52/R53 must not assume one error type covers both
faults" clause is discharged rather than outstanding. No ledger row changes.

**`BASELINE-REVIEW: F238 — local recoverability must preserve a valid lower-precedence value — validate each layer's leaves before precedence merge rather than Python's merge-then-pop — pinned Python code merges before removing the invalid key, while toml::Value supplies the required leaf boundary; affected R53, R54, R55, R58, R67.`**
Raised by the codex raw report (`raw/codex.md:17`) and restored verbatim here under
**JF-6**; revision 1 paraphrased it. **Accepted and carried, and measured twice.**
Disposition, with the two updates the verbatim line cannot carry: the leaf boundary
is R52's `toml::Table` rather than `toml::Value` (R52 selected `toml` 1.1.6 and the
table is what R53's loop walks), and the per-layer validation is R53's published
loop rather than a pass R55 owns. py pops the offending key out of the **merged**
dictionary (`b08bccfb:src/py_launch_blueprint/core/settings.py:162`,
`bad = merged[section].pop(key, None)`); on identical two-layer inputs —
a user layer with a valid `output.format` under a project layer with an invalid one
— merge-then-drop falls back to the built-in default and **loses the user layer's
good value**, while sanitize-then-merge keeps it. Measured under revision 1's
mechanism (`## Empirical check`, M1/N1) and again under R53's (R5/R6). Neither
engine executed it. It is worth carrying back to py as part of the follow-on
project rather than treated as a Rust-only nicety.

**Fitness gates.** Gate 1 (licence) is
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`
for every candidate; nothing was excluded on licence. Gates 2 through 6 are
**`inapplicable — this item has no crate member`**: R55 adds no crate, so there is
no candidate of this item's for them to score. The crates the pattern composes over
are gated by the items that select them — `toml` by R52, `serde` by R53,
`thiserror` by R67 — and none of those gate results is re-derived here. The crate
figures the answer template asks for are likewise `inapplicable — no crate member`.
*Excluded by gate:* **none**. `serde_with`'s `DefaultOnError` and `figment` were
excluded on **fitness**, not by a gate: the first cannot report which key it
dropped (P2), the second has no drop-and-continue. `serde_path_to_error` 0.1.20 and
`serde_ignored` 0.1.14 are **not excluded either** — they pass every gate — they are
simply **not needed**, which is a different disposition and is recorded as such.

Revision 1's per-member gate table is preserved here as superseded wording, because
it is the record that the two crates were evaluated rather than dismissed:

> | Gate | `serde_path_to_error` 0.1.20 | `serde_ignored` 0.1.14 |
> |---|---|---|
> | 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; crates.io reports `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; crates.io reports `MIT OR Apache-2.0` |
> | 2 MSRV | `rust_version` **1.61**; sole dependency `serde` | `rust_version` **1.61**; sole dependency `serde` |
> | 3 advisories / `unsafe` | `https://rustsec.org/packages/serde_path_to_error.html` → **HTTP 404**, no advisory page (controlled: `anyhow` → **200**); `unsafe` posture carried from the opus raw report, not re-audited | `https://rustsec.org/packages/serde_ignored.html` → **HTTP 404** (same control); `unsafe` posture likewise carried, not re-audited |
> | 4 OS matrix | pure Rust, no platform-specific code; executed on macOS arm64 only | same, and same limitation |
> | 5 default features / async | default `std`; **no async-runtime coupling** | default `std`; **no async-runtime coupling** |
> | 6 binary size / compile cost | negligible; the spike lockfile holds 20 packages and the two members add **zero** transitive dependencies beyond `serde`'s own set | same |
>
> Maintenance state, by the rubric: both **stable-quiet**… `pushed_at` 2026-06-24 on
> both repositories shows live maintenance; neither is archived; neither has an
> advisory; both build and run on current stable.

**Compatibility.** With no crate member, the compatibility question is whether the
*pattern* composes with what the other items selected, and it was executed: R53's
published loop shape, run over R52's `toml::Table`, produced the issue list, the
partial value and the unconsumed-key set that clauses 3 and 4 consume, on
`cargo 1.98.0` / `rustc 1.98.0`, edition 2024 (`## Empirical check`, D05). The
binding MSRV floor across the composed crates is **1.71**, R67's `thiserror`, far
below `stable minus 2 minor versions` at any plausible 2026 stable.

**Migration implications** (P03's work list; the template does not exist yet).
R53 places the schema, the `Unvalidated`/`Valid` type-state, `Issue` and the per-key
loop in `crates/rs-launch-blueprint/src/config/schema.rs` and `…/validate.rs`, and
names `…/config/loader.rs` as shared with R52, R54 and R55. This item adds, in that
shared loader: a `ConfigSource` type carrying `Explicit { path, origin: Flag | Env }`
and `Discovered { path, tier }` with an `is_strict`-style predicate; a per-layer
read mapping `ErrorKind::NotFound` to an empty layer plus a warning and every other
`io::Error` to `RSLB104` for explicit sources; a sanitize step that removes each
`Issue.path` and each unconsumed key from that layer's `toml::Table` and turns each
into a `ConfigWarning`; the merge over sanitized tables in R54's order followed by
the single final pass; a `ConfigWarning` type and its `Display`; three variants on
the config error enum with their `ErrorCode` arms; and a CLI startup path that
renders the returned warnings once, after the logger exists, with `config set` and
`config path` not requiring a successful typed load. **No `[dependencies]` line is
added.** Two requirements land on R53's loop as P03 writes it: the per-level
unconsumed-key set must actually be computed at every level the loop descends, and
a section key that is present but is not a table must push an `Issue` at the
section's path. Module names beyond R53's are P03's choice; nothing was scaffolded
here.

re-verify: 2027-03-17, or earlier on any of — **R53 being revised** in a way that
changes the loop's shape or the `Issue` type (the sanitize step consumes both);
**R53's own re-verify trigger 1 firing** — a constraint the type system cannot hold,
which is what would first make `RSLB203` reachable and would change clause 3's
third sub-clause from reserved to exercised; R52 replacing `toml` with a parser
that has no addressable intermediate table (the sanitize step has nothing to
prune); R54 publishing (whether a discovered tier exists at all — if none does,
clause 2's tolerant limb and F236 have no Rust instance, and whether its merge
depth changes what clause 4's merge must do); R58 publishing (the point at which
returned warnings are rendered); R03 publishing (this loader reuses its
absence-versus-failure shape rather than inventing a parallel one); R67 being
revised; or Rust stable advancing far enough that `stable minus 2 minor versions`
rises above 1.71. Revision 1's trigger "R53 publishing" has **fired** and is
discharged by this revision; revision 1's two crate-specific triggers (a RustSec
advisory against `serde_path_to_error` or `serde_ignored`, and either going 18
months without a release) are **retired**, this item having no crate member.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

These five lines are **byte-identical to revision 1** and to their
`docs/port/PARAMETERS.md` rows. No `- owns` line appears above because the prompt's
`## Couplings` records an empty `owns:` field: this item publishes no repo-wide
parameter. R53 owns no parameter either (`research/CLAUDE.md` shows `owns: —` for
it), so reconciling against R53 adds no `- assumes` line; what R53 supplies is a
published **decision**, consumed here at sha256 `be59d65b…` and pinned by check
`D01`.

**No `CONFLICT:` line is raised**, unchanged from revision 1. The codex raw report
raised one against `RSLB203`; it is quoted, adjudicated and rejected under
`## Engines`. R67's catalogue expresses every failure this design produces, and the
strict alternative to clause 1 would need no new row either — it would be `RSLB201`
(usage/parse), whose published row explicitly covers "usage/parse (including the
CLI parser's own errors)".

How the parameters bear on the decision. `error-taxonomy-exit-codes` is the only
consumed parameter; this decision routes to three of its existing rows in practice
— `RSLB104`, `RSLB202` and, reserved but currently unreached, `RSLB203` — plus
`RSLB201` only under the rejected strict alternative for the missing-path case, and
invents none. Its Layering clause (the library crate writes to no process stream or
file) is why warnings are returned rather than printed, and its envelope clause
fixes what the fatal branches emit. `msrv-policy` is satisfied with wide headroom:
the binding floor across the composed crates is `thiserror`'s 1.71, and dropping
the two 1.61 crates does not move it. `rust-edition` was exercised directly — both
verification spikes are edition-2024 packages. `license` constrains nothing here
under the owner's 2026-09-12 ruling. `target-os-matrix` is satisfied by
construction — the pattern is pure Rust with no platform-specific code — but only
`macos-latest` was exercised; see `## Engines`.

Constraints this item places on other items, stated as constraints rather than as
assumptions, because none of them is a parameter. **R52** must expose an untyped
intermediate table the sanitize step can prune — `toml::Table` is exactly that, and
R52 selected `toml` 1.1.6+spec-1.1.0 for the read path with `toml_edit` 0.25.15 for
the `config set` write path, so this constraint is **discharged, not outstanding**.
**R53** owns the leaf pass; two requirements land on how P03 writes its loop
(the per-level unconsumed-key set, and a non-table section key reported at the
section's path), both measured. The second is a gap in R53's published loop shape
that touches R53's own must-agree row at `R53 DECISION.md:184`; the repair is one
line inside R53's module and belongs to P03, so R53 need not revise, and no
`CONFLICT:` arises because R53 owns no parameter. **R54** must tag each layer it discovers with provenance
— the document-level tolerance rule is a function of that tag, not of the tier
count — and owns merge depth and precedence order; this item fixes only the
*sequence*. **R58** must accept a `Vec<ConfigWarning>` rendered by the binary after
logging is initialized.

## Empirical check

**Toolchain.** `cargo 1.98.0 (797e8a9bc 2026-08-05)` (Homebrew),
`rustc 1.98.0 (88d9e12ae 2026-08-18)` (Homebrew), `Darwin arm64` (macOS),
`shellcheck` on `PATH`, `/usr/bin/grep` (BSD grep) as the counting binary.
Working directory: `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/`.

**Every earlier revision's script and logs are unchanged and are not re-run into
new files.** `evidence/check.sh`, `evidence/check.log` and `evidence/rerun.diff`
are byte-identical to what revision 1 committed (sha256 `ed0029f0…`, `d83a1fea…`,
`3dda6290…`), and `evidence/check-r2.sh`, `evidence/check-r2.log` and
`evidence/r2-rerun.diff` are byte-identical to what revision 2 committed — JF-7 is
repaired in a new file, never by editing the script whose output is already cited.
Each revision adds files rather than editing them. Revision 1's result
stands: **`PASS=25 FAIL=0 SKIP=0`, exit `0`**, covering R67's delegation sentence
(C01–C03), the four ledger rows (C04), the `- assumes` byte-identity (C05), the org
CLI Design Standard at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` (C06), the
crates.io snapshots (C07) and revision 1's sixteen-assertion spike (C08).

**JF-2, first half — the archive rerun is now a recorded artifact.** Revision 1
asserted that `evidence/check.sh` reruns from a clean `git archive HEAD`
extraction. That run is now saved as `evidence/check-archive.log`: it ends
`PASS=25 FAIL=0 SKIP=0` with exit `0` (asserted as `JF2b`). It differs from
`evidence/check.log` in three lines and no assertion: the `date (UTC)` header, the
`repository root` header, and the C05 line, which prints that root path inside its
message. **JF-2, second half — the 20-package figure is now read rather than
recomputed by the reader**: `JF2a` counts the `[[package]]` stanzas in revision 1's
committed `evidence/spike/Cargo.lock` and asserts exactly **20**. Revision 1's
`check.sh` was not edited to add this, because the revision rules keep a cited
script byte-identical.

**Command (revision 3; supersedes revision 2's `check-r2.sh`).**

```
./evidence/check-r3.sh 2>&1 | tee evidence/check-r3.log
```

**Result: `PASS=29 FAIL=0 SKIP=0`, exit status `0`.** The full output is
`evidence/check-r3.log`. The script is shellcheck-clean, asserts on content in
every check, finds the repository root by content rather than `.git`, and skips by
name (`JF3-cli-standard-absent`, `JF4-py-repo-absent`, `JF5-ts-repo-absent`,
`JF9a-py-repo-absent`, `JF9b-ts-repo-absent`, `D05-cargo-absent`) where an
external input is unavailable. It carries every revision-2 check plus seven new
ones — `JF7`, `JF7b`, `JF8a`, `JF8b`, `JF9a`, `JF9b`, `JF9c` — so **29 script
checks**, and the nine probe assertions nested inside `D05` bring the log to 38
`PASS` lines in total.

> Superseded wording, revision 2: "**Result: `PASS=18 FAIL=0 SKIP=0`, exit status
> `0`.** The full output is `evidence/check-r2.log`… The eighteen script checks
> and the nine probe assertions nested inside `D05` are:". **JF-7 is granted.**
> `PASS=18` was the number four broken counters printed; the same log carried 22
> script-level `PASS` lines and the bullet list below enumerated 22 identifiers,
> so the prose disagreed with its own log and its own enumeration. Neither
> `evidence/check-r2.sh` nor `evidence/check-r2.log` is edited; both stay as the
> record of what revision 2 ran, and the negative control reads them.

**Why the repaired script's gate can close, shown twice.** Check `JF7` runs the
counter experiment in the live shell and requires both halves of it: a function
invoked as a pipeline's tail leaves `pass=0 fail=0`, the same function invoked
with a here-string leaves `pass=1 fail=1`. Check `JF7b` asserts that this script
contains exactly four here-string-fed `assert_stream` calls, one per repaired
check, so the fix cannot silently regress. Beyond the script,
`evidence/check-r3-negative-control.log` records a forced failure of `JF5b` — its
needle replaced with text absent from the file — run against **both** scripts from
a `git archive HEAD` extraction, neither script edited in place: revision 2's
prints the `FAIL` line, reports `FAIL=0` and exits **`0`**; revision 3's prints the
identical `FAIL` line, reports `FAIL=1` and exits **`1`**. That log states its own
reproduction procedure.

The 29 script checks and the nine probe assertions nested inside `D05` are:

- **D01–D04 — the R53 decision this revision reconciles against.** `D01` pins it at
  sha256 `be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9`, so a
  later R53 revision fails this check rather than silently invalidating the
  reconciliation. `D02` asserts the published signature
  `pub fn validate(self) -> (ConfigFile, Vec<Issue>) { /* per-key loop over toml::Table */ }`;
  `D03a` the `Issue { path, message, span }` type; `D03b`–`D03d` the three sentences
  in which R53 names the coupling, states that unknown-key detection is free, and
  hands unknown-key policy to R55; `D04` that R53 adds no dependency.
- **JF7, JF7b — the harness gate itself** (round-2 JF-7), described above: the
  counter experiment in the live shell, and the four-here-string count that keeps
  the repair from regressing.
- **JF8a, JF8b — where the R8a gap sits** (round-2 JF-8): `JF8a` asserts R53's own
  must-agree row "A value outside a key's allowed set is rejected, never silently
  coerced" (`R53 DECISION.md:184`), and `JF8b` asserts the line that produces the
  silence, `if let Some(t) = table.get("output").and_then(toml::Value::as_table) {`
  (`R53 review/evidence/verify.sh:620`).
- **JF9a, JF9b, JF9c — the pins revision 2 left off** (round-2 JF-9): three
  `model_config = {"extra": "ignore"}` occurrences in py `settings.py` at
  `b08bccfb`; one `z.object` declaration and **zero** `.strict()`/`.passthrough()`
  calls in ts `config.ts:37-41` at `cb1cbcb2`, which is why zod strips unknown
  keys; and `R53 review/evidence/verify.sh:649` as the helper's first line.
- **JF2a, JF2b, JF3, JF4a, JF4b, JF5a, JF5b — the round-1 finding repairs**, each
  verified at its source: the 20-package count; the archive log's summary; R5.7's
  anti-pattern line `❌ no way to see why a setting took the value it did` at the
  pinned standard blob (JF-3, which revision 1 cited under `C06d`, a check covering
  only the R5.8 half); py `config.py:127-128` (the `--config` collapse docstring)
  and `:148-150` (the `load_config` tolerance docstring), both read through the
  `b08bccfb` pin; py `config.py:103` as the line returning the discovered-layer
  warning; and ts `config.ts:154` as the `click.Path(exists=True)` parity comment,
  read through `cb1cbcb2`.
- **D05, D05a–D05g — the reconciliation probe**, unchanged from revision 2 and
  rerun by this script. Source at `evidence/spike-r2/`, copied to a
  temporary directory and **built outside the repository**. It depends on
  `serde_ignored` and `serde_path_to_error` **only in order to measure them against
  R53's loop**; the decision recommends neither. It reproduces R53's published
  `field::<T>(table, section, key, &mut issues)` helper in shape from
  `R53 review/evidence/verify.sh:649-657` — the range corrected from revision 2's
  `:650-657` under **JF-9**, the helper's first line being `:649` (check `JF9c`).
  Resolved versions: `serde` 1.0.229,
  `toml` 1.1.6+spec-1.1.0, `serde_ignored` 0.1.14, `serde_path_to_error` 0.1.20, in
  a 20-package graph. Nine assertions, all passing:

  | Case | What it measures | Result |
  |---|---|---|
  | R1 | R53's loop plus the per-level set-difference, on a document with a top-level unknown key and a nested one | reports both: `["output.colour", "verbose"]` |
  | R2 | `serde_ignored` on the same document | reports the same two: `["output.colour", "verbose"]` |
  | R3 | the two reports compared | **identical** — `serde_ignored` adds nothing |
  | R4 | R53's `Issue.path` used to prune the same `toml::Table` | the one reported path prunes, the sibling `limit = 7` survives, and the second pass is clean — **no path-tracking crate is needed** |
  | R5 | clause 4 on R53's loop: sanitize each layer, merge, one final pass | the lower layer's valid `output.format = json` survives the higher layer's invalid one; one warning naming `project.toml`; the final pass reports nothing |
  | R6 | the same two layers under py's merge-first order | falls back to the built-in default, **losing** the user layer's value |
  | R7 | leaves at a nesting level the hand-written key list does not enumerate | reported as **unknown keys**, never validated — the ground for the no-`flatten` rule |
  | R8a | a section key present but not a table (`output = 5`), under R53's loop **as published** | **silent**: no issue, no unconsumed entry, built-in defaults returned |
  | R8b | the same, with the one-line repair clause 3 requires | one `Issue` at path `output`, prunable, second pass clean |

**What the probe does not establish.** It runs R53's loop shape against a
two-level schema of this synthesis's own construction, not against the template's
real schema, which does not exist. R5/R6 use two layers; three or more, and R54's
actual merge depth, are unexercised. Everything ran on macOS arm64 only.

**Reproducibility, stated exactly.** `evidence/check-r3.log` is the output of one
executed run of `evidence/check-r3.sh`. The script was then rerun and diffed
against that log before this sentence was written. The complete diff is
`evidence/r3-rerun.diff`, and it is **one line**: the `date (UTC)` value in the
environment header. It was also run from a clean `git archive HEAD` extraction,
saved as `evidence/check-r3-archive.log`: same `PASS=29 FAIL=0 SKIP=0`, same exit
`0`, differing from `evidence/check-r3.log` in two header lines (`date (UTC)` and
`repository root`) and in no assertion. Revision 2's `evidence/r2-rerun.diff` is
likewise a one-line diff and is unchanged. Every assertion line, every count and every figure is
byte-identical across the two runs. The same claim holds for revision 1's
`evidence/rerun.diff`, which is likewise a one-line diff and is unchanged. The
crates.io and GitHub figures revision 1 cites are read from snapshots committed
beside the scripts rather than from live endpoints, so no live-source drift can
change an assertion; the snapshots' retrieval date is 2026-09-17.

## Engines

- codex (gpt-5.6-terra) `raw/codex-523260b7256c2c89acef409e57c29369daa1ccdee3f0c4674e4b6bb14248d550.md`
- opus (claude-opus-5) `raw/opus-92427e8b93642e3ff8c4f482636b9cdc7ca2b78729468a7d7e79c31563f92b7f.md`

**Disagreement 1 — does R67's `RSLB203` row conflict with per-leaf recovery? It
does not; codex's reading was wrong.** *Unchanged from revision 1.* codex wrote,
verbatim:

> CONFLICT: R67 error-taxonomy-exit-codes — `RSLB203 config value invalid` cannot mean every invalid file leaf — R55 requires an individually invalid declared config value to warn-and-drop, reserving `RSLB203` for a fatal nonrecoverable validation outcome such as R53's cross-field invariant.

opus reported **no** conflict, holding that R67's catalogue expresses every failure
this design produces. **Settled for opus, from R67's own text rather than from
either engine's argument.** The row reads, in full:
`` `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**) ``.
That is a catalogue *entry*: a fault class, a stable code, an exit integer. It is
not a rule about when the fault is raised. R67 says so itself, in the paragraph
that introduces the configuration rows: "Each case gets its own catalog entry so
R54–R56 can route to any of them without inventing a code. **R55 and R56 own
whether a given condition is tolerated, warned about, or fatal; this item only
guarantees the entry and the code exist.**" (verified, revision 1's check `C02`.)
codex's error is reading an entry as a mandate. A tolerated leaf raises no error at
all — it is a `ConfigWarning` in the `Ok` arm — so it never reaches the catalogue,
and there is nothing for the row to exclude. **No `CONFLICT:` line is carried
forward**, and R67 needs no revision. One thing revision 2 sharpens rather than
changes: codex asked that `RSLB203` be reserved "for a fatal nonrecoverable
validation outcome such as R53's cross-field invariant", and under R53's published
mechanism that is now exactly and only what it is reserved for (clause 3, third
sub-clause). The substance of codex's ask is granted in full, under R55's own
ownership, with no change to R67. That `RSLB203` is currently unreached is **not**
an argument for codex's reading: R67 guarantees the entry whether or not this item
reaches it.

**Disagreement 2 — is a bad *value* in an **explicit** layer fatal or tolerated?**
codex tolerates a bad leaf in every layer. opus makes a bad leaf fatal in an
explicit layer (`RSLB203`) and tolerates only discovered layers. **Settled for
codex**, on four pieces of evidence and against opus's structural argument:
(i) F238's ledger row carries **no layer qualifier** (verified, revision 1's check
`C04d`);
(ii) py's `_discovery_paths` collapses discovery to the single explicit file —
docstring "``--config`` collapses discovery to that single file; otherwise the
system → user → project layers apply" with body `if config_file: target =
Path(config_file); return target, [target]`
(`b08bccfb:src/py_launch_blueprint/core/config.py:124-139`, quoted range
`:127-128`, verified `JF4a`) — so the explicit file *is* the sole file layer that
`settings_from_layers` then validates and tolerates a bad value inside;
(iii) py states the whole rule in its own words in `load_config`'s docstring
(`config.py:148-150`, verified `JF4b`, quoted under `### Principles and
implementation`), drawing the document-level/value-level line exactly where clauses
2 and 3 draw it;
(iv) opus derives explicit-strictness from F237, but F237 is about an
**unparsable** document, not an invalid value; extending it to values would extend
a settled row beyond its own text.
opus's practice evidence argues against opus's own rule: ripgrep reports bad
*lines* in an explicitly named config and keeps the good ones, and starship drops
a bad value per unit with a warning. Revision 1 called this "the one place in this
decision an owner could reasonably decide the other way"; evidence (iii), added
under **JF-4**, narrows that considerably — py states the rule rather than merely
exhibiting it — but the owner's option remains, at a cost of one branch.

**Disagreement 3 — the mechanism for per-key drop. Revision 1's settlement is
superseded by R53's publication.**

> Superseded wording, revision 1: "codex proposes parsing to `toml::Value` and
> converting each declared leaf independently, and admits in its own Parameters
> field that this 'assumes R53 validation = independently callable declared-field
> validation'. That is alternative D — hand-rolled extraction — and it drifts from
> whatever R53 selects. opus proposes prune-and-retry through
> `serde_path_to_error` and executed it. **Settled for opus**."

Two repairs. First, **JF-5(iii)**: codex's sentence does not end where revision 1
cut it. In full (`raw/codex.md:155`) it reads "assumes R53 validation =
independently callable declared-field validation **plus a separately classified
cross-field invariant result**" — and that second clause is now the live
description of `RSLB203`'s only reachable target, so codex separated the two cases
correctly rather than only the first. Second, the settlement itself: **R53 selected
alternative D**, so codex's shape is what the template will have, and the ground
for preferring opus's — that D "drifts from whatever R53 selects" — is gone.
**Revised disposition: neither engine's crate is needed.** codex's architecture is
what R53 supplies; opus's prune-and-retry was correct as a mechanism R55 could own
alone, was executed, and is superseded by a mechanism that needs no crate and one
pass rather than N. Measured: R53's loop reports the same unknown keys as
`serde_ignored` (R3) and its `Issue.path` prunes the same leaves
`serde_path_to_error` located (R4).

**Disagreement 4 — where the degrade warning is emitted.** codex says the CLI or
web composition root emits it, "eventually `tracing::warn!`", citing R67's layering
rule. opus adds the stronger reason: config loading **precedes** logger
initialization, so a `warn!` at the point of degradation has no subscriber and is
discarded. **Settled for opus's reasoning, same outcome** — warnings are returned
as data and rendered once by the binary, which is also what `cargo` does
(`src/workspace/parser/mod.rs:148-152`). Unchanged from revision 1.

**Disagreement 5 — is a missing explicit path warned about or silent?** py is
silent (`core/config.py:114-115`) and codex's essential outcome 1 does not require
a warning; opus requires one. **Settled for opus**, on two rules of the standard,
each now carrying its own citation (**JF-3**): R5.8 names `❌ silently ignoring bad
config` as the anti-pattern (verified, revision 1's check `C06d`), and R5.7 exists
so a user can see why a setting took the value it did, its anti-pattern line
reading `❌ no way to see why a setting took the value it did` (verified, `JF3` —
revision 1 attached `C06d` to both halves, and `C06d` covers only the first).

**A raw claim revision 1 narrowed, and revision 2 restores on a different ground.**
opus's rule 5 was a blanket prohibition on `#[serde(flatten)]` (`raw/opus.md:174`).
Revision 1 re-measured it and narrowed it to *fallible* fields inside the flattened
target, because the collapse of `serde_path_to_error`'s tracked path to `"."` was
what the prohibition rested on. Under R53's per-key loop there is no tracked path
to collapse, and the constraint returns for a different reason: the loop's
hand-written key list and the derive's `flatten` must agree about nesting, and when
they do not, every leaf at the unenumerated level comes back as an unknown key and
none is validated (R7). The blanket rule is therefore right, and revision 1's
narrowing was right for the mechanism revision 1 recommended. Both states are
recorded rather than one being quietly replaced.

**Both engines' `BASELINE-REVIEW:` lines are accepted and carried**, restored
verbatim from the raws under **JF-6**, with their dispositions under
`### Principles and implementation`.

**Unproven, and left for P03 to prove in the real template.** Revision 1 listed
ten; five are retired by this revision and are recorded here rather than dropped.

1. **`ubuntu-latest` was not exercised.** Every check here ran on macOS arm64.
   Nothing in the pattern or the composed crates is platform-specific, but the
   claim is structural, not measured. *Carried.*
2. **The probe runs a schema of this synthesis's construction**, not the
   template's real schema, which does not exist. R5/R6 use two layers; three or
   more, and R54's actual merge depth, are unexercised. *New.*
3. **`Issue.span` feeding R67's optional `hint` field is unexercised.** R53 states
   `serde_spanned` is available in `toml`'s tree; no span was carried through to an
   envelope here. *New.*
4. **The strict alternative for the missing-path case (`RSLB201` at exit 2) was
   not exercised.** *Carried.*
5. **The unreadable-but-present explicit layer (`RSLB104`) was not exercised**:
   both spikes model document-level faults through parse failures, not through a
   permission error. *Carried.*
6. **`RSLB203` is unreached by any executed case** under the recommended design.
   Its reachability depends on R53 adding a cross-field rule, which R53 records as
   vacuous for the current schema. *New, and it replaces revision 1's F1 claim
   (JF-1).*
7. **The `unsafe` posture of `serde_path_to_error` and `serde_ignored`** was
   carried from the opus raw report, not re-audited. *Retired — the two crates are
   no longer members; the composed crates' `unsafe` posture belongs to R52, R53 and
   R67.*
8. **`toml_edit::DocumentMut` as a `serde::Deserializer`.** *Retired — R52 selected
   `toml` for the read path and `toml_edit` for the `config set` write path only, so
   the intermediate the sanitize step prunes is `toml::Table`, which is measured.*
9. **Issue-responsiveness medians, the RustSec 404 interpretation, and the absence
   of a performance measurement** for the two crates. *Retired with the members; no
   crate figure is claimed by this revision.*
10. **Whether `serde_ignored` belongs to this item rather than to R53.** *Retired —
    answered: unknown-key **detection** belongs to R53's loop and needs no crate,
    and unknown-key **policy** is R55's, decided in clause 3.*

**What P03 must validate**: the ten observable acceptance criteria above; the
multi-layer behavior inside the real schema, on both runners in
`ubuntu-latest, macos-latest`; that the library crate's streams stay empty on
every path; that the warning text names both the file and the `Issue.path`; that
`config set` and `config path` work without a successful typed load; that the
per-level unconsumed-key set is computed at every level R53's loop descends; that a
non-table section key is reported rather than silently defaulted; and that the
final pass over the merged sanitized document reports nothing, which is the
assertion that would catch a sanitize or merge bug.
