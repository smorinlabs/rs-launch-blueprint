decision-sha256: ebcbe236064e05558895d2acc2ee5f6b7f9a6c712f6527c76c9fb92fdeecbf51
actor: audit-fable-2026-09-05T183003Z-c02279aa76ae-r4
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: J4 the disclosed failure of `review/evidence/docs-delivery-claims.sh` names the wrong assertion — the decision attributes check 16's `FAIL` to the whole-file hunk-count tripwire, but that assertion still passes (`ASSERT hunk_count_is_17=True`) and the failing one is check 16's byte-identical-region assertion for unproven entry 3, whose end anchor `4. **Whether mdBook` no longer matches because revision 4 rewrote unproven entry 4's opener; `review/audit-codex.md` states the correct mechanism and the decision contradicts it, and the decision does not record that check 17 re-anchors that same region on `4. **Wh` in order to keep asserting it.

## Principle and agreement level

Unchanged from revision 3 and re-confirmed, not re-argued. The shared requirement
— one Markdown file per topic in a purpose-organized tree, a
contributor-maintained navigation index, exactly one README entry point — is
stated at **architectural pattern** level, which is what
`docs/port/BASELINE-REVIEW.md:129` records for F347. Both pinned sources satisfy
it and differ only in mechanism (py: MyST + `{toctree}` + Read the Docs, pin
`b08bccfb`; ts: CommonMark/GFM + bullet indexes, pin `cb1cbcb2`). What must agree
is separated from what may vary, and neither py nor ts is told to adopt this
answer, each with its own reason. Check 17 asserts the whole
shared-requirement-through-what-may-vary block byte-identical to revision 3, and
that assertion passes in my isolated rerun.

Both `BASELINE-REVIEW:` lines keep the required
`F### — principle — proposed change — evidence` shape, name their affected items,
and change no other item's verdict; F357's placement question is explicitly left
to the reconciliation because F354–F357 are not R81's rows. R81 is `open` in
`research/CLAUDE.md`, so the absent `## Supersedes` remains correct.

## Design and evidence

**Press 1 — the shipped-site notice rule is right, and it resolves the
`elasticlunr-rs` asymmetry rather than restating it.** The rule (lines 456–485) is
that a licence expression is owed against an *act of redistribution*, and this
template performs two: publishing this repository, and publishing `book/` to
Pages. The 218-package walk answers only the first. The sharp part is the reason
it cannot answer the second even in principle — "a crate's declared licence
expression is not a list of the third-party files that crate vendors" — which is
correct and is what makes the widening a rule rather than a caveat.

It resolves the asymmetry because it dissolves it. Revision 3 treated
`font-awesome-as-a-crate`'s conjunct as creating a shipped-content duty and
disposed of `elasticlunr-rs`'s under source redistribution. Revision 4 routes
**both** to gap 4: `elasticlunr-rs` is named explicitly against check 14's
default-on search, gap 4 is widened from the Font Awesome icons to "every
third-party file the default theme and the default search runtime write into
`book/` … whether or not the crate it came from appears in the 218-package walk",
and check 18 reads both package versions (`font-awesome-as-a-crate` 0.3.1,
`elasticlunr-rs` 3.1.0) from the committed lock. The preserved revision-2 sentence
that disposed of the three notice-only conjunctions is not contradicted, because
the new text scopes it ("answers only the first act") instead of overwriting it.
The decision asserts no asset list, which is the honest position for a run that
built nothing.

*Observation, not a finding.* Every MPL-2.0 sentence in the decision is about act
1 — mdBook is never linked (lines 398–408), and the `theme/` rule forbids copying
MPL files into the source tree (551–563). The notice most likely to be actually
owed on a published `book/` is mdBook's own default-theme CSS and JavaScript,
which is MPL-2.0 and is named nowhere as a candidate although Font Awesome and
`elasticlunr-rs` are. The rule covers it generically ("from whichever upstream
they came"; "whether or not the crate it came from appears in the walk"), and
naming it as an emitted file would be asserting the asset list the decision
correctly declines to assert, so this is a one-sentence improvement rather than an
unresolved gap.

**Press 2 — gate 5's install-line question is resolved, and "serve survives either
way" is established by reading R42's recipe bodies.** I read them. R42's current
unpublished revision gives `install-tool <spec>` the body
`cargo binstall --locked --no-confirm <name>@<version>`
(`research/runs/R42/2026-09-05T155503Z-4141a35b69e0/review/DECISION.md:27`); its
published revision 6 gives it `cargo install --locked <name>@<version>` (`:1788`).
Neither passes a feature flag, exactly as the decision states, and R81 defines no
install recipe of its own — acquisition is R42's. So the question is genuinely
answered rather than deferred: **this template's install line is R42's generic
recipe with no feature flag**, `--no-default-features --features search` is not it,
and adding it would delete the server F351 ships. The CI half is disposed of
correctly too: the docs job never serves, so either acquisition path is available
to it and the choice has no consequence for F351.

The async half is answered and bounded: `tokio` 1.53.1, `axum` 0.8.9 and
`tokio-tungstenite` 0.29.0 are read from the committed lock by check 18 and stay
inside mdBook's own process, so **R05 and R69 are unconstrained** and no
`CONFLICT:` line follows. The gate block now matches the shape R42 (`:779`,
"Fitness gates, answered for the recommended stack") and R67 (`:490`, "Fitness
gates, answered per selected crate") use, with all six recorded and gate 1's
`inapplicable` line kept verbatim. J2 is resolved.

*Observation, not a finding.* "Neither body passes a feature flag, **so** both take
mdBook's default features" does not follow on the `cargo binstall` path: a
prebuilt archive's feature set was fixed by whoever built it upstream, and the
installer passing no flag is irrelevant to that. The conclusion is probably right
and the decision does not rest on it — unproven entry 7 names both candidate
bodies, "the prebuilt artifact and the `cargo install --locked` fallback", and
says the claim "is an inference about the default feature set, not an observation
of a binary". The substance is recorded; only the connective is loose.

**Press 3 — the confidence statement is now honest about the sample.** The bolded
claim is narrowed to "the five Rust projects surveyed here split on exactly that
structure — four flat, one nested", and the scope is stated once in full, in the
same paragraph, including the limb my predecessor asked for and did not expect:
"chosen as widely used Rust CLI and library projects rather than by a stated
sampling rule, which is the limit this ground carries. It is not a measurement of
Rust practice at large." `## Engines` disagreement 1 and `## Uncertainty` repeat
the same scope rather than a stronger one.

The seven carried adopters are handled correctly. I verified them in
`raw/opus-a80f5625….md:48-56` — the six `rust-lang` documentation repositories each
with `book.toml`, and `rust-lang/rustup` with `doc/user-guide/book.toml` — read
through `GET /repos/<o>/<r>/contents/<path>` on 2026-09-10, which is the endpoint
and date the decision cites. They are marked as carried and not re-verified, held
out of check 13, and, crucially, **not used to raise the confidence**: six are
explicitly discounted as book-shaped rather than CLI-shaped, and the decision names
a *pinned* re-verification of `rustup` as the cheapest thing that would raise the
judgement. "What would raise this above medium, and what would show it wrong"
supplies both halves — two raisers (a pinned `rustup` walk; an owner statement
about a public documentation URL, correctly identified as an owner input no source
can supply) and three P03 falsifiers in arrival order. The runner-up's "gains
nothing in return" is gone, replaced at both sites (lines 496–502 and 636–644) by
ground 4's own cost list.

*Observation, not a finding.* `opus`'s practice table is sixteen rows, not eight:
alongside the adopters it records `sharkdp/bat`, `tokio-rs/tokio`, `astral-sh/uv`,
`rust-github/template` and `ratatui/templates` on the negative side, and `opus`'s
own reading is that "the head-count of Rust CLI repositories favors README-only".
"`opus` already recorded more of it" imports only the positive half and does not
say the table has another half. I do not elevate this: none of the omitted rows
presents a six-category in-repo tree navigated without a generator (`bat`'s loose
`doc/` folder is the closest, and `uv` adopted a generator — MkDocs Material —
which the decision's Python-toolchain exclusion already covers), and the seven are
not load-bearing for the confidence level. One sentence acknowledging the table's
other side would close it.

**Press 5 — everything cleared before, re-confirmed.** Corpus figures: check 12's
`six F342 categories: total bytes 171225` at `docs-delivery-claims.log:207`, with
35 `.md` files across the six categories at the ts pin, unchanged. The four
`- assumes` lines are **byte-identical** to `docs/port/PARAMETERS.md`'s `fixed`
rows — I regenerated them with `awk` and compared, and all four match, `license =
MIT OR Apache-2.0` included. The runner-up comparison still names "no generator at
all" as `codex`'s full recommendation and `opus`'s stated runner-up, keeps it as a
one-commit deletion, and now states both sides of the trade. `audit-codex.md`'s
rerun is consistent: I reproduced its exact artifact,
`2ca46e1812beb805e89c52db8e5d1b89c8fac1fdb23c9e3549b1948be1a75c4a`, byte-identical
to `review/evidence/docs-delivery-claims-r4.log`, and revision 3's log still
matches its auditor's copy at `152ddb42429b3b72646cb24bf9fd6d5cd103adb099784a7865630a6fbeb0981c`.

## Completeness

Every runbook H2 is present and in order, `## Supersedes` correctly absent. The
gate block closes the one structural hole revision 3 had. Source dates are carried
on every external fact, and the figures the run does not re-collect are attributed
to their engine with that engine's date and marked non-load-bearing. The unproven
list grows to seven with the gate-5 entry, each carrying what would prove it, and
"What P03 must validate" now names gaps 1, 2, 4, 6 and 7.

**Press 4 — a check that fails by construction, disclosed and superseded, is
acceptable as history; the decision should not have retired it.** Retiring
`docs-delivery-claims.sh` would destroy the thing that makes it evidence: two
prior audits reproduced it byte-for-byte, and check 18 asserts its sha256 (and its
log's) unchanged. Editing it to pass would be the worse move, because a tripwire
that is adjusted whenever it fires is not a tripwire. Adding a **new** script whose
checks 17 and 18 are offline, deterministic, and write nothing inside
`review/evidence/` — using a `mktemp` directory removed on exit — is the right
handling, and I confirmed the design works: my clone was left with a clean working
tree after the r4 script ran. The contrast is instructive. The **old** script's
`curl` steps rewrote three files under `review/evidence/snapshots/` in my isolated
clone (`github-creating-diagrams.html`, `mpl-2.0-faq.html`,
`n_github-diagrams.txt`) without moving a single assertion — which both confirms
the assertions' robustness against upstream byte drift and shows exactly why the
r4 script's `mktemp` design matters. Nothing in the real repository was written;
all of this ran in a throwaway clone.

What is not acceptable is the *content* of the disclosure, which is finding J4.

## Findings

**J4 — the disclosed failure names the wrong assertion, and the decision's own
empirical audit says so.** Lines 924–930 state that check 16 "gates the whole-file
hunk count at exactly 17, a tripwire revision 3 installed so that 'a later stray
edit cannot slip in as an unremarked change'. Revision 4's edits are exactly such a
change — an intended one — **so** a rerun of `docs-delivery-claims.sh` now reports
`FAIL` in check 16 and exits 1." The causal clause is false.

In an isolated clone of this repository at `research/p02-execution`, I ran
`bash review/evidence/docs-delivery-claims.sh`. It exits 1 as disclosed, with 152
`PASS` and 2 `FAIL`, and checks 1–15 are unaffected as disclosed. But the
hunk-count gate **passes**: the log carries `ASSERT hunk_count_is_17=True`. The
failing assertion is
`FAIL  region marker not found: unproven entry 3 (unsafe posture)  r2=True r3=False`,
which then sets `FAIL  revision-3 untouched-region diff  expected=0 actual=1`.
The cause is an anchor, not a hunk count: check 16 extracts that region with the
end marker `"4. **Whether mdBook"`
(`review/evidence/docs-delivery-claims.sh:514`), which was revision 3's opener for
unproven entry 4, and revision 4 rewrote that entry to begin "4. **Which
third-party assets a default `mdbook build` emits into `book/`". So revision 4's
intended edit to entry **4** broke check 16's ability to evaluate its preservation
assertion for entry **3**.

Three things make this more than a clerical slip.

*It contradicts the audit it cites.* `review/audit-codex.md` — the approving
empirical audit of this same revision — records the correct mechanism in terms:
"The old script's revision-2 hunk-count assertion still passes at 17; the
changed-region assertion is the direct failure." The decision states the opposite
of its own auditor's reproduced result. The finding is the empirical auditor's
observation before it is mine; I reproduced it independently.

*It understates what broke.* "A hunk count moved" and "a byte-identical-region
assertion could no longer be evaluated" are materially different reports. The
preservation assertions are the mechanism this programme uses to prove a revision
did not touch what it promised not to touch; a reader auditing preservation claims
needs to know that one of the nine such assertions is the casualty, not a
whole-file line-count tripwire.

*The re-anchoring is unrecorded.* The r4 script's version of the same region uses
the deliberately looser end marker `"4. **Wh"`
(`review/evidence/docs-delivery-claims-r4.sh:98`), which is why check 17 can still
assert that region byte-identical to revision 3 — and it does, and it passes. So
the substantive preservation claim is intact and nothing was actually lost. But
the decision says check 17 "carries every region assertion check 16 made", which
conceals that one of them had to be re-anchored to keep passing.

This is the class of defect revision 1 was rejected for and revision 2's F4
repaired: a claim about what the checks assert, stated more confidently than a run
supports, in the paragraph whose entire purpose is to be honest about a failure.
It appears to have been written by construction rather than from a run.

**What resolves it — a two-sentence prose repair, plus the same handling revision 4
gave check 16, done from a run.** The prose repair is small and needs no
re-research. In the "What revision 4 ran" paragraph, (i) name the failing assertion
as check 16's byte-identical-region assertion for unproven entry 3, whose end
anchor `4. **Whether mdBook` no longer matches because revision 4 rewrote unproven
entry 4's opener, and record that the whole-file hunk-count gate still passes at
17; and (ii) record that check 17 re-anchors that region on `4. **Wh` and asserts
it byte-identical to revision 3, which is why the preservation claim survives the
old script's failure. Checks 1–15, `docs-delivery-claims.sh` and both revision-3
logs stay untouched.

**The revision-5 author must not repeat the defect on check 17.** Check 17's own
row (line 959) asserts "the title asserted to name revision 4", so a revision 5 —
whose title necessarily names revision 5 — fails check 17 by construction, exactly
as revision 4 failed check 16, and `hunk_count_is_17` against the revision-3 blob
may move with it. That needs the same treatment revision 4 correctly chose for the
old script: leave `docs-delivery-claims-r4.sh` and its log byte-identical, add a
new script re-targeting the revision-diff mechanism at the revision-4 blob, and
disclose the old one's failure. The one thing to do differently is the thing J4 is
about — **the disclosed failing assertion must be named from an actual run of the
script, not inferred from what the check was designed to gate.**

## Assessment

**The recommendation follows from the evidence, and J4 does not touch it.** The
chain is the one revision 3 established and revision 4 did not disturb: the owner
ruling struck a tiebreaker revision 2 had itself declared was not a fit judgement,
leaving the question open; checks 5 and 6 establish that mdBook 0.5 costs the
raw-source reader nothing, which is the ground carrying most weight and which does
not depend on the practice sample; check 12 measures the six-category corpus the
owner already fixed; check 14 supplies the capability a bullet list cannot. Ship
the generator at medium confidence with a one-commit reversal remains a defensible
design call, and the decision is careful to mark it as the one call no source makes
for it.

All three of revision 3's findings are resolved, and resolved on the merits rather
than by restatement. J1's repair is the strongest of the three: the shipped-site
notice rule is a genuine rule, it dissolves the asymmetry instead of explaining it
away, and "crate metadata is not a file list" is the right reason. J2's gate 5
resolves the install-line question by reading R42's two candidate bodies, which I
verified, and correctly concludes that this item does not depend on which body R42
lands. J3's repair narrows the bolded claim, states the missing selection rule
without being asked to, cites `opus`'s seven adopters with their provenance while
declining to let them raise the confidence, and supplies both halves of the
confidence statement.

J4 is new, narrow, and about the decision's account of its own evidence rather
than about its recommendation. Its prose repair is two sentences against facts
already in hand — one of them already written down in `review/audit-codex.md` — so
no re-research is required and no existing script, log or evidence artifact needs
to change. Revision 5 will, however, trip check 17's title assertion the same way
revision 4 tripped check 16, so it needs a new revision-diff script and a
disclosure of its own; that disclosure is the place to apply J4's lesson rather
than repeat it. Because the role contract admits `approve` only with no unresolved
findings, the verdict is reject.
