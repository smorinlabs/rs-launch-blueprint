decision-sha256: 7eec09c4091f7a325a03bf2a0285816b6e57df512c7a56a2bf1eb6b831826727
actor: audit-codex-2026-09-06T043454Z-33c81db94a3b-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: cargo-update-types mechanism is false; saved empirical check does not replay the decision's named source pins

## Rerun

The saved script was recovered byte-for-byte from the `===== SCRIPT SOURCE =====`
section of `review/evidence/dependabot-config-shape.log` into `/tmp/r19-check.sh`.
I invoked `bash /tmp/r19-check.sh` from
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`, the decision's recorded
working directory, with stdout and stderr saved to
`review/evidence/audit-dependabot-config-shape-r1.log`.

The requested Linux invocation could not run because `limactl shell ubuntu`
reported that the instance was stopped, and `limactl start ubuntu` was denied
access to `~/.lima/ubuntu/ha.stdout.log` by the sandbox. The rerun therefore
used macOS: Darwin 25.4.0 arm64, `rustc 1.98.0`, `cargo 1.98.0`, `gh 2.98.0`,
and Python 3. The completed script reports `failed assertions: 0`, whose final
branch exits 0.

The log is complete, but its output does not reproduce the decision's remote
snapshot. The script resolves `main` at run time, obtaining
`dependabot-core` `a141eb05a281ffe077024c93d7050a7840d32365` and `github/docs`
`f3619f5907dd1da5f44d3bbc4e5566373db1fd15`, rather than the decision's
`1abafc5c` and `dd75c5f3` pins. It also now sees one open ratatui Cargo PR,
not five. It did emit every numbered section that the decision attributes to
it, including sections 2, 3, 4, 5, 8, 10, 11, 12, 13, 14, 15, and 16.

## Findings

### F1 — the `update-types` rejection states the opposite of the pinned implementation

The decision says a Cargo `update-types: [minor, patch]` group would include a
Cargo-incompatible `0.1 -> 0.2` update because Dependabot uses plain SemVer
(lines 120 and 198). That is false at the stated `dependabot-core`
`1abafc5ca0900334fd970832e9ef43f2afc78233` pin. The production code in
`cargo/lib/dependabot/cargo/version.rb` sends pre-1.0 updates to
`cargo_pre_1_0_type`; that method returns `major` when the `0.y` component
changes. The pinned test explicitly asserts that `0.1.0 -> 0.2.0` is `major`
and `0.1.0 -> 0.1.1` is `patch`. The group-update path in
`updater/lib/dependabot/updater/group_update_creation.rb` computes that Cargo
type and admits an update only when the group's `update-types` contains it.

The unconditional Cargo production predicate is real: `cargo.rb:19` registers
`->(_) { true }`. Therefore the role-taxonomy capability limit is supported,
but the independent mechanism used to reject ts's update-type filter is not.
The decision must remove the false claim, reconsider the `update-types` choice
on its actual trade-offs, and revise all dependent text before acceptance.

### F2 — the saved check is not a replay of the named source snapshots

Although the decision calls its sources fixed commits, the recovered script
first asks GitHub for each repository's current `main` SHA and then reads that
new SHA. The rerun therefore inspected newer commits. The script can establish
an internally consistent snapshot for its own run, but it cannot reproduce or
verify the implementation claims at the commits named by the decision. This
also explains why its live ratatui output changed. Replace the `main` lookups
with the two literal decision pins, record those inputs, and retain a separate
live-observation section with its retrieval time.

### Checked observations that do not require a decision change

The archived, decision-cited log records all three ratatui observations at its
2026-09-10 retrieval: five open Cargo PRs against a limit of three, three
release ages below seven days, and per-dependency Cargo branches despite a
wildcard group. The rerun still confirms the cooldown observation, but not the
open-PR observation because four of those PRs have since closed. This is normal
live-state drift, not evidence that the historical count was fabricated. I
checked PRs 2760, 2762, 2764, 2765, and 2732: the first four closed at
20:34–20:38 UTC, after the decision log's 15:41 UTC retrieval, while 2732
remains open. Thus all five were open when the decision made its bound.

The decision treats the anomaly as a bound, not an explanation: it says the
older configuration or defaults are hypotheses and identifies the repository's
Dependabot tab and job logs as the evidence needed for a cause. That scope is
correct. The label omission is also supported: the named implementation
registers the Cargo default label, the rerun observed default labels live, and
the pinned documentation says an absent declared label is ignored. All four
`assumes` lines match the current `docs/port/PARAMETERS.md` values exactly after
removing Markdown cell delimiters.

## Assessment

Reject revision 1. The decision may still select a catch-all group, but it
cannot reject the TypeScript update-type shape on a source claim contradicted
by the exact source pin. Revision 2 needs an immutable-pins checker and a
re-evaluated grouping rationale; the role-taxonomy and label findings can be
retained at their stated limits.
