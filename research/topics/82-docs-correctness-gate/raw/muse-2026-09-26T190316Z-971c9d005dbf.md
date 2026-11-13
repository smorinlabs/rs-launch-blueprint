# R82 docs-correctness-gate — Muse raw report (Focused tier, bundle kind)

Actor: `research-muse-2026-09-26T190316Z-971c9d005dbf`. Retrieval date for all
figures: 2026-09-26. This report answers
`research/runs/R82/2026-09-26T190316Z-971c9d005dbf/inputs/prompt.md` exactly.

### Landscape

Category decided: the CI gate that keeps the template's documentation
correct — (a) internal/relative-link checking over the markdown tree
(offline-capable, deterministic), (b) external-URL checking (network,
flaky, rate-limited), and (c) API-reference correctness, i.e. broken
intra-doc links in rustdoc output. Two members: `link-checker` (a+b) and
`rustdoc-gate` (c).

Three-bin map of the Rust field (every shortlisted candidate comes from
this map):

- Built-in / first-party toolchain: rustdoc via `cargo doc`
  (+ `RUSTDOCFLAGS="-D warnings"`) for member (c) — ships with every Rust
  toolchain, no crate needed. For members (a+b) there is NO first-party
  tool: neither cargo/rustup nor mdBook ships a link checker
  (mdBook-link checking is third-party; see below).
- Established industry standard: `lychee` 0.24.2 — 3,949 GitHub stars,
  71,555 downloads in the last 90 days, release 2026-05-01, pushed
  2026-09-21 (endpoints below). Niche-established: `mlc` 1.2.0 (166
  stars, single maintainer, last release 2025-12-13, pushed 2026-09-14)
  and `mdbook-linkcheck` 0.7.7 (170 stars, mdBook-backend-coupled, last
  release 2022-10-03 — stale).
- Up-and-comers: `hyperlink` 0.3.x (229 stars, fresh releases June 2026,
  offline HTML-directory checking only — no external-URL support by
  design). No other Rust-native markdown link checker with traction was
  found. The non-Rust reference `markdown-link-check` (npm, tcort, 717
  stars) was surveyed because the ts precedent explicitly passed over
  it; it is excluded (needs a Node toolchain in Rust CI).

Authoritative sources used, and why each counts:

- Maintainers' own documentation, read via the GitHub contents API
  (`GET /repos/{o}/{r}/contents/{path}`, 2026-09-26): lychee
  `README.md` (979 lines: full `--help` text with flag defaults,
  GitHub-Token rate-limit guidance, feature-comparison table, notable
  users list, dual-license section) and mlc `README.md` (flag table,
  install matrix, Marketplace action). Maintainer docs are authoritative
  for capability and configuration claims.
- Production CI of well-regarded Rust projects, read via the same
  endpoint: `ZcashFoundation/zebra` (`.lychee.toml` + `link-check` job
  in `.github/workflows/advisory.yml`) and `containerd/runwasi`
  (`.github/workflows/docs.yml`). Both pin `lychee-action` by commit
  SHA. Zebra is the Zcash Foundation's production Zcash node in Rust;
  runwasi is a CNCF project — both are serious, long-lived Rust
  codebases whose docs-gate choices carry practice weight.
- The local stable toolchain itself (rustc/cargo 1.98.1, no network):
  executed `cargo doc` probes with exit codes (see Validation
  strategy). The toolchain is authoritative for rustdoc-gate behavior.
- crates.io API (`GET /api/v1/crates/<name>`,
  `/versions?per_page=5`, `/0.24.2/dependencies`,
  `/reverse_dependencies`), GitHub REST API via authenticated `gh`
  (`/repos/{o}/{r}`, `/search/issues`,
  `/issues?state=open&sort=created`, issue comments, `/contents/...`,
  `/search/code`), and rustsec.org package pages (404 = no advisories
  recorded, calibrated against `rsa.html`, HTTP 200 with RUSTSEC
  mentions, same date).

Transport note: unauthenticated `curl` to `api.github.com` returned
HTTP 403 (IP rate limit), so all GitHub figures were collected with
authenticated `gh api` (same `api.github.com` endpoints). One
`search/code` burst hit the code-search rate limit (HTTP 403,
2026-09-26 20:17 UTC); the affected queries were retried once after a
cooldown per the 20-second polling rule and succeeded. No network was
used beyond the prompt's named endpoints (crates.io API,
api.github.com, rustsec.org); in particular `.crate` sources were not
downloaded, so `unsafe` postures are recorded as unverified gaps.

Well-regarded projects surveyed, with the evidence that they are well
regarded:

- `ZcashFoundation/zebra`: production Zcash full node in Rust,
  maintained by the Zcash Foundation. Full lychee run (`--verbose
  --no-progress --cache --config .lychee.toml "**/*.md"`, `fail: true`,
  `GITHUB_TOKEN`, 15-minute timeout, `.lycheecache` action cache) as a
  `link-check` job on `ubuntu-latest`, triggered WEEKLY (`cron:
  "0 8 * * 1"`, Mondays) plus `workflow_dispatch`. Its `.lychee.toml`
  excludes localhost/loopback, `file://`, `example.com`, crates.io
  (rate-limited), and hosts that reject automated checkers
  (eprint.iacr.org 403, torproject GitLab). Cuts directly for the
  MEDIUM cadence question: at zebra scale, the unified check runs on a
  schedule, not per PR.
- `containerd/runwasi`: CNCF runtime project. Post-deploy live-site
  check with `lychee-action@8646ba3...` (`# v2.8.0`), `fail: true`,
  `format: markdown`, `jobSummary: true`, on push/PR to `main`.
- Maintainer-claimed Rust-ecosystem users (lychee README "Users"
  section): `rerun-io/rerun`, `DioxusLabs/dioxus`, `orhun/binsider`,
  `mainmatter/100-exercises-to-learn-rust`, `mre/idiomatic-rust`,
  `bencherdev/bencher` —rerun and Dioxus are prominent Rust OSS
  projects; these are maintainer claims, not independently verified
  workflow reads, except zebra/runwasi above.
- Scale signal: `GET /search/code?q=lychee-action+path:.github/workflows`
  returns `total_count` 10,016 workflow files (2026-09-26). No
  competing Rust link checker is within orders of magnitude of that
  CI footprint (mlc's Marketplace action exists but no comparable
  adoption signal was found; `mdbook-linkcheck` has 1 reverse
  dependent, `cargo-deadlinks` 1, the rest 0).
- Negative results, honestly recorded: `search/code` hits for lychee in
  `rust-lang/rustlings` turned out to be exercise source text (a fruit
  name), not CI usage; `rust-lang/this-week-in-rust` `checks.yml` and
  `Zebra docs-check.yml` contain no lychee reference (the zebra usage
  is in `advisory.yml`); `Relm4/book` workflows contain none. None of
  these is claimed as an adopter.

Fit framing for this template (CLI + library + web service): R11 has
already placed this item's checks — the link check is a step of the
`hygiene` job (compiles nothing, cheap), the rustdoc part is the doc
build step of `check`. R81's delivery model is still open, so the gate
must work against either a plain-markdown tree or a generated-site
source tree: the correct invocation shape points at markdown SOURCE
(zebra: `"**/*.md"`), never at a build artifact. R69's `web` feature
gates `src/web/`; the doc build must include it when on.

### Principles and implementation

Shared requirement (source: py `sphinx-build -W` PR gate + weekly
`linkcheck` job, ts `just docs-check` relative-link script): merged
documentation must not ship broken references. Agreement level:
CAPABILITY + POLICY. Capability: CI fails on (1) unresolved
relative/internal links, (2) dead external URLs modulo an explicit
exclude/allowlist policy, (3) broken intra-doc API links. Policy: which
of these block a PR versus ride a scheduled lane, and what the
exclude/allowlist contains. What must agree: the three failure
conditions and their triggers. What may vary: the exact exclude list
per repo, cache settings, verbosity.

Essential behaviors and observable acceptance criteria:

1. A PR that breaks a relative link between two markdown files fails
   the `hygiene` link-check step (exit nonzero), deterministically,
   with no network access required.
2. A dead external URL in the markdown tree fails the scheduled
   full-link job (exit nonzero) within one schedule period; known-flaky
   hosts do not page per PR (they are excluded or retried per config).
3. A broken intra-doc link (`` [`Missing] ``) fails the `check` doc
   build step (exit nonzero). Verified executed: exit 101 (see
   Validation strategy).
4. All three run on `ubuntu-latest` and `macos-latest` (fixed matrix);
   nothing in the gate can fail merely because a runner has no network
   except the scheduled external check itself.

Architectural alternatives compared before choosing libraries:

- A. Unified prebuilt-binary link checker (lychee via lychee-action)
  for (1)+(2), plus toolchain rustdoc gate for (3). One tool, one
  config (`.lychee.toml`), two triggers (PR offline/internal,
  scheduled full). Chosen.
- B. Hand-rolled dependency-free script (ts `check-links.mjs`
  precedent). Rejected: reproduces only (1), leaves (2) unbuilt
  exactly as in ts (the gap this item exists to close), and trades a
  maintained 3,949-star tool for bespoke template code the team must
  own. The ts script's own header says it exists only because lychee
  "was not installed on the CI image at port time" — lychee-action
  removes that premise entirely.
- C. mdBook-backend checker (`mdbook-linkcheck`). Rejected: it runs
  only as an mdBook preprocessor/backend, so it cannot gate a
  plain-markdown tree — it fails the prompt's explicit either-R81-shape
  requirement. Independently at-risk (no release since 2022-10-03,
  median first response 35.2 days).
- D. Post-build HTML checkers (`hyperlink` on built HTML,
  `cargo-deadlinks` on rustdoc output). Rejected as primary:
  hyperlink covers internal links only (no external support) on a
  build artifact rather than source, adding a build dependency to what
  must be a cheap non-compiling hygiene step; cargo-deadlinks is
  at-risk (no release since 2021-10-13, 9 of 10 recent issues
  unanswered) and redundant, because `-D warnings` fails the build at
  doc-generation time with file:line diagnostics instead of
  after-the-fact HTML scraping.
- E. Gate rustdoc but keep the ts latent posture for API docs
  (D-023(4): configured-but-unused). Rejected — UPGRADE to CI-gated:
  py gates autodoc errors with `-W`, so gating matches the stricter
  half of the precedent; the check is effectively free (ships with the
  toolchain, runs inside the already-decided `check` doc-build step,
  deterministic, zero flake). Preserving latency would keep a known
  hole for no saving.

How the recommended design preserves each principle: (1) py's `-W`
internal strictness is preserved by lychee `--offline` on PR plus
rustdoc `-D warnings` in `check`; (2) py's weekly external posture is
preserved by the scheduled full lychee run, upgraded from Sphinx's
linkcheck builder to a Juniper-native tool with retries (default 3),
backoff (default 1s), per-host throttling, rate-limit respect, disk
cache, and `GITHUB_TOKEN` auth; (3) ts's cheap-PR-check principle is
preserved by keeping the PR step offline and dependency-free at runtime
(prebuilt binary, no compile). Where the ecosystem needs a different
design: Sphinx's single-binary-does-everything shape has no Rust
equivalent (no first-party markdown checker exists), so the gate is a
two-member bundle — prebuilt lychee + toolchain rustdoc — rather than
one command.

Minimal realistic example: a template checkout with `README.md`,
`docs/guide.md` (with one relative link to `docs/other.md` and one
`https://` link), `.lychee.toml` (excludes for localhost, `file://`,
`example.com`), and a `src/lib.rs` doc comment with an intra-doc link.
Acceptance check (proposed, not yet run end-to-end — lychee binary was
not executable in this offline leg): (i) break the relative link → PR
step `lychee --offline --no-progress "**/*.md" README.md` exits
nonzero; (ii) restore it, break the intra-doc link →
`RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features` exits
101 (THIS half executed, see Validation strategy); (iii) scheduled
`lychee --cache --config .lychee.toml "**/*.md"` with `GITHUB_TOKEN`
exits nonzero on a dead external URL and zero on the fixed tree.

No `BASELINE-REVIEW:` finding: no recorded baseline row was challenged
by this research; F348/F349/F350/F353 keep their ledger verdicts.

### Recommendation

One stack: `lychee` 0.24.2 via `lycheeverse/lychee-action` v2.9.0
(pinned to its commit SHA at synthesis) with a repo `.lychee.toml`,
invoked twice — `--offline` on PR as a `hygiene` step, full `--cache`
run on the R34 scheduled lane; plus `RUSTDOCFLAGS="-D warnings" cargo
doc --no-deps --all-features` as the `check` doc-build step.

### Members

#### link-checker

##### Landscape

Sub-category: markdown link checking (internal/relative + external
URLs) from a Rust- distributable tool. Bin map: built-in/first-party —
none (cargo, rustup, and mdBook ship no link checker; verified by the
absence of any such subcommand in the 1.98.1 toolchain and by the
existence of the third-party mdBook backend below). Established: lychee
0.24.2 (3,949 stars, 71,555 recent / 221,798 all-time downloads);
niche-established mlc 1.2.0 (166 stars) and mdbook-linkcheck 0.7.7 (170
stars, backend-coupled). Up-and-comer: hyperlink 0.3.2 (229 stars,
offline HTML only). Non-Rust reference surveyed and excluded:
markdown-link-check (npm, 717 stars). Shortlist (lychee, mlc) comes
from this map.

##### Principles and implementation

Must agree: PR-blocking deterministic failure on broken relative links
(py `-W` + ts `docs-check` capability); scheduled failure on dead
external URLs (py weekly-linkcheck capability, absent in ts).
Essential behaviors: walk markdown source (works for either R81
shape); resolve relative targets against the file tree; issue HTTP
requests with retries, timeout, per-host throttle, and rate-limit
respect; honor an exclude config for localhost/placeholders/flaky
hosts; exit nonzero on any failure; emit machine-readable output for
CI summaries. Observable criteria: criteria (1), (2), (4) of the
top-level section. Architectural comparison: see alternatives A–D
above — unified prebuilt binary wins on capability coverage (only
lychee covers internal+external+offline+cache+throttle in one
invocation shape), distribution (per-OS prebuilt binaries + maintained
action; mlc documents linux binaries and a Marketplace action whose
runner matrix is unverified), and maintenance (lychee active with 0.8d
median response vs mlc slower single-maintainer cadence). Minimal
example and acceptance check: the top-level example, checks (i) and
(iii) — proposed, not executed (binary unavailable in this leg).

##### Dominant choice

`lychee` 0.24.2 (crates.io, license `Apache-2.0 OR MIT`, `rust_version`
1.88.0, released 2026-05-01;
`GET https://crates.io/api/v1/crates/lychee/versions?per_page=5`,
2026-09-26), consumed as the prebuilt binary via
`lycheeverse/lychee-action` v2.9.0 (published 2026-07-09;
`GET /repos/lycheeverse/lychee-action/releases?per_page=5`,
2026-09-26), pinned to its commit SHA at synthesis. Dominant by: 3,949
stars vs 166 (mlc) / 229 (hyperlink) / 170 (mdbook-linkcheck);
71,555 90-day downloads vs 1,539 (mlc); 10,016 workflow files
referencing `lychee-action` (`GET /search/code`, 2026-09-26);
verified production adoption (zebra, runwasi); docs capability
superset (retry/backoff, rate-limit respect, per-host throttle, cache,
offline mode, fragments — maintainer README comparison table).

##### Qualified shortlist

- lychee 0.24.2: 90-day downloads 71,555, all-time 221,798
  (`GET /api/v1/crates/lychee`); last release 0.24.2 @ 2026-05-01
  (versions endpoint; prior 0.24.1/0.24.0/0.23.0/0.22.0 all within 6
  months — steady cadence); stars 3,949, archived false, pushed
  2026-09-21 (`GET /repos/lycheeverse/lychee`); open issues 59
  (`GET /search/issues?q=repo:lycheeverse/lychee+is:issue+is:open`
  `total_count`); responsiveness over 10 most recently opened pure
  issues: median 0.8 days to first non-OP reply, 5 answered / 5
  unanswered (issue comments endpoint); advisories none
  (`https://rustsec.org/packages/lychee.html` HTTP 404, calibrated);
  adopters: reverse-dependencies total 0 (binary, not a library —
  expected), CI adoption instead: 10,016 workflows reference the
  action; verified `ZcashFoundation/zebra` (`.lychee.toml` + weekly
  `link-check` job) and `containerd/runwasi` (`docs.yml`,
  `fail: true`, `format: markdown`, `jobSummary: true`).
  Maintenance: active.
- mlc 1.2.0: 90-day 1,539, all-time 102,553; last release 1.2.0 @
  2025-12-13, MIT, no `rust_version` declared; stars 166, pushed
  2026-09-14; open issues 11; responsiveness median 1.9 days, 7
  answered / 3 unanswered; advisories none (404); revdeps 0; adopter
  evidence: maintainer cites `becheran/ntest` CI usage (README line
  98; same-author project, weak signal — no independent well-regarded
  adopter found). Capabilities (maintainer README): absolute+relative
  file paths and URLs, async, `--offline`/`-o` (skip web links),
  `--throttle` ms between same-host requests (default 0), glob
  `--ignore-links`, `--http-headers`, prebuilt linux x86_64/aarch64
  binaries, Marketplace action, docker image. Maintenance: active
  (pushed within 2 weeks; 5 releases across 2025; the 9.5-month
  release gap is a 6-month-trigger investigation that resolves to
  stability, not abandonment — commits continue).

##### Excluded by gate

- mdbook-linkcheck 0.7.7: EXCLUDED — fails the fitness requirement
  that the gate work against either R81 shape: it runs only as an
  mdBook preprocessor/backend, so a plain-markdown tree (one live R81
  outcome) cannot be gated by it at all. Independently at-risk: last
  release 2022-10-03 (versions endpoint), pushed 2024-08-15, 170
  stars, 31 open issues, responsiveness median 35.2 days (5/5),
  advisories none, revdeps 1 (`fugue-ppl`). Figures from the same
  endpoints, 2026-09-26.
- markdown-link-check (tcort, npm): EXCLUDED — fails the native-design
  mandate (spec §2/A5): it is a JavaScript tool requiring a Node
  toolchain in a Rust template's CI, the exact non-native shape the
  ts port settled for only because lychee "was not installed on the
  CI image at port time" (prompt Context). Not on crates.io (API
  HTTP 404, 2026-09-26); GitHub 717 stars, pushed 2026-07-28, 14 open
  issues (`GET /repos/tcort/markdown-link-check`,
  `/search/issues`, 2026-09-26). Healthy upstream, wrong ecosystem.

##### Up-and-comers

hyperlink 0.3.2 (untitaker): MIT; 90-day 629, all-time 48,459; last
release 0.3.2 @ 2026-06-27 after a 2025-11→2026-06 revival train
(0.2.0/0.2.1/0.3.0/0.3.1/0.3.2); 229 stars, pushed 2026-07-30; 6 open
issues total, responsiveness over all 6: median 15.6 days, 2 answered
/ 4 unanswered; advisories none; revdeps 0 (same endpoints,
2026-09-26). Scope is offline checking of a built HTML directory —
internal links only, no external-URL support — so it cannot cover
member (b) and would add a site-build dependency to the
non-compiling hygiene step. Watch if lychee ever stalls; not the
pick. Maintenance: active but single-maintainer with slow issue
turnaround.

##### Fit for this template

lychee fits all three template surfaces through one invocation shape:
point at markdown source (`"**/*.md"` + `README.md`, zebra-shaped),
which is correct whether R81 yields a generated site (sources still
exist) or a plain tree — no build artifact, no compile, no new
toolchain. Consumption as a pinned prebuilt action adds zero entries
to `Cargo.toml`, zero MSRV pressure, and seconds of CI time. The PR
`hygiene` step uses `--offline --no-progress` (deterministic, no
network, matches ts's cheap-PR principle and R11's placement); the
R34 scheduled lane reuses the same `.lychee.toml` with `--cache` +
`GITHUB_TOKEN` (zebra-shaped; matches py's weekly posture). mlc fits
worse: linux-first distribution (documented CI binaries are linux
only; macOS prebuilt/action-runner support unverified — gap), no
retry/backoff (throttle-only 429 handling), no request cache, and no
independent well-regarded adopter.

##### Recommendation

lychee 0.24.2 via lychee-action v2.9.0, SHA-pinned at synthesis, with
repo `.lychee.toml`. PR step (hygiene):
`lychee --offline --no-progress --config .lychee.toml "**/*.md"
README.md`-equivalent via the action's `args`, `fail: true`.
Scheduled lane (R34): same config plus `--cache`, `--verbose`,
`GITHUB_TOKEN`, `.lycheecache` action cache, `fail: true`.
Baseline `.lychee.toml` excludes (from zebra's, trimmed): localhost /
loopback / link-local, `file://`, `example.com` placeholders,
`github.com/.../runs|issues/0000|pull/0000` templates; add
`--exclude-all-private` consideration at synthesis (lychee flag;
README line 486).

##### Ranked runner-up

mlc 1.2.0 via its Marketplace action or `cargo install mlc`:
simpler single-binary story and a genuine `--offline` mode, but
loses on distribution (linux-documented binaries; macOS path
unverified), HTTP robustness (throttle-only, no retries/backoff,
no cache, no documented rate-limit respect), adoption (no
independent well-regarded adopter vs zebra+runwasi+10k workflows),
and maintenance depth (single maintainer, 166 stars, 1.9d median
but 3/10 recent issues never answered including #158 from
2026-03-24). Revisit only if lychee-action becomes unmaintained.

##### Tradeoffs

Unified tool + split triggers vs single unified check on PR: a
single full check on every PR would catch external rot fastest but
imports network flake and rate limits into the merge gate — both
precedents reject that (py: weekly external; ts: no external on
PR), and zebra runs its full check weekly. Split triggers keep PRs
deterministic while closing ts's external gap on a schedule.
lychee vs mlc: lychee trades a larger dependency footprint (36
required direct deps incl. tokio/reqwest — irrelevant at runtime
since CI consumes a prebuilt static binary) for retry/backoff,
rate-limit respect, cache, GitHub-token auth, fragments, JSON/
markdown/JUnit output, and an order of magnitude more adoption.
lychee-action vs vendoring the binary: the action tracks releases
and runner OS automatically; pin by SHA per R20's pinning policy
(R20 resolved: pin third-party actions).

##### Parameters

Owns none. Assumes `rust-edition = 2024`, `msrv-policy = stable
minus 2 minor versions, raised only in a minor release, declared as
rust-version in Cargo.toml and tested in CI`, `target-os-matrix =
ubuntu-latest, macos-latest`, `license = MIT OR Apache-2.0` (all
owner-fixed, inapplicable to tool selection beyond gate 4, which
lychee's per-OS release binaries satisfy). Assumes R11
`ci-job-structure`: link check is a step of `hygiene` (PR,
offline); scheduled full run rides R34's lane mechanism when it
lands. Assumes R69 `web-extra-surface` only insofar as `"**/*.md"`
globs already cover any web docs without feature awareness. No
`CONFLICT:` lines.

##### Migration implications

- New: `.lychee.toml` at repo root (excludes per Recommendation;
  `exclude_path = ["target", "node_modules", ".git"]`-shaped,
  zebra-derived).
- Edit: `.github/workflows/ci.yml` `hygiene` job — add
  SHA-pinned `lychee-action` step with offline `args`, `fail:
  true`.
- Later (R34 lane exists): add the scheduled full-check job reusing
  `.lychee.toml` with `--cache` + `GITHUB_TOKEN` + `.lycheecache`
  cache step.
- No `Cargo.toml`, feature, or source change (tool is external to
  the build).

##### Validation strategy

Planned (NOT executed — lychee binary unavailable in this offline
leg; synthesis MUST run these): (1) seed a scratch docs tree with
one good relative link, one broken relative link, one good
external URL; run the PR-step args → expect nonzero exit naming
only the broken relative link, with network disabled to prove
offline determinism; verify `--offline` SKIPS (not fails)
external links — if it fails them, switch the PR step to
`--exclude '^https?://'` and record the deviation; (2) fix the
tree, point one external link at a dead host; run the scheduled
args with `--cache` → expect nonzero exit naming the dead URL, and
a second run served from `.lycheecache`; (3) confirm
`lychee --version` reports 0.24.2 on both `ubuntu-latest` and
`macos-latest` runners via the pinned action.

##### Confidence & re-verify trigger

High that lychee is the dominant Rust-ecosystem choice (stars,
downloads, 10k-workflow footprint, verified zebra+runwasi
adoption, capability superset); medium on exact PR-step flags
until the `--offline` skip-vs-fail semantic is executed.
Re-verify: lychee-action v3 release; lychee 0.x→1.x; R81
delivery-model decision (confirm source-glob shape still fits);
R34 lane landing (place the scheduled job).

##### Sources

- `GET https://crates.io/api/v1/crates/lychee` (recent 71,555;
  all-time 221,798) + `/versions?per_page=5` (0.24.2 @ 2026-05-01,
  Apache-2.0 OR MIT, rust 1.88.0) + `/0.24.2/dependencies` (36
  required incl. tokio, reqwest, Rustls path) +
  `/reverse_dependencies` (total 0) — 2026-09-26.
- `GET /repos/lycheeverse/lychee` (3,949 stars, archived false,
  pushed 2026-09-21); `/search/issues?q=repo:lycheeverse/lychee+is:issue+is:open`
  (59); 10 newest pure issues + comments (median 0.8d, 5/5);
  `/contents/.github/workflows/release-binary.yml` (per-OS matrix:
  ubuntu/macos-aarch64+x86_64/windows msvc) and `ci.yml`
  (ubuntu-latest tests); `/contents/README.md` (flag defaults:
  max-retries 3, retry-wait 1s, timeout 20s, max-concurrency 128;
  `--offline`, `--cache`, excludes, GITHUB_TOKEN, comparison
  table, users list, dual license) — 2026-09-26.
- `GET /repos/lycheeverse/lychee-action/releases?per_page=5`
  (v2.9.0 @ 2026-07-09) — 2026-09-26.
- mlc/mdbook-linkcheck/hyperlink/markdown-link-check: same
  endpoint family for each figure in Qualified shortlist /
  Excluded / Up-and-comers — 2026-09-26; mlc README
  (`/contents/README.md`, 234 lines: offline/throttle/ignore/
  install matrix/ntest citation) — 2026-09-26.
- `GET /search/code?q=lychee-action+path:.github/workflows`
  (10,016) — 2026-09-26.
- Adopters: `/contents/.lychee.toml` + `/contents/.github/
  workflows/advisory.yml` in `ZcashFoundation/zebra` (weekly cron
  `0 8 * * 1`, v2.8.0 @ 8646ba3, `--cache --config .lychee.toml
  "**/*.md"`, GITHUB_TOKEN, 15-min timeout);
  `/contents/.github/workflows/docs.yml` in
  `containerd/runwasi` (v2.8.0 pinned, fail/format/jobSummary) —
  2026-09-26.
- `https://rustsec.org/packages/{lychee,mlc,mdbook-linkcheck,
  hyperlink}.html` (all HTTP 404 = none recorded) calibrated
  against `/packages/rsa.html` (HTTP 200, RUSTSEC mentions) —
  2026-09-26.

#### rustdoc-gate

##### Landscape

Sub-category: API-reference correctness — failing CI on broken
intra-doc links (`` [`Item] ``), the rustdoc analogue of py's
`sphinx-build -W` autodoc strictness. Bin map: built-in/first-party
— rustdoc via `cargo doc` + `RUSTDOCFLAGS="-D warnings"` (ships
with every toolchain; the `rustdoc::broken-intra-doc-links` lint
is the targeted form). Established industry standard — the same
built-in gate; no third-party crate is the standard here (see
adopter/reverse-dep evidence below). Up-and-comers — none found;
the only third-party alternative is `cargo-deadlinks` 0.8.1, a
2021 post-build HTML scraper (at-risk, covered as runner-up, not
an up-and-comer). The shortlist (the built-in gate) comes from
this map. Crate figures are inapplicable to the recommendation
itself (no crate is added — reasoning per field, per the tier
guidance); figures are collected for the runner-up instead.

##### Principles and implementation

Must agree: broken API-reference links fail CI (py `-W`
capability); the check is deterministic and offline. Essential
behaviors: `cargo doc` resolves every intra-doc link against the
documented crate graph including the `web`-feature-gated surface
when enabled; any unresolved link or rustdoc warning becomes a
hard error under `-D warnings`; exit nonzero fails the `check`
doc-build step. Observable criterion: top-level criterion (3).
Architectural comparison: build-time lint denial (chosen) vs
post-build HTML scraping (cargo-deadlinks, alternative D above)
— denial wins on diagnostics (file:line errors at generation
time, executed below), determinism (no second tool, no HTML
parsing), cost (zero new dependency, runs inside the existing
`check` job), and maintenance (toolchain-supported vs 2021
stale). Latent-posture alternative E (D-023(4)) rejected — upgrade
to CI-gated, matching py's `-W` strictness for free. Minimal
example: `src/lib.rs` with ``/// See [`crate::Missing]`` →
gate fails; fix the link → gate passes (executed form of
top-level check (ii)).

##### Dominant choice

No crate: `RUSTDOCFLAGS="-D warnings" cargo doc --no-deps
--all-features` on the CI toolchain. Dominant because it is the
only option that is simultaneously first-party, zero-dependency,
OS-independent (runs wherever cargo runs — the whole matrix by
construction), and proven below to fail the build (exit 101) on
exactly the defect class at issue. `--no-deps` scopes the gate to
workspace crates (dependency docs are not this template's
correctness burden); `--all-features` includes R69's
`web`-gated `src/web/` tree plus future nested `otel`/`metrics`
features (R69 names `--features web` or `--all-features` as the
selection idioms; `--all-features` is future-proof because the
template owns its feature tree and has no mutually exclusive
features).

##### Qualified shortlist

The built-in gate only. Crate figures: inapplicable — no crate
is selected, so there is no crates.io record, no GitHub repo, no
release, no advisory surface, and no reverse dependencies to
measure; fitness gates 1–6 are answered as inapplicable with
reasons in Fit/Tradeoffs (license: toolchain component under the
Rust project's own licensing, not a template dependency; MSRV:
the gate runs on CI's installed toolchain including the MSRV
floor by construction; unsafe: no new code; OS: wherever cargo
runs; features/runtime: none; cost: seconds inside `check`).
Evidence for the gate is empirical (executed probes, local
toolchain 1.98.1, 2026-09-26) rather than registry-based.

##### Excluded by gate

None — no third-party candidate was needed, so no exclusion was
taken. (The one surveyed alternative, cargo-deadlinks, is
carried as ranked runner-up with its at-risk evidence rather
than excluded, because its maintenance state, while poor, was
not verified against a hard gate: no open advisory exists for
it, and a broken-build-on-stable verdict would require
compiling its 2021 dependency tree, which this offline leg did
not attempt. Stating the gap instead of inventing a verdict.)

##### Up-and-comers

None found. A fresh survey of the field (crates.io + GitHub,
2026-09-26) surfaced no new or rising rustdoc-lint tool: the
space is owned by the toolchain's own lints
(`rustdoc::broken-intra-doc-links` et al.), and the sole
third-party alternative predates them in spirit (2021) and is
stagnant (see runner-up).

##### Fit for this template

Exact fit: R11 already reserves the doc build step of `check`
for this gate, so adoption is flags-only, no new job, no new
runner, no new dependency, no `Cargo.toml` edit. `--all-features`
covers the CLI binary, core library, and R69's `web` surface in
one invocation; `--no-deps` keeps runtime to seconds. Because
the gate is the toolchain itself, it trivially satisfies the
fixed matrix (`ubuntu-latest, macos-latest`), the MSRV policy
(the floor toolchain's rustdoc IS the gate — doc builds under
`-D warnings` must pass there too, which is the correct
strictness), and offline determinism (no network, no flake —
safe to block PRs, unlike external-URL checking).

##### Recommendation

`RUSTDOCFLAGS="-D warnings" cargo doc --no-deps --all-features`
as the doc build step of R11's `check` job, run after the test
steps so a doc-link break never masks a test failure (R11 step
ordering already runs every step under `!cancelled()`).

##### Ranked runner-up

cargo-deadlinks 0.8.1 (deadlinks/cargo-deadlinks): MIT OR
Apache-2.0; 90-day 7,924, all-time 129,390; last release 0.8.1 @
2021-10-13; 158 stars, pushed 2024-12-10; 14 open issues;
responsiveness median 22.2 days, 1 answered / 9 unanswered (10
newest pure issues); advisories none (rustsec 404, calibrated);
revdeps 1 (`gluon_doc` — not a reference adopter; same
endpoints, 2026-09-26). Post-build HTML link checker for
rustdoc output. Loses on every axis: at-risk maintenance (no
release in ~5 years, 9/10 recent issues ignored), redundant
mechanism (scrapes HTML after the fact instead of denying the
lint at generation), extra install/compile in CI, and zero
reference adoption. Maintenance: at-risk (concrete signals:
5-year release gap, 21-month commit gap, 9/10 issues
unanswered). Not dormant only because no advisory, proven
broken build, or maintainer sunset notice was verified — gap
stated, verdict not inflated.

##### Tradeoffs

Blanket `-D warnings` vs targeted
`-D rustdoc::broken-intra-doc-links`: blanket chosen — it also
denies rustc warnings emitted during the doc build (e.g. unused
imports pulled in by doc cfg), matching py `-W`'s "any warning
fails" posture; both were executed to exit 101 on the same
broken link (Validation strategy), so the targeted form is a
proven fallback if blanket denial ever fires on a toolchain
warning outside the template's control. `--all-features` vs
explicit `--features web`: all-features chosen for
future-proofing nested `otel`/`metrics` (R69); explicit
`--features web` is equivalent today and the fallback if an
all-features combination ever breaks. Built-in vs cargo-deadlinks:
see runner-up — no contest on maintenance or mechanism.

##### Parameters

Owns none. Assumes `rust-edition = 2024` (intra-doc link
syntax is edition-stable for this use), `msrv-policy` (gate
runs on the floor toolchain too — doc warnings must be clean
there), `target-os-matrix` (gate is OS-independent),
`license` (no new dependency). Assumes R11 `ci-job-structure`
(doc build step of `check`) and R69 `web-extra-surface`
(`--all-features` selects the `web`-gated tree; no other
feature knowledge needed). No `CONFLICT:` lines.

##### Migration implications

- Edit: `.github/workflows/ci.yml` `check` job doc-build step →
  `RUSTDOCFLAGS="-D warnings" cargo doc --locked --no-deps
  --all-features` (`--locked` per R11's every-cargo-command rule).
- No new files, no `Cargo.toml` change, no new feature.
- Template docs (contributor guide): one line — "doc comments
  with broken [`links`] fail CI; run the doc build locally
  before pushing."

##### Validation strategy

EXECUTED 2026-09-26 (local toolchain rustc/cargo 1.98.1,
scratch crate `/tmp/r82doc`, no network): crate with two
broken intra-doc links (``[`Nonexistent]`` at crate root,
``[`crate::Missing]`` on `f`). `cargo doc --no-deps` → exit 0
with 2 warnings (`warning: r82doc (lib doc) generated 2
warnings`). `RUSTDOCFLAGS='-D warnings' cargo doc --no-deps`
→ exit 101 (`error: unresolved link to crate::Missing`,
`error: could not document r82doc`). `RUSTDOCFLAGS='-D
rustdoc::broken-intra-doc-links' cargo doc --no-deps` → exit
101. `cargo doc --no-deps --all-features` on the clean tree →
exit 0 (flag acceptance). Planned (synthesis/acceptance, on
CI): run the exact `check`-step command against the template
with the `web` feature on and off; seed one broken intra-doc
link in `src/web/` and confirm the feature-on build fails while
proving the feature-off build still passes (proves `--all-features`
actually covers the gated surface rather than assuming it).

##### Confidence & re-verify trigger

High — the gate's core claim (denial fails the build) is
executed, not cited, and the mechanism is first-party.
Re-verify: new rustdoc lint defaults in a toolchain upgrade
(a new warn-by-default lint could fail the gate until fixed —
that is the gate working, but expect the ping); R69 feature
tree changes (confirm `--all-features` still the right
selector).

##### Sources

- Executed probes: `cargo doc --help` (feature flags
  `--features`/`--all-features`/`--no-default-features`
  listed); exit-code runs above — local toolchain 1.98.1,
  2026-09-26, `/tmp/r82doc` (reproducible in any checkout;
  script-equivalent commands in Validation strategy).
- cargo-deadlinks figures: `GET
  https://crates.io/api/v1/crates/cargo-deadlinks` (7,924 /
  129,390) + `/versions?per_page=5` (0.8.1 @ 2021-10-13, MIT OR
  Apache-2.0) + `/reverse_dependencies` (total 1: `gluon_doc`);
  `GET /repos/deadlinks/cargo-deadlinks` (158 stars, pushed
  2024-12-10); `/search/issues` (14); 10 newest pure issues +
  comments (median 22.2d, 1/9);
  `https://rustsec.org/packages/cargo-deadlinks.html` (404) —
  2026-09-26.

### Compatibility

The members compose by disjoint surfaces, not shared versions,
so there is no version matrix to keep in sync: lychee (prebuilt
binary, pinned action) checks markdown source; rustdoc (CI
toolchain) checks API doc comments; neither consumes the
other's output and neither shares a dependency with the
template build. Joint proof: (1) the template's own CI wires
both — `hygiene` link step + `check` doc-build step per R11 —
so every PR exercises them together; (2) reference halves
exist independently — zebra's `.lychee.toml` + weekly
`link-check` job (lychee half, production) and the executed
exit-101 probe (rustdoc half, this report). No shared adopter
running both exact halves was verified — stated as a gap, not
claimed. Trigger split is deliberate and compatible: PR =
offline lychee + rustdoc denial (both deterministic, both
offline); schedule = full lychee (network-tolerant, cached).
Pinned versions: lychee-action v2.9.0 (SHA at synthesis;
0.24.2 binary) + whatever stable toolchain CI installs
(rustdoc unversioned by design).

### Parameters

Assumes `rust-edition = 2024`.
Assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.
Assumes `target-os-matrix = ubuntu-latest, macos-latest`.
Assumes `license = MIT OR Apache-2.0`.
Assumes R11 `ci-job-structure` (relevant slice): Tier-1
`hygiene` job hosts R82's link check as a step; the `check` job
(an ordered-step compile job, one per matrix OS, every cargo
command `--locked`, steps under `!cancelled()`) hosts R82's
rustdoc part as its doc build step.
Assumes R69 `web-extra-surface` (relevant slice): one
additive off-by-default `web` feature gating `src/web/`, the
`<app>-serve` binary, and the web tests; consumers select with
`--features web` or `--all-features`.
Owns no parameters. No `CONFLICT:` lines. Related, not
consumed: R81 `docs-delivery-model` (open) — this answer points
at markdown source and is correct for either delivery outcome;
R34 scheduled lanes (owns the lane the full-link job will
ride — this item states the flakiness posture, not the
schedule).

### Migration implications

- New: `.lychee.toml` (repo root; excludes + `exclude_path`,
  zebra-derived, trimmed to template needs).
- Edit: `.github/workflows/ci.yml` — (a) `hygiene` job: add
  SHA-pinned `lycheeverse/lychee-action` step, offline args,
  `fail: true`; (b) `check` job: set the doc build step to
  `RUSTDOCFLAGS="-D warnings" cargo doc --locked --no-deps
  --all-features`.
- Later, when R34 lands: add the scheduled full-link job
  (`--cache`, `GITHUB_TOKEN`, `.lycheecache` cache step) in the
  lane R34 provides; no R82 file changes beyond that job block.
- Docs: contributor-guide line on rustdoc-link strictness.
- No `Cargo.toml`, feature, dependency, or source change.

### Validation strategy

Executed (this leg, 2026-09-26, rustc/cargo 1.98.1, offline
scratch crate): the four `cargo doc` exit-code probes in the
rustdoc-gate member (default exit 0 with 2 warnings; `-D
warnings` exit 101; targeted-lint exit 101; `--all-features`
exit 0). These prove principle (3): broken intra-doc links fail
the build under the recommended flags.
Planned (synthesis/acceptance MUST run; lychee binary was not
executable in this offline leg): the three lychee checks in the
link-checker member — (1) offline PR-step determinism incl.
the `--offline` skip-vs-fail semantic check with network
disabled (fallback `--exclude '^https?://'` if it fails
external links); (2) scheduled full-run failure + cache
behavior on a seeded dead URL; (3) pinned-action version proof
(`lychee --version` == 0.24.2) on both matrix runners.
Expected behavior: nonzero exits naming exactly the seeded
defect; zero on the fixed tree; no network traffic in check
(1). Distinguishing mark: anything in this section labeled
EXECUTED was observed; anything labeled planned is a
promise the synthesizer must redeem before acceptance.

### Confidence & re-verify trigger

Overall: high on tool selection (lychee's lead is decisive on
every axis measured the spec's way; rustdoc denial is executed
fact), medium on exact lychee PR-step flags pending the
`--offline` execution. Gaps carried forward: (1) lychee binary
never executed here — all lychee behavior claims rest on
maintainer docs + zebra/runwasi production usage, not on a
local run; (2) `unsafe` postures unverified for all candidates
(no `.crate` download per the named-endpoints network rule —
low weight: lychee/mlc run as prebuilt CI binaries, not linked
code); (3) mlc macOS prebuilt/action-runner support unverified;
(4) no verified adopter running both halves together;
(5) lychee-action v2.9.0 commit SHA not recorded (fetch at
synthesis). Re-verify triggers: lychee-action v3 or lychee 1.x;
R81 delivery-model resolution; R34 lane landing; toolchain
rustdoc-lint default changes; any lychee release touching
`--offline` semantics.

### Sources

Endpoint-family summary (every figure retrieval date 2026-09-26;
per-figure endpoints in the member Sources fields): crates.io
API (`/api/v1/crates/<name>`, `/versions`, `/0.24.2/dependencies`,
`/reverse_dependencies` for lychee, mlc, mdbook-linkcheck,
cargo-deadlinks, hyperlink; 404 for markdown-link-check);
GitHub REST via authenticated `gh` (`/repos/{o}/{r}`,
`/search/issues`, `/issues` + issue comments,
`/contents/.github/workflows/*`, `/contents/README.md`,
`/contents/.lychee.toml`, `/search/code`,
`/repos/lycheeverse/lychee-action/releases`); rustsec.org
package pages (404 = none recorded, rsa-calibrated); local
toolchain probes (rustc/cargo 1.98.1, `/tmp/r82doc`). No other
network used.
