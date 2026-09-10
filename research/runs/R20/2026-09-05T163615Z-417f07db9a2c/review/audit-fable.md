decision-sha256: 02fee7a4d48220fc32187fd8ff43bdb70611907f2f9fbf64ae672b9e609ec772
actor: audit-fable-2026-09-05T163615Z-417f07db9a2c-r2
model: claude-opus-5
family: anthropic
verdict: approve
unresolved-findings: none

## Principle and agreement level

Four principles are stated with sources and levels, and the levels are chosen
rather than inherited. P1 (a reference the upstream cannot silently change) and
P4 (the scope rule is stated over owners) are **policy**, justified on the ground
that the mechanism is GitHub's ref resolution, not the language's — which is the
correct reason for a low-level value to be shared across py, ts and rs under spec
§2, where a deliberately shared mechanism needs its evidence stated. P2 (a pin is
maintained, not merely set) is policy with its *mechanism* explicitly assigned to
R19. P3 (the policy is machine-checked) is **capability**, and that choice is
load-bearing rather than decorative: it says "more than one checker may be
needed" and fixes agreement on the observable behavior — CI failing on a
non-conforming `uses:` — not on the number of commands. Because P3 was set at
capability, revision 2's second check sits inside the declared agreement level
instead of stretching it.

**The owner-prefix boundary is right, and the decision is honest that scope, not
evidence, sets it.** Part 2 puts `smorinlabs/*`, `googleapis/*` and `google/*`
inside the third-party set with no owner-trust carve-out, and the pattern's own
exemption is then constrained to be per file rather than per owner, so
`smorinlabs/contributors-please-action` stays SHA-pinned. The reason for the
*partition* is stated (P4: an owner prefix is the only thing an enforcer can
evaluate). The reason for *no self-trust* follows from P1 — movability does not
depend on who administers the upstream — and the Opus raw states it directly
(`raw/opus.md:114`, the Aqua post-mortem's residual-credential root cause at a
security vendor). The decision carries the Trivy evidence but leaves the
inference to P1 rather than restating it at part 2; substantively sound, one
sentence short of explicit.

The `actions/*`/`github/*` half is labelled "fixed by this item's scope, not by
evidence", and the contrary evidence is filed as a properly formed
`BASELINE-REVIEW: F055` line with four parts and five independent sources, marked
"Recorded, not acted on" with the cost of acting (one line of `zizmor.yml`). The
decision then makes the cost of the scope boundary visible instead of burying it:
observation 7 shows `actions/dependency-review-action@v5` resolves through a
*branch*, the weakest ref class. That is the runbook's required handling —
challenge recorded, baseline not silently changed.

Ledger handling is disciplined. F055 resolves to the ts shape; its row
*description* is corrected from pinned source (py holds 4 floating-major and the
remainder exact patch tags, not one uniform shape) while the `DIVERGENT` verdict
is explicitly preserved, with the reason an exact patch tag is still a mutable
ref. F062 is "touched, not re-decided". Neither row is rewritten by the decision.

## Design and evidence

**Alternatives were genuinely compared.** Four architectural alternatives (A
reference-format policy, B publisher-side immutability, C inventory reduction, D
runtime containment) are compared on what each does and why it loses, and B is
ranked runner-up on a stated structural ground — GitHub shipping a consumer-side
enforcement primitive is re-verify trigger 1, which flips the recommendation.
That is a falsifiable condition, not a hedge. The library selection does not rest
on popularity: the practice survey is reported as **no consensus** (uv, ruff,
zizmor hash-pin; tokio, rustls, ripgrep ref-pin and all three accept
`dtolnay/rust-toolchain@master`), and the discriminator is named as security
posture and recency rather than language or downloads. Counter-evidence is
carried rather than suppressed.

**The second check is proportionate, and narrowing the criterion would have been
the wrong repair.** The first audit's F1 was that `zizmor .github/` does not
enforce the comment grammar. Two repairs were open; the decision took the harder
one and argued it. I agree with the choice, on three grounds the decision states
and one it demonstrates:

- The comment is the whole of P2 and of essential behavior (b). Demoting it to an
  unenforced convention leaves P2 with no observable criterion, which P3 forbids.
  The failure mode is live, not hypothetical: `dependabot-core#7912` (open since
  2023-08-28) and `#14716` (open since 2026-04-14) are the comment-drift bugs, and
  a bare 40-hex SHA with no comment is unreviewable by a human.
- The alternative was examined and rejected from the tool's own artifacts at the
  pinned tag, not from preference: `--persona=pedantic` is a global sensitivity
  switch that imports unrelated findings, zizmor has no per-audit persona setting
  (four documented `rules.<id>` settings, none of them persona), and even pedantic
  does not establish the grammar because the maintainers' own test data labels
  `# 2.7.0` "No finding".
- The check is about as cheap as a bespoke check gets — a `grep` pipeline over
  text files, no network, no token, no install — and it was *executed*, against 19
  real SHA-pinned lines from both source repositories and four synthetic
  non-conforming shapes, with exit statuses recorded.
- The decision did not merely defend revision 1's criterion: it **widened the
  grammar** from `# vX.Y.Z` to a form the evidence supports, because upstream tags
  are not all v-prefixed three-component semver. It relaxed the content of the
  criterion while keeping it enforced. That is the correct combination, and it is
  the opposite of defending a criterion for its own sake.

The regular expression is quoted at lines 85 and 224 and the two byte strings are
identical (I checked; the third occurrence at line 396 is a different, shorter
pattern used for counting pins, not the contract). Unproven 4a names the residual
grammar risk with concrete rejected shapes (`2026.09.1-rc1`, `release-7`), the
evidence that none exists today, and the instruction that the two occurrences must
be widened together and must not drift apart.

**The vendor exemption is argued, and its hole is bounded and named.** Five
distinct moves, not an assertion: the factual basis is executed (vendor, py and ts
copies each 3771 bytes and `diff`-identical; the vendor `examples/` directory
publishes no SHA-pinned variant); the provenance is labelled honestly —
`BASELINE-REVIEW.md` open question 6 recommends option (a), and the decision says
that is "a recommendation to the owner, not an owner decision", which matches the
file at `docs/port/BASELINE-REVIEW.md:364-367`; the scope is per file, never per
owner; the retirement condition is named and actionable (the maintainer is the
owner's own org, and the vendor's `v0` tag is shown to be a choice, not a forced
one); and the reversal path is priced ("the exemption is deleted and the vendor
file diverges by one line"). The best reasoning in the section is the mechanism
constraint: the exemption must be a path-scoped `zizmor.yml` ignore, never an
inline `# zizmor: ignore[unpinned-uses]` comment, because the inline form edits
the file and destroys the byte identity the exemption exists to protect. That is
the decision noticing that the obvious implementation would defeat its own
purpose. The residual hole is exactly two ref-pinned `uses:` clauses in one file,
enumerated by name and line under unproven 1b.

**The reproduction claim is honest.** Revision 1's "reproduces the whole log" was
false and was caught; revision 2 replaced it with a counted comparison behind a
quoted, runnable command. The 28 differing lines are accounted for by category and
the categories sum exactly to 28 (2 + 2 + 8 + 14 + 2), none is an observed value,
and the empirical auditor ran the same command and reproduced the number and the
conclusion. Byte identity is explicitly **not** claimed, with the reason (live
endpoints) and the clearest example named (observation 9's download counts). The
revision-1 log is left untouched rather than regenerated, preserving the audit
trail. The auditor describes the final differing pair as the same `refs/heads/v5`
value on each side of a newline-only boundary where the decision calls it a
trailing-newline difference; those describe one diff pair from two angles and both
conclude no value changed. This is a claim narrowed to fit its evidence and made
checkable, not a problem papered over.

**The unproven list is genuine.** Nine entries, each naming what would prove it,
and several naming the assertion discipline as well ("Assert the exit code, not
the message text"; "a gate never observed to fail has not been validated"). Item 1
is honest that zizmor was never run. Item 1a is the sharpest: it rests on test-data
*labels*, the decision says so ("documentation, not an execution"), and it declines
to resolve the offline question in either direction — noting the audit's own table
says "works offline" while resolving a tag to a commit is inherently online, then
asserting neither reading and naming the two-run experiment that settles it.
Item 5 contains the sentence that most cleanly separates a gap from a conclusion:
`docker://` and reusable-workflow clauses are "outside what this evidence covers
rather than covered by it". Item 6 labels the rs inventory "a projection, not an
inventory". I found no conclusion dressed as a gap, and no assertion elsewhere in
the document that belongs on this list — the claim closest to the line, criterion
3a's default-persona behavior, is flagged at its point of use in part 3.1 and not
only in the list.

**The freshness deferral is clean and provably so.** It is admitted in three
places that do different jobs: the dedicated paragraph ("without a freshness path
the pattern degrades into frozen pins"), criterion 4 marked "(R19's deliverable;
asserted here as a prerequisite)", and re-verify trigger 3, which names the
specific R19 outcome that breaks the pattern and says the response is re-argument,
not a patch. The Opus raw made the dependency explicit at `raw/opus.md:217`,
including a proposed `assumes R19 … = version updates enabled, with cooldown >= 7
days`; the decision preserves Opus's disposition (revisit R20 rather than override
R19) while correctly declining to record that unregistered value as a parameter —
R20 consumes none, and the runbook forbids adopting an unregistered value. It also
hands R19 the `lead 2` evidence that bears on R19's version-versus-security-only
choice instead of pre-deciding it. The dependency is disclosed, priced, and left
with its owner.

**The `## Engines` synthesis fairly represents the raws.** I verified each
characterisation by grep rather than accepting it: Codex does record
`BASELINE-REVIEW: F062` and the verbatim-workflow exemption (`raw/codex.md:90-91`);
Opus never mentions F062 and reads `difftree-action@v0` as an undetected violation
of ts's own policy (`raw/opus.md:167`); Codex excludes zizmor by the MSRV gate at
`rust-version = 1.97.0` and offers a shell fallback (`raw/codex.md:113,122-123`)
while Opus answers the gate `inapplicable` for a prebuilt binary
(`raw/opus.md:118,122`); the two boundary phrasings are quoted accurately
(`raw/opus.md:278` "draws no official-vs-third-party boundary" versus
`raw/codex.md:13,102`); Opus's operability argument and the ts inline comment it
rests on are at `raw/opus.md:69`; and the Trivy figure discrepancy, the six-project
survey with its "no consensus" reading, and `lead 1`'s `install-plugins.ts` reading
are present as described (`raw/opus.md:83,38-42,176`). The claim that **neither
engine covered what a checker enforces about the comment** is exactly right:
`pedantic`, `persona` and `ref-version-mismatch` do not occur in either raw. That
gap is recorded under `## Engines` rather than as a disagreement, with the correct
reason — the engines agreed, and agreement was not evidence of fitness, which is
spec §2's governing rule applied to the decision's own inputs.

## Completeness

The four required H2s are present and correctly ordered (`## Decision` with
`### Principles and implementation` and `re-verify: 2027-03-10` inside it,
`## Parameters`, `## Empirical check`, `## Engines`). No `## Supersedes`, correctly
— this is a revision in place, not a reversal, and the revision note names the
superseded sha256, the auditor, its model and family, and its verdict.

Parameters: R20 owns and consumes nothing, which matches the prompt's empty
`- owns:` and `- consumes:` lines, and the decision says so and adds no registry
row. The four fixed `assumes` values are byte-identical to their rows in
`docs/port/PARAMETERS.md` (I diffed all four). Each is dispositioned rather than
listed: `msrv-policy` binds only through the acquisition channel, which is why the
prebuilt-binary channel is part of the recommendation and not an implementation
detail; `target-os-matrix` is satisfied by the release archives; `license` by MIT;
`rust-edition` has no bearing.

Fitness gates: gate 1 (license MIT), gate 2 (MSRV, answered `inapplicable` with
the gate's own wording quoted and the disagreement that produced the answer
recorded), gate 3 (advisories — and notably not accepted on a bare 404: the 404 is
discriminated against two known-200 controls and corroborated by an empty
advisories API result, which is why Codex's unverified result was downgraded), and
gate 4 (linux-gnu and apple-darwin archives for both architectures). Gates 5 and 6
are answered in substance — zizmor "is not linked into the template" and "enters
neither `Cargo.toml` nor the MSRV job", which is the reason default-features and
binary-size cost do not apply — but the word `inapplicable` is not attached to
them as the prompt's tier guidance asks. A formal looseness, not a silent omission;
the reason is present and unambiguous, and the Opus raw carries both gates
explicitly (`raw/opus.md:125-126`).

Sources carry endpoints and retrieval dates, and the two zizmor reading levels are
distinguished — observations 9-10 read `main`, observations 14-15 read the pinned
tag `v1.30.1`, the document says which line numbers belong to which, and says the
two agree where they overlap. Evidence carried from Opus without re-verification
is labelled as such with its retrieval date, and the TanStack incident is recorded
as secondary-source-only with nothing resting on it.

The audit-codex rerun is consistent with the decision: same sha256, script rerun to
exit 0, the 28-line count reproduced, the regex verified to occur twice
byte-identically, the four `assumes` lines diffed against the registry, the zizmor
facts confirmed at `v1.30.1`, the pinned-tree counts and the 3771-byte identity
re-derived from pinned Git objects, and five cited URLs at HTTP 200. Its one
inability — a Linux rerun blocked by a sandbox denial — is reported rather than
elided.

## Findings

None.

## Assessment

The recommendation is sound and the reasoning supports it. `enforced-owner-prefix-pinning`
adopts the ts shape for a stated reason rather than because ts is the incumbent,
scopes "third-party" by the only partition an enforcer can evaluate, refuses a
self-trust carve-out for the owner's own namespace, and attaches every acceptance
criterion to the command that produces it — which is precisely the defect that
sank revision 1, repaired at the level it occurred rather than papered over. The
document's characteristic move is to narrow claims to their evidence: the ledger
description is corrected while the verdict is preserved, the reproduction claim
becomes a counted comparison behind a runnable command, the guidance boundary is
stated as both halves rather than either engine's stronger framing, the grammar is
widened to what upstream tags actually look like, and the pattern says in terms
what it does not buy ("It does not make CI safe"). It is fit to publish as a
proposal for P03 to validate.

Four notes for the controller. None blocks publication and none is a finding.

1. **Say now what happens to criterion 3a if unproven 1a fails.** Criterion 3a
   asserts that `zizmor .github/` at the default persona exits non-zero on a stale
   comment, and 1a admits that rests on test-data labels rather than an execution.
   If P03 finds it false, the decision does not say which way it goes — and the F1
   repair's two options are not both available here: observation 14 establishes
   there is no per-audit persona setting, so the only fallback is a check that
   resolves tags to commits, which needs network and a token and therefore gives up
   the "no network, no token" property the decision cited for choosing a bespoke
   script in the first place. One sentence naming the disposition (drop 3a, or grow
   the script and accept the token) would keep the F1 defect from recurring one
   level down.
2. **Restore the R08 pointer the synthesis dropped.** `raw/opus.md:200` dispositions
   `lead 1`'s mitigations to workflow-permission hardening, "R08's territory" (and
   notes the R18 overlap). The decision preserves the *limit* under "What this
   pattern does not claim" but not the *owner* of the mitigation. The same gap
   makes the F062 exemption's residual risk read as a policy hole rather than a
   bounded one — the blast radius of the exempted clause is a function of the token
   scope that workflow grants, which is R08's to decide. A cross-reference costs a
   clause and closes the loop.
3. **Attach the word `inapplicable` to fitness gates 5 and 6.** The reason is
   already stated (zizmor is never linked into the template); the tier guidance asks
   for the label, and the Opus raw supplies both answers verbatim.
4. **Two small wording repairs.** Part 1's gloss says "`#`, one space" where the
   expression is `#[[:space:]]`, which also admits a tab; and the 28-line accounting
   calls the last pair "a trailing-newline difference on the final line", where the
   auditor's description makes clear the line carries the `refs/heads/v5` value
   identically on both sides. Neither changes a conclusion.

One further observation, offered as context rather than a request. The empirical
check ran the comment-grammar half but never invoked zizmor at all, and the stated
reason — "running it would require building the thing being recommended" — is
stronger than it needs to be, since a two-clause synthetic workflow plus a
`zizmor.yml` is not the template. The operative constraint is the one stated in the
same paragraph: the check installs nothing, and zizmor requires a binary. I do not
count this against the decision — the owner's 2026-09-10 ruling puts validation in
P03, unproven items 1 and 1a name exactly the experiments that settle it, and this
is a research programme in which a decision must not implement its own
recommendation.
