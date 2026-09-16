decision-sha256: a2504aa7e3ad210e788e41ef53fbf37505a5254f54fd31955f9d1d2b574f5e1c
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r10
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Unchanged, and provably so. The rev9→rev10 diff
(`git diff dd273a2 HEAD -- review/DECISION.md`) is five hunks: the title line,
the QuickInstall bullet, option 2 of the integrity ask, a revision-history entry
and one `## Supersedes` framing paragraph. Nothing lands in the principle
statement, the agreement level, the essential behaviors, the architecture
comparison, the survey or the acceptance criteria. My round-9 assessment of all
of these stands as written and is not restated here: the principle is at the
spec §2 **architectural pattern plus policy** level, the discover-report-remediate
loop and the invocation vocabulary are separated from the acquisition backend,
and the two `BASELINE-REVIEW:` lines (F181 at `:246`, F179 at `:290`) are
byte-identical to revision 6 and answer what `docs/port/BASELINE-REVIEW.md` asked.
No `CONFLICT:` line is owed; the `- consumes:` list is empty and no registered
parameter value moves.

## Design and evidence

Both round-9 findings are closed exactly, and I read the new sentences against
the logs rather than against the revision's account of them.

**J1 — option 2's cost is now the recorded behaviour.** The word `silently` is
gone from the option; `/usr/bin/grep -n -i 'silent' DECISION.md` returns no hit
in the integrity block. The replacement states that the run does **not** fail,
announces the fall-through at `WARN`/`ERROR` level and compiles from source, and
quotes `WARN The package cargo-shear v1.13.1 will be installed from source (with
cargo)` before the `cargo install` line. The quotation is verbatim against
`evidence/binstall-signing.log:452`, inside the cited range `:446-453`, which
runs from `cargo binstall (7b --only-signed) exit=0` (`:446`) through the
dry-run `cargo install cargo-shear --version 1.13.1 --locked` (`:453`) and
contains the `ERROR Failed to download signature: … 404 Not Found` line at
`:451`. The option closes on this decision's own accurate formulation, that the
flag degrades a tool to revision 6's backend rather than failing the recipe,
which is the same sentence the fail-closed-flag bullet already carried. The cost
sentence is rewrapped, not rewritten, and the three options remain an open ask
in the decision's own text.

**J2 — the 404 is attributed to the spec that has one.** The bullet now says the
asset 404s for `taplo-cli@0.10.0` on both Apple targets, cited to
`evidence/binstall-backend.log:166-167`; those are the file's only two
`QuickInstall` lines and both are `taplo-cli` tarball 404s, one per Apple target.
It then says `cargo-shear@1.13.1`'s asset status is unrecorded, the only 404 for
that spec being the `.sig` under `--only-signed` (`binstall-signing.log:451`),
and that `download_signature` is spawned as its own task — confirmed at
`quickinstall.rs:110-136` as quoted in the log at `:347-373`
(`AutoAbortJoinHandle::spawn`), so reaching it establishes nothing about the
tarball either way. The bullet's conclusion is unchanged and now names what
carries it: `7a-downloaded-from-github`, which requires the literal
`has been downloaded from github.com` (`:436`), a line
`resolution.rs:125-127` (log `:387-389`) would have prefixed with
`third-party source ` had QuickInstall won. I confirmed the check-15 leg
separately — `binstall-backend.log:176-181` resolves `cargo-shear` from
`github.com` with no QuickInstall output at all — so "resolved nothing in either
check" holds, with the asserted leg carrying it and the printed-not-asserted one
agreeing.

**The enumeration the repair rests on reproduces.** Matching `cargo-shear`
against `404 Not Found` or `quickinstall` across `evidence/` returns six lines in
six files today, and
`/usr/bin/grep -r -c 'cargo-shear-1.13.1-aarch64-apple-darwin.tar.gz.sig'`
accounts for all six: every one is the same `.sig` URL. The decision's "four
lines in four files … over all 28 files" is a dated snapshot and was exact at
both revision-10 commits — `git ls-tree` counts 28 evidence files at `6d886f6`
and at `34af975`, 36 at `HEAD`. The two extra hits are the round-10 empirical
audit's own `r10-vs-cited.diff` and `.normalized.diff`, which replay that same
line. No QuickInstall tarball line for `cargo-shear@1.13.1` exists anywhere in
this run, in either direction.

**No other `silent` or `404` claim is inconsistent.** I enumerated both
case-insensitively over the whole file. Outside the `## Supersedes` payload the
`silent` hits are: the alias sweep rows 1 and 14 (`:996`, `:1009`), already
adjudicated `Wrong` and `Holds`, where row 14's "hides" is supported by "with no
diagnostic of any kind"; `silently skipped` at `:781`, `:1241` and `:1338`, about
an omitted gate or an assertion, not about a tool's fall-through; and `parameter
is silent on Cargo aliases` (`:909`), a different subject. The `404` hits outside
the repaired bullet are line references into `binstall-signing.log` (`:137`,
`:818` → `:404`, `:410` = `signing: ABSENT`, verified), the repo-probe HTTP 404 at
`:442`, and RustSec / crates.io `none (404)` cells in checks 7, 13 and 14 and the
survey table. None carries either corrected phrasing.

**The recommendation still follows**, on the grounds round 9 recorded and none of
which moved: the generic-recipe shape rests on the two maintained reference
implementations that provision at all, the affirmative case never depended on the
struck gate 1, the fast path was exercised rather than assumed, and the worst
case is stated as revision 6's recommendation exactly. The decision still does
not implement its own recommendation and is right not to.

## Completeness

- Four required H2s present and in order; `## Supersedes` last, permitted and
  named as such; `re-verify: 2027-03-10` still the final line of `## Decision`
  (`:488`).
- `## Supersedes` payload (`:1770` to end) diffs clean against
  `research/topics/42-dev-toolchain-provisioning/DECISION.md` — **byte-identical**,
  both `ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f`, the
  value the framing paragraph claims.
- Parameters: the owned line and all four `- assumes` lines compared
  programmatically against `docs/port/PARAMETERS.md` (`:7-10`, `:14`) —
  **byte-identical**, all five.
- Acceptance criteria (A)-(E): untouched by the diff, and identical to the
  revision-6 block preserved at `:1919-1936`.
- Fitness gates: all six present and answered. Gate 1 `inapplicable` under the
  2026-09-12 ruling — **settled, not a finding**. Gate 5 `inapplicable`, gate 6
  priced with `Neither path was timed here`.
- Revision scope verified independently of the revision's own account: `6d886f6`
  and `34af975` each touch `review/DECISION.md` and nothing else.
- Consistent with `review/audit-codex.md` (round 10, `gpt-5.6-terra`, approve, no
  findings). It binds the same sha256, replays the 45-assertion first leg to
  45/45 from a clean `git archive`, and reaches the same three structural results
  I reached independently (Supersedes byte-identical, parameters byte-identical,
  commit scope). One difference it discloses is worth recording so nobody reopens
  J1 from it: the rerun did not print the `ERROR Failed to download signature`
  line (`r10-vs-cited.diff:35`), a run-to-run difference in unasserted output. J1
  is unaffected — the decision cites the recorded log, where that line is present
  at `:451`, and the "not silent" claim is carried by `7b-no-signature-present`
  and `7b-falls-through-to-cargo-install`, both of which passed in both runs.

## Findings

None.

**Checked and left, so they are not re-litigated.**

1. **The 2026-09-15 owner acceptance post-dates this text.** `docs/port/OWNER-REVIEW.md:137`
   accepts this exact sha256 and `:93-105` records W0-R42i choosing option 3, so
   the decision still puts the tradeoff as an open ask — `:213` asks the owner to
   "choose 1, 2 or 3, or direct otherwise", and `:1766` says the ruling "is still
   outstanding" — which reads as stale against the ledger. That is expected of a
   2026-09-14 artifact, is settled by the task's terms, and OWNER-REVIEW.md:105
   already directs that "R42's republication revision cites this ruling." Not a
   defect in revision 10.
2. **Option 3 is precise enough for P03 to build from, with one lookup.** It
   names the artifact (the declared tool table, the one F183 exists to keep
   small), the shape (one column), the granularity (per tool) and the value
   (whether its artifact is signed), and the owner ruling adds that the recipe
   body stays unflagged and that the choice is re-put if P03 measures a high
   signed fraction. What option 3 does not say is how a tool's signedness is
   determined — but check 15 records the method it used, reading `signing:` from
   the crate's published `Cargo.toml` fetched from `static.crates.io`
   (`binstall-signing.log:404`, `:410`, `:416`), which is findable from the same
   decision. Whether the column is CI-enforced or documentation-only is a P03
   design choice this research decision correctly declines to make.
3. Round 9 cited the `.sig` 404 as `binstall-signing.log:450`; it is at `:451`,
   and revision 10's second commit (`34af975`, "correct R42 revision 10 log
   citations") is what put the right number in. Revision 10 is correct.

## Assessment

**Approve.** Revision 10 does exactly and only what the round-9 rejection asked,
and the diff proves the scope rather than asserting it: two prose clauses in
`## Decision`, their history, and the framing sentence that records them. J1's
replacement states the behaviour the log records — a run that exits 0, announces
the degradation, and compiles from source — and quotes the warning verbatim from
inside the range it cites. J2's replacement gives the 404 to the spec that has
one, marks the other spec's asset status unrecorded, explains why a spawned
signature fetch proves nothing about the tarball, and re-grounds the bullet's
conclusion on the assertion that was always carrying it. Neither repair required
a check to be rerun, and none was: the fifteen cited logs are byte-identical
across both revision-10 commits, the preserved revision-6 payload still hashes to
the value the framing claims, and the five parameter lines still match the
register byte for byte.

The recommendation follows, unchanged, on grounds that never depended on the
struck licence gate. What the owner accepted on 2026-09-15 is a proposal whose
integrity tradeoff was laid out honestly — a comparison table whose left column
declines to flatter the backend it replaced, three options with their real costs,
and an ask rather than a fait accompli — and whose option 3, now chosen, is
specific enough for P03 to implement with the determination method recoverable
from check 15. Nothing in this revision overclaims what the evidence establishes,
and the parts that remain unproven are still listed with what would prove them.
