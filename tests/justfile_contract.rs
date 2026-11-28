//! Contract tests for `Makefile`, `Justfile`, R42 invocation discipline, and Blaze fallback.

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
    fn new(prefix: &str) -> Result<Self, String> {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_err(|err| format!("clock error: {err}"))?
            .as_nanos();
        let path = env::temp_dir().join(format!("{prefix}-{}-{nanos}", std::process::id()));
        fs::create_dir_all(&path)
            .map_err(|err| format!("failed to create temp dir {}: {err}", path.display()))?;
        Ok(Self { path })
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
    // Prefer runtime CARGO_MANIFEST_DIR before compile-time env!("CARGO_MANIFEST_DIR"):
    // Blaze v2 normalizes compile-time manifest paths for cross-worktree cache sharing.
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

fn find_executable_on_path(name: &str) -> Result<PathBuf, String> {
    let path_var = env::var_os("PATH").ok_or_else(|| "PATH is not set".to_owned())?;
    for dir in env::split_paths(&path_var) {
        let candidate = dir.join(name);
        if candidate.is_file() {
            return Ok(candidate);
        }
    }
    Err(format!("executable `{name}` not found on PATH"))
}

fn write_executable(path: &Path, body: &str) -> Result<(), String> {
    fs::write(path, body).map_err(|err| format!("write {}: {err}", path.display()))?;
    let mut perms = fs::metadata(path)
        .map_err(|err| format!("metadata {}: {err}", path.display()))?
        .permissions();
    perms.set_mode(0o755);
    fs::set_permissions(path, perms).map_err(|err| format!("chmod {}: {err}", path.display()))
}

#[test]
fn justfile_lists_required_p04_recipes() {
    let output = Command::new("just")
        .arg("--summary")
        .current_dir(repo_root())
        .output()
        .expect("just --summary must run");
    assert!(
        output.status.success(),
        "just --summary failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let summary = String::from_utf8_lossy(&output.stdout);
    let recipes: Vec<&str> = summary.split_whitespace().collect();

    for required in [
        "setup",
        "check-deps",
        "install-tool",
        "hooks-install",
        "hooks-run",
        "hook-check",
        "check",
        "format",
        "format-files",
        "format-check",
        "check-files",
        "fmt",
        "security",
        "check-hygiene",
        "check-large-files",
        "check-lockfile",
        "lint",
        "lint-fix",
        "typecheck",
        "test",
        "test-slow",
        "test-live",
        "test-all",
        "coverage",
        "lib-check",
        "install-check",
        "deny",
        "check-shell",
        "debug-info",
        "blaze-check",
        "blaze-test",
        "blaze-run",
        "blaze-status",
        "install-blaze",
        "serve",
        "serve-once",
        "export-openapi",
        "check-openapi",
        "api-breaking",
        "test-contract",
        "generate-client",
        "docker-web",
    ] {
        assert!(
            recipes.contains(&required),
            "Justfile is missing required recipe `{required}`; found: {recipes:?}"
        );
    }
}

#[test]
fn justfile_uses_parallel_check_and_respects_r42_invocation_rules() {
    let root = repo_root();
    let justfile = fs::read_to_string(root.join("Justfile")).expect("read Justfile");

    assert!(
        justfile.contains("[parallel]"),
        "Justfile must declare [parallel] on the composite check recipe (py P11)"
    );

    let mut found_parallel_check = false;
    let lines: Vec<&str> = justfile.lines().collect();
    for window in lines.windows(2) {
        if window[0].trim() == "[parallel]"
            && (window[1].starts_with("check:") || window[1].starts_with("@check:"))
        {
            found_parallel_check = true;
            break;
        }
    }
    assert!(
        found_parallel_check,
        "Justfile [parallel] attribute must sit directly above the `check:` recipe"
    );

    // R42: no provisioner prefixes in Justfile recipes and no declarative provisioner manifests.
    // Trailing space on `cargo bin ` distinguishes the `cargo-run-bin` wrapper from `cargo binstall`.
    for forbidden in [
        "mise exec ",
        "cargo bin ",
        "nix develop -c",
        "flox activate",
        "uv run ",
    ] {
        assert!(
            !justfile.contains(forbidden),
            "Justfile must not contain forbidden provisioner prefix `{forbidden}` (R42)"
        );
    }

    for absent_manifest in ["mise.toml", ".mise.toml", ".tool-versions", ".flox"] {
        assert!(
            !root.join(absent_manifest).exists(),
            "R42 forbids declarative provisioner manifest `{absent_manifest}`"
        );
    }

    let cargo_config = root.join(".cargo/config.toml");
    if cargo_config.exists() {
        let text = fs::read_to_string(&cargo_config).expect("read .cargo/config.toml");
        assert!(
            !text.contains("[alias]"),
            "R42 forbids Cargo [alias] tables in .cargo/config.toml"
        );
    }
}

#[test]
fn makefile_provides_level1_bootstrap_contract() {
    let makefile = fs::read_to_string(repo_root().join("Makefile")).expect("read Makefile");
    assert!(
        makefile.contains("SHELL := /bin/bash"),
        "Makefile must pin SHELL := /bin/bash"
    );
    for target in [
        ".PHONY:",
        "bootstrap:",
        "check:",
        "hook-check:",
        "install-rust:",
        "install-just:",
        "help:",
    ] {
        assert!(
            makefile.contains(target),
            "Makefile missing Level-1 target `{target}`"
        );
    }
}

#[test]
fn blaze_recipes_use_blaze_when_present_and_fallback_when_absent() {
    let just_bin = find_executable_on_path("just").expect("just must be installed");
    let tmp = TempDir::new("rslbp-blaze-contract").expect("create temp dir");
    let log_file = tmp.path().join("invocations.log");

    // Helper script template that logs every invocation to $TEST_LOG.
    let stub_cargo = "#!/bin/sh\nprintf 'CARGO:%s\\n' \"$*\" >> \"$TEST_LOG\"\n";
    let stub_blaze = "#!/bin/sh\nif [ \"$1\" = \"--version\" ]; then\n  echo 'blaze 0.20261127.0 (stub)'\n  exit 0\nfi\nprintf 'BLAZE:%s\\n' \"$*\" >> \"$TEST_LOG\"\n";

    // Case 1: `blaze` PRESENT on isolated PATH.
    let bin_with_blaze = tmp.path().join("with-blaze");
    fs::create_dir_all(&bin_with_blaze).expect("create with-blaze dir");
    std::os::unix::fs::symlink(&just_bin, bin_with_blaze.join("just")).expect("symlink just");
    write_executable(&bin_with_blaze.join("cargo"), stub_cargo).expect("write stub cargo");
    write_executable(&bin_with_blaze.join("blaze"), stub_blaze).expect("write stub blaze");
    let path_with_blaze = format!("{}:/usr/bin:/bin", bin_with_blaze.display());

    for (recipe, extra_args, expected_line) in [
        ("blaze-check", &[][..], "BLAZE:check"),
        ("blaze-test", &[][..], "BLAZE:test"),
        (
            "blaze-run",
            &["--version"][..],
            "BLAZE:run --bin rslbp -- --version",
        ),
    ] {
        let _ = fs::remove_file(&log_file);
        let mut cmd = Command::new(&just_bin);
        cmd.arg(recipe)
            .args(extra_args)
            .current_dir(repo_root())
            .env("PATH", &path_with_blaze)
            .env("TEST_LOG", &log_file);
        let out = cmd.output().expect("run just with blaze present");
        assert!(
            out.status.success(),
            "`just {recipe}` with blaze present failed: stdout={} stderr={}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        );
        let log = fs::read_to_string(&log_file).expect("read invocation log");
        assert!(
            log.lines().any(|line| line == expected_line),
            "`just {recipe}` expected `{expected_line}`, got:\n{log}"
        );
        assert!(
            !log.contains("CARGO:"),
            "`just {recipe}` must not invoke cargo when blaze is present:\n{log}"
        );
    }

    let status_present = Command::new(&just_bin)
        .arg("blaze-status")
        .current_dir(repo_root())
        .env("PATH", &path_with_blaze)
        .env("TEST_LOG", &log_file)
        .output()
        .expect("run just blaze-status with blaze present");
    assert!(
        status_present.status.success(),
        "just blaze-status (present) failed: {}",
        String::from_utf8_lossy(&status_present.stderr)
    );
    let status_present_out = String::from_utf8_lossy(&status_present.stdout);
    assert!(
        status_present_out.contains("blaze 0.20261127.0")
            && status_present_out.contains("rust-toolchain.toml"),
        "just blaze-status must report blaze version and rust-toolchain.toml comparison:\n{status_present_out}"
    );

    // Case 2: `blaze` ABSENT from isolated PATH — must gracefully fall back to Cargo.
    let bin_without_blaze = tmp.path().join("without-blaze");
    fs::create_dir_all(&bin_without_blaze).expect("create without-blaze dir");
    std::os::unix::fs::symlink(&just_bin, bin_without_blaze.join("just")).expect("symlink just");
    write_executable(&bin_without_blaze.join("cargo"), stub_cargo).expect("write stub cargo");
    let path_without_blaze = format!("{}:/usr/bin:/bin", bin_without_blaze.display());

    for (recipe, extra_args, expected_prefix) in [
        ("blaze-check", &[][..], "CARGO:check"),
        ("blaze-test", &[][..], "CARGO:test"),
        (
            "blaze-run",
            &["--version"][..],
            "CARGO:run --bin rslbp -- --version",
        ),
    ] {
        let _ = fs::remove_file(&log_file);
        let out = Command::new(&just_bin)
            .arg(recipe)
            .args(extra_args)
            .current_dir(repo_root())
            .env("PATH", &path_without_blaze)
            .env("TEST_LOG", &log_file)
            .output()
            .expect("run just with blaze absent");
        assert!(
            out.status.success(),
            "`just {recipe}` fallback failed: stdout={} stderr={}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        );
        let combined = format!(
            "{}{}",
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        );
        assert!(
            combined
                .to_ascii_lowercase()
                .contains("falling back to cargo"),
            "`just {recipe}` must print a fallback notice when blaze is absent; got:\n{combined}"
        );
        let log = fs::read_to_string(&log_file).expect("read invocation log");
        assert!(
            log.lines().any(|line| line.starts_with(expected_prefix)),
            "`just {recipe}` fallback expected line starting with `{expected_prefix}`, got:\n{log}"
        );
    }

    let status_absent = Command::new(&just_bin)
        .arg("blaze-status")
        .current_dir(repo_root())
        .env("PATH", &path_without_blaze)
        .env("TEST_LOG", &log_file)
        .output()
        .expect("run just blaze-status with blaze absent");
    assert!(
        status_absent.status.success(),
        "just blaze-status (absent) must exit 0: {}",
        String::from_utf8_lossy(&status_absent.stderr)
    );
    let status_absent_out = String::from_utf8_lossy(&status_absent.stdout);
    assert!(
        status_absent_out
            .to_ascii_lowercase()
            .contains("not installed")
            && status_absent_out.contains("just install-blaze"),
        "just blaze-status (absent) must report blaze is not installed and mention install-blaze:\n{status_absent_out}"
    );
}
