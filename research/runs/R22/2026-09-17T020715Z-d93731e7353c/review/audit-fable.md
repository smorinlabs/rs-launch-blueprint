decision-sha256: 0e7ea78e64f6b9dc92a437973a76fb050352ddf64fd53b57c630d814d4c57f87
actor: audit-fable-2026-09-17T020715Z-d93731e7353c-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

I read `review/DECISION.md` whole (748 lines) at the sha256 above, recomputed
twice with `shasum -a 256` — once on opening and once immediately before writing
this file — `raw/codex.md` whole, `inputs/prompt.md`,
`docs/superpowers/plans/p02-roles/judgment-auditor.md`, `docs/port/PARAMETERS.md`,
`docs/port/COMMONALITY.md` rows F063, F064, F133 and F267,
`docs/port/BASELINE-REVIEW.md:69`, `:143`, `:250`, `docs/port/OWNER-REVIEW.md:47`,
`docs/planning/p02/execution-ledger.md:1000` (owner rulings W1-CODEX2 and
W1-CODEX3) and `:1028`, `research/topics/49-build-target-declaration/DECISION.md`,
`research/topics/60-cli-parsing-framework/DECISION.md`, the org CLI Design
Standard v1.4.14 at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in
`/Users/stevemorin/c/cli-standards`, and
`research/runs/R44/2026-09-17T020715Z-ff8c50edbd69/review/DECISION.md` with its
`review/audit-fable.md` for proportion and for the findings convention.

`review/audit-codex.md` does not exist. The role doc lists it as required
reading; the empirical audit is deferred under owner ruling W1-CODEX3 of
2026-09-18 — "Test Codex if it's available now, and if it is, use it. If not, do
without it", with the 21:53Z probe returning the account's usage-limit error
(`docs/planning/p02/execution-ledger.md:1000`). There is therefore no
audit-codex rerun to be consistent with, and this audit ran the reruns itself.

Fitness gate 1 is `inapplicable` by the owner ruling of 2026-09-12
(`docs/port/OWNER-REVIEW.md:47`, "2026-09-12 — no licence check for anything the
template uses (Q4, superseded and widened by Q7.B)"), so this audit raises no
licence finding and does not test the recorded licence figures. The decision
keeps the gate row with that reason rather than dropping it, which is what the
binding prompt asks for.

Everything below that I re-ran was run from a directory created by `mktemp -d`
under `$TMPDIR` and deleted afterwards; every rerun wrote its output there, never
over a tracked log. I touched no file in the run other than the one I am writing.

## Principle and agreement level

The shared requirement is stated at the level the owner stated it and is sourced
to him: "all versions have a single source of truth" (`inputs/prompt.md`,
`## Context`, owner direction 2026-09-04). The decision classifies the agreement
level as an **architectural pattern** rather than a capability, standard or tool,
and it earns that classification rather than asserting it: py binds at import
time through `importlib.metadata` and ts binds at bundle time through a manifest
import, the two mechanisms are unlike, and both satisfy the principle — so what
must agree is "one authored value, one accessor" and what may vary is when and
how the value is bound. That is the correct reading, and it is the same
agreement level `docs/port/BASELINE-REVIEW.md:69` assigns F133.

The decision preserves the principle with a native design rather than a
transliteration. It does not port py's mechanism, and it says exactly why it
cannot: architecture D (an installed-package registry queried at runtime) has no
Rust implementation, because a Rust library is compiled into its consumer's
binary and leaves no installed record. That is a structural argument, not a
preference, and check C4b turns it into a measurement — a binary copied into a
directory holding no `Cargo.toml` and no `.rlib` still reports its version.

The one capability py has that `env!` cannot reproduce is stated as a limit
rather than argued away: a runtime lookup can report the version of something the
process learned about after compilation, such as a dynamically loaded plugin.
The decision records that this template has no such surface, and puts "P03 adding
any surface that loads code at runtime" on the `re-verify:` line. That is the
honest handling.

**Ledger effect is right.** F064 (`COMMONALITY.md:70`, `DIVERGENT`, item R22) is
settled in the ts direction on timing and in a Rust-native way on mechanism.
F063 (`:69`) and F133 (`:139`) are confirmed, not amended — F063 because the
accessor derives from `[package] version` and adds no second authored copy, F133
because the accessor-equality assertion survives and now has measured failure
modes behind it. F267 (`:271`, R60) is left untouched, which the prompt's
`## Out of scope` requires. All four line references check out against
`docs/port/COMMONALITY.md`.

**No `BASELINE-REVIEW:` finding is the correct handling, and the reason given is
the right one.** The raw report proposed retaining F133's accessor assertion.
`docs/port/BASELINE-REVIEW.md:250` records that the 2026-09-04 review already
heard the opposite challenge and rejected it — "F133 finding unsupported
(accessor test cannot fail) | Accepted: an accessor wired to a literal or the
wrong package is catchable | Assertion retained" — so raising it again would
restate a settled row. The decision instead supplies what the 2026-09-04 review
lacked: measurement. Checks C6b–C6d show the test exiting 101 on a stale literal
and C7a–C7b show each crate's macro expanding to its own package's version, so
the assertion that was retained on an argument is now retained on evidence.
There is no `CONFLICT:` line and none is needed: the recommendation requires no
consumed value to change.

## Design and evidence

**The architectural comparison is genuine and is made before any library.** Four
architectures are compared on when the value binds and what it costs, and the
decision does the non-obvious work of refusing to file B (a `build.rs` emitting
`cargo::rustc-env`) opposite A. The Cargo Book's own wording, which I read in
`review/evidence/snapshots/cargo-book-excerpts.txt:8`, says the value "can be
then retrieved by the `env!` macro in the compiled crate" — a build script moves
where the string comes from, never when it binds. So the decided question is A
versus C/D, and B is a variant of A that buys extra fields for the price of a
build script. That reframing is correct and it is what makes the crate
candidates' rejection a fit argument rather than a timing argument.

**The library selection follows from principles and gates, not popularity.** The
three crate candidates are dispatched on gate or fit before any download figure
is weighed, and the selected mechanism is not a crate at all. `clap` — already in
the stack by R60 — is treated as the obvious competing answer and read at source
rather than at docs.rs: `clap::crate_version!` is declared at
`clap_builder/src/macros.rs:16` with body `env!("CARGO_PKG_VERSION")` at `:18`
behind `#[cfg(feature = "cargo")]` at `:14`, and `#[command(version)]` reaches
`Method::from_env(…, "CARGO_PKG_VERSION")` at `clap_derive/src/item.rs:554`. Both
bottom out in the same variable, so the decision correctly calls clap a spelling
of the recommendation rather than an alternative, and decides on scope: either
clap path binds inside the CLI crate, where the library and the web module cannot
see it. That is the argument that actually selects `src/lib.rs`, and it is the
right one.

**I re-derived all four luna corrections. All four hold.**

1. **`built` and gate 2.** The report's clause is quoted accurately — "excluded
   by gate 2. Its published manifest declares `rust-version = "1.87"`, below the
   current policy floor of Rust 1.96" (`raw/codex.md:52`). The gate runs the
   other way: `msrv-policy` floors the *template* at 1.96, so a dependency
   declaring 1.87 compiles on 1.96 and every later compiler, and only a declared
   `rust-version` above the floor fails. The figure is right —
   `crate.rust_version` for built 0.8.1 is `1.87` in
   `snapshots/crates-built-versions.json`, from
   `GET https://crates.io/api/v1/crates/built/versions` retrieved 2026-09-18 —
   and so is the floor: `[pkg.rust] version` in
   `https://static.rust-lang.org/dist/channel-rust-stable.toml` is
   `1.98.1 (48a229cea 2026-09-01)`, channel dated 2026-09-03, giving 1.96. I
   re-confirmed the floor live at 2026-09-18T22:34:41Z (check `L3`). R60's
   published decision reads the gate the same direction at its own candidate
   table (`clap 4.6.6` declares `1.85` — "11 minors of headroom"). The
   withdrawal of the gate-2 exclusion and the re-grounding on fit — R49's
   consumed value forbids a `build.rs` for this package's targets — is correct,
   and the qualification that only the crate's own declaration was read, not its
   tree, is applied to `built`, `vergen-gix` and `shadow-rs` alike.
2. **The RustSec 404s are a negative result with controls both ways.** I re-ran
   the four reads myself against `https://rustsec.org/packages/<name>.html` at
   **2026-09-18T22:34:52Z UTC**: `serde` → **404**, `clap` → **404**,
   `tokio` → **200**, `git2` → **200**. The site serves a package page only for a
   crate carrying at least one advisory, so 404 means no advisory on record, not
   status unknown. The report's reading — "the required RustSec URL returned a
   page-not-found response, so open-advisory status was not independently
   verified" (`raw/codex.md:52`, and the same for the other two) — is the error
   the decision says it is. Three of the four controls are executable checks
   (`L1-serde`, `L1-tokio`, `L1-git2`); the fourth is JF-1 below.
3. **The `shadow-rs` exclusion, read at source.** I read the manifest rather than
   relying on the report or the snapshot alone.
   `GET https://crates.io/api/v1/crates/shadow-rs/2.0.0/dependencies`, retrieved
   **2026-09-18T22:35:33Z UTC**, gives `git2` with `req` `^0.20.0`, `kind`
   `normal`, `optional: true`; and the version's feature map in
   `snapshots/crates-shadow-rs-versions.json` gives `default = ["git2","build"]`,
   so the default tree does pull it. Licence is `MIT AND Apache-2.0` in the same
   snapshot, as the decision records against the report's `MIT`. I read both
   advisories at source — `https://rustsec.org/advisories/RUSTSEC-2026-0183.html`
   and `-0184.html`, retrieved **2026-09-18T22:36:29Z UTC** — and both name
   **Package: git2** with **Patched: >=0.21.0**, which is what makes issue #262's
   premise true rather than stale: a `^0.20.0` pin cannot reach the patch. The
   snapshot of the issue (`snapshots/gh-shadow-rs-issue-262.json`) is `state:
   open`, created 2026-08-05, titled exactly as the decision quotes it. The
   verdict is unchanged from the report's and the attribution is now correct: a
   failure of the tree, not of the crate, and the decision says which.
4. **The four citation repairs.** I opened each at the pinned commit from
   `raw.githubusercontent.com` rather than trusting the committed snapshots, then
   hashed both. **All four snapshots are byte-identical to upstream.** Apache
   Arrow at `d506e145f42169e9c188b627f341da499bf09859`: `arrow/src/lib.rs` is
   **440 lines**, and its single `CARGO_PKG_VERSION` is at **`:412`**
   (`pub const ARROW_VERSION: &str = env!("CARGO_PKG_VERSION");`) — the report's
   `L1822-L1824` (`raw/codex.md:8`, `:44`) is past the end of the file. rav1e at
   `31435de9d76fddd38f6dcc31d4014574cebb2092`: `src/lib.rs:216` is
   `env!("CARGO_PKG_VERSION").to_string()` and `:54` is
   `include!(concat!(env!("OUT_DIR"), "/built.rs"));`; neither of the report's
   `L937-L943` nor `L1223-L1233` contains the variable. OpenTelemetry at
   `1d663f8331f404278565930a4f6ed51404c81cd0`: `opentelemetry-sdk/src/lib.rs`
   exports no version constant, and the only occurrence in
   `opentelemetry-zipkin/src/lib.rs` is `:203`, whose line begins `//!` — a
   doc-comment example, so dropping it as practice evidence is right. The Cargo
   Book: the report's sentence "Cargo's build-script guidance says runtime
   checking of Cargo-provided variables is discouraged" (`raw/codex.md:28`) is
   not on the page; the page's only "discouraged" is about dynamic-library search
   paths, which I confirmed in the excerpt at `:13`, and the rejection of
   architectures C and D rests instead on what the page does say plus C4b.

**Practice evidence is at pinned commits and the repository figures match.**
`snapshots/gh-repo-apache-arrow-rs.json` gives 3613 stars, `archived: false`,
`pushed_at: 2026-09-18T19:33:43Z`; `gh-repo-xiph-rav1e.json` gives 4151,
`archived: false`, `2026-09-18T05:48:23Z`. Both match the decision's text. rav1e
is the stronger citation of the two and the decision says why: it ships the base
version from Cargo and git provenance from a generated module gated behind its
own feature, which is exactly the layering this decision recommends between R22
and R60.

**Nothing rests on the report alone, and the `## Engines` section says so
honestly.** It names the engine (Codex CLI 0.154.0, `gpt-5.6-luna`), states that
this is the only report in the run, and states that the Terra evidence check is
**deferred** under W1-CODEX3 with the reason — the Codex account at its usage
limit — so the report "reached this synthesis unchecked" and was treated as a leg
to verify, not a source to rely on. `docs/planning/p02/execution-ledger.md:1028`
records the same. The verification is the 75-check `r22-sources.sh`, which I
re-ran. Six carried-but-unverified claims are named with why each is
non-load-bearing, and five things are left for P03 to prove. The one I checked
for load-bearing status — the default-feature lists, which the decision says were
not re-read — turns out not to matter for the `shadow-rs` exclusion, exactly as
the decision argues, because I established the default set from crates.io
independently above.

**The programme rule is respected.** Nothing was built. The probes are throwaway
packages under `$TMPDIR` created with `cargo new --vcs none` and removed by an
`EXIT` trap; AC1–AC6 are proposed checks for P03, each labelled proposed and each
mapped to the check id that proved its underlying mechanism. The decision is not
faulted for declining to implement itself, and it does not.

## Completeness

**The three scripts reproduce, and the counts are stated within what the logs
show.** I re-ran all three in place from
`review/evidence`, writing output to a scratch directory:

| Row | Script | My rerun | Diff against the committed log |
|---|---|---|---|
| E1 | `r22-cargo-probe.sh` | exit 0, `CHECKS RUN: 24  PASS: 24  FAIL: 0  SKIP: 0` | identical with `run-started-utc:` filtered |
| E2 | `r22-sources.sh` | exit 0, `CHECKS RUN: 75  PASS: 75  FAIL: 0  SKIP: 0` | identical with `run-started-utc:` filtered |
| E3 | `r22-live-recheck.sh` | exit 0, `CHECKS RUN: 10  PASS: 10  FAIL: 0  SKIP: 0` | every `PASS`/`FAIL` line identical; the `DRIFT` counters and the timestamp are unchanged today too |

24 + 75 + 10 = 109, no failures and no skips, so the decision's "there is no skip
to name" is accurate. I then extracted `git archive` at the commit the decision
names — `582358ae634bf6affd7a9b4b088067759c444c33` — into the scratch directory
(the extraction has no `.git`, neither directory nor file) and re-ran both
deterministic scripts there. `r22-cargo-probe.sh` was **byte-identical**.
`r22-sources.sh` differed on **exactly one line**, and it is `A0b`:

```
6c6
< PASS A0b -- reading a worktree whose .git is a FILE (tested with -e, not -d)
---
> PASS A0b -- reading an extraction with no .git at all (git archive); every path below is tracked content
```

That is precisely what E4 claims. `582358a` is an ancestor of `79c6512`, the
commit that carries `r22-archive-rerun.log`, so the log could only have been
committed after the tree it reads — as the decision says. No committed log
contains an absolute path, which is what makes the two runs diffable rather than
merely comparable.

**No check is uncountable or unfalsifiable.** Each script sets `set -euo
pipefail` on its first executable line, counts `PASS`/`FAIL`/`SKIP`, prints their
sum and exits non-zero on any failure; every check asserts on content — a version
string, a numbered line of source, a JSON field, an HTTP status against controls
in both directions, or a non-zero exit paired with the text explaining it. The
falsifiability claims are themselves testable: C9's control pair isolates the
leading `v` as the cause of Cargo's rejection, and C8 shows that setting the
variable in the running process changes nothing.

**The five `- assumes` lines are byte-identical to the registry.** I extracted
each value from `docs/port/PARAMETERS.md` programmatically and compared
character-for-character rather than by eye, including the 1,818-character
`build-tool-output-shape` line: `msrv-policy` (118 chars), `rust-edition` (4),
`target-os-matrix` (27), `license` (17) and `build-tool-output-shape` (1818) all
match exactly. There is no `- owns` line, which is right — `inputs/prompt.md`
`## Couplings` reads `owns:` with nothing after it — and no `CONFLICT:` line,
which is also right. Dropping the report's `assumes web-extra-surface` line
(`raw/codex.md:86`) is correct: R22 does not consume that parameter, so a
byte-comparison validator would be checking a line this item has no standing to
write. The decision says so and explains R69's and R60's relationship as related
but unregistered.

**The H2 set is right and the shape note is verifiable.** The document carries
exactly four H2 sections — `## Decision`, `## Parameters`, `## Empirical check`,
`## Engines` — one H3, `### Principles and implementation`, no `## Supersedes`
(correct for a first revision) and one `re-verify:` line. I ran the validator the
decision cites: `validate_answer_text` from `scripts/research_validation.py`
returns `[]` for `raw/codex.md` and returns the same H3-ordering diagnostic for
this decision, for R10's and for R44's accepted decision. The decision's note on
shape is therefore exactly true rather than a convenient excuse.

**Proportion fits a light item.** At 748 lines this decision sits beside the
accepted light decisions it should be compared with — R44 at 679 and R10 at 735.
It is not padded: the length is carried by the four luna corrections, the
gate-by-gate candidate table and the 109-check evidence narrative, all of which
the deferred evidence check makes necessary rather than optional.

**Gates and dates.** All six fitness gates are answered per candidate before
popularity, with gate 1 `inapplicable` and its owner reason, gate 4 and gate 6
answered qualitatively with the measurement gap named, and the rejected crates'
`unsafe` posture and per-OS CI explicitly not read and named under `## Engines`
rather than omitted. Every crate figure traces to `snapshots/MANIFEST.txt`, which
records each file's endpoint and UTC retrieval date, and the 25 snapshot files
verify against `snapshots/SHA256SUMS.txt`. Two figure classes are the exceptions,
at JF-1 and JF-2.

## Findings

Three findings, **all non-blocking**. None is an unresolved finding in the
acceptance sense, and the recommendation does not move under any of them.

**JF-1 (non-blocking) — one control figure is asserted outside what the run's
evidence shows.** `## Engines` correction 2 writes that establishing the 404
inference "took controls in both directions, run live on **2026-09-18 UTC**:
`serde` → 404 and `clap` → 404 … `tokio` → 200 and `git2` → 200", and its next
sentence names the controls as "checks `L1-serde`, `L1-tokio` and `L1-git2` in
`r22-live-recheck.sh`". `clap` is not among them. The script's six
`check_rustsec` calls are `serde`, `tokio`, `git2`, `built`, `vergen-gix`,
`shadow-rs`; `clap` appears nowhere in `r22-live-recheck.log`, nowhere in
`r22-sources.log`, and in `snapshots/MANIFEST.txt` only as the three clap-source
rows. So the `clap → 404` figure is the one number in the document that no
committed log or snapshot backs. *It is true* — I read
`https://rustsec.org/packages/clap.html` at 2026-09-18T22:34:52Z UTC and got
**404** — and it carries a date, with its endpoint given by the URL template
three sentences earlier. *What resolves it:* add a
`check_rustsec clap 404 "negative control"` line to `r22-live-recheck.sh`, or
drop `clap` from the sentence. *Why non-blocking:* the inference needs one
negative control and one positive control, and `L1-serde` and `L1-tokio` supply
both as executable checks; `clap` is a redundant fourth reading, and I verified
it independently in any case.

**JF-2 (non-blocking) — two required figure rows are omitted rather than marked
`inapplicable`.** The prompt's `## Required evidence` table requires, per
candidate, `Open issues | GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open | total_count (never open_issues_count)`
and `Adopters | reverse-dependencies page + the projects' Cargo.toml`. The
decision reports neither for `built`, `vergen-gix` or `shadow-rs`: no open-issue
total appears anywhere in the document, and no reverse-dependency adopter is
named for any of the three. The tier guidance is explicit that a figure
inapplicable to the item kind must be stated as `inapplicable` with its reason
and "not omit[ted] silently", and the decision does exactly that for the selected
mechanism's crate figures and for gate 1 — so the standard it applies elsewhere
is not applied to these two rows. It is not a case of the figures being carried
unverified either: the "claims carried without independent verification" block
names issue-responsiveness medians but not open-issue totals, and names no
adopter gap at all. *What resolves it:* one sentence per row stating
`inapplicable` with the reason the decision already has — a `pattern` item whose
recommendation is a language macro, with all three crate candidates rejected on a
gate or on fit that neither figure can move — or the two figures for the three
crates. *Why non-blocking:* both figures are popularity and adoption signals, and
the prompt orders that gates be answered "**before** popularity is weighed"; all
three crates are already out on gate 3 (`shadow-rs`), on R49's consumed
no-`build.rs` clause plus fit (`built`), or on scope (`vergen-gix`), none of which
an issue count or an adopter list could reopen.

**JF-3 (non-blocking) — the CLI Design Standard's R4.6 is rendered as a flat
requirement, losing its tier and its scope.** The decision writes that "R4.6
requires the version value to be 'SemVer without a leading `v`'" and lists it as
essential behavior 4. Reading the blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7` directly: R4.6 is headed
"**R4.6 — Version output format. (SHOULD)**", and its `MUST` clause is
conditional — "*If JSON version output is supported*, it **SHOULD** emit an
object such as … ; `version` **MUST** be SemVer without a leading `v`". So the
`MUST` governs the `version` field of an optional JSON object, not the plain
`--version` line, and the rule as a whole is a `SHOULD`. R60's own decision
carries the tier correctly at its P3 row ("R4.6 `(SHOULD)` output shape"). The
committed excerpt in `snapshots/cli-design-standard-v1.4.14-excerpt.md` quotes
both the heading and the conditional in full, so the evidence is right and only
the prose reading is loose. *What resolves it:* say "R4.6 `(SHOULD)`, whose JSON
`version` field **MUST** be SemVer without a leading `v`". *Why non-blocking:*
the condition is satisfied in this template — R60 has already decided a JSON
version object that serializes `{"version","target","rustc"}` sourcing `version`
from `CARGO_PKG_VERSION` — and the conformance argument does not depend on the
tier anyway, because C9a–C9c show Cargo refusing to parse a manifest whose
`version` carries a leading `v`, so the value cannot acquire one under either
reading.

## Assessment

The recommendation follows from the evidence as written. One public compile-time
constant, `pub const VERSION: &str = env!("CARGO_PKG_VERSION")` in the library
crate at `src/lib.rs`, read by the CLI, diagnostics and the optional web surface,
with no accessor crate, no `build.rs`, no generated module and no runtime
metadata lookup, is what the comparison of architectures A through D selects: D
is structurally unavailable in Rust, C is rejected on an invented convention and
a failure mode with no correct answer plus the measurement at C4b, B is a variant
of A independently forbidden for this package's targets by R49's consumed
`build-tool-output-shape`, and A costs nothing. The placement in the library
rather than in the CLI crate is decided by scope — the argument that also
disposes of clap — and it is the placement R49's one-`[lib]`-one-`[[bin]]` shape
supports without a workspace-inheritance question.

It settles F064 and leaves F063 and F133 unamended, with F133 now supported by
measured failure modes rather than by argument, and it correctly declines to
re-raise a baseline finding the 2026-09-04 review already rejected. The five
assumed parameters are byte-identical to the live registry, there is no owned
parameter and none is needed, and there is no conflict to declare. The 109
checks run, reproduce in place and reproduce from a clean `git archive`
extraction with the single expected `A0b` difference, and every count the
decision states is a count the logs actually show. The four luna corrections are
each correct, each re-derived here at a named endpoint with a UTC timestamp, and
each snapshot they rest on is byte-identical to the upstream source at its pinned
commit. The unproven rows are honest and unusually complete: six carried claims
with their load-bearing status, five things left for P03, a named Linux gap, a
named binary-size and compile-time gap, and an out-of-scope tension between R49's
and R60's published values recorded rather than quietly resolved.

The recommendation would not move under JF-1, JF-2 or JF-3. JF-1 removes a
redundant control from a four-way inference that two executable controls already
establish and that I re-ran independently; JF-2 concerns two popularity figures
for three candidates already excluded on grounds those figures cannot reach; JF-3
is a prose reading of a standard whose evidence the decision quotes correctly and
whose conclusion an independent structural measurement already secures. All three
are reporting-precision defects, not evidentiary ones.

Approved.
