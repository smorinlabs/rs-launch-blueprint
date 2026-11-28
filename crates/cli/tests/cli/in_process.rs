//! In-process CLI acceptance tests covering `R61`–`R67` and `R85` (`R32` M4).
//!
//! Exercises `execute_cli`, `CliRuntime`, `Prompter`, `ClipboardPort`, `PagerWriter`,
//! `render_view`, `TermCaps`, and `resolve_binary_boundary` deterministically.

use std::ffi::OsString;
use std::fs;
use std::io;
use std::os::unix::fs::PermissionsExt;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use rs_launch_blueprint::{
    DomainError, ErrorCode, InMemoryProjectsPort, OutputFormat, Paths, Project, ProjectQuery,
    ProjectsPort, workspace_info,
};
use rs_launch_blueprint_cli::{
    CliError, CliRuntime, ClipboardError, ClipboardPort, ConfigPathView, ConfigShowView,
    ConfigValueView, CrashRecord, CrashSink, DEFAULT_PAGER, DiagnosticCheck, DiagnosticsBundleView,
    DiagnosticsReportView, Exit, FailingClipboard, FileCrashSink, MapEnv, NoopCrashSink,
    PagerWriter, ProjectDeletedView, ProjectListView, PromptError, RecordingClipboard,
    ScriptedAnswer, ScriptedPrompter, TermCaps, TerminalState, VersionView, emit_cli_error,
    escape_label, escape_markdown_cell, execute_cli, format_file_link, format_osc8_link,
    relative_time, render_error, render_view, resolve_binary_boundary, resolve_output_format,
    resolve_pager_argv, run, sanitize_url, write_output_file_atomic,
};
use tempfile::TempDir;

fn args(slice: &[&str]) -> Vec<OsString> {
    let mut out = Vec::with_capacity(slice.len() + 1);
    out.push(OsString::from("rslbp"));
    out.extend(slice.iter().map(OsString::from));
    out
}

fn temp_paths(tmp: &TempDir) -> Paths {
    Paths::from_roots(
        tmp.path().join("config"),
        tmp.path().join("data"),
        tmp.path().join("state"),
        tmp.path().join("cache"),
    )
}

fn sample_projects() -> Vec<Project> {
    vec![
        Project {
            id: "p1".to_owned(),
            name: "Alpha".to_owned(),
            workspace: Some("Core".to_owned()),
        },
        Project {
            id: "p2".to_owned(),
            name: "Beta".to_owned(),
            workspace: None,
        },
    ]
}

fn strip_osc8(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let bytes = input.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == 0x1b && i + 4 <= bytes.len() && &bytes[i + 1..i + 4] == b"]8;" {
            i += 4;
            while i + 1 < bytes.len() {
                if bytes[i] == 0x1b && bytes[i + 1] == b'\\' {
                    i += 2;
                    break;
                }
                i += 1;
            }
        } else {
            let ch = input[i..].chars().next().expect("valid utf-8 char");
            out.push(ch);
            i += ch.len_utf8();
        }
    }
    out
}

// =========================================================================
// R61 — Prompter seam & OV-02 (AC1–AC10)
// =========================================================================

#[test]
fn r61_prompts_are_never_constructed_when_gated_off() {
    let tmp = TempDir::new().expect("temp dir");
    let cfg_path = tmp.path().join("rslbp_config.toml");
    fs::write(&cfg_path, "[output]\nformat = \"table\"\n").expect("seed config");

    let port = Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
    let env = MapEnv::default();
    let prompter = ScriptedPrompter::forbid_all();
    let clipboard = RecordingClipboard::new();

    let run_case = |argv: &[&str]| {
        let mut out = Vec::new();
        let mut err = Vec::new();
        let res = {
            let mut rt = CliRuntime {
                env: &env,
                cwd: tmp.path().to_path_buf(),
                paths: temp_paths(&tmp),
                terminal: TerminalState {
                    stdin_is_tty: true,
                    stdout_is_tty: true,
                    stderr_is_tty: true,
                    hyperlinks_override: Some(false),
                },
                stdin_token: None,
                credential_store: None,
                injected_port: Some(Arc::clone(&port) as _),
                port_factory: None,
                prompter: &prompter,
                clipboard: &clipboard,
                stdout: &mut out,
                stderr: &mut err,
                on_telemetry: None,
                allow_spawn_pager: false,
            };
            execute_cli(&mut rt, &args(argv))
        };
        (res, out, err)
    };

    // 1. project delete under --no-input (even with TTY=true) -> RSLB205, zero prompt called.
    let (res, _, _) = run_case(&["project", "delete", "p1", "--no-input"]);
    match res {
        Err(CliError::Domain { error, .. }) => {
            assert_eq!(error.error_code(), ErrorCode::InputUnavailable);
            assert_eq!(Exit::from_domain_error(&error), Exit::Usage);
        }
        other => panic!("expected InputUnavailable, got {other:?}"),
    }

    // 2. project delete --dry-run and project create --dry-run never prompt or mutate port.
    let (res, _, err) = run_case(&["project", "delete", "p1", "--dry-run"]);
    assert_eq!(res.expect("dry-run delete"), Exit::Success);
    assert!(String::from_utf8_lossy(&err).contains("[dry-run]"));

    let (res, _, _) = run_case(&["project", "create", "Preview", "--dry-run"]);
    assert_eq!(res.expect("dry-run create"), Exit::Success);
    assert_eq!(
        port.list(&ProjectQuery::default()).unwrap().len(),
        2,
        "dry-run must not mutate port"
    );

    // 3. config set --dry-run evaluates BEFORE overwrite confirmation (R61 AC10).
    let (res, _, _) = run_case(&[
        "config",
        "set",
        "output.format",
        "json",
        "--config",
        cfg_path.to_str().unwrap(),
        "--dry-run",
    ]);
    assert_eq!(res.expect("config set dry-run"), Exit::Success);

    // 4. config set with identical value does not prompt even without --yes.
    let (res, _, _) = run_case(&[
        "config",
        "set",
        "output.format",
        "table",
        "--config",
        cfg_path.to_str().unwrap(),
    ]);
    assert_eq!(res.expect("idempotent config set"), Exit::Success);
}

#[test]
fn r61_interactive_delete_confirm_decline_esc_ctrl_c_and_error_variants() {
    let tmp = TempDir::new().expect("temp dir");
    let env = MapEnv::default();
    let clipboard = RecordingClipboard::new();

    let run_delete = |answer: Result<Option<bool>, PromptError>, quiet: bool| {
        let port = Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
        let prompter = ScriptedPrompter::new([ScriptedAnswer::Confirm(answer)]);
        let mut out = Vec::new();
        let mut err = Vec::new();
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: TerminalState {
                stdin_is_tty: true,
                stdout_is_tty: true,
                stderr_is_tty: true,
                hyperlinks_override: Some(false),
            },
            stdin_token: None,
            credential_store: None,
            injected_port: Some(Arc::clone(&port) as _),
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let mut argv = vec!["project", "delete", "p1"];
        if quiet {
            argv.push("--quiet");
        }
        let res = execute_cli(&mut rt, &args(&argv));
        (res, port.list(&ProjectQuery::default()).unwrap(), out, err)
    };

    // OV-02: declined confirmation exits 0 and does NOT delete.
    let (res, snap, out, err) = run_delete(Ok(Some(false)), false);
    assert_eq!(res.expect("OV-02 decline exits 0"), Exit::Success);
    assert_eq!(snap.len(), 2);
    assert!(out.is_empty());
    assert!(String::from_utf8_lossy(&err).contains("Aborted."));

    // ESC cancellation (Ok(None)) exits 0 cleanly and respects --quiet.
    let (res, snap, _, err) = run_delete(Ok(None), true);
    assert_eq!(res.expect("ESC exits 0"), Exit::Success);
    assert_eq!(snap.len(), 2);
    assert!(err.is_empty());

    // Accepted confirmation deletes p1.
    let (res, snap, _, _) = run_delete(Ok(Some(true)), false);
    assert_eq!(res.expect("confirm true deletes"), Exit::Success);
    assert_eq!(snap.len(), 1);
    assert_eq!(snap[0].id, "p2");

    // Ctrl-C -> RSLB903 / exit 130.
    let (res, _, _, _) = run_delete(Err(PromptError::Interrupted), false);
    match res {
        Err(err @ CliError::PromptInterrupted { .. }) => {
            let mut ebuf = Vec::new();
            assert_eq!(emit_cli_error(&err, &mut ebuf), Exit::SigInt);
            assert!(String::from_utf8_lossy(&ebuf).contains("RSLB903"));
        }
        other => panic!("expected PromptInterrupted, got {other:?}"),
    }

    // Defence-in-depth NotTty -> RSLB205 / exit 2.
    let (res, _, _, _) = run_delete(Err(PromptError::NotTty), false);
    match res {
        Err(CliError::Domain { error, .. }) => {
            assert_eq!(error.error_code(), ErrorCode::InputUnavailable);
            assert_eq!(Exit::from_domain_error(&error), Exit::Usage);
        }
        other => panic!("expected InputUnavailable, got {other:?}"),
    }

    // IO failure -> RSLB101 / exit 1.
    let (res, _, _, _) = run_delete(Err(PromptError::Io(io::Error::other("tty err"))), false);
    match res {
        Err(CliError::Domain { error, .. }) => {
            assert_eq!(error.error_code(), ErrorCode::Io);
            assert_eq!(Exit::from_domain_error(&error), Exit::Runtime);
        }
        other => panic!("expected Io, got {other:?}"),
    }

    // Unexpected prompt configuration error -> CliError::Unexpected.
    let (res, _, _, _) = run_delete(Err(PromptError::Unexpected("bad cfg".to_owned())), false);
    assert!(matches!(res, Err(CliError::Unexpected { .. })));
}

#[test]
fn r61_interactive_config_set_init_and_project_select_narrowing() {
    let tmp = TempDir::new().expect("temp dir");
    let cfg_path = tmp.path().join("rslbp_config.toml");
    let env = MapEnv::default();
    let clipboard = RecordingClipboard::new();
    let tty = TerminalState {
        stdin_is_tty: true,
        stdout_is_tty: true,
        stderr_is_tty: true,
        hyperlinks_override: Some(false),
    };

    // 1. config init interactive ESC cancels cleanly without writing file.
    {
        let prompter = ScriptedPrompter::new([
            ScriptedAnswer::Select(Ok(Some("json".to_owned()))),
            ScriptedAnswer::Select(Ok(None)),
        ]);
        let mut out = Vec::new();
        let mut err = Vec::new();
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: tty,
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let exit = execute_cli(
            &mut rt,
            &args(&["config", "init", "--config", cfg_path.to_str().unwrap()]),
        )
        .expect("init ESC exits 0");
        assert_eq!(exit, Exit::Success);
        assert!(!cfg_path.exists());
    }

    // 2. config init interactive completes and writes chosen values.
    {
        let prompter = ScriptedPrompter::new([
            ScriptedAnswer::Select(Ok(Some("markdown".to_owned()))),
            ScriptedAnswer::Select(Ok(Some("never".to_owned()))),
            ScriptedAnswer::Select(Ok(Some("info".to_owned()))),
        ]);
        let mut out = Vec::new();
        let mut err = Vec::new();
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: tty,
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let exit = execute_cli(
            &mut rt,
            &args(&["config", "init", "--config", cfg_path.to_str().unwrap()]),
        )
        .expect("init writes config");
        assert_eq!(exit, Exit::Success);
        let raw = fs::read_to_string(&cfg_path).expect("read config");
        assert!(raw.contains("markdown") && raw.contains("never") && raw.contains("info"));
    }

    // 3. config set interactive overwrite declined -> exit 0, file unchanged.
    {
        let prompter = ScriptedPrompter::new([ScriptedAnswer::Confirm(Ok(Some(false)))]);
        let mut out = Vec::new();
        let mut err = Vec::new();
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: tty,
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let exit = execute_cli(
            &mut rt,
            &args(&[
                "config",
                "set",
                "output.format",
                "json",
                "--config",
                cfg_path.to_str().unwrap(),
            ]),
        )
        .expect("declined overwrite exits 0");
        assert_eq!(exit, Exit::Success);
        assert!(fs::read_to_string(&cfg_path).unwrap().contains("markdown"));
    }

    // 4. project list --select narrowing (selected subset, empty selection, NotTty fallback, ^C).
    let port = Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
    let run_select = |ans: Result<Option<Vec<usize>>, PromptError>| {
        let prompter = ScriptedPrompter::new([ScriptedAnswer::MultiSelect(ans)]);
        let mut out = Vec::new();
        let mut err = Vec::new();
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: tty,
            stdin_token: None,
            credential_store: None,
            injected_port: Some(Arc::clone(&port) as _),
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let res = execute_cli(
            &mut rt,
            &args(&["project", "list", "--select", "-o", "name"]),
        );
        (
            res,
            String::from_utf8(out).unwrap(),
            String::from_utf8(err).unwrap(),
        )
    };

    let (res, out, _) = run_select(Ok(Some(vec![1])));
    assert_eq!(res.expect("narrowed list"), Exit::Success);
    assert_eq!(out, "p2\n");

    let (res, out, err) = run_select(Ok(Some(vec![])));
    assert_eq!(res.expect("empty selection"), Exit::Success);
    assert!(out.is_empty());
    assert!(err.contains("No project entries selected."));

    let (res, out, _) = run_select(Err(PromptError::NotTty));
    assert_eq!(res.expect("NotTty narrowing fallback"), Exit::Success);
    assert_eq!(out, "p1\np2\n");

    let (res, _, _) = run_select(Err(PromptError::Interrupted));
    assert!(matches!(res, Err(CliError::PromptInterrupted { .. })));
}

// =========================================================================
// R62 — Additive `--copy` clipboard ordering & partial failure
// =========================================================================

#[test]
fn r62_copy_writes_after_primary_sink_and_failure_leaves_stdout_intact() {
    let tmp = TempDir::new().expect("temp dir");
    let port = Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
    let env = MapEnv::default();
    let prompter = ScriptedPrompter::forbid_all();

    // Success path: stdout + clipboard both receive exact rendered bytes; stderr note emitted.
    let recorder = RecordingClipboard::new();
    let mut out = Vec::new();
    let mut err = Vec::new();
    {
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: TerminalState::default(),
            stdin_token: None,
            credential_store: None,
            injected_port: Some(Arc::clone(&port) as _),
            port_factory: None,
            prompter: &prompter,
            clipboard: &recorder,
            stdout: &mut out,
            stderr: &mut err,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let exit = execute_cli(&mut rt, &args(&["project", "list", "-o", "name", "--copy"]))
            .expect("copy succeeds");
        assert_eq!(exit, Exit::Success);
    }
    assert_eq!(String::from_utf8(out).unwrap(), "p1\np2\n");
    assert_eq!(recorder.copied(), vec!["p1\np2\n".to_owned()]);
    assert!(
        String::from_utf8(err)
            .unwrap()
            .contains("Copied to clipboard.")
    );

    // Failing clipboard path: stdout STILL holds full output; returns RSLB101 / exit 1.
    let failing = FailingClipboard::new("display server unavailable", None);
    let mut out2 = Vec::new();
    let mut err2 = Vec::new();
    let res = {
        let mut rt = CliRuntime {
            env: &env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: TerminalState::default(),
            stdin_token: None,
            credential_store: None,
            injected_port: Some(port as _),
            port_factory: None,
            prompter: &prompter,
            clipboard: &failing,
            stdout: &mut out2,
            stderr: &mut err2,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        execute_cli(&mut rt, &args(&["project", "list", "-o", "name", "--copy"]))
    };
    assert_eq!(
        String::from_utf8(out2).unwrap(),
        "p1\np2\n",
        "R62: primary stdout must stay intact when clipboard fails"
    );
    match res {
        Err(err @ CliError::Clipboard { .. }) => {
            let mut ebuf = Vec::new();
            assert_eq!(emit_cli_error(&err, &mut ebuf), Exit::Runtime);
            assert!(String::from_utf8_lossy(&ebuf).contains("RSLB101"));
        }
        other => panic!("expected CliError::Clipboard, got {other:?}"),
    }

    // Direct clipboard error helper check.
    let ce = ClipboardError::unavailable("headless", Some("pipe instead".to_owned()));
    assert_eq!(ce.hint().as_deref(), Some("pipe instead"));
    assert!(failing.set_text("x").is_err());
}

// =========================================================================
// R64 — 2-tier shlex pager resolution & stub-pager subprocess contract
// =========================================================================

#[test]
fn r64_pager_resolution_and_stub_pager_subprocess_contract() {
    let empty = MapEnv::default();
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &empty),
        Some(vec!["less".to_owned(), "-FRX".to_owned()])
    );
    assert_eq!(DEFAULT_PAGER, "less -FRX");

    // Disabled when pager_disabled, non-TTY, or machine format.
    assert_eq!(
        resolve_pager_argv(true, OutputFormat::Table, true, &empty),
        None
    );
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, false, &empty),
        None
    );
    for machine in [
        OutputFormat::Json,
        OutputFormat::Markdown,
        OutputFormat::Name,
    ] {
        assert_eq!(resolve_pager_argv(false, machine, true, &empty), None);
    }

    // RSLBP_PAGER beats PAGER; empty string & `cat` disable; unbalanced quotes fall back.
    let env_both = MapEnv::from_pairs([("RSLBP_PAGER", "more -s"), ("PAGER", "less -R")]);
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &env_both),
        Some(vec!["more".to_owned(), "-s".to_owned()])
    );
    let env_cat = MapEnv::from_pairs([("RSLBP_PAGER", "/bin/cat")]);
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &env_cat),
        None
    );
    let env_empty = MapEnv::from_pairs([("RSLBP_PAGER", "  ")]);
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &env_empty),
        None
    );
    let env_bad_quote = MapEnv::from_pairs([("RSLBP_PAGER", "less 'unterminated")]);
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &env_bad_quote),
        None
    );

    // Missing binary returns None cleanly.
    assert!(PagerWriter::try_spawn(&["nonexistent-rslbp-pager-xyz".to_owned()], &empty).is_none());

    // Stub pager script verifying stdin payload passthrough + LESS/LV injection & preservation.
    let tmp = TempDir::new().expect("temp dir");
    let capture_in = tmp.path().join("stdin.txt");
    let capture_env = tmp.path().join("env.txt");
    let script_path = tmp.path().join("stub-pager.sh");
    let script = format!(
        "#!/bin/sh\nprintf 'LESS=%s\\nLV=%s\\n' \"$LESS\" \"$LV\" > \"{}\"\ncat > \"{}\"\n",
        capture_env.display(),
        capture_in.display()
    );
    fs::write(&script_path, script).expect("write stub pager");
    let mut perms = fs::metadata(&script_path).unwrap().permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&script_path, perms).unwrap();

    // Case 1: LESS & LV unset in caller env -> injected as FRX and -c.
    {
        use std::io::Write;
        let mut pager = PagerWriter::try_spawn(&[script_path.display().to_string()], &empty)
            .expect("spawn stub pager");
        pager
            .write_all(b"\x1b[1mHeader\x1b[0m\nRow1\n")
            .expect("write to pager");
        pager.flush().expect("flush pager");
        pager.finish();
    }
    assert_eq!(
        fs::read(&capture_in).unwrap(),
        b"\x1b[1mHeader\x1b[0m\nRow1\n"
    );
    let env_out = fs::read_to_string(&capture_env).unwrap();
    assert!(
        env_out.contains("LESS=FRX"),
        "expected LESS=FRX, got {env_out}"
    );
    assert!(env_out.contains("LV=-c"), "expected LV=-c, got {env_out}");

    // Case 2: Caller explicitly sets LESS & LV -> pager respects caller values.
    let custom_env = MapEnv::from_pairs([("LESS", "-R"), ("LV", "-u")]);
    {
        use std::io::Write;
        let mut pager = PagerWriter::try_spawn(&[script_path.display().to_string()], &custom_env)
            .expect("spawn stub pager");
        pager.write_all(b"second\n").expect("write");
        // Rely on Drop to close stdin before waiting.
    }
    let env_out2 = fs::read_to_string(&capture_env).unwrap();
    assert!(
        !env_out2.contains("LESS=FRX"),
        "PagerWriter must not inject LESS=FRX when caller already set LESS: {env_out2}"
    );
    assert!(
        !env_out2.contains("LV=-c"),
        "PagerWriter must not inject LV=-c when caller already set LV: {env_out2}"
    );
}

// =========================================================================
// R66 & R85 — Output rendering, atomic file write, OSC-8 width equality, relative_time
// =========================================================================

#[test]
fn r66_and_r85_views_adversarial_cells_osc8_width_equality_and_relative_time() {
    // resolve_output_format precedence & mutual exclusion.
    assert_eq!(
        resolve_output_format(None, Some(OutputFormat::Name), false, OutputFormat::Json).unwrap(),
        OutputFormat::Name
    );
    assert_eq!(
        resolve_output_format(None, None, true, OutputFormat::Table).unwrap(),
        OutputFormat::Json
    );
    assert!(
        resolve_output_format(Some(OutputFormat::Json), None, true, OutputFormat::Table).is_err()
    );

    // Adversarial cells across all 4 formats.
    let adversarial = ProjectListView {
        projects: vec![Project {
            id: "id|1\n".to_owned(),
            name: "A|B\\C\"D,E\nF\x1b[31mred\x1b[0m".to_owned(),
            workspace: Some("ws\\|x".to_owned()),
        }],
    };
    for fmt in [
        OutputFormat::Table,
        OutputFormat::Json,
        OutputFormat::Markdown,
        OutputFormat::Name,
    ] {
        let mut buf = Vec::new();
        render_view(&adversarial, fmt, TermCaps::plain(), &mut buf).expect("render adversarial");
        assert!(
            !buf.contains(&0x1b),
            "plain render for {fmt:?} must never contain raw ESC: {:?}",
            String::from_utf8_lossy(&buf)
        );
    }
    assert_eq!(escape_markdown_cell("a|b\\c\nd"), r"a\|b\\c d");

    // All view types render cleanly in all 4 formats.
    let tmp = TempDir::new().expect("temp dir");
    let abs_cfg = tmp.path().join("rslbp_config.toml");
    let cfg_path_view = ConfigPathView {
        path: abs_cfg.clone(),
        exists: true,
    };
    let deleted_view = ProjectDeletedView {
        id: "p1".to_owned(),
        dry_run: false,
    };
    let val_view = ConfigValueView {
        key: "output.format".to_owned(),
        value: Some("table".to_owned()),
        source: "default".to_owned(),
    };
    let show_view = ConfigShowView {
        entries: vec![val_view.clone()],
        sources: vec![abs_cfg.display().to_string()],
    };
    let ver_view = VersionView {
        build: rs_launch_blueprint_cli::build_info(),
    };
    let diag_view = DiagnosticsReportView {
        checks: vec![DiagnosticCheck {
            name: "version".to_owned(),
            status: "ok",
            detail: "0.1.0".to_owned(),
        }],
    };
    let bundle_view = DiagnosticsBundleView {
        version: "0.1.0".to_owned(),
        target: "aarch64-apple-darwin".to_owned(),
        rustc: "1.100.1".to_owned(),
        checks: diag_view.checks.clone(),
        config_path: abs_cfg.display().to_string(),
        config_exists: true,
        loaded_paths: vec![],
        token_present: false,
        token_source: None,
        env: std::collections::BTreeMap::new(),
        log_file: tmp.path().join("rslbp.log").display().to_string(),
    };

    let views: [&dyn rs_launch_blueprint_cli::CliView; 7] = [
        &cfg_path_view,
        &deleted_view,
        &val_view,
        &show_view,
        &ver_view,
        &diag_view,
        &bundle_view,
    ];
    for view in views {
        for fmt in [
            OutputFormat::Table,
            OutputFormat::Json,
            OutputFormat::Markdown,
            OutputFormat::Name,
        ] {
            let mut buf = Vec::new();
            render_view(view, fmt, TermCaps::plain(), &mut buf).expect("render view");
            if fmt == OutputFormat::Json {
                let _: serde_json::Value = serde_json::from_slice(&buf).expect("valid JSON view");
            }
        }
    }

    // R85 AC1–AC4: ConfigPathView OSC-8 hyperlinks in table only, identical visible column widths!
    let mut table_plain = Vec::new();
    let mut table_rich = Vec::new();
    render_view(
        &cfg_path_view,
        OutputFormat::Table,
        TermCaps {
            color: false,
            hyperlinks: false,
        },
        &mut table_plain,
    )
    .expect("plain table");
    render_view(
        &cfg_path_view,
        OutputFormat::Table,
        TermCaps {
            color: false,
            hyperlinks: true,
        },
        &mut table_rich,
    )
    .expect("rich table");
    let plain_s = String::from_utf8(table_plain).unwrap();
    let rich_s = String::from_utf8(table_rich).unwrap();
    assert!(!plain_s.contains("\x1b]8;;"));
    assert!(
        rich_s.contains("\x1b]8;;file://"),
        "expected OSC-8 link: {rich_s}"
    );
    assert_eq!(
        strip_osc8(&rich_s),
        plain_s,
        "R85 AC4: tabled column widths must be identical with vs without OSC-8 hyperlinks"
    );

    // R85 AC5: control escaping & URL percent encoding.
    assert_eq!(escape_label("a[b] \x1b[31m\x07"), r"a[b] \u{1b}[31m\u{7}");
    assert_eq!(
        sanitize_url("https://example.com/a b\x1bc"),
        "https://example.com/a%20b%1Bc"
    );
    assert!(!format_osc8_link("doc", "https://example.com", false).contains('\x1b'));
    assert!(
        format_osc8_link("doc", "https://example.com", true)
            .contains("\x1b]8;;https://example.com\x1b\\")
    );
    assert!(!format_file_link(std::path::Path::new("relative/path.toml"), true).contains('\x1b'));

    // R85 AC6: relative_time buckets (past & future).
    let now = 1_700_000_000_i64;
    assert_eq!(relative_time(now - 30, now), "just now");
    assert_eq!(relative_time(now + 30, now), "just now");
    assert_eq!(relative_time(now - 60, now), "1 minute ago");
    assert_eq!(relative_time(now - 300, now), "5 minutes ago");
    assert_eq!(relative_time(now - 3_600, now), "1 hour ago");
    assert_eq!(relative_time(now - 10_800, now), "3 hours ago");
    assert_eq!(relative_time(now - 86_400, now), "1 day ago");
    assert_eq!(relative_time(now - 2 * 86_400, now), "2 days ago");
    assert_eq!(relative_time(now - 30 * 86_400, now), "1 month ago");
    assert_eq!(relative_time(now - 60 * 86_400, now), "2 months ago");
    assert_eq!(relative_time(now - 365 * 86_400, now), "1 year ago");
    assert_eq!(relative_time(now - 730 * 86_400, now), "2 years ago");
    assert_eq!(relative_time(now + 2 * 86_400, now), "in 2 days");

    // R66 AC12: atomic replacement leaves zero temp files in parent directory.
    let target = tmp.path().join("atomic.json");
    write_output_file_atomic(&target, b"first", false).expect("first write");
    write_output_file_atomic(&target, b"second", false).expect("atomic replace");
    assert_eq!(fs::read(&target).unwrap(), b"second");
    let leftover: Vec<_> = fs::read_dir(tmp.path())
        .unwrap()
        .filter_map(Result::ok)
        .filter(|e| e.file_name().to_string_lossy().contains(".rslbp-out-"))
        .collect();
    assert!(leftover.is_empty(), "temp files leaked: {leftover:?}");

    // Colored stderr error rendering.
    let mut colored_err = Vec::new();
    render_error(
        ErrorCode::Usage,
        "bad flag",
        Some("try --help"),
        OutputFormat::Table,
        true,
        &mut colored_err,
    )
    .expect("render colored err");
    assert!(colored_err.contains(&0x1b));
}

// =========================================================================
// R67 — Binary error boundary precedence & 0600 NDJSON crash sink
// =========================================================================

#[test]
fn r67_binary_boundary_precedence_and_crash_sink_0600_contract() {
    let tmp = TempDir::new().expect("temp dir");
    let crash_path = tmp.path().join("state").join("rslbp_crash.jsonl");
    let sink = FileCrashSink::new(&crash_path);
    assert_eq!(sink.path(), crash_path);

    let f = AtomicBool::new(false);
    let t = AtomicBool::new(true);

    // 1. SIGINT beats BrokenPipe and Unexpected; crash sink untouched.
    let mut out = Vec::new();
    let mut err = Vec::new();
    let exit = resolve_binary_boundary(
        Err(anyhow::Error::new(CliError::BrokenPipe)),
        &t,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::SigInt);
    assert!(!crash_path.exists());

    // 2. SIGTERM beats errors -> Exit::SigTerm (143).
    let exit = resolve_binary_boundary(
        Err(anyhow::anyhow!("boom")),
        &f,
        &t,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::SigTerm);
    assert!(!crash_path.exists());

    // 3. BrokenPipe (both CliError::BrokenPipe and raw io::ErrorKind::BrokenPipe) -> exit 0 silent.
    err.clear();
    let exit = resolve_binary_boundary(
        Err(anyhow::Error::new(CliError::BrokenPipe)),
        &f,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::Success);
    assert!(err.is_empty());

    let exit = resolve_binary_boundary(
        Err(anyhow::Error::new(io::Error::new(
            io::ErrorKind::BrokenPipe,
            "epipe",
        ))),
        &f,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::Success);
    assert!(err.is_empty());

    // 4. Typed DomainError downcast -> domain exit code, crash sink NOT called.
    err.clear();
    let exit = resolve_binary_boundary(
        Err(anyhow::Error::new(DomainError::NotFound {
            kind: "project",
            id: "p9".to_owned(),
        })),
        &f,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::NotFound);
    assert!(String::from_utf8_lossy(&err).contains("RSLB301"));
    assert!(
        !crash_path.exists(),
        "domain errors must never write crash sink"
    );

    // 5. Unexpected error -> RSLB000, exit 1, 0600 NDJSON crash record written with sanitized causes.
    err.clear();
    let exit = resolve_binary_boundary(
        Err(anyhow::anyhow!("unexpected boom\x1b[31m")),
        &f,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::Runtime);
    assert!(String::from_utf8_lossy(&err).contains("RSLB000"));
    assert!(crash_path.exists());
    let mode = fs::metadata(&crash_path).unwrap().permissions().mode() & 0o777;
    assert_eq!(mode, 0o600, "R67: crash log must be 0600, got {mode:o}");
    let line = fs::read_to_string(&crash_path).unwrap();
    let rec: CrashRecord = serde_json::from_str(line.trim()).expect("valid crash NDJSON");
    assert_eq!(rec.code, "RSLB000");
    assert_eq!(rec.version, rs_launch_blueprint::VERSION);
    assert!(!rec.causes[0].contains('\x1b'));

    // 6. CliError::Unexpected also records crash sink.
    let exit = resolve_binary_boundary(
        Err(anyhow::Error::new(CliError::Unexpected {
            message: "internal glitch".to_owned(),
            format: OutputFormat::Json,
            stderr_color: false,
            causes: vec!["cause-1".to_owned()],
        })),
        &f,
        &f,
        &sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::Runtime);
    assert_eq!(fs::read_to_string(&crash_path).unwrap().lines().count(), 2);

    // 7. Unwritable crash sink swallows I/O error without changing exit code or stderr.
    let blocker = tmp.path().join("not-a-dir");
    fs::write(&blocker, b"file").unwrap();
    let broken_sink = FileCrashSink::new(blocker.join("crash.jsonl"));
    err.clear();
    let exit = resolve_binary_boundary(
        Err(anyhow::anyhow!("still handled")),
        &f,
        &f,
        &broken_sink,
        &mut out,
        &mut err,
    );
    assert_eq!(exit, Exit::Runtime);
    assert!(String::from_utf8_lossy(&err).contains("RSLB000"));

    // NoopCrashSink & emit_cli_error helpers.
    NoopCrashSink.record(&CrashRecord::unexpected(vec!["x".to_owned()]));
    let mut ebuf = Vec::new();
    assert_eq!(
        emit_cli_error(&CliError::BrokenPipe, &mut ebuf),
        Exit::Success
    );
    assert_eq!(
        run(workspace_info(), &["--version".to_owned()]),
        std::process::ExitCode::SUCCESS
    );

    // Verify env-driven RSLBP_OUTPUT invalid usage error, --no-color + --color conflict, no subcommand.
    let bad_env = MapEnv::from_pairs([("RSLBP_OUTPUT", "bogus"), ("OTHER", "1")]);
    let mut out_bad = Vec::new();
    let mut err_bad = Vec::new();
    let prompter = ScriptedPrompter::forbid_all();
    let clipboard = RecordingClipboard::new();
    let mut rt = CliRuntime {
        env: &bad_env,
        cwd: tmp.path().to_path_buf(),
        paths: temp_paths(&tmp),
        terminal: TerminalState::default(),
        stdin_token: None,
        credential_store: None,
        injected_port: None,
        port_factory: None,
        prompter: &prompter,
        clipboard: &clipboard,
        stdout: &mut out_bad,
        stderr: &mut err_bad,
        on_telemetry: None,
        allow_spawn_pager: false,
    };
    let res = execute_cli(&mut rt, &args(&["config", "path"]));
    assert!(matches!(
        res,
        Err(CliError::Domain {
            error: DomainError::Usage { .. },
            ..
        })
    ));

    let empty_env = MapEnv::default();
    rt.env = &empty_env;
    let res = execute_cli(
        &mut rt,
        &args(&["--no-color", "--color", "always", "version"]),
    );
    assert!(matches!(
        res,
        Err(CliError::Domain {
            error: DomainError::Usage { .. },
            ..
        })
    ));
    let res = execute_cli(&mut rt, &args(&[]));
    assert!(matches!(
        res,
        Err(CliError::Domain {
            error: DomainError::Usage { .. },
            ..
        })
    ));

    // CliError Display & std::error::Error::source across all 5 variants.
    use std::error::Error as _;
    let bp = CliError::BrokenPipe;
    assert_eq!(bp.to_string(), "broken pipe");
    assert!(bp.source().is_none());
    let dom = CliError::Domain {
        error: DomainError::NotFound {
            kind: "project",
            id: "missing".to_owned(),
        },
        format: OutputFormat::Table,
        stderr_color: false,
    };
    assert!(!dom.to_string().is_empty());
    assert!(dom.source().is_some());
    let clip = CliError::Clipboard {
        error: ClipboardError::unavailable("headless", Some("pipe instead".to_owned())),
        format: OutputFormat::Table,
        stderr_color: false,
    };
    assert!(!clip.to_string().is_empty());
    assert!(clip.source().is_some());
    let interrupted = CliError::PromptInterrupted {
        format: OutputFormat::Table,
        stderr_color: false,
    };
    assert_eq!(interrupted.to_string(), "prompt interrupted");
    assert!(interrupted.source().is_none());
    let unexp = CliError::Unexpected {
        message: "oops".to_owned(),
        format: OutputFormat::Table,
        stderr_color: false,
        causes: vec![],
    };
    assert_eq!(unexp.to_string(), "oops");
    assert!(unexp.source().is_none());

    // Additional execute_cli branches: empty project name, config get unknown/unset token,
    // config set accepted overwrite + interrupted, diagnostics error & bundle via MapEnv,
    // missing port_factory, pager delivery, and failing stdout writer.
    let port = Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
    let cfg_path = tmp.path().join("extra.toml");
    fs::write(&cfg_path, "[output]\nformat = \"table\"\n").unwrap();
    let cfg_s = cfg_path.to_str().unwrap();

    let run_with = |env_ref: &MapEnv,
                    prompter_ref: &ScriptedPrompter,
                    port_opt: Option<Arc<dyn ProjectsPort>>,
                    tty: TerminalState,
                    allow_pager: bool,
                    argv: &[&str]| {
        let mut out = Vec::new();
        let mut err = Vec::new();
        let res = {
            let mut rt2 = CliRuntime {
                env: env_ref,
                cwd: tmp.path().to_path_buf(),
                paths: temp_paths(&tmp),
                terminal: tty,
                stdin_token: None,
                credential_store: None,
                injected_port: port_opt,
                port_factory: None,
                prompter: prompter_ref,
                clipboard: &clipboard,
                stdout: &mut out,
                stderr: &mut err,
                on_telemetry: None,
                allow_spawn_pager: allow_pager,
            };
            execute_cli(&mut rt2, &args(argv))
        };
        (res, out, err)
    };

    let tty_on = TerminalState {
        stdin_is_tty: true,
        stdout_is_tty: true,
        stderr_is_tty: true,
        hyperlinks_override: Some(false),
    };

    // Empty project name -> Usage error.
    let (r, _, _) = run_with(
        &empty_env,
        &prompter,
        Some(Arc::clone(&port) as _),
        TerminalState::default(),
        false,
        &["project", "create", "   "],
    );
    assert!(matches!(
        r,
        Err(CliError::Domain {
            error: DomainError::Usage { .. },
            ..
        })
    ));

    // project list --workspace & --limit & select Io/Unexpected errors.
    let (r, out_ws, _) = run_with(
        &empty_env,
        &prompter,
        Some(Arc::clone(&port) as _),
        TerminalState::default(),
        false,
        &[
            "project",
            "list",
            "--workspace",
            "Core",
            "--limit",
            "1",
            "-o",
            "name",
        ],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    assert_eq!(String::from_utf8(out_ws).unwrap(), "p1\n");

    let p_io = ScriptedPrompter::new([ScriptedAnswer::MultiSelect(Err(PromptError::Io(
        io::Error::other("io"),
    )))]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_io,
        Some(Arc::clone(&port) as _),
        tty_on,
        false,
        &["project", "list", "--select"],
    );
    assert!(matches!(r, Err(CliError::Domain { .. })));

    let p_unexp = ScriptedPrompter::new([ScriptedAnswer::MultiSelect(Err(
        PromptError::Unexpected("bad".to_owned()),
    ))]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_unexp,
        Some(Arc::clone(&port) as _),
        tty_on,
        false,
        &["project", "list", "--select"],
    );
    assert!(matches!(r, Err(CliError::Unexpected { .. })));

    // config get unknown key & unset token.
    let (r, _, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["config", "get", "no.such.key"],
    );
    assert!(matches!(r, Err(CliError::Domain { .. })));
    let (r, out_tok, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["config", "get", "token", "--json"],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    assert!(String::from_utf8(out_tok).unwrap().contains("\"none\""));

    // config set overwrite accepted + interrupted.
    let p_yes = ScriptedPrompter::new([ScriptedAnswer::Confirm(Ok(Some(true)))]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_yes,
        None,
        tty_on,
        false,
        &["config", "set", "output.format", "json", "--config", cfg_s],
    );
    assert_eq!(r.unwrap(), Exit::Success);

    let p_int = ScriptedPrompter::new([ScriptedAnswer::Confirm(Err(PromptError::Interrupted))]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_int,
        None,
        tty_on,
        false,
        &["config", "set", "output.format", "table", "--config", cfg_s],
    );
    assert!(matches!(r, Err(CliError::PromptInterrupted { .. })));

    // config init interrupted + interactive --dry-run.
    let p_init_int = ScriptedPrompter::new([ScriptedAnswer::Select(Err(PromptError::Interrupted))]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_init_int,
        None,
        tty_on,
        false,
        &["config", "init", "--config", cfg_s],
    );
    assert!(matches!(r, Err(CliError::PromptInterrupted { .. })));

    // diagnostics with failing token-file (Exit::Runtime) and --bundle with MapEnv.
    let bad_tok_dir = tmp.path().join("tok-dir");
    fs::create_dir_all(&bad_tok_dir).unwrap();
    let (r, _, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["diagnostics", "--token-file", bad_tok_dir.to_str().unwrap()],
    );
    assert_eq!(r.unwrap(), Exit::Runtime);

    let bundle_env =
        MapEnv::from_pairs([("RSLBP_TOKEN", "sk_secret_val"), ("RSLBP_OUTPUT", "json")]);
    let (r, out_b, _) = run_with(
        &bundle_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["diagnostics", "--bundle"],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    let b_str = String::from_utf8(out_b).unwrap();
    assert!(!b_str.contains("sk_secret_val") && b_str.contains("[REDACTED]"));

    // build_service without injected_port or port_factory -> Unavailable.
    let (r, _, _) = run_with(
        &bundle_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["project", "list"],
    );
    assert!(matches!(r, Err(CliError::Domain { .. })));

    // write_output_file_atomic error path (file as parent).
    assert!(write_output_file_atomic(&blocker.join("out.txt"), b"x", false).is_err());

    // Failing stdout writer (BrokenPipe & Other) + `run()` Domain error path.
    struct FailWriter(io::ErrorKind);
    impl io::Write for FailWriter {
        fn write(&mut self, _buf: &[u8]) -> io::Result<usize> {
            Err(io::Error::new(self.0, "write fail"))
        }
        fn flush(&mut self) -> io::Result<()> {
            Ok(())
        }
    }
    for kind in [io::ErrorKind::BrokenPipe, io::ErrorKind::PermissionDenied] {
        let mut fw = FailWriter(kind);
        let mut fe = Vec::new();
        let mut rt_f = CliRuntime {
            env: &empty_env,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: TerminalState::default(),
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut fw,
            stderr: &mut fe,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        let r = execute_cli(&mut rt_f, &args(&["version"]));
        assert!(r.is_err());
    }
    assert_ne!(
        run(workspace_info(), &["--nope-flag".to_owned()]),
        std::process::ExitCode::SUCCESS
    );

    // Pager path inside deliver_output via allow_spawn_pager: true + stub script.
    let pager_out = tmp.path().join("deliver-pager.txt");
    let pager_sh = tmp.path().join("deliver-pager.sh");
    fs::write(
        &pager_sh,
        format!("#!/bin/sh\ncat > \"{}\"\n", pager_out.display()),
    )
    .unwrap();
    let mut perms = fs::metadata(&pager_sh).unwrap().permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&pager_sh, perms).unwrap();
    let pager_env = MapEnv::from_pairs([("RSLBP_PAGER", pager_sh.to_str().unwrap())]);
    let (r, _, _) = run_with(
        &pager_env,
        &prompter,
        Some(Arc::clone(&port) as _),
        tty_on,
        true,
        &["project", "list"],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    assert!(fs::read_to_string(&pager_out).unwrap().contains("Alpha"));

    // Additional CLI rendering & dispatch branches:
    // - `--help` via execute_cli, `version -o markdown`, empty project list in Table/Markdown
    // - colored Table rendering (bold title + cyan headers), ConfigShowView with None entry,
    //   DiagnosticsBundleView with populated token/loaded_paths/env, CRLF escape_markdown_cell,
    //   render_error without hint under color=true and Markdown
    // - PAGER env fallback, parse_cli format sniffer tokens (-o=markdown, -o name, -o table)
    // - corrupt explicit --config error & discovered config warning emission.
    let (r, out_help, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["--help"],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    assert!(
        String::from_utf8(out_help)
            .unwrap()
            .contains("Usage: rslbp")
    );

    let (r, out_vmd, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["version", "-o", "markdown"],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    let vmd_text = String::from_utf8(out_vmd).unwrap();
    assert!(vmd_text.contains('|') && vmd_text.contains(rs_launch_blueprint::VERSION));

    let empty_port = Arc::new(InMemoryProjectsPort::new());
    for fmt_arg in ["table", "markdown"] {
        let (r, out_empty, _) = run_with(
            &empty_env,
            &prompter,
            Some(Arc::clone(&empty_port) as _),
            TerminalState::default(),
            false,
            &["project", "list", "-o", fmt_arg],
        );
        assert_eq!(r.unwrap(), Exit::Success);
        assert!(
            String::from_utf8(out_empty)
                .unwrap()
                .contains("No project entries found.")
        );
    }

    // Colored table rendering (bold title + cyan header).
    let mut colored_tbl = Vec::new();
    render_view(
        &ProjectListView {
            projects: sample_projects(),
        },
        OutputFormat::Table,
        TermCaps {
            color: true,
            hyperlinks: false,
        },
        &mut colored_tbl,
    )
    .expect("colored table");
    assert!(colored_tbl.contains(&0x1b));

    let show_none = ConfigShowView {
        entries: vec![ConfigValueView {
            key: "output.limit".to_owned(),
            value: None,
            source: "default".to_owned(),
        }],
        sources: vec![],
    };
    let mut show_buf = Vec::new();
    render_view(
        &show_none,
        OutputFormat::Table,
        TermCaps::plain(),
        &mut show_buf,
    )
    .unwrap();
    assert!(String::from_utf8(show_buf).unwrap().contains('-'));

    let mut env_map = std::collections::BTreeMap::new();
    env_map.insert("RSLBP_OUTPUT".to_owned(), "json".to_owned());
    let populated_bundle = DiagnosticsBundleView {
        version: "0.1.0".to_owned(),
        target: "t".to_owned(),
        rustc: "r".to_owned(),
        checks: vec![DiagnosticCheck {
            name: "token".to_owned(),
            status: "ok",
            detail: "present".to_owned(),
        }],
        config_path: "/tmp/c.toml".to_owned(),
        config_exists: false,
        loaded_paths: vec!["/tmp/c.toml".to_owned()],
        token_present: true,
        token_source: Some("env".to_owned()),
        env: env_map,
        log_file: "/tmp/l.log".to_owned(),
    };
    let mut b_tbl = Vec::new();
    render_view(
        &populated_bundle,
        OutputFormat::Table,
        TermCaps::plain(),
        &mut b_tbl,
    )
    .unwrap();
    assert!(String::from_utf8(b_tbl).unwrap().contains("present (env)"));

    assert_eq!(escape_markdown_cell("a\r\nb\rc"), "a b c");

    let mut err_no_hint = Vec::new();
    render_error(
        ErrorCode::NotFound,
        "missing",
        None,
        OutputFormat::Table,
        true,
        &mut err_no_hint,
    )
    .unwrap();
    render_error(
        ErrorCode::NotFound,
        "missing",
        Some("check id"),
        OutputFormat::Markdown,
        false,
        &mut err_no_hint,
    )
    .unwrap();

    // PAGER fallback when RSLBP_PAGER is absent.
    let only_pager = MapEnv::from_pairs([("PAGER", "more")]);
    assert_eq!(
        resolve_pager_argv(false, OutputFormat::Table, true, &only_pager),
        Some(vec!["more".to_owned()])
    );

    // parse_cli error format sniffing (-o=markdown, -o name, -o table).
    for flag_args in [
        &["-o=markdown", "--bad-unknown"][..],
        &["-o", "name", "--bad-unknown"][..],
        &["-o", "table", "--bad-unknown"][..],
    ] {
        let (r, _, _) = run_with(
            &empty_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            flag_args,
        );
        assert!(matches!(r, Err(CliError::Domain { .. })));
    }

    // Corrupt explicit --config returns Config error; unknown key in discovered config warns.
    let bad_cfg = tmp.path().join("bad.toml");
    fs::write(&bad_cfg, "[broken").unwrap();
    let (r, _, _) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["config", "path", "--config", bad_cfg.to_str().unwrap()],
    );
    assert!(matches!(r, Err(CliError::Domain { .. })));

    let warn_cfg = tmp.path().join("warn.toml");
    fs::write(&warn_cfg, "[output]\nunknown_setting = 1\n").unwrap();
    let (r, _, warn_err) = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["config", "show", "--config", warn_cfg.to_str().unwrap()],
    );
    assert_eq!(r.unwrap(), Exit::Success);
    assert!(String::from_utf8(warn_err).unwrap().contains("warning:"));

    // Additional coverage: RSLBP_CONFIG env var, on_telemetry hook with RSLBP_LOG_LEVEL & --log-level,
    // diagnostics --bundle with loaded config, color flags (--no-color, --color always, conflicts + --json),
    // version conflict, project create/delete non-dry-run, config get with loaded config,
    // interactive config init --dry-run, resolve_cli_token with stdin_token & loose 0644 credentials warning,
    // empty DiagnosticsReportView human_note, FailWriter JSON error (json_io_error),
    // write_output_file_atomic persist onto directory, and dead-pager fallback!
    let env_cfg = MapEnv::from_pairs([
        ("RSLBP_CONFIG", warn_cfg.to_str().unwrap()),
        ("RSLBP_LOG_LEVEL", "debug"),
        ("RSLBP_TOKEN", "sk_diag_token_999"),
    ]);
    let mut telemetry_seen = false;
    {
        let mut out_t = Vec::new();
        let mut err_t = Vec::new();
        let mut hook = |cfg: &rs_launch_blueprint_cli::ResolvedTelemetryConfig| {
            telemetry_seen = cfg.log_level_flag.is_some() && cfg.env_log_level.is_some();
        };
        let mut rt_t = CliRuntime {
            env: &env_cfg,
            cwd: tmp.path().to_path_buf(),
            paths: temp_paths(&tmp),
            terminal: TerminalState::default(),
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out_t,
            stderr: &mut err_t,
            on_telemetry: Some(&mut hook),
            allow_spawn_pager: false,
        };
        let exit = execute_cli(
            &mut rt_t,
            &args(&[
                "--log-level",
                "trace",
                "--no-color",
                "diagnostics",
                "--bundle",
            ]),
        )
        .expect("diagnostics bundle with telemetry hook");
        assert_eq!(exit, Exit::Success);
    }
    assert!(telemetry_seen);

    // Color flag combinations, --json error branches, version conflict, non-dry-run create/delete.
    let _ = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["--no-color", "--color", "always", "--json", "version"],
    );
    let _ = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["--color", "always", "config", "path"],
    );
    let _ = run_with(
        &bad_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["--json", "config", "path"],
    );
    let _ = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["version", "--json", "-o", "table"],
    );
    let _ = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &["--json"],
    );
    let _ = run_with(
        &empty_env,
        &prompter,
        Some(Arc::clone(&port) as _),
        TerminalState::default(),
        false,
        &["project", "create", "CreatedReal"],
    )
    .0
    .unwrap();
    let _ = run_with(
        &empty_env,
        &prompter,
        Some(Arc::clone(&port) as _),
        TerminalState::default(),
        false,
        &["project", "delete", "p2", "--yes"],
    )
    .0
    .unwrap();
    let _ = run_with(
        &empty_env,
        &prompter,
        None,
        TerminalState::default(),
        false,
        &[
            "config",
            "get",
            "output.format",
            "--config",
            warn_cfg.to_str().unwrap(),
        ],
    )
    .0
    .unwrap();

    // Interactive config init --dry-run.
    let p_init_dry = ScriptedPrompter::new([
        ScriptedAnswer::Select(Ok(Some("table".to_owned()))),
        ScriptedAnswer::Select(Ok(Some("auto".to_owned()))),
        ScriptedAnswer::Select(Ok(Some("warn".to_owned()))),
    ]);
    let (r, _, _) = run_with(
        &empty_env,
        &p_init_dry,
        None,
        tty_on,
        false,
        &["config", "init", "--dry-run", "--config", cfg_s],
    );
    assert_eq!(r.unwrap(), Exit::Success);

    // resolve_cli_token with injected stdin_token + loose 0644 credentials warning.
    let loose_paths = temp_paths(&tmp);
    fs::create_dir_all(loose_paths.credentials_file().parent().unwrap()).unwrap();
    fs::write(
        loose_paths.credentials_file(),
        "token = \"sk_loose_1234\"\n",
    )
    .unwrap();
    let mut lperms = fs::metadata(loose_paths.credentials_file())
        .unwrap()
        .permissions();
    lperms.set_mode(0o644);
    fs::set_permissions(loose_paths.credentials_file(), lperms).unwrap();
    {
        let mut out_l = Vec::new();
        let mut err_l = Vec::new();
        let mut rt_l = CliRuntime {
            env: &empty_env,
            cwd: tmp.path().to_path_buf(),
            paths: loose_paths.clone(),
            terminal: TerminalState::default(),
            stdin_token: Some("sk_injected_stdin".to_owned()),
            credential_store: None,
            injected_port: None,
            port_factory: None,
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut out_l,
            stderr: &mut err_l,
            on_telemetry: None,
            allow_spawn_pager: false,
        };
        assert_eq!(
            execute_cli(
                &mut rt_l,
                &args(&["config", "get", "token", "--token-file", "-"])
            )
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            execute_cli(&mut rt_l, &args(&["diagnostics"])).unwrap(),
            Exit::Success
        );
        assert!(String::from_utf8(err_l).unwrap().contains("warning:"));
    }

    // Empty DiagnosticsReportView triggers default CliView::human_note(); FailWriter triggers json_io_error.
    let empty_diag = DiagnosticsReportView { checks: vec![] };
    let mut ed_buf = Vec::new();
    render_view(
        &empty_diag,
        OutputFormat::Table,
        TermCaps::plain(),
        &mut ed_buf,
    )
    .unwrap();
    let mut fw_json = FailWriter(io::ErrorKind::Other);
    assert!(
        render_view(
            &empty_diag,
            OutputFormat::Json,
            TermCaps::plain(),
            &mut fw_json
        )
        .is_err()
    );
    assert!(
        render_error(
            ErrorCode::Usage,
            "m",
            None,
            OutputFormat::Json,
            false,
            &mut fw_json
        )
        .is_err()
    );

    // write_output_file_atomic persist onto an existing directory triggers persist error.
    let target_dir = tmp.path().join("existing-dir-target");
    fs::create_dir_all(&target_dir).unwrap();
    assert!(write_output_file_atomic(&target_dir, b"x", false).is_err());
    assert!(write_output_file_atomic(&target_dir, b"x", true).is_err());

    // Quiet branches, absent-token diagnostics, empty RSLBP_OUTPUT, pager broken-pipe, and tracing debug.
    let _ = fs::remove_file(loose_paths.credentials_file());
    let _ = fs::remove_file(loose_paths.config_file());
    let sub = tracing_subscriber::fmt()
        .with_max_level(tracing::Level::TRACE)
        .with_writer(io::sink)
        .finish();
    tracing::subscriber::with_default(sub, || {
        // Diagnostics with NO token configured + config show/get with no config file (default source).
        let (r, out_d, _) = run_with(
            &empty_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            &["diagnostics", "--json"],
        );
        assert_eq!(r.unwrap(), Exit::Success);
        assert!(String::from_utf8(out_d).unwrap().contains("not set"));

        let (r, _, _) = run_with(
            &empty_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            &["config", "show"],
        );
        assert_eq!(r.unwrap(), Exit::Success);

        let (r, _, _) = run_with(
            &empty_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            &["config", "get", "output.format"],
        );
        assert_eq!(r.unwrap(), Exit::Success);

        // Empty RSLBP_OUTPUT is treated as unset; bad flag with --output=json sniffs JSON error format.
        let empty_out_env = MapEnv::from_pairs([("RSLBP_OUTPUT", "")]);
        let (r, _, _) = run_with(
            &empty_out_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            &["config", "path"],
        );
        assert_eq!(r.unwrap(), Exit::Success);

        let (r, _, _) = run_with(
            &empty_env,
            &prompter,
            None,
            TerminalState::default(),
            false,
            &["--output=json", "--nope-unknown-flag"],
        );
        assert!(r.is_err());

        // --quiet suppresses advisory stderr across dry-run, abort, copy, select-none, and config writes.
        let port_q: Arc<dyn ProjectsPort> =
            Arc::new(InMemoryProjectsPort::with_projects(sample_projects()));
        let p_sel_none = ScriptedPrompter::new([ScriptedAnswer::MultiSelect(Ok(None))]);
        assert_eq!(
            run_with(
                &empty_env,
                &p_sel_none,
                Some(Arc::clone(&port_q)),
                tty_on,
                false,
                &["project", "list", "--select", "--quiet"],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                Some(Arc::clone(&port_q)),
                TerminalState::default(),
                false,
                &["project", "create", "quiet-proj", "--dry-run", "--quiet"],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                Some(Arc::clone(&port_q)),
                TerminalState::default(),
                false,
                &["project", "delete", "p1", "--dry-run", "--quiet"],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        let qcfg = tmp.path().join("quiet-cfg.toml");
        let qcfg_s = qcfg.to_str().unwrap();
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                None,
                TerminalState::default(),
                false,
                &[
                    "config",
                    "set",
                    "output.format",
                    "json",
                    "--config",
                    qcfg_s,
                    "--dry-run",
                    "--quiet",
                ],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                None,
                TerminalState::default(),
                false,
                &[
                    "config",
                    "set",
                    "output.format",
                    "json",
                    "--config",
                    qcfg_s,
                    "--yes",
                    "--quiet",
                    "--copy",
                ],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        let p_abort_q = ScriptedPrompter::new([ScriptedAnswer::Confirm(Ok(Some(false)))]);
        assert_eq!(
            run_with(
                &empty_env,
                &p_abort_q,
                None,
                tty_on,
                false,
                &[
                    "config",
                    "set",
                    "output.format",
                    "table",
                    "--config",
                    qcfg_s,
                    "--quiet",
                ],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        let p_init_abort_q = ScriptedPrompter::new([ScriptedAnswer::Select(Ok(None))]);
        assert_eq!(
            run_with(
                &empty_env,
                &p_init_abort_q,
                None,
                tty_on,
                false,
                &["config", "init", "--config", qcfg_s, "--quiet"],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                None,
                TerminalState::default(),
                false,
                &[
                    "config",
                    "init",
                    "--yes",
                    "--dry-run",
                    "--config",
                    qcfg_s,
                    "--quiet",
                ],
            )
            .0
            .unwrap(),
            Exit::Success
        );
        assert_eq!(
            run_with(
                &empty_env,
                &prompter,
                None,
                TerminalState::default(),
                false,
                &["config", "init", "--yes", "--config", qcfg_s, "--quiet"],
            )
            .0
            .unwrap(),
            Exit::Success
        );

        // Pager with LESS & LV already set (preserves user overrides) and broken-pipe pager exit.
        let pager_env = MapEnv::from_pairs([
            ("PAGER", "sh -c 'cat >/dev/null'"),
            ("LESS", "R"),
            ("LV", "-u"),
        ]);
        let _ = PagerWriter::try_spawn(
            &[
                "sh".to_owned(),
                "-c".to_owned(),
                "cat >/dev/null".to_owned(),
            ],
            &pager_env,
        )
        .map(PagerWriter::finish);

        let epipe_pager_env = MapEnv::from_pairs([("PAGER", "sh -c 'exit 0'")]);
        let (epipe_res, _, _) = run_with(
            &epipe_pager_env,
            &prompter,
            None,
            tty_on,
            true,
            &["completion", "bash"],
        );
        // Completion payload (~several KiB) either hits BrokenPipe on fast pager exit or completes cleanly.
        assert!(matches!(
            epipe_res,
            Ok(Exit::Success) | Err(CliError::BrokenPipe)
        ));
    });

    // Future singular relative_time buckets + format_file_link with spaces.
    assert!(format_file_link(std::path::Path::new("/tmp/a b/c.toml"), true).contains("%20"));
    let now = 1_700_000_000_i64;
    assert_eq!(relative_time(now + 60, now), "in 1 minute");
    assert_eq!(relative_time(now + 3_600, now), "in 1 hour");
    assert_eq!(relative_time(now + 86_400, now), "in 1 day");
    assert_eq!(relative_time(now + 30 * 86_400, now), "in 1 month");
    assert_eq!(relative_time(now + 365 * 86_400, now), "in 1 year");
}
