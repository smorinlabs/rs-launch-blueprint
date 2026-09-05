"""Small shared CLI contract for the repository's offline research tools."""

from __future__ import annotations

import argparse
from contextlib import contextmanager
import json
import os
import sys
from pathlib import Path


class UsageError(Exception):
    """Invalid user input, reported with exit status 2."""


class Parser(argparse.ArgumentParser):
    def __init__(self, *args, **kwargs):
        kwargs.setdefault("allow_abbrev", False)
        super().__init__(*args, **kwargs)

    def error(self, message):
        raise UsageError(message)


def add_common_arguments(parser, version):
    parser.add_argument("-V", "--version", action="version", version=version)
    parser.add_argument("-v", "--verbose", action="count", default=0,
                        help="increase diagnostics; repeat for more detail")
    parser.add_argument("-q", "--quiet", action="store_true",
                        help="suppress informational diagnostics, preserving results")
    parser.add_argument("--debug", action="store_true",
                        help="maximum diagnostics; overrides --quiet")
    parser.add_argument("--config", metavar="FILE",
                        help="explicit UTF-8 JSON configuration containing only root")
    parser.add_argument("-o", "--output", choices=("json",),
                        help="select machine-readable result format")
    parser.add_argument("--json", action="store_true",
                        help="alias for --output json")


def parse_args(parser, argv):
    """Parse flags; explicit argv values override the optional config file.

    An empty invocation requests top-level help. No config is read implicitly.
    The tools are offline and have only one configurable setting: their root.
    """
    if not argv:
        parser.print_help()
        raise SystemExit(0)
    if argv[0] == "help":
        argv = [*argv[1:], "--help"]
    args = parser.parse_args(argv)
    args.json = args.json or args.output == "json"
    if args.config:
        try:
            raw = Path(args.config).read_text(encoding="utf-8")
            config = json.loads(raw)
        except (OSError, UnicodeError, ValueError) as exc:
            # Report the path and cause, never the contents of configuration.
            raise UsageError("cannot read JSON configuration %s (%s)" %
                             (args.config, type(exc).__name__)) from exc
        if not isinstance(config, dict) or set(config) - {"root"}:
            raise UsageError("configuration must be an object containing only root")
        if "root" in config:
            if not isinstance(config["root"], str) or not config["root"].strip():
                raise UsageError("configuration root must be nonempty text")
            if getattr(args, "root", None) is None:
                args.root = str((Path(args.config).resolve().parent / config["root"]).resolve())
    args.diagnostic_level = 3 if args.debug else (0 if args.quiet else min(args.verbose, 3))
    return args


def json_requested(argv):
    # Inspect the full invocation even when argument parsing failed.
    for number, token in enumerate(argv):
        if token == "--json" or token == "--output=json" or token == "-ojson":
            return True
        if token in ("--output", "-o") and number + 1 < len(argv) and argv[number + 1] == "json":
            return True
    return False


def emit_error(exc, argv, code="failed", details=None):
    usage = isinstance(exc, UsageError)
    payload = {"code": "usage" if usage else code, "message": str(exc)}
    if details is not None:
        payload["details"] = details
    if json_requested(argv):
        print(json.dumps({"error": payload}, sort_keys=True), file=sys.stderr)
    else:
        print("error: " + str(exc), file=sys.stderr)
    return 2 if usage else 1


def diagnostic(args, message, level=1):
    if args.diagnostic_level >= level:
        print(message, file=sys.stderr)


@contextmanager
def evidence_read_lock(root):
    """Coordinate CLI readers with the runner; never steal an existing lock."""
    root = Path(root).resolve(strict=True)
    for relative in ("research", "research/runs", "research/runs/.publication.lock",
                     "research/runs/.publication-journal.json"):
        if (root / relative).is_symlink():
            raise RuntimeError("refuse symlink in publication coordination path: " + relative)
    if not (root / "research").is_dir():
        raise RuntimeError("missing research directory: " + str(root))
    runs = root / "research/runs"
    runs.mkdir(exist_ok=True)
    lock = runs / ".publication.lock"
    try:
        lock.mkdir()
    except FileExistsError as exc:
        raise RuntimeError("publication lock is active; retry after its owner completes") from exc
    try:
        (lock / "owner.json").write_text(json.dumps({"pid": os.getpid(), "purpose": "evidence validation"}) + "\n")
        if (runs / ".publication-journal.json").exists():
            raise RuntimeError("publication recovery required before validation; run publication recover")
        yield
    finally:
        (lock / "owner.json").unlink(missing_ok=True)
        lock.rmdir()
