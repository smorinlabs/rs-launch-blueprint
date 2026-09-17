# 2026-09-17 — R50 — install-smoke-test (bundle, Focused) — decision (revision 1)

## Decision

**Recommendation — one stack, entirely first-party, adding no crate, no GitHub
Action and no dependency to the template.** Build the publishable archive, install
it from a copy extracted outside the repository into a throwaway root, and execute
the resulting command:

```sh
cargo package -p rs-launch-blueprint --locked --no-verify
# extract target/package/rs-launch-blueprint-<ver>.crate into $(mktemp -d)
cargo install --path "<scratch>/rs-launch-blueprint-<ver>" --root "<scratch>/root" \
    --locked --debug --no-track --target-dir "<target_directory>/install-check"
test -x "<scratch>/root/bin/rslbp"
"<scratch>/root/bin/rslbp" --version    # exit 0, stdout contains <ver>
```

Hold the whole procedure in **one `just` recipe named `install-check`**, attributes
`[group('build'), group('releases')]`, **no alias**, and wire that one recipe into
pull-request CI as **one job named `install-smoke` on `ubuntu-latest` only**, gated
by R11's code-change path filter. The optional web surface is a second, step-level
leg (`just install-check web`) in the same job, conditioned on R11's web filter.

**This decision is a proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. The empirical check
below was executed against throwaway fixture crates, never against the template,
which does not exist. What P03 must validate is listed under `## Engines`. A
decision that does not survive implementation is revised against this recorded
research, not researched again from scratch.

**Ledger rows settled.** `F221` (`docs/port/COMMONALITY.md:225`,
`packaging-distribution`, origin `different`, verdict `DIVERGENT`) — the *cadence*
of a CI-wired build-and-install smoke test: **rs adopts py's cadence**, a
path-filtered pull-request gate, not ts's local-only recipe. `F222` (`:226`,
origin recorded as `py-only`) — the *mechanism*, an ephemeral install-and-run of
the just-built artifact: **rs realizes it as pack → extract → `cargo install
--root` → run**, and the row's own recorded guess (`cargo install --path . --root
<tmp>`) is the **runner-up**, not the recommendation, for the reason measured in
`## Empirical check`.

**Which runner the smoke job uses, and why: `ubuntu-latest` only.** Three grounds,
and one of them is an observation rather than an argument.

1. *The artifact under test has no per-OS variant.* A `.crate` is a **source**
   archive — there is no platform tag as there is on a wheel — so what this check
   exercises (the `[package] include` allow-list's completeness, the manifest
   metadata, the install verb, and the fact that a command called `rslbp` is
   produced and runs) is OS-independent in Cargo. A macOS-only *compile* break in
   the tree is caught by the ordinary test job, which does run on `macos-latest`.
2. *This is py's cadence, not a narrowing of it.* py's own `build-smoke` runs on
   **one** runner (`runs-on: ${{ vars.RUNNER_UBUNTU || 'ubuntu-latest' }}`,
   `.github/workflows/ci.yml:204-223` at pin `b08bccfb`, read by the Opus engine
   2026-09-17) despite py testing on three operating systems. Adopting py's
   cadence therefore means one runner, and the "path-filtered subset" the prompt
   offers as a third option is what py already does (`needs: changes`,
   `if: needs.changes.outputs.code == 'true'`).
3. *The macOS half of `target-os-matrix` is satisfied at the level the parameter
   states.* The registry describes `target-os-matrix` as "CI runners; every tool
   must run on all of them" — a compatibility requirement on the tool, which the
   recipe meets: the complete pack → extract → install → run composition was
   **executed on macOS 26.4 (Darwin arm64) in this synthesis** (`## Empirical
   check`, phases F and G), and contributors run `just install-check` on macOS
   locally. What is *not* covered is a macOS-only failure of the packaged tree
   appearing first in CI; that residual gap is stated here rather than closed, and
   widening the job to a two-runner matrix is a one-line change.

Codex recommended the two-runner matrix; the disagreement and its grounds are
recorded under `## Engines`.

**BASELINE-REVIEW: F222 — the artifact that reaches a consumer is installed as a
consumer installs it and then executed — proposed change: give F222 the origin
`different` with a ts evidence cell, and correct the three places that record ts
as having no install-and-run step — evidence:** `ts-launch-blueprint`'s
`pack-check` recipe at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` ends in
exactly that check. Verified here, mechanically, by
`git -C ~/c/ts-launch-blueprint show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:Justfile`
(`review/evidence/r50-check.sh` phase C, 14 assertions, log lines 32–54):
`Justfile:299` `SCRATCH=$(mktemp -d /private/tmp/ts-pack-check.XXXXXX)`; `:302`
`npm pack --ignore-scripts --pack-destination "$SCRATCH"`; `:304`
`npm install --no-save --no-package-lock "$SCRATCH/$TARBALL"`; `:306` runs
`"$SCRATCH/node_modules/.bin/{{command_name}}" --version`; `:307` compares it for
equality against `"{{command_name}} $VERSION"`; `:312` imports the installed
package and asserts `VERSION`. The recipe's own header comment says so at
`:268-269`: *"then pack + install into a /private/tmp scratch project and
smoke-test the bin + ESM lib import"*. The three statements contradicted are
`docs/port/COMMONALITY.md:226` (origin `py-only`),
`docs/port/areas/packaging-distribution.md:20` (ts cell `—`), and this item's own
binding prompt, `## Context` (*"ts: none (py-only; ts's `pack-check` recipe covers
packed-content assertion, not an install-and-run step…)"*) — all three still
carry the contradicted wording, asserted in phase D of the check (log lines
57–59). The packed-content assertion the prompt names is `pack-check` **step 4**,
the `npm pack --dry-run --json` file-list assertion, which is genuinely R26's
F039/F078 subject; **steps 5–6 are a separate install-and-run half that the row
drops.** Affected items: **R50** (this
item — the correction strengthens the case for the capability, moving ts's
contribution from "absent" to "present, and stronger than py's on the assertion");
**R26**, informationally only, its F039/F078 scope unchanged.

**Disposition of that finding: carried forward and endorsed.** The Opus engine
raised it; every line citation it made was re-read here at the pin and every one
held. It is recorded as a finding for the ledger's owner to apply — a ledger
wording change is a *disposition*, not an edit — and **no ledger row, area file,
index row, prompt or registry file was modified by this synthesis.** F221's own
evidence is untouched and stands: no workflow at the ts pin invokes the recipe, by
a `/usr/bin/grep -c -F` count of **0** across all **8** workflow files (log lines
44–54).

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`**
throughout, and **nothing was excluded on licence grounds**. The recommendation
adds no crate, so gates 2 (dependency-tree MSRV), 3 (RustSec advisories) and 5
(default features / async-runtime coupling of an added dependency) are likewise
`inapplicable`, each for the stated reason rather than omitted. Gate 4 is answered
by the macOS execution above plus Cargo's presence on both runner images; gate 6
(compile-time cost) is the whole substance of the cadence question and is treated
in `### Principles and implementation` with its levers, honestly labelled a model
rather than a measurement.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** *The artifact that ships is installed the way a consumer installs it,
into a location that is not the developer's environment, and the resulting command
is executed.* Source: both source repositories, read at the programme pins — py
`.github/workflows/ci.yml:220-223` at `b08bccfb`
(`uvx --from "$(ls dist/*.whl)" plbp --version`, and the same for the sdist) and
ts `Justfile:299-312` at `cb1cbcb2`. Agreement level: **capability** for the check
existing at all, and **architectural pattern** for the artifact under test being
the *packaged* one rather than the working tree. Both are present in **both**
sources, which is the strongest available evidence that the capability is the
shared principle and the mechanism is the free variable.

| # | Behavior | py at `b08bccfb` | ts at `cb1cbcb2` | Level | Must agree? |
|---|---|---|---|---|---|
| B1 | the packaged artifact is installed into a throwaway location and the command is executed | `ci.yml:220-223` | `Justfile:299-312` | capability | **yes** |
| B2 | the subject is the packaged artifact, not the working tree | `uv build` (`ci.yml:216`), then `dist/*.whl` and `dist/*.tar.gz` | the `npm pack` tarball (`Justfile:302`) | architectural pattern | **yes** |
| B3 | what a failure blocks | a required CI job | only a developer who runs the recipe | policy | **no — this is F221** |
| B4 | how strong the assertion is | `--version` exits 0, output unchecked | `--version` output compared for equality, plus a library-surface import | policy | **no — may vary** |

rs follows **py on B3** and **ts, one step short, on B4**.

**Essential behaviors and observable acceptance criteria.** Numbered so
`## Empirical check` and `## Engines` can point at them. AC1–AC7 are **proposed for
P03**; the parenthetical notes say which of them this synthesis has already
demonstrated on a fixture crate rather than on the template.

- **AC1** — `cargo package -p rs-launch-blueprint --locked --no-verify` exits 0 and
  `<target_directory>/package/rs-launch-blueprint-<ver>.crate` exists, where
  `<ver>` and `<target_directory>` both come from
  `cargo metadata --no-deps --format-version 1`. *(Demonstrated on a fixture.)*
- **AC2** — the archive carries `Cargo.toml` and a minimized `Cargo.lock`, which is
  what makes `--locked` meaningful on the install step. *(Demonstrated.)*
- **AC3** — `cargo install --path <extracted> --root <root> --locked --debug` exits
  0 **and** `<root>/bin/rslbp` exists and is executable. **The two halves are
  separate assertions**, and that is not defensive padding: with every binary
  behind an unmet `required-features` and no `--bin` flag, `cargo install` prints
  *"none of the package's binaries are available for install using the selected
  features"*, **exits 0, and installs nothing**. *(Demonstrated — see
  `## Empirical check`, phase H.)*
- **AC4** — `<root>/bin/rslbp --version` exits 0 and its stdout contains the version
  AC1 read from the manifest. *(Demonstrated.)*
- **AC5** — nothing is left behind: the scratch root and the extracted tree are
  removed on every exit path, and no binary is written to `$CARGO_HOME/bin`.
  *(The `$CARGO_HOME` half demonstrated.)*
- **AC6** *(web leg, conditional on R69's `web` feature)* — with `--features web`
  the install creates **two** executables, `rslbp` and R69's serve binary, and each
  exits 0 for `--version`. The default-feature install creates exactly **one**;
  an install that creates two on the default leg means the feature gate leaked.
  *(The one-versus-two behaviour demonstrated on a fixture; R69's concrete binary
  name is not this item's — see below.)*
- **AC7** — *(the criterion that distinguishes the recommendation from its
  runner-up)* deleting a file the build needs from the `[package] include`
  allow-list makes AC3 **fail**. A template that cannot demonstrate AC7 is not
  running the recommended procedure. *(Demonstrated — phase G.)*

**Architectural alternatives, compared before any tool was chosen.** All five
operate on the same binary and differ only in what they put under test.

| Option | Procedure | Exercises R49's `include`? | Exercises a consumer's install path? | Executes the command? | Verdict |
|---|---|---|---|---|---|
| **A** | `cargo run --locked -- --version` | no | no | yes, from the working tree | **Reject.** It cannot fail for any reason F222 exists to catch |
| **B** | `cargo install --path . --root <tmp> --locked` | **no** | partly | yes | **Runner-up.** The ledger's own guess and `sharkdp/bat`'s live CI pattern; blind to the packaging half — **measured**, see below |
| **C** | pack → extract outside the repository → `cargo install --path <extracted> --root <tmp>` → run | **yes** | yes | yes | **Recommended** |
| **D** | build a local directory registry (`cargo-local-registry`) and install through it | yes | most faithfully | yes | **Reject on cost.** A third-party tool plus a registry fixture and a checksum/index step, to close a gap one indirection wide |
| **E** | `cargo publish --dry-run --locked` | yes | no | **no** | **Reject as a substitute; already adopted elsewhere.** It never runs the command, and it is **R26's element 3** |

**Why C over B, as an observation rather than an argument.** The two options were
run against the same deliberately broken fixture: a package whose `src/main.rs`
needs `src/helper.rs`, with `include` listing only `/src/main.rs` and
`/Cargo.toml`. Option C **failed** at the install step with
`error[E0583]: file not found for module 'helper'`, exit **101**. Option B, given
the identical package, **succeeded** with exit 0 and installed a working binary,
because `--path .` builds the directory as it stands and the omitted file is still
on disk (`## Empirical check`, phase G; log lines 151–186). That is AC7, executed.

**Why that gap is not already covered.** R26 (`packed-artifact-content-guard`,
resolved) owns the packed-content question, and its own decision places elements
1–4 **on the publish workflow's verify job, before the upload** — a pull-request
copy of element 1 is recorded there as "recommended hardening, **not bound
here**", deferred to R11. So at pull-request time the template as currently
decided checks **nothing** about the packaged file set, and this item's marginal
coverage is real: it moves the packaging failure from release-tag time to review
time and adds the one step neither R26 element performs — the installed `rslbp` is
**executed**. A claim of more than that would be overselling it.

**Why the extraction goes to a scratch directory, and the ground that did *not*
survive.** The Opus engine argued that installing from an in-tree
`target/package/<pkg>-<ver>` invites a workspace-membership failure, because
Cargo's own verification path manufactures an ephemeral workspace to avoid exactly
that. **That claim was tested here and not reproduced**: on cargo 1.98.0,
`cargo install --path target/package/r50spike-0.4.2` succeeded, exit 0, with no
workspace error, in **both** live layouts — a root package carrying `[workspace]`,
and a virtual workspace root with `members = ["crates/*"]` (R02, which crate hosts
the binary targets, is still open, so both shapes were run). The recommendation
keeps the scratch extraction on a **different and observed** ground: with
`--no-verify` — the cost lever that removes a duplicated compile — **cargo leaves
no extracted copy in the tree at all**. The extracted directory is a by-product of
the verification build, not of packaging: with `--no-verify` the directory does
not exist, and with verification it does, at the price of a second full compile of
the same tree the install is about to compile again. Extracting the archive to
`$(mktemp -d)` and deleting it on exit is therefore not a workaround for a Cargo
defect; it is the only form the `--no-verify` lever permits, and it makes AC5's
cleanup assertion true by construction.

**Cost, with its workload and its levers, stated as a model and not as a
measurement.** No timing transfers from this synthesis: the fixtures are
zero-dependency crates that compile in well under a second, which proves the
composition works and proves nothing whatever about the template's cost. The real
workload is one compile of `rs-launch-blueprint`'s dependency tree plus the crate,
on a GitHub-hosted `ubuntu-latest` runner. The levers, each with its documented
source in the cargo-install reference
(`https://doc.rust-lang.org/cargo/commands/cargo-install.html`, retrieved
2026-09-17):

| Driver | Default | Lever | Effect |
|---|---|---|---|
| Profile | release | `--debug` | dev-profile compile, and the stricter smoke profile — `debug-assertions` and `overflow-checks` are on, so a startup path that trips an assertion fails loudly |
| Target directory | a new temporary folder | `--target-dir <target_directory>/install-check` | lets R10's cache action cover the smoke build; the docs name CI caching as the reason the flag exists |
| Duplicate verification build | `cargo package` verifies by compiling the extracted tree | `--no-verify` | removes one of two compiles of the same tree |
| Install tracking | tracked | `--no-track` | no tracking state written for a root deleted on exit |
| Feature set | default (`web` off) | `--features web` as a second, path-gated step | a second dependency tree; the expensive leg, hence the condition |

With `--debug`, a cached `--target-dir` and `--no-verify`, the marginal cost over
the ordinary test job is recompiling the crate itself against already-cached
dependencies. That is the basis for answering the prompt's HIGH-2 **no** — Rust's
compile time does not argue for ts's local-only cadence — with the caveat carried
in every direction: it is a cost model backed by documented behaviour and by
well-regarded projects running compile-heavy packaging checks on pull requests
(`astral-sh/uv` gates `cargo publish --workspace --dry-run` on a path-filtered PR
job; `sharkdp/bat` runs `cargo install --locked --path .` in CI), **not a
measurement**, and `## Engines` records it as unproven.

**Lockfile handling.** `--locked` on the pull-request lane. The cargo-install
reference (`https://doc.rust-lang.org/cargo/commands/cargo-install.html`,
retrieved 2026-09-17)
states that the packaged `Cargo.lock` is ignored by default and that
`--locked` forces its use; the unlocked form is the literal behavioural twin of
`uvx`, which resolves fresh against the index, but it is also network-coupled and
non-deterministic — a dependency published an hour ago can turn an unrelated pull
request red. This decision trades that twinhood for determinism and
**recommends to R34, without changing it**, that its `canary.yml` `latest-deps`
leg run the same recipe with `--locked` dropped. That is R34's and R11's call.

**What the check asserts, and what it deliberately does not.** Exit 0, **plus**
the installed file exists (AC3's second half, grounded in the measured
`required-features` behaviour), **plus** `--version`'s stdout *contains* the
version `cargo metadata` reports (AC4). The substring rather than ts's equality
form is deliberate while **R22** (`runtime-version-accessor`) and **R60** are
open: the exact `--version` string is theirs, and the assertion tightens to
equality once they fix it. The **library-surface** check ts also performs
(`Justfile:312`) is recorded as hardening and **not bound**: `cargo install`
builds the packaged `[[bin]]`, and R49's layout makes `src/main.rs` a thin CLI over
the library crate, so the `[lib]` is compiled transitively and a broken
`src/lib.rs` already fails AC3. The flip condition is explicit and is a re-verify
trigger: **if `src/main.rs` ever stops depending on the library crate**, a scratch
consumer crate becomes necessary rather than optional.

**Recipe vocabulary (the prompt's LOW-5).** Yes, it belongs to the F176–F178
vocabulary, which is `just` + `[group(…)]` attributes + short aliases — not a
fixed list of recipe names. Recipe **`install-check`**, attributes
`[group('build'), group('releases')]`, **no alias**; CI job **`install-smoke`**.
Grounds, verified at the pin: ts's closest recipe carries
`[group('releases'), group('build')]` (`Justfile:275`) and has no alias
(`/usr/bin/grep -c -E '^alias [a-z]+ := pack-check$'` = **0**), and in both sources
aliases are reserved for the daily loop. The name deliberately differs from ts's
`pack-check` because in rs the packed-content half is R26's and lives in the
publish workflow, so a recipe called `pack-check` would promise a check it does
not perform; the job name echoes py's `build-smoke` family while naming what it
does.

**Reference implementations.** Each half of the stack has a live, well-regarded
adopter, and the composition as a whole does not — stated rather than papered
over. `sharkdp/bat` runs `cargo install --locked --path .` inside GitHub Actions
and then runs the installed command (`.github/workflows/CICD.yml:99`, `:103`,
`:129`; 60 472 stars, `archived: false`, `pushed_at` `2026-09-04T19:10:30Z`, 330
open issues — `GET https://api.github.com/repos/sharkdp/bat` and
`GET https://api.github.com/search/issues?q=repo:sharkdp/bat+is:issue+is:open`,
retrieved 2026-09-17). `astral-sh/uv` — the authors of the very `uvx` F222 records
py using — gates a compile-heavy packaging check on a path-filtered pull-request
job (`.github/workflows/check-publish.yml` plus `ci.yml:58-61`; 89 890 stars,
`archived: false`, `pushed_at` `2026-09-17T02:33:02Z`, 2 360 open issues, same
endpoints, retrieved 2026-09-17). `ts-launch-blueprint` at pin `cb1cbcb2` is the
shared adopter of (task runner × pack-install-run smoke). But a GitHub code search
for the literal `"cargo install --path target/package"`
(`GET https://api.github.com/search/code`, retrieved 2026-09-17) returned
`total_count: 7`, all documents or fixtures in small repositories — **no
well-regarded project installs from an extracted `.crate`**, so the recommendation
rests on first-party primitives plus the measured AC7 result, not on adoption.
`just` 1.58.0 is the recipe host and is settled upstream by F176 (`COMMON →
REUSE`), re-verified rather than re-opened here: 533 628 90-day downloads,
2 597 663 all-time (`GET https://crates.io/api/v1/crates/just` →
`crate.recent_downloads`, `crate.downloads`), newest un-yanked `1.58.0`
`created_at` `2026-08-03T20:29:15Z` (`…/versions`), 35 828 stars, `archived:
false`, `pushed_at` `2026-09-01T20:47:57Z`, 171 open issues, median first
maintainer response **0.53 days with 0 unanswered** across the ten most recently
opened issues, and no RustSec page (`https://rustsec.org/packages/just.html` →
HTTP 404, against a `time` → HTTP 200 control) — maintenance state **`active`**.
All retrieved 2026-09-17 by the Opus engine.

**Migration implications for P03.** All additive: `Justfile` gains one recipe;
`.github/workflows/ci.yml` gains one job whose body is a single
`run: just install-check` plus the conditional web step; `Cargo.toml`, `.gitignore`
and `just check-deps` are unchanged — the recipe adds no tool (`tar` and `jq` are
already required by R26's element 2, `cargo` and `just` by R42). One portability
correction when porting ts's recipe shape: ts hardcodes
`mktemp -d /private/tmp/ts-pack-check.XXXXXX` (`Justfile:299`), a macOS-only path;
the Rust recipe uses a bare `mktemp -d`, which works on both runner images. The
job needs outbound network (`cargo install` resolves and downloads dependencies) —
the same note R26 recorded for its publish-time verify job, handed to **R08**
rather than settled here. The recipe derives both the `.crate` path and its
`--target-dir` from `cargo metadata`'s `target_directory` rather than from the
literal string `target/`, because R49's `build-tool-output-shape` states the
directory is relocatable; a hardcoded `target/` would break the recipe in the very
job that invokes it.

re-verify: 2027-03-17, or earlier on any of — (1) a Cargo release that changes `cargo install`'s default lockfile handling, its default target directory, or the semantics of `--root`, `--debug`, `--no-track` or `--target-dir`; (2) a Cargo release that changes `cargo package`'s output path, its default verification, or `--no-verify` semantics — in particular, if `--no-verify` ever leaves an extracted copy in the tree, the ground for the scratch extraction moves; (3) R49 changing the binary name `rslbp`, the single `[[bin]]`, or the `[package] include` allow-list; (4) R11 fixing `ci-job-structure` in a way that makes a dedicated, path-filtered job unavailable; (5) R69 resolving its serve binary's placeholder name to a literal, or changing its `required-features` gate; (6) R22 or R60 fixing `--version`'s exact output, at which point AC4 tightens from a substring to ts's equality form; (7) `src/main.rs` ceasing to depend on the library crate, which makes the scratch-consumer library check necessary; (8) a macOS-only packaging failure being observed, which widens the job to the two-runner matrix; (9) R26's elements moving from the publish workflow to pull-request CI, which changes this item's marginal coverage; (10) R34 accepting or declining the unlocked `latest-deps` leg recommended above; (11) the F222 ledger correction above being applied or rejected; or (12) the first execution of the recipe against the real template in P03, which is when every cost figure in this decision first becomes measurable

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

No `CONFLICT:` line: no consumed or read parameter needs to change for this
recommendation to hold, and neither raw report raised one.

**Why the list has exactly four lines.** R50's binding prompt carries an empty
`- owns:` line and an empty `- consumes:` line (asserted mechanically — `## Empirical
check`, phase B, log lines 28–29), so the item owns no parameter and registers no
consumption. The four fixed registry parameters are therefore the complete set of
`- assumes` declarations, and each value above is the **current**
`docs/port/PARAMETERS.md` row, byte-compared against this run's
`inputs/PARAMETERS.md` snapshot for all four (log lines 18–25).

**How the `web-extra-surface` snapshot discrepancy was handled.** This run was
prepared before R69 published: `inputs/PARAMETERS.md` shows
`web-extra-surface = —` while the live registry now carries R69's value. Both
states were asserted rather than assumed — the snapshot row still reads `—` (count
1) and the live row no longer does (count 0), log lines 26–27. The discrepancy
changes nothing that can be written here, because **R50's prompt registers no
consumption of `web-extra-surface`**: an `- assumes web-extra-surface = …` line
would be outside the prompt's coupling set and would fail publication either way,
against the snapshot's `—` or against R69's live value. The parameter is instead
read as context for AC6 and the web leg, both written conditionally, and the fact
that R69's value arrived **after** this run was prepared is stated here as the
task requires. R69's decision is published and owner-facing; note that the second
binary's name is a **placeholder** in R69's own text, so this decision names R49's
`rslbp` for the smoke test and treats the serve binary's concrete name as R69's
and P03's to fix.

**How the other parameters bear on the decision, read but not registered.**
`build-tool-output-shape` (R49, owner-accepted, decision sha256
`86b7f925ef89ac682ea00bb0b6fea8a809c1abc712d9e0e0ced8e5082990d948`) binds this
item through the prerequisite, and the prompt's `## Couplings` deliberately
registers no consumption of it because the test procedure does not vary by the
target's exact name — only by whether a `[[bin]]` target exists. Three of its
values are read: the single `[[bin]]` named **`rslbp`**, the package name
`rs-launch-blueprint` (so `cargo install rs-launch-blueprint` installs the command
`rslbp` with no `--bin` flag, and integration tests resolve it through
`CARGO_BIN_EXE_rslbp`), and the `[package] include` allow-list whose completeness
AC7 exercises. `ci-job-structure` (R11) is unresolved, so the job is written to be
shape-neutral: its body is a single `just install-check`, unchanged whether R11
picks a dedicated job or a step in a shared one, and the skip gate is R11's
mechanism rather than a second one invented here. `package-manager-invocation`
(R42, resolved) fixes how the recipe names its commands — `cargo package`,
`cargo install` and `cargo metadata` written as Cargo's own built-in subcommands,
`just`, `tar` and `jq` as bare executables resolved on `PATH`. `license` bears on
the decision only through R49's `include` allow-list, which must carry both
`LICENSE-MIT` and `LICENSE-APACHE` or the published artifact carries neither text;
it was **not** evaluated as a fitness gate, per the owner ruling of 2026-09-12.

## Empirical check

**Toolchain and host.** `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`;
`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; `just 1.57.0`; `Darwin arm64`,
macOS `26.4` (build `25E246`).

**Command and working directory.**

```
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/evidence/r50-check.sh
```

Exit status **0**. Full output:
`review/evidence/r50-check.log` (213 lines; sha256
`310e9f612c085f79d76d543e481f6da31098595986805b7d9377fd636316cfa4`). Script:
`review/evidence/r50-check.sh`, `shellcheck`-clean, `set -o pipefail` at the top,
`/usr/bin/grep` by absolute path with the binary named beside every count.
**68 `PASS`, 0 `FAIL`, 0 `SKIP`.**

**Reproducibility, having just shown it.** The script was run twice in succession
and the two outputs `diff`ed byte-for-byte before this sentence was written: they
are **identical**, and the saved log is run 1 of that pair. Reproducibility is not
free here — Cargo prints absolute paths, elapsed times, archive file counts and
byte sizes, and an occasional package-cache lock notice, none of which is stable —
so the script normalizes exactly those: the scratch directory (in both its logical
and its `/private`-resolved macOS form) to `<SCRATCH>`, `$HOME` to `<HOME>`,
` in N.NNs` to ` in <T>s`, archive `N files, SIZE` to `<N> files, <SIZE>`, and it
drops any `Blocking waiting for file lock` line. Two values that a reader might
expect to vary do **not**, and are asserted on directly rather than normalized: the
observed exit statuses, and the `0.4.2` the installed fixture binary prints.

**Rerunnable from a clean extraction.** The repository root is derived from the
script's own path, never from `git rev-parse`, and no phase reads this
repository's git history. Verified: `git archive HEAD` was extracted to a scratch
directory with no `.git`, the script copied in and run with `$HOME` pointed at an
empty directory — exit **0**, **54 `PASS`, 0 `FAIL`**, with the one checkout-dependent
phase announcing itself by name, `SKIP ts-pin/all — checkout absent at …`.

**What was checked, and the result.** Nothing was built in this repository and the
template was not scaffolded: every compile below is a throwaway fixture crate with
**zero dependencies**, created under a `mktemp -d` scratch root and deleted on
exit, and `cargo publish` was never invoked in any form (asserted, log line 209).
One deliberate difference between the spike and the recommended recipe: every
`cargo` command in the check passes **`--offline`**, which the fixtures permit
because they have no dependencies to resolve and which keeps the spike provably
network-free. **The recipe this decision recommends does not pass `--offline`** —
`cargo install` must resolve and download the template's real dependency tree —
so the spike is evidence about the composition's mechanics, not about its network
behaviour on a runner.

| Phase | Check | Result |
|---|---|---|
| A | toolchain and host identity | as above (log lines 6–12) |
| B | the four fixed registry values, live versus this run's snapshot; the `web-extra-surface` discrepancy; the prompt's empty `owns`/`consumes` lines | 8 `PASS` (lines 18–29) |
| C | ts `pack-check` at pin `cb1cbcb2`: the header comment, the group attributes, the absence of an alias, the six install-and-run lines, and all 8 workflow files grepped for the recipe name | 14 `PASS`, 0 matches for `pack-check` in any workflow (lines 32–54) |
| D | the three statements the `BASELINE-REVIEW` contradicts still carry their recorded wording | 3 `PASS` (lines 57–59) |
| E | `cargo install --help`: every flag the recipe uses is present; `--dry-run` is marked *unstable* and is therefore not used | 9 `PASS` (lines 62–70) |
| F | the recommended composition, end to end, on a workspace-rooted fixture | 22 `PASS` (lines 78–148) |
| G | **AC7** — option C versus option B against the same hole in `include` | 5 `PASS` (lines 151–186) |
| H | **`required-features`** — the ground for asserting the installed file exists | 5 `PASS` (lines 192–205) |
| I | nothing installed outside the scratch root; no `cargo publish` in the script | 2 `PASS` (lines 208–209) |

**The four results the decision turns on, quoted from the log.**

1. **AC7, the discriminator (phase G).** Against a fixture whose `src/main.rs`
   needs `src/helper.rs` while `include` lists only `/src/main.rs` and
   `/Cargo.toml`: the packaged archive omits the file
   (`AC7/packaged-set-omits-helper`, 0 matches for
   `r50spike-0.4.2/src/helper.rs`); **option C fails** —
   `error[E0583]: file not found for module 'helper'`, then
   `error: could not compile 'r50spike' (bin "rslbpspike") due to 1 previous error`,
   `PASS AC7/optionC-fails-on-the-hole (exit 101)`; and **option B passes on the
   identical package** — `PASS AC7/optionB-passes-on-the-same-hole (exit 0)`,
   `PASS AC7/optionB-installed-a-binary-from-the-unpackaged-tree`.
2. **`required-features` (phase H).** With the only `[[bin]]` carrying
   `required-features = ["web"]` and the feature off:
   `warning: none of the package's binaries are available for install using the
   selected features`, `PASS reqfeat/exit-is-zero (exit 0)`,
   `PASS reqfeat/nothing-was-installed`. With `--features web` on the same
   package: exit 0 and the binary is installed. An exit status alone cannot carry
   AC3.
3. **The `--no-verify` fact that places the extraction (phase F).**
   `PASS optionC/package/no-verify-skips-the-second-compile` (0 matches for
   `Verifying`) and `PASS optionC/package/no-verify-leaves-no-extracted-copy`;
   with verification instead, `PASS optionC/package-with-verify/verifies`,
   `PASS optionC/package-with-verify/second-compile` and
   `PASS optionC/package-with-verify/extracted-copy-exists`.
4. **The workspace claim that did not reproduce (phase F, F2a and F2b).**
   `PASS in-tree/root-package-workspace/install (exit 0)` and
   `PASS in-tree/virtual-workspace/install (exit 0)`, each with 0 matches for
   `member of the wrong workspace`. Recorded as a correction to the Opus raw under
   `## Engines`.

The end-to-end composition itself (phase F3) ran clean:
`Finished 'dev' profile [unoptimized + debuginfo] target(s)`, exactly one binary
installed under the scratch root, `r50spike 0.4.2` printed by the installed
command, exit 0 — and the archive was confirmed to carry both `Cargo.toml` and a
`Cargo.lock`, which is what makes `--locked` meaningful on the install step.

**What this check does not establish**, stated here rather than left to be
inferred: it did not run the recommendation against `rs-launch-blueprint` (there
is no such package), it produced no transferable timing, and it ran only on macOS.
Those limits are carried into `## Engines` as unproven rows.

## Engines

- Codex (gpt-5.6-terra) — `raw/codex.md`
  (`raw/codex-8d50eb6746d64ddc1011b7a4e471004d01d1bf2b82e8971274eb5e82e355b2d3.md`),
  10 `###` sections, two members, no `BASELINE-REVIEW:` finding.
- Claude Opus 5 — `raw/opus.md`
  (`raw/opus-266a269202b7053dca0cf3b0339558f689748d463dc537ac83b2c25abda0efbf.md`),
  10 `###` sections, three members, one `BASELINE-REVIEW:` finding on F222.

No Doxa engine ran; this is a Focused two-engine item.

**Disagreement 1 — the mechanism: option B or option C.** Codex recommended
option B, `cargo install --path . --root <mktemp-root> --locked`, the ledger's own
recorded guess; Opus recommended option C, pack → extract → install → run.
**Settled for option C, by measurement plus a scope fact.** The measurement is
phase G: given the same package with a hole in its `include` allow-list, option C
failed with exit 101 and option B succeeded with exit 0 and installed a working
binary. The scope fact is that nothing else in the template covers that gap at
pull-request time — R26's decision places its elements 1–4 on the **publish**
workflow's verify job and records a pull-request copy as unbound hardening
deferred to R11. Codex's argument for B is not wrong about B; it simply describes
a weaker test, and it is retained as the **runner-up** with a live adopter
(`sharkdp/bat`) for P03 to fall back to if the extract-and-install step proves
fragile.

**Disagreement 2 — the ground for extracting outside the repository.** Opus
asserted that an in-tree `target/package/<pkg>-<ver>` install "invites exactly the
workspace-membership problem" Cargo's verification path bypasses, and labelled it
unverified. **Corrected here: the claim does not reproduce on cargo 1.98.0.** The
in-tree install succeeded, exit 0, in a root-package workspace and in a virtual
workspace with `members = ["crates/*"]` — both shapes run because R02 is open
(phase F, F2a/F2b). The recommendation is unchanged but its ground is replaced by
an observed one: with `--no-verify` there is **no in-tree extracted copy at all**,
so the scratch extraction is the only form that lever permits. This also narrows
the re-verify trigger: what would move the decision is `--no-verify` gaining an
extraction, not a workspace-membership regression.

**Disagreement 3 — how many runners.** Codex recommended a matrix over
`ubuntu-latest` and `macos-latest`, reading `target-os-matrix` as a per-job
mandate; Opus recommended `ubuntu-latest` only. **Settled for `ubuntu-latest`
only**, on the three grounds given in `## Decision`, the strongest of which is that
py's own `build-smoke` uses one runner despite py's three-OS test matrix, so this
is py's cadence rather than a narrowing of it, and the second of which is that the
macOS half of the recipe was **executed in this synthesis** on macOS 26.4 arm64.
Codex's reading is the safer one and its cost is one extra cold compile per
code-touching pull request; the widen trigger is named in `re-verify:` (8).

**Disagreement 4 — the recipe's name and the assertion's strength.** Codex named
one recipe `install-smoke` and asserted exit 0 plus a version string; Opus named
the recipe `install-check` and the job `install-smoke`, and asserted exit 0 **plus**
the installed file's existence **plus** a version substring. **Settled for Opus's
split and Opus's assertion**, the latter because phase H reproduced the
status-0-installed-nothing outcome that makes the file-existence assertion load-
bearing rather than decorative, and the former because ts's analogous recipe's
group attributes and alias-free form were verified at the pin (`Justfile:275`,
alias count 0) and because a recipe named `pack-check` would promise R26's check.

**Disagreement 5 — whether the web surface is in scope.** Codex told P03 not to
add a web-service lifecycle check; Opus added AC6, a second `--features web` leg.
**Both are honoured, because they are about different things**: no web-service
*lifecycle* test is added (starting a server and probing it is R80's and R69's),
and the web leg asserts only what this item asserts about any binary — that it
installs and answers `--version`. The one-versus-two binary behaviour it depends
on was reproduced on a fixture (phase H).

**`BASELINE-REVIEW: F222` disposition.** Carried forward and **endorsed**, with
every line citation re-verified at the ts pin by phase C of the check. It is
recorded for the ledger owner to apply; no ledger, area, index, prompt or registry
file was edited by this synthesis. Codex emitted no `BASELINE-REVIEW:` finding and
did not examine ts's `pack-check` beyond the prompt's summary of it, so there is
no engine disagreement to settle on this point — only a gap that Opus filled and
that this synthesis independently confirmed.

**Unproven, with what would prove it.**

| Claim | Status | What would prove it |
|---|---|---|
| The composition works on the real `rs-launch-blueprint` package | **unproven** — the template does not exist; fixtures are zero-dependency crates | P03 runs `just install-check` against the built template |
| Any cost figure, cold or warm | **unproven** — no timing was measured and none is invented; a zero-dependency fixture proves nothing about a real dependency tree | P03 records wall time, cache hit/miss, runner OS and Rust version for the first cold and warm runs |
| `ubuntu-latest` alone suffices | **partly proven** — the composition ran on macOS here, but the Linux leg the job actually uses was **not** run, and no macOS-specific packaging failure was searched for | the first CI runs, plus any observed macOS-only packaging failure (widen trigger) |
| The exact `--version` output | **not this item's** — R22 and R60 own it; hence a substring, not ts's equality assertion | R22/R60 resolve |
| R69's serve binary's concrete name | **not this item's** — R69's own text carries the placeholder `<app>-serve`; this decision names only R49's `rslbp` | R69/P03 fix the literal |
| A well-regarded project installing from an extracted `.crate` | **none found** — GitHub code search for `"cargo install --path target/package"` returned `total_count: 7`, all documents or fixtures (retrieved 2026-09-17) | a future survey, or P03's own experience standing in for it |
| `--debug` installs a profile a consumer does not get | **acknowledged trade, not a defect** — the release path is exercised by R68's release build and R26's publish-time `cargo publish --dry-run`; the dev profile is also the stricter smoke profile | if a release-only failure is ever observed, the leg switches to the release profile and pays the compile |
| The AC7 negative control in the real template | **proven on a fixture, unproven on the template** | P03 removes an `include` entry, confirms `install-check` fails, restores it |

**What P03 must validate.** (1) The recipe runs green against the real template on
both `ubuntu-latest` and a developer's macOS machine. (2) The AC7 negative control
fails, which is the only way to tell the recommendation from its runner-up by
looking at a green check. (3) The job is skipped on a documentation-only pull
request under R11's filter and red on a broken one. (4) First cold and warm
timings, which convert this decision's cost model into a measurement and which
decide whether the `--target-dir` cache and `--no-verify` levers are sufficient.
(5) The default-feature install produces exactly one binary, and the `--features
web` leg exactly two, once R69's serve target is named.
