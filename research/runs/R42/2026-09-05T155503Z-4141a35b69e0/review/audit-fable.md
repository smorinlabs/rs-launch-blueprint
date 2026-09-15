decision-sha256: 3620897e85a288ea76b071bc5383694802420920dcf8cf335866bbc60a69f045
actor: audit-fable-2026-09-05T155503Z-4141a35b69e0-r9
model: claude-opus-5
family: anthropic
verdict: reject
unresolved-findings: J1 — the owner-facing option 2 says `--only-signed` makes a tool "silently compile from source" and cites step 7b, whose recorded output announces the fall-through with an `ERROR` line and a `WARN` line, which is the same "silently" overstatement the decision's own sweep row 1 struck for the alias case, sitting this time in the block the owner is being asked to decide; J2 — "its asset 404s for both specs" is supported for `taplo-cli` only, since for `cargo-shear` no log records the QuickInstall asset's status and the 404 that is recorded is on the `.sig` under `--only-signed`, which is not an asset 404

## Principle and agreement level

The shared principle is stated at the level the spec's §2 table calls
**architectural pattern plus policy** — a discover-report-remediate loop plus a
stable invocation vocabulary — and the decision says so explicitly, separating
what must agree (one presence command, one remediation string per tool, one
invocation form per tool class, exactly one authoritative tool list) from what
may vary (the acquisition backend, the tool count, the tool identities). That
separation is the load-bearing move of the item: it is what lets py's per-tool
installer layer die in Rust without the principle dying with it, and the reason
given is structural rather than stylistic — py's four tools sat outside `uv`'s
reach because `uv` installs Python distributions, while the Rust equivalents are
themselves crates and rustup reaches `rustfmt` and `clippy` by definition.
Nothing in revision 9 touches any of this, and the rev6→rev9 diff confirms it:
22 hunks, none in the principle, the agreement level, the essential behaviors or
the acceptance criteria.

The two `BASELINE-REVIEW:` lines (F181, F179) are byte-identical to the
published revision 6, carry the runbook's four fields — row, prescription,
evidence, `Affected:` — and answer what `docs/port/BASELINE-REVIEW.md` actually
asked R42: F181's row is marked `blocked pending R42` and asks whether a
`command -v` loop is the right test at all (`:86`), which the line answers by
splitting the test on acquisition channel; F179's finding line asks that `make`
be justified as a chosen mechanism rather than asserted as the only
dependency-free entry point (`:276`, `:462`), which the line does, with the
0-of-17 root-`Makefile` measurement as the cost. No `CONFLICT:` line is owed:
the consumes list is empty and no registered parameter value changes.

## Design and evidence

**The architecture comparison is genuine and survives the licence ruling.** Five
architectures are compared before any tool is named, and the two rejections that
matter are argued on grounds independent of gate 1. The hermetic option is
rejected because it imposes a Nix installation on every downstream consumer of a
*template* and puts an environment prefix on every recipe and hook line —
breaking essential behavior (3) — with its GPL-2.0 declaration explicitly
demoted to a figure. The provisioner option is rejected on a re-measured 0/17
against 5/17 for `flake.nix`, and the decision then does the harder thing:
it concedes that any declarative-provisioner argument in the Rust field has to
be made against `flake.nix` rather than `mise.toml`, and quotes doxa/openai's
own concession against openai's own proposal. Disagreement 6 is the model of how
this should be done — it splits one question the engines asked as one, adopts
openai's provisioner-independent half (`rustup component state`) and rejects
gemini's half because gemini's stated rationale is entirely provisioner-
dependent. I verified the three cited raw-report lines land
(`raw/doxa-openai.normalized.md:201` and `:348`, `raw/doxa-gemini.normalized.md:48`)
and that the `## Engines` one-liners match the reports
(`raw/codex.md:13`, `:112-114`, `:234-235`; `raw/opus.md:155`, `:500`).

**Revision 9's assertions assert content, not exit codes.** I read the three
payloads rather than the prose. The first leg's helpers are
`expect_eq <name> <expected> <actual>` and `expect_has <name> <fixed-string> <file>`;
`set -e` is deliberately absent and no assertion is evaluated inside `$(…)`.
Every claim the decision rests on is one of those:

| Decision claim | Assertion in the script | Demonstrated failing |
|---|---|---|
| five source files read at tag `v1.23.0` | `sha256-<file>` against the recorded digest, plus `http-<file> = 0 200` | `leg1/sha` (`main.rs` in the `args.rs` slot) |
| `signing: ABSENT` / `PRESENT` per spec | `signing-verdict-<spec>` against the expected verdict, computed from the unpacked published `Cargo.toml` | `leg1/signing` (a crate that does declare a key) |
| 7a printed **zero** `Verified signature` lines | `7a-verified-signature-count = 0` from `grep -c` over the captured output | `leg1/p7a` (got 1) |
| 7c printed **exactly one** | `7c-verified-signature-count = 1` plus `7c-verified-package-name` on the stable substring | `leg1/p7c` (got 0) |
| the `--only-signed` fall-through occurred | `7b-falls-through-to-cargo-install` on the literal `cargo install cargo-shear --version 1.13.1 --locked`, plus `7b-status = 0` | `leg1/p7b` (string missing) |
| the negative control failed | `7d-status = 76` plus `7d-crate-not-found` | `leg1/p7d` (got 0) |
| nothing was installed | `cargo-bin-listing-unchanged`, the before and after hashes compared | `leg1/cargohome` |
| exactly three `DataVerifier` impls, one `Sha256Digest` site | `dv-file-count`, `dv-site-count`, `dv-file-set` (the full sorted path set), `sha256digest-construction-sites = 1` | `leg2/dvcount`, `leg2/dupsite` |
| the digest sweep found nothing | `digest-sweep-status = 1` **and** `digest-sweep-hit-count = 0` — status 1 specifically, because 2 means error | `leg2/sweep` |

Each leg asserts its own assertion count (45, 23), so a skipped assertion fails
the run; the round-9 empirical audit demonstrated that meta-assertion firing.
The answer to the question I was asked to press is therefore **yes** — these are
content assertions, and the counts, the fall-through text and the negative
control's status are all among them. I confirmed the thirteen demonstrations in
`evidence/binstall-assertion-controls.log:233-302`, each requiring both a
non-zero exit and that control's own named `ASSERT-FAIL` line, with a
rate-limited run reported `VOID` rather than counted. I spot-checked thirteen
log citations in the decision's four check-16 bullets and gate 3
(`binstall-signing.log:263-269`, `:288-293`, `:323`, `:338`, `:368-373`,
`:387-389`, `:404`, `:410`, `:416`, `:442`, `:446-453`, `:461`, `:468`); all
land on the text they are cited for.

**The one conclusion that moved is reported honestly.** Revision 8's tree
control hashed one file and did not separate v1.22.0 from v1.23.0. Revision 9
neither hides that nor explains it away: the third leg asserts that all eight
files are byte-identical at those two tags (8 of 8, `:228-231`), the second leg
now hashes all eight, and the perturbation becomes v1.21.0. The decision states
both consequences — that the control authenticates content rather than a release
number, and that one file was the weaker control — and adds unproven item 11(d),
which concedes that each control is shown failing under *one* substituted input
and that a control can be sound against the substitution tried and blind to
another. That is the right generalisation to decline.

**Check 15's own overstatement was swept and corrected, unprompted.** Location
(12) of the revision's edit list found that the check-15 row and the revision-7
history both credited that check's negative control with making the check "able
to fail", when its script prints `pipestatus=` without testing it — the same
defect the audit found in check 16. Both sentences now say the status was
printed rather than asserted, and point at check 16's repaired `7d-status`
assertion against the same binary and version. The script and log are left
byte-identical rather than rewritten, with the reason stated. This is the
programme's rule applied to evidence the audit did not challenge, which is the
behaviour the rule is for.

**Scoping.** The recommendation is scoped to what was observed. Gate 4 records
`verified on macOS/arm64 only`; the check-16 host paragraph names Darwin 25.4.0
arm64 and the single session; every runtime observation names its spec and
version (`cargo-shear@1.13.1`, `taplo-cli@0.10.0`, `cargo-binstall@1.23.0`); the
speed benefit is stated as a bound with `How large the saving is was not
measured` and unproven item 5 asking for the measurement; unproven item 11(a)
says two out of two probed is "a sample, not a rate" for signing coverage; and
unproven item 1 enumerates exactly which checks have a Linux leg and which two
(10 and 12) do not. A reader does learn that some tools compile from source:
layer 2's row says the backend "otherwise runs `cargo install --locked` itself",
the third `--locked` bullet records `taplo-cli@0.10.0` falling through with the
`will be installed from source (with cargo)` warning, and gate 6 prices it as
"one source compile per tool wherever it does not". What that reader is told
*about the manner* of the fall-through is J1 below.

**Does the recommendation still follow, now that the licence ground is gone?
Yes.** The affirmative case does not depend on gate 1 and never did: the
generic-recipe shape rests on the two maintained reference implementations that
provision tools at all (`oxc`'s `init`, `biome`'s `install-tools`), the backend
itself is what both of those use, the fast path was exercised rather than
assumed (`cargo-shear@1.13.1` resolved a prebuilt artifact), and revision 6 had
already written that this exact substitution would follow if gate 1 fell. The
decision does not overclaim the benefit — it is qualitative, untimed, and booked
as an upper bound each tool either earns or does not, with the worst case stated
as revision 6's recommendation exactly. Crucially, the decision refuses the
symmetric temptation: having lost the licence ground for the slower backend, it
declines to substitute an integrity ground for it on its own initiative, and
says so in terms.

**Is the integrity choice presented as the owner's? Yes, structurally.** It is
not absorbed. The paragraph opens by naming itself as the ask; the five-row
comparison table sets revision 6's backend against the authorised one on
origin, verification, what `--locked` binds, what executes, and scope; three
options are given with their costs; the close is `choose 1, 2 or 3, or direct
otherwise`; a re-verify event fires on the ruling either way; and unproven item
11 records what was not established. The table's left column is the test of good
faith and it passes — it does **not** claim Cargo verifies anything, it says
`not established in this decision for Cargo itself` and points at 11(b), which
explains that the compile fallback hands the install to a different program this
decision did not read. An owner reading that block gets a true picture of the
tradeoff, with one word wrong (J1).

## Completeness

- Four required H2s present and in order, with `## Supersedes` last and
  `re-verify:` still the final line of `## Decision`. The extra H2 is permitted
  for exactly this case and the decision names the permission.
- `## Supersedes` payload: I extracted lines 1674-end and diffed them against
  `research/topics/42-dev-toolchain-provisioning/DECISION.md`. **Byte-identical**,
  both hashing to `ca5a731081e51ab5d0eea91dd9f4ef8a456855df026354ed1f8146bea77f6d7f`,
  which is the value the framing paragraph claims.
- Parameters: the owned line and all four `- assumes` lines are byte-identical
  both to revision 6 and to the registered values in `docs/port/PARAMETERS.md`
  (`:7-10`, `:14`), compared programmatically rather than by eye. The format note
  explaining why they carry no backticks is still correct.
- Acceptance criteria (A)-(E): byte-identical to revision 6 (20 lines, no diff).
- Fitness gates: all six present, answered and grammatical, each with the
  `Gate N (…)` parenthetical. Gate 1 `inapplicable`, **struck by the owner
  ruling of 2026-09-12 and named as such — correct, and not a finding**. Gate 5
  `inapplicable` (restored at revision 8, still present). Gate 3 is scoped to
  the probed candidates and now splits `--locked` across the two paths.
- Source dates: every figure row carries a retrieval date; the two cells that
  once lacked a query now name check 14; the UTC convention is stated and the
  local-midnight crossing explained rather than left as an apparent future date.
- The decision does not implement its own recommendation and correctly declines
  to. "Nothing recommended was implemented" is stated and the one addition —
  that check 15 and check 16 execute a third-party binary — is disclosed rather
  than buried, with `--dry-run` on every call and the `~/.cargo/bin` listing
  hashed before and after, now asserted equal.
- Consistency with `review/audit-codex.md` (round 9, `gpt-5.6-terra`, approve,
  no findings): consistent. It binds the same sha256, reproduces the three-leg
  replay (45/45, 23/23, 37/37 with 13/13 controls), independently probes the
  meta-assertion and a synthetic HTTP-429 `VOID` path, re-diffs the `Supersedes`
  payload to the same hash, and records that the integrity comparison "remains an
  unanswered owner ask". Its scope is the replay; neither of my findings is
  reachable from it, because both are prose claims that no assertion covers.

## Findings

**J1 (blocking, owner-facing).** `## Decision`, option 2 of the integrity ask:
"the prebuilt path is taken only when the artifact is signed and verifies;
otherwise the tool **silently** compiles from source — observed at check 16,
step 7b." Step 7b's recorded output is not silent. It carries
`cargo-binstall: ERROR Failed to download signature: … 404 Not Found` and
`cargo-binstall:  WARN The package cargo-shear v1.13.1 will be installed from
source (with cargo)` before the `Dry-run: running … cargo install` line
(`evidence/binstall-signing.log:446-453`) — output the decision itself quotes
four paragraphs earlier. This is the identical defect this decision's own
eighteen-row sweep recorded as row 1 and marked **Wrong**: "an alias *silently*
shadows a same-named external subcommand … Cargo warns." The same standard
applies to the same word describing the same kind of announced degradation, and
it applies harder here, because row 1's sentence was an argument inside
`## Parameters` while this one is a consequence inside the three options the
owner is being asked to choose between. The decision already has the accurate
formulation and uses it elsewhere: "the flag degrades a tool to revision 6's
backend rather than failing the recipe." Repair: state option 2's cost as the
observed behaviour — the run does not fail, it announces the degradation at
`ERROR`/`WARN` level and compiles from source — or drop the adverb. Nothing else
in the option changes, and the option's substance (the speed benefit is lost for
every tool that does not publish a key, which is both tools probed) is correct
and asserted.

**J2 (blocking, narrow).** `## Decision`, the QuickInstall bullet: "It resolved
nothing in either check: **its asset 404s for both specs**, and the `WARN` line
that did print names `github.com` with no `third-party source ` prefix." The
first half is supported for one spec and unrecorded for the other.
For `taplo-cli@0.10.0`, check 15 records the QuickInstall *tarball* 404 twice,
for both Apple targets (`evidence/binstall-backend.log:166-167`). For
`cargo-shear@1.13.1` there is no such line anywhere: check 15's `cargo-shear`
run resolves from `github.com` with no QuickInstall output at all
(`binstall-backend.log:176-182`), check 16's 7a likewise
(`binstall-signing.log:434-440`), and the only QuickInstall 404 recorded for
that spec is on `…-aarch64-apple-darwin.tar.gz.sig` under `--only-signed`
(`:450`). A signature 404 is not an asset 404 — `download_signature` is spawned
as its own task (`quickinstall.rs:110-136`, quoted in the same log at `:346-373`),
so reaching it does not establish what happened to the tarball, in either
direction. What the decision should say is that QuickInstall's asset 404s for
`taplo-cli` and that its asset status for `cargo-shear` is unrecorded, which
costs the bullet nothing: its conclusion is carried by the second half, and that
half *is* asserted — `7a-downloaded-from-github` requires the literal
`has been downloaded from github.com`, which a QuickInstall win could not
produce, because `resolution.rs:125-127` prefixes a third-party fetcher's name
with `third-party source `. Repair: one clause.

**Neither finding moves anything else.** The recommendation and all five layers,
the owned parameter, the four `- assumes` lines, acceptance criteria (A)-(E),
the six gates, the architecture comparison, the survey, the three options'
substance, the `## Supersedes` payload and every assertion in the three payloads
all stand as written. Revision 10 is two clauses in `## Decision`, with no
check rerun and no evidence log touched.

**Checked and left, so they are not re-litigated.** (1) Gate 1 recorded as
`inapplicable` with the 2026-09-12 ruling named — correct under the settled
ruling, and the decision is right that the declared licences become figures
rather than tests. (2) 7c resolved an `x86_64-apple-darwin` artifact on an arm64
host; the decision never claims otherwise and the verification claim is
unaffected. (3) The integrity table says "no checksum anywhere under
`binstalk-fetchers`" where the sweep covers `binstalk-fetchers/src`; that is
where the crate's code is. (4) The sweep pattern includes `sha-256`, which the
prose does not name — a wider search than claimed, which is the safe direction.
(5) The rerun rules each log states for "any other host" are reproduction
criteria, not assertions about untested hosts, and are labelled as such.
(6) The decision declines to assert that the fast path generalises, that Linux
behaves the same, or that anything after download is verified; each is an
unproven item with a named proof.

## Assessment

**Reject**, on two clauses and nothing more. Revision 9 does what the round-8
rejection asked and does it properly: the controls are real assertions over
content — digests, counts, verdicts, literal fall-through text, an exit status
of 76 — each leg guards its own assertion count, and thirteen controls are shown
failing under a single substituted input with the rate-limit case voided rather
than counted. It also went looking for the same defect where nobody had asked,
found it in check 15's prose, and corrected the claim rather than the evidence.
The recommendation follows on grounds that never depended on the struck licence
gate, and the integrity tradeoff is handed to the owner with a comparison table
whose left column declines to flatter the backend it replaced.

What stops approval is that the same revision reintroduces, in the owner's own
option list, the one habit this item has been rejected for three times — a word
stronger than the recorded output ("silently", against an `ERROR` and a `WARN`
the decision itself quotes) — and rests a bullet on a 404 that the logs place on
a signature file rather than on the asset it names. Both are corrected in place
by revision 10; neither requires a check to be rerun, and the owner ask should
go out with option 2's cost stated as the run actually behaves.
