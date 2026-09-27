actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 9197c005a053eb476fe3ed4e7905700f243a3dd5f357082d7698de908ad5f331
verdict: approve
unresolved-findings: none

# R83 — empirical audit of DECISION.md revision 3

Auditor: fresh Claude Opus 5.5 context (`claude-opus-5-5`), independent of the synthesizer and the
judgment auditor. Scope: execution truth and evidence support only. Date: 2026-09-27.

## Target identity

`shasum -a 256 research/runs/R83/2026-09-17T034011Z-2af391428997/review/DECISION.md` printed
`9197c005a053eb476fe3ed4e7905700f243a3dd5f357082d7698de908ad5f331`, which equals the expected hash.
The header reads "decision (revision 3)".

## Environment

- Host: macOS (Darwin 25.4.0), arm64.
- Toolchain: `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`.
- `CARGO_HOME=/tmp/cargo-s43-R83-emp` is a private, initially empty cargo home.
- `CARGO_TARGET_DIR=/tmp/cargo-s43-R83-emp-target` was set. `muse-adjudication.sh` overrides it per package; `contract-fuzz-probe.sh` does not.
- Working directory for every script: `research/runs/R83/2026-09-17T034011Z-2af391428997/review/evidence/`.
- Output went to `/tmp/r83-emp-r3/`. Nothing under `evidence/` was written.

## Reruns (all four scripts, per RUNBOOK §5 "The empirical auditor reruns the check")

| Script | Command | Exit | Totals | stderr | Byte-compare against committed `.log` |
|---|---|---|---|---|---|
| `contract-fuzz-probe.sh` | `./contract-fuzz-probe.sh > /tmp/r83-emp-r3/contract-fuzz-probe.log` | 0 | PASS=24 FAIL=0 SKIP=0 TOTAL=24 | empty | differ, lines 3–4 only (see below) |
| `muse-adjudication.sh` | `./muse-adjudication.sh > /tmp/r83-emp-r3/muse-adjudication.log` | 0 | PASS=8 FAIL=0 SKIP=0 TOTAL=8 | empty | **identical** (`cmp` silent; both sha256 `108bacf01e2e27db1eff91b3c8dfdc7c0647ab2ca4943b1515bf30e0c4ce14a6`) |
| `registry-and-standard.sh` | `./registry-and-standard.sh > /tmp/r83-emp-r3/registry-and-standard.log` | 0 | PASS=29 FAIL=0 SKIP=0 TOTAL=29 | empty | differ, line 3 and lines 60–61 only (see below) |
| `registry-skip-paths.sh` | `./registry-skip-paths.sh > /tmp/r83-emp-r3/registry-skip-paths.log` | 0 | PASS=12 FAIL=0 SKIP=0 TOTAL=12 (inner copy `PASS=0 FAIL=0 SKIP=6 TOTAL=6`) | empty | **identical** (both sha256 `8fb45a92298c8e9205134b57688bcc6df3d0b71d37fbb3ff764a14780d54c486`) |

Sum: **73 PASS, 0 FAIL, 0 SKIP**. This matches the decision's carried figure. No real SKIP was taken.

### Differences, quoted, and why neither is drift

`contract-fuzz-probe.log` (`cmp`: "differ: char 82, line 3"):

```
3,4c3,4
< rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
< cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
---
> rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)
> cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)
```

The toolchain header is the only difference. The decision discloses it in `## Empirical check`:
"The host has since moved to `rustc 1.98.1` … `contract-fuzz-probe.log` was not rerun, so it
still records 1.98.0". Every assertion line and every normalised test-output line is
byte-identical under 1.98.1. That includes the seeded 5xx, the minimal failing input, the
boundary-bias sweep `20/20` against `2/20`, the 3.0.3 `UnsupportedSpecFileVersion`, and the
dependency counts `60` and `141`.

`registry-and-standard.log` (`cmp`: "differ: char 93, line 3"):

```
3c3
< retrieved: 2026-09-27T07:41:52Z
---
> retrieved: 2026-09-27T16:07:50Z
60,61c60,61
< oas3: recent_downloads=997209 downloads=2239368
< openapi-fuzzer: recent_downloads=39 downloads=11730
---
> oas3: recent_downloads=1000779 downloads=2242938
> openapi-fuzzer: recent_downloads=40 downloads=11731
```

Line 3 is the `retrieved:` timestamp. Lines 60–61 fall inside
`== volatile figures (counters move; re-read rather than diff) ==`, which spans lines 55–62. The
decision says to re-read that section against its guarding assertions rather than diff it. The
whole `== stable assertions ==` section (lines 5–54) is byte-identical, so every B-check and every
rule text at its pinned line is unchanged. The volatile section was re-read against its guards,
and both still PASS:
`PASS  B23 openapi-fuzzer has had no push since 2024 (maintenance: at-risk)` and
`PASS  B24 oas3 was pushed in 2026 or later (maintenance: active)`.

## Figures re-derived at source

| Claim in the decision | Source checked | Result |
|---|---|---|
| Probe harness is 482 lines (D9, HIGH question 2) | `wc -l evidence/contract-fuzz-probe/tests/contract_fuzz.rs` | 482. Confirmed |
| Probe is valid-only: `contract_fuzz.rs:347`–`:355` builds a `Union` of `min`, `max`, a uniform draw, and `0` when in range | `sed -n 335,360p` | Lines 347–355 are exactly that `Union`; no out-of-range arm exists. Confirmed |
| HIGH question 2 names "both valid and boundary-invalid request payloads per operation" (`inputs/prompt.md:36`) | `sed -n 36p` | Confirmed verbatim |
| Muse says "valid and boundary-invalid" at `raw/muse.md:23`, `:25`, `:65`, `:93` | `grep -n` | Found at exactly lines 23, 25, 65, 93. Confirmed |
| Muse: "Executed results: none" (`:105`) | `sed -n 105p` | Confirmed |
| `raw/muse.md` sha256 `dbd36128…c5df`, 138 lines | `shasum`, `wc -l` | Confirmed |
| Manifest `state` `partial`, `required_engines` `["muse","opus"]`, `operations.muse` `request_id` `2c70e838…`, state `submitting` | `manifest.json` | Confirmed |
| Prompt `:25` `- engines: muse, opus`; `:74` "…line is authoritative" | `sed -n` | Confirmed |
| RUNBOOK §2 lists R83 in the Muse bulk set; Q9.B retired Codex (`RUNBOOK.md:70`–`:73`) | `sed -n 70,73p` | Confirmed |
| Ledger `:1114` records Q5.A Muse bulk substitution | `sed -n 1114p` | Confirmed |
| py pins `schemathesis` 4.21.5 (`uv.lock:2257`–`:2258` at `b08bccfb`) | `git show b08bccfb:uv.lock` in `~/c/py-launch-blueprint` | `name = "schemathesis"` / `version = "4.21.5"`. Confirmed |
| `pyproject.toml:80` only declares the dependency; no `schemathesis.toml` at the pin | `git show`, `git ls-tree` | Line 80 is `"schemathesis>=4.0.0", # WEB-50 …`. The tree has 0 `schemathesis.toml` files. Confirmed |
| py test sets only `max_examples` and `checks` (`tests/web/test_contract.py:21`–`:30`) | `git show b08bccfb:…` | `from_asgi`, `@hypothesis_settings(max_examples=10, deadline=None)`, `checks=(not_a_server_error,)`. No mode narrowing. Confirmed |
| `builder.py:103` does `st.one_of(… for mode in generation.modes)` | installed `schemathesis-4.21.5` in py `.venv` | Confirmed verbatim |
| `_generation.py:63` default `modes or list(GenerationMode)` | same | Confirmed |
| `modes.py:6`–`:12` enumerates `POSITIVE` and `NEGATIVE` | same | Confirmed |
| `_projects.py:396`–`:418` `generation_for` returns the project default when no operation or phase config applies | same | `if not configs: return self.generation`. Confirmed |

## Evidence support of revision 3's change

Revision 3's only change is D10 and the widened P2, which add boundary-invalid generation. The
decision labels that change **proposed, not executed** in five places:

- the revision note;
- the HIGH-question-2 paragraph;
- the "Revision 3 ran nothing new" paragraph;
- the unproven-claims list, which states "designed here, not executed" and names the P03 proof;
- the D10 row.

The source checks above support each of its three grounds. Ground (a) is the prompt. Ground (b)
is py's default `NEGATIVE` mode. Ground (c) is serde integer semantics; the decision itself lists
this as unmeasured, under "Claims recorded as unproven". The per-keyword cost is labelled
"estimated, not measured". No claim of execution exceeds what the committed evidence shows.

The decision says revision 3 changed no evidence script, log or fixture. My reruns are consistent
with that. Two logs are byte-identical, and the other two differ only in the disclosed fields.

## Findings

None unresolved.

Observation, not a finding: `CARGO_TARGET_DIR` was set in this audit's environment, and
`contract-fuzz-probe.sh` does not override it. The byte-identical normalised output shows the
variable does not affect the log.
