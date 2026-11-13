decision-sha256: 013fe4c3fc992d7e3755822cd08fe134cafebf83ecff509000b3a98780e8e7f3
actor: audit-fable-2026-09-05T164358Z-bb73f46c3910-r3
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

This is the first judgment audit R26 has received: revisions 1 and 2 were rejected at
the empirical gate (`review/audit-codex.r1.md`, `review/audit-codex.r2.md`, both verdict
`reject`), so no prior judgment auditor checked the sections revision 3 leaves untouched.
I therefore audited the whole decision, not only the revision-3 delta, and verified every
engine attribution against `raw/codex.md` and `raw/opus.md` myself rather than relying on
the empirical audit's finding that those paragraphs are byte-unchanged since revision 2.

The shared requirement (decision line 26) is stated as an outcome, not a command: *a
publish pipeline must prove, before the irreversible upload, that the artifact contains
exactly the intended files and declares exactly the intended package metadata; the
packaging tool's own silent normalizations are changes requiring assertion, not
trustworthy cleanup.* The agreement level is recorded as **policy plus observable
acceptance criteria** — "Policy or mechanism" is one of the three levels spec §2's table
names, and the level is recorded before alternatives are compared, as §2 requires.

The level is the right one and is argued, not assumed. F039 and F078 are `DIVERGENT`,
origin `ts-only` (`docs/port/COMMONALITY.md:45`, `:84`, both read; the decision's row
citations are exact), so there is no cross-repo mechanism to preserve — only ts's policy.
Binding agreement at command level would have forced a JSON substrate that stable Rust
does not offer (exit 101, log lines 195–198), which is precisely the case §2 contemplates
when it says a language may justify a different architecture while preserving the
principle. The decision does not weaken the requirement on the way down: it names four
essential behaviors, four observable P03 acceptance criteria, and an explicit
must-agree/may-vary split, and the may-vary list (expectation-file format, `diff` versus
set comparison, the pull-request copy, which extra fields the projection pins) contains
nothing load-bearing for the principle. Opus reached the same level independently
(`raw/opus.md:41`); Codex framed it as a "release-integrity capability" shared with
TypeScript with Cargo-specific tooling (`raw/codex.md:3`) — a wording difference, not a
substantive disagreement, and the decision was right not to manufacture one.

Handled as the runbook requires: no `BASELINE-REVIEW:` (decision lines 20 and 55), which
both raws independently support — Codex checked `docs/port/BASELINE-REVIEW.md` and found
no finding naming F039 or F078 (`raw/codex.md:40`), and Opus re-read `py-launch-blueprint`
at pin `b08bccfb` and confirmed the prompt's "py: none for both facts" (`raw/opus.md:386`).
No `CONFLICT:` (decision line 66), consistent with both raws (`raw/codex.md:94`, `:156`,
`:180`; `raw/opus.md:306`) and with R26 owning and consuming nothing.

## Design and evidence

**Architecture before libraries.** The seven-row alternatives table (lines 40–47) compares
architectures, not replacement crates: command-plus-expectation, a snapshot test in the
crate's own suite, post-publish verification, reliance on `cargo package`'s verify build,
the unstable JSON shape, and wrapper tooling. Three rejections are grounded in observed or
pinned facts rather than preference — the verify build is insufficient because fault A
compiled and exited 0; the JSON shape fails the stable-Rust constraint by observation; and
post-publish verification is excluded because `cargo publish` is irreversible. The snapshot
alternative is named a real option and ranked runner-up rather than strawmanned, with a
specific coupling argument (it would bind an integrity gate to whatever R33 selects, and
bulk re-blessing could silently re-record a leak). No crate is adopted, so no popularity
figure is load-bearing, and the decision says exactly that (line 143) — correct, because
Codex's GitHub figures were rate-limited and it declared them unusable
(`raw/codex.md:15`, `:265`), which the decision reports accurately.

**The classifier is a real test, not a tautology — and the strongest evidence is
structural.** Each class's candidate line set is the *complete* set of positions in the
377-line cited log where output of that shape occurs, which I verified independently:
`grep -n -E '^\s*(Packaging|Packaged) '` returns exactly 88, 89, 128, 130, 177, 178, and
C3 is {88,128,177} with C2 {89,130,178}; `grep -n -E '^(---|\+\+\+) /'` returns exactly
113, 114, 134, 135, 157, 158, which is C1 entire; and lines 62/63 are the only adjacent
`src`/`STRAY.txt` pair in the log (the sole other bare `STRAY.txt`, line 247, has no
adjacent `src`). The allow-list is therefore derived from the log's command structure —
three `cargo package` runs, three `diff -u` invocations, one `ls -1` listing — not from
which lines happened to differ. The decisive counter-evidence against post-hoc fitting is
line 178: it is in C2's candidate set even though it rendered `2.5KiB` in all eight
compared logs and never once differed. A rule fitted to observation would have dropped it;
the decision keeps it and argues why (line 93, the coarser unit hides rather than removes
the variance, demonstrated by the archived rerun recording `2.6KiB`).

The class tests themselves are mask-and-compare, not shape-only, for the three classes
that matter: C2 masks `([\d.]+ compressed)` and requires the rest of the line equal, so a
changed `N files` or uncompressed size falls through to unclassified; C3 masks only the
trailing `(/path)`, so a changed package name or version falls through; C4 requires a
reciprocal transposition of exactly `{src, STRAY.txt}` at adjacent indices. Unequal line
counts are reported as `unclassified=1 violations=1` rather than silently tolerated, and
index-by-index comparison makes any insertion produce mass unclassified lines. The
classifier fails closed: if `python3` produced no summary line the `sed` extraction yields
an empty string, which `assert_eq` compares unequal to `0`. Combined with `shape()`
pinning all 22 `PASS` lines byte-identical to the cited log, the rule reduces to: 355
display lines must be byte-identical except at 14 named positions, where only a
masked-equality difference of the named shape is admitted. That is a strong rule.

The two negative controls discriminate on the two axes the rule has. Mutating one `PASS`
line (`"2024"` → `"2023"`) yields `unclassified=1`; placing a C3-shaped difference at line
60 yields `C3-packaging-path lines=60 OUTSIDE-CANDIDATES=60` with `violations=1` — both
reproduced in the archived log at lines 163–176. The decision does not overclaim them: line
89 states exactly what was observed (the classifier reporting a nonzero count on each half)
and then volunteers that the failing *exit path* was never exercised because no real
comparison produced one. That is the right scoping, and a decision that states a limit its
auditor would otherwise have to find is being audited with, not against.

**The recommendation follows from the evidence.** The load-bearing finding is that
`prepare_target_for_publish` warns and returns `Ok(None)`, read at the toolchain's own
commit `797e8a9b` rather than at master, and reproduced: fault A made `cargo package` emit
``warning: ignoring binary `rsguard-serve` …`` and **exit 0**, and the packaged manifest
kept one `[[bin]]` (log lines 124–143, which I read directly). A hazard with no exit-code
signal is exactly what justifies an authoritative target-set diff rather than a stderr grep
alone, and the decision draws that inference and no more — it says the scoped grep's
warning strings "are not a stable interface" and makes the target diff the authoritative
signal. Element 4's dual-license constraint is load-bearing and correctly attributed
(`raw/opus.md:277`). The `--workspace --list` concatenation issue (rust-lang/cargo#13953)
drives the `-p` loop constraint, and is correctly marked as Opus-reported, not triggered here.

**Every engine attribution holds.** I checked each against the raws: Codex's Q2 framing as
documented normalization requiring "a projection equality check with a documented allowlist
of transformations" (`raw/codex.md:28`); Codex executing nothing (`:251`, `:164`
"Planned, not executed"); Codex's placement argument that a pull-request copy "adds
maintenance pressure to every source-file change" (`:30`); the `cargo-package` crate's one
yanked `0.0.0` release with no repository URL (`:11`); Opus's target-pruning finding and its
`src/workspace/parser/mod.rs:3116` citations, which Opus itself labels "master, 2026-09-10"
(`raw/opus.md:49`), so the decision's Disagreement 4 corrects the citation's portability to
the pin without misrepresenting Opus; Opus's `Updating crates.io index` observation and the
unpublished-path-dependency failure (`:73`, `:388`); the `+{"kind":["test"],"name":"it"}`
addition case (`:186`, `:354`); maturin's `["package","--list","--allow-dirty",
"--manifest-path"]` at `src/source_distribution/mod.rs` (`:36`, `:99`); the clap, gitoxide,
ripgrep and serde/tokio adoption facts (`:33`–`:37`); `jq 1.7`/`jq 1.8.2` from
`actions/runner-images` (`:168`, `:183`); and the `cargo-diet` / `cargo-release` exclusions
(`:107`, `:108`). Nothing is attributed to an engine that the engine did not say, and
nothing Opus reported at HEAD is presented as re-read here.

**Disagreements resolved by evidence, not by tribe.** Disagreement 1 went to Opus on the
synthesizer's own pinned-source reading plus reproduction; Disagreement 2 merged Codex's
wider projection and `Cargo.toml.orig` compare into Opus's target-set core; Disagreement 3
went to Codex on placement. I verified the binding reason given for Disagreement 3
independently: `docs/port/PARAMETERS.md:12` lists `ci-job-structure` (R11) as consumed by
"R27 through R32, R35, R37, R39, R40, R71 and R82" — R26 is genuinely absent, so recording
the pull-request copy as hardening rather than binding it is correct, not evasive.

## Completeness

All four required H2s are present and populated: `## Decision` (with recommendation,
settled F039/F078 rows, `### Principles and implementation`, and a `re-verify:` line naming
a date plus six named events), `## Parameters`, `## Empirical check`, `## Engines`.
`## Supersedes` is correctly absent: the runbook reserves it for a reversal with a prior
dated entry preserved, and revisions 1 and 2 were never accepted — both were rejected, and
the revision note supersedes them explicitly while keeping their audits and artifacts.

The four `- assumes` lines (decision lines 61–64) reproduce `docs/port/PARAMETERS.md:7`–`:10`
verbatim, which I checked field by field, and each is given a stated bearing on the decision
rather than listed inertly. R26 owns nothing and consumes nothing; both prompt lines are
empty, and the decision says so.

All six fitness gates are recorded with a reason, none omitted (line 49). Gate 1 (license) is
recorded as adding nothing to the template's licence surface because no dependency is
introduced, which is correct under the owner's 2026-09-12 Q7.B ruling; I raise no finding
about unevaluated dependency licences. Gate 4 (platforms) is the one gate not recorded as
satisfied, and it is recorded honestly as macOS-only with Linux unproven.

Source dates are present throughout and are the right kind: the Cargo source at commit
`797e8a9b` resolved from the binary's own version string, the changelog entries dated
2024-07-25 (1.80) and 2026-03-05 (1.94), the ts and py pins, and HEAD-dated adoption facts
flagged as not re-read. The decision distinguishes checks run from checks proposed
throughout, and its seven-item "Unproven, with what would prove it" list each names a
concrete P03 proof rather than a gesture.

**The empirical rerun is consistent with the decision.** Every figure
`review/audit-codex.md` reports for its rerun matches what the decision states, and I
re-derived each independently rather than inheriting it: the comparison log is 183 lines
with 79 `PASS`, no `FAIL`, and `failed assertions: 0` on its last line; all eight
comparisons report `unclassified=0 violations=0`; the two negative controls report
`unclassified=1` and `violations=1` respectively at log lines 163–176; and
`r26-check.sh` and `packed-artifact-guard.log` still hash to the two values the decision
names at line 5, byte-unchanged from revision 2. The rerun's Linux non-result — the
`ubuntu` VM could not be started — contradicts nothing, because the decision records no
Linux result to contradict and names the Linux half of `target-os-matrix` as P03 work.

**Scope honesty on macOS.** I looked specifically for a claim that generalises past the
host and found none. The blanket statement appears three times at increasing scope — gate 4,
evidence boundary line 128 ("Every result above is macOS arm64. No Linux result exists"),
and unproven item 1, which is phrased over the whole decision ("Every result in this
decision was produced on macOS 26.4 arm64") rather than over one section. The claims most
at risk of quiet generalisation are each tied back: the byte-order listing result cites log
lines 249–250 and the design constraint says "the listing observed here is byte-sorted";
`jq` on the runner images is marked Opus-reported and appears as unproven item 6;
`ubuntu-latest` appears only as a P03 acceptance criterion and as what unproven item 1 asks
for, never as a result. The comparison rule's own precondition requires the same host OS
build, so C4's `ls`-collation mechanism is not claimed to be portable either. The empirical
auditor's inability to start the Linux VM adds no contrary evidence, because the decision
claims no Linux result to contradict.

## Findings

1. **Confirmed — the four difference classes are principled, not fitted to the observed
   output.** Each candidate set is the exhaustive set of positions where that command's
   output occurs in the cited log (verified by independent grep: all three `Packaging`
   lines, all three `Packaged` lines, all six `diff -u` headers, the single adjacent
   `src`/`STRAY.txt` pair). C2 retains line 178 although it never differed in any of the
   eight compared logs — the opposite of post-hoc fitting. C2, C3 and C4 pin everything on
   the line except the named varying substring, so a semantically meaningful change at a
   candidate position falls through to unclassified rather than being absorbed. Not blocking.

2. **Confirmed — the negative controls discriminate on both axes the rule has**, and the
   decision states precisely what they showed and what they did not (the failing exit path
   was never exercised, decision line 89). No overclaim. Not blocking.

3. **Observation — C1's `HDR` regex is looser than C1's stated mechanism.** It accepts any
   `---`/`+++` line with an absolute path and a timestamp at the six candidate positions,
   without requiring that the two headers name the same file; the class's stated mechanism
   is only the `$SCRATCH` path and the mtime. **Not blocking:** an escape would require a
   diff of a *different* file whose body is nonetheless byte-identical, since every body
   line sits outside all four candidate sets, and `shape()` independently pins all 22 `PASS`
   lines byte-identical to the cited log. The decision claims only that the classifier places
   every differing line and leaves nothing over, which is true.

4. **Observation — `r26-crossrun-compare.sh` prints the sha256 of `r26-check.sh` and the
   cited log in phase A but does not assert them**, so the rule's precondition list (line 85)
   does not itself pin the identity of the two inputs it compares. **Not blocking:** the
   decision binds both hashes at lines 5 and 74, and the empirical auditor verified both
   independently and confirmed them byte-unchanged from revision 2.

5. **Observation — element 3, `cargo publish -p <pkg> --dry-run --locked`, is a command
   recommendation that was not executed**, which the runbook's "configuration, command and
   version-pin recommendations must execute" would otherwise reach. **Not blocking:** the
   check's own constraint forbids reaching a publish endpoint, the decision records the
   non-execution in the evidence boundaries and again as unproven item 2 with what would
   prove it (the verify job at P03's first tagged release), and Opus's attempt is reported
   with its actual outcome rather than as a success. Under the programme rule that a claim
   recorded as unproven with its proof named is correct, this stands. I note it rather than
   pass it silently.

6. **Resolved — the accounting the empirical auditor raised does not appear in the
   decision.** The phrase "only seven lines changed" is not in `DECISION.md`; I grepped for
   it. The `DECISION.md` diff from revision 2 is 30 added and 7 removed, and the commit adds
   655 lines (3 + 30 + 183 + 183 + 256), which I confirmed with `git show --numstat`. The
   decision's own wording cannot mislead on this point, because line 5 names the new script
   and both new logs with their sha256s and line 87 describes what the script does; the
   revision note's "unchanged, byte for byte" is scoped explicitly to `r26-check.sh` and
   `packed-artifact-guard.log`, which is exactly true.

7. **Observation — wording only.** The sentence fragment "Two archived scripts and two
   logs." at the end of line 5's inputs list undercounts: `r26-crossrun-compare.rerun.log`
   is a third archived log, and it is cited two sentences later. Nothing load-bearing turns
   on the count, and every artifact is named individually with its hash. Not blocking.

8. **Confirmed — every engine attribution is accurate against the raw reports**, checked
   individually against `raw/codex.md` and `raw/opus.md` because this is the decision's first
   judgment audit and no prior auditor verified them. Both raws' "no `CONFLICT:`" and "no
   `BASELINE-REVIEW:`" statements are as reported, Codex's rate-limit admission is as
   reported, and the four `- assumes` values match `docs/port/PARAMETERS.md` verbatim. Not
   blocking.

## Assessment

Revision 3 answers revision 2's rejection at the right level. Revision 2's defect was not a
missing class but a method error — verifying a rerun rule in the only environment where two
of its four classes cannot appear — and revision 3 names that method error explicitly
(line 91) rather than quietly widening the rule to cover what the auditor found. The
replacement is an executable classifier whose allowed positions are derived from the log's
command structure, whose class tests pin everything on the line except the named varying
substring, and which is exercised against the auditor's own archived rerun log, the log that
refuted its predecessor. It keeps a candidate line that never varied, and it declines to
claim a failure path it did not exercise. That is a rule stated over the evidence rather
than around it.

The decision claims only what its evidence establishes. Every macOS-bound result is fenced
three times over, Linux is named as P03 work rather than assumed from the toolchain's
cross-platform guarantee, and the seven unproven items each name a concrete proof. The
sections revision 3 left untouched — which no judgment auditor had previously read — hold up
under first-time scrutiny: the principle is stated at a level spec §2 names and justifies,
architectures are compared before any library, no popularity figure carries selection weight
because no crate is adopted, and every engine attribution reproduces what the engine
actually wrote. The four findings I record as observations are each resolved in place and
none of them makes a stated claim false. Approve.
