// R56 probe — NOT the template and not an implementation of the recommendation.
// It exercises four claims the raw reports make, so the decision can cite executed
// output rather than assertion: (A) std can create a 0600 file at O_CREAT and read
// back a loose mode; (B) a `token` key can be dropped from a parsed config document
// with a warning that never carries the value; (C) a three-tier resolver's ordering
// and F242's empty-is-unset rule; (D) `secrecy::SecretString` redacts `Debug`.
// C2 is a deliberate NEGATIVE control: it shows the naive fall-through the decision
// forbids, so the wrong behaviour is visible rather than assumed away.
use secrecy::{ExposeSecret, SecretString};
use std::fs;
use std::io::Write;
use std::path::Path;

const SECRET: &str = "sk_live_R56PROBE_DO_NOT_LOG";

#[derive(Debug, PartialEq)]
enum TokenSource {
    TokenFile,
    Env,
    Stored,
    None,
}

#[cfg(unix)]
fn mode_of(p: &Path) -> std::io::Result<u32> {
    use std::os::unix::fs::PermissionsExt;
    Ok(fs::metadata(p)?.permissions().mode())
}
#[cfg(not(unix))]
fn mode_of(_p: &Path) -> std::io::Result<u32> {
    Ok(0o600)
}

/// Some(warning) when the file is group/other-accessible. Compile-time no-op off unix.
#[cfg(unix)]
fn permission_warning(p: &Path) -> Option<String> {
    let m = mode_of(p).ok()?;
    if m & 0o077 != 0 {
        Some(format!(
            "credential file {} is accessible to group/others (mode {:04o}); restrict it with: chmod 600 {}",
            p.display(),
            m & 0o7777,
            p.display()
        ))
    } else {
        None
    }
}
#[cfg(not(unix))]
fn permission_warning(_p: &Path) -> Option<String> {
    None
}

/// Create at 0600 from O_CREAT|O_EXCL — never create-then-chmod.
#[cfg(unix)]
fn write_credential(p: &Path, s: &SecretString) -> std::io::Result<()> {
    use std::os::unix::fs::OpenOptionsExt;
    let mut f = fs::OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(p)?;
    f.write_all(s.expose_secret().as_bytes())
}
#[cfg(not(unix))]
fn write_credential(p: &Path, s: &SecretString) -> std::io::Result<()> {
    let mut f = fs::OpenOptions::new().write(true).create_new(true).open(p)?;
    f.write_all(s.expose_secret().as_bytes())
}

fn read_credential(p: &Path) -> Option<SecretString> {
    let raw = fs::read_to_string(p).ok()?;
    let t = raw.trim_end_matches(['\n', '\r']);
    if t.is_empty() {
        None
    } else {
        Some(SecretString::from(t.to_owned()))
    }
}

/// The config document is scanned for the prohibited key; the value is dropped, never echoed.
fn scan_config(doc: &str) -> (toml::Table, Vec<String>) {
    let mut t: toml::Table = doc.parse().expect("probe fixture parses");
    let mut warnings = Vec::new();
    if t.remove("token").is_some() {
        warnings.push(
            "key `token` in the config file is ignored: this tool never reads a credential from \
             the config file. Use --token-file, the RSLBP_TOKEN environment variable, or \
             `rslbp auth login`."
                .to_string(),
        );
    }
    (t, warnings)
}

fn resolve(
    tokfile: Option<&Path>,
    env: Option<&str>,
    stored: Option<&Path>,
) -> (Option<SecretString>, TokenSource) {
    if let Some(p) = tokfile
        && let Some(s) = read_credential(p)
    {
        return (Some(s), TokenSource::TokenFile);
    }
    if let Some(e) = env
        && !e.is_empty()
    {
        return (Some(SecretString::from(e.to_owned())), TokenSource::Env);
    }
    if let Some(p) = stored
        && let Some(s) = read_credential(p)
    {
        return (Some(s), TokenSource::Stored);
    }
    (None, TokenSource::None)
}

fn check(failures: &mut u32, id: &str, ok: bool, detail: String) {
    if !ok {
        *failures += 1;
    }
    println!(
        "{} {} — {}",
        if ok { "PASS" } else { "FAIL" },
        id,
        detail
    );
}

fn main() {
    let mut failures: u32 = 0;
    let dir = std::env::temp_dir().join(format!("r56-acc-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let cred = dir.join("credentials.toml");
    let secret = SecretString::from(SECRET.to_owned());

    write_credential(&cred, &secret).unwrap();
    let m = mode_of(&cred).unwrap() & 0o7777;
    check(
        &mut failures,
        "A1 create-at-0600",
        m == 0o600,
        format!("mode after create_new(.mode(0o600)) = {m:04o}"),
    );
    check(
        &mut failures,
        "A2 no-warning-at-0600",
        permission_warning(&cred).is_none(),
        "0600 produces no warning".into(),
    );

    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&cred, fs::Permissions::from_mode(0o644)).unwrap();
    }
    let w = permission_warning(&cred);
    check(
        &mut failures,
        "A3 warning-at-0644",
        w.is_some(),
        format!("warning emitted = {}", w.is_some()),
    );
    check(
        &mut failures,
        "A4 warning-omits-secret",
        w.as_deref().is_none_or(|s| !s.contains(SECRET)),
        "warning text does not contain the credential".into(),
    );
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&cred, fs::Permissions::from_mode(0o700)).unwrap();
    }
    check(
        &mut failures,
        "A5 no-warning-at-0700",
        permission_warning(&cred).is_none(),
        "the check is the 0o077 mask, not equality with 0600".into(),
    );
    #[cfg(unix)]
    {
        use std::os::unix::fs::PermissionsExt;
        fs::set_permissions(&cred, fs::Permissions::from_mode(0o600)).unwrap();
    }

    let doc = format!("token = \"{SECRET}\"\n[output]\nformat = \"json\"\n");
    let (tbl, warns) = scan_config(&doc);
    check(
        &mut failures,
        "B1 config-token-warned",
        warns.len() == 1,
        format!("{} warning(s)", warns.len()),
    );
    check(
        &mut failures,
        "B2 config-token-dropped",
        !tbl.contains_key("token"),
        "`token` absent from the accepted table".into(),
    );
    check(
        &mut failures,
        "B3 other-keys-survive",
        tbl.contains_key("output"),
        "[output] survives the drop".into(),
    );
    check(
        &mut failures,
        "B4 warning-omits-secret",
        !warns[0].contains(SECRET),
        "warning names the key, not the value".into(),
    );
    for w in &warns {
        eprintln!("warning: {w}");
    }

    let (t1, s1) = resolve(Some(&cred), Some("env-token"), None);
    check(
        &mut failures,
        "C1 token-file-wins",
        s1 == TokenSource::TokenFile
            && t1.as_ref().map(|s| s.expose_secret()) == Some(SECRET),
        format!("source={s1:?}"),
    );
    let missing = dir.join("nope.toml");
    let (_, s2) = resolve(Some(&missing), Some("env-token"), None);
    check(
        &mut failures,
        "C2 NEGATIVE-CONTROL missing-token-file-falls-through",
        s2 == TokenSource::Env,
        format!("source={s2:?} (the decision forbids this: it MUST be RSLB401/4)"),
    );
    let (_, s3) = resolve(None, Some(""), Some(&cred));
    check(
        &mut failures,
        "C3 empty-env-is-unset",
        s3 == TokenSource::Stored,
        format!("source={s3:?} (F242 parity)"),
    );
    let (_, s4) = resolve(None, None, None);
    check(
        &mut failures,
        "C4 no-token",
        s4 == TokenSource::None,
        format!("source={s4:?}"),
    );

    let d1 = format!("{secret:?}");
    let d2 = format!("{t1:?}");
    check(
        &mut failures,
        "D1 debug-of-secretstring-redacts",
        !d1.contains(SECRET),
        format!("Debug of SecretString = {d1}"),
    );
    check(
        &mut failures,
        "D2 debug-of-resolved-redacts",
        !d2.contains(SECRET),
        format!("Debug of resolved = {d2}"),
    );

    fs::remove_dir_all(&dir).ok();
    println!("PROBE_FAILURES={failures}");
    if failures != 0 {
        std::process::exit(1);
    }
}
