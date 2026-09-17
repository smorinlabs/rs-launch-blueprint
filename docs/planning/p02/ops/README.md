# Controller operating scripts (durable copies)

Copies of the session scratchpad scripts that drive P02's research loop, stored
with a `.txt` suffix so no hook lints them as shell (they are zsh). Restore
with `cp docs/planning/p02/ops/<name>.txt <scratchpad>/<name> && chmod +x`.
Saved on 2026-09-17 after a scratchpad wipe destroyed the originals; recovered
from the session transcript. `codex-audit-rN.sh` and `audit-runner.sh` are
reconstructions and must be exercised once before trust. Every script reads
credentials at run time (`gh auth token`) and stores none.
