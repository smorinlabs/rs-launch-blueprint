//! Template-only final 360-row `COMMONALITY.md` + post-`b08bccf` parity audit test (`P13-TS01`).
//!
//! Removed in stamped child repositories via `press/press-rules.toml` along with `docs/port/`
//! and `scripts/check-parity-audit.py`.

use std::env;
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

#[test]
fn final_parity_audit_accounts_for_all_360_features_and_post_b08bccf_delta() {
    let root = repo_root();
    let script = root.join("scripts/check-parity-audit.py");
    assert!(
        script.is_file(),
        "missing parity audit script {}",
        script.display()
    );

    let out = Command::new("python3")
        .arg(&script)
        .current_dir(&root)
        .output()
        .expect("execute scripts/check-parity-audit.py");
    assert!(
        out.status.success(),
        "parity audit script failed:\nstdout={}\nstderr={}",
        String::from_utf8_lossy(&out.stdout),
        String::from_utf8_lossy(&out.stderr)
    );
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert!(
        stdout.contains("360/360 F### rows: 350 IMPLEMENTED, 10 OMITTED; 85/85 R## items"),
        "unexpected parity audit output: {stdout}"
    );
}
