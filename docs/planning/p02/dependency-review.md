# P02 dependency and effort review

## Recorded graph

The recorded graph has **84 nodes**, **66 edges**, and no cycles. It has 4 waves with counts 33 · 19 · 15 · 17. Its critical depth is 3 edges. The longest paths are graph order only, not a duration forecast; the first is `R01 → R69 → R11 → R08`.

The graph was recomputed from all 84 prompt files. An edge is recorded only when (1) an item names an `R##` on `- consumes:`, or (2) a non-owner names a parameter owner on `- related`. A mutual mention, an owner mentioning a consumer, and other descriptive text do not create an edge.

## R58 ownership gap

`R58` decides the logging architecture: selected stack, initialization and extension composition, redaction, CLI/web profiles, and the OpenTelemetry integration boundary. `R59` says its file sink is attached to R58's pipeline; `R75` must fold framework logging into that pipeline; and `R78` must plug its OTel layer into the pipeline. None can safely choose its integration mechanism before R58's stack is known, yet `R58` owns no registry parameter, so the Runbook's two rules do not schedule those relations. R58 itself already has the recorded hard prerequisite `R69` through `web-extra-surface`; the proposed edges do not reverse it.

## Minimum justified amendment

Do not convert every descriptive relation into an edge. Add one researched parameter, `logging-pipeline-contract`, owned by `R58`, with a value that names the selected tracing/logging stack, initialization and extension interface, structured-field/redaction contract, CLI/web profile boundary, and optional OTel feature boundary. Add exactly these registry consumers: `R59`, `R75`, and `R78`. This turns their existing semantic input into an auditable parameter rather than making a vague global ordering rule. It requires coordinated edits to `docs/port/PARAMETERS.md`, the R58/R59/R75/R78 prompts, and dependency order; it is **proposed**, not currently recorded.

The simulation has **69 edges**, remains cycle-free, and has critical depth 3 edges. It changes levels only for: R59, R75, R78. It should be accepted only if the controller agrees that the contract must be fixed before those consumers research their integration. The graph output retains recorded and proposed edges separately.

## Effort and execution constraints

The schedule assigns **6 Light**, **53 Focused**, and **25 Deep** proposals. Deep is reserved for consequential choices that also retain material uncertainty, hard reversal, or cross-subsystem compatibility risk. A public or security adapter with a fixed upstream policy can be Focused; a parameter owner is never Light. R38 is a bounded three-engine pilot exception while remaining Focused.

The requested engine sets are proposals: Light = Luna plus independent Terra; Focused = Terra plus Opus; Deep = Terra plus Opus plus Doxa. They are not currently compliant replacements for Runbook §2's “every configured engine” rule. This analysis does not authorize dropping coverage: any such change requires an owner amendment. Each tier still needs both independent audits and a real empirical gate; no provisional assignment is an accepted research answer. Escalation raises a tier when evidence shows the initially bounded choice is actually consequential or incompatible.

## Foundational items the graph understates

There are 77 nodes with no recorded descendants. In particular, R02, R05, R06, R58, R60, R65, R66, R70, R75, R78, R79, R80, R81, R82 are foundational decisions by scope but have zero graph influence under the exact rules. Treat the absence as an ownership/scheduling review queue, not as evidence to reduce their research depth.
