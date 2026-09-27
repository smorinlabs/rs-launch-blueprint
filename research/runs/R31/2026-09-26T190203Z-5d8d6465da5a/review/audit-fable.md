actor: audit-fable-R31-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 25480d8d487d4dbff38eeb4d44ee2c175ce5bea6ad635364ad93105c865550f9
verdict: reject
unresolved-findings:
  1. JF-3/JF-1 — decision:341 misrepresents the Muse leg's bandit-class mapping; the shell and SQL rows are a disagreement that is never recorded or adjudicated.
  2. JF-4/JF-10 — decision:349 and :235 rest `rs-sql-format` on `sqlx::query(&format!(..))`, which does not compile against current sqlx 0.9.0; the rule misses the only dynamic form that compiles.
  3. JF-1 (minor; would not block alone) — decision:619-629 says R31 has no engine override, but the live policy now has one.

# Judgment audit — R31 standalone-security-analyzer, DECISION.md revision 1

## Scope and method

This audit judges the reasoning and fidelity of the decision. It does not judge execution.
No evidence script was rerun, because the empirical seat does that.

- Target: `research/runs/R31/2026-09-26T190203Z-5d8d6465da5a/review/DECISION.md`.
- Hash: sha256 recomputed as `25480d8d…865550f9` before reading, equal to the expected value.
- Read in full: the decision, `inputs/prompt.md`, `inputs/prerequisites.json`, `manifest.json` and
  `raw/muse.md`. `raw/opus.md` was spot-checked at every line range the decision cites.
- Contract: `research/RUNBOOK.md` §2 (actors) and §5 (decision shape and acceptance).
- Prerequisite: `research/topics/11-ci-workflow-job-structure/DECISION.md`.
- Checked for context: citations into R06, R16, R42, R69 and R72.
- Not opened: any `review/audit-*.md` or `review/Rxx-r*-snapshot.md`.
- Public queries: read-only, 2026-09-27T03:50Z (2026-09-26 US/Pacific). They were
  `GET https://crates.io/api/v1/crates/sqlx`, `GET https://crates.io/api/v1/crates/sqlx/versions`
  and `GET https://crates.io/api/v1/crates/sqlx-core/0.9.0/download`. The crate was unpacked under
  `/tmp/sqlxchk`.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** | See Findings 1 and 3. `## Decision` line 341 says "Both legs agree on this mapping", but `## Engines` lines 631-639 limit the agreement to eval/exec and deserialization. Everything else is consistent: 3 of the 5 rules overlap CodeQL; the 16/18/19 query counts; the 555-file timing; the tier argument. |
| JF-2 prompt questions and constraints | pass | HIGH 1: no bandit analogue exists, and tooling concentrates on dependency scanning (lines 105-106, 631-634). HIGH 2: ts deferred rather than rejected, and F027 is public-only, so Rust has a stronger case (lines 361-376, 641-664). MEDIUM 3: `cargo-audit`/`cargo-deny` are R13's lane (lines 97-99, 633-635). MEDIUM 4: pre-commit, on measured cost (lines 81-86, 711-717). LOW: exclusions and inline suppression (lines 75-80). Fitness gates 1-6 answered (lines 390-399); gate 1 is `inapplicable` per the 2026-09-12 ruling, which is `execution-ledger.md:495`. Gaps are stated: survey not consulted; Linux not executed. |
| JF-3 engines faithfully represented | **fail** | See Finding 1. The other Muse citations checked are accurate: `raw/muse.md:29`, `:39`, `:57`, `:84` (pre-push and "two Rust queries"), `:92`, `:102`, `:116` and `:147`. It is also accurate that Muse never mentions ast-grep, opengrep or F027. Opus citations 58-64, 73, 82-86, 159-162, 196-205, 287-295, 393, 448-462, 477-483, 515-519, 537-539, 567-578, 673-677, 704, 711-712, 867 and 892-903 are all accurate. |
| JF-4 load-bearing claims trace | **fail** | See Finding 2. These claims trace correctly: R42 at `DECISION.md:27` and `:29`; R16 at `:60`, `:100` and `:110`; the R16 resolve log at lines 5, 25 and 47 (16/18/19); the 18 `security-extended` queries, which include CWE-089, CWE-295 and CWE-327 but not CWE-078; `COMMONALITY.md` rows F027 (line 33), F114, F115 and F147; `OWNER-REVIEW.md:259`; `execution-ledger.md:213` and `:495`; R11 `DECISION.md:259`; R06 `DECISION.md:53`. |
| JF-5 couplings hand over owned choices | pass | The lefthook job is labelled as "R31's slot" and R37 owns the file's shape (line 300). The CI step is "proposed, not executed", and R11 owns `ci.yml` (lines 311-313). Installation is delegated to R42. CodeQL, R13, R28 and R06 lanes are left untouched (lines 94-96). The F027 observation is passed to F027's owner without changing F027. The bare-executable rule follows R42's registered `package-manager-invocation` and does not re-decide it. |
| JF-6 assumes lines equal the live registry | pass | All 5 `assumes` lines equal `inputs/parameters.json` and occur byte-for-byte in the live `docs/port/PARAMETERS.md`. That includes the full `ci-job-structure` value. No owned parameter exists, which matches the empty `- owns:` line in the prompt. |
| JF-7 no conflict with published prerequisites | pass | R11 `DECISION.md` sha256 `410e88e5…` and `acceptance.json` sha256 `774f7649…` equal `prerequisites.json`. R11 is `resolved`. The containment argument that puts the scan in `hygiene` follows R11's registered rule. R16's `paths-ignore` list and codeql-action pin (bundle 2.26.4) are reproduced correctly. R13, R28 and R37 are `open`, and the decision treats them as assumptions (lines 780-783). |
| JF-8 evidence scripts exist; counts match | pass (spot-check) | E1-E5 each have a `.sh` and a `.log`. E1.1 shows 5 passed; E1.5 flags 15 lines; E1.6 flags 6 of 15; E1.8 shows 4 passed, 1 failed, exit 4. E2.1 prints "3 files, 5 rules"; E2.3 and E2.5c print their guard messages. E3 shows 555 files, 139,608 lines, 0.09-0.13 s wall, 0 findings versus 7. E5 ends with `0 failure(s)`. The config digest `62f24bce…` is identical in the E1, E2 and E3 logs. |
| JF-9 decision shape | pass | The H2s are `## Decision` (with `### Principles and implementation` and a `re-verify:` line), `## Parameters`, `## Empirical check` and `## Engines`. `## Supersedes` is correctly absent from a first revision. |
| JF-10 recommendation follows from evidence | **fail (partial)** | The main recommendation follows from the evidence: adopt a standalone scanner, use ast-grep, run it at pre-commit and as a `hygiene` step. The support is F027's public-only gate, the two classes CodeQL lacks at the pin, R42's crates.io preference and the measured cost. `rs-sql-format` does not follow, because its premise is false for the current version of the crate it names first (Finding 2). |

## Findings

### Finding 1 — JF-3 / JF-1: the Muse leg's bandit-class mapping is misreported, and the shell and SQL disagreement is never adjudicated

- **Failed claim** (`DECISION.md:341-342`): "**Which bandit classes survive in Rust.** Both legs agree
  on this mapping, and the mapping shapes the rule set." The table that follows marks "Shell invocation
  (B602, B605) | Survives" (line 348) and "SQL from strings (B608) | Survives" (line 349).
- **Evidence:** `raw/muse.md:29` says the opposite for both rows. It says "SQL string-formatting injection have no
  idiomatic-Rust equivalent (no `eval`, opt-in `serde`, typed query builders); `shell=True`
  injection is structurally absent because `std::process::Command` executes literal argv without
  a shell". Two of the five rules (`rs-shell-invocation`, `rs-sql-format`) therefore target classes
  that one leg says do not exist. `## Engines` lists Disagreements 1-11, and none of them covers
  this. Disagreement 3 addresses only whether CodeQL screens command handling. The decision also
  contradicts itself: `## Engines` lines 635-636 limit the legs' agreement to "`eval`/`exec` and
  unsafe-deserialization classes".
- **Repair:**
  1. Change line 341 so that it says the legs agree only on the eliminated classes.
  2. Add a Disagreement that quotes `raw/muse.md:29` and settles each of the two rows with evidence.
     - Shell: an explicit `Command::new("sh").arg("-c")` is ordinary Rust. The E1 fixtures and the
       7 test-only tokio hits (E3.3b) show it occurs in real code, even though `Command` itself uses
       no shell.
     - SQL: settle it through Finding 2.

  The direction of the decision likely survives. This finding is about fidelity, not the outcome.

### Finding 2 — JF-4 / JF-10: `rs-sql-format` is built on a `sqlx` call form that no longer compiles, and it misses the form that does

- **Failed claims:**
  - `DECISION.md:349`: "SQL from strings (B608) | Survives: `sqlx::query(&format!(..))`". It gives
    no sqlx version and no source.
  - Line 235: the `invalid:` fixture `sqlx::query(&format!("SELECT * FROM t WHERE id = {id}"))`.
  - Lines 154-158: the patterns, which key on `$Q(&format!(..))`, `$Q(format!(..))` and
    `$Q(format!(..).as_str())`.
- **Evidence, retrieved 2026-09-27T03:50Z:**
  - `GET https://crates.io/api/v1/crates/sqlx` reports `max_stable_version` `0.9.0`.
    `/versions` dates it `2026-05-21T17:35:53Z`, and it is not yanked.
  - In the `sqlx-core` 0.9.0 crate, `src/query.rs:653` reads
    `pub fn query<'a, DB>(sql: impl SqlSafeStr)`. `src/query_as.rs:341` has the same bound.
  - `src/sql_str.rs:47-56` implements `SqlSafeStr` only for `&'static str`. Lines 74-114 add
    `AssertSqlSafe<…>` wrappers. The trait's own documentation says it is "a speed bump against
    naively using `format!()`". Its `on_unimplemented` note says "wrap with `AssertSqlSafe()`".
  - Consequences for current sqlx:
    - `sqlx::query(&format!(..))` and `query(format!(..).as_str())` are compile errors, because the
      compiler already screens them.
    - The only dynamic form that compiles is `sqlx::query(AssertSqlSafe(format!(..)))`. None of the
      five `rs-sql-format` patterns matches it, because `$Q(format!($$$A))` needs `format!` as the
      direct argument.
  - The rule's `invalid:` cases pass `ast-grep test` (E1.1) only because ast-grep parses syntax and
    never compiles. The self-test guard therefore cannot detect an `invalid:` case that is not
    valid Rust against the named crate.
  - The defect comes from the Opus leg (`raw/opus.md:287-295`). The synthesis carried it forward
    and widened it; it did not introduce it.
  - For context, R72 records that the template's P02 web service "has no database at all"
    (`research/topics/72-api-pagination/DECISION.md:486`). The rule therefore guards descendant
    code only.
- **Repair:**
  1. Correct the line-349 row and name the sqlx version. For sqlx ≥ 0.9, the compiler rejects
     non-`'static` SQL, and `AssertSqlSafe(..)` is the audited escape hatch.
  2. Either add an `AssertSqlSafe($$$)` pattern (with an `invalid:` case) under a stated policy, or
     narrow the rule's stated value to APIs that still take runtime strings. rusqlite's
     `execute` and diesel's `sql_query` are examples; cite their current signatures.
  3. Replace the uncompilable sqlx fixtures.
  4. Record the parse-only limitation of `ast-grep test` under "Known limitations", together with
     how P03 will confirm that each `invalid:` case compiles against the pinned crates.

### Finding 3 — JF-1 (minor): the engine-identity gap is now stale

This finding would not block acceptance alone.

- **Failed claim** (`DECISION.md:619-623`): "neither the run's `inputs/EXECUTION.json` nor the live
  `research/EXECUTION.json` has an `engine_overrides` entry for R31. RUNBOOK names the sanctioned
  Muse-for-Codex substitutions, and R31 is not among them (`research/RUNBOOK.md:70-72`)".
- **Evidence:**
  - The live `research/EXECUTION.json` now has `engine_overrides.R31 = ["muse", "opus"]`.
  - `research/RUNBOOK.md:73-76` records "Q17.A (2026-09-27) extends the substitution to the research
    wave … R31 …".
  - The frozen `inputs/EXECUTION.json` still has no R31 entry, so that half of the claim remains
    true. Both updates were made after synthesis. Lines 790-798 of the decision already warn that
    RUNBOOK lines drift.
- **Repair:** rewrite the paragraph to cite Q17.A and the live override as the recorded
  substitution. State that the frozen policy input predates the substitution. Drop "R31 is not
  among them".

## Verdict

**reject.** Findings 1 and 2 are the basis. The ast-grep, pre-commit and `hygiene` direction is
well argued and well evidenced. However, the decision misreports one leg on two of its five rule
classes and leaves that disagreement unadjudicated. One of its rules also rests on an API form that
the named crate's current release rejects at compile time. A revision that makes the three repairs
above should be re-audited on the resulting revision.
