#!/usr/bin/env bash
# Resolve the Codex rollout thread id for a run directory. That id is what
# `research_runner.py run submitted --provider codex --operation-id ...`
# records, because the Codex CLI returns no provider operation id of its own.
#
# Matching is on the rollout's recorded working directory, never on a text
# search of rollout bodies: a grep once attributed R46's thread to R47.
#
# usage: codex-thread-for.sh <absolute run dir> [ordinal]
#   ordinal 1 = first session started in that directory (the research run),
#   2 = the second (evidence check or audit), and so on in start order.
#
# Rollouts live under ~/.codex/sessions on the machine that ran them, so this
# resolves nothing for runs performed on a different computer; the ids already
# recorded in each run's manifest.json remain the durable record.
set -uo pipefail

run="${1:?usage: codex-thread-for.sh <absolute run dir> [ordinal]}"
n="${2:-1}"

for f in $(ls ~/.codex/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | sort); do
  cwd=$(head -1 "$f" | grep -o '"cwd":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ "$cwd" = "$run" ]; then
    basename "$f" .jsonl | sed -E 's/^rollout-[0-9T-]+-//'
  fi
done | sed -n "${n}p"
