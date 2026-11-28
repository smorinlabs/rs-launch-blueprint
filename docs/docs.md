# Documentation Authoring Guide

This repository maintains a single CommonMark/GFM documentation corpus under
`docs/` that renders directly on GitHub **and** builds into a static site with
`mdbook 0.5.4` (`R81`, `F347`).

## Single-Source Navigation (`F344`)

`docs/SUMMARY.md` is the **sole** navigation index for the corpus:

- Every chapter and page under `docs/` must be linked in `docs/SUMMARY.md`
  using standard relative `.md` paths.
- `book.toml` enforces `[build] create-missing = false`, so any typo or missing
  file fails `mdbook build` immediately.
- Category overview pages (`docs/<category>/README.md`) hold short narrative
  prose introducing the category and **do not** duplicate bullet lists of their
  pages.
- Never create `docs/index.md`; `docs/README.md` serves as both the GitHub
  directory index and mdBook's prefix chapter (`index.html`).

## Allowed Markdown Dialect (`F343`)

Write in **`GFM ∩ mdBook-0.5-default`** so the exact same bytes render cleanly
on GitHub and in the generated site:

- **Allowed:** standard CommonMark, GFM tables, strikethrough, task lists,
  footnotes, and GitHub alert blockquotes (`> [!NOTE]`, `> [!TIP]`,
  `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`).
- **Forbidden:**
  - Heading attribute blocks (`# Heading { #custom-id }`)
  - Definition lists (`[output.html] definition-lists = false` in `book.toml`)
  - Fenced Mermaid blocks (GitHub renders them, stock mdBook 0.5 does not)
  - mdBook preprocessor link directives (`include`, `playground`, and `hidelines`
    markers)
  - MyST / Sphinx directives (`toctree` and colon-fence admonitions)
  - Code-block attributes beyond the language tag (use plain ` ```rust `)

## Adding a New Page

1. Create the `.md` file in the appropriate category directory under `docs/`
   (for example, `docs/tasks/my-new-guide.md`).
2. Write the page using relative `.md` links for every cross-reference (mdBook
   rewrites `.md` to `.html` in the built site while GitHub resolves `.md`
   directly).
3. Register the page in `docs/SUMMARY.md`.
4. Never run `mdbook init --theme` and never commit a `theme/` directory: doing
   so copies mdBook's MPL-2.0 theme assets into this `MIT OR Apache-2.0`
   repository (`R81`). Use `[output.html] additional-css` if custom styling is
   ever needed.

## Verification Gates (`R82`)

Before opening a pull request, verify formatting, links, book build, and API
rustdoc:

```bash
just format-files  # Format Markdown, TOML, YAML, and JSON with dprint
just docs-build    # Build mdBook site into book/ (create-missing = false)
just docs-check    # Offline relative link check via lychee 0.24.2
just docs-api      # Workspace rustdoc across --all-features with -D warnings
```

- **Local preview:** run `just docs-dev` (`mdbook serve --open`) to preview live
  edits in your browser.
- **Prerequisites:** `just setup` installs pinned `mdbook 0.5.4` and
  `lychee 0.24.2`. To install `lychee` standalone for local `just docs-check`,
  run `just install-tool ubi:lycheeverse/lychee@lychee-v0.24.2`.
- **CI enforcement:** `ci.yml` runs offline `lychee` on every PR in `hygiene`
  and strict `cargo doc --document-private-items` in `check`. `docs.yml` builds
  the mdBook site on every PR and deploys to GitHub Pages on `main` once Pages
  is enabled. `canary.yml` runs the cached network-mode external link check
  (`docs-external-links`) on its weekly schedule so external network flakes
  never block pull requests.

## Future Upgrade Path (`F358`)

`mdbook 0.5.4` covers single-version narrative documentation and client-side
full-text search without adding a Node or Python runtime. If a downstream
project eventually requires **versioned documentation**, **multi-language
localization (i18n)**, or **rich interactive components**, migrating off mdBook
is a generator swap over this unchanged CommonMark/GFM corpus (removing
`book.toml`, `.github/workflows/docs.yml`, and the `docs-*` recipes takes one
commit without editing prose pages). Treat that threshold as a trigger for a
fresh generator evaluation rather than preselecting a replacement in advance.
