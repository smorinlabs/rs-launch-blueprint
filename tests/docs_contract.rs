//! Documentation corpus, mdBook delivery (`R81`), link/rustdoc correctness gates (`R82`),
//! and CLI/Web example guide contract tests (`P13-TS01`).
//!
//! Ships to stamped child repositories; every identity-sensitive assertion derives expected
//! values from `press/press-source.toml` so both the blueprint and stamped children pass.

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

struct TempDir {
    path: PathBuf,
}

impl TempDir {
    fn new(prefix: &str) -> Self {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system clock")
            .as_nanos();
        let path = env::temp_dir().join(format!("{prefix}-{}-{nanos}", std::process::id()));
        fs::create_dir_all(&path).expect("create temp dir");
        Self { path }
    }

    fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.path);
    }
}

fn repo_root() -> PathBuf {
    if let Some(dir) = env::var_os("CARGO_MANIFEST_DIR") {
        let candidate = PathBuf::from(dir);
        if candidate.join("Cargo.toml").is_file() {
            return candidate;
        }
    }
    let compile_time = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    if compile_time.join("Cargo.toml").is_file() {
        return compile_time;
    }
    env::current_dir().expect("resolve workspace root from cwd")
}

fn read_text(root: &Path, rel: &str) -> String {
    let path = root.join(rel);
    fs::read_to_string(&path).unwrap_or_else(|err| panic!("read {}: {err}", path.display()))
}

fn find_on_path(bin: &str) -> Option<PathBuf> {
    let path_var = env::var_os("PATH")?;
    for dir in env::split_paths(&path_var) {
        let candidate = dir.join(bin);
        if candidate.is_file() {
            return Some(candidate);
        }
    }
    None
}

fn extract_summary_targets(summary: &str) -> Vec<String> {
    let mut targets = Vec::new();
    for line in summary.lines() {
        let mut rest = line;
        while let Some(open) = rest.find("](") {
            let after = &rest[open + 2..];
            if let Some(close) = after.find(')') {
                let target = after[..close].trim();
                if target.ends_with(".md") && !target.starts_with("http") {
                    targets.push(target.to_owned());
                }
                rest = &after[close + 1..];
            } else {
                break;
            }
        }
    }
    targets
}

#[test]
fn book_toml_summary_and_dialect_satisfy_r81() {
    let root = repo_root();

    // R81 `theme/` prohibition: never commit MPL-2.0 copied theme files.
    assert!(
        !root.join("theme").exists() && !root.join("docs/theme").exists(),
        "R81 forbids committing a `theme/` directory (copies MPL-2.0 files into MIT OR Apache-2.0 source)"
    );

    // R81 F345: no `docs/index.md`; `docs/README.md` is the book prefix chapter -> index.html.
    assert!(
        !root.join("docs/index.md").exists(),
        "R81 F345 forbids docs/index.md; use docs/README.md as the prefix chapter"
    );

    let source_doc: toml::Value =
        toml::from_str(&read_text(&root, "press/press-source.toml")).expect("parse source config");
    let identity = source_doc["identity"].as_table().expect("[identity]");
    let owner = identity["owner"].as_str().expect("owner");
    let repo_name = identity["repo_name"].as_str().expect("repo_name");

    // Parse and validate book.toml (R81).
    let book_raw = read_text(&root, "book.toml");
    let book: toml::Value = toml::from_str(&book_raw).expect("parse book.toml");
    assert_eq!(
        book["book"]["src"].as_str(),
        Some("docs"),
        "book.toml must set [book] src = \"docs\""
    );
    assert_eq!(
        book["build"]["create-missing"].as_bool(),
        Some(false),
        "book.toml must set [build] create-missing = false so SUMMARY.md drift fails the build"
    );
    assert_eq!(
        book["rust"]["edition"].as_str(),
        Some("2024"),
        "book.toml must set [rust] edition = \"2024\" (mdBook defaults to 2015)"
    );
    assert_eq!(
        book["output"]["html"]["definition-lists"].as_bool(),
        Some(false),
        "book.toml must set [output.html] definition-lists = false per R81 F343"
    );
    let expected_repo_url = format!("https://github.com/{owner}/{repo_name}");
    assert_eq!(
        book["output"]["html"]["git-repository-url"].as_str(),
        Some(expected_repo_url.as_str()),
        "book.toml git-repository-url must match press/press-source.toml"
    );

    // Verify docs/SUMMARY.md exists, lists docs/README.md, and every target exists + follows R81 dialect.
    let summary = read_text(&root, "docs/SUMMARY.md");
    assert!(
        summary.lines().next() == Some("# Summary"),
        "docs/SUMMARY.md must start with `# Summary`"
    );
    let targets = extract_summary_targets(&summary);
    assert!(
        targets.iter().any(|t| t == "README.md"),
        "docs/SUMMARY.md must include README.md as prefix chapter (R81 F345)"
    );

    // F342: all six Diátaxis category overviews plus F347 authoring guide and F354-F356 records.
    for required_page in [
        "README.md",
        "docs.md",
        "about/README.md",
        "about/architecture.md",
        "about/design-decisions.md",
        "tutorials/README.md",
        "tutorials/getting-started.md",
        "tasks/README.md",
        "tasks/development-workflow.md",
        "tasks/config-secrets-logging.md",
        "tasks/testing-and-coverage.md",
        "tasks/ci-cd-and-security.md",
        "tasks/troubleshooting.md",
        "reference/README.md",
        "reference/cli-reference.md",
        "reference/web-api-reference.md",
        "reference/project-structure.md",
        "tools/README.md",
        "tools/blaze.md",
        "tools/toolchain-and-quality.md",
        "contributing/README.md",
        "contributing/contributing-guide.md",
        "adr/README.md",
        "design/README.md",
        "research/README.md",
    ] {
        assert!(
            targets.iter().any(|t| t == required_page),
            "docs/SUMMARY.md missing required page `{required_page}`"
        );
    }

    // Check every referenced file exists and avoids R81 F343 forbidden syntax.
    for rel in &targets {
        let full = root.join("docs").join(rel);
        assert!(
            full.is_file(),
            "docs/SUMMARY.md links to missing file `docs/{rel}`"
        );
        let content = fs::read_to_string(&full).expect("read doc page");
        assert!(
            !content.trim().is_empty(),
            "doc page `docs/{rel}` must be non-empty"
        );

        let mut in_fence = false;
        for (idx, line) in content.lines().enumerate() {
            let trimmed = line.trim_start();
            if trimmed.starts_with("```") {
                if !in_fence && trimmed.starts_with("```mermaid") {
                    panic!(
                        "docs/{rel}:{} uses forbidden `mermaid` fence (R81 F343)",
                        idx + 1
                    );
                }
                in_fence = !in_fence;
                continue;
            }
            if !in_fence {
                assert!(
                    !line.contains("{{#include") && !line.contains("{{#playground"),
                    "docs/{rel}:{} uses forbidden mdBook preprocessor directive (R81 F343)",
                    idx + 1
                );
                assert!(
                    !line.contains("{toctree}") && !trimmed.starts_with(":::{"),
                    "docs/{rel}:{} uses forbidden MyST directive (R81 F343)",
                    idx + 1
                );
                if trimmed.starts_with('#') {
                    assert!(
                        !line.contains("{ #"),
                        "docs/{rel}:{} uses forbidden heading attribute `{{ #id }}` (R81 F343)",
                        idx + 1
                    );
                }
            }
        }
    }

    // F344: per-section README.md files carry prose overviews and do NOT re-list sibling `.md` links.
    for section in [
        "about",
        "tutorials",
        "tasks",
        "reference",
        "tools",
        "contributing",
    ] {
        let text = read_text(&root, &format!("docs/{section}/README.md"));
        let sibling_links: Vec<&str> = text
            .lines()
            .filter(|l| {
                let t = l.trim_start();
                (t.starts_with("- [") || t.starts_with("* [")) && t.contains(".md)")
            })
            .collect();
        assert!(
            sibling_links.is_empty(),
            "docs/{section}/README.md must not re-list category pages (single nav source is docs/SUMMARY.md per R81 F344): {sibling_links:?}"
        );
    }

    // F354: ADR template file exists.
    assert!(
        root.join("docs/adr/template.md").is_file(),
        "docs/adr/template.md must exist (F354)"
    );
}

#[test]
fn lychee_config_gitignore_and_workflows_satisfy_r81_and_r82() {
    let root = repo_root();

    // lychee.toml exists, parses cleanly, excludes target/ and book/.
    let lychee_raw = read_text(&root, "lychee.toml");
    let lychee_doc: toml::Value = toml::from_str(&lychee_raw).expect("parse lychee.toml");
    let excluded: Vec<&str> = lychee_doc["exclude_path"]
        .as_array()
        .expect("lychee.toml must declare exclude_path array")
        .iter()
        .filter_map(toml::Value::as_str)
        .collect();
    for path in ["target", "book", "press/stubs"] {
        assert!(
            excluded.contains(&path),
            "lychee.toml exclude_path missing `{path}`: {excluded:?}"
        );
    }

    // .gitignore ignores .lycheecache (R82) and /book/ (R81).
    let gitignore = read_text(&root, ".gitignore");
    assert!(
        gitignore.lines().any(|l| l.trim() == ".lycheecache"),
        ".gitignore must ignore .lycheecache (R82)"
    );
    assert!(
        gitignore
            .lines()
            .any(|l| matches!(l.trim(), "/book/" | "book/")),
        ".gitignore must ignore /book/ mdBook build output (R81)"
    );

    // .github/workflows/docs.yml (R81, R08, R09, R20).
    let docs_wf = read_text(&root, ".github/workflows/docs.yml");
    for required in [
        "permissions: {}",
        "runs-on: ubuntu-latest",
        "persist-credentials: false",
        "3f28de05dafca9d0f2eab99c662116b0e37b89b1d96a08f8f430b9eeae958cd7",
        "mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz",
        "mdbook build",
        "actions/configure-pages@v6",
        "actions/upload-pages-artifact@v5",
        "actions/deploy-pages@v5",
        "pages: write",
        "id-token: write",
        "name: github-pages",
    ] {
        assert!(
            docs_wf.contains(required),
            ".github/workflows/docs.yml missing required R81/R08/R09 clause `{required}`"
        );
    }

    // .github/workflows/ci.yml wires R82 offline lychee in hygiene and --document-private-items in check.
    let ci_wf = read_text(&root, ".github/workflows/ci.yml");
    for required in [
        "lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0",
        "lycheeVersion: v0.24.2",
        "--offline",
        "--root-dir \"$(pwd)\"",
        "RUSTDOCFLAGS: -D warnings",
        "cargo doc --locked --workspace --no-deps --all-features --document-private-items",
    ] {
        assert!(
            ci_wf.contains(required),
            ".github/workflows/ci.yml missing required R82 clause `{required}`"
        );
    }

    // .github/workflows/canary.yml hosts R82 scheduled external link check (F350).
    let canary_wf = read_text(&root, ".github/workflows/canary.yml");
    for required in [
        "docs-external-links:",
        "lycheeverse/lychee-action@e7477775783ea5526144ba13e8db5eec57747ce8 # v2.9.0",
        "lycheeVersion: v0.24.2",
        "--cache --max-cache-age 1d",
        "--max-retries 3",
        "--timeout 20",
        "actions/cache/restore@v6",
        "actions/cache/save@v6",
    ] {
        assert!(
            canary_wf.contains(required),
            ".github/workflows/canary.yml missing required R82 F350 clause `{required}`"
        );
    }
}

#[test]
fn justfile_provides_r81_and_r82_docs_recipes_and_example_guides_exist() {
    let root = repo_root();

    let output = Command::new("just")
        .arg("--summary")
        .current_dir(&root)
        .output()
        .expect("just --summary must execute");
    assert!(
        output.status.success(),
        "just --summary failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let summary = String::from_utf8_lossy(&output.stdout);
    let recipes: Vec<&str> = summary.split_whitespace().collect();
    for recipe in [
        "docs-build",
        "docs-dev",
        "docs-init",
        "docs-clean",
        "docs-check",
        "docs-api",
    ] {
        assert!(
            recipes.contains(&recipe),
            "Justfile missing required R81/R82 recipe `{recipe}`; found: {recipes:?}"
        );
    }

    let justfile = read_text(&root, "Justfile");
    for required in [
        "mdbook build",
        "mdbook serve --open",
        "mdbook init",
        "mdbook clean",
        "lychee --offline --no-progress --root-dir \"$(pwd)\" .",
        "RUSTDOCFLAGS=\"-D warnings\" cargo doc --locked --workspace --no-deps --all-features --document-private-items",
    ] {
        assert!(
            justfile.contains(required),
            "Justfile missing required R81/R82 command `{required}`"
        );
    }

    // Top-level example guides exist and cover key CLI & Web surfaces.
    let cli_guide = read_text(&root, "EXAMPLECLI.md");
    for required in [
        "project list",
        "config init",
        "diagnostics",
        "completion",
        "RSLB000",
        "--token-file",
        "--output-file",
    ] {
        assert!(
            cli_guide.contains(required),
            "EXAMPLECLI.md missing required CLI walkthrough section/token `{required}`"
        );
    }

    let web_guide = read_text(&root, "EXAMPLEWEB.md");
    for required in [
        "/healthz",
        "/readyz",
        "/metrics",
        "/v1/projects",
        "application/problem+json",
        "Idempotency-Key",
        "just serve",
        "just export-openapi",
    ] {
        assert!(
            web_guide.contains(required),
            "EXAMPLEWEB.md missing required web walkthrough section/token `{required}`"
        );
    }
}

#[test]
fn mdbook_and_lychee_execute_cleanly_when_installed() {
    let root = repo_root();

    if let Some(mdbook) = find_on_path("mdbook") {
        let scratch = TempDir::new("rslbp-mdbook-check");
        let dest = scratch.path().join("book");
        let out = Command::new(&mdbook)
            .args(["build", "--dest-dir", dest.to_str().unwrap()])
            .current_dir(&root)
            .output()
            .expect("run mdbook build");
        let stderr = String::from_utf8_lossy(&out.stderr);
        assert!(
            out.status.success(),
            "mdbook build failed:\nstdout={}\nstderr={stderr}",
            String::from_utf8_lossy(&out.stdout),
        );
        assert!(
            !stderr.contains("ERROR"),
            "mdbook build emitted ERROR diagnostics on stderr:\n{stderr}"
        );
        assert!(
            dest.join("index.html").is_file(),
            "mdbook build must generate index.html from docs/README.md (R81 F345)"
        );
    }

    if let Some(lychee) = find_on_path("lychee") {
        let out = Command::new(&lychee)
            .args([
                "--offline",
                "--no-progress",
                "--root-dir",
                root.to_str().unwrap(),
                ".",
            ])
            .current_dir(&root)
            .output()
            .expect("run lychee --offline");
        assert!(
            out.status.success(),
            "lychee --offline failed:\nstdout={}\nstderr={}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        );
    }
}
