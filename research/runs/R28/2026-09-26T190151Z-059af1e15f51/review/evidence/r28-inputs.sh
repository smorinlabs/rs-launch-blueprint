#!/usr/bin/env bash
# R28 revision 3 — input integrity, citation resolution and decision shape.
# Offline; reads this run directory, the two prerequisite decisions, the
# canonical R28 prompt, the R30 prompt and the research index.
# Paths resolve from this script's own location, so the working directory
# does not matter. Every case prints PASS or FAIL; exit 1 on any FAIL.
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)
run=$(cd "$here/../.." && pwd)
root=$(cd "$run/../../../.." && pwd)
echo "== run:  $run"
echo "== root: $root"
command -v python3 shasum shellcheck
python3 --version

python3 - "$run" "$root" <<'PY'
import hashlib, json, re, subprocess, sys
from pathlib import Path

run, root = Path(sys.argv[1]), Path(sys.argv[2])
fails = 0
def ok(cid, msg): print(f"PASS {cid} — {msg}")
def bad(cid, msg):
    global fails; fails += 1; print(f"FAIL {cid} — {msg}")
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()

dec_path = run / "review/DECISION.md"
dec = dec_path.read_text()
manifest = json.loads((run / "manifest.json").read_text())
R11 = root / "research/topics/11-ci-workflow-job-structure"
R42 = root / "research/topics/42-dev-toolchain-provisioning"

print("\n== I1 run inputs hash to the values manifest.json recorded")
ih = manifest["input_hashes"]
for key, rel in [("prompt", "inputs/prompt.md"), ("policy", "inputs/EXECUTION.json"),
                 ("prerequisites", "inputs/prerequisites.json"), ("parameters_semantic_file", "inputs/parameters.json")]:
    got = sha(run / rel)
    (ok if got == ih[key] else bad)(f"I1-{key}", f"{rel} {got[:12]}… vs manifest {ih[key][:12]}…")
canon = root / "research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md"
# Expected drift: the owner's Q17.A engine decision (2026-09-27) edited the
# canonical prompt after this run's snapshot. Exactly two lines may differ.
import difflib
snap_l = (run / "inputs/prompt.md").read_text().splitlines()
canon_l = canon.read_text().splitlines()
diff = [l for l in difflib.unified_diff(snap_l, canon_l, "inputs/prompt.md", "canonical", n=0, lineterm="")]
for l in diff: print("  " + l)
changed = [(i, a, b) for i, (a, b) in enumerate(zip(snap_l, canon_l), 1) if a != b]
q17a = "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative."
expected = (len(snap_l) == len(canon_l) and [i for i, _, _ in changed] == [28, 79]
            and changed[0][1:] == ("- engines: codex, opus", "- engines: muse, opus")
            and changed[1][2] == changed[1][1] + " " + q17a)
(ok if expected else bad)("I1-canon", "canonical prompt differs from inputs/prompt.md only by the Q17.A edit (line 28 engines, line 79 Muse sentence)")

print("\n== I2 prerequisite decisions and acceptances are the recorded bytes")
pre = json.loads((run / "inputs/prerequisites.json").read_text())
for item, d in [("R11", R11), ("R42", R42)]:
    for kind, fn in [("decision", "DECISION.md"), ("acceptance", "acceptance.json")]:
        got = sha(d / fn)
        (ok if got == pre[item][kind] else bad)(f"I2-{item}-{kind}", f"{got[:12]}…")

print("\n== I3 raw-report hashes quoted in the decision")
for leg in ["muse", "opus"]:
    h = sha(run / f"raw/{leg}.md")
    print(f"raw/{leg}.md {h}")
    (ok if h in dec else bad)(f"I3-{leg}", "full sha256 quoted in DECISION.md")

print("\n== I4 assumes lines are byte-identical to inputs/parameters.json; nothing owned; no CONFLICT")
params = {r["param"]: r for r in json.loads((run / "inputs/parameters.json").read_text())}
alines = [l for l in dec.splitlines() if l.startswith("- assumes ")]
want = ["msrv-policy", "rust-edition", "target-os-matrix", "license", "ci-job-structure", "package-manager-invocation"]
(ok if len(alines) == len(want) else bad)("I4-count", f"{len(alines)} assumes lines")
for name in want:
    line = f"- assumes {name} = {params[name]['value']}"
    (ok if line in alines else bad)(f"I4-{name}", f"{len(params[name]['value'])} value bytes match")
(ok if "- owns: none (R28 registers no parameter)" in dec.splitlines() else bad)("I4-owns", "owns none")
(ok if not re.search(r"^CONFLICT:", dec, re.M) and not re.search(r"^- CONFLICT:", dec, re.M) else bad)("I4-conflict", "no CONFLICT: line")

print("\n== I5 decision shape")
h2 = re.findall(r"^## (.+)$", dec, re.M)
print("H2:", h2)
(ok if h2 == ["Decision", "Parameters", "Empirical check", "Engines"] else bad)("I5-h2", "exactly Decision, Parameters, Empirical check, Engines (nothing published: no Supersedes)")
title = dec.splitlines()[0]
(ok if re.fullmatch(r"# 2026-09-26 — R28 — linter-and-editor-tooling \(bundle, Focused\) — decision \(revision 3\)", title) else bad)("I5-title", title)
decision = dec.split("\n## Decision\n", 1)[1].split("\n## Parameters\n", 1)[0]
(ok if "\n### Principles and implementation\n" in decision else bad)("I5-principles", "### Principles and implementation under ## Decision")
last = [l for l in decision.splitlines() if l.strip()][-1]
(ok if last.startswith("re-verify: ") else bad)("I5-reverify", "last line of ## Decision is re-verify:")
(ok if "narrowed: no" in dec else bad)("I5-narrowed", "narrowed: no stated")
for fid in ["F085", "F086", "F093", "F094", "F096", "F101", "F109", "F195", "F196"]:
    (ok if fid in decision else bad)(f"I5-{fid}", "settled row named in ## Decision")
(ok if dec.splitlines()[2].startswith("**Revision note, revision 3.**")
    and all(f"**Revision note, revision {n}.**" in dec for n in (2, 1)) else bad)("I5-note", "revision-3 note on line 3; revision-2 and revision-1 notes retained")
for n, want_sha in [(2, "dd4c07b66eb1dc6c405e6c52cdabaa4c1d4e2ce4905ff8ebd4b9f9c1937fe2e4"),
                    (1, "90cbe6ce44b7291afdeca2c3a373f6e2d6a584e204672fc8e6f098ff7511759b")]:
    got = sha(run / f"review/R28-r{n}-snapshot.md")
    (ok if got == want_sha and want_sha in dec else bad)(f"I5-snapshot-r{n}", f"review/R28-r{n}-snapshot.md {got[:12]}… and its sha256 quoted in DECISION.md")

print("\n== I6 every raw citation resolves: line range inside the file and quoted fragment inside the range")
FRAG = {
 ("muse", "3"): "Engine: muse (Meta)",
 ("muse", "4-6"): "the floor today is therefore **1.96**",
 ("muse", "78-85"): "Agreement level is **capability + policy**",
 ("muse", "146-152"): "| A. rustup-component linter (clippy)",
 ("muse", "154"): "No `BASELINE-REVIEW:` finding",
 ("muse", "167"): "`cargo clippy --all-targets` (check-only",
 ("muse", "228-230"): "`marker` and `dylint`: custom-lint authoring frameworks",
 ("muse", "240"): 'all = { level = "deny",',
 ("muse", "240-242"): 'pedantic = { level = "warn", priority = -1 }',
 ("muse", "242"): '`undocumented_unsafe_blocks = "warn"`',
 ("muse", "423"): "Relax test lints with `#[allow(clippy::all, clippy::pedantic)]`",
 ("muse", "481"): '`missing_safety_doc` via `pedantic = "warn"`',
 ("muse", "557-558"): "the editor surfaces the same checks CI runs",
 ("muse", "564"): "so editor and CLI cannot",
 ("muse", "704-707"): "`preLaunchTask: cargo build`",
 ("muse", "715"): "`ms-vscode.cpptools` driving `lldb-mi`",
 ("muse", "802"): "Ship no `.vscode/settings.json` toolchain pin",
 ("muse", "845"): "cannot disagree on the",
 ("muse", "940-946"): "Gaps recorded, not filled",
 ("muse", "195-197"): "the 1.96 floor holds trivially",
 ("muse", "205-206"): "Maintenance state: active (pushed 2 days ago",
 ("muse", "222-223"): "`unsafe` posture inapplicable — not linked into the template",
 ("muse", "225"): "features/async-runtime inapplicable — a compiler driver, not a library",
 ("muse", "225-226"): "zero runtime or binary-size cost",
 ("muse", "416-421"): "F100's exclude-scope question therefore concerns only the formatter side",
 ("muse", "577"): "Maintenance state: active.",
 ("muse", "590"): "MSRV inapplicable — editor extension, not",
 ("muse", "591"): "advisories: rustsec 404; `unsafe` inapplicable",
 ("muse", "592-594"): "the extension host is platform-independent and the project ships server binaries",
 ("muse", "594"): "features/async inapplicable — not a Rust library dependency",
 ("muse", "595-596"): "zero template cost (editor-side only;",
 ("muse", "603-605"): "the same command family R30's gate uses — engine owned there",
 ("muse", "692-693"): "editor extension + prebuilt adapter binary, not compiled into the template",
 ("muse", "693-695"): "advisories inapplicable — not a crates.io package",
 ("muse", "697-698"): "features/async inapplicable — not a Rust library dependency",
 ("muse", "698-699"): "zero template cost (editor-side only; debugs the binaries Cargo already builds)",
 ("opus", "3"): "Engine: `claude-opus-5-5`",
 ("opus", "21-23"): "no clippy run at the floor was executed",
 ("opus", "49"): "`llvm-vs-code-extensions.lldb-dap` (LLDB DAP)",
 ("opus", "64-76"): "Well-regarded projects surveyed",
 ("opus", "78-82"): "VS Code 51.6 %",
 ("opus", "90-94"): "the editor shows the same diagnostics the gate enforces",
 ("opus", "125-132"): "P4 — `.cargo/config.toml`",
 ("opus", "159-161"): 'undocumented_unsafe_blocks = "deny"',
 ("opus", "200"): "| E5b | same on a clean tree | **not executed**",
 ("opus", "207"): "BASELINE-REVIEW: F093",
 ("opus", "207-212"): "pins 0.15.21",
 ("opus", "262-265"): "Issue responsiveness",
 ("opus", "283-292"): "fails the **stable Rust** constraint",
 ("opus", "543-544"): "configured by R16 with `security-extended`",
 ("opus", "626-627"): "extension does not use it by default",
 ("opus", "644"): "Keep ts's cross-platform",
 ("opus", "730"): '"cargo": { "args": ["run"',
 ("opus", "738"): '"cargo": { "args": ["run"',
 ("opus", "810-814"): "Record as an override if the synthesizer accepts it",
 ("opus", "941-943"): "Independence disclosure",
 ("opus", "217-219"): "rust-analyzer's `check.command` already runs the same command, so no extra extension is needed",
 ("opus", "265-266"): "ships every six weeks with rustc",
 ("opus", "269-273"): "the retired `rust-lang-nursery/rust-clippy` URL",
 ("opus", "274-275"): "`LICENSE-APACHE` both present via `GET /repos/rust-lang/rust-clippy/contents/<file>`",
 ("opus", "275-276"): "versioned with rustc, so the floor toolchain's own clippy is used",
 ("opus", "276-278"): "`unsafe` posture inapplicable (a developer tool, not a dependency)",
 ("opus", "279-280"): "every rustup tier-1 host incl. `ubuntu-latest`, `macos-latest`",
 ("opus", "280"): "no default features, no async runtime",
 ("opus", "280-281"): "zero binary-size cost (never linked); compile time ≈ `cargo check` plus lint passes",
 ("opus", "617-622"): "`pushed_at` 2026-09-26T10:35:50Z; open issues 1,696; weekly releases",
 ("opus", "624-628"): "Crate figures **inapplicable** (distributed as a VS Code extension with a bundled server binary",
 ("opus", "627-628"): "`LICENSE-MIT` and `LICENSE-APACHE` both present",
 ("opus", "628"): "MSRV n/a (not a",
 ("opus", "629"): "no RustSec entry (not a crate)",
 ("opus", "629-630"): "bundled binary for Linux, macOS, Windows (S17)",
 ("opus", "630"): "(5) n/a; (6) no binary cost.",
 ("opus", "691-695"): "Maintenance: `active` (release within 6 months), with a concentration signal",
 ("opus", "697-699"): "Crate figures **inapplicable** (VS Code extensions)",
 ("opus", "699"): "(1) CodeLLDB MIT",
 ("opus", "700"): "(2)/(3) n/a",
 ("opus", "700-702"): "Linux with glibc 2.18+ for x86_64, aarch64 or armhf; MacOS 10.12+ for x86_64 and 11.0+ for arm64",
 ("opus", "704"): "(5) n/a; (6) extension download only.",
 ("opus", "916"): "`/releases`, `/commits`, `/contributors` for codelldb",
}
def norm(s): return re.sub(r"\s+", " ", s)
cites = set()
for m in re.finditer(r"`raw/(muse|opus)\.md:([0-9]+(?:-[0-9]+)?)`((?:, `:[0-9]+(?:-[0-9]+)?`)*)", dec):
    leg = m.group(1); cites.add((leg, m.group(2)))
    for c in re.findall(r"`:([0-9]+(?:-[0-9]+)?)`", m.group(3)): cites.add((leg, c))
print(f"{len(cites)} distinct raw citations in DECISION.md")
for key in sorted(cites):
    leg, rng = key
    lines = (run / f"raw/{leg}.md").read_text().splitlines()
    a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
    if key not in FRAG:
        bad(f"I6-{leg}:{rng}", "citation has no fragment in this script's table"); continue
    if not (1 <= a <= b <= len(lines)):
        bad(f"I6-{leg}:{rng}", f"range outside the file ({len(lines)} lines)"); continue
    text = norm(" ".join(lines[a-1:b]))
    (ok if norm(FRAG[key]) in text else bad)(f"I6-{leg}:{rng}", repr(FRAG[key]))
unused = sorted(set(FRAG) - cites)
(ok if not unused else bad)("I6-table", f"no stale table entries {unused if unused else ''}".strip())

print("\n== I7 every prerequisite-decision citation resolves")
PFRAG = {
 ("11-ci-workflow-job-structure", "82"): "Fitness gate 1 (licence) is `inapplicable",
 ("11-ci-workflow-job-structure", "268"): "`-D warnings` is on both clippy steps",
 ("11-ci-workflow-job-structure", "320"): "- owns ci-job-structure = ",
 ("42-dev-toolchain-provisioning", "26"): 'components = ["rustfmt", "clippy"]',
 ("42-dev-toolchain-provisioning", "519-521"): "R28's clippy invocation, whatever flags R28 selects, is written `cargo clippy …`",
}
pc = set(re.findall(r"`research/topics/([0-9a-z-]+)/DECISION\.md:([0-9]+(?:-[0-9]+)?)`", dec))
print(f"{len(pc)} distinct prerequisite citations in DECISION.md")
for key in sorted(pc):
    topic, rng = key
    if not topic.startswith(("11-", "42-")):
        bad(f"I7-{topic}", "cites a decision outside the prerequisites"); continue
    lines = (root / f"research/topics/{topic}/DECISION.md").read_text().splitlines()
    a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
    if key not in PFRAG or not (1 <= a <= b <= len(lines)):
        bad(f"I7-{topic}:{rng}", "no fragment or range outside file"); continue
    (ok if norm(PFRAG[key]) in norm(" ".join(lines[a-1:b])) else bad)(f"I7-{topic}:{rng}", repr(PFRAG[key]))

print("\n== I8 the provenance statements are true of the snapshot")
policy = json.loads((run / "inputs/EXECUTION.json").read_text())
r28 = policy["items"]["R28"]
(ok if r28["engines"] == ["codex", "opus"] and r28["tier"] == "focused" else bad)("I8-engines", f"R28 engines {r28['engines']}, tier {r28['tier']}")
(ok if "R28" not in policy.get("engine_overrides", {}) else bad)("I8-override", "no engine_overrides entry for R28")
(ok if manifest["operations"] == {} and not any((run / "operations").iterdir()) else bad)("I8-operations", "manifest operations {} and operations/ empty")
(ok if manifest["required_engines"] == ["codex", "opus"] else bad)("I8-required", f"required_engines {manifest['required_engines']}")
(ok if sorted(p.name for p in (run / "raw").iterdir()) == ["muse.md", "opus.md"] else bad)("I8-raw", "raw/ holds exactly muse.md and opus.md")

print("\n== I9 every other evidence log reports zero failures with the case counts the decision's table states")
counts = {"r28-lint-table": 13, "r28-test-relaxation": 11, "r28-autofix": 5, "r28-floor": 5,
          "r28-editor-config": 6, "r28-sources": 10, "r28-live-figures": 7, "r28-ruff-fix-default": 2}
ev = run / "review/evidence"
for name, n in counts.items():
    log = (ev / f"{name}.log").read_text()
    p = len(re.findall(r"^PASS ", log, re.M)); f = len(re.findall(r"^FAIL ", log, re.M))
    good = p == n and f == 0 and "== summary: 0 failing case(s)" in log
    (ok if good else bad)(f"I9-{name}", f"PASS {p} FAIL {f} (expected {n})")
    (ok if f"| `{name}.sh` |" in dec and f"PASS {n}, FAIL 0" in dec else bad)(f"I9-{name}-table", "row present in ## Empirical check")

print("\n== I10 every evidence script passes shellcheck")
for sh in sorted(ev.glob("*.sh")):
    r = subprocess.run(["shellcheck", str(sh)], capture_output=True, text=True)
    (ok if r.returncode == 0 else bad)(f"I10-{sh.name}", "shellcheck clean" if r.returncode == 0 else r.stdout[:300])
logs = {p.stem for p in ev.glob("*.log")}; shs = {p.stem for p in ev.glob("*.sh")}
(ok if logs == shs else bad)("I10-pairs", f"one .log per .sh ({len(shs)} scripts)")

print("\n== I11 every other file:line citation, and the R30 status claim, resolves")
OFRAG = {
 ("inputs/prompt.md", "31"): "R30 (`type-check-gate`) owns the type-checker engine",
 ("research/topics/30-type-check-gate/prompts/type-check-gate.prompt.md", "9"): "F107 single engine serving both CI and editor",
}
oc = set(re.findall(r"`((?:inputs/[a-z.]+\.md)|(?:research/topics/[0-9a-z-]+/prompts/[0-9a-z.-]+\.md)):([0-9]+(?:-[0-9]+)?)`", dec))
print(f"{len(oc)} distinct other file:line citations in DECISION.md")
for key in sorted(oc):
    rel, rng = key
    base = run if rel.startswith("inputs/") else root
    lines = (base / rel).read_text().splitlines()
    a, _, b = rng.partition("-"); a = int(a); b = int(b) if b else a
    if key not in OFRAG or not (1 <= a <= b <= len(lines)):
        bad(f"I11-{rel}:{rng}", "no fragment or range outside file"); continue
    (ok if norm(OFRAG[key]) in norm(" ".join(lines[a-1:b])) else bad)(f"I11-{rel}:{rng}", repr(OFRAG[key]))
(ok if not sorted(set(OFRAG) - oc) else bad)("I11-table", "no stale table entries")
row = [l for l in (root / "research/CLAUDE.md").read_text().splitlines() if l.startswith("| R30 | type-check-gate |")]
(ok if len(row) == 1 and row[0].rstrip().endswith("| open |") and "`research/CLAUDE.md`, row R30" in dec else bad)("I11-R30-open", "research/CLAUDE.md row R30 status is open, as the decision states")

print(f"\n== summary: {fails} failing case(s)")
sys.exit(1 if fails else 0)
PY
