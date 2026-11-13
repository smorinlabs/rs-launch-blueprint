#!/usr/bin/env python3
"""Apply the approved P02 execution metadata to canonical prompt files."""
from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
PROMPTS = sorted((ROOT / "research/topics").glob("*/prompts/*.prompt.md"))
DEEP = {
    "R01", "R02", "R03", "R05", "R11", "R18", "R25", "R32", "R42",
    "R49", "R54", "R56", "R58", "R60", "R66", "R67", "R68", "R69",
    "R71", "R72", "R73", "R74", "R75", "R78", "R84",
}
LIGHT = {"R22", "R23", "R24", "R41", "R46", "R47"}
ACCEPTANCE_AFTER = {"R83": ["R71"], "R84": ["R71"]}
R58_CONSUMERS = {"R59", "R75", "R78"}

TIER_GUIDANCE = {
    "light": "Codex produces the scoped raw answer and Terra independently checks its evidence.",
    "focused": "Codex and Opus independently investigate the approved input packet.",
    "deep": "Codex, Opus, and Doxa independently investigate the approved input packet.",
}

COMMON_GUIDANCE = (
    "Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):\n"
    "- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.\n"
    "- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.\n"
    "- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.\n"
    "- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.\n"
)


def write_dependency_reconciliation() -> None:
    texts = {path: path.read_text() for path in PROMPTS}
    owners = {
        item_id(text): re.search(r"^- owns:[ \t]*(.*)$", text, re.MULTILINE).group(1).strip()
        for text in texts.values()
    }
    records: list[tuple[str, list[str], list[str], list[str], str]] = []
    exact: list[tuple[str, int, str]] = []
    for path in PROMPTS:
        text = texts[path]
        item = item_id(text)
        coupling = re.search(r"^## Couplings\n(.*?)(?=^## Questions)", text, re.MULTILINE | re.DOTALL).group(1)
        hard = sorted(set(re.findall(r"R\d{2}", re.search(r"^- consumes:.*$", coupling, re.MULTILINE).group(0))))
        related_lines = [(n, raw) for n, raw in enumerate(text.splitlines(), 1) if raw.startswith("- related")]
        related_ids = sorted({rid for _, raw in related_lines for rid in re.findall(r"R\d{2}", raw) if rid != item})
        keystone = sorted(set(related_ids) & {rid for rid, value in owners.items() if value} - {item}) if not owners[item] else []
        acceptance = sorted(set(re.findall(r"R\d{2}", re.search(r"^- acceptance-after:.*$", coupling, re.MULTILINE).group(0))))
        context = sorted(set(related_ids) - set(hard) - set(keystone) - set(acceptance))
        criterion = context_criterion(item, context)
        records.append((item, sorted(set(hard) | set(keystone)), acceptance, context, criterion))
        exact.extend((f"{item} — {path.relative_to(ROOT)}", n, raw) for n, raw in related_lines)

    lines = [
        "# P02 dependency reconciliation\n",
        "\n",
        "This record reviews every one of the 84 canonical prompts and separates three meanings that descriptive coupling prose can carry. **Research** prerequisites are the existing `- consumes:` edges plus the Runbook keystone rule for a non-owner that names an owner. **Acceptance** prerequisites are post-research integration checks recorded by `acceptance-after`. **Context** relations describe compatibility or an open assumption; they do not block dispatch and do not add graph edges.\n",
        "\n",
        "The migration promotes `R58`'s `logging-pipeline-contract` to a researched parameter and makes R59, R75, and R78 explicit consumers. It records `R71` as `acceptance-after` for R83 and R84 because their integrated schema fixtures require R71's committed snapshot. R84 may research against a generic provisional schema, but its publication integration must revalidate against R71. R01/R05 stays one-way under the Runbook keystone rule; no reverse edge or cycle is introduced.\n",
        "\n",
        "## Per-prompt review\n",
        "\n",
        "The table has one row per canonical prompt. It classifies the exact declared coupling text; it is not a claim that semantic discovery is complete. Any undeclared or ambiguous dependency remains unresolved until the controller records it before binding acceptance. Context criteria are completion checks for the eventual decision; they do not turn a contextual relation into a research prerequisite. When an owner prompt names a downstream consumer, that reference remains context and the consumer owns the future integration check against the selected output.\n",
        "\n",
        "| Item | Existing research prerequisites | Acceptance prerequisites | Context relations | Context acceptance criterion |\n|---|---|---|---|---|\n",
    ]
    for item, research, acceptance, context, criterion in sorted(records):
        lines.append(
            f"| {item} | {', '.join(research) or '—'} | {', '.join(acceptance) or '—'} | {', '.join(context) or '—'} | {criterion} |\n"
        )
    lines.extend([
        "\n## Explicit unresolved compatibility checks\n",
        "\n",
        "- **R01 → R05:** R01 resolves the seam with a conditional fixture that remains viable for either sync or async execution; R05 then validates the selected seam and execution model together. No reverse edge is added, so the open relation cannot create a cycle.\n",
        "- **R45 → R18:** the trigger-block fixture must name exactly the bot list resolved by R18. If R18 resolves to no bot, the fixture must prove the trigger block is absent; do not invent a bot name.\n",
        "- **R33, R34, R35, and R48 → R32:** run each selected property/snapshot, scheduled-lane, coverage, and mock fixture using R32's resolved runner and tier boundary. Preserve slow/advisory isolation and exercise R48's mock through R01's selected seam.\n",
        "- **R59, R75, and R78 → R58:** their integration fixtures must use R58's published logging-pipeline contract, including the selected extension point, redaction fields, profile boundary, and optional OTel boundary.\n",
        "- **R83 and R84 → R71:** each schema-driven fixture must consume the committed R71 snapshot before resolution; R84 additionally proves one generated request against that snapshot.\n",
        "\n## Exact cited relation text\n",
        "\n",
        f"The following {len(exact)} excerpts are copied from the canonical prompt files with their source locations. They are evidence for the per-prompt classifications above, not additional edges.\n\n",
    ])
    for source, number, raw in exact:
        lines.extend([f"- `{source}:{number}`\n", f"  {raw}\n"])
    (ROOT / "docs/planning/p02/dependency-reconciliation.md").write_text("".join(lines))


def context_criterion(item: str, context: list[str]) -> str:
    if not context:
        return "No descriptive coupling; run this item's own acceptance gate."
    if item == "R45" and "R18" in context:
        return "Trigger-block fixture names exactly R18's resolved bot list; with no bot, prove the block is absent."
    if item in {"R33", "R34", "R35", "R48"} and "R32" in context:
        return "Run this item's selected fixture using R32's resolved runner and tier boundary; preserve its isolation."
    if item == "R01" and "R05" in context:
        return "Resolve the seam with a conditional fixture viable for either sync or async execution; R05 later validates the selected seam and execution model together."
    if item == "R05" and "R01" in context:
        return "Validate the selected seam and execution model together; do not create a reverse research edge."
    return "Preserve the stated open assumption; no compatibility is presumed. Once a consuming decision has both selected outputs, it records a compatibility check; this relation alone does not block dispatch."


def item_id(text: str) -> str:
    match = re.search(r"^- id: (R\d{2})$", text, re.MULTILINE)
    if not match:
        raise ValueError("prompt has no coupling id")
    return match.group(1)


def tier_for(item: str) -> str:
    if item in LIGHT:
        return "light"
    if item in DEEP:
        return "deep"
    return "focused"


def engines_for(item: str, tier: str) -> list[str]:
    if item == "R38":
        return ["codex", "opus", "doxa"]
    return {"light": ["codex"], "focused": ["codex", "opus"], "deep": ["codex", "opus", "doxa"]}[tier]


def migrate_prompt(path: Path) -> tuple[str, dict[str, object]]:
    original = path.read_text()
    item = item_id(original)
    tier = tier_for(item)
    engines = engines_for(item, tier)
    block_match = re.search(r"^## Couplings\n(.*?)(?=^## Questions)", original, re.MULTILINE | re.DOTALL)
    if not block_match:
        raise ValueError(f"{path}: missing Couplings block")
    block = block_match.group(1)
    block = re.sub(r"^- effort:.*\n", "", block, flags=re.MULTILINE)
    block = re.sub(r"^- engines:.*\n", "", block, flags=re.MULTILINE)
    block = re.sub(r"^- evidence-checks:.*\n", "", block, flags=re.MULTILINE)
    block = re.sub(r"^- acceptance-after:.*\n", "", block, flags=re.MULTILINE)
    if item == "R58":
        block = re.sub(r"^- owns:[ \t]*\n", "- owns: logging-pipeline-contract\n", block, count=1, flags=re.MULTILINE)
    if item in R58_CONSUMERS:
        block = re.sub(
            r"^- consumes:([ \t]*)(.*)$",
            lambda m: "- consumes: " + "; ".join(
                [
                    *[
                        part.strip()
                        for part in m.group(2).split(";")
                        if part.strip() and part.strip() != "R58: logging-pipeline-contract"
                    ],
                    "R58: logging-pipeline-contract",
                ]
            ),
            block,
            count=1,
            flags=re.MULTILINE,
        )
        # The registered consume edge is the source of truth. Remove the old
        # duplicate prose relation so the prompt cannot call it non-registry.
        if item == "R59":
            block = re.sub(
                r"R58 \(`logging-pipeline-architecture`\).*?R57 \(`xdg-directory-set`\)",
                "R57 (`xdg-directory-set`)",
                block,
                flags=re.DOTALL,
            )
            block = block.replace(
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline.\n",
                "",
            )
            block = block.replace(
                "- related (not a registry dependency): R57",
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline.\n- related (not a registry dependency): R57",
                1,
            )
            block = block.replace(
                "- related (integration guidance; registry dependency above): R57",
                "- related (not a registry dependency): R57",
                1,
            )
            if "R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline." not in block:
                block = block.replace(
                    "- related (not a registry dependency): R57",
                    "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) — this item's file sink is a component attached to R58's pipeline.\n- related (not a registry dependency): R57",
                    1,
                )
        elif item == "R75":
            block = re.sub(
                r"^- related \(integration guidance; registry dependency above\):\n",
                "",
                block,
                flags=re.MULTILINE,
            )
            block = re.sub(
                r" R58 \(`logging-pipeline-architecture`\).*?see F263's ledger note for the split\.\s*",
                "\n",
                block,
            )
            block = block.replace(
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.\n",
                "",
            )
            block = block.replace(
                "If your recommendation needs",
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) owns F263, the pipeline-profile side of the same web-logger integration point this item's F327 addresses from the framework side; see F263's ledger note for the split.\nIf your recommendation needs",
                1,
            )
        elif item == "R78":
            block = re.sub(
                r"^- related \(not a registry dependency\): R58 .*\n",
                "",
                block,
                flags=re.MULTILINE,
            )
            block = block.replace(
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; use the logging architecture that R58 establishes; compare direct OpenTelemetry instrumentation with a bridge from that architecture, and record any required change rather than assuming a specific logging crate.\n",
                "",
            )
            block = block.replace(
                "- related (not a registry dependency): R69",
                "- related (integration guidance; registry dependency above): R58 (`logging-pipeline-architecture`) decides the base `tracing`-crate subscriber pipeline this item's OTel layer plugs into; use the logging architecture that R58 establishes; compare direct OpenTelemetry instrumentation with a bridge from that architecture, and record any required change rather than assuming a specific logging crate.\n- related (not a registry dependency): R69",
                1,
            )
    evidence_checks = "terra" if tier == "light" else ""
    acceptance_after = ", ".join(ACCEPTANCE_AFTER.get(item, []))
    metadata = (
        f"- effort: {tier}\n"
        f"- engines: {', '.join(engines)}\n"
        f"- evidence-checks:{' ' + evidence_checks if evidence_checks else ''}\n"
        f"- acceptance-after:{' ' + acceptance_after if acceptance_after else ''}\n"
    )
    block = block.replace("\n\n- related", "\n- related")
    block = block.replace("\n\n- related", "\n- related")
    block = re.sub(r"(\.) If your recommendation needs", r"\1\nIf your recommendation needs", block)
    block = block.rstrip("\n") + "\n"
    block = re.sub(r"^(- consumes:.*\n)", r"\1" + metadata, block, count=1, flags=re.MULTILINE)
    updated = original[: block_match.start(1)] + block + original[block_match.end(1):]
    updated = re.sub(r"\n+## Questions\n", "\n\n## Questions\n", updated, count=1)
    # Normalize this migration's guidance so rerunning the helper cannot leave
    # stale or duplicate tier blocks in a canonical prompt.
    guidance = re.compile(
        r"\nTier execution guidance \(approved 2026-09-04; .*?\):\n(?:- .*\n)+"
    )
    updated = guidance.sub("\n", updated)
    updated = re.sub(r"\n{2,}(?=## Answer template)", "\n\n", updated)
    marker = "\n## Answer template\n"
    if marker not in updated:
        raise ValueError(f"{path}: missing Answer template marker")
    updated = updated.replace(marker, "\n" + COMMON_GUIDANCE + marker, 1)
    if re.search(r"^# Deep-research prompt — .* \(R\d{2}, bundle\)$", updated, re.MULTILINE):
        bundle_members = (
            "### Members\n"
            "For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.\n"
        )
        updated = updated.replace("### Members\nThe full `crate` field set for each member.\n", bundle_members, 1)
    if item == "R79":
        updated = updated.replace(
            "This item is on-by-default, unlike R78's OTel integration which sits behind an opt-in `otel` feature (F304) — do not gate this crate's inclusion behind an optional feature unless the evidence shows the Rust ecosystem norm requires it.",
            "This item is on-by-default in the web example. R78's OTel integration remains an optional packaged capability behind the owner-fixed `otel` feature; the required web example must demonstrate it when that feature is enabled. Keep this metrics crate default-enabled unless evidence shows Rust packaging norms require another shape; report any challenge to the inherited direction as `BASELINE-REVIEW: F326` rather than silently changing the owner requirement.",
            1,
        )
        updated = updated.replace(
            "R78 (`opentelemetry-integration`) is the sibling tracing decision for the same web service, decided separately since it is opt-in where this item is on by default.",
            "R78 (`opentelemetry-integration`) is the sibling tracing decision for the same web service; its package remains optional behind the owner-fixed `otel` feature while this item is enabled by default, and the required web example must exercise the enabled OTel path.",
            1,
        )
        updated = updated.replace(
            "Is the on-by-default posture (no env var gates metrics collection, unlike R78's opt-in OTel feature and unlike R74's opt-in rate limiting) achievable with a default-enabled dependency and unconditional route registration, or does the candidate itself default to opt-in and need explicit always-on wiring in the template?",
            "Is the on-by-default posture (no env var gates metrics collection, unlike R74's opt-in rate limiting) achievable with a default-enabled dependency and unconditional route registration while R78's optional `otel` package still has a required enabled web-example path, or does the candidate itself default to opt-in and need explicit always-on wiring in the template?",
            1,
        )
    path.write_text(updated)
    return item, {
        "tier": tier,
        "engines": engines,
        "evidence_checks": ["terra"] if evidence_checks else [],
        "acceptance_after": ACCEPTANCE_AFTER.get(item, []),
    }


def main() -> None:
    if len(PROMPTS) != 84:
        raise SystemExit(f"expected 84 canonical prompts, found {len(PROMPTS)}")
    items: dict[str, dict[str, object]] = {}
    for path in PROMPTS:
        item, policy = migrate_prompt(path)
        if item in items:
            raise SystemExit(f"duplicate prompt id {item}")
        items[item] = policy
    if len(items) != 84:
        raise SystemExit(f"expected 84 item ids, found {len(items)}")
    execution = {
        "schema_version": 1,
        "approved_on": "2026-09-04",
        "pilot": "R38",
        "items": {item: items[item] for item in sorted(items)},
    }
    (ROOT / "research/EXECUTION.json").write_text(json.dumps(execution, indent=2) + "\n")
    write_dependency_reconciliation()


if __name__ == "__main__":
    main()
