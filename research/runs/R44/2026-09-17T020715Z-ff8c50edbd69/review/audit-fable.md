decision-sha256: ea398ddaecf3f3034ef60ae699d94f380979ca2ef9401160641dd757a1481ceb
actor: audit-fable-2026-09-17T020715Z-ff8c50edbd69-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

I read `review/DECISION.md` whole at the sha256 above, recomputed with
`shasum -a 256`, both raw reports at the sha256s `## Engines` records
(`6c8e968d…` for `raw/codex.md`, `187dc17c…` for `raw/opus.md`, both confirmed
against the run's content-addressed copies), `inputs/prompt.md`,
`research/topics/42-dev-toolchain-provisioning/DECISION.md`,
`research/topics/20-third-party-action-pinning-policy/DECISION.md`,
`research/topics/34-scheduled-freshness-lanes/DECISION.md`,
`docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md` rows F193 and F200,
`docs/port/BASELINE-REVIEW.md:92`, `docs/port/DIVERGENCE-ANALYSIS.md:172`,
`docs/port/OWNER-REVIEW.md:47`, `research/RUNBOOK.md` §4–§5, and both logs under
`review/evidence/`. I reran nothing and invoked no container runtime; that is the
empirical auditor's work and it is deferred.

Fitness gate 1 is `inapplicable` by the owner ruling of 2026-09-12
(`docs/port/OWNER-REVIEW.md:47`, "2026-09-12 — no licence check for anything the
template uses (Q4, superseded and widened by Q7.B)"), so this audit raises no
licence finding and does not test the recorded licence figures.

## Principle and agreement level

**The principle is stated at the right level, and the level is argued rather than
asserted.** The shared requirement is read from py's two files at the pinned
commit `b08bccfb` and quoted as a block: a contributor on an unsupported host
reaches a bootstrapped environment "and that environment is produced by the
repository's own single bootstrap chain, not by a second, parallel set of setup
instructions." The decision names the second clause as load-bearing and then
proves it holds in py: check 7a records that py's `post-create.sh` runs
`make bootstrap` and `just setup`, which is the same Level-1/Level-2 pair
F179–F182 make `COMMON → REUSE`. The recommended `post-create.sh` ends in exactly
those two commands, so the recommendation instantiates the principle rather than
restating it.

**The four-row agreement table is correct against its source.**
`docs/port/DIVERGENCE-ANALYSIS.md:172` reads `partly — adopt-or-drop is a shared
org call (yes); the base image and in-container config, if adopted, is
Rust-specific (no)`, and the decision quotes the first half verbatim and assigns
`policy` to it, `architectural pattern` to `postCreate` delegation and to the
single extension declaration, and `capability, realised natively` to the image,
tag, `remoteUser`, mounts and pre-steps. That mapping is the source's own split.
It is worth recording that `raw/opus.md:120` attributes the phrase "adopt in all
three or drop in all three" to that row; no such string is in the file. The
decision does not carry the misquotation forward — it quotes the real text — and
that correction is evidence the synthesizer re-read the source rather than
trusting its engine.

**The ecosystem-appropriateness test was actually run, and it cuts against the
recommendation in part.** The decision answers "Partly, and its value is narrower
in Rust than in Python", gives the ecosystem-specific reason (Python's
interpreter-plus-virtualenv story is host-entangled; `rustup` plus
`rust-toolchain.toml` is not), and reduces the container's contribution to four
ranked goods. It then names what the container does **not** buy — reproducible
builds, the MSRV floor, the deployment image — which is the discipline the
research mandate asks for when a pattern is inherited from another ecosystem.

**The cross-repo answer classifies ts honestly.** It records the inferred reason
on file ("ts's Node toolchain needs no isolated container"), rejects it on a
stated ground — the same portability argument applies at least as strongly to
`rustup`, so it cannot be what decided it — and lands on "accidental drift in ts,
with a justified difference in realisation", with the artifact free to differ.
Check 7c confirms the premise: `git -C ~/c/ts-launch-blueprint ls-tree cb1cbcb2
-- .devcontainer` returns 0 entries.

## Design and evidence

**Four architectures were compared, not four images, and B is selected on a
structural ground.** The table separates A (no devcontainer), B (image-only),
C (base image plus features) and D (local `Dockerfile`). The reason given for B
over C is that C's configurability — `profile`, `components`, `targets` as
feature options — is configurability this repository must not use, because using
it recreates the second toolchain declaration R42 removed. I checked that against
R42 directly: R42 layer 1 commits `rust-toolchain.toml` with `profile = "minimal"`
and `components = ["rustfmt", "clippy"]`, and R42 layer 3 is `**None.**` for a
declarative provisioner manifest, settling F187, F188 and F189 on the ground that
"The declared tool set has exactly one authoritative location". The decision's
sentence — a `features` block "is refused here on the same ground `mise.toml` and
`flake.nix` were refused there" — is a correct reading of that row, not an
analogy stretched to fit.

**Two independent facts confirm B over C, and both were executed here.** Gate 3's
substitute is installer integrity, and the asymmetry is measured rather than
described: check 5d records `rustup/archive/1.29.0/` and **7** hard-coded
per-architecture sha256 constants in the image's upstream Dockerfile; check 5a
records the unversioned `rustup/dist/` path, a `rustup-init.sha256` served from
the same host, and **0** hard-coded constants in the feature installer. Calling
the second "corruption protection, not provenance" is exactly what those two
observations support. Check 5b reproduces Codex's version-resolution defect at
`feature_rust_1.6.0` — the log prints the source line
`if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then` — and
check 5c records `devcontainers/features` #1726 `open`.

**The postCreate line respects R42.** `rustup toolchain install` with no arguments
materialises the toolchain `rust-toolchain.toml` names (check 6b quotes rustup's
own help, "or by default the active toolchain"), which is R42 layer 1's artifact
and not a second declaration; it installs no individual component, so R42's "No
`install-rustfmt`/`install-clippy` recipe is ever written" is untouched. The two
following lines are bare executables on `PATH` with no provisioner prefix, which
is R42 layer 5's invocation rule. R42's own "no `rustup toolchain install`"
sentence is a statement about R42's empirical-check hygiene — that nothing was
installed on the audit host — and not a prohibition on the template; I checked its
context before relying on it. R42's open integrity tradeoff on the
`cargo binstall` prebuilt path travels into the container unchanged, because
`just setup` is the same recipe a native contributor runs; the decision neither
resolves nor disturbs it, which is the correct posture for a consumer.

**R20 is applied as a principle and the difference is labelled.** R20's decided
grammar is `owner/repo@<40-hex> # vX.Y.Z` enforced by `zizmor` over `.github/`
plus `scripts/check-action-pin-comments.sh`. The decision claims the analogue —
an OCI reference's immutable identity is its `@sha256:` digest, with the readable
release identity beside it — and states plainly that this is "R20's *principle*
applied to a new file type, not R20's checker extended", with acceptance criterion
5 requiring a separate repository-local script because "`zizmor` reads workflows,
not `devcontainer.json`". That is accurate about R20's enforcement surface.

**The macOS-host and CI-validation claims are evidenced, and the two are kept
apart.** Check 1b records the index media type
`application/vnd.oci.image.index.v1+json` and platforms `amd64,arm64`, which is
what supports "an Apple-Silicon macOS host runs the container natively rather than
under emulation." Check 3a resolves `macos-latest` to the macOS 26 Arm64 image and
`ubuntu-latest` to Ubuntu 24.04 from GitHub's own `runner-images` README. Check 3b
prints `macos-26-arm64 readme: 261 lines (whole file read, no head/cut in the
count)` and then `expected 0, got 0` for case-insensitive `docker` lines, against
`Docker Server` and `Docker Client` matches in the Ubuntu inventory. The decision's
sentence "That is a statement about the *runner*, not about a developer's Mac" is
the correct reading, and the log's own NOTE says the same. Gate 4 is therefore
answered as an asymmetry rather than an exclusion, which is the right disposition
for a contributor environment that is not a CI matrix cell.

**Declining Codex's F200 rests on stated grounds, and I checked the decisive one
against the raw.** `raw/codex.md` `### Excluded by gate` contains, verbatim, "It
also fails the required fit gate as a replacement for host validation: the feature
supports Linux distributions, while the owner requires CI on both Ubuntu and
macOS", and `raw/codex.md` `### Landscape` contains, verbatim, "they do not
replace the required native `macos-latest` CI lane". Both quotations in ground 1
are exact, the concession is genuinely in Codex's own Landscape, and no candidate
in either report proposes the container as a replacement for the `macos-latest`
lane — I checked both `### Recommendation` sections for such a proposal and found
none. Ground 2 is also right about where Codex's concrete defect lands: the
`grep -o "."` test and the `git ls-remote` fallback are in the feature installer,
which a features-free recommendation never runs, and the decision reuses that
evidence in the direction it supports rather than discarding it. Ground 3 carries
the practice signal against itself: Codex probed 3 repositories and found 0,
Opus probed 31 and found 4, and check 8a re-probed all 31 and prints one HTTP
status per repository, `expected 4, got 4`. Ground 4 rests on two owner facts
already on record rather than on a preference. The disposition paragraph accepts
Codex's principle in full and declines only the inference, and states what happens
to F200's row if the owner takes the runner-up.

**The runner-up is a real runner-up.** "27 of the 31 well-regarded Rust
repositories re-probed for this decision carry no `.devcontainer` directory" is
check 8a's own arithmetic (31 probed, 4 at HTTP 200), the log's NOTE states the
direction of the signal is against adopting, and the decision carries it as the
runner-up's case. Confidence is split correctly — "high on the mechanics and medium
on the adopt-or-drop call itself" — and a reader who weighs ecosystem practice
higher is told, in `## Decision`, the condition under which A wins.

**The owner-facing cost is stated as a cost and is not buried.** The Dependabot
paragraph ends "**The image digest therefore has no automated bumper.** That is
the single real cost of this recommendation", the Tradeoffs paragraph repeats it
as "an unautomated pin (one string, no bot)", the runner-up paragraph makes it the
winning condition — "if the owner is unwilling to carry an OCI digest that nothing
automatically bumps" — and the re-verify trigger turns check 1c into the manual
bump signal. Four sites, one of them the runner-up's decision rule. The evidence
under it is executed: check 4a shows the parser entry point calling
`parse_features(config_dependency_file)` with 0 references to an image parser, and
check 4b shows `dependabot-core` #9271 `closed`, `closed_at
2026-03-26T00:11:57Z`. Treating this as a downstream implication for R19 rather
than a `CONFLICT:` is correct: no registered parameter value has to move.

**The unproven rows are honest and, in one respect, unusually so.** Nothing was
built, no container was run, and the decision says why a `docker` client on the
host was never invoked. All five acceptance criteria are marked `planned` for P03.
Criterion 2 is given a control — run it once with a channel the image does not
bake, and confirm the run fails when the assertion is inverted — which is the
difference between a test and a status check, and the decision says so itself. The
cargo-cache mount's second justification is marked "asserted from R42's recipe
shape, not observed in a container; P03 confirms", the volume's pre-population
behaviour is P03 item 3 and cited as read from documentation in `raw/opus.md`, and
871,370,327 is repeatedly called a byte total and not a duration. The role doc's
rule applies here: this is a research programme, P03 builds and proves the
template, and a decision must not be faulted for declining to implement its own
recommendation.

**Every "rot" statement is labelled as carried at every site where it is used.**
`/usr/bin/grep -n 'rot\b'` over the decision returns six lines. Two are generic
properties of architecture A ("zero maintenance surface, zero rot"; "cannot rot"),
carrying no figure. The three that rest on the adopters' last-touched dates each
carry the reference: `### Principles and implementation` — "D is excluded on
demonstrated rot — a judgement resting entirely on the adopters' last-touched
dates carried from `raw/opus.md` and **not** re-executed here"; `## Engines`
ground 3 — "the last-touched dates behind that sentence are carried from
`raw/opus.md` and were **not** re-executed here"; and the carried-claims paragraph
itself, which names all four dates (ruff 2024-08-28, biome 2026-09-09, deno
2023-12-19, tauri 2022-06-06) and says they "are the whole basis of every 'rot'
statement in this decision", listing the three sites. The dates match
`raw/opus.md:66-69` exactly, the `2.1.1-bookworm` total 912,332,031 matches
`raw/opus.md:354`, and `universal:6`'s ≈3,821 MiB matches the same line. "Three of
them have let the file rot" is arithmetically right: biome's 2026-09-09 touch is
the fourth and it is not counted.

**The F193 carry-forward is the legitimate disposition.** `inputs/prompt.md`
directs the engine to "Report a challenged baseline as `BASELINE-REVIEW: F### —
principle — proposed change — evidence` in the answer; do not silently change
another item or the ledger", and `research/RUNBOOK.md` §4 puts adjudication with
the controller and the affected decision owners. The decision records the finding,
says "It is recorded here and **not applied**: this decision edits no ledger row",
names the affected items (F193, F200 and R28, which populates
`.vscode/extensions.json`), and states that it holds whichever way the
adopt-or-drop call goes. `docs/port/BASELINE-REVIEW.md:92` carries F193 as
`retained` with R28 owning the entries, and its recorded py count of 11 ids agrees
with check 7b. The evidence under the finding was re-executed, not carried: check
7b prints `expected 4, got 4`, `expected 11, got 11`, `expected 3, got 3` with the
three shared ids listed, `EditorConfig.EditorConfig` as the devcontainer-only
entry, and `expected 8, got 8` for the withheld recommendations; check 1f prints
the image's three contributed extensions. F200's disposition is equally clean: the
row's origin and verdict do not change, and the decision says a `DIVERGENT` row is
settled by its item's decision rather than by a verdict rewrite.

## Completeness

**`## Parameters` is correct in grammar and in content.** I extracted rows 7–10 of
`docs/port/PARAMETERS.md` mechanically into `- assumes <name> = <value>` form and
`diff`ed them against the decision's four `- assumes` lines: no difference. The
four values are therefore byte-identical to the registry, on one line each,
carrying a value and nothing else — no backticks, no citation, no trailing
commentary, which is the format R42's own revision-5 publication failure
established. There is no `- owns` line, and the decision checks rather than
assumes that: `inputs/prompt.md` `## Couplings` carries an empty `owns:` and an
empty `consumes:` field, which I confirmed at lines 19–20. `**No `CONFLICT:`
lines.**` is right — no registered value has to move for this recommendation to
hold, and both raws agree.

**The H2 set matches `research/RUNBOOK.md` §5.** `/usr/bin/grep -n '^## '` returns
exactly `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`.
`### Principles and implementation` is present inside `## Decision`, the settled
`F###` rows are named there, and `re-verify: 2027-03-17, or earlier on any of —`
carries eleven named events. `## Supersedes` is correctly absent: revision 1 is not
a reversal.

**The tally is stated within what the logs show.** `/usr/bin/grep -c '^PASS'` over
`review/evidence/r44-claims.log` returns 53; `^FAIL` returns 0; `^SKIP` returns 0;
the log's closing banner reads `ALL ASSERTIONS PASSED (0 failures)`. I tallied
PASS lines per section with `awk` and every row of the decision's `## Empirical
check` table matches: 1a–1c 5, 1d 2, 1e 4, 1f 5, 2a 1, 3a–3b 5, 4a–4b 3, 5a–5d 9,
6a–6b 3, 7a–7c 8, 8a 2, 9a–9d 6. The column sums to 53, which is the headline.
Section 9b prints the four parameter lines and asserts nothing, so its zero is
correct. The named-skip control is stated exactly as its log reads:
`review/evidence/r44-claims-skip-control.log` gives 23 `PASS`, 8 `SKIP`, 0 `FAIL`,
and each skip names what was missing — five `gh absent`, one `no rustup on this
host`, and two naming the absent sibling checkouts by absolute path, which is the
two-line difference the decision predicts.

**Endpoints and retrieval dates are present where a figure carries weight.** The
digest carries its endpoint and header field inline
(`GET https://mcr.microsoft.com/v2/devcontainers/rust/manifests/2.1.1-trixie`,
`docker-content-digest`, retrieved 2026-09-17). The `## Empirical check` endpoints
paragraph enumerates the MCR registry v2 API paths and the six GitHub REST
endpoint families, states 2026-09-17 (UTC) for every network read, and points at
`review/evidence/snap/RETRIEVED.txt`. Carried figures name `raw/opus.md` as their
source and the reproducibility paragraph names the three classes of line that may
legitimately drift on a re-fetch. The one figure without a per-site endpoint is
the star-count pair in disagreement 4, which the decision itself calls
non-substantive; both raws give the endpoint.

**Two things I could not judge, stated rather than glossed.** First,
`review/audit-codex.md` does not exist in this run, so the role doc's instruction
to check "whether the audit-codex rerun is consistent with the decision" has no
subject; the empirical audit is deferred because the Codex account is out of usage,
and acceptance still requires two approving verdicts under `research/RUNBOOK.md`
§5. This audit is one of them. Second, I did not rerun `r44-claims.sh`, so the
decision's claim that a plain re-run and a `git archive HEAD` extraction both
produced byte-identical output has no witnessing artifact in `review/evidence/`.
It is corroborated circumstantially — commit `5fa9ad0` changed exactly one line of
the script, a `printf` into `toolchain.txt` rather than stdout, so the stdout log
could not have moved; and the skip-control log's SKIP lines quote
`/tmp/r44-extract.oYcaCA/fakehome/c/py-launch-blueprint`, an extraction path that
only a clean-extraction run produces. Confirming it is the empirical auditor's
work, not this audit's, and I record it as unwitnessed here rather than as a
defect.

**One stale input, correctly handled.** `inputs/PARAMETERS.md` predates R69's
publication and carries `—` for `web-extra-surface` where `docs/port/PARAMETERS.md`
now carries the full researched value. Check 9a compares only the four fixed rows,
which are identical in both, and check 9d reads the live registry for R69's value.
The decision's wording follows the same split — "R69 has since published
`web-extra-surface`" — so the stale snapshot is not relied on anywhere. R42's
prerequisite sha256 `a2504aa7…` matches `inputs/prerequisites.json` at check 9c,
and I confirmed the same sha256 against the published
`research/topics/42-dev-toolchain-provisioning/DECISION.md`.

## Findings

Four findings, **all non-blocking**. None is an unresolved finding in the
acceptance sense, and the recommendation does not move under any of them.

**JF-1 (non-blocking) — the reference-implementation label contradicts the
decision's own carried data.** The decision writes:

> `astral-sh/ruff` is the maintained adopter of the same image plus the same
> mount, and its `post-create.sh` is the shape this pattern deliberately trims

Two facts already in this run sit against "the maintained adopter of the same
image". `raw/opus.md:66` records ruff's pin as
`image: mcr.microsoft.com/devcontainers/rust:0-1-bullseye` — the same *repository*
but the `bullseye` variant, which is the EOL Debian line the decision's own table
calls a silent trap ("A bullseye tag still resolves in the registry, so the trap is
silent"). And the same line records ruff's `.devcontainer` last touched
**2024-08-28**, which is one of the three touches behind "three of them have let
the file rot" in `## Engines` ground 3. So the decision calls the same artifact
"maintained" in one section and rotted in another, and does not record that the
tag differs from the one it recommends. *What resolves it:* say "the same image
repository, at its `0-1-bullseye` variant, last touched 2024-08-28", and note that
ruff's stale EOL tag is itself an argument for the digest pin rather than against
the citation. *Why non-blocking:* the prompt's requirement to "cite a maintained
reference implementation, or state the evidence gap" is already met by the
first-party `devcontainers/templates` `src/rust`, which the decision cites as its
reference implementation and marks as carried from `raw/opus.md`; ruff is a
corroborating adopter, and the mount it demonstrates is unaffected by its tag.

**JF-2 (non-blocking) — one load-bearing image property is inferred, not observed,
and appears on neither unproven list.** `post-create.sh` carries the comment:

> Unlike py's slim uv base, this image already carries make, curl, git and
> ca-certificates, so there is no apt-get step here.

The supporting row states the inference chain and cites it — "The image descends
from `buildpack-deps:trixie` (check 5d) and bakes the `git` and `common-utils`
features (check 1f)" — but check 5d asserts only that the *upstream Dockerfile*
contains `FROM buildpack-deps:trixie`. No check reads the final image's filesystem
(deliberately: no container was run), and `make`, `curl` and `ca-certificates`
appear neither in the carried-claims list nor in the seven-item "What P03 must
validate" list, while being the whole justification for omitting an `apt-get`
preamble. *What resolves it:* label the presence claim as inferred from the base
image through check 5d rather than as an image property, and add a
`command -v make curl` assertion to P03's acceptance criterion 1. *Why
non-blocking:* the inference is sound and its evidence is cited at the point of
use, and acceptance criterion 1 (`devcontainer up` then `devcontainer exec`) fails
loudly in P03 if it is wrong, so no P03 work is misdirected.

**JF-3 (non-blocking) — a resolved item is named as the host of a check it does not
define, without the downstream-implication sentence this decision uses elsewhere.**
The re-verify trigger reads:

> the pinned digest stops resolving or stops being multi-architecture (check
> 1a/1b fails in a scheduled lane, R34)

`research/topics/34-scheduled-freshness-lanes/DECISION.md` recommends "run both
lanes, as one schedule-only workflow" — a weekly dependency canary and an advisory
beta-toolchain lane. Neither resolves an OCI digest, so the parenthesis names a
third check inside a resolved item's workflow. The decision knows the correct form
and uses it two paragraphs earlier for R19: "This is a downstream implication for
R19, not a `CONFLICT:` — R19 anticipated it and R44 consumes no registered
parameter." *What resolves it:* one sentence giving R34 the same treatment, or
dropping the parenthetical attribution and leaving the trigger a re-verify
condition without a named host. *Why non-blocking:* no registered parameter moves,
R44 consumes nothing from R34, and check 1c is already stated as the bump signal
independently of where it runs.

**JF-4 (non-blocking) — "verbatim" overstates the F193 carry-forward.** `## Engines`
reads:

> **Disposition: carried forward verbatim as a proposed Notes amendment, applied
> to nothing here.**

The principle and proposed-change clauses are carried essentially unchanged
(`raw/opus.md:297` reads "editor extension set", the decision "editor-extension
set"), but the evidence clause is rewritten rather than copied: the three shared
extension ids are reordered, the executed-check citations `(check 7b, executed)`
and `(check 1f, executed)` are added, and the phrase "withheld from a container
contributor for no recorded reason" is new. *What resolves it:* "carried forward
with its principle and proposed-change clauses unchanged and its evidence
re-executed here". *Why non-blocking:* the rewrite strengthens the finding rather
than altering it, the decision separately and accurately says "Its evidence was
re-executed", and the amendment is still applied to nothing, which is the
disposition the runbook requires.

**Checked and left, so they are not re-litigated.**

1. **"Codex's decisive gate is a category error" is a fair characterisation.**
   Codex's sentence opens with "It also fails", and its `### Excluded by gate`
   marks the installer defect "More importantly", which invites the objection that
   host validation is not Codex's decisive ground. Against that: Codex never
   evaluated an image-only devcontainers image at all — its third bin is the Docker
   Official `rust:<release>-bookworm` image — and the host-validation ground is the
   only one Codex applies to *both* containerised bins, while the installer defect
   reaches the feature bin alone. Codex's `### Dominant choice` leads with "It is
   the smallest design that proves both owner-fixed operating systems". The
   decision also quotes the sentence in full, so the reader sees the "also" and can
   weigh it. No change owed.
2. **The CRLF failure mechanism in P03 item 6 is imprecise but its conclusion
   holds.** The item says a CRLF checkout "makes `#!/bin/sh\r` fail inside the
   container", while `devcontainer.json` invokes the file as
   `sh .devcontainer/post-create.sh`, where the shebang is a comment and is never
   consulted. CRLF still breaks the script — `set -eu\r` and `make bootstrap\r`
   carry the CR into a word — and the declared mode `0755` admits direct
   invocation, where the shebang does bite. The instruction to P03 ("`post-create.sh`
   must be LF") is right either way.
3. **The trailing `// 2.1.1-trixie` comment is redundant here in a way R20's is
   not.** R20's `# vX.Y.Z` exists because a 40-hex SHA displaces the tag entirely;
   the recommended OCI reference is `…:2.1.1-trixie@sha256:…`, so the readable
   identity is already in the value. Harmless, consistent with the stated
   principle, and acceptance criterion 5 enforces the comment rather than the
   redundancy.
4. **The star-count pair in disagreement 4 carries no per-site endpoint.** Both
   raws give `GET https://api.github.com/repos/<o>/<r>` with their retrieval dates,
   the decision states the one-day gap as the cause, and it correctly notes that no
   argument turns on a star count.
5. **R42's unresolved `cargo binstall` integrity tradeoff travels into the
   container.** `just setup` is the same recipe a native contributor runs, so the
   container neither improves nor worsens that posture. R44 correctly declines to
   settle another item's open owner ask, and its own gate-3 substitute is scoped to
   the devcontainer's rustup acquisition, where it belongs.

## Assessment

**Verdict: approve.** The recommendation follows from the evidence as written. The
image-only shape is selected on a structural ground — C's configurability is this
repository's anti-pattern under R42 layer 1 and layer 3 — and is confirmed by two
independently executed facts (the integrity asymmetry at checks 5a and 5d, the
version-resolution defect at checks 5b and 5c) rather than by popularity or by
repository agreement. Codex's `BASELINE-REVIEW: F200` is declined on four stated
grounds, the first of which I verified quotation by quotation against
`raw/codex.md`. All four engine disagreements are settled on grounds: disagreement
1 on the four grounds above, disagreement 2 by giving each `BASELINE-REVIEW` line
its own disposition and its own ledger row, disagreement 3 by showing the two
faults compose rather than compete, and disagreement 4 by showing the differing
figures carry no argument. The four `- assumes` lines are byte-identical to
`docs/port/PARAMETERS.md` rows 7–10 by mechanical `diff`, the `## Parameters`
grammar is the value-only form, and the H2 set matches `research/RUNBOOK.md` §5.
The 53/53 tally, its per-section split, and the 23/8/0 named-skip control are all
stated within what the two logs show. Every "rot" statement is labelled as carried
at every site, and the unproven rows are honest — including the ones that weaken
the recommendation, such as the untimed cold pull and the unobserved volume
behaviour.

**The four findings are non-blocking and `unresolved-findings` is `none`.** JF-1
and JF-4 are precision defects in how two carried artifacts are described; JF-2
labels an inference that is sound and cited at its point of use; JF-3 is a missing
downstream-implication sentence for an item this decision consumes nothing from.
None touches the selected architecture, the image, the digest, the mount, the
`postCreate` chain, the runner-up, or the condition under which the runner-up
wins. **The recommendation would not move under any finding**, and the ledger
dispositions would not change.

**The owner-facing question is visible as a cost, not buried.** A digest that
nothing bumps is named the single real cost in `## Decision`, repeated in
Tradeoffs, made the runner-up's winning condition, and given a manual bump signal
in the re-verify trigger, with checks 4a and 4b establishing that Dependabot's
`devcontainers` ecosystem parses features only and that the pull request which
would have changed that is closed. The owner can take the runner-up on the
decision's own text without further research, which is what a decision at medium
confidence on its central call owes.

**Acceptance is not complete on this audit alone.** `review/audit-codex.md` does
not exist; the empirical audit, including the rerun of `r44-claims.sh`, is
deferred while the Codex account is out of usage. `research/RUNBOOK.md` §5 requires
two approving verdicts with no unresolved findings before R44 may be `resolved`.
