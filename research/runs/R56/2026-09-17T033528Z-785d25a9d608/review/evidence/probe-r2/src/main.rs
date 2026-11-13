// R56 probe, revision 2 — a SECOND probe, added to close JF-1 and JF-2 from the round-1
// judgment audit. The revision-1 probe at ../probe/ is NOT edited: it stays as the record
// of what revision 1 ran. This one exercises exactly the two propositions revision 1
// labelled executed without an assertion behind them:
//
//   JF-1  a set, non-empty RSLBP_TOKEN outranks a PRESENT stored credential — the middle
//         rung of the three-tier chain. Revision 1's C1 passed stored = None and its C3
//         passed an empty env, so neither call exercised this rung.
//   JF-2  the dropped-`token` warning NAMES THE FILE. Revision 1's scan_config took a
//         document string, was never given a path, and its warning named none.
//
// It is still a measuring instrument, not the recommendation implemented: the resolver is
// the same naive first-match function, and nothing here reads a real credential store.
use secrecy::{ExposeSecret, SecretString};
use std::fs;
use std::io::Write;
use std::path::Path;

const STORED_SECRET: &str = "sk_live_R56R2_STORED_DO_NOT_LOG";
const CONFIG_SECRET: &str = "sk_live_R56R2_CONFIG_DO_NOT_LOG";
const ENV_TOKEN: &str = "env-token-r2";

#[derive(Debug, PartialEq)]
enum TokenSource {
    TokenFile,
    Env,
    Stored,
    None,
}

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

/// The same naive first-match resolver revision 1 used. Precedence IS first match, so this
/// is the right instrument for the rung JF-1 names; it is not the recommendation, which
/// makes a named-but-missing --token-file fatal instead of falling through.
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

/// JF-2's repair: the scanner is given the PATH of the layer it is scanning, so the warning
/// it emits can name that file. Revision 1's `scan_config(doc)` could not, which is why its
/// "that warning names the file" clause had no assertion behind it.
fn scan_config_at(path: &Path, doc: &str) -> (toml::Table, Vec<String>) {
    let mut t: toml::Table = doc.parse().expect("probe fixture parses");
    let mut warnings = Vec::new();
    if t.remove("token").is_some() {
        warnings.push(format!(
            "{}: key `token` is ignored — this tool never reads a credential from the config file. \
             Use --token-file, the RSLBP_TOKEN environment variable, or `rslbp auth login`.",
            path.display()
        ));
    }
    (t, warnings)
}

fn check(failures: &mut u32, id: &str, ok: bool, detail: String) {
    if !ok {
        *failures += 1;
    }
    println!("{} {} — {}", if ok { "PASS" } else { "FAIL" }, id, detail);
}

fn main() {
    let mut failures: u32 = 0;
    let dir = std::env::temp_dir().join(format!("r56-r2-{}", std::process::id()));
    fs::create_dir_all(&dir).unwrap();
    let stored = dir.join("credentials.toml");
    write_credential(&stored, &SecretString::from(STORED_SECRET.to_owned())).unwrap();

    // ---- JF-1: the middle rung, plus the control that makes it mean something ----------
    // E0 first: prove the stored credential is READABLE in this fixture. Without it, E1's
    // "env wins" could be an unreadable stored file rather than a precedence win.
    let (t0, s0) = resolve(None, None, Some(&stored));
    check(
        &mut failures,
        "E0 CONTROL stored-tier-is-reachable",
        s0 == TokenSource::Stored && t0.as_ref().map(|s| s.expose_secret()) == Some(STORED_SECRET),
        format!("with no flag and no env, source={s0:?} and the stored value is the one on disk"),
    );
    // E1 is JF-1 itself: a set, non-empty env against a PRESENT, READABLE stored credential.
    let (t1, s1) = resolve(None, Some(ENV_TOKEN), Some(&stored));
    check(
        &mut failures,
        "E1 JF-1 env-outranks-stored",
        s1 == TokenSource::Env,
        format!("source={s1:?} (R10.1 middle rung: RSLBP_TOKEN > stored credential)"),
    );
    check(
        &mut failures,
        "E2 JF-1 env-value-is-the-one-used",
        t1.as_ref().map(|s| s.expose_secret()) == Some(ENV_TOKEN),
        "the resolved value is the env token, not the stored credential".into(),
    );
    check(
        &mut failures,
        "E3 JF-1 stored-value-not-used",
        t1.as_ref()
            .map(|s| s.expose_secret() != STORED_SECRET)
            .unwrap_or(false),
        "the stored credential's bytes are not what resolution returned".into(),
    );
    // E4 completes the chain end to end in one call: flag-file beats both lower tiers.
    let tokfile = dir.join("flag-token");
    write_credential(&tokfile, &SecretString::from("flag-token-r2".to_owned())).unwrap();
    let (t4, s4) = resolve(Some(&tokfile), Some(ENV_TOKEN), Some(&stored));
    check(
        &mut failures,
        "E4 full-chain-in-one-call",
        s4 == TokenSource::TokenFile && t4.as_ref().map(|s| s.expose_secret()) == Some("flag-token-r2"),
        format!("all three tiers supplied, source={s4:?}"),
    );

    // ---- JF-2: the warning names the file ---------------------------------------------
    let layer = dir.join("rslbp_config.toml");
    let doc = format!("token = \"{CONFIG_SECRET}\"\n[output]\nformat = \"json\"\n");
    fs::write(&layer, &doc).unwrap();
    let (tbl, warns) = scan_config_at(&layer, &doc);
    check(
        &mut failures,
        "F1 JF-2 exactly-one-warning",
        warns.len() == 1,
        format!("{} warning(s)", warns.len()),
    );
    let w = &warns[0];
    check(
        &mut failures,
        "F2 JF-2 warning-names-the-file",
        w.contains(&layer.display().to_string()),
        "the warning text contains the scanned layer's path".into(),
    );
    check(
        &mut failures,
        "F3 JF-2 warning-names-the-key",
        w.contains("`token`"),
        "the warning text names the key `token`".into(),
    );
    check(
        &mut failures,
        "F4 JF-2 warning-omits-the-value",
        !w.contains(CONFIG_SECRET),
        "the warning text contains none of the value's bytes".into(),
    );
    check(
        &mut failures,
        "F5 key-still-dropped",
        !tbl.contains_key("token"),
        "naming the file did not change the drop behaviour".into(),
    );
    check(
        &mut failures,
        "F6 other-tables-survive",
        tbl.contains_key("output"),
        "[output] still survives the drop".into(),
    );
    // Echo the warning for the record, with the run-specific temporary directory replaced
    // by a placeholder. F2 above asserts against the REAL path; this line exists so the
    // committed log stays byte-reproducible across runs, which a live $TMPDIR path with a
    // PID in it would not be.
    eprintln!(
        "warning: {}",
        w.replace(&dir.display().to_string(), "<TMPDIR>/r56-r2-<pid>")
    );

    fs::remove_dir_all(&dir).ok();
    println!("PROBE_R2_FAILURES={failures}");
    if failures != 0 {
        std::process::exit(1);
    }
}
