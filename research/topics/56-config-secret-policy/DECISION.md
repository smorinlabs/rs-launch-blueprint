# 2026-09-27 — R56 — config-secret-policy (bundle, Deep) — decision (revision 5)

## Decision

**Revision note (revision 5).** Revision 4 (sha256 `145ac5d7…`, preserved verbatim at
`review/R56-r4-snapshot.md`) was **approved** by its round-4 empirical audit
(`review/audit-claude.r4.md`, `verdict: approve`, no unresolved findings). It was
**rejected** by its round-4 judgment audit (`review/audit-fable.r4.md`, `verdict: reject`)
on one non-blocking finding, JA4-1. **No recommendation, crate, version or parameter value
moves in this revision.** The evidence the empirical audit reran is unchanged and was not
rerun. Revision 5 corrects R54's status in four places and adds two scripts and their logs
under `review/evidence/`, described under `## Empirical check`.

- **JA4-1 (non-blocking; JF-1, JF-4)** — "R54's owner-accepted status is described as
  unresolved." Granted. R54 revision 3 (sha256 `1348f6b3…`) was owner-accepted on
  2026-09-18, and that acceptance adopts `.rslbp/rslbp_config.toml` as the project tier
  (asserted, `check-r5-couplings.log` `K56`, `K57`). R54 is still `open` in the index and
  under further revision (`K58`); its current working decision still carries the tier
  (`K59`). Four statements are corrected. (1) The recommendation's parenthesis now names
  the file and the tier set as R54's accepted ones. (2) The composition-risk paragraph is
  now stated as an actual composition, not a conditional one. (3) Alternative E's cost now
  follows from E's own definition. (4) The `re-verify:` trigger now reads "R54 being revised
  to drop or rename the project tier". The Couplings paragraph gains an R54 entry labelled
  like every other sibling. `K56` pins R54's acceptance row the way `check-r4-couplings.sh`
  `K6` pins R55's. The confidence row for the config-file claim keeps its **High** grade:
  the accepted tier makes the argument against alternative B stronger, not weaker.

**Revision note (revision 4).** Revision 3 (sha256 `289422e8…`, preserved verbatim at
`review/R56-r3-snapshot.md`) was **rejected** by two audits. Its round-2 judgment audit
(`review/audit-fable.r2.md`, `verdict: reject`) raised one blocking finding, JA-1, and one
non-blocking finding, JA-2. Its round-3 empirical audit (`review/audit-claude.r3.md`,
`verdict: reject`) raised one non-blocking finding, EA3-1. Neither audit moved the
recommendation. **No recommendation, crate, version or parameter value moves in this
revision.** Revision 4 answers the half of the prompt's MEDIUM question that revision 3 left
open, corrects R55's status and one misreported rerun, and records a required engine report
that revision 3 omitted. Its new evidence is three scripts and their logs under
`review/evidence/`, described under `## Empirical check`.

- **JA-1 (blocking; JF-2, JF-3, JF-5)** — "the warning-mechanism half of the prompt's MEDIUM
  question is unanswered, the one engine that answered it is not represented, and no coupling
  is handed to R58/R59." Granted on all three counts. (1) Item 5 under
  `### Principles and implementation` now states the carrier: the library returns the
  loose-permission finding as typed data beside the resolved token and writes nothing; the
  binary renders it once, to stderr, after the logger exists. Acceptance criterion 10 makes
  that observable, and is marked **proposed**. (2) The Couplings paragraph hands R58 the
  rendering requirement and R59 the file-sink question without deciding either, and the
  `re-verify:` line gains an R58 trigger. (3) `## Engines` Disagreement 7 records OpenAI's
  buffered-diagnostic position and Muse's `warning-channel` member, and adjudicates both.
  Both agree with the repair.
- **JA-2 (non-blocking; JF-1, JF-4)** — "R55 is described as in flight and unpublished, but
  it was published." Granted. R55 revision 3 is published. The execution ledger records
  "R55 + R57 + R62 PUBLISHED, 2026-09-23" with acceptance `017b9e96` and transaction
  `b8c70833`. The topic's `acceptance.json` hashes to `017b9e96…` and binds R55's decision
  sha256 `5d358c1f…`, which is also the owner-accepted revision (asserted,
  `check-r4-couplings.log` `K2`–`K9`). The topic files' modification time reads
  2026-09-25 08:44 (`K9-detail`); the audit dated publication by that time, and this
  decision uses the ledger's date and prints the time beside it. All three stale statements
  are corrected: the Couplings paragraph, Disagreement 5 and the confidence table. The R55
  re-verify trigger now reads "R55 being revised" instead of "R55 publishing".
- **EA3-1 (non-blocking)** — "the `check-parameters-r2.sh` rerun result is misreported."
  Granted. At revision 3's tree that rerun gives 18 PASS / 4 FAIL, not 19 / 3. `PA6` also
  fails, because the script pins revision 2's title, which is the same mechanism as revision
  1's `PA6`. All three places now name `PA6` as the fourth failure. The same mechanism
  decides how the live parameter check is issued at this revision. `check-parameters-r3.sh`
  pins the revision-3 title, so after this retitle it fails `PA6` exactly as EA3-1
  describes. Regenerating `check-parameters-r3.log` in place would therefore record that
  failure, and it would overwrite the log that revision 3's audits reran. Instead, revision
  3's seven evidence files are left byte-identical and are pinned by sha256
  (`PA15.1`–`PA15.7`), and `check-parameters-r4.sh` re-pins `PA6` and `PA6c` to revision 4.
  Its log is the live record for this revision, and it is regenerated after every edit to
  this file.
- **The Muse leg (not an audit finding; recorded because the synthesis contract requires
  it).** `manifest.json` lists `required_engines` as `muse`, `opus`, `doxa`. The Codex leg
  was migrated to Muse under owner decision Q5.A (2026-09-21), and `raw/muse.md` (sha256
  `80472db4…`) was collected on 2026-09-22 (asserted, `K30`–`K35`). Revision 3 did not
  mention it; the round-3 empirical audit recorded that as an observation outside its seat.
  RUNBOOK §5 requires `## Engines` to cover every report, so revision 4 adds the report,
  corrects the Codex entry, and adjudicates the Muse positions that differ from this
  decision (Disagreements 3, 5, 6, 7 and 8). None of them moves the recommendation.

**Revision note (revision 3).** Revision 2 (sha256 `c2b4da75…`, preserved verbatim at
`review/R56-r2-snapshot.md`) was **rejected** by its round-2 empirical audit
(`review/audit-claude.r2.md`, `verdict: reject`) on two blocking findings and one
non-blocking finding. The audit found the behaviour itself supported: the JF-1 and JF-2
closures execute and pass, and every re-derived figure matches. What failed was the
reproducibility of revision 2's two checks and one description of what a check asserts.
**The recommendation, every parameter value and all of revision 2's reasoning stand
unchanged.** Revision 3 is an evidence repair. It adds three scripts and their logs
under `review/evidence/`, and it edits only this note, the revision history, the title,
`## Empirical check` and one line citation in `## Engines`.

- **EA-1 (blocking)** — "`check-parameters-r2.sh` exits 1 at the current tree (PA10,
  PA10c x2 FAIL)". Granted. Its fixture census listed auditor files by name, so each later
  audit that quoted a fixture broke it. Repair: `check-parameters-r3.sh` removes
  `review/audit-*.md` and frozen `review/R56-r<N>-snapshot.md` copies from the census **by
  pattern**. The no-fixture-in-any-log rules (`PA9`, `PA10b.1`, `PA10b.2`) and the
  sensitive-pattern search over every file (`PA8.1`–`PA8.5`) are unchanged.
  `check-r3-mutation.sh` proves the census ignores a later audit.
- **EA-2 (blocking)** — "`check-probe-r2.sh` hardcodes `./target/debug/r56probe_r2` and
  fails Q3–Q9 (probe exit 127) whenever `CARGO_TARGET_DIR` is set". Granted. Repair:
  `check-probe-r3.sh` exports `CARGO_TARGET_DIR="$work/target"` inside its own work
  directory and asserts the binary is there (`Q2b`). It passes with the variable set and
  unset, and the two logs differ only in `date-utc:`. The JF-1 and JF-2 assertions the
  audit confirmed (`E0`–`E4`, `F1`–`F6`) are carried over unchanged.
- **EA-3 (non-blocking)** — "`PA12-detail` is a printed detail, not an assertion, and
  cannot produce a FAIL". Granted, and repaired by assertion rather than rewording:
  `check-parameters-r3.sh` pins all fourteen revision-1 artifacts (`PA12.1`–`PA12.14`)
  and the seven revision-2 artifacts (`PA13.1`–`PA13.7`) by sha256. Every assertion ID in
  it is unique. Revision 2's sentence calling the printed roll an assertion is corrected
  under `## Empirical check`.

**Revision note (revision 2).** Revision 1 (sha256 `77cba891…`) was **rejected** by its
round-1 judgment audit (`review/audit-fable.md`, `verdict: reject`) on two blocking
findings, with a third recorded non-blocking. **The recommendation does not move, and no
parameter value moves**: the three-tier chain with a dedicated credential store, the crate
stack and its versions, the ledger dispositions, the `RSLB204` instance, the coupling
analysis and the five `- assumes` lines all stand exactly as revision 1 wrote them. The
auditor said so directly — "The recommendation is sound and it **does not move under any
finding**" — and confirmed the ordering against the standard's blob himself. What failed
was this decision's own executed-versus-proposed labelling, in two places.

**JF-1 (blocking)** — "Acceptance criterion 4 marks the chain's middle rung as executed,
and no assertion establishes it." Granted. Revision 1's criterion 4 cited `C1`, which
passes `stored = None`, and `C3`, which passes an *empty* env value; no probe call was
`resolve(None, Some("env-token"), Some(&cred))`, so "a set `RSLBP_TOKEN` outranks the
stored credential" — the middle rung this item exists to decide — carried an **executed**
label with nothing behind it. Repair: **executed, not relabelled.** A new
`evidence/probe-r2/` and `evidence/check-probe-r2.sh` run that exact call as `E1`, with
`E0` as the control that proves the stored credential is present and readable in the same
fixture (so `E1` is a precedence win and not an unreadable file), `E2`/`E3` asserting the
returned value is the env token and not the stored bytes, and `E4` exercising all three
tiers in one call. Revision 1's probe and its five scripts and logs are **not edited**;
they stay as the record of what revision 1 ran.

**JF-2 (blocking, and sharper because the committed log refutes rather than omits)** —
"Acceptance criterion 1 marks 'that warning names the file' as executed via `B1`–`B4`, and
the committed log's warning names no file while `scan_config` takes a document string."
Granted, and the auditor is right that the probe *could not* have carried the clause.
Repair: **executed, not relabelled.** The r2 probe's scanner is `scan_config_at(path, doc)`
— it is handed the layer's path — and `F2` asserts the emitted warning text contains that
path, `F3` that it names the key, `F4` that it contains none of the value's bytes, `F5`
and `F6` that naming the file changed neither the drop nor the surviving tables. The
finding's scope is respected: the recommendation text requiring the warning to name the
file and the key was correct as a P03 requirement and is unchanged.

**JF-3 (non-blocking)** — "'its `GlobalArgs` surface carries `--token-file`' phrases a
prescription as a description." Granted; R60 decides no flag spellings at all. The
superseded wording was "its `GlobalArgs` surface carries `--token-file`, not `--token`",
and it is replaced below with the form the Couplings paragraph already used —
`--token-file` is R60's surface *to carry*. The load-bearing claim in that parenthesis, the
0-occurrence count, is unchanged.

**Revision history.** Revision 1 — 2026-09-17, sha256 `77cba891…`, first decision from the
collected engine reports; rejected by the round-1 judgment audit on JF-1 and JF-2.
Revision 2 — 2026-09-17, sha256 `c2b4da75…`, closing JF-1 and JF-2 by execution and JF-3
by rewording; rejected by the round-2 empirical audit on EA-1 and EA-2.
Revision 3 — 2026-09-26, sha256 `289422e8…`, closing EA-1 and EA-2 with reissued checks and
EA-3 with pinned assertions; rejected by the round-2 judgment audit on JA-1 (JA-2
non-blocking) and by the round-3 empirical audit on EA3-1.
Revision 4 — 2026-09-26, sha256 `145ac5d7…`, closing JA-1 by stating the warning carrier
and the R58/R59 hand-off, JA-2 by restating R55 as published, and EA3-1 by correcting the
rerun record and reissuing the parameter check; it also records the Muse leg. Approved by
the round-4 empirical audit; rejected by the round-4 judgment audit on JA4-1
(non-blocking).
Revision 5 — this file, 2026-09-27, closing JA4-1 by restating R54 as owner-accepted with
its project tier and pinning that acceptance row. No `## Supersedes` section: this item is
not published.

**Status.** This is a *proposal validated in the implementation phase* (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. What P03 must validate, and what this
decision could not prove, is listed under `## Engines`. A decision that does not survive
implementation is revised against this recorded research, not researched again from
scratch.

**Licence gate.** `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Nothing is excluded on
licence anywhere in this decision; every licence string below is recorded as an observed
fact, read from the crates.io snapshot named beside it.

**Recommendation — `config-secret-policy/v1`. Adopt neither source repository's recorded
shape.**

> The layered configuration file — `rslbp_config.toml` per `R5.2`, with the name and the
> tier set fixed by R54, owner-accepted at revision 3 on 2026-09-18, including a project
> tier at `.rslbp/rslbp_config.toml` — at every discovery tier R54 defines, is **never** a
> token source, which is what py's ADR-0002 rules. The precedence
> chain nonetheless has **three** tiers, as ts's does, because the org CLI Design Standard
> `R10.1` **(MUST)** requires three — but the third tier is a **dedicated credential
> store**, not the config file. The chain is
> **`--token-file <PATH>` (or `-`, meaning stdin) > `RSLBP_TOKEN` > stored credential**,
> where the stored credential is by default a `0600` `credentials.toml` under R57's
> `state_dir()`, written only by `rslbp auth login`, never merged into the config chain
> and never project-discovered; an OS keychain may back it instead, behind a
> **non-default** Cargo feature. ts's non-fatal `mode & 0o077` warning is **kept and
> retargeted** from the config file to the credential file and to any `--token-file`
> argument — the two files that actually hold a secret. A `token` key found in any config
> layer is dropped with one warning that names the file and the key and never the value.

The stack that realizes it. `std` needs no version; the three crates carry the version
that resolved and built here, and each figure's endpoint and retrieval date are in
`review/evidence/snapshots/MANIFEST.txt`:

| Slot | Selection | Feature posture | Where it is declared |
|---|---|---|---|
| POSIX mode inspection, and `0600` creation at `O_CREAT` | `std::os::unix::fs::{PermissionsExt, OpenOptionsExt}` — **no crate** | `#[cfg(unix)]` with a `#[cfg(not(unix))]` stub that reports *unchecked*, never *clean* | library crate |
| In-memory carriage and `Debug` redaction | `secrecy` 0.10.3, no features (`serde` off) | default | library crate |
| Memory zeroing beneath it | `zeroize` 1.9.0, declared as an explicit floor | pulled by `secrecy` as `default-features = false, features = ["alloc"]` | workspace manifest |
| OS keychain, optionally backing the third tier | `keyring-core` 1.0.0, with `apple-native-keyring-store` 1.0.2 and `zbus-secret-service-keyring-store` 1.0.1 under `[target.'cfg(…)'.dependencies]` | **non-default** Cargo feature `keychain` | CLI binary crate only |

**Ledger rows this settles.** **F239** (may the config file carry the token) — *no*, and
the schema therefore has no `token` field. **F240** (the precedence chain) — *three tiers,
in `R10.1`'s order*, with the top tier naming a **file** rather than carrying a value.
**F245** (the loose-permission warning) — *kept*, non-fatal, with its subject moved from
the config file to the credential file and any `--token-file` target. The inherited rows
this item was told not to reopen are unaffected: F243 (`0600` write), F241 (env-var name
pattern), F242 (empty string is unset) and F246 (masking for display) all stand, and
§`### Principles and implementation` says how each is realized.

**The one deliberate extension beyond the prompt's binary.** The prompt poses the question
as py's rule versus ts's shape. Both are refused, because the standard that binds this
template answers a third way, and because "the config file" and "a credential file" are
different objects that ts conflates. That reading is not a preference: `R10.1`'s MUST
clause names three tiers whose third is a *stored credential*, and its SHOULD clause names
where that credential lives. The full quotation and its line number are in
`## Empirical check`.

**`RSLB204` acquires exactly one instance, and it is decided here rather than left open.**
R67 defined `RSLB204` ("secret supplied through a prohibited channel" → exit `2`)
prospectively. Under this policy it has one instance and one only: **`rslbp config set
token <value>` is refused with `RSLB204` at exit `2`**, pointing the user at
`--token-file`, `RSLBP_TOKEN` and `rslbp auth login`. That invocation is the prohibited
channel in its sharpest form — it both asks the tool to write a secret into the layered
config file (the channel this decision forbids) and puts the secret in `argv`, which
`R5.5` **(MUST NOT)** forbids outright. A `token` key the user typed into the file *by
hand* is deliberately **not** that case: it is a config-load fault, and R55's principle
that a configuration fault must never leave the user unable to repair the file makes it a
warning. So the same key produces an exit-`2` refusal through the command and a
non-fatal warning through the file, and the difference is which act is being refused.
**No `CONFLICT:` line is raised**: every failure state this policy produces already has a
row in R67's published catalog.

### Principles and implementation

**The shared requirement.** *A credential must reach the tool through a channel that does
not publish it to bystanders, and the user must be able to tell which channel supplied
it.* The principles under it are not all at the same agreement level, and conflating them
is how ts's design came to look like a mere ergonomic variant of py's:

| # | Principle | Source | Agreement level | Must agree across py / ts / rs | May vary |
|---|---|---|---|---|---|
| P1 | A secret is never carried in `argv` | `R5.5` **(MUST)**, standard blob `:327-329` (heading `:326`); clig.dev (`https://clig.dev/`, retrieved 2026-09-17), "Do not read secrets directly from flags" | **standard** | that the top tier names a *file* or reads stdin, never a value | the flag's spelling |
| P2 | Credentials resolve through one documented precedence chain | `R10.1` **(MUST)**, `:545` | **standard — one ordering for all three repos** | flag-supplied token-*file* > `TOOL_TOKEN` env > stored credential | how each runtime reads a file |
| P3 | The general-purpose config file is not a credential store | py ADR-0002 at pin `b08bccfb`; Cargo's `credentials.toml`/`config.toml` split; AWS's `credentials`/`config` split (`https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html`, retrieved 2026-09-17) | **policy** | that the layered settings file carries no secret | where the dedicated store lives, per OS |
| P4 | A stored credential is protected at rest | `R10.1` **(SHOULD)**, `:545` — "the OS keychain when available, falling back to a `0600` file under `$XDG_STATE_HOME/acme/`" | **capability** | that a stored credential is owner-only or OS-protected | keychain versus file; which keychain |
| P5 | A secret is masked wherever it is displayed | `R5.6` **(MUST)**, `:332` (heading `:331`); ledger F246 `COMMON → REUSE` | **standard** | that every display path masks | the mask's shape (ts: `***` plus the last four characters) |
| P6 | Failure to authenticate has a conventional status | `R6.1`, carried into this programme by R67 (`RSLB401`/`RSLB402` → exit `4`) | **standard** | exit `4` | the code string |

**Observable acceptance criteria.** Each is a statement about behaviour a test can
assert. Those marked **executed** were run here against a throwaway probe and are quoted
in `## Empirical check`; the rest are P03's and are marked **proposed**.

1. A config file carrying `token = "<secret>"` produces exactly one warning, that warning
   names the file and the key and contains none of the secret's bytes, the rest of the
   document is still accepted, and the token is not used. **executed** — the one-warning,
   key-dropped, tables-survive and no-secret-bytes clauses by `B1`–`B4`; the *names the
   file* and *names the key* clauses by `F2` and `F3` in the revision-2 probe, which hands
   the scanner the layer's path. Revision 1 labelled the whole criterion executed on
   `B1`–`B4` alone — "**executed** (`B1`–`B4`)" — and `B1`–`B4` cannot carry the
   file-naming clause, because revision 1's `scan_config` took a document string and its
   emitted warning, printed in full in `check-probe.log`, names no file. That is JF-2, and
   this is the executed repair rather than a relabel.
2. A credential file at `0600` produces no warning; the same file at `0644` produces one;
   at `0700` it produces none, proving the test is the `0o077` mask and not equality with
   `0600`. **executed** (`A2`, `A3`, `A5`).
3. The credential file is created at mode `0600` by `O_CREAT`, never created and then
   `chmod`-ed. **executed** (`A1`).
4. `--token-file` outranks a set `RSLBP_TOKEN`, which outranks the stored credential; an
   empty-string env value is treated as unset (F242 parity). **executed** — the top rung by
   `C1`, the F242 parity clause by `C3`, and the **middle rung** by `E1` in the revision-2
   probe, with `E0` as its control and `E2`, `E3`, `E4` around it. Revision 1 labelled the
   whole criterion executed on `C1` and `C3` alone — "**executed** (`C1`, `C3`)" — and
   neither call exercised the middle rung: `C1` passes `stored = None` and `C3` passes an
   empty env value, which is the fallback direction rather than the precedence one. That is
   JF-1, and this is the executed repair rather than a relabel.
5. `Debug` of the token type, and of any structure containing it, prints a placeholder,
   and no test's captured stdout or stderr contains a fixture token's bytes. **executed**
   (`D1`, `D2`, and a leak census returning `0`).
6. `--token-file <PATH>` naming a file that does not exist, or one empty after trimming,
   exits `4` with `RSLB401`; naming a file that exists and cannot be read exits `1` with
   `RSLB101`. **proposed** — and the probe carries the *opposite* behaviour as a labelled
   negative control (`C2`), so the fall-through this criterion forbids is visible rather
   than assumed away.
7. `rslbp config set token <value>` exits `2` with `RSLB204`. **proposed**.
8. `rslbp config view --show-origin` reports the token's source as `token-file`, `env` or
   `stored`, with the value masked. **proposed** (`R5.7` and `R5.6` together).
9. The `keychain` feature stores, retrieves and deletes an entry on each CI runner, or is
   documented as skipped there. **proposed, and the largest open risk** — see
   `## Engines`.
10. During credential resolution the library crate writes nothing to stdout, stderr or any
    file. A `0644` credential file yields exactly one warning line on the binary's stderr;
    the line names the path and `chmod 600`, contains none of the token's bytes, and leaves
    the exit code unchanged. Reading the resolved token a second time in the same process
    emits no second warning. **proposed** — the probe shows the data-return shape (`K54`,
    `K55`), but it is a single crate.

**What must agree across ecosystems, and what may not.** P1, P2, P3, P5 and P6 are
language-independent and must hold identically in py, ts and rs; making py and ts conform
is a follow-on project, and this decision supplies its rationale without touching either
repository or the ledger. Measured against them today, py satisfies P3 and P5 and violates
P1; ts violates P1 and P3. P4's *mechanism* is genuinely ecosystem-bound — Python reaches
for `keyring`, TypeScript for a helper process, Rust for `keyring-core` plus platform
store crates — and in Rust that choice carries a cost the other two do not pay, measured
below and decisive for the feature's default.

**The architectural alternatives, compared before any crate was chosen.**

| Architecture | What it gives | Why it is not selected |
|---|---|---|
| **A. py's ADR-0002 shape** — two tiers, flag then env, no file source of any kind | Zero durable plaintext credentials sanctioned by the tool | It violates `R10.1`'s **MUST**, which requires a third *stored-credential* tier, and it pushes users into unofficial persistence (a shell profile, a `.env`, a wrapper script) that the tool can neither see nor protect |
| **B. ts's shape** — three tiers with the layered config file as the lowest | Minimal implementation; a durable local login with no `auth` command | It puts the secret in the object users copy to new machines, commit to dotfile repositories and paste into issues. Its `mode & 0o077` mitigation addresses only same-host, other-user read access and says nothing about those vectors. It also violates `R10.1`, whose third tier is a stored credential, not a config key |
| **C. Three tiers with a dedicated credential store** — **selected** | `R10.1` satisfied exactly; the settings file stays shareable; the credential has one location, no tiers and no discovery, which is the property that keeps it out of a git working tree | It requires an `auth login`/`logout`/`status` command group that no research item currently owns (recorded under `## Parameters` as an ownership gap, not a conflict) |
| **D. C, but keychain-only, with no plaintext fallback** | Best at-rest protection | Untestable on `ubuntu-latest` without a Secret Service daemon fixture, and it would make the template's headline path depend on a capability most template users will not have. Cargo itself ships the plaintext provider as the default and treats the keychain providers as recommended configuration the user adds |
| **E. B confined to the user tier, refused in any project tier** | Keeps ts's ergonomics while closing the in-repository leak | **Ranked runner-up for the policy.** It wins only if the owner rules that a template must not ship an `auth` command. Its cost is exactly the risk py's ADR names: the user-tier file still holds the secret, and it is still the object users copy to new machines, commit to dotfile repositories and paste into issues. It also gives one key two dispositions: the loader must accept `token` in the user tier and refuse it in every other tier R54 defines, the accepted project tier among them |

**Why B's composition risk is not hypothetical.** ts's file tier is user-tier only, so its
token is never discovered from inside a repository. py *does* have a project tier, and the
standard's `R5.2` **(SHOULD)** puts a project tier at `.<tool>/<tool>_config.toml` in the
current directory *and each parent*. R54 has adopted that tier: its owner-accepted
revision 3 (2026-09-18) reads "the nearest .rslbp/rslbp_config.toml walking up from the
working directory, stopping inclusively at the first ancestor carrying .git or a
Cargo.toml that declares [workspace]" (asserted, `check-r5-couplings.log` `K56`, `K57`;
still present in R54's current working decision, `K59`). When the working directory is
inside a repository, the walk stops no higher than that repository's root, so the
project-tier file it finds lies inside the git working tree. Under B, therefore, the token is readable from, and writable into, a file in the user's
git working tree. That leak is created by *composition*, not by either item alone, which
is why this decision does not leave it to R54.

**Why the CI secret scanner does not backstop B either.** R17 is published and ships a
TruffleHog scan with `--only-verified --fail`, asserted present in
`review/evidence/check-siblings.log` (`X16`). `--only-verified` passes anything the scanner
cannot live-verify against the issuing provider. This template's token is a personal access
token for a fictional projects API: it has no detector and no issuer to verify against. So
the scanner is an argument for forbidding the channel, not for relying on the scanner to
catch its consequences. This is a limit on R17, not a criticism of it.

**How the selected design preserves each principle.**

1. **P3 — the layered config file is never a credential source.** R53's schema declares no
   `token` field, and R53's own out-of-scope list hands that question to this item
   verbatim: "*Whether the schema carries a `token` field at all* — R56 (F239/F240)"
   (asserted, `check-siblings.log` `X8`). A `token` key found in any layer is **dropped
   with one warning** naming the file and the key, never the value, with the exit code
   unchanged. That is R55's own disposition for an unknown key — "Unknown keys warn and
   never fail, in every layer" (asserted, `X9`, and at the published topic file's `:173`,
   `K10`) — borrowed rather than invented.
   Silently ignoring the key, which is py's behaviour, is rejected: the user who wrote it
   believes the tool is authenticated, and R55's second principle is that a degraded load
   is never silent.
2. **P1 and P2 — three tiers, in `R10.1`'s order.** `--token-file <PATH>` > `RSLBP_TOKEN` >
   stored credential. The tier *count* is ts's; the third tier's *identity* is not. The
   top tier accepts `-` as the path, meaning "read the token from stdin", which is the
   channel `R5.5` names alongside a file path and the one an `auth login` pipe uses.
3. **P3 and P4 — the third tier is a dedicated store.** By default a `0600`
   `credentials.toml` at `state_dir().join("credentials.toml")`, where `state_dir()` is
   the accessor on R57's owner-accepted template-owned `Paths` over `etcetera` 0.11.0
   (both asserted, `X11`, `X12`). `R5.3` files logs and history under State and `R10.1`
   names `$XDG_STATE_HOME/<tool>/` for exactly this file. It is written only by
   `rslbp auth login`, never by `config set`, never merged into the config chain, never
   project-discovered.
4. **P4 — the keychain is optional and off by default.** `keyring-core` behind a
   non-default `keychain` feature, for a cost measured rather than asserted: on
   `x86_64-unknown-linux-gnu` the feature takes the dependency tree from **10** packages to
   **89**, including an entire smol-family async runtime (`zbus`, `secret-service`,
   `async-executor`, `async-io`, `blocking`, `polling`, `event-listener`, each asserted
   present), and raises the tree's tightest declared MSRV from `1.85.0` to `1.88`. No
   `tokio` appears, which matters because R05 is unresolved and R69's web stack will bring
   its own runtime: enabling this feature by default would put a *second* async runtime in
   the Linux build of a template whose execution model is not yet decided. On the macOS
   host the same feature costs 3 packages. All four counts are executed
   (`review/evidence/check-probe.log`, `P7`–`P13`).
5. **P4 — the loose-permission check survives, retargeted, and the library returns it
   rather than printing it.** `mode & 0o077 != 0` is checked on the credential file and on
   any `--token-file` target, and produces one non-fatal warning naming the path and
   `chmod 600`, never the value.
   **Cardinality.** The finding is produced **once, at credential resolution**, never on
   every token read. Resolution runs once per process, and it opens at most one file,
   because it stops at the first tier that supplies a token.
   **Carrier.** The library crate returns the finding as typed data beside the resolved
   token — for example a `Vec<CredentialWarning>` field on the value resolution returns; the
   names are P03's. The library never writes the finding: R67's Layering clause, consumed
   under `## Parameters`, says the library crate "must write to no process stream or file".
   The binary renders each finding once, to **stderr**, after logger initialization. That is
   how published R55 carries its own `Vec<ConfigWarning>` (R55 `DECISION.md:264-270`,
   asserted `K11`–`K15`). The finding is not folded into R55's `ConfigWarning`, because that
   type's `source: ConfigSource` names a configuration layer, and the credential file is
   deliberately not one (item 3). How the binary renders the finding — a locked stderr write
   or an event through R58's subscriber — is R58's to decide (see Couplings).
   F245's mechanism is kept; only its subject moves.
   **What is executed.** The probe's `permission_warning` returns `Option<String>`, and only
   `main` writes to stderr (`review/evidence/probe/src/main.rs:36` and `:215`, asserted
   `K54`, `K55`). The probe is one crate, so the library/binary boundary itself is
   **proposed**, as acceptance criterion 10.
6. **P4 — creation is `0600` at `O_CREAT`.** `OpenOptions::new().create_new(true).mode(0o600)`
   via `OpenOptionsExt`, never create-then-`chmod`. ts writes
   `writeFileSync(path, data, { mode: 0o600 })` and then `chmodSync(path, 0o600)`
   (`chmodSync` asserted present at the ts pin, `check-standard.log` `S31`): on a rewrite
   of a pre-existing `0644` file the secret is on disk world-readable between the two
   calls. R52's decision already carries a `BASELINE-REVIEW: F243` disposition about
   atomic `0600` writes; this is the same concern at the syscall level and is recorded here
   as an implementation requirement, not as a second review of that row.
7. **P5 — the token is a `secrecy::SecretString` from the moment it leaves its source.**
   `R5.6` requires masking in "`config view`, `--debug`/request logs, progress, and error
   messages", which is an *open set* of call sites; a free masking function — which is what
   ts has — protects only the sites that remember to call it. `SecretString` makes the
   guarantee a property of the value: its `Debug` prints a placeholder and reaching the
   bytes requires an explicit `expose_secret()`, which is greppable in review and countable
   in CI. Executed: `Debug` of the secret renders `SecretBox<str>([REDACTED])`.
   **The limit, stated because it is easy to overclaim:** `secrecy` does not produce
   F246's *display* convention (`***` plus the last four characters); it makes the
   *default* safe. The masked preview is a `Display` impl the template writes on its own
   `Token` newtype over `SecretString`.
8. **P6 — every failure maps to a row R67 already has.** `--token-file` naming a missing or
   empty file, and no tier supplying a token, are `RSLB401` → `4`; a named file that exists
   but cannot be read is `RSLB101` → `1`, because that is an I/O fault and not an auth-policy
   fault; a remote rejection is `RSLB402` → `4`; `config set token <value>` is `RSLB204` →
   `2`; a `token` key in a layer has no code, because it is a warning. All five codes are
   asserted present in R67's published decision (`X1`–`X3`).

**Reference implementations, with their limits rather than a clean endorsement.**
`rust-lang/cargo` is the first-party precedent for the *file placement*: the token lives in
`$CARGO_HOME/credentials.toml`, written by `cargo login`, and the Cargo Book states that
`registry.token` "should only appear in the credentials file", with OS credential providers
recommended above the plaintext `cargo:token` provider
(`https://doc.rust-lang.org/cargo/reference/registry-authentication.html`, retrieved
2026-09-17 by the Opus engine). `conda/rattler`'s `rattler_networking` crate (`https://github.com/conda/rattler`, read
through `gh api repos/conda/rattler/contents/…` by the Opus engine on 2026-09-17) is the
closest maintained Rust composition of the recommended architecture — pluggable storage backends
named `file.rs`, `keyring.rs`, `memory.rs` and `netrc.rs`, with the keyring backend built on
`keyring_core::{Entry, api::CredentialStore}` and `#[cfg(target_os = …)]` store selection.
Two limits travel with it: it does **not** use `secrecy`, and its file backend sets no mode
at all. So it validates the *shape* and is weaker than this recommendation on two axes. No
single project was found that uses `secrecy` and `keyring-core` together, and none is
claimed. Two counterexamples are recorded rather than hidden: GitHub's `gh` stores its OAuth
token inside its own configuration directory, so "never a config file" is not universal
industry practice; and **Cargo itself accepts a token as a plain `--token` flag value**, the
exact shape `R5.5` forbids. The honest reading is that `R5.5` is *stricter* than the
ecosystem's own practice rather than a description of it. The owner's standard binds this
template regardless, and it is Cargo's file *placement*, not its flag surface, that this
decision follows.

**Published Rust guidance on credential sources — the LOW question, answered including its
null result.** There is no RustSec rule about credential sources: RustSec publishes
vulnerability advisories, and `https://rustsec.org/packages/<name>.html` returns HTTP `404`
for every crate in this stack (retrieved 2026-09-17), with `nix` returning `200` and listing RUSTSEC-2021-0119 as
the positive control that proves a `200` is reachable and a `404` is a real absence
(executed, `check-registry.log`). **And no separate CI standard document exists** — the
phrase "the CI standard's secret-handling rules" has no referent. `cli-standards` at this
blob's repository holds `cli-design-standard.md`, `docs`, `LICENSE` and `README.md` and no
CI standard; a recursive `/usr/bin/grep` over `docs`, `research/CLAUDE.md` and
`docs/superpowers` returns exactly one match, and that match is the P02 execution ledger's
own record of this same finding (executed, `check-standard.log` `S24`, `S25`). The CI-side
secret rules that do exist and were used are R17's published decision and
`docs/port/areas/ci-workflows.md`.

**Provenance of `R10.1`, stated precisely rather than leaned on.** `R10.1` is **derived**,
not `org-locked`: Decision Log row 26 (`:88`) records it as `derived`, whereas rows 1–10
(`:63-72`) are the `org-locked` ones and cover command ordering, `-v`, structured output,
noun number, boolean negation, env prefix, exit codes, config format and filesystem paths.
The standard's conformance clause (`:50`) makes every **MUST** binding for conformance
regardless of provenance, so `R10.1`'s MUST binds this template — but, unlike `R5.3` or
`R6.1`, the owner may reopen it without disturbing an org-locked row. That distinction is
stated because the sibling R57 decision leaned on `org-locked` for `R5.3` and the same move
is not available here. `R5.5` and `R5.6` are rule-level MUSTs in §5 with no Decision-Log
provenance row of their own. §10 binds this template because §10's own scope note (`:542`)
covers "CLIs that talk to a remote API or service": both sources' tokens are personal
access tokens for a remote projects API, and R69's `web-extra-surface` adds an HTTP surface.

**`BASELINE-REVIEW` findings carried, each with this decision's disposition.** None of
these edits the ledger, another item, py or ts; each is raised for the owner.

BASELINE-REVIEW: F240 — a credential must never be readable from the process table, so the top precedence tier must name a *file* (or read stdin) rather than carry a value — replace the recorded `--token <VALUE>` flag tier in all three repositories with `--token-file <PATH>` plus a stdin path, leaving the tier's precedence position unchanged — evidence: org CLI Design Standard v1.4.14 blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, `R5.5` **(MUST)** at `:327-329`, "Secrets (tokens, passwords, keys) **MUST NOT** be accepted as plain command-line flags or positionals, because argv is visible in process listings … ✅ `ACME_TOKEN=… acme login`, `acme login --token-file ./tok` ❌ `acme login --token sk_live_abc123`", reinforced by `R10.1` at `:545` and by clig.dev; both sources violate it at their pins — py `src/py_launch_blueprint/cli/options.py` declares `"--token"` and ts `src/router.ts:136` declares `--token <token>` and documents it as remedy 1 in `missingTokenMessage`, so the leak is not incidental but recommended (all four textual facts asserted in `review/evidence/check-standard.log`, `S12`, `S14`, `S15`, `S27`, `S30`).

- **Disposition: adopted**, and this decision is written as though it holds. Affected
  items: **R56** (this item — the chain's top tier); **R60** (`cli-parsing-framework`,
  owner-accepted at revision 9 and published — `--token-file` is R60's surface to carry,
  and R60 decides no flag spellings, so this adds a flag to a surface whose spellings were
  left open rather than overturning one it settled; the string `--token` occurs **0** times in R60's, R67's
  and R52's published decisions, counted with `/usr/bin/grep -c`, so this raises no
  collision with a published sibling); **R61** (`interactive-prompts` — the stdin path);
  **R67** (`RSLB204` acquires the single instance named in `## Decision`). Changes to py
  and ts remain a follow-on project.

BASELINE-REVIEW: F239 / F240 / F245 — credential exposure minimization — adopt ts's three-tier `flag > env > file` chain across all three repositories, with the configuration file as a sanctioned lowest-precedence token source protected by a `mode & 0o077` warning — raised independently by all three Doxa providers (`raw/doxa-gemini.normalized.md` for F239/F240/F245, `raw/doxa-perplexity.normalized.md` for F239/F240, `raw/doxa-openai.normalized.md` for F239/F240/F245), on the grounds that a two-tier chain degrades CLI ergonomics and that Cargo, Git and the AWS CLI all accept file-borne credentials under strict permissions.

- **Disposition: rejected on the standard, and carried so the owner sees it rather than
  only its refusal.** The ergonomic premise is accepted and is *met* by this decision's
  third tier: a durable local credential exists. What is refused is putting it in the
  layered settings file. The three providers reached the opposite conclusion from the same
  industry evidence because none of them could read the org CLI Design Standard, which is
  a private repository Doxa has no access to; and the industry precedents they cite —
  Cargo's `credentials.toml`, Git's `.git-credentials`, the AWS CLI's `~/.aws/credentials`
  — are each a **dedicated** credential file, which is this decision's third tier, not a
  key in the tool's settings file. `R10.1` **(MUST)** settles the ordering and the third
  tier's identity; `R5.5` **(MUST NOT)** settles the top tier. See `## Engines`,
  Disagreement 1.

**Couplings, stated rather than left implicit.** R57 (owner-accepted): the credential file
is `state_dir().join("credentials.toml")` on R57's template-owned `Paths`; it is
deliberately **outside** R54's discovery, having exactly one location and no tiers. R54
(owner-accepted at revision 3 on 2026-09-18, still `open` in the index and under further
revision; asserted `check-r5-couplings.log` `K56`–`K58`): no token is read at any tier it
defines, its accepted project tier `.rslbp/rslbp_config.toml` included, and the credential
file is not one of its tiers. If R54 is revised to drop or rename the project tier, the
composition paragraph above moves — a re-verify trigger, recorded below. R60
(owner-accepted at revision 9, `clap` 4.6.6 derive): `--token-file` is R60's surface to
carry, and it takes **no** `#[arg(env = …)]` binding — `R5.4` (`:322`) curates the env
surface around auth/token, host, output format, config path and telemetry opt-out, not a
token *path* — so the env tier is read by the resolver itself and `RSLBP_TOKEN` stays the
env tier per F241. R61 (owner-accepted): a stdin token read must respect R61's
interactivity gate at the call site (`std::io::IsTerminal`, asserted `X15`); R61 selects
`Confirm`, `Text`/`CustomType`, `Select` and `MultiSelect` and **no masked password
shape** (asserted `X14`), so the hidden-input path an interactive `auth login` wants is
covered by no decision yet — a gap, not a collision. R55 (published at revision 3, which
the owner accepted on 2026-09-17 and the programme published on 2026-09-23; asserted
`K2`–`K9`): the `token`-key warning is R55's unknown-key disposition, stated in the
published decision at `:173` (`K10`), so if R55 is revised this clause moves with it — a
re-verify trigger, recorded below. R53 (owner-accepted): no `token` field is added to its
schema. R52 (published): the probe parses the config fixture with R52's `toml` 1.1.6, so
the drop-the-key assertion ran against the accepted parser. R17 (published): unaffected by
this item, and explicitly not a backstop for it. R67 (owner-accepted): consumed unchanged.
R58 (open; it owns `logging-pipeline-contract`, which this item does not consume — asserted
`K17`, `K19`, `K21`–`K23`): R58 must accept the credential-resolution warning as a typed
value that the binary renders after logger initialization. Published R55 states the same
requirement for its own warnings: "**R58** must accept a `Vec<ConfigWarning>` rendered by
the binary" (R55 `:561`, `K16`). This item hands R58 that requirement and decides nothing
about R58's crate, subscriber or output format. R59 (open, `file-log-sink`, downstream of
R58, asserted `K18`, `K20`): whether the rendered warning is also written to a file sink is
R59's choice. The warning carries a path and a remedy and never the token, so this item
places no constraint on that choice.

re-verify: 2026-12-17, or earlier on any of — the owner reopening `R10.1`, which Decision Log row 26 marks `derived` rather than `org-locked` and is the one standard dependency here that can move without an org change; R54 being revised to drop or rename the project tier its owner-accepted revision 3 adopts, which moves the composition risk above; R55 being revised to an unknown-key disposition other than warn-and-continue, which moves the `token`-key clause; R58 publishing, in particular with a pipeline that cannot render a typed warning the binary supplies after initialization, which moves the warning carrier in item 5; R53 publishing a schema that carries a `token` field; R05 selecting an async runtime, which changes the cost of the Linux `keychain` tree; R61 publishing a masked-input prompt shape, which supplies the interactive `auth login` path; `secrecy` publishing 0.11, or 2027-09-17 passing with in-tree commits and no release; `keyring-core` publishing 1.1 or 2.0, or `oo7` reaching a stable release with a declared MSRV at or under the then-current floor; GitHub-hosted `ubuntu-latest` images gaining a session bus and a Secret Service daemon, which would make the keychain tier testable; any RustSec or OSV advisory against `secrecy`, `zeroize`, `keyring-core`, either platform store crate, `zbus` or `secret-service`; or current stable Rust rising such that the stable-minus-2 floor passes `1.88`, the `keychain` tree's binding MSRV.

## Parameters

This item owns no registry parameter: the prompt's `## Couplings` carries an empty
`- owns:` line, `research/CLAUDE.md` lists R56's `owns` column as `—`, and
`docs/port/PARAMETERS.md` has no row naming R56 (all three asserted in
`review/evidence/check-siblings.log`, `X17`–`X19`).

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

How each bears on the decision, stated here rather than on the lines above.
`rust-edition` and `msrv-policy`: the probe's manifest declared edition `2024` and
`rust-version = "1.96"`, the floor that stable-minus-2 yields from current stable, and it
resolved and built; the tightest declared floor in the default dependency tree is
`1.85.0` (`hashbrown` 0.17.1) and in the `keychain` tree `1.88`
(`zbus-secret-service-keyring-store`), both under the floor. `target-os-matrix`: both
runners are POSIX, which is what makes the permission check unconditional in practice —
and also what makes the keychain tier untestable on the Linux runner without a
Secret Service daemon fixture. `license`: the gate is `inapplicable — owner ruling
2026-09-12 (Q7.B)`; every selected crate's licence string is nonetheless `MIT OR
Apache-2.0` or `Apache-2.0 OR MIT`, read from the registry snapshots and recorded as
observed. `error-taxonomy-exit-codes`: this item consumes `RSLB401` (exit `4`), `RSLB402`
(exit `4`), `RSLB101` (exit `1`) and `RSLB204` (exit `2`) and adds no row; `RSLB204` gains
the single instance named under `## Decision`.

**No `CONFLICT:` line is raised.** Every failure state this policy produces is expressible
in R67's published catalog, and no consumed parameter needs a different value.

**Two ownership gaps, recorded here because they are not conflicts and must not be
silently absorbed.** First, **the `auth` command group has no owning item**: `R10.1`
**(MUST)** requires `auth login`, `auth logout` and `auth status`, and the recommended
third tier is written by `auth login`, but `research/CLAUDE.md` assigns that command
inventory to no `R##` — R60 owns the parsing framework, not the inventory. Someone must own
it before P03. Second, **no item owns a masked-input prompt**: R61 selects four prompt
shapes and none is a password field, so an interactive `auth login` has no decided way to
read a token without echoing it.

## Empirical check

**Toolchain and environment.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, host `aarch64-apple-darwin`, macOS
`26.4`, `shellcheck` 0.11.0, run 2026-09-17 (UTC). Working directory for every command:
the repository root, `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. The Opus engine
ran its own probe on the same toolchain strings on the same date; the probe below is this
synthesizer's, built and run here, not that one's output copied forward. **Revision 3's
checks and reruns** ran on 2026-09-26 (Pacific; the logs' UTC stamps read 2026-09-27) with
`rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, on the same host, OS and `shellcheck`.
They used a private `CARGO_HOME` and an exported `CARGO_TARGET_DIR`, which is the
environment that exposed EA-2. The revision-1 and revision-2 logs keep their `1.98.0` lines.
**Revision 4's checks and reruns** ran on 2026-09-26 (Pacific; the logs' UTC stamps read
2026-09-27) on the same toolchain (`rustc 1.98.1`, `cargo 1.98.1`), host, OS and
`shellcheck` as revision 3, with a private `CARGO_HOME` and an exported `CARGO_TARGET_DIR`.
**Revision 5's checks** ran on 2026-09-27 (Pacific 2026-09-27 00:30; the logs' UTC stamps
read 2026-09-27T07:30Z and later) on the same host, OS and `shellcheck`. They invoke no
Cargo command, so the toolchain does not bear on them.

**Nothing was built that this decision recommends.** No seam, service, hook pipeline,
acceptance script or template scaffold exists. What ran is a throwaway Cargo package under
a `$TMPDIR` subdirectory created for the run and deleted after it, whose sources are
committed as a fixture at `review/evidence/probe/` (`Cargo.toml`, `Cargo.lock`,
`src/main.rs`) so the numbers are reproducible. The probe is a measuring instrument: it
implements the *naive* resolver so the fall-through the decision forbids is visible as a
labelled negative control, and it does not implement the recommendation.

**The checks, their commands and their results — five from revision 1, two from revision 2,
three from revision 3 and three from revision 4, all unchanged and not rerun into new logs,
plus two added by revision 5.**
Each script asserts on content, never on an exit status alone; each starts with
`set -o pipefail`; each names `/usr/bin/grep` by absolute path beside every count it
reports, because a typed `grep` in these shells is `ugrep` and honours `.gitignore`; and
all fifteen are `shellcheck` 0.11.0 clean, rechecked at revision 5. Six carry a
file-scoped `SC2016` waiver with its reason. In `check-standard.sh` and `check-siblings.sh`, the
assertion needles are the standard's and the siblings' own backtick-bearing text quoted
verbatim. In `check-probe-r2.sh` and `check-probe-r3.sh`, one needle is the probe's
backtick-bearing warning text. In `check-r4-couplings.sh` and `check-r5-couplings.sh`, the
needles are the sources' own backtick-bearing text quoted verbatim.
Every one was run from the repository root with `./review/evidence/<name>.sh`, and its
complete output is the committed log beside it.

| Script | What it decides | PASS assertions | Result | Log |
|---|---|---|---|---|
| `review/evidence/check-standard.sh` | that the standard really says what this decision rests on, at the blob and line numbers cited; that both sources violate `R5.5` at their pins; that no CI standard document exists | 32, plus 3 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-standard.log` |
| `review/evidence/check-siblings.sh` | every claim this decision makes about R67, R60, R53, R55, R57, R61, R52 and R17, and about this run's own engine inventory | 30, plus 10 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-siblings.log` |
| `review/evidence/check-registry.sh` | the crate versions, release dates, MSRV floors, licences, download figures, the `secrecy`→`zeroize` edge, the `forbid(unsafe_code)` posture and the advisory status, read from committed snapshots | 38, plus 3 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-registry.log` |
| `review/evidence/check-probe.sh` | the behavioural claims, the dependency-tree sizes and the tree MSRV maxima, by building and running the probe | 35 (15 from the probe, 20 from the script), plus 1 detail line | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-probe.log` |
| `review/evidence/check-parameters.sh` | that `## Parameters` carries no `- owns` line and that its five `- assumes` values `diff` empty against lines regenerated from the current `docs/port/PARAMETERS.md`; the H2 set, the title, the single `re-verify:` line; and that no personal email, credential pattern or probe fixture reaches any log | 15 | **all PASS**, `CHECK_FAILURES=0`, exit `0` — **against revision 1** | `check-parameters.log` |
| `review/evidence/check-parameters-r2.sh` | **added by revision 2, superseded by `check-parameters-r3.sh`**: everything the revision-1 script asserts, re-pinned to revision 2, plus the second probe's two fixtures and a *printed* sha256 roll of the revision-1 artifacts (`PA12-detail`, never asserted — EA-3) | 22 PASS lines, 20 distinct IDs | **all PASS** at revision 2's commit; at revision 3's tree it exits `1` with 18 PASS and 4 FAIL: `PA6`, because the title no longer reads revision 2, and `PA10` and both `PA10c` lines, because later auditor files and the revision-2 snapshot now name the fixtures (EA-1). Revision 3 recorded only the last three; that was EA3-1 | `check-parameters-r2.log` |
| `review/evidence/check-probe-r2.sh` | **added by revision 2, superseded by `check-probe-r3.sh`**: the chain's middle rung (JF-1) and the warning that names its file (JF-2), by building and running a second throwaway probe at `review/evidence/probe-r2/` | 23 (11 from the probe, 12 from the script) | **all PASS** with `CARGO_TARGET_DIR` unset; with it set, exit `1` and 7 FAIL, the probe exiting `127` (EA-2) | `check-probe-r2.log` |
| `review/evidence/check-probe-r3.sh` | **added by revision 3**: `check-probe-r2.sh` with the target directory pinned inside its work directory, plus `Q2b`, which asserts the binary is at the pinned path; same probe, same fixtures | 24 (11 from the probe, 13 from the script) | **all PASS**, `CHECK_FAILURES=0`, exit `0`, both with `CARGO_TARGET_DIR` exported and with it unset | `check-probe-r3.log` (variable set), `check-probe-r3.unset.log` (unset) |
| `review/evidence/check-parameters-r3.sh` | **added by revision 3**: revision 2's assertions re-pinned to revision 3; the fixture census with auditor files and snapshots excluded by pattern; sha256 pins asserted for the 14 revision-1 and 7 revision-2 artifacts; the snapshot's sha256 | 44 distinct IDs, one PASS line each | **all PASS**, `CHECK_FAILURES=0`, exit `0`, at revision 3. **Superseded at revision 4 by `check-parameters-r4.sh`**: rerun against this file it fails `PA6`, because it pins the revision-3 title | `check-parameters-r3.log` |
| `review/evidence/check-r3-mutation.sh` | **added by revision 3**: in a `$TMPDIR` copy, plants a later `audit-*.md` quoting all three fixtures and edits one revision-1 and one revision-2 artifact by one byte, then runs `check-parameters-r3.sh` | 5 (`M0`–`M4`) | **all PASS**, `CHECK_FAILURES=0`, exit `0`: the unmutated copy passes; the mutated copy exits `1` with exactly `PA12.11` and `PA13.4` failing, while `PA10` and both `PA10c` still pass. **Superseded at revision 4 by `check-r4-mutation.sh`**: its baseline runs `check-parameters-r3.sh`, so `M0` fails at revision 4 | `check-r3-mutation.log` |
| `review/evidence/check-parameters-r4.sh` | **added by revision 4**: revision 3's assertions with `PA6` and `PA6c` re-pinned to revision 4; sha256 pins asserted for the seven revision-3 artifacts (`PA15.1`–`PA15.7`); the revision-3 snapshot's sha256 (`PA16`) | 52 distinct IDs, one PASS line each | **all PASS**, `CHECK_FAILURES=0`, exit `0`, at revision 4. **Superseded at revision 5 by `check-parameters-r5.sh`**: rerun against this file it fails `PA6`, because it pins the revision-4 title | `check-parameters-r4.log` |
| `review/evidence/check-r4-mutation.sh` | **added by revision 4**: `check-r3-mutation.sh` run against `check-parameters-r4.sh`, plus a one-byte edit to one revision-3 artifact (`check-probe-r3.log`, `PA15.4`) | 5 (`M0`–`M4`) | **all PASS**, `CHECK_FAILURES=0`, exit `0`, at revision 4: the unmutated copy passes; the mutated copy exits `1` with exactly `PA12.11`, `PA13.4` and `PA15.4` failing, while `PA10` and both `PA10c` still pass. **Superseded at revision 5**: its baseline runs `check-parameters-r4.sh`, so `M0` fails at revision 5 | `check-r4-mutation.log` |
| `review/evidence/check-r4-couplings.sh` | **added by revision 4**: the prompt's MEDIUM question; R55's publication and its warning carrier, read from the published topic files; R58's and R59's status and ownership; OpenAI's six carrier lines; the Muse report's identity, operation, manifest entry and each Muse position `## Engines` adjudicates; `R8.2`'s exit rule; R67's `RSLB101` and `RSLB104` rows; the probe's data-return shape | 55 (`K1`–`K55`), plus 2 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-r4-couplings.log` |
| `review/evidence/check-parameters-r5.sh` | **added by revision 5**: revision 4's assertions with `PA6` and `PA6c` re-pinned to revision 5; sha256 pins asserted for the six revision-4 artifacts (`PA17.1`–`PA17.6`); the revision-4 snapshot's sha256 (`PA18`) | 59 distinct IDs, one PASS line each | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-parameters-r5.log` |
| `review/evidence/check-r5-couplings.sh` | **added by revision 5**: R54's owner-acceptance row and the project tier it adopts, R54's index status, and the project tier in R54's current working decision (JA4-1) | 4 (`K56`–`K59`), plus 1 detail line | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-r5-couplings.log` |

`review/evidence/refresh-snapshots.sh` is a sixth script and is **not** a check: it is the
only thing in this tree that touches the network, and it exists so that the checks never
do.

**1. The standard, read at the blob this item is bound to.**
`git -C /Users/stevemorin/c/cli-standards cat-file -p f9de0437baece3383e73ca2c5f48b7ab399b51c7`.
`git cat-file -t` reports `blob`, so `git show <sha>:cli-design-standard.md` cannot be used
— that hash is the file's blob, not a commit. The extracted text is 773 lines and hashes to
`9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f`. The load-bearing rule,
quoted from line `545` and asserted there:

(quoted inside a fence, not a blockquote, because the rule's own `>` precedence arrows
would otherwise be read as quote markers):

```text
Authentication lives under an `auth` group: `acme auth login`, `acme auth logout`,
`acme auth status`. Credentials **MUST** resolve in the order flag-supplied token‑*file*
> `ACME_TOKEN` env > stored credential, and a token **MUST NOT** be passed as a plain
flag value (R5.5). Stored credentials **SHOULD** use the OS keychain when available,
falling back to a `0600` file under `$XDG_STATE_HOME/acme/` (R5.3). Auth failures exit
`4` (R6.1).
```

and from line `327`, `R5.5` **(MUST)**:

> Secrets (tokens, passwords, keys) **MUST NOT** be accepted as plain command-line flags
> or positionals, because argv is visible in process listings. Accept them via environment
> variable, a file path, a credential helper, or stdin.

The same script asserts `R5.6` at `:332`, `R5.4`'s curated-env clause at `:322`, §10's
scope note at `:542`, the conformance and SHOULD-waiver clauses at `:50`, Decision Log
row 26 marked `derived` at `:88` and row 8 marked `org-locked` at `:70`; then, at the
programme pins, that py's `options.py` declares `"--token"` and its ADR-0002 exists, and
that ts's `config.ts` carries `tokenSource = 'file'`, `0o077` and `chmodSync` while
`router.ts` declares `--token <token>`. The three repositories it reads are outside this
one, so the script **SKIPs by name** when they are absent — which is what a
`git archive HEAD` extraction of this tree produces.

**2. The siblings, read inside this repository.** Repo-internal only, so it runs unchanged
from a clean `git archive HEAD` extraction with no `.git` and no network. It records each
sibling decision's sha256 as a detail line, then asserts: `RSLB401`, `RSLB402`, `RSLB101`,
`RSLB204` and `RSLB205` all present in R67, with `RSLB204`'s and `RSLB401`'s definitions
quoted; `--token` occurring **0** times in each of R60's, R67's and R52's published
decisions; R53 deferring the token-field question to R56 and declaring no `token:` field;
R55 carrying the unknown-key-warns clause; R57 exposing `pub fn state_dir(&self)` over
`etcetera` 0.11.0; R61 selecting `inquire` 0.9.4, gating on `IsTerminal`, and containing
**0** occurrences of `Password`; R17 carrying `--only-verified`; and this run's own
inventory — no `raw/codex.md`, `raw/codex-exit.txt` = `1`, the transcript recording a usage
limit, and the two present raw reports hashing to the values named in this synthesizer's
brief.

**3. The registry, advisories and crate source, read from committed snapshots.**
`review/evidence/refresh-snapshots.sh` performs the fetches and writes
`snapshots/MANIFEST.txt`, which carries each file's endpoint and its retrieval timestamp
(`2026-09-17T15:22:50Z`); `check-registry.sh` asserts against those bytes rather than
re-fetching, because `crate.recent_downloads` and `pushed_at` move continuously and a check
that re-fetches cannot be rerun and diffed. Observed, all from
`GET https://crates.io/api/v1/crates/<name>` and `/versions`, newest `yanked: false`
version, retrieved 2026-09-17:

| Crate | Version | Released | Declared MSRV | Licence | `recent_downloads` | `downloads` |
|---|---|---|---|---|---|---|
| `secrecy` | 0.10.3 | 2024-10-09 | 1.60 | Apache-2.0 OR MIT | 39,955,248 | 162,048,552 |
| `zeroize` | 1.9.0 | 2026-06-12 | 1.85 | Apache-2.0 OR MIT | 176,274,852 | 695,051,028 |
| `keyring-core` | 1.0.0 | 2026-04-21 | 1.85 | MIT OR Apache-2.0 | 2,413,858 | 2,739,732 |
| `apple-native-keyring-store` | 1.0.2 | 2026-08-06 | 1.85 | MIT OR Apache-2.0 | 1,414,598 | 1,584,784 |
| `zbus-secret-service-keyring-store` | 1.0.1 | 2026-08-15 | 1.88 | MIT OR Apache-2.0 | 1,384,369 | 1,480,639 |

`GET https://crates.io/api/v1/crates/secrecy/0.10.3/dependencies` shows `zeroize` at
`^1.6` with `default_features: false, features: ["alloc"]` and `serde` at `^1` **optional**,
which is the declared edge the compatibility claim rests on. The crate's own published
source at 0.10.3 — snapshotted as extracted text rather than as the `.crate` tarball,
which `.gitignore` excludes under `research/runs/**/*.crate`, so that a rerun can actually
read it back — carries `#![forbid(unsafe_code)]` in `src/lib.rs`, declares
`edition = "2021"` and `rust-version = "1.60"`, and has **no `[features]` table at all** — so `serde` is off unless the
implicit optional-dependency feature is turned on, and a `SecretString` cannot be
`Serialize`d into a config file or a log line by accident. `unsafe` posture, therefore:
`secrecy` forbids it outright and the volatile writes live in `zeroize`, which uses
`unsafe` deliberately and cannot be `forbid(unsafe_code)`; that is a dependency's `unsafe`,
not the template's, and it is the one place in this stack where R06's policy has a live
subject. Advisories: `https://rustsec.org/packages/<name>.html` returns **404** for
`secrecy`, `zeroize`, `keyring-core`, `apple-native-keyring-store` and
`zbus-secret-service-keyring-store`, and **200** for `nix`, whose page lists
RUSTSEC-2021-0119 — the positive control proving the `404`s are real absences rather than a
broken fetch. **Maintenance state by rubric, each verdict earned rather than assumed.** `zeroize` is
**`active`**: released 2026-06-12, repository pushed 2026-09-15, not archived.
`secrecy` is **`stable-quiet`**. The rubric's "no release in 6 months" fires — `0.10.3` is
dated 2024-10-09 — and a trigger is an instruction to investigate, never a verdict, so the
investigation was run here rather than carried over:
`gh api "repos/iqlusioninc/crates/commits?path=secrecy&per_page=6" --jq …`, snapshotted as
`snapshots/gh-commits-secrecy.json` (retrieved 2026-09-17), shows the `0.10.3` release
commit on 2024-10-09 followed by **five** further commits touching `secrecy/` — three in
late 2024, `Rust edition 2024 & MSRV 1.85 (#1347)` on 2026-01-21, and
`doc_auto_cfg => doc_cfg (#1387)` on 2026-09-02. The directory is being carried forward
in-tree, including an edition-2024 move, without a publish; the monorepo is not archived
and was pushed 2026-09-09; there is no advisory and no maintainer notice of abandonment.
`at-risk` needs a concrete signal and `dormant` needs an unpatched advisory, a broken build
on current stable or a maintainer's own notice — none is present, and the probe compiled
`secrecy 0.10.3` on current stable here. `keyring-core` is **`stable-quiet`** on the same
reasoning: one release, `1.0.0` on 2026-04-21, and a repository untouched since
2026-04-21, which trips the trigger — but the parent `keyring-rs` was pushed 2026-09-15 and
`apple-native-keyring-store` published `1.0.2` on 2026-08-06, so the quiet reads as a
frozen 1.0 API rather than abandonment. The two platform store crates are **`active`**.
No issue-responsiveness median is asserted anywhere in this decision; Opus computed some,
they are monorepo-scoped and use "first comment by someone other than the issue author" as
a proxy for "first maintainer response", and no claim here rests on them.

Repository state, via the authenticated `gh` binary with `--jq` (no token, no
header and no environment is ever printed):
`iqlusioninc/crates` 579 stars, `archived: false`, pushed `2026-09-09T15:52:06Z`, 30 open
issues; `RustCrypto/utils` 672 stars, `archived: false`, pushed `2026-09-15T13:36:52Z`,
24 open issues; `open-source-cooperative/keyring-core` 37 stars, `archived: false`, pushed
`2026-04-21T18:53:26Z`. Open-issue counts come from
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, field
`total_count`, never `open_issues_count`.

**4. The probe.** `check-probe.sh` copies `review/evidence/probe/` into a `$TMPDIR`
subdirectory, runs `cargo generate-lockfile --locked` (the committed `Cargo.lock` holds
106 `[[package]]` entries: the 105 dependencies Cargo reports locking, plus the root
package), builds with `cargo build --locked`, runs the binary, and measures. Observed
output, in full:

```
PASS A1 create-at-0600 — mode after create_new(.mode(0o600)) = 0600
PASS A2 no-warning-at-0600 — 0600 produces no warning
PASS A3 warning-at-0644 — warning emitted = true
PASS A4 warning-omits-secret — warning text does not contain the credential
PASS A5 no-warning-at-0700 — the check is the 0o077 mask, not equality with 0600
PASS B1 config-token-warned — 1 warning(s)
PASS B2 config-token-dropped — `token` absent from the accepted table
PASS B3 other-keys-survive — [output] survives the drop
PASS B4 warning-omits-secret — warning names the key, not the value
PASS C1 token-file-wins — source=TokenFile
PASS C2 NEGATIVE-CONTROL missing-token-file-falls-through — source=Env (the decision forbids this: it MUST be RSLB401/4)
PASS C3 empty-env-is-unset — source=Stored (F242 parity)
PASS C4 no-token — source=None
PASS D1 debug-of-secretstring-redacts — Debug of SecretString = SecretBox<str>([REDACTED])
PASS D2 debug-of-resolved-redacts — Debug of resolved = Some(SecretBox<str>([REDACTED]))
PROBE_FAILURES=0
```

and the script's own measurements:

```
PASS P6 leak-census-/usr/bin/grep — 0
PASS P7 tree-default — 10
PASS P8 tree-keychain-macos — 13
PASS P9 tree-keychain-linux — 89
PASS P11 no-tokio — no tokio in the Linux keychain tree — the runtime pulled is the smol family
PASS P12 msrv-max-default — 1.85.0
PASS P13 msrv-max-keychain — 1.88
P12-detail tightest default-tree package: hashbrown 0.17.1 1.85.0
```

`C2` is the negative control: the probe implements the naive resolver so the silent
fall-through is visible, and acceptance criterion 6 forbids it. The leak census is
`cat out.txt err.txt | /usr/bin/grep -c 'sk_live_R56PROBE_DO_NOT_LOG'` over the binary's
combined stdout and stderr, and it returns `0`; the fixture credential appears in no
committed log. Package counts come from
`cargo tree --locked -e normal --prefix none | sed 's/ (\*)//' | sort -u | /usr/bin/grep -c .`
and MSRV maxima from `cargo metadata --locked --format-version 1 --filter-platform <triple>`,
excluding the root package, whose own `rust-version` is the floor being tested.

**Why revision 1's `check-parameters.sh` is reissued rather than rerun, said plainly
rather than left to be discovered.** Two of its fifteen assertions pin revision-1 facts:
`PA6` pins the title's revision number, and `PA10` pins the exact list of files naming the
probe fixture. Retitling this file to revision 2 therefore makes revision 1's `PA6` stop
matching, and revision 2 adds a second probe and is quoted by the judgment audit, which
extends `PA10`'s list. The revision rules forbid editing a cited script or log, so
`check-parameters.sh` and `check-parameters.log` are left exactly as revision 1 committed
them, and `check-parameters-r2.sh` carries the same fifteen assertions re-pinned to this
revision plus seven more.

A rerun of revision 1's script against this file therefore exits `1` with **eight**
failures, and they are enumerated here rather than left as a surprise, because every one of
them is a check correctly pinned to a superseded revision rather than a defect in this one:
`PA6` (the title now reads revision 2); `PA8.1`–`PA8.5` and `PA11` (revision 1's script
excludes only *itself* by name from its sensitive-pattern search, so the new sibling script,
which necessarily names the same patterns in order to search for them, trips all five — a
self-reference between two scripts, not a leak, and `check-parameters-r2.sh` excludes the
whole `check-parameters` family for exactly this reason); and `PA10` (the fixture-file list
has grown by `audit-fable.md`, where the judgment auditor ran his own census, and by the new
sibling script). `check-parameters-r2.log` was the live record for revision 2 and reported
`CHECK_FAILURES=0` at revision 2's commit. Correction at revision 3 (EA-3): the "seven more"
are seven PASS *lines* — `PA6b`, `PA6c`, `PA6d`, `PA10b` twice and `PA10c` twice — so the
22 PASS lines carry 20 distinct IDs. The sha256 roll of the fourteen revision-1 artifacts
is **not** one of them. It is printed as `PA12-detail` and never asserted, so an edit to a
revision-1 artifact changes the log but produces no FAIL and no non-zero exit.

**Why revision 2's two checks are reissued at revision 3.** Revision 2's checks are left
exactly as committed, for the same reason revision 1's were. Each failure below is
reproduced in a rerun, and each is a defect in the check, not in the behaviour it checks.

- **`check-parameters-r2.sh` (EA-1).** Rerun at revision 3's tree, it exits `1` with 18
  PASS and 4 FAIL: `PA6`, `PA10`, `PA10c` and `PA10c`. `PA6` fails because the script pins
  revision 2's title, the same reason as revision 1's `PA6`; revision 3 omitted it and
  recorded 19 / 3, which is EA3-1, corrected at revision 4. Beyond revision 2's allowlist, the census now finds
  the revision-1 fixture in `audit-fable.r1.md` and `R56-r2-snapshot.md`. It finds each
  revision-2 fixture in `audit-fable.md`, `check-probe-r3.sh` and `R56-r2-snapshot.md`.
  (The rerun printed these names; this synthesizer did not open any audit file other than
  `audit-claude.r2.md`.)
  An allowlist of auditor files by name cannot survive a process that adds audits after
  the check is written. `check-parameters-r3.sh` therefore drops files matching
  `^(audit-[^/]*\.md|R56-r[0-9]+-snapshot\.md)$`, relative to `review/`, before comparing.
  Auditor files quote fixtures as evidence of their own census. A snapshot is a frozen copy
  of a decision. Neither defines or emits a fixture. The rules that detect a real leak are
  kept. `PA9`, `PA10b.1` and `PA10b.2` require every fixture to be absent from every
  `*.log`. `PA8.1`–`PA8.5` still search every file under `review/`, auditor files
  included, for the sensitive patterns. The remaining expected lists are
  `DECISION.md evidence/check-probe.sh evidence/probe/src/main.rs` for the revision-1
  fixture (`PA10`), and `DECISION.md evidence/check-probe-r2.sh evidence/check-probe-r3.sh
  evidence/probe-r2/src/main.rs` for each revision-2 fixture (`PA10c.1`, `PA10c.2`).
- **`PA12`/`PA13` (EA-3).** The fourteen revision-1 values are the ones
  `check-parameters-r2.log` printed. The round-2 audit found all fourteen unchanged. The
  seven revision-2 values were read at revision 3 and equal the blobs at `HEAD` `e0b0d1c1`.
  Each value is now a `want` assertion (`PA12.1`–`PA12.14`, `PA13.1`–`PA13.7`), and
  `PA14` asserts that `R56-r2-snapshot.md` hashes to revision 2's sha256.
  `check-parameters-r3.log` reports 44 PASS lines with 44 distinct IDs and
  `CHECK_FAILURES=0`. It was the live record for revision 3, and its line 3 carries
  revision 3's sha256, `289422e8…`. At revision 4 it is frozen and pinned (`PA15.2`), and
  the live record is `check-parameters-r4.log`.
- **The repair is tested, not only asserted.** `check-r3-mutation.sh` copies `review/`
  and `docs/port/PARAMETERS.md` into a `$TMPDIR` directory and runs
  `check-parameters-r3.sh` there twice. The unmutated copy exits `0` (`M0`). It then plants
  `review/audit-zzz-later.md` quoting all three fixtures, and appends one byte each to
  `refresh-snapshots.sh` and `check-probe-r2.log`. The mutated copy exits `1` (`M1`).
  `PA10`, `PA10c.1` and `PA10c.2` still pass (`M2`). The only FAILs are `PA12.11` and
  `PA13.4` (`M3`), with `CHECK_FAILURES=2` (`M4`). The script assembles the fixture strings
  from two halves, so the script itself never enters the census it tests.

**5. The revision-2 probe, which closes JF-1 and JF-2.** `check-probe-r2.sh` copies
`review/evidence/probe-r2/` into a `$TMPDIR` subdirectory, runs
`cargo generate-lockfile --locked` (18 `[[package]]` entries: 17 dependencies plus the root
package), builds with `cargo build --locked`, runs the binary and asserts. It does **not**
rerun any revision-1 script, and revision 1's probe, its five scripts and their logs are
byte-identical to what revision 1 committed. Observed output, in full:

```
PASS E0 CONTROL stored-tier-is-reachable — with no flag and no env, source=Stored and the stored value is the one on disk
PASS E1 JF-1 env-outranks-stored — source=Env (R10.1 middle rung: RSLBP_TOKEN > stored credential)
PASS E2 JF-1 env-value-is-the-one-used — the resolved value is the env token, not the stored credential
PASS E3 JF-1 stored-value-not-used — the stored credential's bytes are not what resolution returned
PASS E4 full-chain-in-one-call — all three tiers supplied, source=TokenFile
PASS F1 JF-2 exactly-one-warning — 1 warning(s)
PASS F2 JF-2 warning-names-the-file — the warning text contains the scanned layer's path
PASS F3 JF-2 warning-names-the-key — the warning text names the key `token`
PASS F4 JF-2 warning-omits-the-value — the warning text contains none of the value's bytes
PASS F5 key-still-dropped — naming the file did not change the drop behaviour
PASS F6 other-tables-survive — [output] still survives the drop
PROBE_R2_FAILURES=0
stderr: warning: <TMPDIR>/r56-r2-<pid>/rslbp_config.toml: key `token` is ignored — this tool never reads a credential from the config file. Use --token-file, the RSLBP_TOKEN environment variable, or `rslbp auth login`.
```

`E0` is the control that makes `E1` mean what it says: without it, "env wins over stored"
could be an unreadable stored file rather than a precedence win, so `E0` first proves the
same fixture resolves to `Stored` when no flag and no env are supplied. The echoed warning
carries a `<TMPDIR>/r56-r2-<pid>` placeholder in place of the run-specific temporary
directory — the probe substitutes it before printing, while `F2` asserts against the
**real** path — so this log stays diffable across runs. Two fixture credentials are used
(`sk_live_R56R2_STORED_DO_NOT_LOG` and `sk_live_R56R2_CONFIG_DO_NOT_LOG`) and the script's
leak census returns `0` for each over the probe's combined stdout and stderr.

**Reproducibility, stated exactly rather than claimed generally, and tested the way an
auditor tests it.** Every script was rerun in place and the rerun diffed against the
committed log; then the whole tree was extracted with
`git archive HEAD | tar -x -C "$TMPDIR/<dir>"` and the six live checks — revision 1's
`check-standard.sh`, `check-siblings.sh`, `check-registry.sh` and `check-probe.sh`, plus
revision 2's `check-probe-r2.sh` and `check-parameters-r2.sh` — were rerun from that
extraction, with no `.git` and from a different absolute path, and diffed again. Revision
1's `check-parameters.sh` is deliberately not in that set: it is pinned to revision 1 and
its eight expected failures are enumerated above. Each is
byte-reproducible **except for its own `date-utc:` stamp**, which the script prints itself
at the top of its output; `check-parameters.log` additionally carries the decision's own
sha256, which changes whenever the decision is edited and is therefore regenerated last.
No other line differs in place. From the extraction **exactly one further line differs**,
and it is named here so the diff is expected rather than surprising: `check-siblings.sh`'s
`X23` becomes `SKIP X23 codex-refusal-recorded — raw/codex-transcript.txt is absent
(gitignored: research/runs/*/*/raw/*-transcript.txt)`, because `.gitignore` excludes that
transcript from the archive. All six live checks still exit `0` there. One thing was changed
to make the rest true rather than asserted: no script prints an absolute path into its log,
since two of them did and their logs would otherwise have differed between a working tree
and an extraction. The SKIP is **by name** for the same reason a silent guard would be a
defect — it would make this decision cite an assertion the rerun does not emit. The volatile sources — crates.io counters, GitHub repository fields, RustSec pages
— are *not* re-fetched by any check: they live in `review/evidence/snapshots/` with their
endpoints and retrieval timestamps, and `refresh-snapshots.sh` is the only thing that
touches the network. That is the rule for comparing across the variance: **diff the logs
ignoring the leading `date-utc:` line**, and refresh the snapshots deliberately, never as a
side effect of a check.

**Reproducibility at revision 3, rerun on 2026-09-26.** The paragraph above records what
revision 2 observed at its own commit. Revision 3 reran every earlier check from the
repository root into scratch files under `$TMPDIR`, diffed each against its committed log,
and wrote no earlier log. The environment is the one named under *Toolchain and
environment*, with `CARGO_TARGET_DIR` exported unless the row says otherwise.

| Check | Exit | PASS / FAIL | Lines that differ from the committed log, besides `date-utc:` |
|---|---|---|---|
| `check-standard.sh` | `0` | 32 / 0 | none |
| `check-registry.sh` | `0` | 38 / 0 | none |
| `check-siblings.sh` | `0` | 30 / 0 | two: the `X0-detail` sha256 of R61's `DECISION.md` (R61 has been revised since; this is a printed detail, not an assertion), and `X26`, which now locates the `W1-CODEX` row at `docs/planning/p02/owner-decisions.md:486` rather than `:485`. The citation in `## Engines` is updated to `:486`. |
| `check-probe.sh`, `CARGO_TARGET_DIR` unset | `1` | 34 / 1 | the toolchain lines, and `P0 lockfile-is-current` FAIL (see below) |
| `check-probe.sh`, `CARGO_TARGET_DIR` exported | `1` | 16 / 4 | `P0` as above, plus `P3`–`P5`: the probe exits `127`, because line 52 runs `./target/debug/r56probe`, the same defect as EA-2 |
| `check-probe-r2.sh`, unset | `0` | 23 / 0 | the toolchain lines |
| `check-probe-r2.sh`, exported | `1` | 5 / 7 | EA-2, as the round-2 audit reported |
| `check-parameters-r2.sh` | `1` | 18 / 4 | `PA6`, because the title read revision 3 (revision 3 recorded 19 / 3 and omitted it — EA3-1, corrected at revision 4); plus EA-1: `PA10`, `PA10c`, `PA10c`, as listed above |
| `check-probe-r3.sh`, exported and unset | `0` | 24 / 0 | the two new logs differ from each other only in `date-utc:` |

`P0` fails for a reason that is not in the round-2 audit. `cargo generate-lockfile
--locked` re-resolves the manifest against the **live** crates.io index. Since 2026-09-17,
`wasm-bindgen`, `wasm-bindgen-macro`, `wasm-bindgen-macro-support` and
`wasm-bindgen-shared` moved from `0.2.128` to `0.2.129`, and `js-sys` moved from `0.3.105`
to `0.3.106`. A fresh resolution still holds 106 `[[package]]` entries. The build from the
committed lockfile still succeeds (`P2`), all 15 probe assertions pass, and every measured
figure is unchanged: `P7` 10, `P8` 13, `P9` 89, `P12` `1.85.0`, `P13` `1.88`. The sentence
above saying that `refresh-snapshots.sh` is "the only thing that touches the network" is
therefore inexact. `P0` and `Q0` read the crates.io index. They assert "the committed
lockfile is what Cargo would resolve today", which is true on the day of the run and can
become false later without any change here. `Q0` still passes today for the 18-package
`probe-r2` lockfile. Revision 1's script is not edited. The drift is recorded here rather
than repaired, because no claim in this decision depends on the index staying fixed.

Portability of the revision-3 checks: they are not in `HEAD`, so `git archive HEAD` cannot
contain them. Instead, `check-r3-mutation.sh` runs `check-parameters-r3.sh` from a copy of
`review/` and `docs/port/PARAMETERS.md` at a different absolute path, and its unmutated
baseline passes (`M0`). `check-probe-r3.sh` builds in its own `$TMPDIR` work directory by
construction and prints no absolute path.

**Revision 4's checks, and reproducibility at revision 4, rerun on 2026-09-26.** Revision 4
adds three scripts and edits no earlier script or log.

- **`check-parameters-r4.sh`** is `check-parameters-r3.sh` with three changes. `PA6` and
  `PA6c` are re-pinned to revision 4. `PA15.1`–`PA15.7` pin the seven revision-3 evidence
  files by sha256, at the bytes revision 3's audits reran; those values were read before
  any revision-4 run. `PA16` asserts that `R56-r3-snapshot.md` hashes to `289422e8…`. The
  census pattern already excludes the new snapshot. `check-parameters-r4.log` reports 52
  PASS lines with 52 distinct IDs and `CHECK_FAILURES=0`. It was the live record for
  revision 4, and its line 3 carries revision 4's sha256, `145ac5d7…`. At revision 5 it is
  frozen and pinned (`PA17.2`), and the live record is `check-parameters-r5.log`.
- **`check-r4-mutation.sh`** repeats revision 3's mutation test against
  `check-parameters-r4.sh` and adds a one-byte edit to `check-probe-r3.log`. The unmutated
  copy exits `0` (`M0`). The mutated copy exits `1` (`M1`), `PA10`, `PA10c.1` and
  `PA10c.2` still pass (`M2`), and the only FAILs are `PA12.11`, `PA13.4` and `PA15.4`
  (`M3`), with `CHECK_FAILURES=3` (`M4`).
- **`check-r4-couplings.sh`** asserts at source every fact this revision adds: 55
  assertions, `K1`–`K55`, summarized in the table above. It reads files inside this
  repository, plus the standard's blob for `K51`, which it SKIPs by name when the
  `cli-standards` repository is absent. It locates ledger rows by content rather than by
  line number, because that file grows while the programme runs, and prints each row's
  current line number.

Every earlier check was rerun from the repository root into scratch files under
`$TMPDIR`, and each rerun was diffed against its committed log. No earlier log was
written. `CARGO_TARGET_DIR` is exported unless the row says otherwise.

| Check | Exit | PASS / FAIL | Lines that differ from the committed log, besides `date-utc:` |
|---|---|---|---|
| `check-standard.sh` | `0` | 32 / 0 | none |
| `check-registry.sh` | `0` | 38 / 0 | none |
| `check-siblings.sh` | `0` | 30 / 0 | the two lines revision 3 named: R61's `X0-detail` sha256, and `X26` at `owner-decisions.md:486` |
| `check-probe.sh`, `CARGO_TARGET_DIR` unset | `1` | 34 / 1 | the toolchain lines and `P0` FAIL, as at revision 3. New at revision 4: Cargo's `Downloading crates …` and `Downloaded …` progress lines, because the private `CARGO_HOME` was fresh and the script's log captures Cargo's stderr. Every measured figure is unchanged: `P7` 10, `P8` 13, `P9` 89, `P12` `1.85.0`, `P13` `1.88` |
| `check-probe.sh`, exported | `1` | 16 / 4 | `P0` and `P3`–`P5`, as at revision 3 |
| `check-probe-r2.sh`, unset | `0` | 23 / 0 | the toolchain lines |
| `check-probe-r2.sh`, exported | `1` | 5 / 7 | `Q3`–`Q9` (EA-2), as at revision 3 |
| `check-probe-r3.sh`, exported | `0` | 24 / 0 | none. The **first** exported run was the first Cargo invocation against the fresh private `CARGO_HOME`, and it exited `1` with `Q0 lockfile-is-current` FAIL (23 / 1). `Q0` counts lines containing `error` in the output of `cargo generate-lockfile --locked` and does not print them, so the cause was not captured. The unset run that followed and an exported rerun both passed `Q0`. It is recorded as a transient failure that did not reproduce |
| `check-probe-r3.sh`, unset | `0` | 24 / 0 | none |
| `check-parameters.sh` | `1` | 7 / 8 | the eight failures enumerated at revision 2: `PA6`, `PA8.1`–`PA8.5`, `PA10` and `PA11`. The files that trip `PA8` are now the three later `check-parameters-r*.sh` scripts, which name the patterns they search for |
| `check-parameters-r2.sh` | `1` | 18 / 4 | `PA6`, `PA10`, `PA10c`, `PA10c`, as corrected under EA3-1 |
| `check-parameters-r3.sh` | `1` | 43 / 1 | `PA6`, because the title now reads revision 4. This is the reason it is superseded |
| `check-r3-mutation.sh` | `1` | 2 / 3 | `M0` fails because its baseline runs `check-parameters-r3.sh`, which fails `PA6`; that extra `PA6` then also fails `M3` and `M4`. This is the reason it is superseded |

**Revision 5's checks, rerun on 2026-09-27.** Revision 5 adds two scripts and edits no
earlier script or log. The round-4 empirical audit reran every earlier check against
revision 4 and found every exit code, count and differing line as the revision-4 table
above records (`review/audit-claude.r4.md`, `verdict: approve`). Revision 5 moves no line
that any earlier check reads. The four checks that invoke no Cargo command —
`check-standard.sh`, `check-siblings.sh`, `check-registry.sh` and `check-r4-couplings.sh` —
were rerun on 2026-09-27 into scratch files under `$TMPDIR` and diffed against their
committed logs. All four exit `0` with 32, 30, 38 and 55 PASS and no FAIL. Besides
`date-utc:`, the only differing lines are the two `check-siblings.sh` lines revision 3
named (R61's `X0-detail` sha256, and `X26` at `owner-decisions.md:486`). The Cargo-building
checks were not rerun. The two checks below that pin this file's title were rerun.

- **`check-parameters-r5.sh`** is `check-parameters-r4.sh` with three changes. `PA6` and
  `PA6c` are re-pinned to revision 5. `PA17.1`–`PA17.6` pin the six revision-4 evidence
  files by sha256 (`check-parameters-r4.sh` and `.log`, `check-r4-mutation.sh` and `.log`,
  `check-r4-couplings.sh` and `.log`); those values were read before any revision-5 run.
  `PA18` asserts that `R56-r4-snapshot.md` hashes to `145ac5d7…`. The census pattern
  already excludes the new snapshot. `check-parameters-r5.log` reports 59 PASS lines with
  59 distinct IDs and `CHECK_FAILURES=0`. It is the live record for this revision, and it
  is regenerated after every edit to this file, because its line 3 carries this file's
  sha256.
- **`check-r5-couplings.sh`** asserts R54's status at source, continuing the `K` numbering
  of `check-r4-couplings.sh`. `K56` pins R54's `OWNER-ACCEPTANCES.md` row (revision 3,
  `1348f6b3…`, `accept`, 2026-09-18), as `K6` pins R55's. `K57` asserts that the same row
  adopts the project tier. `K58` asserts that the index lists R54 as `open`. `K59` asserts
  the project-tier row of R54's current working decision, located by content and reported
  at line 162. R54 is under revision, so that decision's title and sha256 are printed as
  `K59-detail` and not asserted.
- **No revision-5 mutation test was written.** `PA17` uses the same `pin` function whose
  detection of a one-byte edit `check-r4-mutation.log` already demonstrates (`PA15.4`).

| Check | Exit | PASS / FAIL | Result against revision 5 |
|---|---|---|---|
| `check-parameters-r4.sh` | `1` | 51 / 1 | `PA6`, because the title now reads revision 5. This is the reason it is superseded |
| `check-r4-mutation.sh` | `1` | 2 / 3 | `M0` fails because its baseline runs `check-parameters-r4.sh`, which fails `PA6`; that extra `PA6` then also fails `M3` and `M4`. This is the reason it is superseded |

**What was not run, and is therefore not claimed.** No keychain entry was stored or
retrieved on either operating system. No library/binary split of the warning carrier was
built: the probe is one crate. No `cargo audit` or `cargo deny` over a resolved
lockfile — advisory checking went through the RustSec package pages only. No benchmark: the
performance discussion is confined to package counts, dependency-graph shape and build
success, and no latency, throughput or binary-size number is asserted. No issue-responsiveness
figures were recomputed here; Opus's are monorepo-scoped and use "first comment by someone
other than the issue author" as a proxy for "first maintainer response", and they are not
relied on by any claim in this decision.

## Engines

- **Claude Opus 5** — `raw/opus.md`, sha256 `c02aebdd90cb21ca36ce7626b27fba7ca03f0250d6b8501c1546cc3a85d93bef` (asserted, `check-siblings.log` `X24`). Ten H3 fields, four members, a probe of its own under `$TMPDIR` on `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` / `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `aarch64-apple-darwin`, 2026-09-17. One of the two engines that read the org CLI Design Standard; Muse is the other.
- **Doxa** — `raw/doxa.md`, sha256 `a2d31b37e504b3a7146d421cf3abb649fc3ed00da5cd18ea48dafe674c9c24d6` (asserted, `X25`), operation `research-20260916-220330-c7921c22a58240c5`, with the normalized twin `raw/doxa.normalized.md` and three per-provider normalizations: `raw/doxa-openai.normalized.md`, `raw/doxa-perplexity.normalized.md`, `raw/doxa-gemini.normalized.md`. Each provider is treated as a separate voice below, because they disagree with Opus in the same direction but on different evidence and with different defects.
- **Codex — superseded by Muse.** No `raw/codex.md` exists (asserted, `X21`); `raw/codex-exit.txt` reads `1` and `raw/codex-transcript.txt` records the run refusing with a usage-limit message between `2026-09-17T04:40:00Z` and `2026-09-17T04:40:04Z` (asserted, `X22`, `X23`). The engine is **skipped by owner direction**: `docs/planning/p02/owner-decisions.md:486` records `W1-CODEX` — "the Codex CLI account hit its usage limit … with fourteen research legs and every empirical audit waiting on it", owner answer "Let's skip codex for now", 2026-09-16, with the consequence that "Opus legs, syntheses, judgment audits, Doxa and acceptance asks continue" while "no item publishes without its empirical audit" (asserted, `check-siblings.log` `X26`, which recorded the row at `:485` when committed; revision 3's rerun of the same assertion locates it at `:486`). Owner decision Q5.A (2026-09-21) then replaced every remaining Codex leg with a Muse leg — "Muse-bulk all 17 remaining legs" (`docs/planning/p02/execution-ledger.md`, asserted `check-r4-couplings.log` `K35`) — and `manifest.json` records this run's migration from `codex` to `muse` with the reason "muse bulk substitution (owner decision Q5.A 2026-09-21)" (`K34`). So the missing Codex report is a superseded leg, not a gap in the run, and publication of this item still waits on its own empirical audit. Revision 3 described Codex as absent and did not mention the Muse report; revision 4 corrects both. The disagreements below are settled by primary sources, not by counting engines.
- **Muse (Muse Spark)** — `raw/muse.md`, sha256 `80472db40500ffae62fb833ffaf7b12b0d16ef08c9c3c46b6b774a580ac01969`, byte-identical to the content-addressed copy `raw/muse-80472db4….md` (asserted, `K30`, `K31`); operation `agent:research-muse-2026-09-17T033528Z-785d25a9d608:80472db40500`, state `succeeded`, collected 2026-09-22 (`K32`); a required engine of this run (`K33`). Three bundle members — `token-source-policy`, `permission-check` and `warning-channel` — on `rustc 1.98.0`, macOS 26.4 arm64, with network evidence retrieved 2026-09-22. It read the org CLI Design Standard from a local copy, `R10.1` included (`raw/muse.md:56-63`, `K36`, `K37`). Its verdict: the config file never carries the token (`:290`), a **two-tier** chain `--token-file <path>` > env, a stray `token` key fatal as `RSLB204`, the `0o077` warning retargeted to the token file, and no crate shipped — `keyring` 4.2.0 and `secrecy` 0.10.3 surveyed and deferred with triggers.

**Disagreement 1 — may the layered config file carry the token? (the item's whole
question).** Opus and Muse: never (Muse: "config TOML never a token source",
`raw/muse.md:290`). All three Doxa providers: yes, as the lowest-precedence tier —
Gemini ("the three-tier approach gracefully handles all environments"), Perplexity
("rs-launch-blueprint should follow the TypeScript port's shape"), OpenAI ("the config
schema **does have an optional `token` field**"). **Settled for Opus and Muse, on a source the
three Doxa providers never saw.** The org CLI Design Standard is a private repository Doxa cannot reach;
`R10.1` **(MUST)** at `:545` names three tiers whose third is a *stored credential*, and its
SHOULD clause names the keychain or a `0600` file under `$XDG_STATE_HOME/<tool>/` as where
that credential lives — quoted verbatim and asserted at that line in
`check-standard.log` (`S4`–`S7`). Two further grounds, independent of the standard: R53's
accepted decision declares no `token` field and hands that very question to this item
(`X8`), so the majority position would require reopening an owner-accepted sibling; and the
industry precedents all three providers cite — Cargo's `credentials.toml`, Git's
`.git-credentials`, the AWS CLI's `~/.aws/credentials` — are each a **dedicated** credential
file, which is this decision's third tier, not a key in the tool's settings file. The
sharpest concession is OpenAI's: it enumerates "**Separate credentials file**" as an
architecture, calls it a "Strong long-term fit", and declines it only because it "creates a
new discovery/lifecycle concern outside R56/R54". The standard removes that objection by
naming the location itself, and R57 has already resolved it.

**Disagreement 2 — may the top tier be `--token <VALUE>`?** All three providers keep it;
Gemini's own validation strategy runs `./rs-launch-blueprint --token "flag"`. Opus proposes
`--token-file` and raises it as `BASELINE-REVIEW: F240`; Muse proposes the same top tier on
the same rule (`raw/muse.md:204`, `K38`). **Settled for Opus and Muse** by `R5.5`
**(MUST NOT)** at `:327`, asserted verbatim with both of its examples (`S12`, `S14`, `S15`).
This is the one place where the standard is *stricter* than the Rust ecosystem's own
practice — Cargo accepts `--token` — and that is stated in `## Decision` rather than
smoothed over.

**Disagreement 3 — which crates the item may add.** Gemini recommends `figment` as the
configuration aggregator and uses its `find_metadata("token")` provenance API to locate the
file to permission-check; Perplexity recommends `config` plus `dotenvy` plus `secrecy`;
OpenAI recommends **no new dependency at all**, on the ground that F246 already owns
secret-display masking. **Settled against Gemini and Perplexity on scope**, which is a
prompt constraint rather than a judgment: R54 owns discovery and merging and R53 owns
schema validation, and R53 is owner-accepted with `serde` and *no* validation crate, so
introducing `figment` or `config` from this item would overturn two siblings from outside
their scope. `dotenvy` is refused additionally on substance: it reintroduces the runtime
`.env` secrets tier that ts's D-017(5) deliberately omits. **Settled against OpenAI on a
distinction it did not draw**: F246 is a *display convention*, and a convention protects
only the call sites that remember it — which is exactly ts's `redactToken` free function
and its failure mode. `secrecy` makes `R5.6`'s open-ended masking requirement a property of
the type instead, verified here: `Debug` renders `SecretBox<str>([REDACTED])`, reaching the
bytes requires an explicit `expose_secret()`, and the crate carries `#![forbid(unsafe_code)]`
with no `[features]` table, so it cannot be serialized into a file by accident. OpenAI's
objection is nonetheless recorded, because it is the reason the recommendation adds two
small crates rather than none and P03 may reasonably revisit it.
Muse joins OpenAI in declining `secrecy` now. It defers `SecretString` as a documented
hardening path, because R56 "owns source policy, not in-memory representation" and the
token "has exactly one consumer" (`raw/muse.md:223-228`, `K47`). The same distinction
answers it. `R5.6`'s masking list is an open set of display paths, not a count of
consumers, and a second path — `config view --show-origin`, a `--debug` request log —
arrives with the first diagnostic P03 adds. With two engines against the crate, the
confidence row below drops from Medium-high to **Medium**. Muse also names `keyring` 4.2.0
as its deferred keychain crate, where this decision names `keyring-core` 1.0.0 plus two
store crates. That is not a design disagreement. The keyring-rs maintainer's README at
`v4.2.0` tells applications to "take dependencies on the keyring-core crate and the
specific credential stores they want to use" (quoted by Opus, `raw/opus.md:697-700`), and
both engines keep the keychain out of the default build: Muse by deferring it, this
decision by a non-default feature.

**Disagreement 4 — the quality of the evidence behind the majority.** This is not a
tie-breaker but it bears on how much weight the majority carries. Gemini's crate figures are
**not measured**: its `secrecy` row states the newest release is `0.8.0` and all-time
downloads are `24,105,992`, where the registry snapshot gives `0.10.3`, released
2024-10-09, with `162,048,552` (both asserted, `check-registry.log`); its `figment`
90-day figure is labelled "calculated extrapolation from total" and its star count
"approximate via engagement". Perplexity states outright that "numeric metrics are
inapplicable" because it operated "without direct queries to crates.io" — but its members
are real crates.io crates, so the required figures were not inapplicable, they were
un-fetched. Gemini was nevertheless **right on one point where Opus was vaguer**: it states
that `secrecy` uses `#![forbid(unsafe_code)]`, and reading the published 0.10.3 source
confirms it, whereas Opus described the crate only as "a thin wrapper" over `zeroize`'s
deliberate `unsafe`. That correction is carried into `## Empirical check`. Two further
corrections to Opus's own figures, from this synthesizer's measurements: the tightest
declared floor in the default tree is the literal string `1.85.0` and it belongs to
`hashbrown` **0.17.1** — Opus wrote "`hashbrown 1.85.0`", conflating the crate version with
the `rust_version` string; and the committed lockfile holds **106** `[[package]]` entries,
because Cargo's "Locking 105 packages" excludes the root package.

**Disagreement 5 — what happens to a `token` key found in a config layer.** Opus: dropped
with one warning. py: silently ignored. Muse: fatal, `RSLB204` at exit `2`, with a hint
naming `--token-file` and the env var (`raw/muse.md:292`, `K41`). No Doxa provider addresses
it, because under their recommendation the key is valid. **Settled for Opus, on a published
source.** R55 revision 3 is published (`K2`–`K9`) and states "Unknown keys warn and never
fail, in every layer" (`:173`, `K10`). R53's schema declares no `token` field (`X8`), so a
`token` key is an unknown key under R55's own classification. Making it fatal would make it
the one unknown key that fails, which reopens a published sibling from outside its scope,
and it would give `RSLB204` a second instance beside `config set token <value>`. Muse's
strongest point is recorded rather than dismissed: a fatal error forces the user to remove
the secret from a file that may be shared, where a warning only asks. The warning keeps the
file repairable, which is R55's first principle, and it is not silent, which is what
`R5.8` forbids. The exposure it reports happened when the secret was written into the file,
not when the tool reads it. No external authority prescribes warn-versus-fail here, and
none is claimed. R55 being revised remains a re-verify trigger.

**Disagreement 6 — must the stored-credential tier exist now? (Muse against Opus and the
three Doxa providers.)** Muse read `R10.1` and recommends two tiers, `--token-file` > env,
saying the design "Satisfies every MUST" (`raw/muse.md:204-206`, `K38`, `K39`). Every other
engine has a third tier: Opus a dedicated store, the Doxa providers the config file. The
text must answer one question: does `R10.1`'s MUST fix only the *order* of whichever tiers
exist, or does it also require the stored tier to exist? The rule, quoted in full under
`## Empirical check`, opens "Authentication lives under an `auth` group: `acme auth login`,
`acme auth logout`, `acme auth status`", and its SHOULD sentence begins "Stored credentials
**SHOULD** use the OS keychain". Both presuppose a stored credential: `auth login` exists to
create one, and a two-tier design leaves it nothing to write. **Settled for three tiers,
with the limit stated:** the MUST's own words are an ordering, and the existence reading
rests on the rule read as a whole, not on that one clause. Muse's position is closer to this
decision than its tier count suggests. It calls a dedicated credentials file "the natural
form of the deferred stored tier" and rejects it only because neither source has an
`auth login`/`logout` surface (`raw/muse.md:209-213`, `K40`). It defers the keychain tier
until it can "adopt with an `auth login` surface" (`:303-304`, `K45`, `K46`). That ground is
the ownership gap recorded under `## Parameters`, not a defect of the three-tier design. If
the owner rules that the template ships no `auth` group, Muse's chain — alternative A with
this decision's `R5.5` fix to the top tier — competes with alternative E. Muse would rank it
first under that ruling. This decision's ranking of E is unchanged, and it is the owner's to
overturn if that ruling comes.

**Disagreement 7 — what carries the loose-permission warning, and when? (The first half of
the prompt's MEDIUM question.)** Opus answered only the cardinality. OpenAI answered the
mechanism: "The warning is buffered as a typed diagnostic and emitted once by the
application's R58/R59 logging/diagnostic adapter" (`raw/doxa-openai.normalized.md:88`,
`K24`); "R56 should return typed warnings from the library" (`:256`, `K25`); "typed,
non-fatal, once per physical file per config load" (`:323`, `K26`). It ranks a direct
`tracing::warn!` in the loader lower (`:521`, `K27`) and accepts it "only if R58/R59
guarantees a subscriber exists" before loading (`:545`, `K28`). Muse's `warning-channel`
member gives the same answer. The library "prints nothing (R67 layering)"; a
`Config.warnings: Vec<String>` is "populated once at load, plus an optional" injected
`warn` seam; and the binary renders each warning once (`raw/muse.md:301`, `:649`, `:697`;
`K44`, `K48`, `K50`). Muse rejects `eprintln!` from the library as a violation of R67's
layering (`:672`, `K49`). **Settled with OpenAI and Muse; item 5 now states it.** The ground
is R67's Layering clause, the same ground on which published R55 settled its own
Disagreement 4. A `tracing::warn!` inside the library is rejected on that clause whether or
not a subscriber exists. Two details differ from the engines, each for a stated reason.
First, the moment: both engines say "at config load", because OpenAI's token lives in the
config and Muse's token file is read with it. Here the stored credential is read at
credential resolution, which is still once per process. Second, the type: Muse's field is a
`Vec<String>`, while OpenAI's is a typed diagnostic, which this decision matches so that the
binary and R58 can route the warning without parsing text. Muse's optional callback seam is
left to P03. The engines' `assumes R58/R59 …` lines (`:557`, `K29`) are not carried as
parameters, because this item does not consume R58's `logging-pipeline-contract` (`K23`).
The dependency is instead the coupling hand-off stated under `## Decision`.

**Disagreement 8 — which code an unreadable `--token-file` raises.** Muse: `RSLB104`,
citing `R8.2`'s "unreadable files" (`raw/muse.md:241`, `:293`; `K42`, `K43`). This decision:
`RSLB101`. The exit code is `1` either way, and that is all `R8.2` fixes: it says to "use
exit `1` for runtime input failures such as unreadable files" (standard blob `:461`,
asserted `K51`) and names no catalog code. The catalog code is R67's, and R67's rows read
"`RSLB101` I/O → 1" and "`RSLB104` config layer unreadable → 1" (the
`error-taxonomy-exit-codes` value under `## Parameters`; `K52`, `K53`). A token file is
deliberately not a config layer (item 3), so this is **settled for `RSLB101`**. The
difference is visible only in the envelope's `code` string.

**Confidence, split by claim, because the parts are not equally supported.**

| Claim | Confidence | Ground |
|---|---|---|
| The layered config file must not be a token source | **High** | `R5.5`/`R10.1` read and asserted at the pinned blob; py's ADR-0002; Cargo's and AWS's file splits; the composition with R54's owner-accepted project tier (`K56`, `K57`); R17's `--only-verified` limit |
| The chain is three tiers, flag-file > env > stored | **High** for the order; **Medium-high** for the stored tier's existence | `R10.1` **(MUST)** at `:545`, quoted verbatim and asserted at that line; the existence reading rests on the whole rule and is contested by Muse's two-tier reading (Disagreement 6) |
| The third tier is a dedicated `0600` store under `state_dir()` | **High** | `R10.1`'s own words plus R57's owner-accepted `Paths::state_dir()` |
| The permission check is `std::os::unix::fs::PermissionsExt`, warns non-fatally, and tests the `0o077` mask rather than equality with `0600` | **High** | executed, `A1`–`A5` |
| `secrecy` + `zeroize` are the right carriage | **Medium** | executed (`D1`, `D2`, leak census `0`) and the source read; tempered by `secrecy`'s 23-month release gap, and by OpenAI and Muse both declining a new crate (Disagreement 3) |
| The keychain tier belongs behind a non-default feature | **Medium-high** | executed dependency measurements (10 → 89 packages, a second async runtime, MSRV 1.85.0 → 1.88); the CI-daemon claim beneath it is **inferred, not executed** |
| The top tier should be `--token-file` | **High** as a standards reading, **Medium** as a programme decision | `R5.5` is explicit and clig.dev (`https://clig.dev/`, retrieved 2026-09-17) agrees, but it changes a shape both source repositories document as remedy 1, so it is raised as `BASELINE-REVIEW: F240` for the owner rather than asserted |
| A `token` key in a layer warns rather than failing | **Medium** | R55's published disposition (revision 3, published 2026-09-23; `K2`–`K10`); contested by Muse, which makes the key fatal (Disagreement 5); no external authority prescribes it |
| The permission warning is returned as typed data by the library and rendered once to stderr by the binary | **Medium-high** | R67's Layering clause; published R55's identical carrier; OpenAI and Muse agree (Disagreement 7); the library/binary split itself is proposed, not executed (criterion 10) |
| `config set token <value>` is `RSLB204`/2 | **Medium** | a reading of R67's own row text plus `R5.5`; R67 defined the code prospectively and named no instance |

**Unproven, with what would prove it — left for P03 to prove in the real template.**

1. **The keychain tier was never exercised on either operating system.** No entry was
   stored or retrieved. The claim that it cannot be exercised on `ubuntu-latest` is an
   inference from the resolved dependency set plus the Secret Service architecture: the
   Linux store speaks D-Bus to a secret-service daemon, and a GitHub-hosted Linux runner
   has neither a session bus nor such a daemon. **Proof:** a job on `macos-latest` that
   creates and deletes an entry in a throwaway keychain, and one on `ubuntu-latest` that
   does the same under `dbus-run-session` with a headless `gnome-keyring-daemon` — or a
   documented skip. This is the item's largest open risk, and if it resolves against the
   feature, the honest outcome is a `R10.1` SHOULD waiver naming the rule ID, the
   deviation, the rationale and the owner and date, per the conformance clause at `:50` —
   a legitimate conformant path, not a failure.
2. **The `RSLB401`-versus-`RSLB101` split for `--token-file`** is proposed, not executed:
   the probe carries the fall-through it replaces, as a labelled negative control.
3. **`config set token <value>` → `RSLB204`/2** is this decision's reading, not an executed
   behaviour, and it is the only instance the code has.
4. **The masked-input path for an interactive `auth login`** is owned by no decision: R61
   selects no password prompt shape.
5. **The `auth` command group itself** has no owning item, though `R10.1` **(MUST)**
   requires it.
6. **No `cargo audit`/`cargo deny` run** over a resolved lockfile; advisories were checked
   through RustSec package pages and their positive control only.
7. **The warning carrier's library/binary split** is proposed, not executed: the probe
   returns the finding as data but is one crate. **Proof:** acceptance criterion 10 in the
   real template's workspace, with the library's streams captured.
