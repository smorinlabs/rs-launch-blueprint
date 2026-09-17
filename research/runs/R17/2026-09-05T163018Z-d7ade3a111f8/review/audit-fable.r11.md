decision-sha256: 6a26da1a9ef708d28c922c3fb8530e58649f4d2f5699fb1ba10800f8bb28df49
actor: audit-fable-2026-09-05T163018Z-d7ade3a111f8-r11
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-9 (blocking): measurement (7)'s rerun-and-diff record at line 227 says "the two files differ in **25** lines and no more — the three that name this run's `mktemp` workspace and its interpreter resolution, and the twenty-two echoed section-08 lines", and adds that "the **25**-line figure above is measured against measurement (5)'s revision-11 log, not carried", but `diff` of the two revision-11 logs reports **28** lines on each side: the twenty-two section-08 echoes plus **six** environment lines, the three unnamed ones being the shim's `placed at:` line and the two per-mutant section-00 `curl=<workspace>/bin/curl` echoes that revision 11's own harness added; the same sentence-family at measurement (8) names "the eleven fixture, shim and source paths that move with the extraction root" where that diff carries seven lines and no fixture line at all, the fixture digests being printed by basename and identical in both logs

## Principle and agreement level

Unchanged, and re-checked rather than carried. Revision 11 adds four paragraphs, rewrites four in
`## Empirical check`, retitles, and adds nine files under `review/empirical/` and four logs. It
touches no recommendation, no gate wording, no runner-up, no `BASELINE-REVIEW:` line and no
fitness-gate row. Part 2 is still the TruffleHog OSS CLI, `>= 3.97.0, < 4.0.0`, a pinned release
binary in a `run:` step with `--only-verified --fail` under owner ruling W0-R17b; the passing set is
still `0` alone; `--fail-on-scan-errors` is still required; fitness gate 1 is still `inapplicable`
under Q7.B and I raise no licence finding. I confirmed by search that the `f7367c6~1`-to-`153705f`
span touches none of section 13's fourteen anchor prefixes, that the four `- assumes` lines are
still byte-identical to `docs/port/PARAMETERS.md` (rebuilt from that file's rows and `diff`ed:
empty), and that `run-checks-r8.sh` (`697ea3b1…`), `mutations-r8.sh` (`0663adc4…`) and
`mutations-r9.sh` (`774eb8d4…`) are unchanged on disk.

## Design and evidence

**JF-7 is closed, and the repair is better than what I asked for.** I asked for the live-API budget
to be declared and branched on, or for the set assertion to stop being perturbable by it. Revision
11 does the second, through a seam the evidence script already had rather than by editing it:
`run-checks-r8.sh:163` resolves its HTTP client with `resolve_tool curl`, whose probe
(`run-checks-r8.sh:147`) only checks that `--version` exits `0`, so `mutations-r11.sh:160–161`
installs `mutations-r11-curl-shim.sh` as `$WORK/bin/curl` and prepends that directory to the
**mutant's** `PATH` at its line 208 alone — the harness's own `PATH` is untouched, and the real
`curl` is resolved by probe at line 113, before the shim exists.

*The shim's boundary is exactly what the decision says it is, and I read it rather than the prose.*
Only host `api.github.com` is intercepted (`mutations-r11-curl-shim.sh:65–70`); every other host is
`exec`ed to the real curl. Five paths are served from committed bodies (`:74–85`) and **any other
`api.github.com` path is refused with exit `22` and nothing written** (`:86–88`), so a new endpoint
cannot be silently satisfied — it fails the assertion that reads it and shows up as an extra label
in the failing set. The five map to eight labels — `00b`, `03a`, `03b`, `10a`–`10d`, `11c` — and I
confirmed against the script that those are the script's only `api.github.com` requests: lines
218/221 (`/rate_limit`), 353, 842, 843 and 884 (`api_fetch`). The decision's own enumeration of
those five call sites at line 69 is therefore correct.

*Is fixture-feeding those eight a valid proof of falsifiability for the section-08 targets? Yes,
and the reason is structural rather than a matter of trust.* **Section 08 makes no network request
at all** — I swept lines 660–800 of `run-checks-r8.sh` for `CURL` and `https://` and the only hit is
line 794, which is section 09's `git clone`. **The binary section 08 executes cannot be chosen by a
fixture**: it is downloaded from `BASE_URL`, `https://github.com/trufflesecurity/trufflehog/releases/download/<tag>`,
with literal filenames built from the version constant (`:378–387`) — a host the shim passes
through live — and its identity is pinned by `04a` against a live-fetched `checksums.txt` and by
`05a`'s version string. So no fixture reaches any input of `08e`, `08f` or `08h`–`08j`, and none of
the eight fixture-fed labels is a mutation target. What the fixtures remove is a failure mode with
nothing to do with the mutation; what they cannot do is manufacture the result being proved, and a
fixture-fed label can still fail — on a refused endpoint, or on content that stopped satisfying its
assertion.

*The boundary is stated honestly, in three places, and the one consequence is pre-empted rather
than left for an auditor.* Line 73 names the eight fixture-fed labels and the still-live set,
`fixtures-r11/MANIFEST.txt` carries the capture instant (2026-09-17T02:04:39Z, under a declared
token so the capture did not spend the anonymous budget), the six per-file digests and a
"what each satisfies … and what it does NOT" column — including that the trufflehog fixture's
`stargazers_count` "is printed by the parent check and asserted by nothing" — and each log prints
its own `FIXTURE-FED` / `STILL LIVE` block (`…-r11-mutations.log:27–30`). The printed-counter
consequence is the JF-4 defect class, and line 73 pre-empts it: the star figures inside a mutant
run are the fixture's, no committed revision-11 log contains them, and this document's own
section-10 figures still come from `…-r8-repo.log:240–242`. I verified all three: the six digests in
the log equal the committed files and the manifest; `stargazers_count` and `27960` each return zero
across all four revision-11 logs.

*And the runs prove it under a harder condition than the one that broke revision 9.* All four logs
read `live anonymous api.github.com core budget BEFORE … 60 0` and `AFTER … 60 0` — **remaining
zero**, where round 10's failing rerun began at `remaining 8` — and all four end
`mutation-harness failures: 0`, `RESULT: PASS`, with `MUTATION CHECK failing-set: the mutant's
FAILing labels are exactly the targeted ones` for both mutants, each mutant exiting `1`, and the
same `FAIL=3` and `FAIL=1` counts recorded since revision 8. Each log shows the mutant resolved the
shim (`curl=<workspace>/bin/curl` in its own section-00 line, and the shim's banner). The
verdict-block comparison the decision rests on holds: I diffed measurement (5) against (7) and
against (8) with the `grep -n` prefix stripped and **zero** `RESULT` / `summary:` /
`MUTATION CHECK` / `mutation-harness` lines differ in either pair.

**JF-8 is closed.** Line 222 now reads "Section 00 prints `UTC now:`, and the scripts that emit a
section 00 are the two `run-checks` scripts — `run-checks-r8.sh`, which produced measurements (1)
through (4), and `run-checks-r7.sh`, which produced measurement (6) — so the five are measurements
(1), (2), (3), (4) and (6)", with the superseded ground quoted and corrected in its own parenthesis
and the three mutation harnesses named as emitting none. That is exactly the repair I named, and
the enumeration it justifies is the one I verified in round 10.

**Two residuals, recorded as observations and not as findings.** The harness *prints* but does not
*assert* that the mutant resolved the shim (`mutations-r11.sh:213`), and *prints* but does not
assert `BUDGET_BEFORE == BUDGET_AFTER` (`:279–288`, which reports a difference rather than
explaining it away). Neither can mask what the harness proves, and the direction is the safe one: a
bypassed shim yields either a true pass on a healthy budget or a loud failure on a depleted one —
the extra labels appear in the failing set and the harness exits `1` — never a false pass. Both are
visible in every log.

**Where the evidence does not reach the claim.** One sentence-family, in the rerun-and-diff record
at line 227. It is JF-9.

## Completeness

| Required item | Status |
|---|---|
| `## Decision`, `### Principles and implementation`, `re-verify:` (192), `## Parameters` (194), `## Empirical check` (220), `## Engines` (267) | present, in order |
| `## Supersedes` | correctly absent — unpublished revision |
| Owned / consumed parameters | none; the prompt's `- owns:` and `- consumes:` lines are empty |
| The four `- assumes` lines | byte-identical to `docs/port/PARAMETERS.md`, verified programmatically |
| Ledger row, `BASELINE-REVIEW:`, `CONFLICT:` | unchanged and correct; F050 named and not edited, the review carried verbatim and unresolved, no `CONFLICT:` owed |
| Six fitness gates | all six answered for both candidates; gate 1 `inapplicable` under Q7.B |
| Round-9 findings JF-4, JF-5, JF-6 | closed in revision 10 and unchanged here; the figures at lines 166/195 and the section-10/12 evidence rows still cite `…-r8-repo.log:240–242` and `:261–262` |
| New artefacts | `mutations-r11.sh`, `mutations-r11-curl-shim.sh`, `fixtures-r11/` (six bodies plus `MANIFEST.txt`) and four logs, all committed and all digest-matched to what the logs print |
| Untouched artefacts | `run-checks-r8.sh`, `mutations-r8.sh`, `mutations-r9.sh` and the ten earlier logs are byte-identical, as line 75 claims |
| audit-codex | round 10 (`review/audit-codex.md`) binds `a4ce36e4…` and rejects on F1, which revision 11 repairs; round 11 is queued and owns the reruns, so this audit binds nothing to it and states consistency with round 10 only |

## Findings

Numbering continues from round 10's JF-8.

**JF-9 (blocking) — the rerun-and-diff record states a line count its own logs contradict, in the
one sentence that claims to have re-measured it for this revision.** Measurement (7) at line 227
reads: "Against measurement (5)'s log, **all 39** `RESULT`, `summary:`, `MUTATION CHECK` and
`mutation-harness` lines are identical once `grep -n`'s line-number prefix is stripped, compared as
a block by `diff` rather than by eye; **the two files differ in 25 lines and no more** — the three
that name this run's `mktemp` workspace and its interpreter resolution, and the twenty-two echoed
section-08 lines whose only difference is that prefix". Three sentences later it adds: "the
**25**-line figure above is **measured against measurement (5)'s revision-11 log, not carried**".

`diff review/evidence/secret-scanning-ci-workflow-r11-mutations.log
review/evidence/secret-scanning-ci-workflow-r11-mutations-shim-path.log` reports **28** lines on
each side, not 25. The composition is the twenty-two section-08 echoes the sentence names — those
are right — plus **six** environment lines, where the sentence names three: `HOME used by this
harness`, `python3 first on PATH was …bypassed`, `mutant workspace`, and **three the sentence does
not name**, all of them added by revision 11's own harness: the shim's
`placed at: <workspace>/bin/curl` line and the two per-mutant section-00 echoes
`python3=… curl=<workspace>/bin/curl …`. Revision 9's logs carried none of those three, and
3 + 22 = 25 was true of them; the figure is revision 9's, restated under a claim of fresh
measurement.

**A second instance in the same sentence family, folded in here rather than numbered separately
because it is one defect and one repair.** Measurement (8) says the archive log and measurement
(5)'s "differ in **14** lines and no more — the three that name this run's `mktemp` workspace, its
`HOME` and the extraction path, and **the eleven fixture, shim and source paths that move with the
extraction root**". That diff carries **seven** lines on each side, and **no fixture line at all**:
the six recorded bodies are printed by basename with their digests (`…-r11-mutations.log:21–26`),
so they are identical in both logs. The seven are `HOME used by this harness`, the shim's `source:`
path, its `placed at:` path, `source under mutation:`, `mutant workspace:`, and the two section-00
toolchain echoes. The total 14 is defensible if lines are counted on both sides, as measurement (8)
has counted since revision 9; the composition is not.

*Why this blocks, stated against my own round-10 reasoning so the line is visible.* In round 10 I
declined to make these counts a finding: two counting conventions sat side by side, and each figure
was consistent with one of them, so nothing was falsified. That is no longer true. Measurement (7)'s
25 is consistent with **neither** convention — the files differ in 28 lines on each side and 56 in
total — and the sentence now asserts in its own voice that the number was measured against this
revision's log rather than carried. That is JF-4's exact shape, which this document accepted as
blocking and repaired across two revisions: a figure attributed to an artifact of this revision that
the artifact does not carry, sitting in a printed-never-asserted region where a `RESULT`-line rerun
is blind by construction. Approving it would hold a claim that advertises itself as freshly measured
to a looser standard than one that did not.

*What resolves it:* re-run the two `diff`s, state the counts they produce and enumerate the
composition — for (7), twenty-two section-08 echoes plus six environment lines including the shim
placement and the two section-00 toolchain echoes; for (8), the seven lines above, with the fixture
bodies named as identical because they print by basename — and say which side of the `diff` the
number counts, so the two sentences stop using different conventions. Nothing else need change.

*Does the recommendation move under it? No.* JF-9 touches neither the tool, the install shape, the
passing set `{0}`, `--fail-on-scan-errors`, the output-format requirement, the runner-up, a
parameter, an anchor line nor any `RESULT` verdict. The falsifiability proof it sits beside is sound
and I approve of it: the verdict-block comparison it rests on reproduces exactly, with zero
differing lines in both pairs.

## Assessment

Revision 11 answers JF-7 with a better instrument than the one I asked for. Rather than declaring
the depletable budget and branching on it, it removes the dependency: the mutant's `curl` is a
fixture shim installed through the `PATH` lookup `run-checks-r8.sh` already performs, so that script
is again not modified; only `api.github.com` is intercepted, only five recorded paths are served, an
unrecorded path is refused with exit `22` rather than invented, and every other host stays live.
The boundary is drawn where it has to be for the proof to survive: section 08 — the only section the
verdict rests on and the only one either mutation touches — makes no network call, and the binary it
executes is fetched from a passed-through host under literal filenames and pinned by `04a` and
`05a`, so no fixture can reach it. Eight non-target labels are fixture-fed and every one of them is
named, in the decision, in a committed manifest that also records what each fixture does *not*
establish, and in each log's own boundary block. The four runs then pass with the live anonymous
budget at `60 0` — nothing remaining — which is a harder condition than the one that broke revision
9, and each mutant's failing set is exactly its targets. JF-8 is closed with the superseded ground
quoted and corrected.

I reject on one thing, and it is not the repair. The sentence recording how the four logs differ
from one another states 25 where `diff` says 28, names three environment lines where there are six,
misses precisely the three lines revision 11's own shim machinery added, and then says the figure
was measured against this revision's log rather than carried — which is the one claim `diff`
disproves. The companion sentence attributes seven differing lines to eleven fixture paths that are
not in its diff at all. Both are cheap to fix and neither moves a conclusion, but this is the defect
class this document has been rejected for at rounds 6, 9 and 10, and the fix is to re-run two
`diff`s and write down what they print.
