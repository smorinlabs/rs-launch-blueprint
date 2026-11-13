actor: audit-claude-2026-09-17T020714Z-8fdb5c2010e7
model: claude-opus-5-5
family: anthropic
decision-sha256: 44e945045f0e2c964520918801f5c8f3921a3cfefc4ef5c72b0bc497038139ba
verdict: approve
unresolved-findings: none

# R57 xdg-directory-set — empirical audit (Claude seat), decision revision 2

**Seat disclosure.** This audit runs on the Claude seat as the approved fallback
while the OpenAI provider is quota-paused (method amendment Q8.B). It is not a
Codex audit. The auditor is independent of the synthesizer and the judgment
auditor. It did not read `review/audit-fable*.md` or `research/topics/57-*/raw/`.

**Scope.** This audit judges execution truth and evidence support only: whether
the commands run, whether the logs match the claims, and whether the figures are
right. It does not judge whether the recommendation is wise.

## Target identity

```
$ shasum -a 256 research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md
44e945045f0e2c964520918801f5c8f3921a3cfefc4ef5c72b0bc497038139ba  .../review/DECISION.md
```

The hash equals the expected revision-2 hash. `git archive HEAD` of the `review/`
directory is identical to the worktree copy, except for the two gitignored
`.crate` tarballs (`diff -r` output, with no other differences).

## Environment

- Audit host: `Darwin arm64`, `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`,
  `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`, `ShellCheck 0.11.0`.
- The decision and the committed `evidence/toolchain.txt` record `rustc 1.98.0`.
  The patch-level difference matters only for the §8 spike rebuild below.
- All reruns ran in `/tmp/r57audit/x`, a `git archive HEAD` extraction, so the
  script's own writes (`toolchain.txt`, `snap/`) never touched the repository.
  After the audit, `git status --short research/runs/R57` showed only this file.

## Reruns (command → observed output)

### R1 — `r57-claims.sh` from a clean extraction without the tarballs

```
$ bash /tmp/r57audit/x/research/runs/R57/.../review/evidence/r57-claims.sh > /tmp/r57audit/run1.txt 2>&1; echo "exit=$?"
exit=0
$ diff /tmp/r57audit/run1.txt <worktree>/review/evidence/r57-claims.log && echo RUN1-IDENTICAL
RUN1-IDENTICAL
$ /usr/bin/grep -c '^PASS' run1.txt ; ... '^FAIL' ; ... '^SKIP'
53
0
0
$ tail -1 run1.txt
failed assertions: 0
$ shasum -a 256 <worktree>/review/evidence/r57-claims.log
fbbe9fae82267a67d220b71536095e82edc38776ed845bc4017b478252332143
```

The script re-downloaded both tarballs. Their sha256 values equal the constants
the decision states:

- `etcetera-0.11.0.crate`: `de48cc4d1c1d97a20fd819def54b890cadde72ed3ad0c614822a0a433361be96`
- `directories-6.0.0.crate`: `16f5094c54661b38d03bd7e50df373292118db60b585c08a411c6d840017fe7d`

The PASS count per section, summed with `awk` over `run1.txt`, matches every
per-section count the decision states: §1 = 7, §2 = 9, §3 = 3, §4 = 18,
§5 = 6, §7 = 4, §8 = 6. Total = 53. §6 prints figures and asserts nothing.

**Result:** the decision's claims hold: 53/0/0, exit 0, byte-for-byte
reproducible, archive-without-tarballs identical, and the log sha256 is correct.

### R2 — §8 spike re-executed live (the spike snapshot deleted in `/tmp` only)

The script's contract says deleting the snapshot forces re-execution. The run
was made twice: once in the default sandbox, and once with the sandbox disabled.
Both runs produced the same result.

```
$ rm /tmp/r57audit/x/.../snap/spike-macos-arm64.txt
$ bash .../r57-claims.sh > /tmp/r57audit/run3.txt 2>&1; echo "exit=$?"
exit=1
$ diff run3.txt <worktree>/r57-claims.log
409c409,413
< ERR = could not locate home directory
---
> config = <passwd-home>/.config/
> data   = <passwd-home>/.local/share/
> state  = Some("<passwd-home>/.local/state/")
> cache  = <passwd-home>/.cache/
> runtime= None
415,417c419,421
< FAIL no XDG_RUNTIME_DIR fallback is invented (expected 5, got 4; binary: /usr/bin/grep)
< FAIL removing HOME does NOT produce HomeDirError on this platform (expected 0, got 1; binary: /usr/bin/grep)
< FAIL with HOME removed the passwd entry supplies the home directory (expected 1, got 0; binary: /usr/bin/grep)
```

Cases 1–4 of the live spike are **identical** to the committed snapshot:

- The macOS state directory resolves to `/fixed/fake/.local/state/`.
- An absolute `XDG_STATE_HOME` is honoured.
- Empty and relative `XDG_STATE_HOME` values fall back to the default.
- No runtime directory is invented.

These results were rebuilt from the sha256-pinned source under a different
toolchain patch release (1.98.1). They independently confirm the macOS findings
that the crate choice rests on.

Only case 5 (`env -i`, so no `HOME`) diverges. **Diagnosis:** this host's
directory service cannot resolve uid 501. That fault is independent of the
decision:

```
$ env -i /usr/bin/python3 -c 'import pwd,os;print(pwd.getpwuid(os.getuid()).pw_dir)'
KeyError: 'getpwuid(): uid not found: 501'      (sandboxed and unsandboxed, with and without env -i)
$ dscl . -read /Users/stevemorin NFSHomeDirectory UniqueID
Operation failed with error: eServerError
$ env -i /usr/bin/id -un
501                                              (numeric; no user name resolved)
$ dscacheutil -q user -a uid 501; python3 -c 'import pwd;print(pwd.getpwuid(501).pw_dir)'
(no dscacheutil record)  KeyError: 'getpwuid(): uid not found: 501'   (one retry; still failing)
```

**Disposition: observation, not a finding.** The live rerun produced the
alternate branch that the decision itself predicts. The B6 correction
(`DECISION.md` lines 327–335) states that the `Err` arm "is reachable where
neither `HOME` nor a `passwd` entry resolves". This host was in exactly that
state, and the crate returned `HomeDirError` (`ERR = could not locate home
directory`).

The decision's reproducibility claim is also scoped to the snapshotted run. It
says outputs are "snapshotted once … and read from the snapshot afterwards". So
the claim is not refuted.

The divergence also supports the decision's advice to P03. An end-to-end B6 test
that works by unsetting `HOME` is environment-dependent. P03 should construct
the failure state deliberately. This rerun also confirmed empirically that the
script exits non-zero when any assertion fails, as the decision claims.

**Wording note (does not block approval).** Two phrases are stated
unconditionally: "removing `HOME` produces no `HomeDirError` at all" (lines
742–744) and "returns no error at all" (lines 331–332). They are true only when
the `passwd` lookup succeeds. The paragraph around them already says so. A
future revision could add "when the `passwd` entry resolves" to both phrases.
The same clause could also be added to the §8 assertion label in the script.

### R3 — `r57-claims-r2.sh`, in the worktree and in the extraction

```
$ bash <worktree>/.../r57-claims-r2.sh > /tmp/r57audit/r2-worktree.txt 2>&1; echo "wt exit=$?"
wt exit=0
$ diff /tmp/r57audit/r2-worktree.txt <worktree>/.../r57-claims-r2.log && echo R2-WORKTREE-IDENTICAL
R2-WORKTREE-IDENTICAL
$ bash /tmp/r57audit/x/.../r57-claims-r2.sh > /tmp/r57audit/r2-archive.txt 2>&1; echo "arch exit=$?"
arch exit=0
$ diff /tmp/r57audit/r2-archive.txt <worktree>/.../r57-claims-r2.log && echo R2-ARCHIVE-IDENTICAL
R2-ARCHIVE-IDENTICAL
$ /usr/bin/grep -c '^PASS|^FAIL|^SKIP' (each separately) r57-claims-r2.log
13 / 0 / 0
```

This matches the decision's statement "13 passing assertions, 0 failing,
0 skipped" (lines 875–876).

### R4 — shellcheck

```
$ shellcheck --version   → version: 0.11.0
$ shellcheck <worktree>/.../r57-claims.sh;    echo "sc1=$?"   → sc1=0 (no output)
$ shellcheck <worktree>/.../r57-claims-r2.sh; echo "sc2=$?"   → sc2=0 (no output)
```

`r57-claims.sh` disables `SC2016` file-wide, with a stated reason: literal
`$XDG_*` search strings must not expand. The decision's "shellcheck-clean" claim
holds under that directive.

## Figures re-derived at source

| Claim in DECISION.md | Re-derivation | Result |
|---|---|---|
| `snap/` holds 11 files; 9 tracked in `HEAD`; 2 untracked | `ls -1 .../snap \| wc -l` → `11`; `git ls-files .../snap \| wc -l` → `9`; the untracked 2 are the `.crate` files (`diff -r` against the extraction) | holds |
| `.gitignore:12` is `research/runs/**/*.crate` | `sed -n 12p .gitignore` → `research/runs/**/*.crate` | holds |
| R67 decision hash `16947ab1…` equals the hash in `inputs/prerequisites.json` | `shasum -a 256` → `16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`; the same string is present in `prerequisites.json` | holds; prerequisite not stale |
| R67 `:33` defers the crash-record location to R57 | `sed -n 33p` → `\| Crash record \| \`std::fs\` behind an injected sink; **location deferred to R57** \| CLI binary only \|` | holds |
| `RSLB101` occurs once in R67, on line 383 | `/usr/bin/grep -c` → `1`; `/usr/bin/grep -n` → line `383` | holds |
| Standard at blob `f9de0437…`: version 1.4.14, R5.3 is MUST, provenance row 10 is `org-locked` | `git -C ~/c/cli-standards cat-file -p f9de0437…` → line 7 `\| **Version** \| 1.4.14 \|`, line 307 `**R5.3 — Filesystem locations (XDG). (MUST)**`, line 72 `\| 10 \| Filesystem paths \| … \| org-locked \|` | holds |
| crates.io figures, retrieved 2026-09-16: 32,829,812 recent downloads / 108,370,911 total downloads / max stable version 0.11.0 | committed `snap/etcetera-crate.json` → `0.11.0 108370911 32829812`. Live query, 2026-09-25 → `0.11.0 112547836 34718002` | the snapshot matches the decision exactly; the live counters grew as expected, and the max stable version is unchanged |
| RustSec status codes: `etcetera` → 404, `directories` → 200, `anyhow` → 200 (the control) | live `curl -w '%{http_code}'` on 2026-09-25 → `404`, `200`, `200` | holds |
| The §8 spike findings for cases 1–4 | rebuilt live from the pinned source (R2 above) | holds |

## Conclusion

Every command the decision cites runs as stated, and both logs reproduce
byte-for-byte. The stated counts are correct: 53/0/0 for `r57-claims.sh` and
13/0/0 for `r57-claims-r2.sh`. Both scripts are shellcheck-clean. The
load-bearing figures re-derive at source.

The one divergence occurs only on live re-execution of §8 case 5. It traces to
a directory-services fault on the audit host, and it falls on the error branch
the decision itself predicts. It is recorded above as an observation with a
wording suggestion, not as an unresolved finding.

verdict — approve (closing restatement; the header line above is the record).
