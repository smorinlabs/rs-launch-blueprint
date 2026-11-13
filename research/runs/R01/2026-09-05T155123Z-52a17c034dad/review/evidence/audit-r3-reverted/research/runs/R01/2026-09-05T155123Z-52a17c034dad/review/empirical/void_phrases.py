#!/usr/bin/env python3
"""The nine phrases revision 2 used to reason from a licence, and the rule for each.

Revision 3 struck every one of them under the owner's ruling of 2026-09-12 (Q7.B).
Eight must be ABSENT from a repaired decision. The ninth — the patent-grant clause —
is deliberately quoted in the repaired text so a reader can see what was removed, so
it must be PRESENT exactly once and immediately followed by the sentence that strikes
it; a bare reappearance is a failure.

Usage:  void_phrases.py <text-file> <repaired|superseded>

"repaired"   asserts the repair rules above (exit 0 when all nine hold).
"superseded" asserts the opposite — that the text still reasons from a licence — and
             is the negative control: it exits non-zero if the phrase list has gone
             stale and no longer finds the text it was written against.
"""
import sys, pathlib

ABSENT = [
    ("gate-list", "no crate exists to fail a licence, MSRV, advisory, platform, feature or build-cost gate"),
    ("table-header", "| Open issues | Licence | Declared MSRV |"),
    ("serde-clause", "`serde` fails no gate: licence identical to the template's"),
    ("compatibility", "combines every member in production under edition 2024 and `MIT OR Apache-2.0`"),
    ("validation-strategy", "the version pins' resolution with their licences and MSRVs"),
    ("check-3-claim", "with permissive licences and MSRVs inside the 1.96 floor"),
    ("check-3-heading", "**Check 3 — the pins resolve, with licences and MSRVs.**"),
    ("check-3-finding", "Every licence in it is permissive and compatible with distributing an `MIT OR Apache-2.0` project; none is copyleft."),
]
QUOTED = ("patent-grant-clause", "lacks Apache-2.0's patent grant", "That clause is struck")


def main() -> int:
    text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    mode = sys.argv[2]
    failures = 0
    for name, phrase in ABSENT:
        count = text.count(phrase)
        if mode == "repaired":
            ok, detail = count == 0, "absent" if count == 0 else "STILL PRESENT %dx" % count
        else:
            ok, detail = count >= 1, "present %dx" % count if count else "NOT FOUND — phrase list is stale"
        failures += 0 if ok else 1
        print("  %-22s %-4s %s" % (name, "ok" if ok else "FAIL", detail))
    name, phrase, follower = QUOTED
    count = text.count(phrase)
    if mode == "repaired":
        index = text.find(phrase)
        struck = index >= 0 and follower in text[index:index + 320]
        ok = count == 1 and struck
        detail = "quoted once and struck" if ok else "count=%d struck=%s" % (count, struck)
    else:
        ok = count >= 1
        detail = "present %dx" % count if count else "NOT FOUND — phrase list is stale"
    failures += 0 if ok else 1
    print("  %-22s %-4s %s" % (name, "ok" if ok else "FAIL", detail))
    return failures


if __name__ == "__main__":
    sys.exit(main())
