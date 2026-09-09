set -u
source "$HOME/.cargo/env"
SRC=/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R38/2026-09-05T151356Z-c46d732f98ed/review/empirical
DST=/tmp/r38-linux-r4
rm -rf "$DST"; mkdir -p "$DST"
# VM-local copy of the fixture; exclude the macOS-provisioned binary, scratch repos and the cargo target dir
(cd "$SRC" && tar --exclude=./tools --exclude=./.work --exclude=./repo-hygiene/target --exclude=./.audit-work --exclude=./cargo-commitlint-compare -cf - .) | (cd "$DST" && tar -xf -)
echo "linux leg: fixture copied from $SRC to $DST (VM-local; tools/ reprovisioned here)"
echo "os: $(uname -srm); $(lsb_release -ds 2>/dev/null)"
cd "$DST"
time bash run-checks.sh
echo "RUN_CHECKS_EXIT=$?"
