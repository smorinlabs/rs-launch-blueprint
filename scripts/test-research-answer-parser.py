#!/usr/bin/env python3
"""Independent Markdown boundary regressions for research answer validation."""

import unittest

from research_validation import (
    BUNDLE_FIELDS, CRATE_FIELDS, _validate_decision_text, validate_answer_text,
)


def answer(fields, level=3):
    return "\n\n".join("#" * level + " " + field + "\nEvidence." for field in fields)


class MarkdownBoundaryTests(unittest.TestCase):
    def test_tilde_fence_cannot_supply_fields(self):
        self.assertTrue(validate_answer_text("~~~md\n" + answer(CRATE_FIELDS) + "\n~~~", "crate"))

    def test_shorter_or_wrong_fence_cannot_expose_fields(self):
        for false_close in ("```", "~~~~", "````python"):
            with self.subTest(false_close=false_close):
                self.assertTrue(validate_answer_text("````md\n" + false_close + "\n" + answer(CRATE_FIELDS) + "\n````", "crate"))

    def test_empty_code_fence_does_not_supply_body(self):
        complete = answer(CRATE_FIELDS)
        broken = complete.replace("### Recommendation\nEvidence.", "### Recommendation\n```rust\n\n```")
        self.assertTrue(any("empty body" in error for error in validate_answer_text(broken, "crate")))

    def test_substantive_code_is_a_valid_body(self):
        complete = answer(CRATE_FIELDS)
        valid = complete.replace("### Recommendation\nEvidence.", "### Recommendation\n~~~rust\nlet selected = true;\n~~~")
        self.assertEqual([], validate_answer_text(valid, "crate"))

    def test_bundle_members_must_be_inside_members_section(self):
        member = "#### example\n" + answer(CRATE_FIELDS, 5)
        outer = answer(BUNDLE_FIELDS)
        valid = outer.replace("### Members\nEvidence.", "### Members\n" + member)
        self.assertEqual([], validate_answer_text(valid, "bundle"))
        self.assertTrue(validate_answer_text(outer + "\n" + member, "bundle"))

    def test_every_bundle_member_has_its_own_complete_evidence(self):
        outer = answer(BUNDLE_FIELDS)
        first = "#### first\n" + answer(CRATE_FIELDS, 5)
        second = "#### second\n" + answer(CRATE_FIELDS, 5)
        valid = outer.replace("### Members\nEvidence.", "### Members\n" + first + "\n" + second)
        self.assertEqual([], validate_answer_text(valid, "bundle"))
        broken = valid.replace("##### Sources\nEvidence.", "##### Sources\n", 1)
        self.assertTrue(any("empty body" in error for error in validate_answer_text(broken, "bundle")))

    def test_duplicate_member_names_are_rejected(self):
        member = "#### same\n" + answer(CRATE_FIELDS, 5)
        invalid = answer(BUNDLE_FIELDS).replace("### Members\nEvidence.", "### Members\n" + member + "\n" + member)
        self.assertTrue(any("distinct" in error for error in validate_answer_text(invalid, "bundle")))

    def test_historical_principles_and_trigger_cannot_approve_current_entry(self):
        current = "## Decision\nNew pick.\n## Parameters\nNone.\n## Empirical check\nRan.\n## Engines\nCompared.\n"
        history = "## Supersedes\nPrior entry follows.\n## Decision\nOld pick.\n### Principles and implementation\nOld rationale.\nre-verify: event\n"
        errors = []
        _validate_decision_text(current + history, "R01", {"reverify": "event"}, errors)
        self.assertTrue(any("Principles and implementation" in error for error in errors))
        self.assertTrue(any("re-verify" in error for error in errors))

    def test_principles_must_be_in_current_decision_section(self):
        text = "## Decision\nPick.\nre-verify: event\n## Parameters\nNone.\n### Principles and implementation\nMisplaced rationale.\n## Empirical check\nRan.\n## Engines\nCompared.\n"
        errors = []
        _validate_decision_text(text, "R01", {"reverify": "event"}, errors)
        self.assertTrue(any("Principles and implementation" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
