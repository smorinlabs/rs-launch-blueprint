//! Feature-off compile isolation (`R69`) and `rslbp-serve` binary contract tests (`R69`, `R77`,
//! `R80`, `R67`).

use std::path::PathBuf;
use std::process::Command;

fn repo_root() -> PathBuf {
    if let Some(dir) = std::env::var_os("CARGO_MANIFEST_DIR") {
        let candidate = PathBuf::from(dir);
        if candidate.join("Cargo.toml").is_file() {
            return candidate;
        }
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

#[test]
fn feature_off_default_graph_contains_no_axum_or_tokio() {
    let cargo = option_env!("CARGO").unwrap_or("cargo");
    let out = Command::new(cargo)
        .args([
            "tree",
            "--no-default-features",
            "--edges",
            "normal",
            "--prefix",
            "none",
        ])
        .current_dir(repo_root())
        .output()
        .expect("cargo tree must execute");
    assert!(
        out.status.success(),
        "cargo tree failed: {}",
        String::from_utf8_lossy(&out.stderr)
    );
    let tree = String::from_utf8_lossy(&out.stdout);
    for forbidden in ["axum ", "tokio ", "tower-http ", "problem_details "] {
        assert!(
            !tree.contains(forbidden),
            "feature-off normal dependency graph must not contain `{forbidden}`:\n{tree}"
        );
    }
}

#[cfg(feature = "web")]
mod serve_binary {
    use std::io::{Read, Write};
    use std::net::{TcpListener, TcpStream};
    use std::process::{Command, Stdio};
    use std::time::{Duration, Instant};

    use assert_cmd::prelude::*;
    use predicates::str::contains;

    fn serve_bin() -> Command {
        Command::new(env!("CARGO_BIN_EXE_rslbp-serve"))
    }

    #[test]
    fn serve_binary_supports_r4_1_core_flags_and_rejects_bad_settings_with_rslb203() {
        // --version -> stdout `rslbp-serve <version>`, exit 0.
        serve_bin()
            .arg("--version")
            .assert()
            .success()
            .stdout(format!("rslbp-serve {}\n", rs_launch_blueprint::VERSION))
            .stderr("");

        // --help -> stdout mentions core R4.1 flags, exit 0.
        serve_bin()
            .arg("--help")
            .assert()
            .success()
            .stdout(contains("--verbose"))
            .stdout(contains("--quiet"))
            .stdout(contains("--config"))
            .stdout(contains("--debug"))
            .stderr("");

        // Unknown flag -> exit 2 + RSLB201 on stderr, empty stdout.
        serve_bin()
            .arg("--not-a-real-flag")
            .assert()
            .code(2)
            .stdout("")
            .stderr(contains("RSLB201"));

        // R77 AC6: malformed RSLBP_WEB_PORT -> exit 2, RSLB203 on stderr, byte-empty stdout.
        serve_bin()
            .env("RSLBP_WEB_PORT", "eighty")
            .assert()
            .code(2)
            .stdout("")
            .stderr(contains("RSLB203"))
            .stderr(contains("RSLBP_WEB_PORT"));

        // Invalid explicit --config file -> exit 2 + RSLB202 on stderr, empty stdout.
        let tmp_cfg =
            std::env::temp_dir().join(format!("rslbp-serve-bad-cfg-{}.toml", std::process::id()));
        std::fs::write(&tmp_cfg, "not valid = [toml").unwrap();
        serve_bin()
            .args(["--config", tmp_cfg.to_str().unwrap()])
            .assert()
            .code(2)
            .stdout("")
            .stderr(contains("RSLB202"));
        let _ = std::fs::remove_file(&tmp_cfg);

        // Occupied port -> exit 1 (Runtime) + RSLB101 on stderr, empty stdout.
        let held = TcpListener::bind("127.0.0.1:0").expect("hold port");
        let held_port = held.local_addr().unwrap().port();
        serve_bin()
            .args(["-vv"])
            .env("RSLBP_WEB_HOST", "127.0.0.1")
            .env("RSLBP_WEB_PORT", held_port.to_string())
            .env("RSLBP_TOKEN", "dummy-token-for-prod-wiring")
            .assert()
            .code(1)
            .stdout("")
            .stderr(contains("RSLB101"));
        drop(held);
    }

    #[cfg(unix)]
    #[test]
    fn serve_binary_exits_143_on_sigterm_and_honors_verbosity_flags() {
        for (flags, sig_name, expected_code) in [
            (&["--debug"][..], "TERM", 143),
            (&["-q"][..], "TERM", 143),
            (&["-v"][..], "TERM", 143),
            (&["-vvv"][..], "TERM", 143),
        ] {
            let probe = TcpListener::bind("127.0.0.1:0").expect("bind ephemeral port");
            let port = probe.local_addr().unwrap().port();
            drop(probe);

            let child = serve_bin()
                .args(flags)
                .env("RSLBP_WEB_HOST", "127.0.0.1")
                .env("RSLBP_WEB_PORT", port.to_string())
                .env("RSLBP_WEB_LOG_FORMAT", "console")
                .env("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", "5")
                .env_remove("RSLBP_TOKEN")
                .stdout(Stdio::piped())
                .stderr(Stdio::piped())
                .spawn()
                .expect("spawn rslbp-serve");

            let addr = format!("127.0.0.1:{port}");
            let deadline = Instant::now() + Duration::from_secs(5);
            while Instant::now() < deadline {
                if TcpStream::connect(&addr).is_ok() {
                    break;
                }
                std::thread::sleep(Duration::from_millis(20));
            }

            let status = Command::new("kill")
                .args(["-s", sig_name, &child.id().to_string()])
                .status()
                .expect("send signal");
            assert!(status.success());

            let out = child.wait_with_output().expect("wait child");
            assert_eq!(out.status.code(), Some(expected_code));
            assert!(out.stdout.is_empty());
        }
    }

    #[cfg(unix)]
    #[test]
    fn serve_binary_serves_probes_and_projects_and_exits_130_on_sigint() {
        // Reserve an ephemeral localhost port then release it for the child process.
        let probe = TcpListener::bind("127.0.0.1:0").expect("bind ephemeral port");
        let port = probe.local_addr().unwrap().port();
        drop(probe);

        let child = serve_bin()
            .env("RSLBP_WEB_HOST", "127.0.0.1")
            .env("RSLBP_WEB_PORT", port.to_string())
            .env("RSLBP_WEB_LOG_FORMAT", "json")
            .env("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", "5")
            .env_remove("RSLBP_TOKEN")
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .expect("spawn rslbp-serve");

        let addr = format!("127.0.0.1:{port}");
        let deadline = Instant::now() + Duration::from_secs(5);
        let mut ready = false;
        while Instant::now() < deadline {
            if TcpStream::connect(&addr).is_ok() {
                ready = true;
                break;
            }
            std::thread::sleep(Duration::from_millis(25));
        }
        assert!(ready, "rslbp-serve failed to bind {addr} within 5s");

        fn raw_get(addr: &str, path: &str) -> String {
            let mut s = TcpStream::connect(addr).expect("connect to rslbp-serve");
            s.set_read_timeout(Some(Duration::from_secs(2))).unwrap();
            let req =
                format!("GET {path} HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n");
            s.write_all(req.as_bytes()).unwrap();
            let mut resp = String::new();
            s.read_to_string(&mut resp).unwrap();
            resp
        }

        let health = raw_get(&addr, "/healthz");
        assert!(health.starts_with("HTTP/1.1 200"), "healthz: {health}");
        assert!(health.contains(rs_launch_blueprint::VERSION));

        let readyz = raw_get(&addr, "/readyz");
        assert!(readyz.starts_with("HTTP/1.1 200"), "readyz: {readyz}");

        let projects = raw_get(&addr, "/v1/projects");
        assert!(projects.starts_with("HTTP/1.1 200"), "projects: {projects}");
        assert!(projects.contains("\"items\":[]"));

        // Send SIGINT and confirm clean drain exit 130 (R67, R69).
        let kill_status = Command::new("kill")
            .args(["-s", "INT", &child.id().to_string()])
            .status()
            .expect("send SIGINT");
        assert!(kill_status.success());

        let output = child.wait_with_output().expect("wait for rslbp-serve");
        assert_eq!(
            output.status.code(),
            Some(130),
            "expected SIGINT exit 130, got {:?}; stderr:\n{}",
            output.status,
            String::from_utf8_lossy(&output.stderr)
        );
        assert!(
            output.stdout.is_empty(),
            "rslbp-serve must keep stdout empty during serving; got: {:?}",
            String::from_utf8_lossy(&output.stdout)
        );
    }
}
