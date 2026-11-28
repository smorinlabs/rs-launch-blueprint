//! Community governance files, R45 PR-template/contributing contract, setup docs,
//! and R47 local `just update-contributors` contract tests (`P12`).
//!
//! Ships to stamped child repositories; assertions remain valid after Template Press
//! rebranding and declared resets/removals.

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
fn community_files_pr_template_and_issue_templates_satisfy_r45_and_r46() {
    let root = repo_root();

    // R45: PR template carries a pre-flight checklist (F203) and NO Review Trigger / bot @-mentions.
    let pr_tpl = read_text(&root, ".github/pull_request_template.md");
    assert!(
        pr_tpl.contains("just check"),
        ".github/pull_request_template.md must reference `just check`"
    );
    assert!(
        pr_tpl.contains("- [ ]"),
        ".github/pull_request_template.md must include a pre-flight checklist (F203)"
    );
    for forbidden in [
        "@claude",
        "@coderabbit",
        "@greptile",
        "@cubic",
        "Review Trigger",
    ] {
        assert!(
            !pr_tpl.contains(forbidden),
            ".github/pull_request_template.md must NOT contain `{forbidden}` (R45)"
        );
    }

    // R45: CONTRIBUTING.md carries "Requesting another review" with all 4 required statements.
    let contributing = read_text(&root, ".github/CONTRIBUTING.md");
    for required in [
        "## Requesting another review",
        "@claude please re-review",
        "ANTHROPIC_API_KEY",
        "CLAUDE_CODE_OAUTH_TOKEN",
        "ANTHROPIC_FEDERATION_RULE_ID",
        "ANTHROPIC_ORGANIZATION_ID",
        "OWNER",
        "MEMBER",
        "COLLABORATOR",
        ".github/workflows/claude.yml",
        "subsequent push",
        "just setup",
        "just check",
        "just debug-info",
    ] {
        assert!(
            contributing.contains(required),
            ".github/CONTRIBUTING.md missing required R45 / contributor clause `{required}`"
        );
    }

    // CODE_OF_CONDUCT.md, SECURITY.md, CODEOWNERS exist with required anchors.
    let coc = read_text(&root, ".github/CODE_OF_CONDUCT.md");
    assert!(
        coc.contains("Contributor Covenant"),
        ".github/CODE_OF_CONDUCT.md must credit Contributor Covenant"
    );

    let security = read_text(&root, ".github/SECURITY.md");
    for required in [
        "## Reporting a Vulnerability",
        "## Code Scanning Setup",
        "code-scanning/default-setup",
    ] {
        assert!(
            security.contains(required),
            ".github/SECURITY.md missing `{required}`"
        );
    }

    let codeowners = read_text(&root, ".github/CODEOWNERS");
    for required in [
        "/.github/workflows/audit-triage.yml",
        "/.github/scripts/muse_audit_triage.py",
        "/.github/muse-audit-triage/",
        "/AGENTS.md",
        "/.github/CODEOWNERS",
    ] {
        assert!(
            codeowners.contains(required),
            ".github/CODEOWNERS missing required path `{required}`"
        );
    }

    // Issue templates (F201, F202): typed bug/feature/docs + config.yml, no R46 license headers.
    let license_markers = [
        concat!("SPDX-License-", "Identifier:"),
        concat!("Permission is hereby granted, ", "free of charge"),
        concat!("Copyright (", "c)"),
    ];
    for rel in [
        ".github/ISSUE_TEMPLATE/bug.yml",
        ".github/ISSUE_TEMPLATE/feature.yml",
        ".github/ISSUE_TEMPLATE/docs.yml",
        ".github/ISSUE_TEMPLATE/config.yml",
    ] {
        let content = read_text(&root, rel);
        assert!(!content.trim().is_empty(), "{rel} must be non-empty");
        for marker in &license_markers {
            assert!(
                !content.contains(marker),
                "{rel} must not carry a per-file license/copyright header (R46)"
            );
        }
    }
    let issue_cfg = read_text(&root, ".github/ISSUE_TEMPLATE/config.yml");
    assert!(
        issue_cfg.contains("blank_issues_enabled: false"),
        ".github/ISSUE_TEMPLATE/config.yml must set blank_issues_enabled: false (F201)"
    );
    let bug_tpl = read_text(&root, ".github/ISSUE_TEMPLATE/bug.yml");
    assert!(
        bug_tpl.contains("just debug-info"),
        ".github/ISSUE_TEMPLATE/bug.yml must instruct reporters to run `just debug-info`"
    );
}

#[test]
fn project_setup_and_post_init_docs_cover_required_human_configuration() {
    let root = repo_root();

    let post_init = read_text(&root, "docs/POST_INIT.md");
    assert!(
        post_init.contains("PROJECT_SETUP.md"),
        "docs/POST_INIT.md must point to PROJECT_SETUP.md"
    );
    assert!(
        post_init.contains("press/press-receipt.toml"),
        "docs/POST_INIT.md must point to press/press-receipt.toml"
    );

    let setup_doc = read_text(&root, "docs/PROJECT_SETUP.md");
    for required in [
        "ci-ok",
        "press-verify",
        "RELEASE_PLEASE_CLIENT_ID",
        "RELEASE_PLEASE_PRIVATE_KEY",
        "RELEASE_PLEASE_APP_TOKEN",
        "CRATES_IO_TRUSTED_PUBLISHING",
        "CRATES_IO_TOKEN",
        "crates-io",
        "ANTHROPIC_API_KEY",
        "CLAUDE_CODE_OAUTH_TOKEN",
        "OPENAI_API_KEY",
        "META_MUSE_CI_API_KEY",
        "CONTRIBUTORS_PLEASE_CLIENT_ID",
        "CONTRIBUTORS_PLEASE_PRIVATE_KEY",
        "CONTRIBUTORS_PLEASE_PAT",
        "GITHUB_TOKEN",
        "GitHub Pages",
        "GHCR",
        "code-scanning/default-setup",
        "allow_squash_merge=false",
        "just setup",
        "just check",
        "just update-contributors",
    ] {
        assert!(
            setup_doc.contains(required),
            "docs/PROJECT_SETUP.md missing required setup checklist item `{required}`"
        );
    }
}

#[test]
fn justfile_update_contributors_recipe_satisfies_r47() {
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
    assert!(
        recipes.contains(&"update-contributors"),
        "Justfile missing `update-contributors` recipe (R47); found: {recipes:?}"
    );

    let justfile = read_text(&root, "Justfile");
    for required in [
        "contributors-please@1.4.3",
        "alias contributors := update-contributors",
        "update-contributors:",
        "render --config-file",
        "init --non-interactive",
        "GITHUB_SERVER_URL",
        ".contributors.yml",
        ".contributors.jsonl",
    ] {
        assert!(
            justfile.contains(required),
            "Justfile missing R47 contributors clause `{required}`"
        );
    }

    // R47: shebang recipe must NOT carry a leading `@` prefix (just echoes the script body).
    assert!(
        !justfile.contains("@update-contributors:"),
        "Justfile `update-contributors` shebang recipe must not use `@` prefix (R47)"
    );
}
