# R14 — Large-file guard strategy (bundle) — raw report

Actor: `research-muse-2026-09-26T190144Z-53ff8e94fbd8`. Engine: Muse (Meta).
Item kind: `bundle`. Tier: focused. Retrieval date for every figure and
checked-out read below: **2026-09-26**, unless a line says otherwise.

**Status.** This is a research proposal, not a built template. The pinned
precedent reads, the reference-script behavior matrix, `shellcheck`, the
`git diff -z` pipeline probe, and `actionlint` below were executed on
2026-09-26 on macOS 15 / aarch64. No template workflow ran on a hosted
runner and no hook manager ran end to end, because the template has not
been built and R37 (`hook-manager-distribution`) is still open. This
session does not expose a more specific model snapshot than the engine
family recorded above.

### Landscape

The category this item decides is *accidental-large-blob prevention*: a
size gate that stops an unintended big file from reaching the default
branch, enforced at a fast local tier (git hook, before the commit
exists) and a non-bypassable server tier (CI, before the merge). No
candidate is a Rust crate: the enforcement points are a hook-manager job
and a GitHub Actions workflow, both running POSIX shell over `git` and
`wc`. Therefore crates.io 90-day/all-time downloads, last-release,
RustSec advisories, Cargo dependency-tree MSRV, `unsafe` posture,
default features, async-runtime coupling, binary size, and Cargo
compile-time figures are **inapplicable** to every candidate; the
applicable costs are contributor friction (false rejects), late catches
(CI round-trip), maintenance (two definitions drifting apart), and the
one-time cost of a blob that escapes into history. [S1] [S2] [P1] [P2]

| Bin | Candidates found | Fit observation |
|---|---|---|
| Built-in or first-party toolchain | `git diff --diff-filter=A` added-file enumeration; `wc -c` byte size; GitHub Actions `jobs`, `permissions`, `concurrency`, `actions/checkout` with `fetch-depth: 0`; hook-manager `{staged_files}` substitution (R37 owns which manager) | All enforcement in both siblings is composed from exactly these primitives; nothing else is required. No git config key gates commit size (`core.bigFileThreshold` tunes diff performance only, it rejects nothing), so a hook or workflow must do the rejecting. [P1] [P2] [S3] |
| Established industry standard | `pre-commit`'s `check-added-large-files` hook (the intent ts's hook cites by name); lefthook `{staged_files}` shell jobs; a dedicated CI diff-scan workflow (py's `large-file-guard.yml`) | `pre-commit/pre-commit` is active and widely adopted (15,595 stars, `archived: false`, `pushed_at: 2026-08-17T23:37:08Z`, via `GET https://api.github.com/repos/pre-commit/pre-commit`, 2026-09-26); `evilmartians/lefthook` likewise (8,856 stars, `pushed_at: 2026-09-24T07:39:26Z`, same endpoint). Both siblings' hooks are hand-rolled shells in this idiom, not the pre-commit framework itself. [G1] [G2] [P1] [P2] |
| Up-and-comer | No additional candidate shortlisted | Git LFS and server-side push rules change the storage or hosting model rather than gating accidental commits in a template, and were considered as architectural alternatives instead (see `### Principles and implementation`). |

**Authority.** The git CLI as executed locally is the primary authority
for diff enumeration and size measurement (probes 1–9 executed; outputs
under `### Validation strategy`). The two pinned sibling checkouts are
the practice authorities for the inherited shapes: py at
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` and ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, both read from local Git
objects on 2026-09-26. `actionlint` 1.7.12 is the authority for workflow
syntax (executed). GitHub Docs pages for Actions semantics and for
repository push limits are background only in this leg: page bodies were
**not** re-fetched (this leg's network was limited to the prompt's named
API endpoints), so any claim resting only on them is flagged below and
is a re-verification item for synthesis, not an executed check.

| Precedent surveyed | Why it is relevant and well regarded | Observed practice | Transfer limit |
|---|---|---|---|
| py `large-file-guard.yml` + `large-files` hook at `b08bccf` | Sibling template; the maintained two-tier design with an explicit round-3 decision comment (ITM-028) | CI rejects added files over 1,048,576 bytes outside `docs/assets/`; hook rejects staged files over the same threshold with the same exemption; same value in both tiers by stated intent ("Same 1 MB threshold + allowlist as CI"). [P1] | CI file pins a self-hosted-runner variable (`vars.RUNNER_UBUNTU`) that R09 owns; the shape transfers, the runner expression does not. |
| ts `check-large-files` hook at `cb1cbcb`, no CI guard | Sibling template; the divergent one-tier design | Hook rejects staged files over 512,000 bytes with no path exemption; no workflow mentions "large" anywhere in ts CI at the pin. The hook comment cites "`pre-commit`'s `check-added-large-files` intent". [P2] | ts's D-020(6) explains why hook duties exist, not the 500 KB value or the dropped exemption, so neither transfers as a reasoned choice. |

The pinned precedents genuinely diverge on all three axes this item
owns: tier count (two vs one), threshold (1,048,576 vs 512,000 bytes),
and exemption (`docs/assets/` allowlist vs none). Neither proves Rust
fitness by itself. [P1] [P2]

No third-party Rust-project workflow survey was run in this leg (page
fetches beyond the named API endpoints were out of scope for this
worker); practice evidence here is the two sibling precedents plus the
hook-framework adoption figures above. Recorded as gap G1 under
`### Confidence & re-verify trigger`.

### Principles and implementation

**The shared requirement.** *No accidental large blob reaches the
default branch: a fast local check catches it before the commit exists,
and a non-bypassable server check catches whatever evades the local
one, at one shared size value with one shared exemption rule.* Source:
ledger rows F043 (`docs/port/COMMONALITY.md:49`, CI tier) and F172
(`docs/port/COMMONALITY.md:176`, hook tier), realized in py by the two
artifacts read at the pin and half-realized in ts. [P1] [P2] [L1]

**Source and agreement level.** `docs/port/DIVERGENCE-ANALYSIS.md:96-98`
classes R14 `D+A (mixed)`, `harmonize: partly`, with both sub-rows
`harmonize: yes`: F043 asks "does Rust need CI-level redundancy on top
of a pre-commit hook, or is the hook alone sufficient for all three
repos?" and F172 asks for "one threshold value (and whether to exempt
an assets path) for all three repos". Both answers are therefore
**capability/standard — must agree across py, ts, rs**. What may vary is
the *mechanism*: which hook manager runs the local half (R37's, per-repo
decision) and the exact shell spelling. No shared low-level mechanism
beyond "POSIX shell over `git`/`wc`" is recommended, and no per-ecosystem
threshold split is justified: nothing about Rust changes the tradeoff
between catching a blob early and the cost of a false reject. [L2]

| Principle | Agreement level | Essential behavior | Observable acceptance criterion |
|---|---|---|---|
| Early catch is cheap, late catch is certain | Capability/standard | A hook-tier check rejects oversize staged files locally; a CI-tier check rejects oversize added files on the server. | Staging a 2 MB file outside the exemption fails the hook; pushing the same file with `--no-verify` fails the CI check. |
| One value, both tiers, all repos | Standard | Threshold and exemption are defined once and referenced by both tiers. | Changing the threshold requires editing exactly one definition; hook and CI report the same limit. |
| Intentional assets have a home | Policy | Large binary docs assets are committable under exactly one exempt prefix. | A 2 MB PNG under `docs/assets/` passes both tiers; the same bytes under `src/` fail both. |
| Only additions are gated | Policy | The CI tier inspects added files (`--diff-filter=A`), never the whole tree. | A PR that touches no large file passes even if history contains one; growing an existing file past the limit is out of scope for this gate. |

**Architectural alternatives compared before any threshold was chosen.**

| Alternative | What it is | Why it was or was not chosen |
|---|---|---|
| A. Hook tier only (ts status quo) | Local reject, no CI backstop | Fails the "non-bypassable" half: `--no-verify`, `git commit` in an environment where hooks were never installed, and web-UI edits all skip it. ts records no reason for omitting the server tier. Rejected. [P2] |
| B. CI tier only | Server reject, no local check | Certain but late: every accidental blob costs a push, a workflow run, and a history rewrite to fix. The local half costs one shell job and saves that round-trip. Rejected as the sole tier. |
| C. Both tiers, shared definition | py's shape plus a single source of truth | **Chosen.** Fast feedback plus a backstop that cannot be skipped; one script holds the value so the tiers cannot drift. Executed end to end in this leg (probes 1–9). |
| D. Server-side push rules / GitHub push protection | Hosting-level file-size rule | Depends on repository settings outside the template's files; unenforceable in a clone and invisible to branch protection as a named check. Complements C but cannot replace it in a template. Rejected as the mechanism. |
| E. Git LFS with a tracked-pattern policy | Large files stored out of band | Changes the storage model for every clone (client install, pointer files, bandwidth accounting) to solve an accident-prevention problem. No sibling uses it; disproportionate. Rejected. |

**Threshold: 1 MiB (1,048,576 bytes) in both tiers.** Four reasons, in
order of weight. First, it is py's maintained value with a stated
design: ITM-028 round 3 chose "Custom shell step", "Threshold: 1 MB.
Allowlist: `docs/assets/` only", and the hook comment declares the
two-tier value match deliberate. Second, ts's 500 KB coincides with
`pre-commit`'s generic default but ts records no rationale for adopting
that default over py's 1 MB and none for dropping the exemption, so the
divergence reads as accidental drift (class A), not a reasoned
tightening. Third, Rust fit: `target/` is gitignored build output under
R49's accepted `build-tool-output-shape` (artifacts land in `target/`,
relocated or ignored, never committed), so committed-file sizes are
driven by source, docs, and test fixtures exactly as in the siblings —
and a template's fixtures deserve headroom over a generic hook default.
Fourth, one value in both tiers and (per the harmonize-yes ruling) all
three repos removes the drift this item exists to kill. [P1] [P2] [L2]
[L3]

**Exemption: the `docs/assets/` prefix in both tiers.** R81's accepted
`docs-delivery-model` ships one `docs/` corpus rendered in place plus an
`mdbook`-built Pages site, so binary assets (screenshots, diagrams) have
a natural committed home and it sits under `docs/`; py's
`docs/assets/` prefix names exactly that home. ts's no-exemption stance
has no recorded reason and would force every screenshot through the
threshold. R81 does not itself name an assets subdirectory, so P03 must
create `docs/assets/` as the conventional home — recorded as
dependency D1, not assumed. [P1] [L4]

**Single source of truth (LOW question).** Independent per-tier tuning
is not acceptable: it is precisely how ts drifted (500 KB vs 1 MB, no
stated reason). The threshold and exemption live as two constants in one
checked-in script, `scripts/check-large-files.sh`, overridable by
environment (`LARGE_FILE_THRESHOLD_BYTES`,
`LARGE_FILE_ALLOWLIST_PREFIX`) for tests; the hook tier calls it with
staged paths as argv and the CI tier pipes `git diff --name-only -z
--diff-filter=A` into its `--stdin0` mode. The NUL-delimited CI path
also fixes a latent defect in py's loop (`for FILE in ${ADDED}`
word-splits on spaces, so `src/new big.dat` is mis-scanned); probe 8
shows the spaced name handled correctly. This improvement is folded
into the recommendation, not filed as a baseline challenge: it changes
no ledger row's requirement. [P1]

**Cross-repo adjudication (HIGH question, owner clarification
2026-09-04).** Changes to py and ts are a follow-on project; this is
their rationale. F043: ts's missing CI tier is a one-sided omission
(class D) with no recorded reason — ts should gain a CI-tier backstop
at the shared value. F172: ts's 500 KB-with-no-exemption is value drift
(class A) with no recorded reason — ts should adopt 1 MiB plus the
`docs/assets/` exemption. py is unchanged: its two-tier, one-value,
exempted-assets design is the shape the evidence supports for all
three. The hook-manager mechanism stays per-repo under R37. [P1] [P2]
[L2]

**BASELINE-REVIEW finding.** None. F043 and F172 as written ("CI-level
redundancy question, distinct tier" and "bundle, decided together")
describe the guard tiers accurately; this answer fills their values
without challenging any row, and it changes no other item and no ledger
text. [L1]

**Minimal realistic example and its acceptance check.** The example is
the shared script plus one workflow plus one hook job, reproduced under
`### Validation strategy`. Executed in this leg: the script's 7-case
behavior matrix (pass / fail / exempt / missing / empty / mixed NUL
input / exact-boundary), the `git diff -z` end-to-end pipeline with a
spaced filename, the all-zeros base-SHA skip branch, `shellcheck`, and
`actionlint` on the workflow — all green. Proposed for P03 (not
executed): a hosted run proving the workflow fails a `--no-verify`
push, and a hook-manager run proving the staged-file path fails before
commit.

### Recommendation

**One stack: keep both tiers at one shared value — reject files over
1,048,576 bytes (1 MiB) outside `docs/assets/`, enforced by a single
checked-in POSIX-bash script called from a dedicated CI workflow and
from the R37-selected hook manager's staged-file job.**

1. **Shared definition** — `scripts/check-large-files.sh` holds
   `THRESHOLD_BYTES=1048576` and `ALLOWLIST_PREFIX=docs/assets/` (env
   overridable); argv mode for hooks, `--stdin0` mode for CI.
2. **CI tier (F043)** — `.github/workflows/large-file-guard.yml`: one
   `ubuntu-latest` job on `pull_request` and `push` to `main`,
   `fetch-depth: 0`, all-zeros/empty base-SHA skip, `git diff
   --name-only -z --diff-filter=A BASE...HEAD` piped to the script.
   Zero Rust compiles; no second runner (per R11, a workflow that
   compiles no Rust lands on `ubuntu-latest`).
3. **Hook tier (F172)** — one staged-file job in R37's hook
   configuration invoking the same script with the staged paths; no
   separate threshold or exemption text at the call site.
4. **ts follow-on (not this template)** — add the CI tier and adopt 1
   MiB plus the exemption; py unchanged.

### Members

#### CI-tier large-file backstop (F043)

##### Landscape

This member is a pattern (a workflow plus a shell script), not a crate.
Crate downloads, release, RustSec, dependency-tree MSRV, `unsafe`,
default features, async coupling, binary size, and Cargo compile metrics
are inapplicable. The candidates are: a dedicated diff-scan workflow
(py's shape); a step inside R11's `ci.yml` hygiene job; no CI tier (ts
status quo); and hosting-level push rules. [P1] [P2] [L5]

##### Principles and implementation

The server tier exists for exactly one property the hook tier cannot
provide: non-bypassability. It inspects added files on the merge
candidate (`--diff-filter=A` over `BASE...HEAD`) so a contributor who
passes `--no-verify`, commits where hooks were never installed, or edits
in the web UI still meets the gate. It must run on both `pull_request`
and `push` to `main` (direct pushes and merge queues need the same
backstop), skip cleanly when there is no base (first push, all-zeros
SHA), and cost no Rust compile — checkout plus `git diff` plus one
script. The dedicated-file shape follows py and matches the R17
precedent (a dedicated `secret-scan.yml` alongside R11's `ci.yml`);
a hygiene-step placement would be functionally equivalent, and the
recommendation below says why the dedicated file wins. [P1] [L5]

##### Dominant choice

A dedicated `.github/workflows/large-file-guard.yml` (py's file,
hardened): one `ubuntu-latest` job, `permissions: {}` at workflow level
with `contents: read` on the job, `concurrency` keyed on `github.ref`
with `cancel-in-progress: true`, `actions/checkout` with `fetch-depth:
0`, and a `shell: bash` step running the NUL-delimited pipeline into
the shared script. The workflow in `### Validation strategy` is this
choice verbatim; `actionlint` passes. [P1]

##### Qualified shortlist

| Candidate | Pattern figures and maintenance | Production evidence | Trade-off |
|---|---|---|---|
| Dedicated diff-scan workflow (py shape, NUL-hardened) | No crate figures apply; one YAML file plus the shared script; shellcheck + actionlint enforceable | py at `b08bccf` runs this in production; R17's accepted `secret-scan.yml` proves the dedicated-file pattern composes with R11. [P1] | One more workflow file to list as a required check. |
| Step of R11's `hygiene` job in `ci.yml` | Same script; no new file | R11's rule slots non-compiling checks into `hygiene` by default. [L5] | Couples the guard's required-check identity to the hygiene job; a docs-assets-only failure reads as a hygiene failure. |
| ts status quo: no CI tier | Zero code | ts at `cb1cbcb`. [P2] | Bypassable by construction; kept only as the rejected baseline. |

##### Excluded by gate

No candidate fails a license, MSRV, RustSec, `unsafe`, binary-size, or
compile crate gate because there is no crate. Hosting-level push rules
are excluded by **template fit**: they live in repository settings, not
in template files, so a clone does not inherit them and branch
protection cannot name them as a check. The ts no-CI-tier status quo is
excluded by **principle fit**: it cannot satisfy the non-bypassable
acceptance criterion. [P2]

##### Up-and-comers

None shortlisted. Reusable-workflow or composite-action packaging of the
guard could reduce YAML duplication later, but the guard is one step
calling one script — there is no duplication left to package.

##### Fit for this template

**CLI:** nothing to fit — the guard sees files, not targets. **Library:**
same; fixture blobs over 1 MiB outside `docs/assets/` are exactly what
should fail loudly. **Web:** the `web` feature adds source and tests,
not large binaries; no exemption beyond `docs/assets/` is needed. The
`ubuntu-latest`-only runner follows R11 (no Rust compiled) and keeps
the backstop cheap on every PR. [L3] [L5]

##### Recommendation

Ship the dedicated `.github/workflows/large-file-guard.yml` as written
under `### Validation strategy`, calling
`scripts/check-large-files.sh --stdin0`. Do not re-embed the threshold
or exemption in the YAML; do not widen to `macos-latest`.

##### Ranked runner-up

A `large-file-guard` step inside R11's `hygiene` job, running the same
script over the same diff. It wins only if the owner prefers fewer
workflow files over a separately requireable check identity. Same
threshold, same exemption, same script either way.

##### Tradeoffs

The dedicated file costs one workflow in the required-checks list and
one checkout per PR/push; it gains an independent, self-describing
status (`reject-files-over-1mb`), push-to-main coverage without
touching `ci.yml`'s gating logic, and a byte-for-byte lineage to py's
maintained guard. The hygiene-step alternative saves the file at the
cost of a shared check identity. The NUL pipeline costs one flag
(`-z`/`--stdin0`) over py's loop and fixes spaced filenames. [P1]

##### Parameters

This member implements the top-level recommendation; it owns and
consumes no registry parameter. It is constrained by the owner-fixed
toolchain values (edition 2024, MSRV policy, `ubuntu-latest,
macos-latest`, `MIT OR Apache-2.0`), which the shell/git tooling
satisfies trivially, and it places its runner per R11's accepted
`ci-job-structure` without consuming that value as an input.

##### Migration implications

Add `.github/workflows/large-file-guard.yml` (one job, triggers
`pull_request` plus `push: branches: [main]`, `ubuntu-latest`) and
`scripts/check-large-files.sh` (the shared definition). List the
`reject-files-over-1mb` job in branch protection / R12's aggregate
inputs. Do not add a `macos-latest` leg, a matrix, or a cache step.

##### Validation strategy

Executed in this leg (outputs condensed; full log under top-level
`### Validation strategy`): `actionlint` 1.7.12 on the workflow (no
diagnostics); probes 6, 8, 9 proving the `--stdin0` mode, the
spaced-filename `git diff -z` pipeline, and the base-SHA skip branch;
`shellcheck` clean on the script. Proposed for P03: push a PR adding a
2 MB file outside `docs/assets/` with hooks bypassed and assert the
workflow fails naming the file; push a docs-assets-only large PNG and
assert it passes; push to `main` directly in a scratch clone and assert
the guard still runs.

##### Confidence & re-verify trigger

High confidence on keeping the tier and the dedicated-file shape (two
maintained precedents: py's guard and R17's `secret-scan.yml` pattern).
Medium on the exact YAML details (checkout major version, credential
persistence default) — re-verify against R20's pinning policy and the
then-current `actions/checkout` major at implementation. Re-run this
member if GitHub changes diff-range semantics on `pull_request`, if R12
redefines how standalone workflows join the required set, or by
2027-03-26. [P1] [L5]

##### Sources

py precedent at pin: [P1]. ts absence at pin: [P2]. R11 accepted
structure: [L5]. R17 dedicated-workflow precedent: [L6]. Hook-framework
adoption: [G1] [G2]. Executed probes: top-level `### Validation
strategy`.

#### Hook-tier staged-file guard (F172)

##### Landscape

This member is a pattern (one hook-manager job calling the shared
script), not a crate. Crate figures are inapplicable for the same
reason as the CI member. The candidates are: a `{staged_files}` shell
job at 1 MiB with the `docs/assets/` exemption (py's shape); the same
job at 500 KB with no exemption (ts's shape); `pre-commit`'s
`check-added-large-files` (default 500 KB cap) as a managed hook; and no
hook tier. Which manager executes the job is R37's decision, not this
member's. [P1] [P2] [G1]

##### Principles and implementation

The hook tier exists for speed: it rejects the blob before the commit
object exists, saving the push–CI–rewrite round-trip. It inspects
staged paths (the merge candidate's future content at zero diff cost),
skips missing paths (a file staged then removed), skips the exempt
prefix, and reports every oversize file with its byte size and the
remedy. Sharing the script with the CI tier is what makes the two
halves one guard: the hook call site carries no threshold or exemption
text, so the values cannot drift. Filenames with spaces depend on the
manager's substitution quoting (lefthook joins `{staged_files}` with
spaces, as in both siblings); the script itself is argv-safe, and the
residual manager-quoting limit is shared with py and ts, not introduced
here. [P1] [P2]

##### Dominant choice

One staged-file job in R37's hook configuration, shaped after py's
`large-files` job but delegating to the shared script instead of
inlining the loop:

~~~text
large-files:
  run: bash scripts/check-large-files.sh {staged_files}
~~~

(Spelling adapts to whichever manager R37 selects; the constant is that
the call site names no byte value and no path.) Threshold 1,048,576
bytes, exemption `docs/assets/`, inherited from the script. [P1]

##### Qualified shortlist

| Candidate | Pattern figures and maintenance | Production evidence | Trade-off |
|---|---|---|---|
| `{staged_files}` job calling the shared script at 1 MiB + exemption | No crate figures apply; one job stanza; values maintained once | py's inlined 1 MB job at `b08bccf` is the maintained behavioral reference. [P1] | Depends on R37's manager supporting argv substitution (both finalists do). |
| ts shape: inlined 500 KB job, no exemption | Same mechanics, stricter cap | ts at `cb1cbcb`. [P2] | No recorded rationale for the value or the missing exemption; rejects legitimate docs assets. |
| `pre-commit` `check-added-large-files` managed hook | Upstream-maintained hook; default cap 500 KB | `pre-commit/pre-commit`, 15,595 stars, active. [G1] | Adopts the pre-commit framework for one check and inherits its 500 KB default; the siblings rejected framework coupling for this check. |

##### Excluded by gate

No crate gate applies. The managed-`pre-commit`-hook candidate is
excluded by **template fit**: both siblings run this check as a
dependency-free shell job inside their chosen manager, and R37 owns the
manager decision — this item may not smuggle in a second hook
framework. No hook tier at all is excluded by **principle fit**: without
it every accident costs a server round-trip. [P1] [P2] [G1]

##### Up-and-comers

None shortlisted. A manager-native size filter (glob by byte size)
would remove the shell entirely, but neither sibling's manager offers
one and R37 is open; if R37 selects a manager with that feature, the
job stanza shrinks but the shared value must still come from one
definition.

##### Fit for this template

**CLI / library / web:** identical to the CI member — the guard sees
staged paths, and the template's committed profile (source, docs,
fixtures; `target/` ignored per R49) is what the 1 MiB value is sized
for. The hook fires on every commit on every contributor machine
including macOS, so the script must stay POSIX-bash with no GNU-only
flags — as written and as executed (`read -d ''`, `wc -c`, `tr` are all
present on both fixed runners' shells). [L3]

##### Recommendation

Ship one staged-file job calling `bash
scripts/check-large-files.sh {staged_files}` (manager spelling per
R37), with no threshold or exemption text at the call site. Do not
adopt ts's 500 KB value or its missing exemption.

##### Ranked runner-up

The ts value pair repaired: 500 KB **with** the `docs/assets/`
exemption. It wins only if P03 implementation experience shows 1 MiB
lets real accidents through in this template's fixture profile —
unobserved in either sibling. Changing it is a one-constant edit in the
shared script, which is the point of the single source of truth.

##### Tradeoffs

Calling the shared script costs one file lookup per commit versus an
inlined loop and gains drift-proofing: the failure mode it removes (ts's
silent 500 KB / no-exemption split) is observed, not hypothetical. The
1 MiB value over 500 KB trades a small amount of strictness for fixture
headroom and sibling agreement; the exemption trades a narrow, auditable
hole (`docs/assets/`, visible in review) for a usable home for binary
docs assets. [P1] [P2]

##### Parameters

Same as the CI member: this member owns and consumes no registry
parameter. It assumes only that R37's selected manager can run a shell
command over staged paths — the prompt's stated assumption, recorded
here, not decided here.

##### Migration implications

Add one job stanza to R37's hook configuration file invoking the shared
script over staged files. Add no second threshold constant, no second
exemption list, and no new hook framework. If R37 selects lefthook, the
stanza mirrors py's `large-files` job with the loop body replaced by
the script call. Do not touch R40's hygiene checks. [P1]

##### Validation strategy

Executed in this leg: probes 1–5 and 7 (argv-mode pass / fail / exempt
/ missing / empty / exact-boundary 1,048,576) against the script the
hook will call — the hook's entire logic surface. Not executed (blocked
on R37 + P03): a real commit through the selected manager proving the
`{staged_files}` substitution reaches the script and a 2 MB staged file
fails before the commit object exists. Proposed P03 hook cases: oversize
staged file fails with the filename in the message; exempt-asset commit
passes; `--no-verify` commit succeeds locally and fails in CI (the
two-tier contract).

##### Confidence & re-verify trigger

High confidence on keeping the tier, the 1 MiB value, and the exemption
(py's maintained, commented design; ts's divergence unexplained). Medium
on the call-site spelling, which must be re-fit to R37's manager once
selected. Re-run this member if R37 selects a manager without staged-path
substitution, if R81 revises the docs tree so `docs/assets/` is no
longer the natural asset home, or by 2027-03-26. [P1] [L4]

##### Sources

py hook at pin: [P1]. ts hook at pin: [P2]. `pre-commit` adoption:
[G1]. R49 build-output shape: [L3]. R81 docs model: [L4]. Executed
probes: top-level `### Validation strategy`.

### Compatibility

No Cargo version matrix applies because no member is a Rust crate. The
compatibility proof is that both members execute the same script bytes.

| Producer | Consumer | Contract | Proof status |
|---|---|---|---|
| `scripts/check-large-files.sh` | CI workflow (`--stdin0` mode) | Exit 0 + `PASS` line when no added file exceeds 1,048,576 bytes outside `docs/assets/`; exit 1 naming every violator otherwise. | Executed: probes 6, 8, 9. |
| Same script | Hook job (argv mode) | Same exit contract over staged paths. | Executed: probes 1–5, 7. |
| CI tier | Hook tier | Same threshold and exemption, because both read the script's two constants. | Structural: the values exist in exactly one file; verified by inspection of the script in `### Validation strategy`. |
| This item | R37 hook config | The hook job needs staged-path argv substitution from R37's manager. | Assumed per the prompt; R37 open — re-fit spelling at implementation. |
| This item | R12 required checks | `reject-files-over-1mb` is available as a named required check. | Deferred to R12; this item only names the job. |
| This item | R81 docs tree | Exempt prefix `docs/assets/` must exist as the asset home. | R81 names `docs/` but no assets subdir — P03 creates it (D1). |

### Parameters

This item owns no parameter and consumes none (prompt `## Couplings`:
`owns:` empty, `consumes:` empty), so there are no `owns` or `assumes`
lines and no `CONFLICT:` lines. The recommendation is constrained by
the owner-fixed toolchain values — `rust-edition = 2024`, `msrv-policy
= stable minus 2 minor versions, raised only in a minor release,
declared as rust-version in Cargo.toml and tested in CI`,
`target-os-matrix = ubuntu-latest, macos-latest`, `license = MIT OR
Apache-2.0` — which need no `assumes` lines because nothing is
consumed; POSIX `bash`/`git`/`wc` satisfy all four trivially. Placement
notes under `### Members` reference R11's accepted `ci-job-structure`,
R49's `build-tool-output-shape`, and R81's `docs-delivery-model` as
read-only context, not as consumed inputs.

### Migration implications

- Add `scripts/check-large-files.sh` (the shared definition: 1,048,576
  bytes, `docs/assets/` exemption, argv + `--stdin0` modes, executable
  bit set).
- Add `.github/workflows/large-file-guard.yml` (one `ubuntu-latest`
  job, `pull_request` + `push: branches: [main]`, `fetch-depth: 0`,
  base-SHA skip, NUL pipeline into the script).
- Add one staged-file job to R37's hook configuration calling the same
  script; carry no threshold or exemption text at the call site.
- Create `docs/assets/` (with a `.gitkeep` or the first asset) as the
  exempt home when P03 builds the R81 docs tree.
- List `reject-files-over-1mb` as a required check (R12's mechanism).
- Do not add a `macos-latest` CI leg, a matrix, a cache step, a second
  hook framework, or any threshold/exemption text outside the script.

### Validation strategy

Executed read-only on 2026-09-26 except for scratch files under
`/tmp/lfguard` (outside the repo; the reference script below is
proposed for `scripts/`, not yet added). They prove script behavior,
pipeline wiring, and workflow syntax — not hosted execution, hook-manager
substitution, or cross-OS runs.

**Reference script** (the artifact under test; `shellcheck -S warning`
clean):

~~~text
#!/usr/bin/env bash
set -euo pipefail
THRESHOLD_BYTES="${LARGE_FILE_THRESHOLD_BYTES:-1048576}"  # 1 MiB
ALLOWLIST_PREFIX="${LARGE_FILE_ALLOWLIST_PREFIX:-docs/assets/}"
READ_STDIN0=0
if [ "${1:-}" = "--stdin0" ]; then READ_STDIN0=1; shift; fi
FAILED=0
check_one() {
  f="$1"
  case "$f" in "$ALLOWLIST_PREFIX"*) return 0 ;; esac
  [ -f "$f" ] || return 0
  size=$(wc -c <"$f" | tr -d ' ')
  if [ "$size" -gt "$THRESHOLD_BYTES" ]; then
    echo "FAIL: $f is $size bytes (>${THRESHOLD_BYTES}); not under ${ALLOWLIST_PREFIX}"
    FAILED=1
  fi
}
if [ "$READ_STDIN0" -eq 1 ]; then
  while IFS= read -r -d '' f; do check_one "$f"; done
else
  for f in "$@"; do check_one "$f"; done
fi
if [ "$FAILED" -ne 0 ]; then
  echo ""
  echo "Add the file under ${ALLOWLIST_PREFIX} if it is intentional, or remove it."
  exit 1
fi
echo "PASS: no files over ${THRESHOLD_BYTES} bytes outside ${ALLOWLIST_PREFIX}"
~~~

**Behavior matrix** (scratch repo `/tmp/lfguard/t`; `S` = the script):

~~~text
$ S src/small.rs            # 100 bytes            -> PASS, exit 0
$ S src/big.bin             # 1,048,577 bytes      -> FAIL naming src/big.bin, exit 1
$ S docs/assets/shot.png    # 2,097,152 bytes      -> PASS (exempt), exit 0
$ S src/nope.rs             # missing              -> PASS (skipped), exit 0
$ S                         # empty argv            -> PASS, exit 0
$ printf 'src/small.rs\0src/big.bin\0docs/assets/shot.png\0src/with space.rs\0' \
  | S --stdin0              # mixed NUL input      -> FAIL on src/big.bin only, exit 1
$ S src/edge.bin            # exactly 1,048,576    -> PASS (boundary is exclusive), exit 0
~~~

**End-to-end pipeline and skip branch:**

~~~text
$ git diff --name-only -z --diff-filter=A HEAD | S --stdin0
FAIL: src/new big.dat is 1048577 bytes (>1048576); not under docs/assets/
...exit 1   # spaced filename handled; py's `for FILE in ${ADDED}` loop mis-scans it
$ BASE_SHA=0000...; [ -z "${BASE_SHA}" ] || [ "${BASE_SHA}" = "0000..." ] \
  && echo "INFO: no base sha; skipping large-file guard"
INFO: no base sha; skipping large-file guard
~~~

**Proposed workflow** (`actionlint` 1.7.12: no diagnostics, exit 0):

~~~text
name: large-file-guard
on:
  push:
    branches: [main]
  pull_request:
permissions: {}
concurrency:
  group: large-file-guard-${{ github.ref }}
  cancel-in-progress: true
jobs:
  guard:
    name: reject-files-over-1mb
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0
          persist-credentials: false
      - name: Reject new files over 1 MB outside docs/assets/
        env:
          BASE_SHA: ${{ github.event.pull_request.base.sha || github.event.before }}
          HEAD_SHA: ${{ github.event.pull_request.head.sha || github.sha }}
        shell: bash
        run: |
          set -euo pipefail
          if [ -z "${BASE_SHA}" ] || [ "${BASE_SHA}" = "0000...0000" ]; then
            echo "INFO: no base sha; skipping large-file guard"
            exit 0
          fi
          git diff --name-only -z --diff-filter=A "${BASE_SHA}...${HEAD_SHA}" \
            | bash scripts/check-large-files.sh --stdin0
~~~

Notes: `actions/checkout@v6` is a placeholder major for the probe; the
final pin follows R20's policy at implementation. `persist-credentials:
false` matches least-privilege practice; py's file omits it.

**Planned P03 acceptance (not executed).** (1) Hosted workflow run: a PR
adding a 2 MB file outside `docs/assets/` pushed with `--no-verify`
fails `reject-files-over-1mb` naming the file; a docs-assets-only large
PNG passes; a direct push to `main` in a scratch clone still triggers
the guard. (2) Hook run through R37's manager: an oversize staged file
fails before commit; `--no-verify` succeeds locally and fails in CI.
(3) `shellcheck` and `actionlint` over the committed files in CI.

### Confidence & re-verify trigger

**Recommendation confidence: high** that both tiers are kept at one
shared value — py's maintained, commented two-tier design, ts's
unexplained divergence on all three axes, and the executed behavior
matrix agree, and the harmonize-yes ruling assigns both sub-questions
one value for all three repos. **Medium** on 1 MiB over 500 KB as that
value: the evidence is precedent coherence plus fixture headroom, not a
measured Rust fixture-size distribution. **Medium** on workflow details
(checkout major, credential persistence) and on the hook call-site
spelling, both blocked on R20/R37.

Re-run R14 when R37 publishes a manager (re-fit the hook stanza), when
R12 defines standalone-workflow aggregation, when R20's pinning policy
meets the checkout major, when R81 revises the docs tree away from a
`docs/assets/` home, or by 2027-03-26.

Open gaps: (G1) no third-party Rust-project workflow survey in this leg
— synthesis should weigh the sibling evidence against the other engine's
survey if it has one; (G2) GitHub Docs background claims (Actions
semantics, hosting push limits) were cited, not re-fetched, under this
leg's API-endpoints-only network scope; (G3) no hosted workflow run, no
hook-manager run, no macOS execution of the script; (D1) R81 names no
assets subdirectory, so P03 must establish `docs/assets/`. G3/D1 are
implementation gates, not evidence failures.

### Sources

All retrievals and checkout reads below are dated **2026-09-26**.

- **[P1] py precedent at pin `b08bccf`** — read from local Git objects:
  `git -C /Users/stevemorin/c/py-launch-blueprint show
  b08bccfb55d05f15e46a83b52c5660b1881d19f5:.github/workflows/large-file-guard.yml`
  (full file) and `...:lefthook.yml` lines 130–160 (`large-files` job:
  threshold `1048576`, exemption `docs/assets/*`). Authority: the
  maintained sibling design with an explicit ITM-028 round-3 decision.
- **[P2] ts precedent at pin `cb1cbcb`** — read from local Git objects:
  `git -C /Users/stevemorin/c/ts-launch-blueprint show
  cb1cbcb2e88b898e8c081b0abbfabc1630079c00:lefthook.yml` lines 30–60
  (`check-large-files`: `512000` bytes, no exemption) and the empty
  result of grepping that pin's `.github/workflows/ci.yml` for
  "large" (no CI tier). Authority: the divergent sibling shape.
- **[G1] `pre-commit/pre-commit` adoption** — `GET
  https://api.github.com/repos/pre-commit/pre-commit` → 15,595 stars,
  `archived: false`, `pushed_at: 2026-08-17T23:37:08Z`. Authority: the
  framework whose `check-added-large-files` intent ts's hook cites.
- **[G2] `evilmartians/lefthook` adoption** — `GET
  https://api.github.com/repos/evilmartians/lefthook` → 8,856 stars,
  `archived: false`, `pushed_at: 2026-09-24T07:39:26Z`. Authority: the
  hook manager both siblings currently use (R37 decides rs's).
- **[S3] git behavior** — executed locally (`git diff --name-only -z
  --diff-filter=A`, `wc -c`): probes 1–9 under `### Validation
  strategy`. Authority: the tool itself, observed.
- **[L1] Ledger rows** — `docs/port/COMMONALITY.md:49` (F043) and `:176`
  (F172), read in this checkout.
- **[L2] Divergence analysis** — `docs/port/DIVERGENCE-ANALYSIS.md:56`
  (R14 in the harmonize-partly list) and `:96-98` (F043/F172 sub-rows,
  both `harmonize: yes`), read in this checkout.
- **[L3] R49 accepted value** — `docs/port/PARAMETERS.md`,
  `build-tool-output-shape`: artifacts land in `target/`, never
  committed. Read in this checkout.
- **[L4] R81 accepted decision** — `research/topics/81-docs-delivery-model/DECISION.md:146-161`:
  one `docs/` corpus plus `mdbook` → Pages. Read in this checkout.
- **[L5] R11 accepted value** — `docs/port/PARAMETERS.md`,
  `ci-job-structure`: non-compiling checks land on `ubuntu-latest`;
  single-job no-Rust workflows gain nothing from a second runner. Read
  in this checkout.
- **[L6] R17 accepted decision** —
  `research/topics/17-secret-scanning-ci-workflow/DECISION.md:93`: a
  dedicated CI-tier workflow file alongside R11's `ci.yml` is accepted
  practice. Read in this checkout.
