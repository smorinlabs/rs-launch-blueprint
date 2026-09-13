# R60 — CLI parsing framework (bundle, Deep) — revision 3, 2026-09-13

Synthesized 2026-09-10 by a fresh context that produced none of this item's raw
reports, from three engine reports (five provider bodies) plus the verification
run recorded under `## Empirical check`. No template code exists and none was
written here.

Revised 2026-09-12 after the revision-1 draft (sha256
`d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c`) was
**rejected** on two findings — a non-conformant plural command noun and an
unpinned standard.

Revised again 2026-09-13 after the revision-2 draft (sha256
`18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c`) was
**rejected** on one finding: **its evidence scripts could not be rerun once the
revision was committed.** Nothing about the recommendation was challenged and
nothing about it moves. The evidence apparatus is rebuilt so that every input a
script reads is either committed inside this run directory or fetched from a
pinned remote source, and the rerun is demonstrated from a clean extraction of
the commit rather than asserted. This revision also records fitness gate 1 as
`inapplicable` under the owner's 2026-09-12 licence ruling. What changed, and
what is unchanged, is enumerated at the end of `## Engines`. No crate was
scaffolded and no command surface was written in any revision.

## Decision

**Status.** This is a **proposal**, to be validated in the implementation phase
(P03) against the real template (owner ruling, 2026-09-10). Everything below
rests on registry and GitHub queries, reads of the published crate sources at
their exact versions, reads of the org CLI Design Standard **at the pinned
revision recorded under "THE STANDARD PIN" below (version 1.4.14, blob
`f9de0437`)**, reads of the two source repositories through their pins, and one
MSRV-aware dependency resolution — not on a working command-line interface,
which does not exist yet.
P03 builds the template and its CI proves the recommendation. Where a
recommendation here does not survive contact with the built template, the
correction is made **against this recorded research** — its principles, its
compared alternatives and its verified mechanisms — rather than by researching
the item again from scratch. The owner has not reviewed R60; no acceptance is
claimed or implied.

Adopt **`clap` with its `derive` API** as the single declaration of the argv
grammar, and take every one of this bundle's six derived surfaces from that one
declaration rather than from application code. The named stack, at the versions
that resolved and audited clean on 2026-09-10:

| Slot | Selection | Where it goes |
|---|---|---|
| Argument parser | `clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }` | CLI binary crate only |
| Shell completions | `clap_complete = "4.6.9"` (default features; `aot` generation) | CLI binary crate only |
| Build metadata for extended `--version` | a dependency-free `build.rs` reading Cargo's `TARGET` and running `$RUSTC -vV` | CLI binary crate only |
| Did-you-mean matcher | `strsim`, **transitive** through clap's default `suggestions` feature — never a direct dependency | resolved at `0.11.1` on 2026-09-10 |

The library crate and the web crate depend on none of these.

The six surfaces this bundle decides, and the mechanism chosen for each:

| Ledger row | Surface | Mechanism |
|---|---|---|
| F264 | parsing framework | `clap` 4.6.6, `derive` API; a `Cli::command()` factory kept for completion generation and parser tests |
| F265 | command surface shape | noun-verb subcommand groups as nested `Subcommand` enums, each noun **singular in its canonical documented form** (R1.3 `MUST`, `:133`); **no default business command** |
| F267 | extended `--version` | `Command::version` (one line) for `-V`; `Command::long_version` (extended) for `--version` — **see OVERRIDE (OV-01)** |
| F268 | completion generation | a regular `completion <shell>` subcommand calling `clap_complete::aot::generate` against a fresh `Cli::command()` |
| F269 | env-var binding | a **curated** per-option `#[arg(env = "<TOOL>_<NAME>")]`; **no blanket prefix** — py's `auto_envvar_prefix` is not ported |
| F270 | stackable global options | one `#[derive(Args)] struct GlobalArgs`, `#[command(flatten)]`-ed at the root, `global = true` on each field |
| F272 | did-you-mean matching | clap's default `suggestions` feature (`strsim::jaro`, confidence `> 0.7`); no hand-rolled matcher, no direct `strsim`, `infer_subcommands` left off |

F266 (`-V`/`--version` exists) and F271 (a suggestion appears) are inherited
`COMMON → REUSE` rows adjudicated `retained` in
`docs/port/BASELINE-REVIEW.md:114` and `:115` (read 2026-09-10). This item
decides only which crate provides them and, for F272, the matching mechanism.
Both are natively available in the recommended stack: verified in the crate
source, cited below.

**Integration point with the already-published R67.** R67 requires `main` to
return `ExitCode`, a usage/parse failure to be `RSLB201` → exit `2`, a single
JSON envelope on stderr, and stdout byte-empty on the error path
(`research/topics/67-error-and-exit-code-contract/DECISION.md`, read
2026-09-10). `Cli::parse()` does not compose with that: it prints clap's own
message and terminates the process itself. So the template calls
**`Cli::try_parse()`** and routes the `clap::Error` by `kind()`: exactly two
kinds — `ErrorKind::DisplayHelp` and `ErrorKind::DisplayVersion` — are
successful output on stdout at exit `0`; every other kind is `RSLB201` → `2`.
Those two and no others, because that is the exact match arm clap itself uses:
`stream()` is `ErrorKind::DisplayHelp | ErrorKind::DisplayVersion =>
Stream::Stdout, _ => Stream::Stderr`, and `exit_code()` returns `USAGE_CODE`
for every stderr kind and `SUCCESS_CODE` otherwise, those constants being `2`
and `0` (`clap_builder-4.6.6/src/error/mod.rs:222-237`,
`clap_builder-4.6.6/src/util/mod.rs:26,32`, read 2026-09-10). Note the one kind
that reads as if it belonged in the exit-`0` list and does not:
`DisplayHelpOnMissingArgumentOrSubcommand` (`error/kind.rs:300`) falls in the
`_` arm, so clap sends it to stderr at `2`. Whether the template overrides that
is not decided here — it depends on `Command::arg_required_else_help`, which
this item does not set. clap's numbering therefore agrees with R67 at both
ends, but agreement of values is not composition: the envelope and the
`ExitCode` return are the template's, and P03 must build them. Rendering clap's usage text *inside* R67's
JSON envelope is not decided here and is listed under `## Engines` as work P03
must resolve.

### Principles and implementation

**The shared requirement.** Both source implementations declare the command
surface once, as data, and generate every user-visible artifact from that one
declaration — help text, the version flag, the completion script, the
environment fallback and the unknown-command suggestion. py does this with
`click` (py `src/py_launch_blueprint/cli/main.py:29` — `import click`); ts does
it with Commander (ts `src/router.ts:13` — `import { Command, CommanderError }
from 'commander';`). Both lines were read through the pins on 2026-09-10 (`git
-C ~/c/py-launch-blueprint show b08bccfb…:<path>`, `git -C
~/c/ts-launch-blueprint show cb1cbcb2…:<path>`; full output in the evidence
log, section Y/Z). The principle is not "use a parser library". It is
**single-source interface declaration**: the argv grammar has exactly one
definition, and no derived artifact is maintained by hand alongside it. The
residual drift risk is confined to an artifact that is *committed* rather than
emitted at run time — the completion scripts, if the template ever checks them
in — which is what acceptance criterion AC4 is for.

**Source and agreement level.** Five levels are in play, and conflating them
produces the wrong answer. Where a row's source is the org CLI Design Standard,
the citation is `/Users/stevemorin/c/cli-standards/cli-design-standard.md:<line>`,
read 2026-09-10 and pinned as follows.

**THE STANDARD PIN — every `R<n>.<m>` rule and every bare `:<line>` in this
decision resolves against exactly this revision.** A decision that cites a
moving document cannot be re-verified, so the applied revision is fixed by four
identifiers — the declared document version, the commit, the blob object id and
the content sha256 — in the repository named alongside them. Each is
independently checkable, and the content hash is the authoritative one: a
document could in principle be edited without its version being bumped, and the
hash would still catch it.

| Identifier | Value |
|---|---|
| Document version | **1.4.14**, `Status: Active — canonical`, `Last updated 2026-06-28` (declared in the document's own header table, `:1-12`) |
| Repository | `https://github.com/smorinlabs/cli-standards`, path `cli-design-standard.md` |
| Commit | `fb30a591c267a7ec1130ba4cda679eaee494b9d7` (`docs: resolve PR #1 review findings (v1.4.14)`, 2026-06-28) — the most recent commit to touch the file, **confirmed against the published history rather than against a local clone**: `GET https://api.github.com/repos/smorinlabs/cli-standards/commits?path=cli-design-standard.md&per_page=1` returns this commit as the newest, checked 2026-09-12 against `origin/main` after `git fetch` and re-checked 2026-09-13 through that endpoint (`## Empirical check` row E10) |
| Blob object id | `f9de0437baece3383e73ca2c5f48b7ab399b51c7` |
| Content sha256 | `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f` |

**How a future reader resolves it, without a clone and without this machine.**
The pinned text is committed in this run directory as
`review/evidence/snapshots/cli-design-standard-1.4.14.md`, and its sha256 is
`9fb05d3d…` — the same hash the pinned blob has. So the primary recipe is: hash
that file and confirm the value. Two independent recipes re-derive the same
bytes from the published source: `curl -sSL
https://raw.githubusercontent.com/smorinlabs/cli-standards/fb30a591c267a7ec1130ba4cda679eaee494b9d7/cli-design-standard.md`
(a content-addressed URL — the commit id is in the path, so the bytes cannot
move under it), or, given any clone of the repository, `git cat-file blob
f9de0437baece3383e73ca2c5f48b7ab399b51c7`. All three were executed on
2026-09-13 and agreed (`## Empirical check` rows E1 and E10). Every `:<line>`
citation below is a **line number in that text**, not in whatever the working
tree holds later; the pinned text is 773 lines, which is itself asserted so that
an out-of-range citation cannot pass silently. The local working-tree file read
on 2026-09-10 was verified byte-identical to the pinned blob (same sha256), so
the reads this decision rests on and the pinned text are the same bytes. Version,
sha256 and each cited line were checked mechanically; see `## Empirical check`
rows E1–E5 and E10.

**R67 did not pin this document in its decision, and that is why the pin is
stated here in full.** The distinction matters, so state both halves exactly.

- **R67's decision body carries no pin.** It cites the standard by absolute
  path, line and retrieval date only —
  `/Users/stevemorin/c/cli-standards/cli-design-standard.md:351` with the org
  decision row at `:70`, read 2026-09-09
  (`research/topics/67-error-and-exit-code-contract/DECISION.md:78`, and once
  more in its evidence table at `:464`; those two lines are its only citations
  of the file). Neither carries a version, commit, blob id or content hash, and
  the string `1.4.14` does not appear in that document at all.
- **R67's audit trail does name the version.** Its revision-4 audit log records
  "Standard read: `/Users/stevemorin/c/cli-standards/cli-design-standard.md`,
  version 1.4.14"
  (`research/topics/67-error-and-exit-code-contract/evidence/2026-09-05T155124Z-2271e140a7ef-audit-error-and-exit-code-contract-r4.log:6`).
  That is an auditor's record rather than a pin in the deliverable — it fixes
  no commit or hash, and a reader of R67 alone would not find it — but it is
  independent attestation that **R67 and R60 applied the same revision, 1.4.14**.

Both halves were checked mechanically, including the negative one, which is
asserted as a count of zero rather than as absent output (`## Empirical check`
row E6). So there is no R67 *pin form* to be consistent with: this decision
keeps R67's citation style — absolute path, `:<line>`, retrieval date — and adds
the version, commit, blob id and content hash that R67's body omits. The two are
compatible rather than divergent, and now demonstrably about the same text: R67's
2026-09-09 read, its auditor's 1.4.14, and R60's 2026-09-10 read all fall after
the 2026-06-28 commit that is still the file's latest. Should R67 be revised,
adopting this pin form is the cheaper direction of alignment.

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | The argv grammar has one declaration; help, version and completions are generated from it | **capability** (ledger F264 `DIVERGENT`) | that generation is derived, never hand-maintained in parallel | which crate generates; derive vs builder front-end |
| P2 | A command path reads noun then verb, and the noun is singular | **standard, one value for all three repos** — R1.1 `(MUST, Standard profile)` (`:124`), org-locked (`:63` row 1); R1.3 `(MUST)` noun number (`:133`), org-locked (`:67` row 5) | the ordering itself, **and that the canonical documented noun is singular** | nesting depth (R1.2 `SHOULD` ≤ 3, `:129`) and the module layout; whether a hidden plural alias is offered at all (R1.3's `MAY`) |
| P3 | `-V`/`--version` exists and reports the tool's version | **capability + standard** — ledger F266 `COMMON → REUSE`; R4.1 `(MUST)` required global core (`:237`), R4.6 `(SHOULD)` output shape (`:275`) | that the flag exists, and that `-v` is verbose, not version (`:65` row 3, org-locked) | whether `--version` prints more than one line, and where the extra data comes from (R22) |
| P4 | A setting exposed in more than one place uses one deterministic name, and env exposure is curated | **standard** — R3.8 `(MUST)` (`:220`), R5.4 `(MUST)` (`:321`), org-locked (`:69` row 7) | `--some-flag` ↔ `TOOL_SOME_FLAG`, and that the env surface is a curated subset | which options are in the curated subset |
| P5 | Global options work wherever the user puts them | **capability**, floor fixed by R4.5 `(SHOULD)`: "Global flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted after it" (`:270-271`) | before-the-verb acceptance | whether after-the-verb acceptance is free or costs per-command declarations |
| P6 | An unknown command produces a suggestion, not a bare failure | **capability** (ledger F271 `COMMON → REUSE`) | that a suggestion appears | the string metric and threshold (F272) |
| P7 | The tool can print completion scripts for the user's shell | **capability** — R9.1 `(SHOULD)` "at least bash, zsh, and fish" (`:483`) | that a `completion <shell>` surface exists for those three shells | static script generation vs runtime completion |

**The standard binds this item, on the same footing as R67.** R60's own prompt
does not name the org CLI Design Standard, and the Opus raw report therefore
treats its applicability as an open owner question. It is not open. The
already-published R67 rests on the same document, adjudicating its R6.1 as a
`(MUST)` that is `org-locked` and quoting its exit-code table verbatim
(`research/topics/67-error-and-exit-code-contract/DECISION.md:76-82`, read
2026-09-10). This decision follows that treatment: every rule cited above is
cited by file and line with its retrieval date **against the pinned revision
above**, and a `MUST` marked org-locked in the Part II Decision Log table
(header `:61`; row *N* at line 62 + *N*, so row 1 is `:63`, row 5 `:67`, row 7
`:69` and row 8 — R67's exit-code row — `:70`) is binding, not advisory. The ts port
already reconciled onto the same document in code — its router carries the
comment "Usage errors must exit 2 (cli-standards R6.1)" (ts `src/router.ts:117`,
read through the pin 2026-09-10).

Three consequences follow, and they are different in kind:

- **The template is in the Standard profile, so R1.1 is a `MUST` here.** The
  standard defines two profiles (`:50-53`); the verb-first Small-CLI profile
  requires *all three* of its entry criteria to hold (`:578-581`), the first
  being a small fixed command set acting on "a **single implicit resource** or
  no resource at all". This template ships two resource groups (`project`,
  `config`) and exists to be extended, so criteria 1 and 2 both fail. The
  standard's own counter-example is decisive: "a platform tool managing
  `projects`, `deploys`, `tokens`, and `users` — that **MUST** use noun-verb"
  (`:586`). That sentence is **quoted verbatim from the standard, and its plural
  spellings are the standard's own illustrative wording in an Appendix A
  counter-example, not this template's grammar** — the template's nouns are
  singular under R1.3, the next bullet. F265's ordering is therefore settled by
  the standard, not by a preference between the two ports. The ecosystem
  evidence agrees rather than conflicts on ordering, so no override is filed.
- **R1.3 is a `MUST` that fixes the noun's *number*, and the canonical
  documented form is singular.** R1.3 (`:133-137`) states it in three parts:
  "Resource nouns **MUST** be **singular** in their canonical form. The plural
  form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in
  help or docs. The verb already carries cardinality, so `list` returning many
  is not a reason to pluralize." Its non-conformant example is precisely a
  documented plural — "❌ documenting `acme widgets list` as the primary form"
  — and the rule is org-locked (Decision Log row 5, `:67`: "Singular canonical;
  plural accepted as undocumented alias"). So the canonical, documented,
  help-visible noun in this template is **`project`**, giving `<tool> project
  list`; `<tool> projects list` **MAY** be wired as an explicit hidden alias
  (permitted by R1.3's `MAY` and by R1.6's alias allowance, `:146-149`) and, if
  it is, **MUST NOT** appear in `--help` or in any documentation. Three points
  on the mechanism, because each is easy to get wrong:

  1. **clap already distinguishes the two alias kinds, and only one of them
     conforms.** `Command::alias` documents itself as "Aliases defined with this
     method are *hidden* from the help message", pointing at
     `Command::visible_alias` for the other behavior, which in turn is "*visible*
     from the help message and displayed as if it were just another regular
     subcommand" (`clap_builder-4.6.6/src/builder/command.rs:2664-2666` and
     `:2865-2868`; the methods themselves at `:2691` and `:2893`, read
     2026-09-12). So `#[command(alias = "projects")]` is the conformant form,
     and `visible_alias` would *violate* R1.3 by putting the plural in help.
     R1.3's "undocumented alias" is therefore a behavior clap supplies directly,
     not something the template has to build.

     That the *derive* spelling reaches that builder method is verified rather
     than assumed, because this is the mechanism the whole R1.3 repair rests on.
     `alias` is not one of `clap_derive`'s special attribute names — the
     `MagicAttrName` table in `clap_derive-4.6.4/src/attr.rs` contains no
     `Alias` variant and does not mention `alias` at all — so it falls to the
     generic branch, which pushes it verbatim as
     `self.methods.push(Method::new(name, arg))` (`src/item.rs:337-345`), and a
     `Method` renders as `quote!( .#name(#args) )` (`:1281-1289`). The generated
     code is therefore literally `.alias("projects")`, calling
     `Command::alias` — the hidden one. Read 2026-09-12 in the published
     `clap_derive-4.6.4` tarball, whose sha256 matches crates.io's recorded
     checksum (`## Empirical check` row E8).
  2. **An alias is an explicit declaration, so it does not reopen R3.10.** The
     plural is reachable only because it was named; nothing is inferred. This is
     the opposite of `infer_subcommands`, which stays off (essential behavior 6).
  3. **The alias is optional.** The conformant minimum is the singular form
     alone, and P03 may ship that and nothing else.

  **This departs from both source ports, and deliberately.** py declares a
  help-visible plural group — `@click.group(name="projects", cls=SuggestingGroup)`
  (py `src/py_launch_blueprint/cli/commands/projects.py:37`) registered as
  `COMMAND_GROUPS = [projects_group, config_group]`
  (py `cli/commands/__init__.py`) — and ts declares
  `.command('projects', { isDefault: true })` (ts `src/commands/projects.ts:70`),
  which `src/router.ts:234` then looks up by that exact plural name. All three
  lines were read through their pins on 2026-09-12 (`## Empirical check` row E7). **No override is filed for this departure**, on the same footing
  as F269 below: R1.3 is a non-waivable `MUST`, the standard's conformance
  clause admits waivers only for `SHOULD`-level rules (`:50`), and a `MUST`
  leaves nothing to trade off. Recording conformance to an org-locked `MUST` as
  an override would misrepresent a settled constraint as a choice this item
  made. The ports' plural is evidence of prior practice, not a competing option.
- **R4.6 is a `SHOULD` that this design deviates from.** Recorded as OVERRIDE
  (OV-01) below — the only override in this decision.

**What the standard excludes, and why the exclusion is not a clap limitation.**
py binds *every* option to an env var through one prefix (py
`cli/main.py:60-66` — `"auto_envvar_prefix": APP_NAME.upper(),`, whose own
comment calls the prefix "the catch-all for any others"; read through the pin
2026-09-10). R5.4 `(MUST)` says the opposite: "Only a **curated subset** of
settings **SHOULD** read from the environment … and the tool **MUST NOT**
auto-expose every flag as an env var" (`:321-323`). py's own code already hedges
toward the curated form — four of its global options carry explicit `envvar=`
names (`PLBP_OUTPUT`, `PLBP_LOG_LEVEL`, `PLBP_LOG_FILE`, `PLBP_CONFIG`, py
`cli/options.py:62,89,98,107`, read through the pin 2026-09-10). So F269 is
decided by the standard: keep the deterministic `--some-flag` ↔
`<TOOL>_SOME_FLAG` naming that R3.8 `(MUST)` requires, drop the catch-all.

**`<TOOL>`/`<tool>` is a placeholder throughout this decision, and deliberately
so.** py's tool is named `plbp` and its variables are `PLBP_*`; the Rust
template's binary name is **not this item's to set**. It follows from R49
(`build-tool-output-shape`), whose registry value is still `—`
(`docs/port/PARAMETERS.md`, read 2026-09-10), and R9.3 `(MUST)` makes env-var
names part of the tool's public contract — "command names, flag names, exit
codes, env-var names, and machine-readable output shape" (`:491-493`, read
2026-09-10) — so writing
`PLBP_` here would propagate py's name into a Rust interface this item has no
authority over. Every `<TOOL>_` and `<tool>` below resolves to R49's binary name
uppercased and as-is respectively; the *rule* this item fixes is the
deterministic transform, not the string. Where `PLBP_` appears without a
placeholder it is quoting py's own source or a raw report, and says so.

State the reason precisely, because a wrong reason here would propagate. clap
**can** do blanket binding: `Command::mut_args` takes an `FnMut(Arg) -> Arg`
over every argument (`clap_builder-4.6.6/src/builder/command.rs:296-302`, read
2026-09-10), so a builder post-pass that derives `<TOOL>_<UPPER_SNAKE>` from
each long name — which is what the Doxa OpenAI body proposes — is mechanically
constructible. What clap does not ship is a *declarative* prefix switch: a grep
of `clap_builder 4.6.6` and `clap_derive 4.6.4` for `env_prefix`, `auto_env` and
`envvar_prefix` returns nothing, and the only env API is per-argument
`Arg::env` / `Arg::env_os` (`arg.rs:2205,2221`). The blanket design is therefore
excluded **because R5.4 forbids it**, not because clap cannot express it.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Representative | What it gives | What it costs for this template |
|---|---|---|---|---|
| A | Declarative single-source parser, derive front-end | `clap` + `clap_derive` | subcommand routing, help, `-h`/`-V`, completions, env fallback and suggestions from one type definition | the largest compile-time and binary cost among the candidates surveyed (figures and their limits below) |
| B | Same crate, builder front-end | `clap` builder | commands composed at runtime (plugins, config-driven flags) | more code for a fixed command set; no compile-time typing of the parse result |
| C | Minimal lexer, everything else hand-written | `lexopt`, `pico-args`, `clap_lex` | smallest binary, fastest builds, total control over argv semantics | the template must hand-write help, version, man page, completion generators and suggestion matching |
| D | Statically-typed combinator parser | `bpaf` | compile-time-checked parsers; smaller release overhead than clap in the upstream benchmark (qualification 3 below) | combinator style; its completion support was not verified here (see `## Engines`) |
| E | Small derive parser aimed at binary size | `argh`, `xflags` | tiny overhead | `argh` is BSD-3-Clause and declares no `rust-version`; `xflags`'s newest release is a pre-release |

Architecture C is excluded **on fit, not on popularity**, and the strongest
argument for it is worth stating in full because it is real. ripgrep left clap
for `lexopt`, and its maintainer wrote down why (PR #2626, merged 2023-11-21;
quoted in the Opus raw report from `GET
https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626`, retrieved
2026-09-10): "I perceived that Clap solves a more general problem than what I
actually need solved … **No multi-value flags. No sub-commands.**" The same PR
body enumerates the bill: "I had to write my own shell completion generator. I
had to write my own `-h/--help` output generator. I also had to write my own man
page generator." `rs-launch-blueprint` is the inverse of ripgrep's case on the
axis that decided it: it *is* a subcommand tool (F265, and R1.1 makes that a
`MUST`), it *does* need a `completion` command (F268, R9.1), and as a template
it must make adding a noun cheap for every downstream user. ripgrep's
`Cargo.toml:63` still reads `lexopt = "0.3.0"` and names no clap (verified
2026-09-10, evidence log section AA) — the counterexample is genuine, and it
does not transfer.

**Fitness gates, answered per candidate before popularity was weighed.** Every
figure below is from the run recorded in `## Empirical check`, retrieved
2026-09-10.

| Candidate | 1. license — **gate inapplicable**; the value is recorded as a fact, see below | 2. MSRV (floor 1.96) | 3. advisory / `unsafe` | 4. OS matrix | 5. default features | 6. size & build cost | Gate result |
|---|---|---|---|---|---|---|---|
| `clap 4.6.6` | `MIT OR Apache-2.0` | declares `1.85` — 11 minors of headroom | no RustSec page; `cargo audit` clean on the resolved tree | see qualification 2 | `std,color,help,usage,error-context,suggestions` | largest of the surveyed field in the upstream benchmark (qualification 3) | **pass** |
| `clap_complete 4.6.9` | `MIT OR Apache-2.0` | declares `1.85` | no RustSec page | see qualification 2 | `default = []`; requires `clap >= 4.5.20` | not separately measured in the upstream benchmark; adds five shell writers | **pass** |
| `strsim` — `0.11.1` at the 2026-09-10 resolution, and transitive, so the version floats | `MIT` | declares `1.56` | no RustSec page | see qualification 2 | n/a — pulled by clap's `suggestions` | not separately measured | **pass** |
| `vergen 10.0.3` | `MIT OR Apache-2.0` | declares **`1.96.0` — exactly the floor, zero headroom** | no RustSec page | not assessed | `cargo`, `rustc` features needed | build-time only | **pass today, at risk** — see below |
| `built 0.8.1` | `MIT` | declares `1.87` | no RustSec page | not assessed | build-time only | build-time only | **pass** (runner-up) |
| `shadow-rs 2.0.0` | `MIT AND Apache-2.0` | **declares none** | no RustSec page | not assessed | build-time only | build-time only | **excluded by gate 2** (no MSRV evidence) |
| `bpaf 0.9.27` | `MIT OR Apache-2.0` | declares `1.68` | no RustSec page | not assessed | not assessed | smaller than clap in the upstream benchmark (qualification 3) | passes gates; loses on fit (D above) |
| `argh 0.1.19` | **`BSD-3-Clause`** | **declares none** | no RustSec page | not assessed | not assessed | 38 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also rejects invalid-UTF-8 argv per that same benchmark's own column |
| `lexopt 0.3.2` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 37 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also architecture C |
| `pico-args 0.5.0` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 24 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; newest release 2022-06-04, repo `pushed_at` 2023-10-19 |

**Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility
is not evaluated for any dependency or tool`.** The owner ruled that this project
performs no licence check on any tool or library it uses, and extended that
knowingly to crates compiled into the shipped artifact; the repository's own
declared expression `MIT OR Apache-2.0` and its per-file headers are unaffected,
because those are this repository's own source. The gate row is stated rather
than deleted because this item's binding prompt still lists it and directs that
an inapplicable metric carry its reason. **The recommendation does not move, and
no exclusion in the table above ever rested on this gate**: all four exclusions
(`shadow-rs`, `argh`, `lexopt`, `pico-args`) are gate-2 exclusions for declaring
no `rust-version`, and `argh`'s `BSD-3-Clause` — the only value in the column
that differs in kind from the rest — excluded nothing before the ruling and
excludes nothing after it. The licence expressions recorded in that column, in
`## Empirical check` §01 and §08, and in the evidence log's section W are
retained as the values the registry endpoint returned. They are facts about the
crates, evaluated against no gate.

Four qualifications on that table, each of which limits exactly one column:

1. **Gate 3, advisories.** "No RustSec page" means `GET
   https://rustsec.org/packages/<name>.html` returned HTTP 404 for all eight
   crates queried. That reading was validated against two controls that do carry
   advisories — `anyhow` (HTTP 200, `RUSTSEC-2026-0190`, the advisory R67 cites)
   and `atty` (HTTP 200, two IDs) — so a 404 here is absence of an advisory page,
   not a failed request. `cargo audit` (advisory DB of 1,243 advisories, fetched
   2026-09-10) scanned the resolved 29-crate tree and exited `0`. **The `unsafe`
   posture of these crates was not assessed in this run** and is carried to
   `## Engines` as unproven.
2. **Gate 4, the OS matrix.** No CI configuration was read in this run. The
   resolution and the crate reads were performed on macOS 26.4 `aarch64` only.
   That `clap`, `clap_complete` and `strsim` build and are tested on
   `ubuntu-latest` and `macos-latest` is **not established by this decision**; it
   is carried to `## Engines` as unproven with what would prove it. What *is*
   established here is that the recommended pins resolve at the declared MSRV
   floor on one host.
3. **Gate 6, size and build cost.** The only figures available are the upstream
   `rosetta-rs/argparse-rosetta-rs` benchmark's published results, quoted in the
   Opus raw report from that project's README (retrieved 2026-09-10). They were
   measured **by that project, on its own stated system — "Linux 6.17.9-76061709-generic
   (x86_64), rustc 1.94.0 (4a4ef493e 2026-03-02) w/ `-j 8`" — with clap at
   v4.5.60, which is not the 4.6.6 recommended here, and on neither CI runner.**
   No benchmark was run by the Opus report and none was run by this decision.
   Within those limits the published numbers are: `clap_derive` ~596 KiB release
   overhead and ~4 s full debug build against a null baseline of 0 KiB / 163 ms;
   `clap` builder 574 KiB / 3 s; `bpaf_derive` 253 KiB / 4 s; `argh` 38 KiB;
   `lexopt` 37 KiB; `pico-args` 24 KiB. Two readings matter and both are
   qualified the same way: parse latency is 2 ms for *every* entrant in that
   run including the minimal ones, so **on those figures** no candidate can be
   preferred on parsing throughput; and the incremental-rebuild delta the
   template's users would feel is 182 ms vs 123 ms, ~59 ms, **on that system at
   that version**. The cost at 4.6.6 with this template's feature set, on
   `ubuntu-latest` and `macos-latest`, is unmeasured — see `## Engines`.
4. **Gate 2, `vergen`.** `vergen 10.0.3` declares `rust-version = 1.96.0`,
   which is *exactly* today's floor (stable `1.98.1`, published 2026-09-03,
   minus two minors). Resolution at `rust-version = "1.96"` succeeds; resolution
   at `rust-version = "1.95"` — the floor as it stood one Rust release ago —
   makes Cargo report "Adding vergen v10.0.3 (requires Rust 1.96.0)". A
   build-dependency whose MSRV tracks current stable will therefore sit outside
   this template's floor whenever the floor lags, and the template would have to
   pin `vergen` back. That is the concrete reason the dependency-free `build.rs`
   is preferred over the Codex raw report's `vergen` recommendation, and it is a
   maintenance cost the Codex report does not state.

**Practice evidence, verified rather than asserted.** Every manifest line below
was read in this run via `GET
https://api.github.com/repos/<o>/<r>/contents/Cargo.toml`, base64-decoded,
2026-09-10; star counts are from the Opus raw report at the same retrieval date.

| Project | Why it is a relevant reference | Manifest evidence |
|---|---|---|
| `rust-lang/cargo` | the Rust project's own package manager | `Cargo.toml:42-43` — `clap = "4.6.0"`, `clap_complete = { version = "4.6.0", features = ["unstable-dynamic"] }`; `:173` adds `wrap_help` |
| `rust-lang/rustup` | the Rust project's toolchain installer | `Cargo.toml:46,48` — `clap = { version = "4", features = ["derive","wrap_help","string"] }`, `clap_complete` |
| `astral-sh/uv` | one of the newest high-adoption Rust CLIs (89,684 stars per the Opus report) | `Cargo.toml:125,131` — `clap = { version = "4.5.17", … }`, `clap_complete_command = "0.6.1"` |
| `astral-sh/ruff` | same maintainer, 49,573 stars per the Opus report | `Cargo.toml:82-83` — `clap = { version = "4.5.3", features = ["derive"] }` |
| `casey/just` | ships **exactly** this decision's feature set | `Cargo.toml:24-26` — `clap = { version = "4.0.0", features = ["derive","env","string","wrap_help"] }`, `clap_complete = "=4.6.8"`, `clap_mangen = "0.3.0"` |
| `starship/starship` | tracks clap closely; also the adopter of the *rejected* metadata crate | `Cargo.toml:38-39` — `clap = { version = "4.6.6", … }`, `clap_complete = "4.6.9"`; `:79` — `shadow-rs = "2.0.0"` |
| `BurntSushi/ripgrep` | the strongest counterexample | `Cargo.toml:63` — `lexopt = "0.3.0"`; no clap |

`casey/just` is the composition evidence for this feature set: one released
binary carrying `clap` with `derive`+`env`+`string`+`wrap_help` alongside
`clap_complete`. State its limit exactly — its manifest requests `clap =
"4.0.0"` and pins `clap_complete = "=4.6.8"`, so it demonstrates that this
*feature combination* ships in production, not that it ships at the 4.6.6 and
4.6.9 recommended here. The version matrix is proved independently in the
crate metadata — `clap_complete 4.6.9` declares `clap >= 4.5.20`
(`clap_complete-4.6.9/Cargo.toml:127-130`), so `clap 4.6.6` satisfies it, and
the resolution in `## Empirical check` produced a single `clap v4.6.6` node
shared by both.

**Essential behaviors** — each verified by reading the published crate source at
the version cited, 2026-09-10:

1. `--version` renders `Command::long_version` and `-V` renders
   `Command::version`. This is not configuration; it is how the parser
   dispatches `ArgAction::Version`: `Identifier::Long` sets `use_long = true`
   and `Identifier::Short` sets `use_long = false`
   (`clap_builder-4.6.6/src/parser/parser.rs:1322-1330`), and `_render_version`
   then prefers `long_version` or `version` accordingly, each falling back to
   the other (`command.rs:4898-4914`).
2. The rendered string is `format!("{display_name} {ver}\n")`
   (`command.rs:4913`). So the version string is *appended* to the display name
   on one line rather than replacing it: give `long_version` a value whose first
   line is the bare semver, and the **first line of `--version` is
   `<tool> <semver>`**, in R4.6's GNU name-and-version shape, with the extra
   lines coming from newlines inside the `long_version` value. A `long_version`
   whose first line is not the semver would not have that property.
3. A `global = true` argument matches on every child subcommand: "Global
   arguments *only* propagate down … it doesn't matter where the user *uses* the
   global argument" (`arg.rs:877-886`, with the doctest at `:894-911` asserting
   `prog do-stuff --verbose`). This satisfies R4.5's `MUST` (before the verb)
   and its `SHOULD` (after the verb) from one declaration.
4. `Arg::env` is per-argument and reads the process environment at declaration
   time (`arg.rs:2205-2210`), gated on the `env` feature. No prefix or
   auto-binding API exists (grep, above).
5. Unknown-command matching is `strsim::jaro` with the literal threshold
   `confidence > 0.7`, sorted most-similar-last
   (`clap_builder-4.6.6/src/parser/features/suggestions.rs:17-35`). The source
   carries the maintainers' own reason for `jaro` over `jaro_winkler`: "GH
   #4660: using `jaro` because `jaro_winkler` implementation in `strsim-rs` is
   wrong causing strings with common prefix >=10 to be considered perfectly
   similar" (`:17-18`). With the `suggestions` feature off, `did_you_mean`
   returns an empty `Vec` (`:38-45`) — so the feature, which is on by default
   (`clap-4.6.6/Cargo.toml`, `default = [… "suggestions"]`), must stay on.
6. `infer_subcommands` is opt-in (`command.rs:1840`), so exact matching is the
   default. Leave it off: R3.10 `(MUST)` forbids automatic prefix abbreviation
   because "adding a flag later silently breaks scripts that relied on the
   shorter form" (`:229-230`). With the canonical noun singular under R1.3, the
   conformant behavior on a mistyped noun — say `<tool> projct list` — is a
   suggestion that *names* `project`, at exit `2`; what R3.10 forbids is
   *resolving* a prefix such as `proj` to `project` by inference. The
   distinction is between naming a candidate and silently accepting one. A
   plural spelling is a different case again: it is reachable only if an
   explicit hidden alias is declared for it (R1.3's `MAY`), never by inference,
   and it stays absent from help either way.
7. `clap_complete 4.6.9`'s `Shell` enum is `Bash`, `Elvish`, `Fish`,
   `PowerShell`, `Zsh` (`clap_complete-4.6.9/src/aot/shells/shell.rs:15-26`),
   covering R9.1's required three, and `aot::generate` writes to any
   `dyn Write` (`src/aot/generator/mod.rs:284-291`) — so the `completion`
   subcommand can print to stdout rather than to a file.

**Observable acceptance criteria — every one is a proposal for P03; none was
executed here** (see `## Empirical check` for what was and was not run):

| # | Criterion |
|---|---|
| AC1 | `<tool> project list --json` and `<tool> --json project list` both parse, and the flag is declared exactly once (R4.5) |
| AC2 | `<tool> -V` emits exactly one line matching `^<tool> \d+\.\d+\.\d+$` and exits `0` (R4.6's shape) |
| AC3 | `<tool> --version` emits that same first line plus a target-triple line and a rustc line, and the triple differs between the `ubuntu-latest` and `macos-latest` CI legs — which is what distinguishes a build script that read Cargo's `TARGET` from one carrying a hard-coded string |
| AC4 | `<tool> completion bash`, `… zsh` and `… fish` each write a non-empty script to stdout and exit `0`; a golden-file test detects drift between the parser and the emitted scripts |
| AC5 | `<TOOL>_OUTPUT=json <tool> project list` honors the env var; a global option deliberately left out of the curated set is **not** readable from `<TOOL>_*`, asserted by a test over `Cli::command()` that enumerates every argument carrying an `env` and compares it to a pinned list (R5.4) |
| AC6 | `<tool> projct list` (a mistyped noun, unknown) exits `2`, prints a suggestion naming `project` on stderr, keeps stdout byte-empty, and executes no command; and `<tool> proj list` (a bare prefix) also exits `2` rather than resolving to `project`, which is what `infer_subcommands` left off buys (R3.10 + R67) |
| AC7 | `<tool> --help` and `<tool> --version` exit `0` with output on stdout; every other parse failure exits `2` inside R67's JSON envelope on stderr |
| AC8 | every command path is `<noun> <verb>` at depth ≤ 3, asserted by walking `Cli::command().get_subcommands()` (R1.1, R1.2) |
| AC9 | **the canonical form of every documented noun is singular (R1.3 `MUST`).** Three assertions, because the rule has three parts. (a) `<tool> project list` parses and is the documented spelling: `<tool> project --help` and `<tool> --help` both exit `0` and name `project`. (b) Walking `Cli::command().get_subcommands()` (`command.rs:3932`), every subcommand that is help-visible — `is_hide_set()` (`:4242`) false — has a singular `get_name()` (`:3756`), checked against a pinned list of the template's nouns rather than by an English pluralization heuristic, which would misjudge irregular nouns. (c) No plural spelling appears in any rendered help: `render_long_help()` (`:1037`) for the root and for every subcommand contains no `projects`, asserted by string search over the rendered text. (c) is the assertion that actually discharges "**MUST NOT** appear in help or docs"; (a) and (b) alone would pass a tool that documented both spellings |
| AC10 | **if, and only if, a hidden plural alias is declared:** `<tool> projects list` parses to the same command as `<tool> project list` and exits `0`, while the alias is absent from every help surface AC9(c) searches — for the `project` subcommand, `get_visible_aliases()` (`command.rs:3847`) yields nothing and `get_all_aliases()` (`:3874`) yields `projects`, which is exactly the split `Command::alias` produces and `visible_alias` does not (R1.3's `MAY`, R1.6). If no alias is declared, AC10 is vacuous and `<tool> projects list` exits `2` under AC6's rule. Both outcomes conform; P03 records which it chose |

**OVERRIDE (OV-01) — F267 extended `--version` output deviates from R4.6
`(SHOULD)`.** This is the programme's first override and the only one in this
decision. Its rule references — R4.6 at `:275-279` and the conformance clause at
`:50` — resolve against the pinned standard revision recorded under "THE
STANDARD PIN" above (version 1.4.14, blob `f9de0437`), so the `SHOULD` being
deviated from is fixed text rather than whatever a later amendment makes of it.

**Waiver status, as of 2026-09-12: requested, not granted.** The owner has not
answered the waiver request, and nothing below should be read as approval. Only
the owner can record a `SHOULD` waiver (`:50`), no such record exists, and until
one does the recommended option (a) is a *proposed* deviation. The conforming
alternatives are named in the Options table below and are **option (b)** —
extended data behind `<tool> --version -o json` — and **option (c)** — extended
data moved to a `doctor` verb; either can be adopted instead of (a) with no
waiver at all, and the cost of adopting one is confined to rewriting AC2 and
AC3.

**Argument:** R4.6 (`:275-279`, read 2026-09-10) says `--version`/`-V`
"**SHOULD** print a single line `acme <semver>` … a build **MAY** append
commit/date for pre-release builds". Printing a target-triple line and a rustc
line on *every* build is more than that `MAY` permits, so the recommended shape
is a deviation. It is a `SHOULD`, and the standard's own conformance clause
makes such a deviation legitimate only when recorded: "A SHOULD waiver **MUST**
name the rule ID, describe the deviation, explain the rationale, and record the
owner/date or equivalent review record" (`:50`). That owner record does not
exist yet, so this is filed as an override rather than settled. The deviation is
narrow in three ways worth stating exactly: it applies to `--version` only, `-V`
stays fully conformant, and the first line of `--version` is still
`<tool> <semver>` because clap formats `{display_name} {ver}` (essential
behavior 2 above). py's precedent for the extended content is real but is not
itself a reason — py prints three lines on *both* spellings unconditionally (py
`cli/main.py:48-56`, read through the pin 2026-09-10), which is further from
R4.6 than what is recommended here.

**Options:**

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** `-V` one line; `--version` prints that line plus a target line and a rustc line, via `Command::long_version` | F267's information content is available from the flag a user already knows; one `long_version` string, no new command | R4.6 deviation, waiver required per `:50` |
| b | `-V` *and* `--version` both one line; extended data behind `<tool> --version -o json`, which R4.6 explicitly permits (`:277-279`) | fully conformant; costs the user a second flag to discover, and couples F267 to R66's output-format surface, which R60's prompt puts out of scope | conformant |
| c | `-V` and `--version` both one line; extended data moved to a `doctor` verb (py has one at `cli/main.py:103`) | fully conformant; separates "what version" from "what build", which is arguably the cleaner split | conformant |

The owner's ruling is needed because only the owner can record a `SHOULD`
waiver. **If the ruling is (b) or (c), nothing else in this decision changes**:
the build-metadata mechanism, the `version`/`long_version` API and every other
member are unaffected, and only the acceptance criteria AC2/AC3 are rewritten.

**BASELINE-REVIEW findings.** None. F266 and F271, the two inherited rows this
item touches, are marked `retained` in `docs/port/BASELINE-REVIEW.md:114-115`
(read 2026-09-10), and the crate-source reads above confirm both capabilities
are native to the recommended stack rather than hand-built. The Codex raw report
emits a `BASELINE-REVIEW: F269` line; that line is not carried, for the reason
given in `## Engines`.

re-verify: 2027-03-10, or earlier on any of — **the org CLI Design Standard moving off the pinned revision (version 1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`), which is detectable by re-running `## Empirical check` row E10, the only check here that reads live history — `bash review/evidence/r60-snapshot-provenance-r3.sh`, whose check `C2a` fails the moment the newest published commit for that path is no longer `fb30a591…`: any new commit to `cli-design-standard.md` changes the blob id and invalidates every `:<line>` citation here, and an amendment to R1.1, R1.3, R3.10, R4.5, R4.6, R5.4, R9.1 or the Appendix A entry criteria would change the substance as well**; clap releasing a 5.x line; the `clap_complete` `unstable-dynamic` completion path stabilizing; a RustSec advisory opening against `clap`, `clap_builder`, `clap_derive`, `clap_complete` or `strsim`; R22 (`runtime-version-accessor`) resolving and changing where the version value comes from; Rust stable advancing far enough that the MSRV floor rises above a recommended crate's declared `rust-version` (the highest declared `rust-version` among the 28 dependency crates is **1.85**, shared by the five `clap`-family crates, so the current 1.96 floor has eleven minors of headroom and this trigger is remote); or the owner ruling on OVERRIDE (OV-01).

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's prompt carries an empty `- owns:` line and an empty `- consumes:`
line, so it owns no registry parameter and consumes none; the four lines above
are the fixed parameters, copied from `docs/port/PARAMETERS.md`. No `CONFLICT:`
line is raised.

How each bears on the decision. **msrv-policy** fixes the floor at `1.96` today
(stable `1.98.1`, published 2026-09-03, minus two minors) and is what excludes
`shadow-rs`, `argh`, `lexopt` and `pico-args` at gate 2 for declaring no
`rust-version` at all, and what demotes `vergen 10.0.3` — whose declared
`1.96.0` sits exactly on the floor with no headroom — beneath a dependency-free
`build.rs`. **rust-edition** is satisfied without action: `clap 4.6.6` and
`clap_complete 4.6.9` both declare `edition = "2024"` themselves.
**license** is this repository's own declared expression and is unaffected by
anything recommended here, because nothing recommended here is committed into
this repository as source. Under the owner's 2026-09-12 ruling (Q7.B) no
dependency's licence is evaluated against it, so this parameter imposes no
constraint on crate selection and excluded no candidate; the expressions the
registry returned for all 28 resolved crates are recorded as facts in the
evidence log, section W. **target-os-matrix** is the gate
this run did *not* discharge: nothing here was executed on `ubuntu-latest`, and
that gap is recorded under `## Engines`.

Three parameter-shaped notes that are deliberately **not** parameter lines.
R22 (`runtime-version-accessor`, ledger F064) supplies the version *value* that
F267 prints; it is listed in this item's prompt as "related (not a registry
dependency)", and this decision is compatible with either R22 outcome and
imposes no constraint on it. R67 owns `error-taxonomy-exit-codes`; this item
consumes none of it as a parameter, but its parser-error routing must satisfy
R67's contract, as described in `## Decision`. All three Doxa provider bodies
wrote `owns` lines for names such as `cli-parsing-framework`,
`command-surface`, `extended-version` and `blanket-global-env-binding`; no such
row exists in `docs/port/PARAMETERS.md`, and the prompt's `- owns:` line is
empty, so none of them appears above.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4, `aarch64`.
Rust stable at the retrieval date is `1.98.1`, published 2026-09-03 (`GET
https://api.github.com/repos/rust-lang/rust/releases/latest`, `tag_name`), so
the local toolchain is one patch behind stable and the MSRV floor is `1.96`.

**Working directory** for every command:
`/private/tmp/claude-501/…/scratchpad/r60` (a scratch directory). Nothing was
written into the template repository. **Nothing here implements the
recommendation**: no command surface, no `completion` command, no `build.rs`, no
CLI of any kind was written. The only Rust files created are two
resolution-only manifests, each with an empty `src/lib.rs`, which exist solely
so that `cargo` will resolve the pins.

**Two runs, kept separate.** Sections 01–12 below are the **revision-1** run of
2026-09-10; rows E1–E10 are the verification run first performed for revision 2
on 2026-09-12 and **re-executed in full for revision 3 on 2026-09-13** against a
rebuilt, self-contained evidence apparatus. It verifies the standard pin, the
R1.3 rule text, every standard line this decision cites, the clap APIs the new
acceptance criteria name, what this revision preserved, and — row E10 — that
every snapshot it reads really came from the source it names.
**Identifier note:** `E<n>` numbers an evidence row in this section and `C<n>` a
check inside a saved script; `P<n>` numbers a *principle* in `## Decision`'s
agreement table and `AC<n>` an acceptance criterion. The four sequences are
independent — `E6` and `P6` are unrelated. The `C<n>` ids were renumbered in
revision 3 when the scripts were rewritten; where a row names one, it names the
revision-3 script's id.

**Revision-1 output: `review/evidence/r60-cli-parsing-verification.log`** (1,142
lines; the section numbers and letters below match the headings in that file).
**Neither later revision re-ran sections 01–12**, and neither restates their output
as freshly reproduced. Those sections queried live endpoints (crates.io, the
GitHub API, rustsec.org), so a rerun would legitimately differ in download
counts, star counts, issue totals and advisory-database size. What is
independently attested instead is the pair of headline commands: the
revision-1 auditor reran `cargo generate-lockfile` and `cargo-audit audit` in an
isolated fixture and reported both at **exit 0**, with 28 registry packages
locked at `rust-version = "1.96"`, 29 stanzas including the local root, 29 crate
dependencies scanned, and `clap 4.6.6`, `clap_complete 4.6.9` and `strsim 0.11.1`
resolving as recommended (`review/audit-codex.r1.md:8-15`, actor
`audit-codex-2026-09-05T183002Z-09f93cfc507c-r1`, rerun log
`review/evidence/audit-cli-parsing-framework-r1.log`). Those two exit-zero
results are therefore reproduced evidence from a second party, not a
re-description of the original run.

| § | What it checks | Command | Result |
|---|---|---|---|
| 01 | version, license, declared MSRV, downloads for 13 candidates | `GET https://crates.io/api/v1/crates/<name>` and `/versions`, newest unyanked | `clap 4.6.6` MSRV `1.85`, `MIT OR Apache-2.0`, 226,398,266 recent / 1,119,879,906 all-time; `clap_complete 4.6.9` MSRV `1.85`; `vergen 10.0.3` MSRV **`1.96.0`**; `shadow-rs`/`argh`/`lexopt`/`pico-args` declare **no** `rust_version`; `argh` is `BSD-3-Clause` |
| 02 | repository state and open issues | `GET https://api.github.com/repos/<o>/<r>`; `GET /search/issues?q=repo:<o>/<r>+is:issue+is:open` | `clap-rs/clap` 16,697 stars, `archived` false, `pushed_at` 2026-09-09, **369** open issues; `pico-args` `pushed_at` 2023-10-19 |
| 02–03 | advisories, with the 404 reading validated | `GET https://rustsec.org/packages/<name>.html` | 404 for all eight recommended-or-runner-up crates; controls `anyhow` → 200 `RUSTSEC-2026-0190` and `atty` → 200 (two IDs) confirm 404 means "no advisory page" |
| 04 | clap behavior, read in the published tarball | `curl https://static.crates.io/crates/clap/clap-4.6.6.crate` (sha256 `473c7e07f409a8d772161724aa8db6a765a2532a70f9667eeb7b49d3d02fbdca`) and the three companion tarballs, unpacked | the seven essential behaviors listed in `## Decision`, each at a cited file and line; `default = [std,color,help,usage,error-context,suggestions]`; **no** `env_prefix`/`auto_env`/`envvar_prefix` symbol anywhere in `clap_builder` or `clap_derive` |
| 05 | completion generator | read `clap_complete-4.6.9` | `Shell` = Bash/Elvish/Fish/PowerShell/Zsh; depends on `clap >= 4.5.20` with `default-features = false` |
| 06 | build-metadata mechanism | `rustc -vV`; `GET https://doc.rust-lang.org/cargo/reference/environment-variables.html` | `rustc -vV` prints `release:`, `host:`, `commit-hash:`; the Cargo reference lists `TARGET`, `HOST`, `RUSTC`, `PROFILE` among the variables Cargo sets **for build scripts** — the two facts the dependency-free `build.rs` relies on |
| 07 | do the recommended pins resolve at the floor | `cargo generate-lockfile` and `cargo tree -e normal` on a manifest with `rust-version = "1.96"`, `edition = "2024"` and the two dependency lines | **exit 0** — "Locking 28 packages to latest Rust 1.96 compatible versions"; one shared `clap v4.6.6` node under both dependencies; `strsim v0.11.1` present transitively under `clap_builder`, never direct |
| 08 | advisories and licenses of the resolved tree | `cargo audit`; per-crate registry license lookup for all 28 | `cargo audit` **exit 0**, 1,243 advisories loaded, 29 crate dependencies scanned, nothing reported; every license MIT-or-Apache-compatible, `strsim` MIT the only single-licensed one |
| 09 | `vergen` MSRV headroom | the same resolution with `rust-version` `1.96`, then `1.95` | resolves at `1.96`; at `1.95` Cargo reports "Adding vergen v10.0.3 (requires Rust 1.96.0)" |
| 10 | the two source repositories, through their pins | `git -C ~/c/py-launch-blueprint show b08bccfb…:<path>`; `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:<path>` | every `## Context` line confirmed: py `import click`, the three-line eager `_print_version`, `"auto_envvar_prefix": APP_NAME.upper()` with its "catch-all" comment, `COMMAND_GROUPS`, four explicit `envvar=` names, the `_GLOBAL_OPTIONS` re-application loop, `difflib.get_close_matches`; ts `import { Command, CommanderError }`, `.showSuggestionAfterError(true)`, root-only `.option(…)`, `.command('projects', { isDefault: true })`, and the comment "Usage errors must exit 2 (cli-standards R6.1)". These are quotations of the two ports' source; their plural noun is the recorded practice that R1.3 overrides for the Rust template, not this decision's grammar — see the R1.3 consequence bullet in `## Decision` and row P7 below |
| 11 | adopter manifests | `GET /repos/<o>/<r>/contents/Cargo.toml`, base64-decoded, for seven projects | the practice-evidence table in `## Decision`; `casey/just` carries this decision's exact feature set; `starship` carries `shadow-rs`; `ripgrep` carries `lexopt` and no clap |
| 12 | MSRV of the whole resolved tree | `cargo metadata --format-version 1 --all-features` | 28 of the 29 packages declare a `rust-version`; the highest among the dependencies is **1.85**, shared by `clap`, `clap_builder`, `clap_complete`, `clap_derive` and `clap_lex`; `utf8parse` declares none |

**Revision-3 run — the standard pin, R1.3, the new criteria's APIs, and the
provenance of every input.** Three scripts, all under `review/evidence/`, run on
macOS 26.4 `aarch64` on 2026-09-13. Each takes no argument and no working
directory: each derives its own location from `${BASH_SOURCE[0]}` and reaches
everything else relative to that, so the invocation is the same from any
directory and the results do not depend on where the checkout lives.

| Script | Log | Result |
|---|---|---|
| `r60-standard-pin-r3.sh` | `r60-standard-pin-r3.log` | exit `0`, `CHECKS RUN: 73   FAILURES: 0` |
| `r60-preservation-diff-r3.sh` | `r60-preservation-diff-r3.log` | exit `0`, `CHECKS RUN: 66   FAILURES: 0` |
| `r60-snapshot-provenance-r3.sh` | `r60-snapshot-provenance-r3.log` | exit `0`, `CHECKS RUN: 14   FAILURES: 0   UNREACHABLE: 0   UNVERIFIABLE-HERE: 2` |

**Nothing was implemented**: no crate was scaffolded, no command surface,
`build.rs`, `completion` command or test was written, and no script writes any
file anywhere — all three emit only to stdout.

**The revision-2 scripts and logs are retained and are not evidence for this
revision.** `r60-standard-pin-r2.sh`, `r60-preservation-diff-r2.sh`, their two
logs and the volatile sidecar `r60-concurrent-branch-state-r2.txt` stay in
`review/evidence/` because `review/audit-codex.r2.md` cites them by name and
deleting them would erase the record the rejection rests on. They are **known not
to rerun to their saved output from the committed state** — that is the finding
that produced this revision, reproduced by the auditor at exit `1` and exit `2`
— and no row below cites them. The sidecar is no longer produced by anything;
nothing in this decision ever rested on it.

**Why the apparatus was rebuilt, since that is this revision's whole subject.**
Revision 2's two scripts produced the same *content* answers, but they could not
be rerun once revision 2 was committed. Four distinct mechanisms did that, and
each one is removed rather than worked around:

| # | What revision 2 depended on | Why it failed after the commit | What revision 3 does instead |
|---|---|---|---|
| 1 | `HEAD:…/DECISION.md` resolving to the revision-1 blob `5ae06c37…` | at revision 2's commit that path resolves to the revision-2 blob, so the check inverted | the revision-1 and revision-2 texts are committed as `snapshots/r60-decision-r1.md` and `snapshots/r60-decision-r2.md` and identified by the sha256 each audit report names |
| 2 | `git status --porcelain` reporting exactly six dirty paths, one of them `DECISION.md` | committing makes the tree clean, so both counts go to zero | "the revision landed" is the r1→r3 and r2→r3 diffs being non-empty; "nothing was scaffolded" is a `find` over the committed run directory |
| 3 | `$HOME/c/cli-standards`, `$HOME/c/py-launch-blueprint`, `$HOME/c/ts-launch-blueprint` | those clones exist only on the authoring machine | the exact bytes read are committed under `review/evidence/snapshots/`, each verified against `snapshots/MANIFEST.txt` before it is read |
| 4 | an unpacked crate tarball under `/private/tmp/r60-r2-verify/` | a scratch directory that no longer exists; the script's own fallback branch counted a failure | the two source files read out of those tarballs are committed as snapshots, and the tarballs are re-downloaded and re-extracted by the provenance script |

**What each script guarantees, stated as the claims an auditor will test.**

**They can fail.** Every script opens with a `C0` negative control asserting a
substring known to be absent, so each log opens with a deliberate `FAIL` line
followed by `PASS C0 …`; if a harness ever stops detecting mismatches it exits
`99` and says the results are meaningless. Counters are then reset, which is why
the deliberate failure is not in the totals. That control exists because an early
draft put `check` on the right-hand side of a pipe — a subshell, whose increment
of the failure counter is lost — and printed `ALL CHECKS PASSED` while two checks
had in fact failed.

**They assert on content, never on exit status alone.** Every check names an
expected substring, and an empty expectation is itself reported as a bug rather
than passed. Numeric checks compare a labelled string (`count=0`, not `0`), so a
count of `10` cannot satisfy an expectation of `0` by substring match — a latent
defect in revision 2's harness, found and fixed here.

**The two offline logs are reproducible byte-for-byte, and that was demonstrated
from the committed state rather than from the working tree.** `r60-standard-pin-r3.sh`
and `r60-preservation-diff-r3.sh` read only files committed in this repository:
the snapshots under `review/evidence/snapshots/`, `docs/port/PARAMETERS.md`, the
published R67 topic, this run's audit reports, and `review/DECISION.md` itself.
They make no network call and need no git repository. Both were rerun against an
extraction of the exact tree this revision commits — `git archive` of that tree
into an empty directory outside the repository, which carries no `.git` and no
working-tree state — and `diff` against the two logs cited here reported no
difference. The transcript of that extraction and diff is recorded in this
revision's commit message, so the claim can be checked without rerunning
anything. Two properties make it possible and are worth naming, because losing
either would silently break it: no script prints an absolute path, and `shasum`
is always fed on **stdin** so it prints `-` instead of a file name.

**The provenance log is reproducible only while the network is reachable, and
that is said rather than hidden.** `r60-snapshot-provenance-r3.sh` re-downloads
every pinned source and re-derives each snapshot's sha256 from it. It counts three
outcomes separately — `FAILURES` (the source was reached and disagrees),
`UNREACHABLE` (it could not be fetched, so nothing is proved either way) and
`UNVERIFIABLE-HERE` (there is no public remote at all) — and exits on `FAILURES`
alone, so an offline rerun is visibly incomplete instead of quietly green. Its two
`UNVERIFIABLE-HERE` entries are the two TypeScript source files: `smorinlabs/ts-launch-blueprint`
is a private repository, so no rerun outside the owning organisation can refetch
them. That is not asserted either: the script probes
`https://raw.githubusercontent.com/smorinlabs/ts-launch-blueprint/cb1cbcb2…/<path>`
anonymously and requires **HTTP 404**, which is what makes "no public remote" a
checked fact. For those two files the committed snapshot is the evidence of
record. Everything else re-derived exactly: the standard from a commit-addressed
`raw.githubusercontent.com` URL, the two `clap` sources from crates.io tarballs
whose checksums crates.io itself records, the two Python sources from a
commit-addressed URL, and the two decision texts from this repository's own git
objects.

Sections 01–12 above remain **not** claimed as reproducible, for the unchanged
reason: they queried live counters.

| Row | What it checks | Command | Result |
|---|---|---|---|
| E1 | that the text every `:<line>` citation resolves against is the pinned revision (`C1`, `C2` of `r60-standard-pin-r3.sh`) | verify each snapshot's sha256 against `snapshots/MANIFEST.txt`, then hash `snapshots/cli-design-standard-1.4.14.md` | all 10 snapshots match their recorded hashes, MANIFEST records exactly the files present and no others, and the standard snapshot's sha256 is `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f` — **the sha256 of blob `f9de0437…` at commit `fb30a591…`**, which is how the committed text and the pinned blob are established to be the same bytes without needing a clone of the standards repository. The snapshot is 773 lines, asserted, so an out-of-range `:<line>` citation cannot pass silently. Its recorded origin is the commit-addressed URL `raw.githubusercontent.com/smorinlabs/cli-standards/fb30a591…/cli-design-standard.md`. That the pin is still the *newest* published commit is a live-history claim and is row E10 |
| E2 | the document declares version 1.4.14 (`C3`) | `sed -n '1,12p'` on the pinned text | `| **Version** | 1.4.14 |`, `| **Status** | Active — canonical |`, `| **Last updated** | 2026-06-28 |` |
| E3 | R1.3's full text, the rule revision 2 repaired the decision against (`C4`) | the same pinned text, `sed -n '133,137p'` | `**R1.3 — Noun number. (MUST)**`; "Resource nouns **MUST** be **singular** in their canonical form"; "The plural form **MAY** be accepted as an undocumented alias but **MUST NOT** appear in help or docs"; "`list` returning many is not a reason to pluralize"; and the ❌ example "documenting `acme widgets list` as the primary form" |
| E4 | R1.3 is org-locked, and the Decision Log line numbers (`C5`, `C6`) | the same pinned text, `sed -n '61p;63p;65p;67p;69p;70p'` | row 5 `| 5 | Noun number | Singular canonical; plural accepted as undocumented alias |` is at **`:67`**, marked `org-locked`; the table header is at `:61` and row *N* at line 62 + *N*, so row 1 is `:63`, row 3 `:65`, row 7 `:69`, and **`:70` is row 8, Exit codes** — R67's row. **This corrected three citations**: revision 1 cited `:70` for rows 1, 3 and 7, having copied R67's line for its own row 8 |
| E5 | every other standard line this decision cites (`C7`–`C9`) | the same pinned text, one `sed -n '<n>p'` per citation | all resolve: `:50` the SHOULD-waiver clause, `:124` R1.1, `:129` R1.2, `:146` R1.6, `:229` R3.10, `:270` R4.5, `:275` R4.6, `:321` R5.4, `:579` Appendix A criterion 1, `:586` the noun-verb counter-example; R1.3 is cross-referenced by R2.2 at `:177` and by the Appendix C checklist at `:635` ("R1.3 singular nouns") |
| E6 | whether R67 pinned the standard (`C13`) | `grep` over the published R67 topic's `DECISION.md` and its 18 evidence logs, reached by a path relative to the script | **R67's body: no pin** — zero citations carrying a version, commit, blob or hash, across its two citations of the file (`:78`, `:464`), and zero occurrences of `1.4.14`. **R67's audit trail: the version, but not a pin** — its revision-4 audit log records at `:6` "Standard read: `…/cli-design-standard.md`, version 1.4.14"; the only other mention among the evidence logs is one quoted line of the standard's own changelog. Asserted as labelled counts (`count=0`, `count=2`, `count=2`, `count=1`), so an absence cannot be confused with a failed search and a two-digit count cannot satisfy a one-digit expectation. The presence of R67's decision file is itself asserted first, so a moved file would fail rather than read as four zeroes |
| E7 | that both source ports document the plural noun (`C10`) | read the four committed port snapshots, taken through each port's pin | py `cli/commands/projects.py:37` is `@click.group(name="projects", cls=SuggestingGroup)`; py `cli/commands/__init__.py` is `COMMAND_GROUPS = [projects_group, config_group]`; ts `src/commands/projects.ts:70` is `.command('projects', { isDefault: true })`, looked up by that name at ts `src/router.ts:234`. This is the recorded practice R1.3 overrides |
| E8 | the clap 4.6.6 APIs AC9/AC10 name (`C11`, `C12`) | read `snapshots/clap_builder-4.6.6-src-builder-command.rs.txt` and the two `clap_derive-4.6.4` snapshots, each hash-verified against MANIFEST, which records the tarball each came from and that tarball's checksum | the `clap_builder` snapshot's recorded origin is `clap_builder-4.6.6.crate`, sha256 `7b48fea5a88e9ae728a2dcbedbfc0e730f7d60da42e1cb049a83c9fb8b789889` — **the checksum crates.io records for 4.6.6** (`GET /api/v1/crates/clap_builder/4.6.6`, retrieved 2026-09-12 and re-retrieved 2026-09-13; the same response gives `rust_version: 1.85`). All eight methods exist on `Command` at the cited lines: `get_subcommands` `:3932`, `get_name` `:3756`, `is_hide_set` `:4242`, `render_long_help` `:1037`, `get_visible_aliases` `:3847`, `get_all_aliases` `:3874`, `alias` `:2691`, `visible_alias` `:2893`. And the behavioral half: `alias`'s own doc says "Aliases defined with this method are *hidden* from the help message" (`:2664-2666`) while `visible_alias`'s says its alias "is *visible* from the help message" (`:2865-2868`) — which is what makes `#[command(alias = …)]` the R1.3-conformant spelling and `visible_alias` a violation. **The derive forwarding is verified too** (`C12`), since the R1.3 repair rests on it: `clap_derive-4.6.4` (tarball sha256 `d012d2b9d65aca7f18f4d9878a045bc17899bba951561ba5ec3c2ba1eed9a061`, likewise the checksum crates.io records) has no `MagicAttrName::Alias` variant and no mention of `alias` in `src/attr.rs`, so the name falls to the generic branch `_ => self.methods.push(Method::new(name, arg))` (`src/item.rs:337-345`) and a `Method` renders as `quote!( .#name(#args) )` (`:1281-1289`) — emitting `.alias("projects")`, the hidden method |
| E9 | that this revision preserved what the audits did not challenge (`review/evidence/r60-preservation-diff-r3.sh`, log `review/evidence/r60-preservation-diff-r3.log`; its own `C1`–`C7`) | confirm the committed revision-1 and revision-2 texts hash to the values the two audit reports themselves name; for each preserved claim, require every baseline line carrying it to still be present verbatim; re-read the four `assumes` values out of `docs/port/PARAMETERS.md`; `find` the run directory for Rust or Cargo artifacts; enumerate every differing line against both baselines | **exit 0**, `CHECKS RUN: 66 FAILURES: 0`, with **20 revision-1 preservation targets all verbatim**: the `clap 4.6.6` pin and its four features, the `clap_complete 4.6.9` pin, `strsim 0.11.1` transitive-only, the dependency-free `build.rs`, `clap_complete`'s `default = []` and its `clap >= 4.5.20` floor, "Locking 28 packages to latest Rust 1.96 compatible versions", the `cargo generate-lockfile`/`cargo tree` row, the `cargo audit` **exit 0** row with its 1,243 advisories and 29 dependencies, all four `assumes` lines, OV-01's R4.6 quotation and its options b and c and its owner-ruling sentence, architectures A and E, the `clap` fitness-gate data row, and the `casey/just` composition evidence — **plus 3 revision-2 targets**: OV-01's dated not-granted status line, R1.3's rule text as revision 2 quoted it, and the standard-pin row carrying the content hash. The four `assumes` values still match `docs/port/PARAMETERS.md` byte-for-byte and there is no `owns` line, as the prompt's empty `- owns:` requires. Structurally: four H2 sections in the required order, no `## Supersedes`, exactly one override declared and no second one, no affirmative claim that the owner granted the waiver (eight phrasings searched, negated forms excluded), the title recording revision 3, and gate 1 recorded as `inapplicable` with the ruling as its reason while the gate's row is kept in the table rather than removed. `find` reports zero `.rs`, `Cargo.toml` or `Cargo.lock` files and zero `src/` or `target/` directories anywhere in this run directory, and each of the nine evidence files this decision cites is asserted present. Both diffs are enumerated in full in the log; **their line counts are deliberately not quoted here, because quoting a count of the decision's own changed lines would change it** |
| E10 | that every committed snapshot really is what MANIFEST.txt says, and that the pin is still the newest published commit (`review/evidence/r60-snapshot-provenance-r3.sh`, log `review/evidence/r60-snapshot-provenance-r3.log`; its `C1`, `C2`) | re-download each pinned source and re-derive the snapshot's sha256 from it; for a crate, verify the tarball against the checksum crates.io records before extracting; for a private origin, probe anonymously and require HTTP 404; then `GET https://api.github.com/repos/smorinlabs/cli-standards/commits?path=cli-design-standard.md&per_page=1` | **exit 0**, `CHECKS RUN: 14 FAILURES: 0 UNREACHABLE: 0 UNVERIFIABLE-HERE: 2`. The standard re-fetched from its commit-addressed URL hashes to `9fb05d3d…`; both `clap` tarballs hash to the checksums crates.io records and the three extracted files hash to their snapshots; both Python sources re-fetched from their commit-addressed URLs match; both decision baselines match this repository's own git objects. The newest published commit touching `cli-design-standard.md` is still `fb30a591c267a7ec1130ba4cda679eaee494b9d7` — this is the live half of the `re-verify` trigger, and it is the check that will fail first when the standard moves. The 2 `UNVERIFIABLE-HERE` entries are the two TypeScript snapshots: `smorinlabs/ts-launch-blueprint` returns **HTTP 404** to an anonymous request, which the script asserts rather than assumes, so "there is no public remote to refetch from" is a checked fact and the committed snapshot is the evidence of record |

**Headline command and exit status.** `cargo generate-lockfile` on the
recommended pins at `rust-version = "1.96"` → **exit 0**, followed by
`cargo audit` on the resulting lockfile → **exit 0** (revision-1 run, and both
independently reproduced at exit 0 by the revision-1 auditor as described
above). For revision 3: `bash review/evidence/r60-standard-pin-r3.sh` → **exit
0**, 73 checks, 0 failures.

**What these runs do not establish**, stated so they are not read as more:
none of them built or ran any CLI; none executed any acceptance criterion; none
ran a benchmark; none ran anything on `ubuntu-latest`; and none audited any
crate's `unsafe` usage. Each of those is carried to `## Engines`. Rows E1–E10
narrow none of that list: they verify that the standard says what this decision
says it says, that its cited lines resolve, that the clap methods AC9 and
AC10 name exist with the documented alias visibility, and that the evidence can
be rerun from the committed state — **not** that any criterion passes. In
particular, AC9 and AC10 are unexecuted, exactly as AC1–AC8 are.

## Engines

- codex `raw/codex-99cfaa33b3ae00b921df4ad482e3b1a73a9f787eaa4d138197f544d3491cfb05.md` — figures retrieved 2026-09-05; three members (`clap 4.6.6`, `clap_complete 4.6.9`, `vergen 10.0.3`); states it could not compute issue responsiveness.
- opus `raw/opus-26f8720eb4b2714cb14fdca45302b55449205a5c3889909e881aa7116aff7735.md` — figures retrieved 2026-09-10; seven members, one per ledger row; the most complete report, and the only one that read the crate source rather than the documentation.
- doxa `raw/doxa.normalized.md` — three provider bodies regrouped by template field (`doxa-openai.normalized.md`, `doxa-perplexity.normalized.md`, `doxa-gemini.normalized.md`; repairs recorded in `doxa/normalization.json`), retrieved 2026-09-09.

**Where the engines agreed.** All three name `clap` as the framework and
`clap_complete` for F268; all three choose noun-verb subcommand groups over ts's
default-command shape for F265 — **on ordering only; none of them addressed the
noun's number, see "No engine raised R1.3" below** — all three choose `global = true` on a flattened
`GlobalArgs` for F270; and all three keep clap's built-in suggestions for F272
with no direct `strsim`. That agreement is not itself the evidence — the source
reads and the fitness gates in `## Decision` are — but no disagreement had to be
resolved on those four rows.

**Disagreement 1 — where the extended `--version` metadata comes from.** Codex
recommends `vergen 10.0.3` (`cargo` + `rustc` features); Opus recommends a
dependency-free `build.rs` with `built 0.8.1` ranked second; the Doxa OpenAI
body also recommends a plain `build.rs`; the Doxa Gemini body recommends
`shadow-rs`. **Settled by the registry and by resolution**, both in this run:
`shadow-rs 2.0.0` declares no `rust-version`, so it fails gate 2 on evidence;
`vergen 10.0.3` declares `1.96.0`, exactly today's floor, and Cargo reports it
as out of range the moment the floor is one minor lower — a permanent
maintenance coupling that Codex's report does not mention; the Cargo reference
plus `rustc -vV` confirm that `TARGET` and the rustc version are both reachable
from a build script with no crate at all. Hence the dependency-free script, with
`built 0.8.1` (MSRV `1.87`, real headroom) as the ranked runner-up and `vergen`
available if git-derived metadata later becomes a requirement. Note that
`starship/starship`, a well-regarded adopter, does ship `shadow-rs 2.0.0`
(`Cargo.toml:79`, verified 2026-09-10) — the exclusion is on declared-MSRV
evidence under this template's policy, not on the crate's quality.

**Disagreement 2 — blanket versus curated env binding (F269).** The Doxa OpenAI
body recommends automatic `PLBP_<UPPER_SNAKE_LONG_NAME>` binding generated by a
command-graph post-pass "for every application-defined global", and the Doxa
Perplexity body likewise recommends "blanket env-var binding using a standard
prefix such as `PLBP_` … via a small helper or macro that applies the prefix
automatically to each global option". Codex and Opus both recommend a curated
per-option mapping. **Settled by the org CLI Design Standard**, R5.4 `(MUST)`:
"the tool **MUST NOT** auto-expose every flag as an env var"
(`/Users/stevemorin/c/cli-standards/cli-design-standard.md:321-323`, read
2026-09-10 at the pinned revision recorded under "THE STANDARD PIN" — version
1.4.14, blob `f9de0437`), org-locked at `:69` row 7, and already treated as binding by the
published R67. The blanket designs are excluded on that rule alone. Both
blanket proposals are *mechanically* sound — `Command::mut_args` exists and
would do exactly what they describe — and this decision says so rather than
resting the exclusion on a capability claim that the source does not support.

**Disagreement 3 — is the standard binding on R60 at all?** The Opus report
raises this explicitly, treating the standard as "an owner-side requirement
input that the owner should confirm applies to R60 as well as R67", and keeps
its ecosystem case independent of it. **Settled against that framing**, on the
task's direction and on precedent: the published R67 adjudicates the same
document's R6.1 as an org-locked `MUST` and quotes its table verbatim, and ts's
own router cites `cli-standards R6.1` in a code comment. This decision therefore
cites the standard by file, line and retrieval date as R67 did, **and adds the
version, commit, blob id and content hash that R67 did not record** — see "THE
STANDARD PIN" in `## Decision` for the pin and for the verification that R67
carries no version pin of its own. The practical effect is confined but is wider
than revision 1 stated: it fixes F265's ordering as a `MUST` rather than a
preference **and F265's noun number as a `MUST` (R1.3), which is where revision 1
was wrong** — it proposed a plural canonical noun; it decides F269; and it turns
F267 into a recorded override. Every other row lands where all three engines
already put it.

**No engine raised R1.3.** None of the three reports — and none of the five
provider bodies — mentions noun number at all; all of them carried the plural
`projects` straight across from py's and ts's command surfaces, and revision 1
adopted it. The rule was found only by auditing the decision against the standard
it claimed to apply. Two things follow that matter beyond this item. First, the
engines' unanimity on "noun-verb subcommand groups" was agreement on *ordering*
only, and was read in revision 1 as if it settled the whole of F265; agreement
among engines is not evidence of conformance, and here it concealed a `MUST`
violation. Second, because R60 is a prerequisite for much of the programme, a
plural noun documented here would have propagated into every downstream item
that builds a command surface on it — which is the specific reason this
correction is worth its length rather than a one-word edit.

**Disagreement 4 — Codex's `BASELINE-REVIEW: F269` line is not carried.** The
prompt reserves `BASELINE-REVIEW:` for a *challenged baseline*. F269 is a
`DIVERGENT`, py-only row owned by this item
(`docs/port/COMMONALITY.md:273`), not an inherited baseline; the only baseline
rows this item touches are F266 and F271, both already `retained`. Deciding F269
against a curated mapping is this item's job, so it is recorded as the decision
rather than as a challenge to a baseline. The substance of Codex's line — that
an implicit prefix would silently turn every newly added global flag into a
public environment API — is preserved in `## Decision` and in acceptance
criterion AC5.

**Disagreement 5 — Doxa's parameter lines.** All three Doxa bodies write `owns`
lines for names that do not exist in `docs/port/PARAMETERS.md`, and the OpenAI
body additionally writes `assumes current rust-version = 1.96.0`. This item's
prompt carries an empty `- owns:` line, so `## Parameters` above carries only
the four fixed `assumes` values. No engine raised a `CONFLICT:`; none is raised
here.

**Doxa's own evidence gap, carried rather than repaired.** The regrouped Doxa
report opens with an "Evidence-completeness warning" stating that its transport
did not expose the crates.io JSON bodies, so its download, star and
responsiveness cells are marked pending rather than invented
(`doxa.normalized.md:38`). Its architecture reasoning is used above; none of its
figures is. Every registry and GitHub figure in this decision comes from the run
in `## Empirical check` or, where attributed, from the Opus report at its stated
retrieval date.

**Unproven claims, and what would prove each.** P03 must validate all of these
in the real template:

| # | Unproven | What would prove it |
|---|---|---|
| U1 | That `clap 4.6.6`, `clap_complete 4.6.9` and the transitive tree build and test on **`ubuntu-latest`** — gate 4. Nothing in this run executed on Linux; the resolution and the crate reads were done on macOS 26.4 `aarch64` only. | the template's own CI matrix running `cargo test` on both runners |
| U2 | The compile-time and binary-size cost **at 4.6.6, with the `derive`/`env`/`string`/`wrap_help` feature set, on this template's two runners**. The only figures cited anywhere in this decision are upstream `rosetta-rs` results measured by that project on Linux `x86_64` with `rustc 1.94.0` at clap **v4.5.60**; neither Opus nor this decision ran a benchmark. | `cargo bloat` or `cargo build --timings` on the built template, on each runner |
| U3 | The `unsafe` posture of `clap`, `clap_builder`, `clap_derive`, `clap_complete` and `strsim` — gate 3's second half, not assessed in this run. | `cargo geiger`, or reading each crate's `#![forbid(unsafe_code)]`/`unsafe` blocks at the pinned versions |
| U4 | That clap's usage text can be rendered **inside** R67's JSON envelope without losing clap's own formatting, and what the envelope's `message` and `hint` carry for a parse failure. This decision fixes the routing (`try_parse` + `kind()`) and the codes; it does not fix the rendering. | AC6/AC7 executed against the built CLI |
| U5 | Every acceptance criterion AC1–AC10. None was executed: no Rust CLI exists. AC9 and AC10 were added in revision 2 and are as unexecuted as the rest; what revision 2 *did* verify is that the clap APIs they name exist at 4.6.6 with the documented hidden-vs-visible alias behavior (`## Empirical check` row E8), which is a different and weaker claim than the criteria passing. | P03's integration tests |
| U6 | Issue responsiveness for every candidate except `clap-rs/clap`. The Opus report measured the 10 most recently opened issues for that one repository (5 of 10 answered, median 1.29 days among those answered, 5 unanswered, retrieved 2026-09-10) and states it measured no other; that figure also covers `clap_complete`, which shares the tracker. For `bpaf`, `built`, `vergen`, `argh`, `lexopt`, `pico-args` and `strsim`, the maintenance verdicts above rest on open-issue `total_count`, `pushed_at`, `archived` and release recency only. | the same 10-issue procedure run per candidate |
| U7 | That `bpaf` lacks a completion story equivalent to `clap_complete`. Opus asserts it does; Codex asserts a completion feature exists. Neither was verified here, and `bpaf` is excluded on fit (architecture D) rather than on this point, so the disagreement does not change the recommendation. | reading `bpaf 0.9.27`'s published source and feature table |

**Uncertainty that is not an evidence gap.** `clap-rs/clap` carries 369 open
issues against a project led by a single primary maintainer, which is a real
backlog signal. It does not meet the rubric's `at-risk` bar — no unpatched
advisory, no broken build on current stable, no maintainer notice, and releases
continuing (newest `4.6.6`, `created_at` 2026-08-06; repository `pushed_at`
2026-09-09) — so the maintenance verdict recorded here is **`active`**. If a
future re-verification finds the release cadence broken *and* the backlog
growing, architecture D (`bpaf`) is the shortlisted successor and U7 becomes the
first thing to settle.

**Audit of revision 1, and what revision 2 changed.** The revision-1 draft
(sha256 `d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c`, blob
`5ae06c378ee71a8d6b16eb394862806284c72ca5`) was **rejected** by
`audit-codex-2026-09-05T183002Z-09f93cfc507c-r1` (gpt-5.6-terra; report at
`review/audit-codex.r1.md`, rerun log
`review/evidence/audit-cli-parsing-framework-r1.log`) on two findings, both
repaired here.

**F1 — a `MUST` violation of R1.3.** Revision 1 made `projects` a canonical
documented resource noun and its acceptance criteria omitted the singular
canonical form. R1.3 `(MUST)` requires the canonical form to be singular, and a
`SHOULD` waiver cannot waive a `MUST`. Repaired at **nine** locations, found by
searching for every line carrying the noun rather than by re-reading: the F265
mechanism row; the P2 principles row; the Standard-profile consequence bullet
(`projects`→`project` in the template's resource groups); a new consequence
bullet stating R1.3 in full, with the hidden-alias mechanism and its clap
spelling; essential behavior 6, whose R3.10 example had rested on the plural
being canonical; AC1; AC5; AC6, rewritten around a mistyped noun and a bare
prefix instead of the singular form; and the engines-agreement paragraph, which
had read unanimity on *ordering* as though it settled the noun's number. Two new
criteria, **AC9** and **AC10**, assert the rule's three parts directly — that is
the specific gap the auditor named. Two occurrences of the plural were
deliberately **kept**: the verbatim quotation of the standard's own Appendix A
counter-example at `:586`, now marked as a quotation whose plurals are the
standard's illustrative wording, and the quoted `.command('projects', …)` line
from ts's source. Editing either would have falsified a quotation.

**F2 — the standard was not version-pinned.** Repaired by "THE STANDARD PIN" in
`## Decision`, which fixes version 1.4.14, commit `fb30a591…`, blob
`f9de0437…` and content sha256 `9fb05d3d…`, states the three independent recipes
that resolve it (the committed snapshot, the commit-addressed
`raw.githubusercontent.com` URL, and `git cat-file` in any clone), and records
that R67's body pins nothing while R67's revision-4
audit log independently attests the same version 1.4.14. The pin is referenced
from the status paragraph, from OV-01, from the R5.4 citation in this section,
and from the `re-verify` line, which now triggers on the blob id changing.

**Found while verifying the pin, and repaired although the auditor did not raise
it:** revision 1 cited the org-locked Decision Log at `:70` for rows 1, 3 and 7,
but `:70` is row 8 — R67's exit-code row, copied across. The correct lines are
`:63`, `:65` and `:69` (header `:61`, row *N* at 62 + *N*), and row 5, the
noun-number rule F1 turns on, is at `:67`. Three citations corrected. This is
the pin doing its job on its first use: pinning a document is worth nothing if
the line numbers into it are wrong, and only a mechanical check of every cited
line surfaces that.

**What is unchanged from revision 1**, and confirmed unchanged by diffing
against blob `5ae06c378ee71a8d6b16eb394862806284c72ca5`: the recommended crate
and feature set (`clap 4.6.6` with `derive`/`env`/`string`/`wrap_help`,
`clap_complete 4.6.9`, the dependency-free `build.rs`, `strsim 0.11.1`
transitive only); the lockfile generation and advisory audit that both exited
`0`; the four fixed `assumes` parameter lines, byte-for-byte; the five
architecture alternatives and every data row of the fitness-gate table (its
header cell is the one part that changed, and only to mark gate 1 inapplicable —
see the revision-3 note below); the seven essential
behaviors; the practice-evidence table; OV-01's argument, its three options and
its pending status; the five engine disagreements; and U1–U7 apart from U5's
criterion range. **OV-01 remains the only override** and remains ungranted: the
owner has not answered the waiver request, and revision 2 adds an explicit
"requested, not granted" status line plus the two conforming alternatives by
name, so no reading of it implies approval. Conformance to R1.3 is deliberately
**not** recorded as a second override, because a non-waivable `MUST` is a
constraint rather than a choice — the same treatment F269 already receives.

**Audit of revision 2, and what revision 3 changed.** The revision-2 draft
(sha256 `18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c`) was
**rejected** by `audit-codex-2026-09-05T183002Z-09f93cfc507c-r2` (gpt-5.6-terra;
report at `review/audit-codex.r2.md`) on a single blocker: **the evidence scripts
were not rerunnable once the revision was committed**, which contradicted the
decision's own byte-for-byte reproducibility claim. The auditor reported every
substantive content check passing and both negative controls behaving correctly;
what failed were lifecycle assertions that could only hold in an uncommitted
working tree. **No finding touched the recommendation, and the recommendation
does not move.** The four mechanisms behind the failure are named and removed one
by one in the table under `## Empirical check`; the two offline scripts now read
only committed files, and the rerun was demonstrated from a `git archive`
extraction of this revision's own commit rather than asserted.

**Corrected while rebuilding the scripts, although the auditor did not raise
it:** revision 2's harness compared counts as bare substrings, so an expectation
of `0` was satisfied by an actual count of `10`. Six checks were exposed to that.
Every numeric comparison in the revision-3 scripts is now a labelled string
(`count=0`), which cannot match that way. No revision-2 result changes as a
result — the counts were genuinely `0`, `1` and `2` — but the checks were weaker
than they read.

**Also changed in revision 3, on the owner's licence ruling of 2026-09-12 (Q4 as
superseded by Q7.B):** fitness gate 1 is struck from every item's evaluation, so
it is recorded here as `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, with the reason, in
the two places this decision evaluated a licence against a criterion: the
fitness-gate table's gate-1 column header, which now marks the gate inapplicable
and points at the qualification that carries the ruling, and the `## Parameters`
prose for `license`, which had said the parameter was "satisfied by the whole
resolved tree". **Nothing else moves, because nothing else rested on it**: all
four gate exclusions are gate-2 exclusions for a missing `rust-version`, and
`argh`'s `BSD-3-Clause` excluded nothing before the ruling and excludes nothing
after it. The licence values recorded in the table's cells, in `## Empirical
check` §01 and §08 and in the evidence log's section W are left byte-identical
and are re-labelled in prose as facts the registry returned rather than gate
verdicts — deliberately, because three of those lines are revision-1
preservation targets whose alteration would break the preservation claim this
decision rests on, and because deleting an observation is not what the ruling
asks for. The `- assumes license = MIT OR Apache-2.0` line is unchanged: it is
the repository's own declared expression, which the ruling explicitly leaves
standing, and it must in any case match `docs/port/PARAMETERS.md` byte-for-byte.
