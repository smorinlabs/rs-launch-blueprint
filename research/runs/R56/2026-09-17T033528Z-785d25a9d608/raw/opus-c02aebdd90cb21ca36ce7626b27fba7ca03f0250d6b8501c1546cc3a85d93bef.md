# R56 — config secret policy (bundle, Deep) — Opus raw report

Engine identity `research-opus-2026-09-17T033528Z-785d25a9d608`, model `claude-opus-5`.
All retrieval dates in this report are **2026-09-17 (UTC)** unless a line says otherwise;
the session's local date is 2026-09-16, and `date -u` at the start of the run read
`2026-09-17T06:07:22Z`. Both source repositories were read only through the programme
pins — `git -C ~/c/py-launch-blueprint show b08bccfb:<path>` and
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` — never from a working tree.
The org CLI Design Standard was read at the blob the task names:
`git -C ~/c/cli-standards cat-file -p f9de0437baece3383e73ca2c5f48b7ab399b51c7`
(`git cat-file -t` reports `blob`; `git show <commit>:cli-design-standard.md` fails
because that hash is the file's blob, not a commit). Line numbers below are lines of
that blob's 773-line text.

Licence gate: `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Nothing is excluded on
licence anywhere in this report; licence strings are recorded as observed facts only.

### Landscape

**The category this item decides.** Not "which crate", but *credential-source policy for a
CLI that authenticates to a remote API*: which channels may deliver a secret, in what
precedence order, what the tool does when a secret arrives through a channel it does not
honour, and what it checks about a file that holds one. The crates in the stack are
consequences of that policy, not the policy itself. This framing matters because the
prompt poses the question as a binary — py's ADR-0002 rule versus ts's shape — and the
authorities surveyed below answer a *third* way that neither repository implements.

**The three-bin map of the Rust field.**

| Bin | Candidates found | What each would supply |
|---|---|---|
| **Built-in / first-party toolchain** | `std::os::unix::fs::PermissionsExt` + `OpenOptionsExt` + `MetadataExt`; `std::fs`; and — as a *pattern*, not a library — **Cargo's own credential-provider architecture** (`$CARGO_HOME/credentials.toml` separate from `config.toml`, `cargo:token` / `cargo:macos-keychain` / `cargo:libsecret` / `cargo:wincred` / `cargo:token-from-stdout`) | POSIX mode inspection and 0600-at-`O_CREAT` creation; the reference *shape* for "dedicated credential file, keychain provider preferred" |
| **Established industry standard** | `secrecy` 0.10.3, `zeroize` 1.9.0, `keyring` 4.2.0, `keyring-core` 1.0.0 + platform store crates (`apple-native-keyring-store` 1.0.2, `zbus-secret-service-keyring-store` 1.0.1, `dbus-secret-service-keyring-store`, `linux-keyutils-keyring-store`, `windows-native-keyring-store`), `nix` 0.31.3, `rustix` 1.1.5 | in-memory secret carrier with redacting `Debug`; memory zeroing; OS keychain access; libc-level `stat` alternatives to `std` |
| **Up-and-comer** | `oo7` 0.7.0-alpha (Secret Service / XDG portal client, Linux-only), `cap-std` 3.4.6 (capability-based filesystem), the `keyring-core` **1.0 ecosystem split itself** (the API moved out of `keyring` into `keyring-core` with stores as separate crates, `keyring-core` 1.0.0 released 2026-04-21) | a Linux-native alternative to the `secret-service` stack; a sandboxed-`fs` alternative for the permission check; a way to take exactly the stores you need |

Every shortlisted candidate below comes from that map. Figures: `crates.io`
`GET https://crates.io/api/v1/crates/<name>` and `/versions`, `api.github.com`
`GET /repos/<o>/<r>` and `/search/issues`, all retrieved 2026-09-17; per-member rows carry them.

**Authoritative sources used, and why each counts as authority.**

| # | Source | Why authoritative | What it settles here |
|---|---|---|---|
| S1 | **Org CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` | The owner's own normative standard; `rs-launch-blueprint` is a CLI it governs, and ts's D-016(2) already defers to it | `R5.5` (secrets never in argv), `R5.6` (masking), `R5.4` (curated `TOOL_*` env), `R10.1` (the three-tier credential chain and where the stored credential lives), `R6.1` (auth failure exits `4`) |
| S2 | **The Cargo Book**, `reference/config.html` and `reference/registry-authentication.html` (`https://doc.rust-lang.org/cargo/`) | First-party Rust toolchain documentation; Cargo is the CLI every Rust developer authenticates with | That Rust's own tooling puts the token in a **separate `credentials.toml`**, never in `config.toml`, and treats the plain-text file as the *fallback* beneath OS keychain providers |
| S3 | **clig.dev — Command Line Interface Guidelines** (`https://clig.dev/`) | The most widely cited independent, language-agnostic CLI style guide | "Do not read secrets directly from flags"; "Do not read secrets from environment variables"; "Secrets should only be accepted via credential files, pipes, AF_UNIX sockets, secret management services, or another IPC mechanism" |
| S4 | **py `docs/adr/0002-no-secrets-in-config-file.md`** at pin `b08bccfb` | The recorded decision this item is asked to weigh, in the owner's own repository | The security argument: "config files get copied, committed, backed up, and shared in ways secret stores are not, and a 'convenient' token-in-file path normalizes leaking" |
| S5 | **`conda/rattler`, crate `rattler_networking`** (`https://github.com/conda/rattler`) | A widely adopted Rust networking/auth layer (it is what `pixi` authenticates with); `rattler_networking` 0.30.8 appears in `keyring-core`'s reverse-dependency listing on crates.io | A maintained Rust reference implementation of exactly the recommended architecture: pluggable `StorageBackend`s named `file.rs`, `keyring.rs`, `memory.rs`, `netrc.rs` |
| S6 | **AWS CLI user guide**, `cli-configure-files.html`; **GitHub CLI manual**, `gh_help_environment` | Two of the most-used CLIs in the industry; cited as *practice*, not as normative rules | AWS: "The AWS CLI stores sensitive credential information that you specify with `aws configure` in a local file named `credentials`, in a folder named `.aws`" — a dedicated file, separate from `config`. gh: `GH_TOKEN`, `GITHUB_TOKEN` "(in order of precedence)" are consulted, and "Otherwise … the stored credentials will be used" — env above stored credential, matching `R10.1` |

A single blog post was treated as a lead and none is cited as authority. `rustsec.org`
is used only as an advisory oracle, not as style guidance: it publishes no rule about
credential sources, which is the honest answer to the prompt's LOW question (see
`### Principles and implementation`).

**Well-regarded projects surveyed, with the evidence that they are well regarded.**

| Project | Evidence of regard (retrieved 2026-09-17) | What it does about a token |
|---|---|---|
| `rust-lang/cargo` | First-party Rust toolchain; ships with every Rust install | `$CARGO_HOME/credentials.toml`, created and updated by `cargo login`/`cargo logout`; `registry.token` "should only appear in the credentials file"; recommended `global-credential-providers = ["cargo:token", "cargo:libsecret", "cargo:macos-keychain", "cargo:wincred"]`, later entries winning, i.e. **keychain above plain-text file** |
| `conda/rattler` (`rattler_networking` 0.30.8) | Appears in `GET https://crates.io/api/v1/crates/keyring-core/reverse_dependencies` (114 reverse dependents total); the crate is the auth layer of the `pixi` toolchain | `authentication_storage/backends/{file,keyring,memory,netrc}.rs`; the file backend defaults to `home_dir.join(".rattler").join("credentials.json")` — a **dedicated credentials file**, not the tool's config; the keyring backend is `keyring_core::{Entry, api::CredentialStore}` with `#[cfg(target_os = …)]` store selection |
| `kube-rs` (`kube-client` 4.2.0) | Listed in `secrecy`'s reverse-dependency page; the de-facto Kubernetes client for Rust | consumes `secrecy` for in-memory credential carriage |
| `age` / `rage` (`age-core` 0.12.2) | Listed in `secrecy`'s reverse-dependency page; `age` is a widely deployed file-encryption format | consumes `secrecy` |
| RustCrypto (`rsa`, `elliptic-curve`, `ecdsa`, `curve25519-dalek`, …) | The Rust cryptography ecosystem; `zeroize` has 4,333 reverse dependents | consumes `zeroize` universally |
| `py-launch-blueprint` @ `b08bccfb`, `ts-launch-blueprint` @ `cb1cbcb2` | The programme's own sources | py: two tiers, `--token` then `$PLBP_TOKEN`, `token` key silently ignored. ts: three tiers, `--token` > `TS_PROJECTS_TOKEN` > user-tier config file, plus a `mode & 0o077` warning |

**Two counterexamples, stated rather than hidden.** *First*, GitHub's `gh` stores its OAuth
token inside its own configuration directory, so "never a config file" is not universal
industry practice. *Second, and sharper because it is first-party*: **Cargo itself accepts a
token as a plain flag value.** Its own configuration reference says, of `registry.token` and
`registries.<name>.token`, "Can be overridden with the `--token` command-line option"
(`https://doc.rust-lang.org/cargo/reference/config.html`, retrieved 2026-09-17) — the exact
shape `R5.5` **(MUST NOT)** forbids and that `BASELINE-REVIEW: F240` below asks py and ts to
drop, present in the Rust toolchain's flagship CLI. The honest reading is that `R5.5` is a
*stricter* rule than the ecosystem's own practice rather than a description of it; the
owner's standard binds this template regardless, and it is Cargo's file *placement* (a
dedicated `credentials.toml`) rather than its flag surface that this report follows. What is universal in the sample is narrower and is the load-bearing claim: the
credential lives in a **file whose only job is credentials**, written by an auth command, and
it is never a key in the layered, user-edited, project-discoverable settings file. Cargo,
AWS and rattler all draw that line; ts does not.

### Principles and implementation

**The shared requirement.** *A credential must reach the tool through a channel that does not
publish it to bystanders, and the user must be able to tell which channel supplied it.*
Sources and agreement levels, which are not all the same and must not be conflated:

| # | Principle | Source | Agreement level | Must agree across py / ts / rs | May vary |
|---|---|---|---|---|---|
| P1 | A secret is never carried in `argv` | `R5.5` **(MUST)**, `:327-329` (heading `:326`); clig.dev "Do not read secrets directly from flags" | **standard** | that the top tier names a *file* or reads stdin, never a value | the flag's spelling |
| P2 | Credentials resolve through one documented precedence chain | `R10.1` **(MUST)**, `:545` | **standard, one ordering for all three repos** | flag-supplied token-*file* > `TOOL_TOKEN` env > stored credential | how each runtime reads a file |
| P3 | The general-purpose config file is not a credential store | py ADR-0002; Cargo's `credentials.toml` split; AWS's `credentials` split | **policy** | that the layered settings file carries no secret | where the dedicated credential store lives per OS |
| P4 | A stored credential is protected at rest | `R10.1` **(SHOULD)** "OS keychain when available, falling back to a `0600` file under `$XDG_STATE_HOME/acme/`" | **capability** | that a stored credential is owner-only or OS-protected | keychain vs file; which keychain |
| P5 | A secret is masked wherever it is displayed | `R5.6` **(MUST)**, `:332-333` (heading `:331`); ledger F246 `COMMON → REUSE` | **standard** | that every display path masks | the mask's shape (ts: `***` + last 4) |
| P6 | Failure to authenticate has a conventional status | `R6.1`, carried by R67 (`RSLB401`/`RSLB402` → exit `4`) | **standard** | exit `4` | the code string |

**Provenance of `R10.1`, stated precisely rather than leaned on.** `R10.1` is **derived**,
not org-locked: the standard's Decision Log row 26 (`:88`) reads
`| 26 | Authentication | auth login/logout/status; token precedence flag-file > env > stored; keychain-first, 0600 file fallback | Core networked pattern; gh-style | derived |`,
where rows 1–10 (`:63-72`) are the `org-locked` ones and cover command ordering, `-v`,
structured output, noun number, boolean negation, **env prefix (row 7)**, **exit codes
(row 8)**, config format (row 9) and **filesystem paths (row 10)**. The standard's own
conformance clause (`:50`) makes every **MUST** binding for conformance regardless of
provenance, so `R10.1`'s MUST clause binds this template — but, unlike `R5.3` or `R6.1`, the
owner may reopen it without disturbing an org-locked row. That distinction is stated here
because the sibling R57 decision leaned on `org-locked` for `R5.3`, and the same move is not
available for `R10.1`. `R5.5` and `R5.6` are rule-level MUSTs in §5 and carry no Decision-Log
provenance row of their own; the env-prefix and exit-code rows they interact with (`:69`,
`:70`) are org-locked.

**§10 applies to this template.** The standard scopes §10 to "CLIs that talk to a remote API
or service" (`:542`; the `### §10` heading is `:540`). Both sources' tokens are personal access tokens for a remote projects
API (py `cli/commands/projects.py:48`; ts `src/router.ts:136` `--token <token>`, "personal
access token"), and `web-extra-surface` (R69) adds an HTTP surface, so the template is a
networked CLI and §10 binds.

**The decisive architectural observation.** The prompt's binary — py's rule versus ts's shape
— is a false choice, because "the config file" and "a credential file" are different objects
that ts conflates and that every authority surveyed separates:

| | (a) The layered settings file | (b) A dedicated credential store |
|---|---|---|
| Who writes it | the user, by hand, and `config set` | an `auth login` command only |
| How many | one per tier (system, user, project), merged | exactly one, unmerged |
| Where | `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`, plus `$XDG_CONFIG_DIRS` and — per `R5.2` (`:303`) — `.<tool>/<tool>_config.toml` **inside the working directory and each parent** | `$XDG_STATE_HOME/<tool>/` per `R10.1`, or the OS keychain |
| What users do with it | commit it to dotfile repos, copy it to new machines, paste it into issues, back it up | nothing; it is machine-managed |
| Rust precedent | Cargo `config.toml` | Cargo `credentials.toml` |

py's ADR-0002 argument is an argument about **(a)**: "config files get copied, committed,
backed up, and shared in ways secret stores are not, and a 'convenient' token-in-file path
normalizes leaking" (py `docs/adr/0002-no-secrets-in-config-file.md`, read at pin
`b08bccfb`). clig.dev's recommendation — "Secrets should only be accepted via credential
files, pipes, AF_UNIX sockets, secret management services, or another IPC mechanism" — is a
recommendation of **(b)**. They are not in conflict. ts's `src/lib/config.ts:177` puts the
token in **(a)**, and its mitigation at `:135` (`if ((mode & 0o077) !== 0) { warn(…) }`)
addresses only *local read access by other users on the same host* — it says nothing about
the copy, commit, backup and paste vectors that py's ADR names, and nothing at all once the
file is inside a git working tree.

**Why the composition risk with R54 is not hypothetical.** ts's file tier is user-tier only
(`defaultConfigPath` → `configDir(env, homedir)`, `src/lib/config.ts:95-99`), so ts's token
is never discovered from inside a repository. py *does* have a project tier
(`./plbp_config.toml`, `core/config.py:124-139`, the project tier at `:137`), and the standard's `R5.2` **SHOULD** puts a
project tier at `.<tool>/<tool>_config.toml` in the current directory and each parent
(`:303`). If R54 adopts a project tier — which the standard recommends and py already does —
then adopting ts's shape unchanged makes the token readable from, and writable into, a file
that lives in the user's git working tree. That is the exact leak path, and it is created by
*composition*, not by either item alone.

**R17's bearing, stated as a limit rather than a comfort.** R17 is owner-accepted and ships a
TruffleHog CLI scan with `--only-verified --fail` (`research/topics/17-secret-scanning-ci-workflow/DECISION.md`,
`## Decision`, Part 2). `--only-verified` passes anything the scanner cannot *live-verify
against the issuing provider*: R17's own executed evidence records a fixture of realistic but
non-live credentials exiting `0` under the filter and `183` without it (assertions `07a`,
`07b`), and records a `postgres://user:password@localhost:5432/appdb` URI that produced **no
detector hit at all** at `v3.97.4` (`08g`, `08k`). This template's own token is a personal
access token for a fictional projects API: it has no TruffleHog detector and no issuer to
verify against. **So the CI secret scanner does not backstop a token-in-config policy for
this tool's own credential.** That is an argument for forbidding the channel, not for
relying on the scanner to catch its consequences.

**What published Rust guidance says (the LOW question, answered including the null result).**
There is no RustSec rule on credential sources — RustSec publishes vulnerability advisories,
and `GET https://rustsec.org/packages/<name>.html` returned HTTP `404` for every crate in
this stack (a page exists only where an advisory does; `nix` returned `200` with
RUSTSEC-2021-0119 as the positive control). The Rust-side guidance that does exist is
Cargo's own documentation, and it is unusually explicit: alternative authenticated registries
"require a credential provider to be configured **to avoid unknowingly storing unencrypted
credentials on disk**", and `cargo:token` "stores credentials in unencrypted plain text in
the credentials file" — while the *recommended* configuration lists the OS providers after
`cargo:token`, "later entries have higher precedence"
(`https://doc.rust-lang.org/cargo/reference/registry-authentication.html`, retrieved
2026-09-17). Cargo therefore permits a plain-text credential file, in a dedicated file,
as the fallback beneath a keychain — which is `R10.1`'s SHOULD, reached independently.

**Where the ecosystems must differ, and where they must not.** P1–P3 and P5–P6 are
language-independent and must hold identically in py, ts and rs; a follow-on project makes py
and ts conform (py already satisfies P3 and P5 and violates P1; ts violates P1 and P3). P4's
*mechanism* is genuinely ecosystem-bound: Python would reach for `keyring`, TypeScript for
`keytar`'s successors or a subprocess helper, Rust for `keyring-core` plus platform store
crates — and in Rust that choice carries a cost the other two do not pay, measured below.

**The chosen design, and how it preserves each principle.**

1. **The layered config file is never a credential source** (P3). R53's schema declares no
   `token` field. R53's in-flight `## Decision` head was read
   (`research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md`): it recommends
   `serde` with `derive` and no dedicated validation crate, carrying the schema in Rust's own
   types — the keys it enumerates are `OutputFormat`, `ColorChoice` and a `NonZeroU32`
   `output.limit`, and **no `token` field appears in it**, so this recommendation and R53's
   current shape agree rather than collide. A `token` key found in any layer is **dropped with one warning** naming the
   file and the key and never the value, with the exit code unchanged — the same disposition
   R55 clause 3 gives a value-level fault, chosen for consistency with an in-flight sibling (R55 is **not** published to `research/topics/`; it was read at `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md`)
   rather than invented here. Silently ignoring it (py's behaviour) is rejected: the user who
   wrote the key believes the tool is authenticated, and R55's own principle is that a
   dropped leaf is announced.
2. **Three tiers, in `R10.1`'s order** (P1, P2): `--token-file <PATH>` > `RSLBP_TOKEN` env >
   stored credential. The tier *count* is ts's; the third tier's *identity* is not.
3. **The third tier is a dedicated credential store** (P3, P4): by default a `0600` file at
   `state_dir().join("credentials.toml")` — R57's accepted `state_dir()`, which `R5.3` files
   logs and history under and `R10.1` names for exactly this file — written only by
   `rslbp auth login`, never by `config set`, never merged into the config chain, never
   project-discovered. Optionally the OS keychain via `keyring-core`, behind a **non-default**
   Cargo feature, for the reason measured in the `keyring-core` member: on `ubuntu-latest`
   the keychain path pulls 89 packages including a full smol-family async runtime, and there
   is no Secret Service daemon on a hosted runner to talk to.
4. **The loose-permission check survives, retargeted** (P4). `mode & 0o077 != 0` is checked on
   the credential file and on any `--token-file` target — the two files that actually hold a
   secret — and produces one non-fatal warning naming the path and `chmod 600`, never the
   value. It is emitted **once, at credential resolution**, not per token read; there is one
   resolution per process. F245's mechanism is kept; its subject moves.
5. **Creation is `0600` at `O_CREAT`** — `OpenOptions::new().create_new(true).mode(0o600)` via
   `std::os::unix::fs::OpenOptionsExt` — never create-then-`chmod`. ts writes
   `writeFileSync(path, data, { mode: 0o600 })` and then `chmodSync(path, 0o600)` with the
   comment "writeFileSync applies mode only at creation; chmod covers rewrite"
   (`src/lib/config.ts:264-266`): on a rewrite of a pre-existing `0644` file the secret is on
   disk world-readable between the two calls. R52's decision already carries a
   `BASELINE-REVIEW: F243` disposition about atomic 0600 writes; this is the same concern at
   the syscall level and is recorded as an implementation requirement, not a second review.
6. **The token is a `secrecy::SecretString` from the moment it leaves its source** (P5), so
   `R5.6` masking is a property of the type rather than of every call site, and F246's
   inherited display convention becomes the `Display` impl of one wrapper.

**Mapping to R67, which needs no change.** R67 is owner-accepted; every failure this policy
produces has a row already:

| Condition | R67 code | Exit | Why |
|---|---|---|---|
| `--token-file <PATH>` names a file that does not exist, or one that is empty after trimming | `RSLB401` credentials absent | 4 | the user named a credential source and it supplied none; `R10.1` sends auth failures to `4` |
| `--token-file <PATH>` names a file that exists and cannot be read (permission, `EISDIR`, device error) | `RSLB101` I/O | 1 | an I/O fault, not an auth-policy fault |
| No tier supplies a token | `RSLB401` | 4 | ts already exits `4` here (`requireToken` at `src/lib/config.ts:221`, `throw new AuthError(...)` at `:227`) |
| The remote rejects the token | `RSLB402` | 4 | unchanged |
| A `token` key in a config layer | *no code* | unchanged | it is a warning, not a failure |

**No `CONFLICT:` line is required.** R67's `RSLB204` ("secret supplied through a prohibited
channel" → 2) has **no instance** in this design, because the one prohibited channel is
handled by a warning. R67 defined it prospectively; that is recorded here so a synthesizer
does not read its emptiness as a gap. It acquires an instance only under the runner-up in
`### Recommendation` (a deprecated `--token <VALUE>` alias that exists solely to refuse).

**`BASELINE-REVIEW:` finding.**

BASELINE-REVIEW: F240 — a credential must never be readable from the process table, so the top precedence tier must name a *file* (or read stdin) rather than carry a value — replace the recorded `--token <VALUE>` flag tier in all three repositories with `--token-file <PATH>` plus a stdin path, leaving the tier's precedence position unchanged — evidence: org CLI Design Standard v1.4.14 blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` `R5.5` **(MUST)** at `:327-329`, "Secrets (tokens, passwords, keys) **MUST NOT** be accepted as plain command-line flags or positionals, because argv is visible in process listings … ✅ `ACME_TOKEN=… acme login`, `acme login --token-file ./tok` ❌ `acme login --token sk_live_abc123`", reinforced by `R10.1` at `:545` ("flag-supplied token‑*file* > `ACME_TOKEN` env > stored credential, and a token **MUST NOT** be passed as a plain flag value (R5.5)") and by clig.dev ("Do not read secrets directly from flags … the flag value will leak the secret into `ps` output and potentially shell history", retrieved 2026-09-17); both sources violate it at their pins — py `src/py_launch_blueprint/cli/options.py:110-114` declares `click.option("--token", default=None, help="Py Personal Access Token (overrides $PLBP_TOKEN). Never stored.")`, and ts `src/router.ts:136` declares `.option('--token <token>', 'personal access token')` and *documents it as remedy 1* in `missingTokenMessage` (`src/lib/config.ts:203-204`, "1. Use the --token option when running the command: ts-projects --token your_token_here"), so the leak is not incidental but recommended.

Affected items: **R56** (this item — the chain's top tier); **R60** (`cli-parsing-framework`,
published — its `GlobalArgs` surface must declare `--token-file`, not `--token`; the string
`--token` occurs **0 times** in `research/topics/60-cli-parsing-framework/DECISION.md`, and 0
times in R66's and R67's, counted with `/usr/bin/grep -c`, so this raises no collision with a
published sibling); **R61** (`interactive-prompts`, in flight — its
`## Decision` head was read at
`research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md` and selects
`inquire 0.9.4` behind a template-owned `Prompter` trait with `std::io::IsTerminal` as the
interactivity gate; the four prompt shapes it enumerates are `Confirm`, `Text`/`CustomType`,
`Select` and `MultiSelect`, and **none is a masked/password input**. `inquire` ships a
`Password` type but R61 does not select it, so the hidden-input path `auth login` needs is
covered by no decision yet — a gap, not a collision); **R67** (`RSLB204` acquires an instance only
if a refusing `--token` alias is kept). Changes to py and ts are a follow-on project; this
report supplies their rationale and does not edit the ledger.

**Minimal realistic example, and what was actually executed.** A throwaway Cargo package was
created under a subdirectory of `$TMPDIR`, built and run, then deleted. It is *not* the
template; it is a probe that exercises the six behaviours above in Rust. Full commands,
output and figures are in `### Validation strategy`. Everything labelled **executed** below
ran; everything labelled **proposed** did not.

### Recommendation

**One stack — `config-secret-policy/v1`.** Adopt **neither repository's recorded shape**.

> The layered config file (`<tool>_config.toml`, at every discovery tier R54 lands on) is
> **never** a token source, as py's ADR-0002 rules and R53's schema will reflect by having no
> `token` field. The precedence chain nonetheless has **three** tiers, as ts's does, because
> `R10.1` **(MUST)** requires three — but the third tier is a **dedicated credential store**,
> not the config file: a `0600` `credentials.toml` under R57's `state_dir()`, written only by
> `rslbp auth login`, optionally backed by the OS keychain behind a non-default `keychain`
> feature. The chain is `--token-file <PATH>` > `RSLBP_TOKEN` > stored credential. ts's
> non-fatal `mode & 0o077` warning is kept and retargeted from the config file to the
> credential file and any `--token-file` argument. A `token` key found in a config layer is
> dropped with one warning that names the key and never the value.

The crates that realize it, with the versions that resolved and built on `rustc 1.98.0`
(Homebrew) on 2026-09-17:

| Slot | Selection | Feature posture | Where it runs |
|---|---|---|---|
| POSIX mode inspection and `0600`-at-`O_CREAT` creation | `std::os::unix::fs::{PermissionsExt, OpenOptionsExt}` (no crate) | `#[cfg(unix)]` with a `#[cfg(not(unix))]` stub | library crate, credential I/O module |
| In-memory secret carriage and display masking | `secrecy = "0.10.3"`, **default features only** (`serde` off) | default | library crate, the token type |
| Memory zeroing beneath it | `zeroize = "1.9.0"` (floor; `secrecy` requires `^1.6`) | pulled by `secrecy` with `default-features = false, features = ["alloc"]` | transitive |
| OS keychain (optional third-tier backing) | `keyring-core = "1.0.0"` + `apple-native-keyring-store = "1.0.2"` (macOS) and `zbus-secret-service-keyring-store = "1.0.1"` (Linux), each behind `#[target.'cfg(…)'.dependencies]` | **non-default** Cargo feature `keychain` | CLI binary only |

**Ranked runner-up for the policy itself** (not for a crate): keep ts's shape — config file as
lowest tier — but confine it to the **user** tier and refuse it in any project-tier layer,
with the `mode & 0o077` warning as ts has it. It wins only if the owner rules that a template
must not ship an `auth login` command and that a third tier must therefore live in a file the
user already edits. Its cost is exactly the risk py's ADR names, and it becomes materially
worse the moment R54 adopts `R5.2`'s project tier.

**Second runner-up for the refusal mechanism:** keep a deprecated `--token <VALUE>` flag whose
only behaviour is to fail with `RSLB204` at exit `2`, pointing at `--token-file`, so that the
many users following py's and ts's current documentation get a message instead of clap's
unknown-argument error. It gives `RSLB204` its only instance. It is *not* recommended: clap
already exits `2` on an unknown argument with a suggestion, and the alias is public surface
that must then be deprecated and removed under `R9.2`.

### Members

#### std::os::unix::fs (PermissionsExt + OpenOptionsExt)

##### Landscape
Bin: **built-in / first-party toolchain**. The category is "read and set a POSIX file mode
from Rust". The field has exactly four shapes: `std`'s Unix extension traits; a libc wrapper
(`nix`, `rustix`); a capability-based filesystem (`cap-std`); and a convenience wrapper over
`access(2)`-style questions (`faccess`, `file-mode`). `std` is the only one that is already
present, has no MSRV of its own, and has no advisory surface.

##### Principles and implementation
Realizes P4 (a stored credential is protected at rest) and half of P1's enforcement (the
`--token-file` target is checked too). Two operations are needed and both are `std`:
`fs::metadata(p)?.permissions().mode()` via `PermissionsExt` for inspection, and
`OpenOptions::new().write(true).create_new(true).mode(0o600)` via `OpenOptionsExt` for
creation. The second is the one ts gets wrong: creating at `0600` under `O_CREAT|O_EXCL` has
no window in which the file exists with a wider mode, whereas ts's
`writeFileSync(…, {mode}) ; chmodSync(…)` pair (`src/lib/config.ts:264` and `:266`) does.
**How it degrades without a Windows branch** (the prompt's HIGH question): the module is
`#[cfg(unix)]` and a `#[cfg(not(unix))]` sibling returns `None` from `permission_warning` and
opens without a mode. That *is* a compile-time branch, and saying otherwise would be false —
what it is not is a *runtime* branch or a platform-specific dependency, and on the owner-fixed
`target-os-matrix` (`ubuntu-latest, macos-latest`, both POSIX) the `not(unix)` arm is never
compiled at all. `std::os::unix` is available on both, so no `cfg` is needed to *select a
crate*, only to keep the file compilable if the matrix ever widens.

##### Dominant choice
`std`. Executed: `A1 create-at-0600 — mode after create_new(.mode(0o600)) = 0600`;
`A2 no-warning-at-0600`; `A3 warning-at-0644 — warning emitted = true` (see
`### Validation strategy`).

##### Qualified shortlist
`rustix 1.1.5` (`GET https://crates.io/api/v1/crates/rustix`, retrieved 2026-09-17:
`recent_downloads` 252,310,446; `downloads` 1,139,025,249; newest unyanked `1.1.5`
`2026-09-16T23:05:02Z`; declared `rust_version` 1.65; licence
`Apache-2.0 WITH LLVM-exception OR Apache-2.0 OR MIT`; repo `bytecodealliance/rustix`;
`https://rustsec.org/packages/rustix.html` → HTTP 404).
`nix 0.31.3` (`recent_downloads` 176,100,616; `downloads` 799,076,408; newest unyanked
`0.31.3` `2026-05-11T07:01:18Z`; declared `rust_version` 1.69; licence `MIT`).
**`nix` passes gate 3 and is qualified, not excluded** — the gate asks for no *open* advisory,
and `https://rustsec.org/packages/nix.html` returns HTTP `200` listing only
RUSTSEC-2021-0119, "Out-of-bounds write in `nix::unistd::getgrouplist`" (dated 2021-09-30,
retrieved 2026-09-17), which is long patched. Both crates are qualified and both are
unnecessary: they would add a dependency to obtain a number `std` already returns.

##### Excluded by gate
**None. No candidate in this member failed a gate**, and the field is recorded as empty
rather than padded with candidates that merely lost on fit.
Two candidates were **not shortlisted**, on grounds that are explicitly *not* gate failures:
- `faccess 0.2.4` — last release `2022-03-20T14:03:14Z`, no declared `rust_version`
  (`GET https://crates.io/api/v1/crates/faccess`, retrieved 2026-09-17). Under the
  maintenance rubric a stale release date is a **trigger to investigate, never a verdict**,
  and **no investigation was performed**, so no maintenance state is assigned to it here. It
  is not shortlisted because it answers "can *I* access this?" (an `access(2)`-shaped
  question) rather than "who *else* can?", which is the question this item asks.
- `file-mode 0.1.2` — last release `2021-02-24T12:03:09Z`, `recent_downloads` 7,249
  (`GET https://crates.io/api/v1/crates/file-mode`, retrieved 2026-09-17). Same rubric
  caveat: the date is a trigger, not a verdict, and it was not investigated. Not shortlisted
  because `std` already returns the mode it would format.

##### Up-and-comers
`cap-std 3.4.6` (`recent_downloads` 8,083,990; `downloads` 20,638,027; newest
`2026-08-20T15:13:10Z`; repo `bytecodealliance/cap-std`, 821 stars, `archived: false`,
`pushed_at` `2026-08-20T15:13:19Z`, `gh api repos/bytecodealliance/cap-std`, retrieved
2026-09-17). It offers capability-scoped filesystem handles, which would let the credential
module be handed a directory capability rather than an absolute path. **Advisory note**:
OSV reports one advisory, `GHSA-hxf5-99xg-86hw` ("cap-std doesn't fully sandbox all the
Windows device filenames", introduced `0`, fixed `3.4.1`), so `3.4.6` is unaffected and the
issue is Windows-only (`POST https://api.osv.dev/v1/query`, retrieved 2026-09-17). Not
recommended now: it buys sandboxing this template has no threat model for.

##### Fit for this template
Perfect. The template is a CLI plus a library plus an optional web service; the permission
check belongs in the library's credential module and must not drag a dependency into the
library's public dependency graph, which R02 and R04 both care about.

##### Recommendation
`std::os::unix::fs::{PermissionsExt, OpenOptionsExt}` under `#[cfg(unix)]`, with a
`#[cfg(not(unix))]` stub that returns "unchecked" rather than "clean", so a future Windows
matrix entry reports honestly instead of silently asserting safety.

##### Ranked runner-up
`rustix 1.1.5`, if the template ever needs `openat`-relative operations or wants to avoid
`libc` entirely. It changes nothing about this item's behaviour.

##### Tradeoffs
Gains: zero dependencies, zero MSRV pressure, zero advisory surface, zero compile-time cost.
Costs: the `#[cfg]` pair must be written and tested twice, and `std` gives no help with the
TOCTOU gap between `metadata()` and `read_to_string()` — accepted, because the warning is
advisory and the read is the authoritative act.

##### Parameters
Owns none. Assumes `target-os-matrix = ubuntu-latest, macos-latest` (both POSIX) and
`rust-edition = 2024`. No `CONFLICT:`.

##### Migration implications
New library module (proposed name `credentials`) holding `permission_warning`,
`write_credential`, `read_credential`; `#[cfg(unix)]`/`#[cfg(not(unix))]` pairs inside it.

##### Validation strategy
Executed in the probe: `A1`–`A4`. Proposed for P03: the same three assertions as
`#[cfg(unix)]` unit tests plus a `0640` and a `0604` case, and a negative test asserting that
the warning string does not contain the secret's bytes.

##### Confidence & re-verify trigger
**High.** Re-verify only if `target-os-matrix` gains a non-POSIX entry, which turns the stub
from dead code into behaviour.

##### Sources
`std::os::unix::fs` — `https://doc.rust-lang.org/std/os/unix/fs/` (API used; the behaviour
asserted here was executed locally rather than read from the page).
`https://crates.io/api/v1/crates/{rustix,nix,faccess,file-mode,cap-std}` and `/versions`,
retrieved 2026-09-17. `https://rustsec.org/packages/{rustix,nix,cap-std}.html`, retrieved
2026-09-17 (`rustix` `404`, `nix` `200`, `cap-std` `404`).
`POST https://api.osv.dev/v1/query` for `cap-std`, retrieved 2026-09-17.
`gh api repos/bytecodealliance/cap-std`, retrieved 2026-09-17. ts `src/lib/config.ts:264-266`
at pin `cb1cbcb2`.

#### secrecy 0.10.3

##### Landscape
Bin: **established industry standard**. The category is "a type that holds a secret, refuses
to print it, and wipes it on drop". The Rust field has three shapes: `secrecy` (a wrapper
type over `zeroize`); `zeroize` alone (wiping without a `Debug` guard); and hand-rolled
newtypes with a manual `Debug` impl, which is what both source repos do (ts's
`redactToken(token: string)` at `src/lib/config.ts:233`, a free function that every call
site must remember to call).

##### Principles and implementation
Realizes P5. The defect a wrapper fixes is structural, not stylistic: `R5.6` **(MUST)**
requires masking in "`config view`, `--debug`/request logs, progress, and error messages"
(`:332-333`), which is an open set of call sites, and a free masking function only protects
the sites that remember it. `SecretString` makes the guarantee a property of the value: its
`Debug` prints a placeholder, and reaching the bytes requires the explicit
`ExposeSecret::expose_secret()`, which is greppable in review and lintable in CI. **Executed:**
`D1 Debug of SecretString = SecretBox<str>([REDACTED])` and
`D2 Debug of resolved = Some(SecretBox<str>([REDACTED]))`, and a byte census over the probe's
combined stdout and stderr found **0** occurrences of the fixture credential
(`/usr/bin/grep -c 'sk_live_R56PROBE_DO_NOT_LOG'` over both streams → `0`).
**Limit, stated because it is easy to overclaim:** `secrecy` does not make F246's *display*
convention (ts's `***` + last four characters); it makes the *default* safe. The masked-preview
form is a `Display` impl the template writes on its own newtype over `SecretString`.

##### Dominant choice
`secrecy 0.10.3`. `GET https://crates.io/api/v1/crates/secrecy` (retrieved 2026-09-17):
`crate.recent_downloads` **39,649,237**; `crate.downloads` **161,742,808**.
`GET /api/v1/crates/secrecy/versions`: newest unyanked `0.10.3`, `created_at`
`2024-10-09T19:23:36.825181Z`, declared `rust_version` `1.60`, licence `Apache-2.0 OR MIT`.
`gh api repos/iqlusioninc/crates` (the monorepo that publishes it): `stargazers_count`
**579**, `archived` **false**, `pushed_at` `2026-09-09T15:52:06Z`.
`gh api "search/issues?q=repo:iqlusioninc/crates+is:issue+is:open"` → `total_count` **30**.

##### Qualified shortlist
`zeroize 1.9.0` used directly (see its own member); a template-local newtype over `String`
with a manual `Debug`. Both are qualified; both reproduce by hand what `secrecy` makes a type
invariant, and the newtype option is what ts does and what this member exists to improve.

##### Excluded by gate
None excluded. All six gates, answered before popularity:
1. **Licence** — `Apache-2.0 OR MIT`; gate `inapplicable — owner ruling 2026-09-12 (Q7.B)`,
   recorded as observed.
2. **MSRV** — declared `rust_version = 1.60`, far beneath the floor. Current stable is
   **1.98.1** (`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`, retrieved
   2026-09-17), so `stable minus 2 minor versions` is **1.96**. Dependency-*tree* MSRV, measured
   rather than declared: with `rust-version = "1.96"` in the probe manifest, `cargo generate-lockfile`
   reported `Locking 105 packages to latest Rust 1.96 compatible versions`, and the maximum
   declared `rust_version` across the resolved default tree was **1.85** (`hashbrown 1.85.0`,
   then `indexmap`/`serde_spanned`/`toml`/`toml_datetime` at `1.85`), via
   `cargo metadata --format-version 1 --filter-platform aarch64-apple-darwin`. **Passes.**
3. **Advisories** — `https://rustsec.org/packages/secrecy.html` → HTTP **404** (no advisory
   page); `POST https://api.osv.dev/v1/query` for `secrecy` → **0** vulns. `unsafe` posture:
   `secrecy` itself is a thin wrapper and the wiping happens in `zeroize`, which uses
   `unsafe` deliberately (volatile writes and compiler fences) — stated in `zeroize`'s member.
   **Passes.**
4. **Platforms** — it is `no_std`-capable pure Rust with no platform code; built and run here
   on `aarch64-apple-darwin` (macOS) under `rustc 1.98.0`, and resolved for
   `x86_64-unknown-linux-gnu` via `cargo tree --target`. Windows: no platform-specific code,
   supported, not required. **Passes.**
5. **Default features and async coupling** — dependencies at `0.10.3`
   (`GET /api/v1/crates/secrecy/0.10.3/dependencies`, retrieved 2026-09-17): `zeroize ^1.6`
   with `default_features: false, features: ["alloc"]`, and `serde ^1` **optional**. **No
   async runtime, no global state, no I/O.** **Passes.**
6. **Binary size and compile time** — qualitative and measured as package count: the probe's
   default tree is **10 unique packages** (`cargo tree -e normal --prefix none | sed 's/ (\*)//' | sort -u | grep -c .`),
   of which 8 are `toml`'s (R52's already-accepted stack) and the R56 additions are exactly
   **two**: `secrecy` and `zeroize`. Both are small pure-Rust crates with no build script and
   no proc-macro; the compile-time and binary-size cost is negligible.

##### Up-and-comers
None with standing. The category is stable and `secrecy` has occupied it since 2019; the only
movement is people choosing `zeroize` directly. Recorded as an honest empty bin rather than
padded.

##### Fit for this template
Strong for CLI and web service, and it is the *library* crate that matters: R56's token type
crosses the library boundary into both the CLI and the R69 web surface, so the redaction
guarantee has to live on the type rather than at each boundary. One caution worth naming: the
`serde` feature is **off** here. A `SecretString` must never be `Serialize`d into the config
file or a log line, and leaving the feature off makes that a compile error rather than a
review comment.

##### Recommendation
`secrecy = "0.10.3"`, default features (no `serde`), in the library crate, as the inner type
of a template-owned `Token` newtype that supplies F246's masked `Display`.

##### Ranked runner-up
A template-local newtype over `String` holding a `Zeroizing<String>`, with a hand-written
`Debug`. It wins if the owner decides this item may add no crate at all; the cost is that the
guarantee becomes a code-review obligation, which is the failure mode ts demonstrates.

##### Tradeoffs
Gains: `R5.6` enforced by the type system; one place to change F246's mask; `expose_secret()`
is a greppable audit point. Costs: one small dependency; a `stable-quiet` maintenance state
(below); and `expose_secret()` is easy to sprinkle, so the audit point only helps if CI counts
its occurrences.

##### Parameters
Owns none. Assumes `msrv-policy` (passes at 1.60 declared, 1.85 tree maximum) and `license`
(gate inapplicable per the owner ruling). No `CONFLICT:`.

##### Migration implications
One dependency line; one newtype; `Config.token` becomes `Option<Token>` rather than
`Option<String>`; every display path loses its call to a masking function.

##### Validation strategy
Executed: `D1`, `D2`, and the 0-occurrence byte census. Proposed for P03: a CI lint counting
`expose_secret()` occurrences against a pinned allow-list, and a test that renders the error
envelope for `RSLB401`/`RSLB402` and asserts the token's bytes are absent from both streams.

##### Confidence & re-verify trigger
**Medium-high** — high on fitness, tempered by the release gap. **Maintenance state:
`stable-quiet`**, earned rather than assumed. The trigger is the rubric's "no release in 6
months": `0.10.3` is dated `2024-10-09`. The investigation:
`gh api "repos/iqlusioninc/crates/commits?path=secrecy&per_page=10"` (retrieved 2026-09-17)
shows five commits touching `secrecy/` **after** that release — `doc_auto_cfg => doc_cfg (#1387)`
on `2026-09-02`, `Rust edition 2024 & MSRV 1.85 (#1347)` on `2026-01-21`, and three in
late 2024 — so the crate is being carried forward in-tree, including an edition-2024 move,
without a publish. The monorepo is not archived and was pushed `2026-09-09`. It builds on
current stable: the probe compiled `secrecy 0.10.3` under `rustc 1.98.0` with `BUILD_OK`.
There is no unpatched advisory and no maintainer notice of abandonment, so `at-risk` and
`dormant` are both unearned. Re-verify if: (a) 12 further months pass with in-tree commits
and no publish; (b) `iqlusioninc/crates` reports `archived: true`; (c) an advisory is filed
against `secrecy` or `zeroize`; (d) `secrecy 0.11` publishes, which should be adopted for the
edition-2024 alignment.
**Stated limits of the responsiveness figure**: binary `gh`. Over the 10 most recently opened
*issues* found in the 100 most recent `issues` items (the rest are pull requests, which the
query filters on `.pull_request == null`), the repository yielded **9** issues. Median days to
first **non-author** comment over the 6 that got one: **7.9 days** (values 0.19, 0.67, 1.31,
14.50, 24.88, 206.6); **3 unanswered**. Two caveats that must travel with the number: this is
a **monorepo** figure covering every iqlusion crate, not `secrecy` alone; and "first non-author
comment" is a *proxy* for "first maintainer response" — no maintainer-affiliation check was
performed.

##### Sources
`https://crates.io/api/v1/crates/secrecy`, `/versions`, `/0.10.3/dependencies`,
`/reverse_dependencies` — retrieved 2026-09-17.
`gh api repos/iqlusioninc/crates`, `gh api "search/issues?q=repo:iqlusioninc/crates+is:issue+is:open"`,
`gh api "repos/iqlusioninc/crates/commits?path=secrecy&per_page=10"`,
`gh api "repos/iqlusioninc/crates/issues?state=all&sort=created&direction=desc&per_page=100"`
and per-issue `/comments` — retrieved 2026-09-17.
`https://rustsec.org/packages/secrecy.html` (HTTP 404) and `POST https://api.osv.dev/v1/query`
— retrieved 2026-09-17. Adopters: `kube-client 4.2.0`, `async-graphql 7.2.1`, `serenity 0.12.5`,
`age-core 0.12.2`, `sp-core 43.0.0`, `ssh-agent-lib 0.6.0`, `domain 0.12.2` — all read from
`GET https://crates.io/api/v1/crates/secrecy/reverse_dependencies?per_page=20`
(`meta.total` **1,445**), retrieved 2026-09-17. `https://raw.githubusercontent.com/rust-lang/rust/stable/src/version`
→ `1.98.1`, retrieved 2026-09-17. ts `src/lib/config.ts:233` at pin `cb1cbcb2`.

#### zeroize 1.9.0

##### Landscape
Bin: **established industry standard**, and effectively the only occupant: it is the
RustCrypto project's memory-wiping primitive, with **4,333** reverse dependents
(`GET https://crates.io/api/v1/crates/zeroize/reverse_dependencies`, `meta.total`, retrieved
2026-09-17), including `rsa`, `elliptic-curve`, `ecdsa`, `curve25519-dalek`, `digest` and
`cipher`. It is named as its own member rather than folded into `secrecy` because the
template must declare a **floor** for it: `secrecy 0.10.3` requires only `^1.6`, and the
behaviour the template relies on — and the edition/MSRV posture — differ across that range.

##### Principles and implementation
Realizes the "at rest in memory" half of P4. `zeroize` performs a volatile write plus a
compiler fence so the wipe is not optimized away, which is precisely the operation that
cannot be written safely in portable Rust — hence its `unsafe` usage, which is intentional
and is the crate's reason for existing. For this item its role is narrow: it is what makes
dropping a `SecretString` actually erase the token rather than leave it in a freed
allocation that a later core dump or heap dump could contain.

##### Dominant choice
`zeroize 1.9.0`. `GET https://crates.io/api/v1/crates/zeroize` (retrieved 2026-09-17):
`crate.recent_downloads` **175,129,018**; `crate.downloads` **693,909,826**.
`/versions`: newest unyanked `1.9.0`, `created_at` `2026-06-12T18:42:35.275395Z`, declared
`rust_version` `1.85`, licence `Apache-2.0 OR MIT`; the prior release is `1.8.2`
(`2025-09-29T20:20:03Z`, `rust_version` `1.60`). `gh api repos/RustCrypto/utils`:
`stargazers_count` **671**, `archived` **false**, `pushed_at` `2026-09-15T13:36:52Z`.
`gh api "search/issues?q=repo:RustCrypto/utils+is:issue+is:open"` → `total_count` **24**.

##### Qualified shortlist
No alternative crate is qualified for this exact job. `secrecy` is a consumer of it, not a
substitute; `zeroize_derive` is an add-on this item does not need.

##### Excluded by gate
None excluded. Gates:
1. **Licence** `Apache-2.0 OR MIT`; gate `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
2. **MSRV** declared `1.85` at `1.9.0` — beneath the **1.96** floor derived from current
   stable `1.98.1`. It is the tightest constraint the default tree carries, alongside
   `hashbrown 1.85.0`, and it still clears the floor by 11 minor versions. **Passes.**
3. **Advisories** `https://rustsec.org/packages/zeroize.html` → HTTP **404**;
   OSV → **0** vulns. **`unsafe` posture: uses `unsafe` by design** (volatile writes and
   `compiler_fence`); it is not `#![forbid(unsafe_code)]` and cannot be. This is the one place
   in the stack where R06's unsafe-code policy has a live subject, and it is a *dependency's*
   unsafe, not the template's. **Passes, with the posture stated rather than glossed.**
4. **Platforms** pure Rust, `no_std`-capable, no platform code; resolved and built here for
   `aarch64-apple-darwin` and resolved for `x86_64-unknown-linux-gnu`. **Passes.**
5. **Default features / async** — pulled by `secrecy` as
   `default_features: false, features: ["alloc"]`; no async runtime, no I/O, no global state.
   **Passes.**
6. **Size / compile cost** — one of the 10 packages in the probe's default tree; no build
   script, no proc-macro (the derive lives in a separate crate that is not pulled).

##### Up-and-comers
None. Recorded as empty: the category has no credible challenger, and inventing one would
misrepresent the field.

##### Fit for this template
Indirect but load-bearing. The template does not call `zeroize` directly; it declares the
floor so that a future `cargo update` cannot resolve `secrecy`'s `^1.6` down onto a release
predating the edition-2024 and MSRV-1.85 posture the rest of the workspace assumes.

##### Recommendation
Declare `zeroize = "1.9.0"` explicitly in the workspace manifest as a floor, even though
`secrecy` would pull it anyway. This is the same move R67 made for `anyhow >= 1.0.103`.

##### Ranked runner-up
Do not declare it, and let `secrecy`'s `^1.6` decide. Acceptable, and it loses the floor
guarantee; `cargo update` would still normally pick `1.9.0`.

##### Tradeoffs
Gains: a pinned floor; explicitness for `cargo deny`/audit tooling. Costs: one more manifest
line to maintain, and a duplicate-looking entry that a reviewer may try to "clean up" —
worth a manifest comment.

##### Parameters
Owns none. Assumes `msrv-policy` (1.85 declared, floor 1.96) and `rust-edition = 2024`
(`1.9.0`'s MSRV bump to 1.85 is the edition-2024 line). No `CONFLICT:`.

##### Migration implications
One manifest line plus a comment explaining why a transitively-supplied crate is declared.

##### Validation strategy
Executed: the resolved tree shows `secrecy v0.10.3 └── zeroize v1.9.0`
(`cargo tree -e normal`), so the floor and `secrecy`'s requirement agree in practice.
Proposed for P03: a CI check asserting `cargo tree -i zeroize` reports a single version.

##### Confidence & re-verify trigger
**High.** Maintenance state **`active`**: released `2026-06-12`, repository pushed
`2026-09-15`, not archived. Responsiveness, binary `gh`, over the 10 most recently opened
issues in `RustCrypto/utils` (9 issues found among the 30 most recent items): median days to
first non-author comment over the 7 answered = **0.22 days** (0.01, 0.01, 0.13, 0.22, 0.68,
0.73, 6.42); **2 unanswered**. Same two caveats as the previous member: monorepo-scoped, and
"non-author" is a proxy for "maintainer". Re-verify on a `zeroize 2.0` release, on an
advisory against it, or if its declared `rust_version` rises above the then-current
stable-minus-2 floor.

##### Sources
`https://crates.io/api/v1/crates/zeroize`, `/versions`, `/reverse_dependencies` — retrieved
2026-09-17. `gh api repos/RustCrypto/utils`,
`gh api "search/issues?q=repo:RustCrypto/utils+is:issue+is:open"`, and the issues/comments
queries above — retrieved 2026-09-17. `https://rustsec.org/packages/zeroize.html` (HTTP 404)
and `POST https://api.osv.dev/v1/query` — retrieved 2026-09-17.
`https://raw.githubusercontent.com/rust-lang/rust/stable/src/version` → `1.98.1`, retrieved
2026-09-17.

#### keyring-core 1.0.0 (+ platform store crates) — optional `keychain` feature

##### Landscape
Bin: **established industry standard**, undergoing an **up-and-comer**-shaped restructuring.
The category is "read and write a credential in the operating system's protected store".
Three shapes exist in Rust: the batteries-included `keyring` crate (4.2.0), the split
`keyring-core` 1.0.0 plus per-platform store crates that the same maintainer now recommends,
and the Linux-only `oo7` (Secret Service and the XDG secret portal). Cargo's built-in
providers (`cargo:macos-keychain`, `cargo:libsecret`, `cargo:wincred`) are the first-party
*pattern* this member implements, but they are Cargo-internal executables, not a library.

##### Principles and implementation
Realizes P4's SHOULD: `R10.1` (`:545`) — "Stored credentials **SHOULD** use the OS keychain
when available, falling back to a `0600` file under `$XDG_STATE_HOME/acme/` (R5.3)". The
composition is the one `conda/rattler` uses: a `StorageBackend` trait with a keyring backend
and a file backend, the keyring backend calling
`keyring_core::{Entry, api::CredentialStore}` and selecting a store with
`#[cfg(target_os = "macos")] keyring_core::set_default_store(apple_native_keyring_store::keychain::Store::new()?)`
(read from `repos/conda/rattler/contents/crates/rattler_networking/src/authentication_storage/backends/keyring.rs`
via `gh api`, retrieved 2026-09-17). This is also what the crate's own maintainer instructs:
"developers should take dependencies on the keyring-core crate and the specific credential
stores they want to use", and should **not** link `keyring` with its `cli` feature "because
that will bring with it a host of credential stores (and other libraries) they don't need"
(`https://raw.githubusercontent.com/open-source-cooperative/keyring-rs/v4.2.0/README.md:12`,
retrieved 2026-09-17).

##### Dominant choice
`keyring-core 1.0.0` plus `apple-native-keyring-store 1.0.2` and
`zbus-secret-service-keyring-store 1.0.1`, **behind a non-default Cargo feature**.
`GET https://crates.io/api/v1/crates/keyring-core` (retrieved 2026-09-17):
`crate.recent_downloads` **2,404,549**; `crate.downloads` **2,730,423**; newest unyanked
`1.0.0`, `created_at` `2026-04-21T18:51:41.140307Z`, declared `rust_version` `1.85`, licence
`MIT OR Apache-2.0`. `gh api repos/open-source-cooperative/keyring-core`:
`stargazers_count` **37**, `archived` **false**, `pushed_at` `2026-04-21T18:53:26Z`.
`gh api "search/issues?q=repo:open-source-cooperative/keyring-core+is:issue+is:open"` →
`total_count` **1**.
Store crates: `apple-native-keyring-store` `recent_downloads` **1,409,036**, `downloads`
**1,579,222**, newest `1.0.2` `2026-08-06T15:44:02Z`, declared `rust_version` `1.85`;
`zbus-secret-service-keyring-store` newest `1.0.1`, declared `rust_version` `1.88`, licence
`MIT OR Apache-2.0` (all `GET https://crates.io/api/v1/crates/<name>`, retrieved 2026-09-17).

##### Qualified shortlist
`keyring 4.2.0` — the batteries-included form, and the **ranked runner-up** below. Full
figures, because the gate rules require them of whichever crate is named:
`crate.recent_downloads` **10,738,463**; `crate.downloads` **25,420,301**; newest unyanked
`4.2.0`, `created_at` `2026-08-29T23:48:56.175457Z`, declared `rust_version` `1.88.0`,
licence `MIT OR Apache-2.0`. `gh api repos/open-source-cooperative/keyring-rs`:
`stargazers_count` **767**, `archived` **false**, `pushed_at` `2026-09-15T15:46:42Z`;
`gh api "search/issues?q=repo:open-source-cooperative/keyring-rs+is:issue+is:open"` →
`total_count` **0**. Its published feature map at `4.2.0`
(`GET /api/v1/crates/keyring/4.2.0`, retrieved 2026-09-17) is
`"default": ["v1"]` and `"v1": ["apple-native-keyring-store/keychain", "windows-native-keyring-store", "zbus-secret-service-keyring-store"]`,
i.e. **its default already selects the D-Bus Secret Service on Linux**.

##### Excluded by gate
No candidate is excluded outright, but **gate 4 and gate 5 are where this member is decided,
and they are the reason the feature is off by default.**
1. **Licence** — `MIT OR Apache-2.0` throughout; gate `inapplicable — owner ruling 2026-09-12 (Q7.B)`.
2. **MSRV** — measured, not assumed. Maximum declared `rust_version` across the resolved
   `--features keychain` tree for `x86_64-unknown-linux-gnu`
   (`cargo metadata --format-version 1 --features keychain --filter-platform x86_64-unknown-linux-gnu`)
   is **1.88** (`zbus-secret-service-keyring-store`), then `secret-service 1.87.0`, `zbus 1.87`,
   `zbus_macros 1.87`, `zbus_names 1.87`. Floor is **1.96**. **Passes**, with the note that
   this is eight minor versions tighter than the default tree's 1.85 and is the workspace's
   binding MSRV constraint the moment the feature is enabled.
3. **Advisories** — `https://rustsec.org/packages/{keyring-core,apple-native-keyring-store,zbus-secret-service-keyring-store,secret-service,zbus,keyring}.html`
   all HTTP **404**; `POST https://api.osv.dev/v1/query` reports **0** vulns for each.
   `unsafe` posture: `keyring-core` is a pure-Rust API layer; the *stores* necessarily use
   `unsafe` FFI to platform APIs (`apple-native-keyring-store` binds the macOS Keychain), and
   the Linux store reaches the daemon over D-Bus rather than FFI. **Passes**, posture stated.
4. **Builds and is tested on every OS in the matrix** — **this is the finding.** It builds on
   both. It cannot be *exercised* on `ubuntu-latest`: the default Linux store is the D-Bus
   Secret Service, which requires a running secret-service daemon (GNOME Keyring, KWallet,
   KeePassXC) and a session bus; a GitHub-hosted Linux runner has neither, so any test that
   stores or retrieves a credential must either be skipped or run against a
   `dbus-run-session` plus a headless `gnome-keyring-daemon` fixture. macOS runners have a
   Keychain but an unlocked login keychain on a hosted runner is its own fixture problem.
   **This is stated as an inference from the dependency selection plus the Secret Service
   architecture, and it was not executed** — no CI job was run. It is the single most
   important thing for P03 to test before promoting the feature.
5. **Default features and async coupling** — **executed, and adverse.** With the probe's
   `keychain` feature enabled, `cargo tree -e normal --features keychain` resolves
   **13 unique packages** on the macOS host (`keyring-core` → `log`, plus
   `apple-native-keyring-store`), but **89 unique packages** for
   `--target x86_64-unknown-linux-gnu`, and the additions include an entire smol-family async
   runtime: `zbus 5.19.0`, `secret-service 5.2.0`, `async-executor 1.14.0`, `async-io 2.6.0`,
   `blocking 1.7.0`, `polling 3.11.0`, `event-listener 5.4.2`, `futures-util 0.3.34`. No
   `tokio` appears, which matters because R05 (`sync-async-execution-model`) is **unresolved**
   and R69's web stack will bring its own runtime: enabling this feature would put a *second*
   async runtime in the Linux build of a template whose execution model is not yet decided.
6. **Binary size and compile-time cost** — qualitative, from the same measurement:
   default **10** packages → `keychain` on macOS **13** → `keychain` on Linux **89**. A ~9×
   package-count increase on the primary CI runner, with proc-macro crates (`zbus_macros`,
   `futures-macro`, `zvariant_derive`, `serde_repr`) in the graph, is a material cold-build
   cost for a capability most template users will not enable.

##### Up-and-comers
- **The `keyring-core` 1.0 split itself** (2025–2026): the API moved out of `keyring` into
  `keyring-core` with every store as its own crate, `keyring-core 1.0.0` published
  `2026-04-21`. It is the reason this member names `keyring-core` rather than `keyring`, and
  it is young enough that the 1.0 API has not yet been revised.
- **`oo7`** — `GET https://crates.io/api/v1/crates/oo7` (retrieved 2026-09-17):
  `recent_downloads` **1,105,658**; `downloads` **2,036,328**; newest unyanked `0.7.0-alpha`,
  `created_at` `2026-07-17T21:59:38Z`, declared `rust_version` `1.95`, licence `MIT`; repo
  `linux-credentials/oo7`, `stargazers_count` **370**, `archived` **false**, `pushed_at`
  `2026-09-15T21:03:24Z` (`gh api`). `https://rustsec.org/packages/oo7.html` → HTTP 404; OSV
  0 vulns. **Not recommended now**: it is Linux-only (so it cannot be the whole tier on a
  two-OS matrix), its current release is an **alpha**, and its declared MSRV `1.95` sits one
  minor version under the 1.96 floor — the tightest in this report. Its advantage is real and
  worth revisiting: it speaks the XDG secret *portal*, which works inside a Flatpak sandbox
  where the raw Secret Service does not.

##### Fit for this template
Conditional. The template's value is being a *template*: everything it ships must build and be
tested on both runners with no external daemon. A keychain tier fails that test today, while
being exactly what `R10.1` prefers for a real deployment. The resolution is the one Cargo
itself uses: ship the plain-text credential file as the default provider and make the keychain
an opt-in — Cargo's `registry.global-credential-providers` defaults to `["cargo:token"]` and
the keychain providers are *recommended configuration* the user adds
(`https://doc.rust-lang.org/cargo/reference/registry-authentication.html`, retrieved
2026-09-17).

##### Recommendation
Declare, behind a **non-default** Cargo feature named `keychain`, in the **CLI binary only**:
`keyring-core = { version = "1.0.0", optional = true }`, with
`apple-native-keyring-store = { version = "1.0.2", optional = true }` under
`[target.'cfg(any(target_os = "macos", target_os = "ios"))'.dependencies]` and
`zbus-secret-service-keyring-store = { version = "1.0.1", optional = true }` under
`[target.'cfg(all(unix, not(any(target_os = "macos", target_os = "ios", target_os = "android"))))'.dependencies]`.
The exact manifest shape was resolved and locked in the probe. The library crate must not
depend on any of them — same layering rule R67 applies to `anyhow`.

##### Ranked runner-up
`keyring = "4.2.0"` with `default-features = false` and the store features chosen explicitly.
It wins if P03 finds the split crates' versions drift apart awkwardly; it loses on the
maintainer's own advice quoted above. A distant third: ship no keychain tier at all and let
the `0600` file be the only stored credential, documenting the `R10.1` SHOULD as waived per
the standard's conformance clause (`:50`: a SHOULD waiver "**MUST** name the rule ID, describe
the deviation, explain the rationale, and record the owner/date"). **That waiver is the
outcome if the owner declines the feature**, and it is a legitimate conformant path, not a
failure.

##### Tradeoffs
Gains: `R10.1`'s preferred at-rest protection; parity with Cargo's own recommended setup; a
credential that survives no plain-text file at all. Costs: 89 packages and a second async
runtime on Linux; an MSRV floor eight minors tighter; untestable on hosted CI without a
daemon fixture; and a new `auth login`/`logout`/`status` command group that no research item
currently owns.

##### Parameters
Owns none. Assumes `target-os-matrix = ubuntu-latest, macos-latest`, `msrv-policy`,
`rust-edition = 2024`. No `CONFLICT:` — but one **ownership gap**, recorded in this report's
`### Parameters` rather than as a conflict: `R10.1` **(MUST)** requires an `auth` command
group (`auth login`, `auth logout`, `auth status`), and no `R##` in `research/CLAUDE.md` owns
it. R60 owns the parsing framework, not the command inventory.

##### Migration implications
Binary-crate manifest only: a `keychain` feature that is absent from `default`, plus three
optional dependencies — `keyring-core`, and `apple-native-keyring-store` and
`zbus-secret-service-keyring-store` under `[target.'cfg(...)'.dependencies]` — none of which
may appear in the library crate's manifest. One new module `src/credentials/keychain.rs`
gated `#[cfg(feature = "keychain")]`, holding the `cfg(target_os)` store selection modelled
on rattler's `keyring.rs`. One new CI dimension: the workspace must be built and tested
**both** with and without the feature, because the feature changes the Linux dependency graph
from 10 to 89 packages and raises the tree's MSRV from 1.85 to 1.88. Documentation gains one
section explaining that the keychain is opt-in and that the `0600` file remains the default
store — the same explanation Cargo publishes for `cargo:token`.

##### Validation strategy
Executed: the manifest above resolved (`cargo generate-lockfile` → `Locking 105 packages`),
and both feature trees were enumerated (`cargo tree -e normal --features keychain`, with and
without `--target x86_64-unknown-linux-gnu`). **Not executed**: any store or retrieve call
against a real keychain, on either OS. Proposed for P03: a job on `macos-latest` that creates
and deletes an entry in a throwaway keychain, and a job on `ubuntu-latest` that does the same
under `dbus-run-session` with a headless `gnome-keyring-daemon`, each asserting that the
feature-off build still passes every credential test through the file backend.

##### Confidence & re-verify trigger
**Medium.** The crate choice is well evidenced; the *capability's* viability on CI is
inferred and unproven. Maintenance: `keyring-core` is **`stable-quiet`** — one release,
`1.0.0` on `2026-04-21`, repository untouched since `2026-04-21T18:53:26Z`, which trips the
six-month trigger; the investigation finds no advisory, no archive flag, and an active
surrounding ecosystem (the parent `keyring-rs` was pushed `2026-09-15`, and
`apple-native-keyring-store` published `1.0.2` on `2026-08-06`), so the quiet reads as a
frozen 1.0 API rather than abandonment. `keyring-rs` itself is **`active`**. Responsiveness,
binary `gh`: `keyring-core` has only **3** issues in its entire history and **all three were
opened by the maintainer** (`brotskydotcom`), so a median is not meaningful — one received a
non-author comment after **63.0 days** and two received none; the usable sample is the parent
`open-source-cooperative/keyring-rs`, where over the 10 most recently opened issues (8 found)
the median to first non-author comment is **0.40 days** (0.06, 0.07, 0.15, 0.40, 0.51, 0.61,
1.09) with **1 unanswered**, and that one is also maintainer-authored. Same "non-author is a
proxy for maintainer" caveat. Re-verify if: `oo7` reaches a stable release with an MSRV at or
under the floor; `keyring-core` publishes `1.1`/`2.0`; GitHub-hosted `ubuntu-latest` images
gain a session bus and secret service; or R05 selects an async runtime, which changes the cost
of the Linux tree.

##### Sources
`https://crates.io/api/v1/crates/{keyring,keyring-core,apple-native-keyring-store,zbus-secret-service-keyring-store,oo7,zbus,secret-service}`,
plus `/versions`, `/keyring/4.2.0`, `/keyring/4.2.0/dependencies`,
`/keyring-core/reverse_dependencies` — retrieved 2026-09-17.
`gh api repos/open-source-cooperative/{keyring-rs,keyring-core}`,
`gh api repos/linux-credentials/oo7`, the `search/issues` counts, and the issues/comments
queries — retrieved 2026-09-17.
`https://raw.githubusercontent.com/open-source-cooperative/keyring-rs/v4.2.0/README.md` —
retrieved 2026-09-17.
`gh api repos/conda/rattler/contents/crates/rattler_networking/src/authentication_storage/backends` and
`.../backends/{file,keyring}.rs` — retrieved 2026-09-17.
`https://doc.rust-lang.org/cargo/reference/registry-authentication.html` — retrieved 2026-09-17.
`https://rustsec.org/packages/*.html` and `POST https://api.osv.dev/v1/query` — retrieved
2026-09-17.

### Compatibility

**Proof the members are tested together, at three levels of strength.**

1. **A resolved and built version matrix — executed.** All four members were declared in one
   `Cargo.toml` (`edition = "2024"`, `rust-version = "1.96"`) and resolved together:
   `cargo generate-lockfile` reported `Locking 105 packages to latest Rust 1.96 compatible versions`,
   and `cargo build` reported `BUILD_OK` under `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`
   on `aarch64-apple-darwin`, 2026-09-17. The default configuration resolves to **10** unique
   packages, `--features keychain` to **13** on the macOS host and **89** for
   `--target x86_64-unknown-linux-gnu`. The `std` member needs no resolution and was exercised
   in the same binary.
2. **A declared-dependency edge — executed.** `secrecy 0.10.3` depends on `zeroize ^1.6`
   (`default_features: false, features: ["alloc"]`), read from
   `GET https://crates.io/api/v1/crates/secrecy/0.10.3/dependencies`, and the resolved tree
   shows `secrecy v0.10.3 └── zeroize v1.9.0`, so the declared floor `1.9.0` and `secrecy`'s
   requirement agree on one version — `cargo tree -i zeroize` would report a single node.
3. **A shared adopter, stated with its limit.** `conda/rattler`'s `rattler_networking` is the
   closest real composition: it pairs a `keyring_core`-based backend with a file backend for
   the same credential, which is the architecture recommended here. It does **not** use
   `secrecy`, and it does **not** set `0600` on its credentials file — the file backend writes
   through `tempfile` + `persist` with no mode call anywhere in
   `authentication_storage/backends/file.rs` (226 lines, read via `gh api …/contents/…`,
   retrieved 2026-09-17; searched for `mode`/`permission` with `/usr/bin/grep` and found
   none). So the reference implementation validates the *shape* and is weaker than this
   recommendation on two axes; that is reported rather than smoothed over. No single project
   was found that uses `secrecy` and `keyring-core` together, and none is claimed.

**Cross-member interaction to watch.** `secrecy`'s `serde` feature is deliberately off, and
`keyring-core`'s API deals in `String`/`Vec<u8>`; the boundary between them is one
`SecretString::from(String)` call at the point the store returns, after which the plain
`String` must be dropped. P03 should assert in a test that the keychain path produces a
`SecretString` and never logs the intermediate value.

### Parameters

This item owns no registry parameter — `research/CLAUDE.md` lists R56's `owns` column as `—`
and `docs/port/PARAMETERS.md` has no row naming R56.

- `assumes rust-edition = 2024` (fixed, owner-decided 2026-09-02) — the probe's manifest
  declared it and built.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — floor computed as **1.96** from current stable **1.98.1**; measured tree maxima 1.85 (default) and 1.88 (with `keychain`).
- `assumes license = MIT OR Apache-2.0` — gate `inapplicable — owner ruling 2026-09-12 (Q7.B)`; every selected crate's licence string is nonetheless `MIT OR Apache-2.0` or `Apache-2.0 OR MIT`, recorded as observed.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — both POSIX, which is what makes the permission check unconditional in practice and what makes the keychain tier untestable on the Linux runner without a daemon fixture.
- `assumes error-taxonomy-exit-codes = error-contract/v1` (R67, owner-accepted; the full value is in `docs/port/PARAMETERS.md`) — this item consumes `RSLB401` (exit 4), `RSLB402` (exit 4) and `RSLB101` (exit 1) and adds no row. `RSLB204` ("secret supplied through a prohibited channel", exit 2) is **left without an instance** under the recommendation; it acquires one only under the second runner-up.

**No `CONFLICT:` line is raised.** Every failure state this policy produces is expressible in
R67's published catalog, and no consumed parameter needs a different value.

**Two ownership gaps, recorded here because they are not conflicts and must not be silently
absorbed:**
- **The `auth` command group has no owning item.** `R10.1` **(MUST)** requires
  `auth login` / `auth logout` / `auth status`, and the recommended third tier is written by
  `auth login`. `research/CLAUDE.md` assigns it to no `R##`; R60 owns the parsing framework,
  not the command inventory. Someone must own it before P03.
- **The credential file's exact path composes with R54 and R57.** R57 is owner-accepted and
  supplies `state_dir()`; R54 is unresolved and owns discovery for the *config* file only.
  The credential file is deliberately **outside** R54's discovery: it has exactly one
  location and no tiers, which is the property that keeps it out of a repository working tree.

### Migration implications

File-level changes in the template, relative to a port that copied either source:

| Path (proposed) | Change |
|---|---|
| `Cargo.toml` (workspace) | add `secrecy = "0.10.3"` and `zeroize = "1.9.0"`; add a `keychain` feature that is **not** in `default`, with `keyring-core`, `apple-native-keyring-store` and `zbus-secret-service-keyring-store` as optional target-gated dependencies of the **binary** crate |
| `src/config/schema.rs` (R53's) | **no `token` field.** R53's typed struct gains nothing from this item |
| `src/config/load.rs` (R55's loader) | after the untyped sanitize pass, remove a `token` key if present and push one warning naming the file and the key; the value is dropped and never included in the warning |
| `src/credentials/mod.rs` (new) | `Token(SecretString)` with a masking `Display` (F246); `resolve(token_file, env, stored) -> (Option<Token>, TokenSource)`; `TokenSource { TokenFile, Env, Stored, None }` for `R5.7`'s `--show-origin` |
| `src/credentials/file.rs` (new) | `read_credential` (trims a trailing newline; empty ⇒ unset, F242 parity) and `write_credential` (`create_new(true).mode(0o600)`); `permission_warning` under `#[cfg(unix)]` with a `#[cfg(not(unix))]` stub |
| `src/credentials/keychain.rs` (new, `#[cfg(feature = "keychain")]`) | `keyring_core::set_default_store(...)` per `cfg(target_os)`, mirroring rattler's `keyring.rs` |
| `src/cli/args.rs` (R60's `GlobalArgs`) | `--token-file <PATH>`, **with no `#[arg(env = …)]` binding** — `R5.4` (`:322-324`) curates the env surface and lists "auth/token, host/endpoint, output format, config path, and telemetry opt-out", not a token *path*, and R60's AC5 pins the set of env-bound arguments against a list; adding `RSLBP_TOKEN_FILE` would have to be argued to R60, not assumed here. **No** `--token <VALUE>`; `RSLBP_TOKEN` stays the env tier per F241 |
| `src/cli/commands/auth.rs` (new; owner unassigned) | `auth login` (reads the token from stdin or `--token-file`, writes the store), `auth logout`, `auth status` (reports source, never the value) |
| `src/cli/commands/config.rs` | `config set` refuses the key `token` outright; `config view` gains `--show-origin` per `R5.7` |
| docs (`README`, first-run hint) | the three remedies change: `--token-file`, `RSLBP_TOKEN`, `rslbp auth login` — **not** "add `token = …` to the config file", which is ts's current remedy 3 (`src/lib/config.ts:207-209`) |
| `.github/workflows/` | no change required by this item; R17's scanner is unaffected and, per `### Principles and implementation`, does not backstop it |

### Validation strategy

**What was executed.** A throwaway Cargo package was created at
`$TMPDIR/r56probe/cargo/r56probe`, built, run, and the whole `$TMPDIR/r56probe` tree deleted
afterwards. Toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05)`, host `aarch64-apple-darwin`, 2026-09-17. The manifest
declared `edition = "2024"`, `rust-version = "1.96"`, `secrecy = "0.10.3"`,
`zeroize = "1.9.0"`, `toml = "1.1.6"` (R52's crate, so the config-scan assertion runs against
the accepted parser) and the target-gated optional keychain crates behind a non-default
feature.

```
cargo generate-lockfile          → Locking 105 packages to latest Rust 1.96 compatible versions
cargo build                      → BUILD_OK
cargo tree -e normal             → 10 unique packages (default)
cargo tree -e normal --features keychain                                   → 13 (macOS host)
cargo tree -e normal --features keychain --target x86_64-unknown-linux-gnu → 89, incl. zbus 5.19.0,
                                    secret-service 5.2.0, async-executor 1.14.0, async-io 2.6.0,
                                    blocking 1.7.0, polling 3.11.0, event-listener 5.4.2, futures-util 0.3.34
cargo metadata --filter-platform aarch64-apple-darwin      → max declared rust_version 1.85 (hashbrown)
cargo metadata --features keychain --filter-platform x86_64-unknown-linux-gnu
                                                           → max declared rust_version 1.88
./target/debug/r56probe          → exit 0, 12 assertions, all PASS
```

**The probe's full source, so the "executed" rows are reproducible.** The package was deleted
after the run; this is what it contained.

`Cargo.toml`:

```toml
[package]
name = "r56probe"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[dependencies]
secrecy = "0.10.3"
zeroize = "1.9.0"
toml = "1.1.6"
keyring-core = { version = "1.0.0", optional = true }

[target.'cfg(any(target_os = "macos", target_os = "ios"))'.dependencies]
apple-native-keyring-store = { version = "1.0.2", optional = true }

[target.'cfg(all(unix, not(any(target_os = "macos", target_os = "ios", target_os = "android"))))'.dependencies]
zbus-secret-service-keyring-store = { version = "1.0.1", optional = true }

[features]
default = []
keychain = ["dep:keyring-core", "dep:apple-native-keyring-store", "dep:zbus-secret-service-keyring-store"]
```

`src/main.rs`:

```rust
// R56 probe: credential-file permission gate, config-token refusal, secret redaction.
use secrecy::{ExposeSecret, SecretString};
use std::fs;
use std::io::Write;
use std::path::Path;

const SECRET: &str = "sk_live_R56PROBE_DO_NOT_LOG";

#[derive(Debug, PartialEq)]
enum TokenSource { TokenFile, Env, Stored, None }

#[cfg(unix)]
fn mode_of(p: &Path) -> std::io::Result<u32> {
    use std::os::unix::fs::PermissionsExt;
    Ok(fs::metadata(p)?.permissions().mode())
}
#[cfg(not(unix))]
fn mode_of(_p: &Path) -> std::io::Result<u32> { Ok(0o600) }

/// Returns Some(warning) when the file is group/other-accessible. No-op off unix.
#[cfg(unix)]
fn permission_warning(p: &Path) -> Option<String> {
    let m = mode_of(p).ok()?;
    if m & 0o077 != 0 {
        Some(format!("credential file {} is accessible to group/others (mode {:04o}); restrict it with: chmod 600 {}", p.display(), m & 0o7777, p.display()))
    } else { None }
}
#[cfg(not(unix))]
fn permission_warning(_p: &Path) -> Option<String> { None }

/// Create at 0600 from O_CREAT — never create-then-chmod.
#[cfg(unix)]
fn write_credential(p: &Path, s: &SecretString) -> std::io::Result<()> {
    use std::os::unix::fs::OpenOptionsExt;
    let mut f = fs::OpenOptions::new().write(true).create_new(true).mode(0o600).open(p)?;
    f.write_all(s.expose_secret().as_bytes())
}
#[cfg(not(unix))]
fn write_credential(p: &Path, s: &SecretString) -> std::io::Result<()> {
    let mut f = fs::OpenOptions::new().write(true).create_new(true).open(p)?;
    f.write_all(s.expose_secret().as_bytes())
}

fn read_credential(p: &Path) -> Option<SecretString> {
    let raw = fs::read_to_string(p).ok()?;
    let t = raw.trim_end_matches(['\n', '\r']);
    if t.is_empty() { None } else { Some(SecretString::from(t.to_owned())) }
}

/// The config document is scanned for a prohibited key; the value is dropped, never echoed.
fn scan_config(doc: &str) -> (toml::Table, Vec<String>) {
    let mut t: toml::Table = doc.parse().expect("probe fixture parses");
    let mut warnings = Vec::new();
    if t.remove("token").is_some() {
        warnings.push("key `token` in the config file is ignored: this tool never reads a credential from the config file. Use --token-file, the RSLBP_TOKEN environment variable, or `rslbp auth login`.".to_string());
    }
    (t, warnings)
}

fn resolve(tokfile: Option<&Path>, env: Option<&str>, stored: Option<&Path>) -> (Option<SecretString>, TokenSource) {
    if let Some(p) = tokfile {
        if let Some(s) = read_credential(p) { return (Some(s), TokenSource::TokenFile); }
    }
    if let Some(e) = env {
        if !e.is_empty() { return (Some(SecretString::from(e.to_owned())), TokenSource::Env); }
    }
    if let Some(p) = stored {
        if let Some(s) = read_credential(p) { return (Some(s), TokenSource::Stored); }
    }
    (None, TokenSource::None)
}

fn check(id: &str, ok: bool, detail: String) { println!("{} {} — {}", if ok {"PASS"} else {"FAIL"}, id, detail); }

fn main() {
    let dir = std::env::temp_dir().join(format!("r56-acc-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let cred = dir.join("credentials.toml");
    let secret = SecretString::from(SECRET.to_owned());

    write_credential(&cred, &secret).unwrap();
    let m = mode_of(&cred).unwrap() & 0o7777;
    check("A1 create-at-0600", m == 0o600, format!("mode after create_new(.mode(0o600)) = {m:04o}"));
    check("A2 no-warning-at-0600", permission_warning(&cred).is_none(), "0600 produces no warning".into());

    #[cfg(unix)]
    { use std::os::unix::fs::PermissionsExt;
      fs::set_permissions(&cred, fs::Permissions::from_mode(0o644)).unwrap(); }
    let w = permission_warning(&cred);
    check("A3 warning-at-0644", w.is_some(), format!("warning emitted = {}", w.is_some()));
    check("A4 warning-omits-secret", w.as_deref().map_or(true, |s| !s.contains(SECRET)), "warning text does not contain the credential".into());

    let doc = format!("token = \"{SECRET}\"\n[output]\nformat = \"json\"\n");
    let (tbl, warns) = scan_config(&doc);
    check("B1 config-token-warned", warns.len() == 1, format!("{} warning(s)", warns.len()));
    check("B2 config-token-dropped", !tbl.contains_key("token"), "`token` absent from the accepted table".into());
    check("B3 other-keys-survive", tbl.contains_key("output"), "[output] survives the drop".into());
    check("B4 warning-omits-secret", !warns[0].contains(SECRET), "warning names the key, not the value".into());
    for w in &warns { eprintln!("warning: {w}"); }

    let (t1, s1) = resolve(Some(&cred), Some("env-token"), None);
    check("C1 token-file-wins", s1 == TokenSource::TokenFile && t1.as_ref().map(|s| s.expose_secret()) == Some(SECRET), format!("source={s1:?}"));
    let missing = dir.join("nope.toml");
    let (_, s2) = resolve(Some(&missing), Some("env-token"), None);
    check("C2 missing-token-file-does-not-silently-fall-through", s2 == TokenSource::Env, format!("source={s2:?} (see decision: this MUST be a fatal error, not a fallthrough)"));
    let (_, s3) = resolve(None, Some(""), Some(&cred));
    check("C3 empty-env-is-unset", s3 == TokenSource::Stored, format!("source={s3:?} (F242 parity)"));
    let (_, s4) = resolve(None, None, None);
    check("C4 no-token", s4 == TokenSource::None, format!("source={s4:?}"));

    println!("D1 Debug of SecretString = {:?}", secret);
    println!("D2 Debug of resolved = {:?}", t1);
    fs::remove_dir_all(&dir).ok();
}
```

The leak census was run as
`cat out.txt err.txt | /usr/bin/grep -c 'sk_live_R56PROBE_DO_NOT_LOG'`, over the binary's
captured stdout and stderr together.

The 12 assertions, each printed with its measured value:

| id | Assertion | Result |
|---|---|---|
| A1 | `OpenOptions::new().create_new(true).mode(0o600)` yields mode `0600` | **PASS** — `mode after create_new(.mode(0o600)) = 0600` |
| A2 | a `0600` credential file produces no warning | **PASS** |
| A3 | the same file at `0644` produces a warning | **PASS** — `warning emitted = true` |
| A4 | the warning text does not contain the credential | **PASS** |
| B1 | a config document carrying `token = "<secret>"` produces exactly one warning | **PASS** — `1 warning(s)` |
| B2 | the `token` key is absent from the accepted table | **PASS** |
| B3 | the document's other tables (`[output]`) survive the drop | **PASS** |
| B4 | the warning names the key, not the value | **PASS** |
| C1 | `--token-file` outranks a set env var | **PASS** — `source=TokenFile` |
| C2 | **negative control**: a naive resolver silently falls through to env when `--token-file` names a missing file | **PASS (as a demonstration of the wrong behaviour)** — `source=Env`; this is exactly why the recommendation makes that case fatal `RSLB401`/4 rather than a fallthrough |
| C3 | an empty-string env value is treated as unset and the stored credential wins (F242 parity, extended to files by trimming a trailing newline) | **PASS** — `source=Stored` |
| C4 | no tier supplying a token resolves to `None` | **PASS** — `source=None` |
| D1/D2 | `Debug` of the secret and of the resolved option | **PASS** — `SecretBox<str>([REDACTED])` and `Some(SecretBox<str>([REDACTED]))` |
| leak census | occurrences of the fixture credential across the probe's stdout **and** stderr | **0** (`/usr/bin/grep -c 'sk_live_R56PROBE_DO_NOT_LOG'`) |

C2 is deliberately a negative control rather than an assertion of the recommended behaviour:
the probe implements the *naive* resolver so the failure mode is visible, and the decision
above then forbids it. P03 must implement the fatal branch and assert it.

**What is proposed and was not run.** Each of these is P03's, and none is claimed here:

1. `--token-file` naming a missing file exits `4` with `RSLB401` and a hint naming the path;
   naming an unreadable file exits `1` with `RSLB101`. (The probe shows the fallthrough this
   replaces, not the replacement.)
2. `RSLBP_TOKEN=""` with a valid stored credential resolves to the stored credential and
   exits `0` — F242 parity in the real binary.
3. A project-tier config file containing `token = …` (if R54 adopts a project tier) produces
   the same warning as a user-tier one and the value is never used — the composition case.
4. `rslbp config view --show-origin` reports the token's source as `token-file`/`env`/`stored`
   and its value masked, satisfying `R5.7` and `R5.6` together.
5. A CI assertion that no test's captured stdout or stderr contains a fixture token's bytes —
   the probe's leak census, generalized to the whole suite.
6. `keychain` feature on `macos-latest`: store, retrieve and delete an entry in a throwaway
   keychain. On `ubuntu-latest`: the same under `dbus-run-session` with a headless
   `gnome-keyring-daemon`, **or** a documented skip. This is the item's largest open risk.
7. A `cargo deny`/`cargo audit` run over both feature configurations; not run here because no
   workspace exists and the audit database was not fetched.

### Confidence & re-verify trigger

**Confidence, split by claim, because the parts are not equally supported.**

| Claim | Confidence | Ground |
|---|---|---|
| The layered config file must not be a token source | **High** | `R5.5`/`R10.1` read at the pinned blob; py's ADR-0002; Cargo's `credentials.toml` split; AWS's `credentials` split; rattler's dedicated file; the R54 project-tier composition risk; R17's `--only-verified` limit |
| The chain has three tiers in the order flag-file > env > stored | **High** | `R10.1` **(MUST)**, `:545`, quoted verbatim |
| The third tier is a dedicated `0600` store under `state_dir()` | **High** | `R10.1`'s own words plus R57's accepted `state_dir()` |
| The permission check is `std::os::unix::fs::PermissionsExt` and warns non-fatally | **High** | executed (A1–A4) |
| `secrecy` + `zeroize` are the right carriage | **Medium-high** | executed (D1, D2, leak census); tempered by `secrecy`'s 23-month release gap |
| The keychain tier belongs behind a non-default feature | **Medium-high** | executed dependency measurements (89 packages, second async runtime); the CI-daemon claim is **inferred, not executed** |
| The top tier should be `--token-file`, not `--token` | **High** as a standards reading, **Medium** as a programme decision | `R5.5` is explicit and clig.dev agrees, but it changes a shape both source repos document as remedy 1, so it is raised as `BASELINE-REVIEW: F240` for the owner rather than asserted |
| A `token` key warns rather than failing | **Medium** | reasoned from R55's **in-flight** disposition for dropped leaves — a decision not yet published, so this inherits R55's own risk; no external authority prescribes warn-versus-fail here |

**Re-verify triggers**, each mechanical:
1. The owner reopens `R10.1` — it is `derived`, not `org-locked` (Decision Log row 26, `:88`),
   so this is the one standard dependency in this report that can move without an org change.
2. R54 publishes and adopts (or declines) `R5.2`'s project tier — the composition risk in
   `### Principles and implementation` is conditional on it.
3. R53 publishes a schema — confirm it carries no `token` field.
4. R05 selects an async runtime — it changes the cost of the Linux `keychain` tree.
5. R61 publishes — a hidden-input prompt is the interactive path for `auth login`.
6. `secrecy 0.11` publishes, or 12 further months pass with in-tree commits and no release.
7. `keyring-core` publishes `1.1`/`2.0`, or `oo7` reaches a stable release with MSRV ≤ floor.
8. GitHub-hosted `ubuntu-latest` images gain a session bus and secret service.
9. Any RustSec or OSV advisory against `secrecy`, `zeroize`, `keyring-core`, a platform store
   crate, `zbus` or `secret-service`.
10. Current stable Rust rises such that the floor passes `1.88` — the `keychain` tree's
    binding MSRV.

### Sources

**The org CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`
in `/Users/stevemorin/c/cli-standards`, read 2026-09-17 via `git cat-file -p`. Rules quoted:
`R5.1` (`:288`), `R5.2` (`:303`), `R5.3` (`:308` with its purpose table at `:310-316`),
`R5.4` (`:322-324`), `R5.5` (`:327-329`), `R5.6` (`:332-333`), `R5.7` (`:336`),
`R5.8` (`:340`), `R10.1` (`:545`, example `:546`), §10's scope note (`:542`), the
conformance clause (`:50`), and the
Decision Log rows at `:63-72` (org-locked 1–10) and `:88` (row 26, `derived`).

**Rust first-party documentation** — `https://doc.rust-lang.org/cargo/reference/config.html`
and `https://doc.rust-lang.org/cargo/reference/registry-authentication.html`, retrieved
2026-09-17. `https://raw.githubusercontent.com/rust-lang/rust/stable/src/version` → `1.98.1`,
retrieved 2026-09-17. `https://doc.rust-lang.org/std/os/unix/fs/` (API reference).

**Independent guidance** — `https://clig.dev/`, retrieved 2026-09-17.

**Industry practice** — `https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html`
and `https://cli.github.com/manual/gh_help_environment`, both retrieved 2026-09-17.

**Reference implementation** — `https://github.com/conda/rattler`, crate
`rattler_networking`, read through `gh api repos/conda/rattler/contents/…` on 2026-09-17:
`crates/rattler_networking/src/authentication_storage/backends/` (`file.rs`, `keyring.rs`,
`memory.rs`, `netrc.rs`, `mod.rs`, `snapshots`).

**Programme documents** — `research/topics/67-error-and-exit-code-contract/DECISION.md` (R67,
owner-accepted), `research/topics/17-secret-scanning-ci-workflow/DECISION.md` (R17,
owner-accepted), `research/topics/52-toml-crate/DECISION.md` (R52, owner-accepted),
`research/topics/60-cli-parsing-framework/DECISION.md` (R60, published),
`research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md` (R53, in flight —
`## Decision` head read), `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md`
(R55, in flight — `## Decision` head read),
`research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md` (R57, owner-accepted),
`research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md` (R61, in flight —
`## Decision` head read),
`docs/port/PARAMETERS.md`, `docs/port/areas/ci-workflows.md`, `research/CLAUDE.md` — all read
2026-09-17.

**Pinned source repositories** — py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
`docs/adr/0002-no-secrets-in-config-file.md`, `src/py_launch_blueprint/core/config.py`
(`:33`, `:56`, `:63`, `:124-139`, `:164`, `:170-173`, `:224`), `src/py_launch_blueprint/cli/options.py:110-114`,
`src/py_launch_blueprint/cli/commands/projects.py:48`. ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `src/lib/config.ts` (`:1-99`, `:107-139`,
`:144-190`, `:203-209`, `:221-228`, `:233`, `:246-267`), `src/router.ts:136`.

**Registry and repository endpoints** — `GET https://crates.io/api/v1/crates/<name>` and
`/versions` for `secrecy`, `zeroize`, `keyring`, `keyring-core`, `apple-native-keyring-store`,
`zbus-secret-service-keyring-store`, `oo7`, `rustix`, `nix`, `faccess`, `file-mode`,
`cap-std`, `zbus`, `secret-service`; `/secrecy/0.10.3/dependencies`,
`/keyring/4.2.0/dependencies`, `/keyring/4.2.0`; `/reverse_dependencies` for `secrecy`,
`zeroize`, `keyring-core`. `gh api repos/<o>/<r>`,
`gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"`, and
`gh api "repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100"` with
per-issue `/comments`, for `iqlusioninc/crates`, `RustCrypto/utils`,
`open-source-cooperative/keyring-rs`, `open-source-cooperative/keyring-core`,
`linux-credentials/oo7`, `bytecodealliance/cap-std`. `https://rustsec.org/packages/<name>.html`
and `POST https://api.osv.dev/v1/query`. All retrieved 2026-09-17.

**Method notes.** Figures came from `crates.io` (`GET /api/v1/crates/<name>` for
`crate.recent_downloads` and `crate.downloads`; `GET /api/v1/crates/<name>/versions` for the
newest `yanked: false` version's `num`, `created_at`, `rust_version` and `license`), from
`api.github.com` via the authenticated `gh` binary (`repos/<o>/<r>` for `stargazers_count`,
`archived` and `pushed_at`; `search/issues?q=…+is:issue+is:open` for `total_count`, never
`open_issues_count`), from `rustsec.org` package pages, and from `api.osv.dev` as an
independent advisory cross-check. `curl -sS` was used for crates.io with a `User-Agent`
header. Local measurements came from `cargo` 1.98.0 and `rustc` 1.98.0 in a throwaway package
under a subdirectory of `$TMPDIR` that was created for this run and deleted after it; counts
of packages came from `cargo tree -e normal --prefix none | sed 's/ (\*)//' | sort -u | grep -c .`
and MSRV maxima from `cargo metadata --format-version 1 --filter-platform <triple>`.
Occurrence counts over text used `/usr/bin/grep -c` explicitly, because a typed `grep` in this
environment is `ugrep` and honours `.gitignore`.

*What I could not verify, stated plainly.*
(1) **No separate "CI standard" document was found.** The task's phrase "the CI standard's
secret-handling rules" was chased three ways, all executed 2026-09-17:
`/Users/stevemorin/c/cli-standards` at `9da70eb` contains only `cli-design-standard.md`,
`docs/skills/cli-standards.md`, `LICENSE` and `README.md`; `~/c` holds `cli-standards` and
`rest-standards` and no CI-standard repository; and
`/usr/bin/grep -rn -i 'ci standard\|ci-standard\|CI Design Standard' docs research/CLAUDE.md docs/superpowers`
returned **no matches** (an earlier attempt at this search died on an unquoted `--include=*.md`
glob under zsh and produced no output at all; it was re-run properly and this sentence rests
on the re-run). `docs/port/` contains no CI-standard file either — its contents are `areas`,
`BASELINE-REVIEW.md`, `COMMONALITY.md`, `COVERAGE.md`, `DIVERGENCE-ANALYSIS.md`,
`OWNER-ACCEPTANCES.md`, `OWNER-REVIEW.md`, `PARAMETERS.md`, `PY_INVENTORY.md`,
`REVIEW-PHASE4.md`, `TS_INVENTORY.md`, `ts-research-method-review.md`. The CI-side secret
rules I could locate and did use are R17's owner-accepted decision and
`docs/port/areas/ci-workflows.md` (rows F048, F050, F061 and the release-auth rows). If a CI
standard exists somewhere these three searches do not reach, this report has not read it.
(2) **The keychain tier was never exercised.** No keychain entry was stored or retrieved on
either OS; the CI-viability claim is an inference from the resolved dependency set plus the
Secret Service architecture.
(3) **No `cargo audit` / `cargo deny` run.** Advisory checking was done through
`rustsec.org` package pages and OSV, not through a resolved-lockfile audit.
(4) **Issue-responsiveness figures use "first comment by someone other than the issue author"
as a proxy for "first maintainer response"**; no maintainer-affiliation check was made, and
for `iqlusioninc/crates` and `RustCrypto/utils` the figure is monorepo-scoped rather than
crate-scoped.
(5) **`secrecy`'s in-tree commits after `0.10.3` were read from commit subjects**, not from
diffs; the claim is that the directory is being maintained, not that any specific behaviour
changed.
(6) **The `gh` counterexample is thin**: `gh_help_environment` gave the env-over-stored
precedence but the page fetch did not surface the `hosts.yml` path, so no claim is made about
where `gh` stores its token beyond "stored credentials", and no `gh` source was read.
(7) **No benchmark was run.** The performance discussion is confined to package counts,
dependency-graph shape and build success; no latency, throughput or binary-size measurement
was taken, and none is asserted.
