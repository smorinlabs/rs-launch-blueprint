//! CLI-crate contract tests exercising `clap`, `indicatif::InMemoryTerm`, and `anstream`
//! (`R60`, `R63`, `R65`).

use std::error::Error as _;
use std::ffi::OsString;
use std::io;
use std::process::ExitCode;

use anstream::{AutoStream, ColorChoice};
use clap::CommandFactory;
use indicatif::{InMemoryTerm, ProgressDrawTarget};
use proptest::prelude::*;
use rs_launch_blueprint::{
    AuthError, ColorPreference, ConfigError, DomainError, ErrorCode, LogLevel, OutputFormat,
    PortError, Project,
};
use rs_launch_blueprint_cli::{
    CURATED_ENV_VARS, Cli, ClipboardError, ClipboardPort, ColorArg, EnvLookup, Exit,
    FailingClipboard, LogFormatArg, LogLevelArg, MapEnv, OutputFormatArg, ProcessEnv,
    ProjectListView, SpinnerGuard, TermCaps, cli_hint_for_domain_error, is_clipboard_daemon_argv,
    render_version_line, render_view, resolve_color, resolve_stream_color, should_show_spinner,
    sniff_initial_log_settings,
};

fn args(slice: &[&str]) -> Vec<OsString> {
    let mut out = Vec::with_capacity(slice.len() + 1);
    out.push(OsString::from("rslbp"));
    out.extend(slice.iter().map(OsString::from));
    out
}

#[test]
fn r60_clap_grammar_invariants_curated_env_depth_singular_nouns_and_hidden_aliases() {
    let cmd = Cli::command();
    // R60 AC1: clap debug_assert validates flag/short/subcommand consistency.
    cmd.clone().debug_assert();

    // R60 AC5: every clap `env = ...` binding matches CURATED_ENV_VARS exactly.
    let mut found_envs: Vec<(String, String)> = Vec::new();
    for arg in cmd.get_arguments() {
        if let Some(env_name) = arg.get_env() {
            found_envs.push((
                arg.get_id().as_str().to_owned(),
                env_name.to_string_lossy().into_owned(),
            ));
        }
    }
    found_envs.sort();
    let mut expected_envs: Vec<(String, String)> = CURATED_ENV_VARS
        .iter()
        .map(|(id, env)| ((*id).to_owned(), (*env).to_owned()))
        .collect();
    expected_envs.sort();
    assert_eq!(found_envs, expected_envs, "R60 AC5 curated env var drift");

    // R60 AC8 (max depth <= 3), AC9 (singular canonical nouns), AC10 (hidden aliases only).
    fn check_tree(c: &clap::Command, depth: usize) {
        assert!(
            depth <= 3,
            "command `{}` exceeds max depth 3 (R60 AC8)",
            c.get_name()
        );
        let visible_aliases: Vec<&str> = c.get_visible_aliases().collect();
        assert!(
            visible_aliases.is_empty(),
            "command `{}` must not declare visible aliases (R60 AC10): {visible_aliases:?}",
            c.get_name()
        );
        let help = c.clone().render_long_help().to_string();
        assert!(
            !help.contains("projects"),
            "rendered help for `{}` must not contain plural `projects` (R60 AC9)",
            c.get_name()
        );
        for sub in c.get_subcommands() {
            if sub.get_name() != "help" {
                check_tree(sub, depth + 1);
            }
        }
    }
    check_tree(&cmd, 1);

    let project_sub = cmd.find_subcommand("project").expect("project subcommand");
    let all_aliases: Vec<&str> = project_sub.get_all_aliases().collect();
    assert!(
        all_aliases.contains(&"projects"),
        "project must register hidden alias `projects`"
    );

    assert_eq!(
        render_version_line(),
        format!("rslbp {}\n", env!("CARGO_PKG_VERSION"))
    );
    assert!(is_clipboard_daemon_argv(&args(&["--clipboard-daemon"])));
    assert!(!is_clipboard_daemon_argv(&args(&["version"])));

    let (dbg, fmt) = sniff_initial_log_settings(&args(&["--debug", "--log-format", "json"]));
    assert!(dbg);
    assert_eq!(fmt, Some(LogFormatArg::Json));
    let (dbg2, fmt2) = sniff_initial_log_settings(&args(&["--log-format=console"]));
    assert!(!dbg2);
    assert_eq!(fmt2, Some(LogFormatArg::Console));
    let (_, fmt3) = sniff_initial_log_settings(&args(&["--log-format=auto"]));
    assert_eq!(fmt3, Some(LogFormatArg::Auto));
    let (_, fmt4) = sniff_initial_log_settings(&args(&["--log-format=invalid"]));
    assert_eq!(fmt4, None);
}

#[test]
fn r63_spinner_policy_and_in_memory_term_clear_on_drop() {
    assert!(should_show_spinner(true, None, false));
    assert!(
        should_show_spinner(true, Some(std::ffi::OsStr::new("")), false),
        "empty CI='' must not suppress spinner (R63 rev 4)"
    );
    assert!(!should_show_spinner(false, None, false));
    assert!(!should_show_spinner(
        true,
        Some(std::ffi::OsStr::new("1")),
        false
    ));
    assert!(!should_show_spinner(true, None, true));

    let term = InMemoryTerm::new(10, 80);
    let target = ProgressDrawTarget::term_like(Box::new(term.clone()));
    let guard = SpinnerGuard::start_with_target("Fetching records...", true, target);
    assert!(guard.is_active());
    assert!(
        term.contents().contains("Fetching records..."),
        "active spinner should render message: {:?}",
        term.contents()
    );
    guard.finish_and_clear();
    assert!(
        term.contents().trim().is_empty(),
        "finish_and_clear must erase spinner line: {:?}",
        term.contents()
    );

    // Drop clears even on early error return.
    let term_drop = InMemoryTerm::new(10, 80);
    {
        let target2 = ProgressDrawTarget::term_like(Box::new(term_drop.clone()));
        let guard2 = SpinnerGuard::start_with_target("Working...", true, target2);
        assert!(term_drop.contents().contains("Working..."));
        drop(guard2);
    }
    assert!(term_drop.contents().trim().is_empty());

    // Disabled spinner renders nothing.
    let term_off = InMemoryTerm::new(10, 80);
    let target_off = ProgressDrawTarget::term_like(Box::new(term_off.clone()));
    let guard_off = SpinnerGuard::start_with_target("Hidden", false, target_off);
    assert!(!guard_off.is_active());
    assert!(term_off.contents().is_empty());
    guard_off.finish_and_clear();
}

#[test]
fn r65_color_precedence_ladder_and_stream_independence() {
    let empty = MapEnv::default();
    let xterm = MapEnv::from_pairs([("TERM", "xterm-256color")]);
    assert_eq!(
        resolve_color(None, ColorPreference::Auto, &empty),
        ColorChoice::Auto
    );
    assert!(resolve_stream_color(ColorChoice::Auto, true, &xterm));
    assert!(!resolve_stream_color(ColorChoice::Auto, false, &xterm));

    // Tier 1 flag beats everything.
    let no_color = MapEnv::from_pairs([("NO_COLOR", "1")]);
    assert_eq!(
        resolve_color(
            Some(ColorPreference::Always),
            ColorPreference::Never,
            &no_color
        ),
        ColorChoice::Always
    );
    assert_eq!(
        resolve_color(
            Some(ColorPreference::Never),
            ColorPreference::Always,
            &empty
        ),
        ColorChoice::Never
    );
    assert_eq!(
        resolve_color(Some(ColorPreference::Auto), ColorPreference::Never, &empty),
        ColorChoice::Never
    );

    // Tier 2 config always beats NO_COLOR=1; config never beats FORCE_COLOR=1.
    assert_eq!(
        resolve_color(None, ColorPreference::Always, &no_color),
        ColorChoice::Always
    );
    let force_color = MapEnv::from_pairs([("FORCE_COLOR", "1")]);
    assert_eq!(
        resolve_color(None, ColorPreference::Never, &force_color),
        ColorChoice::Never
    );

    // Tier 3 env: NO_COLOR=1 beats FORCE_COLOR=1; empty NO_COLOR="" is unset.
    let both = MapEnv::from_pairs([("NO_COLOR", "1"), ("FORCE_COLOR", "1")]);
    assert_eq!(
        resolve_color(None, ColorPreference::Auto, &both),
        ColorChoice::Never
    );
    let empty_nc_force = MapEnv::from_pairs([("NO_COLOR", ""), ("FORCE_COLOR", "1")]);
    assert_eq!(
        resolve_color(None, ColorPreference::Auto, &empty_nc_force),
        ColorChoice::Always
    );

    // CLICOLOR=0 disables, CLICOLOR=1 enables on TTY, CLICOLOR_FORCE=1 enables.
    let clicolor_zero = MapEnv::from_pairs([("CLICOLOR", "0"), ("TERM", "xterm-256color")]);
    assert!(!resolve_stream_color(
        ColorChoice::Auto,
        true,
        &clicolor_zero
    ));
    let clicolor_one = MapEnv::from_pairs([("CLICOLOR", "1")]);
    assert!(resolve_stream_color(ColorChoice::Auto, true, &clicolor_one));
    let clicolor_force = MapEnv::from_pairs([("CLICOLOR_FORCE", "1")]);
    assert!(resolve_stream_color(
        ColorChoice::Auto,
        false,
        &clicolor_force
    ));

    // Tier 5: TERM=dumb suppresses Auto even on a TTY, but Always overrides it.
    let dumb = MapEnv::from_pairs([("TERM", "dumb")]);
    assert!(!resolve_stream_color(ColorChoice::Auto, true, &dumb));
    assert!(resolve_stream_color(ColorChoice::Always, false, &dumb));
    assert!(!resolve_stream_color(ColorChoice::Never, true, &xterm));

    // Per-stream independence: stdout redirected, stderr TTY -> stderr colored, stdout plain.
    let auto = resolve_color(None, ColorPreference::Auto, &xterm);
    assert!(!resolve_stream_color(auto, false, &xterm));
    assert!(resolve_stream_color(auto, true, &xterm));

    // anstream::AutoStream::current_choice() reflects resolved choice cleanly.
    let stream = AutoStream::new(Vec::<u8>::new(), ColorChoice::Never);
    assert_eq!(stream.current_choice(), ColorChoice::Never);

    // Arg value-enum conversions + MapEnv::with/iter_prefixed + ProcessEnv::iter_prefixed.
    assert_eq!(ColorPreference::from(ColorArg::Auto), ColorPreference::Auto);
    assert_eq!(
        ColorPreference::from(ColorArg::Always),
        ColorPreference::Always
    );
    assert_eq!(
        ColorPreference::from(ColorArg::Never),
        ColorPreference::Never
    );
    for (arg, expected) in [
        (LogLevelArg::Off, LogLevel::Off),
        (LogLevelArg::Error, LogLevel::Error),
        (LogLevelArg::Warn, LogLevel::Warn),
        (LogLevelArg::Info, LogLevel::Info),
        (LogLevelArg::Debug, LogLevel::Debug),
        (LogLevelArg::Trace, LogLevel::Trace),
    ] {
        assert_eq!(LogLevel::from(arg), expected);
    }
    for (arg, expected) in [
        (OutputFormatArg::Table, OutputFormat::Table),
        (OutputFormatArg::Json, OutputFormat::Json),
        (OutputFormatArg::Markdown, OutputFormat::Markdown),
        (OutputFormatArg::Name, OutputFormat::Name),
    ] {
        assert_eq!(OutputFormat::from(arg), expected);
    }

    let built = MapEnv::new()
        .with("RSLBP_B", "2")
        .with("RSLBP_A", "1")
        .with("OTHER", "3");
    assert_eq!(
        built.iter_prefixed("RSLBP_"),
        vec![
            ("RSLBP_A".to_owned(), "1".to_owned()),
            ("RSLBP_B".to_owned(), "2".to_owned()),
        ]
    );
    let _ = ProcessEnv.iter_prefixed("");
}

#[test]
fn exit_taxonomy_and_error_code_mapping_match_cli_design_standard_r6_1() {
    assert_eq!(Exit::Success.code(), 0);
    assert_eq!(Exit::Runtime.code(), 1);
    assert_eq!(Exit::Usage.code(), 2);
    assert_eq!(Exit::NotFound.code(), 3);
    assert_eq!(Exit::Auth.code(), 4);
    assert_eq!(Exit::Conflict.code(), 5);
    assert_eq!(Exit::SigInt.code(), 130);
    assert_eq!(Exit::SigTerm.code(), 143);

    let _code: ExitCode = Exit::NotFound.into();

    const PINNED: &[(&str, u8)] = &[
        ("RSLB000", 1),
        ("RSLB101", 1),
        ("RSLB102", 1),
        ("RSLB103", 1),
        ("RSLB104", 1),
        ("RSLB201", 2),
        ("RSLB202", 2),
        ("RSLB203", 2),
        ("RSLB204", 2),
        ("RSLB205", 2),
        ("RSLB301", 3),
        ("RSLB401", 4),
        ("RSLB402", 4),
        ("RSLB501", 5),
        ("RSLB901", 130),
        ("RSLB902", 143),
        ("RSLB903", 130),
    ];
    for (idx, (expected_code, expected_exit)) in PINNED.iter().enumerate() {
        let actual = ErrorCode::ALL[idx];
        assert_eq!(actual.as_str(), *expected_code);
        assert_eq!(
            Exit::from_error_code(actual).code(),
            *expected_exit,
            "pinned exit code for {expected_code} drifted"
        );
    }

    let missing_auth = DomainError::from(AuthError::CredentialsAbsent {
        detail: "no token".to_owned(),
    });
    assert_eq!(Exit::from_domain_error(&missing_auth), Exit::Auth);
    assert!(
        cli_hint_for_domain_error(&missing_auth)
            .expect("CLI hint")
            .contains("--token-file")
    );
    let prohibited = DomainError::from(ConfigError::ProhibitedSecretChannel {
        key: "token".to_owned(),
    });
    assert!(
        cli_hint_for_domain_error(&prohibited)
            .expect("CLI hint")
            .contains("RSLBP_TOKEN")
    );
    let unauth = DomainError::from(PortError::Unauthorized {
        detail: "expired".to_owned(),
        source: None,
    });
    assert!(
        cli_hint_for_domain_error(&unauth)
            .expect("CLI hint")
            .contains("--token-file")
    );
    let nf = DomainError::NotFound {
        kind: "project",
        id: "demo".to_owned(),
    };
    assert!(cli_hint_for_domain_error(&nf).is_none());
}

#[test]
fn clipboard_error_variants_and_failing_default() {
    let clip_src = ClipboardError::with_source(
        "clipboard failed",
        Some("pipe instead".to_owned()),
        Box::new(io::Error::other("x11 down")),
    );
    assert!(clip_src.source().is_some());
    assert_eq!(clip_src.hint().as_deref(), Some("pipe instead"));

    let failing_default = FailingClipboard::default();
    let err = failing_default.set_text("hello").unwrap_err();
    assert!(err.hint().is_some());
}

#[test]
fn rslbp_binary_reports_version() {
    let bin = env!("CARGO_BIN_EXE_rslbp");
    let output = std::process::Command::new(bin)
        .arg("--version")
        .output()
        .expect("rslbp --version must execute");
    assert!(
        output.status.success(),
        "rslbp --version exited with {:?}",
        output.status
    );
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.trim(),
        format!("rslbp {}", rs_launch_blueprint::VERSION),
        "rslbp --version must print `rslbp <VERSION>`"
    );
}

#[cfg(all(feature = "clipboard", target_os = "linux"))]
#[test]
fn linux_headless_clipboard_fails_fast_and_daemon_exits_cleanly() {
    use rs_launch_blueprint_cli::ArboardClipboard;
    use std::process::{Command, Stdio};

    if std::env::var_os("DISPLAY").is_some() || std::env::var_os("WAYLAND_DISPLAY").is_some() {
        return;
    }
    let err = ArboardClipboard::new()
        .set_text("headless-probe")
        .expect_err("headless Linux without display server must fail fast");
    assert!(
        err.to_string().contains("Linux display server"),
        "unexpected clipboard error: {err}"
    );

    let status = Command::new(env!("CARGO_BIN_EXE_rslbp"))
        .arg("--clipboard-daemon")
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .expect("spawn rslbp --clipboard-daemon");
    assert!(
        !status.success(),
        "clipboard daemon without Linux display server must exit non-zero"
    );
}

proptest! {
    #[test]
    fn cli_output_renderers_preserve_machine_invariants_across_arbitrary_projects(
        projects in proptest::collection::vec(
            (
                "[A-Za-z0-9_|\\\\ -]{1,20}",
                "[A-Za-z0-9_|\\\\\",\\n\\x1b -]{0,32}",
                prop::option::of("[A-Za-z0-9_|\\\\\",\\n -]{0,20}"),
            )
                .prop_map(|(id, name, workspace)| Project { id, name, workspace }),
            0..8,
        ),
    ) {
        let view = ProjectListView {
            projects: projects.clone(),
        };

        let mut json_buf = Vec::new();
        render_view(&view, OutputFormat::Json, TermCaps::plain(), &mut json_buf)
            .expect("render json");
        prop_assert!(!json_buf.contains(&0x1b));
        let parsed: serde_json::Value = serde_json::from_slice(&json_buf).expect("valid json");
        prop_assert_eq!(parsed["projects"].as_array().unwrap().len(), projects.len());

        let mut md_buf = Vec::new();
        render_view(&view, OutputFormat::Markdown, TermCaps::plain(), &mut md_buf)
            .expect("render markdown");
        prop_assert!(!md_buf.contains(&0x1b));
        let md = String::from_utf8(md_buf).expect("utf-8 md");
        if projects.is_empty() {
            prop_assert_eq!(md.lines().count(), 1);
        } else {
            prop_assert_eq!(md.lines().count(), projects.len() + 4);
        }

        let mut name_buf = Vec::new();
        render_view(&view, OutputFormat::Name, TermCaps::plain(), &mut name_buf)
            .expect("render name");
        prop_assert!(!name_buf.contains(&0x1b));
        let names = String::from_utf8(name_buf).expect("utf-8 name");
        prop_assert_eq!(names.lines().count(), projects.len());

        let mut table_buf = Vec::new();
        render_view(&view, OutputFormat::Table, TermCaps::plain(), &mut table_buf)
            .expect("render table");
        prop_assert!(!table_buf.contains(&0x1b));
    }
}
