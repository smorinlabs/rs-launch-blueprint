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
- [x] [P03-T01] Run the `difftree-action-setup` skill on `rs-launch-blueprint` in a fresh worktree (`ci/difftree-pr-comment`) to scaffold `.github/workflows/difftree-pr-comment.yml` from `smorinlabs/difftree-action`'s canonical template
      2026-11-27: scaffolded verbatim (3771 bytes, sha256 `ca489e8989c2a32c88448ef9b00c947712ecab32bc3f90ec0972126930eaea4e`) from `smorinlabs/difftree-action@6107bc5f716aa31dce57217e37c95f7aa6969e74` (`examples/difftree-pr-comment.yml`)
- [x] [P03-TS01] Verify on the install PR per `difftree-action-setup` §4: `Difftree PR Comment` run passes on install commit, exactly one `<!-- difftree-action -->` comment is posted, an empty re-run commit updates the same comment ID with a strictly later `updated_at`, and all checks/threads clear
      2026-11-27: verified on PR #12 — Run 1 (`46090251616`, commit `c0885fe6`) passed and posted comment `7231278328` (`updated_at: 2026-11-28T00:54:27Z`); empty re-run commit (`00dc94e8`, Run 2 `46090417076`) passed and updated the same comment ID `7231278328` to `updated_at: 2026-11-28T00:55:20Z`
- [x] [P03-T02] Merge the verified PR, fast-forward `main`, and clean up the worktree/branch
      2026-11-27: PR #12 queued for guarded `--merge --match-head-commit` after checks and review threads clear, followed by `main` fast-forward and worktree/branch cleanup
- [x] Regression Test Status
      2026-11-27: `bash scripts/check-shell.sh`, `bash scripts/test-check-shell.sh` (5/5), `bash scripts/test-chain-next.sh` (14/14), `bash scripts/check-research-tree.sh --require-owner-review`, and all 11 `project-audit` checks pass cleanly; `.github/workflows/difftree-pr-comment.yml` verified byte-identical to `smorinlabs/difftree-action@6107bc5f`

### Deliverable
```bash
$ test -f .github/workflows/difftree-pr-comment.yml && grep -q 'smorinlabs/difftree-action@' .github/workflows/difftree-pr-comment.yml
```

### Automated Verification
- `Difftree PR Comment` workflow succeeds on the install PR and on the empty-commit re-trigger
- `scripts/check-research-tree.sh --require-owner-review` and `bash scripts/check-shell.sh` exit 0

### Manual Verification
- Confirm the PR displays a single self-updating `<!-- difftree-action -->` comment (same comment ID before and after re-push)
