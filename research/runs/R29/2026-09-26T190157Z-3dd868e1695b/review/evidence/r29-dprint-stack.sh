#!/usr/bin/env bash
# R29 revision 1 — the recommended stack executed on a template-shaped fixture:
# dprint 0.57.4 + toml 0.8.0 + json 0.24.0 + markdown 0.24.0 + pretty_yaml 0.6.0,
# configured by fixtures/tree/dprint.json. The only change to that config is that
# each "https://plugins.dprint.dev/…wasm@<sha256>" entry is replaced by the path of
# the module r29-provision.sh built from the same tagged source (the published
# modules are outside the prompt's named endpoints). Needs: r29-provision.sh run
# first; CARGO_HOME holding dprint; python3; actionlint; lefthook; just; cargo.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
plugins="${PLUGIN_OUT:-/tmp/r29-plugins/out}"
: "${CARGO_HOME:?a private CARGO_HOME must be set}"
export PATH="$CARGO_HOME/bin:$PATH"
scratch="$(mktemp -d /tmp/r29-stack.XXXXXX)"
export DPRINT_CACHE_DIR="$scratch/dprint-cache"   # never the user-level cache
w="$scratch/tree"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
expect_exit() { # id desc expected-code command...
  local id="$1" desc="$2" want="$3" got=0; shift 3
  "$@" >"$scratch/last.out" 2>&1 || got=$?
  if [ "$got" = "$want" ]; then ok "$id" "$desc (exit $got)"; else bad "$id" "$desc (exit $got, wanted $want)"; sed 's/^/    | /' "$scratch/last.out" | head -20; fi
}
strip() { sed 's/\x1b\[[0-9;]*m//g' "$1"; }
g() { git -c user.email=r29@example.invalid -c user.name=r29 "$@"; }

# --- stage the fixture as a git repository ---------------------------------
cp -R "$here/fixtures/tree" "$w"
cp "$here/fixtures/gitignore.fixture" "$w/.gitignore"
mkdir -p "$w/target/debug"
printf '{"decoy":   true}\n' >"$w/target/debug/decoy.json"
printf 'a   =   1\n' >"$w/target/debug/decoy.toml"
cd "$w"
python3 - "$plugins" <<'EOF'
import json, re, sys
p = sys.argv[1]
names = {"toml-0.8.0": "toml", "json-0.24.0": "json", "markdown-0.24.0": "markdown", "g-plane/pretty_yaml-v0.6.0": "pretty_yaml"}
s = open("dprint.json").read()
n = 0
for url, local in names.items():
    s, k = re.subn(r'"https://plugins\.dprint\.dev/' + re.escape(url) + r'\.wasm@[0-9a-f]{64}"', '"%s/%s.wasm"' % (p, local), s)
    n += k
assert n == 4, n
open("dprint.json", "w").write(s)
EOF
g init -q && g add -A && g commit -qm authored

echo "host: $(uname -srm); $(dprint --version); python3 $(python3 -c 'import sys;print(sys.version.split()[0])'); $(actionlint -version | head -1); lefthook $(lefthook version); $(just --version); $(cargo --version)"
echo "plugins (built by r29-provision.sh):"; (cd "$plugins" && shasum -a 256 -c SHA256SUMS | sed 's/^/  /')

if [ "$(dprint --version)" = "dprint 0.57.4" ]; then ok D0 "host is dprint 0.57.4"; else bad D0 "host version $(dprint --version)"; fi

sizes="$(python3 - "$plugins" "$here/snapshots" <<'EOF'
import json, os, sys
p, snap = sys.argv[1], sys.argv[2]
rel = {"json": "dprint-plugin-json-release-0.24.0.json", "markdown": "dprint-plugin-markdown-release-0.24.0.json",
       "toml": "dprint-plugin-toml-release-0.8.0.json", "pretty_yaml": "pretty_yaml-release-v0.6.0.json"}
worst, parts = 0.0, []
for k, f in rel.items():
    pub = [a["size"] for a in json.load(open(os.path.join(snap, f)))["assets"] if a["name"] == "plugin.wasm"][0]
    built = os.path.getsize(os.path.join(p, k + ".wasm"))
    worst = max(worst, abs(built / pub - 1)); parts.append("%s %d/%d" % (k, built, pub))
print("%.4f %s" % (worst, "; ".join(parts)))
EOF
)"
echo "    built/published bytes: ${sizes#* }"
if python3 -c "import sys; sys.exit(0 if float('${sizes%% *}') <= 0.031 else 1)"; then ok D0b "every built module is within 3.1% of the published plugin.wasm size (worst ${sizes%% *})"; else bad D0b "size drift ${sizes%% *}"; fi

# --- file ownership and exclusions ------------------------------------------
dprint output-file-paths 2>/dev/null | sed "s#^$(pwd -P)/##; s#^$w/##" | sort >"$scratch/paths"
cat >"$scratch/paths.want" <<'EOF'
.github/dependabot.yml
.github/workflows/ci.yml
.vscode/extensions.json
.vscode/settings.json
Cargo.toml
README.md
docs/guide.md
dprint.json
lefthook.yml
release-please-config.json
rust-toolchain.toml
rustfmt.toml
yaml-cases/block-scalars.yml
EOF
sort -o "$scratch/paths.want" "$scratch/paths.want"
if diff -u "$scratch/paths.want" "$scratch/paths" >"$scratch/d"; then ok D1 "dprint output-file-paths = exactly the 13 covered files"; else bad D1 "file set differs"; cat "$scratch/d"; fi
if ! grep -qxE 'CHANGELOG\.md|\.release-please-manifest\.json|Cargo\.lock|target/.*' "$scratch/paths"; then ok D2 "CHANGELOG.md, .release-please-manifest.json, Cargo.lock and target/ are not covered"; else bad D2 "an excluded file is covered"; fi
if ! dprint output-file-paths --no-gitignore 2>/dev/null | grep -q '/target/'; then ok D2b "target/ stays excluded with --no-gitignore (the **/target entry itself, not .gitignore)"; else bad D2b "target/ covered without gitignore"; fi

# --- authored tree: check fails, fmt converges, meaning preserved -----------
expect_exit D3 "dprint check on the authored tree reports unformatted files" 20 dprint check
dprint check --list-different 2>/dev/null | sed "s#^$(pwd -P)/##; s#^$w/##" | sort >"$scratch/diff-list" || true
echo "    authored files dprint check lists: $(tr '\n' ' ' <"$scratch/diff-list")"
cat >"$scratch/project.py" <<'EOF'
import json, re, sys, tomllib, yaml
out = {}
for f in sys.argv[1:]:
    t = open(f, encoding="utf-8").read()
    if f.endswith((".yml", ".yaml")):
        out[f] = list(yaml.safe_load_all(t))
    elif f.endswith(".toml"):
        out[f] = tomllib.loads(t)
    elif f.endswith(".json"):
        t = re.sub(r"^\s*//.*$", "", t, flags=re.M)      # JSONC line comments (fixture only)
        t = re.sub(r",(\s*[}\]])", r"\1", t)             # JSONC trailing commas (fixture only)
        out[f] = json.loads(t)
def norm(v):  # PyYAML reads `on:` as True (YAML 1.1); keep key types distinct but sortable
    if isinstance(v, dict):
        return {"%s:%s" % (type(k).__name__, k): norm(x) for k, x in v.items()}
    if isinstance(v, list):
        return [norm(x) for x in v]
    return v
print(json.dumps(norm(out), sort_keys=True, default=str))
EOF
parsed=(.github/dependabot.yml .github/workflows/ci.yml lefthook.yml yaml-cases/block-scalars.yml
        Cargo.toml rust-toolchain.toml rustfmt.toml
        .vscode/settings.json .vscode/extensions.json release-please-config.json dprint.json)
python3 "$scratch/project.py" "${parsed[@]}" >"$scratch/before.json"
shasum -a 256 Cargo.lock target/debug/decoy.json target/debug/decoy.toml CHANGELOG.md .release-please-manifest.json >"$scratch/untouched.sha"
expect_exit D4 "dprint fmt rewrites the authored tree" 0 dprint fmt
g diff --name-only | sort >"$scratch/changed"
if diff -q "$scratch/diff-list" "$scratch/changed" >/dev/null && [ "$(wc -l <"$scratch/changed")" -eq 11 ]; then ok D4b "fmt changed exactly the 11 files check listed"; else bad D4b "changed set differs from check list"; fi
python3 "$scratch/project.py" "${parsed[@]}" >"$scratch/after.json"
if cmp -s "$scratch/before.json" "$scratch/after.json"; then ok D5 "parsed data of all 11 YAML/TOML/JSON(C) files is identical before and after fmt"; else bad D5 "a file's parsed data changed"; fi
if shasum -a 256 -c "$scratch/untouched.sha" >/dev/null 2>&1; then ok D5b "Cargo.lock, target/ decoys, CHANGELOG.md and .release-please-manifest.json are byte-identical after fmt"; else bad D5b "an excluded file changed"; fi
expect_exit D6 "dprint check on the formatted tree" 0 dprint check
g add -A && g commit -qm formatted
dprint fmt >/dev/null 2>&1
if g diff --quiet; then ok D7 "second dprint fmt is a no-op (idempotent)"; else bad D7 "second fmt changed files"; g diff --stat; fi

# --- Cargo.toml conventions vs the Rust Style Guide --------------------------
python3 - >"$scratch/cargo-order" <<'EOF'
import re
sec, keys = None, {}
for line in open("Cargo.toml"):
    m = re.match(r"^\[([^\]]+)\]\s*$", line)
    if m: sec = m.group(1); keys[sec] = []; continue
    m = re.match(r"^([A-Za-z0-9_-]+)\s*=", line)
    if m and sec: keys[sec].append(m.group(1))
print(",".join(keys["package"])); print(",".join(keys["dependencies"]))
EOF
echo "    [package] order: $(sed -n 1p "$scratch/cargo-order"); [dependencies] order: $(sed -n 2p "$scratch/cargo-order")"
if [ "$(sed -n 1p "$scratch/cargo-order")" = "name,version,edition,include,license,rust-version,description" ]; then ok D8 "[package]: name, version first, description last, the rest sorted (Style Guide cargo.md:11-15)"; else bad D8 "package order"; fi
if [ "$(sed -n 2p "$scratch/cargo-order")" = "anyhow,clap,serde" ]; then ok D8b "[dependencies] version-sorted"; else bad D8b "dependency order"; fi
expect_exit D9 "cargo metadata --no-deps --offline accepts the rewritten manifest" 0 cargo metadata --no-deps --offline --format-version 1
if cargo metadata --no-deps --offline --format-version 1 2>/dev/null | python3 -c 'import json,sys;p=json.load(sys.stdin)["packages"][0];t=sorted((x["name"],x["kind"][0]) for x in p["targets"]);sys.exit(0 if p["name"]=="rs-launch-blueprint" and p["rust_version"]=="1.96" and t==[("rs_launch_blueprint","lib"),("rslbp","bin")] else 1)'; then ok D9b "manifest still declares package rs-launch-blueprint, rust-version 1.96, lib + bin rslbp"; else bad D9b "manifest meaning changed"; fi

# --- YAML: pretty_yaml#4 block scalars, workflow semantics ------------------
if cmp -s <(sed -n 1,17p "$here/fixtures/tree/yaml-cases/block-scalars.yml") <(sed -n 1,17p yaml-cases/block-scalars.yml); then ok D10 "block scalars (#4 case, |+, |-, >) and the anchor block are byte-identical after fmt"; else bad D10 "block-scalar bytes changed"; fi
# shellcheck disable=SC2016 # literal Python source; "${{ matrix.os }}" is YAML data, not a shell expansion
if python3 -c 'import yaml,sys;d=yaml.safe_load(open("yaml-cases/block-scalars.yml"));sys.exit(0 if (d["a"],d["b"],d["keep"],d["strip"],d["folded"],d["job"]["retries"],d["job"]["expr"])==("hello\nworld\n","hello\nworld\n","kept\n\n","stripped","folded text\n",3,"${{ matrix.os }}") else 1)'; then ok D10b "block-scalar values keep their final line breaks and chomping; merge key and \${{ }} survive"; else bad D10b "block-scalar values"; fi
expect_exit D11 "actionlint accepts the formatted workflow (hygiene step = dprint check)" 0 actionlint .github/workflows/ci.yml
expect_exit D12 "lefthook validate accepts the formatted lefthook.yml" 0 lefthook validate

# --- Markdown -----------------------------------------------------------------
if grep -qxF '{ "a": 1, "b": [1, 2] }' README.md && grep -qxF 'name = "demo"' README.md; then ok D13 "README fenced json and toml blocks are formatted by the json and toml plugins"; else bad D13 "fenced blocks"; fi
if grep -qxF 'Some prose that stays as written.' docs/guide.md && grep -qxF '1. second' docs/guide.md; then ok D13b "prose is not reflowed (textWrap maintain); ordered-list numbering kept"; else bad D13b "prose changed"; fi

# --- Justfile recipes (bare executable per R42) -------------------------------
expect_exit D14 "just check-files on the formatted tree" 0 just check-files

# --- perturbations: one per family -----------------------------------------
sed -i '' 's/^pre-commit:$/pre-commit:  /' lefthook.yml
python3 - <<'EOF'
s = open("Cargo.toml").read()
dep_a, dep_c = 'anyhow = "1"\n', 'clap = { version = "4", features = ["derive"] }\n'
assert dep_a + dep_c in s
s = s.replace(dep_a + dep_c, dep_c + dep_a, 1)                # dependencies out of order
open("Cargo.toml", "w").write(s)
s = open("release-please-config.json").read().replace('\n  "packages"', '\n      "packages"', 1)
open("release-please-config.json", "w").write(s)
s = open("docs/guide.md").read().replace("1. second", "1.  second", 1)
open("docs/guide.md", "w").write(s)
EOF
g diff --name-only | sort >"$scratch/perturbed"
expect_exit D15 "dprint check after one perturbation per family" 20 dprint check
dprint check --list-different 2>/dev/null | sed "s#^$(pwd -P)/##; s#^$w/##" | sort >"$scratch/listed" || true
if [ "$(wc -l <"$scratch/perturbed")" -eq 4 ] && cmp -s "$scratch/perturbed" "$scratch/listed"; then ok D15b "check names exactly the 4 perturbed files: $(tr '\n' ' ' <"$scratch/listed")"; else bad D15b "listed: $(tr '\n' ' ' <"$scratch/listed") perturbed: $(tr '\n' ' ' <"$scratch/perturbed")"; fi
expect_exit D15c "just check-files fails on the perturbed tree, propagating dprint's code" 20 just check-files
g checkout -q -- .

# --- release-please outputs: why they are excluded ---------------------------
expect_exit D16 "release-please's CHANGELOG.md bytes fail check when the exclusion is removed" 20 dprint check --excludes-override='**/target' CHANGELOG.md
expect_exit D16b "the release-please manifest passes check even unexcluded (its exclusion is precautionary)" 0 dprint check --excludes-override='**/target' .release-please-manifest.json
expect_exit D17 "check given only an excluded file, without --allow-no-files" 14 dprint check CHANGELOG.md
expect_exit D17b "the same with --allow-no-files" 0 dprint check --allow-no-files CHANGELOG.md

# --- checksum pins ------------------------------------------------------------
zero=0000000000000000000000000000000000000000000000000000000000000000
jsum="$(shasum -a 256 "$plugins/json.wasm" | cut -d' ' -f1)"
cp dprint.json "$scratch/dprint.json.keep"
sed -i '' "s#$plugins/json.wasm\"#$plugins/json.wasm@$zero\"#" dprint.json
DPRINT_CACHE_DIR="$scratch/cold-1" expect_exit D18 "cold cache: a wrong @sha256 on the json plugin is refused" 12 dprint check
if grep -q 'Invalid checksum specified in configuration file' "$scratch/last.out"; then ok D18b "refusal message names the invalid checksum"; else bad D18b "no checksum message"; fi
sed -i '' "s#json.wasm@$zero\"#json.wasm@$jsum\"#" dprint.json
DPRINT_CACHE_DIR="$scratch/cold-2" expect_exit D18c "cold cache: the correct @sha256 is accepted" 0 dprint check
sed -i '' "s#json.wasm@$jsum\"#json.wasm@$zero\"#" dprint.json
DPRINT_CACHE_DIR="$scratch/cold-2" expect_exit D18d "warm cache: the same wrong @sha256 is NOT re-verified (observed; CI's cacheless hygiene resolves cold every run)" 0 dprint check
cp "$scratch/dprint.json.keep" dprint.json

cd /
rm -rf "$scratch"
printf 'r29-dprint-stack: PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
