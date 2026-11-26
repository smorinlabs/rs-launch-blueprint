# P03 — Install difftree-action PR comment workflow

**References**
- **Trunk:** [PROJECTS.md](../PROJECTS.md)
- **Prior art:** [COMMONALITY.md (F062)](../docs/port/COMMONALITY.md)
- **Prior art:** [R20 third-party action pinning policy](../research/topics/20-third-party-action-pinning-policy/DECISION.md)

**Goal/Requirement**: Install the canonical `smorinlabs/difftree-action` workflow (`.github/workflows/difftree-pr-comment.yml`) on `rs-launch-blueprint` via the `difftree-action-setup` skill so every pull request gets a single, self-updating ASCII diff-tree comment — bringing `rs-launch-blueprint` into parity with `py-launch-blueprint` and `ts-launch-blueprint`.
- Aligns with `F062` (`docs/port/COMMONALITY.md`, `COMMON → REUSE`) and `R20` (`research/topics/20-third-party-action-pinning-policy/DECISION.md`: canonical file stays byte-identical via path-scoped `zizmor.yml` exemption, or takes the single sanctioned SHA-pin deviation on `smorinlabs/difftree-action` if repo policy requires it).
- Child repos stamped from `rs-launch-blueprint` should inherit `.github/workflows/difftree-pr-comment.yml` intact: when `rs-launch-blueprint` adopts `template-press`, preserve `smorinlabs/difftree-action` via `[rules] keep_names = ["smorinlabs/difftree-action"]` in `press/press-rules.toml` (do not `[[remove]]` the workflow).

**Out of Scope**
- Modifying `smorinlabs/difftree-action` or its canonical template
- Implementing the rest of the Rust blueprint CI workflows beyond `difftree-pr-comment.yml`

**TDD: not applicable** — workflow verification runs on the install PR itself after `.github/workflows/difftree-pr-comment.yml` is committed.

### Tests & Tasks
- [ ] [P03-T01] Run the `difftree-action-setup` skill on `rs-launch-blueprint` in a fresh worktree (`ci/difftree-pr-comment`) to scaffold `.github/workflows/difftree-pr-comment.yml` from `smorinlabs/difftree-action`'s canonical template
- [ ] [P03-TS01] Verify on the install PR per `difftree-action-setup` §4: `Difftree PR Comment` run passes on install commit, exactly one `<!-- difftree-action -->` comment is posted, an empty re-run commit updates the same comment ID with a strictly later `updated_at`, and all checks/threads clear
- [ ] [P03-T02] Merge the verified PR, fast-forward `main`, and clean up the worktree/branch
- [ ] Regression Test Status

### Deliverable
```bash
$ test -f .github/workflows/difftree-pr-comment.yml && grep -q 'smorinlabs/difftree-action@' .github/workflows/difftree-pr-comment.yml
```

### Automated Verification
- `Difftree PR Comment` workflow succeeds on the install PR and on the empty-commit re-trigger
- `scripts/check-research-tree.sh --require-owner-review` and `bash scripts/check-shell.sh` exit 0

### Manual Verification
- Confirm the PR displays a single self-updating `<!-- difftree-action -->` comment (same comment ID before and after re-push)
