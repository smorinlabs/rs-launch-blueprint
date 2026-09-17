decision-sha256: 070b7ae10b4a3de48d8b1a1d7cb4799c18d4bfec92713f7d30776128e4578fd7
actor: audit-fable-2026-09-17T033528Z-e504b7806e0c-r1
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

# R68 release-binary-artifacts — judgment audit (revision 1, 2026-09-17)

Fresh context; I wrote none of this run's artifacts. The sha256 above was recomputed over
`review/DECISION.md` as read (48 317 bytes) and binds this audit to those exact bytes. The
empirical (Codex) audit is deferred under `W1-CODEX`, so this is a judgment-only lens and I say
below what that costs. Every claim I checked was checked against the file it cites, never from
memory.

## Principle and agreement level

**The shared requirement is stated at the level the two source repositories actually agree at,
and the level is argued rather than asserted.** The principle — *an end user installs the tool
with one documented command that does not require the project's build toolchain, and CI proves
that command before the release is announced* — is drawn from two named, pinned realisations:
py's `uv build` → `twine check` → `uvx --from "$(ls dist/*.whl)" plbp --version` chain
(`py .github/workflows/ci.yml:215-222` at pin `b08bccfb`) and ts's single ESM tarball
(`ts package.json:20-23` at pin `cb1cbcb2`). The agreement level is **capability, not
mechanism**, and the paragraph headed *"Why the py precedent does not decide this item"* earns
that: a wheel is a pre-built artifact the registry supplies for free, while crates.io stores
source and `cargo install` compiles it. So the capability py inherits is the capability this
item must build by hand. That is the substance behind F214's `DIVERGENT` verdict, and it is the
rare case where the port argument runs *toward* more mechanism rather than less. Correct, and
correctly evidenced at the Cargo Book's `cargo-package` page with its retrieval date.

**Subject B is handled at the right level too, and the distinction is drawn explicitly.** There
is no tool to select on a first-party manifest surface, so gates 1–5 are answered `inapplicable`
with the reason stated rather than omitted, and gate 6 — size and compile cost — becomes the
whole subject and is answered quantitatively. That is the honest shape for this kind of
question, and the decision says so in one sentence instead of forcing a crate-shaped rubric onto
a set of manifest keys.

**Ledger handling.** F214 (`docs/port/COMMONALITY.md:218`, verdict `DIVERGENT`, Item R68) is
settled by Subject A; F220 (`:224`, `ADOPT`) takes its derived value — the three-command README
order — with the `ADOPT` verdict left alone. I read both rows at those line numbers and they are
the rows cited. `docs/port/BASELINE-REVIEW.md:103` records F220 as *"blocked pending R68"* and
its disposition row (`:323`) as *"`ADOPT` kept — Documented commands derived from the artifact
decision — R68"*; the decision's treatment matches that framing exactly, which is why no
`BASELINE-REVIEW:` line is raised and none should be. I also read
`docs/port/areas/packaging-distribution.md` end to end: of F211–F223 only F214 and F220 are this
item's — F211–F219 are R49's declaration surface, F221/F222 are R50's, F223 is R51's — so no
area row is left unhandled. No `CONFLICT:` line is right as well: the one place a fixed
parameter squeezes the answer is `target-os-matrix` offering no ARM Linux runner, and the
decision narrows the target list rather than asking the registry to move, which is the
runbook's required direction.

## Design and evidence

**Architecture before libraries, and the comparison is real.** S1–S4 are four genuinely
different shapes, each with a cost and a named failure mode, and the table's S1 row does the
thing a self-serving comparison never does: it records that this item's *own* profile
recommendation makes the crates.io-only fallback **more** expensive, because `cargo install`
builds under the package's `release` profile. The library choice then follows from the shape,
not the reverse.

**The tool is selected on capability against an explicitly minority adoption rate.** Three of
eighteen surveyed projects use `dist`; fifteen hand-write matrices. The decision names that and
then gives the capability argument — `dist` is the only candidate producing the whole AC1 asset
set from one configuration block — and verifies it against `dist`'s own `v0.33.0` release: 23
assets, listed in full in `artifact-sources.log` section D, including per-triple `.tar.xz`, a
`.sha256` each, `sha256.sum`, `cargo-dist-installer.sh` and `dist-manifest.json`. This is the
opposite of selection by popularity, and the `Maintenance state: at-risk` paragraph is the
proof: the decision recommends a tool it classifies as at-risk, names the deciding signal (a
*publication gap* — `v0.33.0` on GitHub 2026-09-11, crates.io stable `0.32.0` 2026-05-22, and
`GET https://crates.io/api/v1/crates/cargo-dist/0.33.0` returning
`{"errors":[{"detail":"crate \`cargo-dist\` does not have a version \`0.33.0\`"}]}`), bounds it
twice, and makes the exit a deletion rather than a rewrite. I confirmed every one of those
figures in `artifact-sources.log` section I, and the countervailing ones (`archived: false`,
`pushed_at: 2026-09-17T10:06:25Z`, 2 115 stars, 19 585 / 176 744 downloads, 297 open issues from
`/search/issues` — the prompt's required field, never `open_issues_count`) in section H.

**Every settings-table row I could check at the log is at the log, and the ones that could not be
are flagged.** `create-release = false` → `book/src/reference/config.md` line 1277 at
`ref=v0.33.0`, quoted verbatim. `[dist.github-custom-runners]` → `ubuntu-latest` appears **0**
times in `cargo-dist/src/backend/ci/github.rs` at the same tag, against pinned defaults
`ubuntu-22.04`, `ubuntu-22.04-arm`, `macos-14`, `macos-15-intel`; the `global` key is documented
at config.md line 1534. The no-`[package.metadata.binstall]` row → `SUPPORT.md` lines 148–149
(the versionless `{ name }-{ target }{ archive-suffix }` default) and line 124 (the
`{ bin }{ binary-ext }` `bin-dir` default) at a named HEAD commit, which is exactly why R49's
`rslbp` ≠ `rs-launch-blueprint` pair costs nothing here and costs the runner-up a hand-maintained
`pkg-url`. The release-please half → `docs/manifest-releaser.md` lines 217–221 with the quoted
reason. The `[profile.dist]` stub → `concepts.md` lines 60–62 showing `lto = "thin"`, which is
the whole reason AC6 exists.

**The nine disagreement settlements are on grounds, and I traced each to the raw that made the
claim.** Fat-versus-thin is settled by measurement, not by counting engines — three Doxa
providers and the owner reference are on the losing side, and the decision says plainly that two
of them executed no build (`doxa-openai.normalized.md:13`, `doxa-perplexity.normalized.md:170`,
both verbatim) and that Gemini's table is at `rustc 1.81.0` with a 36.2 MB baseline and ~120
dependencies (`doxa-gemini.normalized.md:103-110`), a magnitude nothing here reproduces, so its
figures are set aside with the reason rather than ignored. Gemini's `strip = "debuginfo"` claim
is quoted correctly from line 122 and refuted by a byte-identical build (1 994 112 == 1 994 112).
Its `cargo-zigbuild` claim (line 92) is refuted at dist's source: 0 occurrences in the
user-facing reference, 5 in the CI backend all inside a `CargoBuildWrapper::ZigBuild` guard.
OpenAI's fourth target is refused at the runner map; its binstall block at binstall's own
defaults; its `[profile.dist]` premise is *conceded* as correct at the tag evaluated, which is
the settlement most decisions would have got wrong in the flattering direction. Perplexity's
0.32.0 changelog claim is settled as a misattribution with the arithmetic shown — the
instruction sits at `CHANGELOG.md` line 2274 and the nearest preceding `# Version` heading is
line 2270, `# Version 0.0.3 (2023-02-27)` — and its `<name>-<version>-<target>` convention is
credited as directionally right. Settlement 3 is flagged as a judgement rather than a finding,
which is the correct label for it. Settlement 9 is left **unsettled**: Opus reported fat LTO
"roughly doubles" the clean build (14.29 s → 28.94 s, `opus.md:389`), this run measured
1.3×–1.7× across two passes, and the decision records the disagreement and then carries **no**
numeric clean-build claim at all. That is the right response to an irreproducible number.

**The measurements carry their provenance and their generalisation is stated as a floor.**
Toolchain (`rustc 1.98.0 (88d9e12ae 2026-08-18)`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`), host
(macOS 26.4 (25E246), Apple M4 Pro, `aarch64-apple-darwin`), date (2026-09-17) and working
directory are stated once and govern the whole table; each row is a clean build into a fresh
`CARGO_TARGET_DIR` with `--config 'profile.release.<key>=<value>'`, so no two rows differ by a
manifest edit — a method detail that matters and is stated. The stand-in's composition is given
(52 unique `cargo tree` lines at default features, 93 with `--all-features`, nine named resolved
direct dependencies at exact versions) **and its unlikeness is given with it**: no domain logic,
no error catalog, no config layering, no observability stack, therefore smaller than the
template will be, therefore *"every absolute byte count is a floor and every percentage is the
transferable figure."* That is the generalisation rule the prompt asks for, stated in one
sentence and then honoured everywhere downstream. Every figure in the decision matches
`profile-probe.log` byte for byte: −24.5% (1 994 112 → 1 504 576), −16.0% for the owner
reference's row, −1.3% for thin alone, +13.0% / +21.8% for `"s"` / `"z"`, −22.9% for
`strip = "symbols"` with **0** backtrace frames against 4, the byte-identical `strip =
"debuginfo"` no-op, exit **134** against 101 for `panic = "abort"`, and +12.5% for
`debug = "line-tables-only"` with 2 `at ./src/…` lines in the build tree and **0** once the
binary travels.

**Opus's Linux figures are labelled as his and are not reproduced.** The unproven list states
that no `x86_64` binary was built here, that every absolute byte count is an `aarch64` Darwin
figure, and that Opus's Linux rows were taken inside an `aarch64` Docker Desktop VM on Apple
Silicon rather than on a bare `x86_64` runner — which is what `opus.md:456` and `:854` actually
say. The decision cites none of them as its own and relies on Linux only for the *direction*
Opus recorded. The same discipline covers the 3-of-18 adoption census, the 10-of-10
responsiveness probe and the nine read manifests, each attributed to Opus with its retrieval
date. I checked the two figures the decision does quote from Opus — `−18.8%` for `lto = "fat"`
alone (`opus.md:467`) and `−24.4%` for the recommended row (`:389`) — and the claimed agreement
"to within one percentage point" holds, at exactly 1.0 pp on the widest row and 0.1 pp on the
recommended one.

**The release-please ↔ dist pairing is an honest limit, not a gap the decision cannot carry.**
Both halves are read at their own maintainers' primary sources, the composition is labelled *"a
reasoned composition, not a documented integration"* in the unproven list, and the proof is
executable and specific (`gh api repos/<o>/<r>/releases/tags/v<X.Y.Z>` against the AC1 asset set
with `.draft == false`, asserted to have been created exactly once). Decisively, the decision
names the **load-bearing precondition** most compositions of this shape omit: F072's
`actions/create-github-app-token v3.2.0` App token, because a tag pushed with the default
`GITHUB_TOKEN` fires no second workflow. Putting that in the plan rather than in a post-mortem
is the difference between a limit and a hole. Under the programme rule that P03 builds and
proves the template, a decision that declines to run `dist` and says exactly what would prove it
is behaving correctly, not deficiently.

## Completeness

Required fields and structure: the H2 set is exactly `## Decision`, `## Parameters`,
`## Empirical check`, `## Engines` in that order, the required H3 `### Principles and
implementation` is present, there is no `## Supersedes` (correct — revision 1 reverses nothing),
and a `re-verify:` line is present carrying six mechanical triggers rather than a bare date. The
five `- assumes` lines are byte-identical to their `docs/port/PARAMETERS.md` rows — I re-derived
this independently of the run's own self-check, matching each value as an exact substring of its
registry cell (`build-tool-output-shape` 1 818 chars, `msrv-policy` 118, `rust-edition` 4,
`target-os-matrix` 27, `license` 17) — and none carries a backtick. No `- owns` line is written,
which is correct twice over: `inputs/prompt.md:24` carries an empty `- owns:` payload and
`docs/port/PARAMETERS.md` registers no R68-owned parameter (R68 appears there only as a consumer
in `build-tool-output-shape`'s Notes). The decision's own sentence about that — *"inventing a
registry row is a registry edit, not a research finding"* — is the right instinct.

Prerequisite and neighbours: R49's `build-tool-output-shape` is consumed verbatim and, as the
prompt asserts, R49's own `DECISION.md` sets no `[profile` key (verified: zero occurrences), so
Subject B takes nothing away from an accepted, published item. The composition with R25 is clean
— R25 fixes `release-type`, `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` in
`release-please-config.json` and says nothing about `draft`, so R68's two added keys are
additive; and `force-tag-creation` protects rather than disturbs R25's version computation,
whose own documented reason is *"allowing release-please to correctly identify the previous
release."* The composition with R26 is clean as well: R26's guard diffs a packed **file** set
against `ci/expected-packed-files.txt` and a publish-facing **field** projection that contains
no profile key, and R49's `include` allow-list admits none of `dist-workspace.toml`,
`release.yml` or `release-please-config.json`, so nothing R68 adds enters the packed set or the
projection.

Owner inputs: `docs/port/OWNER-REVIEW.md` §*"2026-09-16 — Release build profile ownership: R68
(W0-R69p)"* is present at line 136 and its four declined options are reproduced accurately in
the decision's opening; note that the ruling's own text names four keys (`lto`, `codegen-units`,
`opt-level`, `strip`) while the amended prompt asks for six — the decision answers all six, a
superset, so nothing is dropped. Gate 1 is answered `inapplicable — owner ruling 2026-09-12
(Q7.B)` with the section present at line 47 and the gate row **recorded rather than deleted**,
as the prompt requires. The owner reference is reconciled under `docs/planning/p02/owner-
decisions.md` §11 as a research input: `codegen-units = 1` agreed and independently measured,
`lto = "thin"` differed **on measured ground** citing the file by section, `rust-version`/
`edition` overridden by the fixed parameters — which §11 itself instructs, naming edition 2024
over 2021 and `msrv-policy` over `1.85` — C15 container rows handed to R51 with the profile
coupling stated, C14 out of scope. I read the reference file: its `[profile.release]` block at
lines 200–202 is exactly those two keys and nothing else, its caveat at line 435 is the quoted
one, and it contains no `cargo-dist`, `binstall` or release-binary content at all, so the
reconciliation covers every row of it that touches this item.

The three checks are stated within what the logs show. Assertion counts are as claimed — 21, 26,
22 — each log ends `RESULT: PASS`, and I read all three without rerunning them. The narrative
describing `decision-self-check.sh` matches its log line for line. One quiet but strong signal:
that log records `DECISION.md (48317 bytes)` and the file is exactly 48 317 bytes, so the
self-check ran against the final bytes rather than a draft — which is precisely the tripwire the
decision says it is.

## Findings

None is unresolved. Each is either already carried in the decision's own unproven list with the
check that would close it, or immaterial to both recommendations; none requires an edit before
acceptance.

**JF-1 — `x86_64-apple-darwin` on `macos-latest` is a cross-build, and the targets row reads as
if it were native. Non-blocking; the only finding under which any recommendation could move, and
only conditionally.** The `targets` row says *"exactly the triples the two fixed runners build.
Both Darwin triples build on `macos-latest`"*, and the exclusion of `aarch64-unknown-linux-gnu`
is argued from dist's runner map. Applied evenly, that map also assigns `x86_64-apple-darwin` to
`macos-15-intel`, and `macos-latest` is an arm64 host — so the override makes that triple a
cross-build the decision never names. Opus's raw carries the missing half and the synthesis
compressed it out: `opus.md:360` records that *"Apple's toolchain targets both architectures"*
and `:372` that `x86_64-apple-darwin` *"costs one extra `rustup target add` on a runner that
is"* aarch64. Darwin↔Darwin cross-compilation is toolchain-native and dist's generated workflow
installs rustup targets itself, so the recommendation as written is very likely correct; what is
missing is the sentence saying why the ARM-Linux ground does not reach this triple. It is
non-blocking because the gap is already inside the scope of the recorded unproven item *"dist
was never executed in this item"*, whose named proof — `dist plan --output-format=json`
asserting exactly three archives — is the check that would surface a failure before a release,
and because no alternative exists inside the fixed matrix anyway (an Intel macOS runner is not
in `target-os-matrix`). If P03's first `dist plan` or first release contradicts it, the target
list drops to two; nothing else in either recommendation is touched.

**JF-2 — the prompt's per-OS measurement requirement is met on one of the two OSes.
Non-blocking; recorded honestly with its proof.** Profile question 2 asks for figures *"measured
at the pinned toolchain on each OS in the fixed `target-os-matrix`"*; every measurement here is
macOS `aarch64`. The decision does not paper over this: it states that no `x86_64` binary of any
kind was built, that absolute counts are Darwin figures, that Opus's Linux rows came from an
`aarch64` Docker VM and were not reproduced, and that the proof is running the probe's
equivalent on an `ubuntu-latest` runner in P03's CI. Two things keep it non-blocking. First, the
owner ruling that created the subject names no per-OS requirement — that wording is the prompt's
— so nothing owner-fixed is unmet. Second, and decisively, **no recommendation moves**: both
written keys are size wins in the same direction on both platforms, and the two keys whose
behaviour is known to diverge by OS are both *refusals*, where the Linux evidence argues the same
way only harder (`debug = "line-tables-only"` at Opus's +550.8% on Linux against +12.5% here;
`strip`'s refusal rests on 0 backtrace frames, a diagnostic cost that is not platform-specific
in kind).

**JF-3 — two configuration key names in the Subject A settings table are not among the 26
asserted strings. Non-blocking; immaterial.** `cargo-dist-version = "0.33.0"` and `ci =
"github"` are the only keys in that table with no corresponding grep in `artifact-sources.log`
section C; `installers`, `create-release`, `install-updater` and `github-custom-runners` are all
asserted there by name. The row's Ground cell does not claim otherwise — it cites the log for
the release date and the installer-not-crates.io mechanism, both of which are asserted — so this
is an unasserted detail rather than a misattribution, and `dist init` writes both keys in P03.

**JF-4 — one load-bearing behavioural claim carries no endpoint or date. Non-blocking;
immaterial.** *"A tag pushed with the default `GITHUB_TOKEN` does not trigger another workflow;
a tag pushed with an App token does"* is the sentence that makes F072 a precondition rather than
a nicety, and F072 is cited for the token *source* (`COMMONALITY.md:78`), not for this
behaviour. Related and smaller: the countervailing maintenance figures (stars, 90-day and
all-time downloads, `archived`, `pushed_at`) sit in a clause whose endpoints live in
`artifact-sources.log` section H rather than inline, unlike the registry-gap figures beside them,
which do carry theirs. Every such figure exists with its endpoint in the committed log the
section names, and the prompt's own figure table fixes the endpoint unambiguously in each case.

**Observations, carried for the record and not findings.** (1) `strip = "symbols"`'s
after-external-strip column prints `—` where `profile-probe.log` has 1 537 448; the dash is
defensible for a re-strip of an already-stripped binary but a measured value is elided. (2)
`dist`'s own `v0.33.0` release — the 23-asset proof that *"its own release is built by itself"* —
was produced by a workflow that installs the **0.32.0** installer (`release.yml` line 67 at
`ref=v0.33.0`), so that evidence attaches to the previous generator; it sharpens the existing
unproven item rather than adding one. (3) The same installer script is how a P03 developer
obtains `dist` 0.33.0 locally for `dist init`, which follows from the row but is not said. (4)
Opus recorded a further at-risk signal the synthesis omits — `opensource.axo.dev` returning
`NXDOMAIN` (`opus.md`, dominant-choice section); the omission understates rather than overstates
the risk already accepted.

## Assessment

Approve. Neither recommendation moves under any finding: **the profile recommendation moves under
none**, and **the artifact recommendation moves under none as written**, with JF-1 the sole
conditional and its trigger already inside a recorded unproven item with an executable check.

What distinguishes this decision is the number of places it takes the unflattering side of its
own argument. It recommends a tool it grades `at-risk` and names the grade in the same sentence
as the recommendation. It refuses the largest measured size win (`strip = "symbols"`, −22.9%)
because the built binary printed zero backtrace frames, and refuses the second (`panic =
"abort"`, −20.3%) on an exit status of 134 that R67's taxonomy does not carry — and it does not
pretend R67 imposed a symbol requirement it does not impose, instead asserting the requirement as
this item's own, backing it with the measurement, and listing F301 as the trigger that would
reopen `strip` and `debug`. It concedes OpenAI's `[profile.dist]` premise, credits Perplexity's
caution as directionally right while rejecting its conclusion, and declines to settle the one
disagreement its own two runs could not reproduce. The `re-verify:` line is mechanical rather
than calendrical, and trigger 2 — any `cargo-dist` bump, because `dist init` would silently
restore `lto = "thin"` — is exactly the failure mode a template carries for years without
noticing.

The evidence base is reduced and the decision says so twice, in `## Engines` and in the unproven
list: no Codex lens ran under `docs/planning/p02/owner-decisions.md` §12 row `W1-CODEX`, so no
independent model family challenged this text, and the run's `manifest.json` carries operations
for `opus` and `doxa` only, consistent with that. That absence is recorded as a reduction in
coverage rather than dressed up as completeness, which is the honest treatment. Judgment-only
acceptance is available on this audit; publication still waits for the deferred empirical audit,
per the same owner row.
