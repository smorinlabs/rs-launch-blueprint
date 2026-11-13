#!/usr/bin/env bash
# R77 revision 4 — registry and repository drift since revision 1's 2026-09-18
# snapshots, asserted against revision 4's 2026-09-27 snapshots.
#
#   S  SNAPSHOT: the newest non-yanked release of every crate (num, created_at,
#      rust_version), the stable channel, and the repository figures revision 4
#      cites, read from review/evidence/snapshots-r4/ (written by
#      fetch-snapshots-r4.sh). Reproducible for ever.
#   G  GATE: the gate-2 consequences of those figures (config 0.15.26 inside the
#      runner-up range and under the 1.96 floor; the excluded crates still
#      declaring no rust-version on their newest release).
#   L  LIVE: re-fetches the newest non-yanked release per crate. `num` and
#      `rust_version` are printed as DRIFT lines and never asserted, because a
#      new release is expected to appear; the per-version rust_version of the
#      pinned config 0.15.26 is immutable and IS asserted. Without network, SKIP.
#
# Comparison rule across a re-run: S and G lines must match exactly; DRIFT lines
# may move in either direction for rolling counters and forward for releases.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
s1="$here/snapshots"
s4="$here/snapshots-r4"
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}
newest() { # $1 versions.json -> "num|created_at(date)|rust_version"
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
v=[x for x in d["versions"] if not x["yanked"]][0]
print("%s|%s|%s" % (v["num"], v["created_at"][:10], v["rust_version"]))' "$1"
}
jf() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$1" "$2"; }

printf '# R77 drift, revision 4 — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# revision-1 snapshots 2026-09-18; revision-4 snapshots 2026-09-27 (UTC)\n'
[ -d "$s4" ] || { no "snapshots-r4 missing at $s4"; printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"; exit 1; }

echo
echo '## S — newest non-yanked release per crate, 2026-09-18 → 2026-09-27'
while IFS='|' read -r name want; do
  [ -n "$name" ] || continue
  was=$(newest "$s1/cratesio-${name}-versions.json")
  now=$(newest "$s4/cratesio-${name}-versions.json")
  printf '     %-10s 2026-09-18 %-34s 2026-09-27 %s\n' "$name" "$was" "$now"
  assert_eq "S $name newest release on 2026-09-27" "$want" "$now"
done <<'EOF'
envy|0.4.2|2021-01-04|None
config|0.15.26|2026-09-21|1.88.0
figment|0.10.19|2024-05-17|None
confique|0.4.0|2025-10-27|1.68.2
envconfig|0.11.1|2025-12-10|None
serde-env|0.3.0|2026-04-15|None
envious|0.3.0|2026-05-29|None
dotenvy|0.15.7|2023-03-22|1.56.1
serde|1.0.229|2026-07-18|1.56
pathdiff|0.2.3|2024-11-25|None
winnow|1.0.4|2026-07-13|1.65.0
EOF
assert_eq "S config's newest release on 2026-09-18 was 0.15.25 declaring 1.85.0" \
  "0.15.25|2026-06-26|1.85.0" "$(newest "$s1/cratesio-config-versions.json")"
stable=$(/usr/bin/grep -A1 '^\[pkg.rust\]' "$s4/channel-rust-stable.toml" | /usr/bin/sed -n 's/^version = "\(.*\)"$/\1/p')
assert_eq "S current stable on 2026-09-27" "1.98.1 (48a229cea 2026-09-01)" "$stable"

echo
echo '## S — repository figures revision 4 re-records'
assert_eq "S Figment pushed_at on 2026-09-18" "2024-09-13T04:51:49Z" "$(jf "$s1/gh-repo-SergioBenitez__Figment.json" pushed_at)"
assert_eq "S Figment pushed_at on 2026-09-27" "2026-09-27T00:54:08Z" "$(jf "$s4/gh-repo-SergioBenitez__Figment.json" pushed_at)"
n=$(python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' "$s4/gh-commits-SergioBenitez__Figment-since-2024-09-14.json")
assert_eq "S Figment default-branch commits since 2024-09-14" "0" "$n"
assert_eq "S Figment open issues on 2026-09-27" "21" "$(jf "$s4/gh-openissues-SergioBenitez__Figment.json" total_count)"
assert_eq "S serde-env pushed_at on 2026-09-27" "2026-09-19T14:14:42Z" "$(jf "$s4/gh-repo-Xuanwo__serde-env.json" pushed_at)"
assert_eq "S serde-env open issues on 2026-09-18" "1" "$(jf "$s1/gh-openissues-Xuanwo__serde-env.json" total_count)"
assert_eq "S serde-env open issues on 2026-09-27" "0" "$(jf "$s4/gh-openissues-Xuanwo__serde-env.json" total_count)"
assert_eq "S config-rs stars on 2026-09-27" "3214" "$(jf "$s4/gh-repo-rust-cli__config-rs.json" stargazers_count)"
assert_eq "S config-rs pushed_at on 2026-09-27" "2026-09-25T01:17:15Z" "$(jf "$s4/gh-repo-rust-cli__config-rs.json" pushed_at)"
assert_eq "S envy pushed_at unchanged" "2024-06-07T23:13:52Z" "$(jf "$s4/gh-repo-softprops__envy.json" pushed_at)"
assert_eq "S envy open issues unchanged" "14" "$(jf "$s4/gh-openissues-softprops__envy.json" total_count)"

echo
echo '## G — gate-2 consequences'
rv=$(newest "$s4/cratesio-config-versions.json" | cut -d'|' -f3)
num=$(newest "$s4/cratesio-config-versions.json" | cut -d'|' -f1)
if python3 -c 'import sys
v=tuple(int(x) for x in sys.argv[1].split("."))
sys.exit(0 if (0,15,25) <= v < (0,16,0) else 1)' "$num"; then
  ok "G config $num is inside the runner-up range >= 0.15.25, < 0.16.0"
else no "G config $num is outside the runner-up range"; fi
if python3 -c 'import sys
v=tuple(int(x) for x in sys.argv[1].split("."))
sys.exit(0 if v[:2] <= (1,96) else 1)' "$rv"; then
  ok "G config $num's rust-version $rv is at or below the 1.96 floor — gate 2 still passes"
else no "G config $num's rust-version $rv is above the 1.96 floor"; fi
for name in envy figment envconfig serde-env envious; do
  assert_eq "G $name's newest release still declares no rust-version (gate 2 still fails)" \
    "None" "$(newest "$s4/cratesio-${name}-versions.json" | cut -d'|' -f3)"
done

echo
echo '## L — live'
if ! curl -sS --fail --max-time 20 -o /dev/null -H "User-Agent: $UA" https://crates.io/api/v1/crates/config/0.15.26 2>/dev/null; then
  sk "L live re-fetch — crates.io not reachable (12 lines)"
else
  v=$(curl -sS --fail --max-time 30 -H "User-Agent: $UA" https://crates.io/api/v1/crates/config/0.15.26 \
      | python3 -c 'import json,sys; print(json.load(sys.stdin)["version"]["rust_version"])')
  assert_eq "L config 0.15.26 declares rust-version 1.88.0 (immutable per version)" "1.88.0" "$v"
  for name in envy config figment confique envconfig serde-env envious dotenvy serde pathdiff winnow; do
    live=$(curl -sS --fail --max-time 30 -H "User-Agent: $UA" "https://crates.io/api/v1/crates/${name}/versions" \
           | python3 -c 'import json,sys
d=json.load(sys.stdin)
v=[x for x in d["versions"] if not x["yanked"]][0]
print("%s|%s|%s" % (v["num"], v["created_at"][:10], v["rust_version"]))')
    printf 'DRIFT %-10s newest non-yanked snapshot-r4=%s live=%s\n' "$name" "$(newest "$s4/cratesio-${name}-versions.json")" "$live"
  done
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
