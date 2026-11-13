# R29 raw report (muse engine): non-code file formatting

Engine: muse. Run: research/runs/R29/2026-09-26T190157Z-3dd868e1695b. Item kind: bundle.
Retrieval date for every figure and claim below: 2026-09-27. Independence note: no other
engine's report was opened while writing this; all evidence comes from the topic's named
endpoints (crates.io API, api.github.com, rustsec.org) plus the run inputs.

### Landscape

Category decided: which tools format and check the template's non-Rust files (TOML, YAML,
JSON, Markdown) and how they are pinned and invoked. Rust-idiom map in the three required
bins:

- Built-in or first-party toolchain: none for these formats. `rustfmt` covers Rust source
  only (R27's scope, not this item's). `cargo` itself normalizes `Cargo.lock`, so no
  formatter may claim that file. The survey found no Rust-project-owned TOML, YAML, JSON,
  or Markdown formatter (crates.io search `q=yaml+format` / `q=yaml+formatter`, retrieved
  2026-09-27, returns only community crates; absence also confirmed by the lack of any
  first-party candidate in the dprint plugin registry below).
- Established industry standard: `taplo` / `taplo-cli` (TOML; py's enforced tool and the
  most-downloaded Rust TOML toolkit); `dprint` with its official `dprint-plugin-json`,
  `dprint-plugin-markdown`, and `dprint-plugin-toml` WASM plugins (JSON, Markdown, TOML);
  `comrak` (Markdown library plus CLI, 8.1M downloads); cross-ecosystem incumbents
  `yamlfmt` (Go YAML binary, py's configured-but-unwired tool) and `prettier` (JS
  YAML/JSON/Markdown formatter, fallback only, not shortlisted).
- Up-and-comer: `pretty_yaml` with its `dprint-plugin-yaml` WASM distribution (the only
  credible Rust-native YAML formatter found); `rumdl` (Rust Markdown linter plus
  formatter, beta, 88 rules); `dprint-plugin-toml` itself as a young independent TOML
  implementation. Below the adoption bar and not evaluated further: `noya-cli`/`noyafmt`
  (722 downloads), `oafmt` (OpenAPI-scoped, tens of downloads), `prim-cli` (283
  downloads), `jsonfizz` (60 downloads) — all from the same crates.io search endpoints,
  retrieved 2026-09-27.

Authority is established as follows. Maintainers' own documentation read through
`api.github.com/repos/<o>/<r>/contents/<path>` (READMEs, manifests, taplo's clap
definitions in `crates/taplo-cli/src/args.rs`) is authoritative for behavior, flags, and
config shape. `GET https://crates.io/api/v1/crates/<name>` and `.../versions` are
authoritative for downloads, releases, licenses, and declared `rust-version`.
`GET https://api.github.com/repos/<o>/<r>`, `/releases/latest`, and the issues search API
are authoritative for stars, push recency, binary distribution, and issue load.
`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies` is the practice
evidence. `https://rustsec.org/packages/<name>.html` is ground truth for advisories.
Method limit, stated plainly: network use was confined to these named endpoints, so the
annual Rust survey, project blogs, and vendor doc sites (dprint.dev, taplo.tamasfe.dev)
were not consulted; behavior claims rest on in-repo documentation and source instead.

Practice evidence from well-regarded Rust projects, with the evidence for their standing:
Deno (`deno` crate: 632,764 all-time downloads, repository `denoland/deno`, via crates.io
API, retrieved 2026-09-27) lists both `dprint-plugin-json` and `pretty_yaml` among its
dependencies (reverse-dependencies endpoints, retrieved 2026-09-27). `mise` (444,737
all-time downloads, repository `jdx/mise`) depends on `taplo`, alongside `esp-generate`,
`forc-fmt`, `metapac`, and `zino-cli` (taplo reverse-dependencies, 25 total, retrieved
2026-09-27). `dprint` itself dogfoods `dprint-plugin-yaml@0.6.0` together with its
official JSON, Markdown, and TOML plugins in its own `dprint.json` (repo file, retrieved
2026-09-27). `comrak` has 293 reverse dependents including `deno_doc` and `inlyne`
(retrieved 2026-09-27).

Fit framing for this template (CLI plus library plus web service): the template always
carries `Cargo.toml`, `rust-toolchain.toml`, `rustfmt.toml`, GitHub Actions YAML,
`lefthook.yml`, `README.md`, `docs/`, and `CHANGELOG.md`, so TOML and YAML formatting are
mandatory, and JSON/Markdown coverage is cheap once the engine is provisioned. The
template needs enforced check modes (nonzero exit on drift) for hooks and the R11 hygiene
job, pinned versions reproducible on `ubuntu-latest` and `macos-latest`, and disjoint
file ownership so no two tools fight over one file.

### Principles and implementation

Shared requirement: every covered non-code file is deterministically formatted and
machine-checkable, enforced identically on the developer's machine (hooks) and in CI.
Sources: py precedent (taplo enforced via hooks plus CI) and ts precedent (oxfmt enforced
via the same hook glob), per the prompt's `## Context`; the owner research mandate
(principle before libraries) makes enforcement the requirement and tool choice the
research. Agreement level: capability plus policy. What must agree: each covered format
has exactly one owner tool, every owner tool exposes a check mode that exits nonzero on
drift, versions are pinned, and ownership globs are disjoint. What may vary: style
options inside each tool's config (line width, quote style), which are template taste,
not cross-repo contract. Observable acceptance criteria: (1) a clean tree passes every
check command with exit 0; (2) a tree with one dirty file per format fails each
corresponding check with nonzero exit and names the file; (3) formatting twice is a
fixed point (second run changes nothing); (4) `Cargo.lock` is never rewritten by any
formatter.

Architectural alternatives compared before choosing libraries. (A) Per-format
best-of-breed, py-style: taplo plus yamlfmt plus one JSON and one Markdown tool — four
binaries, four configs, four hook/CI invocations; maximal maturity per slot, maximal
provisioning surface. (B) Unified runner plus a TOML specialist (recommended): taplo owns
TOML for its schema-aware lint and ecosystem dominance, while one `dprint` binary owns
YAML, JSON, and Markdown through three pinned WASM plugins (two official, one
community). Two binaries, two configs, two invocations. (C) Prettier-everything:
rejected — it needs a Node toolchain the template otherwise avoids, is not
Rust-ecosystem-native, and still cannot do TOML. (D) Leave YAML (or JSON/Markdown)
unenforced, mirroring py's configured-but-unwired yamlfmt: rejected — it violates the
enforced-formatting principle for files the template always carries. The ts one-tool
instinct (oxfmt) does not transfer literally because no single Rust-native binary covers
all four formats; alternative (B) is the closest Rust-idiomatic equivalent, splitting
only where the ecosystem has a dominant specialist.

How the recommended design preserves each principle: taplo's `format --check` (verified
in clap source, retrieved 2026-09-27) and dprint's `check` (verified in the dprint/check
action README: "fails if something is not properly formatted") satisfy enforcement;
versioned plugin URLs with `@sha` checksum suffixes (form observed in dprint's own
`dprint.json`) satisfy pinning; extension routing (`.toml` to taplo; `.yml`/`.yaml`,
`.json`/`.jsonc`, `.md` to dprint plugins) plus an `excludes` list (`Cargo.lock`,
`target/`) satisfies disjoint ownership. Reference implementations: dprint's self-hosted
`dprint.json` (multi-plugin config with excludes and checksums) and Deno's joint
adoption of `dprint-plugin-json` and `pretty_yaml`. Maturity, dependability,
performance, and integration cost per member are compared in `### Members`; no absolute
speed ranking is inferred (unlike benchmarks were not run; template-scale formatting is
seconds-bounded for every candidate, and dprint caches incrementally per the
dprint/check README). Minimal realistic example: a fixture tree with one dirty file per
format plus a `Cargo.lock` and `target/` decoy, checked by the two commands in
`### Validation strategy`. No `BASELINE-REVIEW:` finding: ledger rows F097/F098/F099 keep
their `DIVERGENT` verdicts — the split of TOML to taplo with YAML/JSON/Markdown unified
under dprint is this item's decision, not a challenge to another item or the ledger.

### Recommendation

One stack: `taplo-cli 0.10.0` for TOML plus `dprint 0.57.4` for YAML, JSON, and Markdown
with three pinned plugins — `dprint-plugin-json 0.24.0`, `dprint-plugin-markdown 0.24.0`,
and `dprint-plugin-yaml` (pretty_yaml) `0.6.0`. Two configs: `.taplo.toml` and
`dprint.json`. Two check invocations (`taplo format --check`, `dprint check`) wired as
separate lefthook jobs in the same tier and as steps of R11's hygiene job. JSON and
Markdown coverage is included; `Cargo.lock` is excluded from every formatter.

### Members

Four format members follow, one per covered format, each with the full crate field set.

#### TOML formatting

##### Landscape

TOML-formatter map: no first-party tool exists. Established: taplo (library `taplo`
0.14.0 plus CLI `taplo-cli` 0.10.0, single repo `tamasfe/taplo`). Up-and-comer:
`dprint-plugin-toml` 0.8.0, an independent implementation on `dprint-core` 0.69 with its
own TOML parser and TOML 1.1 support (plugin Cargo.toml and README, retrieved
2026-09-27) — it does not wrap taplo. Authority and practice evidence are the
maintainer sources plus crates.io and reverse-dependency data cited under `##### Sources`.

##### Principles and implementation

TOML files always exist in this template (`Cargo.toml`, `rust-toolchain.toml`,
`rustfmt.toml`, `.taplo.toml` itself), so TOML formatting is mandatory, not conditional.
Beyond formatting, schema-aware validation is uniquely valuable here: a malformed
`Cargo.toml` breaks every compile-tier job, and taplo's `lint` command validates
documents against a schema URL or catalog (`--schema`, `--schema-catalog`,
`--default-schema-catalogs`, `--no-schema` in `crates/taplo-cli/src/args.rs`, retrieved
2026-09-27). dprint-plugin-toml is format-only with no schema support. The check mode
must be a dry run that reports unformatted files: taplo provides exactly that via
`format --check` ("Dry-run and report any files that are not correctly formatted") with
`--diff` for patch output and `-` for stdin (same source). Config discovery is
automatic unless `--no-auto-config`, overridable via `--config`/`-c` or `$TAPLO_CONFIG`,
and `taplo config default` prints a seed `.taplo.toml` (same source).

##### Dominant choice

taplo. Figures, all retrieved 2026-09-27. crates.io: `taplo-cli` 2,224,667 all-time /
194,730 recent (90-day) downloads, 0.10.0 released 2025-05-23, `rust-version 1.74`,
`MIT`; library `taplo` 3,562,106 / 736,294, 0.14.0 released 2025-05-22. GitHub
`tamasfe/taplo`: 2,402 stars, not archived, pushed 2026-07-28, license MIT; 199 open
issues (issues search API). Distribution answers the prompt's HIGH question directly:
`cargo install taplo-cli` serves the current 0.10.0 (same version and date as the GitHub
release, whose 13 assets cover linux/darwin/windows on x86_64 plus arm variants at
about 4.6–5.2 MB gzipped), and the repo has no root `package.json` (contents API 404,
retrieved 2026-09-27), so npm is not the repo's primary channel — cargo plus release
binaries are current, and any `@taplo/cli` currency question is immaterial to this
recommendation. Adopters (reverse-dependencies, 25 total): `mise`, `esp-generate`,
`forc-fmt`, `metapac`, `zino-cli`, `cargo-fmt-toml`, plus `taplo-cli` itself. Fitness
gates: (1) MIT, compatible; (2) declared rust 1.74 builds on any recent toolchain —
passes as a dev-time binary (not linked into the template); the template's MSRV floor
constrains template code, and a tool older than the floor is not a failure; (3) no
rustsec advisory page exists (HTTP 404, meaning no reported advisories); `unsafe`
posture not audited — method limit, stated; (4) release binaries cover linux and darwin
on x86_64 and aarch64, hence both CI runners, plus Windows; (5) default features are
`completions, lint, lsp, rustls-tls, toml-test` (CLI Cargo.toml); tokio is a
non-optional dependency (binary-internal `rt-multi-thread` use — no feature unification
with the template); (6) ~5 MB binary; 28 normal dependencies make `cargo install` a
moderate build — release binaries are preferred for provisioning. Maintenance state:
`stable-quiet` — no release in 16 months is the trigger to investigate, and the
investigation says slow but alive (pushed 2026-07-28); tempered by 199 open issues and
6/6 of the most recent open issues unanswered with zero comments (responsiveness sample,
method in `##### Sources`), so taplo is dependable but not briskly maintained.

##### Qualified shortlist

`dprint-plugin-toml` 0.8.0 (released 2026-08-18; 19,633 all-time / 2,223 recent
downloads; MIT; repo 24 stars, pushed 2026-09-05, 2 open issues; `plugin.wasm` 510,627
bytes plus `schema.json` release assets; installed via `dprint add toml`). It qualifies
because it is the zero-marginal-cost TOML owner if dprint is already provisioned, is
actively released, and supports TOML 1.1. It is not the pick because adoption is two
orders of magnitude below taplo's, it has no schema validation or LSP story, and its
independent parser has far less production exposure than taplo's.

##### Excluded by gate

None. No TOML-capable candidate failed a fitness gate. (Non-TOML tools such as Biome,
prettier, and jq are out of category for this member, not gate failures.)

##### Up-and-comers

`dprint-plugin-toml` is both the qualified shortlist and the rising alternative; no
further up-and-comer clears the bar. (A dependent named `tomt` appears in taplo's
reverse dependencies, but it was not evaluated — insufficient signal, stated as a gap
rather than a claim.)

##### Fit for this template

taplo fits because the template's most failure-critical files are TOML: `taplo format
--check` enforces style and `taplo lint` can additionally validate `Cargo.toml` against
a schema. One caution: `--default-schema-catalogs` implies online catalogs, so
schema linting is recommended as opt-in (local `--schema` pin or offline-tolerant
invocation), while `format --check` is the enforced gate. Invocation per R42's
`package-manager-invocation` is the bare `taplo` executable on PATH (it is not a
`cargo-<sub>`).

##### Recommendation

`taplo-cli 0.10.0`, provisioned from the 0.10.0 release binaries (preferred) or `cargo
install taplo-cli --version 0.10.0 --locked`, configured by a new `.taplo.toml` seeded
from `taplo config default`, enforcing `taplo format --check` over `**/*.toml`.

##### Ranked runner-up

`dprint-plugin-toml` 0.8.0 via the dprint binary — choose it only if a later decision
forces a single-binary constraint and drops taplo; the cost is losing schema validation
and taplo's adoption depth.

##### Tradeoffs

taplo buys dominance (2.2M CLI downloads, mise/esp-generate/forc-fmt adoption),
schema-aware lint, and a real LSP, at the price of a second binary plus config and a
`stable-quiet` maintenance pace with 199 open issues. dprint-plugin-toml buys unity
with the YAML/JSON/Markdown path and brisk releases at the price of immaturity (19k
downloads, 24 stars) and format-only behavior. The template's TOML files are too
failure-critical to trade away taplo's depth for unity.

##### Parameters

This member owns no registered parameter. It assumes `package-manager-invocation`
(R42): taplo is invoked as the bare `taplo` executable resolved on PATH, with presence
tested by `command -v taplo`. No `CONFLICT:` — nothing in the consumed parameters needs
to change.

##### Migration implications

New `.taplo.toml` at the repo root. One Justfile recipe running the check command. One
lefthook job in the format tier. Steps (version assertion plus check) in R11's hygiene
job. No `Cargo.toml` dependency changes: taplo is an external binary, never linked.

##### Validation strategy

All checks below are PROPOSED — none has been executed (no tool installs were performed;
network was limited to the evidence endpoints). (1) `taplo --version` reports 0.10.0.
(2) On a fixture tree with one dirty `Cargo.toml` (misaligned keys) and one clean file,
`taplo format --check --diff "fixtures/toml/**/*.toml"` exits nonzero and names only
the dirty file. (3) `taplo format` on the fixture followed by `git diff --exit-code`
after a second run proves idempotence. (4) Optional: `taplo lint --no-schema` passes a
valid manifest and fails a malformed one. Expected behavior in each case is the stated
exit code plus file attribution; any deviation fails the member.

##### Confidence & re-verify trigger

High. Re-verify on: taplo archived or an at-risk signal (unpatched advisory, maintainer
deprecation notice, or build breakage on current stable); `dprint-plugin-toml` gaining
schema validation plus adoption within an order of magnitude of taplo's; or 2027-09-30,
whichever comes first.

##### Sources

`GET https://crates.io/api/v1/crates/taplo-cli`, `/taplo`,
`/taplo-cli/0.10.0/dependencies`, `/taplo/reverse_dependencies` (retrieved 2026-09-27);
`GET https://api.github.com/repos/tamasfe/taplo`,
`.../releases/latest`, `.../contents/crates/taplo-cli/src/args.rs`,
`.../contents/crates/taplo-cli/Cargo.toml`, `.../contents/package.json` (404),
`/search/issues?q=repo:tamasfe/taplo+is:issue+is:open`, `/repos/tamasfe/taplo/issues`
plus per-issue comments for responsiveness (method: 10 most recent open non-PR issues,
first comment by a non-author maintainer association; 6/6 unanswered) (retrieved
2026-09-27); `GET https://api.github.com/repos/dprint/dprint-plugin-toml` and
`.../releases/latest` (retrieved 2026-09-27);
`https://rustsec.org/packages/taplo-cli.html` and `/taplo.html` (HTTP 404 = no reported
advisories, retrieved 2026-09-27). The prompt's rustfmt-link claim for taplo is
UNVERIFIED: `src/tools/rustfmt/Cargo.toml` in `rust-lang/rust` contains no taplo
dependency (retrieved 2026-09-27); the recommendation does not depend on it.

#### YAML formatting

##### Landscape

YAML-formatter map: no first-party tool exists. Cross-ecosystem established tools are
`yamlfmt` (Go, Google-origin) and `prettier` (JS, fallback only). The Rust-native field
from crates.io search (`q=yaml+format`, `q=yaml+formatter`, retrieved 2026-09-27) has
exactly one credible formatter: `pretty_yaml` ("Semi-tolerant and configurable YAML
formatter", 840,275 downloads). Everything else is niche (`noya-cli` 722 downloads),
out of scope (`oafmt`, OpenAPI-only, tens of downloads), or a parser/emitter library
rather than an enforceable formatter (`yamlpath`, `yamlpatch`, `serde_yaml`). No
official dprint YAML plugin exists (dprint org repo listing, retrieved 2026-09-27), but
dprint's own README lists `pretty_yaml` as the YAML formatter for dprint, and dprint
dogfoods `dprint-plugin-yaml@0.6.0` in its own `dprint.json`.

##### Principles and implementation

YAML files in this template (GitHub Actions workflows, `lefthook.yml`, linter configs)
are whitespace-significant and CI-critical: a reformatting that changes semantics is
worse than none, so the formatter must be syntax-preserving with a check mode. Two
architectures satisfy this: a standalone YAML binary with a lint flag (`yamlfmt
-lint`, documented in its README's CI example), or a dprint WASM plugin sharing one
binary, one config, and one invocation with JSON and Markdown. The plugin path is
preferred here because dprint is already provisioned for two other formats, the plugin
is version-pinned by URL, and Deno's adoption plus dprint's own dogfooding derisk the
community origin. pretty_yaml integrates via `dprint config add g-plane/pretty_yaml`
with plugin URL `https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm` and a
`yaml` config key in `dprint.json` (pretty_yaml README, retrieved 2026-09-27).

##### Dominant choice

`pretty_yaml` 0.6.0, distributed as the `dprint_plugin_yaml` WASM plugin. Dominance is
stated carefully: no Rust-native YAML formatter dominates the way taplo dominates TOML,
but within Rust-native formatters pretty_yaml leads outright, and it is the only one
with top-tier adoption. Figures, all retrieved 2026-09-27. crates.io `pretty_yaml`:
840,275 all-time / 241,855 recent downloads, 0.6.0 released 2026-01-09, `MIT`, no
declared `rust-version`. GitHub `g-plane/pretty_yaml`: 52 stars, not archived, pushed
2026-08-26, MIT; 2 open issues. Releases v0.3.0 through v0.6.0 each ship `plugin.wasm`
plus `schema.json` (the crate itself sets `publish = false` for the plugin member —
distribution is the WASM asset, verified in `dprint_plugin/Cargo.toml`, which builds on
`dprint-core 0.69` with the `wasm` feature). Adopters (reverse-dependencies, 7 total):
the `deno` crate itself, plus `deno_lib_ext`, `deno_tauri`, `serde_pretty_yaml`,
`prim-fmt`, `panache-formatter`, `lintel-format`. Fitness gates: (1) MIT, compatible;
(2) no declared `rust-version` — gap stated; the shipped artifact is prebuilt WASM run
by dprint's wasmtime, so no template toolchain builds it — passes in the only sense
that applies; (3) no rustsec advisory page (HTTP 404); `unsafe` posture not audited —
method limit, stated; (4) WASM is platform-independent and the host dprint ships
linux/darwin x86_64+aarch64 binaries (verified under JSON member) — passes on both CI
runners; (5) inapplicable as a linked-crate concern (plugin, not a dependency); the
library has 4 normal dependencies (`rowan`, `serde`, `tiny_pretty`, `yaml_parser`) and
no async runtime; (6) prebuilt WASM means zero compile cost at install; binary size not
collected — gap stated rather than guessed. Maintenance state: `stable-quiet` — the
2026-01-09 release is past the 6-month trigger, but the repo was pushed in August 2026
and carries only 2 open issues; both are unanswered with zero comments (responsiveness
sample), including #4, an open block-scalar correctness report — that issue is the
explicit caveat on this choice and shapes the validation fixtures below.

##### Qualified shortlist

`yamlfmt` v0.21.0 (Go). The mature cross-ecosystem incumbent: repo `google/yamlfmt`,
1,830 stars, not archived, pushed 2026-09-24, Apache-2.0, 51 open issues; v0.21.0
released 2026-01-05 with Darwin/Linux/Windows binaries (x86_64 plus arm64) and
cosign-verified `checksums.txt` (release assets, retrieved 2026-09-27); single
self-sufficient binary, `yamlfmt -lint .` is the documented CI check form (README). Two
caveats from its own README: it is "not yet officially supported by Google" and is
"maintained solely by @braydonk ... primarily in spare time". Crate figures are
inapplicable with reason (Go binary, not a crate); license Apache-2.0 is compatible;
OS matrix passes via release binaries; advisory coverage via the Go vulnerability
database was not checked — gap stated (rustsec covers crates only). Responsiveness: the
2 most recent open non-PR issues are both unanswered with zero comments, including a
multiline-string correctness report (#328) — comparable wart to pretty_yaml's #4, so
correctness risk does not separate the two.

##### Excluded by gate

None. No YAML-capable candidate failed a fitness gate. (`prettier` was not evaluated
against the gates because it was never shortlisted: it needs a Node toolchain for one
format and loses on fit before gates matter.)

##### Up-and-comers

`noya-cli` (`noyafmt`), `oafmt` (OpenAPI-scoped semantic formatting), and `prim-cli`
("formatter for a repository's connective tissue") are noted from crates.io search but
all sit below 1,000 downloads with no significant adoption — watched, not evaluated.

##### Fit for this template

pretty_yaml fits because the template's YAML (workflows, lefthook) is formatted by the
same `dprint check` that already covers JSON and Markdown: no third binary, no third
config file, no third hook job. The `yaml` key in `dprint.json` plus one pinned plugin
URL is the entire wiring. yamlfmt would add a Go binary, a `.yamlfmt` config, and a
separate hook/CI step to reproduce py's shape without py's excuse (py had no unified
runner; this template does).

##### Recommendation

`pretty_yaml` 0.6.0 via the dprint plugin URL
`https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm` (URL form from the
pretty_yaml README), configured under the `yaml` key of `dprint.json`, enforced through
`dprint check`.

##### Ranked runner-up

`yamlfmt` v0.21.0 (Go release binary, pinned by version plus checksum). Choose it if the
synthesis or empirical audit finds pretty_yaml's #4-class block-scalar behavior
unacceptable on the template's workflow fixtures, or if a policy against community
plugins is adopted. The switch cost is low: one binary, one `.yamlfmt` file, one hook
job, one CI step.

##### Tradeoffs

pretty_yaml buys Rust-native implementation, one-tool unity with JSON/Markdown,
Deno adoption, dprint's own dogfooding, and prebuilt-WASM provisioning at the price of
a small community footprint (52 stars, single maintainer) and an open scalar-correctness
issue. yamlfmt buys 1,830 stars of battle-testing and a standalone binary at the price
of a non-Rust toolchain dependency, a second config surface, and its own spare-time
maintenance plus open correctness issues. Neither candidate is wart-free; the deciding
factors are ecosystem fit and provisioning unity, both favoring pretty_yaml, with
yamlfmt held as a low-cost fallback — the reverse of ts's D-014(7) arrangement, for
Rust-ecosystem reasons stated above.

##### Parameters

This member owns no registered parameter. It assumes `package-manager-invocation`
(R42): `dprint` is invoked as a bare executable resolved on PATH (it is not a
`cargo-<sub>`). No `CONFLICT:`.

##### Migration implications

No new standalone config file: one `yaml` section plus one plugin URL inside the
`dprint.json` created for the JSON member. No new hook job or CI step beyond the shared
`dprint check` ones. If the runner-up is chosen instead: new `.yamlfmt`, one Justfile
recipe, one lefthook job, one hygiene step.

##### Validation strategy

All checks PROPOSED, none executed. (1) `dprint check` on a fixture set passes with
exit 0 when clean: a GitHub Actions workflow (anchors, expressions, multiline `run: |`
blocks), a `lefthook.yml` analogue, and a pretty_yaml-#4-style block-scalar case.
(2) One dirty fixture (misindented mapping) fails `dprint check` with nonzero exit and
file attribution. (3) `dprint fmt` then re-run proves idempotence. (4) The
block-scalar fixture is asserted byte-stable across two runs; if pretty_yaml mangles
it, the runner-up yamlfmt is evaluated on the same fixture and the member
recommendation flips. Expected behavior is the stated exit codes; any silent rewrite or
non-fixed-point fails the member.

##### Confidence & re-verify trigger

Medium-high: the evidence is strong but the community footprint is small. Re-verify on:
pretty_yaml archived or #4-class correctness issues multiplying without response;
dprint shipping an official YAML plugin (prefer it on maturity); yamlfmt reaching a
supported-maintenance state while pretty_yaml stalls; or 2027-03-31, whichever comes
first.

##### Sources

`GET https://crates.io/api/v1/crates/pretty_yaml`,
`.../pretty_yaml/versions`, `.../pretty_yaml/0.6.0/dependencies`,
`.../pretty_yaml/reverse_dependencies`, crates search `q=yaml+format` and
`q=yaml+formatter` (retrieved 2026-09-27);
`GET https://api.github.com/repos/g-plane/pretty_yaml`,
`.../releases?per_page=5`, `.../contents/dprint_plugin/Cargo.toml`,
`.../contents/Cargo.toml`, `.../contents/README.md`,
`/search/issues?q=repo:g-plane/pretty_yaml+is:issue+is:open`,
`.../issues?state=open&sort=created&direction=desc&per_page=10` (2/2 unanswered)
(retrieved 2026-09-27); `GET https://api.github.com/orgs/dprint/repos?per_page=100`
(no YAML plugin), `.../repos/dprint/dprint/contents/README.md` (lists pretty_yaml),
`.../repos/dprint/dprint/contents/dprint.json` (dogfoods `dprint-plugin-yaml@0.6.0`)
(retrieved 2026-09-27); `GET https://api.github.com/repos/google/yamlfmt`,
`.../releases/latest`, `.../contents/README.md`,
`/search/issues?q=repo:google/yamlfmt+is:issue+is:open`, recent-issues sample (2/2
unanswered) (retrieved 2026-09-27);
`https://rustsec.org/packages/pretty_yaml.html` (HTTP 404 = no reported advisories,
retrieved 2026-09-27).

#### JSON formatting

##### Landscape

JSON-formatter map: no first-party tool exists. Established: `dprint-plugin-json`
(Rust, official dprint plugin), `prettier` (JS, fallback only), `biome` (Rust-written
but npm-distributed JS-platform formatter with JSON/JSONC support), `jq` (ubiquitous C
processor). Up-and-comers: none of note (`jsonfizz`, 60 downloads, is negligible).
This member also carries the full figures for the shared `dprint` CLI binary, which the
YAML and Markdown members pin by reference.

##### Principles and implementation

JSON files in this template are few but real: `dprint.json` itself (self-hosted),
editor configs such as `.vscode/*.json`, test fixtures, and any JSON schemas the web
surface ships. The hard rule is exclusion, not style: `Cargo.lock` must never be
claimed by the JSON formatter — cargo owns that file (R49's `build-tool-output-shape`
covers the manifest surface) and a formatter fighting cargo produces churn on every
build. dprint satisfies this structurally: extension routing plus a top-level
`excludes` list (form verified in dprint's own `dprint.json`, which excludes
`**/target`, lockfiles, and build output). Enforcement is `dprint check`, which "fails
if something is not properly formatted" (dprint/check action README), with
`dprint fmt` as the writer and download-plus-incremental caching for CI speed (same
source). The plugin is added per project via `dprint add json` (plugin README).

##### Dominant choice

`dprint-plugin-json` 0.24.0, run by `dprint` 0.57.4. Plugin figures, all retrieved
2026-09-27: 869,002 all-time / 159,493 recent downloads; 0.24.0 released 2026-09-15;
MIT; repo `dprint/dprint-plugin-json`, 30 stars, not archived, pushed 2026-09-15; 6
open issues; release assets `plugin.wasm` (636,736 bytes) plus `schema.json`; built on
the `jsonc-parser` parser (plugin README); reverse-dependencies (16 total) include the
`deno` crate. Host CLI figures: `dprint` crate 239,963 all-time / 11,573 recent
downloads, described on crates.io as "Binary for dprint code formatter" (so `cargo
install dprint` is a supported channel); 0.57.4 released 2026-09-05, MIT, no declared
`rust-version`; repo `dprint/dprint`, 4,079 stars, not archived, pushed 2026-09-15;
59 open issues; responsiveness sample (method as in TOML member): 1 answered with
0.4-day first maintainer response, 5 unanswered of the 6 most recent open non-PR
issues — the unanswered ones are website/registry requests, not formatter defects;
0.57.4 release ships 17 assets covering `aarch64`/`x86_64` `apple-darwin` and
`unknown-linux-gnu` (plus musl, Windows, and others) at roughly 8–11 MB per zip, and
releases from 0.57.1 carry build-provenance attestations verified by the dprint/check
action. Fitness gates (plugin plus host): (1) MIT throughout, compatible; (2) no
declared `rust-version` on the CLI — gap stated; September-2026 release builds on
current stable qualitatively; both artifacts are prebuilt (native binary plus WASM),
so the template toolchain builds neither; (3) no rustsec advisory pages for `dprint`
or `dprint-plugin-json` (HTTP 404); `unsafe` posture not audited — method limit;
(4) passes on both CI runners via the release binaries above; (5) inapplicable as a
linked-crate concern; implementation facts for the record: the CLI has 48 normal
dependencies including tokio and wasmtime (plugin sandbox runtime), and plugin refs
support `@sha` checksum suffixes (form observed in dprint's own `dprint.json`);
(6) ~8–11 MB binary; `cargo install` would compile wasmtime plus 48 crates and is
discouraged for provisioning — release binaries (or the attestation-verifying
dprint/check action pattern) are the recommended channel. Maintenance state: `active`
(releases within days, pushed 2026-09-15).

##### Qualified shortlist

`biome` (Rust-written formatter with JSON/JSONC support): repo `biomejs/biome`, 25,863
stars, Apache-2.0 (compatible), pushed 2026-09-27 (all retrieved 2026-09-27). It
qualifies on maturity and JSON competence but loses on distribution and scope: there is
no `biome_cli` crate on crates.io (verified absent, retrieved 2026-09-27), so
cargo-install provisioning is unavailable and the template would inherit an npm
channel for one format; its JS/TS/CSS scope far exceeds the need. `jq` (C): ubiquitous
and tiny, but it has no native check mode — enforcement would be a diff round-trip
pattern (`jq empty` plus output comparison) that is a hack, not a gate — and it is
out-of-ecosystem. Both pass the fitness gates; both lose on fit.

##### Excluded by gate

None. No JSON-capable candidate failed a fitness gate.

##### Up-and-comers

None. No rising JSON formatter clears the adoption bar.

##### Fit for this template

`dprint-plugin-json` fits because it rides the already-provisioned dprint binary and
`dprint.json`: JSON coverage costs one plugin URL, with `Cargo.lock`, `target/`, and
generated files excluded by the shared `excludes` list. The ts precedent (oxfmt
covering JSON) is honored in Rust-idiomatic form without a JS toolchain.

##### Recommendation

`dprint-plugin-json` 0.24.0 via `dprint` 0.57.4, pinned by versioned plugin URL with a
checksum suffix, enforced through `dprint check`, with `Cargo.lock` and `target/`
excluded.

##### Ranked runner-up

`biome` (latest release binary): choose it only if a later item brings a JS/TS
formatting need into the template, at which point Biome's wider scope amortizes its
npm-distributed provisioning. For JSON alone it is over-scope and under-integrated.

##### Tradeoffs

dprint-plugin-json buys unity (one binary/config/invocation for three formats),
Deno adoption, checksummed WASM provisioning, and attested releases at the price of a
heavier host binary (~8–11 MB, wasmtime inside) and first-run plugin download (cached
thereafter). Biome buys the strongest JSON-plus-JS engine and 25k-star momentum at the
price of an npm provisioning channel and unused scope. jq buys zero new dependencies
where present at the price of a check-mode hack and no config surface. For a Rust
template already running dprint for YAML and Markdown, the plugin is strictly cheapest.

##### Parameters

This member owns no registered parameter. It assumes `package-manager-invocation`
(R42): `dprint` is invoked as a bare executable on PATH, presence tested by `command
-v dprint`. The dprint/check action's download-and-verify pattern is noted as a CI
option for synthesis; it does not change the invocation shape. No `CONFLICT:`.

##### Migration implications

New `dprint.json` at the repo root (shared with the YAML and Markdown members):
`plugins` entries for json (this member), markdown, and yaml; shared `excludes`
(`Cargo.lock`, `**/target`, generated dirs); per-format config keys as needed. One
Justfile recipe, one lefthook job, and hygiene-job steps shared across the three
dprint-covered formats. No `Cargo.toml` changes.

##### Validation strategy

All checks PROPOSED, none executed. (1) `dprint --version` reports 0.57.4 and `dprint
check` passes with exit 0 on a clean fixture tree. (2) A dirty fixture (misindented
`.vscode/settings.json` analogue) fails with nonzero exit and file attribution.
(3) `dprint fmt` then re-run proves idempotence. (4) A `Cargo.lock` decoy containing
deliberately non-canonical JSON is byte-identical after `dprint fmt`, proving
exclusion. (5) First run downloads and caches plugins; a second run with network
disabled still passes, proving cache sufficiency for CI. Expected behavior is the
stated exit codes plus attribution; any deviation fails the member.

##### Confidence & re-verify trigger

High. Re-verify on: dprint archived or an at-risk signal; `dprint-plugin-json`
unmaintained past two dprint-core generations; Biome publishing a cargo-installable
CLI while a JS-formatting need appears; or 2027-09-30, whichever comes first.

##### Sources

`GET https://crates.io/api/v1/crates/dprint`, `.../dprint/versions`,
`.../dprint/0.57.4/dependencies`, `.../dprint-plugin-json`,
`.../dprint-plugin-json/reverse_dependencies`, `.../crates/biome_cli` (absent)
(retrieved 2026-09-27); `GET https://api.github.com/repos/dprint/dprint`,
`.../releases/latest`, `.../contents/README.md`, `.../contents/dprint.json`,
`.../repos/dprint/check/contents/README.md`,
`.../repos/dprint/dprint-plugin-json[/releases/latest|/contents/README.md|/contents/Cargo.toml]`,
`/search/issues?q=repo:dprint/dprint+is:issue+is:open`, recent-issues sample with
comments (1 answered at 0.4d, 5 unanswered of 6) (retrieved 2026-09-27);
`GET https://api.github.com/repos/biomejs/biome` (retrieved 2026-09-27);
`https://rustsec.org/packages/dprint.html` and `/dprint-plugin-json.html` (HTTP 404 =
no reported advisories, retrieved 2026-09-27).

#### Markdown formatting

##### Landscape

Markdown-formatter map: no first-party tool exists. Established: `dprint-plugin-markdown`
(Rust, official dprint plugin), `comrak` (Rust CommonMark/GFM library plus CLI, 8.1M
downloads), `markdownlint-cli2` (JS, lint-oriented), `mdformat` (Python). Up-and-comer:
`rumdl` (Rust Markdown linter plus formatter, self-declared beta, markdownlint-compatible).
The `dprint` CLI figures are stated once under the JSON member and pinned by reference
here.

##### Principles and implementation

Markdown files in this template ship to users: R49's `build-tool-output-shape` packages
`/README.md` and `/CHANGELOG.md`, and `docs/` plus `.github/*.md` are the contributor
surface — so Markdown formatting is user-facing quality, not cosmetic. GitHub renders
GFM, so the formatter must preserve GFM constructs (tables, task lists, autolinks).
Scope discipline matters more here than in any other member: the need is deterministic
formatting with a check mode, not 88 lint rules to configure and tune — a linter belongs
to a lint decision (R28 owns the linter's config surface), while this item owns
formatting. That scoping is what ranks a formatter-only plugin above a stronger but
broader linter-formatter.

##### Dominant choice

`dprint-plugin-markdown` 0.24.0, run by `dprint` 0.57.4. Plugin figures, all retrieved
2026-09-27: 904,256 all-time / 148,650 recent downloads; 0.24.0 released 2026-09-10;
MIT; repo `dprint/dprint-plugin-markdown`, 58 stars, not archived, pushed 2026-09-10;
4 open issues; release assets `plugin.wasm` (761,907 bytes) plus `schema.json`.
Fitness gates: (1) MIT, compatible; (2) prebuilt WASM, nothing compiled by the
template toolchain — passes; (3) no rustsec advisory page (HTTP 404); `unsafe`
posture not audited — method limit; (4) passes on both CI runners via the host dprint
binaries (verified under JSON member); (5) inapplicable as a linked-crate concern;
(6) zero compile cost (prebuilt WASM, 761,907 bytes). Maintenance state: `active`
(released 2026-09-10, pushed same week).

##### Qualified shortlist

`comrak` 0.55.0: 8,156,412 all-time / 2,376,277 recent downloads; 0.55.0 released
2026-09-06 with declared `rust-version 1.85` (README states "supports Rust 1.85+");
`BSD-2-Clause` — a permissive license compatible with `MIT OR Apache-2.0`; repo
`kivikakk/comrak`, 1,710 stars, not archived, pushed 2026-09-23; 10 open issues; 293
reverse dependents including `deno_doc`, `inlyne`, and `askama_shared`; CommonMark
652/652 and GFM 670/670 conformance badges plus an OpenSSF best-practices badge
(README, retrieved 2026-09-27); CLI via `cargo install comrak`, brew, and other
channels with `--inplace` reformatting and `--to commonmark` rendering; the two
historical XSS advisories (RUSTSEC-2021-0026, RUSTSEC-2021-0063) are patched at
>=0.9.1/>=0.10.1, so 0.55.0 is unaffected (rustsec advisory pages, retrieved
2026-09-27). It qualifies on unmatched spec conformance and adoption but loses on
formatter fit: it is renderer-first (HTML-oriented, Markdown via `--to commonmark`
round-trip with `--width` default 0), its 293 dependents are library users rather than
formatting adopters, and no check-mode flag was observed in the retrieved portion of
its documented `--help` — stated as an evidence gap, not a verdict.

##### Excluded by gate

None. No Markdown-capable candidate failed a fitness gate.

##### Up-and-comers

`rumdl` v0.2.77 — the serious rising alternative, and this member's ranked runner-up.
Figures, all retrieved 2026-09-27: crate 111,384 all-time / 23,634 recent downloads;
0.2.77 released 2026-09-23; edition 2024 with `rust-version 1.94.0`; MIT; repo
`rvben/rumdl`, 1,528 stars, not archived, pushed 2026-09-26; 26 open issues;
responsiveness sample: 1 answered at 3.9 days, 9 unanswered of 10 (most unanswered are
maintainer-filed `code-block-tools` feature specs); v0.2.77 release ships 14 assets
covering darwin/linux x86_64+aarch64 (plus musl and Windows) at roughly 6–7 MB with
`.sha256` files; `cargo install rumdl` supported (README documents cargo, brew,
npm, pip, and more); default features `parallel` plus `native` (the latter pulls
tokio full, tower-lsp, and host-only deps — 43 normal dependencies total); README
declares beta status ("currently Beta while its compatibility policy and 1.0 exit
criteria are formalized"), 88 lint rules, TOML config (`.rumdl.toml`/`rumdl.toml`),
`rumdl check` exiting 1 on violations and `rumdl fmt --check` as the format gate, and
a GitHub Action plus pre-commit hooks. It loses today on beta status plus 0.2.x daily
churn, linter scope far beyond this item's formatting need, a third binary plus config
to provision, and `rust-version 1.94.0` demanding the newest toolchain for
cargo-install — revisit at 1.0.

##### Fit for this template

`dprint-plugin-markdown` fits because README, CHANGELOG, docs, and `.github/*.md` are
formatted by the same `dprint check` that already covers YAML and JSON: one plugin URL
of marginal cost, no new binary, no 88-rule tuning surface, no beta dependency in a
template others copy. The ts precedent (oxfmt covering Markdown) is honored in
Rust-idiomatic form.

##### Recommendation

`dprint-plugin-markdown` 0.24.0 via `dprint` 0.57.4, pinned by versioned plugin URL
with a checksum suffix, enforced through `dprint check` over `**/*.md` (generated
doc dirs excluded as needed).

##### Ranked runner-up

`rumdl` v0.2.77 (release binary, pinned by version plus `.sha256`). Choose it if a
later decision wants Markdown lint depth (not just formatting) and accepts beta
software, or at rumdl 1.0 re-evaluation. The switch cost is one binary, one
`.rumdl.toml`, one hook job, one CI step.

##### Tradeoffs

dprint-plugin-markdown buys unity, stability, and formatter-only scope at the price of
shallower Markdown intelligence than a dedicated linter. rumdl buys 88 rules,
markdownlint compatibility, GFM-flavored parsing, and superior editor/CI integration
at the price of beta churn, tuning burden, and a third provisioning channel. comrak
buys perfect spec conformance and 8M-download trust at the price of renderer-first
ergonomics and unverified check-mode support. For enforced formatting in a template,
unity plus stability wins; lint depth is R28-shaped scope, explicitly out of bounds
here.

##### Parameters

This member owns no registered parameter. It assumes `package-manager-invocation`
(R42): `dprint` as a bare executable on PATH. No `CONFLICT:`.

##### Migration implications

One `markdown` plugin entry inside the shared `dprint.json`; no new config file, hook
job, or CI step beyond the shared `dprint check` ones. If the runner-up is chosen
instead: new `.rumdl.toml`, one Justfile recipe, one lefthook job, one hygiene step.

##### Validation strategy

All checks PROPOSED, none executed. (1) `dprint check` passes with exit 0 on clean
fixtures: a README analogue (headings, code fences, tables, task lists, links), a
CHANGELOG analogue, and a docs page. (2) A dirty fixture (misaligned table, trailing
whitespace) fails with nonzero exit and file attribution. (3) `dprint fmt` then re-run
proves idempotence. (4) GFM constructs survive byte-identically where the formatter
claims preservation — any semantic rewrite fails the member. Same exit-code contract
as the sibling members.

##### Confidence & re-verify trigger

High for the plugin pick; the runner-up watch is the live question. Re-verify on:
rumdl 1.0 release (re-evaluate the formatter-vs-linter scope split); dprint archived
or an at-risk signal; comrak documenting a check mode plus formatting adoption; or
2027-09-30, whichever comes first.

##### Sources

`GET https://crates.io/api/v1/crates/dprint-plugin-markdown`,
`.../comrak`, `.../comrak/versions`, `.../comrak/reverse_dependencies`,
`.../rumdl`, `.../rumdl/versions`, `.../rumdl/0.2.77/dependencies` (retrieved
2026-09-27); `GET https://api.github.com/repos/dprint/dprint-plugin-markdown`,
`.../releases/latest`, `.../repos/kivikakk/comrak`, `.../repos/kivikakk/comrak/contents/README.md`,
`GET https://api.github.com/repos/rvben/rumdl`, `.../releases/latest`,
`.../contents/README.md`, `.../contents/Cargo.toml`,
`/search/issues?q=repo:rvben/rumdl+is:issue+is:open`, recent-issues sample with
comments (1 answered at 3.9d, 9 unanswered of 10) (retrieved 2026-09-27);
`https://rustsec.org/packages/dprint-plugin-markdown.html`,
`/comrak.html`, `/rumdl.html`, and advisory pages `RUSTSEC-2021-0026`/`-0063`
(retrieved 2026-09-27).

### Compatibility

The members are proven to compose by a shared adopter, a shared example repository,
and the version matrix below — all three legs hold.

Shared adopter: the `deno` crate depends on both `dprint-plugin-json` and
`pretty_yaml` (crates.io reverse-dependencies endpoints, retrieved 2026-09-27), so the
JSON and YAML legs of the dprint configuration cohabit in the flagship Rust-plus-TS
runtime. Shared example repository: dprint's own `dprint.json` runs
`dprint-plugin-yaml@0.6.0` together with official JSON, Markdown, TOML, Dockerfile,
exec, and third-party plugins plus a shared `excludes` list (repo file, retrieved
2026-09-27) — the exact multi-plugin shape this stack uses, including one entry with
an `@sha` checksum suffix proving checksum-pinned plugin refs are supported. taplo and
dprint additionally compose by disjoint ownership: taplo claims `**/*.toml` only, the
dprint plugins route by their own extensions (`.yml`/`.yaml`, `.json`/`.jsonc`,
`.md`), and no file extension is claimed twice; both tools are MIT-licensed and both
ship linux plus darwin x86_64/aarch64 binaries.

Version matrix (all retrieved 2026-09-27):

| Role | Artifact | Pinned version | Source |
|---|---|---|---|
| TOML binary | taplo-cli | 0.10.0 | crates.io plus GitHub release 0.10.0 |
| Runner binary | dprint | 0.57.4 | crates.io plus GitHub release 0.57.4 (attested) |
| JSON plugin | dprint-plugin-json | 0.24.0 | versioned plugin URL plus checksum |
| Markdown plugin | dprint-plugin-markdown | 0.24.0 | versioned plugin URL plus checksum |
| YAML plugin | dprint-plugin-yaml (pretty_yaml) | 0.6.0 | `https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm` plus checksum |

Gap stated honestly: the exact `@sha` checksum digests for these five pins were not
collected (that requires downloading release assets outside the named endpoints) and
must be recorded at implementation time; the pinning mechanism itself is verified.

### Parameters

R29 owns no registered parameter, so there are no `owns` lines.

- `assumes ci-job-structure` = R11's accepted value (prerequisites: decision
  `410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c`, acceptance
  `774f76490a7f968960e71f5e1e38866592a064e3c17a453dd5223add0628eac1c`): the operative
  clause for this item is that Tier 1 job `hygiene` "hosts every non-compiling check
  whose input no key contains, R29's non-code formatting slot ... included". Both
  check invocations land as steps of that job; no new job and no new path key are
  needed.
- `assumes package-manager-invocation` = "invoke a tool whose executable is named
  cargo-\<sub\> as cargo \<sub\>, including the rustup components rustfmt and clippy
  as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved
  on PATH; write Cargo's own built-in subcommands as they are; use no provisioner,
  runner or package-manager prefix in any Justfile recipe or lefthook job, and define
  no Cargo alias in the template; test presence by acquisition channel - command -v
  \<executable\> for a tool installed from crates.io or from a release, and the active
  toolchain's component state via rustup component list --installed for a tool rustup
  installs, never command -v for a rustup component" (R42's accepted value, quoted in
  full): both `taplo` and `dprint` are bare executables on PATH with `command -v`
  presence tests.

No `CONFLICT:` lines — the recommendation needs no consumed parameter to change.

### Migration implications

File-level changes in the template, nothing else:

- New `.taplo.toml` at the root (seeded from `taplo config default`), owning
  `**/*.toml`.
- New `dprint.json` at the root: `plugins` entries for json 0.24.0, markdown 0.24.0,
  and yaml 0.6.0 (versioned URLs with checksum suffixes); shared `excludes`
  (`Cargo.lock`, `**/target`, generated dirs); optional per-format keys (`yaml`,
  `json`, `markdown`) only if style tuning is wanted — defaults otherwise.
- Justfile: one recipe per check invocation (naming coordinated with R27's composite
  recipe at synthesis; this item recommends the two checks also run inside the
  composite `check`/`all` path rather than only standalone, since non-code drift
  should fail the same gate as source drift).
- `lefthook.yml`: one job per tool (`taplo format --check`, `dprint check`) in the
  same pre-push tier as `rustfmt` — same tier because template-scale scans are
  seconds-bounded, separate jobs for failure attribution. Hook mode and tier
  ownership stay with R27/R42; this item only states the per-tool commands and the
  tier recommendation (LOW question).
- `.github/workflows/ci.yml`: steps inside the existing `hygiene` job (R29's slot per
  R11) — version assertions plus the two check commands. No new job, no new path key.
- Explicitly unchanged: every `Cargo.toml` (no linked dependencies — both tools are
  external binaries), `Cargo.lock` (never formatter-owned), and rustfmt/linter
  configs (R27's and R28's).

### Validation strategy

Every command below is PROPOSED — none has been executed. No tools were installed and
no fixture tree was built, because provisioning downloads fall outside the topic's
named endpoints; the empirical auditor must run these for acceptance. Expected
behavior is stated per check; any deviation fails the item.

```sh
# 0. Pins: exact versions installed (release binaries preferred over cargo install).
taplo --version            # expect: taplo 0.10.0
dprint --version           # expect: 0.57.4

# 1. Clean tree passes.
taplo format --check "fixtures/**/*.toml"   # expect: exit 0, no output
dprint check                                # expect: exit 0 (yaml/json/md clean)

# 2. One dirty file per format fails with attribution.
#    (dirty: misaligned Cargo.toml keys, misindented workflow mapping,
#     misindented .vscode/settings.json analogue, trailing-whitespace README)
taplo format --check --diff "fixtures/**/*.toml"  # expect: exit != 0, names only the dirty TOML
dprint check                                      # expect: exit != 0, names the dirty yaml/json/md files

# 3. Writers converge to a fixed point.
taplo format "fixtures/**/*.toml" && git diff --quiet -- fixtures/toml/second-run
dprint fmt && dprint check   # expect: second check exits 0 (idempotent)

# 4. Exclusions hold: Cargo.lock decoy with non-canonical JSON is byte-identical
#    after `dprint fmt`; target/ decoys untouched by both tools.

# 5. YAML scalar torture case (pretty_yaml #4 class): block scalars, multiline
#    workflow `run: |` blocks, and anchors survive byte-stable across two runs.
#    If pretty_yaml mangles them, run the same fixture under `yamlfmt -lint`
#    and flip the YAML member to the runner-up.

# 6. Offline repeat: second `dprint check` with network disabled still passes,
#    proving plugin-cache sufficiency for CI (per the dprint/check caching note).
```

### Confidence & re-verify trigger

Overall confidence: medium-high. TOML (taplo), JSON, and Markdown (dprint official
plugins) rest on dominant-or-strong adoption with clean advisories and verified
multi-platform distribution — high. YAML (pretty_yaml community plugin) rests on
Deno adoption plus dprint's own dogfooding but a 52-star footprint and an open
scalar-correctness issue — medium-high, and it is the item's live risk, carried
explicitly with a low-cost yamlfmt fallback. Re-verify triggers (earliest wins):
any member's at-risk signal as listed in its own section; rumdl 1.0 (reopens the
Markdown scope question); dprint shipping an official YAML plugin (reopens the YAML
pick); or 2027-03-31 for YAML and 2027-09-30 for the rest.

### Sources

Retrieval date for all: 2026-09-27. crates.io API:
`GET /api/v1/crates/{taplo,taplo-cli,dprint,rumdl,comrak,pretty_yaml,dprint-plugin-toml,dprint-plugin-json,dprint-plugin-markdown,deno,mise}`,
`.../versions` and `.../<version>/dependencies` for the pinned versions,
`.../reverse_dependencies` for taplo, pretty_yaml, dprint-plugin-json, rumdl, comrak,
dprint, crates search `q=yaml+format` and `q=yaml+formatter`, and the verified-absent
`GET /api/v1/crates/biome_cli`. api.github.com: repo, `releases/latest`, and
`contents/` (READMEs, manifests, taplo `args.rs`, dprint's `dprint.json`) for
`tamasfe/taplo`, `dprint/dprint`, `dprint/check`, `dprint/dprint-plugin-{toml,json,
markdown}`, `g-plane/pretty_yaml`, `rvben/rumdl`, `google/yamlfmt`, `kivikakk/comrak`,
`biomejs/biome`; org listing for `dprint`; issues search plus 10-most-recent-open
samples with comments for taplo, dprint, pretty_yaml, rumdl, and yamlfmt;
`rust-lang/rust` `src/tools/rustfmt/Cargo.toml` (no taplo mention — rustfmt-link claim
unverified). rustsec.org: package pages for taplo, taplo-cli, dprint, pretty_yaml,
rumdl, comrak, dprint-plugin-toml, dprint-plugin-json, dprint-plugin-markdown (all
HTTP 404 except comrak's two patched 2021 XSS entries), plus advisory pages
RUSTSEC-2021-0026 and RUSTSEC-2021-0063. Run inputs: `inputs/prompt.md`,
`inputs/parameters.json` (fixed plus R11/R42 researched values),
`inputs/prerequisites.json` (R11/R42 hashes), `inputs/PARAMETERS.md`.
