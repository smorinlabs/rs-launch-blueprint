//! Repository hygiene and configuration consistency meta-tests (P05).
//!
//! Covers:
//! - F160 / R38: `committed.toml`, `committed.bot.toml`, and `.gitmessage` consistency
//! - F161 / R37: `lefthook.yml` structure, pin, and `tags: [compiles]` contract
//! - R29: `dprint.json` checksum-pinned Wasm plugins and release-please excludes
//! - R31: `sgconfig.yml` and 5 template-owned security rules + test fixtures
//! - R39: `.gitleaks.toml` and `.gitleaksignore` clean baseline
//! - R40: `.editorconfig`, `.editorconfig-checker.json`, `.yamllint`, and `typos.toml`
//! - R43: hub-only AI config (`AGENTS.md`, `CLAUDE.md`, `.claude/settings.json`, no vendor dirs)
//! - R44: digest-pinned image-only `.devcontainer/` and `.vscode/` config (R28)

use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::PathBuf;
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

/// Extract a TOML string array assigned to `key = [...]` (single-line or multi-line).
fn parse_toml_string_array(text: &str, key: &str) -> Result<Vec<String>, String> {
    let mut collecting = false;
    let mut buf = String::new();
    for line in text.lines() {
        let code = line.split('#').next().unwrap_or("").trim();
        if !collecting {
            if let Some(rest) = code.strip_prefix(key) {
                let rest = rest.trim_start();
                if let Some(after_eq) = rest.strip_prefix('=') {
                    let after_eq = after_eq.trim_start();
                    if after_eq.starts_with('[') {
                        collecting = true;
                        buf.push_str(after_eq);
                        if after_eq.contains(']') {
                            break;
                        }
                    }
                }
            }
        } else {
            buf.push(' ');
            buf.push_str(code);
            if code.contains(']') {
                break;
            }
        }
    }
    if !collecting {
        return Err(format!("key `{key}` not found"));
    }
    let start = buf
        .find('[')
        .ok_or_else(|| format!("missing '[' for `{key}`"))?;
    let end = buf
        .rfind(']')
        .ok_or_else(|| format!("missing ']' for `{key}`"))?;
    let inner = &buf[start + 1..end];
    let mut items = Vec::new();
    for part in inner.split(',') {
        let trimmed = part.trim();
        if trimmed.is_empty() {
            continue;
        }
        let unquoted = trimmed
            .strip_prefix('"')
            .and_then(|s| s.strip_suffix('"'))
            .ok_or_else(|| format!("expected double-quoted element in `{key}`, got `{trimmed}`"))?;
        items.push(unquoted.to_owned());
    }
    Ok(items)
}

/// Extract a scalar `key = value` line from a flat TOML file.
fn parse_toml_scalar(text: &str, key: &str) -> Option<String> {
    for line in text.lines() {
        let code = line.split('#').next().unwrap_or("").trim();
        if let Some(rest) = code.strip_prefix(key) {
            let rest = rest.trim_start();
            if let Some(after_eq) = rest.strip_prefix('=') {
                return Some(after_eq.trim().to_owned());
            }
        }
    }
    None
}

/// Strip `//` line comments outside double-quoted strings for JSONC parsing.
fn strip_jsonc_comments(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    for line in input.lines() {
        let mut in_string = false;
        let mut escaped = false;
        let bytes = line.as_bytes();
        let mut i = 0;
        while i < bytes.len() {
            let b = bytes[i];
            if in_string {
                if escaped {
                    escaped = false;
                } else if b == b'\\' {
                    escaped = true;
                } else if b == b'"' {
                    in_string = false;
                }
                i += 1;
            } else if b == b'"' {
                in_string = true;
                i += 1;
            } else if b == b'/' && bytes.get(i + 1) == Some(&b'/') {
                break;
            } else {
                i += 1;
            }
        }
        out.push_str(&line[..i]);
        out.push('\n');
    }
    out
}

#[test]
fn committed_configs_and_gitmessage_share_one_convention_f160() {
    let root = repo_root();
    let main_toml = fs::read_to_string(root.join("committed.toml")).expect("read committed.toml");
    let bot_toml =
        fs::read_to_string(root.join("committed.bot.toml")).expect("read committed.bot.toml");
    let gitmessage = fs::read_to_string(root.join(".gitmessage")).expect("read .gitmessage");

    let expected_types: Vec<String> = [
        "build", "chore", "ci", "docs", "feat", "fix", "perf", "refactor", "revert", "style",
        "test",
    ]
    .into_iter()
    .map(str::to_owned)
    .collect();

    let main_types =
        parse_toml_string_array(&main_toml, "allowed_types").expect("parse main allowed_types");
    let bot_types =
        parse_toml_string_array(&bot_toml, "allowed_types").expect("parse bot allowed_types");

    assert_eq!(main_types, expected_types, "committed.toml allowed_types");
    assert_eq!(
        bot_types, main_types,
        "committed.bot.toml allowed_types must match committed.toml exactly"
    );

    let types_line = gitmessage
        .lines()
        .find_map(|line| line.strip_prefix("# Types:"))
        .expect(".gitmessage must contain a `# Types:` line");
    let gitmessage_types: Vec<String> = types_line
        .split(',')
        .map(|s| s.trim().to_owned())
        .filter(|s| !s.is_empty())
        .collect();
    assert_eq!(
        gitmessage_types, main_types,
        ".gitmessage `# Types:` must match committed.toml allowed_types in order"
    );

    // .gitmessage must be comment-only so an unedited template aborts the commit.
    for (idx, line) in gitmessage.lines().enumerate() {
        assert!(
            line.trim().is_empty() || line.starts_with('#'),
            ".gitmessage line {} must be a comment or blank",
            idx + 1
        );
    }

    // Scalar rules in committed.toml
    assert_eq!(
        parse_toml_scalar(&main_toml, "style").as_deref(),
        Some("\"conventional\"")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "subject_length").as_deref(),
        Some("50")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "line_length").as_deref(),
        Some("72")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "subject_capitalized").as_deref(),
        Some("false")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "subject_not_punctuated").as_deref(),
        Some("true")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "imperative_subject").as_deref(),
        Some("false")
    );
    assert_eq!(
        parse_toml_scalar(&main_toml, "merge_commit").as_deref(),
        Some("false")
    );
    assert!(
        parse_toml_scalar(&main_toml, "ignore_author_re").is_none(),
        "committed.toml must never set ignore_author_re (R38)"
    );
    assert!(
        matches!(
            parse_toml_scalar(&main_toml, "hard_line_length").as_deref(),
            None | Some("0")
        ),
        "committed.toml hard_line_length must be unset or 0 (R38)"
    );

    // Scalar rules in committed.bot.toml: widths relaxed (0), everything else equal.
    assert_eq!(
        parse_toml_scalar(&bot_toml, "style"),
        parse_toml_scalar(&main_toml, "style")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "subject_length").as_deref(),
        Some("0")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "line_length").as_deref(),
        Some("0")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "subject_capitalized"),
        parse_toml_scalar(&main_toml, "subject_capitalized")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "subject_not_punctuated"),
        parse_toml_scalar(&main_toml, "subject_not_punctuated")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "imperative_subject"),
        parse_toml_scalar(&main_toml, "imperative_subject")
    );
    assert_eq!(
        parse_toml_scalar(&bot_toml, "merge_commit"),
        parse_toml_scalar(&main_toml, "merge_commit")
    );
    assert!(
        parse_toml_scalar(&bot_toml, "ignore_author_re").is_none(),
        "committed.bot.toml must never set ignore_author_re (R38)"
    );
    assert!(
        matches!(
            parse_toml_scalar(&bot_toml, "hard_line_length").as_deref(),
            None | Some("0")
        ),
        "committed.bot.toml hard_line_length must be unset or 0 (R38)"
    );

    // .gitmessage documents the exact caps configured in committed.toml
    assert!(gitmessage.contains("maximum of 50"));
    assert!(gitmessage.contains("Limit the subject line to 50"));
    assert!(gitmessage.contains("Wrap the body and footer at 72"));
}

#[test]
fn lefthook_config_satisfies_r37_and_f161() {
    let root = repo_root();
    let text = fs::read_to_string(root.join("lefthook.yml")).expect("read lefthook.yml");

    for required in [
        "min_version: 2.1.14",
        "assert_lefthook_installed: true",
        "pre-commit:",
        "parallel: true",
        "commit-msg:",
        "pre-push:",
        "tags: [compiles]",
        "cargo fmt --all --check",
        "dprint check --allow-no-files",
        "ast-grep scan --error",
        "scripts/check-large-files.sh --staged",
        "scripts/check-cargo-lock.sh",
        "gitleaks git --pre-commit --staged --no-banner --redact --config .gitleaks.toml .",
        "gitleaks git --no-banner --redact --config .gitleaks.toml --log-opts=\"--branches --tags HEAD --not --remotes\" .",
        "committed --fixup --wip --commit-file {1}",
        "editorconfig-checker",
        "ryl",
        "typos --force-exclude",
        "actionlint",
        "RS_PROJECTS_PREPUSH_TESTS",
    ] {
        assert!(
            text.contains(required),
            "lefthook.yml missing required R37/R27/R28/R29/R31/R32/R38/R39/R40/R41/R14 entry `{required}`"
        );
    }

    // Interim .githooks/pre-commit is replaced by lefthook.yml.
    assert!(
        !root.join(".githooks/pre-commit").exists(),
        "interim .githooks/pre-commit must be removed once lefthook.yml is active"
    );

    // Validate lefthook.yml syntax directly with lefthook if installed on PATH.
    let status = Command::new("lefthook")
        .arg("validate")
        .current_dir(&root)
        .status()
        .expect("lefthook validate must execute");
    assert!(status.success(), "lefthook validate failed");
}

#[test]
fn dprint_and_auxiliary_hygiene_configs_match_r29_r39_r40() {
    let root = repo_root();

    // R29: dprint.json has 4 checksum-pinned Wasm plugins and release-please excludes.
    let dprint = fs::read_to_string(root.join("dprint.json")).expect("read dprint.json");
    assert!(dprint.contains("\"lineWidth\": 100"));
    assert!(dprint.contains("\"indentWidth\": 4"));
    for exclude in ["**/target", "CHANGELOG.md", ".release-please-manifest.json"] {
        assert!(
            dprint.contains(exclude),
            "dprint.json missing required exclude `{exclude}`"
        );
    }
    let pinned_plugins = [
        "https://plugins.dprint.dev/toml-0.8.0.wasm@69cb40cba5e8a53560ccea7fdced073a55d04eb05492f0d9b877f916b976945d",
        "https://plugins.dprint.dev/json-0.24.0.wasm@07316f98ceda3761d31569795d82b8a104cb078e54e46fb542c2a81728bc48f1",
        "https://plugins.dprint.dev/markdown-0.24.0.wasm@cf7e65674b7eb5d91f85152ae9020dc8b3e73bd7944efcbfb05df71081217764",
        "https://plugins.dprint.dev/g-plane/pretty_yaml-v0.6.0.wasm@40a2fdda7040317eb1b23520f3a00769a5571eedb049c4ca9175c1b9eeba01ae",
    ];
    for plugin in pinned_plugins {
        assert!(
            dprint.contains(plugin),
            "dprint.json missing checksum-pinned plugin `{plugin}`"
        );
    }

    // R40: .editorconfig, .editorconfig-checker.json, .yamllint, typos.toml
    let editorconfig = fs::read_to_string(root.join(".editorconfig")).expect("read .editorconfig");
    for token in [
        "root = true",
        "end_of_line = lf",
        "insert_final_newline = true",
        "[Makefile]",
        "indent_style = tab",
        "[*.md]",
        "[*.snap]",
        "trim_trailing_whitespace = false",
    ] {
        assert!(
            editorconfig.contains(token),
            ".editorconfig missing `{token}`"
        );
    }
    assert!(
        !editorconfig.contains("[*.ambr]"),
        ".editorconfig must replace Python [*.ambr] with Rust [*.snap]"
    );

    let ec_json = fs::read_to_string(root.join(".editorconfig-checker.json"))
        .expect("read .editorconfig-checker.json");
    assert!(ec_json.contains("\"Version\": \"v4.0.2\""));
    assert!(ec_json.contains("\"Indentation\": true"));
    assert!(ec_json.contains("\"IndentSize\": true"));

    let yamllint = fs::read_to_string(root.join(".yamllint")).expect("read .yamllint");
    assert!(yamllint.contains("extends: default"));
    assert!(yamllint.contains("level: error"));
    assert!(yamllint.contains("min-spaces-from-content: 1"));

    let typos = fs::read_to_string(root.join("typos.toml")).expect("read typos.toml");
    assert!(typos.contains("ignore-hidden = false"));
    assert!(typos.contains(".git/"));

    // R39: .gitleaks.toml and .gitleaksignore
    let gitleaks = fs::read_to_string(root.join(".gitleaks.toml")).expect("read .gitleaks.toml");
    assert!(gitleaks.contains("[extend]"));
    assert!(gitleaks.contains("useDefault = true"));
    // No active broad path allowlist (docs/ or *.md) shipped by default.
    for line in gitleaks.lines() {
        let code = line.split('#').next().unwrap_or("").trim();
        assert!(
            !code.starts_with("paths") && !code.starts_with("[[allowlists]]"),
            ".gitleaks.toml must not ship active path allowlists by default (R39): `{line}`"
        );
    }
    let gitleaksignore =
        fs::read_to_string(root.join(".gitleaksignore")).expect("read .gitleaksignore");
    for (idx, line) in gitleaksignore.lines().enumerate() {
        assert!(
            line.trim().is_empty() || line.starts_with('#'),
            ".gitleaksignore baseline must be header-only (line {}): `{line}`",
            idx + 1
        );
    }

    // R14: .gitattributes documents large-file-ok without active exemptions.
    let gitattributes =
        fs::read_to_string(root.join(".gitattributes")).expect("read .gitattributes");
    assert!(gitattributes.contains("large-file-ok"));
    for line in gitattributes.lines() {
        let code = line.split('#').next().unwrap_or("").trim();
        assert!(
            !code.contains("large-file-ok"),
            ".gitattributes must not ship active large-file-ok entries at baseline (R14)"
        );
    }
}

#[test]
fn ai_furniture_matches_r43_hub_and_announcement_contract() {
    let root = repo_root();

    // A1: AGENTS.md at root; CLAUDE.md imports @AGENTS.md with no duplicate policy.
    let agents = fs::read_to_string(root.join("AGENTS.md")).expect("read AGENTS.md");
    assert!(agents.contains("just check"));
    assert!(agents.contains("just security"));
    assert!(agents.contains("just setup"));

    let claude = fs::read_to_string(root.join("CLAUDE.md")).expect("read CLAUDE.md");
    assert_eq!(
        claude.trim(),
        "@AGENTS.md",
        "CLAUDE.md must be a thin @AGENTS.md import with no independent policy statements (F197)"
    );

    // A2: Zero tracked paths under .cursor/, .windsurf/, or .devin/.
    let out = Command::new("git")
        .args(["ls-files", "--", ".cursor", ".windsurf", ".devin"])
        .current_dir(&root)
        .output()
        .expect("git ls-files must execute");
    assert!(out.status.success());
    let tracked = String::from_utf8_lossy(&out.stdout);
    assert!(
        tracked.trim().is_empty(),
        "R43 forbids vendor AI rule directories (.cursor/, .windsurf/, .devin/): found `{tracked}`"
    );

    // A3, A4a, A4b: .claude/settings.json has exactly one companyAnnouncements string,
    // names rs-launch-blueprint and `just --list`, avoids raw `cargo ` commands,
    // and every `just <recipe>` token appears in `just --summary`.
    let settings =
        fs::read_to_string(root.join(".claude/settings.json")).expect("read .claude/settings.json");
    let key_idx = settings
        .find("\"companyAnnouncements\"")
        .expect(".claude/settings.json must contain companyAnnouncements");
    let after_key = &settings[key_idx..];
    let arr_start = after_key.find('[').expect("companyAnnouncements array '['");
    let arr_end = after_key.find(']').expect("companyAnnouncements array ']'");
    let arr_body = &after_key[arr_start + 1..arr_end];

    let mut entries = Vec::new();
    let mut cur = String::new();
    let mut in_str = false;
    let mut esc = false;
    for ch in arr_body.chars() {
        if in_str {
            if esc {
                cur.push(ch);
                esc = false;
            } else if ch == '\\' {
                esc = true;
            } else if ch == '"' {
                in_str = false;
                entries.push(std::mem::take(&mut cur));
            } else {
                cur.push(ch);
            }
        } else if ch == '"' {
            in_str = true;
        }
    }
    assert_eq!(
        entries.len(),
        1,
        "R43 A3 requires companyAnnouncements to contain exactly 1 string, found {}",
        entries.len()
    );
    let announcement = &entries[0];
    assert!(
        announcement.contains("rs-launch-blueprint"),
        "R43 A4a: announcement must name rs-launch-blueprint"
    );
    assert!(
        announcement.contains("just --list"),
        "R43: announcement must point to `just --list`"
    );
    assert!(
        announcement.contains("AGENTS.md"),
        "R43: announcement must point to AGENTS.md"
    );
    assert!(
        !announcement.contains("cargo "),
        "R43 forbids raw `cargo ` commands in companyAnnouncements: `{announcement}`"
    );

    let summary_out = Command::new("just")
        .arg("--summary")
        .current_dir(&root)
        .output()
        .expect("just --summary must execute");
    assert!(summary_out.status.success());
    let summary_text = String::from_utf8_lossy(&summary_out.stdout);
    let valid_recipes: Vec<&str> = summary_text.split_whitespace().collect();

    let tokens: Vec<&str> = announcement.split_whitespace().collect();
    let mut named_recipes = 0usize;
    for pair in tokens.windows(2) {
        if pair[0] == "just" {
            let candidate =
                pair[1].trim_matches(|c: char| matches!(c, ',' | '.' | ';' | ':' | '(' | ')'));
            if candidate.starts_with('-') {
                continue;
            }
            named_recipes += 1;
            assert!(
                valid_recipes.contains(&candidate),
                "R43 A4b: announcement names `just {candidate}` which is not in `just --summary` ({valid_recipes:?})"
            );
        }
    }
    assert!(
        named_recipes >= 1,
        "R43 A4a: announcement must name at least one `just <recipe>`"
    );
}

#[test]
fn devcontainer_and_vscode_configs_match_r44_and_r28() {
    let root = repo_root();

    // R44: digest-pinned image-only devcontainer with trailing tag comment, no features/customizations.
    let dc_raw = fs::read_to_string(root.join(".devcontainer/devcontainer.json"))
        .expect("read .devcontainer/devcontainer.json");
    assert!(
        dc_raw.contains("mcr.microsoft.com/devcontainers/rust:2.1.1-trixie@sha256:1648c1ac19ef6b55a001048d832956c109a5a9ad37fc6b3c82d37b6cd462bbf3"),
        "devcontainer.json must pin mcr.microsoft.com/devcontainers/rust:2.1.1-trixie by index digest (R44)"
    );
    assert!(
        dc_raw.lines().any(|l| {
            l.contains("\"image\"") && l.contains("@sha256:") && l.contains("// 2.1.1-trixie")
        }),
        "devcontainer.json image line must carry trailing `// 2.1.1-trixie` tag comment (R44)"
    );
    let dc_json = strip_jsonc_comments(&dc_raw);
    assert!(
        !dc_json.contains("\"features\""),
        "devcontainer.json must not declare a features block (R44)"
    );
    assert!(
        !dc_json.contains("\"customizations\""),
        "devcontainer.json must not declare a customizations block (R44)"
    );
    assert!(
        !dc_json.contains("\"extensions\""),
        "devcontainer.json must not declare an extensions array (R44/F193)"
    );
    assert!(
        !root.join(".devcontainer/Dockerfile").exists(),
        "R44 is image-only: no .devcontainer/Dockerfile"
    );

    let post_create_path = root.join(".devcontainer/post-create.sh");
    let post_create = fs::read_to_string(&post_create_path).expect("read post-create.sh");
    let mode = fs::metadata(&post_create_path)
        .expect("stat post-create.sh")
        .permissions()
        .mode();
    assert!(
        mode & 0o111 != 0,
        ".devcontainer/post-create.sh must be executable (0755)"
    );
    assert!(post_create.contains("rustup toolchain install"));
    assert!(post_create.contains("make bootstrap"));
    assert!(post_create.contains("just setup"));
    for line in post_create.lines() {
        let code = line.split('#').next().unwrap_or("");
        assert!(
            !code.contains("apt-get"),
            ".devcontainer/post-create.sh must not invoke apt-get (R44)"
        );
    }

    // R28: .vscode/settings.json, extensions.json, launch.json
    let settings =
        fs::read_to_string(root.join(".vscode/settings.json")).expect("read .vscode/settings.json");
    assert!(settings.contains("\"rust-analyzer.check.command\": \"clippy\""));

    let extensions = fs::read_to_string(root.join(".vscode/extensions.json"))
        .expect("read .vscode/extensions.json");
    assert!(extensions.contains("\"rust-lang.rust-analyzer\""));
    assert!(extensions.contains("\"vadimcn.vscode-lldb\""));

    let launch =
        fs::read_to_string(root.join(".vscode/launch.json")).expect("read .vscode/launch.json");
    assert!(launch.contains("\"type\": \"lldb\""));
    assert!(launch.contains("\"rslbp\""));
}
