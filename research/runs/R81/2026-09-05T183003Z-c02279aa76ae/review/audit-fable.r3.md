decision-sha256: 4647372666b7e94537d75fb684c6ca5ec5cca6929841330bab8832ddb6e7328e
actor: audit-fable-2026-09-05T183003Z-c02279aa76ae-r3
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: J1 the shipped-site attribution duty is recorded only for Font Awesome icon assets, and the decision gives no reason why one `AND`-conjunct in its own table creates a distribution duty while `elasticlunr-rs`'s does not, although check 14 establishes that search ships by default; J2 fitness gate 5 (default features and any async-runtime coupling) has no answer anywhere in the decision, and gates 2, 3, 4 and 6 are answered in substance but never recorded as gate answers, unlike the sibling post-ruling decisions R42 and R67 — gate 5's content is load-bearing because F351 ships `mdbook serve --open` while the decision quotes maintainer guidance to install with `--no-default-features --features search`, which its own quote says disables that server; J3 the medium-confidence fit judgement states its reversal cost but never states what would raise its confidence or what P03 signal would show the call wrong, its bolded "Rust practice splits on exactly that" reaches past the body's own "the one surveyed Rust project", and it does not draw on the seven further verified `book.toml` adopters `opus`'s raw already carries, including `rust-lang/rustup`, a Rust CLI rather than a language book.

## Principle and agreement level

The shared requirement is stated correctly and at the right level. `### Principles
and implementation` names one Markdown file per topic in a purpose-organized tree,
a contributor-maintained navigation index, and exactly one README entry point;
both sources satisfy it and differ only in mechanism (py: MyST + `{toctree}` +
Read the Docs, `py .readthedocs.yaml:44`, `docs/source/conf.py:32`, pin
`b08bccfb`; ts: CommonMark/GFM + bullet indexes, `ts docs/docs.md:1-8`,
`docs/reference/index.md:5`, pin `cb1cbcb2`). The declared level is
**architectural pattern**, which matches `docs/port/BASELINE-REVIEW.md:129` for
F347 — verified: that line records F347's level as `architectural pattern` with
`R81 (mechanics)` as its owner. Five essential behaviors and five observable
acceptance criteria (a)–(e) are stated, with (b) handed to R82 and (e) marked as
review-enforced because it has no executable form. What must agree (the pattern,
F342's category set, F347's existence) is separated from what may vary (generator,
hosting, dialect extensions, preview server), and the decision explicitly declines
to tell py or ts to adopt its answer, giving a per-ecosystem reason for each
(`sphinx.ext.autodoc` has no Rust analogue because docs.rs exists; ts's equivalent
was declined at D-023(6) on maturity).

Both `BASELINE-REVIEW:` lines are handled as the runbook requires: the
`F### — principle — proposed change — evidence` shape is intact, affected items
are named, no other item's rows or verdicts are changed, and F357's placement
question is explicitly *not* decided because F354–F357 are not R81's rows. I
verified the three cited baseline lines: `:133` is the F357 row whose note is
generator-relative, `:134` marks F358 "blocked pending R81", and `:415` records
Astro Starlight as "documented, not shipped" and neither designated nor excluded.
R81 is `open` in `research/CLAUDE.md`, so the absent `## Supersedes` is correct:
nothing published is reversed.

## Design and evidence

**What changed the recommendation.** This is the press point, and the decision
answers it plainly rather than by implication. The revision note (lines 4–22) and
the revision-3 history entry (lines 874–900) separate the two causes: the owner
ruling of 2026-09-12 (Q7.B) struck gate 1, which was revision 2's *tiebreaker* and
which revision 2 had said in terms was "not a fit judgement"; striking it therefore
left the question open rather than answered, and revision 3 answers it on the
merits with evidence that is new in this revision — checks 12 (the corpus measured
at the ts pin), 13 (the practice split), 14 (default search; mermaid) and 15
(Zola's site model). That is the correct disposition of both halves: the ruling is
not made to carry a conclusion it cannot carry, and the new evidence is identified
as new. Both the ruling's effect *and* new evidence are present, and the document
says which is which.

**The fit judgement is argued from principles, not from repository agreement.**
Ground 1 — the generator is a superset because mdBook 0.5 converts `.md`→`.html`
and `README.md`→`index.html` and uses GitHub's own `> [!NOTE]` alert syntax
(check 5, against the maintainers' pages) while GitHub's renderer behaves as
claimed (check 6, `POST https://api.github.com/markdown`) — is the load-bearing
one and it is a design argument, correctly contrasted with py's MyST failure mode.
Ground 4 (a build-time binary that enters no `Cargo.toml` and no MSRV surface) is
likewise structural. Ground 3 is explicitly labelled a capability regained rather
than a requirement satisfied. Only ground 2 leans on adoption, and it is the one
that carries the sample problem (finding J3).

**The runner-up is genuinely compared, with its win condition stated.** "No
generator at all" is named as `codex`'s recommendation in full and `opus`'s stated
runner-up, kept available as a one-commit deletion, and — the part that matters —
the condition under which it wins is stated: it "is the correct answer for a flat
handful of root files, which is what the Rust projects that adopt it actually
carry (check 13), and the wrong answer for the six-category nested tree F342
fixes (check 12)". `zola` and `mdbook-mermaid` are re-judged on fit alone with
their licences demoted to recorded facts, which is what the ruling requires;
check 15 supplies Zola's fit reason (`base_url` is the only required variable; zero
occurrences of `SUMMARY` or `chapter`) independently of EUPL-1.2. One sentence in
that comparison overreaches: the no-generator option "gains nothing in return"
(line 256), which contradicts ground 4's own cost list one page earlier — one
`ubuntu-latest` job, a pin `cargo update` cannot see, a fork inheriting the
workflow, and a tool whose issue triage the decision itself measures as weak.

**The empirical check verifies the claims it is cited for.** I re-counted the
committed log: 154 `PASS`, 8 gated `ASSERT ...=True`, 0 `FAIL`, `failed
assertions: 0`, matching the decision's "162 failure-gated checks" arithmetic
(123 + 31 = 154; 154 + 8 = 162). `review/evidence/audit-docs-delivery-model-r3.log`
is byte-identical to `review/evidence/docs-delivery-claims.log`
(`152ddb42429b3b72646cb24bf9fd6d5cd103adb099784a7865630a6fbeb0981c`), so
`review/audit-codex.md`'s isolated rerun is consistent with this decision. The
gate-versus-recorded-output distinction is honest, and the one deliberately
ungated item — upstream Pages state — carries a stated reason that survives
scrutiny: gating it would fail the audit the moment the owner performs the setting
the decision asks for. The claims the checks are cited for match what the log
asserts, including the per-category tallies (3/7/12/2/5/6 = 35 files, 171,225
bytes, 48 under `docs/`) and check 13's per-repository counts.

**Nothing is claimed as proven that the evidence did not show.** The decision
states repeatedly that no book was built, nothing was timed, no differential
rendering comparison was made, and that identical rendering is a design intention
(gap 2). The hosted URL is recorded as derived-not-observed with `has_pages: false`
(gap 6). Declining to implement is correct for P02 and is not faulted here.

## Completeness

Every runbook H2 is present and in order — `## Decision` (carrying
`### Principles and implementation` and a `re-verify:` line with three triggers
and a date), `## Parameters`, `## Empirical check`, `## Engines` — with
`## Supersedes` correctly absent. Both engines are named with their raw filenames
and retrieval dates; four disagreements are recorded with the evidence that
settled each; six unproven entries each carry what would prove them; and "What
P03 must validate" is enumerated.

The four `- assumes` lines are **byte-identical** to the `fixed` rows of
`docs/port/PARAMETERS.md`: I regenerated them from that file with `awk` and
compared against lines 482–485 — identical for `msrv-policy`, `rust-edition`,
`target-os-matrix` and `license`. The empty `owns`/`consumes` claim matches the
prompt's `## Couplings` block and the R81 row in `research/CLAUDE.md` (`owns` = `—`),
so the absent `CONFLICT:` line is correct. The two unregistered couplings (R42's
`package-manager-invocation`, R11's job split) are recorded as constraints rather
than as value changes, which is the right handling.

Source dates are carried on every external fact: 2026-09-10 for the registry,
repository, RustSec, MPL FAQ and maintainer-documentation reads; 2026-09-12 for
the release-asset endpoint; 2026-09-13 for checks 12–15 and the Pages probe. The
figures the decision does not re-collect (downloads, stars, issue counts) are
attributed to their engine with that engine's retrieval date and are explicitly
marked non-load-bearing.

**The fitness gates are where completeness fails.** Gate 1 is recorded
`inapplicable` with the ruling named, which is correct and is not a finding. But
gate 1 is the *only* gate recorded as a gate. Gates 2, 3, 4 and 6 are answered in
substance elsewhere — MSRV in `## Parameters` (`rust_version` 1.88.0 against a
1.96 floor), advisories in check 4, the OS matrix in check 11's six-asset mapping,
cost in "Cost, stated qualitatively and not measured", and the `unsafe` half of
gate 3 in unproven entry 3 — but never as gate answers, and **gate 5 has no answer
anywhere**. The decision itself argues (lines 167–177) that the prompt's
record-every-gate directive binds it, so this is its own standard. The sibling
decisions resolved after the same ruling carry the block R81 lacks: R42's
`## Decision` has "**Fitness gates, answered for the recommended stack.**" with
gates 2–6 each named including "Gate 5 (default features, async …)", and R67 has
"Fitness gates, answered per selected crate" with the same coverage.

## Findings

**J1 — the shipped-site attribution duty is scoped to icons, and the asymmetry in
its own table is unexplained.** The owner's ruling strikes licence-compatibility
evaluation but explicitly preserves an attribution notice owed on shipped content,
and the decision correctly keeps the Font Awesome duty on that basis (lines 31–32,
234–244, gap 4). The problem is its scope. The decision's own conjunction table
(line 215) lists `elasticlunr-rs` 3.1.0 as `(MIT OR Apache-2.0) AND MIT` — a
trailing conjunct in the same shape as `font-awesome-as-a-crate`'s `CC-BY-4.0 AND
MIT` — and disposes of it under "three combine only notice-retention terms …
which `MIT OR Apache-2.0` redistribution already does" (lines 225–228). That
reasoning is about *this repository's source* redistribution. It does not reach the
built site, and check 14 establishes that the built site ships a search runtime by
default (`[output.html.search] enable`, "on by default"). The decision states no
reason why one conjunct in that table creates a duty on shipped content while the
other is source-redistribution only, and it nowhere asks whether the default theme
emits any other third-party asset — fonts, stylesheets or JavaScript — whose notice
travels with the published site. Gap 4's remedy (inspect `book/` after a P03
`mdbook build`) is mechanically broad enough, but its wording scopes a P03
implementer to icon assets. **What resolves it:** widen gap 4 and the retained
finding from "the CC-BY-4.0 Font Awesome assets" to every third-party asset the
default theme and default search emit into `book/`, and state the rule that
separates a source-redistribution notice from a shipped-content notice. I did not
verify which assets the theme emits and this audit asserts none; that is precisely
what the decision leaves unasked.

**J2 — fitness gate 5 is unanswered, and gates 2, 3, 4 and 6 are not recorded as
gates.** Detailed under `## Completeness`. Gate 5's content is not clerical here.
F351 ships `just docs-dev` running `mdbook serve --open`, and the same decision
quotes mdBook's CI guidance recommending a source install with
`--no-default-features --features search` because that "Disables features like the
HTTP server used by `mdbook serve`" (lines 450–453, check 5). Those two statements
are not contradictory — the primary acquisition path is the prebuilt archive — but
their relationship is **unstated**, and stating it is exactly gate 5's job: what
mdBook's default feature set is, which acquisition path CI takes versus a local
contributor, and whether any async-runtime coupling follows for R05 or R69.
**What resolves it:** a gates block in the shape R42 and R67 use, answering 2–6 for
the recommended tool and keeping gate 1's `inapplicable` line as it stands.

**J3 — the one judgement the recommendation turns on carries no path out of medium
confidence.** Credit first: the reversal cost is stated precisely and three times
(four artifacts, one commit, the corpus untouched — lines 75–89, 735, 908), so
"what P03 does if the generator turns out wrong" is answered. The other half is
not. The decision never states what evidence would raise the fit judgement above
medium, nor what signal in P03 would show the call was wrong, although every one of
its six unproven entries carries a "what would prove it" and the whole document's
discipline is built on that pairing. Three things compound it. (i) The practice
ground rests on a re-verified sample of five with **one** repository on the
positive side (check 13: `ripgrep`, `clap`, `serde`, `ratatui` at
`narrative-dir-files=0  book.toml=0`; `cargo-generate` at `28`/`1`), and the
decision's bolded claim "**Rust practice splits on exactly that**" (line 112)
reaches past its own body sentence "the one surveyed Rust project that faces the
same question" (line 134). (ii) No selection rule is stated for those five, which
is where a one-positive sample is most vulnerable. (iii) The narrowness is
self-imposed: `opus`'s raw already records seven further adopters verified through
`GET /repos/<o>/<r>/contents/<path>` on 2026-09-10 — `rust-lang/book`,
`reference`, `nomicon`, `rust-by-example`, `rustc-dev-guide`, `api-guidelines`
each with `book.toml`, and `rust-lang/rustup` with `doc/user-guide/book.toml`.
`rustup` is a Rust **CLI tool** with a nested narrative tree, not a language book,
so it is a second case of exactly the structure ground 2 turns on, and the decision
does not use it. **What resolves it:** state what would raise the confidence (a
pinned re-verification of `rust-lang/rustup`'s nested guide, or an owner statement
of preference for a hosted site), state the P03 signal that would show the call
wrong, bring the bolded claim down to what five repositories support, and repair
the runner-up sentence "gains nothing in return" (line 256), which contradicts
ground 4's own cost list.

## Assessment

**The recommendation follows from the evidence, and none of these findings
challenges it.** The chain holds: the ruling struck a tiebreaker that revision 2
had declared was not a fit judgement, which left the question open rather than
answered; revision 3 gathered new evidence and answered it; checks 5 and 6
establish that mdBook 0.5 costs the raw-source reader nothing, which is the ground
that carries the most weight and does not depend on the practice sample; check 12
measures the six-category corpus the owner already fixed; check 14 shows the
capability a bullet list cannot supply. Shipping the generator at medium
confidence, with a one-commit reversal, is a defensible design call on that record,
and the decision is careful to mark it as the one call no source states for it.

The findings are about what the decision fails to record *around* that call. J1 and
J2 are omissions with named remedies; J3 asks for the second half of a confidence
statement the document supplies everywhere else. All three are prose repairs
against evidence already in hand — J3's third limb only needs a citation `opus`'s
raw already carries — so revision 4 is an editing pass, not re-research, and no
finding requires the empirical script to change. `review/audit-codex.md`'s
isolated rerun is consistent with this decision and I reproduce its counts and log
hash; it notes the asymmetric sample and judges the decision to state that limit.
I judge the limit stated in the body but overstated in the bolded claim, and the
missing half of the confidence statement to be a gap the document's own standard
forbids. Because the role contract admits `approve` only with no unresolved
findings, the verdict is reject.
