//! Contract tests for `error-contract/v1` (`R67`) and absence-vs-failure mapping (`R03`).

use std::error::Error as _;
use std::io;
use std::process::ExitCode;

use rs_launch_blueprint_core::{
    AuthError, ConfigError, DomainError, ErrorCode, ErrorEnvelope, Exit, PortError,
};

#[test]
fn error_code_all_is_pinned_and_append_only() {
    // R67: every existing (code, exit) row is pinned in registration order.
    // Future rows may ONLY be appended after index 16.
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

    assert!(
        ErrorCode::ALL.len() >= PINNED.len(),
        "ErrorCode::ALL shrank below pinned length {}",
        PINNED.len()
    );

    for (idx, (expected_code, expected_exit)) in PINNED.iter().enumerate() {
        let actual = ErrorCode::ALL[idx];
        assert_eq!(
            actual.as_str(),
            *expected_code,
            "pinned ErrorCode::ALL[{idx}] drifted"
        );
        assert_eq!(
            actual.exit().code(),
            *expected_exit,
            "pinned exit code for {expected_code} drifted"
        );
        assert_eq!(actual.to_string(), *expected_code);
    }

    // Verify wire format (`RSLB` + 3 ASCII digits) and uniqueness across all entries.
    let mut seen = std::collections::BTreeSet::new();
    for code in ErrorCode::ALL {
        let s = code.as_str();
        assert_eq!(s.len(), 7, "code `{s}` must be 7 ASCII bytes");
        assert!(
            s.starts_with("RSLB") && s[4..].bytes().all(|b| b.is_ascii_digit()),
            "code `{s}` must match RSLBddd"
        );
        assert!(seen.insert(s), "duplicate error code `{s}`");
    }
}

#[test]
fn exit_taxonomy_matches_cli_design_standard_r6_1() {
    assert_eq!(Exit::Success.code(), 0);
    assert_eq!(Exit::Runtime.code(), 1);
    assert_eq!(Exit::Usage.code(), 2);
    assert_eq!(Exit::NotFound.code(), 3);
    assert_eq!(Exit::Auth.code(), 4);
    assert_eq!(Exit::Conflict.code(), 5);
    assert_eq!(Exit::SigInt.code(), 130);
    assert_eq!(Exit::SigTerm.code(), 143);

    // Ensure `From<Exit> for ExitCode` compiles and works.
    let _code: ExitCode = Exit::NotFound.into();
}

#[test]
fn domain_not_found_maps_to_rslb301_names_input_and_has_no_source() {
    let err = DomainError::NotFound {
        kind: "project",
        id: "demo".to_owned(),
    };

    assert_eq!(err.error_code(), ErrorCode::NotFound);
    assert_eq!(err.error_code().as_str(), "RSLB301");
    assert_eq!(err.exit(), Exit::NotFound);
    assert_eq!(err.exit().code(), 3);
    assert!(err.source().is_none(), "absence has no transport cause");

    let msg = err.to_string();
    assert!(
        msg.contains("project") && msg.contains("demo"),
        "Display must name resource kind and offending id; got: {msg}"
    );
}

#[test]
fn port_error_variants_map_to_r67_rows_and_preserve_cause_chain() {
    let io_err = DomainError::from(PortError::Io {
        source: io::Error::new(io::ErrorKind::PermissionDenied, "disk denied"),
    });
    assert_eq!(io_err.error_code(), ErrorCode::Io);
    assert_eq!(io_err.exit(), Exit::Runtime);

    let transport_err = DomainError::from(PortError::Transport {
        source: Box::new(io::Error::new(io::ErrorKind::TimedOut, "connect timed out")),
    });
    assert_eq!(transport_err.error_code(), ErrorCode::Transport);
    assert_eq!(transport_err.exit(), Exit::Runtime);
    let mut chain = Vec::new();
    let mut cur: Option<&(dyn std::error::Error + 'static)> = Some(&transport_err);
    while let Some(e) = cur {
        chain.push(e.to_string());
        cur = e.source();
    }
    assert!(
        chain.iter().any(|s| s.contains("connect timed out")),
        "source chain must preserve underlying transport cause: {chain:?}"
    );

    let remote_err = DomainError::from(PortError::RemoteApi {
        detail: "502 bad gateway".to_owned(),
        source: None,
    });
    assert_eq!(remote_err.error_code(), ErrorCode::RemoteApi);
    assert_eq!(remote_err.exit(), Exit::Runtime);

    let unauth_err = DomainError::from(PortError::Unauthorized {
        detail: "token expired".to_owned(),
        source: None,
    });
    assert_eq!(unauth_err.error_code(), ErrorCode::CredentialsRejected);
    assert_eq!(unauth_err.exit(), Exit::Auth);

    let conflict_err = DomainError::from(PortError::Conflict {
        detail: "already exists".to_owned(),
        source: None,
    });
    assert_eq!(conflict_err.error_code(), ErrorCode::Conflict);
    assert_eq!(conflict_err.exit(), Exit::Conflict);

    let unavail_err = DomainError::from(PortError::Unavailable {
        detail: "mutex poisoned".to_owned(),
    });
    assert_eq!(unavail_err.error_code(), ErrorCode::Io);
    assert_eq!(unavail_err.exit(), Exit::Runtime);
}

#[test]
fn config_and_auth_errors_map_to_expected_r67_codes() {
    let unreadable = DomainError::from(ConfigError::Unreadable {
        path: "/etc/rslbp/rslbp_config.toml".into(),
        source: io::Error::new(io::ErrorKind::PermissionDenied, "denied"),
    });
    assert_eq!(unreadable.error_code(), ErrorCode::ConfigUnreadable);
    assert_eq!(unreadable.exit(), Exit::Runtime);

    let unparsable = DomainError::from(ConfigError::Unparsable {
        path: "bad.toml".into(),
        detail: "expected '='".to_owned(),
        span: Some(4..5),
    });
    assert_eq!(unparsable.error_code(), ErrorCode::ConfigUnparsable);
    assert_eq!(unparsable.exit(), Exit::Usage);

    let prohibited = DomainError::from(ConfigError::ProhibitedSecretChannel {
        key: "token".to_owned(),
    });
    assert_eq!(prohibited.error_code(), ErrorCode::ProhibitedSecretChannel);
    assert_eq!(prohibited.exit(), Exit::Usage);
    assert!(prohibited.hint().is_some());

    let auth_missing = DomainError::from(AuthError::CredentialsAbsent {
        detail: "no token configured".to_owned(),
    });
    assert_eq!(auth_missing.error_code(), ErrorCode::CredentialsAbsent);
    assert_eq!(auth_missing.exit(), Exit::Auth);
}

#[test]
fn error_envelope_omits_null_hint_and_serializes_exact_r67_keys() {
    let without_hint = ErrorEnvelope::new(ErrorCode::NotFound, "project 'demo' not found", None);
    let json_no_hint = serde_json::to_value(&without_hint).expect("serialize envelope");
    assert_eq!(
        json_no_hint,
        serde_json::json!({
            "error": {
                "code": "RSLB301",
                "message": "project 'demo' not found"
            }
        })
    );

    let with_hint = ErrorEnvelope::new(
        ErrorCode::ProhibitedSecretChannel,
        "cannot store secret in config file",
        Some("use --token-file, RSLBP_TOKEN, or `rslbp auth login`".to_owned()),
    );
    let json_with_hint = serde_json::to_value(&with_hint).expect("serialize envelope with hint");
    assert_eq!(
        json_with_hint,
        serde_json::json!({
            "error": {
                "code": "RSLB204",
                "message": "cannot store secret in config file",
                "hint": "use --token-file, RSLBP_TOKEN, or `rslbp auth login`"
            }
        })
    );
}

#[test]
fn domain_error_to_envelope_and_clipboard_error_variants() {
    use rs_launch_blueprint_core::{ClipboardError, ClipboardPort, FailingClipboard};

    let usage = DomainError::Usage {
        message: "bad arg".to_owned(),
        hint: Some("try --help".to_owned()),
    };
    let env_usage = usage.to_envelope();
    assert_eq!(env_usage.error.code, "RSLB201");
    assert_eq!(env_usage.error.hint.as_deref(), Some("try --help"));

    let conflict = DomainError::Conflict {
        message: "file exists".to_owned(),
        hint: None,
    };
    assert_eq!(conflict.to_envelope().error.code, "RSLB501");
    assert_eq!(conflict.exit(), Exit::Conflict);

    let interrupted = DomainError::PromptInterrupted;
    assert_eq!(interrupted.to_envelope().error.code, "RSLB903");
    assert_eq!(interrupted.exit(), Exit::SigInt);

    let clip_src = ClipboardError::with_source(
        "clipboard failed",
        Some("pipe instead".to_owned()),
        Box::new(io::Error::other("x11 down")),
    );
    assert!(clip_src.source().is_some());
    assert_eq!(clip_src.hint().as_deref(), Some("pipe instead"));
    let clip_dom = DomainError::Clipboard(clip_src);
    assert_eq!(clip_dom.to_envelope().error.code, "RSLB101");
    assert_eq!(clip_dom.exit(), Exit::Runtime);

    let failing_default = FailingClipboard::default();
    let err = failing_default.set_text("hello").unwrap_err();
    assert!(err.hint().is_some());

    // Exercise remaining DomainError::hint & ConfigError/AuthError/PortError branches.
    let port_transport = DomainError::from(PortError::Transport {
        source: Box::new(io::Error::other("timeout")),
    });
    assert!(port_transport.hint().is_some());

    let cfg_write = DomainError::from(ConfigError::WriteFailed {
        path: "/tmp/c.toml".into(),
        source: io::Error::other("rofs"),
    });
    assert_eq!(cfg_write.error_code(), ErrorCode::Io);
    assert!(cfg_write.hint().is_none());

    let cfg_unknown = DomainError::from(ConfigError::UnknownKey {
        key: "bad.key".to_owned(),
        valid_keys: vec!["output.format"],
    });
    assert_eq!(cfg_unknown.error_code(), ErrorCode::ConfigInvalid);
    assert!(cfg_unknown.hint().unwrap().contains("output.format"));

    let cfg_unparsable = DomainError::from(ConfigError::Unparsable {
        path: "/tmp/bad.toml".into(),
        detail: "bad".to_owned(),
        span: None,
    });
    assert!(cfg_unparsable.hint().unwrap().contains("bad.toml"));

    let auth_unavail = DomainError::from(AuthError::StoreUnavailable {
        detail: "locked".to_owned(),
    });
    assert_eq!(auth_unavail.error_code(), ErrorCode::Io);
    assert!(auth_unavail.hint().is_none());

    let auth_io = DomainError::from(AuthError::Io {
        path: "/tmp/c".into(),
        source: io::Error::other("io"),
    });
    assert_eq!(auth_io.error_code(), ErrorCode::Io);
    assert!(auth_io.hint().is_none());
}
