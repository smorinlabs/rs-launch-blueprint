# 2026-09-17 — R53 — config-schema-validation (crate, Focused) — decision (revision 2)

**Revision note, revision 2.** Revision 2 answers the round-1 judgment audit
(`review/audit-fable.md`, verdict `reject`, findings JF-1 to JF-4) and changes **nothing in
the recommendation**: still `serde >= 1.0.229, < 2.0.0` with `features = ["derive"]` and no
validation crate, still `garde >= 0.23.0, < 0.24.0` as the ranked runner-up, no parameter
value moved, no gate disposition reversed and no candidate excluded or admitted. The
round-1 empirical (Codex) audit did not run — the Codex account is out of usage, as
`review/audit-fable.md` records — so no artifact was reproduced by a second engine; even so,
`review/evidence/verify.sh` and `review/evidence/r53-verify.log` are carried into this
revision **byte-identical**, and every new check is a new file
(`r53-r2-gate-posture.sh`/`.log`, `r53-r2-verify-rerun.log`). The blocking finding is a
completeness defect in two prompt-mandated per-candidate fields, and closing it **strengthens**
the recommendation rather than disturbing it: the crate carrying `unsafe` on its default build
path is `garde`, the one not chosen.

| Finding | Disposition in this revision |
|---|---|
| **JF-1** (blocking) — fitness gate 3's `unsafe`-posture limb and gate 5's async-runtime-coupling limb are answered for no candidate, though the prompt says "do not omit it silently" | **Accepted in full, and answered by new executed evidence rather than by carrying the raw.** A new check, `review/evidence/r53-r2-gate-posture.sh`, downloads each candidate's **published crate source at its exact version** into a `$TMPDIR` vendor directory and censuses it with `/usr/bin/grep -n -w 'unsafe'` by absolute path (checks `G01`–`G23`), then reads default features and the whole normal-dependency list for async coupling from each crate's own crates.io records (`G24`–`G31`). A new H3, **"The six fitness gates, per candidate"**, states both limbs for `serde`, `garde`, `validator`, `serde_valid`, `nutype` and `validify`, names `garde`'s three default-path `unsafe` sites explicitly, and gives the reason no exclusion follows. Superseded wording, corrected in place at two locations: "**`serde`'s own `unsafe` posture**, not audited here" in the not-proven list, and "`garde`'s and `validator`'s `unsafe` audits … are carried from `raw/opus.md`" in the not-re-read list — the audit is right that nothing was carried, and both sentences are replaced by the executed result. The word `async` did not appear in revision 1 at all; gate 5 now has its own row and its own check. |
| **JF-2** (non-blocking) — a quoted Codex sentence is truncated mid-sentence and closed with a full stop | **Accepted.** Superseded wording: "That is a deliberate diagnostic boundary, not full Zod aggregate parity." The quotation now carries Codex's clause to its end — "…not full Zod aggregate parity, and R55 decides how either class is tolerated" — which, as the audit notes, agrees with this decision's own refusal to pre-decide R55. |
| **JF-3** (non-blocking) — three container-type claims that decide the runner-up ranking carry no check identifier and are absent from the not-re-read list | **Accepted, and closed by reading the published sources rather than by demoting the claims.** The same new check asserts all three from the extracted crate sources: `toml 1.1.6+spec-1.1.0` `src/table.rs:14` `pub type Table = Map<String, Value>;` with `src/map.rs:36-37` `#[cfg(not(feature = "preserve_order"))] type MapImpl<K, V> = BTreeMap<K, V>;` (`G32`, `G33`); `garde 0.23.0` `src/error.rs:23-24,50` `Report { errors: Vec<(Path, Error)> }` and `into_inner(self) -> Vec<(Path, Error)>` (`G34`, `G35`); `validator 0.21.0` `src/types.rs:50` `pub struct ValidationErrors(pub HashMap<Cow<'static, str>, ValidationErrorsKind>);` (`G36`, `G37`). The audit is right that the `BTreeMap` claim was sourced nowhere in either raw; it now rests on the crate's own `cfg` line. The determinism sentence is rewritten to rest on the documented container type, with the single probe observation kept as corroboration rather than as ground. |
| **JF-4** (non-blocking) — the reproducibility paragraph reports a comparison whose second input was not kept | **Accepted.** `verify.sh` was rerun for revision 2 and **both** logs are now committed: `r53-verify.log` (unchanged, byte-identical to revision 1) and `r53-r2-verify-rerun.log`. The paragraph now cites the committed pair and states the diff a reader can reproduce with `diff` over two files in the tree, instead of describing a comparison only the author saw. |

**Revision history.** Revision 1 — sha256
`62f5c9f799c008af0de12deb083276454808183cbc8313acbec6ce53e0ab0cf1`, commits `9b5cdbc`
(first write) and `1a4ba6f` (three citation corrections); rejected by the round-1 judgment
audit (`review/audit-fable.md`, commit `57c1a3d`) on JF-1, with JF-2 to JF-4 non-blocking.
The round-1 empirical audit did not run. Revision 2 — this file, plus the new
`r53-r2-gate-posture` check and the second `verify.sh` log. Revision 1's `verify.sh` and
`r53-verify.log` are carried forward byte-identical.

Actor `synth-opus-2026-09-17T020714Z-d0b567b4b9f1-r2`, model `claude-opus-5`, item kind
`crate`, effort tier `focused` (two engines, no Doxa). Nothing has been published for R53, so
there is no `## Supersedes`.

Retrieval dates: **2026-09-17 (UTC)** for everything this decision checked itself through
`review/evidence/verify.sh`, and each raw report's own date for anything carried from a raw —
**2026-09-17** for both `raw/codex.md` (Codex, `gpt-5.6-terra`, sha256
`65b51d2faa31f2abeff6435508793bfe28e71d964fc24bfd9be64eac447e2758`) and `raw/opus.md`
(Claude Opus 5, sha256 `2067c9a10ddc3c802af481e7e0a4f3c57ec19e695d4501b963b61a491152821d`).
The harness reports the local date as 2026-09-16; every endpoint call in this run was made
after 04:00 UTC on 2026-09-17, so the UTC date is used throughout and is the one to
re-verify against.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate below. Nothing is excluded on licence; licence strings are reported as metadata
only. The ruling is recorded in `docs/port/OWNER-REVIEW.md` under
"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by
Q7.B)" (evidence checks `S16`, `S17`). Neither raw excluded any candidate on licence, so no
candidate needed re-evaluating on the other gates for that reason.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; **P03 builds the
template and its CI proves the recommendation.** No Rust source exists in this repository —
`rs-launch-blueprint` is still a research tree — so nothing here is an implemented result. The
one piece of Rust this synthesis compiled is a throwaway probe built under `$TMPDIR` and
deleted after the run (`## Empirical check`), which runs the candidate crates over six literal
TOML strings and settles the engines' disagreement; it is not template code and no Rust file
was written into the repository. The list of what P03 must validate closes `## Engines`.
A decision that does not survive implementation is revised against this recorded research, not
researched again from scratch.

### The recommended mechanism

**`serde` with the `derive` feature, version range `>= 1.0.229, < 2.0.0` — Cargo
`serde = { version = "1.0.229", features = ["derive"] }` — and no dedicated validation
crate.** The schema is carried in Rust's own type system; the report layer is roughly sixty
lines of the template's own library code.

| Piece | What it is | What it supplies |
|---|---|---|
| Fieldless `enum` per literal set, `#[serde(rename_all = "lowercase")]` | `OutputFormat` (`table \| json \| markdown \| name`, R66's set), `ColorChoice` (`auto \| always \| never`, py `settings.py:46`) | py's `Literal[…]` and ts's `z.enum`, plus the allowed-values hint text for free: serde emits ``unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name` `` (`S87`) |
| `NonZeroU32` for a positive integer | `output.limit` | ts's `z.number().int().positive()` (`ts@cb1cbcb2:src/lib/config.ts:40`). Observed rejection: ``invalid value: integer `0`, expected a nonzero u32`` (`S86`) — the exact case `docs/port/BASELINE-REVIEW.md` cites as the reason typed deserialization alone is not enough |
| `#[serde(try_from = "…")]` newtype | anything a type cannot express directly | the escape hatch for a future constraint; none is needed by the current schema |
| `Unvalidated` / `Valid` type-state | `Valid`'s field is private and `Unvalidated::validate` is its only constructor | F229's *before use*, enforced by the compiler rather than by call-order discipline |
| `Vec<Issue>` where `Issue = { path: String, message: String, span: Option<Range<usize>> }` | the report | zod's `issue.path.join('.')` and pydantic's `err["loc"]`, in a type the template owns rather than a 0.x crate's type in the library's public signature |
| A per-key deserialization loop over R52's `toml::Table` | each known key deserialized independently, failures pushed onto `Vec<Issue>`, survivors written into the config value | **aggregate reporting** — three bad keys produce three issues with dotted paths (`S80`–`S83`), which a serde-layered validation crate cannot do (measured for `garde` at `S74`/`S75`; see the scope note under `### Principles and implementation`) — plus a surviving partial value (`S84`), which is what leaves R55's fatal-versus-drop policy genuinely open |

**No dependency is added by this item.** `serde` is already required by R66's result-data
contract (`serde 1.0.229`, `features = ["derive"]`, library crate — evidence `S32`) and by
R52's typed read. The marginal crate cost of R53 is zero.

**Ledger rows this settles.** **F228** (`docs/port/COMMONALITY.md:232`, `DIVERGENT`, owner
`R53` — evidence `S09`): the config schema validation library. The answer is that Rust's seat
for `pydantic`/`zod` is `serde` derive plus the type system, and the library column is
deliberately empty. **F229** (`:233`, `COMMON → REUSE`, no research item — `S10`) is the
pattern row; it is inherited, not re-litigated, and its own Notes anticipated this shape
("serde's typed deserialization preserves this same pattern, so this is a substitution in
spirit, not an override" — `S12`), so **no `OVERRIDE (OV-nn)` is opened**. F229's recorded
acceptance criterion — "validation-before-use with constrained types or explicit checks, and
representative rejected values" (`S11`) — is met by the enum and `NonZeroU32` rejections above.

**What this decision does not decide.**

- *Whether an invalid key is fatal or dropped with a warning* — R55 (F238). The mechanism
  produces the issue list and the surviving partial value as two independent results
  (`S80`, `S84`), so either policy is expressible on it. This decision takes no position.
- *Whether unknown keys are tolerated* — also R55's. `#[serde(deny_unknown_fields)]` is named
  in this item's HIGH question and is **deliberately omitted**: py sets
  `model_config = {"extra": "ignore"}` on all three models and zod's `z.object` strips unknown
  keys, so both sources tolerate them. Under the per-key loop, unknown-key *detection* is free
  (any key in the table the loop did not consume), so the policy is a one-line branch rather
  than an attribute decision. Note for whoever takes it: the org CLI Design Standard's own
  R5.8 example diagnoses an unknown key (``acme config validate`` reports
  ``.acme/acme_config.toml:12 unknown key 'default-region'`` — `S36`), which points the other
  way from both sources. That tension is R55's to resolve, not this item's.
- *Whether the schema carries a `token` field at all* — R56 (F239/F240). The schema shape
  accommodates one either way.
- *Which crate parses the bytes* — R52 (F225/F226), already decided; see the coupling below.
- *The error code and exit status* — R67, consumed here as published.

**Couplings, stated rather than re-decided.**

1. **R52 (`toml-crate`) supplies what this mechanism needs, so nothing is asked of it.**
   R52 selected `toml` `1.1.6` with default features only and `toml_edit` `0.25.15` for the
   write path (`S25`, `S26`, `S27`). `raw/opus.md` passed R52 a requirement — an addressable
   intermediate value the loader can walk key by key, and a source location for a rejected key.
   Both are satisfied: `toml::Table` is the intermediate (the probe walks it, `S80`), and
   `serde_spanned` is a non-optional dependency of `toml` — it resolves as `serde_spanned
   v1.1.1` under `toml v1.1.6+spec-1.1.0` in the probe's own `cargo tree -e normal`
   (`review/evidence/r53-verify.log`, line 388) — so `toml::Spanned` can carry offsets when
   P03 wants them. **The requirement is therefore discharged, not outstanding.**
2. **Opus's re-verify trigger 1 did not fire.** It said this item's answer would change
   materially if R52 selected `toml-span` (whose `DeserError { errors: Vec<Error> }` aggregates
   natively). R52 selected `toml`, so the per-key loop stands as the aggregation mechanism.
3. **R52's re-verify trigger 6 is not tripped by this decision.** That trigger reads "R53
   concludes it needs per-field byte spans beyond `serde_spanned` and `toml::de::Error::span()`"
   (`S28`). This decision concludes the opposite: `serde_spanned`, already in `toml`'s tree, is
   sufficient, and per-field `Spanned` placement is P03's choice.
4. **R55's parallel work touches R67's `RSLB203` row, which this item's report feeds.**
   R55's Codex raw raised `CONFLICT: R67 error-taxonomy-exit-codes` against that row
   (`S29`, `S30`) and assumed of this item "independently callable declared-field validation
   plus a separately classified cross-field invariant result" (`S31`). The first half holds
   and is proven (`S80`, `S84`); the second half is vacuous for the current schema, which has
   no cross-field rule. The conflict itself is carried under `## Engines` without adjudication —
   it is R55's and R67's to settle, and **this decision emits no `CONFLICT:` line of its own**.
   One further coupling for R55 to reconcile, stated as a coupling and not as a decision made
   on R55's behalf: **R53's per-key loop supplies leaf-level dotted paths and free unknown-key
   detection** — every key present in the parsed table that the loop did not consume — which is
   exactly what R55's own re-verify trigger watches; R55 decides what to do with both, and
   nothing here constrains that choice.

**Re-verification triggers**, each mechanical enough to be checked without judgment:

1. A second constraint appears that the type system cannot hold — R56 adding a `token` with a
   length or prefix rule, a numeric key with an upper bound, or any cross-field rule. One such
   constraint is a `try_from` newtype; two or more flip the trade to the runner-up.
2. `serde` publishes a `2.0` release, or `serde-rs/serde` pull request 2891
   (`#[serde(validate = "function")]`, open and unmerged since 2025-02-11 — `S66`, `S67`)
   merges, which would give serde a validation hook and reopen the composition question.
3. R52 replaces `toml` with a parser that has no addressable intermediate value, or adds one
   with native multi-error deserialization.
4. A RustSec or OSV advisory is filed against `serde`, `serde_core` or `serde_derive`
   (`https://rustsec.org/packages/serde.html` answered HTTP 404 on 2026-09-17, with `atty`,
   `time` and `openssl` answering 200 in the same run as controls — `S59`, `S60`, `S61`).
5. `serde`'s published `rust_version` (1.56 on 2026-09-17, `S47`) rises above the then-current
   stable-minus-2 floor.
6. Adopting the runner-up: `garde` crosses its 6-month release trigger on 2026-11-23 with its
   unanswered-issue run unbroken, which moves the runner-up seat to `validator`.

Otherwise at the scheduled date on the final line of this section, which is 90 days from this run — `recent_downloads` is
a rolling 90-day window, so every popularity figure here ages out together.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**
A configuration file is untrusted input authored by hand. The requirement both source repos
implement is: *no value read from that file reaches program logic until it has been checked
against a declared schema, and a value the schema rejects produces a report that names the
offending key.* Agreement is required at the level of an **architectural pattern plus an
observable standard**, not a library. F229 records the pattern
(`docs/port/COMMONALITY.md:233`, `COMMON → REUSE`, `S10`) and its 2026-09-04 baseline review
supplies the acceptance criterion (`docs/port/BASELINE-REVIEW.md`, row `retained` at `S13`,
finding line at `S14`), precisely because typed deserialization alone accepts values the
sources reject — "a derived integer accepts values ts `config.ts:40` rejects with
`.positive()`" (`S15`). F228 (`:232`, `DIVERGENT`, `S09`) is the library seat this item fills.

**What must agree, and what may vary.** Both raws reached the same table independently.

| Must agree (observable from outside) | May vary (mechanism) |
|---|---|
| A value outside a key's allowed set is rejected, never silently coerced | Whether the check is a type, a derive attribute, or a hand-written predicate |
| The report names the offending key by its dotted path | Whether the path comes from a validator, a parser span, or a hand-built string |
| Every invalid key in the document is reported, not only the first | Whether aggregation happens in the parser, a validation crate, or a per-key loop |
| No value is used before the check runs | Whether that is enforced by discipline, a type-state, or call order |

The third row is an **addition** to F229's recorded criteria, proposed by `raw/opus.md` as a
`BASELINE-REVIEW: F229` finding and adopted here; its disposition and evidence are under
`## Engines`. It matters because both sources aggregate and differ only in what they do with
the aggregate: py `b08bccfb:src/py_launch_blueprint/core/settings.py:158-176` iterates
`exc.errors()` and pops each offending `(section, key)` in turn — a loop that is only possible
because pydantic returned them all — while ts `cb1cbcb2:src/lib/config.ts:126-129` maps over
every `result.error.issues` entry and joins them into one message. **py's per-key drop policy
is unimplementable on a fail-fast mechanism**, which is why the aggregate is a requirement and
not a nicety. Both raws read these files at the programme pins; this synthesis did not re-read
the pinned source repositories, and says so under `## Engines`.

**The org CLI Design Standard v1.4.14** (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read at that blob by check `S35`) binds this
port by the owner's ruling of 2026-09-14. Four of its rules bear here:

- **R5.8** — a tool with project/user config "**SHOULD** validate config files with precise
  file/key diagnostics and **SHOULD** provide `acme config validate`" (`S35`). Two obligations
  follow. *Precise file/key diagnostics*: the per-key loop's dotted path is the key half
  (`S81`–`S83`), and the file/line half is what `toml::Spanned` in the intermediate supplies —
  the standard's own example shows a line number (`S36`). *A `config validate` subcommand*:
  the validation pass must be callable on its own, without executing a command, which the
  `Unvalidated::validate` entry point is by construction.
- **R7.6** — errors "**SHOULD** be lowercase-first, free of a trailing period, name the
  offending input in quotes, and state a next step where possible" (`S37`). serde's generated
  messages already satisfy the first three: ``unknown variant `yaml`, expected one of `table`,
  `json`, `markdown`, `name` `` is lowercase-first, has no trailing period, quotes the
  offending input, and names the allowed set — which is the "next step" py builds by
  reflection at `settings.py:129-135`.
- **R7.8** — under a machine format an error is "a single JSON object" (`S38`), which is
  R67's envelope. A `Vec<Issue>` renders into one `hint` string; it does not become a second
  JSON document or an array member, because R67 defines exactly three keys and this item adds
  none.
- **R7.12** — the error-code catalog (`S39`) is R67's, consumed unchanged.

**The standard fixes no validation crate, and that silence is load-bearing.** Its Rust
appendix names config *loaders* — "Pair with `figment`/`config` crates for the precedence
chain and `directories`/`etcetera` for XDG paths" (`S40`) — while the words `garde`,
`serde_valid`, `validify`, `nutype`, `pydantic` and `zod` appear nowhere in the document
(`S41`), and the word "validator" appears **zero** times, case-insensitive
(`/usr/bin/grep -c -i`, `S42`). The mechanism choice is therefore this template's to make and
is not org-locked — the same conclusion R52 reached about TOML crates.

**Architectural alternatives, compared before any library.** Both raws agree on the four
alternatives; they disagree on which wins. Each row's aggregation column is an executed
result, not a prediction.

| Alternative | What it is | Type errors aggregated? | Constraint errors aggregated? | Evidence |
|---|---|---|---|---|
| 1. Parse-don't-validate (types carry the invariants) | fieldless enums, `NonZeroU32`, `try_from` newtypes; serde rejects at deserialization; no separate step | **No** — one error per document | n/a (there is no separate constraint layer) | `S72`, `S73` |
| 2. Deserialize, then run a validation crate (the pydantic/zod shape) | `garde` or `validator` layered over the same serde types | **No** — the validator never runs (measured for `garde`; scope note below) | Yes | `S74`, `S75`, `S76`, `S77` |
| 3. Aggregate at the parse layer | `toml-span`'s `DeserError { errors: Vec<Error> }` | Yes, with spans | Yes | out of scope — this is R52's seat, and R52 chose `toml` |
| 4. **Per-key deserialization over an intermediate table** | parse to `toml::Table`, deserialize each known key independently, push `(path, message)` per failure | **Yes** | **Yes** | `S80`–`S85` |

Alternative 2's row is the decisive one and it was **measured, not argued**. For a document
carrying three bad keys at once (`format = "yaml"`, `limit = "abc"`, `color = "rainbow"`),
`serde`'s derived `Deserialize` early-returns on the first failure — the probe records exactly
one error (`S72`) — so a `garde`-annotated struct never materializes and
`garde::Validate::validate` is never reached: `P2_GARDE_REACHED = false`,
`P2_GARDE_REPORT_ENTRIES = 0` (`S74`, `S75`). Adding the crate changes the report from one
error to one error. Recorded in `garde`'s favour, because it is true and relevant to the
runner-up condition: once every *type* is accepted, `garde` does aggregate *constraint*
errors — two entries, `limit: lower than 1` and `workspace: length is lower than 1` (`S77`,
`S78`, `S79`). The capability is real; it is simply not the capability this schema lacks.

**The scope of that finding, stated once here and referred to from everywhere else it is
used.** What was *measured* is `garde` 0.23.0 behind `serde` 1.0.229 and `toml` 1.1.6, on this
host, for one document. What *follows structurally* is the general form: any validation crate
whose rules run **after** a derived `Deserialize` has produced the value cannot report a type
error, because the derived code returns before the value exists — and `serde::de::Error`'s
constructors each return one `Self`, so what it returns is one error, not a set. That is the
architecture of `garde`, `validator`, `serde_valid` and `validify` alike. It was **not
separately measured for `validator` or `serde_valid`**, and where this decision says "no
serde-layered validator aggregates type errors" it means the inference just stated, resting on
the `garde` measurement plus serde's documented derive behaviour — not four measurements.

Alternative 4 delivers what both sources do: the same document yields three issues with dotted
paths — ``output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`,
`name` ``, ``output.color: unknown variant `rainbow`, expected one of `auto`, `always`,
`never` ``, `output.limit: invalid type: string "abc", expected a nonzero u32` (`S81`–`S83`) —
alongside the surviving partial value `ConfigFile { output: OutputSettings { format: Table,
color: Auto, limit: None } }` (`S84`). The issue list and the partial value are independent
results, which is precisely what keeps R55's choice open.

**Two independent constraints force the intermediate table, which answers the prompt's MEDIUM
integration question.** First, aggregation, per the table above. Second, **R67's catalog
splits `RSLB202` "config document unparsable" → 2 from `RSLB203` "config value invalid" → 2**
(`S19`, `S20`), and with the `toml` crate those two are indistinguishable from the error value:
`toml::de::Error` has no kind, variant or discriminant, and `impl serde::de::Error for Error`
routes every serde-originated type failure into the same type, so separating them would mean
string-matching `message()`. A two-stage parse decides it structurally, and the probe confirms
the boundary holds: an unterminated table header fails as a `toml::Table`
(`P6_SYNTAX_AS_TABLE_OK = false`, `S88`) while the same bytes that carry three bad *values*
succeed as a `Table` (`S89`) and fail only as the typed struct (`S90`). So the loader is
`toml::from_str::<toml::Table>` → `RSLB202` on failure; `Unvalidated::validate` → `RSLB203` on
failure. The per-key loop is the second half of a structure R67 requires anyway.

**Determinism, which a CLI needs and a `HashMap` cannot give.** R52 selected `toml` with
default features and explicitly **not** `preserve_order` (`S27`), and the crate's own
published source decides what that means: `src/table.rs:14` declares
`pub type Table = Map<String, Value>;` (`G32`) and `src/map.rs:36-37` selects that map's
backing with `#[cfg(not(feature = "preserve_order"))] type MapImpl<K, V> = BTreeMap<K, V>;`
(`G33`). So `toml::Table` is `BTreeMap`-backed under R52's feature selection and iterates in
sorted key order — **the ground is the crate's `cfg` line, not an inference from behaviour**.
The probe corroborates it on one document, recording
`P4_TABLE_KEY_ORDER = ["color", "format", "limit"]` for a file written in the order
`format, limit, color` (`S85`). Two consequences, both worth stating. The report order is
**deterministic and therefore snapshot-testable**, which `validator`'s
`ValidationErrors(pub HashMap<Cow<'static, str>, ValidationErrorsKind>)` —
`validator 0.21.0` `src/types.rs:50`, read at the published version (`G36`), and not a
`BTreeMap` (`G37`) — is not. And the single error a fail-fast mechanism reports is
**not necessarily the first key in the user's file**: for the three-bad-key document written
`format, limit, color`, serde's derive reported `color` — the file's third key — at document
line 4 (`S73`, `P1_SERDE_DERIVE_DISPLAY_FIRSTLINE = TOML parse error at line 4, column 9`),
which is consistent with the sorted iteration order `S85` records. **That is one observation on
one document, not a rule**; no ordering guarantee is claimed and none was tested across inputs.
It is enough for the point being made: the one error a user is shown need not be the first
mistake they made, which is the concrete cost of fail-fast.

**Where a different ecosystem needs a different design.** py and ts have a runtime
type-erasure problem this template does not: a Python `dict` or a JS object carries no
declared field types, so a schema library must re-declare them at runtime, and re-declaring
them is the natural place to also declare `.positive()`. Rust declares them at compile time,
so the constraint layer collapses into the type layer for everything a type can express. What
Rust does *not* get free is exactly what a runtime schema walk gives py and ts free:
aggregation. The port therefore moves work in the opposite direction from the naive mapping —
**less** library for constraints, **more** deliberate structure for reporting.

**Practice evidence, at the strength it actually supports.** `raw/opus.md` surveyed seven
well-regarded Rust CLI or CLI-adjacent programs that read a user-editable TOML config and must
report a bad value to a human, and found seven of seven using `serde` derive with no
validation crate. This synthesis re-ran that census against each project's **`Cargo.lock` at
the pinned commit** rather than its root `Cargo.toml`, because a lockfile covers every
workspace member and every transitive dependency, so absence there is a strictly stronger
claim (`S68`–`S71`):

| Project (pinned commit) | Resolved packages | `serde` | TOML family | `validator`/`garde`/`serde_valid`/`nutype`/`validify` |
|---|---|---|---|---|
| `alacritty/alacritty` @ `d692748d3f61` | 292 | yes | `toml`, `toml_edit` | **0** |
| `starship/starship` @ `4ff40d066af2` | 428 | yes | `toml`, `toml_edit` | **0** |
| `helix-editor/helix` @ `079a789e8cb0` | 337 | yes | `toml` | **0** |
| `zellij-org/zellij` @ `474ea0cef620` | 538 | yes | `toml` | **0** |
| `jj-vcs/jj` @ `e6dd2c0d60f2` | 517 | yes | `toml` | **0** |
| `rust-lang/mdBook` @ `afe6eb8836bf` | 273 | yes | `toml` | **0** |
| `EmbarkStudios/cargo-deny` @ `79d7f54dc1bf` | 211 | yes | `toml-span` | **0** |

**2,596 resolved packages across seven lockfiles; zero occurrences of any validation crate**
(counts from `/usr/bin/grep -c` over each whole lockfile, never a truncated prefix; totals at
`S70`, `S71`). Where such a project needs more than fail-fast type rejection it writes the pass
itself: `cargo-deny` — the closest analogue of all, a Rust CLI whose entire job is reading a
`deny.toml` and emitting diagnostics about it — declares its own
`pub trait UnvalidatedConfig { type ValidCfg; fn validate(self, ctx: ValidationContext<'_>) -> Self::ValidCfg; }`
with a `ValidationContext` holding `diagnostics: &'ctx mut Vec<diag::Diagnostic>`
(`raw/opus.md`, read at the pinned commit above on 2026-09-17; this synthesis verified the
lockfile, not that source file — see `## Engines`). **The limit of this evidence, stated:**
seven projects is a cohort, not a census of the ecosystem, and the counter-evidence is equally
clear about where validation crates *do* live — the top reverse dependencies of `garde` are
`garde-actix-web`, `axum-valid`, `apistos-gen` and `schemars`, and of `serde_valid`
are `axum_serde_valid` and `swagger`: HTTP request-body validators, not CLI config validators.

**Maturity, dependability, integration cost.** Every figure below carries its endpoint and was
retrieved 2026-09-17; download counts and star counts are volatile and are recorded, not
asserted on an exact value (`## Empirical check`).

| Crate | 90-day dl | All-time dl | Stars | Newest non-yanked | Declared MSRV | Non-optional normal deps | Maintenance |
|---|---|---|---|---|---|---|---|
| `serde` | 308,308,063 | 1,402,408,950 | 10,826 | 1.0.229, 2026-07-18 | 1.56 | **1** (`serde_core`) | **active** |
| `garde` | 1,800,800 | 4,321,159 | 898 | 0.23.0, 2026-05-23 | 1.87 | **2** (`compact_str`, `smallvec`) | **at-risk** (signal below) |
| `validator` | 11,775,106 | 65,165,401 | 2,516 | 0.21.0, 2026-07-27 | 1.88 | **6** (`idna`, `regex`, `serde`, `serde_derive`, `serde_json`, `url`) | **active** |
| `serde_valid` | 1,579,995 | 4,363,036 | 90 | 3.1.2, 2026-09-10 | *none declared* | **10**, including `thiserror ^1.0` | **active** |

Endpoints: `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`); `GET https://crates.io/api/v1/crates/<name>/versions` (newest with
`yanked: false`: `num`, `created_at`, `rust_version`, `license`);
`GET https://crates.io/api/v1/crates/<name>/<version>/dependencies` (`kind == "normal"`,
`optional == false`); `gh api repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`);
`gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` (`.total_count`, never
`open_issues_count`). Checks `S43`–`S58`, `S62`, `S63`.

Three of those numbers decide something. `validator`'s six non-optional dependencies include
`regex`, `idna`, `url` and `serde_json`, none of which this use case needs and none of which a
feature flag can remove (`S54`, `S55`). `serde_valid` carries a non-optional `thiserror ^1.0`
(`S56`), which is semver-incompatible with R67's library-crate `thiserror` 2.x (`S24`), so a
library crate adopting it would compile two major versions of its own error-derive crate.
`garde`'s tree is the smallest of the three and it declares no `default` feature key at all,
so `features = ["derive"]` is the entire surface (`S57`, `S58`) — which is why it, and not
`validator`, is the runner-up.

**The six fitness gates, per candidate.** Revision 1 answered gates 1, 2, 4 and 6 and the
advisory half of gate 3, and left gate 3's `unsafe`-posture limb and gate 5's async-coupling
limb unstated for every candidate; the prompt's tier guidance forbids that ("Apply every
fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and
the reason in the answer; do not omit it silently"), and revision 2 closes it. Every cell
below is executed evidence from this run unless the cell says otherwise.

| Gate | `serde` 1.0.229 | `garde` 0.23.0 | `validator` 0.21.0 | `serde_valid` 3.1.2 | `nutype` 0.7.0 | `validify` 2.0.0 |
|---|---|---|---|---|---|---|
| **1 · licence** | `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`. Strings recorded as metadata only, `S16`/`S17`: `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `MIT` | same ruling; `MIT` | same ruling; `MIT` |
| **2 · MSRV ≤ 1.96 floor** | declares **1.56** — passes (`S47`) | declares **1.87** — passes (`S48`) | declares **1.88** — passes (`S49`) | declares **none** — evidence gap, not a breach (`S50`) | declares none | declares none (`S51`) |
| **3a · RustSec advisory** | none; HTTP 404 with 200 controls in the same run (`S59`, `S60`, `S61`) | none, same method | none, same method | none, same method | none, same method | none, same method |
| **3b · `unsafe` posture** | **2 `unsafe` blocks** in its own `src/`, both `str::from_utf8_unchecked` — `src/core/format.rs:16` and `src/core/ser/impls.rs:821` (`G01`, `G02`); its only non-optional dependency `serde_core` 1.0.229 mirrors the same two (`G03`); `serde_derive` has **0** (`G04`). No crate-level `unsafe_code` lint | **7 matching lines** (`G05`), of which **4** are inside `src/rules/pattern.rs`'s `regex_js_sys` module, gated `#[cfg(all(target_arch = "wasm32", target_os = "unknown"))]` and therefore absent from an `ubuntu-latest`/`macos-latest` build (`G07`, `G16`, `G17`). **Three are on the default path**: `src/error/rc_list/mod.rs:93` `unsafe { transmute(&next.value) }` (`G08`, `G09`) in the un-gated `mod rc_list;` that backs `garde::error::Path` (`G18`, `G19`), and two in the un-gated `pub mod i18n;` (`G06`, `G20`, `G21`) — a raw-pointer deref and a lifetime `transmute` behind a stated stack-guard SAFETY argument. `garde_derive` adds **2** (`G10`). No crate-level `unsafe_code` lint (`G22`) | **0** anywhere in its `src/` (`G11`). No crate-level `unsafe_code` lint (`G23`) | **0** anywhere in its `src/` (`G12`) | **3** matches, all of them **doc-comment prose** in `src/lib.rs` describing its opt-in `new_unchecked` feature, not compiled `unsafe` (`G14`, `G15`) | **0** anywhere in its `src/` (`G13`) |
| **4 · ubuntu + macOS** | no upstream macOS leg (Ubuntu and Windows only); satisfied by portability, receipt is the template's own `macos-latest` job | no upstream macOS leg | no upstream macOS leg | no upstream macOS leg | no upstream macOS leg | not evaluated — excluded on maintenance |
| **5a · default features** | `default = ["std"]`, so `features = ["derive"]` is additive (`G24`, `G25`) | **no `default` key at all**, so `features = ["derive"]` is the whole surface (`G26`) | no `default` key (`G27`) | `default = ["i128"]` (`G28`) | `default = ["std"]` (`G29`) | no `default` key (`G30`) |
| **5b · async-runtime coupling** | **none.** 2 normal dependencies, 0 matching an executor or reactor | **none.** 13 normal dependencies (optional included), 0 matching | **none.** 9 normal dependencies, 0 matching | **none.** 13 normal dependencies, 0 matching | **none.** 1 normal dependency, 0 matching | **none.** 12 normal dependencies, 0 matching |
| **6 · binary size / compile cost** | already in the tree for R52 and R66, so **zero marginal crates**; `serde_derive` is a proc macro and costs compile time, not binary bytes | adds `garde`, `garde_derive`, `compact_str`, `smallvec` — the smallest addition of any validation crate (`S53`) | adds `regex` (and its automata/syntax subtree), `idna`, `url`, `serde_json` unavoidably (`S54`, `S55`) | adds all of `validator`'s weight plus `indexmap`, `itertools`, `num-traits`, `unicode-segmentation` and a second major of `thiserror` (`S56`) | one dependency, `nutype_macros` | not evaluated |

Gate 5b's method, stated because a null result is only evidence if the search was real: the
whole **normal** dependency list of each crate — optional entries included, since a feature
flag can turn one on — was matched against
`^(tokio|async-std|smol|futures|futures-[a-z-]+|async-global-executor|async-io|async-executor|actix-rt)$`.
Across all six candidates the total is **0** (`G31`). Every candidate in this field is
synchronous, and none of them can drag an async runtime into a CLI's tree.

**What follows from gate 3b, and what does not.** **No candidate is excluded on it.** R06
(`research/topics/06-unsafe-code-policy/DECISION.md`) forbids `unsafe` in the **template's own
code** through `[workspace.lints.rust] unsafe_code = "forbid"` and explicitly makes no claim
about the dependency tree, because Cargo compiles dependencies with `--cap-lints allow`. The
recommended crate is not `unsafe`-free either — `serde` carries two `str::from_utf8_unchecked`
calls, which is unremarkable in a crate with `serde`'s audit exposure — so the finding does
not separate the recommendation from the runner-up in the template's favour by accident. What
it does do is put a fact in front of anyone acting on re-verify trigger 6: **adopting `garde`
adds three `unsafe` sites on the default build path**, one of them a `transmute` in the
allocator-free list that backs its error `Path`. That is not a reason to reject `garde` — it
carries no advisory (`S59`) and its `SAFETY` comments state their arguments — but it is a fact
the runner-up's adopter is entitled to know before the trade is made, and revision 1 did not
supply it.

**Performance is not a discriminator and none is manufactured.** Config validation runs once
per process over a file of tens of lines. No candidate publishes a benchmark for that workload,
none was run here, and comparing library microbenchmarks across unlike harnesses would violate
the prompt's instruction not to infer a fastest option from unlike benchmarks. The measurable
cost is compile time and dependency count, addressed above by dependency count; **no
wall-clock compile time or binary size was measured and none is claimed.**

**The ranked runner-up, and the condition under which it wins.**
**`garde`, `>= 0.23.0, < 0.24.0`** — `garde = { version = "0.23.0", default-features = false,
features = ["derive"] }`, layered over the same serde schema types and called at the same point
the hand-written pass would run. It wins **the moment the schema acquires two or more
constraints the type system cannot hold**: a string key with a length or pattern bound (R56
adding a `token` with a minimum length or prefix rule), a numeric key whose valid range is not
merely "nonzero", or any cross-field rule. At that point the hand-written pass begins
reimplementing `garde`'s rule set with worse messages. `garde` is preferred over `validator`
for that seat on three grounds: its `Report` holds `errors: Vec<(Path, Error)>` and hands it
back with `into_inner(self) -> Vec<(Path, Error)>` — `garde 0.23.0` `src/error.rs:23-24` and
`:50`, read at the published version (`G34`, `G35`) — an ordered sequence, where `validator`'s
`ValidationErrors` wraps an unordered `HashMap` (`G36`) a CLI must sort before printing; it
adds two small non-optional crates where `validator` adds `regex`, `url`, `idna` and
`serde_json` unavoidably (`S53`, `S54`); and its `Unvalidated<T>`/`Valid<T>` type-state is the
same structure this decision recommends building by hand.

**`garde` must be re-examined before adoption, not merely preferred, because of one concrete
maintenance signal.** Its `at-risk` rubric state does **not** rest on release age — 0.23.0 was
3.8 months old on 2026-09-17, so the 6-month trigger has not fired. It rests on this: the only
commits on the default branch after the 0.23.0 release are **two**, and **both** are the same
Dependabot GitHub-Actions bump and its merge, from 2026-05-29
(`gh api "repos/jprochazk/garde/commits?since=2026-05-23T16:00:00Z&per_page=100"` — `S64`,
`S65`). `raw/opus.md` adds, from a sample this synthesis did not re-run, that 0 of the 10 most
recently opened issues drew any comment at all, spanning 2026-01-17 to 2026-08-22. Counter-
evidence recorded in fairness: the repository is not archived (`S62`), `pushed_at` reads
2026-07-31 (a push to some branch, not a default-branch commit), it carries no RustSec advisory
(`S59`), and its history is a single maintainer's batched cadence (0.22.0 2025-01-19, 0.22.1
2025-11-30, 0.23.0 2026-05-23). It is **not** `dormant`: no unpatched advisory, no broken build
on current stable, no maintainer notice.

**What the pick gives up, and why each cost is accepted.**

- *Versus `garde`* — a maintained rule library (`length`, `range`, `pattern`, `contains`,
  `prefix`, `email`, `url`, `dive`, `custom`, conditional `if`), a ready-made type-state, and
  a `Path` type. Accepted because the current schema needs exactly zero of those rules: three
  literal sets and one positive integer are types. The cost is real and bounded by the
  runner-up condition above. What the pick gains and `garde` does not offer at all is
  aggregation of *type* errors (`S74`, `S75`) — the item's central requirement.
- *Versus `validator`* — a larger adopter set and a better maintenance record. Accepted
  because of the six unavoidable, unused dependencies, and because a `HashMap` error container
  has no defined iteration order, so CLI stderr output would need sorting before it could be
  snapshot-tested.
- *Versus `serde_valid`* — the field's best maintainer responsiveness and a nested-JSON error
  tree that would map cleanly onto an HTTP problem document. Accepted because of the
  `thiserror ^1.0` collision (`S56`, `S24`) and because a JSON-shaped error is a poor fit for
  a CLI's line-oriented stderr.
- *Versus a dependency in general* — **this recommendation ships code rather than a
  dependency.** Roughly sixty lines (the type-state, `Issue`, the per-key loop) become the
  template's to test and maintain. Accepted because those lines sit in the crate's own public
  API where owning the type is an asset — R04's public-API-surface enforcement means any type
  a validation crate's derive forces into a signature (`garde::Report`,
  `validator::ValidationErrors`) becomes part of the library's semver surface, and a 0.x
  crate's breaking change then becomes the library's — and because the two-stage split R67
  requires means most of those lines get written either way. **It is a maintenance transfer,
  not a free saving**, and P03 should hold it to the test coverage a dependency would have
  earned.

**Fit across the three surfaces.** *CLI* — the surface that drives the answer: it is where a
human edits the file, where R67's `RSLB202`/`RSLB203` split lands, where R55's tolerance policy
applies, and where a deterministic, snapshot-testable stderr message matters. *Library* — the
schema types are part of the public API, so R67's `thiserror`-not-`anyhow` layering (`S24`) and
R04's surface enforcement both bind; a project-owned `Vec<Issue>` keeps the semver surface the
template's. *Web* — request-body validation over an extractor is a different problem (many
small untrusted payloads per second, arbitrary shapes, an aggregate field-error response
mapping onto RFC 9457), and it is exactly where `garde` and `serde_valid` live. **This item's
"no validation crate" answer is scoped to the config file and must not be read as a
workspace-wide ban**: if the web surface wants request validation, that is R69/R70's decision
and `garde` is a live candidate there. The config schema types themselves are format-agnostic
and shared unchanged across all three surfaces.

**Reference implementations.** `EmbarkStudios/cargo-deny` at `79d7f54dc1bf` for the
`UnvalidatedConfig` → `ValidCfg` plus accumulated-diagnostics structure; `rust-lang/mdBook` at
`afe6eb8836bf` and `helix-editor/helix` at `079a789e8cb0` for serde-derive-only TOML config in
a Rust-project-owned and a widely used editor tool respectively (`S68`, `S69`). For the
type-state itself, `garde`'s own `Unvalidated<T>`/`Valid<T>` is the maintained model the
hand-written version mirrors.

**Minimal realistic example (proposed shape; the probe ran this logic, the template does
not exist).** Field names come from resolved sibling decisions rather than being invented:
`output.format` uses R66's `table | json | markdown | name` (`S33`), `output.color` uses py's
`auto | always | never`, `output.limit` carries ts's `.positive()`.

```rust
// crates/rs-launch-blueprint/src/config/schema.rs  — P03 writes this; it does not exist.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat { #[default] Table, Json, Markdown, Name }

#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default)]   // missing keys take Default; `deny_unknown_fields` is deliberately NOT set
pub struct OutputSettings {
    pub format: OutputFormat,
    pub color:  ColorChoice,
    pub limit:  Option<NonZeroU32>,
}

/// One rejected key. `path` matches zod `issue.path.join('.')` and pydantic `err["loc"]`;
/// `span` feeds R67's optional `hint`.
#[derive(Debug, Clone)]
pub struct Issue { pub path: String, pub message: String, pub span: Option<Range<usize>> }

/// `Valid`'s field is private and this is its only constructor, so F229's "before use"
/// is a compiler-checked property rather than a convention.
impl Unvalidated {
    pub fn validate(self) -> (ConfigFile, Vec<Issue>) { /* per-key loop over toml::Table */ }
}
```

`validate` returns the partial value **and** the issue list rather than
`Result<Valid, Vec<Issue>>`, deliberately: making any issue fatal would pre-decide R55, and
R55's Codex raw is contesting exactly that. Whether the caller promotes `(ConfigFile, [])` to
`Valid`, warns and drops per key, or fails the file is R55's to choose on top of this shape.

**File-level changes P03 will make.** No file below exists yet. `Cargo.toml` (workspace):
`serde = { version = "1.0.229", features = ["derive"] }` — already present for R66 and R52, so
no new entry. `crates/rs-launch-blueprint/src/config/schema.rs`: the typed schema and one
fieldless enum per literal set. `crates/rs-launch-blueprint/src/config/validate.rs`: the
`Unvalidated`/`Valid` type-state, `Issue`, the per-key loop, and the writable-key list that py
builds by reflection at `settings.py:76-84` and Rust gets from the enum's own variants.
`crates/rs-launch-blueprint/src/config/loader.rs` (shared with R52/R54/R55): the two-stage
boundary. `crates/rs-launch-blueprint/tests/config_schema.rs`: the rejected-value table as the
executable form of F229's criterion. No `build.rs`, no proc-macro crate of the template's own,
no feature flag, no new CI job, and no entry in R42's tool-provisioning surface — this item
adds no binary to `PATH`.

re-verify: 2026-12-16, or earlier on any of — a second constraint appearing that the type system cannot express (R56 adding a constrained token, a bounded numeric key, or any cross-field rule); serde publishing 2.0, or serde-rs/serde pull request 2891 merging; R52 replacing toml with a parser that has no addressable intermediate value or one with native multi-error deserialization; a RustSec or OSV advisory against serde, serde_core or serde_derive; serde's published rust_version rising above the then-current stable-minus-2 floor; or garde reaching 2026-11-23 without a release, which moves the runner-up seat to validator.

## Parameters

R53 owns no registry parameter: the binding prompt's `## Couplings` block carries an empty
`- owns:` line (`S01`), so this decision declares none, and `docs/port/PARAMETERS.md` lists no
`R53` owner. Its one consumed parameter is R67's, named on the prompt's
`- consumes: R67: error-taxonomy-exit-codes` line (`S02`).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No `CONFLICT:` line is emitted by this item.** Neither raw raised one, and nothing in this
recommendation requires a consumed parameter to change; R67's contract is satisfied as
published. R55's Codex raw *did* raise a `CONFLICT:` against R67's `RSLB203` row; it is R55's
line, is carried verbatim with this item's disposition under `## Engines`, and is not
restated as a parameter declaration here.

**How the assumed parameters bear on the decision.** `error-taxonomy-exit-codes` bears in four
places. Its `RSLB202` / `RSLB203` split is what forces the two-stage parse, because
`toml::de::Error` carries no kind discriminant (`S19`, `S20`, and the structural boundary
measured at `S88`–`S90`). Its envelope — one stderr JSON object `{"error":{"code","message",
"hint"?}}` with stdout byte-empty on the error path (`S22`) — is what a `Vec<Issue>` must
render into, as one `hint` string rather than a new field; this item defines no new envelope
key. Its requirement that `hint` "must be able to name the offending input per R7.6" (`S23`)
is what makes the dotted path load-bearing and the span worth carrying. Its layering rule —
`thiserror` in the library crate, `anyhow` in binary crates only (`S24`) — is what turns
`serde_valid`'s non-optional `thiserror ^1.0` into a real cost rather than a detail (`S56`).
`msrv-policy` sets the floor at **1.96** against current stable 1.98.1 (2026-09-01, from
`[pkg.rust] version` in `https://static.rust-lang.org/dist/channel-rust-stable.toml`,
retrieved 2026-09-17), and `serde` declares 1.56 (`S47`), well under it. `rust-edition = 2024`
independently needs 1.85 or newer and is what the probe compiled under.
`target-os-matrix` is the gate-4 obligation discussed under `## Engines`: no candidate
publishes macOS test evidence upstream, so the template's own `macos-latest` job is the
receipt, and this synthesis ran on one macOS host, which is not that matrix. `license` is
recorded but not evaluated for any dependency, per the 2026-09-12 owner ruling (`S16`, `S17`).

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4 (build 25E246),
`Darwin 25.4.0 arm64`, `jq-1.8.2`, `gh version 2.98.0`, `grep (BSD grep, GNU compatible)
2.6.0-FreeBSD` at `/usr/bin/grep`. **This is the local stable toolchain, not the MSRV floor:
compiling under 1.98.0 does not prove the recommendation builds under 1.96**, which is P03's
`cargo +1.96 check --workspace` to run once a lockfile exists.

**Commands and working directory.** Two scripts, run from the repository root. The first is
revision 1's and is carried into revision 2 **byte-identical**, with its log; the second is
new in revision 2 and answers judgment findings JF-1 and JF-3.

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
R=research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence

shellcheck "$R/verify.sh"                 && "$R/verify.sh"              > "$R/r53-verify.log" 2>&1
shellcheck "$R/r53-r2-gate-posture.sh"    && "$R/r53-r2-gate-posture.sh" > "$R/r53-r2-gate-posture.log" 2>&1
"$R/verify.sh" > "$R/r53-r2-verify-rerun.log" 2>&1   # the JF-4 second log, kept
```

**Observed result.** `shellcheck` exits 0 with no finding on **both** scripts. `verify.sh`
exits **0** — **117 checks run, 0 failures, 0 skips** — and `r53-r2-gate-posture.sh` exits
**0** — **37 checks run, 0 failures, 0 skips**. The full outputs are the committed
`review/evidence/r53-verify.log`, `review/evidence/r53-r2-gate-posture.log` and the rerun
`review/evidence/r53-r2-verify-rerun.log`. **154 assertions in total, none failing, none
skipped on this host.**

**What the revision-2 check adds, and how it reads its sources.** `r53-r2-gate-posture.sh`
answers the two gate limbs revision 1 left unstated, and it does so from **published crate
source at an exact version** rather than from documentation or from a raw report. For each of
`serde` 1.0.229, `serde_core` 1.0.229, `serde_derive` 1.0.229, `garde` 0.23.0, `garde_derive`
0.23.0, `validator` 0.21.0, `serde_valid` 3.1.2, `nutype` 0.7.0, `validify` 2.0.0 and (for
JF-3's `Table` claim only) `toml` 1.1.6+spec-1.1.0, it downloads the `.crate` tarball from
`https://crates.io/api/v1/crates/<name>/<version>/download`, extracts it into a `$TMPDIR`
vendor directory deleted by an `EXIT` trap, and censuses it with `/usr/bin/grep -n -w 'unsafe'`
by absolute path over every `.rs` file `find(1)` locates — printing **every matching line
beneath its count**, so the count is auditable against the listing rather than taken on trust,
and never from a `head`-truncated prefix. Gate 5 is read from
`GET https://crates.io/api/v1/crates/<name>/<version>` (the `default` feature key) and
`.../dependencies` (the whole `kind == "normal"` list, optional entries included). **Nothing is
compiled, and no file is written into the repository.** Because crates.io releases are
immutable, every count in that log is reproducible byte-for-byte; a rerun differs only in the
retrieval-date line and the eleven lines carrying the PID-bearing vendor path, which is what a
rerun of it during this revision showed.

**What the script verifies, and how it is kept honest.** It sets `set -uo pipefail` so a
failing command inside a pipeline cannot be masked by a succeeding one; every load-bearing
claim goes through an assertion that compares the **content** expected, so a check that cannot
fail is not counted as evidence; `/usr/bin/grep` is invoked by absolute path everywhere and is
named beside every count, because a typed `grep` in an agent shell may be `ugrep` honouring
`.gitignore`, which would silently turn a census into a subset; no count anywhere comes from
`head`-truncated output; the exit status is the number of failed assertions; and sections
needing something a clean `git archive HEAD` extraction does not have — the sibling
`cli-standards` clone, `cargo`, `gh`, the network — print `SKIP <name>` by name rather than
failing. Adopter lockfiles are read at pinned commits, never at a moving branch. No token and
no environment value is printed; `gh` is used through its own authenticated CLI.

**The six behavioural probes (section 9 of the log) are the check that decides this item.**
They are a throwaway spike, permitted by the role for verification and recorded here with its
toolchain: a three-dependency crate written into `$TMPDIR/r53-verify.$$/probe`, pinned to
`serde = "=1.0.229"`, `toml = "=1.1.6"` and
`garde = { version = "=0.23.0", default-features = false, features = ["derive"] }` (resolved
graph confirmed by `cargo tree -e normal`, 39 lines — `S91`, `S92`, `S93`), compiled and run
by `cargo run --quiet`, and deleted by the script's `EXIT` trap. **Nothing was written into the
repository and no template file was created.** Observed stdout, verbatim:

```text
P1_SERDE_DERIVE_ERROR_COUNT = 1
P1_SERDE_DERIVE_MSG = unknown variant `rainbow`, expected one of `auto`, `always`, `never`
P1_SERDE_DERIVE_DISPLAY_FIRSTLINE = TOML parse error at line 4, column 9
P2_GARDE_REACHED = false
P2_GARDE_REPORT_ENTRIES = 0
P2_SERDE_FAILED_FIRST_MSG = unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
P3_GARDE_CONSTRAINT_ENTRIES = 2
P3_GARDE_ENTRY = limit: lower than 1
P3_GARDE_ENTRY = workspace: length is lower than 1
P4_TABLE_KEY_ORDER = ["color", "format", "limit"]
P4_PERKEY_ISSUE_COUNT = 3
P4_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
P4_ISSUE = output.color: unknown variant `rainbow`, expected one of `auto`, `always`, `never`
P4_ISSUE = output.limit: invalid type: string "abc", expected a nonzero u32
P4_PARTIAL_VALUE = ConfigFile { output: OutputSettings { format: Table, color: Auto, limit: None } }
P5_NONZERO_ISSUE = output.limit: invalid value: integer `0`, expected a nonzero u32
P5_ENUM_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
P6_SYNTAX_AS_TABLE_OK = false
P6_BADVALUES_AS_TABLE_OK = true
P6_BADVALUES_AS_STRUCT_OK = false
```

Reading, in one line each. **P1** — serde's derive is fail-fast: three bad keys, one error.
**P2** — a `garde`-annotated struct fed one bad *type* (`format = "yaml"`) alongside two
values its `garde` rules would reject (`limit = 0`, `workspace = ""`) never deserializes, so
`validate` is never called and the report is empty; this is the measured form of the claim
that a serde-layered validator cannot aggregate type errors, at the scope stated under
`### Principles and implementation`. **P3** — once every type is accepted,
`garde` genuinely does aggregate two constraint errors; the capability is real. **P4** — the
per-key loop over `toml::Table` reports all three with dotted paths and hands back the
surviving partial value. **P4_TABLE_KEY_ORDER** — sorted, because R52 chose `toml` without
`preserve_order`, so the report is deterministic; note that the single error P1 shows is
`color`, not the file's first key `format`. **P5** — the two representative rejected values
F229's criterion names, with their exact messages. **P6** — the `RSLB202`/`RSLB203` boundary
holds structurally, with no string-matching of `message()`.

**Reproducibility, measured rather than asserted, and now checkable from the tree.**
`verify.sh` was rerun for revision 2 and **both logs are committed**, so a reader reproduces
the comparison without rerunning anything:

```bash
diff research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/r53-verify.log \
     research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/r53-r2-verify-rerun.log
```

The **entire diff is four lines — two changed pairs — and neither is a figure**: both carry the
probe crate's `$TMPDIR` path, which embeds the shell's PID and so differs on every run
(log lines 315 and 357). The rerun's own summary reads `checks run: 117`, `failures: 0`,
`skips: 0`, identical to the committed log's. **Every `PASS` / `FAIL` / `SKIP` line, every
count, and all twenty probe output lines reproduced byte-for-byte.** Revision 1 asserted this
same comparison from a second log it did not keep, which is judgment finding JF-4; the
committed pair replaces that assertion with an artifact.

The `VOLATILE` lines happened not to move inside that short interval, and that is not a
guarantee: each is a live figure that will drift on any longer one. `crate.recent_downloads`
is a rolling 90-day window; `crate.downloads`, `stargazers_count`, `pushed_at` and
`search/issues .total_count` move whenever upstream does; the current-stable line moves on
each Rust release; and the retrieval-date line on line 2 changes daily by construction. **The
rule for comparing across them:** they are recorded with their endpoint and asserted only
against a floor, never an exact value, so a re-verification compares them against the
2026-09-17 readings quoted in this decision and treats an increase as expected. Everything
else — the ledger rows, the R67 hash, the pinned lockfile counts, the standard's text at its
blob, the probe's output — is stable input.

**What this check does not prove**, listed rather than glossed: the recommendation under the
**1.96 MSRV floor** (local toolchain is 1.98.0, and the transitive tree was not resolved at
1.96); **macOS and Linux CI**, since this is one macOS developer host and not the two-runner
matrix; **compile-time or binary-size cost**, which was not measured; and whether
**`toml::Spanned` in the intermediate carries the per-key offsets** R67's `hint` wants, which
the probe did not exercise. Each is listed again under `## Engines` with what would prove it.
Revision 1 listed a fourth item here — "**`serde`'s own `unsafe` posture**, not audited here" —
which **revision 2 removes because it is now audited**: `r53-r2-gate-posture.sh` censuses
`serde` 1.0.229's published source along with every other candidate's (`G01`–`G04`), and the
result is in the gate table under `## Decision`. What the new check still does **not** prove is
narrower and is stated in its place: it reads each candidate's **own** `src/` tree only, so the
`unsafe` posture of the transitive dependencies those crates pull in — `regex`, `idna`, `url`,
`serde_json`, `compact_str`, `smallvec` and the rest — is unexamined. Proving that needs a
whole-tree audit against a resolved lockfile (`cargo geiger` or equivalent), which P03 can run
once a lockfile exists and which no gate here requires.

## Engines

- Codex (`gpt-5.6-terra`) — `raw/codex.md`, sha256 `65b51d2f…`, 15 H3 sections, written
  2026-09-17. Recommends `serde = "1.0"` plus
  `garde = { version = "0.23.0", default-features = false, features = ["derive"] }`; runner-up
  `validator 0.21.0`; carries `BASELINE-REVIEW: F229`; emits no `CONFLICT:`.
- Claude Opus 5 — `raw/opus.md`, sha256 `2067c9a1…`, 15 H3 sections, written 2026-09-17.
  Recommends `serde` `>= 1.0.229, < 2.0.0` with `derive` and **no validation crate**,
  constraints carried in the types plus a per-key loop for aggregate reporting; runner-up
  `garde >= 0.23.0, < 0.24.0`; carries `BASELINE-REVIEW: F229` with an added acceptance
  criterion; passes a non-parameter requirement to R52; emits no `CONFLICT:`.

**Disagreement 1 — `serde` alone, or `serde` plus `garde`? Settled for `serde` alone, by
measurement.** This is the item's central question and the engines split on it. It is *not* a
factual dispute: Codex states the same underlying fact Opus does — "a malformed TOML value or
wrong Rust type still fails during deserialization before Garde runs; Garde aggregates all
semantic errors only after structure succeeds. That is a deliberate diagnostic boundary, not
full Zod aggregate parity, and R55 decides how either class is tolerated" (`raw/codex.md:13`;
revision 1 quoted this sentence only as far as "parity" and closed it with a full stop, which
presented a partial quotation as a complete one — the dropped clause is not adverse, since it
agrees with this decision's own refusal to pre-decide R55). The disagreement is whether that
concession is fatal. The probe
measures its size in two halves. A document with three bad keys yields exactly one error from
serde's derive alone (`S72`). A document carrying one bad *type* plus two values `garde`'s own
rules would reject yields `P2_GARDE_REACHED = false` and `P2_GARDE_REPORT_ENTRIES = 0` (`S74`,
`S75`) — the crate is in the tree and contributes nothing, because deserialization returned
first. Together: for a config file whose first failure is a type, adding `garde` changes the
report from one error to one error. Since the aggregate loop must be built regardless — both to match both
sources' behaviour and to give R67 its `RSLB202`/`RSLB203` split structurally — and since every
constraint in the current schema is a type (three literal sets, one positive integer), the
crate's remaining job for this schema is empty. **Codex's recommendation is therefore not
adopted, but its analysis is not rejected**: `garde` is this decision's ranked runner-up on
Codex's own grounds (smallest tree, the ordered `Report` of `G34`/`G35`, aggregate contract), and its winning
condition is written into the re-verify triggers. Fairness recorded: `garde` does aggregate
constraint errors, measured at `S77`–`S79`.

**Disagreement 2 — `garde`'s maintenance state: Codex says `active`, Opus says `at-risk`.
Settled for `at-risk`, on a re-run signal.** Codex's ground for `active` is correct as far as
it goes: 0.23.0 is under four months old and the repository is unarchived (confirmed, `S44`,
`S62`). The prompt's rubric, though, says a release gap is "a trigger to investigate, never
the verdict", and `at-risk` needs a concrete signal. This synthesis re-ran the commit query and
found one: after the 0.23.0 release there are exactly **two** default-branch commits, and both
are a Dependabot Actions bump and its merge (`S64`, `S65`). Opus's unanswered-issue sample
(0 of 10, spanning eight months) is consistent with that but was **not re-run here** and is
carried as the raw's finding, not as this decision's measurement. The state does not change
the recommendation — `garde` is the runner-up either way — but it does change what P03 must do
before adopting the runner-up, which is written into trigger 6.

**Disagreement 3 — gate 2 semantics for a third-party crate. Settled against Codex's
phrasing.** Codex writes that "`garde`'s declared 1.87 is below the project floor but its
resolved dependency tree still requires P03 verification", which inverts the test: the
`msrv-policy` floor is the *oldest* Rust this template supports, so a dependency passes when
its declared `rust_version` is at or **below** the floor. `garde` 1.87 (`S48`), `validator`
1.88 (`S49`) and `serde` 1.56 (`S47`) all pass a 1.96 floor. Codex also excluded `validify` on
gate 2 for declaring no `rust_version`; Opus reads an undeclared `rust_version` as an evidence
gap rather than a breach, because the policy's "declared as rust-version in Cargo.toml and
tested in CI" clause binds this template's own crates, not third parties. Opus's reading is
adopted. The outcome is the same either way — `validify` is out — but on **maintenance**: its
newest non-yanked release is 2.0.0 of 2025-02-09, 19 months before this run (`S50`/`S51` record
the undeclared `rust_version` for `serde_valid` and `validify`; the release date is in the log
at the `validify/versions` endpoint), on a crate that is a fork of a candidate already in the
shortlist and offers nothing `garde` does not.

**Disagreement 4 — RustSec's 404. Settled for Opus's reading, by re-running its control.**
Codex records "the specified RustSec package page returned 404, so advisory absence remains
re-verification work". Opus treats 404 as the no-advisory response and validates it with
controls. This synthesis re-ran both halves in one pass: `serde`, `garde`, `validator`,
`serde_valid`, `nutype` and `validify` each answered **404**, while `atty`, `time` and
`openssl` — three crates with known advisories — each answered **200**, and a nonexistent crate
name answered 404 (`S59`, `S60`, `S61`). So 404 is the no-advisory response and the endpoint
was not simply down. **The residual caveat is kept**: a 404 cannot distinguish "no advisory"
from "name unknown to RustSec", so this is evidence of absence at the strength the endpoint
supports, not a certificate.

**Agreements worth recording, because they are not disagreements.** Both engines place `serde`
derive as the structural layer and treat a validation crate as an optional layer above it, not
a replacement. Both exclude `validify`, on different grounds settled in Disagreement 3. Both
place the parse-layer aggregators outside this item's seat as the wrong architectural layer —
Codex names `deserr`, Opus names `toml-span`, and a TOML parser is R52's decision. Both
report that **no candidate publishes macOS test evidence upstream**, at different breadth:
Codex records that `garde`'s release CI tests Ubuntu and WASM while `validator`'s tests Ubuntu
only, and that "neither publishes macOS test evidence"; Opus extends the same reading to
`serde_valid` and `nutype` (Ubuntu only) and to `serde` itself (Ubuntu and Windows, no macOS
leg). So gate 4 is satisfied by portability rather than by upstream evidence for every
candidate including the recommended one, and **P03 must treat a green `macos-latest` job as
the gate-4 receipt**. Neither engine proved the absence of platform-conditional code, and
neither does this decision. Both emit no `CONFLICT:`. Both state that nothing was built.

**`BASELINE-REVIEW: F229` — two lines, two dispositions. The ledger is not edited here.**

- *Codex's line*, carried verbatim less its trailing parenthetical citation and the code
  formatting inside it: `BASELINE-REVIEW: F229 — configuration is validated before
  use — retain the pattern and layer Garde semantic validation after Serde structural decoding;
  require representative rejected values — Serde alone admits a signed integer that TypeScript
  rejects with .positive(); affected items R53, R52, R55`. **Disposition: half accepted, half
  not.** Its "require representative rejected values" half is already F229's recorded criterion
  (`S11`) and is satisfied — ``invalid value: integer `0`, expected a nonzero u32`` and
  ``unknown variant `yaml`, expected one of …`` (`S86`, `S87`). Its "layer Garde" half is the
  recommendation this decision does not adopt, for the reason in Disagreement 1. No ledger
  change is proposed by this half.
- *Opus's line*, carried verbatim in substance: `BASELINE-REVIEW: F229 — the parsed file is
  validated against a typed schema before any value is used — add to the acceptance criteria
  that every invalid key in the document is reported in one pass rather than only the first,
  because the recorded criterion is satisfied by a fail-fast mechanism that cannot carry py's
  per-key drop behaviour — evidence: py b08bccfb:src/py_launch_blueprint/core/settings.py:158-176
  iterates exc.errors() and pops each offending (section, key) in turn; ts
  cb1cbcb2:src/lib/config.ts:126-129 maps over every result.error.issues entry; whereas serde's
  derived Deserialize early-returns on the first bad field — affected items R53, R55 (F238), R52
  (F225/F226); affected records docs/port/COMMONALITY.md:233, docs/port/BASELINE-REVIEW.md:106
  and its finding line at :279`. **Disposition: adopted as this decision's proposal**, and
  strengthened from a documentation argument to a measured one (`S72`, `S74`, `S75`, `S80`).
  Its R52 clause is now moot: R52 selected `toml`, so the aggregation is built on
  `toml::Table` as that clause anticipated. **This decision edits no ledger, no prompt, no
  index and no registry**; the F229 row and the `BASELINE-REVIEW.md` finding line are left for
  the owner's disposition.

**`CONFLICT:` raised by a sibling item, carried without adjudication.** R55's Codex raw
(`research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/raw/codex.md`) raised the following, quoted
verbatim (`S29`, `S30`):

> CONFLICT: R67 error-taxonomy-exit-codes — `RSLB203 config value invalid` cannot mean every
> invalid file leaf — R55 requires an individually invalid declared config value to
> warn-and-drop, reserving `RSLB203` for a fatal nonrecoverable validation outcome such as
> R53's cross-field invariant.

**Where R53 touches the same row:** the per-key loop is what produces
the "individually invalid declared config value" the conflict is about, and R67's `RSLB203`
(`S20`) is where this item routes a validation failure. **Disposition: not adjudicated here,
and deliberately not foreclosed.** The mechanism returns the issue list and the surviving
partial value as independent results (`S80`, `S84`), so it supports warn-and-drop per key, a
fatal whole-file failure, or a split between them without any change to this decision. R55's
assumption about this item — "independently callable declared-field validation plus a
separately classified cross-field invariant result" (`S31`) — holds in its first half and is
vacuous in its second: the current schema has **no cross-field rule**, so no separately
classified cross-field outcome exists yet to reserve `RSLB203` for. If R67 accepts R55's
conflict, this item's report is the input to whatever split R67 records; nothing above needs
to change.

**Sources this synthesis relied on but did not itself re-read.** Both raws read the pinned
source repositories (`py@b08bccfb`, `ts@cb1cbcb2`) for `settings.py` and `config.ts`; this
synthesis quotes those line references from the raws and did **not** re-run `git show` against
either repository, which is outside this run's tree. Likewise `cargo-deny`'s `src/cfg.rs`
`UnvalidatedConfig` trait, both crates' `.github/workflows` runner labels, and the
issue-responsiveness samples are **referred to from `raw/opus.md` at its stated retrieval date
and are not reproduced here**; this synthesis verified the lockfiles, the registry figures, the
RustSec responses, the commit history and the serde pull request itself.

Revision 1's wording of that sentence also listed "`garde`'s and `validator`'s `unsafe`
audits" among the things "carried from `raw/opus.md`". **That was inaccurate twice over and is
corrected here**: nothing was carried — the audits were referred to, not reproduced, which is
the audit's point — and the `unsafe` posture is no longer a referred-to claim at all, because
revision 2 re-ran it from the published crate sources at every candidate's exact version
(`G01`–`G23`). Where the new census and `raw/opus.md:533-547` differ, **the census governs**:
the raw described `garde`'s `src/rules/pattern.rs` `unsafe impl Send`/`Sync` as "js-sys only",
which the `cfg` line confirms exactly (`G16`, `G17`), but it did not separate the seven
matching lines into the three that are on the default path and the four that are not, and it
reported `serde` as "not audited here", which is now audited. The word "referred to" is used
above rather than "carried" for the remaining items, deliberately.

**What P03 must validate.** Each line is a check that can fail, not a restatement.

1. **The MSRV floor.** `cargo +1.96 check --workspace --locked` once a lockfile exists. This
   synthesis compiled only under local stable 1.98.0 and resolved no transitive tree at 1.96.
2. **The gate-4 receipt.** The config-schema test file runs green on both `ubuntu-latest` and
   `macos-latest`. No candidate crate, `serde` included, publishes macOS test evidence
   upstream, so the template's own job **is** the macOS evidence; gate 4 is not satisfied until
   it is green.
3. **The aggregate, end to end.** A config file with three invalid keys yields three entries in
   one `hint`, exit `2`, code `RSLB203`, stdout byte-empty. The probe proved the mechanism in
   isolation; nothing has proved it through R67's envelope.
4. **The `RSLB202`/`RSLB203` split through the real loader.** An unterminated table header
   yields `RSLB202`; three bad values yield `RSLB203`; both exit `2` and are distinguishable by
   `code`. Proved structurally at the `toml` API (`S88`–`S90`), not through the error type.
5. **Spans.** Whether `toml::Spanned` in the intermediate carries a usable per-key offset into
   `Issue::span`, so R67's `hint` can name a file and line the way the standard's R5.8 example
   does. **Unproven here** — the probe leaves `span` as `None` and `toml::Table` carries no
   offsets. What would prove it: a spike deserializing the intermediate as a map of
   `toml::Spanned<toml::Value>` and printing the recovered ranges.
6. **"Before use", as a compiler-checked property.** A `trybuild` or `tests/ui/` case in which
   constructing `Valid` directly fails to compile (`E0603`/`E0451`). **Unproven here**, because
   the type does not exist; the probe demonstrated the loop, not the type-state.
7. **The maintenance transfer.** The roughly sixty hand-written lines carry the test coverage a
   dependency would have earned, including the rejected-value table as executable tests.
8. **The runner-up condition, at the time it is needed.** If R56 or R55 adds two or more
   constraints the type system cannot express, re-check `garde`'s maintenance state before
   adopting it — the 6-month release trigger falls on 2026-11-23 — and move the runner-up seat
   to `validator` if the Dependabot-only commit run and the unanswered-issue run have both
   continued.
