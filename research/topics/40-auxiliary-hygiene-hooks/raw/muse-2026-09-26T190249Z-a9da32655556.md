# R40 — Auxiliary hygiene hooks (bundle) — raw report

Actor: `research-muse-2026-09-26T190249Z-a9da32655556`. Engine: Muse (Meta).
Item kind: `bundle`. Tier: focused. Retrieval date for every figure and
checked-out read below: **2026-09-26**, unless a line says otherwise.

**Status.** This is a research proposal, not a built template. The pinned
sibling reads, the crates.io / api.github.com / rustsec.org figure pulls,
and behavior probes P1–P5 below were executed on 2026-09-26 on macOS 15 /
aarch64 with typos-cli 1.32.0, actionlint 1.7.12, yamllint 1.38.0 and
codespell 2.4.2. No hook manager ran end to end (R37 still open), no
template CI ran (template not built), and `editorconfig-checker` was not
executed (binary not installed; see gap G3). GitHub API reads used the
authenticated REST endpoint (`gh api`, same named endpoint as the prompt's
`GET https://api.github.com/...`) because the anonymous quota for this
egress IP was exhausted. This session does not expose a more specific
model snapshot than the engine family recorded above.

### Landscape

The category this item decides is *auxiliary pre-commit
hygiene/structural-validity tooling beyond the language formatter and
linter*: a whitespace/EOL/format-validity checker, a YAML structural
linter, a spell-checker, a GitHub Actions workflow-syntax linter, and the
cross-editor `.editorconfig` baseline they enforce. Only two candidates
in the whole field are Rust crates (`typos-cli`, `zizmor`); the rest are
Go or Python binaries or plain config files. Cargo-tree figures
(90-day/all-time downloads, dependency-tree MSRV, `unsafe` posture,
default features, async-runtime coupling, compile time) are therefore
**inapplicable** to every non-crate candidate with the reason stated per
member; GitHub figures (stars, license, push date, release, open-issue
count) apply to all tool candidates. [C1] [G1–G6]

**Three-bin map.** There is no built-in or first-party Rust toolchain
answer for any of the four checks: `rustfmt` normalizes `.rs` files only,
`clippy` lints Rust code only, and neither reads `.editorconfig`, YAML
style rules, prose dictionaries, or workflow semantics.

| Sub-capability | Built-in / first-party | Established industry standard | Up-and-comer |
|---|---|---|---|
| Whitespace/EOL/format-validity (F167) | None: `rustfmt` is `.rs`-only; `git` has no size/EOL gate | `editorconfig-checker` (Go binary, MIT, v4.0.2) [G5] | None shortlisted |
| YAML structural lint (F168) | None | `yamllint` (Python, GPL-3.0, v1.38.0) [G3] | `ryl` 0.22.0, `yamllint-rs` 0.1.4, `yaml-lint` 0.1.0, `fast-yaml-linter` 0.6.6 — all pre-1.0, trivial adoption (see member) [C2] |
| Spell-check (F169) | None (`rustc` has no prose check) | `codespell` (Python, GPL-2.0, v2.4.3) [G2]; `typos` (Rust, Apache-2.0, v1.50.3) [G1] [C1] | None shortlisted beyond these two |
| Workflow-syntax lint (F170) | None | `actionlint` (Go binary, MIT, v1.7.12) [G4] | `zizmor` (Rust, MIT, v1.30.1) — adjacent concern (security audit), not a syntax substitute [G6] [C3] |
| Cross-editor baseline (F191/F192) | None (no Rust tool emits `.editorconfig`) | The EditorConfig file format itself (unversioned standard) | None |

**Authority.** (1) The two pinned sibling checkouts, read from local Git
objects: py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, ts at
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — authoritative for what each
sibling actually runs, because they are the artifacts under comparison.
[P1] [P2] (2) The prompt's named API endpoints — authoritative for
version, license, activity and adoption figures; every number below
carries its endpoint. (3) The tools' own executed behavior (probes
P1–P5) — authoritative for exit codes and config-honoring. (4) Accepted
decisions R33 (adopted `insta` 1.48.0, committed snapshot files),
R11/R42 (consumed parameters, quoted under `### Parameters`), and
`docs/port/DIVERGENCE-ANALYSIS.md` (per-tool adopt-or-drop framing).
[D1] [D2] (5) Maintained third-party Rust projects below — practice
evidence, not fitness proof. No blog post is cited as authority. Docs
pages and release notes outside the named endpoints were **not**
fetched; claims that would need them are flagged as gaps, not asserted.

**Practice evidence** (repo-tree reads via `GET
https://api.github.com/repos/<o>/<r>/git/trees/HEAD?recursive=1`,
2026-09-26; file reads via the `contents` endpoint):

| Project surveyed | Why it is a relevant, well-regarded reference | Observed practice | Transfer |
|---|---|---|---|
| `rust-lang/cargo` | The Rust package manager itself; maintained by the Cargo team | Ships root `typos.toml` (allow-lists `flate2`, short-word regexes) and runs `crate-ci/typos@v1.50.0` as a `spellcheck` CI job on ubuntu-latest [G7] | Direct: typos + committed config + CI-tier wiring is production Rust practice |
| `rust-lang/rust` | The compiler; sets ecosystem norms | Ships root `.editorconfig`; vendored `src/tools/rust-analyzer/.typos.toml` and `compiler/rustc_codegen_gcc/_typos.toml` [G8] | Direct for `.editorconfig`; typos configs are vendored-subtree evidence, weaker than cargo's root config |
| `rust-analyzer` (via rustc subtree) | The de-facto Rust IDE engine | Maintains its own `.typos.toml` [G8] | Supporting: second independent typos adopter in Rust tooling |
| `tokio-rs/tokio`, `serde-rs/serde` | Flagship async runtime / serialization framework | Tree grep for typos/codespell/yamllint/actionlint/editorconfig/zizmor returns no matches [G8] | Honest negative: flagship crates can ship without any of these hooks; adoption is template judgment, not ecosystem mandate |
| py at `b08bccf` | Sibling template; the maintained four-hook design | `editorconfig-checker` + `yamllint` + `actionlint` + `codespell` lefthook jobs with committed configs; `.editorconfig` with `[*.md]` and `[*.ambr]` carve-outs [P1] | Shape transfers; `uv run` prefixes do not (R42: bare executables) |
| ts at `cb1cbcb` | Sibling template; the divergent design | No auxiliary hook tools; whitespace/EOL folded into the oxfmt formatter job (D-020(6)); actionlint advisory-only install hint in `Justfile`; carries a `.github/actionlint.yaml` ignore file and a lefthook with format/lint/typecheck only [P2] | ts's fold-into-formatter is viable only where the formatter covers every staged file type (see member 1) |

**Fit over abstract best.** The template is a CLI + library + web service
whose non-Rust surface (Markdown docs, YAML workflows, TOML configs) is
small but user-visible: a template's own hygiene files are its first
impression. Speed at commit time matters more than check depth — every
recommended hook runs in milliseconds without compiling Rust — and every
recommended tool except `yamllint` is a dependency-free binary, so the
template asks contributors for no new language runtime.

### Principles and implementation

**The shared requirement.** *Every commit is free of mechanical hygiene
defects that a machine can catch in milliseconds: no trailing whitespace
or missing final newline outside declared exceptions, no structurally
sloppy YAML, no dictionary typos in prose and identifiers, and no
workflow file that disagrees with the Actions schema — checked locally
before the commit exists and re-checked on the server before the merge.*
Source: ledger rows F167–F170, F191–F192
(`docs/port/COMMONALITY.md:171-174,195-196`), realized in py by the four
jobs and two configs read at the pin. [P1] [L1]

**Source and agreement level.**
`docs/port/DIVERGENCE-ANALYSIS.md:164` classes the R40 item `D`,
`harmonize: partly`: "For each of the 4 tools: does the value justify
adoption for Rust, independent of language". F167 alone is class `C`,
`harmonize: no`: "Does rustfmt plus the chosen non-Rust-file formatter
already cover trailing-whitespace/EOF-newline for every staged file
type, or does a gap remain". [D1]

| Principle | Agreement level | Essential behavior | Observable acceptance criterion |
|---|---|---|---|
| Mechanical hygiene is machine-checked at commit time (per tool: whitespace-validity, YAML structure, spelling, workflow syntax) | Capability — must agree that each adopted check exists in hook tier + CI tier | Each adopted tool runs on staged files pre-commit and re-runs on the full tree in CI | Staging a file with the defect fails the hook; pushing with `--no-verify` fails the CI slot |
| The cross-editor baseline is the EditorConfig format with documented exceptions | Standard (file format) + policy (exception list) | A committed `.editorconfig` with `root = true`; every exception carries an inline rationale | A fresh clone opened in any EditorConfig-aware editor shows LF/UTF-8/trim behavior; `git grep` finds a rationale comment above each exception stanza |
| Checks stay millisecond-scale and runtime-free where the ecosystem allows | Policy — may vary by ecosystem | Prefer dependency-free binaries; a runtime-backed tool needs a maturity argument no binary can yet match | Hook tier adds no language-runtime provisioning beyond what the template already requires, except the single justified case (member 2) |

What must agree across py/ts/rs is the *capability set* (the four
checks plus the baseline file), not the tool names. What may vary is the
mechanism per ecosystem. In this bundle the variance collapses further
than the prompt presumes: all four recommended tools are
language-agnostic binaries, so the Rust stack doubles as the harmonized
recommendation — the single substitution (typos for codespell) is
justified below on license and maintenance grounds that hold in every
ecosystem, and ships to py/ts as follow-on rationale, not as a Rust-only
divergence.

**Architectural alternatives compared before any tool was chosen.**

| Alternative | What it is | Why it was or was not chosen |
|---|---|---|
| A. Four hook-tier checks + `.editorconfig`, one tool substituted | py's shape with typos for codespell | **Chosen.** Keeps the maintained capability set; every tool is a binary except the one with no mature binary alternative. |
| B. Fold whitespace/EOL into the formatter (ts status quo, D-020(6)) | No validity linter; formatter owns whitespace | Rejected for Rust. `rustfmt` covers `.rs` only, and R29 (non-code-file-formatting, still open) cannot be presumed to cover every staged file type a template holds. A formatter also *fixes* while a validity linter *verifies the committed baseline* — including files no formatter touches. If R29 later covers all types, this alternative can be revisited; the re-verify trigger records it. |
| C. Drop some or all four checks | Ship rustfmt/clippy only | Rejected. The template's non-Rust surface (docs, workflows, configs) is its first impression; tokio/serde's negative shows hooks are optional for libraries, but a *template* teaches contributor hygiene by example. Each check's value is argued per member. |
| D. CI tier only, no hook tier | Server-side checks only | Rejected. All four tools run in milliseconds without compiling Rust, so ts's push-boundary cost argument (D-020(3), aimed at full test suites) does not transfer. Local failure is one `git commit` round-trip; CI-only failure is a push plus a workflow run. |
| E. One meta-linter for everything (`pre-commit` framework hooks, multi-language bundles, `linthis`-style multi-linters) | Single binary for all checks | Rejected. The `pre-commit` framework is Python-distributed (reintroduces the runtime for all four checks to remove it from one); `linthis` 0.28.6 (1,138 all-time downloads [C2]) is immature. Best-of-breed binaries compose through the hook manager R37 owns. |

**Answers to the prompt's questions.** HIGH (F167 gap): yes, a separate
validity linter is still needed — `rustfmt` owns `.rs` only and no
decided formatter owns the rest; member 1 argues it. HIGH (`.editorconfig`
at all): yes — rustc itself ships a root `.editorconfig` [G8], ts records
no decision against one (its omission is unexplained drift, not D-014),
and the file costs nothing while giving every contributor's editor the
baseline the validity linter verifies. HIGH (cross-repo principle): the
capability set above at capability/standard level; tool differences are
justified only by license/runtime/maintenance evidence, and here only
one substitution survives that test. MEDIUM (yamllint/codespell
Python-runtime cost): codespell is replaced by typos (no runtime, better
license); yamllint is kept because the crates.io field shows no mature
Rust-native YAML linter (best is `ryl` 0.22.0, 8,802 all-time downloads
[C2]). MEDIUM (actionlint keep + tier): keep, at pre-commit *and* CI —
it is a millisecond Go binary, so the "slower Rust iteration loop" costs
it nothing. LOW (per-filetype exceptions): keep `[*.md]` (hard breaks),
replace `[*.ambr]` (syrupy is Python-only) with `[*.snap]` for R33's
adopted `insta` snapshots, flagged for synthesis to confirm the
extension (gap G4).

**Reference implementations.** `rust-lang/cargo` is the maintained
reference for member 3 (root `typos.toml` + `spellcheck` CI job via
`crate-ci/typos@v1.50.0` [G7]). py at `b08bccf` is the maintained
reference for the composed four-hook shape and for members 1, 2 and 4
(job bodies, `.editorconfig-checker.json` with indent rules disabled per
ITM-009, `.yamllint` with the Actions-`truthy` carve-out) [P1]. Member 5
is referenced by rustc's root `.editorconfig` plus py's commented file.
No maintained reference was found for a Rust-native YAML linter or for
`zizmor`-as-syntax-checker; both are recorded as gaps, not
recommendations.

**Minimal realistic example.** A scratch repo holding `.editorconfig`
(member 5), `.editorconfig-checker.json`, `.yamllint`, `_typos.toml`
(members 1–3 configs as specified under `### Members`), one Markdown
file with a hard break + a typo, one YAML file with a style violation,
and one workflow missing `runs-on`: running the four bare executables
(`ec`, `yamllint`, `typos`, `actionlint`, per R42's invocation rule)
must fail on exactly the seeded defects and pass once each is fixed.
Probes P1–P5 executed the typos/yamllint/actionlint/codespell halves;
the `ec` half is planned, not executed (gap G3).

No `BASELINE-REVIEW:` finding: no recorded baseline principle is
challenged by this answer; the ts omissions read as unexplained drift
(class A/D per [D1]), and the single tool substitution is an
implementation choice inside an unchanged capability, not a baseline
change.

### Recommendation

One stack. All four tools run at pre-commit on staged files (inside the
hook manager R37 owns) and re-run on the full tree in CI (hygiene job;
actionlint in the workflow-lint job gated on the `workflows` key, per
R11). Versions are the newest non-prerelease observed 2026-09-26.

| Member | Tool (version) | Config file | Tier |
|---|---|---|---|
| Whitespace/EOL/format-validity (F167) | `editorconfig-checker` v4.0.2 (Go binary, MIT) | `.editorconfig-checker.json` (indent rules disabled, py ITM-009 shape) | hook + CI hygiene |
| YAML structural lint (F168) | `yamllint` v1.38.0 (Python, GPL-3.0, pipx-isolated) | `.yamllint` (py-pin shape: default + line-length 88 warning + Actions truthy carve-out + no document-start) | hook + CI hygiene |
| Spell-check (F169) | `typos` v1.50.3 (Rust binary/crate `typos-cli`, Apache-2.0) — replaces codespell | `_typos.toml` | hook + CI hygiene |
| Workflow-syntax lint (F170) | `actionlint` v1.7.12 (Go binary, MIT) | `.github/actionlint.yaml` (this item: tier + file presence; rule content is R09's) | hook + CI workflow-lint |
| Cross-editor baseline (F191/F192) | `.editorconfig` (unversioned EditorConfig standard) | the file itself: LF/UTF-8/trim/final-newline defaults, indent 4 (2 for yml/yaml/json/toml), `[*.md]` + `[*.snap]` trim carve-outs with rationale comments | committed file, verified by member 1 |

### Members

#### whitespace-eol-validity (F167)

##### Landscape

The gap is real and formatter-shaped: `rustfmt` owns `.rs` files only,
and R29 (non-code-file-formatting) is still open, so no decided tool owns
whitespace/EOL/final-newline for the template's Markdown, YAML, TOML, or
miscellaneous staged files. The bins hold exactly one established
candidate: `editorconfig-checker`, a Go binary (MIT) that verifies staged
files against the committed `.editorconfig`. No built-in alternative
exists (`git` exposes no EOL gate), and no up-and-comer was shortlisted —
the field is this one tool plus the fold-into-formatter architecture
(rejected at bundle level while R29 is open). Figures via `GET
https://api.github.com/repos/editorconfig-checker/editorconfig-checker`,
2026-09-26: 638 stars, `archived: false`, `pushed_at:
2026-09-21T08:14:54Z`, license MIT; latest release v4.0.2 published
2026-09-19; open issues `total_count: 25` via the search endpoint. [G5]
Crates.io figures, RustSec, dependency-tree MSRV, `unsafe` posture,
default features, async-runtime coupling and compile-time cost are
**inapplicable**: the candidate is a Go binary, not a Rust crate, and the
template never compiles it.

##### Principles and implementation

Essential behavior: every staged file matches the `.editorconfig`
baseline for charset, EOL, final newline and trailing whitespace, with
indent rules *disabled* — py's ITM-009 shape, where Ruff/yamlfmt/taplo
own indent and double-enforcement risks spurious failures; for Rust the
indent owners are rustfmt (`.rs`) and R29's formatter (the rest). The
check verifies the baseline; it never reformats. Acceptance: a staged
file with trailing whitespace (outside a declared exception) or a
missing final newline fails the hook; the same file passes once fixed;
`[*.md]` hard breaks pass (py's `.editorconfig-checker.json` honors
`trim_trailing_whitespace = false` per its own comment [P1]).
Maintenance state: **active** — release v4.0.2 within the week,
pushed within the week, 25 open issues. Integration cost is one hook job
plus one JSON config; runtime cost is milliseconds (single static
binary). The py precedent runs it via the PyPI wheel (`uv run ec`); the
Rust template must install the prebuilt binary instead (release assets
include `linux-amd64`, `linux-arm64` and `darwin-all` tarballs [G9]) and
invoke the bare `ec` executable per R42.

##### Dominant choice

`editorconfig-checker` v4.0.2 — the only established tool in its bin,
maintained by its own org, MIT-licensed, with the exact config shape the
template needs already proven in py. [G5] [P1]

##### Qualified shortlist

`editorconfig-checker` v4.0.2 (sole member; no second qualified
candidate — the fold-into-formatter alternative is an architecture, not
a tool, and is rejected while R29 is open).

##### Excluded by gate

None. Fitness gates: (1) MIT — pass. (2) Crate/dependency-tree MSRV —
inapplicable (Go binary; nothing enters a Cargo tree). (3) RustSec/`unsafe`
— inapplicable as specified (not a crate; Go vulnerability state not
checkable via the named endpoints — gap G5). (4) OS matrix — pass:
prebuilt linux (`amd64`, `arm64`, `386`) and `darwin-all` assets on the
v4.0.2 release [G9]; Windows assets also present (informative). (5)
Default features/async coupling — inapplicable (not a crate). (6)
Binary size/compile cost — no compile cost (prebuilt binary); size not
measured in this leg (gap, low weight: CI downloads one tarball).

##### Up-and-comers

None. No Rust-native `.editorconfig` verifier with any adoption was
found; none is needed — the incumbent is a dependency-free binary with
no runtime problem to solve.

##### Fit for this template

Exact fit: it verifies member 5's baseline file across every staged file
type, including types no formatter will ever cover (`.gitignore`,
`LICENSE`, miscellaneous dotfiles). Its indent-blind config composes
with rustfmt + R29 instead of fighting them.

##### Recommendation

Adopt `editorconfig-checker` v4.0.2: hook job `ec -config
.editorconfig-checker.json {staged_files}` on all staged files (bare
executable, presence-guarded per R42), re-run over the full tree as a
hygiene-job step per R11. Config: py's `.editorconfig-checker.json`
shape with `Exclude` adapted (`target/`, `.git/`, `dist/`-equivalents)
and `Indentation`/`IndentSize` disabled.

##### Ranked runner-up

Fold into R29's formatter (no tool). Ranked below because R29 is
undecided and any single formatter leaves some staged file type
uncovered; revisit if R29's decision claims total coverage.

##### Tradeoffs

Keeps a fifth config file and a Go-binary install for one check; the
alternative (no validity linter) leaves non-formatter-covered files
unchecked and the `.editorconfig` baseline unverified. The single-dash
flag spelling (`-config`, Go style) is a documented footgun (py's
lefthook comment [P1]); the template's job body must copy it exactly.

##### Parameters

None beyond the bundle-level assumes (`ci-job-structure`,
`package-manager-invocation`); this member owns no parameter and raises
no `CONFLICT:`.

##### Migration implications

Add `.editorconfig-checker.json` (adapted Exclude list) and one hook-job
body + one CI hygiene step, both invoking bare `ec`. No Cargo.toml
change.

##### Validation strategy

Planned, not executed (gap G3): seed a scratch repo with a trailing-space
`.txt`, a missing-newline `.md` (no hard break), and a hard-break `.md`;
`ec -config .editorconfig-checker.json` over the tree must fail on
exactly the first two. The `ec` binary was not installed in this leg, so
no observed output is claimed.

##### Confidence & re-verify trigger

Medium-high. Re-verify when R29 decides: if its formatter covers every
staged file type, re-run alternative B; if `editorconfig-checker` shows
a concrete at-risk signal (archived, unpatched CVE in its module tree,
broken release assets), re-open the member.

##### Sources

[G5] repo + release + open-issue figures; [G9] release-asset list;
[P1] py `lefthook.yml:82` job, `.editorconfig-checker.json`, ITM-009
comment; [P2] ts D-020(6) fold rationale; [D1] F167 class-C question.

#### yaml-structural-lint (F168)

##### Landscape

Structural/style YAML linting (truthy keys, colons/commas spacing,
document rules) as distinct from YAML *formatting* (R29's F098). Bins:
built-in — none; established — `yamllint` (Python, GPL-3.0), the tool py
runs (`uv run yamllint -c .yamllint {staged_files}` on `*.{yml,yaml}`
[P1]); up-and-comers — four Rust-native crates found via `GET
https://crates.io/api/v1/crates?q=yaml+lint`, 2026-09-26: `ryl` 0.22.0
(8,802 all-time / 4,814 recent downloads), `yamllint-rs` 0.1.4 (1,479 /
239), `yaml-lint` 0.1.0 (368 / 53) + `yaml-lint-core` 0.1.0 (479 / 83),
`fast-yaml-linter` 0.6.6 (862 / 249) with `fast-yaml-cli` 0.6.6 (371 /
139). [C2] [G3] `yamllint` figures: 3,467 stars, `archived: false`,
`pushed_at: 2026-09-19T13:20:39Z`, GPL-3.0; latest release v1.38.0
published 2026-01-13; open issues `total_count: 128`. [G3]

##### Principles and implementation

Essential behavior: staged YAML files satisfy the committed rule set —
starting from py's proven `.yamllint` (extends default; line-length 88
as warning with non-breakable allowances; truthy carve-out for
Actions' `on`/`off` keys with `check-keys: false`; `document-start`
disabled; comment rules explicit [P1]) — while R29's formatter owns
reformatting. Acceptance: the P4 probe's `bad.yml` (double space after
colon, missing space after comma) fails with the two expected rule hits;
`good.yml` passes; a workflow using `on:` as a key is not flagged
truthy. Maintenance: `yamllint` is **active** (pushed within the week;
January release is normal cadence for a mature linter, not a stall
signal — no-release-in-6-months is a trigger to investigate, and the
investigation shows current-month commits). The Python-runtime cost is
real but bounded: pipx-style isolated install, no project dependency,
invoked as a bare `yamllint` executable per R42. No surveyed Rust
project runs YAML lint at all (tree greps negative [G8]), so practice
evidence for tool choice comes from py plus the crates.io field, not
from Rust precedent.

##### Dominant choice

`yamllint` v1.38.0 — the only mature YAML linter in any language in the
field; every Rust-native alternative is pre-1.0 with three-to-four
orders of magnitude less adoption.

##### Qualified shortlist

`yamllint` v1.38.0 (sole member). The Rust-native crates are not
shortlisted: best case `ryl` 0.22.0 has 8,802 all-time downloads against
`yamllint`'s 3,467 stars and decade-long maintenance — not template
grade today.

##### Excluded by gate

None excluded *by gate*, but two gate notes apply to the pick. (1)
License: GPL-3.0 — the tool is invoked as a dev-time binary, never
linked or distributed with the template, so copyleft does not attach to
template output; recorded as a tradeoff, not a failure, since the gate's
compatibility reading targets template dependencies. (2–6) Crate MSRV,
RustSec, `unsafe`, features, async coupling, compile cost —
inapplicable (Python program, not a crate; installed prebuilt via pipx).
(4) OS matrix — pass by construction: pure-Python, runs wherever the
template's Python provision runs on ubuntu-latest/macos-latest (same
provision py already relies on; exact provisioner mechanics are R42's
wider tooling question, already decided for invocation shape).

##### Up-and-comers

`ryl` 0.22.0 (fast, yamllint-inspired, updated 2026-09-06, 4,814 recent
downloads [C2]) is the one to watch; `fast-yaml-linter` 0.6.6 and
`yamllint-rs` 0.1.4 trail it. All are pre-1.0; none has a maintained
reference adopter. Re-verify trigger names the graduation bar.

##### Fit for this template

Direct fit: the template's YAML surface is small (workflows, issue
templates, dependabot config) but schema-sensitive — exactly where
truthy-key and indentation-style linting pays. Overlap with actionlint
on workflow files is acceptable: yamllint owns YAML style, actionlint
owns Actions semantics.

##### Recommendation

Keep `yamllint` v1.38.0: hook job `yamllint -c .yamllint
{staged_files}` globbed to `*.{yml,yaml}` (bare executable,
presence-guarded), re-run over the tree as a hygiene-job step. Config:
py's `.yamllint` with the `ignore` list adapted to Rust artifacts.

##### Ranked runner-up

`ryl` (unpinned; currently 0.22.0) — ranked below solely on maturity.
If it reaches 1.0 with a stable rule set and a maintained adopter, it
removes the template's last Python-runtime hook dependency.

##### Tradeoffs

Keeps one Python-runtime tool in a Rust template (provisioning weight
falls on R42's installer story) and one GPL-3.0 binary in the toolchain
(no copyleft effect on template output, but an org-policy flag for
shops that bar GPL tools outright). The alternative — dropping YAML
lint — loses the truthy-key and style net over the template's most
failure-prone configs.

##### Parameters

None beyond the bundle-level assumes; owns nothing; no `CONFLICT:`.

##### Migration implications

Add `.yamllint` (adapted ignore list) and one hook-job body + one CI
hygiene step invoking bare `yamllint`. No Cargo.toml change.

##### Validation strategy

Executed (probe P4, 2026-09-26, yamllint 1.38.0): `bad.yml` failed with
exactly `1:6 colons` + `2:13 commas` (exit 1); `good.yml` passed (exit
0). Planned, not executed: the truthy carve-out against a real workflow
file and the full-tree CI re-run.

##### Confidence & re-verify trigger

Medium. The keep decision is forced by the field, not enthusiastic.
Re-verify when any Rust-native YAML linter reaches 1.0 with a
maintained reference adopter, or yearly: re-run the crates.io `q=yaml
lint` search and graduate `ryl` (or successor) if the maturity gap has
closed.

##### Sources

[G3] repo + release + open-issue figures; [C2] crates.io `q=yaml lint`
search results; [P1] py `lefthook.yml` yamllint job + `.yamllint`;
[G8] surveyed-negative Rust tree greps; probe P4 output.

#### spell-check (F169)

##### Landscape

Prose/identifier spell-checking over staged files. Bins: built-in —
none; established — two: `codespell` (Python, GPL-2.0: 2,428 stars,
`pushed_at: 2026-09-23T13:17:40Z`, v2.4.3 published 2026-07-15, open
issues 189 [G2]) and `typos` (Rust crate `typos-cli` + binary,
Apache-2.0: 4,158 stars, `pushed_at: 2026-09-25T18:41:08Z`, v1.50.3
published 2026-09-25, open issues 126 [G1]; crate downloads 1,002,025
all-time / 115,151 recent, `max_version: 1.50.3`, newest non-yanked
`1.50.3` created 2026-09-25 with `rust_version: 1.95` [C1]; RustSec
page for `typos-cli` returns 404 — no advisories on record [R1]).
Up-and-comers — none; the bin is a two-horse race the Rust horse leads.

##### Principles and implementation

Essential behavior: dictionary typos in prose, comments and identifiers
fail the hook with a correction suggestion; project vocabulary
(crate names, lints, hashes) is allow-listed in a committed config, not
by skipping files. Acceptance: P1's `typo.txt` (`sentance`, `teh`)
fails naming both corrections (exit 2); `clean.txt` passes (exit 0);
P2's `_typos.toml` `[default.extend-words]` entry silences exactly the
listed word. Maintenance: `typos` is **active** (release + push within
48h of retrieval); responsiveness sample (6 newest non-PR issues,
`#1594`–`#1607`, 2026-08-08–26): first maintainer (`COLLABORATOR`)
response on all 6 within ~1h, median under 1 day, 0 unanswered [G1b].
(`#1610`, opened by the maintainer, excluded from the sample; only 7
issues appear in the last 30 opened items because the rest are PRs —
stated so the sample is not mistaken for a full 10.) Integration cost:
one binary + `_typos.toml`; zero runtime provisioning; typos reads
`_typos.toml`/`typos.toml` natively (P2 executed). codespell by contrast
needs a Python provision solely to run it and carries GPL-2.0.

##### Dominant choice

`typos` v1.50.3 — leads codespell on every measured axis: adoption
(4,158 vs 2,428 stars; 126 vs 189 open issues), license (Apache-2.0 vs
GPL-2.0), runtime footprint (static binary vs Python), maintenance
recency, and Rust-ecosystem practice (cargo's root `typos.toml` +
`spellcheck` CI job via `crate-ci/typos@v1.50.0` [G7];
rust-analyzer's `.typos.toml` [G8]). No axis favors codespell except
incumbency in py.

##### Qualified shortlist

`typos` v1.50.3; `codespell` v2.4.3 (qualified but dominated — kept on
the shortlist only as the evaluated incumbent).

##### Excluded by gate

None. Gates for the pick: (1) Apache-2.0 — pass (template-license
compatible). (2) MSRV — the template never compiles `typos-cli` as a
dependency (prebuilt binary / `crate-ci/typos` action), so the Cargo-tree
reading is inapplicable; for the record, the crate declares
`rust_version: 1.95` [C1], inside any plausible stable-minus-2 window
against the observed local stable 1.98.1. (3) No RustSec page (404) —
no advisories on record [R1]; `unsafe` posture not audited in this leg
(gap, low weight: lint-time binary, not linked). (4) OS matrix — pass:
cargo runs the same binary on ubuntu-latest in CI [G7]; typos publishes
multi-platform binaries and the probe ran the macOS/aarch64 build
locally. (5) Features/async — inapplicable (standalone binary). (6)
Zero compile cost when installed prebuilt (recommended path); `cargo
install` cost not measured (not recommended).

##### Up-and-comers

None. The spell-checker field is consolidated; both established tools
are the whole map.

##### Fit for this template

Exact fit: Rust-native, Apache-2.0, config-file allow-listing shaped
like cargo's (extend-exclude + extend-words), CI wiring already proven
by cargo's `spellcheck` job. Removes the template's only other
Python-runtime hook tool besides yamllint.

##### Recommendation

Adopt `typos` v1.50.3, replacing codespell: hook job `typos
{staged_files}` (bare executable, presence-guarded), re-run over the
tree as a hygiene-job step (cargo's `crate-ci/typos` action shape is
the CI reference, subject to R20's pinning policy for the `uses:` line).
Config: committed `_typos.toml` seeded with template vocabulary.

##### Ranked runner-up

`codespell` v2.4.3 — loses on license, runtime footprint, and every
adoption/maintenance figure; retained only so the incumbent comparison
is on record. Probe P5 confirms it works (exit 65 on typos, 0 clean),
so the rejection is preference, not function.

##### Tradeoffs

One substitution cost: contributors coming from py meet a different
spell-checker with a different config file and allow-list syntax, and
py's `[tool.codespell]` section has no counterpart (typos uses its own
TOML file). Offset: no Python provision, permissive license, faster
runs, and the same tool cargo itself uses. Cross-repo follow-on: the
evidence supports typos for py/ts too (language-agnostic binary), with
the caveat that py's "no new runtime" argument does not apply where
Python is already provisioned.

##### Parameters

None beyond the bundle-level assumes; owns nothing; no `CONFLICT:`.

##### Migration implications

Add `_typos.toml`; add one hook-job body + one CI hygiene step invoking
bare `typos`. Do not carry any codespell config. No Cargo.toml change.

##### Validation strategy

Executed (probes P1/P2/P5, 2026-09-26, typos-cli 1.32.0 local /
codespell 2.4.2): typos flagged both seeded typos with corrections
(exit 2), passed clean text (exit 0), and honored `_typos.toml`
extend-words (exit 0); codespell flagged both (exit 65) and passed
clean (exit 0). Version skew note: the local typos (1.32.0) predates
the recommended 1.50.3; behavior verified is stable long-standing
behavior (flag/pass/allow-list), and CI pins the recommended version.
Planned, not executed: full-tree CI re-run.

##### Confidence & re-verify trigger

High. Re-verify only on a concrete signal: typos archived/neglected,
an open RustSec advisory for `typos-cli`, or a rule-quality regression
reported by a reference adopter (cargo, rust-analyzer).

##### Sources

[G1] typos repo + release + open-issue figures; [G1b] issues
`#1594`–`#1607` + first comments (responsiveness sample); [C1]
crates.io `typos-cli` record + versions; [R1] rustsec.org 404 for
`typos-cli`; [G2] codespell figures (runner-up); [G7] cargo
`typos.toml` + `main.yml` spellcheck job; [G8] rust-analyzer
`.typos.toml`; probes P1/P2/P5 output.

#### workflow-syntax-lint (F170)

##### Landscape

GitHub Actions workflow-syntax linting: schema conformance
(`runs-on`, inputs, `uses:` refs), expression checking, and embedded
`run:` shell-script checking. Bins: built-in — none; established —
`actionlint` (Go binary, MIT: 4,265 stars, `archived: false`,
`pushed_at: 2026-07-16T06:05:57Z`, v1.7.12 published 2026-03-30, open
issues 143 [G4]); up-and-comer — `zizmor` (Rust, MIT: 6,579 stars,
pushed 2026-09-26, v1.30.1 published 2026-09-09, open issues 137 [G6];
crate `zizmor` 247,234 all-time / 47,997 recent downloads, `max_version:
1.30.1` [C3]) — adjacent, not substitutive: it audits workflow
*security* (template injection, permission creep), while actionlint
checks *syntax and schema*; ts's own `.github/actionlint.yaml` at the
pin exists precisely to carry actionlint schema ignores [P2]. Crates.io
and RustSec readings for actionlint are inapplicable (Go binary, not a
crate).

##### Principles and implementation

Essential behavior: every workflow file parses against the Actions
schema with project-specific ignores in a committed config; embedded
shell is shellchecked when `shellcheck` is present (py's ADR-0018 note;
shellcheck present on this probe host [P1]). Acceptance: P3's
workflow missing `runs-on` fails with the `[syntax-check]` finding
(exit 1); the clean workflow passes (exit 0). Tier: pre-commit on
staged workflow files *and* CI — actionlint is a millisecond static
binary, so Rust's slower compile loop is irrelevant to its hook cost,
and py already runs both tiers (local mirror of the lint job per
ADR-0018 [P1]). ts is the cautionary tale: actionlint demoted to an
advisory install hint plus an ignore file with no wired job [P2] —
exactly the drift this member reverses. Maintenance: **stable-quiet** —
v1.7.12 is ~6 months old (trigger to investigate, duly investigated:
pushed 2026-07-16, no archived flag, schema-update cadence explains the
pace for a mature single-purpose linter); responsiveness sample (5
newest non-PR issues `#734`–`#742`, 2026-09-04–23): 3 with no comments,
1 first-commented by a non-maintainer, 1 by a contributor — no
maintainer first-response observed in-window, consistent with
stable-quiet single-maintainer cadence, not with at-risk (no concrete
distress signal: builds, releases, and schema refreshes continue).
This item decides tier + tool only; config rule content (runner labels,
`RUNNER_*` vars, stale-metadata suppression) is R09's.

##### Dominant choice

`actionlint` v1.7.12 — the only established workflow-syntax linter; its
6,579-star Rust neighbor checks a different property.

##### Qualified shortlist

`actionlint` v1.7.12 (sole member). `zizmor` is not shortlisted *for
this member's property* (syntax); it is recorded under Up-and-comers as
a future security complement for adjacent scope, not as an
alternative answer to F170.

##### Excluded by gate

None. Gates for the pick: (1) MIT — pass. (2/3/5) Crate MSRV, RustSec,
features/async — inapplicable (Go binary). (4) OS matrix — pass:
release assets include `linux_amd64`, `linux_arm64`, `darwin_amd64`,
`darwin_arm64` tarballs [G9]; Windows zips also present
(informative). (6) No compile cost (prebuilt binary; py's
`install-actionlint` script shape is the install reference, adapted to
R42's bare-executable rule).

##### Up-and-comers

`zizmor` v1.30.1 (Rust, MIT, very active) — the field's rising tool,
but for workflow *security auditing*, a different check that would
stack alongside actionlint, not replace it. No syntax-check up-and-comer
exists.

##### Fit for this template

Direct fit: the template's CI is workflow-heavy (R11's `ci.yml` detector
+ tiered jobs, R12's aggregate, release/scanner lanes), so a schema
linter catching `runs-on`/input/expression mistakes before push pays
every week. Pre-commit cost is milliseconds on staged workflow files
only (py's `glob` scoping [P1]).

##### Recommendation

Keep `actionlint` v1.7.12 at both tiers: hook job on staged
`.github/workflows/*.{yml,yaml}` (bare `actionlint`, presence-guarded
with fail-and-guidance, py ADR-0018 shape) and the R11 workflow-lint CI
job (gated on the `workflows` key). Ship a minimal
`.github/actionlint.yaml` carrying only this item's tier needs; R09
owns its self-hosted-runner content.

##### Ranked runner-up

CI-only actionlint (drop the hook tier). Ranked below: saves nothing
measurable (millisecond binary) and surrenders the fast local catch;
ts's unwired state shows where that road ends.

##### Tradeoffs

One more binary install plus a config file whose content is split across
two items (tier here, rules in R09) — the split is the prompt's design,
and the file's ownership boundary must be commented in the file itself
to survive. actionlint's slow maintainer cadence means schema-lag
ignores (like ts's `create-github-app-token` carve-out [P2]) will recur;
that is handled by config, not by switching tools.

##### Parameters

None beyond the bundle-level assumes; owns nothing; no `CONFLICT:`.

##### Migration implications

Add `.github/actionlint.yaml` (minimal skeleton with the R09-ownership
comment); add one hook-job body (globbed to workflows) + the R11
workflow-lint CI job step invoking bare `actionlint`. No Cargo.toml
change.

##### Validation strategy

Executed (probe P3, 2026-09-26, actionlint 1.7.12): missing-`runs-on`
workflow failed with the expected `[syntax-check]` finding (exit 1);
clean workflow passed (exit 0). Planned, not executed: shellcheck
integration finding on an embedded `run:` defect; full-tree CI re-run.

##### Confidence & re-verify trigger

Medium-high on the tool, high on the tier. Re-verify on a concrete
at-risk signal (repo archived, 12+ months with no push, or a
broken-on-current-macOS release) or if `zizmor` grows a syntax-check
mode that subsumes actionlint's property — re-run the member, do not
assume substitution.

##### Sources

[G4] actionlint repo + release + open-issue figures; [G4b] issues
`#734`–`#742` + first comments (responsiveness sample); [G9]
release-asset list; [G6] [C3] zizmor figures (adjacent tool); [P1] py
`lefthook.yml` actionlint job + ADR-0018 comment; [P2] ts
`.github/actionlint.yaml` + advisory-only `Justfile` hint; probe P3
output.

#### editorconfig-baseline (F191/F192)

##### Landscape

The committed cross-editor formatting baseline file and its documented
per-filetype exceptions. The "field" is not a tool market but a
standard: the EditorConfig file format (`root = true`, charset/EOL/
indent/trim/final-newline properties), which editors implement natively
and member 1 verifies. Bins are therefore degenerate — built-in: none
(no Rust tool emits or owns `.editorconfig`); established: the
EditorConfig format itself, as realized in py's commented 30-line file
(UTF-8/LF/trim/final-newline defaults, indent 4, `[*.{yml,yaml,json,
toml}]` indent 2, `[Makefile]` tabs, `[*.md]` + `[*.ambr]` trim
carve-outs with rationale comments [P1]) and in rustc's root
`.editorconfig` [G8]; up-and-comers: none. All crate/GitHub/advisory
figures are **inapplicable**: this member is a committed text file in an
unversioned standard format, with no package, repo, release, or advisory
surface of its own.

##### Principles and implementation

Essential behavior: a fresh clone carries the baseline; every editor
that reads EditorConfig applies it without configuration; every
exception states its reason inline so a later reader can tell drift
from intent. Acceptance: the file exists at repo root with `root =
true`; a hardcoded review checklist (the F192 test) finds a rationale
comment above each exception stanza; member 1's check passes on the
committed tree. ts's absence of any `.editorconfig` is unexplained —
no `D-0nn` addresses it, and D-014(6)/(7) cover only the taplo/yamlfmt
installer removal [P2] [D1] — so it reads as drift, not as a reasoned
rejection, and the class-D harmonize-partly framing leaves the adopt
decision to value judgment: near-zero cost, positive editor coverage.
The `[*.md]` trim carve-out keeps Markdown hard breaks (py's rationale
stands unchanged). The `[*.ambr]` carve-out does **not** transfer:
syrupy/amber snapshots are Python-only. Its successor is `[*.snap]`
`trim_trailing_whitespace = false`: R33 adopted `insta` 1.48.0 with
committed snapshot files separate from test source [D2], and insta's
snapshot-file convention is the `*.snap` extension — flagged as gap G4
because the extension spelling was not re-verified against insta's
docs or sources in this leg (no local registry copy; docs outside
named endpoints). If synthesis confirms a different convention, the
stanza follows the confirmed spelling; the principle (snapshot bytes
are never editor-trimmed) is unaffected.

##### Dominant choice

Ship `.editorconfig` (py's file adapted: defaults unchanged; `[*]`
indent 4 matching rustfmt's default; `[*.{yml,yaml,json,toml}]` indent
2; `[Makefile]` tabs retained; `[*.md]` carve-out retained with its
rationale; `[*.snap]` carve-out replacing `[*.ambr]` with an
insta-rationale comment citing R33).

##### Qualified shortlist

Ship `.editorconfig` (sole member). "No baseline file" (ts status quo)
is not shortlisted: it saves one 30-line file while leaving editor
behavior undeclared and member 1 with nothing to verify.

##### Excluded by gate

None. All six fitness gates are inapplicable with reason: no license
(a 30-line config in a standard format carries no licenseable
dependency), no MSRV/dependency tree, no advisory surface, no OS build
(it is not built), no features/runtime, no compile cost. The applicable
quality bar is review: every stanza traceable to rustfmt defaults, R29
conventions, or a cited decision.

##### Up-and-comers

None — standards do not have up-and-comers in this sense; the
alternative (per-editor settings files) is strictly worse (N files, no
checker support).

##### Fit for this template

Exact fit: a template's contributors arrive with unknown editors; the
baseline is the only mechanism that reaches all of them before any
formatter runs. rustc shipping a root `.editorconfig` [G8] settles the
"does a Rust repo need one" question affirmatively.

##### Recommendation

Adopt the adapted `.editorconfig` as member content (this file *is* the
member). Exceptions: `[*.md]` and `[*.snap]`, each with an inline
rationale comment; drop `[*.ambr]`.

##### Ranked runner-up

Ship the baseline with `[*.md]` only (defer `[*.snap]` until the first
insta snapshot lands). Ranked below: R33 already decided snapshots are
committed, so the carve-out is known-needed, not speculative — with gap
G4 as the only hedge.

##### Tradeoffs

Thirty lines to maintain against R29's formatter conventions (indent
widths must agree or editors and formatters fight — a review coupling,
not a registry edge). Carries no tool, no install, no CI cost.

##### Parameters

None beyond the bundle-level assumes; owns nothing; no `CONFLICT:`.

##### Migration implications

Add `.editorconfig` at repo root with the adapted content. No hook job,
no CI step, no Cargo.toml change — member 1 enforces it.

##### Validation strategy

Planned, not executed: (1) review check — every stanza maps to a cited
default/decision and every exception has its rationale comment; (2)
`ec` full-tree pass over a fixture repo containing a hard-break `.md`
and a trailing-space `.snap` (blocked on gap G3, the unexecuted `ec`
binary).

##### Confidence & re-verify trigger

High on adoption, medium on the `[*.snap]` spelling (gap G4).
Re-verify the indent widths when R29 decides (formatter–editor
agreement), and the snapshot stanza if R33's snapshot layout changes.

##### Sources

[P1] py `.editorconfig` (full text at pin); [P2] ts absence + D-014
scope; [G8] rustc root `.editorconfig` (tree read); [D2] R33 `insta`
adoption; [D1] item class-D framing.

### Compatibility

The members compose by construction: four independent single-purpose
binaries plus one text file, with no shared library, runtime (except
yamllint's isolated Python), or config surface. Proof of joint
operation: (a) py at `b08bccf` runs all four hook jobs plus the
`.editorconfig` baseline in one lefthook stage [P1] — the substitution
of typos for codespell removes a runtime rather than adding coupling;
(b) `rust-lang/cargo` runs typos alongside its full CI matrix [G7];
(c) probes P1–P5 executed typos/yamllint/actionlint/codespell in one
directory without interference. Version matrix (all observed
2026-09-26): editorconfig-checker v4.0.2 + yamllint v1.38.0 + typos
v1.50.3 + actionlint v1.7.12 + unversioned `.editorconfig`. No member
constrains another's version. The one cross-member rule is editorial:
indent widths in `.editorconfig` must agree with rustfmt defaults and
R29's formatter choice (review coupling, re-verify trigger on member 5).

### Parameters

owns: none — this item owns no registry parameter.

assumes ci-job-structure = the R11 accepted value (run-inputs
`prerequisites.json`: acceptance
`774f76490a7f968960e71f5e1e38866592a064e3c17a453dd5223add0628eac1`):
operative excerpts for this item — "a check that compiles nothing is a
step of hygiene", "workflow-lint, gated on workflows, hosts only checks
whose whole input is the workflow tree", and hooks that "compile
nothing" carry "no cache step". Members 1–3 land as hygiene-job steps;
member 4 lands in workflow-lint.

assumes package-manager-invocation = the R42 accepted value (run-inputs
`prerequisites.json`: acceptance
`a3732b422e672ddc8793d69cb2b494eafb0579a4232e9c54f0017c2a8bf9eb93`):
"invoke every other tool as a bare executable resolved on PATH",
"use no provisioner, runner or package-manager prefix in any Justfile
recipe or lefthook job", "test presence by acquisition channel -
command -v \<executable\> for a tool installed from crates.io or from a
release". All four hook bodies use bare executables with `command -v`
presence guards.

No `CONFLICT:` line — no consumed value needs to change.

### Migration implications

Template files added: `.editorconfig` (member 5), `.editorconfig-checker.json`
(member 1, indent rules disabled, Rust-adapted Exclude), `.yamllint`
(member 2, py-pin rules, Rust-adapted ignore), `_typos.toml` (member 3,
seeded vocabulary), `.github/actionlint.yaml` (member 4 skeleton with
the R09-ownership-boundary comment). Hook-manager content (R37 owns the
manager; this item supplies the four job bodies): `ec -config
.editorconfig-checker.json {staged_files}` (all types),
`yamllint -c .yamllint {staged_files}` (glob `*.{yml,yaml}`),
`typos {staged_files}` (all types), `actionlint {staged_files}` (glob
`.github/workflows/*.{yml,yaml}`) — each presence-guarded, failing with
install guidance rather than skipping silently (py ADR-0018 shape).
CI content (slots under R11, not owned here): members 1–3 as hygiene-job
steps, member 4 as the workflow-lint job. Explicitly not carried:
`[*.ambr]`, any codespell config, any `uv run`/`uvx` prefix, any Cargo
alias. Follow-on (out of scope, rationale supplied): py replaces
codespell with typos; ts adopts the four checks + baseline (its
`.github/actionlint.yaml` finally gets a wired job).

### Validation strategy

Executed 2026-09-26 on macOS 15 / aarch64 (script `/tmp/r40probe.sh`,
kept out of the repo per the scratch rule): P1 typos 1.32.0 flagged
`sentance`→`sentence` + `teh`→`the` (exit 2) and passed clean text
(exit 0); P2 typos honored `_typos.toml` `[default.extend-words]` (exit
0); P3 actionlint 1.7.12 flagged missing `runs-on` with
`[syntax-check]` (exit 1) and passed the clean workflow (exit 0); P4
yamllint 1.38.0 with py-derived rules flagged `colons` + `commas` on
`bad.yml` (exit 1) and passed `good.yml` (exit 0); P5 codespell 2.4.2
flagged both seeded typos (exit 65) and passed clean (exit 0).
Expected behavior in the template: each seeded defect fails exactly its
own check and the fixed tree passes all four — the bundle's executable
acceptance check is the minimal example under `### Principles and
implementation` run with the four pinned versions. Planned, not
executed: the `ec` half of the example (gap G3), the truthy-carve-out
workflow case, shellcheck-integration findings, any hook-manager run
(R37 open), and any hosted-runner CI run (template not built).

### Confidence & re-verify trigger

Bundle confidence: medium-high. The capability set and three of five
members (typos, actionlint, `.editorconfig`) rest on executed probes
plus production precedent; yamllint rests on field dominance without a
Rust-native challenger; `editorconfig-checker` rests on precedent and
figures without an executed run. Gaps: G1 — no third-party Rust-project
survey beyond the four tree greps (page fetches outside named endpoints
were out of scope); G2 — issue-responsiveness sampled for typos (6
issues) and actionlint (5 issues) only, not for the runner-up field; G3
— `ec` behavior never executed (binary not installed); G4 — `[*.snap]`
spelling not re-verified against insta's docs/sources; G5 — Go-module
vulnerability state for the two Go binaries not checked (no named
endpoint covers it). Re-verify triggers: R29's formatter decision
(member 1 alternative B; member 5 indent widths); any Rust-native YAML
linter reaching 1.0 with a maintained adopter (member 2); concrete
neglect signals on actionlint or editorconfig-checker (member 4/1
`stable-quiet`→`at-risk` watch); annually otherwise.

### Sources

- [P1] py-launch-blueprint at `b08bccf` (local `git show`: `lefthook.yml`
  four jobs + ITM/ADR comments, `.editorconfig`, `.editorconfig-checker.json`,
  `.yamllint`), read 2026-09-26.
- [P2] ts-launch-blueprint at `cb1cbcb` (local `git show`: `lefthook.yml`,
  `Justfile` actionlint hint, `.github/actionlint.yaml`, D-020(6)/D-014
  comments), read 2026-09-26.
- [L1] `docs/port/COMMONALITY.md:171-174,195-196` (F167–F170, F191–F192
  ledger rows).
- [D1] `docs/port/DIVERGENCE-ANALYSIS.md:56-62,164-165,286-287` (R40 item
  class D harmonize-partly; F167 class C; analyst notes).
- [D2] `research/topics/33-property-and-snapshot-testing/DECISION.md`
  (R33 adopted `insta` 1.48.0, committed snapshot files).
- [G1] `GET https://api.github.com/repos/crate-ci/typos` (4,158 stars,
  Apache-2.0, pushed 2026-09-25) + `/releases/latest` (v1.50.3,
  2026-09-25) + `search/issues?q=repo:crate-ci/typos+is:issue+is:open`
  (126), all 2026-09-26 via authenticated REST.
- [G1b] Same endpoint family: issues `#1594`–`#1607` + first comments
  (responsiveness sample), 2026-09-26.
- [G2] `GET https://api.github.com/repos/codespell-project/codespell`
  (2,428 stars, GPL-2.0, pushed 2026-09-23) + `/releases/latest`
  (v2.4.3, 2026-07-15) + open-issue search (189), 2026-09-26.
- [G3] `GET https://api.github.com/repos/adrienverge/yamllint` (3,467
  stars, GPL-3.0, pushed 2026-09-19) + `/releases/latest` (v1.38.0,
  2026-01-13) + open-issue search (128), 2026-09-26.
- [G4] `GET https://api.github.com/repos/rhysd/actionlint` (4,265 stars,
  MIT, pushed 2026-07-16) + `/releases/latest` (v1.7.12, 2026-03-30) +
  open-issue search (143), 2026-09-26.
- [G4b] Same endpoint family: issues `#734`–`#742` + first comments
  (responsiveness sample), 2026-09-26.
- [G5] `GET
  https://api.github.com/repos/editorconfig-checker/editorconfig-checker`
  (638 stars, MIT, pushed 2026-09-21) + `/releases/latest` (v4.0.2,
  2026-09-19) + open-issue search (25), 2026-09-26.
- [G6] `GET https://api.github.com/repos/zizmorcore/zizmor` (6,579 stars,
  MIT, pushed 2026-09-26) + `/releases/latest` (v1.30.1, 2026-09-09) +
  open-issue search (137), 2026-09-26.
- [G7] `GET https://api.github.com/repos/rust-lang/cargo/contents/
  typos.toml` + `.../contents/.github/workflows/main.yml` (root typos
  config + `spellcheck` job via `crate-ci/typos@v1.50.0`), 2026-09-26.
- [G8] `GET https://api.github.com/repos/<o>/<r>/git/trees/HEAD?
  recursive=1` for rust-lang/rust, tokio-rs/tokio, rust-lang/cargo,
  serde-rs/serde, grepped for hygiene-tool traces, 2026-09-26.
- [G9] `GET https://api.github.com/repos/<o>/<r>/releases/latest`
  `.assets[].name` for editorconfig-checker + actionlint (linux/darwin
  prebuilt binaries incl. arm64), 2026-09-26.
- [C1] `GET https://crates.io/api/v1/crates/typos-cli` (1,002,025 /
  115,151 downloads, max 1.50.3) + `/versions` (newest non-yanked 1.50.3,
  2026-09-25, rust_version 1.95), 2026-09-26.
- [C2] `GET https://crates.io/api/v1/crates?q=yaml+lint&per_page=10`
  (`ryl`/`yamllint-rs`/`yaml-lint`/`fast-yaml-linter`/`linthis`
  versions + downloads), 2026-09-26.
- [C3] `GET https://crates.io/api/v1/crates/zizmor` (247,234 / 47,997
  downloads, max 1.30.1) + `/versions` (1.30.1, 2026-09-09, no
  rust_version), 2026-09-26.
- [R1] `https://rustsec.org/packages/typos-cli.html` → 404 page body (no
  advisories on record), fetched 2026-09-26.


