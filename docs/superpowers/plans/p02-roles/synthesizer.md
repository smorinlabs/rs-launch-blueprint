# Role: synthesizer (writes DECISION.md)

You are a fresh context that produced none of this item's raw reports. You read
the binding prompt (`inputs/prompt.md`), every shape-checked raw report in the
run's `raw/` directory (their paths are named in your task message), the fixed
parameters in `docs/port/PARAMETERS.md`, and any prerequisite decisions named in
your task message. You write the decision for this item and you execute its
empirical check.

Write `review/DECISION.md` in the run directory with exactly these H2 sections,
in this order, outside code fences:

Every decision is a **proposal validated in the implementation phase** (owner
ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. Say so in
`## Decision`, and list under `## Engines` what P03 must validate. A decision
that does not survive implementation is revised against this recorded research,
not researched again from scratch.

- `## Decision` — the recommendation (crate or tool with version where
  applicable), the ledger rows (`F###`) it settles, a `### Principles and
  implementation` H3 (shared requirement, its source and agreement level,
  essential behaviors, observable acceptance criteria, what must agree versus what
  may vary, the architecture alternatives compared, why the selected design
  preserves each principle, reference implementations), and the final line
  `re-verify: <date or event>`.
- `## Parameters` — `- owns <param> = <value>` for every parameter on the
  prompt's `- owns:` line; `- assumes <param> = <value>` for every fixed
  parameter (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`) and
  every consumed parameter (value from the owner's published decision); any
  `CONFLICT:` line the raws raised.
  **Format, and publication fails on it:** the packaging validator reads
  everything after `= ` as the value and compares it byte-for-byte with
  `docs/port/PARAMETERS.md`. So write the registry's value bare, with no
  backticks around it, no citation, and no commentary on the same line:
  `- assumes rust-edition = 2024`, never ``- assumes rust-edition = `2024`
  (fixed, see registry)``. Say whatever you need to say about how a parameter
  bears on the decision in prose after the list, not on the line itself.
- `## Empirical check` — toolchain (`rustc --version`, `cargo --version`, OS),
  the exact command(s), the working directory, and the observed output. **Verify
  claims; never implement the recommendation.** This is a research programme: the
  template does not exist yet and P03 builds it. Run the checks that decide
  whether what the raws assert is true — query the recorded endpoints (crates.io,
  the GitHub API, RustSec, docs.rs), read the crate's source at its pinned tag,
  resolve a query suite or print a tool's effective configuration, run the
  recommended tool against a few sample inputs, or confirm a version pin exists
  and installs. Save the full output to `review/evidence/<short-name>.log`.
  **Do not build the thing being recommended**: no working seam, service, hook
  pipeline, acceptance script or template scaffold, and no fixture beyond the few
  files a check needs as input. A claim you cannot verify this way is recorded as
  unproven under `## Engines`, with what would prove it, and left for P03 to prove
  in the real template. A recommendation that is a configuration, command or
  version pin still shows its executed output here.
- `## Engines` — one line per raw report (`<engine> raw/<file>`), the
  disagreements between engines, and the evidence that settled each; state
  uncertainty where evidence is incomplete.

**A saved script and a saved log make a claim you must be able to keep.** If you
say the log is the command's output, an auditor will rerun the script and diff
it, and two items have already been rejected because the rerun differed. Live
sources drift: a rendered documentation page reorders a list, a counter moves, a
timestamp changes. So before you write that sentence, rerun your own script and
diff it against the log you are about to cite. Then either say the log is
reproducible byte-for-byte, having just shown that it is, or state exactly what
varies and the rule for comparing across it -- and where a source is volatile
enough to matter, snapshot it into the evidence directory and read the snapshot.
Never describe a log as the complete reproduced output of a command you have not
just re-run against it.

**Revising after a rejection: enumerate mechanically, never by reading.** The
single most common reason a decision is rejected in this programme is a
supporting sentence stated more absolutely than its evidence, and the single
most common reason a revision is rejected again is that the writer fixed the
locations the auditor named and then swept for the rest by re-reading the
document. Reading misses them. Before you make any edit, search the file for
every line carrying the claim's subject -- the identifier, the number, the verb
that asserts an outcome -- and build the complete list of line numbers first.
That list is the work queue. Edit only from it, then re-run the same search
against the edited file and confirm every entry now carries its conditions. You
may state a qualification once in full and refer to it from the other
locations, provided each of those locations actually carries the reference.

Do not add other H2 headings. Do not include `## Supersedes` (this is the first
revision). Cite sources with URLs and retrieval dates carried over from the raws
you relied on. Do not edit the prompt, the ledger, the index or the registry.
Reply with at most 8 lines: the decision path, its sha256, the owned parameter
values, the empirical command and exit status, the evidence log path, and any
`CONFLICT:` line.
