#!/usr/bin/env bash
# R32 E10 — every line citation in review/DECISION.md resolves to a line that
# carries its token; the assumes lines are the registered bytes; the prerequisite
# decisions are the ones this run was prepared against; the H2 shape.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN="$(cd "$HERE/../.." && pwd)"
ROOT="$(cd "$RUN/../../../.." && pwd)"
echo "INFO run=$RUN root=$ROOT"
python3 - "$RUN" "$ROOT" <<'PY'
import re, sys, json, hashlib, glob
run, root = sys.argv[1], sys.argv[2]
D = open(f'{run}/review/DECISION.md').read()
P = F = 0
def res(ok, cid, desc):
    global P, F
    if ok: P += 1; print(f'PASS {cid} — {desc}')
    else:  F += 1; print(f'FAIL {cid} — {desc}')
PATH = {
  'R11 DECISION.md': f'{root}/research/topics/11-ci-workflow-job-structure/DECISION.md',
  'cargo-targets.md': f'{run}/review/evidence/snapshots/cargo-targets.md',
  'test-groups.md':   f'{run}/review/evidence/snapshots/nx-test-groups.md',
  'tests/index.md':   f'{run}/review/evidence/snapshots/rustc-tests-index.md',
  'running.md':       f'{run}/review/evidence/snapshots/nx-running.md',
  'partitioning.md':  f'{run}/review/evidence/snapshots/nx-partitioning.md',
}
def path(f):
    if f in PATH: return PATH[f]
    if f.startswith(('raw/', 'inputs/', 'review/')): return f'{run}/{f}'
    return f'{root}/{f}'
# (file, range) -> token that must occur in that line range
T = {
 ('R11 DECISION.md','282'): 'the tier names inside `check`',
 ('R11 DECISION.md','294'): "**The rustdoc part is `check`'s doc build step**",
 ('cargo-targets.md','126-127'): 'will run them serially',
 ('inputs/prompt.md','23'): '- owns:',
 ('inputs/prompt.md','26'): '- engines: codex, opus, doxa',
 ('inputs/prompt.md','8-9'): 'F173 opt-in pre-push full-suite hook',
 ('inputs/prompt.md','58'): '| Issue responsiveness | 10 most recently opened issues |',
 ('partitioning.md','8'): 'using the `--partition` option',
 ('partitioning.md','31'): '`--partition slice:m/n`',
 ('partitioning.md','55'): '`--partition hash:m/n`',
 ('partitioning.md','57'): 'completely deterministic',
 ('partitioning.md','63'): '`--partition count:m/n`',
 ('raw/doxa-gemini.normalized.md','166'): 'Command::cargo_bin("rs-launch-blueprint")',
 ('raw/doxa-gemini.normalized.md','176'): '19,468,971',
 ('raw/doxa-gemini.normalized.md','178'): '127+',
 ('raw/doxa-gemini.normalized.md','188-198'): '`owns F117 = cargo-nextest`',
 ('raw/doxa-gemini.normalized.md','199-203'): '`assumes ci-job-structure = open`',
 ('raw/doxa-gemini.normalized.md','207'): 'slow-timeout = "60s"',
 ('raw/doxa-gemini.normalized.md','208'): 'predicates = "3.0.1"',
 ('raw/doxa-gemini.normalized.md','209'): 'A flat, non-subdirected `tests/` directory',
 ('raw/doxa-gemini.normalized.md','21-23'): 'Architectural Pattern',
 ('raw/doxa-gemini.normalized.md','211'): 'RS_PROJECTS_PREPUSH_TESTS=1',
 ('raw/doxa-gemini.normalized.md','27'): 'BASELINE-REVIEW: F124',
 ('raw/doxa-gemini.normalized.md','29'): 'BASELINE-REVIEW: F125',
 ('raw/doxa-gemini.normalized.md','31'): "Nextest's `setup-scripts`",
 ('raw/doxa-gemini.normalized.md','33'): 'both the default `cargo test` runner and `cargo-nextest` parallelize',
 ('raw/doxa-openai.normalized.md','130-157'): '├── slow.rs',
 ('raw/doxa-openai.normalized.md','14'): '`test-r`; `cargo-maelstrom`',
 ('raw/doxa-openai.normalized.md','157'): '#[path = "..."]',
 ('raw/doxa-openai.normalized.md','227'): 'CARGO_BIN_EXE_rs-launch',
 ('raw/doxa-openai.normalized.md','273'): 'BASELINE-REVIEW: F124',
 ('raw/doxa-openai.normalized.md','275'): 'BASELINE-REVIEW: F128',
 ('raw/doxa-openai.normalized.md','285'): '`cargo-nextest 0.9.145`',
 ('raw/doxa-openai.normalized.md','295'): 'serial default; opt-in `parallel` profile',
 ('raw/doxa-openai.normalized.md','297'): 'R32-owned Cargo dev-dependencies:** **none**',
 ('raw/doxa-openai.normalized.md','37'): '`test-r 3.0.12`',
 ('raw/doxa-openai.normalized.md','42'): 'were inaccessible to the research transport',
 ('raw/doxa-openai.normalized.md','50'): 'bounded, reproducible confidence',
 ('raw/doxa-openai.normalized.md','553'): '`serial_test` is not needed as a baseline dependency',
 ('raw/doxa-openai.normalized.md','627'): 'Add `assert_cmd` if the process tier grows',
 ('raw/doxa-openai.normalized.md','718'): 'RS_LAUNCH_PREPUSH_TESTS',
 ('raw/doxa-openai.normalized.md','728'): 'git config core.hooksPath .githooks',
 ('raw/doxa-openai.normalized.md','828-838'): 'owns test-runner = cargo-nextest 0.9.145',
 ('raw/doxa-openai.normalized.md','840-846'): 'CONFLICT: none',
 ('raw/doxa-openai.normalized.md','86'): 'test-threads = 1',
 ('raw/muse.md','134'): '`tempfile 3.27.0`',
 ('raw/muse.md','220-221'): 'terminate-after-2 bounds a hung test at ~3 min',
 ('raw/muse.md','3'): 'Engine: muse (Meta). Model family: meta',
 ('raw/muse.md','42-45'): 'Cargo nextest does not support doctest',
 ('raw/muse.md','440-445'): 'R33',
 ('raw/muse.md','467'): 'serial_test = { version = "3", default-features = false }',
 ('raw/muse.md','47-49'): 'assert_cmd = "1.0.8"',
 ('raw/muse.md','52-55'): 'serial_test 155.1M',
 ('raw/muse.md','543-545'): 'F129 layout: flat tier-named files',
 ('raw/muse.md','555-556'): 'F131: NO flag',
 ('raw/muse.md','556'): 'sharding uses nextest `--partition` (CI concern, not template default)',
 ('raw/muse.md','559-561'): "Rust-side var name is R37's",
 ('raw/muse.md','661-663'): 'tokio runs nextest',
 ('raw/muse.md','687'): 'assumes `ci-job-structure = <accepted R11 value',
 ('raw/muse.md','692'): 'No `CONFLICT:` lines',
 ('raw/muse.md','71-93'): 'P-budget',
 ('raw/opus.md','1038'): 'RS_PROJECTS_PREPUSH_TESTS:-0',
 ('raw/opus.md','1114-1117'): '`astral-sh/uv` uses `cargo-nextest`',
 ('raw/opus.md','1118-1120'): 'cargo test --doc',
 ('raw/opus.md','1144'): '`CONFLICT: R11 ci-job-structure',
 ('raw/opus.md','119-122'): 'The default test run is fast, hermetic, order-independent',
 ('raw/opus.md','1238-1240'): 'are each one to seven lines off',
 ('raw/opus.md','151-160'): 'ts accidental drift',
 ('raw/opus.md','196-198'): 'It offers *partitioning*',
 ('raw/opus.md','209-214'): '`ntest`',
 ('raw/opus.md','3'): 'claude-opus-5-5',
 ('raw/opus.md','317-324'): 'none — cargo test already parallelizes test binaries by default',
 ('raw/opus.md','325'): 'BASELINE-REVIEW: F129',
 ('raw/opus.md','418'): 'ubuntu-latest, ubuntu-24.04-arm, macos-latest, windows-latest',
 ('raw/opus.md','425'): 'median 0.18 days',
 ('raw/opus.md','436-448'): 'Under M1, `#[serial]` would silently',
 ('raw/opus.md','452-458'): '`test-r` 3.0.12',
 ('raw/opus.md','55-61'): '`ntest` 0.9.5',
 ('raw/opus.md','62-64'): '`libtest2-mimic` 0.0.4',
 ('raw/opus.md','689'): 'ubuntu-latest, windows-latest, macos-latest',
 ('raw/opus.md','696'): 'median 0 days',
 ('raw/opus.md','701-702'): '`escargot` is not excluded but is unnecessary',
 ('raw/opus.md','789-793'): '`tests/cli/main.rs` declares',
 ('raw/opus.md','94-111'): '`.config/nextest.toml`',
 ('raw/opus.md','96'): '`Cargo.toml:369` `assert_cmd`',
 ('raw/opus.md','96-102'): 'oxidecomputer/omicron',
 ('research/RUNBOOK.md','73-76'): 'Q17.A (2026-09-27)',
 ('research/topics/01-ports-and-adapters-seam/DECISION.md','3'): 'struck fitness gate 1',
 ('research/topics/11-ci-workflow-job-structure/DECISION.md','320'): 'cargo test with the feature off scoped by -p to the non-web packages',
 ('research/topics/11-ci-workflow-job-structure/DECISION.md','329'): 'crates/web/tests/',
 ('research/topics/49-build-target-declaration/DECISION.md','13'): 'R32 resolves the built binary',
 ('research/topics/49-build-target-declaration/DECISION.md','727-731'): 'is then not set for integration tests',
 ('research/topics/69-web-framework-stack/DECISION.md','2310-2316'): "**That call is R32's**",
 ('running.md','58'): 'Doctests are currently',
 ('test-groups.md','21'): 'you can emulate them by using test groups',
 ('tests/index.md','211-213'): '#89583',
}
cites = []; last = None
for m in re.finditer(r'`?((?:raw|inputs|research|review)/[\w./-]+?\.md|R11 DECISION\.md|(?<![\w/])cargo-targets\.md|(?<![\w/])test-groups\.md|tests/index\.md|(?<![\w/])running\.md|(?<![\w/])partitioning\.md):(\d+(?:-\d+)?)|`:(\d+(?:-\d+)?)`', D):
    if m.group(1): last = m.group(1); cites.append((last, m.group(2)))
    else: cites.append((last, m.group(3)))
cites = sorted(set(cites))
print(f'INFO {len(cites)} distinct line citations in DECISION.md')
res(set(cites) == set(T), 'E10-cover', f'the token table covers exactly the cited set (missing {sorted(set(cites)-set(T))}, extra {sorted(set(T)-set(cites))})')
for (f, r) in cites:
    if (f, r) not in T: continue
    a, _, b = r.partition('-'); a = int(a); b = int(b or a)
    lines = open(path(f), encoding='utf-8').read().split('\n')
    ok = b <= len(lines) and T[(f, r)] in '\n'.join(lines[a-1:b])
    res(ok, f'E10 {f}:{r}', f'carries {T[(f, r)]!r}')
# assumes lines are the registered bytes, in the run's snapshot
params = json.load(open(f'{run}/inputs/parameters.json'))
reg = {p['param']: p['value'] for p in params}
got = [l for l in D.split('\n') if l.startswith('- assumes ')]
res(len(got) == 9, 'E10-assumes-n', f'nine assumes lines ({len(got)})')
for l in got:
    k, _, v = l[len('- assumes '):].partition(' = ')
    res(reg.get(k) == v, f'E10-assumes {k}', 'byte-identical to inputs/parameters.json')
res(not re.search(r'^- owns ', D, re.M), 'E10-owns', 'no owns line (the prompt owns nothing)')
res(len(re.findall(r'^`CONFLICT: R11 ci-job-structure — ', D, re.M)) == 1, 'E10-conflict', 'exactly one CONFLICT line, against R11')
# prerequisites are the decisions this run was prepared against
pre = json.load(open(f'{run}/inputs/prerequisites.json'))
for k, v in pre.items():
    d = glob.glob(f'{root}/research/topics/{k[1:]}-*/')[0]
    for f, h in (('DECISION.md', v['decision']), ('acceptance.json', v['acceptance'])):
        res(hashlib.sha256(open(d + f, 'rb').read()).hexdigest() == h, f'E10-pre {k} {f}', 'matches inputs/prerequisites.json')
# shape
h2 = re.findall(r'^## (.+)$', D, re.M)
res(h2 == ['Decision', 'Parameters', 'Empirical check', 'Engines'], 'E10-h2', f'H2 set {h2}')
res(bool(re.match(r'# \d{4}-\d{2}-\d{2} — R32 — test-harness-and-execution \(bundle, Deep\) — decision \(revision 2\)\n', D)), 'E10-title', 'title line with date and revision 2')
dec = D.split('\n## Parameters')[0]
res('\n### Principles and implementation\n' in dec, 'E10-principles', '### Principles and implementation under ## Decision')
res(bool(re.search(r'^re-verify: ', dec, re.M)), 'E10-reverify', 're-verify: line at the end of ## Decision')
res('@@' not in D, 'E10-placeholders', 'no unfilled placeholder')
print(f'RESULT PASS={P} FAIL={F}')
sys.exit(1 if F else 0)
PY
