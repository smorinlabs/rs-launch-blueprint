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

Research the best engineering principles, architectures, and libraries for a
realistic CLI, library, and web-service example. Existing blueprints supply
evidence and lessons; agreement between them does not establish best practice.
Preserve the intended outcomes with designs suited to each ecosystem, and
justify both shared conventions and useful differences. Changes to recorded
patterns remain auditable as **OVERRIDE** decisions with the argument and
options considered. Full vocabulary: `docs/port/README.md`; authority: design
spec §2 and owner amendment A5.

## License

MIT OR Apache-2.0, at your option — see `LICENSE` (Apache-2.0) and `LICENSE-MIT`.
