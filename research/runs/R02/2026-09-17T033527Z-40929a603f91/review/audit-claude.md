actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f
verdict: reject
unresolved-findings: 6 — EA-1: r02-check-r2.sh (revision-2 current) exits 1 on R2-9a (wanted 2, got 4 OV-03 references), and the EF6a disclosure is stale; EA-2: R2-9d/R2-9e match only H3 override headings; EA-3: EF4-guppy fails (guppy now 0.19.1); EA-4: B4 fails under CARGO_TARGET_DIR and its absent check passes vacuously; EA-5: "two orders above the 190" is 12.8x, one order; EA-6: the rustc/cargo 1.98.0 -> 1.98.1 version lines fall outside the stated comparison filter. Each finding is detailed under ## Findings.

# Empirical audit — R02 crate-boundary-enforcement, DECISION.md revision 2

**Auditor:** a fresh empirical auditor (Claude Opus family, `claude-opus-5-5`). It is independent of the synthesizer and of the judgment auditor. It read no `review/audit-*.md`, no `raw/` directory and no `R*-snapshot.md`.
**Date:** 2026-09-26. The evidence was recorded 2026-09-16 to 2026-09-18, so it is about 9 days old.
**Scope:** execution truth and evidence support only.

## Hash gate

`shasum -a 256 research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`
→ `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f`. This equals the expected value, so the audit proceeded. The copy extracted by `git archive HEAD` has the same hash. `HEAD` was `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`.

## Method

- **Why the rerun used a copy of the committed tree.** The shared working tree has uncommitted edits from another session. They touch `docs/port/PARAMETERS.md` (the `ci-job-structure` row, which R02 does not assume) and R02's `inputs/`, `manifest.json` and `operations/codex.json`. The audit binds to committed state, so each script ran in its own pristine `git archive HEAD | tar -x` extraction under `/tmp/r02-audit-claude/t-<script>/`.
- **Why each script got its own copy.** Three scripts write into `evidence/snapshots/`. Separate copies mean no script reads another's writes, and nothing was written to the real `evidence/`.
- **Command form.** From each extraction's `review/evidence/`, the command was `bash <script>.sh > /tmp/r02-audit-claude/logs/<script>.log 2>&1`. Each fresh log was then compared with the committed paired log using `cmp`, and with `diff` where they differed.
- **Evidence left untouched.** After all the reruns, `git status --short research/runs/R02/2026-09-17T033527Z-40929a603f91/review/` shows only `?? …/review/audit-claude.md`. Nothing under `evidence/` changed.
- **Pre-check.** All five scripts and all five logs in the extraction are byte-identical to the working-tree copies (`cmp`).
- **Toolchain observed:**
  - `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)` and `clippy 0.1.98`
  - cargo-deny 0.20.2, fetched by the script and checksum-verified
  - macOS 26.4 (build 25E246), Darwin arm64
  - `shellcheck` 0.11.0
  - `CARGO_HOME=/tmp/cargo-s15-R02-emp` and `CARGO_TARGET_DIR=/tmp/cargo-s15-R02-emp-target`, both inherited from the environment

**Which logs are current.** `## Empirical check` states: "Revision 2 added one script and re-ran none." The four revision-1 logs are revision-1 records carried byte-identical. Check `R2-7*` pins them by sha256, and all of `R2-7*` pass in my rerun. So `r02-check-r2.log` is the only log that is current for revision 2. The decision also discloses two revision-1 checks that are expected to fail against the current tree: `S1a` and `EF6a`. I reran all five scripts as instructed. I judge the revision-1 logs as records, and I treat the disclosed `S1a` failure as expected.

## Reruns

| Script | Exit | CHECKS / FAILURES / SKIPPED | Compared with the committed log | Assessment |
|---|---|---|---|---|
| `r02-check-r2.sh` **(current for revision 2)** | **1** (the decision claims 0) | 66 / **1** / 0 | differs from line 94: `FAIL R2-9a: OV-03 is now named outside this item, where revision 1's check EF6a required zero -- wanted [2], got [4]` | **Fails** (EA-1) |
| `r02-decision-shape.sh` | 1 | 33 / 1 / 0 | differs at line 8: `FAIL S1a: title line -- wanted [... (revision 1)], got [... (revision 2)]`. As a consequence, the `S8b` count is 53, where the revision-1 record has 52, because revision 2 cites `S1a` | Expected. The decision discloses this failure by design. Not a finding |
| `r02-workspace-probe.sh` | 1 in my environment. **0** with `env -u CARGO_TARGET_DIR` | 26 / 1 / –, and **26 / 0** with the variable unset | With the variable unset, all `PASS`/`FAIL`/`SKIP` lines are identical. 78 lines differ. After the decision's own filter (mktemp suffix and `Finished … in N.NNs`), the only lines left are the `cargo`/`rustc` version lines (74 + 4 = 78) | Passes with the variable unset. EA-4 and EA-6 |
| `r02-cargo-deny-bans.sh` | 0 | 17 / 0 / 0 | 20 differing lines: the mktemp suffix ×7 pairs, the `cargo 1.98.0`→`1.98.1` line, and `CD6` timing `0.437 s`→`0.190 s` (sub-second, which is the comparison rule the decision states). The published and observed tarball sha256 are both `fe67d82a…090c3` (`PASS CD0a`) | Passes. EA-6 |
| `r02-ecosystem-figures.sh` | 1 | 35 / **2** / 0 | `FAIL EF4-guppy: newest version of guppy -- wanted 0.18.0, got 0.19.1` and `FAIL EF6a: … wanted 0, got 4`. The other differences are `VOLATILE (not asserted)` counters, and `EF2d` now reads 2434 stars and still passes | EA-3, EA-1, EA-5 |

Other re-derivations:

- **`shellcheck`.** Running `shellcheck r02-workspace-probe.sh r02-ecosystem-figures.sh r02-cargo-deny-bans.sh r02-decision-shape.sh r02-check-r2.sh` exits 0. The decision's claim holds.
- **`EF5`–`EF5d`.** These pass against the committed registry: four fixed parameters, and the R69 and R49 clauses present verbatim.
- **Load-bearing results that reproduce.**
  - `A`: a single crate compiles an upward `use` with no error.
  - `C1`–`C4`: all four violations are build errors.
  - `E`, `F` and `G` reproduce.
  - `CD2a`–`CD5d`: the cargo-deny `wrappers` semantics, dev-dependency coverage and global `--all-features` placement reproduce.
  - The substantive `OV-03` claim holds (see EA-2).

## Findings

**EA-1 — the current revision-2 script fails `R2-9a`. The `EF6a` disclosure is stale for the same reason.**
- **Failed claim.** The decision says `r02-check-r2.sh` was run "exit 0, 66 checks, 0 failures, 0 skips, and its output byte-identical to the committed `r02-check-r2.log`". It also says: "Two files name it, both owner records under `docs/port/` … Checks `R2-9a`–`R2-9e` pin exactly that: two files".
- **Evidence.** The fresh run exits 1 with `CHECKS RUN: 66 FAILURES: 1 SKIPPED: 0`. The reference list now also contains:
  - `research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md`, from revision 3 (`1e3cdb5b`, 2026-09-18). Its hit is line 1090: "`OV-04` is unused elsewhere while `OV-01`, `OV-02` and `OV-03` are taken".
  - `research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md`, from revision 3 (`53b13f45`, 2026-09-18). Its hit is line 643: "`OV-03` (R02)".

  Both hits *acknowledge* that R02 owns OV-03. Neither claims it, so the substance is intact. **This is drift after publication, not an original error.** R02 revision 2 was committed at `d3acb9a5` (2026-09-18 15:07:17 -0700). The R80 revision-3 commit `53b13f45` came at 18:35:22 and the R77 revision-3 commit `1e3cdb5b` at 18:41:42 the same day. So the decision's byte-identical claim was true when it was written. But the pinned count of 2 is false, and the committed log no longer reproduces. The same drift makes `EF6a` report `got 4` where the decision's table explains exactly two owner-record hits. `R2-9b`'s message "both files are owner records" also still prints `PASS` while four files are listed, because `ok` tests only for the presence of the two substrings. That PASS message is now false.
- **Repair.**
  - Replace the exact `== 2` count in `R2-9a` with a per-file classification. Every hit must be either (a) an owner record under `docs/port/`, or (b) a decision whose every `OV-03` line also names `R02` or describes OV-03 as taken, with no heading that declares it. Fail on any other hit.
  - Reword `R2-9b` so it does not assert a file count.
  - Rerun the script and re-record `r02-check-r2.log`. Update the `EF6a` row and the "Two files name it" sentence to state the current set and the rule, rather than a count that other items can change.

**EA-2 — `R2-9d`/`R2-9e` are narrower than the claim they support.**
- **Failed claim.** The decision promises "**zero** decisions outside this item declaring an override numbered `OV-03` by heading — the form in which a competing claim would be made".
- **Evidence.** `R2-9d` greps only `'^### OVERRIDE (OV-03)'`, and the `R2-9e` control greps only `'^### OVERRIDE (OV-02)'`. But the programme's other overrides are declared at H4, sometimes with backticks: R77 has `#### OVERRIDE (OV-04) — …`, and R80 has ``#### `OVERRIDE (OV-05)` — …``. A competing H4 or backticked `OV-03` claim would therefore pass `R2-9d`. The claim is true today. My search with `/usr/bin/grep -nE '^#+ .*OV-03'` over every topic and run `DECISION.md` outside R02 returns **0**. An any-level override-heading census returns only OV-02 (R61), OV-03 (R02), OV-04 (R77) and OV-05 (R80).
- **Repair.** Change both patterns to `'^#+ .*OVERRIDE \(OV-0[23]\)'` (any heading level, backticks tolerated), and re-record the log.

**EA-3 — registry drift: `EF4-guppy`.**
- **Failed claim.** Line 42 names "`guppy` 0.18.0 as a custom-lint substrate", and `## Empirical check` says the script "confirms … `guppy` **0.18.0**".
- **Evidence.** The rerun prints `FAIL EF4-guppy: newest version of guppy -- wanted 0.18.0, got 0.19.1`. `GET https://crates.io/api/v1/crates/guppy/versions` returns `0.19.1 2026-09-24T17:19:47Z` and `0.19.0 2026-09-19T01:56:24Z`, and `0.18.0 2026-08-25`. So 0.18.0 was correct at the 2026-09-17 retrieval, and this is drift, not an original error. It is not load-bearing, because guppy is excluded "on fit", not on version.
- **Repair.** Make the `EF4-*` assertions time-bound. Assert "newest non-yanked version with `created_at` ≤ 2026-09-17T23:59:59Z" from the versions payload, which the script already fetches. Print today's newest version under a `VOLATILE (not asserted)` label. Alternatively, re-record at a new retrieval date, and write "0.18.0 as of 2026-09-17" in the decision.

**EA-4 — `r02-workspace-probe.sh` depends on `CARGO_TARGET_DIR`, and `B4`'s absence check passes vacuously.**
- **Failed claim.** The decision says `B4` shows "`target/debug` holds `rslbp` and not `rslbp-serve`", and that every script "assert[s] on the *content* their claim needs".
- **Evidence.** This environment exports `CARGO_TARGET_DIR`. In it, the rerun prints `ls: …/r02-probe.2rUdr6/ws/target/debug: No such file or directory`, then `FAIL B4: the rslbp binary is built by default -- missing substring: rslbp`, and then **`PASS B4: the feature-gated serve binary is skipped by default (required-features) (absent: rslbp-serve)`**. That last line passes against an empty listing, so it proves nothing. Rerun with `env -u CARGO_TARGET_DIR`, the script gives `CHECKS RUN: 26 FAILURES: 0` with all verdict lines identical. So the behaviour claim holds, but the script's result depends on the caller's environment.
- **Repair.** Set `export CARGO_TARGET_DIR="$W/target"` (or `unset CARGO_TARGET_DIR`) near the top of the script. Make every `absent` check fail when its input listing is empty or the command that produced it failed. A minimal version: assert that `rslbp` is present before asserting that `rslbp-serve` is absent. Apply the same guard to any other `absent` check that reads a command's output. Then re-record the log.

**EA-5 — "two orders above the 190" is not supported by the evidence.**
- **Failed claim.** `## Empirical check` says: "records `cargo-deny` at **2,426** stars, two orders above the 190 the gemini leg attributed to what it labelled the 'Actions repo'".
- **Evidence.** 2426 / 190 = 12.8×, and log10(12.8) ≈ 1.1. That is one order of magnitude, not two. The script's own verdict line says so: `PASS EF2d: cargo-deny has 2426 stars, an order of magnitude above the 190 …` (2434 in my rerun). The Engines row 6 states the figure without the multiplier and is unaffected.
- **Repair.** Change the wording to "about 13 times (one order of magnitude above) the 190".

**EA-6 — toolchain drift is not covered by the comparison rule.**
- **Failed claim.** For `r02-workspace-probe.log` and `r02-cargo-deny-bans.log`, the reproducibility table says that "a mechanical filter for those two patterns leaves **0** other differing lines".
- **Evidence.** After that filter, `cargo 1.98.0 (797e8a9bc 2026-08-05)` → `cargo 1.98.1 (797e8a9bc 2026-08-05)` still differs in both logs, and `rustc 1.98.0 (88d9e12ae 2026-08-18)` → `rustc 1.98.1 (48a229cea 2026-09-01)` also differs in the probe log. No verdict line changes.
- **Repair.** Either print the toolchain lines under a `VOLATILE (not asserted)` label and add them to the stated filter, or assert a tolerance such as `rustc 1.98.*`. Also record in `## Empirical check` that the results hold on 1.98.1 (observed 2026-09-26).

## Not findings, recorded for completeness

- **`S1a`** fails by design, as the decision discloses. `S8b` now counts 53 labels, against 52 in the revision-1 record. The difference is `S1a` itself, which revision 2 cites.
- **Volatile download and star counters** moved, as the decision says they would. None is asserted.
- **`CD6`** read `0.190 s`, which is sub-second, as the decision's comparison rule allows. The label and magnitude match.
