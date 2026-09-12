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

UA='rs-launch-blueprint-research/1.0 (steve@conceptm.com)'
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
printf '%s\n' '> [!NOTE]' '> hello' '' '# Head { #id .cls }' '' 'term' ': definition' '' '[link](./other.md)' > "$SNAP/.dialect-probe.md"
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

hdr "result"
say "failed assertions: $FAILS"
rm -f "$SNAP"/.norm.py "$SNAP"/.cratelic.py
[ "$FAILS" -eq 0 ] || exit 1
exit 0
