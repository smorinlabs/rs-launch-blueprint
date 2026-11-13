//! Compensating control (R15): `press/press-source.toml` must agree with
//! Cargo's own view of the package. `template-press` 4.0.1 discovery reads
//! `pyproject.toml` only, so on a Rust target only `owner` and `repo_name`
//! (git origin) are cross-checked by the tool; this test restores the rest.
use std::process::Command;

fn source_identity() -> toml::Table {
    let path = concat!(env!("CARGO_MANIFEST_DIR"), "/press/press-source.toml");
    let text = std::fs::read_to_string(path).expect("read press/press-source.toml");
    let doc: toml::Table = text.parse().expect("press-source.toml is valid TOML");
    doc["identity"].as_table().expect("[identity] table").clone()
}

fn cargo_metadata() -> serde_json::Value {
    let cargo = std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_string());
    let out = Command::new(cargo)
        .args(["metadata", "--no-deps", "--format-version", "1", "--offline"])
        .current_dir(env!("CARGO_MANIFEST_DIR"))
        .output()
        .expect("run cargo metadata");
    assert!(out.status.success(), "cargo metadata failed: {}", String::from_utf8_lossy(&out.stderr));
    serde_json::from_slice(&out.stdout).expect("cargo metadata emits JSON")
}

#[test]
fn press_source_agrees_with_cargo_metadata() {
    let id = source_identity();
    let field = |k: &str| id[k].as_str().unwrap_or_else(|| panic!("identity.{k} is a string")).to_string();
    let meta = cargo_metadata();
    let manifest = concat!(env!("CARGO_MANIFEST_DIR"), "/Cargo.toml");
    let pkg = meta["packages"]
        .as_array()
        .expect("packages array")
        .iter()
        .find(|p| p["manifest_path"] == manifest)
        .expect("this package appears in cargo metadata");
    let targets = pkg["targets"].as_array().expect("targets array");
    let names_of = |kind: &str| -> Vec<String> {
        targets
            .iter()
            .filter(|t| t["kind"].as_array().unwrap().iter().any(|k| k == kind))
            .map(|t| t["name"].as_str().unwrap().to_string())
            .collect()
    };
    let libs = names_of("lib");
    let bins = names_of("bin");
    let authors: Vec<String> = pkg["authors"].as_array().unwrap().iter().map(|a| a.as_str().unwrap().to_string()).collect();

    let mut errors = Vec::new();
    if pkg["name"] != field("repo_name").as_str() {
        errors.push(format!("package name {} != repo_name {}", pkg["name"], field("repo_name")));
    }
    if !libs.contains(&field("package_name")) {
        errors.push(format!("lib targets {libs:?} do not include package_name {:?}", field("package_name")));
    }
    if !bins.contains(&field("app_name")) {
        errors.push(format!("bin targets {bins:?} do not include app_name {:?}", field("app_name")));
    }
    if !authors.iter().any(|a| a.contains(&field("email"))) {
        errors.push(format!("authors {authors:?} do not carry email {:?}", field("email")));
    }
    assert!(errors.is_empty(), "press-source.toml disagrees with cargo metadata:\n  {}", errors.join("\n  "));
}
