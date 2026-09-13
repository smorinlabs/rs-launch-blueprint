decision-sha256: fd09fa1c682c049be39bfb841c0a57b1c6fff557ce5a16f0ba828dc4ceecabd1
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0-r7
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

`argv`: Extracted and executed the complete recorded `check15.sh` payload from
`review/evidence/binstall-backend.log`. The first byte-for-byte environment
replay reached the signed release binary but its mutable cargo-binstall cache
was denied by this audit sandbox. I then reran the unchanged script body with
only `CARGO_HOME` redirected to a fresh temporary directory; every `cargo
binstall` command, pin, target, flag, input, and the real `~/.cargo/bin`
no-write control remained as recorded. I separately asserted the output's
content, compared it with the recorded output after only the decision's
documented timing and host-state differences, compared the Supersedes payload
with the published copy, checked the five parameter declarations, and curled
five cited sources.

`cwd`: `research/runs/R42/2026-09-05T155503Z-4141a35b69e0`.

`toolchain`: macOS arm64, the published `cargo-binstall` 1.23.0 release binary,
Homebrew Cargo, Bash, Python 3, curl, shasum, and diff. No template, recipe,
tool-table, component, or permanent binary was written; every binstall call had
`--dry-run` and the real `~/.cargo/bin` listing was unchanged.

`exit code`: 0.

`log path`: `review/evidence/audit-dev-toolchain-provisioning-r7.log`.

`matches the decision`: Yes, substantively. The isolated-cache replay returned
0 for `taplo-cli`, `cargo-machete`, and `cargo-shear`; 76 for the not-found
control; and the expected content. Its only changed branch was
`cargo-machete`: the decision's rerun rule expressly declares its
already-installed shortcut host state, and the temporary `CARGO_HOME` correctly
made it resolve a prebuilt artifact instead. The normalized diff otherwise
matches the recorded output.

## Findings

None.

Check 15 directly supports all three revision-7 corrections. `--locked` is
documented as a pass-through to `cargo install` and the `taplo-cli@0.10.0`
fallback printed `cargo install ... --locked`; it does not constrain a prebuilt
download. `cargo-shear@1.13.1` resolved a prebuilt artifact, whereas
`taplo-cli@0.10.0` fell back to source on the same target. The backend needs a
`cargo-binstall` executable on `PATH`, so recording it as a declared tool-table
entry is necessary and the decision no longer characterizes the substitution as
literally one line.

The Supersedes payload hashes to
`ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f` and is
byte-identical to the published topic decision. Gate 1 remains named and is
operationally inapplicable under Q7.B: the decision records it as struck by the
owner ruling and evaluated for no candidate, while retaining licence figures.
All four `assumes` values are byte-identical to `inputs/PARAMETERS.md`. The
live owned-value cell is the repository's intentional unpublished `—`
placeholder; the decision's nonempty, pipe-free owned value is byte-identical to
the publication projection prescribed by `scripts/research_package.py`.

## Assessment

Approve. The revision is candid about the added bootstrap/tool-table entry, the
limited meaning of `--locked`, target-specific prebuilt availability, and the
unmeasured performance benefit. It does not claim the unbuilt template or an
end-to-end installation was proven. Five curl spot-checks confirmed the current
crate metadata, immutable source hash and locked-flag text, RustSec 404, the
reference toolchain components, and the Oxc generic acquisition reference.
