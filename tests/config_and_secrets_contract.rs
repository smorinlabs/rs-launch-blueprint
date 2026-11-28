//! Contract tests for `Paths` (`R57`), layered TOML config (`R52`–`R55`), and secret policy (`R56`).

use std::ffi::OsStr;
use std::fs;
use std::num::NonZeroU32;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use rs_launch_blueprint_core::{
    AuthError, ColorPreference, ConfigDiscoveryInputs, ConfigError, ConfigOverrides,
    ConfigWarningKind, CredentialStore, ErrorCode, Exit, FileCredentialStore, FileLogFormat,
    LogLevel, MERGE_STRATEGY_DOC, OutputFormat, PRECEDENCE_CHAIN_DOC, Paths, PermissionCheck,
    TOOL_NAME, Token, TokenResolutionInputs, TokenSource, UnvalidatedConfig,
    discover_project_config_file, discover_system_config_files, inspect_file_permissions,
    load_config, merge_tables_recursive, resolve_token, set_config_value,
};

static NEXT_TEMP: AtomicU64 = AtomicU64::new(0);

struct TempDir {
    path: PathBuf,
}

impl TempDir {
    fn new(label: &str) -> Self {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock")
            .as_nanos();
        let seq = NEXT_TEMP.fetch_add(1, Ordering::Relaxed);
        let path = std::env::temp_dir().join(format!(
            "rslbp-p06-{label}-{}-{nanos}-{seq}",
            std::process::id()
        ));
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

fn write_file(path: &Path, content: &str) {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).expect("create parent dirs");
    }
    fs::write(path, content).expect("write file");
}

#[test]
fn paths_namespaces_four_xdg_dirs_without_creating_them() {
    let tmp = TempDir::new("paths");
    let home = tmp.path().join("fresh-home");

    let paths = Paths::from_roots(
        home.join(".config"),
        home.join(".local/share"),
        home.join(".local/state"),
        home.join(".cache"),
    );

    assert_eq!(TOOL_NAME, "rslbp");
    assert_eq!(paths.config_dir(), home.join(".config/rslbp"));
    assert_eq!(paths.data_dir(), home.join(".local/share/rslbp"));
    assert_eq!(paths.state_dir(), home.join(".local/state/rslbp"));
    assert_eq!(paths.cache_dir(), home.join(".cache/rslbp"));

    assert_eq!(
        paths.config_file(),
        home.join(".config/rslbp/rslbp_config.toml")
    );
    assert_eq!(
        paths.credentials_file(),
        home.join(".local/state/rslbp/credentials.toml")
    );
    assert_eq!(paths.log_file(), home.join(".local/state/rslbp/rslbp.log"));
    assert_eq!(
        paths.crash_log_file(),
        home.join(".local/state/rslbp/rslbp_crash.jsonl")
    );

    // Resolution is pure: creates zero directories on disk (R57 B5).
    assert!(!home.exists(), "Paths must never create directories");
}

#[test]
fn precedence_chain_and_merge_strategy_docs_are_pinned_verbatim() {
    for required in [
        "1. Command-line flags",
        "2. Environment variables",
        "3. Project/local config file",
        "4. User config file",
        "5. System config file",
        "6. Built-in defaults",
    ] {
        assert!(
            PRECEDENCE_CHAIN_DOC.contains(required),
            "PRECEDENCE_CHAIN_DOC missing `{required}` (R54 AC9)"
        );
    }
    assert!(
        MERGE_STRATEGY_DOC.contains("recursively")
            && MERGE_STRATEGY_DOC.contains("replace")
            && MERGE_STRATEGY_DOC.contains("nearer"),
        "MERGE_STRATEGY_DOC must state recursive table merge and scalar/array replacement (R54 AC11)"
    );
}

#[test]
fn system_config_dirs_honours_order_ignores_relative_and_falls_back_to_etc_xdg() {
    let tmp = TempDir::new("sysdirs");
    let first = tmp.path().join("sys1");
    let second = tmp.path().join("sys2");
    let joined = std::env::join_paths([
        PathBuf::from("relative/ignored"),
        first.clone(),
        second.clone(),
    ])
    .expect("join paths");

    let dirs = discover_system_config_files(Some(&joined));
    assert_eq!(
        dirs,
        vec![
            first.join("rslbp/rslbp_config.toml"),
            second.join("rslbp/rslbp_config.toml"),
        ]
    );

    // Unset, empty, or relative-only falls back to /etc/xdg.
    assert_eq!(
        discover_system_config_files(None),
        vec![PathBuf::from("/etc/xdg/rslbp/rslbp_config.toml")]
    );
    assert_eq!(
        discover_system_config_files(Some(OsStr::new(""))),
        vec![PathBuf::from("/etc/xdg/rslbp/rslbp_config.toml")]
    );
    assert_eq!(
        discover_system_config_files(Some(OsStr::new("rel/only"))),
        vec![PathBuf::from("/etc/xdg/rslbp/rslbp_config.toml")]
    );
}

#[test]
fn project_discovery_walks_up_stops_at_git_dir_or_file_and_workspace_cargo_toml() {
    // Case 1: Workspace root Cargo.toml with [workspace] + nested member Cargo.toml (R54 AC7b).
    let tmp = TempDir::new("proj-ws");
    let root = tmp.path().join("repo");
    let member_src = root.join("crates/foo/src");
    fs::create_dir_all(&member_src).expect("mkdir member_src");
    write_file(
        &root.join("Cargo.toml"),
        "[workspace]\nmembers = [\"crates/*\"]\n",
    );
    write_file(
        &root.join("crates/foo/Cargo.toml"),
        "[package]\nname = \"foo\"\n",
    );
    let root_cfg = root.join(".rslbp/rslbp_config.toml");
    write_file(&root_cfg, "[output]\nformat = \"json\"\n");

    assert_eq!(
        discover_project_config_file(&member_src),
        Some(root_cfg),
        "must not stop at member Cargo.toml without [workspace]"
    );

    // Case 2: `.git` as a directory blocks parent config above boundary (R54 AC7).
    let tmp2 = TempDir::new("proj-git-dir");
    let outer = tmp2.path().join("outer");
    write_file(
        &outer.join(".rslbp/rslbp_config.toml"),
        "[output]\nformat = \"name\"\n",
    );
    let inner = outer.join("inner");
    fs::create_dir_all(inner.join(".git")).expect("mkdir .git");
    let sub = inner.join("a/b");
    fs::create_dir_all(&sub).expect("mkdir sub");
    assert_eq!(
        discover_project_config_file(&sub),
        None,
        ".git directory boundary must block config in parent above boundary"
    );

    // Case 3: `.git` as a file (git worktree) — found at boundary, blocked above boundary.
    let tmp3 = TempDir::new("proj-git-file");
    let parent = tmp3.path().join("parent");
    write_file(
        &parent.join(".rslbp/rslbp_config.toml"),
        "[output]\nformat = \"name\"\n",
    );
    let wt = parent.join("worktree");
    fs::create_dir_all(wt.join("sub")).expect("mkdir wt/sub");
    write_file(&wt.join(".git"), "gitdir: /some/path/.git/worktrees/wt\n");
    assert_eq!(
        discover_project_config_file(&wt.join("sub")),
        None,
        ".git file must block config above worktree root"
    );
    let wt_cfg = wt.join(".rslbp/rslbp_config.toml");
    write_file(&wt_cfg, "[output]\nformat = \"markdown\"\n");
    assert_eq!(
        discover_project_config_file(&wt.join("sub")),
        Some(wt_cfg),
        ".git file boundary stop must be inclusive of the worktree root"
    );
}

#[test]
fn six_rung_precedence_and_recursive_merge_work_end_to_end() {
    let tmp = TempDir::new("six-rungs");
    let sys1 = tmp.path().join("sys1");
    let sys2 = tmp.path().join("sys2");
    let home = tmp.path().join("home");
    let project = tmp.path().join("proj");
    fs::create_dir_all(project.join(".git")).expect("mkdir .git");

    // Rung 5: two system tiers — sys1 outranks sys2 (R54 AC2).
    write_file(
        &sys2.join("rslbp/rslbp_config.toml"),
        "[output]\nformat = \"name\"\ncolor = \"never\"\nlimit = 10\n[logging]\nlevel = \"error\"\n",
    );
    write_file(
        &sys1.join("rslbp/rslbp_config.toml"),
        "[output]\nformat = \"markdown\"\nlimit = 20\n",
    );

    // Rung 4: user tier overrides format, leaves color from sys2 and limit from sys1.
    let paths = Paths::from_roots(
        home.join("config"),
        home.join("data"),
        home.join("state"),
        home.join("cache"),
    );
    write_file(
        &paths.config_file(),
        "[output]\nformat = \"json\"\n[logging]\nfile-format = \"json\"\n",
    );

    // Rung 3: project tier overrides only `output.limit`, preserving user's `output.format` (recursive merge!).
    write_file(
        &project.join(".rslbp/rslbp_config.toml"),
        "[output]\nlimit = 50\n",
    );

    let xdg_dirs = std::env::join_paths([&sys1, &sys2]).expect("join sys dirs");
    let loaded = load_config(&ConfigDiscoveryInputs {
        explicit_flag: None,
        explicit_env: Some(OsStr::new("")), // empty env ignored (F242)
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect("load_config");

    assert!(
        loaded.warnings.is_empty(),
        "warnings: {:?}",
        loaded.warnings
    );
    let cfg = loaded.config.as_config();
    assert_eq!(cfg.output.format, OutputFormat::Json); // from user
    assert_eq!(cfg.output.color, ColorPreference::Never); // from sys2
    assert_eq!(cfg.output.limit, NonZeroU32::new(50)); // from project
    assert_eq!(cfg.logging.level, LogLevel::Error); // from sys2
    assert_eq!(cfg.logging.file_format, FileLogFormat::Json); // from user

    // Explicit --config replaces ALL discovered layers (R54 AC4).
    let explicit = tmp.path().join("explicit.toml");
    write_file(&explicit, "[output]\nformat = \"name\"\n");
    let loaded_explicit = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&explicit),
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect("load explicit");
    let ecfg = loaded_explicit.config.as_config();
    assert_eq!(ecfg.output.format, OutputFormat::Name);
    assert_eq!(
        ecfg.output.limit, None,
        "project limit must be invisible under --config"
    );
    assert_eq!(
        ecfg.output.color,
        ColorPreference::Auto,
        "sys2 color must be invisible"
    );

    // Rung 2 (env) and Rung 1 (flags) layer above explicit/discovered config.
    let with_env = loaded_explicit.config.apply_overrides(&ConfigOverrides {
        output_format: Some(OutputFormat::Markdown),
        ..ConfigOverrides::default()
    });
    assert_eq!(with_env.as_config().output.format, OutputFormat::Markdown);
    let with_flag = with_env.apply_overrides(&ConfigOverrides {
        output_format: Some(OutputFormat::Json),
        ..ConfigOverrides::default()
    });
    assert_eq!(with_flag.as_config().output.format, OutputFormat::Json);
}

#[test]
fn recursive_merge_replaces_arrays_and_scalars_wholesale() {
    let mut base: toml::Table =
        toml::from_str("items = [\"a\", \"b\"]\n[nested.deep]\nkeep = 1\noverride_me = \"old\"\n")
            .expect("base");
    let overlay: toml::Table =
        toml::from_str("items = [\"c\"]\n[nested.deep]\noverride_me = \"new\"\n").expect("overlay");
    merge_tables_recursive(&mut base, overlay);

    assert_eq!(
        base["items"].as_array().expect("items array"),
        &[toml::Value::String("c".to_owned())]
    );
    assert_eq!(base["nested"]["deep"]["keep"].as_integer(), Some(1));
    assert_eq!(base["nested"]["deep"]["override_me"].as_str(), Some("new"));
}

#[test]
fn validation_aggregates_all_bad_keys_deterministically_and_catches_non_table_section() {
    let raw = r#"
[output]
format = "yaml"
limit = 0
color = "rainbow"
extra_key = true
"#;
    let table: toml::Table = toml::from_str(raw).expect("parse table");
    let report = UnvalidatedConfig::from_table(table).validate();

    // Deterministic sorted key order (BTreeMap-backed toml::Table).
    let issue_paths: Vec<&str> = report.issues.iter().map(|i| i.path.as_str()).collect();
    assert_eq!(
        issue_paths,
        vec!["output.color", "output.format", "output.limit"]
    );
    assert_eq!(report.unknown_keys, vec!["output.extra_key"]);

    // R55 R8a/R8b: section key that is not a table MUST be reported, never silently defaulted.
    let bad_section: toml::Table = toml::from_str("output = 5\n").expect("parse table");
    let sec_report = UnvalidatedConfig::from_table(bad_section).validate();
    assert_eq!(sec_report.issues.len(), 1);
    assert_eq!(sec_report.issues[0].path, "output");
}

#[test]
fn error_tolerance_preserves_lower_tier_values_and_handles_explicit_faults() {
    let tmp = TempDir::new("tolerance");
    let sys = tmp.path().join("sys");
    let home = tmp.path().join("home");
    let project = tmp.path().join("proj");
    fs::create_dir_all(project.join(".git")).expect("mkdir .git");

    let paths = Paths::from_roots(
        home.join("config"),
        home.join("data"),
        home.join("state"),
        home.join("cache"),
    );

    // R54 AC12a / R55 F238: invalid project leaf falls back to USER value, sibling keeps project value.
    write_file(
        &sys.join("rslbp/rslbp_config.toml"),
        "[logging]\nlevel = \"info\"\n",
    );
    write_file(&paths.config_file(), "[output]\nformat = \"json\"\n");
    write_file(
        &project.join(".rslbp/rslbp_config.toml"),
        "token = \"sk_live_MUST_NOT_LEAK\"\n[output]\nformat = \"invalid-fmt\"\ncolor = \"never\"\nunknown_leaf = 42\n",
    );

    let xdg_dirs = std::env::join_paths([&sys]).expect("join");
    let loaded = load_config(&ConfigDiscoveryInputs {
        explicit_flag: None,
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect("discovered faults must tolerate");

    let cfg = loaded.config.as_config();
    assert_eq!(
        cfg.output.format,
        OutputFormat::Json,
        "must fall back to user tier value, not built-in Table default"
    );
    assert_eq!(
        cfg.output.color,
        ColorPreference::Never,
        "valid sibling in project tier must survive"
    );
    assert_eq!(cfg.logging.level, LogLevel::Info);

    assert_eq!(loaded.warnings.len(), 3, "warnings: {:?}", loaded.warnings);
    for w in &loaded.warnings {
        let rendered = w.to_string();
        assert!(
            !rendered.contains("sk_live_MUST_NOT_LEAK"),
            "warning must NEVER leak secret bytes: {rendered}"
        );
    }
    assert!(loaded.warnings.iter().any(|w| {
        matches!(w.kind, ConfigWarningKind::ProhibitedSecretKey)
            && w.key.as_deref() == Some("token")
            && w.to_string().contains("rslbp_config.toml")
    }));
    assert!(loaded.warnings.iter().any(|w| {
        matches!(w.kind, ConfigWarningKind::InvalidValue { .. })
            && w.key.as_deref() == Some("output.format")
    }));
    assert!(loaded.warnings.iter().any(|w| {
        matches!(w.kind, ConfigWarningKind::UnknownKey)
            && w.key.as_deref() == Some("output.unknown_leaf")
    }));

    // R54 AC12b: corrupt discovered project file warns and preserves user + system tiers.
    write_file(
        &project.join(".rslbp/rslbp_config.toml"),
        "[output\nbroken =",
    );
    let loaded_corrupt = load_config(&ConfigDiscoveryInputs {
        explicit_flag: None,
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect("corrupt discovered layer must warn, not fail");
    assert_eq!(
        loaded_corrupt.config.as_config().output.format,
        OutputFormat::Json
    );
    assert_eq!(
        loaded_corrupt.config.as_config().logging.level,
        LogLevel::Info
    );
    assert!(
        loaded_corrupt
            .warnings
            .iter()
            .any(|w| matches!(w.kind, ConfigWarningKind::UnparsableDiscoveredFile { .. }))
    );

    // Missing explicit --config warns once and returns defaults (R55 clause 1 / F235).
    let missing_explicit = tmp.path().join("does-not-exist.toml");
    let loaded_missing = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&missing_explicit),
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect("missing explicit config must warn, not fail");
    assert_eq!(loaded_missing.warnings.len(), 1);
    assert!(matches!(
        loaded_missing.warnings[0].kind,
        ConfigWarningKind::MissingExplicitFile
    ));
    assert!(
        loaded_missing.warnings[0]
            .to_string()
            .contains("does-not-exist.toml")
    );

    // Corrupt explicit --config is fatal RSLB202 / exit 2 (R55 clause 2 / F237).
    let bad_explicit = tmp.path().join("bad-explicit.toml");
    write_file(&bad_explicit, "[output\nbad");
    let err_parse = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&bad_explicit),
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect_err("corrupt explicit config must fail");
    assert_eq!(err_parse.error_code(), ErrorCode::ConfigUnparsable);
    assert_eq!(err_parse.error_code().exit(), Exit::Usage);

    // Unreadable explicit --config (directory path) is fatal RSLB104 / exit 1 (R55 clause 2).
    let dir_as_file = tmp.path().join("dir-not-file");
    fs::create_dir_all(&dir_as_file).expect("mkdir");
    let err_io = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&dir_as_file),
        explicit_env: None,
        cwd: &project,
        paths: &paths,
        xdg_config_dirs: Some(&xdg_dirs),
    })
    .expect_err("unreadable explicit config must fail");
    assert_eq!(err_io.error_code(), ErrorCode::ConfigUnreadable);
    assert_eq!(err_io.error_code().exit(), Exit::Runtime);
}

#[test]
fn toml_edit_writer_preserves_comments_enforces_0600_and_refuses_corrupt_or_secret() {
    let tmp = TempDir::new("writer");
    let cfg_path = tmp.path().join("nested/rslbp_config.toml");

    // R56 AC7: `config set token <value>` MUST fail with RSLB204 / exit 2.
    let err_secret = set_config_value(&cfg_path, "token", "sk_live_forbidden")
        .expect_err("setting token in config must be refused");
    assert_eq!(err_secret.error_code(), ErrorCode::ProhibitedSecretChannel);
    assert_eq!(err_secret.error_code().exit(), Exit::Usage);
    assert!(!cfg_path.exists(), "refused write must not create file");

    // Seed file with header comment, per-key comment, and inline trailing comment (R52 AC3).
    let initial = "\
# Header comment must survive
[output]
# Per-key comment for format
format = \"table\" # trailing comment must survive
color = \"auto\"
";
    write_file(&cfg_path, initial);

    let coerced = set_config_value(&cfg_path, "output.format", "json").expect("set output.format");
    assert_eq!(coerced, "json");

    let updated = fs::read_to_string(&cfg_path).expect("read updated");
    assert!(
        updated.contains("# Header comment must survive"),
        "{updated}"
    );
    assert!(
        updated.contains("# Per-key comment for format"),
        "{updated}"
    );
    assert!(
        updated.contains("# trailing comment must survive"),
        "{updated}"
    );
    assert!(updated.contains("format = \"json\""), "{updated}");

    // Verify 0600 mode (R52 AC5).
    let mode = fs::metadata(&cfg_path).expect("stat").permissions().mode() & 0o7777;
    assert_eq!(mode, 0o600, "config file must be written at mode 0600");

    // Verify re-read through typed loader (R52 AC4).
    let parsed: toml::Table = toml::from_str(&updated).expect("re-parse");
    let report = UnvalidatedConfig::from_table(parsed).validate();
    assert!(report.issues.is_empty());
    assert_eq!(report.config.as_config().output.format, OutputFormat::Json);

    // Corrupt file refuses write without destroying original bytes (R52 AC6).
    let corrupt_path = tmp.path().join("corrupt.toml");
    let broken = "[output\nbroken = ";
    write_file(&corrupt_path, broken);
    let err_corrupt = set_config_value(&corrupt_path, "output.format", "json")
        .expect_err("corrupt file must refuse modification");
    assert_eq!(err_corrupt.error_code(), ErrorCode::ConfigUnparsable);
    assert_eq!(fs::read_to_string(&corrupt_path).expect("read"), broken);
}

#[test]
fn secret_policy_precedence_redaction_and_0600_permissions() {
    let tmp = TempDir::new("secrets");
    let secret_stored = "sk_live_STORED_SECRET_9876";
    let secret_env = "sk_live_ENV_SECRET_5432";
    let secret_file = "sk_live_FILE_SECRET_1111";

    let cred_path = tmp.path().join("state/credentials.toml");
    let store = FileCredentialStore::new(&cred_path);
    store
        .save(&Token::new(secret_stored))
        .expect("save stored credential");

    // Created at 0600 (R56 AC3).
    assert_eq!(
        inspect_file_permissions(&cred_path).expect("inspect"),
        PermissionCheck::Secure
    );
    let mode = fs::metadata(&cred_path).expect("stat").permissions().mode() & 0o7777;
    assert_eq!(mode, 0o600);

    // Stored tier works cleanly when neither token-file nor env is set.
    let res_stored = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: Some(""), // empty env is unset (F242)
        store: Some(&store),
    })
    .expect("resolve stored");
    let resolved = res_stored.resolved.expect("stored token present");
    assert_eq!(resolved.source, TokenSource::Stored);
    assert_eq!(resolved.token.expose_secret(), secret_stored);
    assert!(res_stored.warnings.is_empty());

    // Debug and Display never leak the full secret (R56 AC5).
    let dbg_str = format!("{resolved:?}");
    let disp_str = format!("{}", resolved.token);
    assert!(!dbg_str.contains(secret_stored), "Debug leaked: {dbg_str}");
    assert!(
        !disp_str.contains(secret_stored),
        "Display leaked: {disp_str}"
    );
    assert_eq!(disp_str, "***9876");

    // 0644 triggers loose permission warning naming path and chmod 600, never secret (R56 AC2/AC10).
    fs::set_permissions(&cred_path, fs::Permissions::from_mode(0o644)).expect("chmod 0644");
    let res_loose = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: None,
        store: Some(&store),
    })
    .expect("loose permissions must warn, not fail");
    assert_eq!(res_loose.warnings.len(), 1);
    let warn_text = res_loose.warnings[0].to_string();
    assert!(warn_text.contains("credentials.toml"), "{warn_text}");
    assert!(warn_text.contains("chmod 600"), "{warn_text}");
    assert!(!warn_text.contains(secret_stored), "{warn_text}");

    // 0700 triggers NO warning (mask is 0o077, not == 0o600).
    fs::set_permissions(&cred_path, fs::Permissions::from_mode(0o700)).expect("chmod 0700");
    let res_700 = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: None,
        store: Some(&store),
    })
    .expect("0700 resolve");
    assert!(res_700.warnings.is_empty());
    fs::set_permissions(&cred_path, fs::Permissions::from_mode(0o600)).expect("chmod 0600");

    // Middle rung: RSLBP_TOKEN outranks stored credential (R56 AC4).
    let res_env = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect("resolve env");
    let env_resolved = res_env.resolved.expect("env token");
    assert_eq!(env_resolved.source, TokenSource::Env);
    assert_eq!(env_resolved.token.expose_secret(), secret_env);

    // Top rung: --token-file outranks RSLBP_TOKEN and stored credential (R56 AC4).
    let tok_file = tmp.path().join("my.tok");
    write_file(&tok_file, &format!("{secret_file}\n"));
    fs::set_permissions(&tok_file, fs::Permissions::from_mode(0o600)).expect("chmod 0600");
    let res_file = resolve_token(&TokenResolutionInputs {
        token_file: Some(&tok_file),
        stdin_token: None,
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect("resolve file");
    let file_resolved = res_file.resolved.expect("file token");
    assert_eq!(file_resolved.source, TokenSource::TokenFile);
    assert_eq!(file_resolved.token.expose_secret(), secret_file);

    // --token-file pointing to missing file -> RSLB401 / exit 4, NEVER falls through to env (R56 AC6).
    let missing_tok = tmp.path().join("nope.tok");
    let err_missing = resolve_token(&TokenResolutionInputs {
        token_file: Some(&missing_tok),
        stdin_token: None,
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect_err("missing --token-file must fail with RSLB401");
    assert_eq!(err_missing.error_code(), ErrorCode::CredentialsAbsent);
    assert_eq!(err_missing.error_code().exit(), Exit::Auth);

    // Empty --token-file -> RSLB401 / exit 4.
    let empty_tok = tmp.path().join("empty.tok");
    write_file(&empty_tok, "  \n");
    let err_empty = resolve_token(&TokenResolutionInputs {
        token_file: Some(&empty_tok),
        stdin_token: None,
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect_err("empty --token-file must fail with RSLB401");
    assert_eq!(err_empty.error_code(), ErrorCode::CredentialsAbsent);

    // Unreadable --token-file (directory) -> RSLB101 / exit 1 (R56 AC6).
    let dir_tok = tmp.path().join("dir.tok");
    fs::create_dir_all(&dir_tok).expect("mkdir");
    let err_io = resolve_token(&TokenResolutionInputs {
        token_file: Some(&dir_tok),
        stdin_token: None,
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect_err("unreadable --token-file must fail with RSLB101");
    assert_eq!(err_io.error_code(), ErrorCode::Io);
    assert_eq!(err_io.error_code().exit(), Exit::Runtime);

    // Stdin (`-`) reads injected stdin token.
    let res_stdin = resolve_token(&TokenResolutionInputs {
        token_file: Some(Path::new("-")),
        stdin_token: Some("sk_live_STDIN_TOKEN\n"),
        env_token: Some(secret_env),
        store: Some(&store),
    })
    .expect("stdin resolve");
    let stdin_resolved = res_stdin.resolved.expect("stdin token");
    assert_eq!(stdin_resolved.source, TokenSource::Stdin);
    assert_eq!(stdin_resolved.token.expose_secret(), "sk_live_STDIN_TOKEN");

    // Delete stored credential works cleanly.
    assert!(store.delete().expect("delete existing"));
    assert!(!store.delete().expect("delete absent"));
    let _check_err_type: fn(AuthError) -> ErrorCode = |e| e.error_code();
    let _check_cfg_err_type: fn(ConfigError) -> ErrorCode = |e| e.error_code();
}

#[cfg(feature = "keychain")]
#[test]
fn keychain_credential_store_round_trips_using_keyring_core_mock() {
    use rs_launch_blueprint::KeychainCredentialStore;

    let backend = keyring_core::mock::Store::new().expect("mock keyring store");
    let store = KeychainCredentialStore::with_store(backend, "rslbp-test", "default");

    assert!(store.load().expect("empty load").0.is_none());
    store
        .save(&Token::new("sk_live_KEYCHAIN_9999"))
        .expect("save keychain");
    let (loaded, warns) = store.load().expect("load keychain");
    assert!(warns.is_empty());
    assert_eq!(
        loaded.expect("present").expose_secret(),
        "sk_live_KEYCHAIN_9999"
    );
    assert!(store.delete().expect("delete keychain"));
    assert!(store.load().expect("after delete").0.is_none());
    assert!(!store.delete().expect("delete absent keychain"));
    assert!(format!("{store:?}").contains("KeychainCredentialStore"));
}

#[test]
fn schema_display_validation_writer_all_keys_and_in_memory_credential_store() {
    use rs_launch_blueprint::{
        FileLogFormat, InMemoryCredentialStore, ValidConfig, get_config_value,
        read_config_file_key, validate_config_assignment,
    };

    // Display impls for config enums and TokenSource.
    assert_eq!(OutputFormat::Markdown.to_string(), "markdown");
    assert_eq!(ColorPreference::Always.to_string(), "always");
    assert_eq!(LogLevel::Trace.to_string(), "trace");
    assert_eq!(FileLogFormat::Json.to_string(), "json");
    assert_eq!(TokenSource::Env.to_string(), "env");
    assert_eq!(TokenSource::Stdin.to_string(), "stdin");
    assert_eq!(TokenSource::TokenFile.to_string(), "token-file");
    assert_eq!(TokenSource::Stored.to_string(), "stored");

    // UnvalidatedConfig::parse_str, as_table, ValidConfig::defaults, into_inner, is_clean.
    let parsed = UnvalidatedConfig::parse_str("[output]\nformat = \"json\"\n").expect("parse");
    assert!(parsed.as_table().contains_key("output"));
    assert!(UnvalidatedConfig::parse_str("[broken").is_err());

    let clean_report = parsed.validate();
    assert!(clean_report.is_clean());
    let valid_def = ValidConfig::defaults();
    assert_eq!(valid_def.into_inner().output.format, OutputFormat::Table);

    // Exhaustive invalid type & section validation cases + ValidationIssue::Display.
    let bad_toml = r#"
extra_root = 1
[output]
format = 123
color = 456
limit = "not-int"
[logging]
level = "bogus"
file = 789
file-format = "xml"
file-level = "nope"
unknown_log = 1
[nested]
api_key = "forbidden"
"#;
    let rep = UnvalidatedConfig::parse_str(bad_toml).unwrap().validate();
    assert!(!rep.is_clean());
    assert!(!rep.issues.is_empty());
    assert!(rep.issues[0].to_string().contains(&rep.issues[0].path));
    assert!(rep.unknown_keys.iter().any(|k| k == "extra_root"));
    assert!(
        rep.prohibited_secret_keys
            .iter()
            .any(|k| k == "nested.api_key")
    );

    let bad_types = r#"
logging = "not-a-table"
[output]
limit = -5
"#;
    let rep2 = UnvalidatedConfig::parse_str(bad_types).unwrap().validate();
    assert!(rep2.issues.iter().any(|i| i.path == "logging"));
    assert!(rep2.issues.iter().any(|i| i.path == "output.limit"));

    let bad_log_types = r#"
[logging]
level = 1
file-format = 2
file-level = 3
"#;
    let rep3 = UnvalidatedConfig::parse_str(bad_log_types)
        .unwrap()
        .validate();
    assert_eq!(rep3.issues.len(), 3);

    // Writer: every writable key get/set/validate/read_config_file_key + error paths.
    let tmp = TempDir::new("writer-all");
    let cfg_path = tmp.path().join("rslbp_config.toml");
    assert_eq!(
        read_config_file_key(&cfg_path, "output.format").unwrap(),
        None
    );

    for (key, val) in [
        ("output.format", "name"),
        ("output.color", "always"),
        ("output.limit", "25"),
        ("logging.level", "debug"),
        ("logging.file", "/tmp/rslbp.log"),
        ("logging.file-format", "json"),
        ("logging.file-level", "info"),
    ] {
        let canon = validate_config_assignment(key, val).expect(key);
        let written = set_config_value(&cfg_path, key, val).expect(key);
        assert_eq!(written, canon);
        assert_eq!(
            read_config_file_key(&cfg_path, key).unwrap().as_deref(),
            Some(canon.as_str())
        );
    }

    // Load back and read every key via get_config_value.
    let paths = Paths::from_roots(
        tmp.path().join("c"),
        tmp.path().join("d"),
        tmp.path().join("s"),
        tmp.path().join("k"),
    );
    let loaded = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&cfg_path),
        explicit_env: None,
        cwd: tmp.path(),
        paths: &paths,
        xdg_config_dirs: None,
    })
    .expect("load written config");
    for key in [
        "output.format",
        "output.color",
        "output.limit",
        "logging.level",
        "logging.file",
        "logging.file-format",
        "logging.file-level",
    ] {
        assert!(get_config_value(&loaded.config, key).unwrap().is_some());
    }
    assert!(get_config_value(&loaded.config, "unknown.key").is_err());

    // Invalid assignments rejected cleanly.
    for (key, bad) in [
        ("output.format", "yaml"),
        ("output.color", "neon"),
        ("output.limit", "0"),
        ("output.limit", "abc"),
        ("logging.level", "verbose"),
        ("logging.file-format", "yaml"),
        ("logging.file-level", "verbose"),
        ("unknown.key", "x"),
        ("api_token", "sk_bad"),
    ] {
        assert!(
            validate_config_assignment(key, bad).is_err(),
            "{key}={bad} must fail"
        );
    }

    // Corrupt TOML rejected by read_config_file_key.
    fs::write(&cfg_path, "[broken").unwrap();
    assert!(read_config_file_key(&cfg_path, "output.format").is_err());

    // InMemoryCredentialStore full CRUD + short Token::masked().
    let short_tok = Token::new("abc");
    assert_eq!(short_tok.masked(), "***");
    let mem_empty = InMemoryCredentialStore::new();
    assert!(mem_empty.load().unwrap().0.is_none());
    mem_empty.save(&Token::new("sk_mem_1234")).unwrap();
    assert_eq!(
        mem_empty.load().unwrap().0.unwrap().expose_secret(),
        "sk_mem_1234"
    );
    assert!(mem_empty.delete().unwrap());
    assert!(!mem_empty.delete().unwrap());

    let mem_pre = InMemoryCredentialStore::with_token(Token::new("sk_pre_9876"));
    assert_eq!(
        mem_pre.load().unwrap().0.unwrap().expose_secret(),
        "sk_pre_9876"
    );

    // Empty stdin token fails with CredentialsAbsent.
    let res_empty_stdin = resolve_token(&TokenResolutionInputs {
        token_file: Some(Path::new("-")),
        stdin_token: Some("   \n"),
        env_token: None,
        store: None,
    });
    assert!(res_empty_stdin.is_err());

    // ConfigOverrides covering all 7 fields cleanly.
    let overridden = ValidConfig::defaults().apply_overrides(&ConfigOverrides {
        output_format: Some(OutputFormat::Json),
        output_color: Some(ColorPreference::Never),
        output_limit: std::num::NonZeroU32::new(42),
        logging_level: Some(LogLevel::Debug),
        logging_file: Some(PathBuf::from("/tmp/ov.log")),
        logging_file_format: Some(FileLogFormat::Json),
        logging_file_level: Some(LogLevel::Trace),
    });
    let oc = overridden.as_config();
    assert_eq!(oc.output.color, ColorPreference::Never);
    assert_eq!(oc.output.limit, std::num::NonZeroU32::new(42));
    assert_eq!(oc.logging.level, LogLevel::Debug);
    assert_eq!(oc.logging.file.as_deref(), Some(Path::new("/tmp/ov.log")));
    assert_eq!(oc.logging.file_format, FileLogFormat::Json);
    assert_eq!(oc.logging.file_level, Some(LogLevel::Trace));

    // Default optional keys return None via get_config_value; read_config_file_key handles integer & missing section.
    let def_cfg = ValidConfig::defaults();
    assert_eq!(get_config_value(&def_cfg, "output.limit").unwrap(), None);
    assert_eq!(get_config_value(&def_cfg, "logging.file").unwrap(), None);
    assert_eq!(
        get_config_value(&def_cfg, "logging.file-level").unwrap(),
        None
    );
    let partial_cfg = tmp.path().join("partial.toml");
    fs::write(&partial_cfg, "[output]\nlimit = 15\n").unwrap();
    assert_eq!(
        read_config_file_key(&partial_cfg, "output.limit")
            .unwrap()
            .as_deref(),
        Some("15")
    );
    assert_eq!(
        read_config_file_key(&partial_cfg, "logging.level").unwrap(),
        None
    );
    assert_eq!(
        read_config_file_key(&partial_cfg, "no_dot_key").unwrap(),
        None
    );

    // Explicit unreadable directory, explicit prohibited secret key, and explicit invalid value.
    let dir_cfg = tmp.path().join("dir-as-cfg");
    fs::create_dir_all(&dir_cfg).unwrap();
    let err_unreadable = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&dir_cfg),
        explicit_env: None,
        cwd: tmp.path(),
        paths: &paths,
        xdg_config_dirs: None,
    })
    .unwrap_err();
    assert_eq!(err_unreadable.error_code(), ErrorCode::ConfigUnreadable);

    let secret_cfg = tmp.path().join("explicit-secret.toml");
    fs::write(&secret_cfg, "token = \"sk_bad\"\n").unwrap();
    let loaded_sec = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&secret_cfg),
        explicit_env: None,
        cwd: tmp.path(),
        paths: &paths,
        xdg_config_dirs: None,
    })
    .expect("secret leaf warns and strips");
    assert!(
        loaded_sec
            .warnings
            .iter()
            .any(|w| matches!(w.kind, ConfigWarningKind::ProhibitedSecretKey))
    );

    let invalid_cfg = tmp.path().join("explicit-invalid.toml");
    fs::write(&invalid_cfg, "[output]\nformat = \"xml\"\n").unwrap();
    let loaded_inv = load_config(&ConfigDiscoveryInputs {
        explicit_flag: Some(&invalid_cfg),
        explicit_env: None,
        cwd: tmp.path(),
        paths: &paths,
        xdg_config_dirs: None,
    })
    .expect("invalid leaf warns and defaults");
    assert!(
        loaded_inv
            .warnings
            .iter()
            .any(|w| matches!(w.kind, ConfigWarningKind::InvalidValue { .. }))
    );

    // FileCredentialStore: nested `[auth] token`, invalid TOML, directory-as-file Io error, unwritable save.
    let nested_creds = tmp.path().join("nested_creds.toml");
    fs::write(&nested_creds, "[auth]\ntoken = \"sk_nested_77\"\n").unwrap();
    let nested_store = FileCredentialStore::new(&nested_creds);
    let (tok_nested, _) = nested_store.load().expect("load nested auth.token");
    assert_eq!(tok_nested.unwrap().expose_secret(), "sk_nested_77");

    let bad_creds = tmp.path().join("bad_creds.toml");
    fs::write(&bad_creds, "[broken").unwrap();
    assert!(FileCredentialStore::new(&bad_creds).load().is_err());

    let dir_creds = tmp.path().join("dir_creds");
    fs::create_dir_all(&dir_creds).unwrap();
    let dir_store = FileCredentialStore::new(&dir_creds);
    assert!(dir_store.load().is_err());
    assert!(dir_store.delete().is_err());

    let file_blocker = tmp.path().join("file_blocker");
    fs::write(&file_blocker, b"x").unwrap();
    assert!(
        FileCredentialStore::new(file_blocker.join("creds.toml"))
            .save(&Token::new("sk_fail"))
            .is_err()
    );
    assert!(set_config_value(&file_blocker.join("cfg.toml"), "output.format", "json").is_err());

    // set_config_value rejects corrupt existing TOML file & repairs non-table section header.
    let corrupt_write = tmp.path().join("corrupt_write.toml");
    fs::write(&corrupt_write, "[broken").unwrap();
    assert!(set_config_value(&corrupt_write, "output.format", "json").is_err());

    let non_table_sec = tmp.path().join("non_table_sec.toml");
    fs::write(&non_table_sec, "output = 123\n").unwrap();
    assert!(set_config_value(&non_table_sec, "output.format", "json").is_err());

    // Discovered unreadable (non-UTF-8) config file warns cleanly instead of failing.
    let bad_disc = tmp.path().join("bad-disc");
    fs::create_dir_all(bad_disc.join(".git")).unwrap();
    fs::create_dir_all(bad_disc.join(".rslbp")).unwrap();
    let bad_disc_file = bad_disc.join(".rslbp/rslbp_config.toml");
    fs::write(&bad_disc_file, [0xff_u8, 0xfe]).unwrap();
    let loaded_disc = load_config(&ConfigDiscoveryInputs {
        explicit_flag: None,
        explicit_env: None,
        cwd: &bad_disc,
        paths: &paths,
        xdg_config_dirs: None,
    })
    .expect("unreadable discovered layer warns");
    assert!(!loaded_disc.warnings.is_empty());
    assert!(
        loaded_disc.warnings[0]
            .to_string()
            .contains("skipping unreadable config file")
    );
    let bad_parse_disc = tmp.path().join("bad-parse-disc");
    fs::create_dir_all(bad_parse_disc.join(".git")).unwrap();
    fs::create_dir_all(bad_parse_disc.join(".rslbp")).unwrap();
    fs::write(bad_parse_disc.join(".rslbp/rslbp_config.toml"), "[broken").unwrap();
    let loaded_bad_parse = load_config(&ConfigDiscoveryInputs {
        explicit_flag: None,
        explicit_env: None,
        cwd: &bad_parse_disc,
        paths: &paths,
        xdg_config_dirs: None,
    })
    .expect("unparsable discovered layer warns");
    assert!(
        loaded_bad_parse.warnings[0]
            .to_string()
            .contains("skipping invalid TOML")
    );

    // Writer edge cases: get_config_value rejects secret keys, read_config_file_key handles
    // unreadable files and non-string values, set_config_value replaces non-value items and reports
    // atomic rename failures onto an existing directory.
    assert!(matches!(
        rs_launch_blueprint_core::get_config_value(&loaded_disc.config, "token"),
        Err(ConfigError::ProhibitedSecretChannel { .. })
    ));
    assert!(matches!(
        rs_launch_blueprint_core::read_config_file_key(&bad_disc_file, "output.format"),
        Err(ConfigError::Unreadable { .. })
    ));
    let bool_cfg = tmp.path().join("bool-val.toml");
    fs::write(&bool_cfg, "[output]\nflag = true\n").unwrap();
    assert_eq!(
        rs_launch_blueprint_core::read_config_file_key(&bool_cfg, "output.flag").unwrap(),
        Some("true".to_owned())
    );
    let subtable_cfg = tmp.path().join("subtable-val.toml");
    fs::write(&subtable_cfg, "[output.format]\nnested = 1\n").unwrap();
    assert_eq!(
        set_config_value(&subtable_cfg, "output.format", "json").unwrap(),
        "json"
    );
    let dir_target = tmp.path().join("cfg-is-dir");
    fs::create_dir_all(&dir_target).unwrap();
    assert!(set_config_value(&dir_target, "output.format", "json").is_err());

    // resolve_token with no file, no env, and no store returns Ok(None) cleanly.
    let none_tok = resolve_token(&TokenResolutionInputs {
        token_file: None,
        stdin_token: None,
        env_token: None,
        store: None,
    })
    .expect("no token sources is not an error");
    assert!(none_tok.resolved.is_none());
    assert!(none_tok.warnings.is_empty());
}
