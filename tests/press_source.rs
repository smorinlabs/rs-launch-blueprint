//! Template Press source-config and drift-guard contract tests (`R15`).
//!
//! Ships to stamped child repositories: every assertion derives expected values
//! from `press/press-source.toml` and `cargo metadata` so the same test validates
//! both the blueprint and every derived project.

use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

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

#[test]
fn press_source_agrees_with_cargo_metadata() {
    let root = repo_root();
    let source_raw = read_text(&root, "press/press-source.toml");
    let source_doc: toml::Value =
        toml::from_str(&source_raw).expect("parse press/press-source.toml");
    let identity = source_doc
        .get("identity")
        .and_then(toml::Value::as_table)
        .expect("press/press-source.toml must declare [identity]");

    let req = |key: &str| -> String {
        identity
            .get(key)
            .and_then(toml::Value::as_str)
            .filter(|v| !v.trim().is_empty())
            .unwrap_or_else(|| panic!("press/press-source.toml [identity] missing `{key}`"))
            .to_owned()
    };

    let package_name = req("package_name");
    let repo_name = req("repo_name");
    let app_name = req("app_name");
    let author = req("author");
    let email = req("email");
    let owner = req("owner");
    let _display_name = req("display_name");

    let cargo = option_env!("CARGO").unwrap_or("cargo");
    let output = Command::new(cargo)
        .args([
            "metadata",
            "--no-deps",
            "--format-version",
            "1",
            "--offline",
        ])
        .current_dir(&root)
        .output()
        .expect("run cargo metadata");
    assert!(
        output.status.success(),
        "cargo metadata failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let meta: serde_json::Value =
        serde_json::from_slice(&output.stdout).expect("parse cargo metadata JSON");
    let packages = meta["packages"]
        .as_array()
        .expect("cargo metadata packages array");
    let root_pkg = packages
        .iter()
        .find(|pkg| pkg["name"].as_str() == Some(repo_name.as_str()))
        .unwrap_or_else(|| {
            let names: Vec<&str> = packages.iter().filter_map(|p| p["name"].as_str()).collect();
            panic!(
                "press-source.toml disagrees with cargo metadata:\n  \
                 no workspace package matches repo_name `{repo_name}` (found {names:?})"
            )
        });

    let targets = root_pkg["targets"]
        .as_array()
        .expect("root package targets array");

    let lib_targets: Vec<&str> = targets
        .iter()
        .filter(|t| {
            t["kind"]
                .as_array()
                .is_some_and(|kinds| kinds.iter().any(|k| k.as_str() == Some("lib")))
        })
        .filter_map(|t| t["name"].as_str())
        .collect();
    assert!(
        lib_targets.contains(&package_name.as_str()),
        "press-source.toml disagrees with cargo metadata:\n  \
         lib targets {lib_targets:?} do not include package_name `{package_name}`"
    );

    let cli_pkg_name = format!("{repo_name}-cli");
    let cli_pkg = packages
        .iter()
        .find(|pkg| pkg["name"].as_str() == Some(cli_pkg_name.as_str()))
        .unwrap_or_else(|| {
            let names: Vec<&str> = packages.iter().filter_map(|p| p["name"].as_str()).collect();
            panic!(
                "press-source.toml disagrees with cargo metadata:\n  \
                 no workspace package matches CLI crate `{cli_pkg_name}` (found {names:?})"
            )
        });
    let bin_targets: Vec<&str> = cli_pkg["targets"]
        .as_array()
        .expect("CLI package targets array")
        .iter()
        .filter(|t| {
            t["kind"]
                .as_array()
                .is_some_and(|kinds| kinds.iter().any(|k| k.as_str() == Some("bin")))
        })
        .filter_map(|t| t["name"].as_str())
        .collect();
    assert!(
        bin_targets.contains(&app_name.as_str()),
        "press-source.toml disagrees with cargo metadata:\n  \
         CLI bin targets {bin_targets:?} do not include app_name `{app_name}`"
    );

    let authors: Vec<&str> = root_pkg["authors"]
        .as_array()
        .expect("root package must declare authors matching press-source.toml (R15)")
        .iter()
        .filter_map(serde_json::Value::as_str)
        .collect();
    assert!(
        authors
            .iter()
            .any(|entry| entry.contains(&author) && entry.contains(&email)),
        "press-source.toml disagrees with cargo metadata:\n  \
         authors {authors:?} do not include `{author}` and `{email}`"
    );

    let repository = root_pkg["repository"]
        .as_str()
        .expect("root package must declare repository");
    let expected_suffix = format!("/{owner}/{repo_name}");
    assert!(
        repository.trim_end_matches('/').ends_with(&expected_suffix),
        "press-source.toml disagrees with cargo metadata:\n  \
         repository `{repository}` does not end with `{expected_suffix}`"
    );
}

#[test]
fn press_verify_workflow_ships_clean_and_requirements_are_hash_pinned() {
    let root = repo_root();

    // press/requirements.in and hash-pinned press/requirements.txt (R15).
    let req_in = read_text(&root, "press/requirements.in");
    assert!(
        req_in.contains("template-press=="),
        "press/requirements.in must pin an exact template-press version"
    );

    let req_txt = read_text(&root, "press/requirements.txt");
    assert!(
        req_txt.contains("template-press=="),
        "press/requirements.txt must pin template-press"
    );
    assert!(
        req_txt.contains("--hash=sha256:"),
        "press/requirements.txt must carry --hash=sha256: digests (uv pip compile --generate-hashes)"
    );

    // press-verify.yml carries NO source identity literals so it ships verbatim to children (R15 P3).
    let wf = read_text(&root, ".github/workflows/press-verify.yml");
    for required in [
        "permissions: {}",
        "runs-on: ubuntu-latest",
        "persist-credentials: false",
        "astral-sh/setup-uv@",
        "press/requirements.txt",
        "press verify",
    ] {
        assert!(
            wf.contains(required),
            ".github/workflows/press-verify.yml missing required R15/R08/R09/R20 clause `{required}`"
        );
    }

    let source_doc: toml::Value =
        toml::from_str(&read_text(&root, "press/press-source.toml")).expect("parse source config");
    let identity = source_doc["identity"].as_table().expect("[identity]");
    for field in [
        "package_name",
        "repo_name",
        "app_name",
        "owner",
        "email",
        "author",
        "display_name",
    ] {
        let val = identity[field].as_str().expect("identity string");
        assert!(
            !wf.contains(val),
            ".github/workflows/press-verify.yml must carry NO source identity literal (found `{field}` = `{val}`)"
        );
    }
}
