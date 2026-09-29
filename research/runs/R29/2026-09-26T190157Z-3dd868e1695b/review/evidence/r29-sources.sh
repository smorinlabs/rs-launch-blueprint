#!/usr/bin/env bash
# R29 revision 1 — source-level adjudications, offline, over the snapshots that
# r29-snapshots.sh captured (endpoint + UTC time per file in snapshots/PROVENANCE.tsv).
# Each check prints PASS/FAIL with its id; the script exits non-zero on any FAIL.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
# py <id> <description> <python-body>: the body must print exactly "ok".
py() {
  local id="$1" desc="$2" out
  out="$(SNAP="$snap" python3 -c "import json,os,re,sys
S=os.environ['SNAP']
def J(f): return json.load(open(os.path.join(S,f)))
def T(f): return open(os.path.join(S,f),encoding='utf-8').read()
def L(f,n): return T(f).split('\n')[n-1]
$3" 2>&1)" || true
  if [ "$out" = ok ]; then ok "$id" "$desc"; else bad "$id" "$desc :: $out"; fi
}

echo "snapshot set: $(($(wc -l <"$snap/PROVENANCE.tsv") - 1)) entries; retrieval window:"
awk -F'\t' 'NR>1 {print $3}' "$snap/PROVENANCE.tsv" | sort | sed -n '1p;$p'

# --- taplo maintenance (Disagreement A) --------------------------------------
py S1a "taplo#715 is the owner's own thread, closed" '
i=J("taplo-issue-715.json"); print("ok" if i["user"]["login"]=="tamasfe" and i["author_association"]=="OWNER" and i["state"]=="closed" and i["title"]=="The future of the project" else i["state"])'
py S1b "owner comment 3513470749 (2025-11-10): plans no longer exist" '
c={x["id"]:x for x in J("taplo-issue-715-comments.json")}[3513470749]
print("ok" if c["user"]["login"]=="tamasfe" and c["created_at"].startswith("2025-11-10") and "Whatever plans I had with this project do not really exist anymore" in c["body"] else c["body"][:80])'
py S1c "owner comment 3516463115 (2025-11-11): 'destined to eventually die'" '
c={x["id"]:x for x in J("taplo-issue-715-comments.json")}[3516463115]
print("ok" if c["user"]["login"]=="tamasfe" and "it is destined to eventually die" in c["body"] and "the code is unmaintainable as-is" in c["body"] else c["body"][:80])'
py S1d "owner comment 3524761328 (2025-11-13): 'I don't want to be involved anymore'" '
c={x["id"]:x for x in J("taplo-issue-715-comments.json")}[3524761328]
print("ok" if c["user"]["login"]=="tamasfe" and c["created_at"].startswith("2025-11-13") and "I don'"'"'t want to be involved anymore" in c["body"] else c["body"][:80])'
py S1e "collaborator panekj 4106765129 (2026-03-22): keeps merging and releasing 'as long as I can'" '
c={x["id"]:x for x in J("taplo-issue-715-comments.json")}[4106765129]
print("ok" if c["user"]["login"]=="panekj" and c["author_association"]=="COLLABORATOR" and c["created_at"].startswith("2026-03-22") and "keep merging and creating new releases here as long as I can" in c["body"] else c["body"][:80])'
py S1f "taplo-cli newest unyanked release is still 0.10.0 of 2025-05-23; repo not archived, pushed 2026-07-28" '
d=J("crates-taplo-cli.json"); v=[x for x in d["versions"] if not x["yanked"]][0]; r=J("repo-tamasfe-taplo.json")
print("ok" if (v["num"],v["created_at"][:10],v["rust_version"])==("0.10.0","2025-05-23","1.74") and r["archived"] is False and r["pushed_at"].startswith("2026-07-28") and r["stargazers_count"]==2402 else (v["num"],r["pushed_at"]))'

# --- provisioning through R42's install-tool (cargo binstall 1.23.0) --------
py S2a "binstall v1.23.0 default templates include '{ repo }/releases/download/{ version }' + '/{ name }-{ target }{ archive-suffix }'" '
t=T("binstall-hosting.rs"); print("ok" if "template!(\"{ repo }/releases/download/{ version }\")" in t and "template!(\"/{ name }-{ target }{ archive-suffix }\")" in t else "missing")'
py S2b "dprint 0.57.4 release carries dprint-<target>.zip for both matrix runners' targets (a binstall template match)" '
names={a["name"] for a in J("dprint-release-0.57.4.json")["assets"]}
need={"dprint-x86_64-unknown-linux-gnu.zip","dprint-aarch64-apple-darwin.zip","dprint-x86_64-apple-darwin.zip"}
print("ok" if need<=names and "SHASUMS256.txt" in names else sorted(need-names))'
py S2c "taplo 0.10.0 release assets carry no target triple and no 'taplo-cli' prefix, so no binstall template can name them" '
names=[a["name"] for a in J("taplo-release-0.10.0.json")["assets"]]
triples=("x86_64-unknown-linux-gnu","aarch64-apple-darwin","x86_64-apple-darwin")
print("ok" if len(names)==13 and not any(t in n for n in names for t in triples) and not any(n.startswith("taplo-cli") for n in names) and "taplo-linux-x86_64.gz" in names else names)'
py S2d "dprint crate manifest has no [package.metadata.binstall] stanza (binstall uses its defaults)" '
print("ok" if "binstall" not in T("dprint-crate-Cargo.toml") and "wasmtime = { version = \"=43.0.2\"" in T("dprint-crate-Cargo.toml") else "found")'

# --- dprint behaviour claims ------------------------------------------------
# shellcheck disable=SC2016 # literal Python source quoting Markdown backticks, not a shell expansion
py S3a "dprint cli.md:222-223 — exit 14 no files (0 with --allow-no-files), exit 20 unformatted" '
print("ok" if L("dprint-cli.md",222).startswith("- `14` - No files found error") and "--allow-no-files" in L("dprint-cli.md",222) and L("dprint-cli.md",223).startswith("- `20` - `dprint check` found non-formatted files") else [L("dprint-cli.md",222)])'
py S3b "dprint config.md:42 plugins may be URLs or file paths; :100 Wasm plugins get no checksum by default" '
print("ok" if "These may be URLs or file paths to a WebAssembly file of the plugin." in L("dprint-config.md",42) and L("dprint-config.md",100).startswith("By default Wasm plugins are added without a checksum") else "mismatch")'
py S3c "dprint/dprint's own dprint.json uses npm: specifiers (toml :26, yaml :30), no plugins.dprint.dev URL; the only @sha is the exec process plugin (:27)" '
f="dprint-dprint.json"
print("ok" if L(f,26).strip()=="\"npm:@dprint/toml@0.8.0\"," and L(f,30).strip()=="\"npm:dprint-plugin-yaml@0.6.0\"," and "plugins.dprint.dev" not in T(f) and L(f,27).strip().startswith("\"npm:@dprint/exec@0.7.3/plugin.json@") and len(re.findall(r"@[0-9a-f]{64}",T(f)))==1 else "mismatch")'
py S3d "deno .dprint.json:91-95 — json-0.21.3, markdown-0.21.1, toml-0.7.0, pretty_yaml-v0.6.0 via plugins.dprint.dev" '
f="deno-dprint.json"
print("ok" if "json-0.21.3.wasm" in L(f,91) and "markdown-0.21.1.wasm" in L(f,92) and "toml-0.7.0.wasm" in L(f,93) and "g-plane/pretty_yaml-v0.6.0.wasm" in L(f,95) else "mismatch")'
py S3e "rustup ci.yaml:1682/1686/1689 installs taplo+oxfmt and runs 'oxfmt . --check' and 'taplo fmt'" '
f="rustup-ci.yaml"
print("ok" if L(f,1682).strip()=="tool: taplo,oxfmt" and L(f,1686).strip()=="oxfmt . --check" and L(f,1689).strip()=="taplo fmt" else "mismatch")'

# --- TOML conventions (Disagreement H) --------------------------------------
# shellcheck disable=SC2016 # literal Python source quoting Markdown backticks, not a shell expansion
py S4a "Rust Style Guide cargo.md:5 and :11-15 — same indentation as Rust; name, version first, description last; version-sort other sections" '
f="style-guide-cargo.md"
t=" ".join(L(f,n) for n in range(11,16))
print("ok" if L(f,5)=="Use the same line width and indentation as Rust code." and "Version-sort key names within each section, with the exception of the" in t and "the `description` at the end of that section." in t else "mismatch")'
py S4b "dprint-plugin-toml 0.8.0 resolve_config.rs:70 — cargo.applyConventions defaults to true; cargo.rs:13 keys on the file name Cargo.toml" '
print("ok" if "\"cargo.applyConventions\", true" in L("dprint-plugin-toml-resolve_config.rs",70) and "n == \"Cargo.toml\"" in L("dprint-plugin-toml-cargo.rs",13) else "mismatch")'

# --- YAML member (Disagreement G) -------------------------------------------
py S5a "pretty_yaml#4 (block-scalar final line break) is open, filed 2024-12-16, zero comments" '
i=J("pretty_yaml-issue-4.json")
print("ok" if i["state"]=="open" and i["created_at"].startswith("2024-12-16") and i["comments"]==0 and len(J("pretty_yaml-issue-4-comments.json"))==0 else (i["state"],i["comments"]))'
py S5b "pretty_yaml v0.6.0 dprint wrapper is package dprint_plugin_yaml, publish = false, cdylib" '
t=T("pretty_yaml-dprint_plugin-Cargo.toml")
print("ok" if "name = \"dprint_plugin_yaml\"" in t and "publish = false" in t and "\"cdylib\"" in t and "description = \"pretty_yaml as dprint plugin.\"" in t else "mismatch")'
py S5c "crates.io has no crate named yamlfmt or dprint-plugin-yaml (both 404)" '
p={l.split("\t")[0]:l.split("\t")[3] for l in T("PROVENANCE.tsv").splitlines()[1:]}
print("ok" if p["crates-yamlfmt.json"]=="404" and p["crates-dprint-plugin-yaml.json"]=="404" else p)'

# --- checksum pins (gap both legs recorded) ---------------------------------
py S6 "the four @sha256 pins in fixtures/tree/dprint.json equal the api.github.com release digests of plugin.wasm" '
cfg=json.load(open(os.path.join(S,"..","fixtures","tree","dprint.json")))
pins={u.split("@")[0]:u.split("@")[1] for u in cfg["plugins"]}
want={"https://plugins.dprint.dev/toml-0.8.0.wasm":"dprint-plugin-toml-release-0.8.0.json",
      "https://plugins.dprint.dev/json-0.24.0.wasm":"dprint-plugin-json-release-0.24.0.json",
      "https://plugins.dprint.dev/markdown-0.24.0.wasm":"dprint-plugin-markdown-release-0.24.0.json",
      "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm":"pretty_yaml-release-v0.6.0.json"}
bad=[u for u,f in want.items() if [a["digest"] for a in J(f)["assets"] if a["name"]=="plugin.wasm"]!=["sha256:"+pins.get(u,"")]]
print("ok" if not bad and len(pins)==4 else bad)'

# --- release-please CHANGELOG shape (Disagreement D) -------------------------
py S7 "fixture CHANGELOG.md is the first 12 lines of release-please's own generated CHANGELOG.md, with its double blank line and '*' bullets" '
src=T("release-please-CHANGELOG.md"); fx=open(os.path.join(S,"..","fixtures","tree","CHANGELOG.md"),encoding="utf-8").read()
print("ok" if src.startswith(fx) and fx.count("\n")==12 and "\n\n\n### " in fx and "\n* " in fx else "mismatch")'

# --- figures quoted in DECISION.md ------------------------------------------
py S8 "crates.io figures (recent 90-day / all-time / newest unyanked / date) as quoted in DECISION.md" '
want={"dprint":(11573,239963,"0.57.4","2026-09-05"),"dprint-plugin-json":(159493,869002,"0.24.0","2026-09-15"),
"dprint-plugin-markdown":(148650,904256,"0.24.0","2026-09-10"),"dprint-plugin-toml":(2223,19633,"0.8.0","2026-08-18"),
"pretty_yaml":(241855,840275,"0.6.0","2026-01-09"),"taplo-cli":(194730,2224667,"0.10.0","2025-05-23"),
"rumdl":(23634,111384,"0.2.77","2026-09-23"),"tombi-cli":(80,1032,"0.0.1","2025-03-13")}
got={}
for k in want:
  d=J("crates-%s.json"%k); v=[x for x in d["versions"] if not x["yanked"]][0]
  got[k]=(d["crate"]["recent_downloads"],d["crate"]["downloads"],v["num"],v["created_at"][:10])
print("ok" if got==want else {k:got[k] for k in want if got[k]!=want[k]})'
py S9 "GitHub repo figures: stars / archived / pushed_at as quoted in DECISION.md" '
want={"repo-dprint-dprint.json":(4079,False,"2026-09-15"),"repo-g-plane-pretty_yaml.json":(52,False,"2026-08-26"),
"repo-dprint-dprint-plugin-toml.json":(24,False,"2026-09-05"),"repo-tamasfe-taplo.json":(2402,False,"2026-07-28")}
got={f:(J(f)["stargazers_count"],J(f)["archived"],J(f)["pushed_at"][:10]) for f in want}
print("ok" if got==want else got)'
py S10 "rustsec.org: no package page for any recommended or compared crate (404); control page time.html is 200" '
p={l.split("\t")[0]:l.split("\t")[3] for l in T("PROVENANCE.tsv").splitlines()[1:]}
ks=["rustsec-"+k for k in ("dprint","dprint-plugin-json","dprint-plugin-markdown","dprint-plugin-toml","pretty_yaml","taplo","taplo-cli")]
print("ok" if all(p[k]=="404" for k in ks) and p["rustsec-time"]=="200" else {k:p[k] for k in ks+["rustsec-time"]})'

printf 'r29-sources: PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
