actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 7a9345c67b42d504501e2039214fd42d9d31b69d61402c958c62c5bf7448a410
verdict: reject
unresolved-findings:
  1. EA-1 (observed failure): `engines-r4.sh` does not reproduce. It fails 1 of 75 checks.
     - Failed claim: the `## Empirical check` table says "`engines-r4.sh` (revision 4) | `./engines-r4.sh > engines-r4.log 2>&1` | **PASS 75, FAIL 0, SKIP 0, exit 0**". The committed `engines-r4.log` records the same result.
     - Evidence: the fresh run on 2026-09-27T08:16:10Z exited 1 with `PASS 74  FAIL 1  SKIP 0  TOTAL 75`. The diff against the committed log is `88c88`:
       `< PASS  R80 claims OV-05 (JF-1 5) (:20)`
       `> FAIL  R80 claims OV-05 (JF-1 5) — line 20 of .../research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md lacks: OVERRIDE (OV-05)`
       The cause is drift in a file that another item owns. `engines-r4.sh:181` pins line 20 of R80's working-tree `DECISION.md`. That file is modified and uncommitted (`git status`: ` M`, mtime 2026-09-27 00:41 PDT, which is 07:41Z). The edit happened after the committed log's run at 06:24:24Z. It moved the phrase from line 20 to line 65. The substance still holds: `git show HEAD:<R80 DECISION.md>` has `OVERRIDE (OV-05)` at `:20`, and the working copy has it at `:65`, `:103` and `:718`. So the decision's prose claim at `DECISION.md:21` ("which R80 now claims") stays true. Only the script's binding fails. This is the same failure class as R80's own EA-1, where a check read another item's mutable working file.
     - Repair: bind the R80 check to a fixed revision, not to the working file. Use `git show HEAD:research/runs/R80/.../review/DECISION.md`, or R80's accepted sha256, and do not pin a working-tree line number. Alternatively, assert that the phrase is present anywhere in the file. Then rerun `engines-r4.sh`, commit its log, and restate the table row from the new log.

## Scope and method

- Target: `review/DECISION.md` revision 4. `shasum -a 256` gave `7a9345c6…a410` before the work and again after it. It matches the expected hash.
- Repository state: HEAD is `e0b0d1c1762ee8aa4b28c62282a2225103e594eb`. The revision-4 `DECISION.md`, `engines-r4.sh`/`.log` and `rerun-r4.sh`/`.log` are working-tree files: modified or untracked, not in HEAD. The five earlier scripts and their logs are byte-identical to HEAD.
- Host: macOS, aarch64. Host toolchain `rustc 1.98.1 (48a229cea 2026-09-01)`. MSRV toolchain 1.96.0 via rustup. Private `CARGO_HOME=/tmp/cargo-s36-R70-emp`.
- No write into `evidence/`: all 17 files in `evidence/` were hashed before the reruns and after them. The two hash lists are identical.
- Two scripts write beside themselves: `registry.sh` writes `registry-figures.log`, and `archive-check.sh` copies `registry-archive.log` and `probe-archive.log` into its own directory. Both therefore ran inside a throwaway clone of HEAD at `/private/tmp/r70-audit/clone`. The other five scripts ran in place, with stdout and stderr sent to `/tmp/r70-audit/`.

## Reruns (fresh log compared with `cmp` against the committed log)

| Script | Command | Observed | vs committed log |
|---|---|---|---|
| `engines-r4.sh` | `./engines-r4.sh > /tmp/r70-audit/engines-r4.log 2>&1` (in place) | **PASS 74 FAIL 1 SKIP 0, exit 1** | differs. Banner date, plus `88c88` (EA-1) and the summary line |
| `rerun-r4.sh` | `./rerun-r4.sh > /tmp/r70-audit/rerun-r4.log 2>&1` (in place; it clones HEAD itself) | **PASS 30 FAIL 0 SKIP 0, exit 0** | differs only in moving banner lines: date, `CARGO_HOME`, scratch path, and the nested archive-check date at `:78` |
| `rest-r2.sh` | `./rest-r2.sh > /tmp/r70-audit/rest-r2.log 2>&1` (in place, against the current `DECISION.md`) | **PASS 79 FAIL 0 SKIP 0, exit 0** | differs only at `2c2`, the banner date |
| `probe-r2.sh` | `./probe-r2.sh > /tmp/r70-audit/probe-r2.log 2>&1` (in place) | **PASS 25 FAIL 0 SKIP 0, exit 0** | differs only in banner lines 2, 4 and 6: date, host rustc 1.98.0 → 1.98.1, scratch suffix. Every verdict, body and catalog line is identical |
| `probe.sh` | `./probe.sh > /tmp/r70-audit/probe.log 2>&1` (in place) | **PASS 33 FAIL 0 SKIP 0, exit 0** | differs only in banner lines 2, 4, 5 and 8: date, host rustc/cargo 1.98.1, scratch suffix |
| `registry.sh` | `./registry.sh > /tmp/r70-audit/registry.log 2>&1` (in the HEAD clone) | **PASS 64 FAIL 1 SKIP 0, exit 1** | differs at `2c2` (date), `65c65` (`< PASS  IANA problem+json cites RFC9457` / `> FAIL  IANA problem+json does not cite RFC9457`) and `87c87` (summary), and nowhere else |
| `archive-check.sh` | `./archive-check.sh > /tmp/r70-audit/archive-check.log 2>&1` (in the HEAD clone, run from the symlink-resolved `/private/tmp` path) | **PASS 9 FAIL 2 SKIP 0, exit 1** | the two failures are `registry.sh FAILED from the extracted tree` and `registry.log differs from the archive rerun`. The embedded diff is exactly `62c62` (the IANA verdict) and `84c84` (the summary). The probe comparison still passes: `probe-archive.log` has PASS 33 and agrees on every verdict |

Setup note: my first `archive-check.sh` attempt reported `FAIL  the evidence directory is absent from HEAD`. That failure came from my harness, not from the script. I had invoked it through `/tmp`, which is a symlink to `/private/tmp`. `rerun-r4.sh` avoids the same trap with `pwd -P`. The rerun from the resolved path is the row above.

## Disclosed IANA drift: verified

The decision says `registry.sh` now drifts on 1 of 65 checks, and that `archive-check.sh` now reports 9 of 11. Both statements hold exactly. They hold in my direct runs and in `rerun-r4.sh`'s pinned assertions. I fetched the IANA registry directly with `curl https://www.iana.org/assignments/media-types/application.csv`. It returns `problem+json,application/problem+json,[RFC 9457]` and `problem+xml,application/problem+xml,[RFC 9457]`, with a space. `rerun-r4.sh`'s `RFC ?9457` match accepts both spellings, and its two IANA checks pass. The "space-tolerant" pin therefore holds. The committed `registry.sh` is unedited: it is byte-identical to HEAD.

## Figures re-derived at source

- `raw/opus.md` sha256 = `82538638b5f54017c22853eb9e52e6d4e6c71b78e35fad8ed6ea68be3fefe39e`, and the collected `raw/opus-82538638….md` is present. `raw/muse.md` sha256 = `989725675cb0f0c7d0dbb975435097d4d0f837e0ec32c137fc4cf64b3c4a7249`, 218 lines. `scripts/check-answer-shape.sh raw/muse.md bundle` prints `OK: validation passed`.
- `inputs/prompt.md` sha256 = `b47f8a26…`, which equals `manifest.input_hashes.prompt`. Line `:23` reads `- engines: muse, opus`. Line `:69` contains the quoted substitution sentence. Line `:62` carries the quoted gate-2 wording.
- `research/EXECUTION.json`: `engine_overrides.R70` and `items.R70.engines` are both `['muse', 'opus']`. In the manifest, `state` is `partial` and `operations.muse.state` is `submitting` with no `raw_sha256`, as the decision says. The Opus leg's `actual_model` is `claude-opus-5`.
- `execution-ledger.md:1114` carries the Q5.A "Muse-bulk all 17 remaining legs" ruling. `:1157` carries "R70 sha 98972567 (218 lines, bundle OK)".
- The Muse citations hold: `raw/muse.md` has "None of the envelope-crate candidates fails a fitness gate" at `:65`, "declares no rust-version" at `:73`, "no wildcard arm" at `:124`, "(R67 undecided; …)" at `:187`, and "Proposed, not executed" at `:37`.

## Scope note

The EF-2 EXTRA cycle fix is disclosed as possibly out of scope. Whether it is in scope is the judgment seat's decision. I judged only whether it executes: the related `engines-r4.sh` checks (`revision-1 bodies quoted`, `revision-2 bodies quoted`, and `stale 'The four bodies' lead-in is gone`) pass in the fresh run.
