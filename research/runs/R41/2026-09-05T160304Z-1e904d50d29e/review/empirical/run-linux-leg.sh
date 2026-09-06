#!/usr/bin/env bash
# run-linux-leg.sh — host-side driver for the Linux leg of the R41 empirical check
# (synthesizer, 2026-09-05; rewritten for the r2 rerun).
#
# Transfers review/empirical/fixture and run-checks.sh into a fresh mktemp
# directory inside the Lima VM `ubuntu` with `limactl copy`, runs the runner
# there at the 1.96.0 floor and the stable toolchain, and prints everything on
# stdout for capture on the host. The VM's 9p mount of the repository is
# read-only and served stale cached file contents on 2026-09-05 (an r2 attempt
# that copied from the mount ran the r1 script; kept as
# ../evidence/lockfile-freshness-acceptance-linux.r2-discarded-stale-9p-cache.log),
# so the mount is not read. The VM-side sha256 of the transferred files is
# printed so the log proves which versions ran.
#
# Usage: bash run-linux-leg.sh > ../evidence/<new-log-name>.log 2>&1
# Always write a new log name; never overwrite an existing evidence log
# (r1: lockfile-freshness-acceptance-linux.log; r2: …-linux.r2.log).
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
TMP=$(limactl shell ubuntu -- bash -lc 'mktemp -d /tmp/r41-synth-XXXXXX' 2>/dev/null | tr -d '\r' | tail -1)
case "$TMP" in /tmp/r41-synth-*) ;; *) echo "could not create a VM temp directory: '$TMP'" >&2; exit 2;; esac
limactl copy -r "$HERE/fixture" "$HERE/run-checks.sh" "ubuntu:$TMP/" || { echo "limactl copy failed" >&2; exit 2; }
echo "linux leg: fixture and runner transferred with limactl copy into $TMP in the Lima VM ubuntu (the 9p mount is read-only and may serve stale cached content, so it is not read); stdout captured on the host"
limactl shell ubuntu -- bash -lc '
set -u
source "$HOME/.cargo/env"
TMP="$1"
chmod +x "$TMP/fixture/scripts/check-cargo-lock.sh" "$TMP/run-checks.sh"
echo "transferred files (sha256 computed in the VM):"
(cd "$TMP" && sha256sum run-checks.sh fixture/scripts/check-cargo-lock.sh | sed "s/^/  /")
echo "host provenance: rustup stable alias = $(rustup run stable rustc --version 2>&1); PATH cargo = $(command -v cargo)"
export WORK_DIR="$TMP/.work"
bash "$TMP/run-checks.sh" "floor-1.96.0=$(dirname "$(rustup which --toolchain 1.96.0 cargo)")" "stable-1.98.1=$(dirname "$(rustup which --toolchain stable cargo)")"
echo "runner exit: $?"
' _ "$TMP"
