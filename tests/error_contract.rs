//! Contract tests for `error-contract/v1` (`R67`) and absence-vs-failure mapping (`R03`)
//! on the standalone library crate (transport-neutral, zero POSIX exit codes or CLI flags).

use std::error::Error as _;
use std::io;

use rs_launch_blueprint_core::{
    AuthError, ConfigError, DomainError, ErrorCode, ErrorEnvelope, PortError,
};

#[test]
fn error_code_all_is_pinned_and_append_only() {
    // R67: every existing wire token row is pinned in registration order.
    // Future rows may ONLY be appended after index 16.
    const PINNED: &[&str] = &[
        "RSLB000", "RSLB101", "RSLB102", "RSLB103", "RSLB104", "RSLB201", "RSLB202", "RSLB203",
        "RSLB204", "RSLB205", "RSLB301", "RSLB401", "RSLB402", "RSLB501", "RSLB901", "RSLB902",
        "RSLB903",
    ];

    assert!(
        ErrorCode::ALL.len() >= PINNED.len(),
        "ErrorCode::ALL shrank below pinned length {}",
        PINNED.len()
    );

    for (idx, expected_code) in PINNED.iter().enumerate() {
        let actual = ErrorCode::ALL[idx];
        assert_eq!(
            actual.as_str(),
            *expected_code,
            "pinned ErrorCode::ALL[{idx}] drifted"
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
fn domain_not_found_maps_to_rslb301_names_input_and_has_no_source() {
    let err = DomainError::NotFound {
        kind: "project",
        id: "demo".to_owned(),
    };

    assert_eq!(err.error_code(), ErrorCode::NotFound);
    assert_eq!(err.error_code().as_str(), "RSLB301");
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

    let transport_err = DomainError::from(PortError::Transport {
        source: Box::new(io::Error::new(io::ErrorKind::TimedOut, "connect timed out")),
    });
    assert_eq!(transport_err.error_code(), ErrorCode::Transport);
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

    let unauth_err = DomainError::from(PortError::Unauthorized {
        detail: "token expired".to_owned(),
        source: None,
    });
    assert_eq!(unauth_err.error_code(), ErrorCode::CredentialsRejected);
    let unauth_hint = unauth_err.hint().expect("unauthorized hint");
    assert!(
        !unauth_hint.contains("--token-file") && !unauth_hint.contains("rslbp auth login"),
        "library hint must stay transport-neutral: {unauth_hint}"
    );

    let conflict_err = DomainError::from(PortError::Conflict {
        detail: "already exists".to_owned(),
        source: None,
    });
    assert_eq!(conflict_err.error_code(), ErrorCode::Conflict);

    let unavail_err = DomainError::from(PortError::Unavailable {
        detail: "mutex poisoned".to_owned(),
    });
    assert_eq!(unavail_err.error_code(), ErrorCode::Io);
}

#[test]
fn config_and_auth_errors_map_to_expected_r67_codes_with_transport_neutral_hints() {
    let unreadable = DomainError::from(ConfigError::Unreadable {
        path: "/etc/rslbp/rslbp_config.toml".into(),
        source: io::Error::new(io::ErrorKind::PermissionDenied, "denied"),
    });
    assert_eq!(unreadable.error_code(), ErrorCode::ConfigUnreadable);

    let unparsable = DomainError::from(ConfigError::Unparsable {
        path: "bad.toml".into(),
        detail: "expected '='".to_owned(),
        span: Some(4..5),
    });
    assert_eq!(unparsable.error_code(), ErrorCode::ConfigUnparsable);

    let prohibited = DomainError::from(ConfigError::ProhibitedSecretChannel {
        key: "token".to_owned(),
    });
    assert_eq!(prohibited.error_code(), ErrorCode::ProhibitedSecretChannel);
    let prohibited_hint = prohibited.hint().expect("prohibited secret hint");
    assert!(
        !prohibited_hint.contains("--token-file") && !prohibited_hint.contains("rslbp auth login"),
        "library hint must stay transport-neutral: {prohibited_hint}"
    );

    let auth_missing = DomainError::from(AuthError::CredentialsAbsent {
        detail: "no token configured".to_owned(),
    });
    assert_eq!(auth_missing.error_code(), ErrorCode::CredentialsAbsent);
    let auth_hint = auth_missing.hint().expect("credentials absent hint");
    assert!(
        !auth_hint.contains("--token-file") && !auth_hint.contains("rslbp auth login"),
        "library hint must stay transport-neutral: {auth_hint}"
    );
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
        Some("supply credentials via a secret provider or credential store".to_owned()),
    );
    let json_with_hint = serde_json::to_value(&with_hint).expect("serialize envelope with hint");
    assert_eq!(
        json_with_hint,
        serde_json::json!({
            "error": {
                "code": "RSLB204",
                "message": "cannot store secret in config file",
                "hint": "supply credentials via a secret provider or credential store"
            }
        })
    );
}

#[test]
fn domain_error_to_envelope_and_remaining_hint_branches() {
    let usage = DomainError::Usage {
        message: "bad arg".to_owned(),
        hint: Some("provide a non-empty value".to_owned()),
    };
    let env_usage = usage.to_envelope();
    assert_eq!(env_usage.error.code, "RSLB201");
    assert_eq!(
        env_usage.error.hint.as_deref(),
        Some("provide a non-empty value")
    );

    let conflict = DomainError::Conflict {
        message: "file exists".to_owned(),
        hint: None,
    };
    assert_eq!(conflict.to_envelope().error.code, "RSLB501");

    let input_unavail = DomainError::InputUnavailable {
        message: "non-interactive input".to_owned(),
        hint: Some("pass explicit arguments".to_owned()),
    };
    assert_eq!(input_unavail.error_code(), ErrorCode::InputUnavailable);
    assert_eq!(
        input_unavail.hint().as_deref(),
        Some("pass explicit arguments")
    );

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
