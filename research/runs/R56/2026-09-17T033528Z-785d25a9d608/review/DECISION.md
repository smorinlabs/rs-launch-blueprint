# 2026-09-17 — R56 — config-secret-policy (bundle, Deep) — decision (revision 1)

## Decision

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

> The layered configuration file — `rslbp_config.toml`, at every discovery tier R54 lands
> on — is **never** a token source, which is what py's ADR-0002 rules. The precedence
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
   document is still accepted, and the token is not used. **executed** (`B1`–`B4`).
2. A credential file at `0600` produces no warning; the same file at `0644` produces one;
   at `0700` it produces none, proving the test is the `0o077` mask and not equality with
   `0600`. **executed** (`A2`, `A3`, `A5`).
3. The credential file is created at mode `0600` by `O_CREAT`, never created and then
   `chmod`-ed. **executed** (`A1`).
4. `--token-file` outranks a set `RSLBP_TOKEN`, which outranks the stored credential; an
   empty-string env value is treated as unset (F242 parity). **executed** (`C1`, `C3`).
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
| **E. B confined to the user tier, refused in any project tier** | Keeps ts's ergonomics while closing the in-repository leak | **Ranked runner-up for the policy.** It wins only if the owner rules that a template must not ship an `auth` command. Its cost is exactly the risk py's ADR names, and it worsens the moment R54 adopts `R5.2`'s project tier |

**Why B's composition risk is not hypothetical.** ts's file tier is user-tier only, so its
token is never discovered from inside a repository. py *does* have a project tier, and the
standard's `R5.2` **(SHOULD)** puts a project tier at `.<tool>/<tool>_config.toml` in the
current directory *and each parent*. If R54 adopts a project tier — which the standard
recommends and py already does — then B makes the token readable from, and writable into,
a file that lives in the user's git working tree. That leak is created by *composition*,
not by either item alone, which is why this decision does not leave it to R54.

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
   never fail, in every layer" (asserted, `X9`) — borrowed rather than invented.
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
5. **P4 — the loose-permission check survives, retargeted.** `mode & 0o077 != 0` is
   checked on the credential file and on any `--token-file` target, and produces one
   non-fatal warning naming the path and `chmod 600`, never the value. It is emitted
   **once, at credential resolution** — there is one resolution per process — not on every
   token read. F245's mechanism is kept; only its subject moves.
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
  owner-accepted at revision 9 and published — its `GlobalArgs` surface carries
  `--token-file`, not `--token`; the string `--token` occurs **0** times in R60's, R67's
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
deliberately **outside** R54's discovery, having exactly one location and no tiers. R60
(owner-accepted at revision 9, `clap` 4.6.6 derive): `--token-file` is R60's surface to
carry, and it takes **no** `#[arg(env = …)]` binding — `R5.4` (`:322`) curates the env
surface around auth/token, host, output format, config path and telemetry opt-out, not a
token *path* — so the env tier is read by the resolver itself and `RSLBP_TOKEN` stays the
env tier per F241. R61 (owner-accepted): a stdin token read must respect R61's
interactivity gate at the call site (`std::io::IsTerminal`, asserted `X15`); R61 selects
`Confirm`, `Text`/`CustomType`, `Select` and `MultiSelect` and **no masked password
shape** (asserted `X14`), so the hidden-input path an interactive `auth login` wants is
covered by no decision yet — a gap, not a collision. R55 (in flight; revision 3 at the time
of writing, up from the revision 2 named in this synthesizer's brief): the `token`-key
warning is R55's unknown-key disposition, so if R55 moves, this clause moves with it — a
re-verify trigger, recorded below. R53 (owner-accepted): no `token` field is added to its
schema. R52 (published): the probe parses the config fixture with R52's `toml` 1.1.6, so
the drop-the-key assertion ran against the accepted parser. R17 (published): unaffected by
this item, and explicitly not a backstop for it. R67 (owner-accepted): consumed unchanged.

re-verify: 2026-12-17, or earlier on any of — the owner reopening `R10.1`, which Decision Log row 26 marks `derived` rather than `org-locked` and is the one standard dependency here that can move without an org change; R54 publishing and either adopting or declining `R5.2`'s project tier, on which the composition risk above is conditional; R55 publishing with an unknown-key disposition other than warn-and-continue, which moves the `token`-key clause; R53 publishing a schema that carries a `token` field; R05 selecting an async runtime, which changes the cost of the Linux `keychain` tree; R61 publishing a masked-input prompt shape, which supplies the interactive `auth login` path; `secrecy` publishing 0.11, or 2027-09-17 passing with in-tree commits and no release; `keyring-core` publishing 1.1 or 2.0, or `oo7` reaching a stable release with a declared MSRV at or under the then-current floor; GitHub-hosted `ubuntu-latest` images gaining a session bus and a Secret Service daemon, which would make the keychain tier testable; any RustSec or OSV advisory against `secrecy`, `zeroize`, `keyring-core`, either platform store crate, `zbus` or `secret-service`; or current stable Rust rising such that the stable-minus-2 floor passes `1.88`, the `keychain` tree's binding MSRV.

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
synthesizer's, built and run here, not that one's output copied forward.

**Nothing was built that this decision recommends.** No seam, service, hook pipeline,
acceptance script or template scaffold exists. What ran is a throwaway Cargo package under
a `$TMPDIR` subdirectory created for the run and deleted after it, whose sources are
committed as a fixture at `review/evidence/probe/` (`Cargo.toml`, `Cargo.lock`,
`src/main.rs`) so the numbers are reproducible. The probe is a measuring instrument: it
implements the *naive* resolver so the fall-through the decision forbids is visible as a
labelled negative control, and it does not implement the recommendation.

**The five checks, their commands and their results.** Each script asserts on content,
never on an exit status alone; each starts with `set -o pipefail`; each names
`/usr/bin/grep` by absolute path beside every count it reports, because a typed `grep` in
these shells is `ugrep` and honours `.gitignore`; and all five are `shellcheck` 0.11.0
clean (two carry a file-scoped `SC2016` waiver with its reason, because their assertion
needles are the standard's and the siblings' own backtick-bearing text quoted verbatim).
Every one was run from the repository root with `./review/evidence/<name>.sh`, and its
complete output is the committed log beside it.

| Script | What it decides | PASS assertions | Result | Log |
|---|---|---|---|---|
| `review/evidence/check-standard.sh` | that the standard really says what this decision rests on, at the blob and line numbers cited; that both sources violate `R5.5` at their pins; that no CI standard document exists | 32, plus 3 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-standard.log` |
| `review/evidence/check-siblings.sh` | every claim this decision makes about R67, R60, R53, R55, R57, R61, R52 and R17, and about this run's own engine inventory | 29, plus 10 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-siblings.log` |
| `review/evidence/check-registry.sh` | the crate versions, release dates, MSRV floors, licences, download figures, the `secrecy`→`zeroize` edge, the `forbid(unsafe_code)` posture and the advisory status, read from committed snapshots | 38, plus 3 detail lines | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-registry.log` |
| `review/evidence/check-probe.sh` | the behavioural claims, the dependency-tree sizes and the tree MSRV maxima, by building and running the probe | 35 (15 from the probe, 20 from the script), plus 1 detail line | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-probe.log` |
| `review/evidence/check-parameters.sh` | that `## Parameters` carries no `- owns` line and that its five `- assumes` values `diff` empty against lines regenerated from the current `docs/port/PARAMETERS.md`; the H2 set, the title, the single `re-verify:` line; and that no personal email, credential pattern or probe fixture reaches any log | 15 | **all PASS**, `CHECK_FAILURES=0`, exit `0` | `check-parameters.log` |

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
broken fetch. Repository state, via the authenticated `gh` binary with `--jq` (no token, no
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

**Reproducibility, stated exactly rather than claimed generally.** Every script was rerun
after its log was written and the rerun was diffed against the committed log. Each is
byte-reproducible **except for its own `date-utc:` stamp**, which the script prints itself
at the top of its output; `check-parameters.log` additionally carries the decision's own
sha256, which changes whenever the decision is edited and is therefore regenerated last.
No other line differs in any of the five. The volatile sources — crates.io counters, GitHub repository fields, RustSec pages
— are *not* re-fetched by any check: they live in `review/evidence/snapshots/` with their
endpoints and retrieval timestamps, and `refresh-snapshots.sh` is the only thing that
touches the network. That is the rule for comparing across the variance: **diff the logs
ignoring the leading `date-utc:` line**, and refresh the snapshots deliberately, never as a
side effect of a check.

**What was not run, and is therefore not claimed.** No keychain entry was stored or
retrieved on either operating system. No `cargo audit` or `cargo deny` over a resolved
lockfile — advisory checking went through the RustSec package pages only. No benchmark: the
performance discussion is confined to package counts, dependency-graph shape and build
success, and no latency, throughput or binary-size number is asserted. No issue-responsiveness
figures were recomputed here; Opus's are monorepo-scoped and use "first comment by someone
other than the issue author" as a proxy for "first maintainer response", and they are not
relied on by any claim in this decision.

## Engines

- **Claude Opus 5** — `raw/opus.md`, sha256 `c02aebdd90cb21ca36ce7626b27fba7ca03f0250d6b8501c1546cc3a85d93bef` (asserted, `check-siblings.log` `X24`). Ten H3 fields, four members, a probe of its own under `$TMPDIR` on `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` / `cargo 1.98.0 (797e8a9bc 2026-08-05)`, `aarch64-apple-darwin`, 2026-09-17. The only engine that read the org CLI Design Standard.
- **Doxa** — `raw/doxa.md`, sha256 `a2d31b37e504b3a7146d421cf3abb649fc3ed00da5cd18ea48dafe674c9c24d6` (asserted, `X25`), operation `research-20260916-220330-c7921c22a58240c5`, with the normalized twin `raw/doxa.normalized.md` and three per-provider normalizations: `raw/doxa-openai.normalized.md`, `raw/doxa-perplexity.normalized.md`, `raw/doxa-gemini.normalized.md`. Each provider is treated as a separate voice below, because they disagree with Opus in the same direction but on different evidence and with different defects.
- **Codex — absent.** No `raw/codex.md` exists (asserted, `X21`); `raw/codex-exit.txt` reads `1` and `raw/codex-transcript.txt` records the run refusing with a usage-limit message between `2026-09-17T04:40:00Z` and `2026-09-17T04:40:04Z` (asserted, `X22`, `X23`). The engine is **skipped by owner direction** — `docs/planning/p02/owner-decisions.md` section 12, `W1-CODEX` — so this is a recorded absence under a standing ruling, not a gap in the run. The practical cost is that the independent second model family, which this programme uses as the adversarial lens, did not read this item: the disagreements below are settled by primary sources rather than by a third opinion.

**Disagreement 1 — may the layered config file carry the token? (the item's whole
question).** Opus: never. All three Doxa providers: yes, as the lowest-precedence tier —
Gemini ("the three-tier approach gracefully handles all environments"), Perplexity
("rs-launch-blueprint should follow the TypeScript port's shape"), OpenAI ("the config
schema **does have an optional `token` field**"). **Settled for Opus, on a source the other
three never saw.** The org CLI Design Standard is a private repository Doxa cannot reach;
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
`--token-file` and raises it as `BASELINE-REVIEW: F240`. **Settled for Opus** by `R5.5`
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
with one warning. py: silently ignored. No provider addresses it, because under their
recommendation the key is valid. Settled for Opus, but on an **in-flight** source: R55's
unknown-key disposition, which is at revision 3 and under judgment, not published
(`X9`, `X10`). This decision therefore inherits R55's risk, and R55 moving is a re-verify
trigger. No external authority prescribes warn-versus-fail here, and none is claimed.

**Confidence, split by claim, because the parts are not equally supported.**

| Claim | Confidence | Ground |
|---|---|---|
| The layered config file must not be a token source | **High** | `R5.5`/`R10.1` read and asserted at the pinned blob; py's ADR-0002; Cargo's and AWS's file splits; the R54 project-tier composition risk; R17's `--only-verified` limit |
| The chain is three tiers, flag-file > env > stored | **High** | `R10.1` **(MUST)** at `:545`, quoted verbatim and asserted at that line |
| The third tier is a dedicated `0600` store under `state_dir()` | **High** | `R10.1`'s own words plus R57's owner-accepted `Paths::state_dir()` |
| The permission check is `std::os::unix::fs::PermissionsExt`, warns non-fatally, and tests the `0o077` mask rather than equality with `0600` | **High** | executed, `A1`–`A5` |
| `secrecy` + `zeroize` are the right carriage | **Medium-high** | executed (`D1`, `D2`, leak census `0`) and the source read; tempered by `secrecy`'s 23-month release gap |
| The keychain tier belongs behind a non-default feature | **Medium-high** | executed dependency measurements (10 → 89 packages, a second async runtime, MSRV 1.85.0 → 1.88); the CI-daemon claim beneath it is **inferred, not executed** |
| The top tier should be `--token-file` | **High** as a standards reading, **Medium** as a programme decision | `R5.5` is explicit and clig.dev (`https://clig.dev/`, retrieved 2026-09-17) agrees, but it changes a shape both source repositories document as remedy 1, so it is raised as `BASELINE-REVIEW: F240` for the owner rather than asserted |
| A `token` key in a layer warns rather than failing | **Medium** | reasoned from R55's in-flight disposition; no external authority prescribes it |
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
