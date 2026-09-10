decision-sha256: 93157625c1b307d3e9d7c10b320accfc72c69422556c47cd94fdc4f9ed5c2182
actor: audit-codex-2026-09-05T155503Z-4141a35b69e0-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: the sweep says corrections 3–5 are scoped to the recorded machine, but the decision still says “any machine” and “wherever rustup is installed,” which the cited logs do not establish

## Rerun

`argv`: Created a fresh fixture containing the recorded `neg`, `pos`, `c196`,
and `c191` `rust-toolchain.toml` files, the two recorded Cargo aliases, and the
two external-subcommand stubs. On macOS, reran checks 1 and 3; all nine commands
of check 9 in each of `neg`, `pos`, and `c196`; check 10 in `pos`, `c196`,
`c191`, and `neg`; and checks 11 and the rustup-proxied bare-name negative case
from check 12. On Lima Ubuntu, after `source $HOME/.cargo/env`, repeated the
check-9 matrix and the check-11 precedence probes against Linux-target fixtures.
I also made five `curl` citation spot checks and compared `review/evidence`
between `HEAD^` and `HEAD`.

`cwd`: the isolated macOS fixture was under this run directory and was removed
after the rerun. The Linux fixture was under `/tmp` in the VM and was removed
by the VM command. No fixture or implementation file remains in the repository.

`toolchain`: macOS used the recorded restricted `PATH`
`$HOME/.cargo/bin:/usr/bin:/bin`, so Cargo was rustup's proxy rather than the
Homebrew Cargo. Linux used the same restricted shape after sourcing rustup's
environment. No component, crate, release tool, template, or P03 artifact was
installed or created.

`exit code`: the rerun command completed with exit 0. Expected negative checks
remained negative: absent components and their `rustup which` lookups exited 1;
missing aliases and built-in executables exited 1; an alias outside its directory
exited 101; and the alias-versus-external collision exited 1 after Cargo selected
the alias and printed its warning.

`log path`: `review/evidence/audit-dev-toolchain-provisioning-r3.log`.

`matches the decision`: The recorded component matrix, the custom-subcommand
dispatch, the two observed precedence relations, the explicit alias warning,
and the five citation reachability checks reproduced. The revision's claim that
the corrected proxy statements are now machine-scoped does not match its current
wording or the cited logs.

## Findings

### F1 — corrections 3–5 remain broader than their evidence

The revision-3 sweep says correction 3 changed the statement to be “scoped to
that machine,” and corrections 4 and 5 to the 13 observed macOS symlinks and
the six check-9 cells. However, `BASELINE-REVIEW: F181` still says that
`command -v` “cannot fail for a rustup component on any machine where rustup
itself is installed and `$CARGO_HOME/bin` is on `PATH`.” The owned parameter
likewise says “wherever rustup is installed” before claiming the test passes
whether the component is installed.

`review/evidence/presence-test.log` and
`review/evidence/invocation-sweep.log` record the 13 proxy symlinks and the
three macOS toolchain cells. The archived revision-2 audit and this audit add
the same three-cell result on one Linux VM. Those observations support the
class-specific recommendation and the local statement that `command -v` passed
for the tested names in the tested cells. They do not make the universal
“any machine” or “wherever” statements an output recorded by those logs.

The decision must either limit those sentences to the recorded host and cells,
as its sweep says it did, or add a separately cited Rustup specification and
label the universal rule as an inference from that specification. This is a
wording-only correction; it does not require P03 implementation.

The precedence correction is otherwise sound. The evidence establishes
`built-in > external` and `alias > external`, with Cargo warning for the latter.
It does not exercise `built-in` versus `alias`, and revision 3 now explicitly
declines to assert that ordering.

`git diff --quiet HEAD^ HEAD -- review/evidence` exited 0. Revision 3 did not
modify an existing evidence log; the new audit log is the sole audit artifact
created by this review.

## Assessment

Revision 3 correctly fixes the revision-2 defect: Cargo reports alias shadowing
explicitly, so it is not silent. Its narrower `command -v cargo-myver` claim,
the local check-9 observation, the two exercised precedence relations, and the
eight held statements agree with the cited records. The remaining universal
proxy wording contradicts the sweep's own stated scope and must be narrowed or
independently sourced before the decision can be approved.
