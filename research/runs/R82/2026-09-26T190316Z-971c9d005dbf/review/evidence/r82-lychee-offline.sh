#!/usr/bin/env bash
# R82 revision 2: execute the F349 hygiene command and the F350 scheduled-job flags with the
# pinned lychee 0.24.2 release binary (RUNBOOK §3 bounded supplementary execution, authorized
# by the controller for revision 2: one release asset for one environment).
#   L0 fetch lychee-aarch64-apple-darwin.tar.gz (this host), verify against the release API
#      digest and the .sha256 sidecar, print the version
#   L1 the exact hygiene args with the proposed lychee.toml over a fixture holding one good
#      relative link, one broken relative link, one external https URL, and a broken link
#      under target/ -> expect exit 2 naming only docs/missing.md
#   L1v L1 plus --verbose, which names the URL L1 counts as excluded
#   L2 the L1 fixture without the broken relative link -> expect exit 0 (the external URL
#      contributes no failure offline)
#   L3 the L1 fixture with exclude_path = [] -> the target/ link now fails (config is read)
#   L4 the scheduled-job flags, network mode, against a closed localhost port only
# The fixture is not a git repository, so .gitignore skipping is not exercised here.
# Usage (from the run directory): bash review/evidence/r82-lychee-offline.sh > review/evidence/r82-lychee-offline.log 2>&1
set -euo pipefail

run_dir="$(cd "$(dirname "$0")/../.." && pwd)"
tag="lychee-v0.24.2"
asset="lychee-aarch64-apple-darwin.tar.gz"
url="https://github.com/lycheeverse/lychee/releases/download/$tag/$asset"

scratch="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$scratch"' EXIT
scrub() { sed -e "s#$scratch#<scratch>#g" -e 's/\x1b\[[0-9;]*m//g'; }

echo "# r82-lychee-offline — run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# host: $(uname -srm)"
echo

echo "## L0 fetch and verify the pinned release asset"
echo "url: $url"
api_digest="$(gh api "repos/lycheeverse/lychee/releases/tags/$tag" \
  --jq ".assets[] | select(.name == \"$asset\") | .digest")"
curl -sfL -o "$scratch/$asset" "$url"
curl -sfL -o "$scratch/$asset.sha256" "$url.sha256"
got="$(shasum -a 256 "$scratch/$asset" | cut -c1-64)"
sidecar="$(cut -c1-64 < "$scratch/$asset.sha256")"
echo "downloaded sha256: $got"
echo "release API digest: $api_digest"
echo "sidecar .sha256:    $sidecar"
if [[ "sha256:$got" != "$api_digest" || "$got" != "$sidecar" ]]; then
  echo "FAIL digest mismatch"; exit 1
fi
echo "ok   digest matches both"
mkdir "$scratch/bin"
tar -xzf "$scratch/$asset" -C "$scratch/bin"
lychee="$(find "$scratch/bin" -type f -name lychee | head -n 1)"
echo "binary: ${lychee#"$scratch/"}"
echo "version: $("$lychee" --version)"
echo

echo "## lychee.toml: byte-identical to the TOML block in review/DECISION.md"
awk '/^```toml$/{f=1; next} /^```$/{f=0} f' "$run_dir/review/DECISION.md" > "$scratch/lychee.toml"
cat "$scratch/lychee.toml"
grep -q '^exclude_path = \["target"\]$' "$scratch/lychee.toml" || { echo "FAIL no exclude_path"; exit 1; }
echo "ok   extracted $(wc -l < "$scratch/lychee.toml" | tr -d ' ') lines"
echo

mkfix() { # mkfix <dir> <with-broken:yes|no>
  local d="$1"
  mkdir -p "$d/docs" "$d/target/doc"
  cp "$scratch/lychee.toml" "$d/lychee.toml"
  printf '# Guide\n\nBack to [the readme](../README.md).\n' > "$d/docs/guide.md"
  {
    printf '# Fixture\n\n'
    printf -- '- good relative link: [guide](docs/guide.md)\n'
    [[ "$2" == yes ]] && printf -- '- broken relative link: [missing](docs/missing.md)\n'
    printf -- '- external URL: [example](https://example.com/some/page)\n'
  } > "$d/README.md"
  printf '[decoy under target](not-there.md)\n' > "$d/target/doc/decoy.md"
}

case_run() { # case_run <id> <dir> <args...>
  local id="$1" d="$2"; shift 2
  { printf '%s  cwd=<fixture>  lychee' "$id"; printf ' %q' "$@"; echo; } | scrub
  local rc=0
  (cd "$d" && "$lychee" "$@") > "$scratch/out" 2>&1 || rc=$?
  echo "     exit=$rc"
  scrub < "$scratch/out" | sed 's/^/     | /'
}

# The hygiene step's args exactly as the decision writes them; "$(pwd)" is the fixture root.
hygiene() { case_run "$1" "$2" --offline --no-progress --root-dir "$(cd "$2" && pwd)" .; }

echo "## L1 hygiene args, proposed lychee.toml, fixture with a broken relative link"
mkfix "$scratch/f1" yes
hygiene L1 "$scratch/f1"
echo

echo "## L1v the L1 run with --verbose added (names what L1 counts as excluded)"
case_run L1v "$scratch/f1" --offline --no-progress --root-dir "$scratch/f1" . --verbose
echo

echo "## L2 same fixture without the broken relative link"
mkfix "$scratch/f2" no
hygiene L2 "$scratch/f2"
echo

echo "## L3 control: L1 fixture with exclude_path = [] (proves the config file is read)"
mkfix "$scratch/f3" yes
sed -i '' 's/^exclude_path = \["target"\]$/exclude_path = []/' "$scratch/f3/lychee.toml"
grep -n '^exclude_path' "$scratch/f3/lychee.toml" | sed 's/^/     config: /'
hygiene L3 "$scratch/f3"
echo

echo "## L4 scheduled-job flags, network mode, against a closed localhost port"
if nc -z -w 2 127.0.0.1 1 2>/dev/null; then
  echo "FAIL 127.0.0.1:1 is open; L4 would not model a dead host"; exit 1
fi
echo "precheck: 127.0.0.1:1 refuses connections"
mkdir -p "$scratch/f4/docs"
cp "$scratch/lychee.toml" "$scratch/f4/lychee.toml"
printf '# Guide\n' > "$scratch/f4/docs/guide.md"
printf -- '- [guide](docs/guide.md)\n- [dead host](http://127.0.0.1:1/gone)\n' > "$scratch/f4/README.md"
case_run L4 "$scratch/f4" \
  --cache --max-cache-age 1d \
  --cache-exclude-status '429, 500..' \
  --max-retries 3 --retry-wait-time 2 --timeout 20 \
  --accept '100..=103, 200..=299, 429' \
  --no-progress \
  --root-dir "$scratch/f4" \
  .
echo "     .lycheecache written: $([[ -f "$scratch/f4/.lycheecache" ]] && echo yes || echo no)"
