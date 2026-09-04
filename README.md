# rs-launch-blueprint

The Rust sibling of [py-launch-blueprint](https://github.com/smorinlabs/py-launch-blueprint)
and [ts-launch-blueprint](https://github.com/smorinlabs/ts-launch-blueprint): a
production-ready template for a Rust CLI + library + web service.

**Status: research phase.** There is no Rust code here yet. This repository
currently holds the analysis that decides what the template will be made of:

| Where | What |
|---|---|
| `docs/port/` | Side-by-side inventories of the two existing blueprints and the authoritative reuse / substitute / override ledger (`COMMONALITY.md`) |
| `research/CLAUDE.md` | Index of every open technology or pattern decision, one deep-research prompt each |
| `docs/superpowers/specs/` | The approved design for this research program |
| `scripts/check-research-tree.sh` | Structural checks for the index, prompts, and ledger |

## Governing rule

Anything both existing blueprints do the same way is inherited here by default.
Deviating requires a very strong Rust-specific reason, and every deviation is
labeled **OVERRIDE** with its argument and the options considered. Replacing a
language-bound tool (e.g. `ruff` → a Rust linter) under the same pattern is a
substitution, not an override. Full vocabulary: `docs/port/README.md`.

## License

MIT OR Apache-2.0, at your option — see `LICENSE` (Apache-2.0) and `LICENSE-MIT`.
