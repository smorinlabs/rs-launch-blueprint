actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 37acd7c718c90060d00da77eccd363b911039cab0da3d8d0ba9637e93f20d622
verdict: approve
unresolved-findings: none

# R68 — directed verification of revision 7 (release-binary-artifacts, crate, Deep)

Verified file: `research/runs/R68/2026-09-17T033528Z-e504b7806e0c/review/DECISION.md`.
I recomputed its sha256 with `shasum -a 256` on 2026-09-27 before reading it. The result matched
the expected value above.

Scope: this is a directed check of the repairs enumerated from the revision-6 audits. It is not a
new trawl for findings. Sources read: `review/audit-fable.r6.md`, `review/audit-codex.r6.md`, and
`diff review/R68-r6-snapshot.md DECISION.md`. For anchor checks only, I also searched the live R50
file `research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/DECISION.md` (read-only). I made
three read-only `gh api` GET requests at `ref=v0.33.0` to spot-check the codex-3 facts. I read no
other audit or snapshot file.

## Diff scope

`diff` shows eight hunks:

1. the title (revision 6 → 7);
2. the new revision note and the relabelled "Revision 6 history" (lines 3–42);
3. the tool-and-pin row (:196);
4. the R50 hand-off (:444–:456);
5. the host paragraph (:519–:525);
6. the build-time sentence (:710–:711);
7. the artifact-sources paragraph (:725–:728);
8. the reproduction rule (:775–:779) and Disagreement 1 (:855–:857).

Every hunk is either one of the enumerated repairs or the conventional header, revision-note or
history update. There is no other change.

## Per-fix confirmations

### 1. JF6-1 + codex-2 (one edit): CONFIRMED

- **Hand-off, :444–:456.** It cites "revision 7, read 2026-09-27". It states that the R50 file
  "is uncommitted and still changing, so no digest is pinned and every citation of it here is
  anchored by quoted text rather than by line number". The false "revision header and the line
  numbers cited here unchanged" parenthetical is gone. The hand-off anchors each R50 statement with
  a quoted string:
  - `--locked --debug --no-track`;
  - the AC3 command `cargo install --path <extracted> --root <root> --locked --debug`;
  - `dev-profile compile`;
  - "R68's release build as the only release-profile compile the template is currently expected
    to perform";
  - "(13) R68 (`release-binary-artifacts`) resolving".

  The conditional status is retained: "R50's unaccepted proposal and can still change" and
  "**If R50 keeps `--debug`**". Re-verify trigger (7) is still referenced.
- **Build-time sentence, :710–:711.** It reads "R50 run decision revision 7, read 2026-09-27:
  `--locked --debug --no-track`, a `dev-profile compile`; see the R50 hand-off under
  `## Decision`". The sentence remains conditional ("as R50's current unaccepted proposal
  stands").
- **Disagreement 1, :855–:857.** It uses the same revision-7 citation with the same two quoted
  anchors. It keeps "while R50's unaccepted proposal keeps `--debug`" and re-verify trigger (7).
- **No R50 line numbers remain.** A search for `R50` lines containing `line[s] <n>` returned no
  match.
- **Live R50 spot-grep (`grep -F`, read-only).** Line 1 of the R50 file names "decision
  (revision 7)". Each anchor occurs in it:

  | Anchor | Occurrences | Lines |
  |---|---|---|
  | `--locked --debug --no-track` | 2 | 7 and 111 (install command and recipe) |
  | the AC3 `cargo install … --locked --debug` command | 1 | 331 (AC3) |
  | `dev-profile compile` | 1 | 429 (profile row) |
  | the "release-profile compile" quotation | 1 | 977 |
  | the "(13) R68 … resolving" quotation | 1 | 560 |

  Each passage describes its anchor's context correctly.

### 2. Codex-1 (CPU header): CONFIRMED, script half deferred as stated

- **Host paragraph, :519–:525.** It identifies the CPU name as the `cpu:` header, which the probe
  reads with `sysctl -n machdep.cpu.brand_string`. It says "That field may be unavailable". Under a
  denying sandbox, the log prints `sysctl: sysctl fmt -1 1024 1: Operation not permitted` and an
  empty `cpu: ` line. It also records that `system_profiler SPHardwareDataType` independently
  returned `Chip: Apple M4 Pro`.
- **Reproduction rule, :775–:779.** It reads "Header lines are not compared either". It covers the
  `date(UTC):` line and the possibly empty `cpu:` line, and says to confirm the host with
  `system_profiler SPHardwareDataType`.
- **Deferral.** The revision-note table (codex 1 row) states "**deferred**: the `profile-probe.sh`
  fallback to `system_profiler` (or an explicit unavailable label) lands in the next evidence
  revision". The text half stands on its own wording: it accurately describes the current script's
  behaviour and gives the cross-check.

### 3. Codex-3 (dist bootstrap): CONFIRMED, script half deferred as stated

- **Tool-and-pin row, :196.** The row says dist's "self-release workflow demonstrates a GitHub
  Release installer bootstrap, never a crates.io install". It states that at `ref=v0.33.0`,
  `.github/workflows/release.yml` line 67 fetches `v0.32.0/cargo-dist-installer.sh`, "not the
  `v0.33.0` asset". It cites `book/src/reference/config.md`, `ref=v0.33.0`, lines 163–176 ("will
  fetch and use the given version of dist"), and the `v0.33.0` release's own
  `cargo-dist-installer.sh` asset for the selected pin. The over-specific "from that GitHub
  Release's `cargo-dist-installer.sh`" wording is gone from this row.
- **Artifact-sources paragraph, :725–:728.** It states that "the bootstrap version that workflow
  actually fetches at `ref=v0.33.0` is **`v0.32.0`** (`release.yml` line 67 …)". It adds "which
  the script does not yet print (deferred to the next evidence revision; see the revision note)".
- **Deferral.** The revision-note table (codex 3 row) states "**deferred**: making
  `artifact-sources.sh` print the bootstrap version lands in the next evidence revision".
- **Live spot-check (read-only `gh api`, 2026-09-27).** All three facts hold:
  - `release.yml` line 67 at `v0.33.0` curls `…/releases/download/v0.32.0/cargo-dist-installer.sh`.
  - `config.md` lines 163–176 hold the `cargo-dist-version` section with the sentence "Your
    [release CI][github-ci] will fetch and use the given version of dist to build and publish
    your project."
  - The `v0.33.0` release assets include exactly one `cargo-dist-installer.sh`.

## Observations (non-blocking)

- **O1.** The revision note openly records a known self-check gap. `decision-self-check.sh` was not
  re-run, so its title assertion still names revision 6 and will fail against this file. For the
  same reason, the "as of revision 6" self-check passages were left unedited. The next evidence
  revision must update the script and re-run it, alongside the two deferred script halves.
- **O2.** The revision note records that `## Engines` Disagreement 10 still carries the
  over-specific wording "from that release's `cargo-dist-installer.sh`". It is out of scope here,
  so I only record it for the next audit.
- **O3.** The build-time sentence (:710–:711) and Disagreement 1 (:855–:857) do not restate that
  the R50 file is "uncommitted/in flux". The build-time sentence points to the hand-off, which does
  state it. Disagreement 1 carries the same dated revision-7 citation and quoted anchors, which
  already make the citation robust. I judge this sufficient.

## S1 adjudication (2026-09-28, Q23)

- File verdict was approve and stays approve. `decision-sha256` re-bound e0383096cc38 -> 37acd7c718c9 across the S1-attested micro-repair below; S1 verified by diff that no other byte changed. Original approval transfers under the Q23 verdict-transfer rule.
- S1 repair (one clause):

```diff
- which the script does not yet print
+ which no dedicated labeled assertion prints yet
(at DECISION.md:727; the only byte change r7-prerepair -> r7-final)
```
