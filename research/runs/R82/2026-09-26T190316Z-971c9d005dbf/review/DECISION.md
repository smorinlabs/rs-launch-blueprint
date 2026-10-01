# 2026-09-28 — R82 — docs-correctness-gate (bundle, Focused) — decision (revision 2)

**Revision note, revision 2.** Revision 2 repairs exactly the two findings of the judgment audit
(`review/audit-fable.md`, verdict `reject`, on revision 1 sha256 `4853cae1…5d43`); the empirical
audit (`review/audit-claude.md`) approved, and its observations are not repaired here. Revision 1
is preserved byte-for-byte as `review/R82-r1-snapshot.md`. Repair actor:
`repair-opus-2026-09-26T190316Z-971c9d005dbf-r2`, a fresh Claude Opus 5.5 context
(`claude-opus-5-5`). The recommendation does not move.

1. **Finding 1 — lychee never executed (RUNBOOK §5).** Under the controller's RUNBOOK §3 bounded
   supplementary execution, this revision fetched the pinned lychee 0.24.2 release asset for one
   environment (macOS arm64), verified its digest, and ran the exact `hygiene` arguments with the
   proposed `lychee.toml` against a fixture, plus the scheduled-job flags against a closed
   localhost port. New evidence: `review/evidence/r82-lychee-offline.sh` and its log, cases
   `L0`–`L4` under `## Empirical check`. AC1 and AC3 change from "proposed" to "executed"; gap 1,
   the F349 and F350 confidence lines and the "Not executed" line are updated to match.
2. **Finding 2 — question 5's clause "without failing the build when it is not".** Answer 5 now
   addresses that clause and interprets the executed case `G4a` (with `G4b`, `G4c`). No new
   execution was needed; the cases were already in `r82-rustdoc-gate.log`.

Revision 2's checks are dated **2026-09-28 UTC** (host clock 2026-09-27 21:33 PDT at the start of
the repair). `r82-rustdoc-gate.sh` and `r82-upstream-reads.sh` are untouched and were not rerun;
`r82-decision-integrity.sh` was updated for the revision-2 title and the new `L` cases, and rerun.

**Revision note, revision 1.** This is the first synthesis of R82. It reads the two raw reports of
run `2026-09-26T190316Z-971c9d005dbf` in full — `raw/muse.md` (Muse leg, actor
`research-muse-2026-09-26T190316Z-971c9d005dbf`, `raw/muse.md:3`) and `raw/opus.md` (Claude Opus
leg, `claude-opus-5-5`, `raw/opus.md:3`) — and no other attempt. Nothing has been published for
R82, so there is no `## Supersedes`. Synthesizer: actor
`synth-opus-2026-09-26T190316Z-971c9d005dbf-r1`, a fresh Claude Opus 5.5 context
(`claude-opus-5-5`) that produced neither raw report and no evidence check before this one. It is
**the same model family as the Opus leg**; RUNBOOK §2 counts a fresh context as independent
work, not as a new model family.

**Dates.** Every check this decision ran itself is dated **2026-09-27 UTC** (the host clock read
2026-09-26 20:03 PDT at the start of the run, which is 2026-09-27 03:03 UTC). Figures carried from a
raw report keep that report's retrieval date, 2026-09-26.

**Read scope.** Per the dispatch, this synthesis read only the run directory, the item prompt,
`research/RUNBOOK.md`, the two prerequisite decisions R11 and R69 named in
`inputs/prerequisites.json`, R53's published decision as the shape model, and the live
`research/EXECUTION.json` (for R82's engine entry only). The research index `research/CLAUDE.md`
was not opened deliberately; the harness attached it to this session's context, and Engines
disagreement 11 cites it. It did **not** open
R81's or R34's decisions. Both are `related`, not prerequisites: R81 owns no registry parameter,
and R34 is absent from the prompt's `- consumes:` line (prompt line 23). Every statement below
about their content is attributed to the Opus leg and marked unverified by this synthesis.

**Inputs gap for the controller.** The run's `inputs/prompt.md` (sha256 `3757ab1f…932`) and
`manifest.json` (`required_engines: codex, opus`) predate owner decision Q17.A (2026-09-27,
`research/RUNBOOK.md:73-78`). The topic prompt differs from the run's `inputs/prompt.md` at
exactly two lines: line 25 now reads `- engines: muse, opus`, and line 71 gains the sentence
"This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot". The live
`research/EXECUTION.json` lists R82 under `engine_overrides` as `muse, opus`. No research content
differs, but the recorded input snapshot does not match the engines that ran. RUNBOOK §3 ("Changed
prompt, policy … revalidate") applies; this synthesis cannot rewrite the manifest (no runner
commands).

## Decision

**Status.** This decision is a proposal that the implementation phase validates, as R11's is
(`research/topics/11-ci-workflow-job-structure/DECISION.md:86`). The template has no `.github/`
tree, no docs tree and no Rust source yet. Nothing below has run on a GitHub-hosted runner.

**Recommendation — one stack.** One link checker, invoked twice, plus the toolchain's own
`rustdoc` with warnings denied:

| Part | Ledger row | Tool and invocation | Where it runs | Blocks a PR? |
|---|---|---|---|---|
| Internal and relative links in the prose tree | F349 | `lychee` 0.24.2 via `lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8` (tag `v2.9.0`), args `--offline --no-progress --root-dir "$(pwd)" .`, config `lychee.toml` | a step of R11's always-run `hygiene` job, never path-gated | yes |
| External URLs | F350 | the same pinned action and `lychee.toml`, network mode, with a result cache, retries and a timeout | its own job in R34's scheduled lane, never in `ci.yml` | no; a failed scheduled run is the report |
| API reference (rustdoc) | F353 | `cargo doc --locked --workspace --no-deps --all-features --document-private-items` with `RUSTDOCFLAGS: -D warnings` set on that step only | R11's `check` job, `Doc build` step, on both `ubuntu-latest` and `macos-latest` | yes |

No crate enters the template's `Cargo.toml`. `lychee` is a prebuilt CI binary, and `rustdoc`
ships with every Rust toolchain.

**Answers to the prompt's five questions.**

1. **HIGH — is `lychee` the single tool for both link parts?** Yes for internal and external links,
   as **one tool and one config with two invocations**, not one invocation. Both legs agree on the
   tool. `--offline` restricts lychee's accepted URL schemes to `file`
   (`lychee-bin/src/client.rs:22-27` at tag `lychee-v0.24.2`, read in check `U3`). A URL whose
   scheme is not accepted is filtered out (`lychee-lib/src/filter/mod.rs:172-177` and `:221-222`,
   check `U4`). Exit code 2 counts only "non-excluded" link failures (lychee README `:752`, check
   `U6`). So offline mode **skips** external URLs rather than failing them, which settles the
   question the Muse leg left open (`raw/muse.md:436-439`) from source; revision 2's executed cases
   `L1` and `L2` confirm it (the external URL is counted as excluded). lychee does not replace
   rustdoc: intra-doc links are resolved by rustdoc itself.
2. **HIGH — does `RUSTDOCFLAGS="-D warnings"` make `cargo doc` fail on broken intra-doc links, and
   is it free?** Yes, and yes. A broken link warns and exits 0 without the flag (`G1b`) and exits
   101 with it (`G1c`), on 1.98.1 and on the 1.96.0 floor. It needs no crate and no config. Three
   command details are required for it to cover the template, each shown by an executed case below:
   `--workspace` (`G2`), a feature selection that includes every gated module (`G3`–`G5`), and
   `--document-private-items` for private items (`G6`).
3. **MEDIUM — which docs surface does the link checker walk?** The Markdown sources, never a build
   artifact. Sources exist under any delivery model R81 picks; a built site does not exist in R11's
   build-free `hygiene` job. Both legs agree.
4. **MEDIUM — cadence and flakiness for external links?** Scheduled, never a required PR check.
   Both source repositories keep network checking off the PR path (py runs it weekly; ts has none),
   and so do the practice examples this synthesis re-read: lychee's own `links.yml` triggers only on
   `schedule` (`cron: "00 18 * * *"`), `repository_dispatch` and `workflow_dispatch`, and
   ZcashFoundation/zebra's `advisory.yml` runs lychee on `cron: "0 8 * * 1"` plus
   `workflow_dispatch` (check `U10`). Flakiness controls: retries, a timeout, a cache that does not
   store transient failures, the default `GITHUB_TOKEN` for `github.com` links, and an explicit
   exclusion list.
5. **LOW — `--all-features` or an explicit feature list?** `--all-features`. This decision departs
   from the Opus leg here; see Engines, disagreement 3. With today's single `web` feature the two
   forms resolve to the same feature set and share one doc unit (`G10`: the second run is `Fresh`,
   0 units re-documented). When a nested feature such as R78's `otel = ["web", …]` lands,
   `--features web` silently stops documenting the nested module, so a broken link there passes
   (`G5a`, exit 0), while `--all-features` fails it (`G5b`, exit 101).
   On the clause "without failing the build when it is not" (prompt line 37): the gate always runs
   `--all-features`, so the CI gate never builds feature-off docs, and unlike `--features web` it
   does not error before the `web` feature is declared (carried from the judgment audit's repair
   text; not executed here). A feature-off doc build is **not**
   protected: `G4a` shows that when ungated facade docs link into the gated surface
   (``[`web::serve`]``), plain `cargo doc` under `-D warnings` exits 101, while the same tree passes
   with `--features web` or `--all-features` (`G4b`, `G4c`, exit 0). This decision **accepts**
   that: every gated invocation (the CI `Doc build` step and `just docs-api`) enables all features,
   and without `-D warnings` the feature-off build only warns, as `G1b` shows for a broken link.
   The mitigation for an author who wants feature-off `-D warnings` builds to pass is to keep such
   links inside gated items or behind `cfg_attr(feature = "web", doc = …)`; it is named here and
   **not executed**.

**Settled ledger rows.**

| Row | Before (verdict `DIVERGENT`) | Settled as |
|---|---|---|
| F348 the CI docs-correctness gate itself | py: `sphinx-build -W` blocks the PR (`ci.yml:242`); ts: `just docs-check` blocks the PR on relative links (`ci.yml:98`) (prompt line 8) | two blocking steps: offline `lychee` in `hygiene` (F349) and `cargo doc` with `-D warnings` in `check` (F353) |
| F349 offline relative-link checker | py: none beyond Sphinx `-W`; ts: `scripts/check-links.mjs` | `lychee --offline` step in `hygiene` |
| F350 external URL check | py: weekly `sphinx-build -b linkcheck`; ts: none | scheduled `lychee` job in R34's lane |
| F353 API-reference generator | py: autodoc configured, unused; ts: TypeDoc optional, ungated | CI-gated `cargo doc` with `-D warnings` |

`BASELINE-REVIEW: F353 — a configured API-reference generator must be a gated one — proposed change: from the shared "configured-but-unused" latent posture (py sphinx.ext.autodoc wired with zero directives, docs/source/conf.py:27; ts TypeDoc as the optional ungated just docs-api, Justfile:203; prompt line 9) to cargo doc gated by RUSTDOCFLAGS=-D warnings in R11's check job — evidence: rustdoc ships with the toolchain, so the cost reason for the latent posture does not apply; R11 already reserves the step (research/topics/11-ci-workflow-job-structure/DECISION.md:294); executed cases G1c and G3b fail the build on 1.98.1 and 1.96.0; affected items: R11 (step flags), R32 (doctest step must not inherit the flag).`

### Principles and implementation

**Shared requirement.** Documentation that ships with the template must not silently rot. A broken
reference must fail a check the author sees before merge when the failure is deterministic, and
must be reported on a schedule when it is not. Source: py blocks PRs with `sphinx-build -W` and
runs external link checking weekly; ts blocks PRs on relative links only (prompt line 8). The
Opus leg quotes py's own reason, "Link checking is external-network-flaky, so it lives in the weekly
workflow" (`raw/opus.md:114-117`, carried; py was not re-read here).

**Agreement level: policy, not mechanism.**

- **P1** — deterministic, offline correctness is a blocking pull-request gate.
- **P2** — network-dependent checking never blocks a pull request.

The mechanisms (Sphinx, a Node script) do not transfer to a Rust template and need not agree. What
may vary: the tool, whether anchors are checked, the scheduled cadence (R34's), and job topology
(R11's).

**Essential behaviors.**

| Id | Behavior | Principle |
|---|---|---|
| B1 | Every relative link in the tracked Markdown resolves to an existing file, offline, on every PR; failure exits non-zero | P1 |
| B2 | Every intra-doc link in the workspace's API docs resolves, including feature-gated and private items, on every PR that can change Rust code; failure exits non-zero | P1 (the `sphinx-build -W` parity point) |
| B3 | External URLs are checked with retries, a timeout, a cache and an exclusion list, on a schedule, never as a required PR check | P2 |
| B4 | The link gate reads Markdown sources, so it does not depend on R81's delivery model | P1 |

**Architectural alternatives, compared before tools.**

| Alternative | Verdict and reason |
|---|---|
| Check Markdown sources | **Chosen** for F349: works for a plain tree and for a built site, because both keep sources; needs no build in `hygiene` |
| Check a built site (`hyperlink` over mdBook output) | Not chosen: needs a build step R11 keeps out of `hygiene`; `hyperlink` has no network mode, so F350 would still need lychee |
| Renderer-integrated check (`mdbook-linkcheck` or its fork `mdbook-linkcheck2`) | Not chosen: couples the gate to mdBook and cannot check a plain tree |
| One network invocation on every PR | Rejected by P2: external reachability is non-deterministic |
| One tool, two invocations | **Chosen** for F349 + F350: one pinned binary, one config file |
| Hand-written script (ts precedent) | Rejected: covers F349 only; ts's stated reason, lychee "not installed on this machine/CI image" (Opus quoting `check-links.mjs:5-6`, `raw/opus.md:177`), no longer holds once the action installs a prebuilt binary |
| rustdoc gate by `RUSTDOCFLAGS=-D warnings` | **Chosen** for F353: every warn-by-default rustdoc lint fails, including lints later toolchains add, which is Sphinx `-W`'s open-ended strictness |
| rustdoc gate by `[workspace.lints.rustdoc]` | Runner-up: also fails the build (the Opus leg's executed E3, `raw/opus.md:794`), but fails only listed lints; the shared lint table belongs to the lint-policy items |
| Post-build HTML scraping of `target/doc` (`cargo-deadlinks`) | Rejected: redundant, since rustdoc resolves intra-doc links itself (`G1c`); no release since 2021-10-13 |

**Implementation — the `hygiene` step (F349, blocking).**

```yaml
      - name: Docs link check, offline (R82)
        uses: lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0
        with:
          lycheeVersion: v0.24.2
          args: >-
            --offline
            --no-progress
            --root-dir "$(pwd)"
            .
          fail: true
```

- The SHA is the commit that tag `v2.9.0` points to (`U1`: `object.type=commit`). The pin format
  (full SHA plus version comment) is R20's.
- `lycheeVersion: v0.24.2` equals the action's own default at that tag (`action.yml:28-30`, `U2`).
  It is written out so that the binary version is visible where re-verification looks for it.
- `--root-dir "$(pwd)"` is the form lychee-action's README uses (`README.md:81` at `v2.9.0`, `U6b`).
  lychee needs it only when a file contains root-relative links (`/docs/x.md`).
- The input `.` walks the repository and skips files ignored by `.gitignore` (lychee README
  `:644-645`, `U6`), so a local `target/` is skipped when it is ignored; `lychee.toml` excludes it
  anyway.
- `--include-fragments` is **not** in the blocking step in revision 1. See Engines, disagreement 4.

**Implementation — `lychee.toml` at the repository root.** lychee reads a file of this name by
default (`[default: lychee.toml]`, README `:392`, `U6`), so neither invocation needs `--config`.

```toml
exclude_path = ["target"]
# Hosts that reject automated checkers or rate-limit hard. Add one regex per host,
# each with a comment naming the observed failure.
exclude = []
```

**Implementation — the scheduled job (F350, reporting).** A job in R34's scheduled workflow, not a
leg of R34's freshness matrix. The Opus leg reports R34's file as `.github/workflows/canary.yml`,
weekly plus `workflow_dispatch` (`raw/opus.md:145-148`); **this synthesis did not verify that**.
R11 fixes only that the job belongs to R34's lane and not to `ci.yml`
(`research/topics/11-ci-workflow-job-structure/DECISION.md:294`).

```yaml
  docs-external-links:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@<R20-pinned sha>
        with:
          persist-credentials: false
      - name: Restore lychee cache
        uses: actions/cache/restore@<R20-pinned sha>
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
          restore-keys: cache-lychee-
      - name: External link check (R82)
        uses: lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0
        with:
          lycheeVersion: v0.24.2
          args: >-
            --cache --max-cache-age 1d
            --cache-exclude-status '429, 500..'
            --max-retries 3 --retry-wait-time 2 --timeout 20
            --accept '100..=103, 200..=299, 429'
            --no-progress
            --root-dir "$(pwd)"
            .
          fail: true
      - name: Save lychee cache
        if: ${{ !cancelled() }}
        uses: actions/cache/save@<R20-pinned sha>
        with:
          path: .lycheecache
          key: cache-lychee-${{ github.sha }}
```

- Every flag exists in lychee 0.24.2's parameter block (README lines `331`, `394`, `397`, `613`,
  `623`, `683`, `694`, `719`; `U6`). The range syntax of `--accept` and `--cache-exclude-status`
  and the defaults are carried from the Opus leg's README read (`raw/opus.md:504-507`). Revision 2
  executed these flags against a closed localhost port (`L4`): they parse, the dead URL is reported
  and the run exits 2, and `.lycheecache` is written. No real external host was contacted.
- The restore/save cache pair with `restore-keys: cache-lychee-` is lychee-action's own README
  pattern (`README.md:108-110` at `v2.9.0`, `U6b`).
- The action's `token` input defaults to `${{ github.token }}` (`action.yml:40-42`, `U2`), which
  lychee uses for `github.com` links.
- Accepting 429 treats "rate-limited" as not-broken. The Opus leg reports rolldown and dioxus do the
  same (`raw/opus.md:98-99`, carried).

**Implementation — the `check` job's doc step (F353, blocking).**

```yaml
      - name: Doc build
        if: ${{ !cancelled() }}
        env:
          RUSTDOCFLAGS: -D warnings
        run: cargo doc --locked --workspace --no-deps --all-features --document-private-items
```

| Flag | Why it is required | Executed evidence (1.98.1 and 1.96.0 alike) |
|---|---|---|
| `RUSTDOCFLAGS: -D warnings` | turns all 7 warn-by-default rustdoc lints into errors | `G0` lists the 7; `G1c` broken link → 101; `G8a` bare URL → 101 |
| `--workspace` | the template's root is a package, so without it `cargo doc` documents only the root package | `G2a`–`G2c`: broken link in member `crates/core` → **exit 0** without it; `G2d` → 101 with it |
| `--all-features` | documents every feature-gated module | `G3a` broken link in `cfg(feature = "web")` module, no feature → exit 0; `G3b`/`G3c` → 101; `G5a`/`G5b` nested feature |
| `--document-private-items` | extends the gate to private items' docs | `G6a` private broken link → exit 0 without it; `G6b` → 101 with it |
| `--no-deps` | dependency docs are not this template's burden | all cases |
| `--locked` | R11 requires it on every cargo command | all cases |
| `env:` on the step, not the job | cargo also passes `RUSTDOCFLAGS` to `rustdoc --test` | `G9c`: the doctest `rustdoc --test` argv carries `-D warnings`; `G9a`/`G9b`: no behavioural change was observed for the case tried |

What `-D warnings` does **not** do: it does not deny rustc lints raised while the doc build
type-checks the crate. An unused import prints a warning and the build exits 0 (`G7a`, `G7b`).
Those lints are clippy's and rustc's job in R11's earlier `check` steps.

**Fitness gates.** Gate 1 (licence) is `inapplicable` under owner ruling Q7.B as recorded in R53's
published decision (`research/topics/53-config-schema-validation/DECISION.md:45-47`); licences are
reported as metadata only, and nothing is excluded on licence.

| Gate | `lychee` 0.24.2 (prebuilt, via the action) | `rustdoc` (toolchain component) |
|---|---|---|
| 1 licence | `Apache-2.0 OR MIT` (`U5`, `U7`), metadata only | toolchain, not a dependency |
| 2 MSRV | `rust-version = "1.88.0"` (`U5`); never enters the template's dependency graph | lint set and behaviour identical on 1.96.0 and 1.98.1 (`G0`–`G10`) |
| 3 advisories, `unsafe` | rustsec 404 for `lychee` and `lychee-lib`, positive control `time` 200 (`U9`); the Opus leg read no `#![forbid(unsafe_code)]` in either crate root (`raw/opus.md:353`, carried) | inapplicable to a toolchain component |
| 4 OS matrix | runs only in `hygiene` and the scheduled job, both `ubuntu-latest` by R11's rule; darwin release assets exist for local use (`raw/opus.md:354`, carried) | runs in `check` on both OSes; executed locally on macOS arm64 only |
| 5 features, runtime | `tokio` inside a prebuilt binary; irrelevant to the template's graph | the template's own feature question, answered by `--all-features` |
| 6 size, compile cost | zero compile cost to the template | rustdoc over workspace crates; dependency metadata is shared with `check`'s earlier steps when the feature sets match (`G10`) |

### Members

#### F349 — lychee, offline internal-link check

- **Dominant choice:** `lychee` 0.24.2, released 2026-05-01T15:41:34Z (`U7`). Maintenance
  `active`: 7 of its 10 most recently opened issues answered by a maintainer, median 0.09 days
  (`U8`, re-counted; matches `raw/opus.md:299`).
- **Qualified shortlist:** `hyperlink` 0.3.2 (built HTML only; `active`, maintainer median 0.15 days
  over 8/10 by `U8`) and `mlc` 1.2.0 (`at-risk`: 2 of 10 answered, median 4.67 days, `U8`).
- **Excluded:** `mdbook-linkcheck` 0.7.7 — cannot check a plain tree, and `at-risk`: open #96 "fails
  on mdbook 0.5", open #92, 0 of 10 maintainer responses, repository last pushed 2024-08-15 (`U8`,
  `U8b`). Non-Rust tools (`markdown-link-check`, Sphinx, `check-links.mjs`) would add a Node or
  Python runtime to `hygiene`.
- **Up-and-comer:** `mdbook-linkcheck2` 0.13.0 (the Opus leg reports rust-lang/rustc-dev-guide uses
  it, `raw/opus.md:101`, carried) — a candidate only if a built-site check is ever added.
- **Ranked runner-up:** `hyperlink`, for checking a rendered mdBook site in addition to sources.
- **Confidence:** high on the tool and on `--offline` semantics (read at the release tag, and
  **executed** in revision 2 with the pinned 0.24.2 binary: `L1`–`L3`); neither leg ran it, and no
  GitHub Actions run has (see gaps).

#### F350 — lychee, scheduled external-URL check

- **Dominant choice:** the same pinned binary and `lychee.toml`, network mode, in R34's lane.
- **Qualified shortlist:** `mlc` 1.2.0 (network-capable; `at-risk` by `U8`), `mdbook-linkcheck2`
  with web links (ties the lane to `mdbook build`).
- **Excluded:** `hyperlink` lacks a network mode; `mdbook-linkcheck` as above.
- **Ranked runner-up:** the same tool plus a non-blocking PR run limited to URLs the diff adds
  (the rerun pattern the Opus leg reports, `raw/opus.md:554-556`); rejected because it needs a
  custom diff script.
- **Tradeoff:** a broken external URL can merge and live until the next scheduled run; accepted, as
  py accepts it.
- **Confidence:** high that external checking stays off the PR path; medium on the exact retry and
  accept values (practice-derived; the flags parse and report a dead localhost URL in `L4`, but no
  real external host was checked).

#### F353 — rustdoc, API-reference gate

- **Dominant choice:** `RUSTDOCFLAGS=-D warnings` on `cargo doc`. Practice re-read in `U10`:
  ripgrep runs `RUSTDOCFLAGS: -D warnings` with `cargo doc --no-deps --document-private-items
  --workspace` (`ci.yml:245-246`); lychee runs `RUSTDOCFLAGS: -D warnings` with
  `cargo doc --workspace --no-deps` (`ci.yml:19,68-70`); axum runs
  `RUSTDOCFLAGS: "-D rustdoc::all -A rustdoc::private-doc-tests"` with `--all-features --no-deps`
  per package (`CI.yml:42-49`).
- **Qualified shortlist:** the manifest lint table (runner-up, above); axum's `-D rustdoc::all`
  (stricter, adds allow-by-default lints).
- **Excluded:** `cargo docs-rs` and `--cfg docsrs` need nightly and fail the stable-only
  constraint (Opus leg, `raw/opus.md:659-660`, carried); `cargo-deadlinks` is redundant and
  `at-risk`: 0 of its 10 most recent issues have a maintainer response (`U8`), no release since
  2021-10-13.
- **Up-and-comers:** none; the space belongs to the toolchain's own lints.
- **Confidence:** high — every flag's effect executed on the current stable and the MSRV floor.

### Compatibility

The members share no library boundary: lychee is a prebuilt binary that never links against the
template, and rustdoc is the toolchain. One maintained repository runs the exact pairing:
lycheeverse/lychee gates its own `cargo doc --workspace --no-deps` with `RUSTDOCFLAGS: -D warnings`
(`ci.yml:19,68-70`) and runs its lychee link check on a schedule only (`links.yml:3-7`), both
re-read in `U10`. The Muse leg's gap "no shared adopter" (`raw/muse.md:718-719`) is closed by that
read. Version matrix: lychee 0.24.2 × lychee-action v2.9.0 (whose default `lycheeVersion` is
v0.24.2) × rustdoc 1.96.0–1.98.1 (executed).

### Migration implications

| File | Change | Owner of the surrounding structure |
|---|---|---|
| `.github/workflows/ci.yml`, job `hygiene` | add the offline lychee step | R11 (placement), R20 (pin format) |
| `.github/workflows/ci.yml`, job `check`, step `Doc build` | step-level `env: RUSTDOCFLAGS: -D warnings`; command as above | R11 (step), R82 (flags) |
| R34's scheduled workflow | add the `docs-external-links` job | R34 (file and cadence) |
| `lychee.toml` (new, root) | `exclude_path`, `exclude` | R82 |
| `.gitignore` | add `.lycheecache` | R82 |
| `Justfile` | `docs-check` → `lychee --offline --no-progress --root-dir "$(pwd)" .`; `docs-api` → `RUSTDOCFLAGS="-D warnings" cargo doc --locked --workspace --no-deps --all-features --document-private-items` | the task-runner item |
| contributor docs | one line: install `lychee` to run `just docs-check` locally | R81's docs tree |

No `Cargo.toml`, feature or dependency change. The template carries no Sphinx configuration and
no `check-links.mjs`.

### Acceptance criteria and what P03 must validate

| Id | Criterion | Status |
|---|---|---|
| AC1 | A PR adding `[x](docs/missing.md)` to any tracked Markdown file fails `hygiene` with lychee exit 2 | **executed locally** with the pinned 0.24.2 binary and the exact `hygiene` args (`L1`: exit 2 naming only `docs/missing.md`; `L2`: exit 0 without it); CI leg proposed |
| AC2 | A PR adding a broken intra-doc link, including inside the `web`-gated module or a private item, fails `check`'s `Doc build` on both OS legs | **executed locally** (`G1c`, `G3b`, `G3c`, `G6b`); CI leg proposed |
| AC3 | A PR adding an unreachable external URL fails no required check | **executed locally** (`L1`, `L1v`, `L2`: the external URL is excluded and contributes no failure), confirming the source reads `U3`, `U4`; CI leg proposed |
| AC4 | A dispatched scheduled run reports that URL as broken | **proposed** |
| AC5 | The doctest step does not inherit the doc step's `RUSTDOCFLAGS` | **proposed** for CI; the leak path is executed (`G9c`) |
| AC6 | `--include-fragments` produces no false positives on the template's real headings under GitHub and mdBook rendering; only then may it join the blocking step | **proposed** |

**Gaps, recorded.**

1. **lychee execution — closed in revision 2 by RUNBOOK §3 supplementary execution.** Neither the
   Muse leg (`raw/muse.md:432-433`) nor the Opus leg (`raw/opus.md:35-40`) ran lychee, and revision
   1 did not either: every install path lies outside the prompt's named endpoints. The controller
   then authorized one bounded fetch of the pinned release asset. Revision 2 ran the F349 command
   (`L1`–`L3`) and the F350 flags (`L4`) with lychee 0.24.2 on macOS arm64, so RUNBOOK §5's
   execution clause is met for both, and the empirical auditor can rerun
   `r82-lychee-offline.sh`. What remains unexecuted: any GitHub Actions run of lychee-action, the
   Linux x86_64 asset the action downloads, `.gitignore` skipping (the fixture is not a git
   repository), and network mode against real external hosts.
2. R81 and R34 content is carried from the Opus leg and not verified here (read scope above). In
   particular the Opus leg's claims that R81 wants `docs/SUMMARY.md` treated as the navigation
   source and forbids `{ #id }` heading attributes (`raw/opus.md:137-145`) should be confirmed
   against R81's decision before acceptance.
3. lychee-action installs the binary with `curl -sfLO` and `tar -xvzf` and no checksum step
   (`action.yml:89`, `:92`, `U2`). A SHA-pinned action pins the installer script, not the binary.
   Noted for R20 and R08.
4. The fixtures model axum and tokio by the modules they gate, not by the crates (no registry
   access). Real-dependency doc-build cost and intra-doc links into those crates are unmeasured.
5. Orphan pages (a file under `docs/` that no link reaches) are not a link property and are not
   caught by this gate (Opus leg, `raw/opus.md:144-145`).
6. Neither leg has an operation record: the run's `operations/` directory is empty and
   `manifest.json` records `operations: {}`. RUNBOOK §2 requires actual resolved models and
   says embedded labels do not establish them. The Muse leg's resolved model is therefore
   unrecorded, and the Opus leg's `claude-opus-5-5` rests on its own self-report. The controller
   should attach both operation records before acceptance.

re-verify: 2027-03-27, or earlier on any of — a lychee 0.25 or 1.x release, or a lychee-action v3 release; tag `v2.9.0` of `lycheeverse/lychee-action` resolving to a commit other than `e7477775783ea5526144ba13e8db5eec57747ce8`; R69 revision 10 publishing (member layout `crates/web`; both layouts are covered by `G2`–`G5`, but the `assumes web-extra-surface` line must be re-derived); R78 or R79 adding a feature that cannot be enabled together with the others, which would break `--all-features`; R02 changing the package graph; R81 or R34 revising, or this decision's carried statements about them failing confirmation; R11 changing its `Doc build` step or `hygiene` placement; a Rust release that promotes an allow-by-default rustdoc lint or changes the warn-by-default set shown in `G0`; P03 enabling `--include-fragments`; the supplementary lychee execution of gap 1 contradicting any lychee behaviour recorded here

## Parameters

R82 owns no registry parameter: the prompt's `- owns:` line is empty (prompt line 22). It consumes
two researched parameters (prompt line 23), and the four fixed parameters apply. The values below
are byte-identical to `inputs/parameters.json` (checked by `r82-decision-integrity.sh`).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner

**No `CONFLICT:` line.** The recommendation fits every consumed value as written.

- From `ci-job-structure`, this decision relies on four statements, all in R11's slot row for R82
  (`research/topics/11-ci-workflow-job-structure/DECISION.md:294`): the link check is a step of
  `hygiene`; it is never path-gated; the rustdoc part is `check`'s doc build step whose flags are
  R82's; an external-URL check on a schedule belongs to R34's lane, not `ci.yml`. It adds nothing
  that compiles to `hygiene`.
- From `web-extra-surface`, it relies on "consumers select the surface with --features web or
  --all-features". `--all-features` is one of the two sanctioned selectors.
- R69 revision 10 is owner-accepted but not published, as R11 records
  (`research/topics/11-ci-workflow-job-structure/DECISION.md:329`). It moves the web surface into a
  `crates/web` member. That is a pending publication, not a disagreement, so it is not a
  `CONFLICT:`. The recommended command covers both layouts (`G2`–`G5` use both).
- The fixed parameters: edition 2024 and `rust-version = "1.96"` in both fixtures; the gate runs in
  `check` on both OSes of `target-os-matrix`; the floor behaviour is executed (`G0`–`G10` on
  1.96.0). R11's `msrv-floor` job runs only the declared-floor check, so the doc gate does **not**
  run on the floor in CI; the floor results show the gate would behave the same there.

## Empirical check

**Host and toolchains, read from the tools.** macOS `Darwin 25.4.0 arm64`. Current stable:
Homebrew `cargo 1.98.1 (797e8a9bc 2026-08-05)`, `rustdoc 1.98.1 (48a229cea 2026-09-01)`. MSRV floor
(stable minus 2): rustup `cargo 1.96.0 (30a34c682 2026-05-25)`, `rustdoc 1.96.0 (ac68faa20
2026-05-25)`, invoked as `rustup run 1.96.0`. `shellcheck` at `/opt/homebrew/bin/shellcheck`;
`gh version 2.101.0`. A private `CARGO_HOME` (`/tmp/cargo-s13-R82`), `CARGO_NET_OFFLINE=true`, no
registry dependency in either fixture. Revision 2 adds `lychee 0.24.2`, the release asset
`lychee-aarch64-apple-darwin.tar.gz` from tag `lychee-v0.24.2`, fetched once into a scratch
directory; its sha256 `c9d3740e…4977` matches both the release API digest and the `.sha256`
sidecar (`L0`).

**Working directory:** the repository root `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`.
Each script builds its fixtures under one `mktemp -d` directory and deletes it on exit.

| Script | Log | What it checks | Rerun |
|---|---|---|---|
| `review/evidence/r82-rustdoc-gate.sh` | `r82-rustdoc-gate.log` | the F353 command, 27 cases per toolchain (G0–G10) on two fixture layouts | fresh, 2026-09-27T03:05:10Z |
| `review/evidence/r82-upstream-reads.sh` | `r82-upstream-reads.log` | lychee-action tag, `action.yml`, lychee source and README at the release tag, crates.io, maintainer responsiveness, rustsec, practice workflows (U1–U10) | fresh; the final run is the one logged |
| `review/evidence/r82-lychee-offline.sh` | `r82-lychee-offline.log` | the F349 `hygiene` args with the proposed `lychee.toml` (extracted from this file) and the F350 flags, with the pinned lychee 0.24.2 binary (L0–L4) | fresh, revision 2, 2026-09-28 |
| `review/evidence/r82-decision-integrity.sh` | `r82-decision-integrity.log` | the six `assumes` lines against `inputs/parameters.json`; prerequisite decision hashes; every file:line citation in this decision | fresh, after revision 2 was written |

Command form: `bash review/evidence/<script>.sh > review/evidence/<script>.log 2>&1`, run from the
run directory. All four pass `shellcheck` with no findings (`r82-rustdoc-gate.sh` disables SC2016
once, because its backticks are literal rustdoc link syntax).

**Fixtures.** Layout A models R69 revision 9 as registered: the root package hosts the binaries,
declares `web = []`, and gates the in-crate module `src/web/`; one member, `crates/core`. Layout B
models the member layout R11 describes for R69 revision 10 (root facade plus `crates/{core,cli,web}`,
`web = ["dep:rslb-web"]`) and adds `otel = ["web"]` as a stand-in for R78. Each case copies the
clean fixture, applies one mutation, runs one command, and records the exit code and the
`error:`/`warning:` lines.

**Observed results (identical on 1.98.1 and 1.96.0).** `DOC` abbreviates
`cargo doc --locked --workspace --no-deps`; flags are `RUSTDOCFLAGS=-D warnings` unless noted.

| Case | Mutation | Command | Exit | Key output |
|---|---|---|---|---|
| G0 | — | `rustdoc -W help` | — | 11 `rustdoc::` lints, 4 allow, 7 warn |
| G1a | none | `DOC --all-features` | 0 | — |
| G1b | broken link in `crates/core` | same, **no** `RUSTDOCFLAGS` | 0 | ``warning: unresolved link to `Nope` `` |
| G1c | same | `DOC --all-features` | 101 | ``error: unresolved link to `Nope` ``; `-D rustdoc::broken-intra-doc-links` implied by `-D warnings` |
| G2a | same | `cargo doc --no-deps --all-features` (Muse's command) | **0** | none — member not documented |
| G2b | same | Muse's command plus `--locked` | **0** | none |
| G2c | same, layout B | Muse's command plus `--locked` | **0** | none |
| G2d | same, layout B | `DOC --all-features` | 101 | ``error: unresolved link to `Nope` `` |
| G3a | broken link in `src/web/` (layout A) | `DOC` (feature off) | **0** | none — module not compiled |
| G3b | same | `DOC --features web` | 101 | ``error: unresolved link to `crate::Missing` `` |
| G3c | same | `DOC --all-features` | 101 | same |
| G4a | facade links ``[`web::serve`]`` (layout B) | `DOC` | 101 | ``error: unresolved link to `web::serve` `` |
| G4b / G4c | same | `DOC --features web` / `--all-features` | 0 / 0 | — |
| G5a | broken link in the `otel` module (layout B) | `DOC --features web` | **0** | none — module not compiled |
| G5b | same | `DOC --all-features` | 101 | ``error: unresolved link to `crate::NoExporter` `` |
| G6a | private fn with a broken link | `DOC --all-features` | **0** | none |
| G6b | same | `DOC --all-features --document-private-items` | 101 | ``error: unresolved link to `AlsoNope` `` |
| G6c / G6d | public doc links a private fn | `DOC --all-features`, without / with `--document-private-items` | 101 / 101 | ``error: public documentation for `exposed` links to private item `hidden` `` |
| G7a / G7b | unused import in `crates/core` | `DOC --all-features`, without / with `--document-private-items` | 0 / 0 | `warning: unused import` (rustc lint, not denied) |
| G8a | bare URL in a doc comment | `DOC --all-features` | 101 | `error: this URL is not a hyperlink` |
| G9a / G9b | bare URL | `cargo test --locked --doc -p rslb-core`, without / with `RUSTDOCFLAGS` | 0 / 0 | — |
| G9c | none | `RUSTDOCFLAGS="-D warnings" cargo test --locked --doc -p rslb-core -v` | — | 1 `rustdoc … --test` argv line carries `-D warnings` |
| G10 | none | `DOC --features web`, then `DOC --all-features -v` | 0 | second run: `Fresh=2`, `Documenting=0` |

**Upstream reads (named endpoints only; `r82-upstream-reads.log`).**

| Check | Observed |
|---|---|
| U1 | `refs/tags/v2.9.0` → `object.type=commit`, `object.sha=e7477775783ea5526144ba13e8db5eec57747ce8`; releases v2.9.0 2026-07-09, v2.8.0 2026-02-25 |
| U2 | `action.yml` at `v2.9.0` (sha256 `4ec6e0eb…d592`, 133 lines): `fail` default `true`, `failIfEmpty` default `true`, `jobSummary` default `true`, `lycheeVersion` default `v0.24.2`, `token` default `${{ github.token }}`; installer `curl -sfLO` (line 89), `tar -xvzf` (line 92), no checksum line |
| U3 | `lychee-bin/src/client.rs:22-27` at `lychee-v0.24.2`: "Offline mode overrides the scheme" → `vec!["file".to_string()]` |
| U4 | `lychee-lib/src/filter/mod.rs:172-177` `is_scheme_excluded`; `:221-222` applies it when deciding exclusion |
| U5 | `lychee-bin/Cargo.toml`: `edition = "2024"`, `license = "Apache-2.0 OR MIT"`, `rust-version = "1.88.0"` |
| U6 | README at the tag (907 lines): every flag used above present; exit codes 0/1/2/3 at `:746-754`; `.gitignore` skipped unless `--no-ignore` (`:644-645`); config default `lychee.toml` (`:392`); `--include-fragments` without a value means `anchor-only` |
| U6b | lychee-action README at `v2.9.0`: `args: --root-dir "$(pwd)" …` (`:81`); cache example `path: .lycheecache`, `restore-keys: cache-lychee-` (`:108-110`) |
| U7 | crates.io: `lychee` 0.24.2, 2026-05-01T15:41:34Z, `rust_version` 1.88.0 |
| U8 | 10 most recently opened issues, maintainer = `author_association` OWNER/MEMBER/COLLABORATOR: lychee 7/10, median 0.09 d; mlc 2/10, 4.67 d; cargo-deadlinks 0/10; hyperlink 8/10, 0.15 d; mdbook-linkcheck 0/10 |
| U8b | mdbook-linkcheck #92 and #96 open; repository pushed 2024-08-15 |
| U9 | rustsec.org: 404 for lychee, lychee-lib, mlc, cargo-deadlinks, mdbook-linkcheck, hyperlink; 200 for the positive control `time` |
| U10 | lychee `links.yml:3-7` schedule-only; lychee `ci.yml:19,68-70`; zebra `advisory.yml:4-6,38,44`; ripgrep `ci.yml:245-246`; axum `CI.yml:42-49` |

**lychee cases (revision 2; `r82-lychee-offline.log`).** Working directory: a scratch fixture
root, so `"$(pwd)"` is that root. The fixture's `lychee.toml` is the TOML block above, extracted
byte-for-byte from this file. `README.md` holds one good relative link (`docs/guide.md`), one
broken relative link (`docs/missing.md`) and one external URL (`https://example.com/some/page`);
`target/doc/decoy.md` holds a broken link. The fixture is not a git repository.

| Case | Fixture or change | Command | Exit | Key output |
|---|---|---|---|---|
| L0 | — | fetch `lychee-aarch64-apple-darwin.tar.gz` (tag `lychee-v0.24.2`); `lychee --version` | — | sha256 matches the release API digest and the `.sha256` sidecar; `lychee 0.24.2` |
| L1 | as above | `lychee --offline --no-progress --root-dir "$(pwd)" .` (the `hygiene` args) | **2** | one `[ERROR] …/docs/missing.md … File not found`; `4 Total … 2 OK … 1 Error … 1 Excluded`; nothing under `target/` |
| L1v | same | L1 plus `--verbose` | 2 | `[EXCLUDED] https://example.com/some/page`; the proposed `exclude = []` is empty, so the exclusion is the offline scheme filter of `U3`, `U4` |
| L2 | broken relative link removed | the `hygiene` args | **0** | `3 Total … 2 OK … 0 Errors … 1 Excluded` |
| L3 | L1 fixture, `exclude_path = []` | the `hygiene` args | 2 | a second `[ERROR]` for `target/doc/not-there.md`: `exclude_path = ["target"]` in L1 is read and honoured |
| L4 | good link plus `http://127.0.0.1:1/gone` (port checked closed), no other external URL | the scheduled-job args (`--cache … --accept '100..=103, 200..=299, 429' --no-progress --root-dir … .`), network mode | 2 | `[ERROR] http://127.0.0.1:1/gone … Connection refused`; `.lycheecache` written |

The cases confirm: exit 2 names only the broken relative link; the external URL is skipped
offline and contributes no failure; the config file parses and `exclude_path` takes effect; the
scheduled-job flag syntax parses and a dead host fails the run.

**Not executed.** Any GitHub Actions run, including lychee-action and its Linux asset; lychee's
`.gitignore` skipping; network mode against real external hosts (gap 1).

## Engines

| Engine | Report | Identity | Shape check |
|---|---|---|---|
| Muse (Meta) | `raw/muse.md`, 819 lines, sha256 `d52ed1052fd8f923966df5e03487c6a2e812e460ee246cab9f5deb4499ca49cc` | actor `research-muse-2026-09-26T190316Z-971c9d005dbf` (`raw/muse.md:3`); retrieval 2026-09-26; **resolved model unrecorded** — no operation record exists (gap 6), and "Muse (Meta)" comes from the prompt, not a receipt | `scripts/check-answer-shape.sh … bundle` → `OK: validation passed` |
| Claude Opus | `raw/opus.md`, 851 lines, sha256 `fcf8fdfde5add51c03822ac0c4e08cafb83a0a0b8138f38390c2306a935101a9` | `claude-opus-5-5` as self-reported in the raw (`raw/opus.md:3`), no operation record (gap 6); network 2026-09-26 US Pacific, experiments 2026-09-27T00:54Z | `OK: validation passed` |
| Synthesis (this file) | `review/DECISION.md` and three evidence scripts | actor `synth-opus-2026-09-26T190316Z-971c9d005dbf-r1`, fresh `claude-opus-5-5` context; same family as the Opus leg | — |
| Repair, revision 2 | `review/DECISION.md` and `r82-lychee-offline.sh` | actor `repair-opus-2026-09-26T190316Z-971c9d005dbf-r2`, fresh `claude-opus-5-5` context | — |

No evidence-check engine is configured for R82 (the prompt's `- evidence-checks:` line is empty).
Both legs agree on the architecture: lychee for both link parts, offline on PRs and networked on a
schedule, and rustdoc with `-D warnings` in `check`. They disagree on the details below. Each is
resolved by evidence, not by preference.

**Disagreement 1 — `--workspace` on `cargo doc`. Settled for Opus.** Muse recommends
`cargo doc --no-deps --all-features` (`raw/muse.md:599-600`); Opus adds `--workspace`
(`raw/opus.md:625`). With a root package, which both R69 layouts have, Muse's command documents only
the root package, so a broken link in a member passes: exit 0 in `G2a`–`G2c`, exit 101 in `G2d`.
Muse's executed probe used a single-crate scratch project (`raw/muse.md:662-665`), which cannot show
this.

**Disagreement 2 — `--document-private-items`. Settled for Opus.** Muse does not consider it. Opus
includes it (`raw/opus.md:625`). `G6a` (exit 0) and `G6b` (exit 101) show private items' broken
links are invisible without it. ripgrep uses the same flag (`U10`). The cost is that private doc
comments become part of the gate; accepted, because B2 has no public-only qualifier.

**Disagreement 3 — `--all-features` versus `--features web`. Settled for Muse, on new evidence.**
Muse chooses `--all-features` for future nested features (`raw/muse.md:633-635`). Opus chooses
`--features web` so the doc step matches R11's feature-on clippy step and reuses its metadata, with
"both steps change together" when R78 and R79 add features (`raw/opus.md:262-266`). R69 sanctions
both selectors. Today they are the same unit (`G10`), so Opus's cache argument costs nothing now
and gains nothing now. Later, `--features web` fails open: `G5a` shows a broken link in a nested
`otel` module passing. Opus's remedy depends on someone remembering to edit the list, which is the
failure mode R11 designs out of its detector ("a path nobody anticipated runs the gate rather than
skipping it"). `--all-features` fails closed. Its cost arrives only when a nested feature lands: the
doc step then type-checks that feature's dependencies, which the clippy step does not share unless
R11 also uses `--all-features` there. axum, the web framework R69 selected, documents with
`--all-features` (`U10`). The fallback, if a future feature cannot be combined with the others, is
an explicit list of every feature.

**Disagreement 4 — `--include-fragments` in the blocking PR step. Settled against Opus for
revision 1.** Opus includes it (`raw/opus.md:231`), states it was not executed, and names its own
false-positive mode: lychee's heading-slug generation may differ from GitHub's and mdBook's
(`raw/opus.md:402-406`). Muse does not use it. An unexecuted flag with a known false-positive mode
does not belong in a blocking gate. It becomes AC6, to be enabled after P03 validates it; the flag
exists and defaults to `anchor-only` (`U6`).

**Disagreement 5 — PR-step input and config file name. Settled for Opus.** Muse walks
`"**/*.md" README.md` with `--config .lychee.toml` (`raw/muse.md:363-364`, `:418`). Opus walks `.`
with `--root-dir "$(pwd)"` and a root `lychee.toml` (`raw/opus.md:318-322`, `:572-573`). lychee's
default config name is `lychee.toml` (`U6`, README `:392`), so the Opus form needs no `--config`
flag; `.` walks skip `.gitignore`d files (`U6`, `:644-645`); the `$(pwd)` root-dir form is the
action README's own (`U6b`). Muse's glob form is not wrong, but its `.gitignore` behaviour is
unverified and its `README.md` argument duplicates the glob.

**Disagreement 6 — the `--offline` semantics. Settled from source.** Muse leaves open whether
`--offline` skips or fails external URLs and gives a fallback (`raw/muse.md:436-439`). Opus reads
that it skips them (`raw/opus.md:327-331`). This synthesis re-read the tag's source: `U3`, `U4`
and README `:752` agree with Opus, and revision 2's executed `L1v` and `L2` confirm it. The
fallback is not needed.

**Disagreement 7 — maintainer responsiveness figures. Settled for Opus.** Muse reports lychee
median 0.8 days, 5 of 10 (`raw/muse.md:285-286`), and mlc median 1.9 days, 7 of 10, `active`
(`raw/muse.md:296-297`, `:304-307`), counting "first non-OP reply". Opus reports lychee 0.09 days,
7 of 10, and mlc 4.67 days, 2 of 10, `at-risk` (`raw/opus.md:299`, `:301`), counting
maintainer-association comments. The prompt asks for "median days to first maintainer response".
`U8` recounts both methods on the 10 most recently opened issues: lychee 7/10 at 0.09 days and mlc
2/10 at 4.67 days under **both** methods. Muse's figures do not reproduce under either method. mlc
is therefore `at-risk`, with the concrete signal of 8 unanswered issues back to 2025-02.

**Disagreement 8 — `cargo-deadlinks` maintenance state. Settled for Muse.** Muse says `at-risk`
(`raw/muse.md:617-621`); Opus says `stable-quiet` and did not sample issues (`raw/opus.md:304`).
The rubric requires a concrete signal for `at-risk`. `U8` finds 0 of the 10 most recent issues with
a maintainer response, which is that signal. Muse's own count, 1 answered of 10 at 22.2 days
(`raw/muse.md:609`), does not reproduce; `U8` finds 4 non-maintainer replies and no maintainer
reply. The state is `at-risk`; the crate is rejected as redundant regardless.

**Disagreement 9 — `hyperlink` responsiveness.** Muse: median 15.6 days, 2 of 6, over its open
issues only (`raw/muse.md:333-334`). Opus: 0.29 days, 7 of 9, excluding one owner-authored issue
(`raw/opus.md:300`). `U8` on the 10 most recently opened issues: 8/10 at 0.15 days by the
maintainer method, 7/10 at 0.29 days by the non-opener method. Opus's sample is the one the
prompt defines; the state is `active` under every method. It does not change the ranking.

**Disagreement 10 — why `mdbook-linkcheck` is excluded.** Muse: it cannot check a plain tree
(`raw/muse.md:311-314`). Opus: `at-risk` on mdBook 0.5 incompatibility (`raw/opus.md:360-365`).
Both hold; `U8b` confirms #92 and #96 are open. Both reasons are recorded.

**Disagreement 11 — whether R81 and R34 are open.** Muse treats R81 as open and R34 as not yet
landed (`raw/muse.md:114`, `:424`, `:758`). Opus says both resolved (`raw/opus.md:134`). The
research index `research/CLAUDE.md` marks R81 and R34 `resolved`, so Muse's framing is stale. The
design is unaffected, because both legs point the gate at Markdown sources. The Opus leg's
statements about the two decisions' content are carried unverified (gap 2).

**Disagreement 12 — BASELINE-REVIEW findings.** Muse reports none (`raw/muse.md:210-211`) while
recommending the F353 upgrade from the latent posture to a gated check (`raw/muse.md:175-181`).
Opus reports F353 and F350 (`raw/opus.md:218-219`). The mandate asks for a `BASELINE-REVIEW:` line
when a recorded pattern is departed from. The prompt records that both repositories share the
latent, ungated posture for F353 (prompt line 9), so the upgrade departs from a shared baseline and
is carried in `## Decision`. F350 is not carried: its verdict is `DIVERGENT` (py weekly, ts none),
so there is no shared baseline to challenge, and choosing py's side is the research answer itself.

**Disagreement 13 — Muse's reasons for blanket `-D warnings` and the floor.** Muse says blanket
`-D warnings` "also denies rustc warnings emitted during the doc build (e.g. unused imports)"
(`raw/muse.md:626-628`). `G7a` and `G7b` refute it: an unused import warns and the build exits 0.
Blanket denial remains the choice, for the reason Opus gives: it covers every warn-by-default
rustdoc lint, now and later (`G0`, `G8a`). Muse also says the floor toolchain's rustdoc "IS the
gate" (`raw/muse.md:592-594`, `:643`). R11's `msrv-floor` job runs only the declared-floor check
(`research/topics/11-ci-workflow-job-structure/DECISION.md:320` owned value), so the gate runs on
stable in `check`; `G0`–`G10` show the floor would behave identically.

**Disagreement 14 — scoping `RUSTDOCFLAGS` to the step.** Opus requires step scope because cargo
passes `RUSTDOCFLAGS` to `rustdoc --test` (`raw/opus.md:634-635`); Muse is silent. `G9c` confirms
the argv. `G9a`/`G9b` show no outcome change for the one case tried, so the observed effect is on
the invocation, not yet on a result. Step scope costs nothing and keeps R32's doctest step
independent of R82's flags, so it is kept.

**Disagreement 15 — member split.** Muse groups the bundle into two members (link checker,
rustdoc gate); Opus into three, one per ledger row. This decision uses three, so each settled row
maps to one member.

**Uncertainty that remains.** lychee behaviour is executed locally on macOS arm64 (`L0`–`L4`) but
not in GitHub Actions or against real external hosts (gap 1). R81 and R34 content is unverified here (gap 2). The
retry, accept and cache values for the scheduled job are practice-derived.
