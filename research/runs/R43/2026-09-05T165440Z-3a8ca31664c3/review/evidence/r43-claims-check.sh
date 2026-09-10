#!/usr/bin/env bash
# R43 ai-assistant-repo-furniture — synthesizer empirical check.
# Verifies the claims the two raw reports rest on. Implements nothing:
# no assistant file is authored, no template is scaffolded, no vendor
# product is installed or launched.
# Run from the repository root of rs-launch-blueprint-p02-plan.

FAIL=0
DOC=$(mktemp -d)
PY_PIN=b08bccfb55d05f15e46a83b52c5660b1881d19f5
TS_PIN=cb1cbcb2e88b898e8c081b0abbfabc1630079c00

say() { printf '\n=== %s ===\n' "$1"; }
ck()  { # ck <label> <expected> <actual>
  if [ "$2" = "$3" ]; then printf 'PASS  %-62s expected=%s actual=%s\n' "$1" "$2" "$3"
  else printf 'FAIL  %-62s expected=%s actual=%s\n' "$1" "$2" "$3"; FAIL=$((FAIL+1)); fi
}
cnt() { grep -c -- "$1" "$2" 2>/dev/null || true; }
fetch() { # fetch <url> <outfile>
  code=$(curl -sSL --max-time 45 -o "$2" -w '%{http_code}' "$1")
  printf 'GET %s -> HTTP %s (%s bytes)\n' "$1" "$code" "$(wc -c < "$2" | tr -d ' ')"
}

say "0. Toolchain and environment"
date -u +'run started %Y-%m-%dT%H:%M:%SZ'
echo "cwd: $(pwd)"
rustc --version 2>&1 || echo 'rustc: not installed'
cargo --version 2>&1 || echo 'cargo: not installed'
uname -a
sw_vers 2>/dev/null | tr '\n' ' '; echo
curl --version | head -1
jq --version
git --version
gh --version | head -1
echo "NOTE: no Rust code, crate or dependency is involved in R43; the toolchain"
echo "      lines are recorded because the role requires them, not because any"
echo "      check below compiles anything."

# ---------------------------------------------------------------------------
say "1. Vendor documentation — does the text say what the raws quote?"
echo "This tier proves only what the vendors DOCUMENT. It does not prove that any"
echo "installed build behaves that way; no vendor product is run by this script."

fetch https://cursor.com/docs/rules "$DOC/cursor-rules.html"
CUR="$DOC/cursor-rules.html"
ck "cursor: mentions AGENTS.md"                 1 "$([ "$(cnt 'AGENTS.md' "$CUR")" -gt 0 ] && echo 1 || echo 0)"
ck "cursor: 'alternative to' + .cursor/rules"   1 "$(grep -ci 'alternative to' "$CUR" | awk '{print ($1>0)?1:0}')"
ck "cursor: documents project rules dir"        1 "$([ "$(cnt '.cursor/rules' "$CUR")" -gt 0 ] && echo 1 || echo 0)"
ck "cursor: documents alwaysApply frontmatter"  1 "$([ "$(cnt 'alwaysApply' "$CUR")" -gt 0 ] && echo 1 || echo 0)"
ck "cursor: documents globs frontmatter"        1 "$([ "$(cnt 'globs' "$CUR")" -gt 0 ] && echo 1 || echo 0)"
# The Cursor page is a 550 KB single-page app; strip tags to plain prose before
# asserting on wording, because a raw grep over the markup matches <meta> tags.
python3 - "$CUR" > "$DOC/cursor-rules.txt" <<'PYX'
import html, re, sys
raw = open(sys.argv[1], encoding="utf-8", errors="replace").read()
text = html.unescape(re.sub(r"<[^>]+>", " ", raw))
sys.stdout.write(re.sub(r"\s+", " ", text))
PYX
CURT="$DOC/cursor-rules.txt"
ck "cursor: AGENTS.md is one of its rule types"  1 "$(grep -ci 'Simple alternative to .cursor/rules' "$CURT" | awk '{print ($1>0)?1:0}')"
ck "cursor: steers plain-markdown users to it"   1 "$(grep -ci 'prefer plain markdown, use AGENTS.md instead' "$CURT" | awk '{print ($1>0)?1:0}')"
ck "cursor: states it supports AGENTS.md in root" 1 "$(grep -ci 'supports AGENTS.md in the project root' "$CURT" | awk '{print ($1>0)?1:0}')"
ck "cursor: documents nested AGENTS.md"          1 "$(grep -ci 'Nested AGENTS.md support in subdirectories' "$CURT" | awk '{print ($1>0)?1:0}')"
echo "-- verbatim prose, the four rule types:"
grep -o -i 'Cursor supports four types of rules.\{0,250\}' "$CURT" | head -1
echo "-- verbatim prose, AGENTS.md section:"
grep -o -i 'AGENTS.md is a simple markdown file.\{0,250\}' "$CURT" | head -1
echo "-- verbatim prose, plain-markdown steer:"
grep -o -i 'A plain .md file in .cursor/rules is ignored.\{0,220\}' "$CURT" | head -1
echo "-- verbatim prose, nested AGENTS.md:"
grep -o -i 'Nested AGENTS.md support in subdirectories.\{0,250\}' "$CURT" | head -1
echo "-- verbatim prose, globs syntax:"
grep -o -i 'Use globs to scope a rule.\{0,140\}' "$CURT" | head -1

for u in desktop/cascade/memories desktop/cascade/agents-md cli/extensibility/rules; do
  f="$DOC/devin-$(basename "$u").md"; fetch "https://docs.devin.ai/$u.md" "$f"
done
MEM="$DOC/devin-memories.md"; AGM="$DOC/devin-agents-md.md"; CLI="$DOC/devin-rules.md"
ck "devin memories: .devin/rules preferred"     1 "$(grep -ci 'preferred' "$MEM" | awk '{print ($1>0)?1:0}')"
ck "devin memories: .windsurf fallback named"   1 "$(grep -ci 'windsurf' "$MEM" | awk '{print ($1>0)?1:0}')"
ck "devin memories: Cascade named the legacy agent" 1 "$(grep -ci 'legacy Cascade agent only' "$MEM" | awk '{print ($1>0)?1:0}')"
ck "devin memories: .windsurf/rules is the fallback" 1 "$(grep -ci '\.windsurf/rules/\*\.md. (fallback)' "$MEM" | awk '{print ($1>0)?1:0}')"
ck "devin agents-md: root = always-on rule"     1 "$(grep -ci 'always.on' "$AGM" | awk '{print ($1>0)?1:0}')"
ck "devin cli: AGENTS.md Recommended"           1 "$(grep -ci 'recommended' "$CLI" | awk '{print ($1>0)?1:0}')"
ck "devin cli: .windsurfrules labelled Legacy"  1 "$(grep -ci 'legacy windsurf' "$CLI" | awk '{print ($1>0)?1:0}')"
ck "devin cli: read_config_from block present"  1 "$(grep -ci 'read_config_from' "$CLI" | awk '{print ($1>0)?1:0}')"
echo "-- verbatim: .devin precedence"
grep -o -i '.\{0,140\}precedence over.\{0,80\}' "$MEM" "$CLI" | head -3
echo "-- verbatim: Cascade marked legacy, and the rule-location table row"
grep -n -i 'legacy Cascade agent only' "$MEM" | head -1
grep -n -i 'preferred) or' "$MEM" | head -1
echo "-- verbatim: root AGENTS.md handling"
grep -o -i '.\{0,140\}always.on.\{0,120\}' "$AGM" | head -3
echo "-- verbatim: agents_standard / cursor / windsurf / claude toggles"
grep -n -A14 'read_config_from' "$CLI" | head -22
echo "-- verbatim: AGENTS.md row of the supported-file table"
grep -n -i 'AGENTS.md' "$CLI" | head -6
echo "-- verbatim: Skills-over-Rules guidance"
grep -o -i '.\{0,120\}Skills instead.\{0,120\}' "$CLI" | head -2

for u in settings settings-reference hooks memory settings-example; do
  fetch "https://code.claude.com/docs/en/$u.md" "$DOC/cc-$u.md"
done
SREF="$DOC/cc-settings-reference.md"; SET="$DOC/cc-settings.md"
HOK="$DOC/cc-hooks.md"; MEMO="$DOC/cc-memory.md"
ck "claude: companyAnnouncements in reference"  1 "$([ "$(cnt 'companyAnnouncements' "$SREF")" -gt 0 ] && echo 1 || echo 0)"
ck "claude: reference grants scope 'Any file'"  1 "$(grep -i 'companyAnnouncements' "$SREF" | grep -ci 'any file' | awk '{print ($1>0)?1:0}')"
ck "claude: random pick across entries"         1 "$(grep -ci 'at random' "$SREF" | awk '{print ($1>0)?1:0}')"
ck "claude: lists merge instead of overriding"  1 "$(grep -ci 'merge instead of overriding' "$SET" | awk '{print ($1>0)?1:0}')"
ck "claude: hooks say use CLAUDE.md instead"    1 "$(grep -ciE "static context that doesn't require a script, use \[CLAUDE\.md\]\([^)]*\) instead" "$HOK" | awk '{print ($1>0)?1:0}')"
ck "claude: successful hook stdout never shown" 1 "$(grep -ci "stdout is never shown in the transcript" "$HOK" | awk '{print ($1>0)?1:0}')"
ck "claude: additionalContext documented"       1 "$([ "$(cnt 'additionalContext' "$HOK")" -gt 0 ] && echo 1 || echo 0)"
ck "claude: memory 'reads CLAUDE.md, not AGENTS.md'" 1 "$(grep -ci 'reads .CLAUDE.md., not .AGENTS.md.' "$MEMO" | awk '{print ($1>0)?1:0}')"
echo "-- verbatim: companyAnnouncements row"
grep -n -i 'companyAnnouncements' "$SREF" | head -3
echo "-- verbatim: list-merge rule and its exempt keys"
grep -n -i -A6 'merge instead of overriding' "$SET" | head -12
echo "-- verbatim: hook stdout / additionalContext audience"
grep -n -i "use \[CLAUDE\.md\]" "$HOK" | head -2
grep -n -i "stdout is never shown in the transcript" "$HOK" | head -2
grep -o -i '.\{0,160\}additionalContext.\{0,200\}' "$HOK" | head -3
echo "-- verbatim: CLAUDE.md vs AGENTS.md"
grep -o -i '.\{0,60\}reads .CLAUDE.md., not .AGENTS.md.\{0,240\}' "$MEMO" | head -2
echo "-- companyAnnouncements framing in the managed-settings example:"
grep -o -i '.\{0,120\}companyAnnouncements.\{0,200\}' "$DOC/cc-settings-example.md" | head -2

# ---------------------------------------------------------------------------
say "2. The Windsurf -> Devin rename: redirects prove the rename, not its date"
for u in https://windsurf.com/ https://docs.windsurf.com/windsurf/cascade/memories https://docs.cursor.com/context/rules; do
  printf '%s -> %s\n' "$u" "$(curl -sSL --max-time 45 -o /dev/null -w '%{url_effective} HTTP %{http_code}' "$u")"
done
fetch https://docs.devin.ai/release-notes/2026.md "$DOC/devin-release-notes.md"
RN="$DOC/devin-release-notes.md"
ck "release notes: occurrences of 'Windsurf'"   0 "$(grep -ci 'windsurf' "$RN" | tr -d ' ')"
echo "earliest 'Devin Desktop' mention in the 2026 release notes:"
grep -n -i 'devin desktop' "$RN" | tail -3
echo "NOTE: a zero count corroborates Opus's report that no first-party page dates"
echo "      the rename. The rename itself is proven by the redirects above."

# ---------------------------------------------------------------------------
say "3. First-party bin is empty: Cargo defines no AI-assistant path"
fetch https://doc.rust-lang.org/cargo/reference/manifest.html "$DOC/cargo-manifest.html"
ck "cargo manifest ref: agent/editor config paths" 0 \
   "$(grep -ciE 'agents\.md|\.cursor|windsurf|companyAnnouncements' "$DOC/cargo-manifest.html" | tr -d ' ')"

# ---------------------------------------------------------------------------
say "4. Pinned source repositories — read through their pins only"
echo "-- ts@${TS_PIN:0:8} vendor rule files present in the pinned tree:"
git -C ~/c/ts-launch-blueprint ls-tree -r --name-only "$TS_PIN" | grep -E '^\.(cursor|windsurf|devin)/' || true
TS_SPOKES=$(git -C ~/c/ts-launch-blueprint ls-tree -r --name-only "$TS_PIN" | grep -cE '^\.(cursor|windsurf|devin)/' | tr -d ' ')
ck "ts pin: vendor rule files (negative control)" 3 "$TS_SPOKES"
PY_SPOKES=$(git -C ~/c/py-launch-blueprint ls-tree -r --name-only "$PY_PIN" | grep -cE '^\.(cursor|windsurf|devin)/|^\.windsurfrules$|^\.cursorrules$' | tr -d ' ')
ck "py pin: vendor rule files"                    0 "$PY_SPOKES"

echo "-- ts@ .cursor/rules/projectenv.mdc (verbatim):"
git -C ~/c/ts-launch-blueprint show "$TS_PIN:.cursor/rules/projectenv.mdc" | cat -A | sed -n '1,14p' | sed 's/\$$//'
echo "-- ts@ .cursor/rules/doc-template.mdc frontmatter (verbatim, first 8 lines):"
git -C ~/c/ts-launch-blueprint show "$TS_PIN:.cursor/rules/doc-template.mdc" | sed -n '1,8p'
GLOBSEQ=$(git -C ~/c/ts-launch-blueprint show "$TS_PIN:.cursor/rules/doc-template.mdc" | sed -n '1,8p' | grep -cE '^[[:space:]]*-[[:space:]]*"docs/\*\*/\*\.md"' | tr -d ' ')
ck "ts pin: doc-template globs is a YAML sequence" 1 "$GLOBSEQ"
POINTER=$(git -C ~/c/ts-launch-blueprint show "$TS_PIN:.cursor/rules/projectenv.mdc" | grep -c 'read rules \./doc-template.mdc' | tr -d ' ')
ck "ts pin: projectenv uses ./path include form"   1 "$POINTER"
echo "NOTE: both are format drift measured against the CURRENT Cursor documentation"
echo "      fetched in section 1. Neither was verified by executing Cursor, and this"
echo "      script does not execute Cursor."

echo "-- ts@ .windsurf/rules/justfile-rules.md (verbatim, first 10 lines):"
git -C ~/c/ts-launch-blueprint show "$TS_PIN:.windsurf/rules/justfile-rules.md" | sed -n '1,10p'
TRIG=$(git -C ~/c/ts-launch-blueprint show "$TS_PIN:.windsurf/rules/justfile-rules.md" | grep -c 'trigger: glob' | tr -d ' ')
ck "ts pin: windsurf rule uses trigger: glob"      1 "$TRIG"

echo "-- py@${PY_PIN:0:8} .claude/settings.json keys:"
git -C ~/c/py-launch-blueprint show "$PY_PIN:.claude/settings.json" | jq -r 'keys[]'
PYANN=$(git -C ~/c/py-launch-blueprint show "$PY_PIN:.claude/settings.json" | jq 'has("companyAnnouncements")')
ck "py pin: has companyAnnouncements"              false "$PYANN"
echo "-- py: the consolidation commit that dropped the vendor rule files:"
git -C ~/c/py-launch-blueprint show --stat --format='%H%n%s' fc8d944b7e439bb4e3f19aaf1b2bdf8da4292a57 | head -12

# ---------------------------------------------------------------------------
say "5. The announcement shape checks, run against the ts pin via stdin"
echo "These prove the assertions are well formed. They do NOT prove Claude Code"
echo "displays a project-scope announcement; no client is launched here."
A3=$(git -C ~/c/ts-launch-blueprint show "$TS_PIN:.claude/settings.json" | jq -e '.companyAnnouncements | length == 1' 2>&1)
ck "A3 ts pin: companyAnnouncements length == 1"   true "$A3"
A4A=$(git -C ~/c/ts-launch-blueprint show "$TS_PIN:.claude/settings.json" | jq -e '.companyAnnouncements[0] | test("ts-launch-blueprint") and test("just ")' 2>&1)
ck "A4a ts pin: names the repo and a just recipe"  true "$A4A"
echo "-- recipe tokens the ts welcome names (the input A4b would cross-check):"
git -C ~/c/ts-launch-blueprint show "$TS_PIN:.claude/settings.json" \
  | jq -r '.companyAnnouncements[0]' | grep -o 'just [a-z][a-z0-9-]*' | awk '{print $2}' | sort -u
echo "NOTE: check A4b (cross-checking those tokens against 'just --summary') is NOT"
echo "      executed. It needs a working tree with a Justfile and the just binary;"
echo "      the rs template does not exist, and running it against the ts working"
echo "      tree instead of the pin would break the pinned-read rule. A4b is carried"
echo "      as an unproven check for P03."

# ---------------------------------------------------------------------------
say "6. Practice evidence — re-checking a subset of Opus's 50-repo census"
echo "Opus reports (2026-09-10): AGENTS.md 24/50, .cursor/ 1/50, .windsurf/ 0/50,"
echo ".devin/ 0/50. Re-checked below for 12 of those repositories."
SUB="rust-lang/rust rust-lang/cargo BurntSushi/ripgrep astral-sh/ruff astral-sh/uv \
tokio-rs/tokio tokio-rs/axum clap-rs/clap nushell/nushell surrealdb/surrealdb \
meilisearch/meilisearch casey/just"
AG=0; CU=0; WS=0; DV=0; CL=0; N=0
for r in $SUB; do
  t=$(gh api "repos/$r/git/trees/HEAD" --jq '.tree[].path' 2>/dev/null)
  [ -z "$t" ] && { echo "  $r: API returned nothing (treated as no data, not a state)"; continue; }
  N=$((N+1))
  a=$(printf '%s\n' "$t" | grep -cx 'AGENTS.md' | tr -d ' ')
  c=$(printf '%s\n' "$t" | grep -cx '.cursor' | tr -d ' ')
  w=$(printf '%s\n' "$t" | grep -cx '.windsurf' | tr -d ' ')
  d=$(printf '%s\n' "$t" | grep -cx '.devin' | tr -d ' ')
  k=$(printf '%s\n' "$t" | grep -cx '.claude' | tr -d ' ')
  AG=$((AG+a)); CU=$((CU+c)); WS=$((WS+w)); DV=$((DV+d)); CL=$((CL+k))
  printf '  %-28s AGENTS.md=%s .cursor=%s .windsurf=%s .devin=%s .claude=%s\n' "$r" "$a" "$c" "$w" "$d" "$k"
done
printf 'subset totals (n=%s): AGENTS.md=%s .cursor=%s .windsurf=%s .devin=%s .claude=%s\n' "$N" "$AG" "$CU" "$WS" "$DV" "$CL"
ck "subset: repositories committing .windsurf/"    0 "$WS"
ck "subset: repositories committing .devin/"       0 "$DV"

echo "-- companyAnnouncements in the Rust .claude/settings.json adopters Opus read:"
for r in astral-sh/ruff astral-sh/uv biomejs/biome swc-project/swc; do
  body=$(gh api "repos/$r/contents/.claude/settings.json" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null)
  if [ -z "$body" ]; then echo "  $r: no .claude/settings.json returned"; else
    printf '  %-20s keys=[%s] companyAnnouncements=%s\n' "$r" \
      "$(printf '%s' "$body" | jq -r 'keys | join(",")')" \
      "$(printf '%s' "$body" | jq 'has("companyAnnouncements")')"
  fi
done

# ---------------------------------------------------------------------------
say "7. The three GitHub issues the raws cite"
for n in 39998 22425 32221; do
  printf 'anthropics/claude-code#%s: ' "$n"
  gh api "repos/anthropics/claude-code/issues/$n" \
    --jq '"\(.title) | state=\(.state) reason=\(.state_reason) created=\(.created_at) closed=\(.closed_at)"' 2>&1 | head -1
done

say "Result"
printf 'failed checks: %s\n' "$FAIL"
date -u +'run finished %Y-%m-%dT%H:%M:%SZ'
rm -rf "$DOC"
exit "$FAIL"
