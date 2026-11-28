//! Template-only Template Press, bootstrap skill, contributors automation, and end-to-end
//! stamped child acceptance tests (`P12-TS01`).
//!
//! `press/press-rules.toml` removes this file in stamped child repositories so child suites
//! do not recurse or pin removed template-only surfaces.

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

const INHERITED_GIT_ENV_VARS: &[&str] = &[
    "GIT_DIR",
    "GIT_WORK_TREE",
    "GIT_INDEX_FILE",
    "GIT_OBJECT_DIRECTORY",
    "GIT_ALTERNATE_OBJECT_DIRECTORIES",
    "GIT_COMMON_DIR",
    "GIT_PREFIX",
];

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

fn provision_press_bin(root: &Path, scratch: &Path) -> PathBuf {
    let uv = find_on_path("uv").expect("`uv` must be on PATH to run template-press tests");
    let venv = scratch.join("press-venv");
    let venv_out = Command::new(&uv)
        .args(["venv", "--python", "3.13", venv.to_str().unwrap()])
        .current_dir(root)
        .output()
        .expect("create press venv");
    assert!(
        venv_out.status.success(),
        "uv venv failed:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&venv_out.stdout),
        String::from_utf8_lossy(&venv_out.stderr)
    );

    let python = venv.join("bin/python");
    let sync_out = Command::new(&uv)
        .args([
            "pip",
            "sync",
            "--python",
            python.to_str().unwrap(),
            "press/requirements.txt",
        ])
        .current_dir(root)
        .output()
        .expect("sync press requirements");
    assert!(
        sync_out.status.success(),
        "uv pip sync press/requirements.txt failed:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&sync_out.stdout),
        String::from_utf8_lossy(&sync_out.stderr)
    );

    let press_bin = venv.join("bin/press");
    assert!(
        press_bin.is_file(),
        "expected press executable at {}",
        press_bin.display()
    );
    press_bin
}

#[test]
fn press_rules_stubs_and_gitignore_match_p12_contract() {
    let root = repo_root();

    let rules_raw = read_text(&root, "press/press-rules.toml");
    let rules_doc: toml::Value = toml::from_str(&rules_raw).expect("parse press/press-rules.toml");

    let rules = rules_doc["rules"]
        .as_table()
        .expect("press-rules.toml must declare [rules]");
    let langs: Vec<&str> = rules["languages"]
        .as_array()
        .expect("[rules] languages array")
        .iter()
        .filter_map(toml::Value::as_str)
        .collect();
    assert_eq!(langs, vec!["rust"]);

    let keep_names: Vec<&str> = rules["keep_names"]
        .as_array()
        .expect("[rules] keep_names array")
        .iter()
        .filter_map(toml::Value::as_str)
        .collect();
    assert!(
        keep_names.contains(&"smorinlabs/difftree-action"),
        "keep_names must preserve smorinlabs/difftree-action (#618): {keep_names:?}"
    );

    let sub_fields: Vec<&str> = rules["substring_rewrite_fields"]
        .as_array()
        .expect("[rules] substring_rewrite_fields array")
        .iter()
        .filter_map(toml::Value::as_str)
        .collect();
    assert!(
        sub_fields.contains(&"app_name"),
        "substring_rewrite_fields must include app_name (R15 CARGO_BIN_EXE_<name>): {sub_fields:?}"
    );

    // Declared [[regenerate]] includes Cargo.lock and forwards CARGO_HOME / RUSTUP_HOME.
    let regens = rules_doc["regenerate"]
        .as_array()
        .expect("press-rules.toml must declare [[regenerate]]");
    let cargo_lock_regen = regens
        .iter()
        .find(|e| e.get("file").and_then(toml::Value::as_str) == Some("Cargo.lock"))
        .expect("[[regenerate]] must rebuild Cargo.lock");
    let regen_env: Vec<&str> = cargo_lock_regen
        .get("env")
        .and_then(toml::Value::as_array)
        .expect("Cargo.lock [[regenerate]] must declare env list")
        .iter()
        .filter_map(toml::Value::as_str)
        .collect();
    for var in ["CARGO_HOME", "RUSTUP_HOME"] {
        assert!(
            regen_env.contains(&var),
            "Cargo.lock [[regenerate]] env must forward `{var}`: {regen_env:?}"
        );
    }

    // Declared [[remove]] covers template-only files and directories.
    let removes = rules_doc["remove"]
        .as_array()
        .expect("press-rules.toml must declare [[remove]]");
    let removed_files: Vec<&str> = removes
        .iter()
        .filter_map(|e| e.get("file").and_then(toml::Value::as_str))
        .collect();
    let removed_dirs: Vec<&str> = removes
        .iter()
        .filter_map(|e| e.get("dir").and_then(toml::Value::as_str))
        .collect();

    for expected_file in [
        ".github/workflows/template-receipt-guard.yml",
        ".github/workflows/bootstrap-acceptance.yml",
        ".github/workflows/update-contributors.yml",
        ".contributors.yml",
        "CONTRIBUTORS.md",
        ".claude/skills/new-rust-project/SKILL.md",
        "tests/bootstrap_acceptance.rs",
    ] {
        assert!(
            removed_files.contains(&expected_file),
            "[[remove]] missing template-only file `{expected_file}`"
        );
    }
    for expected_dir in [
        "research",
        "docs/port",
        "docs/planning",
        "docs/superpowers",
        "docs/handoffs",
        "projects",
    ] {
        assert!(
            removed_dirs.contains(&expected_dir),
            "[[remove]] missing template-only dir `{expected_dir}`"
        );
    }

    // All 7 declared stubs exist and carry zero source identity literals.
    let forbidden_literals = [
        "rs-launch-blueprint",
        "rs_launch_blueprint",
        "rslbp",
        "RSLBP",
        "smorinlabs",
        "Steve Morin",
        "steve.morin@gmail.com",
    ];
    for stub in [
        "press/stubs/readme.md",
        "press/stubs/post-init.md",
        "press/stubs/projects.md",
        "press/stubs/security.md",
        "press/stubs/docs-index.md",
        "press/stubs/bootstrap-provenance.md",
        "press/stubs/retired-bootstrap.md",
    ] {
        let text = read_text(&root, stub);
        assert!(!text.trim().is_empty(), "{stub} must be non-empty");
        for literal in forbidden_literals {
            assert!(
                !text.contains(literal),
                "{stub} must stay free of source identity literal `{literal}`"
            );
        }
    }

    // R15: .gitignore ignores press/press-answers.toml and NEVER press/press-receipt.toml.
    let gitignore = read_text(&root, ".gitignore");
    assert!(
        gitignore
            .lines()
            .any(|l| l.trim() == "press/press-answers.toml"),
        ".gitignore must ignore transient press/press-answers.toml (R15)"
    );
    assert!(
        !gitignore
            .lines()
            .any(|l| l.trim() == "press/press-receipt.toml"),
        ".gitignore must NOT ignore press/press-receipt.toml (children legitimately commit it; R15)"
    );
}

#[test]
fn template_receipt_guard_and_bootstrap_workflows_satisfy_contract() {
    let root = repo_root();

    // template-receipt-guard.yml (R15, R08, R09)
    let guard_wf = read_text(&root, ".github/workflows/template-receipt-guard.yml");
    for required in [
        "permissions: {}",
        "runs-on: ubuntu-latest",
        "persist-credentials: false",
        "press/press-receipt.toml",
        "::error::press-receipt.toml committed in the template",
    ] {
        assert!(
            guard_wf.contains(required),
            "template-receipt-guard.yml missing `{required}`"
        );
    }

    // Exercise the receipt guard condition on clean repo (0) and receipt-present scratch dir (1).
    let check_cmd = r#"if [ -f press/press-receipt.toml ]; then echo '::error::press-receipt.toml committed in the template — it would disarm every fork'\''s guard. Revert.'; exit 1; fi"#;
    let clean = Command::new("bash")
        .args(["-c", check_cmd])
        .current_dir(&root)
        .output()
        .expect("run receipt guard on clean template");
    assert!(
        clean.status.success(),
        "receipt guard must exit 0 on clean template"
    );

    let dirty = TempDir::new("r15-receipt-guard");
    fs::create_dir_all(dirty.path().join("press")).unwrap();
    fs::write(
        dirty.path().join("press/press-receipt.toml"),
        "[press]\nverified = true\n",
    )
    .unwrap();
    let failed = Command::new("bash")
        .args(["-c", check_cmd])
        .current_dir(dirty.path())
        .output()
        .expect("run receipt guard with receipt");
    assert!(
        !failed.status.success(),
        "receipt guard must exit non-zero when press/press-receipt.toml exists"
    );
    assert!(
        String::from_utf8_lossy(&failed.stdout).contains("::error::press-receipt.toml committed"),
        "receipt guard must emit ::error:: annotation"
    );

    // bootstrap-acceptance.yml (R08, R09, R20, py P07/P12)
    let acc_wf = read_text(&root, ".github/workflows/bootstrap-acceptance.yml");
    for required in [
        "permissions: {}",
        "runs-on: ubuntu-latest",
        "persist-credentials: false",
        "schedule:",
        "workflow_dispatch:",
        "pull_request:",
        "release-please--",
        "astral-sh/setup-uv@",
        "bootstrap_acceptance",
    ] {
        assert!(
            acc_wf.contains(required),
            "bootstrap-acceptance.yml missing `{required}`"
        );
    }
}

#[test]
fn bootstrap_skill_and_agents_symlink_match_contract() {
    let root = repo_root();

    let skill = read_text(&root, ".claude/skills/new-rust-project/SKILL.md");
    let readme = read_text(&root, ".claude/skills/new-rust-project/README.md");
    let doc_page = read_text(&root, "docs/skills/new-rust-project.md");

    // Frontmatter validity + Codex <= 1024 char description envelope.
    let mut parts = skill.splitn(3, "---\n");
    let before = parts.next().unwrap_or("");
    assert!(
        before.is_empty(),
        "SKILL.md must start with YAML frontmatter `---`"
    );
    let fm = parts.next().expect("SKILL.md frontmatter block");
    let body = parts.next().expect("SKILL.md body after frontmatter");
    assert!(
        fm.lines().any(|l| l.trim() == "name: new-rust-project"),
        "SKILL.md frontmatter must declare `name: new-rust-project`"
    );
    let desc_line = fm
        .lines()
        .find(|l| l.trim_start().starts_with("description:"))
        .expect("SKILL.md frontmatter must declare description");
    let desc = desc_line
        .trim_start()
        .strip_prefix("description:")
        .unwrap()
        .trim()
        .trim_matches('\'')
        .trim_matches('"');
    assert!(
        !desc.is_empty() && desc.len() <= 1024,
        "SKILL.md description must be 1..=1024 chars (got {})",
        desc.len()
    );

    // Zero unfilled placeholders.
    for (name, text) in [
        ("SKILL.md", body),
        ("README.md", readme.as_str()),
        ("docs/skills/new-rust-project.md", doc_page.as_str()),
    ] {
        for placeholder in ["{{", "<TODO", "TODO:", "TBD"] {
            assert!(
                !text.contains(placeholder),
                "{name} contains unfilled placeholder `{placeholder}`"
            );
        }
    }

    for required in [
        "smorinlabs/rs-launch-blueprint",
        "gh repo create",
        "cargo fetch --locked",
        "--base main",
        "press/requirements.txt",
        "template-press==5.0.0",
        "press check-tools",
        "press clean",
        "press rebrand",
        "press verify",
        "press/press-receipt.toml",
        "docs/PROJECT_SETUP.md",
        "just setup",
        "just check",
        "/healthz",
    ] {
        assert!(
            skill.contains(required),
            "SKILL.md missing required bootstrap step/reference `{required}`"
        );
    }

    // Global installation guidance in README.md (#616).
    for required in [
        "~/.claude/skills/new-rust-project",
        "~/.agents/skills/new-rust-project",
        "SKILL.md",
        "docs/PROJECT_SETUP.md",
    ] {
        assert!(
            readme.contains(required),
            ".claude/skills/new-rust-project/README.md missing `{required}`"
        );
    }

    // Codex / agents relative directory symlink.
    let link_path = root.join(".agents/skills/new-rust-project");
    let link_meta =
        fs::symlink_metadata(&link_path).expect(".agents/skills/new-rust-project must exist");
    assert!(
        link_meta.file_type().is_symlink(),
        ".agents/skills/new-rust-project must be a symlink"
    );
    let target = fs::read_link(&link_path).expect("read symlink");
    assert_eq!(
        target,
        PathBuf::from("../../.claude/skills/new-rust-project"),
        ".agents/skills/new-rust-project must be a relative symlink to ../../.claude/skills/new-rust-project"
    );
    assert!(
        link_path.join("SKILL.md").is_file(),
        "symlinked .agents/skills/new-rust-project/SKILL.md must resolve"
    );
}

#[test]
fn contributors_config_roster_and_workflow_satisfy_r07_r21_f209() {
    let root = repo_root();

    let cfg = read_text(&root, ".contributors.yml");
    for required in [
        "classifier: path",
        "output_file: CONTRIBUTORS.md",
        "state_file: .contributors.jsonl",
        "in_place: true",
        "in_place_marker_start: \"<!-- contributors-please:start -->\"",
        "in_place_marker_end: \"<!-- contributors-please:end -->\"",
        "classification:",
        "categories:",
        "default:",
        "identity_map:",
        "- login: smorin",
    ] {
        assert!(
            cfg.contains(required),
            ".contributors.yml missing required F209 clause `{required}`"
        );
    }
    for unsupported in ["start_marker:", "end_marker:", "path_rules:"] {
        assert!(
            !cfg.contains(unsupported),
            ".contributors.yml must not use unsupported key `{unsupported}`"
        );
    }

    let roster = read_text(&root, "CONTRIBUTORS.md");
    assert!(
        roster.contains("<!-- contributors-please:start -->")
            && roster.contains("<!-- contributors-please:end -->"),
        "CONTRIBUTORS.md must contain both contributors-please in-place markers (R47)"
    );

    let wf = read_text(&root, ".github/workflows/update-contributors.yml");
    let wf_code: String = wf
        .lines()
        .map(|l| l.split('#').next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");

    // R07: push to main with paths-ignore on generated files + workflow_dispatch; NO schedule.
    assert!(
        !wf_code.contains("schedule:"),
        "update-contributors.yml must NOT contain a `schedule:` trigger (R07 rev 3/4)"
    );
    assert!(
        !wf_code.contains("pull_request:"),
        "update-contributors.yml must NOT trigger on pull_request (R07)"
    );
    for required in [
        "branches: [main]",
        "paths-ignore:",
        "- CONTRIBUTORS.md",
        "- .contributors.jsonl",
        "workflow_dispatch:",
        "permissions: {}",
        "contents: write",
        "pull-requests: write",
        "issues: write",
        "runs-on: ubuntu-latest",
        "fetch-depth: 0",
        "persist-credentials: false",
        "smorinlabs/contributors-please-action@3c6dbff9ef21190aa1f63b3c400ed4f0ab404ac1 # v1.3.9",
        "app-id: ${{ secrets.CONTRIBUTORS_PLEASE_CLIENT_ID }}",
        "private-key: ${{ secrets.CONTRIBUTORS_PLEASE_PRIVATE_KEY }}",
        "pat: ${{ secrets.CONTRIBUTORS_PLEASE_PAT }}",
        "output-file: CONTRIBUTORS.md",
        "state-file: .contributors.jsonl",
        "config-file: .contributors.yml",
        "mode: pull-request",
        "commit-message: \"docs: update contributors\"",
    ] {
        assert!(
            wf.contains(required),
            "update-contributors.yml missing required R07/R21/R08/R09/R20 clause `{required}`"
        );
    }
    assert!(
        !wf_code.contains("secrets.GITHUB_TOKEN"),
        "update-contributors.yml must NEVER pass secrets.GITHUB_TOKEN (R21)"
    );
    assert!(
        !wf_code.contains("[skip ci]"),
        "update-contributors.yml commit-message must NOT carry [skip ci] (R07/R21)"
    );
}

mod live {
    use super::*;
    use std::io::{Read, Write};
    use std::net::{TcpListener, TcpStream};
    use std::process::Stdio;
    use std::thread;
    use std::time::{Duration, Instant};

    #[test]
    #[ignore = "live: provisions pinned template-press via uv and runs press verify --json"]
    fn press_verify_passes_hermetically_on_template() {
        let root = repo_root();
        let scratch = TempDir::new("p12-press-verify");
        let press = provision_press_bin(&root, scratch.path());

        let out = Command::new(&press)
            .args(["verify", "--target", root.to_str().unwrap(), "--json"])
            .output()
            .expect("run press verify --json");
        assert!(
            out.status.success(),
            "press verify failed (exit {:?}):\nstdout={}\nstderr={}",
            out.status.code(),
            String::from_utf8_lossy(&out.stdout),
            String::from_utf8_lossy(&out.stderr)
        );
        let payload: serde_json::Value =
            serde_json::from_slice(&out.stdout).expect("parse press verify --json output");
        assert_eq!(
            payload["verified"].as_bool(),
            Some(true),
            "press verify must report verified=true: {payload}"
        );
        assert_eq!(
            payload["surviving"].as_array().map(Vec::len),
            Some(0),
            "press verify must report zero surviving leaks: {payload}"
        );
        assert_eq!(
            payload["stale_ignores"].as_array().map(Vec::len),
            Some(0),
            "press verify must report zero stale ignores: {payload}"
        );
    }

    fn run_checked(
        cwd: &Path,
        program: &Path,
        args: &[&str],
        extra_env: &[(&str, &str)],
    ) -> String {
        let mut cmd = Command::new(program);
        cmd.args(args).current_dir(cwd);
        for var in INHERITED_GIT_ENV_VARS {
            cmd.env_remove(var);
        }
        for (k, v) in extra_env {
            cmd.env(k, v);
        }
        let out = cmd.output().unwrap_or_else(|err| {
            panic!("failed to launch {} {:?}: {err}", program.display(), args)
        });
        let stdout = String::from_utf8_lossy(&out.stdout).into_owned();
        let stderr = String::from_utf8_lossy(&out.stderr).into_owned();
        assert!(
            out.status.success(),
            "command `{} {}` in {} failed ({:?}):\n--- stdout ---\n{stdout}\n--- stderr ---\n{stderr}",
            program.display(),
            args.join(" "),
            cwd.display(),
            out.status.code()
        );
        stdout
    }

    fn copy_tracked_tree(src: &Path, dst: &Path) {
        let git = find_on_path("git").expect("git on PATH");
        let mut cmd = Command::new(&git);
        cmd.args(["ls-files", "-z"]).current_dir(src);
        for var in INHERITED_GIT_ENV_VARS {
            cmd.env_remove(var);
        }
        let out = cmd.output().expect("git ls-files -z");
        assert!(out.status.success(), "git ls-files failed");

        for rel_bytes in out.stdout.split(|&b| b == 0).filter(|s| !s.is_empty()) {
            let rel = std::str::from_utf8(rel_bytes).expect("utf-8 tracked path");
            let from = src.join(rel);
            let to = dst.join(rel);
            let meta = match fs::symlink_metadata(&from) {
                Ok(m) => m,
                Err(_) => continue,
            };
            if let Some(parent) = to.parent() {
                fs::create_dir_all(parent).expect("create parent dir");
            }
            if meta.file_type().is_symlink() {
                let link_target = fs::read_link(&from).expect("read symlink");
                std::os::unix::fs::symlink(link_target, &to).expect("recreate symlink");
            } else if meta.is_file() {
                fs::copy(&from, &to).unwrap_or_else(|err| panic!("copy {rel}: {err}"));
                let perms = meta.permissions();
                fs::set_permissions(&to, perms).expect("preserve file permissions");
            }
        }
    }

    #[test]
    #[ignore = "live: stamps a fresh child repo into a temp dir, runs full `just check`, packaging, CLI and web /healthz smoke"]
    fn stamped_child_rebrands_cleanly_and_passes_just_check() {
        let root = repo_root();
        let git = find_on_path("git").expect("git on PATH");
        let just = find_on_path("just").expect("just on PATH");
        let cargo = PathBuf::from(option_env!("CARGO").unwrap_or("cargo"));

        let scratch = TempDir::new("p12-bootstrap-acceptance");
        let press = provision_press_bin(&root, scratch.path());
        let child = scratch.path().join("harbor-sample");
        let child_target = env::var_os("RSLBP_BOOTSTRAP_TARGET_DIR")
            .filter(|v| !v.is_empty())
            .map(PathBuf::from)
            .unwrap_or_else(|| scratch.path().join("cargo-target"));
        fs::create_dir_all(&child).expect("create child dir");

        copy_tracked_tree(&root, &child);
        let expected_difftree = read_text(&child, ".github/workflows/difftree-pr-comment.yml");

        let git_env = [
            ("GIT_AUTHOR_NAME", "Bootstrap Acceptance"),
            ("GIT_AUTHOR_EMAIL", "acceptance@example.org"),
            ("GIT_COMMITTER_NAME", "Bootstrap Acceptance"),
            ("GIT_COMMITTER_EMAIL", "acceptance@example.org"),
        ];
        run_checked(&child, &git, &["init", "--initial-branch=main"], &git_env);
        run_checked(
            &child,
            &git,
            &["config", "commit.gpgSign", "false"],
            &git_env,
        );
        run_checked(&child, &git, &["add", "--all"], &git_env);
        run_checked(
            &child,
            &git,
            &["commit", "-m", "chore: instantiate template"],
            &git_env,
        );
        run_checked(
            &child,
            &git,
            &[
                "remote",
                "add",
                "origin",
                "https://github.com/example-labs/harbor-sample.git",
            ],
            &git_env,
        );

        let answers = scratch.path().join("press-answers.toml");
        fs::write(
            &answers,
            "[answers]\n\
             package_name = \"harbor_sample\"\n\
             repo_name = \"harbor-sample\"\n\
             app_name = \"harborctl\"\n\
             author = \"Example Maintainer\"\n\
             email = \"maintainer@example.org\"\n\
             owner = \"example-labs\"\n\
             display_name = \"Harbor Sample\"\n",
        )
        .expect("write answers");

        run_checked(&child, &press, &["check-tools", "--target", "."], &[]);
        run_checked(&child, &press, &["clean", "--target", ".", "--show"], &[]);
        run_checked(&child, &press, &["clean", "--target", "."], &[]);
        run_checked(
            &child,
            &press,
            &[
                "rebrand",
                "--target",
                ".",
                "--config",
                answers.to_str().unwrap(),
                "--dry-run",
            ],
            &[],
        );
        assert!(
            run_checked(&child, &git, &["status", "--porcelain"], &git_env)
                .trim()
                .is_empty(),
            "press rebrand --dry-run must leave working tree clean"
        );

        run_checked(
            &child,
            &press,
            &[
                "rebrand",
                "--target",
                ".",
                "--config",
                answers.to_str().unwrap(),
            ],
            &[],
        );

        // Receipt & source config assertions.
        let receipt_doc: toml::Value =
            toml::from_str(&read_text(&child, "press/press-receipt.toml")).expect("parse receipt");
        assert_eq!(receipt_doc["press"]["verified"].as_bool(), Some(true));
        assert_eq!(
            receipt_doc["press"]["to"]["repo_name"].as_str(),
            Some("harbor-sample")
        );
        assert_eq!(
            receipt_doc["press"]["to"]["app_name"].as_str(),
            Some("harborctl")
        );
        let new_source: toml::Value = toml::from_str(&read_text(&child, "press/press-source.toml"))
            .expect("parse new source");
        assert_eq!(
            new_source["identity"]["package_name"].as_str(),
            Some("harbor_sample")
        );

        // difftree-pr-comment.yml preserved verbatim via keep_names (#618).
        let child_difftree = read_text(&child, ".github/workflows/difftree-pr-comment.yml");
        assert_eq!(
            child_difftree, expected_difftree,
            "difftree-pr-comment.yml must remain byte-identical in stamped child"
        );
        assert!(child_difftree.contains("uses: smorinlabs/difftree-action@v0"));

        // Template-only dirs and files removed.
        for removed in [
            "research",
            "docs/port",
            "docs/planning",
            "docs/superpowers",
            "docs/handoffs",
            "projects",
            ".github/workflows/template-receipt-guard.yml",
            ".github/workflows/bootstrap-acceptance.yml",
            ".github/workflows/update-contributors.yml",
            ".contributors.yml",
            "CONTRIBUTORS.md",
            ".claude/skills/new-rust-project/SKILL.md",
            "tests/bootstrap_acceptance.rs",
            "scripts/chain-next.sh",
            "scripts/check-research-tree.sh",
        ] {
            assert!(
                !child.join(removed).exists(),
                "template-only path `{removed}` must be removed in stamped child"
            );
        }

        // Retired bootstrap symlink still resolves to directory with README.md.
        assert!(child.join(".agents/skills/new-rust-project").is_dir());
        assert!(
            child
                .join(".claude/skills/new-rust-project/README.md")
                .is_file()
        );

        // Reset files equal their declared stubs.
        for (target_rel, stub_rel) in [
            ("README.md", "press/stubs/readme.md"),
            ("docs/POST_INIT.md", "press/stubs/post-init.md"),
            ("PROJECTS.md", "press/stubs/projects.md"),
            (".github/SECURITY.md", "press/stubs/security.md"),
            ("docs/README.md", "press/stubs/docs-index.md"),
            (
                "docs/skills/new-rust-project.md",
                "press/stubs/bootstrap-provenance.md",
            ),
            (
                ".claude/skills/new-rust-project/README.md",
                "press/stubs/retired-bootstrap.md",
            ),
        ] {
            assert_eq!(
                read_text(&child, target_rel),
                read_text(&child, stub_rel),
                "reset file `{target_rel}` must match `{stub_rel}`"
            );
        }
        assert_eq!(
            read_text(&child, ".release-please-manifest.json").trim(),
            "{}"
        );

        // Restore projects/.gitkeep and format/stage so git-backed gates see renamed files.
        fs::create_dir_all(child.join("projects")).unwrap();
        fs::write(child.join("projects/.gitkeep"), "").unwrap();
        run_checked(&child, &just, &["format"], &[]);
        run_checked(&child, &git, &["add", "--all"], &git_env);
        run_checked(&child, &git, &["diff", "--cached", "--check"], &git_env);

        let target_env = [("CARGO_TARGET_DIR", child_target.to_str().unwrap())];
        run_checked(&child, &just, &["check"], &target_env);
        run_checked(&child, &press, &["verify", "--target", "."], &[]);
        run_checked(&child, &just, &["check-packaging"], &target_env);
        run_checked(&child, &just, &["lib-check"], &target_env);

        // CLI binary & web serve binary smoke tests.
        let cli_ver = run_checked(
            &child,
            &cargo,
            &["run", "--locked", "--bin", "harborctl", "--", "--version"],
            &target_env,
        );
        assert_eq!(cli_ver.trim(), "harborctl 0.1.0");

        let serve_ver = run_checked(
            &child,
            &cargo,
            &[
                "run",
                "--locked",
                "-p",
                "harbor-sample-web",
                "--bin",
                "harborctl-serve",
                "--",
                "--version",
            ],
            &target_env,
        );
        assert_eq!(serve_ver.trim(), "harborctl-serve 0.1.0");

        // Boot harborctl-serve on an ephemeral loopback port and verify /healthz.
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind ephemeral port");
        let port = listener.local_addr().unwrap().port();
        drop(listener);

        let serve_bin = child_target.join("debug/harborctl-serve");
        assert!(
            serve_bin.is_file(),
            "expected built {}",
            serve_bin.display()
        );
        let mut server = Command::new(&serve_bin)
            .current_dir(&child)
            .env("HARBORCTL_WEB_HOST", "127.0.0.1")
            .env("HARBORCTL_WEB_PORT", port.to_string())
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .spawn()
            .expect("spawn harborctl-serve");

        let deadline = Instant::now() + Duration::from_secs(15);
        let mut health_body = None;
        while Instant::now() < deadline {
            assert!(
                server.try_wait().expect("poll server").is_none(),
                "harborctl-serve exited before becoming ready"
            );
            if let Ok(mut stream) = TcpStream::connect(("127.0.0.1", port)) {
                let _ = stream.set_read_timeout(Some(Duration::from_secs(2)));
                let req = format!(
                    "GET /healthz HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nConnection: close\r\n\r\n"
                );
                if stream.write_all(req.as_bytes()).is_ok() {
                    let mut resp = String::new();
                    if stream.read_to_string(&mut resp).is_ok()
                        && let Some((head, body)) = resp.split_once("\r\n\r\n")
                        && head
                            .lines()
                            .next()
                            .is_some_and(|status| status.starts_with("HTTP/1.1 200"))
                    {
                        health_body = Some(body.to_owned());
                        break;
                    }
                }
            }
            thread::sleep(Duration::from_millis(100));
        }

        let _ = server.kill();
        let _ = server.wait();

        let body = health_body.expect("harborctl-serve /healthz did not respond within 15s");
        let health: serde_json::Value =
            serde_json::from_str(&body).unwrap_or_else(|e| panic!("invalid JSON `{body}`: {e}"));
        assert_eq!(health["status"].as_str(), Some("ok"));
        assert_eq!(health["version"].as_str(), Some("0.1.0"));
    }
}
