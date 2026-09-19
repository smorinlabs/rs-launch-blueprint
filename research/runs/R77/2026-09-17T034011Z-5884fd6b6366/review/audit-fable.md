decision-sha256: 46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68
actor: audit-fable-2026-09-17T034011Z-5884fd6b6366-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# Judgment audit — R77 web-env-settings, revision 2 (round 1)

I produced none of this item's artifacts. The bound sha256 was recomputed twice with
`shasum -a 256`: once against the working-tree file at the start of this audit, and once
against `git archive d36492b` extracted to a scratch tree, both giving
`46b2a05f40f6a3ea27b5fdef415c50adccd27ade5ed6fa94f83ed933503d7f68`. Revision 1 was never
audited, so this is the first round on this item and the actor carries `-r1`. The
empirical leg is absent under owner ruling `W1-CODEX3`; `## Engines` records that
honestly, which I checked rather than took on trust.

**The working-tree copy of `DECISION.md` advanced to an uncommitted revision 3 while this
audit was running** — a shared worktree with many agents active. This audit is bound to
**revision 2 as committed at `d36492b`**, and every rerun and quotation cited below was
taken either before that change or from the clean `d36492b` extraction. I read and
verified nothing from the dirty file, and I edited no path but this one. Eight findings
are recorded, all non-blocking.

## Principle and agreement level

The principle is stated at the right level and it is the level the evidence supports.
F324 is a `py-only` / `DIVERGENT` row (`docs/port/COMMONALITY.md:328`, confirmed at that
line), so nothing is inherited and no `BASELINE-REVIEW:` adjudication is owed; the
decision says exactly that and I confirmed `docs/port/BASELINE-REVIEW.md` carries no
F324, F330 or F303 row. Agreement is fixed at **architectural pattern and policy**, with
an eight-row must-agree / may-vary table that puts the crate, the spelling of the
derivation and the error wording on the may-vary side. That is the defensible level: the
12-factor argument is language-neutral, and the org CLI Design Standard v1.4.14
independently requires the prefix — `R5.4` is at line **321** of blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`, which I opened, and it reads as quoted,
including the curated-subset `SHOULD` and the "**MUST NOT** auto-expose every flag"
clause.

The ts half is handled structurally rather than by preference: no `web/` or `server/`
path exists at the ts pin, so there is no object to harmonize with, and the decision
reaches `harmonize: no` by argument instead of by inheriting the label. The one half of
py's pattern that does not port — the lazy-load fallback in `web/deps.py` — is correctly
not re-raised here: R69 revision 10 carries `BASELINE-REVIEW: F330` at its line 1007, the
line names R77 as an affected item, and this design satisfies it (no `OnceLock`, no
default-on-read, `AppState` the only path). That is the runbook's handling.

## Design and evidence

**The recommendation follows.** Four architectural shapes (A1–A4) are compared before any
crate is weighed, and A1's rejection rests on an owner-accepted decision (R54 revision 3)
rather than on taste. The library selection is not popularity-driven: it is gate-driven,
and the gate is applied before the download figures are read. I re-ran every evidence
script both in place and from a clean `git archive d36492b` extraction with no `.git`
present, and all four reproduce the counts the decision states exactly —
`figures.sh` **121/0/0**, `sources.sh` **84/0/0**, `probes.sh` **34/0/0**,
`rest-conformance-r2.sh` **91/0/0**, total **330**. The SKIP branches are real, not
assumed: with `HOME` pointed at an empty directory, `rest-conformance-r2.sh` gives
**67/0/1** with group B skipping **by name** for its 24 checks (67 + 24 = 91), and
`sources.sh` gives **47/0/4** naming the CLI-standard blob (9), the py pin (9), the ts pin
(1) and the registry cache (18); 47 + 37 = 84, the in-place total. The arithmetic closes
in both directions.

**The gate-2 exclusions are read from the registry, not asserted.** All five crates said
to declare no `rust-version` — `envy` 0.4.2, `figment` 0.10.19, `envconfig` 0.11.1,
`serde-env` 0.3.0, `envious` 0.3.0 — are asserted as `rust_version: None` against a
committed snapshot **and** a live re-fetch of the immutable per-version field
(`figures.log` lines 10, 20, 30, 35, 40 and 107, 113, 119, 122, 125), with `config`'s
1.85.0 and `confique`'s 1.68.2 as passing controls and the 1.96 floor re-derived from
`channel-rust-stable.toml`. The RustSec method carries its own control: 404 for all eight
crates beside HTTP 200 with `RUSTSEC-` hits for `atty` and `time`, so a site outage cannot
read as "no advisory". The citation of three of those five exclusions is thin — see JF-7 —
but the fact is established.

**The unreproducible baseline is handled honestly.** The raw report states an absolute
stripped baseline of 302,704 B (`raw/opus.md:309`, `:556`, `:895`) and says the first five
build times "are within this machine's noise of each other" (`:318`). The decision
reproduces neither, says so under `## Engines`, and responds structurally rather than
rhetorically: it cites deltas only, and `probes.sh` asserts five *thresholds*
(`> 50000`, `< 50000`, `> 100000` at lines 478–499) and no absolute byte count anywhere. I
grepped for every absolute figure in `probes.sh` and found none. The `figment` build-time
sample is carried as not-a-finding in either direction, which is the right disposition for
one sample on a loaded machine.

**The REST pass is sound rule by rule.** I opened all nineteen passages at the pinned blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` and every one lands at the stated line
(210, 229, 237, 271, 291, 1259, 1271, 1281, 1317, 1323, 1348, 1387, 1397, 1398, 1422,
1435, 1546, 1606, 1686). The eight CONFORM rows are right, and the two forward rules
carry their weight: R1.6's "no environment variable may turn an applicability switch on"
is the correct consequence of a switch state having to be declarable in a static note, and
R7.2's "no knob may flip a resource to `public`" names the cross-user-leak hazard exactly.
The three N/A rows are right for the right reason on R10.1 and R10.6 — §10.1 is scoped by
`async-operations` and §10.3–§10.4 by `webhooks`, both off, and the standard states that
scoping at line 1541, which I read. **Move 1 is correct and is the sharper of the two**:
R9.1 freezes the version marker, a freely settable mount prefix could carry or overwrite
it, and the response — reserve no version variable at all, and make a version-shaped
`RSLBP_WEB_ROOT_PATH` a boot failure — is the minimum that preserves "one uniform
placement". **Move 2's second constraint is right and is R77's to make**: R11.2 is a MUST,
py's `rate_limit: str | None = None` disables limiting by default, and porting it would
ship a template nonconformant out of the box. Its first constraint is not R77's — JF-2.

**`OVERRIDE (OV-04)` is necessary, correctly shaped, and correctly routed.** I searched
R69 revision 10's 5162 lines for `rustls`, `native-tls`, `axum-server`, `tls`,
`certificate` and `plaintext`: **zero hits for every term**. R69 neither raises the
plaintext-listener question nor records a rationale R77 could be inheriting, so under
W2-REST — which binds every web item and says "nothing already accepted is reopened" —
R77 is the first item at which this departure from a MUST can be written down, and `R1.7`
makes silence nonconformance "regardless of the deviation's merits". The note carries all
six fields of the §1.9 shape (rule ID · strength · what differs · why · approver · date),
the `**Argument:**` is grounded in R69's accepted stack and the `target-os-matrix`, and
the three options are genuine with their costs stated: (a) record and keep the loopback
default, (b) in-process TLS — rejected on the credential-coupling, dependency and
ownership grounds, (c) refuse `0.0.0.0` — rejected because R51 owns the Dockerfile. The
withdrawal condition is sound and bidirectional: if R69 adopts an in-process terminator,
OV-04 is withdrawn *and* certificate and key settings come under this naming rule with
`R8.12`'s redaction applied from the first line. It is flagged for the owner in three
places (`approver: pending owner review`, the re-verify line, and `## Engines`). **The
number is right**: the controller's allocation table at
`docs/planning/p02/execution-ledger.md:1073` records the concurrent collision with R80 and
rules that R77 keeps OV-04 as the earlier commit, with R80 renumbered to OV-05 — which
HEAD `53b13f4` is.

## Completeness

Every required field is present and correct. The H2 set is exactly the synthesizer
contract's four — `## Decision`, `## Parameters`, `## Empirical check`, `## Engines` — in
order, with `### Principles and implementation` inside the first, one terminal
`re-verify:` line, and no `## Supersedes`. The six `- assumes` lines are **byte-identical**
to the live `docs/port/PARAMETERS.md` rows: I extracted the registry value column and
compared character-for-character, and `msrv-policy` (118 B), `rust-edition` (4 B),
`target-os-matrix` (27 B), `license` (17 B), `web-extra-surface` (2638 B) and
`error-taxonomy-exit-codes` (4057 B) all match at equal length. `web-extra-surface`
carries revision-9 bytes (`src/web/`, no `crates/web`), which I confirmed is what the
registry still holds, with revision 10's `crates/web` paths explained in prose and booked
as a re-verify trigger — correctly not a `CONFLICT:`. No `- owns` line is present and none
is owed: the prompt's `- owns:` and `- consumes:` lines are both empty. Gate 1 is recorded
`inapplicable` for every candidate against the 2026-09-12 (Q7.B) ruling, which is right.

The unproven rows are honest and complete: `confique` on 1.68.2, Windows, the
`x86_64-unknown-linux-gnu` sizes, the carried issue-responsiveness medians and adoption
rows, the two non-reproduced raw claims, and `pathdiff`'s undeclared `rust-version` under
the third gate reading with its consequence spelled out ("`config` — the ranked runner-up
— falls too"). The weakest-supported value, the 8-second budget, is named as such.

**AC11–AC14 are checkable.** AC12 and AC13 are mechanical (`RSLBP_WEB_ROOT_PATH=/v1` as a
boot failure versus `/api` accepted; a `grep -riE` that must match nothing). AC11's
field-name half is mechanical and its "no value reaches any response" half is checkable by
sentinel values, though the decision does not name that mechanism. AC14 is checkable but
cannot run until R74 publishes, which the decision states.

The raw report is represented accurately: `raw/opus.md` recommends adopting no crate with
`config` runner-up and `confique` third, exactly as `## Engines` says, and contains **zero**
matches for the standard, its blob, `W2-REST` or any of R8.1/R9.1/R11.2 — so the
decision's statement that the whole conformance pass is the synthesizer's own reading, not
engine output, is true and was worth stating.

## Findings

**JF-1 — non-blocking. The frame that decides twelve rows is stated more absolutely than
the standard supports.** The pass opens with "The standard contains the string
'environment variable' **zero** times … No rule in it names a setting, requires one, or
turns on one." The first half is exact — I reproduced the zero count on the extracted
blob. The second half is not: `R3.9` at line **677** reads "Deployments needing keys kept
out of intermediary logs MUST add explicit header-redaction and cache-key-exclusion
configuration" — a MUST that requires deployment configuration, in the idempotency area
whose two variables this item names. (`R12.8` at line 1836, "MUST fail closed on a
missing, empty, or default secret at configuration load", is not a counter-example: §12
binds consumers and this template is a provider.) Non-blocking: R3.9's clause is
conditional on a deployment need this template does not have, the redaction surface is
R70's and R73's, and no disposition moves. A revision should narrow the sentence to the
string finding, or quote R3.9 as a twentieth passage with a forward rule.

**JF-2 — non-blocking. Move 2's "at least four members" is stated as a constraint on R74
rather than as a reading R74 may flip.** `R8.10` at line 1387 says an API "MUST adopt each
axis default unless a named trigger applies, and MUST record any flip in its conformance
note" — so the four dimensions are a *default* with named triggers, and the conformance
note is R69's or R71's artifact, as this decision itself says under OV-04. The escape
hatch ("only the membership moves") covers membership, but constraint 1 states the floor
flatly and the variable-set table restates it as fact. On the ownership question: the
**no-disabling-default** rule is R77's, because R77 owns the naming rule and is the first
web item to read R11.2; the **arity** is R74's, because it follows from the posture R74
chooses. Non-blocking — R74 owns the semantics and the decision says so; nothing in the
crate answer or `## Parameters` turns on it.

**JF-3 — non-blocking. Move 2 constrains defaults where Move 1 constrains values, and the
same hazard is left open.** Move 1 clause 2 makes a version-shaped `RSLBP_WEB_ROOT_PATH` a
boot failure under `RSLB203`, and AC12 checks it. Move 2 constraint 2 binds only "no
member's *default* may disable rate limiting", and AC14 checks only the all-unset case. An
operator who sets a family member to a disabling value puts the deployment outside R11.2's
MUST with no boot rejection — the same class of hazard, treated asymmetrically. Non-
blocking: R74 fixes the values and can carry the guard. A revision should either extend
the boot-validation rule to reject a disabling value or say why the operator case is out
of scope.

**JF-4 — non-blocking, and the item a controller most needs from this pass. Move 2
contradicts R74's binding prompt, and the decision does not name the collision.** R74's
prompt states the mandate as a middleware "**off by default and enabled by one env var**"
(`research/runs/R74/2026-09-18T215916Z-14066395aaea/inputs/prompt.md:32`), and R74's
in-flight legs follow it — its Opus raw proposes `rate_limit: Option<…>` defaulting to
`None` with one gate variable, and the Doxa leg names `RS_LAUNCH_RATE_LIMIT` with
`rate_limit_enabled_default = false`. Both breach Move 2's second constraint, and both
breach the four-member floor. No `CONFLICT:` line is available — R74 owns no registry
parameter — so its absence is correct, but the decision asserts R74 "owns rate-limiting
semantics" while overriding the semantics R74's own prompt fixes, without recording that
R74's prompt must move. R77's reading is the right one (W2-REST postdates that prompt and
R11.2 is a MUST); what is missing is the statement, which a revision should add beside the
coupling paragraph.

**JF-5 — non-blocking. The rerun-invariance rule omits a counter the script actually
carries.** `rerun-diff-r2.log` states "This script reads only committed files and git
blobs: no counter, no clock-dependent input, no network call. The only line permitted to
differ is its own timestamp header", echoed in `## Empirical check`. Three `PASS` lines
embed a live working-tree file count: rerunning today gives "OV-01 is already taken (12
files)", "OV-02 … (2 files)" against the committed log's 13 and 3. The companion check is
a working-tree census too, and HEAD's own ledger entry (`908cd1e`,
`docs/planning/p02/execution-ledger.md:1070`) now contains the literal `OVERRIDE (OV-04)`,
so the in-place script **fails** that check at today's HEAD while still passing from the
`d36492b` archive. Non-blocking, and it changes no verdict: every `PASS`/`FAIL`/`SKIP`
outcome reproduced at `d36492b` in place and from the clean extraction, the totals are
91/0/0 both ways, the counts are `n > 0` controls, and the allocation has since been
ratified in R77's favour. A revision should name the file-count lines as a fourth varying
kind and pin the census to a commit rather than the working tree.

**JF-6 — non-blocking. Move 2 raises the per-variable parse count above the twelve the
cost argument uses.** The variable-set section says "The `WebSettings` field count is still
twelve … so the hand-maintenance cost argued in `### Tradeoffs` stands as written", but
that cost is stated per parse arm — "Roughly one `FromStr` arm per field, twelve of them"
— and the reserved family is at least four further environment-variable **names** to read
and parse, so the arms are at least fifteen even though the fields stay twelve. Non-
blocking: the runner-up's winning condition is "twelve fields become thirty", and fifteen
arms is nowhere near it.

**JF-7 — non-blocking. Three classes of figure carry no endpoint at the point of claim.**
The prompt and spec §7.6 require every number to carry its endpoint.
`GET https://api.github.com/repos/<o>/<r>` is never named in the decision, yet
`stargazers_count`, `archived` and `pushed_at` are cited across six candidates (981, 913,
232, 25, 60 and 3,210 stars, and five `pushed_at` dates); only the `search/issues`
endpoint appears. `dotenvy`'s 46,188,632 90-day downloads carries neither endpoint nor
date on its line, and the "All figures: `GET https://crates.io/api/v1/crates/<name>` …
retrieved 2026-09-18" sentence attaches to a landscape table that excludes it. And of the
five gate-2 exclusions, only `envy` names the endpoint and date inline, `figment` inherits
them by "same endpoint", and `envconfig`, `serde-env` and `envious` carry neither. Non-
blocking, because every one of these is asserted in `figures.sh` against a committed
snapshot (`dotenvy` at line 77; the GitHub snapshots under `evidence/snapshots/gh-*`) and
I reproduced all 121 checks: the figures are sound and only the citation is short.

**JF-8 — non-blocking. Two precision slips in the conformance table.** The `R8.5` row is
labelled "**CONFORMS as N/A-with-reason**", which conflates two of the three states the
§1.9 note template keeps separate (conform, deviation, N/A declaration); R8.5 is also not
switch-scoped, so it borrows R1.6's vocabulary for a rule-level N/A, which `R1.7`'s
template does permit ("rule ID or switch"). Separately, the `R7.2` quotation stops at "one
user's data to another" and drops the rule's own next sentence, "**Exception:** genuinely
public responses", with no ellipsis. Neither changes a disposition — the substance of R8.5
(no credential is a field of `WebSettings`, so there is no lifetime to govern) is right,
and the R7.2 forward rule is already consistent with the exception via R7.3's third tier.

## Assessment

**The recommendation would not move under any of these findings**, and I checked the two
that could have moved it. JF-1 attacks the frame that carries twelve CONFORM rows, so I
read the candidate counter-examples in full: R3.9's clause is conditional and belongs to
R70/R73, and R12.8 binds consumers rather than this provider, so no row's disposition
changes. JF-4 attacks the one place this decision overrides another item's mandate, and
the override survives, because `R11.2` is a MUST in a standard the owner ruled binding on
2026-09-18 and R74's prompt predates that ruling. No crate is adopted, `config >= 0.15.25,
< 0.16.0` stays the ranked runner-up with its two winning conditions intact, `confique`
0.4.0 stays third on the testability ground, the `const fn` prefix derivation and the
`Arc<WebSettings>` / `FromRef` threading stand as measured against real axum 0.8.9, and
nothing in `## Parameters` moves.

Three things I record for the controller rather than as findings against this revision.
The working-tree file has advanced to an uncommitted revision 3 since `d36492b`, so this
audit binds a sha the on-disk file no longer carries. R80 has since published its revision
3 (HEAD `53b13f4`), which both takes OV-05 and files one of the two sentences this
decision quotes from R80's raw under its own "Overstated" heading — R77's attribution to
"R80's raw" is accurate and its re-verify trigger on R80's publication has now fired. And
`OVERRIDE (OV-04)` still needs an approver and a date, and will have to migrate into
whichever item writes the conformance note, which this decision already says is R69's or
R71's artifact.

I therefore **approve** revision 2, with no unresolved findings. Acceptance still requires
the deferred empirical leg's disposition under `W1-CODEX3` and the owner's ruling on
`OVERRIDE (OV-04)`. Nothing in the decision was edited by this audit.
