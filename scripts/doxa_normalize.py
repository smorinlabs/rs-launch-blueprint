#!/usr/bin/env python3
"""Normalize a completed Doxa deep-research operation into publishable twins.

A Doxa `all_deep_research` operation saves one Markdown file per provider under
`<run>/doxa/research-outputs/`.  Each saved file echoes the prompt (a frontmatter
block plus a fenced `### Prompt` section) before the provider's answer, so the
saved file cannot be shape-checked as an answer.  This tool produces the two
artifacts the packager stages:

  raw/doxa-<provider>.normalized.md   one provider's answer body, prompt echo
                                      stripped, lossless heading repairs applied
  raw/doxa.normalized.md              the three bodies regrouped under the
                                      prompt's template fields as one answer

usage
-----
  # one per provider (openai, perplexity, gemini)
  scripts/doxa_normalize.py provider \
      --saved <run>/doxa/research-outputs/<file>.md \
      --provider openai --kind bundle \
      --out <run>/raw/doxa-openai.normalized.md \
      --record <run>/doxa/normalization.json

  # then the merged twin
  scripts/doxa_normalize.py merge --run-dir <run> --kind bundle \
      --out <run>/raw/doxa.normalized.md \
      --record <run>/doxa/normalization.json

  # ad-hoc shape check of any twin
  scripts/doxa_normalize.py check --file <run>/raw/doxa.normalized.md --kind bundle

Every subcommand runs `research_validation.validate_answer_text` on what it
wrote and exits non-zero, printing the errors, when the shape check fails.  The
output file is always left on disk so the failure can be inspected.

EXPECTED FAILURE: `provider` routinely exits non-zero for Perplexity on bundle
prompts, which fills the per-member fields but drops four or five top-level
template fields.  That gap is recorded (`field_gaps`) and never supplemented;
the caller proceeds to `merge`, whose regrouped twin is the artifact that must
pass.

repairs applied by `provider` (lossless: no prose is added, removed or edited)
  1. `### #### Member name`            -> `#### Member name`
  2. `### Principles and Implementation` -> `### Principles and implementation`
     and the same case repair on a member's `##### ` fields (bundle only)
  3. `## Sources`                      -> `### Sources`, but only when no
     `### Sources` already exists (a provider may legitimately carry both: a
     template field and a trailing reference list)
  4. any remaining non-template `### X` -> `**X**`

regrouping applied by `merge`
  * each provider's body is sliced at its template-field H3 headings; the text
    before the first field becomes that provider's preamble
  * fields are emitted in template order; within a field the providers appear
    in the fixed order OpenAI, Perplexity, Gemini under bold labels
  * every H1-H3 heading inside a provider's preamble or field body is demoted to
    bold text, so the only H1-H3 headings in the twin are the template's own.
    This is what keeps `### Members` open: a provider H2 landing inside the
    members span closes the window and orphans every `##### ` member field (the
    defect that refused R69's publication on 2026-09-17)
  * outside `### Members`, a stray `##### ` is demoted to `###### `, which the
    validator ignores
  * under `### Members` every provider's members are kept with the provider name
    appended; a member whose `##### ` fields are not the complete crate field set
    is demoted to bold text and recorded in `member_notes`
  * a content-line census asserts that every non-blank, non-heading line of every
    provider twin survives into the merged twin

Python 3, standard library only (plus this repository's research_validation).
"""
from __future__ import print_function

import argparse
import collections
import json
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
if str(HERE) not in sys.path:
    sys.path.insert(0, str(HERE))
from research_validation import (  # noqa: E402
    BUNDLE_FIELDS,
    CRATE_FIELDS,
    PATTERN_FIELDS,
    _headings_with_bodies,
    _line_states,
    validate_answer_text,
)

PROVIDERS = ["openai", "perplexity", "gemini"]
LABELS = {"openai": "OpenAI", "perplexity": "Perplexity", "gemini": "Gemini"}
KINDS = {"crate": CRATE_FIELDS, "pattern": PATTERN_FIELDS, "bundle": BUNDLE_FIELDS}
FRONTMATTER_KEYS = ("mode", "provider", "model", "operation_id", "created_at")


# ---------------------------------------------------------------- primitives


def fence_map(lines):
    """Return a bool per line: True when the line is a fence delimiter or inside one."""
    states = _line_states("\n".join(lines) + "\n")
    return [fenced for _, fenced in states][:len(lines)]


def canonical(name, fields):
    """Return the template field `name` names, compared case-insensitively, else None."""
    folded = name.strip().casefold()
    for field in fields:
        if field.casefold() == folded:
            return field
    return None


def heading(line, level):
    """Return the text of a level-`level` ATX heading that is not a deeper marker."""
    match = re.match(r"^%s[ \t]+([^#].*)$" % ("#" * level), line)
    return match.group(1).strip() if match else None


def any_heading(line):
    """Return (level, text) for any ATX heading, else None."""
    match = re.match(r"^(#{1,6})[ \t]+(.*)$", line)
    return (len(match.group(1)), match.group(2).strip()) if match else None


def strip_blank_edges(lines):
    start, end = 0, len(lines)
    while start < end and not lines[start].strip():
        start += 1
    while end > start and not lines[end - 1].strip():
        end -= 1
    return lines[start:end]


# ------------------------------------------------------- saved-file handling


def split_saved(text):
    """Return (metadata, answer_body) for one Doxa saved provider file.

    The answer begins after the fenced block of the file's `### Prompt` section.
    """
    lines = text.splitlines()
    fenced = fence_map(lines)
    prompt_at = next((i for i, line in enumerate(lines)
                      if not fenced[i] and line.strip() == "### Prompt"), None)
    if prompt_at is None:
        raise ValueError("saved file has no '### Prompt' section; cannot find the answer body")
    opened = next((i for i in range(prompt_at + 1, len(lines)) if fenced[i]), None)
    if opened is None:
        raise ValueError("saved file has no fenced prompt echo after '### Prompt'")
    closed = opened
    while closed + 1 < len(lines) and fenced[closed + 1]:
        closed += 1
    body = strip_blank_edges(lines[closed + 1:])
    if not body:
        raise ValueError("saved file has no answer body after the prompt echo")

    metadata = {}
    for index in range(0, prompt_at):
        if fenced[index]:
            continue
        match = re.match(r"^(%s):[ \t]*(.*)$" % "|".join(FRONTMATTER_KEYS), lines[index])
        if match and match.group(1) not in metadata:
            metadata[match.group(1)] = match.group(2).strip()
    for key in ("provider", "model", "operation_id"):
        if not metadata.get(key):
            raise ValueError("saved file frontmatter has no %r line" % key)
    return metadata, body


# ------------------------------------------------------------ twin normalizing


def repair(body, kind):
    """Apply the lossless heading repairs; return (lines, changes in document order)."""
    fields = KINDS[kind]
    lines = list(body)
    fenced = fence_map(lines)

    present = set()
    for index, line in enumerate(lines):
        if fenced[index]:
            continue
        text = heading(line, 3)
        if text is not None:
            name = canonical(text, fields)
            if name:
                present.add(name)

    changes = []
    for index, line in enumerate(lines):
        if fenced[index]:
            continue
        nested = re.match(r"^###[ \t]+(#{1,6}[ \t]+.*)$", line)
        if nested:
            marker = nested.group(1)
            lines[index] = marker
            changes.append("'%s' -> H%d" % (line, len(marker) - len(marker.lstrip("#"))))
            continue
        text = heading(line, 3)
        if text is not None:
            name = canonical(text, fields)
            if name is None:
                lines[index] = "**%s**" % text
                changes.append("'### %s' (not a template field) -> bold" % text)
            elif name != text:
                lines[index] = "### %s" % name
                changes.append("'### %s' -> '### %s' (case)" % (text, name))
            continue
        text = heading(line, 2)
        if text is not None:
            name = canonical(text, fields)
            if name is not None and name not in present:
                lines[index] = "### %s" % name
                present.add(name)
                changes.append("'## %s' -> H3" % text)
            continue
        if kind == "bundle":
            text = heading(line, 5)
            if text is not None:
                name = canonical(text, CRATE_FIELDS)
                if name is not None and name != text:
                    lines[index] = "##### %s" % name
                    changes.append("'##### %s' -> '##### %s' (case)" % (text, name))
    return lines, changes


def field_gaps(lines, kind):
    fields = KINDS[kind]
    fenced = fence_map(lines)
    found = {canonical(heading(line, 3) or "", fields)
             for index, line in enumerate(lines) if not fenced[index]}
    missing = [field for field in fields if field not in found]
    return missing


def shape_of(errors):
    """One-line `shape` value for the record.

    On failure the record carries the last error, which the validator emits in
    increasing specificity (field order, then empty bodies, then per-member
    faults); the full list always goes to stdout.  The Wave 0 records this tool
    reproduces use the same convention.
    """
    return "OK: validation passed" if not errors else "FAIL: %s" % errors[-1]


# --------------------------------------------------------------- record file


def load_record(path):
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))
    return {}


def save_record(path, record):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(record, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def run_relative(run_dir, path):
    try:
        return str(path.resolve().relative_to(run_dir.resolve()))
    except ValueError:
        return str(path)


# ---------------------------------------------------------------- regrouping


def segment(lines, kind):
    """Split one provider twin into (preamble, {field: lines}) at template-field H3s."""
    fields = KINDS[kind]
    fenced = fence_map(lines)
    marks = []
    for index, line in enumerate(lines):
        if fenced[index]:
            continue
        text = heading(line, 3)
        name = canonical(text, fields) if text is not None else None
        if name is not None and name == text:
            marks.append((index, name))
    if not marks:
        return list(lines), {}
    preamble = lines[:marks[0][0]]
    bodies = collections.OrderedDict()
    for position, (index, name) in enumerate(marks):
        end = marks[position + 1][0] if position + 1 < len(marks) else len(lines)
        bodies.setdefault(name, []).extend(lines[index + 1:end])
    return preamble, bodies


def demote(lines, kind, keep_members):
    """Demote every heading that must not survive into the merged twin.

    H1-H3 become bold text so they cannot close a template field or the
    `### Members` window.  Outside `### Members`, a bundle's stray `##### `
    becomes `###### `, which the validator ignores.
    """
    result = list(lines)
    fenced = fence_map(result)
    for index, line in enumerate(result):
        if fenced[index]:
            continue
        found = any_heading(line)
        if not found:
            continue
        level, text = found
        if level <= 3:
            result[index] = "**%s**" % text if text else ""
        elif level == 5 and kind == "bundle" and not keep_members:
            result[index] = "###### %s" % text
    return result


def regroup_members(lines, label, used, kind):
    """Rewrite one provider's `### Members` body for the merged twin."""
    lines = demote(lines, kind, keep_members=True)
    fenced = fence_map(lines)
    starts = [index for index, line in enumerate(lines)
              if not fenced[index] and heading(line, 4) is not None]
    notes = []
    if not starts:
        return lines, notes
    for position, start in enumerate(starts):
        end = starts[position + 1] if position + 1 < len(starts) else len(lines)
        name = heading(lines[start], 4)
        section = "\n".join(lines[start + 1:end])
        found = _headings_with_bodies(section, "##### ")
        complete = ([entry for entry, _ in found] == CRATE_FIELDS
                    and all(nonempty for _, nonempty in found))
        tagged = "%s (%s)" % (name, label)
        if not complete:
            present = ", ".join(entry for entry, _ in found) or "none"
            lines[start] = ("**%s — incomplete member in this provider's report; "
                            "fields present: %s**" % (tagged, present))
            inner = fence_map(lines)
            for index in range(start + 1, end):
                if inner[index]:
                    continue
                text = heading(lines[index], 5)
                if text is not None:
                    lines[index] = "**%s**" % text
            notes.append("member %r incomplete (H5 fields present: %s); demoted to bold text"
                         % (name, [entry for entry, _ in found]))
            continue
        unique = tagged
        counter = 2
        while unique in used:
            unique = "%s (%s #%d)" % (name, label, counter)
            counter += 1
        if unique != tagged:
            notes.append("member %r renamed to %r to keep member names distinct" % (tagged, unique))
        used.add(unique)
        lines[start] = "#### %s" % unique
    return lines, notes


HEADER = ("Normalization record: Doxa operation {operation} ({mode}) returned one report per "
          "provider. This file regroups the three answer bodies under the prompt's template "
          "fields so the single-report shape check applies; within each field the three provider "
          "sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold "
          "label{members}. Every content line of each provider's answer body is preserved (the "
          "originals are the three saved files under the run's doxa/ directory; "
          "raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would "
          "fall outside the template are demoted to bold text so no heading outside the template "
          "remains; doxa/normalization.json lists every other adjustment.")

MEMBERS_CLAUSE = (", and under `### Members` every provider's members are kept with the provider "
                  "name appended to the member heading")


def build_merged(item, kind, operation, mode, twins, models):
    """Return (text, member_notes by provider)."""
    fields = KINDS[kind]
    out = ["# %s — Doxa engine report (three providers, regrouped by template field)" % item, ""]
    out.append(HEADER.format(operation=operation, mode=mode,
                             members=MEMBERS_CLAUSE if kind == "bundle" else ""))
    out.append("")
    out.append("**Provider preambles (text preceding each provider's first template field)**")

    parts, notes = {}, {}
    for provider in PROVIDERS:
        if provider not in twins:
            continue
        preamble, bodies = segment(twins[provider], kind)
        parts[provider] = (strip_blank_edges(demote(preamble, kind, keep_members=False)), bodies)

    for provider in PROVIDERS:
        if provider not in parts:
            continue
        out += ["", "**%s (%s)**" % (LABELS[provider], models.get(provider, "unknown model")), ""]
        out += parts[provider][0]

    used = set()
    for field in fields:
        out += ["", "### %s" % field]
        for provider in PROVIDERS:
            if provider not in parts:
                continue
            out += ["", "**%s**" % LABELS[provider], ""]
            body = parts[provider][1].get(field)
            if body is None:
                out.append("_No `%s` section in this provider's report "
                           "(see doxa/normalization.json)._" % field)
                continue
            if kind == "bundle" and field == "Members":
                body, member_notes = regroup_members(body, LABELS[provider], used, kind)
                notes.setdefault(provider, []).extend(member_notes)
            else:
                body = demote(body, kind, keep_members=False)
            out += strip_blank_edges(body)
    return "\n".join(out) + "\n", notes


def census(twin_lines, merged_text):
    """Return the multiset of twin content lines absent from the merged twin."""
    fenced = fence_map(twin_lines)
    wanted = collections.Counter()
    for index, line in enumerate(twin_lines):
        if not line.strip():
            continue
        if not fenced[index] and any_heading(line):
            continue
        wanted[line] += 1
    return wanted - collections.Counter(merged_text.splitlines())


# ----------------------------------------------------------------- reporting


def report(path, kind, errors):
    if errors:
        print("FAIL %s (%s): %d shape error(s)" % (path, kind, len(errors)))
        for error in errors:
            print("  %s" % error)
        return 1
    print("OK %s (%s): validation passed" % (path, kind))
    return 0


# ---------------------------------------------------------------- subcommands


def command_provider(args):
    saved = Path(args.saved)
    out = Path(args.out)
    record_path = Path(args.record)
    metadata, body = split_saved(saved.read_text(encoding="utf-8"))
    if metadata["provider"] != args.provider:
        raise SystemExit("saved file is provider %r, not %r"
                         % (metadata["provider"], args.provider))
    lines, changes = repair(body, args.kind)
    text = "\n".join(lines) + "\n"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")

    errors = validate_answer_text(text, args.kind)
    run_dir = record_path.parent.parent
    record = load_record(record_path)
    record.setdefault("operation_id", metadata["operation_id"])
    record["kind"] = args.kind
    providers = record.setdefault("providers", {})
    entry = providers.setdefault(args.provider, {})
    entry["saved_file"] = run_relative(run_dir, saved)
    entry["model"] = metadata["model"]
    entry["changes"] = changes
    entry["normalized"] = out.name
    entry["shape"] = shape_of(errors)
    missing = field_gaps(lines, args.kind)
    if missing:
        entry["field_gaps"] = "missing fields: %r" % missing
    else:
        entry.pop("field_gaps", None)
    if args.kind == "bundle":
        entry.setdefault("member_notes", [])
    entry.setdefault("content_lines_missing_from_regrouped", None)
    record["providers"] = {name: providers[name] for name in PROVIDERS if name in providers}
    save_record(record_path, record)

    print("%s: %d heading repair(s)%s"
          % (args.provider, len(changes),
             ("; " + record["providers"][args.provider]["field_gaps"]) if missing else ""))
    return report(out, args.kind, errors)


def command_merge(args):
    run_dir = Path(args.run_dir)
    out = Path(args.out)
    record_path = Path(args.record)
    record = load_record(record_path)
    if not record.get("providers"):
        raise SystemExit("%s has no provider records; run the 'provider' subcommand first"
                         % record_path)
    item = args.item or run_dir.resolve().parent.name

    twins, models = {}, {}
    mode, operation = "all_deep_research", record.get("operation_id", "unknown")
    for provider in PROVIDERS:
        entry = record["providers"].get(provider)
        if not entry:
            print("note: no record for provider %s; it contributes nothing" % provider)
            continue
        twin = run_dir / "raw" / entry["normalized"]
        if not twin.exists():
            print("note: %s is missing; provider %s contributes nothing" % (twin, provider))
            continue
        twins[provider] = twin.read_text(encoding="utf-8").splitlines()
        models[provider] = entry.get("model", "unknown model")
        saved = run_dir / entry.get("saved_file", "")
        if saved.is_file():
            try:
                metadata, _ = split_saved(saved.read_text(encoding="utf-8"))
                mode = metadata.get("mode") or mode
                operation = metadata.get("operation_id") or operation
            except ValueError:
                pass
    if not twins:
        raise SystemExit("no provider twins found under %s/raw" % run_dir)

    text, notes = build_merged(item, args.kind, operation, mode, twins, models)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")

    lost = 0
    for provider, lines in twins.items():
        missing = census(lines, text)
        record["providers"][provider]["content_lines_missing_from_regrouped"] = sum(missing.values())
        if args.kind == "bundle":
            record["providers"][provider]["member_notes"] = notes.get(provider, [])
        lost += sum(missing.values())
        if missing:
            print("CENSUS FAIL %s: %d content line(s) absent from the merged twin"
                  % (provider, sum(missing.values())))
            for line in list(missing)[:5]:
                print("  missing: %s" % line[:160])
    errors = validate_answer_text(text, args.kind)
    record["kind"] = args.kind
    record["regrouped"] = {"file": out.name, "shape": shape_of(errors)}
    save_record(record_path, record)

    print("merged %d provider(s); content lines lost: %d" % (len(twins), lost))
    status = report(out, args.kind, errors)
    return 1 if (status or lost) else 0


def command_check(args):
    path = Path(args.file)
    errors = validate_answer_text(path.read_text(encoding="utf-8"), args.kind)
    return report(path, args.kind, errors)


def main(argv=None):
    parser = argparse.ArgumentParser(
        prog="doxa_normalize.py",
        description="Normalize saved Doxa provider reports into publishable answer twins.")
    subparsers = parser.add_subparsers(dest="command")

    one = subparsers.add_parser("provider", help="strip a saved file's prompt echo and repair headings")
    one.add_argument("--saved", required=True, help="the Doxa saved provider file")
    one.add_argument("--provider", required=True, choices=PROVIDERS)
    one.add_argument("--kind", required=True, choices=sorted(KINDS))
    one.add_argument("--out", required=True, help="raw/doxa-<provider>.normalized.md")
    one.add_argument("--record", required=True, help="doxa/normalization.json")
    one.set_defaults(handler=command_provider)

    both = subparsers.add_parser("merge", help="regroup the provider twins into one answer")
    both.add_argument("--run-dir", required=True, help="the research run directory")
    both.add_argument("--kind", required=True, choices=sorted(KINDS))
    both.add_argument("--out", required=True, help="raw/doxa.normalized.md")
    both.add_argument("--record", required=True, help="doxa/normalization.json")
    both.add_argument("--item", help="item id for the title (default: the run directory's parent)")
    both.set_defaults(handler=command_merge)

    only = subparsers.add_parser("check", help="shape-check an existing twin")
    only.add_argument("--file", required=True)
    only.add_argument("--kind", required=True, choices=sorted(KINDS))
    only.set_defaults(handler=command_check)

    args = parser.parse_args(argv)
    if not getattr(args, "handler", None):
        parser.print_help()
        return 2
    return args.handler(args)


if __name__ == "__main__":
    sys.exit(main())
