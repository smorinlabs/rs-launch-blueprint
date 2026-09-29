actor: audit-claude-r11r7vo2-2026-09-25
model: claude-opus-5-5
family: anthropic
decision-sha256: 410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c
verdict: approve
unresolved-findings: none

1. `shasum -a 256 review/DECISION.md` = 410e88e5195a08def126037e9c451988633b1e48437ac82edca0a08c7a62418c, equal to the expected sha; DECISION.md wording is unchanged.
2. `review/evidence/reproduction-r2.log` header lines 2-4 now read: record date (UTC) 2026-09-26T02:23:21Z, labelled as the write time and distinct from the 2026-09-23 extraction; extraction ran (UTC) 2026-09-23T13:00:09Z to 2026-09-23T13:00:14Z; extraction directory `$TMPDIR/r11-r7-archive.ss7yNL`.
3. `TZ=UTC stat` over the eleven extraction outputs gives a first mtime of 2026-09-23T13:00:09Z (`r11-r2-detector.archive.log`) and a last of 2026-09-23T13:00:14Z (four `*.r2-archive.log` files). That matches the header. The `*.archive.log` glob also matches six revision-1 `r11-*.archive.log` files dated 2026-09-18T23:04:38-39Z. Those files belong to revision 1's extraction, not this one, so they do not bear on the window.
4. `r11-r7-archive.ss7yNL` appears at reproduction-r2.log lines 65 and 74, both inside the `## r11-programme-inputs.sh` section (lines 60-75). Each is a `> INFO repository root: /var/folders/.../T/r11-r7-archive.ss7yNL` diff line.
5. DECISION.md:377 says "the exact time and every `diff` are in `review/evidence/reproduction-r2.log`". This now holds: the exact UTC window is in the header, and the log carries a `diff` for all eleven scripts. E1-residual is resolved.
