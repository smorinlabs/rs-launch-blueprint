//! F133-style meta-test: every release-managed copy of the package version
//! must equal `[package] version` in `Cargo.toml`, and the release config must
//! select release-please's native Rust strategy without a duplicate
//! `Cargo.lock` `extra-files` writer.

use std::fs;
use std::path::PathBuf;

fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

fn read(name: &str) -> String {
    fs::read_to_string(root().join(name)).unwrap_or_else(|e| panic!("{name}: {e}"))
}

fn manifest_version() -> String {
    let t: toml::Value = toml::from_str(&read("Cargo.toml")).unwrap();
    t["package"]["version"].as_str().unwrap().to_string()
}

#[test]
fn release_please_manifest_matches_cargo_toml() {
    let j: serde_json::Value = serde_json::from_str(&read(".release-please-manifest.json")).unwrap();
    assert_eq!(j["."].as_str().unwrap(), manifest_version());
}

#[test]
fn cargo_lock_entry_matches_cargo_toml() {
    let lock: toml::Value = toml::from_str(&read("Cargo.lock")).unwrap();
    let mine: Vec<&toml::Value> = lock["package"]
        .as_array()
        .unwrap()
        .iter()
        .filter(|p| p["name"].as_str() == Some("demo-single"))
        .collect();
    assert_eq!(mine.len(), 1, "exactly one [[package]] entry for this crate");
    assert_eq!(mine[0]["version"].as_str().unwrap(), manifest_version());
}

#[test]
fn release_config_uses_native_rust_strategy_without_lock_extra_file() {
    let cfg: serde_json::Value = serde_json::from_str(&read("release-please-config.json")).unwrap();
    let pkg = &cfg["packages"]["."];
    assert_eq!(pkg["release-type"], "rust");
    let extra = pkg["extra-files"].as_array().cloned().unwrap_or_default();
    assert!(
        extra.iter().all(|e| e != "Cargo.lock" && e["path"] != "Cargo.lock"),
        "Cargo.lock must not be a second extra-files writer: {extra:?}"
    );
}
