//! GitHub Actions CI, security, contract, and AI review/triage workflow meta-tests (`P10-TS01`).
//!
//! Validates:
//! - R08: uniform top-level `permissions: {}`, `persist-credentials: false` / commented exception,
//!   and `difftree-pr-comment.yml` exact-name exemption (`scripts/check-workflow-permissions.sh`)
//! - R09: literal GitHub-hosted runner labels (`ubuntu-latest`, `macos-latest`, `${{ matrix.os }}`)
//! - R11: fail-closed `plan` path-filter detector (including renames, packaging inputs, nested
//!   Markdown, pipe-buffer stress, and py P12 release-please fast-path) and no trigger `paths:`
//! - R12: `ci-ok` coverage of every other job in `ci.yml`, `always()`, `permissions: {}`,
//!   `workflow-lint` completeness guard, and T1–T9 allow-list verdict vectors
//! - R20: `zizmor.yml` owner-prefix SHA pinning + `scripts/check-action-pin-comments.sh` controls
//! - R13/R14/R16/R17/R19/R34/R38/R51/R71: security, contract, freshness, and Dependabot invariants
//! - R18/R86/1b-A: credential-preflight gating with positive predicates and security guards on all
//!   Claude, Codex, and Muse audit-triage workflows

use std::collections::{BTreeMap, BTreeSet};
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

fn workflow_files(root: &Path) -> Vec<PathBuf> {
    let dir = root.join(".github/workflows");
    let mut files: Vec<PathBuf> = fs::read_dir(&dir)
        .expect("read .github/workflows")
        .filter_map(Result::ok)
        .map(|entry| entry.path())
        .filter(|path| {
            path.is_file()
                && matches!(
                    path.extension().and_then(|e| e.to_str()),
                    Some("yml" | "yaml")
                )
        })
        .collect();
    files.sort();
    files
}

fn read_workflow(root: &Path, name: &str) -> String {
    let path = root.join(".github/workflows").join(name);
    fs::read_to_string(&path).unwrap_or_else(|err| panic!("read {}: {err}", path.display()))
}

/// Extract top-level job IDs under `jobs:` from a standard 2-space-indented GitHub Actions YAML.
fn parse_job_ids(yaml: &str) -> Vec<String> {
    let mut in_jobs = false;
    let mut job_ids = Vec::new();
    for line in yaml.lines() {
        if !in_jobs {
            if line.trim_end() == "jobs:" {
                in_jobs = true;
            }
            continue;
        }
        if line.is_empty() || line.trim_start().starts_with('#') {
            continue;
        }
        // A new column-0 key exits `jobs:`.
        if !line.starts_with(' ') && !line.starts_with('\t') {
            break;
        }
        // Standard 2-space indent for job keys (`  job-id:`).
        if let Some(rest) = line.strip_prefix("  ")
            && !rest.starts_with(' ')
            && let Some((key, after)) = rest.split_once(':')
            && (after.trim().is_empty() || after.trim_start().starts_with('#'))
        {
            let trimmed = key.trim();
            if !trimmed.is_empty() && !trimmed.starts_with('#') {
                job_ids.push(trimmed.to_owned());
            }
        }
    }
    job_ids
}

/// Extract the `needs:` list for a specific job in a standard 2-space-indented workflow YAML.
fn parse_job_needs(yaml: &str, target_job: &str) -> Vec<String> {
    let mut in_jobs = false;
    let mut in_target = false;
    let mut in_needs_list = false;
    let mut needs = Vec::new();

    for line in yaml.lines() {
        if !in_jobs {
            if line.trim_end() == "jobs:" {
                in_jobs = true;
            }
            continue;
        }
        if !in_target {
            if let Some(rest) = line.strip_prefix("  ")
                && !rest.starts_with(' ')
                && rest.starts_with(&format!("{target_job}:"))
            {
                in_target = true;
            }
            continue;
        }
        if !line.is_empty() && !line.trim_start().starts_with('#') {
            if !line.starts_with(' ') {
                break;
            }
            if let Some(rest) = line.strip_prefix("  ")
                && !rest.starts_with(' ')
            {
                break;
            }
        }
        if in_needs_list {
            let trimmed = line.trim();
            if let Some(item) = trimmed.strip_prefix("- ") {
                let val = item.split('#').next().unwrap_or("").trim();
                if !val.is_empty() {
                    needs.push(val.to_owned());
                }
                continue;
            } else if !trimmed.is_empty() && !trimmed.starts_with('#') {
                in_needs_list = false;
            }
        }
        if let Some(rest) = line.strip_prefix("    needs:") {
            let value = rest.split('#').next().unwrap_or("").trim();
            if value.is_empty() {
                in_needs_list = true;
            } else if value.starts_with('[') && value.ends_with(']') {
                for item in value[1..value.len() - 1].split(',') {
                    let v = item.trim();
                    if !v.is_empty() {
                        needs.push(v.to_owned());
                    }
                }
            } else {
                needs.push(value.to_owned());
            }
        }
    }
    needs
}

fn extract_marked_block(text: &str, begin: &str, end: &str) -> String {
    let mut collecting = false;
    let mut lines = Vec::new();
    for line in text.lines() {
        if line.contains(begin) {
            collecting = true;
            continue;
        }
        if line.contains(end) {
            break;
        }
        if collecting {
            lines.push(line);
        }
    }
    assert!(
        !lines.is_empty(),
        "failed to extract marked block `{begin}` .. `{end}`"
    );
    let min_indent = lines
        .iter()
        .filter(|l| !l.trim().is_empty())
        .map(|l| l.len() - l.trim_start_matches(' ').len())
        .min()
        .unwrap_or(0);
    lines
        .into_iter()
        .map(|l| {
            if l.len() >= min_indent {
                &l[min_indent..]
            } else {
                ""
            }
        })
        .collect::<Vec<_>>()
        .join("\n")
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

fn git_cmd(dir: &Path, args: &[&str]) -> String {
    let mut cmd = Command::new("git");
    cmd.args(["-c", "commit.gpgSign=false"])
        .args(args)
        .current_dir(dir)
        .env("GIT_AUTHOR_NAME", "Test User")
        .env("GIT_AUTHOR_EMAIL", "test@example.com")
        .env("GIT_COMMITTER_NAME", "Test User")
        .env("GIT_COMMITTER_EMAIL", "test@example.com");
    for var in INHERITED_GIT_ENV_VARS {
        cmd.env_remove(var);
    }
    let out = cmd.output().expect("git must execute");
    assert!(
        out.status.success(),
        "git {args:?} failed: stdout={} stderr={}",
        String::from_utf8_lossy(&out.stdout),
        String::from_utf8_lossy(&out.stderr)
    );
    String::from_utf8_lossy(&out.stdout).trim().to_owned()
}

fn run_plan_detector(
    detector_body: &str,
    repo_dir: &Path,
    event_name: &str,
    base_sha: &str,
    head_ref: &str,
    head_repo: &str,
    repository: &str,
) -> BTreeMap<String, String> {
    let out_dir = TempDir::new("r11-github-output");
    let out_file = out_dir.path().join("github-output.tmp");
    fs::write(&out_file, "").expect("init GITHUB_OUTPUT file");
    let script = format!("set -euo pipefail\n{detector_body}\n");
    let mut cmd = Command::new("bash");
    cmd.args(["-c", &script])
        .current_dir(repo_dir)
        .env("GITHUB_OUTPUT", &out_file)
        .env("EVENT_NAME", event_name)
        .env("BASE_SHA", base_sha)
        .env("HEAD_REF", head_ref)
        .env("HEAD_REPO", head_repo)
        .env("REPOSITORY", repository);
    for var in INHERITED_GIT_ENV_VARS {
        cmd.env_remove(var);
    }
    let out = cmd.output().expect("run plan detector bash body");
    assert!(
        out.status.success(),
        "plan detector failed (event={event_name}, head_ref={head_ref}): stdout={} stderr={}",
        String::from_utf8_lossy(&out.stdout),
        String::from_utf8_lossy(&out.stderr)
    );
    let raw = fs::read_to_string(&out_file).expect("read GITHUB_OUTPUT");
    let mut map = BTreeMap::new();
    for line in raw.lines() {
        if let Some((k, v)) = line.split_once('=') {
            map.insert(k.to_owned(), v.to_owned());
        }
    }
    map
}

#[test]
fn expected_p10_workflows_and_supporting_files_exist_and_shellcheck_retired() {
    let root = repo_root();

    // P10-T01: standalone shellcheck.yml is retired once covered by hygiene in ci.yml.
    assert!(
        !root.join(".github/workflows/shellcheck.yml").exists(),
        ".github/workflows/shellcheck.yml must be retired once covered by ci.yml hygiene"
    );

    for wf in [
        "ci.yml",
        "dep-audit.yml",
        "dependency-review.yml",
        "codeql.yml",
        "secret-scan.yml",
        "large-file-guard.yml",
        "commitlint.yml",
        "api-contract.yml",
        "docker-web.yml",
        "canary.yml",
        "manual-pr-security-scan.yml",
        "claude-code-review.yml",
        "claude.yml",
        "codex-code-review.yml",
        "codex.yml",
        "audit-triage.yml",
        "difftree-pr-comment.yml",
    ] {
        assert!(
            root.join(".github/workflows").join(wf).is_file(),
            "missing required P10 workflow `.github/workflows/{wf}`"
        );
    }

    for file in [
        "zizmor.yml",
        "scripts/check-workflow-permissions.sh",
        "scripts/check-action-pin-comments.sh",
        ".github/codeql/codeql-config.yml",
        ".github/dependabot.yml",
        ".claude/commands/review-pr.md",
        ".github/codex/review-pr.md",
        ".github/codex/assist.md",
        ".github/muse-audit-triage/policy.json",
        ".github/muse-audit-triage/triage-settings.json",
        ".github/muse-audit-triage/NOTICE",
        ".github/muse-audit-triage/runtime.py",
        ".github/scripts/muse_audit_triage.py",
        ".cargo/audit.toml",
    ] {
        assert!(
            root.join(file).is_file(),
            "missing required P10 supporting file `{file}`"
        );
    }

    for exec_script in [
        "scripts/check-workflow-permissions.sh",
        "scripts/check-action-pin-comments.sh",
    ] {
        let mode = fs::metadata(root.join(exec_script))
            .expect("stat script")
            .permissions()
            .mode();
        assert!(
            mode & 0o111 != 0,
            "{exec_script} must have executable bit set"
        );
    }
}

#[test]
fn workflow_permissions_hardening_r08_and_script_controls() {
    let root = repo_root();
    let script = root.join("scripts/check-workflow-permissions.sh");

    // 1. Live repository tree must pass R08 permissions guard.
    let live = Command::new("bash")
        .arg(&script)
        .current_dir(&root)
        .output()
        .expect("run scripts/check-workflow-permissions.sh");
    assert!(
        live.status.success(),
        "check-workflow-permissions.sh failed on repo:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&live.stdout),
        String::from_utf8_lossy(&live.stderr)
    );

    // 2. Every non-exempt workflow declares column-0 `permissions: {}` and sets
    //    `persist-credentials: false` on every `actions/checkout` step.
    for path in workflow_files(&root) {
        let name = path.file_name().unwrap().to_string_lossy();
        let text = fs::read_to_string(&path).expect("read workflow");
        if name != "difftree-pr-comment.yml" {
            assert!(
                text.lines().any(|l| l.trim_end() == "permissions: {}"),
                "{name} must declare top-level `permissions: {{}}` (R08)"
            );
        }
        let lines: Vec<&str> = text.lines().collect();
        for (idx, line) in lines.iter().enumerate() {
            let code = line.split('#').next().unwrap_or("").trim();
            if code.starts_with("- uses: actions/checkout@")
                || code.starts_with("uses: actions/checkout@")
            {
                let window_end = (idx + 12).min(lines.len());
                let mut found = false;
                for next in &lines[idx + 1..window_end] {
                    let trimmed = next.trim();
                    if trimmed.starts_with("- ") {
                        break;
                    }
                    if trimmed.starts_with("persist-credentials:") && trimmed.contains("false") {
                        found = true;
                        break;
                    }
                }
                assert!(
                    found,
                    "{name}:{} `actions/checkout` step must set `persist-credentials: false` (R08)",
                    idx + 1
                );
            }
        }
    }

    // 3. Negative and exemption controls on check-workflow-permissions.sh.
    let tmp = TempDir::new("r08-perm-controls");
    let wf_dir = tmp.path().join(".github/workflows");
    fs::create_dir_all(&wf_dir).unwrap();

    // Missing top-level permissions: {}
    fs::write(
        wf_dir.join("bad-top.yml"),
        "name: Bad\non: push\npermissions:\n  contents: read\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo ok\n",
    )
    .unwrap();
    let bad_top = Command::new("bash")
        .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(
        !bad_top.status.success(),
        "top-level non-empty permissions must fail check-workflow-permissions.sh"
    );
    fs::remove_file(wf_dir.join("bad-top.yml")).unwrap();

    // Uncommented persist-credentials: true, 'true', True, expression, and flow-style map
    for (case_name, with_block) in [
        (
            "bare-true",
            "        with:\n          persist-credentials: true",
        ),
        (
            "quoted-true",
            "        with:\n          persist-credentials: 'true'",
        ),
        (
            "cap-true",
            "        with:\n          persist-credentials: True",
        ),
        (
            "expr",
            "        with:\n          persist-credentials: ${{ inputs.persist }}",
        ),
        ("flow-map", "        with: { persist-credentials: false }"),
    ] {
        let body = format!(
            "name: Bad\non: push\npermissions: {{}}\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v7\n{with_block}\n"
        );
        let p = wf_dir.join(format!("{case_name}.yml"));
        fs::write(&p, body).unwrap();
        let res = Command::new("bash")
            .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
            .output()
            .unwrap();
        assert!(
            !res.status.success(),
            "R08 negative case `{case_name}` must fail check-workflow-permissions.sh"
        );
        fs::remove_file(&p).unwrap();
    }

    // Commented exception `persist-credentials: true # needed for push` passes.
    fs::write(
        wf_dir.join("good-exception.yml"),
        "name: Good\non: push\npermissions: {}\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v7\n        with:\n          persist-credentials: true # needed for git push step\n",
    )
    .unwrap();
    let good_ex = Command::new("bash")
        .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(
        good_ex.status.success(),
        "commented persist-credentials exception must pass: stderr={}",
        String::from_utf8_lossy(&good_ex.stderr)
    );
    fs::remove_file(wf_dir.join("good-exception.yml")).unwrap();

    // Exact-name exemption for difftree-pr-comment.yml only.
    let difftree = fs::read_to_string(root.join(".github/workflows/difftree-pr-comment.yml"))
        .expect("read difftree");
    fs::write(wf_dir.join("difftree-pr-comment.yml"), &difftree).unwrap();
    let exempt_ok = Command::new("bash")
        .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(
        exempt_ok.status.success(),
        "difftree-pr-comment.yml must be exempt by exact basename"
    );
    fs::rename(
        wf_dir.join("difftree-pr-comment.yml"),
        wf_dir.join("not-difftree.yml"),
    )
    .unwrap();
    let renamed_fail = Command::new("bash")
        .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
        .output()
        .unwrap();
    assert!(
        !renamed_fail.status.success(),
        "same bytes under another basename must NOT be exempt"
    );
}

#[test]
fn third_party_action_pinning_r20_and_comment_script_controls() {
    let root = repo_root();

    // 1. zizmor.yml policy matches R20 verbatim.
    let zizmor_cfg = fs::read_to_string(root.join("zizmor.yml")).expect("read zizmor.yml");
    for required in [
        "unpinned-uses:",
        "actions/*: ref-pin",
        "github/*: ref-pin",
        "\"*\": hash-pin",
        "difftree-pr-comment.yml:63",
    ] {
        assert!(
            zizmor_cfg.contains(required),
            "zizmor.yml missing R20 clause `{required}`"
        );
    }

    // 2. Live repo passes check-action-pin-comments.sh.
    let script = root.join("scripts/check-action-pin-comments.sh");
    let live = Command::new("bash")
        .arg(&script)
        .current_dir(&root)
        .output()
        .expect("run scripts/check-action-pin-comments.sh");
    assert!(
        live.status.success(),
        "check-action-pin-comments.sh failed on repo:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&live.stdout),
        String::from_utf8_lossy(&live.stderr)
    );

    // 3. Every active non-actions/non-github `uses:` across all workflows is full-SHA pinned
    //    with a `# v?[0-9]+(\.[0-9]+)*` release comment (except exempt difftree-pr-comment.yml).
    for path in workflow_files(&root) {
        let name = path.file_name().unwrap().to_string_lossy();
        let text = fs::read_to_string(&path).expect("read workflow");
        for (idx, line) in text.lines().enumerate() {
            let trimmed = line.trim();
            if trimmed.starts_with('#') {
                continue;
            }
            let after_uses = if let Some(rest) = trimmed.strip_prefix("- uses:") {
                rest.trim()
            } else if let Some(rest) = trimmed.strip_prefix("uses:") {
                rest.trim()
            } else {
                continue;
            };
            let action_ref = after_uses.split('#').next().unwrap_or("").trim();
            if action_ref.starts_with("./")
                || action_ref.starts_with("actions/")
                || action_ref.starts_with("github/")
            {
                continue;
            }
            if name == "difftree-pr-comment.yml" && action_ref == "smorinlabs/difftree-action@v0" {
                continue;
            }
            let (_repo, sha) = action_ref.split_once('@').unwrap_or_else(|| {
                panic!("{name}:{} third-party uses missing `@`: `{line}`", idx + 1)
            });
            assert!(
                sha.len() == 40 && sha.bytes().all(|b| matches!(b, b'0'..=b'9' | b'a'..=b'f')),
                "{name}:{} third-party action must be 40-hex SHA pinned (R20): `{line}`",
                idx + 1
            );
            let comment = after_uses
                .split_once('#')
                .map(|(_, c)| c)
                .unwrap_or_else(|| {
                    panic!(
                        "{name}:{} SHA-pinned action missing trailing version comment (R20): `{line}`",
                        idx + 1
                    )
                });
            let ver = comment.strip_prefix(' ').unwrap_or_else(|| {
                panic!(
                    "{name}:{} comment must start with `# ` (single space): `{line}`",
                    idx + 1
                )
            });
            let ver = ver.trim_end();
            let digits = ver.strip_prefix('v').unwrap_or(ver);
            let valid_ver = !digits.is_empty()
                && digits
                    .split('.')
                    .all(|seg| !seg.is_empty() && seg.bytes().all(|b| b.is_ascii_digit()));
            assert!(
                valid_ver,
                "{name}:{} version comment `#{comment}` violates R20 grammar `v?[0-9]+(\\.[0-9]+)*`",
                idx + 1
            );
        }
    }

    // 4. Positive and negative controls on check-action-pin-comments.sh.
    let tmp = TempDir::new("r20-pin-controls");
    let wf_dir = tmp.path().join(".github/workflows");
    fs::create_dir_all(&wf_dir).unwrap();

    for (case_name, uses_line, expect_ok) in [
        (
            "valid-semver",
            "      - uses: Swatinem/rust-cache@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v2.9.2",
            true,
        ),
        (
            "valid-major",
            "      - uses: dtolnay/rust-toolchain@683b588c487a69d01f6c6ddf40f036ff682cc2c8 # v1",
            true,
        ),
        (
            "valid-no-v",
            "      - uses: foo/bar@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # 2.7.0",
            true,
        ),
        (
            "missing-comment",
            "      - uses: foo/bar@6323deb102c322ba6fcbdcafc7e3dddab59af2b6",
            false,
        ),
        (
            "prose-comment",
            "      - uses: foo/bar@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # pinned by hand",
            false,
        ),
        (
            "extra-suffix",
            "      - uses: foo/bar@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 # v1; CLI 2.1",
            false,
        ),
        (
            "no-space-after-hash",
            "      - uses: foo/bar@6323deb102c322ba6fcbdcafc7e3dddab59af2b6 #v1.0.0",
            false,
        ),
    ] {
        let p = wf_dir.join(format!("{case_name}.yml"));
        fs::write(
            &p,
            format!("name: Test\non: push\npermissions: {{}}\njobs:\n  j:\n    runs-on: ubuntu-latest\n    steps:\n{uses_line}\n"),
        )
        .unwrap();
        let res = Command::new("bash")
            .args([script.to_str().unwrap(), wf_dir.to_str().unwrap()])
            .output()
            .unwrap();
        assert_eq!(
            res.status.success(),
            expect_ok,
            "R20 pin comment control `{case_name}` expected ok={expect_ok}, got {:?}\nstdout={}\nstderr={}",
            res.status.code(),
            String::from_utf8_lossy(&res.stdout),
            String::from_utf8_lossy(&res.stderr)
        );
        fs::remove_file(&p).unwrap();
    }
}

#[test]
fn runner_labels_follow_r09_hosted_literals() {
    let root = repo_root();
    for path in workflow_files(&root) {
        let name = path.file_name().unwrap().to_string_lossy();
        let text = fs::read_to_string(&path).expect("read workflow");
        assert!(
            !text.contains("vars.RUNNER_"),
            "{name} must not reference vars.RUNNER_* indirection (R09)"
        );
        for (idx, line) in text.lines().enumerate() {
            let trimmed = line.trim();
            if trimmed.starts_with('#') {
                continue;
            }
            if let Some(rest) = trimmed.strip_prefix("runs-on:") {
                let value = rest.split('#').next().unwrap_or("").trim();
                assert!(
                    matches!(value, "ubuntu-latest" | "macos-latest" | "${{ matrix.os }}"),
                    "{name}:{} disallowed runs-on label `{value}` (R09 allows only ubuntu-latest, macos-latest, or `${{{{ matrix.os }}}}`)",
                    idx + 1
                );
            }
        }
    }
}

#[test]
fn ci_plan_detector_fails_closed_and_supports_release_fast_path_r11() {
    let root = repo_root();
    let ci_yml = read_workflow(&root, "ci.yml");

    // No trigger-level paths or paths-ignore in ci.yml (R11).
    let on_section = ci_yml
        .split("\njobs:")
        .next()
        .expect("ci.yml must have jobs:");
    let on_code: String = on_section
        .lines()
        .map(|l| l.split('#').next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");
    assert!(
        !on_code.contains("paths:") && !on_code.contains("paths-ignore:"),
        "ci.yml must never use trigger-level paths/paths-ignore filters (R11)"
    );
    assert!(
        on_section.contains("merge_group:"),
        "ci.yml must trigger on merge_group (R11/R12)"
    );
    assert!(
        !ci_yml.contains("outputs.code != 'false'")
            && !ci_yml.contains("outputs.web != 'false'")
            && !ci_yml.contains("outputs.workflows != 'false'"),
        "ci.yml must use positive predicates (`== 'true'`), never negated `!= 'false'` (R11)"
    );

    let detector = extract_marked_block(&ci_yml, "# R11-DETECTOR-BEGIN", "# R11-DETECTOR-END");

    // Build an isolated scratch git repository to execute the detector body directly.
    let tmp = TempDir::new("r11-plan-detector");
    let repo = tmp.path();
    git_cmd(repo, &["init", "-b", "main"]);
    fs::create_dir_all(repo.join("src")).unwrap();
    fs::create_dir_all(repo.join("crates/core/src")).unwrap();
    fs::create_dir_all(repo.join("crates/web/src")).unwrap();
    fs::create_dir_all(repo.join("docs")).unwrap();
    fs::create_dir_all(repo.join("openapi")).unwrap();
    fs::create_dir_all(repo.join(".github/workflows")).unwrap();
    fs::write(repo.join("README.md"), "# readme\n").unwrap();
    fs::write(repo.join("CHANGELOG.md"), "# changelog\n").unwrap();
    fs::write(repo.join("LICENSE"), "Apache-2.0\n").unwrap();
    fs::write(repo.join("LICENSE-MIT"), "MIT\n").unwrap();
    fs::write(
        repo.join(".release-please-manifest.json"),
        "{\".\": \"0.1.0\"}\n",
    )
    .unwrap();
    fs::write(
        repo.join("Cargo.toml"),
        "[workspace.package]\nversion = \"0.1.0\"\n[dependencies]\nrs-launch-blueprint-core = { version = \"0.1.0\", path = \"crates/core\" }\n",
    )
    .unwrap();
    fs::write(
        repo.join("crates/core/Cargo.toml"),
        "[package]\nname = \"rs-launch-blueprint-core\"\nversion = \"0.1.0\"\n",
    )
    .unwrap();
    fs::write(
        repo.join("Cargo.lock"),
        "[[package]]\nname = \"rs-launch-blueprint\"\nversion = \"0.1.0\"\n",
    )
    .unwrap();
    fs::write(repo.join("src/lib.rs"), "pub fn a() {}\n").unwrap();
    fs::write(repo.join("crates/core/src/lib.rs"), "pub fn b() {}\n").unwrap();
    fs::write(repo.join("crates/web/src/lib.rs"), "pub fn c() {}\n").unwrap();
    fs::write(repo.join("docs/guide.md"), "# guide\n").unwrap();
    fs::write(repo.join("openapi/openapi.json"), "{}\n").unwrap();
    fs::write(repo.join(".github/workflows/ci.yml"), "name: CI\n").unwrap();
    git_cmd(repo, &["add", "."]);
    git_cmd(repo, &["commit", "-m", "chore: base"]);
    let base_sha = git_cmd(repo, &["rev-parse", "HEAD"]);

    // Case 1: Non-PR events (`push`, `merge_group`) never skip-gate anything.
    for ev in ["push", "merge_group"] {
        let out = run_plan_detector(
            &detector,
            repo,
            ev,
            "",
            "",
            "smorinlabs/rs-launch-blueprint",
            "smorinlabs/rs-launch-blueprint",
        );
        assert_eq!(out.get("code").map(String::as_str), Some("true"), "ev={ev}");
        assert_eq!(out.get("web").map(String::as_str), Some("true"), "ev={ev}");
        assert_eq!(
            out.get("workflows").map(String::as_str),
            Some("true"),
            "ev={ev}"
        );
        assert_eq!(out.get("docs").map(String::as_str), Some("true"), "ev={ev}");
        assert_eq!(
            out.get("release").map(String::as_str),
            Some("false"),
            "ev={ev}"
        );
    }

    // Helper to test a single PR commit off base_sha.
    let test_pr_change =
        |branch: &str, head_repo: &str, mutate: &dyn Fn(&Path)| -> BTreeMap<String, String> {
            git_cmd(repo, &["checkout", "-B", branch, &base_sha]);
            mutate(repo);
            git_cmd(repo, &["add", "-A"]);
            git_cmd(repo, &["commit", "-m", "chore: test case"]);
            run_plan_detector(
                &detector,
                repo,
                "pull_request",
                &base_sha,
                branch,
                head_repo,
                "smorinlabs/rs-launch-blueprint",
            )
        };

    // Case 2: Docs-only PR skips compile tier (`code=false`, `web=false`, `workflows=false`).
    let docs_only = test_pr_change("feat/docs", "smorinlabs/rs-launch-blueprint", &|r| {
        fs::create_dir_all(r.join(".vscode")).unwrap();
        fs::create_dir_all(r.join(".github/ISSUE_TEMPLATE")).unwrap();
        fs::write(r.join("docs/guide.md"), "# updated\n").unwrap();
        fs::write(r.join(".vscode/settings.json"), "{}\n").unwrap();
        fs::write(r.join(".github/ISSUE_TEMPLATE/bug.yml"), "name: bug\n").unwrap();
        fs::write(r.join("NOTES.md"), "# root non-packaged md\n").unwrap();
    });
    assert_eq!(docs_only["code"], "false");
    assert_eq!(docs_only["web"], "false");
    assert_eq!(docs_only["workflows"], "false");
    assert_eq!(docs_only["docs"], "true");
    assert_eq!(docs_only["release"], "false");

    // Case 3: Packaging inputs (README.md, CHANGELOG.md, LICENSE, LICENSE-MIT) force code=true.
    for pkg_file in ["README.md", "CHANGELOG.md", "LICENSE", "LICENSE-MIT"] {
        let out = test_pr_change("feat/pkg", "smorinlabs/rs-launch-blueprint", &|r| {
            fs::write(r.join(pkg_file), "updated\n").unwrap();
        });
        assert_eq!(
            out["code"], "true",
            "packaging input `{pkg_file}` must set code=true"
        );
        assert_eq!(
            out["web"], "true",
            "packaging input `{pkg_file}` must set web=true (fail-closed)"
        );
    }

    // Case 4: Nested Markdown inside packaged dirs (`src/`, `crates/`) sets code=true.
    for nested_md in ["src/notes.md", "crates/core/README.md"] {
        let out = test_pr_change("feat/nested-md", "smorinlabs/rs-launch-blueprint", &|r| {
            fs::write(r.join(nested_md), "# nested\n").unwrap();
        });
        assert_eq!(
            out["code"], "true",
            "nested markdown `{nested_md}` must set code=true (R11 rev 3)"
        );
        assert_eq!(out["web"], "true");
    }

    // Case 5: Core / OpenAPI / unknown root file fail closed (`code=true`, `web=true`).
    for path in [
        "crates/core/src/lib.rs",
        "openapi/openapi.json",
        "unknown.txt",
    ] {
        let out = test_pr_change("feat/code", "smorinlabs/rs-launch-blueprint", &|r| {
            fs::write(r.join(path), "changed\n").unwrap();
        });
        assert_eq!(out["code"], "true", "`{path}` must set code=true");
        assert_eq!(out["web"], "true", "`{path}` must set web=true");
    }

    // Case 6: Rename out of packaged path into docs/ still sets code=true (`--no-renames`).
    let rename_out = test_pr_change("feat/rename", "smorinlabs/rs-launch-blueprint", &|r| {
        git_cmd(r, &["mv", "src/lib.rs", "docs/moved.rs"]);
    });
    assert_eq!(
        rename_out["code"], "true",
        "rename from src/ into docs/ must fail closed via --no-renames (R11 rev 5)"
    );
    assert_eq!(rename_out["web"], "true");

    // Case 7: `workflows` matches workflows, local actions (incl. non-ASCII), and actionlint config.
    for wf_path in [
        ".github/workflows/ci.yml",
        ".github/actions/local/action.yml",
        ".github/actions/café/action.yml",
        ".github/actionlint.yaml",
    ] {
        let out = test_pr_change("feat/wf", "smorinlabs/rs-launch-blueprint", &|r| {
            let full = r.join(wf_path);
            fs::create_dir_all(full.parent().unwrap()).unwrap();
            fs::write(&full, "updated: true\n").unwrap();
        });
        assert_eq!(
            out["workflows"], "true",
            "`{wf_path}` must set workflows=true (R11 rev 6)"
        );
    }

    // Case 8: Pipe-buffer stress (>150 KiB changed-path list) must not SIGPIPE fail-open (R11 rev 5).
    let stress_docs = test_pr_change("feat/big-docs", "smorinlabs/rs-launch-blueprint", &|r| {
        let dir = r.join("docs/generated-many-pages-padding-directory-name");
        fs::create_dir_all(&dir).unwrap();
        for i in 0..2200 {
            fs::write(
                dir.join(format!(
                    "page-{i:04}-padding-filename-to-exceed-pipe-buffer.md"
                )),
                "ok\n",
            )
            .unwrap();
        }
    });
    assert_eq!(
        stress_docs["code"], "false",
        "large docs-only list must still prove skippable without SIGPIPE"
    );

    let stress_code = test_pr_change("feat/big-code", "smorinlabs/rs-launch-blueprint", &|r| {
        let dir = r.join("docs/generated-many-pages-padding-directory-name");
        fs::create_dir_all(&dir).unwrap();
        for i in 0..2200 {
            fs::write(
                dir.join(format!(
                    "page-{i:04}-padding-filename-to-exceed-pipe-buffer.md"
                )),
                "ok\n",
            )
            .unwrap();
        }
        fs::write(r.join("src/lib.rs"), "pub fn changed() {}\n").unwrap();
    });
    assert_eq!(
        stress_code["code"], "true",
        "large changed-path list containing src/lib.rs must never SIGPIPE fail-open"
    );

    // Case 9: Release-please fast-path (py P12) — valid version bump vs tampered PRs.
    let rp_ok = test_pr_change(
        "release-please--branches--main",
        "smorinlabs/rs-launch-blueprint",
        &|r| {
            fs::write(
                r.join(".release-please-manifest.json"),
                "{\".\": \"0.2.0\"}\n",
            )
            .unwrap();
            fs::write(r.join("CHANGELOG.md"), "# changelog\n## 0.2.0\n").unwrap();
            fs::write(
                r.join("Cargo.toml"),
                "[workspace.package]\nversion = \"0.2.0\"\n[dependencies]\nrs-launch-blueprint-core = { version = \"0.2.0\", path = \"crates/core\" }\n",
            )
            .unwrap();
            fs::write(
                r.join("Cargo.lock"),
                "[[package]]\nname = \"rs-launch-blueprint\"\nversion = \"0.2.0\"\n",
            )
            .unwrap();
        },
    );
    assert_eq!(rp_ok["release"], "true");
    assert_eq!(rp_ok["code"], "false");
    assert_eq!(rp_ok["web"], "false");

    // Release-please from a fork MUST NOT take the fast-path.
    let rp_fork = test_pr_change(
        "release-please--branches--main",
        "evil/rs-launch-blueprint",
        &|r| {
            fs::write(
                r.join(".release-please-manifest.json"),
                "{\".\": \"0.2.0\"}\n",
            )
            .unwrap();
            fs::write(r.join("CHANGELOG.md"), "# changelog\n## 0.2.0\n").unwrap();
        },
    );
    assert_eq!(rp_fork["release"], "false");
    assert_eq!(rp_fork["code"], "true");

    // Release-please touching an extra Cargo.toml dependency line MUST NOT take the fast-path.
    let rp_extra_dep = test_pr_change(
        "release-please--branches--main",
        "smorinlabs/rs-launch-blueprint",
        &|r| {
            fs::write(
                r.join(".release-please-manifest.json"),
                "{\".\": \"0.2.0\"}\n",
            )
            .unwrap();
            fs::write(r.join("CHANGELOG.md"), "# changelog\n## 0.2.0\n").unwrap();
            fs::write(
                r.join("Cargo.toml"),
                "[workspace.package]\nversion = \"0.2.0\"\n[dependencies]\nrs-launch-blueprint-core = { version = \"0.2.0\", path = \"crates/core\" }\nevil = \"1.0\"\n",
            )
            .unwrap();
        },
    );
    assert_eq!(rp_extra_dep["release"], "false");
    assert_eq!(rp_extra_dep["code"], "true");

    // Release-please deleting a tracked workspace member Cargo.toml MUST NOT take the fast-path.
    let rp_deleted_cargo = test_pr_change(
        "release-please--branches--main",
        "smorinlabs/rs-launch-blueprint",
        &|r| {
            fs::write(
                r.join(".release-please-manifest.json"),
                "{\".\": \"0.2.0\"}\n",
            )
            .unwrap();
            fs::write(r.join("CHANGELOG.md"), "# changelog\n## 0.2.0\n").unwrap();
            fs::remove_file(r.join("crates/core/Cargo.toml")).unwrap();
        },
    );
    assert_eq!(rp_deleted_cargo["release"], "false");
    assert_eq!(rp_deleted_cargo["code"], "true");
}

#[test]
fn ci_ok_folds_every_ci_job_and_uses_fail_closed_allow_list_r12() {
    let root = repo_root();
    let ci_yml = read_workflow(&root, "ci.yml");

    let job_ids = parse_job_ids(&ci_yml);
    assert!(
        job_ids.iter().any(|j| j == "ci-ok"),
        "ci.yml must declare aggregate job `ci-ok` (R12)"
    );
    let expected_needs: BTreeSet<String> = job_ids.into_iter().filter(|j| j != "ci-ok").collect();
    for core_job in [
        "plan",
        "hygiene",
        "workflow-lint",
        "check",
        "msrv-floor",
        "install-smoke",
        "coverage",
    ] {
        assert!(
            expected_needs.contains(core_job),
            "ci.yml missing expected job `{core_job}`"
        );
    }

    let actual_needs: BTreeSet<String> = parse_job_needs(&ci_yml, "ci-ok").into_iter().collect();
    assert_eq!(
        actual_needs, expected_needs,
        "ci-ok needs must fold in EVERY other ci.yml job including plan (R12)"
    );

    // Check workflow-lint completeness guard exists.
    assert!(
        ci_yml.contains("yq -o=json '.jobs' .github/workflows/ci.yml"),
        "workflow-lint must include the R12 ci-ok completeness guard"
    );

    // Verify ci-ok job structure: always(), permissions: {}, timeout-minutes: 5, no checkout,
    // positive jq allow-list over NEEDS_JSON.
    let ci_ok_section = ci_yml
        .split("\n  ci-ok:")
        .nth(1)
        .expect("ci-ok section in ci.yml");
    assert!(
        ci_ok_section.contains("if: ${{ always() }}") || ci_ok_section.contains("if: always()"),
        "ci-ok must run under always() (R12)"
    );
    assert!(
        ci_ok_section.contains("permissions: {}"),
        "ci-ok must declare permissions: {{}} (R08/R12)"
    );
    assert!(
        !ci_ok_section.contains("actions/checkout"),
        "ci-ok must not run actions/checkout (R12)"
    );
    assert!(
        ci_ok_section.contains("NEEDS_JSON: ${{ toJSON(needs) }}"),
        "ci-ok must pass toJSON(needs) via env: (R12)"
    );
    let jq_rule = r#"length > 0 and all(.[]; .result == "success" or .result == "skipped")"#;
    assert!(
        ci_ok_section.contains(jq_rule),
        "ci-ok must enforce the R12 positive allow-list `{jq_rule}`"
    );

    // Execute the exact jq allow-list against all nine R12 T1–T9 verdict vectors.
    let vectors = [
        (
            "T1-all-success",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"success"},"check":{"result":"success"}}"#,
            true,
        ),
        (
            "T2-docs-only-skips",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"success"},"check":{"result":"skipped"}}"#,
            true,
        ),
        (
            "T3-plan-failed",
            r#"{"plan":{"result":"failure"},"hygiene":{"result":"success"},"check":{"result":"skipped"}}"#,
            false,
        ),
        (
            "T4-plan-cancelled",
            r#"{"plan":{"result":"cancelled"},"hygiene":{"result":"success"},"check":{"result":"skipped"}}"#,
            false,
        ),
        (
            "T5-check-failed",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"success"},"check":{"result":"failure"}}"#,
            false,
        ),
        (
            "T6-check-cancelled",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"success"},"check":{"result":"cancelled"}}"#,
            false,
        ),
        (
            "T7-hygiene-failed",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"failure"},"check":{"result":"skipped"}}"#,
            false,
        ),
        (
            "T8-unknown-result",
            r#"{"plan":{"result":"success"},"hygiene":{"result":"unknown"}}"#,
            false,
        ),
        ("T9-empty-needs", r#"{}"#, false),
    ];

    for (label, json, expect_pass) in vectors {
        let out = Command::new("jq")
            .args(["-e", jq_rule])
            .stdin(std::process::Stdio::piped())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::piped())
            .spawn()
            .and_then(|mut child| {
                use std::io::Write;
                child
                    .stdin
                    .as_mut()
                    .unwrap()
                    .write_all(json.as_bytes())
                    .unwrap();
                child.wait_with_output()
            })
            .expect("jq must execute");
        assert_eq!(
            out.status.success(),
            expect_pass,
            "R12 verdict vector `{label}` expected pass={expect_pass}"
        );
    }
}

#[test]
fn ai_and_triage_workflows_use_positive_credential_preflight_and_guards() {
    let root = repo_root();

    for wf in [
        "claude-code-review.yml",
        "claude.yml",
        "codex-code-review.yml",
        "codex.yml",
        "audit-triage.yml",
    ] {
        let text = read_workflow(&root, wf);
        let jobs = parse_job_ids(&text);
        assert!(
            jobs.iter().any(|j| j == "credential-preflight"),
            "{wf} must declare a `credential-preflight` job (R18/R86/1b-A)"
        );
        assert!(
            !text.contains("outputs.credential !="),
            "{wf} must use a POSITIVE credential predicate, never `!= 'none'` (R18/R86)"
        );
        assert!(
            text.contains("::notice "),
            "{wf} preflight must emit a `::notice` when credential is absent"
        );
        assert!(
            text.contains("GITHUB_STEP_SUMMARY"),
            "{wf} preflight must write a `$GITHUB_STEP_SUMMARY` block when credential is absent"
        );
        assert!(
            text.contains("delete ") || text.contains("Delete "),
            "{wf} preflight must state deleting the workflow file as the opt-out"
        );
        // Never reference `secrets.` inside a job-level `if:` condition.
        for (idx, line) in text.lines().enumerate() {
            let trimmed = line.trim();
            if trimmed.starts_with("if:") {
                assert!(
                    !trimmed.contains("secrets."),
                    "{wf}:{} cannot read `secrets.` in job/step `if:`",
                    idx + 1
                );
            }
        }
    }

    // Claude workflows (R18 rev 6)
    let claude_review = read_workflow(&root, "claude-code-review.yml");
    for required in [
        "github.event.pull_request.head.repo.full_name == github.repository",
        "github.event.pull_request.draft == false",
        "github.event.pull_request.user.type != 'Bot'",
        "github.event.sender.type != 'Bot'",
        "needs.credential-preflight.outputs.credential == 'static'",
        "needs.credential-preflight.outputs.credential == 'federation'",
        "anthropics/claude-code-action@19dda84776b3518d98b8798e591daee763049ed3 # v1.0.220",
        "/review-pr",
    ] {
        assert!(
            claude_review.contains(required),
            "claude-code-review.yml missing R18 clause `{required}`"
        );
    }
    assert!(
        !claude_review.contains("plugin_marketplaces:") && !claude_review.contains("plugins:"),
        "claude-code-review.yml must not fetch unpinnable plugin marketplaces (R18 rev 4)"
    );
    assert!(
        !claude_review.contains("ENABLE_CLAUDE_REVIEW"),
        "claude-code-review.yml must not use enable variables (R18 rev 6)"
    );

    let claude_assist = read_workflow(&root, "claude.yml");
    for required in [
        "github.event.sender.type != 'Bot'",
        "github.event.comment.user.type != 'Bot'",
        "github.event.review.user.type != 'Bot'",
        "github.event.issue.user.type != 'Bot'",
        r#"contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)"#,
        "needs.credential-preflight.outputs.credential == 'static'",
        "needs.credential-preflight.outputs.credential == 'federation'",
        "anthropics/claude-code-action@19dda84776b3518d98b8798e591daee763049ed3 # v1.0.220",
    ] {
        assert!(
            claude_assist.contains(required),
            "claude.yml missing R18 clause `{required}`"
        );
    }
    assert!(
        !claude_assist.contains("ENABLE_CLAUDE_ASSISTANT"),
        "claude.yml must not use enable variables (R18 rev 6)"
    );

    // Codex workflows (R86 rev 2): three-job split, :read-only, drop-sudo, pinned CLI 0.154.0.
    let codex_review = read_workflow(&root, "codex-code-review.yml");
    assert_eq!(
        parse_job_ids(&codex_review),
        vec!["credential-preflight", "codex-review", "post-review"]
    );
    for required in [
        "github.event.pull_request.head.repo.full_name == github.repository",
        "github.event.pull_request.draft == false",
        "github.event.pull_request.user.type != 'Bot'",
        "github.event.sender.type != 'Bot'",
        "needs.credential-preflight.outputs.credential == 'present'",
        "openai/codex-action@86365089eb2b84e0a8fb0717b304f8bdcb13b20e # v1.12",
        "codex-version: \"0.154.0\"",
        "permission-profile: \":read-only\"",
        "safety-strategy: drop-sudo",
        "prompt-file: .github/codex/review-pr.md",
    ] {
        assert!(
            codex_review.contains(required),
            "codex-code-review.yml missing R86 clause `{required}`"
        );
    }
    let post_review = codex_review.split("\n  post-review:").nth(1).unwrap();
    assert!(
        !post_review.contains("OPENAI_API_KEY"),
        "codex-code-review.yml post-review job must hold NO model credential (R86)"
    );

    let codex_assist = read_workflow(&root, "codex.yml");
    assert_eq!(
        parse_job_ids(&codex_assist),
        vec!["credential-preflight", "codex-assistant", "post-reply"]
    );
    for required in [
        "startsWith(github.event.comment.body, '/codex')",
        r#"contains(fromJSON('["OWNER","MEMBER","COLLABORATOR"]'), github.event.comment.author_association)"#,
        "github.event.comment.user.type != 'Bot'",
        "github.event.sender.type != 'Bot'",
        "needs.credential-preflight.outputs.credential == 'present'",
        "openai/codex-action@86365089eb2b84e0a8fb0717b304f8bdcb13b20e # v1.12",
        "codex-version: \"0.154.0\"",
        "permission-profile: \":read-only\"",
        "safety-strategy: drop-sudo",
        "prompt-file: .github/codex/assist.md",
    ] {
        assert!(
            codex_assist.contains(required),
            "codex.yml missing R86 clause `{required}`"
        );
    }
    let post_reply = codex_assist.split("\n  post-reply:").nth(1).unwrap();
    assert!(
        !post_reply.contains("OPENAI_API_KEY"),
        "codex.yml post-reply job must hold NO model credential (R86)"
    );

    // Muse audit-triage (owner 1b-A): credential-preflight gated on META_MUSE_CI_API_KEY,
    // muse-spark-1.3-contributor, classify_inline_comments: "false".
    let audit_triage = read_workflow(&root, "audit-triage.yml");
    for required in [
        "workflows: [weekly-audit]",
        "github.event.repository.owner.type == 'Organization'",
        "META_MUSE_CI_API_KEY",
        "needs.credential-preflight.outputs.credential == 'present'",
        "ANTHROPIC_BASE_URL: https://api.meta.ai",
        "classify_inline_comments: \"false\"",
        "anthropics/claude-code-action@f3b070c88125d33dbae5653df5f143101d4ea9dc # v1.0.276",
    ] {
        assert!(
            audit_triage.contains(required),
            "audit-triage.yml missing 1b-A clause `{required}`"
        );
    }
    let muse_policy = fs::read_to_string(root.join(".github/muse-audit-triage/policy.json"))
        .expect("read muse policy.json");
    let policy_json: serde_json::Value =
        serde_json::from_str(&muse_policy).expect("valid muse policy.json");
    assert_eq!(policy_json["model"], "muse-spark-1.3-contributor");
    assert_eq!(policy_json["organization"], "smorinlabs");
}

#[test]
fn security_contract_and_freshness_workflows_satisfy_r13_r14_r16_r17_r19_r34_r38_r51_r71() {
    let root = repo_root();

    // R13: dep-audit.yml (weekly-audit, Monday, non-PR, cargo-audit + cargo-deny + osv-scanner)
    let dep_audit = read_workflow(&root, "dep-audit.yml");
    assert!(dep_audit.contains("name: weekly-audit"));
    assert!(!dep_audit.contains("pull_request:"));
    for required in [
        "cron: \"0 5 * * 1\"",
        "cargo-audit@0.22.2",
        "cargo audit --deny warnings",
        "cargo-deny@0.20.2",
        "cargo deny --all-features check",
        "google/osv-scanner-action/osv-scanner-action@a345acffa64b0eaede81a3d9aae6141214d9c8fc # v2.6.0",
    ] {
        assert!(
            dep_audit.contains(required) || dep_audit.contains(&required.replace('"', "'")),
            "dep-audit.yml missing R13 clause `{required}`"
        );
    }

    // R14: large-file-guard.yml calls scripts/check-large-files.sh with no duplicate 1048576.
    let lfg = read_workflow(&root, "large-file-guard.yml");
    assert!(lfg.contains("scripts/check-large-files.sh --range"));
    assert!(
        !lfg.contains("1048576"),
        "large-file-guard.yml must not duplicate the 1048576 threshold (R14 single source of truth)"
    );

    // R16: codeql.yml + .github/codeql/codeql-config.yml
    let codeql_cfg = fs::read_to_string(root.join(".github/codeql/codeql-config.yml"))
        .expect("read codeql-config.yml");
    for required in [
        "uses: security-extended",
        "**/tests/**",
        "**/benches/**",
        "**/fuzz/**",
    ] {
        assert!(
            codeql_cfg.contains(required),
            "codeql-config.yml missing R16 entry `{required}`"
        );
    }
    let codeql = read_workflow(&root, "codeql.yml");
    for required in [
        "github/codeql-action/init@v4.37.9",
        "github/codeql-action/analyze@v4.37.9",
        "languages: rust",
        "build-mode: none",
        "config-file: ./.github/codeql/codeql-config.yml",
    ] {
        assert!(
            codeql.contains(required),
            "codeql.yml missing R16 clause `{required}`"
        );
    }
    assert!(
        !codeql.contains("queries:"),
        "codeql.yml must not pass inline `queries:` on Init step (R16 A3)"
    );

    // R17: secret-scan.yml (TruffleHog CLI v3.97.4 + cosign verify-blob + exit allow-list)
    let secret_scan = read_workflow(&root, "secret-scan.yml");
    for required in [
        "3.97.4",
        "cosign verify-blob",
        "--only-verified",
        "--fail",
        "--fail-on-scan-errors",
        "--github-actions",
        "shell: bash",
    ] {
        assert!(
            secret_scan.contains(required),
            "secret-scan.yml missing R17 clause `{required}`"
        );
    }
    assert!(
        !secret_scan.contains("--since-commit"),
        "secret-scan.yml must scan full history without --since-commit (R17)"
    );

    // R38: commitlint.yml
    let commitlint = read_workflow(&root, "commitlint.yml");
    for required in [
        "merge_group:",
        "crate-ci/committed@faeed42f2e10c244533a01525f13c4d8b6ce383f # v1.1.11",
        "github.event.pull_request.user.login != 'dependabot[bot]'",
        "github.event.pull_request.user.login == 'dependabot[bot]'",
        "--config committed.bot.toml",
        "HEAD~..HEAD^2",
    ] {
        assert!(
            commitlint.contains(required),
            "commitlint.yml missing R38 clause `{required}`"
        );
    }

    // R71: api-contract.yml (no trigger-level paths:, pinned oasdiff v1.32.1 + sha256)
    let api_contract = read_workflow(&root, "api-contract.yml");
    let api_on = api_contract.split("\njobs:").next().unwrap();
    let api_on_code: String = api_on
        .lines()
        .map(|l| l.split('#').next().unwrap_or(""))
        .collect::<Vec<_>>()
        .join("\n");
    assert!(
        !api_on_code.contains("paths:") && !api_on_code.contains("paths-ignore:"),
        "api-contract.yml must not use trigger-level paths: filter (R11/R71)"
    );
    for required in [
        "1.32.1",
        "7c8939fc49b75ee11fec66a5b83b37a2fca6aee109fed85013b1ba2ac2a1ee7f",
        "--allow-external-refs=false",
        "--fail-on ERR",
        "--severity-levels openapi/oasdiff-levels.txt",
        "--err-ignore openapi/breaking-accepted.txt",
        "--test openapi",
    ] {
        assert!(
            api_contract.contains(required),
            "api-contract.yml missing R71 clause `{required}`"
        );
    }

    // R51: docker-web.yml (fail-closed plan, BuildKit, smoke checks, no registry push)
    let docker_web = read_workflow(&root, "docker-web.yml");
    for required in [
        "DOCKER_BUILDKIT=1",
        "--platform linux/amd64",
        "nonroot:nonroot",
        "/healthz",
        "143",
        "Dockerfile",
        ".dockerignore",
    ] {
        assert!(
            docker_web.contains(required),
            "docker-web.yml missing R51 clause `{required}`"
        );
    }
    assert!(
        !docker_web.contains("docker/login-action")
            && !docker_web.contains("docker/build-push-action"),
        "docker-web.yml must not log in or push to a registry (R51; GHCR publish is P11)"
    );

    // R34: canary.yml (3-leg matrix, Tuesday schedule, no PR trigger, no cache, no continue-on-error)
    let canary = read_workflow(&root, "canary.yml");
    assert!(!canary.contains("pull_request:"));
    assert!(!canary.contains("Swatinem/rust-cache"));
    assert!(!canary.contains("continue-on-error:"));
    for required in [
        "CARGO_RESOLVER_INCOMPATIBLE_RUST_VERSIONS",
        "cargo update --verbose",
        "latest-deps",
        "next-toolchain",
        "beta",
        "--locked",
        "timeout-minutes: 30",
        "failure() && github.event_name == 'schedule'",
    ] {
        assert!(
            canary.contains(required),
            "canary.yml missing R34 clause `{required}`"
        );
    }

    // R19: .github/dependabot.yml (2 entries: cargo + github-actions)
    let dependabot =
        fs::read_to_string(root.join(".github/dependabot.yml")).expect("read dependabot.yml");
    let eco_count = dependabot
        .lines()
        .filter(|l| l.trim_start().starts_with("- package-ecosystem:"))
        .count();
    assert_eq!(
        eco_count, 2,
        ".github/dependabot.yml must declare exactly 2 ecosystems (cargo + github-actions)"
    );
    for required in [
        "package-ecosystem: \"cargo\"",
        "package-ecosystem: \"github-actions\"",
        "default-days: 5",
        "open-pull-requests-limit: 5",
        "versioning-strategy: \"increase-if-necessary\"",
        "applies-to: version-updates",
        "patterns: [\"*\"]",
    ] {
        assert!(
            dependabot.contains(required) || dependabot.contains(&required.replace('"', "'")),
            ".github/dependabot.yml missing R19 clause `{required}`"
        );
    }
    assert!(
        !dependabot.contains("labels:") && !dependabot.contains("update-types:"),
        ".github/dependabot.yml must omit `labels` and `update-types` (R19)"
    );
}
