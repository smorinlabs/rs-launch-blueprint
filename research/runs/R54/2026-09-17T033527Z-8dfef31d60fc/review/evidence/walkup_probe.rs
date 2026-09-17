// R54 throwaway probe — the bounded project-tier walk-up.
// NOT template code. It exists to test one rule this decision states:
// stop at `.git` (directory OR file) always, and at a `Cargo.toml` ONLY when that
// manifest declares a top-level `[workspace]` table. Compiled with `rustc --edition 2024`
// into a $TMPDIR subdirectory that `check.sh` creates and deletes; nothing is written
// into the repository. See review/DECISION.md `## Empirical check` check P.
//
// The probe prints paths relative to the temporary tree root so its output is
// byte-stable across runs.

use std::path::{Path, PathBuf};

/// Boundary policy under test.
#[derive(Clone, Copy, PartialEq)]
enum Marker {
    /// `.git` always; `Cargo.toml` only when it declares `[workspace]`.
    WorkspaceQualified,
    /// The naive reading of the standard's example list: any `Cargo.toml` stops.
    AnyCargoToml,
}

fn declares_workspace(manifest: &Path) -> bool {
    // Approximation of "the document has a top-level `workspace` table".
    // P03 detects this with R52's `toml` parser, not by line matching; the probe
    // matches on the section header because it has no dependencies.
    match std::fs::read_to_string(manifest) {
        Ok(text) => text
            .lines()
            .any(|l| l.trim_start().starts_with("[workspace]") || l.trim_start().starts_with("[workspace.")),
        Err(_) => false,
    }
}

fn is_boundary(dir: &Path, marker: Marker) -> bool {
    // `.git` is a boundary whether it is a directory (normal clone) or a file
    // (a `git worktree` checkout or a submodule), so `exists()` is the right test.
    if dir.join(".git").exists() {
        return true;
    }
    let manifest = dir.join("Cargo.toml");
    if !manifest.exists() {
        return false;
    }
    match marker {
        Marker::AnyCargoToml => true,
        Marker::WorkspaceQualified => declares_workspace(&manifest),
    }
}

/// Return the nearest `<ancestor>/.rslbp/rslbp_config.toml`, searching from `cwd`
/// upward and stopping *inclusively* at the first ancestor carrying a boundary marker.
fn find_project_config(cwd: &Path, marker: Marker) -> Option<PathBuf> {
    for dir in cwd.ancestors() {
        let candidate = dir.join(".rslbp").join("rslbp_config.toml");
        if candidate.is_file() {
            return Some(candidate);
        }
        if is_boundary(dir, marker) {
            return None;
        }
    }
    None
}

fn rel(root: &Path, p: &Path) -> String {
    p.strip_prefix(root)
        .map(|r| r.to_string_lossy().into_owned())
        .unwrap_or_else(|_| "<outside-tree>".to_string())
}

fn mkfile(p: &Path, body: &str) {
    std::fs::create_dir_all(p.parent().expect("parent")).expect("create_dir_all");
    std::fs::write(p, body).expect("write");
}

fn case(
    failures: &mut u32,
    name: &str,
    root: &Path,
    cwd: &Path,
    marker: Marker,
    expected: Option<&str>,
) {
    let got = find_project_config(cwd, marker).map(|p| rel(root, &p));
    let want = expected.map(|s| s.to_string());
    let verdict = if got == want { "PASS" } else { "FAIL" };
    if got != want {
        *failures += 1;
    }
    println!(
        "{verdict} {name} cwd={} got={} want={}",
        rel(root, cwd),
        got.clone().unwrap_or_else(|| "None".into()),
        want.clone().unwrap_or_else(|| "None".into())
    );
}

fn main() {
    let root = PathBuf::from(std::env::args().nth(1).expect("usage: walkup_probe <tmp-root>"));
    let mut failures: u32 = 0;

    // Tree A — a Cargo workspace: the root manifest declares [workspace],
    // the member manifest does not. A .rslbp/ sits at the workspace root.
    let a = root.join("A");
    mkfile(&a.join("Cargo.toml"), "[workspace]\nmembers = [\"crates/foo\"]\n");
    mkfile(&a.join(".rslbp/rslbp_config.toml"), "# root project layer\n");
    mkfile(&a.join("crates/foo/Cargo.toml"), "[package]\nname = \"foo\"\n");
    std::fs::create_dir_all(a.join("crates/foo/src")).expect("mkdir src");

    case(
        &mut failures,
        "P1-workspace-qualified-finds-root",
        &root,
        &a.join("crates/foo/src"),
        Marker::WorkspaceQualified,
        Some("A/.rslbp/rslbp_config.toml"),
    );
    case(
        &mut failures,
        "P2-any-cargo-toml-loses-root",
        &root,
        &a.join("crates/foo/src"),
        Marker::AnyCargoToml,
        None,
    );
    case(
        &mut failures,
        "P3-workspace-root-inclusive",
        &root,
        &a,
        Marker::WorkspaceQualified,
        Some("A/.rslbp/rslbp_config.toml"),
    );

    // Tree B — `.git` as a directory at the repository root.
    let b = root.join("B");
    std::fs::create_dir_all(b.join(".git")).expect("mkdir .git");
    mkfile(&b.join(".rslbp/rslbp_config.toml"), "# repo project layer\n");
    std::fs::create_dir_all(b.join("a/b")).expect("mkdir a/b");
    case(
        &mut failures,
        "P4-git-dir-root-found",
        &root,
        &b.join("a/b"),
        Marker::WorkspaceQualified,
        Some("B/.rslbp/rslbp_config.toml"),
    );

    // Tree C — `.git` as a FILE (a `git worktree` checkout, the shape this
    // repository itself is checked out as).
    let c = root.join("C");
    mkfile(&c.join(".git"), "gitdir: /elsewhere/.git/worktrees/x\n");
    mkfile(&c.join(".rslbp/rslbp_config.toml"), "# worktree project layer\n");
    std::fs::create_dir_all(c.join("a/b")).expect("mkdir a/b");
    case(
        &mut failures,
        "P5-git-file-root-found",
        &root,
        &c.join("a/b"),
        Marker::WorkspaceQualified,
        Some("C/.rslbp/rslbp_config.toml"),
    );

    // Tree D — a boundary BELOW the config file: the walk must stop and not find it.
    let d = root.join("D");
    mkfile(&d.join(".rslbp/rslbp_config.toml"), "# must NOT be reached\n");
    std::fs::create_dir_all(d.join("a/.git")).expect("mkdir a/.git");
    std::fs::create_dir_all(d.join("a/b")).expect("mkdir a/b");
    case(
        &mut failures,
        "P6-boundary-below-blocks",
        &root,
        &d.join("a/b"),
        Marker::WorkspaceQualified,
        None,
    );

    // Tree E — two project files; only the nearest is returned (R5.1 rung 3 says
    // "nearest", singular — one project layer, not Cargo's merged ancestor chain).
    let e = root.join("E");
    std::fs::create_dir_all(e.join(".git")).expect("mkdir .git");
    mkfile(&e.join(".rslbp/rslbp_config.toml"), "# far\n");
    mkfile(&e.join("a/.rslbp/rslbp_config.toml"), "# near\n");
    std::fs::create_dir_all(e.join("a/b")).expect("mkdir a/b");
    case(
        &mut failures,
        "P7-nearest-only",
        &root,
        &e.join("a/b"),
        Marker::WorkspaceQualified,
        Some("E/a/.rslbp/rslbp_config.toml"),
    );

    // Tree F — no marker and no file: the walk reaches the filesystem root and
    // returns None rather than looping or panicking.
    let f = root.join("F/a/b");
    std::fs::create_dir_all(&f).expect("mkdir F/a/b");
    case(
        &mut failures,
        "P8-no-marker-no-file",
        &root,
        &f,
        Marker::WorkspaceQualified,
        None,
    );

    // Tree G — `[workspace.package]` alone also declares the workspace table.
    let g = root.join("G");
    mkfile(
        &g.join("Cargo.toml"),
        "[workspace.package]\nedition = \"2024\"\n",
    );
    mkfile(&g.join(".rslbp/rslbp_config.toml"), "# root\n");
    mkfile(&g.join("crates/bar/Cargo.toml"), "[package]\nname = \"bar\"\n");
    std::fs::create_dir_all(g.join("crates/bar/src")).expect("mkdir src");
    case(
        &mut failures,
        "P9-workspace-package-counts",
        &root,
        &g.join("crates/bar/src"),
        Marker::WorkspaceQualified,
        Some("G/.rslbp/rslbp_config.toml"),
    );

    println!("PROBE-FAILURES {failures}");
    if failures != 0 {
        std::process::exit(1);
    }
}
