actor: codex
model: gpt-6-astra
family: openai
decision-sha256: 9e5aaf13544bc41f5ca56cac563a5c0e1dfd7bb9f9373afec6302de34e0ff775
verdict: approve
unresolved-findings: none

# R73 revision 4 empirical re-run

The target `review/DECISION.md` hash matched before any other read and matched again after execution. This is the single Q23 empirical re-run for the Codex seat. The revision note at `DECISION.md:3-5` retains the exact **required-next-rev (HR-A Q4)** label. The point-in-time coordinator context was `research/EXECUTION.json` sha256 `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`; no live policy drift is treated as a finding.

All six committed evidence scripts were run unmodified in the foreground, in their default snapshot modes, with the prescribed `CARGO_HOME=/tmp/cargo-s69-R73-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s69-R73-evr-target`. Their rerun stdout and stderr are in `/tmp/r73-evr-*.log`; no evidence log or snapshot was rewritten. The first probe attempt skipped resolution because the prescribed Cargo cache was empty and network access was unavailable. A second run with network access filled that same `/tmp` cache and completed in under 1200 seconds. The completed probe output is `/tmp/r73-evr-probe-network.log`.

| Script | Rerun result | Byte comparison with committed log |
|---|---|---|
| `r73-standard-conformance.sh` | 45 pass, 0 fail, 0 skip | Different UTC timestamp only |
| `r73-probe.sh` | 27 pass, 0 fail, 0 skip; 10 store and 18 router tests pass | UTC timestamp, scratch path, test scheduling, and measured timings differ; all assertions and dependency deltas agree |
| `r73-sources.sh` | 23 pass, 0 fail, 0 skip | Different UTC timestamp only |
| `r73-registry.sh` | 17 pass, 0 fail, 0 skip | Different UTC timestamp only |
| `r73-muse-currency.sh` | 46 pass, 0 fail, 0 skip | Different UTC timestamp only |
| `r73-decision-shape.sh` | 37 pass, 4 fail, 0 skip; exit 1 | UTC timestamp and the `D7-tree` unrelated missing-topic list differ; the same four check IDs fail |

The five evidence scripts reproduce **158 pass, 0 fail, 0 skip**, as `DECISION.md:769-783` claims. `P5-bench` now measures 193 ns/op instead of the committed 184 ns/op; both support the decision's stated sub-microsecond conclusion. The shape failures are `D8-r02-sha`, `D8-r02-workspace`, `D8-r02-b1b2`, and `D7-tree`, all disclosed at `DECISION.md:784-807`. The three R02 checks read a live revision that moved past the accepted revision 2; the accepted revision 2 snapshot still hashes to `9e8f8e8c11ffb9b383819b2de1b05eab71a32e3af358b75ea8475d48f3c9707f` and retains the cited workspace and `B1`/`B2` lines at 22, 78, and 251. `D7-tree` continues to fail on missing topic publications outside R73 in the clean extraction, while `D7-tree-live` passes. The list of those unrelated topics has changed since the committed log; the disclosed cause still holds.

## Revision 4 repair check

- `DECISION.md:495-510,636` narrows the 503 execution claim to failure at `begin()` and describes completion failure as a forwarded 2xx with possible re-execution after expiry. The retry table at `:298-309` carries the same consequence. This matches the probe's `layer.rs:197,203,215` result-discard paths and `w15`'s pre-`begin()` poison case.
- `DECISION.md:749-758` says `s10` executes `PortError::Unavailable`, leaving the `RSLB101` mapping for P03. `:197-202` labels `s06` a three-entry demonstration and the 1,025th-key case an inference. `:567-575` states five `Begin` outcomes and ten store checks. The rerun reports ten store tests.
- `DECISION.md:424-458,520-539` defines claim tokens, conditional completion and abandonment, capacity handling, and the web dispatch seam. `:538-553` defines validated `dry_run` behavior. `:844-855` explicitly says the probe implements none of these revision 4 refinements and assigns proposed acceptance cases 23-27. The probe's 28 passing behavioral tests are therefore not presented as tests of those refinements.
- `DECISION.md:1084-1098` identifies Perplexity's optional fingerprint allocation; `:1250-1288` leaves R75 placement as its decision and correctly distinguishes `MethodRouter::route_layer`; `:1309-1351` records the R78/R79 instrumentation obligations and the unexecuted integrated cases. The per-outcome retry table at `:298-309` replaces the blanket retry claim.

## Findings

- **OBS-1 — Expected log bytes differ.** Five evidence logs differ in run metadata or nondeterministic probe output, with no changed check result or load-bearing value. The shape log differs in its `D7-tree` list, but retains the disclosed four failures and 37 passes.
- **OBS-2 — Revision 4 contract remains unexecuted.** Claim ownership, capacity under running claims, offloaded store dispatch, validated `dry_run` values, 405 placement, and integrated OpenTelemetry cases remain P03 acceptance obligations explicitly listed in the decision. The decision does not claim the revision 3 probe executes them.

No BLOCKING finding: the complete empirical rerun did not contradict a load-bearing claim, and the decision discloses the remaining execution gaps.
