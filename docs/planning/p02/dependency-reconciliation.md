# P02 dependency reconciliation

This record reviews every one of the 84 canonical prompts and separates three meanings that descriptive coupling prose can carry. **Research** prerequisites are the existing `- consumes:` edges plus the Runbook keystone rule for a non-owner that names an owner. **Acceptance** prerequisites are post-research integration checks recorded by `acceptance-after`. **Context** relations describe compatibility or an open assumption; they do not block dispatch and do not add graph edges.

The migration promotes `R58`'s `logging-pipeline-contract` to a researched parameter and makes R59, R75, and R78 explicit consumers. It records `R71` as `acceptance-after` for R83 and R84 because their integrated schema fixtures require R71's committed snapshot. R84 may research against a generic provisional schema, but its publication integration must revalidate against R71. R01/R05 stays one-way under the Runbook keystone rule; no reverse edge or cycle is introduced.

## Per-prompt review

The table has one row per canonical prompt. It classifies the exact declared coupling text; it is not a claim that semantic discovery is complete. Any undeclared or ambiguous dependency remains unresolved until the controller records it before binding acceptance. Context criteria are completion checks for the eventual decision; they do not turn a contextual relation into a research prerequisite. When an owner prompt names a downstream consumer, that reference remains context and the consumer owns the future integration check against the selected output.

| Item | Existing research prerequisites | Acceptance prerequisites | Context relations | Context acceptance criterion |
|---|---|---|---|---|
| R01 | — | — | R02, R05 | Resolve the seam with a conditional fixture viable for either sync or async execution; R05 later validates the selected seam and execution model together. |
| R02 | R01 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R03 | R01, R67 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R04 | — | — | R02 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R05 | R01 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R06 | — | — | R28 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R07 | — | — | R21 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R08 | R11 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R09 | R11 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R10 | R42 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R11 | R69 | — | R02, R12, R13 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R12 | R11 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R13 | R11 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R14 | R11 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R15 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R16 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R17 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R18 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R19 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R20 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R21 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R22 | R49 | — | R60 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R23 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R24 | R38 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R25 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R26 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R27 | R11, R42 | — | R28 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R28 | R11, R42 | — | R27, R30 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R29 | R11, R42 | — | R27 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R30 | R11 | — | R28 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R31 | R11 | — | R28 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R32 | R01, R11, R42, R49, R69 | — | R33, R34, R35, R48 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R33 | — | — | R32 | Run this item's selected fixture using R32's resolved runner and tier boundary; preserve its isolation. |
| R34 | — | — | R32 | Run this item's selected fixture using R32's resolved runner and tier boundary; preserve its isolation. |
| R35 | R11 | — | R32 | Run this item's selected fixture using R32's resolved runner and tier boundary; preserve its isolation. |
| R37 | R11, R38, R42, R69 | — | R32, R39, R40, R41 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R38 | — | — | R24, R37 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R39 | R11 | — | R37 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R40 | R11, R42 | — | R09, R37 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R41 | — | — | R37 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R42 | — | — | R27, R28, R29, R32, R37, R40 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R43 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R44 | R42 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R45 | — | — | R18 | Trigger-block fixture names exactly R18's resolved bot list; with no bot, prove the block is absent. |
| R46 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R47 | — | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R48 | R01 | — | R32 | Run this item's selected fixture using R32's resolved runner and tier boundary; preserve its isolation. |
| R49 | — | — | R50, R68 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R50 | R49 | — | R26 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R51 | R69 | — | R80 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R52 | R67 | — | R53 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R53 | R67 | — | R52, R55, R56 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R54 | R67 | — | R55, R56, R57 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R55 | R67 | — | R53, R54 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R56 | R67 | — | R53, R54 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R57 | R67 | — | R59 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R58 | R69 | — | R57, R59 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R59 | R58 | — | R57 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R60 | — | — | R22 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R61 | R67 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R62 | R67 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R63 | — | — | R65 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R64 | — | — | R65 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R65 | — | — | R63, R64, R66 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R66 | — | — | R85 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R67 | — | — | R57, R61 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R68 | R49 | — | R50, R51 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R69 | R01 | — | R11, R32, R37, R51, R58, R71, R82, R83, R84 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R70 | R67, R69 | — | R71 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R71 | R11, R69 | — | R70, R83, R84 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R72 | R69 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R73 | R69 | — | R75 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R74 | R69 | — | R70, R75 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R75 | R58, R69 | — | — | No descriptive coupling; run this item's own acceptance gate. |
| R76 | R69 | — | R75 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R77 | R69 | — | R53 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R78 | R58, R69 | — | R79 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R79 | R69 | — | R75, R78 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R80 | R69 | — | R51, R70 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R81 | — | — | R82 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R82 | R11, R69 | — | R81 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R83 | R69 | R71 | R32, R84 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R84 | R69 | R71 | R83 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |
| R85 | — | — | R65, R66 | Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch. |

## Explicit unresolved compatibility checks

- **R01 → R05:** R01 resolves the seam with a conditional fixture that remains viable for either sync or async execution; R05 then validates the selected seam and execution model together. No reverse edge is added, so the open relation cannot create a cycle.
- **R45 → R18:** the trigger-block fixture must name exactly the bot list resolved by R18. If R18 resolves to no bot, the fixture must prove the trigger block is absent; do not invent a bot name.
- **R33, R34, R35, and R48 → R32:** run each selected property/snapshot, scheduled-lane, coverage, and mock fixture using R32's resolved runner and tier boundary. Preserve slow/advisory isolation and exercise R48's mock through R01's selected seam.
- **R59, R75, and R78 → R58:** their integration fixtures must use R58's published logging-pipeline contract, including the selected extension point, redaction fields, profile boundary, and optional OTel boundary.
- **R83 and R84 → R71:** each schema-driven fixture must consume the committed R71 snapshot before resolution; R84 additionally proves one generated request against that snapshot.

## Exact cited relation text

The following 94 excerpts are copied from the canonical prompt files with their source locations. They are evidence for the per-prompt classifications above, not additional edges.

- `R01 — research/topics/01-ports-and-adapters-seam/prompts/ports-and-adapters-seam.prompt.md:26`
  - related (not a registry dependency): R05 (`sync-async-execution-model`, F016/F022) decides the sync/async shape of the I/O boundary this seam wraps. R05 registers no parameter this item can consume — treat its direction as open, do not block on it.
- `R01 — research/topics/01-ports-and-adapters-seam/prompts/ports-and-adapters-seam.prompt.md:27`
  - related (not a registry dependency): R02 (`crate-boundary-enforcement`) owns the Cargo workspace crate topology (F021); this item does not decide which crate a port trait or adapter physically lives in.
- `R02 — research/topics/02-crate-boundary-enforcement/prompts/crate-boundary-enforcement.prompt.md:26`
  - related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a port/adapter split exists and how an adapter satisfies a port (F011, moved from this item to R01 at the Task 10 reconciliation); assume R01's port split exists and design the crate topology (F021) to hold it, but do not re-decide F011 here. `http-transport-injection-seam` is R01's registered parameter; this item's crate-boundary decision does not need its value — nothing here depends on trait-object vs. generic-bound seam shape, only on how many crates the boundary needs and which way they may depend on each other.
- `R03 — research/topics/03-port-absence-vs-failure-contract/prompts/port-absence-vs-failure-contract.prompt.md:26`
  - related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a formal port trait exists for the driven-I/O seam (F001). This item's absence-vs-failure pattern must work whether that boundary is a trait method, a generic-bound function, or a directly injected closure — treat R01's shape as open, do not block on it.
- `R04 — research/topics/04-public-api-surface-enforcement/prompts/public-api-surface-enforcement.prompt.md:26`
  - related (not a registry dependency): R02 (`crate-boundary-enforcement`) decides the Cargo workspace crate topology (F021). Whether this item's enforcement mechanism is single-crate `pub`/`pub(crate)` visibility or a multi-crate boundary (an internal crate simply not published/re-exported) depends on R02's answer — assume either shape is possible and state which mechanism applies to each, do not pick R02's topology for it.
- `R05 — research/topics/05-sync-async-execution-model/prompts/sync-async-execution-model.prompt.md:25`
  - related (not a registry dependency): R01 (`ports-and-adapters-seam`) names this item as a related coupling — R01's seam decision (trait object, generic bound, or direct injection) wraps around whichever sync/async model this item picks, but R01 registers `http-transport-injection-seam`, which this item does not need to consume: the seam's shape is compatible with either a sync or an async execution model. Treat R01's direction as open, do not block on it.
- `R06 — research/topics/06-unsafe-code-policy/prompts/unsafe-code-policy.prompt.md:26`
  - related (not a registry dependency): R28 (`linter-and-editor-tooling`) decides how clippy/rustc lints are wired into the hook/CI pipeline. If this item recommends a clippy-based check (e.g. `clippy::undocumented_unsafe_blocks`) alongside a crate-root attribute, R28's CI-wiring answer is where that check lands — this item states the policy and the lint/attribute that expresses it, not which job runs it.
- `R07 — research/topics/07-contributors-bot-trigger-cadence/prompts/contributors-bot-trigger-cadence.prompt.md:25`
  - related (not a registry dependency): R21 (`contributors-bot-credential-source`) decides the bot's credential source (F061) on the same workflow file; this item decides only the `on:` trigger, not the auth mechanism.
- `R08 — research/topics/08-workflow-permission-hardening/prompts/workflow-permission-hardening.prompt.md:25`
  - related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides how many jobs exist per workflow and owns `ci-job-structure`; this item's per-job re-grant pattern applies uniformly regardless of R11's answer, so no parameter value is needed from it.
- `R09 — research/topics/09-self-hosted-runner-indirection/prompts/self-hosted-runner-indirection.prompt.md:25`
  - related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides how many jobs exist per workflow; each such job needs this item's `runs-on:` pattern repeated, but the pattern's shape does not depend on the job count.
- `R10 — research/topics/10-dependency-cache-action/prompts/dependency-cache-action.prompt.md:25`
  - related (not a registry dependency): R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation`, the toolchain-install step this item's cache action wraps; this item does not need R42's value to decide which cache action to use, only to know a toolchain-install step precedes it.
- `R11 — research/topics/11-ci-workflow-job-structure/prompts/ci-workflow-job-structure.prompt.md:26`
  - related (not a registry dependency): R02 (`crate-boundary-enforcement`) decides whether a crate-boundary/import-boundary-lint job exists in CI at all; this item's job-topology answer must have room for it either way. R12 (`aggregate-required-status-check`) consumes this item's `ci-job-structure` value to decide what an aggregate status-check job folds together. R13 (`dependency-vulnerability-scanning`) consumes this item's `ci-job-structure` value to decide whether its always-on SCA scaffold (F049) lands as a step inside a shared job or as its own dedicated job.
- `R12 — research/topics/12-aggregate-required-status-check/prompts/aggregate-required-status-check.prompt.md:25`
  - related (not a registry dependency): none beyond the consumed parameter.
- `R13 — research/topics/13-dependency-vulnerability-scanning/prompts/dependency-vulnerability-scanning.prompt.md:28`
  - related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides whether F049's always-on scaffold runs as a step inside a shared job or as its own dedicated job; this item's tool/one-liner recommendation must fit either shape R11 produces.
- `R14 — research/topics/14-large-file-guard-strategy/prompts/large-file-guard-strategy.prompt.md:25`
  - related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides whether `rs-launch-blueprint`'s CI checks are separate workflow files or jobs/steps inside `ci.yml`; py's CI-tier large-file guard is already its own dedicated workflow file (`large-file-guard.yml`), independent of `ci.yml`'s internal job structure, so this item's CI-tier recommendation does not need R11's value to be answered, only to be placed correctly relative to it.
- `R15 — research/topics/15-template-drift-receipt-guard/prompts/template-drift-receipt-guard.prompt.md:25`
  - related (not a registry dependency): none.
- `R16 — research/topics/16-codeql-config-customization/prompts/codeql-config-customization.prompt.md:25`
  - related (not a registry dependency): none.
- `R22 — research/topics/22-runtime-version-accessor/prompts/runtime-version-accessor.prompt.md:26`
  - related (not a registry dependency): R60 (`cli-parsing-framework`, F267 extended CLI version output) prints whatever version-metadata source this item selects; no registered parameter connects them — treat R60's direction as open, do not block on it.
- `R27 — research/topics/27-formatter-config-surface/prompts/formatter-config-surface.prompt.md:28`
  - related (not a registry dependency): R28 (`linter-and-editor-tooling`) decides clippy's config surface in the same bundle-decided-together spirit; F100's exclude-list scope question ("does Rust share one exclude list across rustfmt/clippy or keep them per-tool") depends on R28's clippy config shape — assume R28's answer is open and state the exclude-list recommendation for both outcomes if they diverge.
- `R28 — research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md:31`
  - related (not a registry dependency): R30 (`type-check-gate`) owns the type-checker engine and its CI/hook/strictness configuration (F105-F108, F110-F113). This item only picks that checker's editor-extension recommendation (F109) alongside the lint/format extension (F101) — assume R30 has picked a checker (likely `rust-analyzer`'s built-in diagnostics or a `cargo check`-based gate) and recommend the matching editor extension, without re-deciding which checker runs in CI.
- `R28 — research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md:32`
  - related (not a registry dependency): R27 (`formatter-config-surface`) decides `rustfmt`'s config surface in the same bundle-decided-together spirit; F100's exclude-list scope question depends on this item's clippy config shape — coordinate the answer's exclude-scope recommendation with R27's, but do not decide R27's formatter config here.
- `R29 — research/topics/29-non-code-file-formatting/prompts/non-code-file-formatting.prompt.md:29`
  - related (not a registry dependency): R27 (`formatter-config-surface`) decides whether the composite `just check`/`just all` recipe includes a Rust format-check step (F102). This item decides whether that same composite recipe, or a separate one, also runs the TOML/YAML/JSON/Markdown formatters chosen here — coordinate the recipe wiring recommendation with R27's answer, but do not re-decide F102 here.
- `R30 — research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md:28`
  - related (not a registry dependency): R28 (`linter-and-editor-tooling`) owns the type-checker's editor-extension recommendation (F109); assume this item's checker choice (`rust-analyzer`'s built-in diagnostics, a `cargo check`-based gate, or both) is what R28's editor-extension answer must match, without deciding R28's extension pick here.
- `R31 — research/topics/31-standalone-security-analyzer/prompts/standalone-security-analyzer.prompt.md:28`
  - related (not a registry dependency): R28 (`linter-and-editor-tooling`) owns the linter's own built-in security-rule coverage (F096). This item decides only whether a separate, dedicated AST-based security scanner is added on top of whatever clippy config R28 lands on — assume R28's built-in coverage exists and evaluate the marginal case for adding more, do not re-decide clippy's rule selection here.
- `R32 — research/topics/32-test-harness-and-execution/prompts/test-harness-and-execution.prompt.md:30`
  - related (not a registry dependency): R48 (`mocking-crates`) owns the mock/test-double and HTTP-transport-mocking crate pick (F119/F120) — coordinate on the shape of test doubles the harness expects but do not choose the crate. R33 (`property-and-snapshot-testing`, F122/F123), R34 (`scheduled-freshness-lanes`, F126/F127), and R35 (`coverage-tooling`, F134-F138) each own an adjacent testing-coverage decision this item must not re-open.
- `R33 — research/topics/33-property-and-snapshot-testing/prompts/property-and-snapshot-testing.prompt.md:28`
  - related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base runner and execution behavior these tests run under; this item's crates must run under whatever R32 picks, but does not decide it.
- `R34 — research/topics/34-scheduled-freshness-lanes/prompts/scheduled-freshness-lanes.prompt.md:27`
  - related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner and tiers this item's scheduled/advisory workflows would invoke; this item does not re-decide the runner.
- `R35 — research/topics/35-coverage-tooling/prompts/coverage-tooling.prompt.md:27`
  - related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner this item's coverage tool instruments; this item does not re-decide the runner.
- `R37 — research/topics/37-hook-manager-distribution/prompts/hook-manager-distribution.prompt.md:30`
  - related (not a registry dependency): R38 (`commit-message-linter`), R39 (`secret-scanning-hooks`), R40 (`auxiliary-hygiene-hooks`), and R41 (`lockfile-freshness-check`) each own a specific hook *job's* tool and config; this item owns the hook *manager*'s distribution, install trigger, and full-suite CI re-run — the container those jobs run inside, not their contents. R32 (`test-harness-and-execution`) owns F173 (the opt-in pre-push test-suite hook) — coordinate on where in the stage tiering it lands but do not re-decide it.
- `R38 — research/topics/38-commit-message-linter/prompts/commit-message-linter.prompt.md:27`
  - related (not a registry dependency): R24 (`changelog-section-mapping`) and the release-please configuration (ledger rows F063, F066, F073) consume the `commit-message-convention` parameter this item owns — coordinate the type-enum's naming so it maps cleanly to changelog sections, but do not decide that mapping here. R37 (`hook-manager-distribution`) owns the hook manager wrapping the `commit-msg` stage this item's tool runs inside.
- `R39 — research/topics/39-secret-scanning-hooks/prompts/secret-scanning-hooks.prompt.md:27`
  - related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering this item's scanner jobs would run inside; this item does not re-decide the manager.
- `R40 — research/topics/40-auxiliary-hygiene-hooks/prompts/auxiliary-hygiene-hooks.prompt.md:28`
  - related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering these four hooks would run inside; this item does not re-decide the manager. R09 (`self-hosted-runner-indirection`) owns actionlint's self-hosted-runner-specific config content.
- `R41 — research/topics/41-lockfile-freshness-check/prompts/lockfile-freshness-check.prompt.md:25`
  - related (not a registry dependency): R37 (`hook-manager-distribution`) owns the hook manager and its stage tiering this item's check would run inside; this item does not re-decide the manager.
- `R42 — research/topics/42-dev-toolchain-provisioning/prompts/dev-toolchain-provisioning.prompt.md:27`
  - related (not a registry dependency): R37 (`hook-manager-distribution`) decides how lefthook itself is installed (F143), a distribution question this item does not re-decide.
- `R42 — research/topics/42-dev-toolchain-provisioning/prompts/dev-toolchain-provisioning.prompt.md:28`
  - related (not a registry dependency): R27, R28, R29, R32, R37, R40 each pick their own dev tool; this item's `package-manager-invocation` parameter tells their Justfile recipes and lefthook jobs how to invoke whatever tool they pick.
- `R43 — research/topics/43-ai-assistant-repo-furniture/prompts/ai-assistant-repo-furniture.prompt.md:25`
  - related (not a registry dependency): none — this item's decision is self-contained repo furniture with no other research item's parameter as an input.
- `R44 — research/topics/44-devcontainer-environment/prompts/devcontainer-environment.prompt.md:25`
  - related (not a registry dependency): R42 (`dev-toolchain-provisioning`) decides the repo's general non-cargo toolchain-provisioning mechanism; if a devcontainer is adopted, its base image and `postCreate` step should be consistent with whatever R42 resolves to, but this item does not consume a registered parameter from R42 to do so.
- `R45 — research/topics/45-pr-comment-bot-trigger-block/prompts/pr-comment-bot-trigger-block.prompt.md:24`
  - related (not a registry dependency): R18 (`ai-assisted-review-workflows`) decides which AI-assisted review bots this template configures at all; this item's trigger-block content, if adopted, must name whichever bots R18 resolves to rather than inventing its own bot list.
- `R46 — research/topics/46-per-file-license-header/prompts/per-file-license-header.prompt.md:24`
  - related (not a registry dependency): none — this item's decision depends only on the already-fixed `license` parameter, not on any other research item's registered output.
- `R47 — research/topics/47-contributors-recipe-mode/prompts/contributors-recipe-mode.prompt.md:25`
  - related (not a registry dependency): none — the CI-side workflow this recipe complements is already settled (F060, `COMMON → REUSE`), so this item has no other research item's output as an input.
- `R48 — research/topics/48-mocking-crates/prompts/mocking-crates.prompt.md:27`
  - related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner and tiers this item's mock crates run under; this item does not re-decide the runner.
- `R49 — research/topics/49-build-target-declaration/prompts/build-target-declaration.prompt.md:26`
  - related (not a registry dependency): R68 (`release-binary-artifacts`) decides which distributable artifact types beyond the base `.crate` file this template ships (F214); this item's `[[bin]]`/`[lib]` declarations are the input R68's binary-artifact packaging builds on top of, but this item does not decide the artifact-type question itself.
- `R49 — research/topics/49-build-target-declaration/prompts/build-target-declaration.prompt.md:27`
  - related (not a registry dependency): R50 (`install-smoke-test`) decides how the built artifact is install-and-run tested; this item only declares what gets built.
- `R50 — research/topics/50-install-smoke-test/prompts/install-smoke-test.prompt.md:26`
  - related (not a registry dependency): R49 (`build-target-declaration`) owns `build-tool-output-shape`, the binary/library target names and layout this item's smoke test installs and runs; this item does not register a consumption of that parameter because its own test procedure does not vary by the target's exact name or path, only by whether a `[[bin]]` target exists.
- `R50 — research/topics/50-install-smoke-test/prompts/install-smoke-test.prompt.md:27`
  - related (not a registry dependency): R26 (`packed-artifact-content-guard`) decides the separate packed-content-assertion question (F039/F078); this item's install-and-run check is complementary, not overlapping.
- `R51 — research/topics/51-container-image/prompts/container-image.prompt.md:26`
  - related (not a registry dependency): R80 (`health-probe-endpoints`) decides the `/healthz` endpoint's own behavior; this item's container `HEALTHCHECK` instruction, if adopted, probes whatever endpoint R80 resolves to, but registers no dependency on it beyond that.
- `R52 — research/topics/52-toml-crate/prompts/toml-crate.prompt.md:26`
  - related (not a registry dependency): R53 (`config-schema-validation`) validates the value this item's parser produces; this item does not decide the schema or validation mechanism.
- `R53 — research/topics/53-config-schema-validation/prompts/config-schema-validation.prompt.md:26`
  - related (not a registry dependency): R52 (`toml-crate`) — this item's schema validates the value R52's parser produces. R55 (`config-error-tolerance`) decides what happens when this item's validation fails per-key; treat that as open. R56 (`config-secret-policy`) may add a `token` field to this item's schema; treat that as open.
- `R54 — research/topics/54-config-discovery-tiers/prompts/config-discovery-tiers.prompt.md:26`
  - related (not a registry dependency): R55 (`config-error-tolerance`) decides how a missing/unparsable/invalid layer this item discovers is handled. R56 (`config-secret-policy`) decides whether any tier this item discovers may carry a token. R57 (`xdg-directory-set`) decides the broader XDG directory set beyond config.
- `R55 — research/topics/55-config-error-tolerance/prompts/config-error-tolerance.prompt.md:27`
  - related (not a registry dependency): R54 (`config-discovery-tiers`) — F236's discovered-layer tolerance only applies if R54 adopts a discovered (non-explicit) tier; treat R54's answer as open. R53 (`config-schema-validation`) — F238's per-key-drop tolerance depends on whatever validation mechanism R53 selects.
- `R56 — research/topics/56-config-secret-policy/prompts/config-secret-policy.prompt.md:26`
  - related (not a registry dependency): R53 (`config-schema-validation`) — if this item concludes the file may carry a token, that field must be added to R53's schema. R54 (`config-discovery-tiers`) — this item's precedence chain composes with however many tiers R54 lands on.
- `R57 — research/topics/57-xdg-directory-set/prompts/xdg-directory-set.prompt.md:26`
  - related (not a registry dependency): R59 (`file-log-sink`) — F258's default file-sink path is the state directory this item would resolve, if adopted; R59 does not require this item to land first, since it may default to a hardcoded/relative path if this item concludes no data/state/cache set is needed. R67 (`error-and-exit-code-contract`) — the crash-log path would also consume this item's state directory, if adopted.
- `R58 — research/topics/58-logging-pipeline-architecture/prompts/logging-pipeline-architecture.prompt.md:28`
  - related (not a registry dependency): R59 (`file-log-sink`) builds its file sink on top of whatever pipeline this item recommends; treat R59 as downstream of this item. R57 (`xdg-directory-set`) may supply a state-directory default this item's pipeline does not itself need but R59 will.
- `R59 — research/topics/59-file-log-sink/prompts/file-log-sink.prompt.md:26`
  - related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline.
- `R59 — research/topics/59-file-log-sink/prompts/file-log-sink.prompt.md:27`
  - related (not a registry dependency): R57 (`xdg-directory-set`) — this item's default file-sink path (F258) depends on whether R57 concludes a state directory exists; treat R57's answer as open and state the fallback.
- `R60 — research/topics/60-cli-parsing-framework/prompts/cli-parsing-framework.prompt.md:32`
  - related (not a registry dependency): R22 (`runtime-version-accessor`, ledger row F064) decides whether `rs-launch-blueprint` reads its version at compile time (`env!("CARGO_PKG_VERSION")`) or via a runtime metadata lookup; this item's extended `--version` output (F267) prints whatever build metadata R22's answer makes available, but does not decide where that metadata comes from.
- `R61 — research/topics/61-interactive-prompts/prompts/interactive-prompts.prompt.md:26`
  - related (not a registry dependency): R67 (`error-and-exit-code-contract`) owns F299 (interactive-prompt cancellation), which is contingent on this item adopting an interactive-prompt crate at all — R67 needs to know only whether a crate exists, not any registered parameter value from this item.
- `R62 — research/topics/62-clipboard-integration/prompts/clipboard-integration.prompt.md:25`
  - related (not a registry dependency): R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes`; the typed error this item's clipboard-write function raises on failure eventually gets a catalog entry and exit code from R67, but this item does not need that value to make its own recommendation.
- `R63 — research/topics/63-progress-spinner/prompts/progress-spinner.prompt.md:25`
  - related (not a registry dependency): R65 (`color-enablement-chain`) decides F290's TTY-detection mechanism; this item's spinner-gating logic should reuse whatever check R65 lands on rather than implementing a second, divergent TTY check, but R65 registers no parameter this item formally consumes.
- `R64 — research/topics/64-pager-integration/prompts/pager-integration.prompt.md:26`
  - related (not a registry dependency): R65 (`color-enablement-chain`) decides F290's TTY-detection mechanism; this item's paging gate ("is stdout a terminal") should reuse whatever check R65 lands on rather than implementing a second, divergent TTY check, but R65 registers no parameter this item formally consumes.
- `R65 — research/topics/65-color-enablement-chain/prompts/color-enablement-chain.prompt.md:26`
  - related (not a registry dependency): R63 (`progress-spinner`) and R64 (`pager-integration`) each reuse this item's TTY-detection mechanism (F290) for their own stream-is-a-terminal checks; neither needs a registered parameter from this item, just its chosen mechanism. R66 (`output-format-surface`) decides which output formats exist and their rendering; whether the resulting text-mode table carries color styling (F289) is this item's concern, applied to whatever text-mode rendering R66's answer produces.
- `R66 — research/topics/66-output-format-surface/prompts/output-format-surface.prompt.md:26`
  - related (not a registry dependency): R85 (`rich-terminal-row-niceties`) owns F359, terminal-only presentation additions layered on top of whatever text-mode row rendering this item's answer produces; R85 needs no registered parameter from this item, only its text-format row shape as a starting point.
- `R67 — research/topics/67-error-and-exit-code-contract/prompts/error-and-exit-code-contract.prompt.md:28`
  - related (not a registry dependency): R57 (`xdg-directory-set`) decides whether `rs-launch-blueprint` adopts a dedicated state/cache directory set beyond config; this item's crash-log file (F302) needs a location that answer would provide, but R57 registers no parameter this item formally consumes — treat the state-directory question as open, state the assumption made, and do not block on R57's answer. R61 (`interactive-prompts`) decides whether an interactive-prompt crate exists at all; F299 is contingent on R61's answer.
- `R68 — research/topics/68-release-binary-artifacts/prompts/release-binary-artifacts.prompt.md:26`
  - related (not a registry dependency): R51 (`container-image`) decides the separate question of whether a container image ships as an additional distribution artifact for the optional web-service build; that is orthogonal to this item's CLI/library binary-artifact question.
- `R68 — research/topics/68-release-binary-artifacts/prompts/release-binary-artifacts.prompt.md:27`
  - related (not a registry dependency): R50 (`install-smoke-test`) decides how whichever artifact this item selects gets install-and-run tested; this item does not decide the test mechanism.
- `R69 — research/topics/69-web-framework-stack/prompts/web-framework-stack.prompt.md:28`
  - related (not a registry dependency): `web-extra-surface`'s value (this item's `owns` parameter) is consumed by R11 (`ci-workflow-job-structure`, CI job and skip-gating structure), R32 (`test-harness-and-execution`, test tiers), R37 (`hook-manager-distribution`, hook wiring for the OpenAPI snapshot check), R51 (`container-image`), R58 (`logging-pipeline-architecture`, shared logging pipeline profiles), and R71/R82/R83/R84 (the OpenAPI and docs gates) — the Parameters field of this item's answer must state a value precise enough for all of them to consume directly: whether the surface exists as a named Cargo feature, that feature's name, and what crates/capabilities it gates. R01 (`ports-and-adapters-seam`) decides the driven-I/O seam's shape (F001, `http-transport-injection-seam`); this item's web adapter must wire through whichever shape R01 lands on — treat R01's choice as open, do not block on it.
- `R70 — research/topics/70-http-problem-envelope/prompts/http-problem-envelope.prompt.md:26`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework hosts this envelope's error-handling extension point (F303); this item's envelope pattern must work with whichever framework R69 picks — treat R69's choice as open, do not block on it. R71 (`openapi-generation-pipeline`) owns the OpenAPI schema post-processing that keeps the generated error shape in sync with this envelope (F307); this item defines the envelope contract that R71 must document, not the sync step itself.
- `R71 — research/topics/71-openapi-generation-pipeline/prompts/openapi-generation-pipeline.prompt.md:29`
  - related (not a registry dependency): R70 (`http-problem-envelope`) decides the error envelope shape (F305/F306) that this item's schema post-processing (F307) must stay in sync with — treat R70's shape as open, do not block on it. R83 (`openapi-contract-fuzzing`) and R84 (`openapi-typed-client-generation`) each consume the committed snapshot this item produces (F332) — do not decide their scope here.
- `R72 — research/topics/72-api-pagination/prompts/api-pagination.prompt.md:27`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework this pagination extractor must integrate with — treat R69's choice as open, do not block on it.
- `R73 — research/topics/73-idempotency-middleware/prompts/idempotency-middleware.prompt.md:28`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this idempotency middleware must integrate with — treat R69's choice as open. R75 (`http-middleware-stack`) owns the overall middleware ordering contract (F317) this middleware must be placed within — this item does not decide that ordering.
- `R74 — research/topics/74-rate-limiting-middleware/prompts/rate-limiting-middleware.prompt.md:28`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this rate-limiting middleware must integrate with, and R70 (`http-problem-envelope`) decides the envelope shape 429 responses render through — treat both as open, do not block on them. R75 (`http-middleware-stack`) owns the overall middleware ordering contract (F317) this middleware must be placed within.
- `R75 — research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md:29`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/server this middleware stack runs on and which layer/middleware model it exposes — treat R69's choice as open, do not block on it.
- `R75 — research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md:30`
  - related (integration guidance; registry dependency above):
- `R75 — research/topics/75-http-middleware-stack/prompts/http-middleware-stack.prompt.md:31`
  - related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.
- `R76 — research/topics/76-cors-middleware/prompts/cors-middleware.prompt.md:27`
  - related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this CORS layer must integrate with. R75 (`http-middleware-stack`) owns the overall ordering contract (F317) this layer must be positioned within. Treat both as open, do not block on them.
- `R77 — research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md:27`
  - related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework whose state/DI mechanism this item's settings object is threaded through; treat the framework choice as open and answer *Fit for this template* generically or per-candidate-framework rather than assuming one.
- `R77 — research/topics/77-web-env-settings/prompts/web-env-settings.prompt.md:28`
  - related (not a registry dependency): R53 (`config-schema-validation`) decides the CLI's general config schema/validation crate; this item's env-settings object is web-only and does not need to share a crate with it, though reuse is a valid finding if the crate fits both.
- `R78 — research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md:27`
  - related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; use the logging architecture that R58 establishes; compare direct OpenTelemetry instrumentation with a bridge from that architecture, and record any required change rather than assuming a specific logging crate.
- `R78 — research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md:28`
  - related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's tracing spans instrument; treat the framework choice as open.
- `R78 — research/topics/78-opentelemetry-integration/prompts/opentelemetry-integration.prompt.md:29`
  - related (not a registry dependency): R79 (`prometheus-metrics`) is the sibling metrics decision for the same web service; using OpenTelemetry and useful request metrics in the example is shared; coordinate compatible integration boundaries while each item retains its own decision scope.
- `R79 — research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md:28`
  - related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's metrics middleware/route attaches to; treat the framework choice as open.
- `R79 — research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md:29`
  - related (not a registry dependency): R75 (`http-middleware-stack`) decides the general framework-appropriate middleware stack (request-id, access-log, security headers) this item's metrics collection sits alongside; a shared middleware-composition story is a valid finding but not a requirement.
- `R79 — research/topics/79-prometheus-metrics/prompts/prometheus-metrics.prompt.md:30`
  - related (not a registry dependency): R78 (`opentelemetry-integration`) is the sibling tracing decision for the same web service; its package remains optional behind the owner-fixed `otel` feature while this item is enabled by default, and the required web example must exercise the enabled OTel path.
- `R80 — research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md:28`
  - related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework these endpoints are routed through; treat the framework choice as open.
- `R80 — research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md:29`
  - related (not a registry dependency): R70 (`http-problem-envelope`) decides the problem-document envelope this item's `/readyz` 503 response reuses; assume some RFC 9457 envelope exists and design against it generically.
- `R80 — research/topics/80-health-probe-endpoints/prompts/health-probe-endpoints.prompt.md:30`
  - related (not a registry dependency): R51 (`container-image`) consumes this item's `/healthz` shape for its container `HEALTHCHECK` directive (F337); do not redesign the container probe here, only note what `/healthz` returns for it to probe.
- `R81 — research/topics/81-docs-delivery-model/prompts/docs-delivery-model.prompt.md:26`
  - related (not a registry dependency): R82 (`docs-correctness-gate`) decides the CI-facing correctness gate (link checking, rustdoc gating) built atop whatever docs tree or site this item produces; assume R82 resolves separately and design this item's tree/site to be checkable by either an mdBook-style build or a plain-markdown link walk.
- `R82 — research/topics/82-docs-correctness-gate/prompts/docs-correctness-gate.prompt.md:28`
  - related (not a registry dependency): R81 (`docs-delivery-model`) decides the docs tree/site this item's link checker and rustdoc gate check; assume R81 resolves to *some* delivery model and design this item's gate to fit either a generated-site build output or a plain-markdown tree.
- `R83 — research/topics/83-openapi-contract-fuzzing/prompts/openapi-contract-fuzzing.prompt.md:28`
  - related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item fuzzes against (F332); assume R71 resolves to *some* committed schema and design the fuzzer to consume it generically, without picking the generator.
- `R83 — research/topics/83-openapi-contract-fuzzing/prompts/openapi-contract-fuzzing.prompt.md:29`
  - related (not a registry dependency): R84 (`openapi-typed-client-generation`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides typed-client generation from the same schema, a separate concern from fuzzing.
- `R83 — research/topics/83-openapi-contract-fuzzing/prompts/openapi-contract-fuzzing.prompt.md:30`
  - related (not a registry dependency): R32 (`test-harness-and-execution`) decides the general test-tiering mechanism (marking a test "slow"/excluded from default runs) that this item's fuzz suite plugs into.
- `R84 — research/topics/84-openapi-typed-client-generation/prompts/openapi-typed-client-generation.prompt.md:27`
  - related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- `R84 — research/topics/84-openapi-typed-client-generation/prompts/openapi-typed-client-generation.prompt.md:28`
  - related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
- `R85 — research/topics/85-rich-terminal-row-niceties/prompts/rich-terminal-row-niceties.prompt.md:26`
  - related (not a registry dependency): R66 (`output-format-surface`) decides which output formats exist and the base text-mode row shape; this item's terminal-only row variant is layered on top of whatever row-rendering shape R66's answer produces. R65 (`color-enablement-chain`) decides the TTY-detection and color-gating mechanism; this item's hyperlink escape codes must only render when R65's gate allows it, and R65 registers no parameter this item formally consumes.
