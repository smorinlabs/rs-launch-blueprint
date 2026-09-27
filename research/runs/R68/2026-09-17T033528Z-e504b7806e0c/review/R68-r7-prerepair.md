# 2026-09-27 — R68 — release-binary-artifacts (crate, Deep) — decision (revision 7)

**Revision note.** Revision 7 is a directed repair. It applies the MECHANICAL findings of
both revision-6 audits, both against revision 6 (sha256
`bf71fda79b6b51278c5c54f945f2154606b7ba762d1e49578e4dcc64b0cbb900`, preserved verbatim at
`review/R68-r6-snapshot.md`): finding JF6-1 of the judgment audit (`review/audit-fable.r6.md`,
actor `fable`, verdict `approve`) and findings 1–3 of the empirical audit
(`review/audit-codex.r6.md`, actor `codex`, verdict `approve`). Neither audit found a BLOCKING
defect. **The recommendation does not move**: every setting, key, silence, target, ranking,
figure and `- assumes` line is unchanged, so the owner acceptance `W1-R68` needs no
re-asking. All edits are prose. The evidence set is stable: no file under
`review/evidence/` was modified, added or re-run in this revision. Where a finding names a
script change, the decision-text half is applied now and the script half is explicitly
deferred to the next evidence revision; until then the decision text states the fact the
script would print.

| Finding | Audit (actor) | Severity | Text half applied in revision 7 | Script half |
|---|---|---|---|---|
| JF6-1 — stale R50 revision and line locators | `audit-fable.r6.md` (`fable`) | MECHANICAL | the R50 hand-off under `## Decision`, the build-time paragraph under `## Empirical check`, and `## Engines` Disagreement 1 cite R50's run decision as revision 7, read 2026-09-27, and anchor every R50 statement by quoted text instead of line number; the false "revision header and the line numbers cited here unchanged" parenthetical is replaced by a statement that the file is uncommitted and in flux | n/a |
| codex 2 — stale R50 source revision and locators | `audit-codex.r6.md` (`codex`) | MECHANICAL | applied together with JF6-1 as one edit across the same three passages; the conditional, unaccepted status is retained. JF6-1's quoted-text anchoring governs, so no R50 line number is kept | n/a |
| codex 1 — probe CPU header drift | `audit-codex.r6.md` (`codex`) | MECHANICAL | the host paragraph under `## Empirical check` labels the `cpu:` header as possibly unavailable under a sandbox that denies `sysctl -n machdep.cpu.brand_string`, with the `system_profiler SPHardwareDataType` cross-check; the reproduction rule states that header lines are not compared | **deferred**: the `profile-probe.sh` fallback to `system_profiler` (or an explicit unavailable label) lands in the next evidence revision |
| codex 3 — dist bootstrap version described too specifically | `audit-codex.r6.md` (`codex`) | MECHANICAL | the tool-and-pin row now says the self-release workflow demonstrates a GitHub Release installer bootstrap, cites `book/src/reference/config.md` lines 163–176 and the `v0.33.0` installer asset for the selected pin; the `artifact-sources.sh` paragraph under `## Empirical check` states the actual bootstrap version, `v0.32.0` (`release.yml` line 67 at `ref=v0.33.0`) | **deferred**: making `artifact-sources.sh` print the bootstrap version lands in the next evidence revision |

The R50 anchors were re-verified against the live R50 file, read-only, on 2026-09-27
(Pacific): its title names revision 7, and `--locked --debug --no-track`,
`cargo install --path <extracted> --root <root> --locked --debug`, `dev-profile compile`,
"R68's release build as the only release-profile compile the template is currently expected
to perform" and "(13) R68 (`release-binary-artifacts`) resolving" each occur in it. The dist
bootstrap facts were read on 2026-09-27 with `gh api` at `ref=v0.33.0`. Because
`decision-self-check.sh` was deliberately not modified or re-run, its title assertion still
names revision 6 and will fail against this file until the next evidence revision updates
it, and the committed `decision-self-check.r6.log` was produced against revision 6's bytes,
not this file's. For the same reason, two passages under `## Empirical check` that describe
the self-check ("Its 30 assertions, as of revision 6" and the closing sentence of the
reproduction rule about `decision-self-check.r6.log`) still describe revision 6 and are left
unedited for the next evidence revision. `## Engines` Disagreement 10 carries the same
over-specific wording codex finding 3 names ("from that release's
`cargo-dist-installer.sh`"); it was not enumerated in either audit and is left unedited,
recorded here for the next audit. No revision of this item was ever published, so there is
no `## Supersedes` section.

**Revision 6 history.** Revision 6 answers one finding from each revision-5 audit, both against
revision 5 (sha256 `10a6a71bda644a93a8aa667e34a90b11b5c4f890b40366ba23b464ead0010b41`,
preserved verbatim at `review/R68-r5-snapshot.md`): finding JF-5-1 of the judgment audit
(`review/audit-fable.r5.md`, actor `fable`, verdict `reject`) and finding EA5-1 of the
empirical audit (`review/audit-claude.r5.md`, actor `claude`, verdict `reject`). Both are
prose repairs. **The recommendation does not move**: every setting, key, silence, target,
ranking and `- assumes` line is unchanged, so the owner acceptance `W1-R68` needs no
re-asking. What changed: (JF-5-1) the `features` row and the *Web* paragraph under *Fit,
per surface* no longer state R51's undecided container image as the web surface's delivery
vehicle. The exclusion of the `web`-gated binary from the release archives now rests on
this item's own scope, the CLI audience the archives serve. The web binary's delivery is
stated as R51's open decision (F223), conditionally. Re-verify trigger (8) is added for R51
resolving F223 to anything other than a published image, and the R51 hand-off names it.
(EA5-1) The `install-updater` row now describes what the option does: it installs a
separate `<package>-update` executable beside the program. The unsupported claim that it
adds bytes to every shipped binary is removed. The `axoupdater` exclusion under *Fitness
gates* now distinguishes that standalone updater from the library integration. Both
statements cite dist's configuration reference and updater guide at `ref=v0.33.0`.
`profile-probe.sh` and `artifact-sources.sh` were not re-run, and no measurement, figure,
threshold or tolerance moved. `decision-self-check.sh` gains the revision-6 title assertion
and a revision-5 snapshot assertion (30 assertions) and was re-run as
`decision-self-check.r6.log`. No revision of this item was ever published, so there is no
`## Supersedes` section.

**Revision 5 history.** Revision 5 answered the two findings of the revision-4 judgment audit
(`review/audit-fable.r4.md`, actor `fable`, verdict `reject`) against revision 4 (sha256
`d07d74abb54cc9fe516b41edbc3e5b163e467808fb6314740537cf9c0f017da8`, preserved verbatim at
`review/R68-r4-snapshot.md`). The revision-4 empirical audit (`review/audit-claude.r4.md`,
actor `claude`, verdict `approve`) is undisturbed: no measurement, figure, threshold or
tolerance moved, and `profile-probe.sh` and `artifact-sources.sh` were not re-run. Both
findings are prose repairs, and the judgment audit states that neither moves a measured
direction. **The recommendation does not move**, so the owner acceptance `W1-R68` needs no
re-asking. What changed: (JF-1) the fat-LTO cost weighing — in the owner-reference
reconciliation row, the build-time paragraph under `## Empirical check` and `## Engines`,
Disagreement 1 — now separates two costs. The *incremental* penalty falls only on
`--release` rebuilds. The *marginal clean-build* cost (`thin` + one unit → `fat` + one
unit, 18 s → 25 s in `profile-probe.r2.log`, about 1.2× to 1.6× across the kept logs)
falls on the release build once per release **and** on every source installer once per
version: `cargo install --locked` users and cargo-binstall users on a target outside the
three shipped triples, whom binstall falls back to compiling. The weighing now states why
that cost is accepted. (JF-4) Every statement that R50's smoke test builds with `--debug`
now cites R50's in-flight run decision by path, revision and line, labels the
value as R50's current unaccepted proposal, and makes the R50 hand-off conditional on it;
re-verify trigger (7) is added for R50's acceptance or a change of its smoke build
profile. `decision-self-check.sh` gains the revision-5 title assertion and a revision-4
snapshot assertion (29 assertions) and was re-run as `decision-self-check.r5.log`. No
revision of this item was ever published, so there is no `## Supersedes` section.

**Revision 4 history.** Revision 4 answered the three findings of the revision-3 judgment audit
(`review/audit-fable.r3.md`, actor `fable`, verdict `reject`) and the one finding of the
revision-3 empirical audit (`review/audit-claude.r3.md`, actor `claude`, verdict `reject`),
both against revision 3 (sha256
`bb55cf4acbc9ce3ab4fb9ea7b0d969c2a86a77253640b52df1690a792155d4c2`, preserved verbatim at
`review/R68-r3-snapshot.md`). The empirical audit found every script passing and every
figure re-deriving; its one finding and all three judgment findings are prose repairs.
**The recommendation does not move**, and the judgment audit states that none of its
findings moves it, so the owner acceptance `W1-R68` needs no re-asking: Subject A, Subject
B's two written keys and four deliberate silences, the runner-up ranking, the ledger rows,
the five `- assumes` lines and `CONFLICT: none` are unchanged. What changed:
(JF-3/JF-4) `## Engines`, Disagreement 1, now labels Codex's 28.22 s → 47.39 s and
7.35 s → 18.99 s correctly, as the marginal cost of `thin` + one unit → `fat` + one unit,
sets them beside this item's own marginal clean figure (18 s → 25 s in
`profile-probe.r2.log`), withdraws "adds no new cost information", and weighs the marginal
cost against the 8.5-point size gain; Disagreement 9 now cites Codex's baseline → `fat` + one
unit figure, 29.04 s → 47.39 s. The owner-reference reconciliation row names the same
marginal figure. (JF-2) *What is unproven* discloses that incremental wall time was
measured for the baseline and recommended profiles only, and that Codex's is the only
`thin` + one-unit incremental figure on record; the build-time table gains a marginal
clean column. (JF-1, EA3-1) The `## Empirical check` description of
`decision-self-check.sh` is rewritten from the script itself. All three evidence scripts
were re-run into `.r4.log` files, and `decision-self-check.sh` gains the revision-4 title
assertion and a revision-3 snapshot assertion (28 assertions). The R49 A4 citation moves
from lines 889–890 to 889–891, where the winning condition actually ends. No revision of
this item was ever published, so there is no `## Supersedes` section.

**Revision 3 history.** Revision 3 answered the three findings of the revision-2 judgment
audit (`review/audit-fable.r1.md`, actor `fable`, verdict `reject`) against revision 2
(sha256 `72bd7972c748e529a1b226db5940e7ade4b5a2adf8e98588b137479bb6d3c5c8`, preserved
verbatim at `review/R68-r2-snapshot.md`). The revision-2 empirical audit
(`review/audit-claude.r2.md`, verdict `approve`) was undisturbed: no measurement, figure,
threshold or tolerance moved. The recommendation did not move. What changed was prose and
couplings. (JF-3) The collected Codex report (`raw/codex.md`, sha256
`297219edca2cbdaf2ce69069cf5a9bd562796daa4da5376c1e5b9ead80ae699b`, model
`gpt-5.6-terra`, collected 2026-09-21) was represented in `## Engines` and its disagreements
adjudicated; the three "absent / no lens / only engine that measured" statements were
deleted. (JF-5) An R49 hand-off recorded that this decision fires R49's A4 re-verify
trigger. (JF-2) The Subject B table cited the Cargo Book profiles chapter with its retrieval
date, and one line each recorded the inheritance rule and the override precedence.
`decision-self-check.sh` gained the revision-3 title assertion and the revision-2 snapshot
assertion (27 assertions) and was re-run as `decision-self-check.r3.log`.

**Revision 2 history.** Revision 2 rewrote revision 1 (sha256
`070b7ae10b4a3de48d8b1a1d7cb4799c18d4bfec92713f7d30776128e4578fd7`, preserved verbatim at
`review/R68-r1-snapshot.md`). It answered the two findings of the revision-1 empirical audit
(`review/audit-claude.r1.md`, actor `audit-claude-r68r1-s4`, verdict `reject`). Both findings
concerned how `review/evidence/profile-probe.sh` runs and how its reproduction is stated. Neither
disputed the direction of any measurement, so the recommendation did not move. What changed was
the probe, its lockfile, its reproduction rule, and every figure it measured. Those figures,
including the measured cells of the Subject B table, come from
`review/evidence/profile-probe.r2.log`. Revision 1's three logs are kept
unchanged beside it as history.

*EA-1: the probe failed as committed on the documented host.* Revision 1's guard demanded
`rustc 1.98.0`. On 2026-09-26 the host's Homebrew `rust` was 1.98.1, Homebrew keeps no 1.98.0,
and neither the script nor this decision said how to obtain the pinned toolchain. Revision 2
makes three changes. (a) The pin moves to the toolchain this host provides, `rustc 1.98.1
(48a229cea 2026-09-01) (Homebrew)`. The script header records that the committed log was
produced by the Homebrew distribution (`brew install rust`), and the log prints `rustc -vV`'s
commit hash and LLVM version. (b) The script gains an explicit selection route. With
`R68_TOOLCHAIN=<version>` set, every `rustc` and `cargo` call runs through `rustup run
<version>`, and the guard's failure message names `rustup toolchain install <version>`. (c)
Re-verify trigger (4) no longer contradicts the guard. `R68_TOOLCHAIN_OVERRIDE=1` runs at any
toolchain and heads the log `UNPINNED RERUN — … a NEW measurement, not a comparison with the
committed log`. The pin moved rather than staying at 1.98.0 because installing 1.98.0 needs
`static.rust-lang.org`, which is not one of this item's endpoints. For the same reason the
`R68_TOOLCHAIN` route was written but not executed; that gap is recorded under `## Engines`.

*EA-2: "byte-for-byte" was false for an independent rerun.* Revision 1 ran `cargo
generate-lockfile` at run time, so the dependency graph floated with crates.io. Revision 2
commits `review/evidence/profile-probe.Cargo.lock` (85 packages, sha256
`2756d45c172e38e05192d18dfc98cb028ff112dd1164b1f6a58d3cfc21ec1082`), and every `cargo` call
runs `--locked`. The log prints that sha256, and `decision-self-check.sh` asserts that it
matches the committed file. Revision 1's graph cannot be reconstructed, because its log
recorded only the nine direct versions. The new lockfile was therefore resolved fresh on
2026-09-26, with `thiserror` pinned back to revision 1's `2.0.20`, the only direct dependency
that had moved. The reproduction rule was then **measured rather than asserted**. A second run
in the same environment reproduced every `SIZE`, `DELTA`, `BACKTRACE` and `ASSERT` line
byte-for-byte. A third run with a different `CARGO_HOME` and `TMPDIR` moved `lto = "fat"` from
−19.8% to −19.0%, and every assertion outcome held. The rule is now a tolerance, stated under
`## Empirical check`, *Reproduction rule*.

## Decision

This decision is a **proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. The list of claims P03 must validate is
under `## Engines`. A decision that does not survive implementation is revised against
this recorded research, not researched again from scratch.

R68 answers two subjects. Subject A is which distributable artifact types the template
ships beyond the single `.crate` file `cargo publish` always produces. Subject B, added
by owner ruling W0-R69p (2026-09-16, `docs/port/OWNER-REVIEW.md`, section *"2026-09-16 —
Release build profile ownership: R68 (W0-R69p)"*), is the Cargo release build profile.

**Subject A — ship two channels, not one.** Publish the `.crate` to crates.io exactly as
`cargo publish` already produces it, **and** publish cross-compiled GitHub Release
binaries built by **`dist`** — the current command name for the tool whose crate is
`cargo-dist` and whose repository is `axodotdev/cargo-dist` — pinned at **`0.33.0`**,
operated in **follower mode** behind the release-please flow the template already
inherits (F063–F077). `cargo-binstall` compatibility (acceptance baseline **1.23.0**,
released 2026-09-05) is taken for free from the archive naming rather than configured.

| Setting | Value | Ground |
|---|---|---|
| tool and pin | `cargo-dist-version = "0.33.0"` in `dist-workspace.toml`; `ci = "github"` | `0.33.0` is the newest non-prerelease GitHub release (published 2026-09-11T05:40:23Z, `GET /repos/axodotdev/cargo-dist/releases`). dist's own self-release workflow demonstrates a GitHub Release installer bootstrap, never a crates.io install (`review/evidence/artifact-sources.log`, section C); at `ref=v0.33.0` its `.github/workflows/release.yml` line 67 fetches `v0.32.0/cargo-dist-installer.sh`, not the `v0.33.0` asset. For the selected pin, dist's configuration reference states that release CI "will fetch and use the given version of dist" named by `cargo-dist-version` (`book/src/reference/config.md`, `ref=v0.33.0`, lines 163–176), and the `v0.33.0` release carries its own `cargo-dist-installer.sh` asset (read 2026-09-27). Pinning `0.33.0` is therefore possible even though crates.io's newest stable is `0.32.0` |
| `targets` | `["x86_64-unknown-linux-gnu", "x86_64-apple-darwin", "aarch64-apple-darwin"]` | exactly the triples the two fixed runners build. Both Darwin triples build on `macos-latest`; the GNU/Linux triple is native on `ubuntu-latest` |
| `[dist.github-custom-runners]` | `global` and the Linux triple → `"ubuntu-latest"`; both Darwin triples → `"macos-latest"` | **required, not cosmetic.** dist's compiled-in defaults are the pinned labels `ubuntu-22.04`, `ubuntu-22.04-arm`, `macos-14` and `macos-15-intel`, and `ubuntu-latest` appears **0** times in its CI backend (`cargo-dist/src/backend/ci/github.rs` at `ref=v0.33.0`; counts in `artifact-sources.log`, section C). Without the override the generated workflow runs on labels the fixed `target-os-matrix` does not name |
| `create-release` | `false` | dist's own reference states that with `create-release = false` it assumes a draft GitHub Release for the current tag already exists "and just upload artifacts to it, undrafting when all artifacts are uploaded" (`book/src/reference/config.md`, `ref=v0.33.0`, line 1277) |
| `installers` | `["shell"]` | one POSIX installer script. `powershell` has no target in the fixed matrix; `homebrew` needs a tap this item does not own |
| `install-updater` | `false` (dist's default) | with `true`, dist's shell and PowerShell installers install a **separate** standalone program named `<package>-update` alongside the program, which the user runs to poll for newer releases and install them; the shipped program itself is not changed (`book/src/reference/config.md`, `ref=v0.33.0`, lines 911–927; `book/src/installers/updater.md`, same ref, lines 7–24; read 2026-09-27). Left off because that additional self-update command is outside every requirement here |
| `features` / `default-features` / `all-features` | left at dist's defaults | so the `web`-gated second binary R69 adds is **not** built into the release archives. That exclusion rests on this item's own scope: the archives, the installer script and binstall's inference serve the `rslbp` CLI audience, and `web` is an optional Cargo feature (F017), not the default build. How the web binary reaches users is R51's open decision (F223): **if** R51 ships a published container image, that image is the web surface's pre-built delivery vehicle; **otherwise** the web binary is reachable only by a source install with `--features web`, and this row re-opens under re-verify trigger (8) |
| `[package.metadata.binstall]` | **not written** | dist names archives after the **package** (`cargo-dist-<triple>.tar.xz`, although the binary inside is `dist`), and cargo-binstall's documented default GitHub filename list includes the versionless `{ name }-{ target }{ archive-suffix }` form under `{ repo }/releases/download/v{ version }/`, with a default `bin-dir` that concatenates `{ bin }{ binary-ext }`. `{ name }` is the crate name and `{ bin }` is the Cargo binary name, so R49's `rslbp` ≠ `rs-launch-blueprint` pair is the case the two defaults already cover (`SUPPORT.md` lines 148–149 and 124, quoted in `artifact-sources.log`, section E) |
| release-please side | `"draft": true` and `"force-tag-creation": true` on the released package | release-please's manifest reference documents both, and states that setting `force-tag-creation` "ensures the tag is created immediately" — without that tag the dist workflow never fires (`docs/manifest-releaser.md`, lines 217–221) |
| README — F220's derived value | document, in this order: (1) `cargo binstall rs-launch-blueprint`, (2) the installer-script one-liner, (3) `cargo install --locked rs-launch-blueprint` | F220 (`documented end-user install method`, `ADOPT`, `docs/port/COMMONALITY.md:224`) is a value derived from this item's artifact decision |

**Ranked runner-up: `taiki-e/upload-rust-binary-action` (`v1.30.2`, 2026-04-17) in a
hand-written three-target matrix, plus an explicit `[package.metadata.binstall]` block.**
Its price is exact and measured at the source: its default archive name is `$bin-$target`
— the *binary* name — while cargo-binstall's defaults are built from `{ name }`, the
*crate* name, so this template's `rslbp` ≠ `rs-launch-blueprint` pair forces a
hand-maintained `pkg-url` that nothing in CI checks. It wins when dist's registry gap or
unanswered-issue signal becomes an event the template actually hits, and it wins
immediately for a fork that adds Windows. Second runner-up: crates.io-only, which wins
only if the owner decides the audience is exclusively developers who already have a Rust
toolchain.

**Subject B — write two keys, leave four silent, declare no custom profile.**

```toml
[profile.release]
lto = "fat"
codegen-units = 1
```

| Key | Value | Manifest treatment | Cargo's documented default | Measured basis (this host, this run) |
|---|---|---|---|---|
| `lto` | `"fat"` | **written** | `false` — which the Cargo Book defines as thin local LTO on the local crate, not "no LTO" | with `codegen-units = 1`: **−24.5%** (1 994 032 → 1 504 528 B). `"thin"` alone reaches only −1.3%; the owner reference's `"thin"` + `codegen-units = 1` row reaches −16.0% |
| `codegen-units` | `1` | **written** | `16` for non-incremental release builds | −14.9% on its own, and the second half of the −24.5% row above |
| `opt-level` | leave at `3` | **silent** | `3` for `release` | both size-oriented levels made this binary **larger**: `"s"` **+12.9%**, `"z"` **+21.8%**. Writing a key that loses on both axes would be a defect |
| `strip` | leave at `"none"` | **silent** | `"none"` | it is the largest single size win measured (**−22.9%**) and is still refused: with `strip = "symbols"` the built binary's panic backtrace is `stack backtrace:` followed by **zero frames**, against 4 named frames at the recommended profile. `strip = "debuginfo"` is a **byte-identical no-op** on `release` (1 994 032 == 1 994 032), because `release` carries no debuginfo to remove |
| `panic` | leave at `"unwind"` | **silent** | `'unwind'` | measured: the abort build's panic exit status is **134**, not Rust's **101**, and its backtrace lost every user frame (2 frames against 4). Neither status is in R67's taxonomy, and abort additionally bypasses the flush-before-exit path R67's boundary contract depends on. The −20.2% size gain is largely supplied by `lto = "fat"` already |
| `debug` | leave at `false` | **silent** | `0` / `false` / `"none"` for `release` | `debug = "line-tables-only"` costs **+12.5%**, and the gain is an illusion for an end user: the same binary, copied out of the build tree with `target/` deleted, printed **0** `at ./src/…` lines where it printed 2 inside the tree. macOS `split-debuginfo` defaults to `unpacked`, so the line tables live in files the user never receives |
| custom profile | **none of this item's own** | — | a custom profile must declare `inherits` | if `dist init` writes a `[profile.dist]` stub, trim it to `inherits = "release"` with **no** keys. dist's own documentation shows the stub it generates carrying `lto = "thin"` (`book/src/reference/concepts.md`, `ref=v0.33.0`, lines 60–62) — which would silently override the recommended `lto = "fat"` for every released binary |

*Cargo Book citation (prompt line 59).* Every "Cargo's documented default" cell above is
quoted from the Cargo Book's profiles chapter
(`https://doc.rust-lang.org/cargo/reference/profiles.html`, retrieved 2026-09-17 in
`review/evidence/artifact-sources.log`, section B; default block re-read 2026-09-27), whose
`release` default block states `opt-level = 3`, `debug = false`, `strip = "none"`,
`lto = false`, `panic = 'unwind'`, `incremental = false` and `codegen-units = 16`.
Permitted values on the same page: `lto` one of `true`/`"fat"`, `"thin"`, `false` (thin
local LTO on the local crate only), `"off"`; `codegen-units` an integer;
`opt-level` one of `0`/`1`/`2`/`3`/`"s"`/`"z"`; `strip` one of `"none"` (the default),
`"debuginfo"`, `"symbols"` (bools `true`/`false` are aliases of `"symbols"`/`"none"`);
`panic` one of `"unwind"`/`"abort"`; `debug` one of `0`/`false`/`"none"` (the release
default), `"line-tables-only"`, `"line-directives-only"`, `1`/`"limited"`,
`2`/`true`/`"full"`. **Inheritance rule:** a custom profile must declare `inherits`, Cargo
reads profile settings only from the workspace-root manifest, and "Profile settings defined
in dependencies will be ignored". **Override precedence:** a `--config
'profile.release.<key>=<value>'` flag overrides the manifest value — the mechanism every
`profile-probe.sh` row relies on, since no two rows differ by a manifest edit (see
`## Empirical check`). Codex read the same page independently on 2026-09-21 and states the
same six defaults (`raw/codex.md`, `### Sources`, item 1).

**Reconciliation with the owner-supplied reference architecture**
(`docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`). Under
`docs/planning/p02/owner-decisions.md` §11 that file is an owner-supplied research input,
not a binding standard.

| Reference row | Section | Disposition |
|---|---|---|
| `codegen-units = 1` | *Reference `Cargo.toml`* | **agreed**, and independently measured here at −14.9% on its own |
| `lto = "thin"` | *Reference `Cargo.toml`* | **differed, on measured ground.** `"thin"` + `codegen-units = 1` reaches −16.0% where `"fat"` + `codegen-units = 1` reaches −24.5% on the same stand-in, same toolchain, same host: the reference's row gives up roughly a third of the available reduction. The cost of the difference — measured here as the marginal clean build `thin` + `codegen-units = 1` → `fat` + `codegen-units = 1`, 18 s → 25 s in `profile-probe.r2.log`, about 1.2× to 1.6× across the kept logs — falls on the release build once per release and on every source installer once per version: `cargo install --locked` users (README install path 3) and cargo-binstall users on a target outside the three shipped triples, whom binstall falls back to compiling. That cost is accepted because the three shipped triples cover the default audience at zero compile cost, and a source installer pays it once per installed version (see the build-time paragraph under `## Empirical check` and `## Engines`, Disagreement 1). Observation, offered as provenance rather than proof: `inherits = "release"` with `lto = "thin"` is byte-for-byte the `[profile.dist]` stub dist's own book shows it generating, and the reference's own *Caveats* section records that its material was "compiled in my head, not against the toolchain" |
| `rust-version = "1.85"`, `edition = "2021"` | *Reference `Cargo.toml`* | **overridden by the owner-fixed parameters**, which the prompt's constraints make binding: `rust-edition` is `2024` and the floor follows `msrv-policy`. Not this item's to set beyond noting the override |
| distroless/cc-debian12, cargo-chef, `nonroot`, `PORT`, `/healthz`, `/readyz` | *Details* → C15 | **handed to R51**, which owns F223/F336/F337. This item states only the coupling it creates: a container built by a plain `cargo build --release` inherits `[profile.release]` and therefore the fat-LTO link, and a cargo-chef dependency-cook layer must use the same profile as the final build or the cache misses |
| mold/lld linker, `rust-toolchain.toml` pin, bacon | *Details* → C14 | **out of scope here**; the toolchain-file question is R27's and no `[profile.*]` key is involved |

**Ledger rows settled.** F214 (`distributable artifact types`, `packaging-distribution`,
origin `different`, verdict `DIVERGENT`, item R68, `docs/port/COMMONALITY.md:218`) is
settled by Subject A. F220 (`documented end-user install method`, `ADOPT`,
`docs/port/COMMONALITY.md:224`) takes its derived value from the README row above; the
`ADOPT` verdict itself is unchanged. No ledger row is challenged: there is **no
`BASELINE-REVIEW:` finding in this item**.

**Licence.** Fitness gate 1 is recorded, not deleted, and answered `inapplicable — owner
ruling 2026-09-12 (Q7.B)` (`docs/port/OWNER-REVIEW.md`, section *"2026-09-12 — no licence
check for anything the template uses (Q4, superseded and widened by Q7.B)"*). Nothing is
excluded on licence grounds. `cargo-binstall`'s registry licence is recorded as a fact and
explicitly not evaluated.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.** Both
source repositories realise the same principle: *an end user installs the tool with one
documented command that does not require the project's build toolchain, and CI proves that
command before the release is announced.* py realises it as "build every distributable
format the ecosystem defines and check them" — `uv build` produces an sdist and a wheel,
then `twine check dist/*` and a `uvx --from "$(ls dist/*.whl)" plbp --version` smoke run
(`py .github/workflows/ci.yml:215-222` at the programme pin `b08bccfb`). ts realises it as
"one package format, because npm defines exactly one" (`"type": "module"` with a
`files: ["dist"]` allow-list, `ts package.json:20-23` at pin `cb1cbcb2`). The agreement
level is **capability, not mechanism**: the two registries' artifact formats differ so
completely that no mechanism ports.

**Why the py precedent does not decide this item.** py's two formats are one channel
(PyPI) carrying two payload shapes, and a wheel *is* a pre-built artifact — installing it
runs no compiler. Rust has no registry analogue: crates.io stores source, and
`cargo install` compiles it (`https://doc.rust-lang.org/cargo/commands/cargo-package.html`,
retrieved 2026-09-17 — `cargo package` "will create a distributable, compressed `.crate`
file with the source code of the package"). So the capability py gets free from its
registry is exactly the capability this item must decide whether to build by hand. That is
the substance behind F214's `DIVERGENT` verdict, and it argues *for* shipping binaries:
matching py's observable outcome requires a mechanism py never needed.

**Essential behaviors.** (1) One documented install command per audience. (2) The
downloaded artifact runs on `x86_64-unknown-linux-gnu`, `x86_64-apple-darwin` and
`aarch64-apple-darwin` with no Rust toolchain present. (3) The release that publishes the
`.crate` and the release that publishes the binaries are the *same* release, announced
once, on the tag release-please already owns (F063, F073). (4) A shipped binary's panic
output identifies the failing frames, because an end user cannot rebuild it.

**Observable acceptance criteria.** AC1: after a release,
`GET /repos/<o>/<r>/releases/tags/v<X.Y.Z>` lists one archive per target triple, a
`.sha256` per archive, a `sha256.sum`, an installer script and `dist-manifest.json`, and
`.draft == false`. AC2: `cargo binstall rs-launch-blueprint` on a clean machine installs
`rslbp` without invoking `rustc`, provable from binstall's own resolved strategy naming
`crate-meta-data` rather than `compile`. AC3: `cargo install --locked
rs-launch-blueprint` still works. AC4: `RUST_BACKTRACE=1 rslbp <panicking input>` on a
*downloaded* binary prints at least one frame naming `rs_launch_blueprint`. AC5: the
GitHub Release is created once, by release-please, and completed by the binary job. AC6:
no `[profile.dist]` key other than `inherits` exists in the manifest.

**What must agree, and what may vary.** What must agree: that a pre-built binary exists
for every triple the two fixed runners can build; that one release carries both channels;
that the shipped binary keeps its symbols. What may vary: the producer tool (the runner-up
reaches the same artifact set with more template-owned YAML), the installer flavours, and
whether a fork widens the triple list.

**Architectural alternatives, compared before libraries.**

| Shape | What it is | Cost | Where it fails |
|---|---|---|---|
| S1 crates.io-only | publish the `.crate`; README says `cargo install --locked` | zero release-CI cost | every user pays a full optimised compile — and this item's own profile recommendation makes that compile *more* expensive, since `cargo install` builds under the package's `release` profile |
| S2 hand-written matrix | a job per target running `cargo build --release --target …`, `tar`, `gh release upload` | ~60 lines of YAML the template owns forever; no tool dependency | the template hand-writes checksums, archive layout, installer script and the naming scheme binstall infers — four places to be subtly wrong once and not notice |
| S3 single-purpose Action | `taiki-e/upload-rust-binary-action` in a matrix | ~25 lines; one pinned Action; the most responsive maintainer surveyed | its default archive name is the binary name, which breaks binstall's crate-name-based inference for this template, making metadata mandatory rather than free |
| S4 whole-job tool | `dist` generates and owns `release.yml` | a generated workflow the template does not hand-edit; a tool version to track; a `curl … \| sh` bootstrap in that workflow | its generated runner labels and `[profile.dist]` stub must both be reconciled with this repository's fixed parameters and measured profile |

**How the recommended design preserves each principle.** S4 with `create-release = false`
is the only shape where the *same* GitHub Release carries both the changelog release-please
wrote and the binaries, with neither side racing the other: release-please supplies the
draft and the tag, dist fills the draft and undrafts it. Both halves of that hand-off were
read at their own maintainers' primary sources this run. **The load-bearing precondition is
F072's auth mechanism**: the ledger records `actions/create-github-app-token v3.2.0` as the
release-please token source (`docs/port/COMMONALITY.md:78`). A tag pushed with the default
`GITHUB_TOKEN` does not trigger another workflow; a tag pushed with an App token does.
Without F072's App token the dist workflow never fires, so the coupling belongs in the plan
rather than in a CI post-mortem.

**Maturity, dependability and the tool's standing.** `dist` is dominant on **capability,
not popularity**. Of eighteen well-regarded Rust CLIs Opus surveyed for a dist
configuration, three used it (`astral-sh/uv`, `astral-sh/ruff`, `atuinsh/atuin`); the other
fifteen ship binaries from hand-written matrices. What makes dist dominant is that it is
the only candidate producing the whole artifact set AC1 names from one configuration block,
verified this run against its own `v0.33.0` release: **23 assets**, including
`cargo-dist-<triple>.tar.xz` per triple, a `.sha256` per archive, `sha256.sum`,
`cargo-dist-installer.sh`, `cargo-dist.rb` and `dist-manifest.json`. Its own release is
built by itself, which is the strongest available evidence that the generated pipeline
works.

**Maintenance state: `at-risk`, with the deciding signal named.** The signal is a
*publication gap*, not a silence: the newest non-prerelease GitHub release is `v0.33.0`
(2026-09-11), while crates.io's newest stable is `0.32.0` (2026-05-22) and
`GET https://crates.io/api/v1/crates/cargo-dist/0.33.0` returns
`{"errors":[{"detail":"crate `cargo-dist` does not have a version `0.33.0`"}]}` (all
retrieved 2026-09-17). Against 297 open issues, Opus's ten-issue responsiveness probe found
**10 of 10 recently opened issues with no maintainer comment**, so the median time to first
maintainer response is undefined — this synthesis did not re-run that probe, and reports it
as Opus's measurement. Countervailing signals, recorded rather than suppressed:
`archived: false`, `pushed_at: 2026-09-17T10:06:25Z`, 2 115 stars, 19 585 downloads in 90
days and 176 744 all-time. Two facts bound the risk. First, the gap does **not** block the
pin: the generated workflow installs dist from the GitHub Release installer script and
never from crates.io (verified this run). Second, dist's output is ordinary GitHub Actions
YAML checked into the repository, so a fork that outgrows the tool deletes
`dist-workspace.toml` and keeps the workflow — the exit to the runner-up is a deletion, not
a rewrite.

**Fitness gates, answered per candidate before popularity was weighed.** Gate 1
`inapplicable — owner ruling 2026-09-12 (Q7.B)` for every row. Gate 2 (MSRV):
`cargo-dist` declares `rust_version` `1.74` and `cargo-binstall` `1.79.0`, both far under
the floor the `msrv-policy` produces — and neither is a Cargo dependency of the template, so
neither enters its MSRV surface at all. Gate 3 (advisories, `unsafe`): both tools' RustSec
package pages return HTTP 404 against a control set (`time`, `openssl`, `chrono` → HTTP
200), so 404 means "no advisory page", not "fetch failed"; `unsafe` posture is not measured
and is not reachable, because neither tool is linked into anything this template ships.
Gate 4 (OS matrix): dist is itself a cross-target build tool, but its *default* runner
labels are outside the fixed matrix and must be overridden — the row above does that. Gate
5 (default features, async coupling): `inapplicable` for both, as neither is a Cargo
dependency. Gate 6 (size and compile cost): zero bytes added to the shipped binary; N
parallel build jobs added to the release path only. **Excluded by gate:** `cross` (fails
gate 4 — it builds inside Docker containers and GitHub's macOS runners provide no container
runtime, so it cannot produce the Darwin triples); `cargo-xwin` (no Windows target exists in
the fixed matrix); `axoupdater` (fails gate 5 by scope, in both of its forms: integrated as a
library it would be a runtime dependency inside the program, and as dist's standalone
updater, enabled by `install-updater`, it is a separate `<package>-update` executable
installed beside the program — either adds an unrequested self-update surface; see the
`install-updater` row); `cargo-zigbuild` and `houseabsolute/actions-rust-cross`
(wrong layer — cross-compilation backends that still need a producer above them). For
Subject B there is no candidate to gate: the surface is Cargo's own, gates 1–5 are
`inapplicable — the decision selects values on a first-party manifest surface, not a crate`,
and gate 6 is the whole subject, answered quantitatively under `## Empirical check`.

**Fit, per surface.** *CLI* — this is where the decision has teeth, and where R49's accepted
value does the work: the shipped command is `rslbp` while the distribution name stays
`rs-launch-blueprint`, which is exactly the pair binstall's `{ name }` / `{ bin }` defaults
were built for. *Library* — a consumer depending on `rs_launch_blueprint` inherits
**nothing** from Subject B: the Cargo Book states that Cargo only reads profile settings
from the workspace-root manifest and that "Profile settings defined in dependencies will be
ignored". That is the answer to profile question 5, and it belongs in the README, because a
downstream user reading `lto = "fat"` in this manifest will otherwise assume they inherit
the build cost. *Web* — R69's accepted `web-extra-surface` adds a second binary behind
`required-features = ["web"]`; leaving dist's `features` at its default keeps that binary
out of the release archives. That disposition rests on this item's scope — the archives
serve the CLI audience, and `web` is an optional feature rather than the default build —
and should be written down rather than left to a default. It does not decide how the web
binary is delivered. That is R51's decision (F223, `DIVERGENT`,
`docs/port/COMMONALITY.md:227`), and R51 is `open` (`research/CLAUDE.md:56`) with the
question of whether an image is published at all still asked
(`research/topics/51-container-image/prompts/container-image.prompt.md`, lines 30 and 35).
If R51 publishes an image, that image is the web surface's pre-built channel. If R51
resolves F223 to no image, or to a Dockerfile documented for forks only, the web binary
has no pre-built channel, and re-verify trigger (8) re-opens this disposition.

**Minimal realistic example.** A `dist-workspace.toml` carrying the seven settings
tabulated above, a `release-please-config.json` with `"draft": true` and
`"force-tag-creation": true`, a generated and committed `.github/workflows/release.yml`,
a `[profile.release]` block of exactly two keys, a `[profile.dist]` stub reduced to
`inherits = "release"`, and a README documenting three install commands in the stated
order. No `[package.metadata.binstall]` block, recorded as a deliberate non-change so that
a later contributor who "fixes" the missing block knows it was checked against binstall's
documented defaults and found unnecessary.

**File-level changes in the template, for P03.** `Cargo.toml`: add the two-key
`[profile.release]`, with a comment recording that the four omissions are deliberate; after
`dist init`, delete the `lto` line from the `[profile.dist]` stub it writes. New file
`dist-workspace.toml`. New generated file `.github/workflows/release.yml`, committed and
not hand-edited. `release-please-config.json`: add `"draft"` and `"force-tag-creation"`.
`README.md`: the three install commands plus one sentence stating that this manifest's
`[profile.release]` governs this repository's builds and `cargo install`, and is not
inherited by a downstream application. Hand-offs recorded rather than actioned: to **R51**
the container profile coupling above, and the dependence of the `web`-binary exclusion on
F223's outcome, which re-verify trigger (8) watches; to **R50**, a conditional observation. R50 is `open`
(`research/CLAUDE.md:55`) and has no published decision. Its in-flight run decision,
`research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md` (revision 7, read
2026-09-27), is uncommitted and still changing, so no digest is pinned and every citation of
it here is anchored by quoted text rather than by line number. It currently proposes an
install smoke test that builds with `--debug`: its install command and recipe carry
`--locked --debug --no-track`, and its AC3 command is
`cargo install --path <extracted> --root <root> --locked --debug`. Its profile row calls
that a `dev-profile compile`. That
value is R50's unaccepted proposal and can still change. **If R50 keeps `--debug`**, its
smoke test does not exercise this profile at all, so nothing in pull-request CI proves the
release profile links until a release runs, and dist's own build jobs are the cheap cover.
R50's own record already names "R68's release build as the only release-profile compile the
template is currently expected to perform" and lists "(13) R68 (`release-binary-artifacts`)
resolving" as a re-verify trigger, so the coupling is recorded on both sides; re-verify trigger (7) below covers R50's side moving; to **R22**, that the installer script and the archive names encode the version
that R22's accessor must agree with; to **R49**, that this decision fires its A4 re-verify
trigger — R68 resolves F214 to cross-compiled release binaries, which is the condition R49
names (lines 889–891) under which its ranked runner-up A4, Cargo plus a `dist`
orchestration layer, wins, and R49 lists that event as a re-verify trigger requiring a
re-check of whether `dist`'s `[workspace.metadata.dist]` deprecation has become a removal
at the version R68 adopts (lines 1042–1047). That re-check at `ref=v0.33.0` is R49's to
run; this item does not decide R49's re-verification.

**Reference implementations.** `astral-sh/uv` and `astral-sh/ruff` both run dist and both
keep `[profile.dist]` empty with the real settings in `[profile.release]`;
`nextest-rs/nextest` ships `[profile.release] strip = "none"` with the stated reason that
symbols "are useful for debugging issues with nextest in the field"; `BurntSushi/ripgrep`
takes the other side of the custom-profile trade with a separate `[profile.release-lto]`.
Those manifests were read by Opus at `raw.githubusercontent.com` on 2026-09-17 and are
reported here as its practice census, not as this synthesis's own retrieval.

re-verify: on any of these mechanical triggers, whichever comes first — (1) re-run `review/evidence/artifact-sources.sh`; a `registry-gap-present=1` line for a **second** consecutive dist release promotes `at-risk` to a decision to move to the runner-up, and a `registry-gap-present=0` line permits re-verifying the maintenance state upward; check no later than the template's second release; (2) any `cargo-dist` version bump, because `dist init` regenerates the `[profile.dist]` stub and would silently restore `lto = "thin"`; (3) any change to R49's `[[bin]]` name or to the package name, which re-opens the binstall-metadata question that the `{ name }` / `{ bin }` pairing currently closes; (4) any raise of the MSRV floor under `msrv-policy`, which is also the moment to re-read the Cargo Book's `release` default block and re-run `review/evidence/profile-probe.sh` at the new toolchain with `R68_TOOLCHAIN_OVERRIDE=1` — the script then labels its log a new measurement, and what is compared with `profile-probe.r2.log` is each `ASSERT` outcome and each `DELTA` direction, never the bytes; (5) `target-os-matrix` gaining a Windows or ARM-Linux runner, which re-opens the target list; (6) F301 defining a stack-trace or symbol-bundle requirement, which re-opens `strip` and `debug`; (7) R50 being accepted, which settles or re-opens the conditional R50 hand-off, or R50's install smoke test changing its build profile away from `--debug`, which re-opens that hand-off and the claim that the incremental fat-LTO penalty lands on no pull-request CI path; (8) R51 resolving F223 to anything other than a published container image for the web-service build — no image, or a Dockerfile documented for forks only — which leaves the `web`-gated binary with no pre-built channel and re-opens the `features` / `default-features` / `all-features` row and the *Web* paragraph under *Fit, per surface*.

## Parameters

- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

`## Couplings` in `inputs/prompt.md` carries an **empty** `- owns:` line, and
`docs/port/PARAMETERS.md` registers no parameter owned by R68, so this decision writes no
`- owns` line: inventing a registry row is a registry edit, not a research finding. Both
decisions above are recorded as decision values. `CONFLICT:` lines: **none** — reached by
examination, not assumed. The consumed `build-tool-output-shape` forbids a
"build-orchestration crate": `dist` is a host executable, never a Cargo dependency of the
template, so the prohibition does not reach it. `dist-workspace.toml` **is** a second
declaration surface in R49's own terms — R49's A4 clause says that when R68 resolves F214
to cross-compiled binaries, "a second declaration surface becomes the place where the
shipped output shape is actually described" — and that is precisely why this decision hands
R49 its fired A4 re-verify trigger (see `## Decision`) rather than recording a conflict: a
fired re-verify trigger asks the owner to re-check its own decision at the adopted version,
while a `CONFLICT` line would ask a consumed value to change. No consumed value has to
change: R49's manifest target declarations, allow-list and `target/` layout stand untouched.
The one place a fixed parameter constrains the answer is `target-os-matrix` providing no
ARM Linux runner, and that is resolved by narrowing the target list rather than by asking
for the parameter to move.

Two consequences of R49's consumed `build-tool-output-shape` are load-bearing above. The
`--target` level of its documented layout (`target/<triple>/release/`) is where dist finds
cross-compiled output. The binary name `rslbp` being a different string from the package
name `rs-launch-blueprint` is what makes cargo-binstall's `{ bin }`-based `bin-dir` default
the right one and the runner-up's binary-named archive the wrong one. `msrv-policy` bears on
the decision twice: every profile key recommended or deliberately left silent predates the
resulting floor by many releases, and neither `dist` nor `cargo-binstall` enters the
template's MSRV surface, because both are host executables rather than Cargo dependencies.
`target-os-matrix` bears on it through the `[dist.github-custom-runners]` override and the
exclusion of `aarch64-unknown-linux-gnu`. `rust-edition` was the edition the probe crate was
built at throughout. `license` is recorded and, per the 2026-09-12 ruling, evaluated against
nothing. R69's `web-extra-surface` is relevant but is **not** consumed by this item's
couplings block, so it is stated in prose rather than as an `assumes` line.

## Empirical check

**Toolchain and host, revisions 2 and 4.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
`cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, LLVM 22.1.8, macOS 26.4 (25E246), Apple M4
Pro, `aarch64-apple-darwin`, 2026-09-26 (Pacific) for both. The CPU name is the probe log's
`cpu:` header (`cpu: Apple M4 Pro` in `profile-probe.r2.log` and `profile-probe.r4.log`),
which `profile-probe.sh` reads with `sysctl -n machdep.cpu.brand_string`. That field may be
unavailable: under a sandbox that denies the query, the log prints
`sysctl: sysctl fmt -1 1024 1: Operation not permitted` and an empty `cpu: ` line, as the
revision-6 empirical audit's rerun did; there `system_profiler SPHardwareDataType`
independently returned `Chip: Apple M4 Pro`. `gh version 2.101.0`. Revision 1 ran on the
same host at `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)` and `gh version 2.98.0` on
2026-09-17. Working directory for every script:
`research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/evidence/`.

**Commands executed in revision 2, and their status.**

```
./profile-probe.sh        > profile-probe.r2.log        2>&1   # exit 0, RESULT: PASS, 21 assertions
./profile-probe.sh        > profile-probe.r2-rerun-same-env.log 2>&1   # exit 0, RESULT: PASS, 21 assertions
CARGO_HOME=/tmp/s8-R68-r2-alt-cargo-home TMPDIR=/tmp/s8-R68-r2-alt-tmpdir/a-longer-scratch-path \
  ./profile-probe.sh      > profile-probe.r2-rerun-alt-paths.log 2>&1  # exit 0, RESULT: PASS, 21 assertions
./artifact-sources.sh     > artifact-sources.r2.log     2>&1   # exit 0, RESULT: PASS, 26 assertions
./decision-self-check.sh  > decision-self-check.r2.log  2>&1   # exit 0, RESULT: PASS, 26 assertions
```

**Commands executed in revision 3, and their status.**

```
./decision-self-check.sh  > decision-self-check.r3.log  2>&1   # exit 0, RESULT: PASS, 27 assertions
```

**Commands executed in revision 4, and their status.** All three scripts were re-run on
2026-09-26 (Pacific) with the private `CARGO_HOME` `/tmp/cargo-s25-R68-r4` and the default
macOS `$TMPDIR`:

```
./artifact-sources.sh     > artifact-sources.r4.log     2>&1   # exit 0, RESULT: PASS, 26 assertions
./profile-probe.sh        > profile-probe.r4.log        2>&1   # exit 0, RESULT: PASS, 21 assertions
./decision-self-check.sh  > decision-self-check.r4.log  2>&1   # exit 0, RESULT: PASS, 28 assertions
```

`artifact-sources.r4.log` differs from `artifact-sources.r2.log` in the `date(UTC):` line
only. `profile-probe.r4.log` meets the reproduction rule below against `profile-probe.r2.log`:
every `DELTA`, `BACKTRACE` and `ASSERT` line is byte-identical, and one `SIZE` line differs
(the path effect, tabulated below). `profile-probe.sh` and `artifact-sources.sh` are
unchanged in revision 4, and every figure this decision cites keeps its home in the r2 logs
(sizes, deltas, backtraces) and in `artifact-sources.log` (2026-09-17 retrievals); the r4
logs add one build-time row and confirm the rest. `decision-self-check.sh` makes two
changes: the title assertion now names revision 4, and a revision-3 snapshot assertion was
added, hence 28 assertions. `shellcheck` 0.11.0 reports nothing on all three
scripts. Revision 3's `decision-self-check.r3.log` is kept unchanged beside it as history.

**Commands executed in revision 5, and their status.** Only the self-check was re-run, on
2026-09-27; revision 5 is a prose revision, and no line any figure is cited from moved:

```
./decision-self-check.sh  > decision-self-check.r5.log  2>&1   # exit 0, RESULT: PASS, 29 assertions
```

`decision-self-check.sh` makes two changes: the title assertion now names revision 5, and a
revision-4 snapshot assertion was added, hence 29 assertions. `shellcheck` 0.11.0 reports
nothing on it. `profile-probe.sh` and `artifact-sources.sh` are unchanged and were not
re-run; their r2 and r4 logs remain the evidence. Revision 4's `decision-self-check.r4.log`
is kept unchanged as history.

**Commands executed in revision 6, and their status.** Revision 6 is a prose revision.
Only the self-check was re-run, on 2026-09-27, after the last edit to this file:

```
./decision-self-check.sh  > decision-self-check.r6.log  2>&1   # exit 0, RESULT: PASS, 30 assertions
```

`decision-self-check.sh` makes two changes: the title assertion now names revision 6, and a
revision-5 snapshot assertion was added, hence 30 assertions. `shellcheck` 0.11.0 reports
nothing on it. The `install-updater` row's two dist pages were read on 2026-09-27 at
`ref=v0.33.0` with `gh api -H 'Accept: application/vnd.github.raw'
'repos/axodotdev/cargo-dist/contents/<path>?ref=v0.33.0'`; the bodies retrieved hash to
sha256 `1b45ad791749e55df2ed18267f5dcd104e961170cec3402c994bce3482d2d2a6`
(`book/src/reference/config.md`, the same file `artifact-sources.sh` already retrieves) and
`b63bd80f0b60991197eac77a923309d03ce733c0e0508d8950ca3cca3729503c`
(`book/src/installers/updater.md`, which no evidence script retrieves).
`profile-probe.sh` and `artifact-sources.sh` are unchanged and were not re-run. Revision 5's
`decision-self-check.r5.log` is kept unchanged as history.

The first probe run used the private `CARGO_HOME` set for this session
(`/tmp/cargo-s8-R68-r2`) and the default macOS `$TMPDIR`; the second repeated it unchanged. The
third changed only the two paths shown. `shellcheck` 0.11.0 reports nothing on
`profile-probe.sh` or `decision-self-check.sh`. Revision 1's logs `profile-probe.log`,
`artifact-sources.log` and `decision-self-check.log` are unchanged.

None of the three builds the thing being recommended. `profile-probe.sh` builds a
throwaway stand-in crate under a directory it creates below `$TMPDIR` and deletes on exit,
to decide whether the raws' profile claims are true. `artifact-sources.sh` only queries
endpoints. `decision-self-check.sh` reads this decision back against the registry, the
ledger, the prompt and the owner reference, and is the check an auditor should run first.
Its 30 assertions, as of revision 6: the H2 set and its order; the presence of the
`### Principles and implementation` H3; the absence of a `## Supersedes` section; that the
title names revision 6; that `review/R68-r1-snapshot.md`, `review/R68-r2-snapshot.md`,
`review/R68-r3-snapshot.md`, `review/R68-r4-snapshot.md` and `review/R68-r5-snapshot.md`
hash to the audited revision-1, revision-2, revision-3, revision-4 and revision-5 digests; the presence of the `re-verify:` line; that the prompt's `- owns:` line is empty
and this decision therefore writes none; that the registry records no R68-owned parameter;
that the prompt consumes exactly R49's `build-tool-output-shape`; that each of the five
`- assumes` lines is byte-identical to its registry row (one assertion per line) and that the
set carries no backticks (one more); that
`docs/port/COMMONALITY.md` lines 218, 224 and 78 are the F214, F220 and F072 rows cited
above; that both owner-review sections exist; that the owner reference really does state
`lto = "thin"` / `codegen-units = 1`, really does carry its own "compiled in my head, not
against the toolchain" caveat, and really does contain the container rows handed to R51;
that `profile-probe.r2.log` prints the sha256 of the committed `profile-probe.Cargo.lock`
and ends `RESULT: PASS`; and that no email address appears anywhere under `review/`. Nothing was written into the repository outside `review/`, and no template
scaffold, workflow, seam or fixture was created. All three scripts run from a clean
`git archive HEAD` extraction: none reads `.git`, the probe's lockfile sits beside it, and `decision-self-check.sh` exits with a
named `SKIP` message if any file it reads is absent from the extraction.

**What `profile-probe.sh` measured.** The stand-in is a two-binary, one-library crate named
`rs-launch-blueprint`, edition 2024, `rust-version = "1.96"`, `autobins = false`, mirroring
R49's target shape (`[lib] rs_launch_blueprint`, `[[bin]] rslbp`, `[[bin]] rslbp-serve` with
`required-features = ["web"]`) and R69's feature shape (`web = ["dep:axum", "dep:tokio"]`).
The whole graph is pinned by `profile-probe.Cargo.lock` (85 packages). Direct dependencies:
`anyhow 1.0.104`, `clap 4.6.7`, `serde 1.0.229`, `serde_json 1.0.151`, `thiserror 2.0.20`,
`tracing 0.1.44`, `tracing-subscriber 0.3.23`, `axum 0.8.9`, `tokio 1.53.1`, the same nine
versions revision 1 recorded. The graph has **52** unique `cargo tree` lines at default
features and **93** with `--all-features`. **Its unlikeness to the template is stated:** it has a port
trait, an in-memory adapter, a clap parser and three axum routes, but no domain logic, no
error catalog, no config layering and no observability stack, so it is *smaller* than the
template will be — every absolute byte count is a floor and every percentage is the
transferable figure. Each row is one clean build into a fresh `CARGO_TARGET_DIR` with
`cargo build --release --locked --offline --features web` and `--config
'profile.release.<key>=<value>'` overrides, so no two rows differ by a manifest edit. The
measured binary is `rslbp`. Figures below are `profile-probe.r2.log`; the last column is
revision 1's `profile-probe.log` at 1.98.0, for comparison.

| Row | `rslbp` bytes | Δ vs baseline | after external `strip -S -x` | revision 1 Δ |
|---|---|---|---|---|
| **baseline (Cargo `release` defaults)** | **1 994 032** | — | 1 628 360 | — |
| `lto = "thin"` | 1 968 928 | −1.3% | 1 603 320 | −1.3% |
| `lto = "fat"` | 1 598 560 | −19.8% | 1 297 032 | −19.8% |
| `codegen-units = 1` | 1 697 232 | −14.9% | 1 430 312 | −14.9% |
| `lto = "thin"` + `codegen-units = 1` (**the owner reference's row**) | 1 675 728 | −16.0% | 1 423 160 | −16.0% |
| `lto = "fat"` + `codegen-units = 1` (**recommended**) | 1 504 528 | **−24.5%** | 1 230 568 | −24.5% |
| `opt-level = "s"` | 2 252 048 | **+12.9%** | 1 993 512 | +13.0% |
| `opt-level = "z"` | 2 428 208 | **+21.8%** | 2 018 504 | +21.8% |
| `strip = "symbols"` | 1 537 408 | −22.9% | — | −22.9% |
| `strip = "debuginfo"` | 1 994 032 | **0.0%** (byte-identical no-op) | 1 628 360 | 0.0% |
| `panic = "abort"` | 1 590 384 | −20.2% | 1 296 488 | −20.3% |
| `debug = "line-tables-only"` | 2 242 552 | +12.5% | 1 628 280 | +12.5% |

Backtrace and exit status of the **built** binary, `RUST_BACKTRACE=1 rslbp panic`:

| Profile | frames | exit |
|---|---|---|
| baseline | 4 | 101 |
| `lto = "fat"` + `codegen-units = 1` (recommended) | 4 | 101 |
| `strip = "symbols"` | **0** | 101 |
| `panic = "abort"` | 2 | **134** |
| `debug = "line-tables-only"` | 5 | 101 |

and, for `debug = "line-tables-only"`, `at ./src/…` lines: **2** while the binary sits in
its build tree, **0** once it is copied out and `target/` is deleted.

**Build time, and the honest limit on it.** Six full runs now exist, and each gives a
clean build (baseline → recommended) and a bin-only rebuild after touching `src/main.rs`
(baseline → recommended). The fourth column is the marginal clean build from the owner
reference's row to the recommended row, read from the same log's `TIME thin+cu1` and
`TIME fat+cu1` lines; the probe measures no incremental time for `thin` + cu1 (see *What is
unproven* under `## Engines`):

| Run | Toolchain | Clean build | Clean, `thin` + cu1 → `fat` + cu1 | Bin-only rebuild |
|---|---|---|---|---|
| revision 1, run 1 (`profile-probe.log`) | 1.98.0 | 17 s → 23 s | 18 s → 23 s | 1 s → 11 s |
| revision 1, run 2 (log not kept) | 1.98.0 | 14 s → 24 s | — | 0 s → 11 s |
| revision 2 (`profile-probe.r2.log`) | 1.98.1 | 17 s → 25 s | 18 s → 25 s | 1 s → 12 s |
| revision 2, same environment (`profile-probe.r2-rerun-same-env.log`) | 1.98.1 | 16 s → 30 s | 19 s → 30 s | 1 s → 13 s |
| revision 2, other paths (`profile-probe.r2-rerun-alt-paths.log`) | 1.98.1 | 18 s → 24 s | 20 s → 24 s | 1 s → 12 s |
| revision 4 (`profile-probe.r4.log`) | 1.98.1 | 16 s → 25 s | 18 s → 25 s | 0 s → 12 s |

**Only the incremental separation is a claim this decision makes**: roughly an order of
magnitude in all six runs, in the direction Opus reported. The clean-build ratio spans about
1.3× to 1.9× across the six runs, and the marginal `thin` → `fat` clean ratio about 1.2× to
1.6× across the five kept logs. The clean-build ratio's upper end approaches the "roughly doubles" Opus
reported, and its lower end does not. That spread is wide enough that this synthesis records
the disagreement rather than resolving it, and treats the clean-build cost as "materially
longer" instead of a number. Nothing in the recommendation turns on which figure is right.
Two costs are weighed separately. **The clean-build cost** — against the owner reference's
row, the marginal 1.2× to 1.6× above (18 s → 25 s in `profile-probe.r2.log`) — is paid by
two populations. The release build pays it once per release. Every source installer pays it
once per installed version: a `cargo install --locked` user (README install path 3), since
`cargo install` builds under the package's `release` profile, and a cargo-binstall user on
a target outside the three shipped triples, whom binstall falls back to compiling (its
`compile` strategy; see AC2). That cost is accepted because the three shipped triples cover
the default audience with no compile at all, a source installer pays it once per version
rather than per use, and the size gain lands on every download. **The incremental penalty**
lands only on `--release` rebuilds. The contributor loop uses the dev profile. R50's install
smoke test, as R50's current unaccepted proposal stands, builds with `--debug` (R50 run
decision revision 7, read 2026-09-27: `--locked --debug --no-track`, a
`dev-profile compile`; see the R50 hand-off under `## Decision`), so it does
not pay this penalty either; if R50 changes that profile, re-verify trigger (7) applies.

**What `artifact-sources.sh` verified,** with every figure carrying its endpoint and the
retrieval date 2026-09-17. Twenty-six assertions passed, each asserting on *content*
rather than on an exit code: the Cargo Book's `.crate`, dependency-profile-ignored,
`split-debuginfo unpacked` and `inherits` statements; dist's `create-release = false`
undrafting sentence and its pinned-point-release runner map (`ubuntu-latest` count **0**)
including the ARM Linux label that excludes `aarch64-unknown-linux-gnu` from the fixed
matrix; the documented `global` key inside `[dist.github-custom-runners]` that the
recommended configuration pins; the `[profile.dist] inherits = "release" / lto = "thin"`
stub in dist's own book, and the 2023-era `# Version 0.0.3` changelog entry that is the
real home of the "delete `[profile.dist]`" instruction;
dist's generated workflow installing dist from its GitHub Release installer script and
**not** from crates.io (`cargo install cargo-dist` count **0**) — the bootstrap version that
workflow actually fetches at `ref=v0.33.0` is **`v0.32.0`** (`release.yml` line 67,
`v0.32.0/cargo-dist-installer.sh`, read 2026-09-27), which the script does not yet print
(deferred to the next evidence revision; see the revision note); the 23-asset list of
dist's `v0.33.0` release; cargo-binstall's documented versionless `{ name }-{ target
}{ archive-suffix }` filename default and `{ bin }{ binary-ext }` `bin-dir` default; the
runner-up's `$bin-$target` archive default; release-please's `draft` and
`force-tag-creation` keys with the quoted reason; the RustSec control pair; and the two
tools' declared `rust_version` floors. `gh` was already authenticated and no token or
environment was printed. Revision 2 re-ran the script on 2026-09-26 into
`artifact-sources.r2.log`: 26 assertions passed, and `registry-gap-present=1` still holds
(dist's newest non-prerelease GitHub release is still `v0.33.0`; crates.io still has no
`0.33.0`). The figures this decision cites keep their 2026-09-17 retrieval date and their home
in `artifact-sources.log`. Drift observed on 2026-09-26 includes one fact a reader should know:
cargo-binstall `1.24.0` was published 2026-09-26, with the same declared `rust_version`
`1.79.0`. The `1.23.0` named under `## Decision` is an acceptance baseline, a floor, so a newer
release does not move it.

**Reproduction rule, stated after re-running each script against the exact log committed
beside it.** `artifact-sources.sh` was re-run against the committed `artifact-sources.log`
and the two were diffed: **exactly one line differed, the `date(UTC):` line** — all 26
`ASSERT` lines and every `PINNED`, `HEAD` and `FIGURE` line were byte-identical. That is not a promise that it
always will be: `FIGURE` lines carry live counters (download totals, star counts, open-issue
totals, `pushed_at`) and `HEAD` lines carry a moving default-branch commit sha, so those
lines will drift; the script prints the resolved sha and quotes the matched text beside each
`HEAD` line precisely so the bytes relied on stay in the log after the branch moves.
`PINNED` lines read immutable tag refs and reproduce for as long as the tag exists.
Revision 1 said that a rerun of `profile-probe.sh` reproduced every `SIZE`, `DELTA`,
`BACKTRACE` and `ASSERT` line byte-for-byte. **The revision-1 audit showed that this was
false for an independent rerun**, and revision 2 withdraws it. What byte identity depends
on was measured. Each comparison below states what differed between the two runs and the
largest `DELTA` difference on any of the twelve rows:

| Comparison | What differed | Largest `DELTA` difference |
|---|---|---|
| `profile-probe.r2.log` vs `profile-probe.r2-rerun-same-env.log` | nothing but the clock | **0.0 pp**: every `SIZE`, `DELTA`, `BACKTRACE` and `ASSERT` line byte-identical |
| `profile-probe.r2.log` vs `profile-probe.r2-rerun-alt-paths.log` | `CARGO_HOME` and `TMPDIR` paths | **0.8 pp** (`lto = "fat"`, −19.8% → −19.0%); `debug = "line-tables-only"` grew 576 bytes with an unchanged `DELTA` |
| `profile-probe.log` (revision 1) vs `profile-probe.r2.log` | rustc 1.98.0 → 1.98.1, both Homebrew; transitive graph; paths | **0.1 pp** (`opt-level = "s"`, `panic = "abort"`) |
| `raw/opus.md` lines 463–476 vs `profile-probe.r2.log` | Opus's own session at Homebrew 1.98.0 on the same machine model; its own graph and paths | **1.0 pp** (`lto = "fat"`, −18.8% against −19.8%) |
| `profile-probe.r2.log` vs `profile-probe.r4.log` | `CARGO_HOME` path (`/tmp/cargo-s8-R68-r2` → `/tmp/cargo-s25-R68-r4`) | **0.0 pp**: every `DELTA`, `BACKTRACE` and `ASSERT` line byte-identical; `debug = "line-tables-only"` grew 96 bytes |
| `review/audit-claude.r1.md` runs 3c/3d vs revision 1 | rustup's 1.98.0 distribution instead of Homebrew's; graph; paths | **2.0 pp** (`debug = "line-tables-only"`, +12.5% → +14.5%) |

So a pinned lockfile makes a same-environment rerun byte-identical, and absolute build
paths alone are enough to move a row by 0.8 pp. Paths are deliberately **not** remapped
(`--remap-path-prefix` or `trim-paths`), because the `at ./src/` check depends on unremapped
in-tree source paths, and remapping would change what that check measures.
**Reproduction rule, as revision 2 states it.** An independent rerun at the pinned toolchain
with the committed lockfile must reproduce every `ASSERT` outcome and every `BACKTRACE`
line exactly, and every `DELTA` to within **±2.5 percentage points**. The tolerance is an
estimate, not a measured bound: the largest difference observed is 2.0 pp, and 0.5 pp is
headroom. `SIZE` lines are not expected to match. Header lines are not compared either: the
`date(UTC):` line always differs, and the `cpu:` line may be empty, preceded by a `sysctl`
"Operation not permitted" line, when the environment denies
`sysctl -n machdep.cpu.brand_string` (see the host paragraph above); confirm the host with
`system_profiler SPHardwareDataType` instead. Compare `ASSERT` outcomes, not `ASSERT`
text, because the text embeds percentages. Every threshold assertion clears its threshold by
more than the tolerance: `fat+cu1` sits 4.5 pp past the 20% line and `thin+cu1` 4.0 pp short
of it, `lto = "thin"` 3.7 pp inside its 5% bound, and `strip = "symbols"` 7.9 pp past its
15% bound. The `strip = "debuginfo"` byte-identity assertion held in every run, including the
audit's. This is why this decision states size deltas as measurements with a stated
tolerance, and build times as a range with their spread shown. `decision-self-check.r6.log` was produced by the last run of that script
against the final bytes of this file; it reproduces except for its `date(UTC):` line and the
byte count it prints for `DECISION.md`, which changes whenever this file is edited — so a
mismatch there is the intended signal that the decision changed after its self-check ran,
and the fix is to re-run the script, not to edit the log.

## Engines

- Claude Opus 5 `raw/opus.md` (sha256 `b75fa7ab…`, 15 H3 sections) — one of two engines
  that measured profiles, the other being Codex below. Its macOS figures (`raw/opus.md`
  lines 463–476, Homebrew 1.98.0) were
  reproduced independently here to within one percentage point on every profile row, by
  revision 1 at 1.98.0 and again by revision 2 at 1.98.1. The largest gap is `lto = "fat"`
  alone, −19.8% here against Opus's −18.8%, and the recommended row differs by 0.1 pp
  (−24.5% against −24.4%). Every directional finding it reported
  (`"fat"` beats `"thin"`; `"s"`/`"z"` are larger, not smaller; `strip` empties the
  backtrace; `strip = "debuginfo"` is a no-op on `release`; macOS line tables do not travel)
  reproduced exactly.
- Doxa `raw/doxa.md`, with the normalized twins `raw/doxa.normalized.md` and
  `raw/doxa-{openai,perplexity,gemini}.normalized.md` (operation
  `research-20260916-220422-5fd5c62e52434fa9`).
- Codex `raw/codex.md` (sha256
  `297219edca2cbdaf2ce69069cf5a9bd562796daa4da5376c1e5b9ead80ae699b`, 48 183 bytes) —
  model `gpt-5.6-terra` via `codex-cli-0.155.1`, submitted 2026-09-20, collected
  2026-09-21 (`operations/codex.json`, state `succeeded`). Revision 2 misrecorded this
  report as absent; the W1-CODEX deferral had lapsed when the leg was submitted
  successfully under the W1-CODEX3 use-if-available rule, and revision 3 corrects the
  record. Codex is the second engine that measured profiles: an edition-2024 stand-in
  (`r68-profile-probe`, 12 direct dependencies, 162 locked packages) at Homebrew rustc
  1.98.0 on Apple M4 Pro, one sample per row with `CARGO_INCREMENTAL=0`, plus a
  policy-floor check at rustc 1.96.0. Positions: dist `0.32.0` (approved line
  `>=0.32.0, <0.33.0`); four targets including `aarch64-unknown-linux-gnu`;
  `lto = "thin"` + `codegen-units = 1` + `strip = "symbols"`; `[profile.dist]
  inherits = "release"`; cargo-binstall mentioned only after the smoke proves it;
  runner-up crates.io-only; maintenance `active` with a backlog caveat. All figures
  retrieved 2026-09-21 UTC.

**Disagreements between engines, and the evidence that settled each.**

1. **`lto = "fat"` (Opus) versus `lto = "thin"` (all three Doxa providers, agreeing with the
   owner reference; Codex, on its own measurement).** Settled by measurement, executed in six runs across two toolchains (two at 1.98.0 in
   revision 1, three at 1.98.1 in revision 2, one at 1.98.1 in revision 4): in every one, `"thin"` + `codegen-units = 1`
   reaches −16.0% where `"fat"` + `codegen-units = 1` reaches −24.5% on the same stand-in, and `"thin"` alone reaches −1.3%. Doxa/Perplexity and Doxa/OpenAI
   both state plainly that they executed no build; Doxa/Gemini presents a measurement table
   at `rustc 1.81.0` with a 36.2 MB baseline binary and "approximately 120 transitive
   dependencies", a toolchain and a magnitude that neither this run nor Opus's reproduces,
   so its figures are not used. Codex measured the same direction on a different stand-in
   (162 packages, rustc 1.98.0, one sample per row): `fat` + one unit is 486 592 bytes
   smaller than `thin` + one unit (3 156 320 against 3 642 912), and `thin` alone is −1.7%
   against −1.3% here — noise-level on both stand-ins. Codex nevertheless recommends
   `thin` as the size/time balance. Its cost figures are the **marginal** cost of moving
   from `thin` + one unit to `fat` + one unit — from the owner reference's row to the
   recommended row — and not a baseline → recommended figure: clean 28.22 s → 47.39 s
   (~1.7×) and edit rebuild 7.35 s → 18.99 s (~2.6×) (`raw/codex.md` lines 588–589, restated
   at line 311). This item measured the same marginal clean step in every kept log:
   18 s → 25 s in `profile-probe.r2.log` (lines 42 and 44), and 18 s → 23 s, 19 s → 30 s,
   20 s → 24 s and 18 s → 25 s in the other four kept logs — about 1.2× to 1.6× (the
   `thin` + cu1 column of the build-time table under `## Empirical check`). Codex's
   1.7× sits at or just above the top of that range, so it is new cost information, and it
   points the same way as this item's own figures: `fat` costs more build time than `thin`.
   No run in this item measured the marginal *incremental* cost (see *What is unproven*),
   so Codex's 2.6× edit-rebuild figure is the only such measurement on record and the
   strongest number against `fat`. Weighed explicitly against what it buys — 8.5
   percentage points of the baseline (−16.0% → −24.5%, 171 200 bytes on this stand-in;
   486 592 bytes, 13.4% of the `thin` + one-unit binary, on Codex's). The extra clean-build
   time falls on the release build once per release and on every source installer once per
   installed version — `cargo install --locked` users and cargo-binstall users on a target
   outside the three shipped triples, whom binstall falls back to compiling. The extra
   incremental time falls only on `--release` rebuilds, which the contributor loop (dev
   profile) does not perform, and which R50's install smoke test does not perform either
   while R50's unaccepted proposal keeps `--debug` (R50 run decision revision 7, read
   2026-09-27: `--locked --debug --no-track`, a `dev-profile compile`; re-verify trigger
   (7)). The size gain lands on every download, and the three shipped
   triples serve the default audience with no compile, so the source-install cost is
   accepted as a one-time cost per version. **Opus's direction is adopted; `lto = "fat"`
   stands.**
2. **`strip = "debuginfo"` (Doxa/Gemini, which claims it "drops the massive DWARF tables
   … but crucially retains function line numbers") versus leaving `strip` silent (Opus,
   Doxa/Perplexity); Codex writes `strip = "symbols"`.** Settled by measurement: on the `release` profile
   `strip = "debuginfo"` produced a binary **byte-identical** to the baseline — 1 994 032
   bytes both times in `profile-probe.r2.log` (1 994 112 in revision 1's log) — because `release` carries no debuginfo to remove. Gemini's claimed
   ~8 MB saving does not exist on this profile. Codex's `strip = "symbols"` is the largest
   reduction on its stand-in too (3 642 912 → 2 923 344 bytes), and its premise is correct:
   R67's crash record requires no stack trace and F301 is open. It is still refused,
   because Codex measured no backtrace and this item did: with `strip = "symbols"` the
   built binary's panic backtrace is zero frames against 4 named frames at the recommended
   profile, which fails AC4 and essential behavior (4) — a requirement this decision
   asserts with its own evidence rather than inheriting from R67. **Opus is adopted;
   `strip` stays silent.**
3. **Writing `strip = "none"` and `panic = "unwind"` explicitly (Doxa/OpenAI) versus leaving
   both silent (Opus).** Not settled by measurement — both produce identical binaries, since
   the written values *are* the defaults. Settled on the prompt's own instruction to state
   "why silence is the better record for that key": a written key reads as a decision that
   was measured against an alternative, and re-litigating it later requires re-deriving the
   default. The decision instead records the two refusals in prose and in a manifest comment.
   This is a judgement, not a finding, and is flagged as such. (Codex agrees with the
   silence side: it deliberately omits `opt-level`, `debug` and `panic` as redundant
   lines.)
4. **A separate `[profile.dist]` carrying the aggressive settings (Doxa/Gemini) versus a
   settings-free `[profile.dist]` adapter that dist "generally refuses to run without"
   (Doxa/OpenAI) versus no custom profile at all, with any generated stub trimmed (Opus);
   against Doxa/Perplexity's report that dist's 0.32.0 changelog tells users to *delete*
   `[profile.dist]`.** Partly settled: dist's own book at `ref=v0.33.0` still shows the
   generated stub as `[profile.dist] inherits = "release" / lto = "thin"` and still gives
   the rationale for a separate profile, so OpenAI's premise that a stub exists is correct
   at the tag evaluated, while Gemini's proposal to put the aggressive settings *in* it is
   rejected on the divergence argument (CI would then ship a binary compiled differently
   from the one a contributor tested and from the one `cargo install` produces).
   **Unresolved and recorded:** whether dist 0.33.0 *requires* the stub was not tested —
   dist was never executed in this item — so the decision says "trim the stub if `dist init`
   writes one" rather than "delete it", and AC6 plus the guard check below are the executable
   form of it. Codex agrees on the stub's *content* — its `[profile.dist]` carries only
   `inherits = "release"`, because "cargo-dist always builds with profile dist" — and on the
   cache-separation cost (`target/dist` versus `target/release`); it differs only in writing
   the stub pre-emptively rather than conditionally. The conditional stands, because the
   requirement is what is unproven, not the content. **Perplexity's changelog claim is settled and is a misattribution:** the
   instruction "(optional) delete `[profile.dist]` from your Cargo.toml" appears once in
   dist's `CHANGELOG.md` at `ref=v0.33.0`, at line 2274, and the nearest preceding
   `# Version` heading above it is `# Version 0.0.3 (2023-02-27)` — a 2023 migration note,
   not 0.32.0 advice (`artifact-sources.log`, section C).
5. **Four targets including `aarch64-unknown-linux-gnu` (Doxa/OpenAI; Codex) versus three (Opus).**
   Settled at dist's source: `cargo-dist/src/backend/ci/github.rs` at `ref=v0.33.0` maps the
   ARM Linux target to `ubuntu-22.04-arm`, and the fixed `target-os-matrix` names no ARM
   Linux runner. **Three targets.** Codex's rationale — serve users, not only CI
   contributors — is heard, but neither Codex nor OpenAI shows the fourth triple building
   on the fixed labels, and the fixed matrix binds the producer. The widening is documented
   (add the runner label, add the triple), not forbidden.
6. **An explicit `[package.metadata.binstall]` block (Doxa/OpenAI; Doxa/Perplexity warns
   configuration "may be needed") versus none (Opus, Doxa/Gemini).** Settled at
   cargo-binstall's own `SUPPORT.md`: its default GitHub filename list includes the
   versionless `{ name }-{ target }{ archive-suffix }` form, which is exactly the shape of
   dist's observed `cargo-dist-<triple>.tar.xz` assets, and its default `bin-dir` concatenates
   `{ bin }{ binary-ext }`. **No block.** Note that Perplexity's asserted convention
   `<name>-<version>-<target>` is *also* on binstall's default list, so its caution was
   directionally right and its conclusion unnecessary. (Codex agrees: no metadata by
   default, with `bin-dir = "{bin}"` as the fallback if the smoke fails — the same repair
   AC2 prescribes.)
7. **dist cross-compiles "via `cargo-zigbuild`" (Doxa/Gemini).** Settled at the source:
   `cargo-zigbuild` appears **0** times in dist's user-facing configuration reference and
   appears in its CI backend only inside a conditional `CargoBuildWrapper::ZigBuild` guard —
   an opt-in wrapper dist installs when a target demands one, not the mechanism the three
   recommended natively-built targets use. **Gemini's claim overstates it.**
8. **`release-plz` as a challenger (Doxa/Gemini, Doxa/OpenAI).** Not contested: both
   providers reach the same conclusion this decision does — it orchestrates releases and
   delegates binary production, so it is a possible replacement for release-please, which
   F063–F077 already settle, and not a replacement for the producer this item chooses.
9. **The clean-build cost of fat LTO.** Opus reported that it "roughly doubles" the clean
   release build. Six runs measured 17 s → 23 s, 14 s → 24 s, 17 s → 25 s, 16 s → 30 s,
   18 s → 24 s and 16 s → 25 s: a ratio between roughly 1.3× and 1.9×. Codex's stand-in measured
   29.04 s → 47.39 s (~1.6×) from Cargo's `release` defaults to `fat` + one unit
   (`raw/codex.md` lines 584 and 589), inside that spread; the revision-2 empirical audit's
   independent rerun measured ~2.4×, outside it (`review/audit-claude.r2.md`, §1c).
   **Not settled**, and the decision carries no numeric clean-build claim as a result.
10. **The dist pin: `0.32.0` with approved line `>=0.32.0, <0.33.0` (Codex) versus `0.33.0`
    (this decision).** Codex "cannot substantiate 0.33.0" because it read only the
    crates.io versions endpoint, where `0.32.0` (2026-05-22) is the newest non-yanked
    release. Answered at the source Codex did not query: `v0.33.0` exists as a GitHub
    Release (published 2026-09-11T05:40:23Z), and dist's generated workflow installs dist
    from that release's `cargo-dist-installer.sh`, never from crates.io
    (`artifact-sources.log`, section C) — so the registry gap Codex observed is real (it
    is this decision's `at-risk` signal) but does not block the pin. Codex's own re-verify
    trigger — "0.33.0 or another newer line becomes available" — is satisfied in fact.
    **`0.33.0` stands.**
11. **README order: cargo-binstall mentioned only after the smoke proves it (Codex) versus
    binstall listed first (this decision).** The disagreement is presentation order, and
    both sides agree proof is required: AC2 — `cargo binstall --dry-run` resolving the
    `crate-meta-data` strategy on both fixed runners — *is* the proof Codex demands. The
    order stands because the documented default must name the no-toolchain path first
    (essential behavior 1); if AC2 fails, the fallback metadata Codex prescribes
    (`bin-dir = "{bin}"`) is exactly the documented repair.
12. **Ranked runner-up: crates.io-only (Codex) versus `taiki-e/upload-rust-binary-action`
    (this decision).** Codex's runner-up is this decision's *second* runner-up, and the
    winning conditions align: P03 cannot demonstrate dist's generated follower workflow at
    acceptable cost, or the audience is exclusively Rust developers. The ranking stands
    because Codex never evaluates the single-purpose Action — its shortlist has no such
    row, and its bespoke-workflow exclusion argues against hand-written matrices generally
    without engaging the Action's ~25-line cost or its binary-named archive price (the
    `$bin-$target` paragraph in `## Decision`). Recorded as agreement on the fallback, not a dispute.
13. **Maintenance state: `active` with a backlog caveat, "not at-risk" (Codex) versus
    `at-risk` (this decision).** Different signals. Codex's responsiveness sample
    (2026-09-21: 2 of 10 answered, median 0.335 days, current commits) postdates Opus's
    (10 of 10 unanswered) and softens the silence signal — recorded, not suppressed. It
    does not touch the publication gap (`0.33.0` current on GitHub, absent from crates.io),
    which is the signal this decision's `at-risk` rests on. Codex itself demands a
    release-time recheck of the version and generated workflow, which is convergent
    caution under a different label. **`at-risk` stands**, with re-verify trigger (1) as
    the exit.

**What is unproven, and what would prove it.** These are left for P03 to prove in the real
template, and are the checks that must pass before the recommendation is considered
validated.

- **`dist` was never executed in this item.** Its behaviour is taken from its documentation
  and source read at `ref=v0.33.0`. Proof: `dist plan --output-format=json` in CI on every
  pull request touching `dist-workspace.toml`, asserting a manifest naming exactly three
  archives and one installer.
- **The release-please → dist hand-off is a reasoned composition, not a documented
  integration.** Neither project documents the other; both halves (`create-release = false`;
  `draft` + `force-tag-creation`) were read at their own maintainers' sources. Proof: after a
  release, `gh api repos/<o>/<r>/releases/tags/v<X.Y.Z>` asserted against the AC1 asset set
  with `.draft == false`, and asserted to have been created exactly once.
- **cargo-binstall's inference was never exercised against a real release.** The
  zero-metadata conclusion rests on binstall's documented defaults plus dist's observed asset
  names. Proof: `cargo binstall --no-confirm --dry-run rs-launch-blueprint` on
  `ubuntu-latest` and `macos-latest` after a release, asserting the resolved strategy is
  `crate-meta-data` rather than `compile` — this is AC2.
- **Whether dist 0.33.0 requires a `[profile.dist]` stub.** Proof: AC6 — a guard asserting
  that no `[profile.dist]` key other than `inherits` exists, so a later `dist init` cannot
  silently restore `lto = "thin"`.
- **No `x86_64` binary of any kind was built here**, and no measurement was taken on
  `ubuntu-latest`'s actual architecture. Every absolute byte count above is an `aarch64`
  Darwin figure. **The Linux figures in `raw/opus.md` are Opus's, taken inside an
  `aarch64` Docker Desktop VM on Apple Silicon rather than on a bare `x86_64` runner, and
  were not reproduced here**; this decision cites none of them as its own, and relies on
  Linux only for the direction Opus recorded (notably `debug = "line-tables-only"` costing
  +550.8% there against +12.5% here, the ELF-embedded-DWARF versus macOS
  `split-debuginfo = unpacked` asymmetry). Proof: run `profile-probe.sh`'s equivalent on an
  `ubuntu-latest` runner in P03's CI.
- **The probe's toolchain-selection route and the distribution effect were not exercised
  in revision 2.** `R68_TOOLCHAIN=<version>` (run through `rustup run`) was written but
  never run, because installing a matching rustup toolchain needs `static.rust-lang.org`,
  which is outside this item's endpoints. The 2.0 pp distribution-plus-graph difference is
  the revision-1 audit's measurement, and that audit did not separate its causes. Revision 2
  separated only the path effect (0.8 pp). Proof: run
  `R68_TOOLCHAIN=1.98.1 ./profile-probe.sh` after `rustup toolchain install 1.98.1`, and
  check the result against the ±2.5 pp rule.
- **Incremental build wall time was measured for two of the twelve settings only.** The
  prompt (line 59) asks for clean and incremental wall time per build, once per setting
  under test. `profile-probe.sh` records a clean time for every row, but it rebuilds after
  touching `src/main.rs` only for the baseline and recommended profiles
  (`profile-probe.r2.log` lines 102–104), because those are the only two target
  directories it keeps. No incremental figure exists here for the other ten rows — in
  particular none for `lto = "thin"` + `codegen-units = 1`, the owner reference's row and
  the one alternative this decision argues against partly on build time. The only
  incremental measurement of that row on record is Codex's: 7.35 s, against 18.99 s for
  `fat` + one unit (`raw/codex.md` lines 588–589), on a different stand-in and reported as
  Codex's measurement, not this item's. Proof: have the probe keep every row's target
  directory and rebuild each after the same touch, in P03 against the real template.
- **The stand-in is not the template.** 52 unique `cargo tree` lines at default features,
  93 with `--all-features`, no domain logic. Absolute sizes are floors; percentages are what
  transfers. Proof: re-run the matrix against the real template once it exists.
- **Opus's issue-responsiveness probe (10 of 10 unanswered) and its 18-project adoption
  census (3 of 18 using dist) were not re-run here** and are reported as its measurements
  with its retrieval date, not as this synthesis's.
- **The generated workflow bootstraps dist with `curl … | sh`.** Doxa/OpenAI flags an open
  upstream concern about that installer's checksum verification; this synthesis did not read
  that issue and records the bootstrap shape as a residual supply-chain risk to be weighed in
  P03 against F020's third-party-action pinning policy.
- **The Codex lens ran and is represented above** (`raw/codex.md`, collected 2026-09-21).
  Revision 2's "absent, by owner direction" record was stale: the W1-CODEX deferral had
  lapsed when the leg was submitted successfully on 2026-09-20 under the W1-CODEX3
  use-if-available rule (`manifest.json`, `operations/codex.json`).
