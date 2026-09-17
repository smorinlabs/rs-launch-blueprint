decision-sha256: 78d7256f6bd9ac21c78560ffffeea343bee6c46fa98de1aeb20ed1e7071be8d9
actor: audit-fable-2026-09-17T020714Z-8fdb5c2010e7-r1
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: JF-1 the `snap/` inventory sentence miscounts the committed evidence (12/10 stated, 11/9 actual); JF-2 the back-reference "`R5.9` and `R10.1` print as quoted above" points at quotations the decision does not contain; JF-3 the py and ts source readings that carry the cross-language agreement claims are cited without file or line, ts not at all, and are not listed among the carried-from-raw rows; JF-4 the struct surface is attributed to an edition-2024 fact that forces injection rather than a struct; JF-5 the comparative adoption figure "roughly 2.4× less raw adoption" carries no number, endpoint or retrieval date

# Judgment audit — R57 xdg-directory-set, revision 1

Empirical (Codex) audit deferred: the Codex account is out of usage, so this
audit ran alone. Acceptance still needs the second approving verdict.

## Principle and agreement level

The decision states the shared requirement as a capability the user exercises —
find, relocate, back up and delete this tool's per-user files *by their kind* —
and then binds it at the level the org CLI Design Standard sets, not at the level
the ledger row happened to record. That ordering is right, and the standard
supports it. Read by me at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` of
`/Users/stevemorin/c/cli-standards` with `git cat-file -p` (the document states
`| **Version** | 1.4.14 |` at its line 7), rule `R5.3` at line 307 reads:

```
**R5.3 — Filesystem locations (XDG). (MUST)**
Per-user paths **MUST** follow the XDG Base Directory Specification, namespaced under the tool name, honoring `XDG_*` overrides and falling back to the defaults below.

| Purpose | Variable | Default |
|---------|----------|---------|
| Config | `$XDG_CONFIG_HOME/acme/` | `~/.config/acme/` (file: `acme_config.toml`) |
| Data | `$XDG_DATA_HOME/acme/` | `~/.local/share/acme/` |
| State (logs, history) | `$XDG_STATE_HOME/acme/` | `~/.local/state/acme/` |
| Cache | `$XDG_CACHE_HOME/acme/` | `~/.cache/acme/` |
| Runtime (sockets) | `$XDG_RUNTIME_DIR/acme/` | (set by system) |
```

and its provenance row at line 72 reads:

```
| 10 | Filesystem paths | XDG Base Directory Specification | Modern standard; predictable | org-locked |
```

The rule sentence governs *per-user paths a tool uses*; it does not oblige a tool
to use all five purposes. The decision's distinction — "what `R5.3` fixes
unconditionally is **where a file of a given kind goes**", with which roots ship
on day one argued row by row — is exactly what that sentence supports, no more.
The omitted **Runtime** row is the test the decision sets itself and passes: it
is declined on three independent grounds (nothing in the template opens a socket,
FIFO or lock file; the XDG specification gives `XDG_RUNTIME_DIR` no fallback; and
`etcetera` 0.11.0 returns `None` rather than inventing one), and the decision
records how the row becomes satisfiable later. Declining a row of a MUST table
while asserting the table's rule is unconditional is the one move that could have
been incoherent here, and it is argued rather than asserted.

The F249 disposition is correct and is stated as a ledger *disposition*, not an
edit. `docs/port/COMMONALITY.md:253` still carries the contingency clause
verbatim, which is what the runbook requires (`research/RUNBOOK.md:167`: "The
controller adjudicates `BASELINE-REVIEW:` findings with the affected decision
owners"), and the decision emits one `BASELINE-REVIEW:` line proposing the
replacement. It takes Opus's disposition over Codex's and says so, with the
gradation it added disclosed under Disagreement 2 ("Opus's disposition is taken,
edited for the gradation above"). Comparing the two raws confirms the account:
Codex's line (`raw/codex.md`) proposes "keep R57 config-only until R59 or R67
selects persistent disk output" — a restatement of the contingency, not a removal
— and Codex's `### Sources` names the freedesktop specification, crates.io,
GitHub, RustSec, docs.rs and the two pinned repositories, but not the org
standard, so the decision's reason for not being able to stand on Codex's text is
accurate. Opus's line (`raw/opus.md:346`) says the accessor set "is therefore
unconditional"; the decision narrows that to the location rule, which is the
weaker and better-supported claim.

## Design and evidence

Architectural alternatives are compared before any crate: hand-rolled over `std`
(A), config framework owns the paths (B), base-directory crate wrapped in a
template-owned type (C). Each rejection carries a reason that is not popularity —
A on ~150 lines of owned platform logic whose one benefit (injectable
environment) C supplies free, B on scope and on capability (it answers only the
config question and gives no data/state/cache accessor, and `confy` 2.0.0 depends
on `etcetera` anyway).

The library selection turns on a capability fact on a required CI leg, read at
each crate's own published source at a pinned sha256, not on downloads. That is
the gate-before-popularity rule applied literally, and the decision says so
(`directories`' "roughly 2.4× less raw adoption — accepted … since a download
count does not create a macOS state directory"). The excluding fact — `state_dir:
None` at both macOS construction sites in `src/mac.rs`, with zero occurrences of
`XDG_` in that file — is verified in this run (`## Empirical check` §5), and is
independent of the `directories` maintenance question, which is why leaving
Disagreement 3 (`archived` versus `stable-quiet` after the Codeberg relocation)
unsettled is genuinely immaterial. Disagreement 5 (`xdg` 3.0.0 gate 4) is
likewise immaterial: `xdg` is not recommended under either engine's reading, and
the decision records the open gate for a later item rather than resolving it from
one engine's word.

The spike carries enough provenance to be believed and re-run. `rustc 1.98.0
(88d9e12ae 2026-08-18) (Homebrew)`, `cargo 1.98.0`, `Darwin arm64` are in
`review/evidence/toolchain.txt`; its whole source is embedded in the committed
`review/evidence/r57-claims.sh` (a `[package] name = "r57spike"` manifest and a
heredoc `src/main.rs` calling `choose_base_strategy()`), it builds under
`WORK=$(mktemp -d)`, so "a throwaway package **outside this repository**" is
literally true, and every case runs under `env -i` with `HOME=/fixed/fake` so the
snapshot carries no machine-dependent text. Its output is committed at
`review/evidence/snap/spike-macos-arm64.txt` and matches the five cases quoted in
`## Empirical check` §8.

Both self-flagged findings are handled in the main body, not buried. B6 is
corrected under `### Principles and implementation` in bold — "**That test would
pass vacuously.**" — with the mechanism named (`std::env::home_dir()` falls
through to the `passwd` entry), the `Result` return type defended on the reachable
arm (a container UID absent from `/etc/passwd`), and the corrected construction
handed to P03 as validation item 2. The `RSLB101` routing is called "**this
decision's proposal for P03**" and the supporting count is one I reproduced:
`RSLB101` occurs exactly once in `research/topics/67-error-and-exit-code-contract/DECISION.md`,
on line 383, inside the owned parameter value. The prerequisite is current — the
file hashes to `16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`,
the value the decision cites — and its line 33 does defer the crash record's
location to R57, so the "already-accepted consumer" ground holds.

Nothing in the decision implements its own recommendation, which is correct for
this programme: the B1–B7 table is explicitly P03's, only the crate's half of B2
and B3 is claimed as observed, and `## Engines` carries seven `U#` rows naming
what would prove each.

## Completeness

Verified by me against the artifacts, all passing:

- The four `- assumes` values are byte-identical to `docs/port/PARAMETERS.md`
  lines 7–10 and appear in registry order (`msrv-policy`, `rust-edition`,
  `target-os-matrix`, `license`), compared field by field rather than by eye.
- The prompt's `## Couplings` carries bare `- owns:` and `- consumes:` lines, so
  "no owned parameter, and no consumed parameter" is right, and raising no
  `CONFLICT:` line is right.
- The H2 set and order — `## Decision`, `## Parameters`, `## Empirical check`,
  `## Engines` — matches `research/RUNBOOK.md:181-189`; `## Supersedes` is
  correctly absent (no reversal); `### Principles and implementation` and a
  `re-verify:` line are both present.
- Gate 1 is recorded as `inapplicable` with the ruling named, per
  `docs/port/OWNER-REVIEW.md` "2026-09-12 — no licence check for anything the
  template uses (Q4, superseded and widened by Q7.B)", which directs exactly
  that. No licence finding is raised.
- `review/evidence/r57-claims.log` gives 53 `^PASS`, 0 `^FAIL`, 0 `^SKIP` counted
  with `/usr/bin/grep -c` over the whole file, its last line is `failed
  assertions: 0`, and it hashes to
  `fbbe9fae82267a67d220b71536095e82edc38776ed845bc4017b478252332143`, the value
  the decision cites. The per-section counts the decision states (7 + 9 + 3 + 18
  + 6 + 4 + 6) sum to 53. The script was not re-run, per this audit's scope.

The reproducibility claims are stated as transcripts of procedures the
synthesizer ran (the byte-for-byte rerun diff and the `git archive HEAD`
extraction). Neither leaves an artifact in the tree, so neither is independently
checkable from the commit; both are, however, falsifiable by anyone re-running
the committed script, and the decision names the mechanism that makes them hold
(pinned tarball sha256s, a blob rather than a branch tip, snapshots under
`snap/`, machine-dependent text confined to `toolchain.txt`). I record this as a
limit on the evidence, not as a finding.

Figure provenance is good where the figure was collected here (§6 names the
endpoint and the retrieval date for each crates.io field; §7 pairs the RustSec
404 against a live `anyhow` 200 control) and is explicitly labelled where it was
carried (`U3`, `U4`, `U5` name the raw, its retrieval date 2026-09-17 — which
matches every retrieval date in `raw/opus.md` — and what re-fetching would prove).
JF-5 below is the one figure that escapes both treatments.

## Findings

Blocking here means the sentence misstates committed evidence or misattributes a
deciding ground; non-blocking means a citation or provenance gap. The role doc
gates approval on all unresolved findings regardless of that flag.

**JF-1 — the `snap/` inventory miscounts the committed evidence. Blocking.**
`## Empirical check` states:

> `snap/` holds 12 artifacts; **10 are committed and 2 are not** — the `.crate`
> tarballs match this repository's `.gitignore:12` rule `research/runs/**/*.crate`

`snap/` holds **11** files, of which **9** are in `HEAD` and 2 are gitignored.
The nine were added in one commit, `f78601b feat(research): synthesize R57
xdg-directory-set (revision 1)`, whose stat lists exactly those nine `snap/`
paths, so the tree never held ten committed snapshots at any revision. The rest
of the sentence is correct: `.gitignore:12` is `research/runs/**/*.crate`, and
the two absent files are `snap/etcetera-0.11.0.crate` and
`snap/directories-6.0.0.crate`. **Resolves by:** correcting the two numbers to 11
and 9. The paragraph's argument — that the tarballs' absence costs nothing
because the script re-fetches and sha256-checks them — is unaffected.

**JF-2 — a back-reference to quotations the decision does not contain.
Non-blocking.** `## Empirical check` §1 ends:

> `R5.9` and
> `R10.1` print as quoted above. 7 passing checks in this section.

Neither rule is quoted above. `R5.9` is referred to twice (as anticipating "a
documented cache location", and in P03 validation item 6) but never quoted;
`R10.1` occurs nowhere else in the decision, so "as quoted above" has no
referent. Both do print in the log, whose §1 assertions read `PASS R5.9 makes
documenting a cache location a SHOULD` and `PASS R10.1 places a stored credential
under $XDG_STATE_HOME`, so the evidence exists and only the cross-reference is
wrong. **Resolves by:** quoting the two rules, or replacing "as quoted above"
with what the log asserts.

**JF-3 — the py and ts source readings are carried without citation and without
being labelled as carried. Non-blocking.** Under "What must agree across py, ts
and rs" the decision writes:

> - One namespace segment, the *binary* name — py `APP_NAME = "plbp"`, ts
>   `TOOL_DIR_NAME = 'ts-projects'`, rs `rslbp`

The string `xdg-paths.ts` appears nowhere in the decision, and py's constant
carries a pin (`b08bccfb`) elsewhere but no file or line here. `raw/opus.md`
carries both at their pins — its `### Sources` items 3 and 4 give
`APP_NAME = "plbp"` at `paths.py:56` and `TOOL_DIR_NAME` at `xdg-paths.ts:13` —
so the facts are sourced, one layer back. The decision's `## Empirical check`
reads no py or ts file, and its carried-evidence rows `U3`–`U5` cover only the
adopter, issue-#117 and maintenance figures, so a reader cannot tell that the
cross-language agreement claims are also carried. The same trim removed a
citation from the example's comment, which in `raw/opus.md:292-294` read
"reproduces py's documented Windows behaviour (\"Windows has no data/state
split\", paths.py docstring at pin)" and in the decision reads only "reproduces
py's documented Windows shape". `AGENTS.md` requires citing the files in both
source repos. **Resolves by:** restoring the `paths.py:56` / `xdg-paths.ts:13`
citations at their pins, or adding a `U#` row that labels the py and ts readings
as carried from `raw/opus.md`.

**JF-4 — the struct surface is attributed to a fact that forces injection, not a
struct. Blocking.** The decision heads the argument:

> **The accessor surface is a struct, and one edition-2024 fact decides it.**

and closes it under *Tradeoffs*:

> the env-reading path itself must be covered by a child-process integration test
> rather than a unit test — which is precisely why the surface is a struct

The edition-2024 fact is correct and the `forbid` reading is correct
(`research/topics/06-unsafe-code-policy/DECISION.md:24` is `unsafe_code =
"forbid"`). What it establishes is that resolution must take its environment
*injected* rather than read it internally. It does not select a struct over free
functions: `pub fn config_dir(s: &impl BaseStrategy) -> PathBuf` is a free
function, is hermetically unit-testable, and violates nothing. The decision's own
analogy points the same way — it cites ts as injecting `env` and `homedir` as
parameters to a *free function*, `configDir(env, homedir)`, and then says "Rust
must do the TypeScript thing", which is injection, not a value type. The
`Tradeoffs` sentence is weaker still: if the env-reading path needs a
child-process test either way, that cost is unchanged by the surface shape. The
struct is independently and adequately justified elsewhere, under *Per target
shape* — resolve once at the composition root, R01's root constructing the value
rather than reaching for a static, and an embedding consumer needing to *supply*
paths through `from_strategy(&impl BaseStrategy)` — so this is a misattribution of
deciding force, not a wrong conclusion. **Resolves by:** reattributing in one
sentence: edition 2024 plus `forbid` rules out internal environment reads; the
struct is then chosen on resolve-once and the composition-root and embedding
requirements.

**JF-5 — a comparative adoption figure with no number, endpoint or retrieval
date. Non-blocking.** Under *Tradeoffs*:

> and roughly 2.4× less raw adoption — accepted under the explicit
> gate-before-popularity rule

`directories`' own download figures appear nowhere in the decision — the only
download numbers given are `etcetera`'s, at `GET
https://crates.io/api/v1/crates/etcetera` retrieved 2026-09-16 — so the
multiplier is unreconstructable from the decision, and the prompt's evidence
table requires each figure to carry its endpoint and retrieval date. **Resolves
by:** giving `directories`' `crate.recent_downloads` with its endpoint and date,
or dropping the multiplier and keeping the qualitative statement, which is all
the argument uses.

## Assessment

The recommendation is sound and follows from the evidence as written: four
accessors on one template-owned `Paths` over `etcetera` 0.11.0
`choose_base_strategy()`, namespaced `rslbp`, no runtime accessor, with
`directories` 6.0.0 excluded on a macOS capability absence verified in the
crate's own `src/mac.rs` at a pinned sha256 and corroborated by a macOS spike.
The F249 disposition is right and correctly framed, the two unsettled engine
splits are genuinely immaterial, the spike's provenance is sufficient, and the
two self-flagged findings are handled in the open.

**No finding moves the recommendation.** JF-1, JF-2 and JF-5 are corrections to
sentences about evidence; JF-3 restores citations to facts that are already
sourced one layer back; JF-4 reattributes a conclusion the decision already
justifies on other grounds. None requires new research, none touches the crate
choice, the accessor set, the namespace, the Runtime omission or the ledger
disposition. The verdict is `reject` only because the role doc admits no
unresolved findings on `approve` and an auditor may not edit the decision;
revision 2 is approvable with sentence-level corrections to the five passages
quoted above.

One matter outside this audit's scope, recorded for the controller: the empirical
(Codex) audit is deferred for lack of account usage, so acceptance still requires
that second approving verdict on whatever revision this becomes.
