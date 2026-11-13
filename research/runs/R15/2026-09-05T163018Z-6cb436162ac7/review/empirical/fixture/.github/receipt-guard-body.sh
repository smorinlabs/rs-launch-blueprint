#!/usr/bin/env bash
# Verbatim body of the `No committed receipt in the template` step in
# .github/workflows/template-receipt-guard.yml, runnable outside Actions.
if [ -f press/press-receipt.toml ]; then
  echo "::error::press-receipt.toml committed in the template —" \
    "it would disarm every fork's guard. Revert."
  exit 1
fi
