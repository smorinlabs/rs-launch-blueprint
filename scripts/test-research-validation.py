#!/usr/bin/env python3
"""Regression tests for P02 evidence validation.

These tests intentionally exercise defects the former grep-only answer check
accepted: headings hidden in a fence and headings with no answer body.
"""
import importlib.util
import hashlib
import json
import tempfile
import unittest
from pathlib import Path


HERE = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location("research_validation", HERE / "research_validation.py")
validation = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(validation)


def answer(fields, body="content"):
    return "\n\n".join("### %s\n%s" % (field, body) for field in fields) + "\n"


def prompt(item, tier, engines, checks="", after=""):
    return """## Objective
x

## Context
x

## Out of scope
x

## Couplings
- id: %s
- effort: %s
- engines: %s
- evidence-checks: %s
- acceptance-after: %s

## Questions
x

## Required evidence
x

## Answer template
x

## Constraints
x
""" % (item, tier, engines, checks, after)


class AnswerShapeTests(unittest.TestCase):
    def test_complete_crate_answer_is_valid(self):
        self.assertEqual([], validation.validate_answer_text(answer(validation.CRATE_FIELDS), "crate"))

    def test_fenced_headings_do_not_satisfy_fields(self):
        # The old shell grep accepted this because it did not track fences.
        text = "```markdown\n" + answer(validation.CRATE_FIELDS) + "```\n"
        self.assertTrue(validation.validate_answer_text(text, "crate"))

    def test_fenced_body_counts_after_a_real_heading(self):
        text = answer(validation.CRATE_FIELDS)
        text = text.replace("### Landscape\ncontent", "### Landscape\n```text\nsubstantive evidence\n```")
        self.assertEqual([], validation.validate_answer_text(text, "crate"))

    def test_empty_heading_body_is_rejected(self):
        # The old shell grep accepted headings with no substantive answer.
        text = answer(validation.CRATE_FIELDS)
        text = text.replace("### Recommendation\ncontent", "### Recommendation\n")
        errors = validation.validate_answer_text(text, "crate")
        self.assertTrue(any("empty body" in error for error in errors), errors)

    def test_bundle_requires_named_members_with_h5_crate_shape(self):
        text = answer(validation.BUNDLE_FIELDS)
        self.assertTrue(validation.validate_answer_text(text, "bundle"))
        member = "#### serde\nmember description\n\n" + "\n\n".join("##### %s\ncontent" % x for x in validation.CRATE_FIELDS)
        self.assertEqual([], validation.validate_answer_text(text.replace("### Members\ncontent", "### Members\n" + member), "bundle"))


class ExecutionPolicyTests(unittest.TestCase):
    def make_root(self):
        temp = tempfile.TemporaryDirectory()
        root = Path(temp.name)
        (root / "research/topics/01-one/prompts").mkdir(parents=True)
        (root / "research/topics/02-two/prompts").mkdir(parents=True)
        (root / "docs/port").mkdir(parents=True)
        (root / "docs/port/PARAMETERS.md").write_text("| param | kind | owner | value | description |\n|---|---|---|---|---|\n")
        (root / "research/CLAUDE.md").write_text("""# Research index
| id | slug | kind | origin | verdict | owns | prompt | status |
|---|---|---|---|---|---|---|---|
| R01 | one | pattern | different | DIVERGENT | — | [prompt](topics/01-one/prompts/one.prompt.md) | open |
| R02 | two | pattern | different | DIVERGENT | — | [prompt](topics/02-two/prompts/two.prompt.md) | open |
""")
        (root / "research/topics/01-one/prompts/one.prompt.md").write_text(prompt("R01", "focused", "codex, opus"))
        (root / "research/topics/02-two/prompts/two.prompt.md").write_text(prompt("R02", "focused", "codex, opus"))
        policy = {"schema_version": 1, "approved_on": "2026-09-04", "pilot": "R01", "items": {"R01": {"tier": "focused", "engines": ["codex", "opus", "doxa"], "evidence_checks": [], "acceptance_after": []}, "R02": {"tier": "focused", "engines": ["codex", "opus"], "evidence_checks": [], "acceptance_after": []}}}
        # R01 is the generic fixture pilot, so its prompt mirrors the approved exception.
        (root / "research/topics/01-one/prompts/one.prompt.md").write_text(prompt("R01", "focused", "codex, opus, doxa"))
        (root / "research/EXECUTION.json").write_text(json.dumps(policy))
        return temp, root

    def test_minimal_policy_is_valid(self):
        temp, root = self.make_root()
        self.addCleanup(temp.cleanup)
        self.assertEqual([], validation.validate_execution_policy(root))

    def test_bool_schema_version_is_not_an_integer(self):
        temp, root = self.make_root()
        self.addCleanup(temp.cleanup)
        policy_path = root / "research/EXECUTION.json"
        policy = json.loads(policy_path.read_text()); policy["schema_version"] = True
        policy_path.write_text(json.dumps(policy))
        errors = validation.validate_execution_policy(root)
        self.assertTrue(any("schema_version" in error for error in errors), errors)

    def test_malformed_policy_types_return_diagnostics(self):
        for field, value in (("pilot", {}), ("schema_version", [])):
            temp, root = self.make_root(); self.addCleanup(temp.cleanup)
            policy_path = root / "research/EXECUTION.json"; policy = json.loads(policy_path.read_text())
            policy[field] = value; policy_path.write_text(json.dumps(policy))
            self.assertTrue(validation.validate_execution_policy(root))
        temp, root = self.make_root(); self.addCleanup(temp.cleanup)
        policy_path = root / "research/EXECUTION.json"; policy = json.loads(policy_path.read_text())
        policy["items"]["R01"]["acceptance_after"] = [{}]; policy_path.write_text(json.dumps(policy))
        self.assertTrue(validation.validate_execution_policy(root))

    def test_acceptance_cycle_is_rejected_separately(self):
        temp, root = self.make_root()
        self.addCleanup(temp.cleanup)
        policy_path = root / "research/EXECUTION.json"
        policy = json.loads(policy_path.read_text())
        policy["items"]["R01"]["acceptance_after"] = ["R02"]
        policy["items"]["R02"]["acceptance_after"] = ["R01"]
        policy_path.write_text(json.dumps(policy))
        (root / "research/topics/01-one/prompts/one.prompt.md").write_text(prompt("R01", "focused", "codex, opus, doxa", after="R02"))
        (root / "research/topics/02-two/prompts/two.prompt.md").write_text(prompt("R02", "focused", "codex, opus", after="R01"))
        errors = validation.validate_execution_policy(root)
        self.assertTrue(any("acceptance graph has cycle" in error for error in errors), errors)

    def test_accepted_topic_then_missing_or_rejecting_audit_is_rejected(self):
        temp, root = self.make_root()
        self.addCleanup(temp.cleanup)
        index = root / "research/CLAUDE.md"
        index.write_text(index.read_text().replace("| R01 | one | pattern | different | DIVERGENT | — | [prompt](topics/01-one/prompts/one.prompt.md) | open |", "| R01 | one | pattern | different | DIVERGENT | — | [prompt](topics/01-one/prompts/one.prompt.md) | resolved |"))
        topic = root / "research/topics/01-one"
        (topic / "raw").mkdir(); (topic / "evidence").mkdir()
        decision = topic / "DECISION.md"; decision.write_text("## Decision\npick\n\n### Principles and implementation\nprinciple\n\nre-verify: event\n\n## Parameters\nnone\n\n## Empirical check\nran\n\n## Engines\nthree reports\n")
        prompt_path = topic / "prompts/one.prompt.md"
        answer_text = answer(validation.PATTERN_FIELDS)
        raw = topic / "raw/codex.md"; raw.write_text(answer_text)
        opus = topic / "raw/opus.md"; opus.write_text(answer_text)
        doxa = topic / "raw/doxa.md"; doxa.write_text(answer_text)
        audit_c = topic / "audit-codex.md"
        audit_f = topic / "audit-fable.md"
        output = topic / "evidence/output.log"; output.write_text("ok\n")
        def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
        def identity(actor, family): return {"actor":actor, "model":actor+"-model", "family":family}
        def artifact(path, actor, family): return {"path":str(path.relative_to(root)), "sha256":digest(path), "identity":identity(actor, family)}
        audit_c.write_text("decision-sha256: %s\nactor: audit-one\nmodel: audit-one-model\nfamily: openai\nverdict: approve\nunresolved-findings: none\nanalysis: empirical rerun evidence\n" % digest(decision))
        audit_f.write_text("decision-sha256: %s\nactor: audit-two\nmodel: audit-two-model\nfamily: anthropic\nverdict: approve\nunresolved-findings: none\nanalysis: judgment evidence\n" % digest(decision))
        policy = json.loads((root / "research/EXECUTION.json").read_text())["items"]["R01"]
        acceptance = {"item":"R01","schema_version":1,"decision_sha256":digest(decision),"prompt_sha256":digest(prompt_path),"policy_snapshot":policy,"engine_reports":[dict(engine="codex", **artifact(raw,"producer","openai")), dict(engine="opus", **artifact(opus,"producer-two","anthropic")), dict(engine="doxa", **artifact(doxa,"producer-three","mixed"))],"evidence_checks":[],"synthesis":identity("synthesis","anthropic"),"audits":[dict(kind="empirical", **artifact(audit_c,"audit-one","openai"), decision_sha256=digest(decision), verdict="approve", unresolved_findings=[]), dict(kind="judgment", **artifact(audit_f,"audit-two","anthropic"), decision_sha256=digest(decision), verdict="approve", unresolved_findings=[])],"empirical":{"argv":["cargo","test"],"cwd":"fixture","toolchain":"rustc fixture","output_log":str(output.relative_to(root)),"output_sha256":digest(output),"exit_code":0,"executed_by":identity("audit-one","openai")},"parameters":{"consumed":{},"fixed":{}},"prerequisites":{"research":{},"acceptance_after":{}},"reverify":"event","engines":"record","principles":"record"}
        acceptance_path = topic / "acceptance.json"; acceptance_path.write_text(json.dumps(acceptance))
        self.assertEqual([], validation.validate_topic(root, "R01"))

        # Each mutation starts from the proven GREEN bundle, then independently
        # demonstrates one RED acceptance gate.
        baseline = json.loads(json.dumps(acceptance))
        decision.write_text("## Decision\n\n## Parameters\nnone\n\n## Empirical check\nran\n\n## Engines\nthree reports\n")
        broken = json.loads(json.dumps(baseline)); broken["decision_sha256"] = digest(decision)
        for audit in broken["audits"]: audit["decision_sha256"] = broken["decision_sha256"]
        acceptance_path.write_text(json.dumps(broken))
        self.assertTrue(any("current '## Decision' is empty" in error for error in validation.validate_topic(root, "R01")))
        decision.write_text("## Decision\npick\n\n### Principles and implementation\nprinciple\n\nre-verify: event\n\n## Parameters\nnone\n\n## Empirical check\nran\n\n## Engines\nthree reports\n")

        raw.write_text("")
        broken = json.loads(json.dumps(baseline)); broken["decision_sha256"] = digest(decision)
        broken["engine_reports"][0]["sha256"] = digest(raw)
        for audit in broken["audits"]: audit["decision_sha256"] = broken["decision_sha256"]
        acceptance_path.write_text(json.dumps(broken))
        self.assertTrue(any("engine_reports[0]: answer:" in error for error in validation.validate_topic(root, "R01")))
        raw.write_text(answer_text)

        broken = json.loads(json.dumps(baseline)); broken["engine_reports"][1]["identity"] = broken["engine_reports"][0]["identity"]
        acceptance_path.write_text(json.dumps(broken))
        self.assertTrue(any("engine report actors must be distinct" in error for error in validation.validate_topic(root, "R01")))

        broken = json.loads(json.dumps(baseline)); broken["parameters"]["fixed"] = {"msrv-policy": "wrong"}; broken["parameters"]["consumed"] = {"missing": "wrong"}
        acceptance_path.write_text(json.dumps(broken))
        errors = validation.validate_topic(root, "R01")
        self.assertTrue(any("parameters.fixed" in error for error in errors), errors)
        self.assertTrue(any("parameters.consumed" in error for error in errors), errors)

        acceptance_path.write_text(json.dumps(baseline))
        acceptance_path.unlink()
        self.assertTrue(any("acceptance.json" in error for error in validation.validate_topic(root, "R01")))
        acceptance_path.write_text(json.dumps(acceptance))
        audit_c.write_text("verdict: REJECT\nunresolved-findings: none\n")
        errors = validation.validate_topic(root, "R01")
        self.assertTrue(any("verdict: approve" in error for error in errors), errors)


if __name__ == "__main__":
    unittest.main()
