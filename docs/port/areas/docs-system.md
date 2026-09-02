# Area: docs-system

Sources: py-launch-blueprint @ b08bccf · ts-launch-blueprint @ cb1cbcb

| feature | py | ts | origin | ts-decisions | notes |
|---|---|---|---|---|---|
| docs delivery model | `.readthedocs.yaml:44` — `configuration: docs/source/conf.py`, generated Sphinx HTML site hosted on Read the Docs | `docs/docs.md:1` — README-centric front door + plain CommonMark/GFM `docs/` tree rendered by GitHub | different | D-023(1) | No generated site, no host, in ts. |
| documentation information architecture | `docs/source/index.md:241` — `{toctree}` listing about/tasks/tools/tutorials/reference/contributing | `docs/docs.md:1` — same Diátaxis categories, flattened from `docs/source/` to `docs/` | same | D-023(2) | Category set preserved verbatim; only the physical tree location changed. |
| markdown dialect | `docs/source/conf.py:33` — MyST (colon fences, deflist, heading anchors) via `myst_parser` | `docs/docs.md:3` — plain CommonMark/GFM, no MyST | different | D-023(3) | ~90% of the py corpus was already generator-agnostic per the decision log. |
| section navigation mechanism | `docs/source/reference/index.md:4` — Sphinx `{toctree}` directive | `docs/reference/index.md:5` — plain bullet list of relative links | different | D-023(3) | 8 toctree blocks converted; same pattern repeats across every index page. |
| root-README vs. site-landing-page duplication | `docs/source/index.md:1` — separate landing page duplicating README content | `README.md:137` — landing content merged into README, no separate `index.md` | different | D-023(3) | py keeps two parallel front doors; ts keeps one. |
| root README "documentation" pointer | `README.md:20` — links out to the hosted ReadTheDocs URL | `README.md:139` — links to the in-repo `docs/docs.md` tree with a bullet index of every section | different | D-023(1) | — |
| documentation authoring guide (how to add a page) | `docs/source/docs.md:5` — explains adding pages via Sphinx `{toctree}` entries and MyST cross-reference labels | `docs/docs.md:1` — explains adding pages via a plain relative link from a directory's `index.md` | same | D-023(3) | Both are a dedicated "how this docs tree works" page; content mechanics differ with the underlying system. |
| doc content correctness gate | `.github/workflows/ci.yml:242` — `sphinx-build -W` fails the PR on any broken cross-reference or autodoc error | `.github/workflows/ci.yml:98` — `just docs-check` (`scripts/check-links.mjs`) fails the PR on any broken relative link | different | D-023(5) | py's gate also covers autodoc/directive errors; ts's is link-resolution only. |
| offline relative-link checker tool | — | `scripts/check-links.mjs:1` — dependency-free Node script walking `README.md` + `docs/` for unresolved relative link targets | ts-only | D-023(5) | Chosen over lychee/markdown-link-check per the script's own header comment (not installed on this machine/CI image). |
| external URL link-check | `.github/workflows/dep-audit.yml:69` — weekly `sphinx-build -b linkcheck` job | — | py-only | — | No decision entry addresses external-URL checking specifically; D-023(5) only speaks to the internal-link replacement. |
| local docs preview server (hot reload) | `Justfile:450` — `docs-dev` runs `sphinx-autobuild` | — | py-only | — | ts's guide directs authors to an editor preview or a pushed branch instead (`docs/docs.md:11`). |
| docs scaffold/init recipe | `Justfile:434` — `init-docs` runs `sphinx-quickstart` | — | py-only | — | No scaffolding step exists for a system with no generator to initialize. |
| API reference doc generator | `docs/source/conf.py:27` — `sphinx.ext.autodoc`, wired but zero directives used (latent) | `Justfile:203` — TypeDoc, wired as optional `just docs-api`, not CI-gated (D-023(4)) | different | D-023(4) | Matched latent-investment posture: configured-but-unused in both. |
| ADR (Architecture Decision Record) system | `docs/adr/README.md:1` — dated/numbered directory with conventions, index table, and `docs/adr/template.md:1` scaffold file | — | py-only | — | No `docs/adr/` (or equivalent) directory exists in ts; not addressed by any D-023 sub-item. |
| design-spec doc system | `docs/design/README.md:1` — numbered directory of normative "what to build" proposals with its own index | — | py-only | — | Same gap as the ADR row; no ts equivalent found. |
| research doc system | `docs/research/README.md:1` — numbered directory of non-normative investigation docs with its own index | — | py-only | — | Same gap; TS_PORT_DECISIONS.md is itself an ADR-style log, but it documents the *port process*, not the ported project's own decisions. |
| internal-docs top-level orientation page | `docs/README.md:1` — explains the adr/design/research three-bucket split and why they live outside the published site | — | py-only | — | No equivalent top-level "how our internal docs are organized" page in ts. |
| documented (unshipped) future docs-site upgrade path | — | `docs/port/TS_PORT_DECISIONS.md:308` — Astro Starlight on GitHub Pages named as the designated upgrade path if a hosted site becomes necessary; not built | ts-only | D-023(6) | Decision-log-only; no Starlight config or GitHub Pages workflow exists in the repo. |

## Language-bound tools
- `sphinx` (py) — the documentation-site generator itself
- `myst-parser` (py) — Markdown-in-Sphinx parser enabling MyST syntax
- `furo` (py) — HTML theme for the generated site (`docs/source/conf.py:64`)
- `sphinx-autobuild` (py) — watch-and-rebuild server backing `docs-dev`
- `sphinx-copybutton` (py) — adds a copy button to rendered code blocks
- `sphinx-rtd-theme` / `sphinxext-opengraph` (py) — docs dependency group entries, unused per D-023(5)
- TypeDoc / `typedoc-plugin-markdown` (ts) — optional API-doc generator behind `just docs-api`

## Cross-area parameters
- `web-extra-surface` — the docs CI job syncs `--extra web` so autodoc can import the optional web module (`.github/workflows/ci.yml:240`); whether ts carries an equivalent optional surface is decided outside this area.
- `ci-job-structure` — whether the doc-correctness gate is its own CI job (py's `docs:` job) or a step inside a shared job (ts's `ci.yml:98` step) follows the CI topic's overall job layout, not this area.

## Files read
- py: `docs/source/conf.py`
- py: `docs/source/index.md`
- py: `docs/source/docs.md`
- py: `docs/source/reference/index.md`
- py: `docs/source/github-templates.md` — no feature: content page, already covered by the information-architecture row
- py: `docs/adr/README.md`
- py: `docs/adr/template.md`
- py: `docs/design/README.md`
- py: `docs/research/README.md`
- py: `docs/README.md`
- py: `docs/RELEASE.md` — no feature: release-process content, owned by the release-versioning area
- py: `docs/POST_INIT.md` — no feature: template-rebrand checklist, not part of the docs generator/ADR/README-structure/lint/publish scope
- py: `README.md`
- py: `Justfile`
- py: `pyproject.toml`
- py: `.github/workflows/ci.yml`
- py: `.github/workflows/dep-audit.yml`
- py: `.readthedocs.yaml`
- py: `lefthook.yml` — no feature: no docs-related hook entries found
- ts: `docs/docs.md`
- ts: `docs/reference/index.md`
- ts: `README.md`
- ts: `Justfile`
- ts: `package.json`
- ts: `scripts/check-links.mjs`
- ts: `.github/workflows/ci.yml`
- ts: `docs/maintainers-release.md` — no feature: release-process content, owned by the release-versioning area
- ts: `docs/port/TS_PORT_DECISIONS.md`
- ts: `docs/port/goal.md` — no feature: port-process orchestration contract, not part of the shipped docs system
- ts: `lefthook.yml` — no feature: no docs-check/docs-api hook wiring found (CI-only)
- ts: `.oxfmtrc.json` — no feature: markdown formatting scope is owned by the lint-format area
