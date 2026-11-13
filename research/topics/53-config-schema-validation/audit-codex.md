actor: audit-codex-2026-09-17T020714Z-d0b567b4b9f1
model: gpt-5.6-terra
family: openai
decision-sha256: be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9
verdict: approve
unresolved-findings: none

# Empirical audit

I audited execution truth and evidence support only. I did not assess the
recommendation. The decision hash was computed before reading it and again
after the reruns; both computations produced the header value above.

## Current-revision reruns

All commands below started in
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Scratch logs and Cargo
state were kept under `/tmp`; no evidence log in the repository was replaced.

1. Command:

   ```bash
   shellcheck research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/verify.sh
   ```

   Observed output: exit 0; no findings.

2. Command:

   ```bash
   TMPDIR=/tmp/r53-codex-audit-tmp CARGO_HOME=/tmp/r53-codex-audit-cargo \
     research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/verify.sh \
     > /tmp/r53-codex-audit-verify.log 2>&1
   ```

   Observed output: exit 0; `checks run: 117`, `failures: 0`, `skips: 0`.
   The compiled probe resolved `serde v1.0.229`, `toml v1.1.6+spec-1.1.0`,
   and `garde v0.23.0` in a 39-line normal dependency tree. Its decisive
   output reproduced:

   ```text
   P1_SERDE_DERIVE_ERROR_COUNT = 1
   P1_SERDE_DERIVE_MSG = unknown variant `rainbow`, expected one of `auto`, `always`, `never`
   P1_SERDE_DERIVE_DISPLAY_FIRSTLINE = TOML parse error at line 4, column 9
   P2_GARDE_REACHED = false
   P2_GARDE_REPORT_ENTRIES = 0
   P2_SERDE_FAILED_FIRST_MSG = unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
   P3_GARDE_CONSTRAINT_ENTRIES = 2
   P3_GARDE_ENTRY = limit: lower than 1
   P3_GARDE_ENTRY = workspace: length is lower than 1
   P4_TABLE_KEY_ORDER = ["color", "format", "limit"]
   P4_PERKEY_ISSUE_COUNT = 3
   P4_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
   P4_ISSUE = output.color: unknown variant `rainbow`, expected one of `auto`, `always`, `never`
   P4_ISSUE = output.limit: invalid type: string "abc", expected a nonzero u32
   P4_PARTIAL_VALUE = ConfigFile { output: OutputSettings { format: Table, color: Auto, limit: None } }
   P5_NONZERO_ISSUE = output.limit: invalid value: integer `0`, expected a nonzero u32
   P5_ENUM_ISSUE = output.format: unknown variant `yaml`, expected one of `table`, `json`, `markdown`, `name`
   P6_SYNTAX_AS_TABLE_OK = false
   P6_BADVALUES_AS_TABLE_OK = true
   P6_BADVALUES_AS_STRUCT_OK = false
   ```

3. Command:

   ```bash
   shellcheck research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/r53-r2-gate-posture.sh
   ```

   Observed output: exit 0; no findings.

4. Command:

   ```bash
   TMPDIR=/tmp/r53-codex-audit-tmp CARGO_HOME=/tmp/r53-codex-audit-cargo \
     research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/r53-r2-gate-posture.sh \
     > /tmp/r53-codex-audit-gate-posture.log 2>&1
   ```

   Observed output: exit 0; `checks run: 37`, `failures: 0`, `skips: 0`.
   The source census reproduced `serde=2`, `serde_core=2`,
   `serde_derive=0`, `garde=7`, `garde_derive=2`, `validator=0`,
   `serde_valid=0`, `nutype=3`, and `validify=0` matching `unsafe` lines.
   It also reproduced zero async-runtime/reactor dependencies across all six
   candidates and the asserted `toml::Table`, `garde::Report`, and
   `validator::ValidationErrors` container shapes.

## Reproduction comparison

The current rerun is the evidence for this verdict. The committed logs were
used only as the requested reproduction target. A byte comparison of the
filtered stable output succeeded with exit 0 for both scripts:

```bash
diff -u /tmp/r53-codex-audit-verify-committed-stable.txt \
        /tmp/r53-codex-audit-verify-rerun-stable.txt
diff -u /tmp/r53-codex-audit-gate-committed-stable.txt \
        /tmp/r53-codex-audit-gate-rerun-stable.txt
```

The first comparison included every `PASS`, `FAIL`, and `SKIP` line plus every
`P1_` through `P6_` probe line. The second included every `PASS`, `FAIL`, and
`SKIP` line. Full-log changes were confined to retrieval dates, live registry
and GitHub figures, temporary paths, the unasserted current `nutype` release
line, and the unlocked probe's indirect `unicode-ident` version. They did not
change a direct candidate pin, an assertion, a check count, or probe behavior.
The committed revision-2 pair itself still has the stated two PID-bearing
changed pairs and no changed evidence line.

## Independent source re-derivations

- A fresh crates.io version query for `serde 1.0.229` returned
  `num=1.0.229 rust_version=1.56 default=std derive=true`, supporting the
  version, MSRV declaration, and feature claims.
- I downloaded the published `toml 1.1.6+spec-1.1.0` crate into `/tmp` and
  read `src/table.rs:14` and `src/map.rs:36-37`: `Table` is
  `Map<String, Value>` and the no-`preserve_order` configuration selects
  `BTreeMap`.
- I separately downloaded published `garde 0.23.0` into `/tmp`. Its source
  yielded seven `unsafe` matching lines: two in `i18n.rs`, one in
  `error/rc_list/mod.rs`, and four in `rules/pattern.rs`. The latter module is
  gated by `target_arch = "wasm32"` and `target_os = "unknown"`, matching the
  decision's source-backed gate-3 account.

The empirical commands run, their claims and figures are supported by their
current outputs, and the decision accurately limits the checks it does not
claim to prove.
