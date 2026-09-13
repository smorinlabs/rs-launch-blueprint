#!/usr/bin/env bash
# R81 docs-delivery-model — claim verification. Verifies claims made by the two
# raw reports; implements nothing. No book is built, no generator initialised,
# no site deployed, no tool installed.
#
# Run from the run directory:
#   research/runs/R81/2026-09-05T183003Z-c02279aa76ae
#   bash review/evidence/docs-delivery-claims.sh > review/evidence/docs-delivery-claims.log 2>&1
#
# Output is assertion-shaped on purpose: PASS/FAIL plus stable fields only.
# No volatile counter (stars, downloads, pushed_at, open issues) is printed.
set -u
set -o pipefail

UA='rs-launch-blueprint-research/1.0 (https://github.com/smorinlabs/rs-launch-blueprint)'
REPO_ROOT=$(cd "$(dirname "$0")/../../../../../.." && pwd)
EV=$(cd "$(dirname "$0")" && pwd)
SNAP="$EV/snapshots"
mkdir -p "$SNAP"
FAILS=0

say()  { printf '%s\n' "$*"; }
hdr()  { printf '\n=== %s ===\n' "$*"; }
assert() { # assert <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'PASS  %-58s %s\n' "$1" "$3"
  else printf 'FAIL  %-58s expected=%s actual=%s\n' "$1" "$2" "$3"; FAILS=$((FAILS+1)); fi
}
assert_has() { # assert_has <label> <file> <substring>
  if grep -Fq -- "$3" "$2"; then printf 'PASS  %-58s present\n' "$1"
  else printf 'FAIL  %-58s MISSING: %s\n' "$1" "$3"; FAILS=$((FAILS+1)); fi
}

# tag-stripping normalizer, so assertions read rendered text not HTML
cat > "$SNAP/.norm.py" <<'PY'
import re,html,sys
t=open(sys.argv[1],encoding='utf-8',errors='replace').read()
t=re.sub(r'<(script|style)[^>]*>.*?</\1>',' ',t,flags=re.S|re.I)
t=re.sub(r'<[^>]+>',' ',t); t=html.unescape(t); t=re.sub(r'\s+',' ',t)
sys.stdout.write(t)
PY

# ---------------------------------------------------------------- check 1
hdr "check 1 — toolchain and host"
say "rustc: $(rustc --version)"
say "cargo: $(cargo --version)"
say "gh:    $(gh --version | head -1)"
say "uname: $(uname -srm)"
say "os:    $(sw_vers -productName) $(sw_vers -productVersion)"

# ---------------------------------------------------------------- check 2
hdr "check 2 — crates.io newest unyanked version, licence, rust_version"
cat > "$SNAP/.cratelic.py" <<'PY'
import json,sys,time,urllib.request,urllib.error
ua=sys.argv[1]
def get(u):
    # crates.io rate-limits; back off and retry rather than reporting a false negative
    for attempt in range(6):
        try:
            return json.load(urllib.request.urlopen(urllib.request.Request(u,headers={"User-Agent":ua})))
        except urllib.error.HTTPError as e:
            if e.code!=429 or attempt==5: raise
            time.sleep(5*(attempt+1))
for name in sys.argv[2:]:
    u="https://crates.io/api/v1/crates/%s/versions"%name
    d=get(u); time.sleep(1.0)
    vs=[v for v in d.get("versions",[]) if not v["yanked"]]
    if vs:
        v=vs[0]
        print("%-18s newest_unyanked=%-9s license=%-9s rust_version=%s"%(name,v["num"],v.get("license"),v.get("rust_version")))
    else:
        a=d.get("versions",[])
        print("%-18s NO_UNYANKED total_versions=%d newest=%s yanked=%s"%(name,len(a),a[0]["num"] if a else "-",a[0]["yanked"] if a else "-"))
PY
python3 "$SNAP/.cratelic.py" "$UA" mdbook cobalt-bin mdbook-mermaid mdbook-admonish mdbook-alerts zola > "$SNAP/.crates.txt"
st=$?; cat "$SNAP/.crates.txt"; assert "crates.io query exit" "0" "$st"
assert_has "mdbook 0.5.4 is MPL-2.0"            "$SNAP/.crates.txt" "mdbook             newest_unyanked=0.5.4     license=MPL-2.0   rust_version=1.88.0"
assert_has "cobalt-bin is MIT (permissive Rust SSG)" "$SNAP/.crates.txt" "cobalt-bin         newest_unyanked=0.20.4    license=MIT"
assert_has "mdbook-mermaid is MPL-2.0"          "$SNAP/.crates.txt" "mdbook-mermaid     newest_unyanked=0.17.1    license=MPL-2.0"
assert_has "mdbook-admonish 1.20.0 is MIT"      "$SNAP/.crates.txt" "mdbook-admonish    newest_unyanked=1.20.0    license=MIT"
assert_has "mdbook-alerts 0.8.0 is MIT"         "$SNAP/.crates.txt" "mdbook-alerts      newest_unyanked=0.8.0     license=MIT"
assert_has "zola registry entry is a yanked placeholder" "$SNAP/.crates.txt" "zola               NO_UNYANKED total_versions=1 newest=0.1.1 yanked=True"

# ---------------------------------------------------------------- check 3
hdr "check 3 — GitHub repository licence and archived flag"
for r in rust-lang/mdBook getzola/zola lambdalisue/rs-mdbook-alerts badboy/mdbook-mermaid \
         actions/configure-pages actions/upload-pages-artifact actions/deploy-pages; do
  line=$(gh api "repos/$r" --jq '"\(.license.spdx_id) archived=\(.archived)"') || { say "FAIL  gh api repos/$r"; FAILS=$((FAILS+1)); continue; }
  printf '%-34s %s\n' "$r" "$line"
done
assert "rust-lang/mdBook licence"     "MPL-2.0"  "$(gh api repos/rust-lang/mdBook --jq '.license.spdx_id')"
assert "rust-lang/mdBook archived"    "false"    "$(gh api repos/rust-lang/mdBook --jq '.archived')"
assert "getzola/zola licence"         "EUPL-1.2" "$(gh api repos/getzola/zola --jq '.license.spdx_id')"
assert "getzola/zola archived"        "false"    "$(gh api repos/getzola/zola --jq '.archived')"
assert "rs-mdbook-alerts licence"     "MIT"      "$(gh api repos/lambdalisue/rs-mdbook-alerts --jq '.license.spdx_id')"
assert "rs-mdbook-alerts archived"    "true"     "$(gh api repos/lambdalisue/rs-mdbook-alerts --jq '.archived')"
assert "mdbook-mermaid repo licence"  "MPL-2.0"  "$(gh api repos/badboy/mdbook-mermaid --jq '.license.spdx_id')"
assert "mdbook-mermaid archived"      "false"    "$(gh api repos/badboy/mdbook-mermaid --jq '.archived')"
for a in configure-pages upload-pages-artifact deploy-pages; do
  assert "actions/$a licence" "MIT" "$(gh api "repos/actions/$a" --jq '.license.spdx_id')"
  assert "actions/$a archived" "false" "$(gh api "repos/actions/$a" --jq '.archived')"
done

# ---------------------------------------------------------------- check 4
hdr "check 4 — RustSec"
assert "rustsec.org/packages/mdbook.html"         "200" "$(curl -sS -o /dev/null -w '%{http_code}' https://rustsec.org/packages/mdbook.html)"
assert "rustsec.org/packages/mdbook-mermaid.html" "404" "$(curl -sS -o /dev/null -w '%{http_code}' https://rustsec.org/packages/mdbook-mermaid.html)"
curl -sS -o "$SNAP/RUSTSEC-2021-0001.md" https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/mdbook/RUSTSEC-2021-0001.md
assert "RUSTSEC-2021-0001 fetch exit" "0" "$?"
assert_has "RUSTSEC-2021-0001 patched range" "$SNAP/RUSTSEC-2021-0001.md" 'patched = [">= 0.4.5"]'

# ---------------------------------------------------------------- check 5
hdr "check 5 — mdBook maintainer documentation (snapshots in evidence/snapshots/)"
fetch_norm() { # fetch_norm <path>
  local p="$1" f
  f=$(printf '%s' "$p" | tr '/' '_')
  curl -sS -o "$SNAP/$f" "https://rust-lang.github.io/mdBook/$p" || return 1
  python3 "$SNAP/.norm.py" "$SNAP/$f" > "$SNAP/n_$f" || return 1
  printf '%s\n' "$SNAP/n_$f"
}
M=$(fetch_norm format/markdown.html)            || { say "FAIL fetch markdown.html"; FAILS=$((FAILS+1)); }
S=$(fetch_norm format/summary.html)             || { say "FAIL fetch summary.html"; FAILS=$((FAILS+1)); }
G=$(fetch_norm format/configuration/general.html) || { say "FAIL fetch general.html"; FAILS=$((FAILS+1)); }
I=$(fetch_norm cli/init.html)                   || { say "FAIL fetch init.html"; FAILS=$((FAILS+1)); }
C=$(fetch_norm guide/creating.html)             || { say "FAIL fetch creating.html"; FAILS=$((FAILS+1)); }
K=$(fetch_norm continuous-integration.html)     || { say "FAIL fetch ci.html"; FAILS=$((FAILS+1)); }
assert_has "md->html link conversion + GitHub motivation" "$M" "Relative links that end with .md will be converted to the .html extension. It is recommended to use .md links when possible. This is useful when viewing the Markdown file outside of mdBook, for example on GitHub"
assert_has "README.md -> index.html conversion"           "$M" "Links to README.md will be converted to index.html"
assert_has "admonitions use GitHub alert syntax"          "$M" "[!NOTE]"
assert_has "admonition family: CAUTION"                   "$M" "[!CAUTION]"
assert_has "definition lists documented"                  "$M" "Definition lists can be used for things like glossary entries"
assert_has "definition-lists disable switch"              "$M" "definition-lists"
assert_has "heading attributes syntax"                    "$M" "Example heading { #first .class1 .class2 }"
assert_has "SUMMARY.md is mandatory"                      "$S" "Without this file, there is no book"
assert_has "[book] src is configurable"                   "$G" "configurable with the src key in the configuration file"
assert_has "create-missing documented"                    "$G" "create-missing"
assert_has "mdBook default code edition is 2015"          "$G" 'edition = "2015"'
assert_has "--theme copies MPL theme into the tree"       "$I" "the default theme will be copied into a directory called theme"
assert_has "non-chapter files are copied to output"       "$C" "All other files in the src directory will be included in the output"
assert_has "CI guidance: prebuilt binary is fast"         "$K" "does not necessarily require dealing with caching"
assert_has "CI guidance: --no-default-features drops serve" "$K" "Disables features like the HTTP server used by mdbook serve"

# ---------------------------------------------------------------- check 6
hdr "check 6 — GitHub's own renderer on the dialect (POST /markdown, mode=gfm)"
printf '%s\n' '> [!NOTE]' '> hello' '' '# Head { #id .cls }' '' 'term' ': definition' '' '[link](./other.md)' '' '```mermaid' 'graph TD; A-->B;' '```' > "$SNAP/.dialect-probe.md"
python3 - "$SNAP/.dialect-probe.md" > "$SNAP/.dialect-probe.json" <<'PY'
import json,sys
print(json.dumps({"text":open(sys.argv[1]).read(),"mode":"gfm"}))
PY
gh api -X POST markdown --input "$SNAP/.dialect-probe.json" > "$SNAP/dialect-probe.html"
assert "POST /markdown exit" "0" "$?"
cat "$SNAP/dialect-probe.html"
assert_has "alert renders as a GitHub callout"        "$SNAP/dialect-probe.html" 'class="markdown-alert markdown-alert-note"'
assert_has "heading attributes render literally"      "$SNAP/dialect-probe.html" '>Head { #id .cls }</h1>'
assert_has "definition list renders literally"        "$SNAP/dialect-probe.html" ': definition'
assert_has "relative .md link href preserved"         "$SNAP/dialect-probe.html" 'href="./other.md"'

# ---------------------------------------------------------------- check 7
hdr "check 7 — adopters running mdBook through the first-party Pages triple"
gh api repos/rust-lang/goals/git/blobs/4dce369a600e57b9cae2e2a5b3edca0a27942ecc --jq '.content' | base64 -d > "$SNAP/goals-mdbook.yml"
assert "goals blob fetch exit" "0" "$?"
gh api repos/Spotifyd/spotifyd/git/blobs/8dfc018421bca766fe7c1d772b5a6dfc3c1a1bd3 --jq '.content' | base64 -d > "$SNAP/spotifyd-docs.yml"
assert "spotifyd blob fetch exit" "0" "$?"
for f in goals-mdbook.yml spotifyd-docs.yml; do
  say "-- $f"
  grep -nE 'mdbook|actions/(configure-pages|upload-pages-artifact|deploy-pages)' "$SNAP/$f" | sed 's/^/   /'
done
assert_has "goals: mdbook installed and run"   "$SNAP/goals-mdbook.yml" 'cargo install --version ${MDBOOK_VERSION} mdbook'
assert "goals: configure-pages present"     "1" "$(grep -c 'actions/configure-pages@' "$SNAP/goals-mdbook.yml")"
assert "goals: upload-pages-artifact"       "1" "$(grep -c 'actions/upload-pages-artifact@' "$SNAP/goals-mdbook.yml")"
assert "goals: deploy-pages present"        "1" "$(grep -c 'actions/deploy-pages@' "$SNAP/goals-mdbook.yml")"
assert "spotifyd: configure-pages present"  "1" "$(grep -c 'actions/configure-pages@' "$SNAP/spotifyd-docs.yml")"
assert "spotifyd: upload-pages-artifact"    "1" "$(grep -c 'actions/upload-pages-artifact@' "$SNAP/spotifyd-docs.yml")"
assert "spotifyd: deploy-pages present"     "1" "$(grep -c 'actions/deploy-pages@' "$SNAP/spotifyd-docs.yml")"
assert_has "spotifyd: mdbook installed and run" "$SNAP/spotifyd-docs.yml" 'cargo install --version ${MDBOOK_VERSION} mdbook'
say "goals action pins: $(grep -oE 'actions/(configure-pages|upload-pages-artifact|deploy-pages)@v[0-9]+' "$SNAP/goals-mdbook.yml" | sort | tr '\n' ' ')"
say "spotifyd action pins: $(grep -oE 'actions/(configure-pages|upload-pages-artifact|deploy-pages)@v[0-9]+' "$SNAP/spotifyd-docs.yml" | sort | tr '\n' ' ')"
# The decision says the adopters' pinned majors differ from the ones opus recommends
# (v6.0.0/v5.0.0/v5.0.1). Assert the pins, so that claim is failure-gated too.
assert "goals pins (sorted)" "actions/configure-pages@v5 actions/deploy-pages@v4 actions/upload-pages-artifact@v3" \
  "$(grep -oE 'actions/(configure-pages|upload-pages-artifact|deploy-pages)@v[0-9]+' "$SNAP/goals-mdbook.yml" | sort | tr '\n' ' ' | sed 's/ *$//')"
assert "spotifyd pins (sorted)" "actions/configure-pages@v3 actions/deploy-pages@v4 actions/upload-pages-artifact@v3" \
  "$(grep -oE 'actions/(configure-pages|upload-pages-artifact|deploy-pages)@v[0-9]+' "$SNAP/spotifyd-docs.yml" | sort | tr '\n' ' ' | sed 's/ *$//')"
assert "no adopter pins configure-pages@v6" "0" "$(grep -c 'actions/configure-pages@v6' "$SNAP/goals-mdbook.yml" "$SNAP/spotifyd-docs.yml" | awk -F: '{s+=$2} END{print s}')"
assert "goals pinned run 34280395920 conclusion" "success" "$(gh api repos/rust-lang/goals/actions/runs/34280395920 --jq '.conclusion')"
assert "goals pinned run event"                  "push"    "$(gh api repos/rust-lang/goals/actions/runs/34280395920 --jq '.event')"
assert "goals Pages build_type"                  "workflow" "$(gh api repos/rust-lang/goals/pages --jq '.build_type')"
assert "goals Pages html_url"  "https://goals.rust-lang.org/" "$(gh api repos/rust-lang/goals/pages --jq '.html_url')"
assert "published site responds" "200" "$(curl -sS -o /dev/null -w '%{http_code}' https://goals.rust-lang.org/)"

# ---------------------------------------------------------------- check 8
# Licence walk over the resolved dependency tree of mdbook = "=0.5.4".
# The full walk (one crates.io request per package, 0.12s apart) was run once on
# 2026-09-10 and its result is the committed snapshot
# evidence/mdbook-0.5.4-licences.json. crates.io rate-limits a 218-request sweep,
# so by default this check recomputes the summary from that snapshot and
# re-queries a fixed 16-package sample live, asserting each matches the snapshot.
# The sample covers every package this decision names: the eight mdbook* crates,
# all four packages whose declared expression is conjunctive (AND), r-efi, and two
# ordinary dependencies as controls.
# Pass --full-walk to re-query all 218 (expect HTTP 429 unless well spaced).
hdr "check 8 — licence walk over the resolved dependency tree of mdbook = \"=0.5.4\""
python3 - "$UA" "$EV/mdbook-0.5.4-Cargo.lock" "$EV/mdbook-0.5.4-licences.json" "${1:-}" <<'PY'
import collections,json,re,sys,time,urllib.request,urllib.error
ua,lockpath,cachepath,mode=sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4]
lock=open(lockpath).read()
pkgs=[]
for blk in lock.split('[[package]]')[1:]:
    n=re.search(r'^name = "(.+)"',blk,re.M); v=re.search(r'^version = "(.+)"',blk,re.M)
    s=re.search(r'^source = "(.+)"',blk,re.M)
    if n and v and s: pkgs.append((n.group(1),v.group(1)))
cache=json.load(open(cachepath))
def live(n,v):
    u="https://crates.io/api/v1/crates/%s/%s"%(n,v)
    for attempt in range(8):
        try:
            d=json.load(urllib.request.urlopen(urllib.request.Request(u,headers={"User-Agent":ua})))
            return d["version"].get("license")
        except urllib.error.HTTPError as e:
            if e.code!=429 or attempt==7: return "ERROR:%s"%e
            time.sleep(20*(attempt+1))
sample=[("mdbook","0.5.4"),("mdbook-core","0.5.4"),("mdbook-driver","0.5.4"),("mdbook-html","0.5.4"),
        ("mdbook-markdown","0.5.4"),("mdbook-preprocessor","0.5.4"),("mdbook-renderer","0.5.4"),
        ("mdbook-summary","0.5.4"),("font-awesome-as-a-crate","0.3.1"),("r-efi","5.3.0"),("r-efi","6.0.0"),
        ("elasticlunr-rs","3.1.0"),("matchit","0.8.4"),("unicode-ident","1.0.24"),
        ("pulldown-cmark","0.13.4"),("handlebars","6.4.4")]
full = mode=="--full-walk"
print("lock registry packages: %d ; snapshot entries: %d ; mode: %s"%(len(pkgs),len(cache),"full-walk" if full else "snapshot+sample"))
lock_matches = sorted("%s %s"%p for p in pkgs)==sorted(cache)
print("ASSERT lock_matches_snapshot=%s"%lock_matches)
out={}
for n,v in pkgs:
    k="%s %s"%(n,v)
    out[(n,v)] = live(n,v) if full else cache[k]
    if full: time.sleep(0.3)
bad=[]
if not full:
    for n,v in sample:
        got=live(n,v); time.sleep(2.0)
        exp=cache["%s %s"%(n,v)]
        if got!=exp: bad.append((n,v,exp,got))
    print("ASSERT sample_%d_matches_snapshot=%s%s"%(len(sample),not bad,"" if not bad else " mismatches=%s"%bad))
c=collections.Counter(out.values())
for l,k in c.most_common(): print("%4d  %s"%(k,l))
strong=[(n,v,l) for (n,v),l in out.items() if l and re.search(r'\b(GPL|AGPL|EUPL|SSPL)\b',l) and ' OR ' not in l]
mpl=sorted(n for (n,v),l in out.items() if l=='MPL-2.0')
errs=[k for k,l in out.items() if str(l).startswith('ERROR')]
nolic=[k for k,l in out.items() if l is None]
print("MPL-2.0 packages (%d): %s"%(len(mpl),", ".join(mpl)))
print("non-permissive-only (GPL/AGPL/EUPL/SSPL with no permissive arm): %s"%(strong or "none"))
print("query errors: %s"%(errs or "none"))
print("packages with no declared licence: %s"%(nolic or "none"))
print("noteworthy: font-awesome-as-a-crate 0.3.1=%s ; r-efi 6.0.0=%s"%(out.get(("font-awesome-as-a-crate","0.3.1")),out.get(("r-efi","6.0.0"))))
# A conjunctive (AND) expression is not a permissive disjunction: every named
# licence's conditions apply together. Enumerate them rather than summarising them
# away, and fail if the set is not exactly the four the decision records.
conj=sorted("%s %s = %s"%(n,v,l) for (n,v),l in out.items() if l and ' AND ' in l)
print("conjunctive (AND) expressions (%d):"%len(conj))
for e in conj: print("      %s"%e)
expected_conj=sorted([
  "elasticlunr-rs 3.1.0 = (MIT OR Apache-2.0) AND MIT",
  "font-awesome-as-a-crate 0.3.1 = CC-BY-4.0 AND MIT",
  "matchit 0.8.4 = MIT AND BSD-3-Clause",
  "unicode-ident 1.0.24 = (MIT OR Apache-2.0) AND Unicode-3.0"])
conj_ok = conj==expected_conj
print("ASSERT conjunctive_set_is_exactly_the_four_recorded=%s"%conj_ok)
# The LGPL arm in the tree is disjunctive, so a permissive arm is selectable.
lgpl=sorted("%s %s = %s"%(n,v,l) for (n,v),l in out.items() if l and 'LGPL' in l)
print("LGPL-mentioning expressions (%d): %s"%(len(lgpl),"; ".join(lgpl) or "none"))
lgpl_ok = lgpl==sorted(["r-efi 5.3.0 = MIT OR Apache-2.0 OR LGPL-2.1-or-later",
                        "r-efi 6.0.0 = MIT OR Apache-2.0 OR LGPL-2.1-or-later"])
print("ASSERT lgpl_only_as_a_disjunctive_arm_of_r_efi=%s"%lgpl_ok)
# Cargo's pre-SPDX slash form is a disjunction, counted separately so the
# permissive total is not inflated by treating it as a single licence.
slash=sorted("%s %s = %s"%(n,v,l) for (n,v),l in out.items() if l and '/' in l)
print("legacy slash-syntax disjunctions (%d): %s"%(len(slash),"; ".join(slash) or "none"))
mpl_ok = mpl==sorted(["mdbook","mdbook-core","mdbook-driver","mdbook-html","mdbook-markdown","mdbook-preprocessor","mdbook-renderer","mdbook-summary"])
print("ASSERT mpl_are_exactly_the_mdbook_family=%s"%mpl_ok)
print("ASSERT no_reciprocal_licence_stronger_than_mpl2_in_tree=%s"%(not strong))
# Arithmetic the decision's paragraph states, asserted rather than asserted in prose.
n_perm = len(out)-len(mpl)-len(conj)-len(lgpl)-len(slash)
print("partition: %d total = %d MPL-2.0 + %d conjunctive + %d r-efi-LGPL-disjunction + %d legacy-slash + %d single-or-disjunctive-permissive"
      %(len(out),len(mpl),len(conj),len(lgpl),len(slash),n_perm))
part_ok = (len(out),len(mpl),len(conj),len(lgpl),len(slash),n_perm)==(218,8,4,2,8,196)
print("ASSERT partition_is_218_8_4_2_8_196=%s"%part_ok)
sys.exit(1 if (bad or strong or errs or nolic or not lock_matches or not mpl_ok
               or not conj_ok or not lgpl_ok or not part_ok) else 0)
PY
assert "licence walk exit" "0" "$?"

# ---------------------------------------------------------------- check 9
hdr "check 9 — MPL-2.0 is file-level (Mozilla FAQ)"
curl -sS -o "$SNAP/mpl-2.0-faq.html" https://www.mozilla.org/en-US/MPL/2.0/FAQ/
assert "MPL FAQ fetch exit" "0" "$?"
python3 "$SNAP/.norm.py" "$SNAP/mpl-2.0-faq.html" > "$SNAP/n_mpl-faq.txt"
assert_has "MPL FAQ file-level copyleft sentence" "$SNAP/n_mpl-faq.txt" "The MPL's \"file-level\" copyleft is designed to encourage contributors to share modifications they make to your code, while still allowing them to combine your code with code under other licenses (open or proprietary) with minimal restrictions."

# ---------------------------------------------------------------- check 10
hdr "check 10 — fixed parameters generated from the registry and diffed"
awk -F'|' '$2 ~ /^ *(msrv-policy|rust-edition|target-os-matrix|license) *$/ && $3 ~ /^ *fixed *$/ {
  p=$2; v=$5; gsub(/^ +| +$/,"",p); gsub(/^ +| +$/,"",v); print "- assumes " p " = " v
}' "$REPO_ROOT/docs/port/PARAMETERS.md" > "$SNAP/.params-registry.txt"
grep -E '^- assumes (msrv-policy|rust-edition|target-os-matrix|license) = ' "$EV/../DECISION.md" > "$SNAP/.params-decision.txt"
say "-- generated from docs/port/PARAMETERS.md:"
sed 's/^/   /' "$SNAP/.params-registry.txt"
if diff -u "$SNAP/.params-registry.txt" "$SNAP/.params-decision.txt" > "$SNAP/.params.diff" 2>&1; then
  assert "parameter round-trip diff" "empty" "empty"
else
  cat "$SNAP/.params.diff"; assert "parameter round-trip diff" "empty" "non-empty"
fi

# ---------------------------------------------------------------- check 11
# The decision's target-os-matrix paragraph claims mdBook 0.5.4 ships prebuilt
# binaries for the matrix platforms. Map every asset rather than summarising the
# set, because "Linux and macOS, both x86_64 and aarch64" is true of the release
# only if aarch64 Linux is read as musl: there is no aarch64-unknown-linux-gnu asset.
hdr "check 11 — mdBook v0.5.4 release assets (GET /repos/rust-lang/mdBook/releases/tags/v0.5.4)"
gh api repos/rust-lang/mdBook/releases/tags/v0.5.4 --jq '.assets[].name' | sort > "$SNAP/.mdbook-v0.5.4-assets.txt"
assert "release asset query exit" "0" "$?"
sed 's/^/   /' "$SNAP/.mdbook-v0.5.4-assets.txt"
assert "asset count" "6" "$(wc -l < "$SNAP/.mdbook-v0.5.4-assets.txt" | tr -d ' ')"
for a in mdbook-v0.5.4-aarch64-apple-darwin.tar.gz \
         mdbook-v0.5.4-aarch64-unknown-linux-musl.tar.gz \
         mdbook-v0.5.4-x86_64-apple-darwin.tar.gz \
         mdbook-v0.5.4-x86_64-pc-windows-msvc.zip \
         mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz \
         mdbook-v0.5.4-x86_64-unknown-linux-musl.tar.gz; do
  assert_has "asset present: $a" "$SNAP/.mdbook-v0.5.4-assets.txt" "$a"
done
assert "NO aarch64-unknown-linux-gnu asset" "0" \
  "$(grep -c 'aarch64-unknown-linux-gnu' "$SNAP/.mdbook-v0.5.4-assets.txt")"
# The matrix runners this template targets, mapped to the asset each would download.
assert "ubuntu-latest (x86_64 Linux glibc) asset count" "1" \
  "$(grep -c 'x86_64-unknown-linux-gnu' "$SNAP/.mdbook-v0.5.4-assets.txt")"
assert "macos-latest (aarch64 macOS) asset count" "1" \
  "$(grep -c 'aarch64-apple-darwin' "$SNAP/.mdbook-v0.5.4-assets.txt")"

# ---------------------------------------------------------------- check 12
# The fit judgement in revision 3 rests on the shape of the corpus F342 fixes.
# Measure it rather than assert it, and measure it from an immutable source an
# auditor can reach: the ts-launch-blueprint tree at the pinned commit the
# programme reads that repository through. The GitHub tree API at a commit SHA
# returns the same bytes forever, so this is reproducible off this machine.
# Counted: blobs whose path matches ^docs/<category>/....md for the six
# categories F342 fixes. Files directly under docs/ are NOT in the six-category
# count and are reported separately.
hdr "check 12 — the corpus F342 fixes, measured at the ts pin"
TSPIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00
gh api "repos/smorinlabs/ts-launch-blueprint/git/trees/$TSPIN?recursive=1" \
  --jq '.tree[] | select(.type=="blob") | "\(.size)\t\(.path)"' > "$SNAP/.ts-tree.txt"
assert "ts pinned tree fetch exit" "0" "$?"
assert "ts pinned tree is non-empty" "yes" \
  "$([ -s "$SNAP/.ts-tree.txt" ] && echo yes || echo no)"
for c in about tasks tools tutorials reference contributing; do
  n=$(grep -cE "	docs/$c/[^	]*\.md$" "$SNAP/.ts-tree.txt")
  say "   docs/$c: $n .md files"
done
assert "ts docs/about .md count"        "3"  "$(grep -cE '	docs/about/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "ts docs/tasks .md count"        "7"  "$(grep -cE '	docs/tasks/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "ts docs/tools .md count"        "12" "$(grep -cE '	docs/tools/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "ts docs/tutorials .md count"    "2"  "$(grep -cE '	docs/tutorials/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "ts docs/reference .md count"    "5"  "$(grep -cE '	docs/reference/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "ts docs/contributing .md count" "6"  "$(grep -cE '	docs/contributing/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "six F342 categories: total .md files" "35" \
  "$(grep -cE '	docs/(about|tasks|tools|tutorials|reference|contributing)/[^	]*\.md$' "$SNAP/.ts-tree.txt")"
assert "six F342 categories: total bytes" "171225" \
  "$(grep -E '	docs/(about|tasks|tools|tutorials|reference|contributing)/[^	]*\.md$' "$SNAP/.ts-tree.txt" | awk -F'\t' '{s+=$1} END{print s+0}')"
assert "whole docs/ tree .md count" "48" \
  "$(grep -cE '	docs/.*\.md$' "$SNAP/.ts-tree.txt")"
# The six categories are nested one level below docs/, which is the structural
# property the fit judgement turns on. A flat corpus would have 0 here.
assert "the six categories are directories, not flat files" "6" \
  "$(grep -oE '	docs/(about|tasks|tools|tutorials|reference|contributing)/' "$SNAP/.ts-tree.txt" | sort -u | wc -l | tr -d ' ')"

# ---------------------------------------------------------------- check 13
# Practice evidence for the fit judgement: among widely used Rust projects, the
# ones that keep narrative in the README keep it FLAT at the repository root and
# ship no book.toml; the one with a nested narrative tree ships mdBook. Every
# repository is read at a pinned commit so the result is stable.
hdr "check 13 — Rust practice splits on narrative structure, not on project kind"
probe_repo() { # probe_repo <owner/repo> <sha>  -> "<size>\t<path>" per blob
  gh api "repos/$1/git/trees/$2?recursive=1" --jq '.tree[] | select(.type=="blob") | "\(.size)\t\(.path)"' > "$SNAP/.tree-$(printf '%s' "$1" | tr '/' '_').txt"
}
for pair in "BurntSushi/ripgrep 3fce3b5bb0236da2df6d99672afb8a719642eca7" \
            "clap-rs/clap 48ed7869b91addcfb485decf2b445c74bef00535" \
            "serde-rs/serde a874a1b1bb1cc16cf5ee3b1b7b527af5705742bb" \
            "ratatui/ratatui 982cd76bcabf3899bd35e7ad10f16553e95c84db" \
            "cargo-generate/cargo-generate b1def653c6104a5e98024f56208b243dc6294de9"; do
  set -- $pair
  probe_repo "$1" "$2" || { say "FAIL  tree fetch $1"; FAILS=$((FAILS+1)); continue; }
  f="$SNAP/.tree-$(printf '%s' "$1" | tr '/' '_').txt"
  nd=$(grep -cE '\t(docs|doc|guide|book)/' "$f")
  nb=$(grep -cE '(\t|/)book\.toml$' "$f")
  nr=$(grep -cE '\t[^/]*\.md$' "$f")
  say "   $1  narrative-dir-files=$nd  book.toml=$nb  root-md=$nr"
  assert "$1 tree is non-empty" "yes" "$([ -s "$f" ] && echo yes || echo no)"
done
for r in BurntSushi_ripgrep clap-rs_clap serde-rs_serde ratatui_ratatui; do
  assert "$r has no docs/doc/guide/book directory" "0" \
    "$(grep -cE '\t(docs|doc|guide|book)/' "$SNAP/.tree-$r.txt")"
  assert "$r ships no book.toml" "0" \
    "$(grep -cE '(\t|/)book\.toml$' "$SNAP/.tree-$r.txt")"
done
assert "cargo-generate ships guide/book.toml" "1" "$(grep -cE '\tguide/book\.toml$' "$SNAP/.tree-cargo-generate_cargo-generate.txt")"
assert "cargo-generate keeps an mdBook SUMMARY.md" "1" "$(grep -cE '\tguide/src/SUMMARY\.md$' "$SNAP/.tree-cargo-generate_cargo-generate.txt")"
# ...and its guide is nested, not flat: subdirectories under guide/src.
assert "cargo-generate guide/src has nested subdirectories" "2" \
  "$(grep -oE '\tguide/src/[^/]+/' "$SNAP/.tree-cargo-generate_cargo-generate.txt" | sort -u | wc -l | tr -d ' ')"
# ripgrep's root narrative is flat and substantial: the split is by structure,
# not by byte count. Assert the three files exist at the root.
# The decision quotes these byte figures, so they are gated, not just printed.
assert "ripgrep GUIDE.md size"  "40895" "$(awk -F'\t' '$2=="GUIDE.md"{print $1}'  "$SNAP/.tree-BurntSushi_ripgrep.txt")"
assert "ripgrep FAQ.md size"    "42243" "$(awk -F'\t' '$2=="FAQ.md"{print $1}'    "$SNAP/.tree-BurntSushi_ripgrep.txt")"
assert "ripgrep README.md size" "21599" "$(awk -F'\t' '$2=="README.md"{print $1}' "$SNAP/.tree-BurntSushi_ripgrep.txt")"
assert "clap README.md size"    "1827"  "$(awk -F'\t' '$2=="README.md"{print $1}' "$SNAP/.tree-clap-rs_clap.txt")"

# ---------------------------------------------------------------- check 14
# Two facts the fit judgement and the F343 forbidden set rest on:
#   (a) mdBook's HTML renderer enables full-text search by default;
#   (b) mdBook 0.5 documents no mermaid support, while GitHub documents diagram
#       rendering for the same fence - so the fence renders differently on the
#       two surfaces and is excluded by the GFM-intersect-mdBook rule.
# (b) is asserted as a NEGATIVE on mdBook's own Markdown reference page: a
# non-zero count there would mean the exclusion is wrong, so the assertion can
# genuinely fail.
hdr "check 14 — mdBook default search; mermaid renders differently on the two surfaces"
R=$(fetch_norm format/configuration/renderers.html) || { say "FAIL fetch renderers.html"; FAILS=$((FAILS+1)); }
assert_has "mdBook HTML search is on by default" "$R" "search feature enabled (on by default)"
assert_has "mdBook documents [output.html.search] enable" "$R" "enable: Enables the search feature"
# mdBook's Markdown reference must not mention mermaid at all.
assert "mdBook Markdown reference mentions mermaid" "0" \
  "$(grep -oic 'mermaid' "$SNAP/n_format_markdown.html" | tr -d ' ')"
curl -sS -o "$SNAP/github-creating-diagrams.html" -L \
  "https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams"
assert "GitHub diagrams doc fetch exit" "0" "$?"
python3 "$SNAP/.norm.py" "$SNAP/github-creating-diagrams.html" > "$SNAP/n_github-diagrams.txt"
assert_has "GitHub documents mermaid-fence diagram rendering" "$SNAP/n_github-diagrams.txt" \
  "add Mermaid syntax inside a fenced code block with the mermaid language identifier"
# The REST renderer recognizes the language but returns a highlighted code block,
# not a diagram. Recorded exactly, so the decision cannot overstate it.
assert_has "POST /markdown marks the fence as source-mermaid" "$SNAP/dialect-probe.html" \
  'class="highlight highlight-source-mermaid"'

# ---------------------------------------------------------------- check 15
# Zola is re-judged on fit alone now that gate 1 is inapplicable. The fit reason
# is its shape: a general website generator with a required base_url and no
# chapter/SUMMARY model. Read that from the maintainers' own configuration page.
hdr "check 15 — Zola's site model (maintainers' configuration documentation)"
curl -sS -o "$SNAP/zola-configuration.html" https://www.getzola.org/documentation/getting-started/configuration/
assert "Zola configuration doc fetch exit" "0" "$?"
python3 "$SNAP/.norm.py" "$SNAP/zola-configuration.html" > "$SNAP/n_zola-configuration.txt"
assert_has "Zola: base_url is the only required variable" "$SNAP/n_zola-configuration.txt" \
  "The base URL of the site; the only required configuration variable."
assert "Zola configuration page mentions SUMMARY" "0" \
  "$(grep -oc 'SUMMARY' "$SNAP/n_zola-configuration.txt" | tr -d ' ')"
assert "Zola configuration page mentions chapters" "0" \
  "$(grep -oic 'chapter' "$SNAP/n_zola-configuration.txt" | tr -d ' ')"

# ---------------------------------------------------------------- recorded, not gated
# The hosted Pages URL this decision names is DERIVED from the repository slug,
# not observed. These two facts are printed and deliberately NOT asserted,
# because the owner performing the one-time "Pages source = GitHub Actions"
# setting flips both of them, and that is a change the decision welcomes rather
# than a regression. The decision states them as of their retrieval date only.
hdr "recorded (not gated) — upstream Pages state for smorinlabs/rs-launch-blueprint"
say "has_pages: $(gh api repos/smorinlabs/rs-launch-blueprint --jq '.has_pages' 2>&1)"
say "GET /pages http status: $(gh api repos/smorinlabs/rs-launch-blueprint/pages --silent >/dev/null 2>&1 && echo 200 || echo 'non-200 (404 expected while Pages is disabled)')"

# ---------------------------------------------------------------- check 16
# Revision 3 changes the recommendation. This check proves mechanically which
# parts of revision 2 it did NOT touch, by diffing the current DECISION.md
# against the revision-2 git blob and asserting that each region the licence
# ruling does not reach is byte-identical. The blob id is stable across later
# commits.
#
# PRECONDITION: this check reads the repository's own git history, so $REPO_ROOT
# must be a git checkout (clone or worktree) whose object database contains blob
# 9f2bcb9ddf5266bf4face766e98b7cd1be3616ad. A rerun from a plain file copy of the
# tree with no .git cannot run it: the blob read fails, this check reports FAIL,
# and the script exits 1. Checks 1-15 do not read git and are unaffected.
hdr "check 16 — revision-3 diff against the revision-2 blob"
R2BLOB=9f2bcb9ddf5266bf4face766e98b7cd1be3616ad
git -C "$REPO_ROOT" cat-file blob "$R2BLOB" > "$SNAP/.decision-r2.md"
assert "revision-2 blob read exit" "0" "$?"
assert "revision-2 blob sha256" "5ab7479c7d5e0485fa1c05aef9a894f4c36b56de3692bef89c17efc33a09404e" \
  "$(shasum -a 256 "$SNAP/.decision-r2.md" | awk '{print $1}')"
assert "revision-2 blob is non-empty" "yes" \
  "$([ -s "$SNAP/.decision-r2.md" ] && echo yes || echo no)"
python3 - "$SNAP/.decision-r2.md" "$EV/../DECISION.md" <<'PY'
import sys
r2=open(sys.argv[1]).read().splitlines(True); r3=open(sys.argv[2]).read().splitlines(True)
def region(lines,start,ends):
    i=[k for k,l in enumerate(lines) if l.startswith(start)]
    if not i: return None
    i=i[0]
    for k in range(i+1,len(lines)):
        if any(lines[k].startswith(e) for e in ends): return lines[i:k]
    return None
# Regions the owner's licence ruling does not reach: asserted byte-identical to
# revision 2. The licence-walk table and its reading are the substantive ones -
# the ruling changes what is EVALUATED, not what the walk found.
REGIONS=[
 ("licence partition table",      "| Class | Count | Packages",                   ["\n"]),
 ("what each class means",        "**What each class means for the fixed",        ["**None of these 218"]),
 ("shared requirement -> what may vary",
                                  "**Shared requirement, its source and agreement level.**",
                                                                                  ["**Architectural alternatives compared"]),
 ("the four fixed - assumes lines", "- assumes msrv-policy",                      ["\n"]),
 ("check-8 snapshot rationale",   "**How check 8 avoids lying about a rate-limited sweep.**",
                                                                                  ["**Nothing recommended was implemented.**"]),
 ("revision-1 check-defect record", "Three assertions failed on revision 1's first run",
                                                                                  ["| # | Check |"]),
 ("disagreement 4 (figures)",     "**Disagreement 4 — the mdBook MSRV and figure set.**",
                                                                                  ["**Unproven, with what would prove it.**"]),
 ("unproven entry 3 (unsafe posture)", "3. **mdBook's `unsafe` posture**",        ["4. **Whether mdBook"]),
 ("revision-1 history entry",     "- **Revision 1**, 2026-09-10, sha256",         ["- **Revision 2**"]),
]
bad=0
for name,start,ends in REGIONS:
    a,b=region(r2,start,ends),region(r3,start,ends)
    if a is None or b is None:
        print("FAIL  region marker not found: %-38s r2=%s r3=%s"%(name,a is not None,b is not None)); bad+=1
    elif a==b:
        print("PASS  region byte-identical to revision 2: %-34s %d lines"%(name,len(a)))
    else:
        print("FAIL  region CHANGED: %s"%name); bad+=1
        for l in a:
            if l not in b: print("        r2-only: %s"%l.rstrip()[:120])
# Regions the ruling DOES change: asserted to have changed, and to carry the
# sentence that shows they were changed for the right reason.
# Each entry: name, revision-2 start marker, revision-3 start marker, end markers,
# and the sentence revision 3's version must carry. The gate-1 record opens with a
# different line in each revision, so its two markers differ.
CHANGED_BY_RULING=[
 ("recommendation paragraph", "**Recommendation — ", "**Recommendation — ",
  ["| Ledger row"], "GitHub Pages site published from the upstream repository."),
 ("fitness gate 1 record", "**The licence condition", "**Fitness gate 1**",
  ["What the ruling does not reach","**The dependency tree was walked"],
  "inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool"),
 ("disagreement 1 (the fit judgement)", "**Disagreement 1 — ship a generator",
  "**Disagreement 1 — ship a generator", ["**Disagreement 2"],
  "Settled for `opus`, on fit, in revision 3."),
 ("baseline-review F357 line", "BASELINE-REVIEW: F357", "BASELINE-REVIEW: F357",
  ["\n","BASELINE-REVIEW: F358"], "that condition is now met"),
 ("baseline-review F358 line", "BASELINE-REVIEW: F358", "BASELINE-REVIEW: F358",
  ["\n","### Principles"], "with mdBook shipped"),
]
for name,s2,s3,ends,frag in CHANGED_BY_RULING:
    a,b=region(r2,s2,ends),region(r3,s3,ends)
    if a is None or b is None:
        print("FAIL  ruling region marker not found: %-34s r2=%s r3=%s"%(name,a is not None,b is not None)); bad+=1; continue
    if a==b:
        print("FAIL  ruling region NOT updated (still revision-2 text): %s"%name); bad+=1
    elif frag in "".join(b):
        print("PASS  ruling region updated and carries its marker sentence: %s"%name)
    else:
        print("FAIL  ruling region changed but lacks its marker sentence: %s"%name); bad+=1
# Text revision 3 must carry (the gate-1 record on ONE line, so a grep finds it
# whole) and text it must NO LONGER carry (the branch structure).
whole3="".join(r3)
MUST_CARRY=[
 ("gate 1 recorded on one line, verbatim",
  "`inapplicable \u2014 owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`"),
 ("the theme/ prohibition survives the ruling",
  "never commit a `theme/` directory"),
 ("the Font Awesome attribution duty survives the ruling",
  "attribution owed for icon\nassets in the built site"),
 ("no surveyed licence reaches the template's own source",
  "none of them\nreaches the template's own `MIT OR Apache-2.0` source"),
 ("mermaid fences are forbidden by F343",
  "` ```mermaid ` fences"),
 # Carried forward from revision 2's check 12: the three sentences the revision-1
 # audit required preserved. They are still gated here so the requirement does not
 # silently lapse when the revision-diff check is re-targeted.
 ("no adopter of the exact Pages-action majors is claimed",
  "not the `v6.0.0`/`v5.0.0`/`v5.0.1`\n   majors `opus` recommends"),
 ("no local renderer matches the host's dialect",
  "no local renderer reproducing GitHub's exact Markdown semantics\n   was identified"),
 ("identical rendering rests on inspection",
  "**Identical rendering on both surfaces is inspected, not verified.**"),
]
for name,frag in MUST_CARRY:
    if frag in whole3: print("PASS  present verbatim: %s"%name)
    else: print("FAIL  required text MISSING: %s"%name); bad+=1
# The branch structure must be gone from the decision itself. It is allowed, and
# required, in the revision-history entries, which describe what revisions 1 and
# 2 said - so the scan stops at "**Revision history.**".
cut=whole3.index("**Revision history.**")
live=whole3[:cut]
MUST_NOT_CARRY=["branch A","branch B","Branch A","Branch B",
                "branch-A","branch-B","two-branch"]
for frag in MUST_NOT_CARRY:
    n=live.count(frag)
    if n==0: print("PASS  branch structure removed from the live decision: no %r"%frag)
    else: print("FAIL  branch structure still in the live decision: %r x%d"%(frag,n)); bad+=1
# ...and it must still be described in the history, or the history is lying.
if "branch" in whole3[cut:]: print("PASS  revision history still describes the branch structure")
else: print("FAIL  revision history no longer describes the branch structure"); bad+=1
# There must be no `## Supersedes` section: R81 is not published.
# A heading, not a mention: the decision legitimately says in prose that no such
# section is present, so match a line that STARTS with the heading.
if not any(l.startswith("## Supersedes") for l in r3): print("PASS  no ## Supersedes heading")
else: print("FAIL  ## Supersedes heading present"); bad+=1
import difflib
hunks=[l for l in difflib.unified_diff(r2,r3,n=3) if l.startswith('@@')]
print("whole-file unified-diff hunks: %d"%len(hunks))
for h in hunks: print("      %s"%h.strip())
# The count is gated so a later stray edit cannot slip in as an unremarked change.
EXPECTED_HUNKS=17
if len(hunks)==EXPECTED_HUNKS: print("ASSERT hunk_count_is_%d=True"%EXPECTED_HUNKS)
else: print("ASSERT hunk_count_is_%d=False actual=%d"%(EXPECTED_HUNKS,len(hunks))); bad+=1
sys.exit(1 if bad else 0)
PY
assert "revision-3 untouched-region diff" "0" "$?"

hdr "result"
say "failed assertions: $FAILS"
rm -f "$SNAP"/.norm.py "$SNAP"/.cratelic.py "$SNAP"/.decision-r2.md
[ "$FAILS" -eq 0 ] || exit 1
exit 0
