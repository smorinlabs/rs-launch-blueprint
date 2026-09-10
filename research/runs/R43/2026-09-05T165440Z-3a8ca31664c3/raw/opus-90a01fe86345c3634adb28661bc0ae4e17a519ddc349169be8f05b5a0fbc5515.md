# R43 — ai-assistant-repo-furniture (bundle) — Opus raw report

Retrieval date for every figure and claim in this report: **2026-09-10** (unless a
different date is stated inline). Source repositories were read only through their
programme pins: Python `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (written below as
`py@b08bccfb`) and TypeScript `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
(`ts@cb1cbcb2`).

### Landscape

**The category this item decides.** Not a crate choice and not a Rust API design. The
category is *committed repository furniture that a third-party AI coding tool reads at
session start*: vendor-owned configuration paths (`.cursor/rules/*.mdc`,
`.windsurf/rules/*.md`, `.devin/rules/*.md`) and one tool-owned settings key
(`.claude/settings.json` → `companyAnnouncements`). Every candidate is a plain text or
JSON file interpreted by a tool the repository does not vendor, version, or test
against. Consequently the field to map is the *AI-coding-tool configuration ecosystem*,
not the Rust crate ecosystem; the Rust-specific part of the question is only which
commands the human-facing welcome names.

**Three-bin map.**

| Bin | Candidates found | Note |
|---|---|---|
| Built-in or first-party toolchain (Rust/Cargo) | *empty* | Cargo, rustup and `rustc` define no AI-assistant configuration path. `cargo metadata`, `Cargo.toml` `[package.metadata]` and `rust-toolchain.toml` carry no agent-instruction convention. Verified by absence: `curl -sS https://doc.rust-lang.org/cargo/reference/manifest.html \| grep -ciE 'agents\.md\|\.cursor\|windsurf\|claude'` returned **0** (retrieved 2026-09-10). This bin being empty is the reason the decision is a repo-hygiene decision, not a Rust-ecosystem decision. |
| Established industry standard | **`AGENTS.md`** (the hub, F197, out of scope for re-decision but the baseline every spoke is measured against); **`.cursor/rules/*.mdc`** (Cursor project rules); **`.claude/settings.json`** keys, including `companyAnnouncements`; **`CLAUDE.md`** with an `@AGENTS.md` import (F197's spoke) | `AGENTS.md` is "used by over 60k open-source projects" and "is now stewarded by the Agentic AI Foundation under the Linux Foundation" (https://agents.md/, retrieved 2026-09-10). |
| Up-and-comer / in transition | **`.devin/rules/*.md`** (the successor to `.windsurf/rules/*.md`); **`AGENTS.local.md`** (personal, gitignored, Devin CLI); Claude Code **`SessionStart` hooks** as a repo-scoped session-context mechanism; **agent "skills"** directories (`.claude/skills/`, `.agents/`) | `.devin/rules/` is documented as "preferred… takes precedence over `.windsurf/`" (https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10). |
| Legacy / demoted | **`.windsurf/rules/*.md`** (fallback only), **`.windsurfrules`** (labelled "Legacy Windsurf workspace rules"), **`.cursorrules`** (superseded by `.cursor/rules/`) | Same Devin CLI page, "Supported File Names" table, retrieved 2026-09-10. |

**Authorities used, and why each counts.**

1. **Cursor's own product documentation** — https://cursor.com/docs/rules (retrieved
   2026-09-10; the older `docs.cursor.com/context/rules` URL 308-redirects here). This
   is the maintainer's normative specification of the `.mdc` frontmatter contract and of
   `AGENTS.md` support. Maintainer documentation is the only authority that can settle
   "does this file shape still work".
2. **Cognition's own product documentation for Devin Desktop and Devin CLI** —
   https://docs.devin.ai/desktop/cascade/memories.md,
   https://docs.devin.ai/desktop/cascade/agents-md.md and
   https://docs.devin.ai/cli/extensibility/rules.md (all retrieved 2026-09-10).
   `https://docs.windsurf.com/windsurf/cascade/memories` now resolves to the first of
   these, and `https://windsurf.com/` resolves to `https://devin.ai/desktop` (curl
   `-w %{url_effective}`, retrieved 2026-09-10) — so this is the successor vendor's own
   normative documentation for the path ts wrote to.
3. **Anthropic's Claude Code documentation** — https://code.claude.com/docs/en/settings.md,
   https://code.claude.com/docs/en/settings-reference.md,
   https://code.claude.com/docs/en/settings-example.md,
   https://code.claude.com/docs/en/hooks.md and https://code.claude.com/docs/en/memory.md
   (all retrieved 2026-09-10). These define `companyAnnouncements`' scope, type,
   selection semantics and merge behaviour — every load-bearing fact about F199.
4. **The AGENTS.md project** — https://agents.md/ and the specification repository
   `agentsmd/agents.md` (retrieved 2026-09-10). Authoritative for the format's
   governance and cross-vendor reach; it is the reference point that makes a
   vendor-specific spoke redundant or not.
5. **A 50-repository census of well-regarded Rust projects** (method and evidence
   below). Practice evidence, not authority — used to weigh what maintained Rust
   projects actually commit.

A single blog post was treated as a lead only: several secondary write-ups date the
Windsurf → Devin Desktop rebrand to June 2026, and I **could not confirm that date from
a first-party source** (see *Method notes*).

**Practice evidence: what well-regarded Rust projects actually ship.** I enumerated the
root tree of 50 repositories via `GET https://api.github.com/repos/<owner>/<repo>/git/trees/HEAD`
(retrieved 2026-09-10) and recorded which AI-furniture paths exist at the root. The
selection criterion for "well regarded" is stated per group rather than asserted:
Rust-project-org repositories (`rust-lang/rust`, `rust-lang/cargo`,
`rust-lang/rust-analyzer`, `rust-lang/rustup`) are the language's own output; the rest
were chosen for adoption and maintainer standing evidenced by star count and active
pushes (`stargazers_count`, `pushed_at` from `GET /repos/<o>/<r>`), spanning the three
shapes this template presents — CLI (`ripgrep`, `bat`, `starship`, `just`, `uutils/coreutils`,
`typos`, `uv`, `ruff`), library (`serde`, `tokio`, `clap`, `reqwest`, `sqlx`, `egui`,
`bevy`) and service/server (`axum`, `vector`, `qdrant`, `meilisearch`, `risingwave`,
`tikv`, `surrealdb`, `lancedb`).

The standing evidence, cited rather than asserted, from
`GET https://api.github.com/repos/<owner>/<repo>` over the same 50 repositories
(retrieved 2026-09-10): `stargazers_count` ranges from **4,125** (`crate-ci/typos`, the
least-starred member of the set) through a median of **30,782** to **123,077**
(`rustdesk/rustdesk`); `pushed_at` shows **47 of 50 pushed within September 2026**, and
the least recently pushed repository in the whole set, `BurntSushi/ripgrep`, was pushed
`2026-08-04T13:59:44Z` — 37 days before retrieval. Every repository in the census is
therefore both widely adopted and actively maintained by these measures. (One redirect
was followed: `launchbadge/sqlx` resolves to `transact-rs/sqlx`.)

Result (n = 50, retrieved 2026-09-10):

| Root path | Repositories with it | Share |
|---|---|---|
| `AGENTS.md` | 24 | 48% |
| `CLAUDE.md` | 19 | 38% |
| `.claude/` | 7 | 14% |
| `.cursor/` | **1** (`surrealdb/surrealdb`) | 2% |
| `.windsurf/` | **0** | 0% |
| `.devin/` | **0** | 0% |
| `.cursorrules` / `.windsurfrules` | **0** | 0% |

Repositories carrying both `AGENTS.md` and `CLAUDE.md` include `rust-lang/rust`,
`rust-lang/rust-analyzer`, `astral-sh/ruff`, `astral-sh/uv`, `zed-industries/zed`,
`oxc-project/oxc`, `biomejs/biome`, `nushell/nushell`, `rolldown/rolldown`,
`swc-project/swc`, `tikv/tikv`, `risingwavelabs/risingwave`, `rerun-io/rerun`,
`vectordotdev/vector`, `wasmerio/wasmer`, `rustdesk/rustdesk` and `lancedb/lancedb`.
Repositories carrying `AGENTS.md` with no `CLAUDE.md` include `meilisearch/meilisearch`,
`uutils/coreutils`, `web-infra-dev/rspack`, `DioxusLabs/dioxus`, `vercel/turborepo`,
`astral-sh/ty` and `gitbutlerapp/gitbutler`. The single `.cursor/` adopter,
`surrealdb/surrealdb`, ships five substantive rules
(`.cursor/rules/{bug-investigation,git-safety,pull-requests,rust-code-quality,surrealql-language-tests}.mdc`,
`GET /repos/surrealdb/surrealdb/git/trees/<.cursor sha>?recursive=1`, retrieved
2026-09-10) — not thin hub pointers.

Of the seven `.claude/` adopters I read every `.claude/settings.json` present
(`GET /repos/<o>/<r>/contents/.claude/settings.json`, retrieved 2026-09-10):
`astral-sh/ruff` (plugins + a `SessionStart` hook), `astral-sh/uv` (`SessionStart`,
`PostToolUse` hooks), `biomejs/biome` (permissions only), `swc-project/swc` (permissions
only); `rolldown/rolldown`, `gitbutlerapp/gitbutler` and `denoland/deno` ship
`.claude/skills` with no `settings.json`. **`companyAnnouncements` appears in none of
them.** The Rust ecosystem's observed session-start mechanism is a `SessionStart` hook
that feeds *the agent* (`astral-sh/ruff` → `.claude/hooks/session-start.sh`;
`astral-sh/uv` → `bash agents/hooks/session-start.sh`), which is a different audience
from the human-facing announcement F199 describes.

### Principles and implementation

**The shared requirement.** One canonical, version-controlled statement of how to work
in this repository, discoverable by whichever AI coding tool a contributor happens to
use, with no second place where the same policy can drift. This is F197's principle
(`docs/port/COMMONALITY.md:201`, `COMMON → REUSE`, "AI-agent instruction hub (single
canonical file + thin per-tool import)"). R43 does not re-decide the hub; it decides
what, if anything, points at it, and whether a human-facing welcome ships beside it.

**Agreement level.** Two different levels are in play, and conflating them is the error
the ts precedent invites:

| Concern | Agreement level (spec §2 vocabulary) | Must agree across py/ts/rs? |
|---|---|---|
| A single canonical instruction file exists, and no second file restates its policy | **architectural pattern** | Yes — this is F197, already `COMMON → REUSE` |
| Which vendor-specific rule paths are committed (`.cursor/`, `.windsurf/`, `.devin/`) | **policy/mechanism** | No — it may vary with each repository's contributor tooling and with each vendor's current discovery behaviour |
| A repository-scoped welcome greets a human at session start | **capability/standard**, and an explicit owner requirement (Context §11, D-024(6)) | Yes for the capability; the mechanism is per-tool |
| Which commands the welcome names | **policy/mechanism**, derived from F176 (`task-runner tool` = `just`, `COMMON → REUSE`) | No — each ecosystem names its own recipes |

**Essential behaviours.**

- B1. A contributor's tool loads the repository's instructions without the contributor
  configuring anything.
- B2. There is exactly one place where a policy statement lives; every other file either
  points at it or does not exist.
- B3. A human opening a Claude Code session in this repository sees, once, what the
  project is and which commands to run.
- B4. No committed file can silently go stale relative to the commands or paths it
  names.

**Observable acceptance criteria.**

- A1. `AGENTS.md` exists at the repository root, and `CLAUDE.md` contains an
  `@AGENTS.md` import and no independent policy statements. (F197's criterion, carried
  here only as the precondition R43 assumes.)
- A2. `git ls-files` returns zero paths under `.cursor/`, `.windsurf/` or `.devin/`.
- A3. `.claude/settings.json` parses as JSON and `companyAnnouncements` is an array of
  exactly length 1.
- A4. That single string names the repository and at least one `just` recipe, and every
  `just <recipe>` token it contains appears in the output of `just --summary`.

**Architectural alternatives, compared before any file is chosen.** Four designs can
satisfy B1–B3. They differ in where the instruction text lives and who reads it.

| Design | How a vendor tool finds the instructions | Files committed | Drift surface |
|---|---|---|---|
| **D1. Hub-only** — root `AGENTS.md`, plus `CLAUDE.md` importing it | Every surveyed vendor reads root `AGENTS.md` natively; Claude Code reads `CLAUDE.md` | 2 | 1 file of policy |
| **D2. Hub + thin vendor spokes** (the ts shape) | Same as D1, plus a `.mdc`/`.md` rule file per vendor that re-points at the hub | 2 + n | 1 policy file + n vendor frontmatter contracts that each vendor may change |
| **D3. Hub + substantive vendor rules** (the `surrealdb` shape) | Same as D1, plus vendor rules carrying their own content | 2 + n | n+1 policy sources — violates B2 |
| **D4. Hub + nested `AGENTS.md`** for directory-scoped guidance | Cursor: "Nested `AGENTS.md` support in subdirectories… automatically applied"; Devin: subdirectory `AGENTS.md` is treated as "a **glob** rule with an auto-generated pattern of `<directory>/**`" | 2 + k, all in one format | 1 format, no vendor frontmatter |

D3 is excluded on principle: it creates a second policy source, which is exactly what
`py@b08bccfb` removed in commit `fc8d944b7e439bb4e3f19aaf1b2bdf8da4292a57`
("docs(agents): make agents.md canonical; claude.md imports it; drop vendor rule
files (#410)", `git -C ~/c/py-launch-blueprint show --stat fc8d944`, retrieved
2026-09-10).

D2 versus D1 is the real question, and the answer turns on whether the spoke buys
anything. It does not, for three verified reasons:

1. **Both vendors read the hub natively, without a spoke.** Cursor: "Cursor supports
   AGENTS.md in the project root and subdirectories" (https://cursor.com/docs/rules,
   retrieved 2026-09-10). Devin Desktop: `AGENTS.md` is fed "into the same Rules engine
   that powers `.devin/rules/` (and the legacy `.windsurf/rules/`)… Root directory:
   Treated as an **always-on** rule" (https://docs.devin.ai/desktop/cascade/agents-md.md,
   retrieved 2026-09-10). Devin CLI: "`AGENTS.md` | Recommended" in its supported-file
   table, and "Devin CLI reads this file automatically"
   (https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10). A spoke
   whose entire content is "read `AGENTS.md`" therefore instructs a tool to do what it
   already does.
2. **The spoke is a second frontmatter contract that only the vendor controls.** ts's
   `.cursor/rules/doc-template.mdc` (`ts@cb1cbcb2`) writes `globs` as a YAML sequence:

   ```
   globs:
     - "docs/**/*.md"
   ```

   Cursor's current documentation shows `globs` as a plain string and states "Separate
   multiple patterns with commas" (https://cursor.com/docs/rules, retrieved 2026-09-10);
   the YAML-sequence form appears nowhere in the current reference. The same file's
   sibling, `.cursor/rules/projectenv.mdc:9-11` (`ts@cb1cbcb2`), writes
   `read rules ./doc-template.mdc` where the documented include syntax is `@filename`.
   Both are **format drift observed against current vendor documentation; neither was
   verified by executing Cursor**, which this research programme cannot do. That is
   itself the point: a spoke's correctness is only ever verifiable by running the
   vendor's product, so it cannot be gated in CI.
3. **The directory-scoping argument for a spoke has been absorbed by the hub format.**
   ts's `.windsurf/rules/justfile-rules.md:2` (`ts@cb1cbcb2`) uses `trigger: glob` with
   `globs: Justfile` to scope conventions to one root file. Nested `AGENTS.md` now
   provides directory scoping in both vendors (D4 above) — but not *single-file* scoping,
   and a root-level `Justfile`'s conventions land in the always-on root hub either way.
   For ts's actual rule (about 30 lines) the context saving of a glob trigger over a
   section of the root hub is negligible, and the cost is a second policy source that
   restates conventions F177 and F178 already record as `just`-native.

D1 therefore preserves every principle at its declared level while removing the two
drift surfaces D2 adds. The one capability D1 loses is the ability to give a tool
*instructions the hub should not contain* — for which the current, vendor-endorsed
answer is a skill or plugin, not a rule file: "**To improve coding ability, speed of
completion, and lower cost**, we highly recommend **using Skills instead whenever
possible**" (https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10).
That is the documented escape hatch if a future need appears.

**The welcome announcement is a different mechanism with a different audience, and both
are needed.** Claude Code exposes two session-start surfaces, and they do not
substitute for one another:

- `companyAnnouncements` — "Show your organization's announcements to users at startup",
  category *Interface and terminal*, scope *Any file*, type *array of strings*
  (https://code.claude.com/docs/en/settings-reference.md §`companyAnnouncements`,
  retrieved 2026-09-10). Human-facing.
- A `SessionStart` hook returning `additionalContext` — "passes a string from your hook
  into Claude's context window… it doesn't appear as a chat message in the interface"
  (https://code.claude.com/docs/en/hooks.md, retrieved 2026-09-10). Agent-facing, and the
  same page directs "For static context that doesn't require a script, use CLAUDE.md
  instead."

`astral-sh/ruff` and `astral-sh/uv` are the maintained reference implementations of the
hook path, and both use it for *dynamic* agent context, not a human greeting. For F199's
stated outcome — a human sees what the project is — `companyAnnouncements` is the only
documented mechanism, and a hook would be the wrong tool by Anthropic's own guidance.

**How the recommended design composes, end to end.** A contributor clones the template.
Whatever tool they open — Cursor, Devin Desktop, Devin CLI, Codex, Claude Code — reads
root `AGENTS.md`, natively in every case except Claude Code, which reads `CLAUDE.md`
whose first non-heading line is `@AGENTS.md`. Claude Code additionally prints the single
`companyAnnouncements` string once at session start, naming the repository and its `just`
recipes. Nothing else about AI tooling is committed. Behaviour is verified by the
executable checks in `### Validation strategy`: a `git ls-files` assertion for the
absent spokes, a `jq` assertion for the announcement's shape, and a
`just --summary` cross-check that every recipe the announcement names still exists.

**Fitness gates, applied before popularity.** No member is a crate, so gates 2, 3, 5 and
6 have no subject; gates 1 and 4 do apply to committed files and are answered, not
waved through.

| Gate | Verdict for all three members |
|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | **Pass.** Every member is original repository content authored under the template's own license. Neither the `.mdc` frontmatter contract nor the `companyAnnouncements` JSON key is a licensed artifact; using a documented configuration key creates no license obligation. |
| 2. Crate + dependency-tree MSRV within `stable minus 2 minor versions…` | **Inapplicable** — no crate and no dependency tree; nothing enters `Cargo.toml`, so `rust-version` is unaffected. |
| 3. No open RustSec advisory; `unsafe` posture | **Inapplicable** — RustSec indexes crates.io packages; none of these members is one. `unsafe` posture: no Rust code is added. |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **Pass.** All three members are static text or JSON with no build step; the acceptance checks in `### Validation strategy` use `git`, `jq` and `just`, all available on both runners. Windows: `git ls-files` and `jq` behave identically; the announcement string is plain UTF-8. Claude Code's own note that on Windows "creating a symlink requires Administrator privileges… so use the `@AGENTS.md` import instead" (https://code.claude.com/docs/en/memory.md, retrieved 2026-09-10) is why F197's import form, not a symlink, is the assumed hub spoke. |
| 5. Default features and async-runtime coupling | **Inapplicable** — no Cargo features and no runtime. |
| 6. Binary-size and compile-time cost | **Inapplicable** — nothing is compiled or linked. Repository cost is qualitative: the recommendation removes 3 files (about 60 lines) relative to the ts precedent and adds 1 JSON key. |

**Maintenance-state rubric applied to the reference artifacts.**
`agentsmd/agents.md` — `stargazers_count` 24268, `archived` false, `pushed_at`
`2026-08-25T16:41:55Z`, license MIT (`GET https://api.github.com/repos/agentsmd/agents.md`,
retrieved 2026-09-10); open issues 90
(`GET https://api.github.com/search/issues?q=repo:agentsmd/agents.md+is:issue+is:open`,
`total_count`, retrieved 2026-09-10); issue responsiveness across the 10 most recently
opened issues (#233, #232, #231, #229, #228, #227, #224, #218, #217, #215): **0 of 10 have
a first response from an OWNER, MEMBER or COLLABORATOR**, so the median days-to-first-
maintainer-response is undefined and the unanswered count is 10. Verdict:
**stable-quiet**, not `at-risk`. Rationale per the rubric — the trigger (quiet issue
tracker, last push 16 days before retrieval) prompted investigation rather than deciding
it, and the concrete signals that would make it `at-risk` are absent: the format is
governed by the Agentic AI Foundation under the Linux Foundation, its normative content
is a one-page convention with no code to rot, and its liveness is carried by vendor
implementations (Cursor, Devin, Claude Code `/import`) rather than by repository
activity. `anthropics/claude-code` — `stargazers_count` 144641, `archived` false,
`pushed_at` `2026-09-10T06:06:11Z` (same-day), open issues 11811 by the `search/issues`
rule (retrieved 2026-09-10). Verdict: **active**.

**Where a different ecosystem needs a different design.** Nothing here is Rust-specific
except the content of the announcement string. The `AGENTS.md`-only hub is the same
design py already reached (`fc8d944`, pre-pin) and the design ts should converge on; the
announcement is the same mechanism ts already uses. The only justified per-ecosystem
difference is the recipe list inside the announcement, which follows each repository's
own `Justfile`. This answer supplies the rationale for the follow-on py and ts changes;
it changes neither repository.

**BASELINE-REVIEW.** None. F197 ("AI-agent instruction hub (single canonical file + thin
per-tool import)", `docs/port/COMMONALITY.md:201`, `COMMON → REUSE`) is **re-confirmed by
new evidence, not challenged**: Claude Code's memory documentation states plainly
"Claude Code reads `CLAUDE.md`, not `AGENTS.md`. If your repository already uses
`AGENTS.md` for other coding agents, create a `CLAUDE.md` that imports it so both tools
read the same instructions without duplicating them"
(https://code.claude.com/docs/en/memory.md, retrieved 2026-09-10). The thin per-tool
import is therefore still required, for exactly one tool. F176 (`task-runner tool` =
`just`, `COMMON → REUSE`) is likewise assumed unchanged and is the basis for the
announcement's command vocabulary. No `COMMON → REUSE` or `ADOPT` row is challenged by
this item.

### Recommendation

**Ship an `AGENTS.md`-only hub with no vendor rule spokes, plus a single-entry Claude
Code repo-welcome announcement whose command list is CI-checked against the Justfile.**

Concretely: the template commits **no** `.cursor/`, `.windsurf/` or `.devin/` directory,
and commits `.claude/settings.json` containing a `companyAnnouncements` array of exactly
one string that names `rs-launch-blueprint`, states what it is, and lists its `just`
recipes. `AGENTS.md` and its `CLAUDE.md` import are F197's, assumed present. A repository
guard asserts the absence of the vendor directories and the shape of the announcement, so
the decision cannot decay silently; a second guard asserts every `just` recipe the
announcement names still exists.

### Members

#### Cursor project-rule spoke (`.cursor/rules/*.mdc`)

##### Landscape

Cursor project rules are `.mdc` files under `.cursor/rules`, version-controlled, with
YAML frontmatter carrying `description`, `globs` and `alwaysApply`
(https://cursor.com/docs/rules, retrieved 2026-09-10). Bin: **established industry
standard** — Cursor is one of the five tools named on https://agents.md/ as having
collaborated on the format, and its rules directory is the most widely recognised
vendor-specific rule path. The competing option inside the same bin is **no rule file at
all**, relying on Cursor's native `AGENTS.md` support. The up-and-comer adjacent to this
member is nested `AGENTS.md`, which Cursor documents as automatically applied in
subdirectories and combined with parent directories, "with more specific instructions
taking precedence".

The ts precedent commits two files at `ts@cb1cbcb2`:
`.cursor/rules/projectenv.mdc` (`alwaysApply: true`, empty `globs`, body
`- read rules @AGENTS.md for base project dependencies` /
`- read rules ./doc-template.mdc for base project documentation`) and
`.cursor/rules/doc-template.mdc` (`globs:` as a YAML sequence of `"docs/**/*.md"`,
`alwaysApply: false`, body a documentation-structure template naming AGENTS.md as the
charter). py commits neither, at `py@b08bccfb` or since `fc8d944`.

##### Principles and implementation

Principle: B1 (a contributor's tool loads the repository's instructions with no setup)
and B2 (exactly one policy source). Agreement level: **policy/mechanism** — the spoke is
a mechanism serving a pattern that is already agreed at a higher level (F197), so py, ts
and rs may legitimately differ here without breaking agreement.

Does the mechanism still serve the principle? For B1, no: Cursor reads root `AGENTS.md`
natively, so the always-apply pointer rule is redundant with the vendor's own default. For
B2, a pointer-only rule is neutral, but ts's second file (`doc-template.mdc`) carries
substantive documentation policy and therefore *is* a second policy source, which B2
forbids. The architectural alternative that preserves both behaviours with fewer moving
parts is D1 (hub-only), or D4 (nested `AGENTS.md`) if directory-scoped guidance is ever
needed — both use one format the vendor documents as first-class.

Minimal realistic example of the recommended state: the repository root contains
`AGENTS.md`; `git ls-files '.cursor/*'` prints nothing. Executable acceptance check:
`test -z "$(git ls-files '.cursor')"`. Reference implementations of exactly this state
among maintained Rust projects: `rust-lang/rust`, `rust-lang/rust-analyzer`,
`astral-sh/ruff`, `astral-sh/uv`, `zed-industries/zed`, `oxc-project/oxc`,
`biomejs/biome`, `nushell/nushell` — all carry `AGENTS.md` at the root and no `.cursor/`
(root-tree enumeration, retrieved 2026-09-10). The single counter-example,
`surrealdb/surrealdb`, is a maintained reference for the *substantive* rule pattern (D3),
not the thin-spoke pattern (D2): its five rules carry their own content.

##### Dominant choice

**Omitting `.cursor/rules/` and relying on Cursor's native `AGENTS.md` support is the
dominant choice**, on both authority and practice. Authority: Cursor's own documentation
presents `AGENTS.md` as a peer of Project Rules — "Cursor supports four types of rules"
with `AGENTS.md` listed fourth, described as "Agent instructions in markdown format.
Simple alternative to `.cursor/rules`", and the rule-file page steers plain-markdown
users to it: "If you prefer plain markdown, use AGENTS.md instead"
(https://cursor.com/docs/rules, retrieved 2026-09-10). Practice: 1 of 50 surveyed Rust
repositories commits `.cursor/`, against 24 that commit `AGENTS.md` (root-tree census,
retrieved 2026-09-10).

##### Qualified shortlist

1. **No `.cursor/` directory** (recommended). Passes gates 1 and 4; gates 2, 3, 5, 6
   inapplicable (no crate). Zero drift surface.
2. **A single `.cursor/rules/hub.mdc` with `alwaysApply: true` whose body is
   `@AGENTS.md`**. Passes the same gates. Uses the documented include syntax rather than
   ts's `./doc-template.mdc` path form. Justified only if a Cursor version is found that
   does not read root `AGENTS.md` — no such version is documented as of 2026-09-10.
3. **Nested `AGENTS.md` files** for directory-scoped guidance instead of a glob rule.
   Passes the same gates; kept on the shortlist as the *replacement* for the glob-rule
   capability rather than as a spoke.

##### Excluded by gate

None excluded by gates 1–6: every candidate here is committed repository text, and no
candidate fails the license gate or the two-OS gate. Excluded on **principle B2**, not on
a gate: ts's `.cursor/rules/doc-template.mdc` shape, which carries a documentation-structure
policy that duplicates what the hub must own. This exclusion is recorded here rather than
under a gate because the fitness gates as written test crate properties, and no gate tests
"is this a second policy source".

##### Up-and-comers

- **Nested `AGENTS.md`** — Cursor documents it as shipped: "Nested `AGENTS.md` support in
  subdirectories is now available… Instructions from nested `AGENTS.md` files are combined
  with parent directories" (retrieved 2026-09-10). This is the credible successor to
  glob-scoped `.mdc` rules for directory-level guidance.
- **Team Rules** — dashboard-managed, Team/Enterprise plans, precedence
  "Team Rules → Project Rules → User Rules" (retrieved 2026-09-10). Not a repository
  artifact, so out of reach for a template, but it means an organisation can impose rules
  without the repository committing any file — further reducing the case for a committed
  spoke.
- **Remote rules via GitHub** — Cursor can import `.mdc` files from a repository into
  `.cursor/rules/imported/<repoName>` (retrieved 2026-09-10). Relevant as a future
  distribution channel if the owner ever wants shared rules across repositories, which
  would be a separate decision.

##### Fit for this template

The template is CLI + library + web service in one Cargo workspace. The workspace shape
is the one case where directory-scoped rules could earn their keep — different guidance
for the CLI crate, the library crate and the web crate. Even there, nested `AGENTS.md`
covers it in the hub's own format (auto-scoped by directory in both Cursor and Devin),
so the workspace shape argues for D4, never for D2. Against the py precedent the
recommendation is *identical* (py ships nothing); against the ts precedent it is a
removal, whose rationale this report supplies for the follow-on ts change.

##### Recommendation

**Do not ship `.cursor/rules/`.** Assert its absence in the repository guard
(criterion A2). If a genuine Cursor-only need appears later, add one nested `AGENTS.md`
in the affected directory before adding any `.mdc` file.

##### Ranked runner-up

A single `.cursor/rules/hub.mdc`, `alwaysApply: true`, body `@AGENTS.md` and nothing
else. Ranked second because it is the only spoke shape that cannot become a second policy
source. It would become the recommendation only if Cursor's native `AGENTS.md` support is
withdrawn or made opt-in — the re-verify trigger below.

##### Tradeoffs

| | Ship the spoke (ts shape) | Omit it (recommended) |
|---|---|---|
| Cursor loads the hub | Yes (redundantly) | Yes, natively |
| Policy sources | 2 (`AGENTS.md` + `doc-template.mdc`) | 1 |
| Frontmatter contracts to track | 1 vendor-owned | 0 |
| Verifiable in CI | No — correctness needs the vendor product | N/A |
| Signals to a Cursor user that the repo supports them | Yes, weakly | No explicit signal; `AGENTS.md` is the signal |
| Files/lines | +2 files, ~40 lines | 0 |

The one real loss is discoverability theatre: a Cursor user browsing the repository sees
no Cursor-shaped file. The mitigation is a single sentence in `AGENTS.md` naming the tools
known to read it — text in the hub, not a second file.

##### Parameters

`owns` — none. R43 owns no entry in `docs/port/PARAMETERS.md`.
`assumes` — F197 (hub exists as `AGENTS.md` + `CLAUDE.md` import), `COMMON → REUSE`.
`CONFLICT:` — none.

##### Migration implications

Template file-level effect: **no `.cursor/` directory is created.** Relative to the ts
precedent, `.cursor/rules/projectenv.mdc` and `.cursor/rules/doc-template.mdc` are not
ported. The documentation-template content of `doc-template.mdc` — the parts that are
real policy — belongs in `AGENTS.md` or under `docs/`, which is F197's and R81's
territory, not this item's. One line is added to the repository guard script asserting
`git ls-files '.cursor'` is empty.

##### Validation strategy

Proposed for rs (the Rust template does not exist yet, so this is a planned check, not an
executed result):

```sh
test -z "$(git ls-files '.cursor')" || { echo "unexpected Cursor rule files"; exit 1; }
```

Expected behaviour: exit 0 and no output on a conforming tree. **Executed as a negative
control** against `ts@cb1cbcb2` on 2026-09-10:
`git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb2 | grep -cE '^\.(cursor|windsurf|devin)/'`
returned **3**, which is the expected result for the ts pin because ts ships the spokes;
the rs target value is 0. Not verifiable in CI, and deliberately out of scope: whether
Cursor actually loads the hub — that requires running the vendor product, which is the
core argument against committing spokes at all.

##### Confidence & re-verify trigger

**Confidence: high** on the mechanism facts (vendor documentation is unambiguous and was
read at its current URL on 2026-09-10) and **high** on the practice evidence (a 50-repo
census, not a sample of convenience). **Medium** on durability: Cursor's documentation
URL moved during the ts-to-rs interval (`docs.cursor.com/context/rules` → `cursor.com/docs/rules`),
so the vendor reorganises. Re-verify if any of these occur: Cursor's rules documentation
stops listing `AGENTS.md` among its rule types; Cursor announces that native `AGENTS.md`
reading is opt-in; more than 20% of a re-run 50-repo census commits `.cursor/`; or P03
finds a concrete Cursor-only instruction that cannot live in `AGENTS.md`. Otherwise
re-verify at the next annual template review.

##### Sources

- Cursor, "Rules" — https://cursor.com/docs/rules (retrieved 2026-09-10). Rule types
  including `AGENTS.md`; `.mdc` requirement and `.md` being ignored; the
  `alwaysApply`/`description`/`globs` interaction table; comma-separated `globs`;
  `@filename` includes; nested `AGENTS.md`; Team Rules precedence; remote rule import.
- ts pin — `git -C ~/c/ts-launch-blueprint show cb1cbcb2:.cursor/rules/projectenv.mdc`
  and `…:.cursor/rules/doc-template.mdc` (retrieved 2026-09-10).
- py pin and history — `git -C ~/c/py-launch-blueprint ls-tree -r --name-only b08bccfb`
  (no `.cursor` path) and `git show --stat fc8d944` (retrieved 2026-09-10).
- Root-tree census — `GET https://api.github.com/repos/<owner>/<repo>/git/trees/HEAD`
  over 50 repositories (retrieved 2026-09-10); `.cursor` contents for `surrealdb/surrealdb`
  via `GET /repos/surrealdb/surrealdb/git/trees/610594670e8dc1aceb14c335ca3f4f4d62de5ace?recursive=1`.
- AGENTS.md project — https://agents.md/ (retrieved 2026-09-10).

#### Windsurf / Devin workspace-rule spoke (`.windsurf/rules/*.md`, now `.devin/rules/*.md`)

##### Landscape

This is the member where the vendor changed most since the ts port. Windsurf is now
**Devin Desktop**, a Cognition product: `https://windsurf.com/` resolves to
`https://devin.ai/desktop` and `https://docs.windsurf.com/windsurf/cascade/memories`
resolves to `https://docs.devin.ai/desktop/cascade/memories` (curl redirect chains,
retrieved 2026-09-10). Bin placement has moved accordingly: `.devin/rules/*.md` is the
**up-and-comer**; `.windsurf/rules/*.md` is **legacy/demoted** — "`.devin/rules/*.md`
(preferred) or `.windsurf/rules/*.md` (fallback)" and "`.devin/` is the preferred
location and takes precedence over `.windsurf/`"
(https://docs.devin.ai/desktop/cascade/memories.md and
https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10). The
single-file `.windsurfrules` that D-024(5) already retired is now explicitly labelled
"Legacy Windsurf workspace rules" in Devin CLI's supported-file table (same page).

A second change compounds this. The rule-file mechanism ts wrote to belongs to
**Cascade**, and Cascade is now the legacy agent: "**Memories apply to the legacy Cascade
agent only.** The Devin Local agent — the default agent for new tabs — does not persist
memories" (https://docs.devin.ai/desktop/cascade/memories.md, retrieved 2026-09-10). The
default agent reads rules through the Devin CLI rules system, where `.windsurf/rules/`
appears under "Rules From Other Tools" rather than among Devin's native paths. To be
precise about the asymmetry, because it is narrower than it first looks: the
`read_config_from` block shows `agents_standard`, `cursor`, `windsurf` and `claude` all
set to `true`, so `.windsurf/rules/` and `AGENTS.md` are **both read by default and both
switchable off by the user** (https://docs.devin.ai/cli/extensibility/rules.md, retrieved
2026-09-10). The real differences are the ones this member turns on: `AGENTS.md` is
labelled "Recommended" in the supported-file table and read automatically, `.devin/`
"takes precedence over `.windsurf/`", the single-file `.windsurfrules` is labelled
"Legacy", and the rule directory belongs natively to Cascade, the agent the vendor now
calls legacy.

The ts precedent commits one file at `ts@cb1cbcb2`:
`.windsurf/rules/justfile-rules.md`, frontmatter `trigger: glob` / `globs: Justfile`,
body a set of `Justfile` conventions (recipe spacing, group membership, a doc comment
before each recipe) with a TypeScript example block. py commits nothing.

##### Principles and implementation

Principle: B1 and B2, as for the Cursor member; plus B4 (no committed file goes stale).
Agreement level: **policy/mechanism**.

The frontmatter shape ts used is still valid — `trigger: glob` with `globs` is one of the
four documented activation modes (`always_on`, `model_decision`, `glob`, `manual`;
https://docs.devin.ai/desktop/cascade/memories.md, retrieved 2026-09-10). So this is not a
"broken file" finding. It is a **placement and audience** finding: the file sits at a
fallback path, in a directory named for a product that no longer exists under that name,
native to Cascade (the legacy agent) and reached by the default agent only through the
other-tools import layer, and its content restates conventions that F177 and F178 record
as `just`-native and `COMMON → REUSE`.

The architectural alternative that preserves the same behaviour with none of that is the
hub: root `AGENTS.md` is processed by the same rules engine as an always-on rule
(https://docs.devin.ai/desktop/cascade/agents-md.md, retrieved 2026-09-10), and Devin
CLI reads it automatically. If per-directory scoping is ever wanted, a subdirectory
`AGENTS.md` becomes "a **glob** rule with an auto-generated pattern of `<directory>/**`"
— the same capability, in the hub's format, with no vendor frontmatter to track.

Minimal realistic example: root `AGENTS.md` exists; `git ls-files '.windsurf' '.devin'`
prints nothing. Executable acceptance check:
`test -z "$(git ls-files '.windsurf' '.devin')"`. Reference implementations: **0 of 50**
surveyed Rust repositories commit `.windsurf/` or `.devin/` (root-tree census, retrieved
2026-09-10) — there is no maintained Rust reference implementation of this spoke to cite,
which is itself the evidence.

##### Dominant choice

**Omitting the vendor rule directory is the dominant choice, and the margin is wider than
for Cursor.** Practice: 0 of 50 (census, retrieved 2026-09-10). Authority: the vendor's
own documentation demotes the path to a fallback, marks the agent that consumes it as
legacy, and recommends `AGENTS.md` — "`AGENTS.md` is the recommended approach for project
rules. It's easy to read, version-controlled, and works across multiple AI tools"
(https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10). Additionally the
vendor steers non-trivial guidance away from rules entirely: "we highly recommend **using
Skills instead whenever possible**… **Rules and AGENTS should be kept as small as
possible**" (same page).

##### Qualified shortlist

1. **No `.windsurf/` and no `.devin/` directory** (recommended). Gates 1 and 4 pass;
   2, 3, 5, 6 inapplicable.
2. **`.devin/rules/hub.md` with `trigger: always_on`** pointing at `AGENTS.md`. Gates
   pass. Would be the correct *modern* spelling of ts's spoke; still redundant with
   native `AGENTS.md` reading, and still unverifiable in CI.
3. **Nested `AGENTS.md`** where directory-scoped guidance is wanted. Gates pass. This is
   the direct replacement for `trigger: glob`.

##### Excluded by gate

None excluded by fitness gates 1–6. Excluded on **principle B2 and B4**: porting
`.windsurf/rules/justfile-rules.md` as-is. It duplicates `Justfile` policy the hub must
own (B2), and it names a directory whose vendor now treats it as a fallback under a
retired product name, which is a standing staleness liability (B4). Recorded here because
no fitness gate as written tests placement or duplication.

##### Up-and-comers

- **`.devin/rules/*.md` and `.devin/global_rules.md`** — the preferred successor paths,
  same `trigger` frontmatter vocabulary (retrieved 2026-09-10). If a rule file is ever
  needed, this is the path, not `.windsurf/`.
- **Skills and plugins** — the vendor's own recommended replacement for large rules;
  "Skills can now be distributed via Plugins… applied consistently across Devin Cloud,
  Devin CLI, and Devin Desktop" (https://docs.devin.ai/release-notes/2026.md, entry
  labelled July 17, 2026, retrieved 2026-09-10).
- **`AGENTS.local.md`** — a gitignored personal-rules file alongside `AGENTS.md`
  (https://docs.devin.ai/cli/extensibility/rules.md, retrieved 2026-09-10). Worth noting
  in the template's `.gitignore` discussion, which is another item's decision.

##### Fit for this template

Same reasoning as the Cursor member, with one addition specific to a template: a template
is copied and then lives for years in repositories its author does not watch. A path the
vendor has already demoted once, under a product name the vendor has already retired, is
the worst possible thing to bake into a template — every copy inherits the liability and
none of them will notice. The hub format has moved in the opposite direction: governed by
a foundation, read by every surveyed vendor, and recommended by this vendor by name.

##### Recommendation

**Do not ship `.windsurf/rules/` or `.devin/rules/`.** Assert the absence of both in the
repository guard (criterion A2). Any `Justfile` convention worth stating goes in
`AGENTS.md`, where F177 and F178's `just`-native conventions already live.

##### Ranked runner-up

`.devin/rules/hub.md`, `trigger: always_on`, body pointing at `AGENTS.md`. Ranked second
because it at least uses the current path. It would become the recommendation only if
Devin's documentation stops listing `AGENTS.md` as read-by-default, or if the
`agents_standard` import defaults to `false`.

##### Tradeoffs

| | Ship `.windsurf/rules/` (ts shape) | Ship `.devin/rules/` | Omit both (recommended) |
|---|---|---|---|
| Read by Devin Local (default agent) | Yes, via the other-tools import layer (default on, user-toggleable) | Yes | Yes, via `AGENTS.md` (also default on, user-toggleable) |
| Path status per vendor docs | Fallback / legacy product name | Preferred | N/A |
| Policy sources | 2 | 2 | 1 |
| Rust-project precedent | 0 of 50 | 0 of 50 | 24 of 50 carry `AGENTS.md` |
| Staleness liability in every copied template | High | Medium | None |
| Files/lines | +1 file, ~30 lines | +1 file | 0 |

##### Parameters

`owns` — none.
`assumes` — F197 (hub), `COMMON → REUSE`; F176 (`task-runner tool` = `just`),
`COMMON → REUSE`; F177 and F178 (`just`-native recipe grouping and aliases),
`COMMON → REUSE` — these are why the `Justfile` conventions in ts's rule file belong in
the hub rather than in a vendor rule.
`CONFLICT:` — none.

##### Migration implications

Template file-level effect: **no `.windsurf/` and no `.devin/` directory is created.**
Relative to ts, `.windsurf/rules/justfile-rules.md` is not ported; its substantive content
(recipe spacing, group membership, a doc comment before each recipe) becomes a short
section of `AGENTS.md` under F197, phrased for `just` in a Rust workspace. The repository
guard gains one assertion covering both paths.

##### Validation strategy

Proposed for rs (planned, not executed — the Rust template does not exist):

```sh
test -z "$(git ls-files '.windsurf' '.devin')" || { echo "unexpected vendor rule files"; exit 1; }
```

Expected behaviour: exit 0, no output. **Executed as a negative control** against
`ts@cb1cbcb2` on 2026-09-10: the combined
`grep -cE '^\.(cursor|windsurf|devin)/'` over the pinned tree returned 3 (two `.cursor`
files, one `.windsurf` file) — the expected value for ts, and the value rs must drive to
0. As with the Cursor member, whether Devin actually loads the hub cannot be asserted in
CI; that limitation is an argument for the recommendation, not against the check.

##### Confidence & re-verify trigger

**Confidence: high.** Two independent vendor pages (Devin Desktop's memories page and
Devin CLI's rules page) agree on the precedence and the legacy labelling, the census is
unanimous at 0 of 50, and the redirect evidence for the product rename is first-party.
**One thing I could not verify:** the date of the Windsurf → Devin Desktop rename from a
first-party source. Cognition's 2026 release notes
(https://docs.devin.ai/release-notes/2026.md, 58 dated entries spanning January 9 to
September 9, 2026, retrieved 2026-09-10) contain **zero** occurrences of "Windsurf" and
their earliest "Devin Desktop" mention is the July 10, 2026 entry; secondary write-ups
place the rebrand in June 2026, which I record as **unconfirmed**. This does not affect
the recommendation, which rests on the documented current precedence rather than on when
it changed. Re-verify if: Devin's rules documentation promotes `.windsurf/` back to a
first-class path; `agents_standard` or the `AGENTS.md` default read is withdrawn; or a
re-run census shows any meaningful `.devin/` adoption among Rust projects.

##### Sources

- Cognition, "Memories & Rules" (Devin Desktop) —
  https://docs.devin.ai/desktop/cascade/memories.md (retrieved 2026-09-10). Cascade
  marked legacy; Devin Local the default agent; `.devin/rules/*.md` preferred with
  `.windsurf/rules/*.md` fallback; the four `trigger` activation modes; the 12,000- and
  6,000-character rule limits.
- Cognition, "AGENTS.md" (Devin Desktop) —
  https://docs.devin.ai/desktop/cascade/agents-md.md (retrieved 2026-09-10). Root
  `AGENTS.md` = always-on rule; subdirectory = auto-glob `<directory>/**`; same rules
  engine as `.devin/rules/`.
- Cognition, "Rules & AGENTS.md" (Devin CLI) —
  https://docs.devin.ai/cli/extensibility/rules.md (retrieved 2026-09-10). `AGENTS.md`
  "Recommended" and read automatically; `.windsurfrules` "Legacy Windsurf workspace
  rules"; `.devin/` precedence; `.cursor/` and `.windsurf/` under "Rules From Other
  Tools" with `config.json` toggles; the Skills-over-Rules recommendation.
- Cognition, Devin release notes 2026 — https://docs.devin.ai/release-notes/2026.md
  (retrieved 2026-09-10). Used to attempt to date the rename; see the unverified note
  above.
- Product-rename redirects — `curl -sSL -o /dev/null -w '%{url_effective}'` against
  `https://windsurf.com/` → `https://devin.ai/desktop` and
  `https://docs.windsurf.com/windsurf/cascade/memories` →
  `https://docs.devin.ai/desktop/cascade/memories` (retrieved 2026-09-10).
- ts pin — `git -C ~/c/ts-launch-blueprint show cb1cbcb2:.windsurf/rules/justfile-rules.md`
  (retrieved 2026-09-10).
- Root-tree census — as cited in the Cursor member (retrieved 2026-09-10).

#### Claude Code repo-welcome startup announcement (`.claude/settings.json` → `companyAnnouncements`)

##### Landscape

Bin: **established industry standard** — a documented, versioned key of a first-party
tool, with a published scope and type. Category peers, all first-party Claude Code
mechanisms:

| Candidate | Audience | Mechanism |
|---|---|---|
| `companyAnnouncements` | **Human**, at startup | Settings key, category *Interface and terminal*, scope *Any file*, array of strings |
| `SessionStart` hook → `additionalContext` | **Agent** | Runs a command every session; string enters Claude's context wrapped in a system reminder, "doesn't appear as a chat message in the interface" |
| `CLAUDE.md` / `@AGENTS.md` import | **Agent** | Static memory, loaded at session start |
| `systemMessage` from a hook | **Human**, as a warning | Hook JSON field |
| README / `AGENTS.md` prose | **Human**, on demand | Not shown at startup |

Only `companyAnnouncements` puts repository-scoped text in front of a human at session
start. All figures below from https://code.claude.com/docs/en/settings-reference.md and
https://code.claude.com/docs/en/hooks.md, retrieved 2026-09-10.

The ts precedent at `ts@cb1cbcb2` is `.claude/settings.json` with a
`companyAnnouncements` array of exactly one string naming the project, its origin, and
seven `just` recipes with parenthetical purposes, then pointing at `AGENTS.md`,
`docs/port/` and the `Justfile`. py's `.claude/settings.json` at `py@b08bccfb` has no such
key (it carries only `extraKnownMarketplaces` and `enabledPlugins`).

##### Principles and implementation

Principle: B3 — a human opening a session in this repository sees, once, what the project
is and which commands to run. Agreement level: **capability/standard**, and this one is
an **explicit owner requirement** (Context §11 records D-024(6) as reusing the org's
`companyAnnouncements` welcome-string convention "per the owner's own global instruction
mandating repo-welcome announcements"). Because it is an owner requirement, research does
not decide *whether*; it decides the *shape* and the *content vocabulary*, and it must
surface the mechanism's failure modes.

**Three mechanism facts settle the shape, and all three are documented:**

1. **Project scope works.** Scope is `Any file`, which includes shared project settings
   (`.claude/settings.json`). Corroborated in the field by
   `anthropics/claude-code` issue #39998 ("[BUG] companyAnnoucements override", opened
   2026-03-27, closed `not_planned` 2026-04-30,
   https://github.com/anthropics/claude-code/issues/39998, retrieved 2026-09-10), whose
   reporter observes that "project settings can display their messages as if they were
   from the company". The report was closed for inactivity, so the framing stands as
   described.
2. **The array merges across scopes.** "When you set the same list key… in more than one
   file, Claude Code combines the lists instead of picking one"
   (https://code.claude.com/docs/en/settings.md, "Lists merge instead of overriding",
   retrieved 2026-09-10). Four keys are exempted — `fallbackModel`, `modelPicker`,
   `availableModels`, `modelSettings` — and `companyAnnouncements` is **not** among them,
   so it merges.
3. **More than one entry is chosen at random.** "When you list more than one, Claude Code
   picks one at random for each session; on a person's very first launch it shows the
   first entry" (https://code.claude.com/docs/en/settings-reference.md
   §`companyAnnouncements`, retrieved 2026-09-10).

Chaining 2 and 3 gives the consequence that governs the design: **for a contributor whose
organisation or user settings already set `companyAnnouncements`, the repository's welcome
merges into that pool and is shown roughly 1 of N sessions, and when shown it is framed as
a company message.** The design responses are (a) keep the repository's array at exactly
one entry, so the template never multiplies the pool on its own, and (b) treat the welcome
as a convenience, never as the only place a required instruction appears — anything a
contributor must know belongs in `AGENTS.md`, which is loaded every session regardless.

**The MEDIUM question — `just` recipes or `cargo` commands?** Name **`just` recipes**, for
two recorded reasons and one new one. F176 fixes `just` as the template's task-runner tool
(`docs/port/COMMONALITY.md:180`, `COMMON → REUSE`, "tool: just (casey/just v1.58.0, checked
2026-09-02)"). R42's resolved `package-manager-invocation` parameter
(`docs/port/PARAMETERS.md`) settles that recipes invoke `cargo` subcommands directly and
that no provisioner prefix appears in any recipe — so `just` is the human-facing surface
and `cargo` is what the recipes run. Naming raw `cargo` commands in the welcome would
teach a contributor the layer beneath the one the repository asks them to use, and would
duplicate `AGENTS.md`'s command card, reintroducing the two-policy-source problem in a
new place. The new reason: unlike `cargo build`, a `just` recipe name is *checkable* —
`just --summary` enumerates them, so a welcome that names recipes can be gated against
drift, which a welcome naming `cargo` commands cannot.

**The LOW question — staleness.** The announcement is the one member of this bundle with a
real staleness risk, because it hard-codes recipe names that P03 has not chosen yet. That
risk is answered by making the check executable (criterion A4) rather than by omitting the
welcome. The vendor-rule members' staleness risk, by contrast, is *not* checkable, which is
why they are omitted and this one is not.

Minimal realistic example (illustrative; P03 owns the final recipe list):

```json
{
  "companyAnnouncements": [
    "rs-launch-blueprint: a production-ready Rust template shipping a CLI, a library crate and an optional web service behind a Cargo feature. Commands: just all (format-check, lint, typecheck, test), just check-deps (toolchain check), just debug-info (environment report). See AGENTS.md for the project charter and the Justfile for all recipes."
  ]
}
```

Executable acceptance check, run against that file: exactly one entry, the string names
the repository and at least one `just` recipe, and every `just <name>` token it contains
appears in `just --summary`.

##### Dominant choice

**`companyAnnouncements` is the dominant — indeed the only — documented choice for a
repository-scoped, human-facing startup message in Claude Code.** The alternatives fail on
audience, not on quality: `SessionStart` + `additionalContext` reaches the agent and is
explicitly not shown in the interface, and Anthropic's own hooks documentation redirects
static content away from hooks entirely ("For static context that doesn't require a
script, use CLAUDE.md instead", https://code.claude.com/docs/en/hooks.md, retrieved
2026-09-10). Popularity does not select it and cannot: **0 of the 7 Rust repositories with
a `.claude/` directory use the key** (contents reads, retrieved 2026-09-10), so the
dominant choice here rests on the mechanism's documented function plus the owner
requirement, and the report says so rather than manufacturing adoption evidence.

##### Qualified shortlist

1. **Single-entry `companyAnnouncements` in `.claude/settings.json`** (recommended).
   Gates 1 and 4 pass; 2, 3, 5, 6 inapplicable. Documented scope `Any file`; no script,
   no runtime.
2. **`SessionStart` hook printing a banner.** Gates pass, but it fails the requirement:
   a successful hook's stdout "is never shown in the transcript"
   (https://code.claude.com/docs/en/hooks.md, `suppressOutput` row, retrieved
   2026-09-10), and `additionalContext` reaches the model, not the human. It also adds a
   shell script to every session's critical path. Kept on the shortlist only because
   `astral-sh/ruff` and `astral-sh/uv` are maintained Rust reference implementations of
   it — for the *agent-context* purpose, which is a different requirement.
3. **A `systemMessage` from a lightweight hook.** Gates pass; shown to the human as a
   warning. Rejected as a misuse of a warning channel for a welcome, and it still
   requires a script.

##### Excluded by gate

None excluded by fitness gates 1–6 — no candidate is a crate, none carries a license
obligation, and all three run identically on `ubuntu-latest` and `macos-latest`.
Excluded on **requirement fit**: candidates 2 and 3 above, because the required audience
is the human developer and only candidate 1 addresses it without a script. Recorded here
because the gates as written do not test audience.

##### Up-and-comers

- **`SessionStart` hooks with `additionalContext`** — the clear direction of travel in
  well-regarded Rust repositories (`astral-sh/ruff`, `astral-sh/uv`, retrieved
  2026-09-10). Not a substitute for this member, but a strong future candidate for a
  *separate* decision about giving the agent dynamic repository context (open issues,
  recent changes). Out of scope for R43.
- **`.claude/skills/` and plugin marketplaces** — present in `rolldown/rolldown`,
  `gitbutlerapp/gitbutler`, `denoland/deno`, `biomejs/biome`, `astral-sh/ruff` (retrieved
  2026-09-10), and in both source repos' settings (`ts@cb1cbcb2` enables
  `typescript-lsp@claude-plugins-official` and `ast-grep@ast-grep-marketplace`;
  `py@b08bccfb` enables `astral@astral-sh`). A Rust equivalent (a `rust-analyzer` or
  `ast-grep` plugin enable) is a plausible sibling addition to the same file, but it is
  not F199 and this item does not decide it.

##### Fit for this template

The template's audience is a developer who has just cloned a scaffold and does not yet
know its command vocabulary — precisely the case a one-line startup welcome serves. The
CLI + library + web-service shape makes the welcome more valuable than in a single-crate
project, because the recipe set spans three surfaces. Against the ts precedent the shape
is identical (single entry, project summary, `just` list, pointer to `AGENTS.md`); the
only changes are Rust vocabulary and the addition of the drift check ts does not have.
Against py, this is an addition, and this report is the rationale for the follow-on py
change.

##### Recommendation

**Ship `.claude/settings.json` with `companyAnnouncements` as an array of exactly one
string.** The string must: name `rs-launch-blueprint`; say in one clause that it is a Rust
template shipping a CLI, a library and an optional web service; list the `just` recipes a
newcomer needs, each with a parenthetical purpose; and point at `AGENTS.md` and the
`Justfile`. Do not add a second entry. Do not name raw `cargo` commands. Gate the recipe
names in CI against `just --summary`.

##### Ranked runner-up

A `SessionStart` hook emitting `systemMessage`. Ranked second only as a contingency: it
would become the recommendation if `companyAnnouncements` were restricted to managed
scope in a future Claude Code release, which is the re-verify trigger below.

##### Tradeoffs

| | Single-entry `companyAnnouncements` (recommended) | Multi-entry array | `SessionStart` hook |
|---|---|---|---|
| Seen by the human at startup | Yes | Only one entry at random per session | No (stdout is not shown; `additionalContext` goes to the model) |
| Adds a script to every session | No | No | Yes |
| Behaviour when the org also sets the key | Merges into the pool; shown ~1 of N sessions, framed as a company message | Same, worse odds | Unaffected |
| Drift-checkable in CI | Yes, against `just --summary` | Yes | Yes, but the script is another artifact to maintain |
| Rust-project precedent | None found (0 of 7 `.claude/` adopters) | None | `astral-sh/ruff`, `astral-sh/uv` |
| Cost | 1 JSON key | 1 JSON key | 1 script + 1 settings block |

The honest cost of the recommendation: in an enterprise that deploys its own announcement,
the repository welcome is diluted rather than guaranteed, and issue #39998 shows it can
read as if the company sent it. That is why nothing required may live only here.

##### Parameters

`owns` — none. R43 owns no entry in `docs/port/PARAMETERS.md`.
`assumes` — F176 (`task-runner tool` = `just`), `COMMON → REUSE`;
`package-manager-invocation` (R42, resolved: recipes invoke `cargo <sub>` directly, no
provisioner prefix in any Justfile recipe); F197 (hub), `COMMON → REUSE`.
`CONFLICT:` — none. No consumed parameter needs to change for this recommendation to
hold.

##### Migration implications

Template file-level changes:

- **Create** `.claude/settings.json` (or extend it, if another item already creates it for
  plugin enables) with a `companyAnnouncements` array of one string.
- **Do not** add a `SessionStart` hook for this purpose.
- **Add** to the repository guard: the JSON-shape assertion (A3) and the recipe
  cross-check (A4).
- **Coordinate** with F197: the announcement's recipe list and `AGENTS.md`'s command card
  are two renderings of the same fact, so if P03 wants a single source it should generate
  the announcement string from the `Justfile` rather than maintaining a third copy. That
  is an implementation choice for P03; the acceptance check makes either choice safe.

##### Validation strategy

Two checks. Both were **executed on 2026-09-10 against the ts pin** as a working
demonstration that the assertions are well-formed, and both are **proposed** for rs, whose
tree does not exist yet.

```sh
# A3: exactly one announcement entry
jq -e '.companyAnnouncements | length == 1' .claude/settings.json

# A4a: the entry names the repository and at least one just recipe
jq -e '.companyAnnouncements[0] | test("rs-launch-blueprint") and test("just ")' .claude/settings.json

# A4b: every `just <name>` the entry mentions is a real recipe
just --summary | tr ' ' '\n' > /tmp/recipes.txt
jq -r '.companyAnnouncements[0]' .claude/settings.json \
  | grep -o 'just [a-z][a-z0-9-]*' | awk '{print $2}' | sort -u \
  | while read -r r; do grep -qx "$r" /tmp/recipes.txt || { echo "stale recipe: $r"; exit 1; }; done
```

Executed results against `ts@cb1cbcb2` (`git show cb1cbcb2:.claude/settings.json`,
2026-09-10): A3 returned `true` (**PASS**); A4a, with the repository name substituted to
`ts-launch-blueprint`, returned `true` (**PASS**). A4b was **not executed**: it requires a
checked-out tree with a `Justfile` and the `just` binary on PATH, and running it against
the ts working tree rather than the pin would violate the pinned-read rule. Expected
behaviour for rs: all three exit 0 on a conforming tree; A4b exits 1 naming the offending
recipe when P03 renames a recipe without updating the welcome — which is the drift this
check exists to catch.

##### Confidence & re-verify trigger

**Confidence: high** on the mechanism (four Anthropic documentation pages read at their
current URLs on 2026-09-10, with the merge rule, the random-selection rule and the scope
each stated explicitly) and on the owner requirement (recorded in the prompt's Context).
**Medium** on the exact welcome text, which depends on a recipe set P03 has not chosen —
hence the executable check rather than a fixed string. **Low-to-medium** on ecosystem
durability: `companyAnnouncements` appears in Anthropic's *managed-settings* example
(https://code.claude.com/docs/en/settings-example.md, retrieved 2026-09-10) framed as an
administrator key, even though the reference page gives it scope `Any file`; a future
release could narrow it. Re-verify if: the settings reference changes
`companyAnnouncements`' scope away from `Any file`; the random-selection or list-merge
semantics change; P03 renames or removes a recipe (the A4b check fires); or a Claude Code
release adds a first-class repository-welcome mechanism.

##### Sources

- Anthropic, "Settings reference" — https://code.claude.com/docs/en/settings-reference.md
  §`companyAnnouncements` (retrieved 2026-09-10): scope `Any file`, type array of strings,
  default unset, random selection across multiple entries, first entry on first launch.
- Anthropic, "Settings files and precedence" — https://code.claude.com/docs/en/settings.md
  (retrieved 2026-09-10): the five-level precedence stack; "Lists merge instead of
  overriding" and the four exempt model keys.
- Anthropic, "Example settings files" — https://code.claude.com/docs/en/settings-example.md
  (retrieved 2026-09-10): `companyAnnouncements` in the managed-settings example,
  "A message every user sees at startup".
- Anthropic, "Hooks reference" — https://code.claude.com/docs/en/hooks.md (retrieved
  2026-09-10): `SessionStart` matchers and the "use CLAUDE.md instead" guidance;
  `additionalContext` semantics; `suppressOutput` note that a successful hook's stdout is
  never shown; the 10,000-character output cap.
- Anthropic, "Manage Claude's memory" — https://code.claude.com/docs/en/memory.md
  (retrieved 2026-09-10): "Claude Code reads `CLAUDE.md`, not `AGENTS.md`"; the
  `@AGENTS.md` import; the Windows symlink caveat; `/init` reading Cursor rules and, under
  `CLAUDE_CODE_NEW_INIT=1`, `AGENTS.md`, `.devin/rules/`, `.windsurf/rules/`.
- `anthropics/claude-code` issue #39998 —
  https://github.com/anthropics/claude-code/issues/39998 (retrieved 2026-09-10): project
  settings' announcements rendered as company messages; opened 2026-03-27, closed
  `not_planned` 2026-04-30.
- Repository figures — `GET https://api.github.com/repos/anthropics/claude-code`
  (`stargazers_count` 144641, `archived` false, `pushed_at` 2026-09-10T06:06:11Z) and
  `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code+is:issue+is:open`
  (`total_count` 11811), retrieved 2026-09-10.
- Source pins — `git -C ~/c/ts-launch-blueprint show cb1cbcb2:.claude/settings.json`;
  `git -C ~/c/py-launch-blueprint show b08bccfb:.claude/settings.json` and
  `…:CLAUDE.md` (retrieved 2026-09-10).
- Rust `.claude/settings.json` reads — `GET /repos/<o>/<r>/contents/.claude/settings.json`
  for `astral-sh/ruff`, `astral-sh/uv`, `biomejs/biome`, `swc-project/swc` (retrieved
  2026-09-10); `.claude/` listings for `rolldown/rolldown`, `gitbutlerapp/gitbutler`,
  `denoland/deno`.

### Compatibility

The three members are not libraries and have no version matrix, so compatibility is
demonstrated by shared adopters running the exact combination.

**Shared adopters of members 1 and 2 in their recommended (omitted) state, alongside the
hub this item assumes:** `astral-sh/ruff`, `astral-sh/uv`, `biomejs/biome`,
`rust-lang/rust`, `rust-lang/rust-analyzer`, `zed-industries/zed`, `oxc-project/oxc`,
`nushell/nushell`, `rolldown/rolldown`, `swc-project/swc`, `tikv/tikv`,
`risingwavelabs/risingwave`, `rerun-io/rerun`, `wasmerio/wasmer`, `vectordotdev/vector`,
`lancedb/lancedb`, `rustdesk/rustdesk` — each carries root `AGENTS.md`, most carry
`CLAUDE.md`, and **none** carries `.cursor/`, `.windsurf/` or `.devin/` (root-tree
enumeration over 50 repositories, retrieved 2026-09-10). `astral-sh/ruff`,
`astral-sh/uv` and `biomejs/biome` additionally carry a `.claude/settings.json` beside
that hub, proving the exact file set members 1–3 produce coexists in maintained Rust
repositories: `AGENTS.md` + `CLAUDE.md` + `.claude/settings.json`, with no vendor rule
directory.

**Member 3's key is not covered by that shared adopter set, and I say so plainly.** None
of the seven Rust repositories with a `.claude/` directory sets `companyAnnouncements`
(contents reads, retrieved 2026-09-10). The evidence that the key functions at project
scope is (a) Anthropic's reference stating scope `Any file`
(https://code.claude.com/docs/en/settings-reference.md, retrieved 2026-09-10), (b) issue
#39998's reporter observing project-scope announcements displaying in practice, and (c)
`ts@cb1cbcb2`, the org's own repository, which ships exactly this shape. That is a
documented-plus-one-adopter basis, weaker than the unanimous basis for members 1 and 2, and
it is why the recommendation constrains the key to a single entry and forbids putting
required information only there.

**No mutual interference.** The three members touch disjoint paths (`.cursor/`,
`.windsurf/`+`.devin/`, `.claude/settings.json`) and no member's recommended state
depends on another's implementation — only on F197's hub, which all three assume.
`.claude/settings.json` is shared with whichever item decides plugin enables; the
`companyAnnouncements` key is independent of `enabledPlugins` and
`extraKnownMarketplaces`, as both source repos demonstrate (`ts@cb1cbcb2` carries all
three keys in one file).

### Parameters

- `owns` — **none.** R43 owns no parameter in `docs/port/PARAMETERS.md`; the prompt's
  `owns:` field is empty and the registry lists no `researched` row against R43.
- `assumes task-runner tool = just` — F176, `docs/port/COMMONALITY.md:180`,
  `COMMON → REUSE` ("tool: just (casey/just v1.58.0, checked 2026-09-02"). The
  announcement names `just` recipes on this basis.
- `assumes package-manager-invocation = invoke a tool whose executable is named
  cargo-<sub> as cargo <sub>` — and every other tool as a bare executable resolved on
  PATH, with no provisioner, runner or package-manager prefix in any Justfile recipe (`docs/port/PARAMETERS.md`, R42, resolved).
  This is why the welcome names `just` recipes rather than raw `cargo` invocations.
- `assumes AI-agent instruction hub = single canonical AGENTS.md + thin per-tool import` —
  F197, `docs/port/COMMONALITY.md:201`, `COMMON → REUSE`. Re-confirmed, not challenged,
  by https://code.claude.com/docs/en/memory.md (retrieved 2026-09-10).
- `assumes rust-edition = 2024`, `assumes msrv-policy = stable minus 2 minor versions,
  raised only in a minor release, declared as rust-version in Cargo.toml and tested in
  CI`, `assumes license = MIT OR Apache-2.0`, `assumes target-os-matrix = ubuntu-latest,
  macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). None is
  constrained by this item: no member adds a crate, a dependency, an edition-sensitive
  construct or an OS-sensitive step.
- `CONFLICT:` — **none.** No recommendation in this report requires a consumed parameter
  to change.
- `BASELINE-REVIEW:` — **none.** See `### Principles and implementation` for why F197 is
  re-confirmed rather than challenged.

### Migration implications

File-level changes in the `rs-launch-blueprint` template, relative to a straight port of
the ts precedent:

| Path | Action | Reason |
|---|---|---|
| `.cursor/rules/projectenv.mdc` | **not created** | Cursor reads root `AGENTS.md` natively (https://cursor.com/docs/rules, 2026-09-10); the pointer is redundant |
| `.cursor/rules/doc-template.mdc` | **not created**; its real documentation policy moves into `AGENTS.md` or `docs/` under F197/R81 | It is a second policy source (principle B2), and its YAML-sequence `globs` no longer matches the documented frontmatter |
| `.windsurf/rules/justfile-rules.md` | **not created**; its `Justfile` conventions move into `AGENTS.md` | Path demoted to a fallback behind `.devin/rules/`; content duplicates F177/F178 |
| `.devin/rules/` | **not created** | Same reasoning; the hub covers it, and nested `AGENTS.md` covers directory scoping |
| `.claude/settings.json` | **created (or extended)** with `companyAnnouncements`: an array of exactly one string naming the repository, its three surfaces, its `just` recipes and pointers to `AGENTS.md` and the `Justfile` | F199; owner requirement recorded in D-024(6) |
| Repository guard script (name and location owned by P03) | **one new check block** asserting A2, A3 and A4 | Makes the decision non-decaying; without it the omission silently reverts the first time someone runs a tool's init wizard |
| `AGENTS.md` | **gains** a short "tools that read this file" note and the `Justfile` conventions inherited from ts's Windsurf rule | Keeps the single policy source complete after the spokes are dropped; the file itself is F197's, not this item's |

Nothing enters `Cargo.toml`, no CI job is added beyond the existing repository-guard lane
(R11 owns the job structure), and no crate is introduced.

Follow-on projects, stated as implications and not as changes made here: `ts-launch-blueprint`
would delete `.cursor/rules/` and `.windsurf/rules/`, folding their real content into
`AGENTS.md`; `py-launch-blueprint` would gain the single-entry `companyAnnouncements`
alongside its existing `extraKnownMarketplaces`/`enabledPlugins`. Both are out of this
item's scope; this report is their rationale.

### Validation strategy

Four checks. **Executed** results are against the ts pin on 2026-09-10, used as a working
demonstration and as a negative control; every rs-facing assertion is **proposed**,
because the Rust template does not exist yet.

1. **A2 — no vendor rule files** (proposed for rs):

   ```sh
   test -z "$(git ls-files '.cursor' '.windsurf' '.devin')" \
     || { echo "unexpected AI-editor rule files"; exit 1; }
   ```

   Expected on a conforming rs tree: exit 0, no output. **Executed negative control**
   against `ts@cb1cbcb2`:
   `git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb2 | grep -cE '^\.(cursor|windsurf|devin)/'`
   returned **3** — the expected value for ts, which ships two `.cursor` files and one
   `.windsurf` file. rs must return 0.

2. **A3 — the announcement is a single entry** (proposed for rs):
   `jq -e '.companyAnnouncements | length == 1' .claude/settings.json`.
   **Executed** against `ts@cb1cbcb2`'s `.claude/settings.json`: returned `true`
   (**PASS**).

3. **A4a — the announcement names the repository and a `just` recipe** (proposed for rs):
   `jq -e '.companyAnnouncements[0] | test("rs-launch-blueprint") and test("just ")' .claude/settings.json`.
   **Executed** against `ts@cb1cbcb2` with the name substituted to `ts-launch-blueprint`:
   returned `true` (**PASS**).

4. **A4b — every recipe the announcement names exists** (proposed for rs; **not
   executed**, because it needs a working tree with a `Justfile` and the `just` binary,
   and running it against a working tree would break the pinned-read rule):

   ```sh
   just --summary | tr ' ' '\n' | sort -u > /tmp/recipes.txt
   jq -r '.companyAnnouncements[0]' .claude/settings.json \
     | grep -o 'just [a-z][a-z0-9-]*' | awk '{print $2}' | sort -u \
     | while read -r r; do
         grep -qx "$r" /tmp/recipes.txt || { echo "announcement names a missing recipe: $r"; exit 1; }
       done
   ```

   Expected: exit 0 while the welcome matches the `Justfile`; exit 1 naming the recipe the
   first time P03 renames or removes one without updating the welcome.

**Explicitly not verifiable, and stated as a limit rather than glossed:** whether Cursor,
Devin Desktop or Devin CLI in fact load `AGENTS.md` in a given version. That requires
running each vendor's product, which this programme does not do, and which no CI lane
could do either. The recommendation is deliberately arranged so that this unverifiable
question is answered by the vendors' own current documentation rather than by a file the
repository must keep in sync.

### Confidence & re-verify trigger

**Overall confidence: high** for the recommendation, **medium** for the exact announcement
text.

What makes it high: every mechanism claim comes from the vendor's own current
documentation, read at its live URL on 2026-09-10, and the two omission decisions are
corroborated by a 50-repository census that is unanimous for `.windsurf`/`.devin` (0 of
50) and near-unanimous for `.cursor` (1 of 50). The two vendor-side findings that matter
most — Cursor listing `AGENTS.md` as a first-class rule type, and Cognition demoting
`.windsurf/` to a fallback under a renamed product — are each supported by more than one
page from the same vendor.

What keeps the announcement at medium: its content depends on a `Justfile` P03 has not
written, and `companyAnnouncements` is presented in Anthropic's own example material as an
administrator key even though its reference entry grants it project scope. The A4b check
is the mitigation for the first; the single-entry rule and the "nothing required lives
only here" constraint are the mitigation for the second.

**Re-verify triggers, any one of which reopens this item:**

- Cursor's rules documentation stops listing `AGENTS.md` among its rule types, or makes
  native `AGENTS.md` reading opt-in.
- Cognition promotes `.windsurf/` back to a first-class path, or changes Devin CLI's
  `agents_standard` import to default off.
- Anthropic narrows `companyAnnouncements`' scope away from `Any file`, or changes the
  list-merge or random-selection semantics.
- A re-run of the 50-repository census shows `.cursor/` above 20% or any meaningful
  `.devin/` adoption among well-regarded Rust projects.
- P03 renames a `just` recipe named in the welcome (check A4b fires).
- Otherwise: re-verify at the next annual template review, or on any vendor rebrand of the
  kind that produced this item's largest finding.

### Sources

Every URL below was retrieved on **2026-09-10**; every pinned repository read went through
its commit pin.

**Vendor and standards documentation**
- Cursor, "Rules" — https://cursor.com/docs/rules
- AGENTS.md — https://agents.md/ ; specification repository `agentsmd/agents.md`
- Cognition, "Memories & Rules" (Devin Desktop) — https://docs.devin.ai/desktop/cascade/memories.md
- Cognition, "AGENTS.md" (Devin Desktop) — https://docs.devin.ai/desktop/cascade/agents-md.md
- Cognition, "Rules & AGENTS.md" (Devin CLI) — https://docs.devin.ai/cli/extensibility/rules.md
- Cognition, "Welcome to Devin Desktop" — https://docs.devin.ai/desktop/getting-started.md
- Cognition, Devin release notes 2026 — https://docs.devin.ai/release-notes/2026.md
- Anthropic, "Settings files and precedence" — https://code.claude.com/docs/en/settings.md
- Anthropic, "Settings reference" — https://code.claude.com/docs/en/settings-reference.md
- Anthropic, "Example settings files" — https://code.claude.com/docs/en/settings-example.md
- Anthropic, "Hooks reference" — https://code.claude.com/docs/en/hooks.md
- Anthropic, "Manage Claude's memory" — https://code.claude.com/docs/en/memory.md
- Cargo manifest reference (used to establish the empty first-party bin) — https://doc.rust-lang.org/cargo/reference/manifest.html

**Endpoints queried for figures**
- `GET https://api.github.com/repos/agentsmd/agents.md` → `stargazers_count` 24268,
  `archived` false, `pushed_at` 2026-08-25T16:41:55Z, license MIT
- `GET https://api.github.com/search/issues?q=repo:agentsmd/agents.md+is:issue+is:open` →
  `total_count` 90
- `GET https://api.github.com/repos/agentsmd/agents.md/issues?state=all&sort=created&direction=desc`
  plus `/issues/<n>/comments` for the 10 most recently opened issues → 0 of 10 with a
  first response from OWNER/MEMBER/COLLABORATOR
- `GET https://api.github.com/repos/anthropics/claude-code` → `stargazers_count` 144641,
  `archived` false, `pushed_at` 2026-09-10T06:06:11Z
- `GET https://api.github.com/search/issues?q=repo:anthropics/claude-code+is:issue+is:open`
  → `total_count` 11811
- `GET https://api.github.com/repos/<owner>/<repo>/git/trees/HEAD` over the 50 surveyed
  repositories → the root-path census tabulated in `### Landscape`
- `GET https://api.github.com/repos/<owner>/<repo>/contents/.claude[/settings.json]` for
  the 7 `.claude/` adopters
- `GET https://api.github.com/repos/surrealdb/surrealdb/git/trees/610594670e8dc1aceb14c335ca3f4f4d62de5ace?recursive=1`
  → the five `.cursor/rules/*.mdc` files
- `GET https://api.github.com/repos/anthropics/claude-code/issues/39998` and its comments
- HTTP redirect probes via `curl -sSL -o /dev/null -w '%{url_effective}'` for
  `https://windsurf.com/`, `https://docs.windsurf.com/windsurf/cascade/memories`,
  `https://docs.cursor.com/context/rules`

**Pinned source repositories**
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` for `.cursor/rules/projectenv.mdc`,
  `.cursor/rules/doc-template.mdc`, `.windsurf/rules/justfile-rules.md`,
  `.claude/settings.json`, `AGENTS.md`, `CLAUDE.md`; and
  `git ls-tree -r --name-only cb1cbcb2`
- `git -C ~/c/py-launch-blueprint show b08bccfb:<path>` for `.claude/settings.json` and
  `CLAUDE.md`; `git ls-tree -r --name-only b08bccfb`; `git show --stat fc8d944`
  (commit `fc8d944b7e439bb4e3f19aaf1b2bdf8da4292a57`, pre-pin, "drop vendor rule files")

**Repository documents consulted for baseline and parameters**
- `docs/port/COMMONALITY.md` rows F176, F177, F178, F197, F198, F199
- `docs/port/PARAMETERS.md` (fixed rows; R42's resolved `package-manager-invocation`)
- `docs/port/BASELINE-REVIEW.md` (row format and classification vocabulary)

**Method notes.** I queried, all on 2026-09-10: crates.io — **not queried, and
deliberately so**, because this bundle contains no crate member, so
`https://crates.io/api/v1/crates/<name>` and `/versions` have no subject; the crate figure
table (90-day downloads, all-time downloads, last release) is therefore recorded as
`inapplicable` with that reason rather than filled with unrelated numbers. RustSec
(`https://rustsec.org/packages/<name>.html`) — **not queried**, for the same reason: it
indexes crates.io packages and none of these members is one. GitHub REST — `/repos/<o>/<r>`,
`/repos/<o>/<r>/git/trees/HEAD`, `/repos/<o>/<r>/contents/<path>`,
`/repos/<o>/<r>/issues`, `/repos/<o>/<r>/issues/<n>/comments` and
`/search/issues?q=repo:<o>/<r>+is:issue+is:open` (the `total_count` rule, never
`open_issues_count` — for `agentsmd/agents.md` the two differ, 90 against 170, and I used
90). Vendor documentation was fetched with `curl -sSL` against the `.md` variants that
Cursor's and Cognition's and Anthropic's documentation sites serve, so the text quoted is
the source markdown rather than a rendered approximation.

**What I could not verify.** (1) The date of the Windsurf → Devin Desktop rename from a
first-party source: Cognition's 2026 release notes contain 58 dated entries from
January 9 to September 9, 2026 with **zero** occurrences of "Windsurf" and no
"Devin Desktop" mention earlier than the July 10, 2026 entry; `https://devin.ai/blog`
returned HTTP 429 and `https://windsurf.com/` returned 429 before redirecting; secondary
write-ups place the rebrand in June 2026, which I record as a lead, not a fact. The
recommendation does not depend on the date. (2) Whether Cursor, Devin Desktop or Devin CLI
actually load `AGENTS.md` in any given installed version — that requires executing the
vendors' products, which this programme does not do; I rely on their current documentation
and say so wherever the claim is load-bearing. (3) Check A4b (`just --summary`
cross-check) was designed but not executed, because it needs a working tree with a
`Justfile` and running it against the ts working tree rather than the pin would violate the
pinned-read rule. (4) Whether ts's `.cursor/rules/doc-template.mdc` YAML-sequence `globs`
is in fact rejected by current Cursor builds: it does not match the documented form, but I
label this **format drift observed against current documentation, not verified by
execution**. (5) Claude Code's exact rendering of a project-scope announcement in an
organisation that also deploys one — issue #39998's screenshot is described in the
reporter's words and the issue was closed `not_planned`, so I report the merge and
random-selection semantics from the documentation and the framing complaint from the
issue, without asserting a specific on-screen result.
