actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 437ad0c97631f53435b1c17e4d6c898d965eb41cb25c51ce862a94c02237d35e
verdict: approve
unresolved-findings: none

# R83 openapi-contract-fuzzing — empirical audit of DECISION.md revision 1

Seat: empirical auditor. Scope: execution truth and evidence support only. I did not read any
`review/audit-*.md`, any `raw/` of `research/topics/`, or any `review/Rxx-r*-snapshot.md`. I made
no git writes, ran no `scripts/research_runner.py` command, and called no paid or submitting API.
The untracked `operations/muse.json` and `raw/muse.md` exist in the run tree. They are not part of
revision 1 and are not referenced by it, and I did not read them.

## 1. Identity and currency

- `shasum -a 256 review/DECISION.md` returned
  `437ad0c97631f53435b1c17e4d6c898d965eb41cb25c51ce862a94c02237d35e`, which matches the expected
  hash, so the audit proceeded.
- **Revision 1 is the index (staged) copy, not HEAD.** `git show :<path>/review/DECISION.md |
  shasum -a 256` returns `437ad0c9…`. `git show HEAD:<path>/review/DECISION.md` returns `3e62d6e4…`,
  an earlier draft of revision 1 that commit `b1ac6d57` records. That earlier draft cites 26
  registry checks, not 29.
- **Current evidence for revision 1.** The decision's `## Empirical check` names two scripts, two
  paired logs and `clean-extraction.log`. The two scripts and two paired logs are staged, and each
  one's index blob equals its working-tree blob:

  | File | Index blob = working-tree blob |
  |---|---|
  | `contract-fuzz-probe.sh` | `ca6069eb` |
  | `contract-fuzz-probe.log` | `cce149d7` |
  | `registry-and-standard.sh` | `a935ebc9` (29 checks, adds `B25`, `B26`, `B27`) |
  | `registry-and-standard.log` | `9d29f41d` |

  `clean-extraction.log` is the exception. The index blob `601cb4da` equals HEAD and records
  **26/26**. The working-tree blob `432d87ec` is an unstaged edit and records **29/29**. The
  decision cites 24/24 and 29/29, so the **working-tree copy is the current one**. I audited
  against it. See observation O2 for the staging hazard.

## 2. Reruns

Host for every rerun: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc
2026-08-05) (Homebrew)`, macOS/arm64, `/usr/bin/grep` BSD 2.6.0-FreeBSD. `CARGO_HOME` was the
private `/tmp/cargo-s15-R83-emp`. Each run's working directory was the script's own `evidence/`
directory. Output went to `/tmp/r83-emp-claude/`, and nothing under `evidence/` was overwritten.

| # | Command | Exit | Totals | Comparison |
|---|---|---|---|---|
| R1 | `./contract-fuzz-probe.sh > /tmp/r83-emp-claude/contract-fuzz-probe.log 2>&1` (in place) | 0 | PASS=24 FAIL=0 SKIP=0 TOTAL=24 | `cmp`: differ at char 82, line 3; diff is lines 3–4 only (below) |
| R2 | `./registry-and-standard.sh > /tmp/r83-emp-claude/registry-and-standard.log 2>&1` (in place) | 0 | PASS=29 FAIL=0 SKIP=0 TOTAL=29 | `cmp`: differ at char 90, line 3; diff is the `retrieved:` line plus the declared-volatile section only (below) |
| R3 | `git archive HEAD research/runs/R83 \| tar -x -C <mktemp>`, then both scripts from the extracted `evidence/` | 0, 0 | 24/24; **26/26** | probe log byte-identical to R1; registry total is 26 because HEAD carries the pre-revision script (O3) |
| R4 | `cp -R <run-dir> <mktemp>`, a relocated working-tree copy with no `.git`, then both scripts | 0, 0 | 24/24; 29/29 | probe log byte-identical to R1 (`cmp` silent) |
| R5 | fixture copied to `<mktemp>`, `Cargo.toml.fixture`→`Cargo.toml`, `env R83_LEG=clean cargo test -q --test contract_fuzz -- --test-threads=1` and the same with `R83_SEED_DEFECT=1` | — | `ok. 3 passed … finished in 0.01s`; `FAILED. 2 passed; 1 failed … finished in 0.01s` | recovers the "0.01 s" that the committed log normalises to `<duration>` |

R1 diff, committed log `<` versus fresh log `>`:

```
3,4c3,4
< rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
< cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
---
> rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
> cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)
```

Every other byte matches. That includes all 24 assertions, the dependency counts `60` and `141`,
and the resolved versions `axum v0.8.9`, `oas3 v0.22.0`, `proptest v1.11.0` and `tower v0.5.3`.

R2 diff: the `== stable assertions ==` section is byte-identical, including the 145-rule count and
all nine rule texts at their line numbers. The only differences are these lines:

```
3c3
< retrieved: 2026-09-19T01:42:59Z
> retrieved: 2026-09-27T03:47:20Z
56c56
< matusf/openapi-fuzzer stars=577 archived=false pushed_at=2024-01-29T11:19:08Z
> matusf/openapi-fuzzer stars=578 archived=false pushed_at=2024-01-29T11:19:08Z
58c58
< x52dev/oas3-rs stars=79 archived=false pushed_at=2026-09-09T10:10:27Z
> x52dev/oas3-rs stars=79 archived=false pushed_at=2026-09-20T15:41:55Z
60,61c60,61
< oas3: recent_downloads=796004 downloads=2011518
< openapi-fuzzer: recent_downloads=40 downloads=11730
> oas3: recent_downloads=992223 downloads=2234390
> openapi-fuzzer: recent_downloads=39 downloads=11730
```

The decision says to compare this section by re-reading it against its guard assertions, not by
diffing it. Both guards pass on today's values. `B23` checks that `openapi-fuzzer` has not been
pushed after 2024; it is still `2024-01-29`. `B24` checks that `oas3` was pushed in 2026 or later;
it now reads `2026-09-20`.

## 3. Load-bearing figures re-derived at source

| Claim in the decision | Where I checked it | Result |
|---|---|---|
| `OPENAPI_SUPPORTED_VERSION_RANGE` at `src/spec/mod.rs:75` | `oas3-0.22.0` in the cargo registry cache, line 75 | `const OPENAPI_SUPPORTED_VERSION_RANGE: &str = "~3.1";` ✓ |
| `Spec::operations()` at `src/spec/mod.rs:205` | same crate, line 205 | `pub fn operations(&self) -> impl Iterator<Item = (String, Method, &Operation)>` ✓ |
| `Schema::resolve` at `src/spec/schema.rs:594` | same crate, line 594 | `pub fn resolve(&self, spec: &Spec) -> Result<Self, RefError>` ✓ |
| `oas3` declares `rust-version` 1.87; `proptest` 1.11.0 declares 1.85 | each crate's `Cargo.toml:14` | `"1.87"`, `"1.85"` ✓ (also `B7`, `B9` in R2) |
| "a probe whose harness is 482 committed lines" | `wc -l tests/contract_fuzz.rs` | 482 ✓ |
| No operation name appears in the harness (weak criterion 1) | `grep 'projects-create\|projects-read' tests/contract_fuzz.rs` | no match; both names occur only in `src/openapi.json` ✓ |
| `limit` is declared with `"minimum": 0` | `src/openapi.json:55` | `"limit": { "type": "integer", "minimum": 0, "maximum": 100 }` ✓ |
| Seeded 500 found and minimized in 0.01 s | R5 | `finished in 0.01s` ✓ |
| Both scripts are `shellcheck` clean | `/opt/homebrew/bin/shellcheck` on both | exit 0, no output ✓ |
| No token bytes and no personal email address in the scripts or logs | `/usr/bin/grep -nE '@\|ghp_\|github_pat_\|gho_\|sk-'` over both `.sh` and the three `.log` | one hit, `"$@"` at `contract-fuzz-probe.sh:89`, a bash argument expansion ✓ |
| `raw/opus.md` sha256 `5c8efd3c…e28741` | `shasum -a 256` | matches ✓ |
| `manifest.json` `state: partial`, `required_engines: ["codex","opus"]` | index copy (`git show :…/manifest.json`) | `partial ['codex', 'opus']` ✓ (see O4 for the working-tree copy) |
| Rerunnable outside the worktree | R3, R4 | both scripts exit 0 with no SKIP ✓ |

## 4. Observations with repairs (non-blocking)

Each observation below records drift or a publication hazard. None of them makes a stated claim of
revision 1 fail under rerun, so none is an unresolved finding.

- **O1 — Toolchain drift, and an unlocked dependency resolution.** The decision records its host as
  `rustc 1.98.0 (88d9e12ae 2026-08-18)`. Today's host is `rustc 1.98.1`, and that difference alone
  breaks byte-identity of `contract-fuzz-probe.log` (R1 diff, lines 3–4). All assertions and the
  "1.96 floor = stable 1.98 minus two minors" arithmetic are unaffected. A second, latent risk:
  the fixture ships no `Cargo.lock`, so the byte-identical dependency section (60/141 and the
  resolved versions) held this time only because resolution did not move in 9 days.
  **Repair:** (a) treat the `== environment ==` header as a legitimately varying field, the same
  way the registry script already treats `retrieved:`, and state that in `## Empirical check`;
  (b) commit a `Cargo.lock.fixture` beside `Cargo.toml.fixture` and have the script copy it to
  `Cargo.lock`, with `--locked` on `cargo build`/`cargo test`/`cargo tree`, so the graph counts and
  resolved versions cannot drift silently. A `rust-toolchain.toml` pin is the heavier alternative,
  and it conflicts with the fixture's deliberate not-a-rooted-package design.
- **O2 — Staging hazard for `clean-extraction.log` (addressed to the publisher).** The index holds
  blob `601cb4da` (26/26, the pre-revision run). The current evidence is the working-tree blob
  `432d87ec` (24/24 and 29/29). If the index is committed as it stands, the committed log
  contradicts the committed decision's table row "24/24 and 29/29 … `review/evidence/clean-extraction.log`".
  **Repair:** stage the working-tree `clean-extraction.log` (`432d87ec`) together with the decision
  before publication. After the commit, verify that `git rev-parse HEAD:<path>/review/evidence/clean-extraction.log`
  equals `432d87ec…`.
- **O3 — The table's clean-extraction command refers forward to a commit that does not exist yet.**
  The `## Empirical check` table says `git archive HEAD | tar -x …` yields "24/24 and 29/29". Run
  today against HEAD (R3), that exact command yields **24/24 and 26/26**, because HEAD still
  carries the pre-revision `registry-and-standard.sh`. The log header was already reworded to
  `git archive <tree>` and "after this commit", and the prose conditions rerunnability on "after
  this decision is committed". R4 proves the relocation property on the current tree.
  **Repair:** align the table's command cell with the log header, for example
  `git archive <publication-commit>`. Alternatively, re-verify after publication that
  `git archive HEAD` yields 24/24 and 29/29.
- **O4 — `manifest.json` has an unstaged working-tree change.** The index copy matches the decision:
  `required_engines: ["codex","opus"]`, `state: partial`. The working-tree copy now reads
  `required_engines: ['muse','opus']`, apparently from a later engine substitution that revision 1
  does not describe. This is outside empirical scope. It is recorded so that the publisher does
  not stage a manifest that disagrees with the audited decision's `## Engines`.
- **O5 — Expected volatile drift.** `x52dev/oas3-rs` `pushed_at` moved from 2026-09-09 to
  2026-09-20. `oas3` downloads rose from 2,011,518 to 2,234,390, and `openapi-fuzzer` stars from
  577 to 578. The Decision section's dated figure "pushed 2026-09-09, check `B24`" remains true as
  a dated retrieval, and `B24` still passes. **Repair:** none needed. At `re-verify`, re-read the
  figures against `B23`/`B24`.

## 5. Verdict

Approve. Both named scripts execute today and exit 0. The probe passes 24/24 and the registry
check passes 29/29, with no SKIP, whether run in place or from a relocated copy. Every stable
assertion reproduces byte-for-byte. Every load-bearing figure I re-derived at source (the oas3
line anchors, MSRVs, harness size, seeded boundary and 0.01 s duration) matches the decision. The
only differences are toolchain drift and publication-staging hazards, listed as O1–O4 with
repairs. None of them falsifies a claim of revision 1.
