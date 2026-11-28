//! CLI-crate contract tests exercising `clap`, `indicatif::InMemoryTerm`, and `anstream`
//! (`R60`, `R63`, `R65`).

use std::ffi::OsString;

use anstream::{AutoStream, ColorChoice};
use clap::CommandFactory;
use indicatif::{InMemoryTerm, ProgressDrawTarget};
use rs_launch_blueprint_cli::{
    CURATED_ENV_VARS, Cli, ColorArg, EnvLookup, LogFormatArg, LogLevelArg, MapEnv, OutputFormatArg,
    ProcessEnv, SpinnerGuard, is_clipboard_daemon_argv, render_version_line, resolve_color,
    resolve_stream_color, should_show_spinner, sniff_initial_log_settings,
};
use rs_launch_blueprint_core::{ColorPreference, LogLevel, OutputFormat};

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
