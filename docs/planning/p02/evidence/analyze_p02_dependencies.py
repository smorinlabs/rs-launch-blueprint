#!/usr/bin/env python3
"""Reproduce the historical P02 dependency and effort comparison at BASE_COMMIT.

This is intentionally a planning-only tool: it reads prompt metadata and writes
only docs/planning/p02 artifacts.  It implements the two RUNBOOK.md edge rules
verbatim and keeps the R58 amendment as a separate simulated graph.
"""
from __future__ import annotations

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
BASE_COMMIT = "2f3569051af2c2089f60f6cad129bc6e55482c30"
# Reproduce the reviewed before/after graph, even after A6 changes this checkout.
PROMPTS = [ROOT / name for name in subprocess.check_output(
    ["git", "ls-tree", "-r", "--name-only", BASE_COMMIT, "research/topics"],
    cwd=ROOT, text=True).splitlines() if name.endswith(".prompt.md")]
OUT = ROOT / "docs/planning/p02"
ID_RE = re.compile(r"R\d{2}")

# Proposed execution effort. This is not an amendment to RUNBOOK.md section 2:
# that section still requires every configured engine until its owner changes it.
# Deep needs consequential impact *and* unresolved uncertainty, a hard-to-reverse
# choice, or compatibility across subsystems. A public/security adapter with a
# fixed upstream policy can be Focused; an owner is never Light.
DEEP = {
    "R01", "R02", "R03", "R05", "R11", "R18", "R25", "R32", "R42", "R49",
    "R54", "R56", "R58", "R60", "R66", "R67", "R68", "R69", "R71", "R72",
    "R73", "R74", "R75", "R78", "R84",
}

# These have consequence beyond Light's local/reversible bar, but their prompt
# scope remains a bounded integration rather than a Deep architecture decision.
# The set also excludes public/security adapters from Light where their selected
# upstream policy has not yet been proven sufficient. All owners remain Focused
# or Deep independently of this set.
LIGHT = {"R22", "R23", "R24", "R41", "R46", "R47"}

# Concrete empirical acceptance criteria, derived from each prompt's Objective,
# Value test, and HIGH questions.  These are proposed gates, not claimed runs.
ACCEPTANCE = {
    "R01": "Fake and production adapters pass one substitutability suite through the selected seam.",
    "R02": "A forbidden cross-crate import fails while the permitted composition root builds.",
    "R03": "Fixtures prove missing-resource and transport-failure behavior follows the selected public error contract and exit mapping.",
    "R04": "A public-API fixture proves the selected export boundary admits intended symbols and detects the selected class of accidental exposure.",
    "R05": "CLI, library, and web examples complete the selected sync/async request path without blocking misuse.",
    "R06": "Unsafe-code fixtures prove the selected allow, deny, or justification policy is enforced at the declared crate boundary.",
    "R07": "Workflow fixtures prove the contributor bot fires only for the selected event and cadence.",
    "R08": "A workflow permission audit rejects a job with broader permissions than its declared need.",
    "R09": "Rendered workflow YAML uses the selected runner indirection in every relevant job.",
    "R10": "A cold and warm Cargo build show the selected cache key restores only compatible artifacts.",
    "R11": "A changed-path fixture proves required checks and skip-gating have the selected job behavior.",
    "R12": "If an aggregate status check is selected, passing and failing constituent fixtures prove its declared merge-gating semantics; otherwise document the replacement gate.",
    "R13": "A vulnerable fixture dependency makes the selected scanner fail in the selected CI placement.",
    "R14": "If a guard is selected, oversized-file fixtures exercise every selected local and CI tier; if none is selected, record the evidence and residual risk.",
    "R15": "A hermetic self-press fixture generates a buildable renamed copy, and a separate committed-receipt fixture is rejected by the receipt guard.",
    "R16": "A fixture proves the selected CodeQL applicability outcome: configured analysis and exclusions if adopted, or documented non-applicability and compensating coverage if not.",
    "R17": "A planted secret fixture fails the selected CI scanner without exposing the secret in output.",
    "R18": "A PR-event fixture proves each configured AI review workflow is safe and trigger-limited.",
    "R19": "A static configuration fixture validates the selected update groups, schedules, and allow/ignore rules; no live bot PR is required.",
    "R20": "Policy fixtures cover the selected action-reference policy and every declared exception, including its permitted and refused references.",
    "R21": "A dry-run fixture proves the selected credential source, access scope, and absent-credential behavior without using a real secret.",
    "R22": "Built binary and library report the same package version through the selected accessor.",
    "R23": "A version bump fixture fails until Cargo manifest, lockfile, and release metadata agree.",
    "R24": "Representative commit types map to the intended changelog sections.",
    "R25": "Breaking, feature, and fix fixtures produce the selected semver bump classifications.",
    "R26": "Packed-crate inspection rejects an unexpected file and permits the declared artifact set.",
    "R27": "A deliberately misformatted Rust file fails the selected formatter check and is repaired deterministically.",
    "R28": "A clippy/editor fixture reports the selected lint configuration on both supported OS runners.",
    "R29": "Misformatted TOML, YAML, JSON, and Markdown fixtures fail the selected non-code formatting gate.",
    "R30": "A type-error fixture fails the selected type-check gate in CI and the documented editor path.",
    "R31": "A security-analyzer fixture finds a known insecure Rust pattern with the expected severity handling.",
    "R32": "Unit, integration, and built-binary tiers run the selected test command and isolate their fixtures.",
    "R33": "A generated counterexample and a snapshot mismatch both fail with actionable reproduction output.",
    "R34": "Scheduled-workflow fixtures prove advisory checks do not block the normal PR lane.",
    "R35": "Coverage gate reports the selected threshold and fails a deliberately uncovered branch.",
    "R37": "Hook install and a staged commit prove the selected manager invokes the intended stages.",
    "R38": "Invalid commit header/body/footer fixtures fail the selected commit-message convention check.",
    "R39": "A staged secret fixture is blocked locally and its value is redacted from diagnostics.",
    "R40": "One fixture per hygiene hook demonstrates its selected stage, failure, and repair command.",
    "R41": "A stale Cargo.lock fixture is rejected by the selected freshness check.",
    "R42": "A clean checkout provisions and invokes one selected dev tool through the documented recipe.",
    "R43": "AI-assistant instruction fixtures show the selected repo furniture is discoverable and non-conflicting.",
    "R44": "If adopted, a fresh devcontainer build invokes R42's approved setup and runs its smoke command; otherwise demonstrate the documented host setup and justify omitting the container.",
    "R45": "A PR-comment fixture proves the bot ignores untrusted or malformed trigger text.",
    "R46": "A new source-file fixture is accepted only with the selected license-header policy applied.",
    "R47": "Contributor recipe mode fixtures prove default and opt-in commands select the intended behavior.",
    "R48": "A mock HTTP failure and success exercise the selected test-double mechanism through R01's seam.",
    "R49": "Cargo metadata and a clean build prove selected bin, lib, and artifact names match the contract.",
    "R50": "A packed artifact installs in a clean temporary prefix and its binary completes a smoke command.",
    "R51": "Container build, startup, and selected health probe pass with the web feature both enabled and disabled.",
    "R52": "Valid, malformed, and duplicate-key TOML fixtures follow the selected parser/error contract.",
    "R53": "Invalid config field fixtures produce the selected validation errors without accepting partial bad state.",
    "R54": "Conflicting config files prove the selected discovery order and precedence.",
    "R55": "Missing, unparsable, and invalid-layer fixtures prove the selected tolerate-or-fail behavior.",
    "R56": "Secret-bearing config fixtures prove redaction and the selected storage/override policy.",
    "R57": "OS-specific environment fixtures resolve every selected XDG directory and its fallback.",
    "R58": "CLI and web request paths emit structured redacted logs, preserve host ownership, and correlate a trace when enabled.",
    "R59": "If a file sink is selected, two sinks with different levels rotate at the selected limit and retain events accepted by either; otherwise prove the omitted config/flag surface is absent.",
    "R60": "Representative CLI invocations prove parsing, help, version, and error behavior match the selected framework contract.",
    "R61": "Interactive and non-TTY fixtures prove selected prompts are cancellable and never block scripted use.",
    "R62": "If clipboard support is selected, success and unavailable-backend fixtures prove its fallback/error behavior; otherwise prove the selected omission is explicit.",
    "R63": "If a spinner is selected, TTY and redirected-output fixtures prove it never contaminates a selected machine-readable mode; otherwise prove the selected omission.",
    "R64": "If a pager is selected, TTY, no-pager, and pager-failure fixtures prove output preservation; otherwise prove the selected direct-output behavior.",
    "R65": "TTY, NO_COLOR, explicit color, and redirected-output fixtures prove precedence and no escape leakage.",
    "R66": "Each selected output mode renders its declared shape, and modes designated machine-readable contain no terminal markup.",
    "R67": "Representative domain, config, and cancellation failures map to the selected stable exit-code catalog.",
    "R68": "If binary artifacts are selected, the release workflow produces each and verifies its checksum/signature contract; otherwise prove the chosen crates-only release path.",
    "R69": "Feature-on web server handles a real request with graceful shutdown; feature-off workspace still builds.",
    "R70": "A domain error produces the selected RFC-style HTTP envelope with stable status and fields.",
    "R71": "If the selected web surface has OpenAPI, its generated schema is committed, validates, and its CI diff check detects an API change; otherwise record the compatible no-schema path.",
    "R72": "Fixtures prove the selected pagination strategy's declared boundary, ordering, malformed-input, and response-shape behavior without assuming cursor pagination.",
    "R73": "If idempotency middleware is selected, repeated-request fixtures prove replay, conflict, expiry, and response behavior; otherwise record the chosen absence boundary.",
    "R74": "If rate limiting is selected, threshold and recovery fixtures prove its algorithm, identity scope, status, headers, and exceptions; otherwise record the chosen absence boundary.",
    "R75": "Middleware-order integration test proves request ID, logging, security headers, and error behavior compose once.",
    "R76": "Allowed, denied, preflight, credentialed, and cache fixtures prove the selected CORS policy and declared exception cases.",
    "R77": "Environment fixtures validate required web settings, defaults, and redacted error reporting.",
    "R78": "A real request propagates incoming context through handler and outbound spans; a collector receives correlated spans/logs and useful request metrics; shutdown and collector-failure fixtures preserve the required behavior.",
    "R79": "If metrics are selected, a real request increments them with only documented label cardinality; otherwise prove the selected no-metrics boundary.",
    "R80": "If health probes are selected, live, ready, and dependency-failed fixtures prove them; otherwise record the selected deployment contract.",
    "R81": "Docs build or render from a clean checkout and exposes the selected CLI, library, and web guides.",
    "R82": "A broken link and failing rustdoc example are both rejected by the selected correctness gate.",
    "R83": "If OpenAPI fuzzing is selected, a generated schema fixture finds a seeded contract violation and retains a reproducer; otherwise record the selected no-fuzzing boundary.",
    "R84": "A provisional generic client fixture compiles against a representative schema; publication integration waits for R71's committed schema, then proves a generated request.",
    "R85": "TTY and redirected-output fixtures prove OSC-8/relative-time additions stay terminal-only and safely escaped.",
}

FOUNDATIONAL = {
    "R01", "R02", "R05", "R06", "R11", "R42", "R49", "R58", "R60", "R65",
    "R66", "R67", "R69", "R70", "R75", "R78", "R79", "R80", "R81", "R82",
}

# Escalations are deliberately decision-specific.  They are proposed queue
# controls, replacing the old repeated engine-failure sentence in the schedule.
ESCALATION = {
    "R01": "the seam would force a different crate topology or invalidate fake substitutability",
    "R02": "a boundary choice changes the public exports or composition-root direction",
    "R03": "an error distinction changes the shared exit-code catalog or caller compatibility",
    "R04": "the export guard requires a different crate boundary or breaks a supported consumer",
    "R05": "the execution model changes the web adapter, test strategy, or MSRV support",
    "R06": "the unsafe policy conflicts with a required dependency or a security baseline",
    "R07": "the trigger cadence changes credential exposure or release automation behavior",
    "R08": "least-privilege evidence conflicts with a required workflow capability",
    "R09": "runner indirection changes supported OS or security isolation assumptions",
    "R10": "the cache action conflicts with MSRV, key correctness, or supply-chain policy",
    "R11": "the job topology changes a consumer's required-check or path-skip semantics",
    "R12": "the selected merge gate conflicts with branch-protection or required-check behavior",
    "R13": "scanner coverage conflicts with the selected CI topology or actionable remediation",
    "R14": "the chosen guard leaves an unaccepted repository-size or bypass risk",
    "R15": "the receipt design cannot distinguish a changed template input from a stale artifact",
    "R16": "CodeQL applicability leaves a security-coverage gap or needs a compensating control",
    "R17": "the scanner leaks a planted secret or cannot cover the required CI event",
    "R18": "a review bot requires unsafe permissions, untrusted input, or unresolved cost controls",
    "R19": "the static update policy cannot express an ecosystem group or a declared exception",
    "R20": "a pinning exception weakens the documented supply-chain boundary",
    "R21": "the credential source expands token scope, violates fork safety, or lacks a fail-closed path",
    "R22": "the version source diverges between binary, library, and release artifact",
    "R23": "the synchronization rule conflicts with the selected release tool's source of truth",
    "R24": "a commit type cannot map cleanly to the R38 convention or release notes",
    "R25": "the bump rule changes downstream compatibility expectations or conflicts with release automation",
    "R26": "artifact content policy conflicts with crate publishing or release-binary requirements",
    "R27": "formatter configuration changes shared CI recipes or conflicts with toolchain support",
    "R28": "lint/editor selection changes safety policy, CI behavior, or supported developer environments",
    "R29": "a non-code formatter changes generated files or conflicts with the shared recipe contract",
    "R30": "the type gate changes MSRV, CI job shape, or public API enforcement",
    "R31": "the analyzer has a material false-negative/false-positive security tradeoff",
    "R32": "test tiering changes a consumer's prerequisite, artifact contract, or CI cost boundary",
    "R33": "property/snapshot tooling changes the R32 test contract or cannot retain counterexamples",
    "R34": "a scheduled lane silently becomes merge-blocking or cannot reproduce a freshness failure",
    "R35": "coverage measurement changes R32 execution assumptions or misreports generated code",
    "R37": "hook installation changes CI, web-surface, or package-manager assumptions",
    "R38": "the convention cannot drive changelog mapping and release automation consistently",
    "R39": "hook scanning leaks a secret, bypasses staged files, or conflicts with R37 stages",
    "R40": "a hygiene hook changes shared recipe or hook-manager behavior",
    "R41": "the freshness check conflicts with Cargo's selected lockfile workflow",
    "R42": "provisioning changes the invocation contract consumed by tooling and hooks",
    "R43": "assistant instructions create conflicting authority or unsafe repository automation",
    "R44": "the devcontainer changes the supported toolchain or cannot reproduce the documented setup",
    "R45": "a comment trigger can execute on untrusted input or names an unresolved bot",
    "R46": "the header policy conflicts with the fixed dual-license declaration or generated files",
    "R47": "recipe modes change contributor defaults, CI parity, or documented recovery",
    "R48": "the mock mechanism cannot honor R01's selected seam or R32's execution model",
    "R49": "target names/layout change version access, smoke tests, or release artifacts",
    "R50": "the install test cannot exercise the R49 selected public binary artifact",
    "R51": "container behavior disagrees with the R69 feature boundary or health contract",
    "R52": "parser semantics change config validation, diagnostics, or accepted user files",
    "R53": "schema behavior changes config compatibility or error taxonomy",
    "R54": "discovery precedence conflicts with secret handling or user configuration expectations",
    "R55": "tolerance behavior hides a configuration error or conflicts with the error catalog",
    "R56": "secret policy permits exposure, unsafe persistence, or conflicts with discovery tiers",
    "R57": "directory rules change state-file location or platform fallback behavior",
    "R58": "the pipeline contract cannot support R59, R75, or R78 without a new approved dependency",
    "R59": "the file sink requires a different R58 extension point or unsafe secret/retention policy",
    "R60": "the parser changes public CLI grammar, machine output, or error semantics",
    "R61": "prompt behavior blocks non-interactive users or changes cancellation semantics",
    "R62": "clipboard behavior needs unsupported OS access or changes public error handling",
    "R63": "spinner behavior contaminates a selected machine-readable output mode",
    "R64": "pager behavior loses output, hangs scripts, or conflicts with terminal policy",
    "R65": "color precedence leaks escapes into a public machine format or breaks accessibility",
    "R66": "a format choice changes downstream machine-consumer compatibility or R85 terminal layering",
    "R67": "a code mapping changes documented caller recovery or HTTP error translation",
    "R68": "artifact policy changes installability, signing, or release-consumer compatibility",
    "R69": "the web feature boundary changes runtime composition, CI, or supported surface",
    "R70": "the envelope changes client-visible HTTP recovery or OpenAPI representation",
    "R71": "schema generation changes the contract consumed by R83/R84 or cannot be reproducibly committed",
    "R72": "pagination strategy changes client-visible compatibility or the R84 generated-client assumptions",
    "R73": "idempotency behavior changes mutation safety, storage needs, or HTTP-client expectations",
    "R74": "rate-limit policy changes public availability, identity scope, or response compatibility",
    "R75": "middleware ordering changes logging, authentication, error, or security-header semantics",
    "R76": "CORS exceptions expose credentials/origins beyond the selected public policy",
    "R77": "web settings change startup safety, secret handling, or handler configuration",
    "R78": "telemetry integration cannot compose with R58 or changes request/runtime failure behavior",
    "R79": "metric labels create unsafe cardinality, incompatible observability, or middleware conflicts",
    "R80": "probe semantics change deployment readiness or container health behavior",
    "R81": "delivery model changes the public documentation path or makes R82 checks inapplicable",
    "R82": "correctness gate cannot validate the R81 selected docs model or misses public breakage",
    "R83": "fuzzing changes schema assumptions, cannot retain a reproducer, or conflicts with R71",
    "R84": "client generation cannot use R71's published schema or changes client-visible compatibility",
    "R85": "terminal niceties leak into a selected machine format or break safe link escaping",
}


def ids(text: str) -> list[str]:
    return sorted(set(ID_RE.findall(text)))


def prompt_info(path: Path) -> dict:
    text = subprocess.check_output(["git", "show", BASE_COMMIT + ":" + str(path.relative_to(ROOT))], cwd=ROOT, text=True)
    title = re.search(r"^# Deep-research prompt — (.+?) \((R\d{2}), (\w+)\)$", text, re.M)
    if not title:
        raise ValueError(f"bad title: {path}")
    item, kind = title.group(2), title.group(3)
    coupling = re.search(r"^## Couplings\n(.*?)(?=^## Questions)", text, re.M | re.S)
    if not coupling:
        raise ValueError(f"missing coupling block: {path}")
    block = coupling.group(1)
    # Use horizontal whitespace: `\\s*` would consume the next line when an
    # empty owns/consumes field is followed by a related line.
    owns = re.search(r"^- owns:[ \\t]*(.*)$", block, re.M).group(1).strip()
    consumes_line = re.search(r"^- consumes:[ \\t]*(.*)$", block, re.M).group(1)
    related_lines = re.findall(r"^- related .*?:\s*(.*)$", block, re.M)
    objective = re.search(r"^## Objective\n(.*?)(?=^## Context)", text, re.M | re.S).group(1).strip()
    decision = re.search(r"^Decision:\s*(.*)$", text, re.M)
    return {
        "id": item, "name": title.group(1), "kind": kind, "path": str(path.relative_to(ROOT)),
        "owns": owns or None, "hard": ids(consumes_line), "related": ids("\n".join(related_lines)),
        "objective": " ".join(objective.split()),
        "decision": decision.group(1) if decision else title.group(1),
    }


def graph(infos: dict[str, dict], extra: dict[str, list[str]] | None = None):
    """Return prereqs, forward graph, and recorded edge provenance."""
    owners = {item for item, info in infos.items() if info["owns"]}
    prereq = {item: set(info["hard"]) for item, info in infos.items()}
    source = {(d, item): "registry" for item, info in infos.items() for d in info["hard"]}
    for item, info in infos.items():
        if item not in owners:
            for d in set(info["related"]) & owners:
                if d != item:
                    prereq[item].add(d)
                    source[(d, item)] = "keystone"
    for item, deps in (extra or {}).items():
        for d in deps:
            prereq[item].add(d)
            source[(d, item)] = "proposed-registry"
    forward = {item: set() for item in infos}
    for item, deps in prereq.items():
        for d in deps:
            if d not in forward:
                raise ValueError(f"unknown dependency {d} for {item}")
            forward[d].add(item)
    return prereq, forward, source


def schedule(prereq: dict[str, set[str]], forward: dict[str, set[str]]):
    indegree = {n: len(v) for n, v in prereq.items()}
    ready = sorted(n for n, d in indegree.items() if d == 0)
    order = []
    while ready:
        n = ready.pop(0)
        order.append(n)
        for child in sorted(forward[n]):
            indegree[child] -= 1
            if indegree[child] == 0:
                ready.append(child)
                ready.sort()
    if len(order) != len(prereq):
        cyclic = sorted(set(prereq) - set(order))
        return None, cyclic
    level, path = {}, {}
    for n in order:
        if not prereq[n]:
            level[n], path[n] = 0, [n]
        else:
            parent = max(sorted(prereq[n]), key=lambda p: level[p])
            level[n], path[n] = level[parent] + 1, path[parent] + [n]
    descendants = {}
    for n in reversed(order):
        reached = set()
        stack = list(forward[n])
        while stack:
            child = stack.pop()
            if child not in reached:
                reached.add(child)
                stack.extend(forward[child])
        descendants[n] = reached
    return {"order": order, "level": level, "path": path, "descendants": descendants}, []


def effort(item: str, info: dict, descendant_count: int) -> tuple[str, str, str]:
    """Return a tier and a decision-specific rubric explanation."""
    subject = info["name"].lower()
    security = {"R06", "R08", "R13", "R16", "R17", "R18", "R20", "R21", "R31", "R39", "R45", "R56", "R76"}
    public = {"R03", "R04", "R12", "R60", "R66", "R67", "R68", "R70", "R71", "R72", "R73", "R74", "R81", "R82", "R83", "R84"}
    runtime = {"R01", "R02", "R05", "R11", "R27", "R28", "R30", "R32", "R37", "R42", "R49", "R51", "R52", "R53", "R54", "R55", "R58", "R59", "R65", "R69", "R75", "R77", "R78", "R79", "R80"}
    if item in DEEP:
        depth = "Deep"
        engines = "Proposed: Terra + Opus + Doxa" if item != "R38" else "Pilot: Terra + Opus + Doxa"
        if item in security:
            kind = "cross-cutting security boundary"
        elif item in public:
            kind = "public compatibility contract"
        elif item in runtime:
            kind = "runtime or crate-composition boundary"
        else:
            kind = "cross-subsystem design boundary"
        rationale = f"impact={kind} in {subject}; uncertainty=competing consequential designs; reversibility=expensive after consumers wire in; maturity=requires authoritative and practice evidence."
    elif item in LIGHT:
        depth = "Light"
        engines = "Proposed: Luna + independent Terra"
        rationale = f"impact={subject} has a bounded local effect; uncertainty=policy fit rather than topology; reversibility=small documented change; maturity=verify established primary guidance and one maintained example."
    else:
        depth = "Focused"
        engines = "Pilot: Terra + Opus + Doxa" if item == "R38" else "Proposed: Terra + Opus"
        rationale = f"impact={subject} affects a bounded integration; uncertainty=candidate and failure-mode fit; reversibility=moderate once recipes/tests adopt it; maturity=compare primary guidance with maintained practice."
    return depth, engines, rationale


def success_stop_and_escalation(item: str, depth: str) -> str:
    """Proposed completion condition plus a named decision-specific escalation."""
    if depth == "Deep":
        stop = "Stop only when the choice and runner-up condition are actionable, material disagreements have evidence-based dispositions, and the acceptance test passes"
    elif depth == "Focused":
        stop = "Stop when the discriminating fixture separates the selected option from its strongest alternative and all approved questions are answered"
    else:
        stop = "Stop when primary guidance, the maintained example, runner-up rationale, and the local fixture agree with no material question"
    return f"{stop}. Escalate if {ESCALATION[item]}."


def main() -> None:
    infos = {info["id"]: info for info in map(prompt_info, PROMPTS)}
    if len(infos) != 84:
        raise ValueError(f"expected 84 prompts, found {len(infos)}")
    if set(ACCEPTANCE) != set(infos):
        raise ValueError("acceptance map does not cover exactly the prompt IDs")
    current_pre, current_for, current_source = graph(infos)
    current, cycles = schedule(current_pre, current_for)
    if cycles:
        raise ValueError(f"recorded graph cycle: {cycles}")
    # Minimum semantic amendment: make the pipeline's chosen public integration
    # contract available to the three items whose prompts require it.  R58 already
    # consumes R69, so this creates no reverse edge.
    proposed_extra = {"R59": ["R58"], "R75": ["R58"], "R78": ["R58"]}
    proposed_pre, proposed_for, proposed_source = graph(infos, proposed_extra)
    proposed, proposed_cycles = schedule(proposed_pre, proposed_for)

    def payload(s, pre, fwd, source):
        return {
            "node_count": len(infos),
            "edge_count": sum(map(len, pre.values())),
            "cycle_free": not bool(s is None),
            "cycles": proposed_cycles if s is proposed else cycles,
            "waves": {str(k): sorted(n for n, v in s["level"].items() if v == k) for k in sorted(set(s["level"].values()))},
            "critical_depth_edges": max(s["level"].values()),
            "critical_paths": [s["path"][n] for n in s["order"] if s["level"][n] == max(s["level"].values())],
            "nodes": {
                n: {
                    "name": infos[n]["name"], "kind": infos[n]["kind"], "prerequisites": sorted(pre[n]),
                    "direct_descendant_count": len(fwd[n]),
                    "unique_transitive_descendant_count": len(s["descendants"][n]),
                    "level": s["level"][n], "longest_path": s["path"][n],
                    "outgoing_edges": [{"to": c, "rule": source[(n, c)]} for c in sorted(fwd[n])],
                } for n in sorted(infos)
            },
        }

    output = {
        "source": {"commit": "2f3569051af2c2089f60f6cad129bc6e55482c30", "runbook_edge_rules": ["registry consumes", "keystone related-to-parameter-owner"]},
        "recorded": payload(current, current_pre, current_for, current_source),
        "proposed_r58_amendment": {
            "status": "proposal; not recorded in prompts, PARAMETERS.md, or RUNBOOK.md",
            "new_parameter": {"owner": "R58", "name": "logging-pipeline-contract", "value_shape": "selected tracing/logging stack; initialization and extension interface; event-field/redaction contract; CLI/web profile boundary; optional OTel feature boundary"},
            "new_consumes": {"R59": ["R58: logging-pipeline-contract"], "R75": ["R58: logging-pipeline-contract"], "R78": ["R58: logging-pipeline-contract"]},
            "simulation": payload(proposed, proposed_pre, proposed_for, proposed_source),
        },
    }
    (OUT / "dependencies.json").write_text(json.dumps(output, indent=2) + "\n")

    waves = {level: sorted(n for n, level_ in current["level"].items() if level_ == level) for level in sorted(set(current["level"].values()))}
    zero = sorted(n for n, ds in current["descendants"].items() if not ds)
    foundational_zero = sorted(FOUNDATIONAL & set(zero))
    lines = [
        "# P02 item schedule\n",
        "This is a planning proposal, not a research result or authorization to run engines. `Recorded prerequisites` use exactly the two `research/RUNBOOK.md` rules. The graph is **not a complete semantic ordering**: descriptive prompt couplings can identify an unresolved ordering need, but are not invented as edges here. `Overlay` is the separately proposed R58 amendment only. `Downstream` reports direct / unique transitive descendants in the recorded graph. `Wave` is graph depth only; no elapsed-time estimate is implied.\n",
        "Every proposed tier retains independent synthesis, two independent non-producer audits (`audit-codex.md` and `audit-fable.md`), and the item-specific empirical gate. The tiers cannot replace the Runbook requirement that every configured engine runs until the owner amends it; Doxa remains paid and wave-confirmed. Unknown submission state is reconciled from the provider operation inventory or request ID and is never retried automatically. An authentication, quota, or provider-wide fault pauses new submissions for that provider until the controller records recovery; completed artifacts remain retained.\n",
        "Proposed initial sequencing: first run the bounded three-engine R38 parameter-owner pilot; only after its receipt/recovery checks, begin the five-item batch R01, R42, R49, R67, and R47 as capacity allows. This is a queue proposal, not a claim that baseline review or semantic-dependency reconciliation is complete.\n",
        "| Item | Decision source | Recorded prerequisites | Proposed overlay | Downstream | Proposed depth and engines | Rationale | Proposed empirical acceptance test | Concurrency class | Proposed success stop and item-specific escalation |\n",
        "|---|---|---|---|---:|---|---|---|---|---|\n",
    ]
    for item in sorted(infos):
        info = infos[item]
        depth, engines, rationale = effort(item, info, len(current["descendants"][item]))
        prereqs = ", ".join(sorted(current_pre[item])) or "—"
        overlay = "R58: logging-pipeline-contract (proposed)" if item in proposed_extra else "—"
        downstream = f"{len(current_for[item])} / {len(current['descendants'][item])}"
        if item in proposed_extra:
            proposed_prereqs = ", ".join(sorted(proposed_pre[item]))
            wave = f"Recorded W{current['level'][item]}; proposed W{proposed['level'][item]} — after {proposed_prereqs}"
        else:
            wave = f"W{current['level'][item]} — parallel after {prereqs}" if prereqs != "—" else f"W{current['level'][item]} — independent"
        stop = success_stop_and_escalation(item, depth)
        decision = f"[{info['name']}](../../../{info['path']})"
        lines.append(f"| {item} | {decision} | {prereqs} | {overlay} | {downstream} | {depth}; {engines}; two audits + empirical gate | {rationale} | {ACCEPTANCE[item]} | {wave} | {stop} |\n")
    lines.extend([
        "\n## Graph cautions\n",
        f"The recorded graph has {len(zero)} zero-influence nodes: {', '.join(zero)}. That is a scheduling fact, not proof that they are low-impact. The following are foundational by their decision scope despite zero recorded descendants: {', '.join(foundational_zero)}. They need owner/controller sequencing judgment or a justified parameter/edge amendment, not automatic demotion.\n",
        "Exact observed semantic-ordering examples that remain unresolved rather than silently converted to graph truth: R59 says it attaches to R58's pipeline; R75 says it folds framework logging into that pipeline; R78 says its OTel layer plugs into it; and R84 consumes R71's committed schema but lacks a registry edge. The first three are the explicit R58 overlay; R84 may run a generic provisional fixture but its publication integration is held until R71 resolves. No claim here says baseline review or missing semantic dependencies are resolved.\n",
        "A provisional research recommendation is not accepted: resolution still requires shape-valid raw work, synthesis, a recorded empirical check, and two independent non-producer audits under `research/RUNBOOK.md`.\n",
    ])
    (OUT / "item-schedule.md").write_text("".join(lines))

    cdepth = current["level"]
    pd = proposed["level"]
    changed = sorted(n for n in infos if cdepth[n] != pd[n])
    review = f"""# P02 dependency and effort review

## Recorded graph

The recorded graph has **{len(infos)} nodes**, **{sum(map(len, current_pre.values()))} edges**, and no cycles. It has {len(waves)} waves with counts {' · '.join(str(len(waves[w])) for w in sorted(waves))}. Its critical depth is {max(cdepth.values())} edges. The longest paths are graph order only, not a duration forecast; the first is `{' → '.join(current['path'][next(n for n in current['order'] if cdepth[n] == max(cdepth.values()))])}`.

The graph was recomputed from all 84 prompt files. An edge is recorded only when (1) an item names an `R##` on `- consumes:`, or (2) a non-owner names a parameter owner on `- related`. A mutual mention, an owner mentioning a consumer, and other descriptive text do not create an edge.

## R58 ownership gap

`R58` decides the logging architecture: selected stack, initialization and extension composition, redaction, CLI/web profiles, and the OpenTelemetry integration boundary. `R59` says its file sink is attached to R58's pipeline; `R75` must fold framework logging into that pipeline; and `R78` must plug its OTel layer into the pipeline. None can safely choose its integration mechanism before R58's stack is known, yet `R58` owns no registry parameter, so the Runbook's two rules do not schedule those relations. R58 itself already has the recorded hard prerequisite `R69` through `web-extra-surface`; the proposed edges do not reverse it.

## Minimum justified amendment

Do not convert every descriptive relation into an edge. Add one researched parameter, `logging-pipeline-contract`, owned by `R58`, with a value that names the selected tracing/logging stack, initialization and extension interface, structured-field/redaction contract, CLI/web profile boundary, and optional OTel feature boundary. Add exactly these registry consumers: `R59`, `R75`, and `R78`. This turns their existing semantic input into an auditable parameter rather than making a vague global ordering rule. It requires coordinated edits to `docs/port/PARAMETERS.md`, the R58/R59/R75/R78 prompts, and dependency order; it is **proposed**, not currently recorded.

The simulation has **{sum(map(len, proposed_pre.values()))} edges**, remains cycle-free, and has critical depth {max(pd.values())} edges. It changes levels only for: {', '.join(changed) or 'none'}. It should be accepted only if the controller agrees that the contract must be fixed before those consumers research their integration. The graph output retains recorded and proposed edges separately.

## Effort and execution constraints

The schedule assigns **{len([n for n in infos if effort(n, infos[n], len(current['descendants'][n]))[0] == 'Light'])} Light**, **{len([n for n in infos if effort(n, infos[n], len(current['descendants'][n]))[0] == 'Focused'])} Focused**, and **{len([n for n in infos if effort(n, infos[n], len(current['descendants'][n]))[0] == 'Deep'])} Deep** proposals. Deep is reserved for consequential choices that also retain material uncertainty, hard reversal, or cross-subsystem compatibility risk. A public or security adapter with a fixed upstream policy can be Focused; a parameter owner is never Light. R38 is a bounded three-engine pilot exception while remaining Focused.

The requested engine sets are proposals: Light = Luna plus independent Terra; Focused = Terra plus Opus; Deep = Terra plus Opus plus Doxa. They are not currently compliant replacements for Runbook §2's “every configured engine” rule. This analysis does not authorize dropping coverage: any such change requires an owner amendment. Each tier still needs both independent audits and a real empirical gate; no provisional assignment is an accepted research answer. Escalation raises a tier when evidence shows the initially bounded choice is actually consequential or incompatible.

## Foundational items the graph understates

There are {len(zero)} nodes with no recorded descendants. In particular, {', '.join(foundational_zero)} are foundational decisions by scope but have zero graph influence under the exact rules. Treat the absence as an ownership/scheduling review queue, not as evidence to reduce their research depth.
"""
    (OUT / "dependency-review.md").write_text(review)


if __name__ == "__main__":
    main()
