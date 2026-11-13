# Baseline review samples for the P02 plan

Status: evidence for planning the mandatory P02-T01 baseline review. This is
not a completed review of every REUSE/ADOPT row and changes no verdict.

The source commits remain Python
`b08bccfb55d05f15e46a83b52c5660b1881d19f5` and TypeScript
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. The commands below read those Git
objects, not a moving checkout. The Rust ledger is at
`2f3569051af2c2089f60f6cad129bc6e55482c30`.

| Feature | Verified source behavior | Planning finding and affected decision |
|---|---|---|
| F246, secret masking for display | Python `src/py_launch_blueprint/cli/commands/config.py:212` reveals the last four characters when length exceeds four. TypeScript `src/lib/config.ts:233` does so only when length exceeds eight. | The ledger's common reveal-last-four description omits a behaviorally meaningful threshold difference. Example: a six-character token reveals four characters in Python and none in TypeScript. Review the agreement level and existing R56 secret policy scope before freezing a Rust masking rule. This is source evidence, not a recommendation to reveal secrets. |
| F179, two-level bootstrap using Makefile and Justfile | Python `Makefile:43` separates base toolchain installation from development tasks. TypeScript `Makefile:1` makes the same split. | A shared mechanism is verified, but agreement does not establish its fitness for Rust. R42 provisioning must compare how the desired bootstrap and repeatable-task outcomes can be met, including the existing split. Preserve history if evidence changes the baseline. |
| F304, tracing as a second optional dependency group | Python `pyproject.toml:53` defines `web` and `otel` separately. The pinned TypeScript source has no corresponding web implementation. | R69 web surface and R78 OTel integration must justify the Rust feature boundary. The owner's requirement for a working OTel example must survive any optional packaging choice. The Python packaging mechanism does not settle the Rust architecture. |
| F331, router import plus registry entry | Python `src/py_launch_blueprint/web/routers/__init__.py:24-30` describes and implements a FastAPI router list. There is no TypeScript web implementation in the pinned source. | R69 must preserve straightforward resource registration while comparing native router composition. The ADOPT phrase “nothing to research” cannot fix a Python registry architecture before that comparison. |

Candidate findings for the controller to adjudicate under RUNBOOK §4:

```text
BASELINE-REVIEW: F246 — prevent sensitive values appearing in routine display — explicitly assess short-token thresholds under R56 before treating reveal-last-four as the shared policy — pinned Python config.py:212 and TypeScript config.ts:233 disagree for lengths 5 through 8
BASELINE-REVIEW: F179 — bootstrap a repeatable development environment — let R42 justify the Makefile/Justfile division before preserving it as architecture — pinned Python Makefile:43 and TypeScript Makefile:1 establish precedent, not Rust fitness
BASELINE-REVIEW: F304 — keep CLI/library dependency costs controlled while providing a working OTel web example — let R69 and R78 justify feature boundaries — Python pyproject.toml:53-69 has separate extras and pinned TypeScript has no web implementation
BASELINE-REVIEW: F331 — make adding a resource straightforward and explicit — let R69 compare native composition before accepting a router registry — Python web/routers/__init__.py:24-30 uses a FastAPI-specific list
```

Reconciliation is one controlled change to the affected ledger rows, history,
prompts, index and dependencies. These samples do not authorize new items or
changes to fixed owner requirements. The full baseline review must classify
every inherited row as retained with a fitness argument, challenged, or blocked
pending a named decision. It should batch related mechanisms into existing
decision scope where valid and seek an owner disposition for new scope.

Reproduction from the named source repository directories:

```bash
git show b08bccfb55d05f15e46a83b52c5660b1881d19f5:src/py_launch_blueprint/cli/commands/config.py
git show b08bccfb55d05f15e46a83b52c5660b1881d19f5:src/py_launch_blueprint/web/routers/__init__.py
git show b08bccfb55d05f15e46a83b52c5660b1881d19f5:Makefile
git show b08bccfb55d05f15e46a83b52c5660b1881d19f5:pyproject.toml
```

```bash
git show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:src/lib/config.ts
git show cb1cbcb2e88b898e8c081b0abbfabc1630079c00:Makefile
git ls-tree -r --name-only cb1cbcb2e88b898e8c081b0abbfabc1630079c00 src
```
