//! Release automation, binary distribution, packed-artifact guard, and GHCR container
//! publishing meta-tests (`P11-TS01`).
//!
//! Validates:
//! - R22/R23/R25/F133: lockstep literal versions across all 4 workspace manifests, literal
//!   `[workspace] members` paths (no glob), `.release-please-manifest.json` consistency,
//!   and `release-please-config.json` native `release-type: "rust"` without a duplicate
//!   `Cargo.lock` `extra-files` entry.
//! - R24: total ordered 11-entry `changelog-sections` array matching `committed.toml`'s
//!   type enum by set equality and release-please's exact `DEFAULT_HEADINGS`.
//! - R26: all 4 first-party packed `.crate` content guards (`scripts/check-packed-artifacts.sh`
//!   and checked-in byte-sorted `ci/expected-packed-files/*.txt` +
//!   `ci/expected-packaged-targets/*.json`), including negative fault-injection controls.
//! - R68: `[profile.release]` (`lto = "fat"`, `codegen-units = 1`, four deliberate silences),
//!   `[profile.dist]` (`inherits = "release"` only), no `[package.metadata.binstall]`,
//!   `dist-workspace.toml` follower-mode configuration (`cargo-dist 0.33.0`), and hardened
//!   `.github/workflows/release.yml`.
//! - R04/F074/F075: `.github/workflows/publish.yml` tag ancestry, version match, R26 guards,
//!   `cargo-semver-checks`, and credential/environment-gated crates.io publish.
//! - Owner review-gate 1a-A OVERRIDE of R51 (2026-11-27): `.github/workflows/publish-container.yml`
//!   and `scripts/publish_container.py` digest/tag wiring, non-regressing `latest` promotion,
//!   and anonymous-access verification.
//! - `docs/RELEASE.md`: complete operator release guide.

use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
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
    env::current_dir().expect("resolve repo root")
}

fn read_repo_file(root: &Path, rel: &str) -> String {
    let path = root.join(rel);
    fs::read_to_string(&path).unwrap_or_else(|err| panic!("read {}: {err}", path.display()))
}

fn copy_dir_filtered(src: &Path, dst: &Path) {
    fs::create_dir_all(dst).expect("create dst dir");
    for entry in fs::read_dir(src).expect("read src dir") {
        let entry = entry.expect("dir entry");
        let name = entry.file_name();
        if name == ".git" || name == "target" || name == "research" || name == "clients" {
            continue;
        }
        let from = entry.path();
        let to = dst.join(&name);
        if from.is_dir() {
            copy_dir_filtered(&from, &to);
        } else {
            fs::copy(&from, &to).expect("copy file");
        }
    }
}

#[test]
fn release_please_config_matches_r23_r24_r25_r68() {
    let root = repo_root();
    let raw = read_repo_file(&root, "release-please-config.json");
    let cfg: serde_json::Value =
        serde_json::from_str(&raw).expect("parse release-please-config.json");

    assert_eq!(
        cfg["$schema"].as_str(),
        Some(
            "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json"
        ),
        "release-please-config.json must declare canonical $schema"
    );

    let title_pattern = cfg["pull-request-title-pattern"]
        .as_str()
        .expect("pull-request-title-pattern must be set");
    assert!(
        title_pattern.starts_with("chore(release): ") && title_pattern.contains("${version}"),
        "PR title pattern must be a Conventional Commit referencing ${{version}}, got `{title_pattern}`"
    );
    let sample_title = title_pattern.replace("${version}", "10.20.30");
    assert!(
        sample_title.len() <= 50,
        "rendered release PR title `{sample_title}` exceeds R38 50-char header limit"
    );

    let pkg = &cfg["packages"]["."];
    assert!(pkg.is_object(), "packages[\".\"] must be an object");

    // R23: native Rust strategy, no Cargo.lock extra-files writer.
    assert_eq!(
        pkg["release-type"].as_str(),
        Some("rust"),
        "R23 requires native release-type: \"rust\""
    );
    assert_eq!(
        pkg["package-name"].as_str(),
        Some("rs-launch-blueprint"),
        "package-name must match root crate"
    );
    assert_eq!(
        pkg["include-component-in-tag"].as_bool(),
        Some(false),
        "single-version workspace tags must be vX.Y.Z without component prefix"
    );
    assert_eq!(
        pkg["include-v-in-tag"].as_bool(),
        Some(true),
        "tags must carry leading v prefix"
    );
    if let Some(extra) = pkg.get("extra-files").and_then(serde_json::Value::as_array) {
        for entry in extra {
            let path = entry.get("path").and_then(serde_json::Value::as_str);
            assert_ne!(
                path,
                Some("Cargo.lock"),
                "R23 forbids extra-files Cargo.lock writer alongside release-type: rust"
            );
        }
    }

    // R25: full pre-1.0 semver dampening.
    assert_eq!(
        pkg["bump-minor-pre-major"].as_bool(),
        Some(true),
        "R25 requires bump-minor-pre-major: true"
    );
    assert_eq!(
        pkg["bump-patch-for-minor-pre-major"].as_bool(),
        Some(true),
        "R25 requires bump-patch-for-minor-pre-major: true"
    );

    // R68: follower mode hand-off to cargo-dist (draft release + immediate tag creation).
    assert_eq!(
        pkg["draft"].as_bool(),
        Some(true),
        "R68 requires draft: true so cargo-dist uploads binaries and undrafts"
    );
    assert_eq!(
        pkg["force-tag-creation"].as_bool(),
        Some(true),
        "R68 requires force-tag-creation: true so the tag triggers cargo-dist and publish.yml"
    );

    // R24: total ordered 11-entry changelog-sections array.
    let sections = pkg["changelog-sections"]
        .as_array()
        .expect("changelog-sections array must exist");
    let expected: [(&str, &str, bool); 11] = [
        ("feat", "Features", false),
        ("fix", "Bug Fixes", false),
        ("perf", "Performance Improvements", false),
        ("revert", "Reverts", false),
        ("docs", "Documentation", false),
        ("refactor", "Code Refactoring", true),
        ("test", "Tests", true),
        ("build", "Build System", true),
        ("ci", "Continuous Integration", true),
        ("style", "Styles", true),
        ("chore", "Miscellaneous Chores", true),
    ];
    assert_eq!(
        sections.len(),
        expected.len(),
        "R24 requires exactly 11 changelog-sections entries"
    );

    let mut config_types = BTreeSet::new();
    for (idx, ((exp_type, exp_section, exp_hidden), actual)) in
        expected.iter().zip(sections.iter()).enumerate()
    {
        let act_type = actual["type"].as_str().expect("section type string");
        let act_section = actual["section"].as_str().expect("section title string");
        let act_hidden = actual
            .get("hidden")
            .and_then(serde_json::Value::as_bool)
            .unwrap_or(false);
        assert!(
            actual.get("scope").is_none(),
            "R24 rejects scope-routed changelog entries (index {idx})"
        );
        assert_eq!(
            (act_type, act_section, act_hidden),
            (*exp_type, *exp_section, *exp_hidden),
            "R24 changelog-sections[{idx}] mismatch"
        );
        config_types.insert(act_type.to_owned());
    }

    // R24 criterion A5: exact set equality with committed.toml's allowed_types enum.
    let committed_raw = read_repo_file(&root, "committed.toml");
    let committed: toml::Value = toml::from_str(&committed_raw).expect("parse committed.toml");
    let committed_types: BTreeSet<String> = committed["allowed_types"]
        .as_array()
        .expect("committed.toml allowed_types")
        .iter()
        .map(|v| v.as_str().expect("type string").to_owned())
        .collect();
    assert_eq!(
        config_types, committed_types,
        "R24 A5: changelog-sections types must equal committed.toml allowed_types by set equality"
    );
}

#[test]
fn workspace_manifests_and_release_manifest_versions_stay_consistent_f133_r22_r23_r25() {
    let root = repo_root();
    let expected_version = rs_launch_blueprint::VERSION;
    assert_eq!(expected_version, env!("CARGO_PKG_VERSION"));

    // R23 S6a/S6c: root workspace members must be literal paths (release-please Rust strategy
    // does not expand member globs like `crates/*`).
    let root_manifest: toml::Value =
        toml::from_str(&read_repo_file(&root, "Cargo.toml")).expect("parse root Cargo.toml");
    let mut members: Vec<&str> = root_manifest["workspace"]["members"]
        .as_array()
        .expect("workspace.members array")
        .iter()
        .map(|v| v.as_str().expect("member path string"))
        .collect();
    members.sort_unstable();
    assert_eq!(
        members,
        vec!["crates/cli", "crates/core", "crates/web"],
        "R23 requires literal [workspace] members paths (no glob) so release-please updates all members"
    );
    assert!(
        root_manifest["workspace"]["package"]
            .get("version")
            .is_none(),
        "R23 S7c: [workspace.package] must omit version because release-please rejects version.workspace = true"
    );

    // R23 S7c: every workspace manifest declares a literal string `[package] version`
    // matching `rs_launch_blueprint::VERSION`, and every intra-workspace path dep matches it.
    let workspace_pkgs = [
        "rs-launch-blueprint",
        "rs-launch-blueprint-core",
        "rs-launch-blueprint-cli",
        "rs-launch-blueprint-web",
    ];
    for rel in [
        "Cargo.toml",
        "crates/core/Cargo.toml",
        "crates/cli/Cargo.toml",
        "crates/web/Cargo.toml",
    ] {
        let doc: toml::Value =
            toml::from_str(&read_repo_file(&root, rel)).expect("parse workspace manifest");
        let ver = doc["package"]["version"]
            .as_str()
            .unwrap_or_else(|| panic!("{rel} must declare literal string [package] version (R23)"));
        assert_eq!(
            ver, expected_version,
            "{rel} [package] version drifted from rs_launch_blueprint::VERSION"
        );
        if let Some(deps) = doc.get("dependencies").and_then(toml::Value::as_table) {
            for dep_name in workspace_pkgs {
                if let Some(dep_val) = deps.get(dep_name) {
                    let dep_table = dep_val
                        .as_table()
                        .unwrap_or_else(|| panic!("{rel} dep {dep_name} must be a table"));
                    assert!(
                        dep_table.contains_key("path"),
                        "{rel} intra-workspace dep {dep_name} must specify path"
                    );
                    assert_eq!(
                        dep_table.get("version").and_then(toml::Value::as_str),
                        Some(expected_version),
                        "{rel} intra-workspace dep {dep_name} version drifted"
                    );
                }
            }
        }
    }

    // R25 + F133: `.release-please-manifest.json` must exist as a JSON object; empty `{}`
    // pre-first-release requires version `0.1.0`, and any populated `"."` entry must match
    // `Cargo.toml`.
    let rp_manifest_raw = read_repo_file(&root, ".release-please-manifest.json");
    let rp_manifest: serde_json::Value =
        serde_json::from_str(&rp_manifest_raw).expect("parse .release-please-manifest.json");
    let obj = rp_manifest
        .as_object()
        .expect(".release-please-manifest.json must be a JSON object");
    if obj.is_empty() {
        assert_eq!(
            expected_version, "0.1.0",
            "R25 empty .release-please-manifest.json is only valid before the initial 0.1.0 release"
        );
    } else {
        assert_eq!(
            obj.get(".").and_then(serde_json::Value::as_str),
            Some(expected_version),
            "F133: .release-please-manifest.json[\".\"] drifted from Cargo.toml version"
        );
    }
}

#[test]
fn release_profile_and_dist_workspace_match_r68() {
    let root = repo_root();
    let root_manifest: toml::Value =
        toml::from_str(&read_repo_file(&root, "Cargo.toml")).expect("parse root Cargo.toml");

    // R68 Subject B: exactly two keys written in [profile.release], four deliberate silences.
    let release_profile = root_manifest
        .get("profile")
        .and_then(|p| p.get("release"))
        .and_then(toml::Value::as_table)
        .expect("root Cargo.toml must declare [profile.release] (R68)");
    assert_eq!(
        release_profile.get("lto").and_then(toml::Value::as_str),
        Some("fat"),
        "R68 requires [profile.release] lto = \"fat\""
    );
    assert_eq!(
        release_profile
            .get("codegen-units")
            .and_then(toml::Value::as_integer),
        Some(1),
        "R68 requires [profile.release] codegen-units = 1"
    );
    for silent_key in ["opt-level", "strip", "panic", "debug"] {
        assert!(
            !release_profile.contains_key(silent_key),
            "R68 leaves [profile.release].{silent_key} unset at Cargo default"
        );
    }
    assert_eq!(
        release_profile.len(),
        2,
        "R68 [profile.release] must declare exactly two keys (lto, codegen-units)"
    );

    // R68 AC6: [profile.dist] inherits release with NO other keys (no lto = "thin" override).
    let dist_profile = root_manifest
        .get("profile")
        .and_then(|p| p.get("dist"))
        .and_then(toml::Value::as_table)
        .expect("root Cargo.toml must declare [profile.dist] (R68)");
    assert_eq!(
        dist_profile.get("inherits").and_then(toml::Value::as_str),
        Some("release"),
        "R68 AC6: [profile.dist] must inherit \"release\""
    );
    assert_eq!(
        dist_profile.len(),
        1,
        "R68 AC6: [profile.dist] must declare only `inherits = \"release\"` (no lto override)"
    );

    // R68: no [package.metadata.binstall] block (binstall defaults match crate/bin names).
    let binstall = root_manifest
        .get("package")
        .and_then(|p| p.get("metadata"))
        .and_then(|m| m.get("binstall"));
    assert!(
        binstall.is_none(),
        "R68 deliberately omits [package.metadata.binstall]"
    );

    // R68 Subject A: dist-workspace.toml follower-mode configuration.
    let dist_cfg: toml::Value = toml::from_str(&read_repo_file(&root, "dist-workspace.toml"))
        .expect("parse dist-workspace.toml");
    let dist = dist_cfg
        .get("dist")
        .and_then(toml::Value::as_table)
        .expect("dist-workspace.toml must declare [dist]");
    assert_eq!(
        dist.get("cargo-dist-version").and_then(toml::Value::as_str),
        Some("0.33.0"),
        "R68 pins cargo-dist-version = \"0.33.0\""
    );
    assert_eq!(
        dist.get("ci").and_then(toml::Value::as_str),
        Some("github"),
        "R68 sets ci = \"github\""
    );
    assert_eq!(
        dist.get("create-release").and_then(toml::Value::as_bool),
        Some(false),
        "R68 follower mode requires create-release = false"
    );
    assert_eq!(
        dist.get("install-updater").and_then(toml::Value::as_bool),
        Some(false),
        "R68 disables standalone updater binary (install-updater = false)"
    );

    let installers: Vec<&str> = dist
        .get("installers")
        .and_then(toml::Value::as_array)
        .expect("dist.installers")
        .iter()
        .map(|v| v.as_str().expect("installer string"))
        .collect();
    assert_eq!(
        installers,
        vec!["shell"],
        "R68 sets installers = [\"shell\"]"
    );

    let targets: Vec<&str> = dist
        .get("targets")
        .and_then(toml::Value::as_array)
        .expect("dist.targets")
        .iter()
        .map(|v| v.as_str().expect("target string"))
        .collect();
    assert_eq!(
        targets,
        vec![
            "x86_64-unknown-linux-gnu",
            "x86_64-apple-darwin",
            "aarch64-apple-darwin",
        ],
        "R68 targets must match fixed Ubuntu + macOS runner matrix"
    );

    let runners = dist
        .get("github-custom-runners")
        .and_then(toml::Value::as_table)
        .expect("R68 requires [dist.github-custom-runners]");
    assert_eq!(
        runners.get("global").and_then(toml::Value::as_str),
        Some("ubuntu-latest")
    );
    assert_eq!(
        runners
            .get("x86_64-unknown-linux-gnu")
            .and_then(toml::Value::as_str),
        Some("ubuntu-latest")
    );
    assert_eq!(
        runners
            .get("x86_64-apple-darwin")
            .and_then(toml::Value::as_str),
        Some("macos-latest")
    );
    assert_eq!(
        runners
            .get("aarch64-apple-darwin")
            .and_then(toml::Value::as_str),
        Some("macos-latest")
    );

    // R68 CLI-only archive boundary: web-gated `rslbp-serve` must not be packaged into CLI archives.
    assert!(
        dist.get("features").is_none() && dist.get("all-features").is_none(),
        "R68 leaves Cargo features at defaults so optional web surface is not enabled"
    );
    let binaries = dist
        .get("binaries")
        .and_then(toml::Value::as_table)
        .expect("dist-workspace.toml must scope [dist.binaries] to rslbp only");
    for triple in targets {
        let bins: Vec<&str> = binaries
            .get(triple)
            .and_then(toml::Value::as_array)
            .unwrap_or_else(|| panic!("missing [dist.binaries] entry for {triple}"))
            .iter()
            .map(|v| v.as_str().expect("binary name"))
            .collect();
        assert_eq!(
            bins,
            vec!["rslbp"],
            "release archive for {triple} must contain only rslbp (not web-gated rslbp-serve)"
        );
    }
}

#[test]
fn packed_artifact_guards_pass_and_discriminate_faults_r26() {
    let root = repo_root();

    // Element 4: every publishable manifest declares `include` (including README & licenses)
    // and never `exclude`; internal web crate explicitly sets `publish = false` and `dist = false`.
    for (rel, required_entries) in [
        (
            "Cargo.toml",
            &[
                "/src",
                "/README.md",
                "/CHANGELOG.md",
                "/LICENSE",
                "/LICENSE-MIT",
            ][..],
        ),
        (
            "crates/core/Cargo.toml",
            &["/src", "/README.md", "/LICENSE", "/LICENSE-MIT"][..],
        ),
        (
            "crates/cli/Cargo.toml",
            &[
                "/src",
                "/build.rs",
                "/README.md",
                "/LICENSE",
                "/LICENSE-MIT",
            ][..],
        ),
    ] {
        let doc: toml::Value =
            toml::from_str(&read_repo_file(&root, rel)).expect("parse package manifest");
        let pkg = doc["package"].as_table().expect("[package] table");
        assert!(
            !pkg.contains_key("exclude"),
            "R26 forbids declaring package.exclude alongside package.include in {rel}"
        );
        let include: Vec<&str> = pkg
            .get("include")
            .and_then(toml::Value::as_array)
            .unwrap_or_else(|| panic!("{rel} must declare explicit [package] include (R26)"))
            .iter()
            .map(|v| v.as_str().expect("include string"))
            .collect();
        for entry in required_entries {
            assert!(
                include.contains(entry),
                "{rel} [package] include missing required allow-list entry `{entry}`"
            );
        }
        assert!(
            pkg.get("metadata")
                .and_then(|m| m.get("docs"))
                .and_then(|d| d.get("rs"))
                .and_then(|r| r.get("all-features"))
                .and_then(toml::Value::as_bool)
                == Some(true),
            "{rel} must configure [package.metadata.docs.rs] all-features = true"
        );
    }

    let web_doc: toml::Value = toml::from_str(&read_repo_file(&root, "crates/web/Cargo.toml"))
        .expect("parse web manifest");
    assert_eq!(
        web_doc["package"]
            .get("publish")
            .and_then(toml::Value::as_bool),
        Some(false),
        "crates/web must declare publish = false (internal service crate, OV-18)"
    );
    assert_eq!(
        web_doc["package"]
            .get("metadata")
            .and_then(|m| m.get("dist"))
            .and_then(|d| d.get("dist"))
            .and_then(toml::Value::as_bool),
        Some(false),
        "crates/web must declare [package.metadata.dist] dist = false"
    );
    assert!(
        !root
            .join("ci/expected-packed-files/rs-launch-blueprint-web.txt")
            .exists(),
        "unpublishable crates/web must not have a packed-files baseline"
    );

    // Expectation files exist for all 3 publishable crates and file lists are byte-sorted (LC_ALL=C).
    for (pkg, expect_cargo_lock) in [
        ("rs-launch-blueprint-core", false),
        ("rs-launch-blueprint", false),
        ("rs-launch-blueprint-cli", true),
    ] {
        let files_rel = format!("ci/expected-packed-files/{pkg}.txt");
        let files_txt = read_repo_file(&root, &files_rel);
        let lines: Vec<&str> = files_txt.lines().collect();
        assert!(!lines.is_empty(), "{files_rel} must not be empty");
        let mut sorted = lines.clone();
        sorted.sort_unstable();
        assert_eq!(
            lines, sorted,
            "R26 requires {files_rel} to be sorted in byte order (LC_ALL=C)"
        );
        for synthesized in [
            "Cargo.toml",
            "Cargo.toml.orig",
            "LICENSE",
            "LICENSE-MIT",
            "README.md",
        ] {
            assert!(
                lines.contains(&synthesized),
                "{files_rel} must list `{synthesized}`"
            );
        }
        if expect_cargo_lock {
            assert!(
                lines.contains(&"Cargo.lock"),
                "{files_rel} (binary crate) must list Cargo-synthesized `Cargo.lock`"
            );
        }

        let targets_rel = format!("ci/expected-packaged-targets/{pkg}.json");
        let targets_raw = read_repo_file(&root, &targets_rel);
        let targets_json: serde_json::Value = serde_json::from_str(&targets_raw)
            .unwrap_or_else(|err| panic!("parse {targets_rel}: {err}"));
        assert!(
            targets_json.as_array().is_some_and(|a| !a.is_empty()),
            "{targets_rel} must be a non-empty JSON target array"
        );
    }

    // Guard script exists, is executable, and passes on the healthy repository.
    let guard_script = root.join("scripts/check-packed-artifacts.sh");
    assert!(
        guard_script.is_file(),
        "missing scripts/check-packed-artifacts.sh"
    );
    let mode = fs::metadata(&guard_script)
        .expect("stat check-packed-artifacts.sh")
        .permissions()
        .mode();
    assert!(
        mode & 0o111 != 0,
        "scripts/check-packed-artifacts.sh must be executable"
    );

    let scratch_target = TempDir::new("r26-live-target");
    let live = Command::new("bash")
        .args([
            guard_script.to_str().expect("utf8 path"),
            "--allow-dirty",
            "--no-verify",
            "--offline",
        ])
        .current_dir(&root)
        .env("CARGO_TARGET_DIR", scratch_target.path())
        .output()
        .expect("run scripts/check-packed-artifacts.sh");
    assert!(
        live.status.success(),
        "R26 packed-artifact guard failed on healthy workspace:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&live.stdout),
        String::from_utf8_lossy(&live.stderr)
    );

    // Fault injection (R26 acceptance criteria a, b, and element 4):
    // copy workspace into a scratch git repository (so Cargo synthesizes `.cargo_vcs_info.json`)
    // and verify each fault fails the guard.
    let fault_ws = TempDir::new("r26-fault-ws");
    copy_dir_filtered(&root, fault_ws.path());
    for git_args in [
        &["init", "-b", "main"][..],
        &["add", "-A"][..],
        &["commit", "-m", "chore: baseline"][..],
    ] {
        let mut cmd = Command::new("git");
        cmd.args(["-c", "commit.gpgSign=false"])
            .args(git_args)
            .current_dir(fault_ws.path())
            .env("GIT_AUTHOR_NAME", "Test User")
            .env("GIT_AUTHOR_EMAIL", "test@example.com")
            .env("GIT_COMMITTER_NAME", "Test User")
            .env("GIT_COMMITTER_EMAIL", "test@example.com");
        for var in [
            "GIT_DIR",
            "GIT_WORK_TREE",
            "GIT_INDEX_FILE",
            "GIT_OBJECT_DIRECTORY",
            "GIT_ALTERNATE_OBJECT_DIRECTORIES",
            "GIT_COMMON_DIR",
            "GIT_PREFIX",
        ] {
            cmd.env_remove(var);
        }
        let status = cmd.output().expect("git init/commit in scratch workspace");
        assert!(
            status.status.success(),
            "git {git_args:?} failed: {}",
            String::from_utf8_lossy(&status.stderr)
        );
    }

    let fault_target = TempDir::new("r26-fault-target");
    let fault_script = fault_ws.path().join("scripts/check-packed-artifacts.sh");
    let root_cargo = fault_ws.path().join("Cargo.toml");
    let orig_cargo = fs::read_to_string(&root_cargo).expect("read copied Cargo.toml");

    // Fault A: narrow `crates/cli/Cargo.toml` `include` so `src/main.rs` is omitted (pruned binary hazard, F078).
    let cli_cargo = fault_ws.path().join("crates/cli/Cargo.toml");
    let orig_cli_cargo = fs::read_to_string(&cli_cargo).expect("read copied crates/cli/Cargo.toml");
    let fault_a_cargo = orig_cli_cargo.replace(
        "\"/src\",",
        "\"/src/lib.rs\", \"/src/app.rs\", \"/src/args.rs\", \"/src/clipboard.rs\", \"/src/color.rs\", \"/src/crash_sink.rs\", \"/src/exit.rs\", \"/src/output.rs\", \"/src/pager.rs\", \"/src/prompter.rs\", \"/src/rich.rs\", \"/src/spinner.rs\", \"/src/telemetry.rs\",",
    );
    assert_ne!(
        fault_a_cargo, orig_cli_cargo,
        "fault A edit must modify crates/cli/Cargo.toml"
    );
    fs::write(&cli_cargo, &fault_a_cargo).expect("write fault A crates/cli/Cargo.toml");
    let out_a = Command::new("bash")
        .args([
            fault_script.to_str().expect("utf8 path"),
            "--allow-dirty",
            "--no-verify",
            "--offline",
            "-p",
            "rs-launch-blueprint-cli",
        ])
        .current_dir(fault_ws.path())
        .env("CARGO_TARGET_DIR", fault_target.path())
        .output()
        .expect("run guard on fault A");
    assert!(
        !out_a.status.success(),
        "R26 Fault A (pruned rslbp binary) must fail check-packed-artifacts.sh"
    );
    fs::write(&cli_cargo, &orig_cli_cargo).expect("restore crates/cli/Cargo.toml");

    // Fault B: stray root file added to `include` (file-set addition hazard, F039).
    fs::write(fault_ws.path().join("STRAY.txt"), "stray\n").expect("write stray file");
    let fault_b_cargo = orig_cargo.replace(
        "\"/LICENSE-MIT\",",
        "\"/LICENSE-MIT\",\n    \"/STRAY.txt\",",
    );
    fs::write(&root_cargo, &fault_b_cargo).expect("write fault B Cargo.toml");
    let out_b = Command::new("bash")
        .args([
            fault_script.to_str().expect("utf8 path"),
            "--allow-dirty",
            "--no-verify",
            "--offline",
            "-p",
            "rs-launch-blueprint",
        ])
        .current_dir(fault_ws.path())
        .env("CARGO_TARGET_DIR", fault_target.path())
        .output()
        .expect("run guard on fault B");
    assert!(
        !out_b.status.success(),
        "R26 Fault B (stray packed file) must fail check-packed-artifacts.sh"
    );
    let _ = fs::remove_file(fault_ws.path().join("STRAY.txt"));

    // Fault C: both `include` and `exclude` declared simultaneously (R26 element 4).
    let fault_c_cargo = orig_cargo.replace(
        "readme = \"README.md\"",
        "exclude = [\"/docs\"]\nreadme = \"README.md\"",
    );
    fs::write(&root_cargo, &fault_c_cargo).expect("write fault C Cargo.toml");
    let out_c = Command::new("bash")
        .args([
            fault_script.to_str().expect("utf8 path"),
            "--allow-dirty",
            "--no-verify",
            "--offline",
            "-p",
            "rs-launch-blueprint",
        ])
        .current_dir(fault_ws.path())
        .env("CARGO_TARGET_DIR", fault_target.path())
        .output()
        .expect("run guard on fault C");
    assert!(
        !out_c.status.success(),
        "R26 Fault C (include + exclude together) must fail check-packed-artifacts.sh"
    );
}

#[test]
fn release_publish_and_container_workflows_and_docs_match_p11_contract() {
    let root = repo_root();

    // 1. release-please.yml (R23/R24/R25 + credential-preflight skip-gating)
    let rp_wf = read_repo_file(&root, ".github/workflows/release-please.yml");
    for required in [
        "permissions: {}",
        "cancel-in-progress: false",
        "credential-preflight:",
        "needs.credential-preflight.outputs.auth == 'app'",
        "needs.credential-preflight.outputs.auth == 'pat'",
        "actions/create-github-app-token@v3",
        "googleapis/release-please-action@45996ed1f6d02564a971a2fa1b5860e934307cf7 # v5.0.0",
        "config-file: release-please-config.json",
        "manifest-file: .release-please-manifest.json",
    ] {
        assert!(
            rp_wf.contains(required),
            "release-please.yml missing required clause `{required}`"
        );
    }
    assert!(
        !rp_wf.contains("secrets.GITHUB_TOKEN"),
        "release-please.yml must never fall back to GITHUB_TOKEN (F072/R68)"
    );

    // 2. release.yml (cargo-dist 0.33.0 follower mode, R68 + R08/R09/R20)
    let rel_wf = read_repo_file(&root, ".github/workflows/release.yml");
    for required in [
        "permissions: {}",
        "0.33.0",
        "x86_64-unknown-linux-gnu",
        "x86_64-apple-darwin",
        "aarch64-apple-darwin",
        "4b3f0a5f0ebbdb798f6db649d01b32ba1518376b6f7a0502b7d92b75cc2c8293",
        "7b3cbe25511de01d74c0f5fcb7909edabd379bea9cfa284d93af5a3cdfa3247c",
        "dist plan",
        "dist build",
        "dist host",
        "--draft=false",
        "actions/create-github-app-token@v3",
    ] {
        assert!(
            rel_wf.contains(required),
            "release.yml missing required R68 clause `{required}`"
        );
    }
    let rel_wf_code: String = rel_wf
        .lines()
        .map(|line| line.split('#').next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");
    assert!(
        !rel_wf_code.contains("cargo-dist-installer.sh")
            && !rel_wf_code.lines().any(|line| {
                line.trim_end().ends_with("| sh")
                    || line.contains("| sh ")
                    || line.trim_end().ends_with("| bash")
                    || line.contains("| bash ")
            }),
        "release.yml must verify cargo-dist tarball SHA-256 rather than piping curl to sh"
    );

    // 3. publish.yml (R04 cargo-semver-checks for both library crates + R26 guards + gated crates.io publish)
    let pub_wf = read_repo_file(&root, ".github/workflows/publish.yml");
    for required in [
        "permissions: {}",
        "cancel-in-progress: false",
        "git merge-base --is-ancestor",
        "scripts/check-packed-artifacts.sh",
        "obi1kenobi/cargo-semver-checks-action@6b69fcf40e9b5fb17adeb57e4b6ecd020649a239 # v2.9",
        "package: rs-launch-blueprint-core",
        "package: rs-launch-blueprint",
        "feature-group: all-features",
        "cargo publish --workspace --dry-run --locked",
        "credential-preflight:",
        "environment: crates-io",
        "rust-lang/crates-io-auth-action@3268eb413133e2960fa4ae0e963ca76380c54cd9 # v1.0.6",
        "CRATES_IO_TOKEN",
    ] {
        assert!(
            pub_wf.contains(required),
            "publish.yml missing required R04/R26/F075 clause `{required}`"
        );
    }

    // 4. publish-container.yml + scripts/publish_container.py (owner 1a-A OVERRIDE of R51)
    let pc_wf = read_repo_file(&root, ".github/workflows/publish-container.yml");
    for required in [
        "permissions: {}",
        "1a-A",
        "R51",
        "release:",
        "types: [published]",
        "!github.event.release.draft",
        "!github.event.release.prerelease",
        "publish-version:",
        "promote-latest:",
        "packages: write",
        "container-version-${{ github.event.release.tag_name }}",
        "container-latest",
        "docker/setup-buildx-action@f87e5991a6d7451dcb8d9637bfbc97413f497069 # v4.4.1",
        "scripts/publish_container.py publish",
        "scripts/publish_container.py promote",
    ] {
        assert!(
            pc_wf.contains(required),
            "publish-container.yml missing required 1a-A GHCR clause `{required}`"
        );
    }

    let pc_script = root.join("scripts/publish_container.py");
    assert!(pc_script.is_file(), "missing scripts/publish_container.py");
    let pc_py = read_repo_file(&root, "scripts/publish_container.py");
    for required in [
        "ghcr.io",
        "linux/amd64",
        "org.opencontainers.image.source",
        "org.opencontainers.image.version",
        "org.opencontainers.image.revision",
        "docker-content-digest",
        "/healthz",
        "nonroot:nonroot",
        "143",
        "GITHUB_STEP_SUMMARY",
    ] {
        assert!(
            pc_py.contains(required),
            "scripts/publish_container.py missing required GHCR verification clause `{required}`"
        );
    }

    // Exercise scripts/publish_container.py self-check mode against workspace manifests & lockfile.
    let self_test = Command::new("python3")
        .args([pc_script.to_str().expect("utf8 path"), "self-test"])
        .current_dir(&root)
        .output()
        .expect("run python3 scripts/publish_container.py self-test");
    assert!(
        self_test.status.success(),
        "scripts/publish_container.py self-test failed:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&self_test.stdout),
        String::from_utf8_lossy(&self_test.stderr)
    );

    // 5. docs/RELEASE.md covers end-to-end release, crates.io, cargo-dist, and GHCR flow.
    let release_doc = read_repo_file(&root, "docs/RELEASE.md");
    for required in [
        "release-please",
        "crates.io",
        "cargo-dist",
        "dist-workspace.toml",
        "ghcr.io/smorinlabs/rs-launch-blueprint",
        "1a-A",
        "R51",
        "RELEASE_PLEASE_CLIENT_ID",
        "RELEASE_PLEASE_PRIVATE_KEY",
        "RELEASE_PLEASE_APP_TOKEN",
        "CRATES_IO_TOKEN",
        "crates-io",
        "cargo add rs-launch-blueprint",
        "cargo binstall rs-launch-blueprint-cli",
        "cargo install --locked rs-launch-blueprint-cli",
        "@sha256:",
    ] {
        assert!(
            release_doc.contains(required),
            "docs/RELEASE.md missing required section/token `{required}`"
        );
    }
}
