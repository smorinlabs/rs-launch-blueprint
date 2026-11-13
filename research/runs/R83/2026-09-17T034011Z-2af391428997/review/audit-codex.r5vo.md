actor: codex
model: gpt-6-astra
family: openai
decision-sha256: 90bc90e8254dea3be6046d95f0de6791b2005c3694d41a0ace01498d5ecbb209
verdict: approve
unresolved-findings: none
# R83 revision 5 — directed verification

The decision's SHA-256 matched the supplied value before any review file was read. Among audit and snapshot files, I read only the two named r4 audits and the r4 snapshot. I also read revision 5, the two named scripts, and their committed and fresh logs, and ran `diff -u` between the snapshot and revision 5. The checks below address only the four enumerated repairs.

## Per-fix result

1. **JF4-1-1 — confirmed.** `DECISION.md:137`–`:144` makes the valid boundary requirement a mapper property: a `Just` arm per declared boundary, asserted by `contract_mapper.rs`. It explicitly says the 16 random valid cases need not hit every boundary. The per-run guarantee applies to the enumerated boundary-invalid arms only. The Generation and Case count rows at `:242`–`:244` agree.
2. **JF4-1-2 — confirmed.** `DECISION.md:784`–`:785` reads: “(6) Query, header and cookie parameter generation, proved against R72's `cursor`/`limit` for the query location.”
3. **Codex-1 — disputed as specified above.** `DECISION.md:602`–`:612` limits byte identity to the original same-toolchain pair and records the r4 rerun at `PASS=24 FAIL=0 SKIP=0 TOTAL=24` with `cmp` exit 1. The fresh rerun also passed 24 checks; its committed-log diff consists solely of the `rustc` and `cargo` version lines, with `rustc` first. The decision quotes the full `rustc` lines but only the `cargo` version prefixes.
4. **Codex-2 — confirmed.** `DECISION.md:613`–`:623` limits “only difference” to the original pair, quotes the r4 audit's `retrieved:` values (`2026-09-27T07:41:52Z` and `2026-09-27T18:16:14Z`) and download counters (`oas3` `997209 / 2239368` to `1000779 / 2242938`; `openapi-fuzzer` `39 / 11730` to `40 / 11731`), and records 29 PASS. The fresh rerun's stable assertions and all 29 PASS lines match the committed log byte-for-byte. Its current differences have the same field shape: `retrieved: 2026-09-27T19:39:32Z`, `oas3` `1003425 / 2245584`, and `openapi-fuzzer` `40 / 11731`.

## Rerun record

Both commands ran from `review/evidence/`, with `TMPDIR=/tmp`, stdout and stderr redirected to the named `/tmp` log, and a 1,100-second wall alarm. Neither command reached its alarm.

| Command | Script exit | Fresh totals | Committed-log `cmp -s` exit | `diff -u` exit |
|---|---:|---|---:|---:|
| `TMPDIR=/tmp /usr/bin/perl -e 'alarm 1100; exec @ARGV or die $!' -- ./contract-fuzz-probe.sh > /tmp/r83-contract-fuzz-probe-r5vo.log 2>&1` | 0 | `PASS=24 FAIL=0 SKIP=0 TOTAL=24` | 1 | 1 |
| `TMPDIR=/tmp /usr/bin/perl -e 'alarm 1100; exec @ARGV or die $!' -- ./registry-and-standard.sh > /tmp/r83-registry-and-standard-r5vo.log 2>&1` | 0 | `PASS=29 FAIL=0 SKIP=0 TOTAL=29` | 1 | 1 |

The comparisons used `cmp -s /tmp/r83-contract-fuzz-probe-r5vo.log contract-fuzz-probe.log` and `cmp -s /tmp/r83-registry-and-standard-r5vo.log registry-and-standard.log`. Both mismatches were inspected with `diff -u` in committed-log-to-fresh-log order. The probe's PASS lines and totals match byte-for-byte; the registry's stable section, PASS lines, and totals match byte-for-byte. The registry script's own standard checks invoke read-only Git against the pinned standard clone; I issued no separate Git command.

## S1 adjudication (2026-09-28, Q23)

- Original file verdict: disputed. S1 disposition: repair ACCEPTED; file verdict set to approve, unresolved-findings set to none. The raised dispute is preserved verbatim below; it is resolved, not open.
- Rationale: the enumerated repair (S56 brief job 1, codex-1) required scoping the byte-identity sentence to the original pair and recording the 1.98.1 rerun. Both are present (DECISION :606-616: full rustc lines quoted, cargo versions recorded, 24/24 totals match, cmp shape confirmed by the verifier's own rerun). Verbatim full-line cargo quotation was never enumerated; the r4 audit's own evidence wording abbreviates identically, and the cargo build-hash is identical on both lines, so nothing material is lost. Directed-verifier overreach per Q13.A (confirm enumerated repairs only). Full-line quotation kept as an observation for next touch.
- Raised dispute, verbatim:

```text
Codex-1 — `DECISION.md:611` abbreviates both `cargo` version lines, so the required verbatim rustc/cargo version-line quotation is incomplete. The committed line is `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; the fresh line is `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`. Quote both complete lines in the decision.
```
