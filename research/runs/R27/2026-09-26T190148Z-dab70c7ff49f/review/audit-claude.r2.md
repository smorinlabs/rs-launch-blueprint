actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 59972facff399c5712e45f18af321588d6a0c1ba39b205d1ef06e09a7e6ee388
verdict: approve
unresolved-findings: none

# R27 formatter-config-surface — empirical audit, revision 2

Target: `research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/DECISION.md`, revision 2.
The decision sha256 was recomputed with `shasum -a 256` before any other step. It matched the expected value `59972fac…e388`.

Scope: execution truth and evidence support only. I read `## Empirical check`, `## Engines` and the cited `## Decision` figures, plus `research/RUNBOOK.md` §5. I did not read any `review/audit-*.md`, any `raw/` file, or any `R27-r*-snapshot.md`.

## Environment

- Host: macOS, `Darwin 25.4.0 arm64`. `rustup 1.29.1 (d95a37b6a 2026-08-13)`.
- `PATH=$HOME/.cargo/bin:/usr/bin:/bin` and `RUSTUP_AUTO_INSTALL=0` were used for the toolchain probes. Each script sets the same values itself.
- `CARGO_HOME=/tmp/cargo-s29-R27-emp` (private to this audit). The original run used `/tmp/cargo-s9-R27`. No log line depends on this path.
- `TMPDIR=/var/folders/23/311glm5s6f918wv29gx_0xzm0000gn/T/`. The scripts build their scratch trees under `$TMPDIR/r27s/`.

## Reruns

Command, run from the repository root:

```bash
E=research/runs/R27/2026-09-26T190148Z-dab70c7ff49f/review/evidence
mkdir -p /tmp/r27-emp-r2
for c in r27-config-surface r27-workspace-scope r27-hook r27-channel-pin r27-figures; do
  shellcheck "$E/$c.sh"; echo "$c shellcheck=$?"
  "$E/$c.sh" > /tmp/r27-emp-r2/$c.log 2>&1; echo "$c exit=$?"
  cmp "$E/$c.log" /tmp/r27-emp-r2/$c.log && echo "$c IDENTICAL"
done
```

| Script | shellcheck | Exit | Pass / fail / skip | `cmp` against the paired `.log` |
|---|---|---|---|---|
| `r27-config-surface.sh` | 0 | 0 | 65 / 0 / 0 (`== summary: 65 checks, 65 pass, 0 fail`) | **identical** |
| `r27-workspace-scope.sh` | 0 | 0 | 14 / 0 / 0 (`== summary: 14 checks, 14 pass, 0 fail`) | differs at line 52 (wall-clock timings only; see below) |
| `r27-hook.sh` | 0 | 0 | 13 / 0 / 0 (`== summary: 13 checks, 13 pass, 0 fail`) | **identical** |
| `r27-channel-pin.sh` | 0 | 0 | 9 / 0 / 0 (`== summary: 9 checks, 9 pass, 0 fail`) | **identical** |
| `r27-figures.sh` | 0 | 0 | no assertions (observations only) | differs at line 1 (live public API data, 5 hours later; see below) |

Total: **101 assertions, 101 pass, 0 fail, 0 skipped.** This matches the decision's claim. The evidence directory was left untouched: file mtimes stayed 18:15–18:18 after the reruns.

### Drift 1: `r27-workspace-scope.log`, C2.8 timings

```
52c52
<     run 1 real=0.08s
---
>     run 1 real=0.06s
54,56c54,56
<     run 3 real=0.07s
<     just format-check real=0.54s
<   PASS format-check measured at 0.54s, under 5 s on this host
---
>     run 3 real=0.13s
>     just format-check real=0.36s
>   PASS format-check measured at 0.36s, under 5 s on this host
```

Judgment: this is not a finding. These lines are wall-clock measurements, so they cannot be byte-stable between runs. The only assertion on them is "under 5 s", and it passes again (0.36 s). The decision reports the figures as one scratch-workspace run on one host (`## Empirical check`: "The timing figures come from a six-file scratch workspace on one host"). The committed log supports the quoted values of 0.07–0.08 s and 0.54 s. My rerun gives the same order of magnitude. No claim that depends on these figures changes. That covers the composite placement (F102) and the glob rejection's "about 0.08 s per commit".

### Drift 2: `r27-figures.log`, live GitHub figures

```
1c1
< == retrieved 2026-09-27T01:15:13Z; ...
> == retrieved 2026-09-27T06:16:26Z; ...
10c10  rustfmt stargazers_count 6974 -> 6975 (archived=false, pushed_at 2026-09-24T13:36:12Z unchanged)
16c16  #7138: "no qualifying comment [none]" -> "first qualifying comment after 1.09 days"
26c26  answered=1 unanswered=9 median_days_answered=0.6 -> answered=2 unanswered=8 median_days_answered=0.845
46,47c46,47  clap stars 16726 -> 16727, pushed_at -> 2026-09-27T01:58:33Z; serde stars 10835 -> 10836
```

Judgment: this is not a finding. The script queries live public data and stamps its retrieval time on line 1. The decision's figures (F2 6,974 stars; F4 1 answered after 0.6 days, 9 unanswered) match the committed log at its recorded retrieval time, 2026-09-27T01:15:13Z.

The one semantic change is consistent with that log, not a contradiction of it. Issue #7138 was opened at 2026-09-26T02:29:13Z. At the original retrieval, 0.95 days later, it had no qualifying comment. Its first qualifying comment came at 1.09 days, after that retrieval. The rerun still supports the **active** maintenance verdict, and more strongly than before. F1, F3, F5–F10 reproduced unchanged: `1.98.1` published 2026-09-03T13:14:07Z, 718 open issues, the toolchain-file values, F7's tokio line, F8 and the F10 HTTP 404s.

Controller note ("any drift is a finding"): I examined both drifts. Each comes from a wall-clock or live-network measurement that is inherently non-reproducible and bound to a recorded time. Neither contradicts a decision claim or changes an assertion outcome. Every deterministic output reproduced byte for byte: all of C1, C3 and C4, and C2.1–C2.7.

## Figures re-derived at source

- **`rustfmt.toml` hash.** I extracted the TOML block from the decision (`DECISION.md` lines 27–32) and piped it to `shasum -a 256`. The result was `a714037d3cb8919614f9b8619ff9a940ac858e5da22b25298abb7f68c310bea8`. This equals the decision's stated hash and the hash the rerun of C1.1 printed.
- **Toolchain table.** I read each version from the tool:
  - `rustc/rustfmt/clippy +1.93.0`: 1.93.0 / `1.8.0-stable (254b59607d 2026-01-19)` / 0.1.93.
  - `+stable`: 1.94.0 / `1.8.0-stable (4a4ef493e3 2026-03-02)` / 0.1.94.
  - `+1.96.0`: 1.96.0 / `1.9.0-stable (ac68faa20c 2026-05-25)` / `'cargo-clippy' is not installed`.
  - `+1.96`: 1.96.1 / `1.9.0-stable (31fca3adb2 2026-06-26)` / 0.1.96.
  - Homebrew: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, `rustfmt 1.9.0`.

  Every cell matches the decision's table, including "not installed" for clippy on 1.96.0.
- **C4.5 and C4.6 in the rerun log.** C4.5: all four builds give formatted sha256 `a251383e89c8906f`. C4.6: 806/410, 811/408 and 819/414 lints (total/warn-by-default); the 6 new warn-by-default lints include `clippy::manual-take` and `clippy::manual-pop-if`. Both match the decision's C4 row.
- **C1.1 "all four rustfmt builds".** The rerun log lists them as rustup 1.94.0, 1.96.0, 1.96.1 and Homebrew 1.98.1. Each gives `exit=0 warnings=0 output=empty`. That is consistent with the decision's wording.

## Revision-2 scope check

The revision note states that revision 2 is prose-only and that all evidence bytes are unchanged. That is consistent with the evidence: every deterministic log reproduced byte for byte against the paired committed `.log`, and the scripts pass shellcheck. The two fixes named in the revision note (F1 in `## Engines` row 1 and the channel body; F2 in the hook-mode section) are judgment and fidelity matters. They are outside this empirical seat's scope, and they move no executed check or figure.

## Result

Every executed claim in `## Empirical check` reproduces. The load-bearing figures re-derive at source. The only byte drift is wall-clock timing and live-API data, which is expected and supports no changed claim. Verdict: **approve**, with no unresolved findings.
