#!/usr/bin/env bash
# R29 revision 2 — checks on review/DECISION.md itself, offline:
#   C1  H2 structure, title, revision note, actor and licence lines, re-verify line,
#       compared with a published decision (R11) for the same H2 set;
#   C2  every `assumes` line byte-identical to inputs/parameters.json; no owns, no CONFLICT;
#   C3  prerequisite and input hashes as the run recorded them;
#   C4  every raw/…:N and prerequisite DECISION.md:N citation resolves to the quoted
#       text, and no such citation in DECISION.md is missing from the table below;
#   C5  the staffing facts the decision's header reports.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
run="$(cd "$here/../.." && pwd)"
root="$(cd "$run/../../../.." && pwd)"
dec="$run/review/DECISION.md"
pass=0 fail=0
ok()  { pass=$((pass + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
bad() { fail=$((fail + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
py() {
  local id="$1" desc="$2" out
  out="$(RUN="$run" ROOT="$root" DEC="$dec" python3 -c "import json,os,re,hashlib
RUN,ROOT,DEC=os.environ['RUN'],os.environ['ROOT'],os.environ['DEC']
D=open(DEC,encoding='utf-8').read()
def sha(p): return hashlib.sha256(open(p,'rb').read()).hexdigest()
$3" 2>&1)" || true
  if [ "$out" = ok ]; then ok "$id" "$desc"; else bad "$id" "$desc :: $out"; fi
}

echo "DECISION.md: $(wc -l <"$dec") lines, sha256 $(shasum -a 256 "$dec" | cut -d' ' -f1)"

py C1a "title line names date, item, slug, kind, tier and revision 2" '
print("ok" if D.split("\n")[0]=="# 2026-09-27 — R29 — non-code-file-formatting (bundle, Focused) — decision (revision 2)" else D.split("\n")[0])'
py C1b "H2 set is Decision, Parameters, Empirical check, Engines in that order, the same as published R11" '
mine=re.findall(r"^## (.+)$",D,re.M)
pub=re.findall(r"^## (.+)$",open(os.path.join(ROOT,"research/topics/11-ci-workflow-job-structure/DECISION.md"),encoding="utf-8").read(),re.M)
print("ok" if mine==["Decision","Parameters","Empirical check","Engines"]==pub else (mine,pub))'
# shellcheck disable=SC2016 # literal Python source quoting Markdown backticks, not a shell expansion
py C1c "revision-2 and revision-1 notes, both actor lines with model, licence-gate line; no Supersedes" '
print("ok" if "**Revision note, revision 2.**" in D and "actor `repair-opus-2026-09-26T190157Z-3dd868e1695b-r2`, model `claude-opus-5-5`" in D and "**Revision note, revision 1.**" in D and "Actor `synth-opus-2026-09-26T190157Z-3dd868e1695b-r1`, model `claude-opus-5-5`" in D and "**Fitness gate 1 (licence) is `inapplicable" in D and not re.search(r"^## Supersedes",D,re.M) else "missing")'
py C1d "## Decision holds ### Principles and implementation and exactly one re-verify: line" '
dec=D.split("\n## Parameters")[0].split("\n## Decision")[1]
print("ok" if "\n### Principles and implementation\n" in dec and len(re.findall(r"^re-verify: ",dec,re.M))==1 and len(re.findall(r"^re-verify: ",D,re.M))==1 else "missing")'

py C2a "each assumes line is byte-identical to inputs/parameters.json, one per parameter" '
params=json.load(open(os.path.join(RUN,"inputs/parameters.json")))
lines=[l for l in D.split("\n") if l.startswith("- assumes ")]
want=["- assumes %s = %s"%(p["param"],p["value"]) for p in params]
print("ok" if sorted(lines)==sorted(want) and len(lines)==6 else [w[:60] for w in want if w not in lines])'
py C2b "no owns line and no CONFLICT: line" '
print("ok" if not re.search(r"^- owns ",D,re.M) and not re.search(r"^\s*-?\s*CONFLICT:",D,re.M) else "found")'

py C3a "prerequisite DECISION.md and acceptance.json hashes equal inputs/prerequisites.json" '
pre=json.load(open(os.path.join(RUN,"inputs/prerequisites.json")))
t={"R11":"research/topics/11-ci-workflow-job-structure","R42":"research/topics/42-dev-toolchain-provisioning"}
got={k:{"acceptance":sha(os.path.join(ROOT,v,"acceptance.json")),"decision":sha(os.path.join(ROOT,v,"DECISION.md"))} for k,v in t.items()}
print("ok" if got==pre else got)'
py C3b "inputs/prompt.md hashes to the manifest's recorded prompt hash" '
m=json.load(open(os.path.join(RUN,"manifest.json")))
print("ok" if sha(os.path.join(RUN,"inputs/prompt.md"))==m["input_hashes"]["prompt"] else "mismatch")'
# shellcheck disable=SC2016 # literal Python source quoting Markdown backticks, not a shell expansion
py C3c "the live topic prompt differs from the run snapshot only by the Muse substitution (engines line and one tier-guidance sentence)" '
m=json.load(open(os.path.join(RUN,"manifest.json")))
a=open(os.path.join(RUN,"inputs/prompt.md"),encoding="utf-8").read().split("\n"); b=open(os.path.join(ROOT,m["prompt_source"]),encoding="utf-8").read().split("\n")
d=[(i+1,x,y) for i,(x,y) in enumerate(zip(a,b)) if x!=y]
okd=len(a)==len(b) and [n for n,_,_ in d]==[26,72] and d[0][1]=="- engines: codex, opus" and d[0][2]=="- engines: muse, opus" and d[1][2]==d[1][1]+" This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
print("ok" if okd else d if d else "identical")'
# shellcheck disable=SC2016 # literal Python source quoting Markdown backticks, not a shell expansion
py C4 "every raw and prerequisite line citation resolves to its quoted text, and none is unlisted" '
R11="research/topics/11-ci-workflow-job-structure/DECISION.md"; R42="research/topics/42-dev-toolchain-provisioning/DECISION.md"
T={("raw/muse.md",3):"Engine: muse.",("raw/muse.md",4):"Retrieval date for every figure and claim below: 2026-09-27",
("raw/muse.md",53):"dogfoods `dprint-plugin-yaml@0.6.0`",("raw/muse.md",100):"fails if something is not properly formatted",
("raw/muse.md",112):"No `BASELINE-REVIEW:` finding",("raw/muse.md",118):"One stack: `taplo-cli 0.10.0` for TOML",
("raw/muse.md",122):"separate lefthook jobs in the same tier",("raw/muse.md",169):"gates: (1) MIT, compatible",
("raw/muse.md",179):"`stable-quiet` — no release in 16 months",("raw/muse.md",211):"schema linting is recommended as opt-in",
("raw/muse.md",281):"rustfmt-link claim for taplo is",("raw/muse.md",324):"builds on",("raw/muse.md",325):"`dprint-core 0.69`",
("raw/muse.md",339):"including #4, an open block-scalar",("raw/muse.md",449):"(2/2 unanswered)",
("raw/muse.md",475):"`Cargo.lock` must never be",("raw/muse.md",476):"claimed by the JSON formatter",
("raw/muse.md",585):"A `Cargo.lock` decoy containing",("raw/muse.md",586):"deliberately non-canonical JSON",
("raw/muse.md",776):"including one entry with",("raw/muse.md",777):"an `@sha` checksum suffix proving",
("raw/muse.md",803):"0628eac1c`",("raw/muse.md",837):"same pre-push tier as `rustfmt`",
("raw/muse.md",832):"- Justfile: one recipe per check invocation",("raw/muse.md",833):"this item recommends the two checks also run inside the",
("raw/muse.md",834):"composite `check`/`all` path rather than only standalone",("raw/muse.md",835):"should fail the same gate as source drift",
("raw/opus.md",3):"Engine: claude-opus-5-5 (Opus seat, CLI run 2026-09-26)",("raw/opus.md",90):"The dominant practice among large Rust",
("raw/opus.md",122):"A5. Generated files whose layout belongs to another tool",("raw/opus.md",136):"**Markdown only with the `napi` feature**",
("raw/opus.md",147):"`dprint check` exits `20` when a file is unformatted",("raw/opus.md",221):"**BASELINE-REVIEW.** None.",
("raw/opus.md",225):"The npm-staleness note for `@taplo/cli`",("raw/opus.md",230):"cited by `rustfmt`",
("raw/opus.md",236):"**One stack: `dprint` 0.57.4",("raw/opus.md",267):"**LOW, hook tier?** The same pre-commit tier",
("raw/opus.md",268):"`{staged_files}` scoping",("raw/opus.md",324):"**Gate 1 (licence)** is struck",
("raw/opus.md",345):"**Unverified:** whether `cargo binstall",("raw/opus.md",373):"which R27 may fold into its composite under F102.",
("raw/opus.md",843):"mode follows R27",("raw/opus.md",844):"recipe inclusion follows R27",("raw/opus.md",854):"R27 decides whether its composite `check`/`all` recipes call them (F102).",("raw/opus.md",428):"median 44.2 days",
("raw/opus.md",442):"The label is `at-risk`, not `dormant`",("raw/opus.md",481):"Editor interplay",
("raw/opus.md",725):"loads `npm:dprint-plugin-yaml@0.6.0`",("raw/opus.md",735):"median 0.6 days; 1 unanswered",
("raw/opus.md",933):"identity with `pretty_yaml` was not verified",("raw/opus.md",937):"Whether the standalone `oxfmt` release binary formats Markdown is unverified",
(R42,12):"Owner direction on this item exists as of 2026-09-12",(R42,13):"no licence check for any tool or",(R42,16):"Fitness gate 1 is struck from every candidate evaluation here.",
(R42,91):"`taplo-cli@0.10.0` had",(R42,93):"will be installed from source (with cargo)",
(R11,82):"Fitness gate 1 (licence) is `inapplicable",(R11,188):"R29'"'"'s non-code formatting slot and R20'"'"'s two pin-policy checks are steps of `hygiene`"}
def line(f,n):
    p=os.path.join(RUN,f) if f.startswith("raw/") else os.path.join(ROOT,f)
    return open(p,encoding="utf-8").read().split("\n")[n-1]
errs=[(f,n) for (f,n),want in T.items() if want not in line(f,n)]
cited=set()
for f,a,b in re.findall(r"`(raw/(?:muse|opus)\.md):(\d+)(?:-(\d+))?`",D):
    cited.update((f,n) for n in range(int(a),int(b or a)+1))
for who,a,b in re.findall(r"(R11|R42) `DECISION\.md:(\d+)(?:-(\d+))?`",D):
    f=R11 if who=="R11" else R42
    cited.update((f,n) for n in range(int(a),int(b or a)+1))
listed={k[:2] for k in T}
unlisted=[c for c in cited if c not in listed and not (c[0]==R42 and 12<=c[1]<=17) and not (c[0]==R42 and c[1]==92)]
print("ok" if not errs and not unlisted and len(cited)>=40 else {"mismatch":errs,"unlisted":sorted(unlisted),"n":len(cited)})'

py C5 "staffing facts: policy snapshot names codex+opus for R29, no R29 engine override, manifest requires codex+opus, raw holds muse.md+opus.md" '
e=json.load(open(os.path.join(RUN,"inputs/EXECUTION.json"))); m=json.load(open(os.path.join(RUN,"manifest.json")))
raws=sorted(os.listdir(os.path.join(RUN,"raw")))
print("ok" if e["items"]["R29"]["engines"]==["codex","opus"] and "R29" not in e["engine_overrides"] and m["required_engines"]==["codex","opus"] and raws==["muse.md","opus.md"] else (e["items"]["R29"],raws))'

printf 'r29-decision-checks: PASS=%d FAIL=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
