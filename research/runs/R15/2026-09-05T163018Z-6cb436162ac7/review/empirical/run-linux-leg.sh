#!/usr/bin/env bash
# R15 Linux leg. The Lima VM (`ubuntu`, Ubuntu aarch64 — GitHub's ubuntu-latest
# runners are x86_64) mounts this worktree READ-ONLY, so the fixture and the
# check script are copied to ~/r15-empirical inside the VM, an isolated venv is
# created there (uv venv + uv pip install template-press==4.0.1), the cases run
# there, and the per-case logs are copied back into review/evidence/.
# Usage: run-linux-leg.sh   (from the host; requires `limactl` and a running `ubuntu` VM)
set -u
E="$(cd "$(dirname "$0")" && pwd)"
EVID="$E/../evidence"
VM=ubuntu
VMDIR='$HOME/r15-empirical'
limactl shell "$VM" -- bash -lc "rm -rf $VMDIR && mkdir -p $VMDIR/evidence"
limactl copy -r "$E/fixture" "$VM:r15-empirical/fixture"
limactl copy "$E/run-checks.sh" "$VM:r15-empirical/run-checks.sh"
limactl shell "$VM" -- bash -lc "
  source \$HOME/.cargo/env; export PATH=\$HOME/.local/bin:\$PATH
  cd $VMDIR
  {
    echo \"# uv venv + template-press install (linux leg: \$(uname -srm), \$(lsb_release -ds 2>/dev/null)), \$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    echo '# NOTE: VM is aarch64; GitHub ubuntu-latest runners are x86_64.'
    uv --version
    uv venv venv-linux --python 3.13 2>&1
    uv pip install --python venv-linux/bin/python template-press==4.0.1 2>&1
    venv-linux/bin/press --version; echo \"exit=\$?\"
    uv pip show --python venv-linux/bin/python template-press 2>&1 | grep -v '^Location'
  } 2>&1 | tee evidence/install-template-press-linux.log
  EVID=$VMDIR/evidence bash run-checks.sh linux
"
limactl copy -r "$VM:r15-empirical/evidence/." "$EVID/"
echo "logs copied to $EVID"
