# 2026-09-26 — R37 — hook-manager-distribution (bundle, Focused) — decision (revision 4)

**Revision note, revision 4.** This is fix round 3, a directed repair against revision 3 (sha256
`26e619d7e4d8ee82c5de7658964b842c9e6a75a9d2a30b2bd855ed5eebeede85`, preserved byte-identical at
`review/R37-r3-snapshot.md`). Both revision-3 audits approved with MECHANICAL-only findings: the
judgment audit (`review/audit-fable.r3.md`, M1) and the empirical audit (`review/audit-codex.r3.md`,
findings 1–3). Those approvals bind the revision-3 hash; whether they re-bind to revision 4 or are
asked again is the controller's decision. No finding reopens F143, F144 or F174, the candidate
`lefthook.yml`, any parameter, or the recommendation, and revision 4 moves none of them. **Prose
only:** no evidence file changes, so no script was rerun — every cited evidence line is byte-stable.

| Finding | What the audit found | Disposition in revision 4 |
|---|---|---|
| **M1** (judgment) | The R42 quotation "codex's shape carried a checksum and this one does not" was located at `DECISION.md:368` only | **Applied as directed.** The tradeoff paragraph now cites `DECISION.md:1288-1289`, with the same point at `:368`; the other `:368` citations (the rejected-alternative row) are unchanged |
| **1** (empirical) | A fresh `r37-wiring.sh` run is not byte-identical to the committed log (scratch paths, timings, rendered hook glyph), although every `PASS`/`FAIL`/`TOTAL` line matches | **Applied.** `## Empirical check` states that raw wiring logs vary in those three respects and that reproducibility is judged on the assertion lines |
| **2** (empirical) | The `8,856`-star figure is undated, and a fresh `r37-endpoints.sh` run differs from the committed log in retrieval time and live figures, although all 17 assertions pass | **Applied.** The figure is dated to the committed retrieval time; `## Empirical check` records the audit-observed rerun figure `8,857` and the byte drift; the committed log stays the historical observation |
| **3** (empirical) | The engine-roster note describes only the captured policy input, which is stale against the current `research/EXECUTION.json` | **Applied.** The note distinguishes the captured Codex/Opus input from the current Muse/Opus policy and leaves reconciliation to the controller |

**Revision note, revision 3.** This is fix round 2, against revision 2 (sha256
`2cb2a5d7032347dc780d97f6529e2502f8a3d074c4c425567cc69506a30dcfa3`, preserved
byte-identical at `review/R37-r2-snapshot.md`). The revision-2 judgment audit
(`review/audit-fable.r2.md`) rejected it with one finding, JF-1/JF-10. The concurrent empirical audit
(`review/audit-claude.r2.md`) approved revision 2 (`pass=9/17/26 fail=0`, same sha256); that approval
binds revision 2 only, so revision 3 needs both audits afresh. The finding does not reopen F143, F144
or F174, the candidate `lefthook.yml`, or any parameter, and revision 3 moves none of them. **Prose
only:** no evidence file changes, so no script was rerun — every cited evidence line is byte-stable.

| Finding | What the audit found | Disposition in revision 3 |
|---|---|---|
| **JF-1 / JF-10** | `setup: hooks-install` runs `lefthook install` before the pin assertion, because `just` runs a recipe's dependencies before its body. With lefthook absent, `hooks-install` fails first (exit 127) and the assertion's `just install-tool` guidance never prints; with an off-pin lefthook, hooks are wired before the assertion fails. The revision-2 JF-5 repair (dropping `install-tools`) exposed this ordering | **Fixed.** The assertion moves into a private recipe `_lefthook-pin`, listed as the **first** dependency: `setup: _lefthook-pin hooks-install`. `just` runs dependencies in the listed order before the body, so the pin is asserted before anything is wired. The assertion is guarded by `command -v lefthook`, so a missing binary reaches the guidance message instead of a shell error. The JF-5 intent is kept: `setup` still depends on no R42 recipe. The F143 cell, the F144 cell, the settled F144 row, the claim under the fragment, and V3 (off-pin: no hook written; new lefthook-absent case) are reworded to match |

One audit observation is also applied: the stage-tier paragraph now names `check`'s `cargo test` steps
as the CI counterpart of R32's pre-push hook F173. The actor suffix below now reads `-r3`, per the
per-revision convention (R11's header); revision 2's header carried `-r1`.

**Revision note, revision 2.** This is fix round 1, against revision 1 (sha256
`df4128e723e25c2c4e1331580d6b6ee7f3485caf9dd4eed898e4658ecddff635`, preserved
byte-identical at `review/R37-r1-snapshot.md`). The revision-1 judgment audit
(`review/audit-fable.md`) rejected it with findings JF-5, JF-2, JF-3 and JF-4 (minor). The concurrent
empirical audit (`review/audit-claude.md`) approved revision 1 (52 pass, 0 fail, 0 skip); that approval
binds revision 1 only, so revision 2 needs both audits afresh. No finding reopens the three ledger-row
decisions (F143, F144, F174) or the candidate `lefthook.yml`, and revision 2 moves none of them.
**Prose only:** no evidence file changes, so no script was rerun — every cited evidence line is
byte-stable.

| Finding | What the audit found | Disposition in revision 2 |
|---|---|---|
| **JF-5** | `setup: install-tools hooks-install` depends on an `install-tools` recipe R42 does not define | **Fixed.** `setup` now depends on `hooks-install` only; the fragment states R42 owns `check-deps` and `install-tool`, and contributors reach `setup` through R42's `check-deps` flow |
| **JF-2** | Stage tiers undeclared, R32 coordination missing, "pre-commit stage only" unreasoned | **Fixed.** A stage-tier paragraph declares `pre-commit` / `commit-msg` / `pre-push`, records the R32 coordination point, and carries the exclusion reason with each excluded stage's CI counterpart |
| **JF-3** | Disagreement 8 drops Muse's `just` entry and report-only shape without adjudication | **Fixed.** Disagreement 8 states both and adjudicates: `just` is R42's `check-deps` concern; the doctor is report-only. The F186 row and BASELINE-REVIEW line gain the two clauses |
| **JF-4** | "0.0–10.8 days" mismatches the cited log (max is 10.696) | **Fixed.** Reads "0.0–10.7 days" |

Actor `synth-opus-2026-09-26T190226Z-92b52ed66313-r4`, model `claude-opus-5-5` (Claude Code CLI
seat), item kind `bundle`, effort tier `focused` (two engines, no Doxa). **Revision 4.** Nothing has
been published for R37, so there is no `## Supersedes`.

**Seat disclosure.** `research/RUNBOOK.md` names a fresh Claude Fable context as the synthesizer. This
synthesis ran on the Opus seat. It is a fresh context that produced neither raw report nor any earlier
evidence check, but `raw/opus.md` was written by the same model family (`claude-opus-5-5`). The
judgment auditor should weigh the Opus leg with that in mind.

Retrieval dates: **2026-09-26 (Pacific)** for everything this decision checked itself; the endpoint log
stamps `2026-09-27T01:57:16Z` UTC (`review/evidence/r37-endpoints.log:1`). Both raw reports are dated
2026-09-26.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every candidate
below. The ruling is recorded in the accepted prerequisite R42: "no licence check for any tool or
library the template uses", with `license = MIT OR Apache-2.0` governing only this repository's own
source (`research/topics/42-dev-toolchain-provisioning/DECISION.md:13-16`), and R38 re-published on it
(`research/topics/38-commit-message-linter/DECISION.md:302`). Licence strings below are figures only.
`raw/muse.md` excluded `cargo-binstall` partly on its `GPL-3.0` licence (`raw/muse.md:21`, `:70`); that
ground is void, and its independent capability ground is kept (Disagreement 3).

## Decision

**Status.** This decision is a **proposal to be validated in the implementation phase.** P02 is
research only. The template does not exist yet; P03 builds it, and P03's CI proves or revises this
recommendation. What was executed here is listed under `## Empirical check`; what P03 must still prove
closes `## Engines`.

### The recommended stack

One lefthook binary, one config file, one pin, three decisions — one per ledger row.

| Ledger row | Decision | Mechanism |
|---|---|---|
| **F143** — how lefthook is acquired and pinned | lefthook **2.1.14** from `evilmartians/lefthook`'s immutable GitHub release, acquired through **R42's layer 4** (`ubi`, crate `ubi-cli` 0.12.0) from the single `Justfile` tool table | tool-table entry for lefthook at `v2.1.14`, installed by R42's generic `just install-tool <spec>` into `${CARGO_HOME:-$HOME/.cargo}/bin`; `min_version: 2.1.14` in `lefthook.yml`; `just setup` asserts `lefthook version` equals `2.1.14` before it wires any hook |
| **F144** — what wires hooks on a fresh clone | an **explicit** `just setup`, which first asserts the pin (`_lefthook-pin`) and only then runs `just hooks-install` (body: `lefthook install`) | `assert_lefthook_installed: true` in `lefthook.yml`, so a hook whose binary has vanished fails instead of passing; lefthook's default auto-resync kept for local runs; `just hooks-install` kept as the F145 re-wire recipe |
| **F174** — how CI re-runs the hook suite | **one step of R11's `hygiene` job**: `lefthook run pre-commit --all-files --no-auto-install --no-tty --fail-on-changes` with `LEFTHOOK_EXCLUDE=compiles` | every pre-commit job that compiles Rust carries `tags: [compiles]`, is excluded from the `hygiene` re-run, and has its CI counterpart as an ordered step of R11's `check` job |

Not created: `scripts/install-lefthook.sh`, `package.json`, `build.rs`, a `cargo-husky` or
`rusty-hook` dev-dependency, `mise.toml`, `.tool-versions`.

### Settled `F###` rows

| Row | Settled as |
|---|---|
| F143 | lefthook 2.1.14 via R42 layer 4 (`ubi`), pinned once in the tool table and floor-guarded by `min_version` |
| F144 | explicit `just setup` → pin assertion (`_lefthook-pin`) → `just hooks-install` → `lefthook install`; `assert_lefthook_installed: true` |
| F174 | single `hygiene` step, pre-commit stage only, `--all-files --no-auto-install --no-tty --fail-on-changes`, compiling jobs excluded by the `compiles` tag |
| F186 (content, per the prompt's baseline-review instruction) | the hook-toolchain readiness check audits `command -v lefthook`, `lefthook version` = pin, and `lefthook check-install`, plus the executables R39 and R40 select; it drops py's `bun` and `uv`; it is report-only, never aborting `setup`; `just` presence is left to R42's `check-deps` (Disagreement 8) |

F145 (`hooks-install` recipe) and F175 (`hooks-run` whole-tree recipe) are `COMMON → REUSE` rows owned
elsewhere. This decision only records their bodies' interaction with the choices above: `hooks-install`
is `lefthook install`, and `hooks-run` gains `--no-auto-install` so that running it does not wire hooks
as a side effect (check W06).

### Principles and implementation

**Shared principle and agreement level.** Both raws identify the same principle in different words
(`raw/muse.md:28`, `raw/opus.md:92-95`): *the hook suite is defined once in `lefthook.yml`; a pinned
lefthook runs it locally after one documented activation step; and CI, the authority, re-runs it over
the whole tree so a bypassed hook (`git commit --no-verify`) cannot merge unchecked.* The agreement level
is **capability plus policy**, not mechanism.

| Must agree across py, ts and rs | May vary per ecosystem |
|---|---|
| lefthook is the manager (F142, not reopened) | the acquisition channel (py: Bun; ts: pnpm devDependency; rs: R42 layer 4) |
| one exact version pin in one place | where the pin lives (script variable, `package.json`, `Justfile` tool table) |
| one documented activation step; `hooks-install` as the re-wire fallback (F145) | whether activation is automatic (pnpm `prepare`) or explicit (`just setup`) |
| a missing binary makes the hook fail, not pass | — |
| CI re-runs the pre-commit suite over all files (F174) | which jobs are excluded because another CI job already runs them |

**Why the Rust mechanism differs.** Cargo has no lifecycle hook comparable to pnpm's `prepare`, and no
dependency slot for a non-crate binary: `GET https://crates.io/api/v1/crates/lefthook` returns
"crate `lefthook` does not exist" (`review/evidence/r37-endpoints.log:3-4`). A `build.rs` side effect is
the only automatic trigger Cargo offers, and both raws reject it: it would run for every build including
downstream consumers of the library (`raw/muse.md:30`), and R38 already records a hook-rewriting
`build.rs` as something that "must never run" in the template
(`research/topics/38-commit-message-linter/DECISION.md:181`). The explicit step is therefore the Rust
realisation of the same capability, not a regression from ts.

**Architectural alternatives, compared before tools.**

| Sub-decision | Alternative | Verdict |
|---|---|---|
| F143 | R42 layer 4: `ubi` from the vendor's immutable release, pinned in the one tool table | **selected** — the only route consistent with R42's accepted layers 2–4 |
| | per-tool download-and-checksum script (`raw/muse.md`'s recommendation) | **excluded** — R42 rejects it by name (`DECISION.md:368`) and forbids per-tool scripts (`:27`); its stronger integrity is recorded as this decision's main tradeoff |
| | `cargo install` / `cargo binstall lefthook` | excluded — capability: no crate exists |
| | npm / pnpm / Bun / PyPI / `go install` | excluded — each imports a language runtime solely for one Go binary; R38 chose native `committed`, so no such runtime exists to share |
| | `mise` / `asdf` / `.tool-versions` | excluded — R42 layer 3 forbids provisioner manifests (`DECISION.md:28`) |
| | Homebrew / apt | excluded — the formula tracks the latest release, so the channel cannot install an exact pin |
| F144 | explicit `just setup` + `assert_lefthook_installed: true` | **selected** |
| | `build.rs`, `cargo-husky`, `rusty-hook` | excluded — Cargo book's `OUT_DIR` rule (carried from `raw/opus.md:115-117`), runs on every build, R38 `:181` |
| | committed `.githooks/` + `core.hooksPath` | excluded — bypasses lefthook (F142) |
| | `cargo xtask setup` | not selected — same explicit step with a Rust program to maintain; `just` is already the task runner |
| F174 | one `hygiene` step, compiling jobs excluded by tag | **selected** — R11's slot (`research/topics/11-ci-workflow-job-structure/DECISION.md:292`) and partition rule (`:278`) |
| | per-tool CI steps with a parity table (py ADR 0018) | kept only for compiling jobs; as the whole mechanism it has no structural guarantee that a new hook job is mirrored |
| | whole suite inside `check` | excluded — puts non-compiling checks behind R11's compile tier and runs them once per matrix leg |
| | its own job | excluded — R11: a check that compiles nothing is a step of `hygiene` |

**Candidate files.** The `lefthook.yml` below is byte-identical to
`review/evidence/r37-lefthook.candidate.yml` (sha256 `17dfcab4…`), which check W11 validates unmodified
and checks W01–W08 exercise (with one marked substitution). Only its manager settings and two
illustrative jobs are this item's; stage contents belong to R27/R28/R30/R32/R38/R39/R40/R41.

```yaml
# lefthook.yml — R37 revision 1 candidate (manager settings and stage skeleton only).
# Job bodies other than the two shown belong to R27/R28/R30/R32/R38/R39/R40/R41.
min_version: 2.1.14
assert_lefthook_installed: true

pre-commit:
  parallel: true
  jobs:
    - name: fmt
      glob: "*.rs"
      run: cargo fmt --all --check
    - name: clippy
      tags: [compiles]
      run: cargo clippy --workspace --all-targets --locked -- -D warnings
```

The `clippy` job illustrates the tag contract only. Whether a compiling job sits at pre-commit at all is
R30's and R28's decision; the tag rule applies to whichever compiling job any item places there.
The `commit-msg` stage carries R38's fixed command `committed --fixup --wip --commit-file {1}`
(`research/topics/38-commit-message-linter/DECISION.md:106`); it is omitted from the candidate because
`committed` was not installed for this check, and R38's wiring through lefthook remains unexecuted
(R38 `:187`).

**Stage tiers.** R37 wires three stages; their contents belong to the owning items. `pre-commit`
carries the hook jobs and is the only stage the F174 re-run covers. `commit-msg` carries R38's fixed
command above. `pre-push` carries R39's range scan (`inputs/prompt.md:18`) and R32's opt-in test-suite
hook F173 (`inputs/prompt.md:21`) — the R32 coordination point (`inputs/prompt.md:33`): F173 lands in
the pre-push tier, owned by R32, not re-decided here. The F174 re-run excludes `commit-msg` and
`pre-push` because `commit-msg` cannot run over files and is re-checked by R38's range job, while
pre-push jobs belong to R39 (secret range scan, CI in R17) and R32 (`raw/opus.md:582-584`). Each
excluded stage therefore keeps a CI counterpart: R38's range job for `commit-msg`, R17 for R39's scan,
and `check`'s ordered `cargo test` steps (the assumed `ci-job-structure`) for R32's F173.

`Justfile` fragment (proposed, not executed; R42 owns the `install-tool` body, the `check-deps`
recipe and the spec syntax; `setup` depends on no R42 recipe). `just` runs a recipe's dependencies in
the listed order before its body, so `_lefthook-pin` completes before `hooks-install` starts, and a
failed assertion stops `setup` before any hook is written:

```just
lefthook_version := "2.1.14"

# F144: assert the pin first, then wire hooks
setup: _lefthook-pin hooks-install

_lefthook-pin:
    command -v lefthook >/dev/null && test "$(lefthook version)" = "{{lefthook_version}}" || { echo "lefthook {{lefthook_version}} required; run: just install-tool <lefthook tool-table spec>" >&2; exit 1; }

# F145: re-wire git hooks (idempotent)
hooks-install:
    lefthook install

# F175: run the pre-commit suite over the whole tree without wiring hooks
hooks-run:
    lefthook run pre-commit --all-files --no-auto-install
```

Contributors reach `setup` through R42's accepted flow — `just check-deps`, then the printed
`just install-tool <spec>` lines, then `just check-deps` again
(`research/topics/42-dev-toolchain-provisioning/DECISION.md:459-464`). If `setup` is run without that
flow, `_lefthook-pin` prints the same explicit `just install-tool` step and exits 1, before any hook is
written, both when lefthook is absent (the `command -v` guard) and when another version is on `PATH`.

`.github/workflows/ci.yml` — one step of R11's `hygiene` job (proposed, not executed):

```yaml
      - name: Hook suite (pre-commit, all files, non-compiling jobs)
        env:
          GITHUB_TOKEN: ${{ github.token }}   # ubi resolves the tag through the GitHub API; scope per R08
          LEFTHOOK_EXCLUDE: compiles
        run: |
          just install-tool <lefthook tool-table spec>
          lefthook run pre-commit --all-files --no-auto-install --no-tty --fail-on-changes
```

`<lefthook tool-table spec>` is a placeholder. `raw/opus.md:208` proposes the spelling
`gh:evilmartians/lefthook@v2.1.14`, but R42 defines no spelling for its "second spec form"
(`research/topics/42-dev-toolchain-provisioning/DECISION.md:29`; no `gh:` token appears anywhere in that
file). The spelling is R42's to fix; the resolved command must be
`ubi --project evilmartians/lefthook --tag v2.1.14 --in "${CARGO_HOME:-$HOME/.cargo}/bin"`.

**How each flag earns its place** (all executed, `## Empirical check`):

| Setting | Without it | With it | Check |
|---|---|---|---|
| `assert_lefthook_installed: true` | vanished binary → hook prints `Can't find lefthook in PATH` and exits 0 | exits 1, "Operation is aborted due to lefthook settings" | W08 |
| `min_version: 2.1.14` | an older binary runs | `required lefthook version (…) is higher than current`, exit 1 | W05 |
| `--no-auto-install` (CI, `hooks-run`) | `lefthook run` wires `.git/hooks` as a side effect, **including under `CI=true`** | clone stays unwired | W04, W06, W12 |
| `--fail-on-changes` (CI) | a job that rewrites files exits 0 and the change is lost | exit 1, "files were modified by a hook" | W09, W10 |
| `LEFTHOOK_EXCLUDE=compiles` (CI) | the compiling job runs inside `hygiene` | skipped (`clippy (skip) tags`) | W04, W04b |
| `lefthook check-install` (F186 doctor) | — | exit 1 absent or stale, 0 wired and current | W01, W02, W07 |

**Fitness gates, per member.** Gates are answered before popularity.

| Gate | F143 lefthook binary (+ `ubi-cli` backend) | F144 wiring | F174 CI step |
|---|---|---|---|
| 1 licence | inapplicable — owner ruling; recorded: lefthook `MIT` (`r37-endpoints.log:13`) | inapplicable | inapplicable |
| 2 MSRV | inapplicable to lefthook (prebuilt Go binary, never compiled by Cargo). `ubi-cli` 0.12.0 declares **no** `rust-version`; library `ubi` 0.12.0 declares 1.88 (`r37-endpoints.log:5`, `:8`), inside the floor 1.96 derived from stable 1.98.1 (`:68`). Relevant only if `cargo binstall ubi-cli` falls back to a source build | inapplicable — no crate added | inapplicable — no crate added |
| 3 advisories, `unsafe` | no RustSec page for `lefthook`, `ubi`, `ubi-cli`, `cargo-binstall` (all HTTP 404, `r37-endpoints.log:59-66`); `unsafe` inapplicable to a Go binary; not measured for `ubi` | inapplicable | inapplicable |
| 4 OS | v2.1.14 ships `MacOS_arm64`, `MacOS_x86_64`, `Linux_x86_64`, `Linux_arm64` (`r37-endpoints.log:16-19`); upstream CI `os: [ubuntu-latest, macos-latest, windows-latest]` carried from `raw/opus.md:330-332`, not re-read | generated hook is POSIX `sh`; executed on macOS only | runs in `hygiene` on `ubuntu-latest` (R11); macOS behaviour exercised locally |
| 5 features, async | inapplicable — not linked | inapplicable | inapplicable |
| 6 size, compile time | zero compile time; 13.4–14.8 MB unpacked per asset (`r37-endpoints.log:16-19`) | none | one binary download per `hygiene` run; bootstrap chain cost unmeasured (gap 4) |

**Maintenance.** lefthook: 8,856 stars as retrieved at `2026-09-27T01:57:16Z` UTC
(`r37-endpoints.log:1`, `:13`), not archived, `pushed_at` 2026-09-24, latest release v2.1.14
published 2026-09-14 and `immutable: true`, 71 open issues by the search endpoint
(`r37-endpoints.log:13-25`). Of the 10 most recently opened issues, none carries a comment and 5 were
closed `completed` within 0.0–10.7 days (`r37-endpoints.log:27-36`); rubric **active** (release within
two weeks; five releases May–September per `raw/opus.md:563-564`). `ubi`: 595 stars, not archived,
`pushed_at` 2026-09-19 (`:67`).

**BASELINE-REVIEW lines** (carried from `raw/opus.md:252`, `:254`; the `docs/port/` lines they cite
were **not re-read** by this synthesis, which was scoped to the run directory and prerequisites):

BASELINE-REVIEW: F186 — a doctor recipe reports whether the git-hook toolchain is present — audit `command -v lefthook`, an exact `lefthook version` match against the tool-table pin, and `lefthook check-install` (exit 0 wired and current, exit 1 absent or stale), plus the executables R39 and R40 select; drop `bun` and `uv` from py's list; do not audit `ubi` or `cargo-binstall` here, because they are R42's acquisition backends — evidence: `lefthook check-install --help` (`review/evidence/r37-cli-contract.log:37-48`) and checks W01, W02, W07; py `Makefile:130` carried from `raw/opus.md:252`, not re-read. Revision 2 adds: report-only shape, never aborting `setup` (Muse's F181/F185 shape, adopted in Disagreement 8); `just` is not audited here — its presence is R42's `check-deps` concern.

BASELINE-REVIEW: F174 — CI re-runs the whole pre-commit hook suite over all files — R37 decides that the re-run exists and its contract (pre-commit stage only; `--all-files --no-auto-install --no-tty --fail-on-changes`; compiling jobs tagged `compiles` and excluded with `LEFTHOOK_EXCLUDE`); R11 decides only its placement — evidence: R11's slot is conditional on this item ("if CI re-runs the hook suite, it is a step of `hygiene` when it compiles nothing", `research/topics/11-ci-workflow-job-structure/DECISION.md:292`); the ownership note it would correct (`docs/port/DIVERGENCE-ANALYSIS.md:154`) is carried from `raw/opus.md:254`, not re-read.

**Coordination notes for R42, not `CONFLICT:` lines.** No registered value changes. (1) R42's layer-4
backend must be installed as the crate **`ubi-cli`**: crate `ubi` 0.12.0 has `bin_names: []` and
`ubi-cli` 0.12.0 has `bin_names: ["ubi"]` (`r37-endpoints.log:5-9`). (2) R42's proof text
`ubi --project <owner>/<repo> --in ./bin` (`research/topics/42-dev-toolchain-provisioning/DECISION.md:1702`)
places the binary in `./bin`, which is not on `PATH`, contrary to R42's own bare-executable rule; this
item uses `--in "${CARGO_HOME:-$HOME/.cargo}/bin"`, where `cargo binstall` already places layer-2 tools.

**The tradeoff this recommendation accepts.** `ubi` downloads over TLS but compares no checksum
(carried from `raw/opus.md:366-370`; the `ubi` README was not re-read here). lefthook publishes
`lefthook_checksums.txt` (`r37-endpoints.log:20`), and v2.1.14 is an immutable release (`:21`), so the
assets cannot be replaced after publication, but nothing on this path verifies them. `raw/muse.md`'s
per-tool script would verify them. R42 weighed exactly this and chose the generic recipe: "codex's shape
carried a checksum and this one does not" (`DECISION.md:1288-1289`; the same point at `:368`), and put the equivalent `cargo binstall`
integrity question to the owner (`:176-200`). This item does not reopen R42; it records that the first
layer-4 occupant inherits the same unverified-prebuilt property.

re-verify: 2027-03-26, or earlier on any of — a lefthook release beyond 2.1.14 (move the tool-table pin, `lefthook_version` and `min_version` together, then rerun review/evidence/r37-wiring.sh and r37-cli-contract.sh with the new PIN); a lefthook 3.x; lefthook publishing on crates.io, which moves it to R42 layer 2; R42 fixing the layer-4 spec spelling, changing its layer-4 backend, adding checksum verification to it, or the owner ruling on R42's integrity options; ubi-cli declaring a rust-version above the stable-minus-2 floor or a RustSec or GitHub advisory for lefthook, ubi, ubi-cli or cargo-binstall; R11 changing hygiene's toolchain or its partition rule; R30 or R28 placing a compiling check at pre-commit without the compiles tag; lefthook changing the semantics of assert_lefthook_installed, min_version, check-install, --all-files, --no-auto-install, --fail-on-changes or LEFTHOOK_EXCLUDE; R38's runner-up condition bringing a Node or Bun runtime into the template, which reopens npm distribution; or GET https://api.github.com/repos/evilmartians/lefthook returning archived true

## Parameters

R37 owns **no** registry parameter: the prompt's `## Couplings` block carries an empty `- owns:` line
and `- consumes: R11: ci-job-structure; R42: package-manager-invocation; R69: web-extra-surface`, and
`research/CLAUDE.md` records `—` in R37's `owns` column. There is therefore no `- owns` line below. The
consumed values are copied byte-for-byte from `inputs/parameters.json`.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- No `CONFLICT:` line. Neither raw raised one (`raw/muse.md:242`, `raw/opus.md:711-713`), and nothing in this recommendation requires a registered value to change.

**How each consumed value is applied.** `ci-job-structure` (R11): the re-run is a step of `hygiene`,
which compiles nothing and has no `needs` edge, so it reports even when the compile tier is skipped;
compiling counterparts are ordered steps of `check`. `package-manager-invocation` (R42): lefthook is
invoked as a bare `lefthook` on `PATH` with no prefix, and its presence is tested with
`command -v lefthook` because it is release-acquired. `web-extra-surface` (R69): **no effect** on the
manager's acquisition, wiring or CI step — both raws agree (`raw/muse.md:34`, `raw/opus.md:616-619`);
web-specific compiling checks are already `check` steps under R11.

## Empirical check

**Toolchain and host.** macOS 26.4, `Darwin 25.4.0 arm64`; `git version 2.50.1 (Apple Git-155)`;
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`; `rustfmt 1.9.0`; lefthook `2.1.14` at
`/opt/homebrew/bin/lefthook` (Homebrew); `curl 8.7.1`, `jq-1.8.2`, `gh 2.101.0` authenticated. Private
`CARGO_HOME=/tmp/cargo-s9-R37`. Every script passes `shellcheck` with no findings.

**To rerun.** `r37-endpoints.sh` needs `curl`, `jq` and an authenticated `gh`. `r37-cli-contract.sh`
and `r37-wiring.sh` need `git`, `cargo` with `rustfmt`, and lefthook 2.1.14 on `PATH` by any channel;
they fail at C00/W00 on any other version. The recommended channel could not be run here (gap 1).

**What the checks do and do not do.** They verify the facts the recommendation rests on through the
prompt's named endpoints, capture the shipped binary's own flag contract, and execute the wiring and CI
behaviour of the candidate `lefthook.yml` in a throwaway git tree. They **do not** run `ubi`, install
`ubi-cli`, run `just`, or touch GitHub Actions: `ubi` downloads from `github.com/…/releases/download` and
installing `ubi-cli` downloads from `static.crates.io`, both outside this synthesis's network scope (the
topic's named endpoints). The acquisition path (F143) is therefore **not executed** (gap 1).

Working directory for every command:
`research/runs/R37/2026-09-26T190226Z-92b52ed66313/review/evidence/`.

| Script | Command | Observed |
|---|---|---|
| `r37-endpoints.sh` | `bash r37-endpoints.sh > r37-endpoints.log 2>&1` | exit 0, `TOTAL pass=17 fail=0` (`r37-endpoints.log:69`) |
| `r37-cli-contract.sh` | `bash r37-cli-contract.sh > r37-cli-contract.log 2>&1` | exit 0, `TOTAL pass=9 fail=0` (`r37-cli-contract.log:71`) |
| `r37-wiring.sh` | `bash r37-wiring.sh > r37-wiring.log 2>&1` | exit 0, `TOTAL pass=26 fail=0` (`r37-wiring.log:86`) |

**`r37-endpoints.sh`** asserts structural facts and prints live figures as `FIGURE` lines, which will
drift on a rerun. Asserted: no `lefthook` crate (E01); `ubi` 0.12.0 ships no executable and `ubi-cli`
0.12.0 ships `ubi` (E02, E03); lefthook not archived (E05); v2.1.14 carries the four Linux/macOS assets
and `lefthook_checksums.txt` and is `immutable` (E06); py's pin v2.1.8 does ship macOS binaries (E07);
no RustSec page for four packages (E10). It also records three issue samples (E09) that settle
Disagreement 5.

**Rerun drift, audit-observed.** The revision-3 empirical audit (`review/audit-codex.r3.md`) reran
`r37-endpoints.sh` at `retrieved_at_utc 2026-09-27T17:45:30Z`. It reported lefthook
`stargazers_count=8857`, against `8856` in the committed log at `2026-09-27T01:57:16Z`
(`r37-endpoints.log:1`, `:13`). The fresh log also differed in crates.io download counts and in
issue #1526's comment count, so `cmp` against the committed log returned 1; all 17 assertions still
passed (`TOTAL pass=17 fail=0`). The committed log is kept as the historical observation, and the
figures above are dated to its retrieval time.

**`r37-cli-contract.sh`** asserts that `lefthook version` equals `2.1.14` (C00), that `lefthook run
--help` documents `--all-files`, `--no-auto-install`, `--no-tty`, `--[no-]fail-on-changes`, `--tag`,
`--job` and `--exclude` (C01; `r37-cli-contract.log:6-35`), and that `check-install --help` states
"0 – hooks are installed / 1 – hooks are not installed or stale" (C02; `:37-48`). Note from that
output: `run --exclude` excludes **files**, not tags (`r37-cli-contract.log:18`), which is why the CI step excludes the compiling
job through `LEFTHOOK_EXCLUDE`.

**`r37-wiring.sh`** builds a seed repository with `cargo init --lib --edition 2024`, the candidate config
with one substitution (the `compiles` job's `run:` becomes `echo CLIPPY-RAN; exit 1`, asserted to change
exactly one line), a bare `origin.git`, a contributor `clone`, and unwired CI clones. Git's global and
system config are isolated. The CI command is
`CI=true LEFTHOOK_EXCLUDE=compiles lefthook run pre-commit --all-files --no-auto-install --no-tty --fail-on-changes --colors off`.

| Case | Observed (`r37-wiring.log`) |
|---|---|
| W01, W02 | fresh clone `check-install` exit 1; after `lefthook install` exit 0 and `.git/hooks/pre-commit` written (`:5-8`) |
| W03, W03b | the wired hook rejects `pub fn  f( )->u8{1}` with a `fmt` diff, exit 1, commit count stays 1; `--no-verify` lands it (count 2) (`:9-27`) |
| W04 | in an unwired clone the CI command exits 1 on the bypassed file, prints `clippy (skip) tags`, `CLIPPY-RAN` count 0, and writes no hook (`:28-47`) |
| W04b | without `LEFTHOOK_EXCLUDE` the compiling job runs (`CLIPPY-RAN` count 1) (`:48`) |
| W04c | positive control: after the fix lands, the same CI command exits 0 (`:49-58`) |
| W05 | `min_version: 9.9.9` → `Error: required lefthook version (9.9.9) is higher than current (2.1.14)`, exit 1 (`:59-61`) |
| W06 | a run without `--no-auto-install` wires the unwired clone (`check-install` 1 → 0) (`:62-63`) |
| W07 | appending a `post-checkout` hook to `lefthook.yml` makes `check-install` exit 1 (stale) (`:64`) |
| W08 | hooks installed from a copied binary that is then deleted, run with `PATH=/usr/bin:/bin`: `assert_lefthook_installed: true` → exit 1 with "Operation is aborted due to lefthook settings"; `false` → exit 0 after "Can't find lefthook in PATH" (`:65-71`) |
| W09, W10 | a job running `cargo fmt --all` rewrites the file and exits 0; with `--fail-on-changes` it exits 1 with "files were modified by a hook, and fail_on_changes is enabled" (`:72-80`) |
| W11 | `lefthook validate` on the **unmodified** candidate prints `All good`, exit 0 (`:81-82`) |
| W12 | isolates W04 from W06: an unwired clone run with `CI=true` but **without** `--no-auto-install` is wired afterwards (`check-install` 1 → 0), so `CI=true` alone does not suppress auto-install and the flag is required in the CI step (`:83-85`) |

These reproduce the Opus leg's T1–T10 (`raw/opus.md:740-753`) independently, on the published candidate,
and add W04c (positive control), W11 (validation of the unmodified file) and W12 (the `CI=true` confound). Timings are for a one-file
crate and are not a performance claim.

**Raw wiring logs are not byte-reproducible.** A rerun of `r37-wiring.sh` varies in three respects:
the random scratch-directory paths, the elapsed times, and the rendered hook glyph (the committed
banner at `r37-wiring.log:10` reads `│ 🥊 lefthook  v2.1.14   hook:  pre-commit │`; the revision-3
empirical audit's rerun rendered `│ lefthook  v2.1.14   hook:  pre-commit │`). Reproducibility is
therefore judged on the `PASS`, `FAIL` and `TOTAL` lines, not on a byte comparison. On that basis the
audit's rerun reproduced the committed log exactly (26 pass, 0 fail), while `cmp` against the full
raw log returned 1; that raw-log mismatch is retained in `review/audit-codex.r3.md`.

**Not executed here** (P03, table at the end of `## Engines`): the `ubi` acquisition on either runner;
anything on `ubuntu-latest`; the `hygiene` step on a real pull request; `just setup`'s version
assertion; R38's `commit-msg` job firing through the lefthook-installed hook.

## Engines

- **Muse (Meta)** — `raw/muse.md`, 40,445 bytes, sha256
  `91f2cf4d880de0aae932fea0b97b081b5f07c0834cc787b6cefa6e1c84117104`. **Engine-roster note for the
  controller:** the policy snapshot lists R37's engines as `codex` and `opus`
  (`inputs/EXECUTION.json:428-434`), `manifest.json` records `required_engines: ["codex", "opus"]`, and
  R37 is **not** among the `engine_overrides` entries (`inputs/EXECUTION.json:5` onward). That is
  the **captured** input of this run. The **current** working-tree `research/EXECUTION.json` differs:
  it sets `engine_overrides.R37` and `items.R37.engines` to `["muse", "opus"]`, consistent with the
  Q17.A amendment in `research/RUNBOOK.md` §2. The Muse leg therefore departs from the captured
  Codex/Opus input but matches the current Muse/Opus policy, and no replacement raw report is called
  for by the current policy. The controller reconciles the run's captured inputs with the current
  policy before publication; this synthesis does not rule on it.
  Recommends a per-tool, checksum-verified download script, `just`
  1.58.0 as a member, and a `hygiene` run-all step. Executed nothing (`raw/muse.md:40`).
- **Claude Opus 5.5** — `raw/opus.md`, 74,779 bytes, sha256
  `05e9c6a9f86a47f0d1aeeaf9d20757dc121162ed93850148c08d93ee04bae665`. Recommends R42 layer 4 (`ubi`),
  `assert_lefthook_installed`, and a tag-excluding `hygiene` step. Executed T1–T10 on lefthook 2.1.14;
  did not run `ubi`.
- **Prerequisite decisions consumed** (hashes from `inputs/prerequisites.json`): R11 decision
  `410e88e5…`, R38 decision `c2e9b6e1…`, R42 decision `a2504aa7…`, R69 decision `d4507f5b…`. R38 is a
  related prerequisite, not a consumed parameter, so it has no `assumes` line.

**Where the legs agree** (not re-litigated): lefthook is fixed (F142); no Cargo-native acquisition
exists; no `build.rs`; explicit `just setup` → `hooks-install` → `lefthook install`; `hooks-install`
kept as F145's re-wire; a whole-tree run-all step in R11's `hygiene` job rather than py's per-tool jobs
or a separate job; `--no-auto-install` in CI; R69 has no effect; F186 drops `bun` and `uv`; no
`CONFLICT:`.

**Disagreement 1 — acquisition channel (F143). Settled for the Opus leg.** Muse recommends
`scripts/install-lefthook.sh`, a pinned, checksum-verified direct download (`raw/muse.md:46`, `:62`).
Opus recommends R42's layer 4 (`raw/opus.md:144`, `:150`). The legs diverge because Muse adjudicated
only against the registered **value** of `package-manager-invocation`, which is silent on scripts,
while Opus read the accepted R42 **decision**, which is not. That decision reserves layer 4 for this
item ("reserves the slot for R37/R39/R40", `DECISION.md:29`), forbids "per-tool shell script[s]"
(`:27`), and rejects "Per-tool installer recipes with pinned URL + SHA-256" by name (`:368`). A consumer
that re-decides an accepted owner's layer structure is out of bounds. Muse's integrity argument is real
and R42 concedes it (`:368`); it is carried as this decision's tradeoff, not as a ground to reopen R42.

**Disagreement 2 — whether the CI step needs tag exclusion (F174). Settled for the Opus leg.** Muse
places the whole suite in `hygiene` on the premise that "a hook-suite re-run … compiles nothing itself"
(`raw/muse.md:178`, `:186`). That premise holds only if no pre-commit job compiles, which R30 and R28
have not yet decided. Opus's `tags: [compiles]` + `LEFTHOOK_EXCLUDE=compiles` design holds under either
outcome, and W04/W04b show it keeps compilation out of `hygiene` without skipping the non-compiling jobs.
The obligation to tag a compiling job passes to whichever item places one at pre-commit.

**Disagreement 3 — `cargo-binstall`'s exclusion ground.** Muse excluded it on capability and licence
(`raw/muse.md:21`, `:70`). The licence ground is void under the owner ruling; the capability ground
(it installs crates, and lefthook is not one) stands, and both legs share it. `cargo-binstall` is not a
candidate here in any case: it is R42's layer-2 backend, used only to install `ubi-cli`.

**Disagreement 4 — `--no-auto-install` spelling.** Muse rated it medium confidence pending confirmation
(`raw/muse.md:230`, `:254`). Confirmed: `lefthook run --help` documents it (`r37-cli-contract.log:22`,
`:30`), and W04/W06 show its effect.

**Disagreement 5 — lefthook issue responsiveness.** Muse: "6 of 10 have a first comment, all within one
day" (`raw/muse.md:24`). Opus: "no issue carries any comment" (`raw/opus.md:566`). **Settled for Opus,
with Muse's figure explained.** The prompt's sample is the 10 most recently *opened issues*. Excluding
pull requests, the `state=all` sample is exactly Opus's ten (#1493–#1548) and none carries a comment
(`r37-endpoints.log:27-36`); the `state=open` sample has 3 of 10 commented (`:38-47`). Muse's endpoint
(`state=open`, `per_page=10`, `raw/muse.md:24`) returns pull requests too: 8 of its 10 entries are pull
requests, and exactly 6 of the 10 carry a comment (`:49-58`). Muse's figure measures pull-request
review, not issue response. Neither sample reaches a verdict other than **active**, which rests on
release cadence.

**Disagreement 6 — whether `just` is a member.** Muse makes `just` 1.58.0 a member with a version floor
(`raw/muse.md:112-172`). **Not adopted.** `just` is the F145/F175 recipe runner, a `COMMON → REUSE`
baseline outside this item's three rows, and R42 owns how it is acquired. A floor of 1.58.0 is also
unsupported by any feature this decision uses; the host that ran these checks has `just 1.57.0`.

**Disagreement 7 — `assert_lefthook_installed`, `min_version` and `--fail-on-changes`.** Only Opus
proposes them; Muse neither adopts nor rejects them. **Adopted**, because each closes a failure the
principle forbids and each was executed here (W05, W08, W09/W10). Muse's recommended shape was
fail-open when the binary vanishes (W08, `false` branch).

**Disagreement 8 — BASELINE-REVIEW lines and F186's content.** Muse files none and states F186's
content in prose (`raw/muse.md:36`, `:42`): it audits `lefthook`, **`just` (recipe runner)**, plus the
hook-job tools R39/R40 select, in a **report-only shape** (sibling F181/F185), never aborting `setup`
(unlike F182). Opus files two (`raw/opus.md:252`, `:254`); its F186 list omits `just` and adds
`lefthook check-install`, which W01/W02/W07 show catches a stale wiring that `command -v` cannot.
**Adjudicated.** (a) `just` is **not** audited by F186 — its presence is R42's `check-deps` concern:
R42's accepted contributor flow opens with `just check-deps`
(`research/topics/42-dev-toolchain-provisioning/DECISION.md:459-464`), Disagreement 6 already rules R42
owns how `just` is acquired, and a doctor invoked as a `just` recipe cannot diagnose a missing `just`.
(b) The doctor is **report-only**, never aborting `setup` — Muse's F181/F185 shape is adopted, because
aborting enforcement already lives in `just setup`'s version assertion and in
`assert_lefthook_installed` (W08). Both lines are carried, with their `docs/port/` citations marked
unread and the F186 line gaining the two adjudicated clauses.

**Carried from one raw, not verified by this synthesis.** (a) Opus's reading that py's Bun installer
rests on the premise that lefthook 2.x ships no Darwin binary (`raw/opus.md:119-128`): the release
listing half is verified (`r37-endpoints.log:23-24`); the py comment itself was not re-read. (b) py's
`min_version: 1.13.0` drift against its 2.1.8 pin (`raw/opus.md:129-132`). (c) The ts CI line: the
prompt cites `.github/workflows/ci.yml:106`, Opus reads `:113-114` at `e5100b4f` (`raw/opus.md:137`);
not reconciled here. (d) Opus's 17-repository practice survey (`raw/opus.md:59-83`) and ruff as the
closest shared-adopter shape (`:689-691`); Muse's contrary claim that nushell "standardizes on
Justfiles" (`raw/muse.md:13`) conflicts with Opus's `toolkit.nu` reading, and neither was re-read.
(e) `ubi`'s missing checksum verification and its API rate-limit caveat (`raw/opus.md:360-371`).

**Gaps recorded.**

1. The F143 acquisition path never ran: no `ubi` invocation and no asset download, on either runner.
2. Nothing ran on `ubuntu-latest`; every executed check is macOS arm64.
3. No well-regarded Rust project using lefthook was found (Opus survey, 0 of 17); the reference shape
   for F144/F174 is ruff on `prek`.
4. The `hygiene` bootstrap chain — `just`, then `cargo-binstall`, then `ubi-cli`, then lefthook — on a
   runner that carries no cache step is unmeasured. It is the cost of honouring R42 that Muse's direct
   download would have avoided.
5. The layer-4 spec spelling is unowned text in this decision until R42 fixes it.
6. Parity for `compiles`-tagged jobs is a mapping, not structural; Opus's proposed drift guard
   (`raw/opus.md:610-612`) has no owner.
7. `ubi-cli` declares no `rust-version`; whether `cargo binstall ubi-cli@0.12.0` finds a prebuilt or
   compiles is unmeasured.
8. Citations into `docs/port/` and the py/ts trees are carried from the raws, not re-read.

**What P03 must validate.**

| # | Claim | How P03 proves it |
|---|---|---|
| V1 | The layer-4 path installs a working lefthook 2.1.14 on `PATH` | on `ubuntu-latest` and `macos-latest` with no lefthook present: `just install-tool <spec>`, then `command -v lefthook` resolves under `$CARGO_HOME/bin` and `lefthook version` prints `2.1.14` |
| V2 | The installed bytes are the published ones | compare `sha256` of the installed binary's source asset with `lefthook_checksums.txt`; records, without fixing, the integrity gap |
| V3 | `just setup` wires hooks and enforces the pin | fresh clone: `just setup` exits 0 and `lefthook check-install` exits 0; with another lefthook version on `PATH`, `just setup` exits non-zero, prints the `just install-tool` guidance, and no hook is written (`lefthook check-install` still exits 1); with no lefthook on `PATH`, `just setup` exits non-zero with the same guidance and no hook is written |
| V4 | The `hygiene` step catches a bypassed hook | a pull request carrying a `--no-verify` formatting violation fails the step; the fix passes; a docs-only pull request still runs it |
| V5 | Compiling jobs are never run in `hygiene` and always run in `check` | a CI assertion that every `compiles`-tagged job's command appears among `check`'s steps (the gap-6 guard) |
| V6 | R38's `commit-msg` job fires through the lefthook-installed hook | a commit with a non-conventional message is rejected by the wired hook |
| V7 | Bootstrap cost is acceptable | time a cold `hygiene` run from checkout to the lefthook step, runner class stated |
