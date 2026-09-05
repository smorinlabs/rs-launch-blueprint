//! F160 adapter: the commit-message template (.gitmessage) and the selected
//! linter's configuration (committed.toml) must express one convention.
//! Direct analogue of ts `tests/repo-hygiene.test.ts:19-34`, which imports
//! commitlint's configuration for the same purpose. In the template this test
//! lives wherever R02's crate topology places the meta-suite and resolves the
//! repository root from CARGO_MANIFEST_DIR; here the root is the fixture dir.

use std::fs;
use std::path::{Path, PathBuf};

fn root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR")).join("..")
}

fn committed_config() -> toml::Value {
    let text = fs::read_to_string(root().join("committed.toml")).expect("read committed.toml");
    toml::from_str(&text).expect("parse committed.toml")
}

fn gitmessage() -> String {
    fs::read_to_string(root().join(".gitmessage")).expect("read .gitmessage")
}

/// Extract the integer that follows `prefix` in `text` (first occurrence).
fn number_after(text: &str, prefix: &str) -> i64 {
    let start = text.find(prefix).unwrap_or_else(|| panic!("`{prefix}` not found in .gitmessage")) + prefix.len();
    let digits: String = text[start..].chars().take_while(|c| c.is_ascii_digit()).collect();
    digits.parse().unwrap_or_else(|_| panic!("no integer after `{prefix}`"))
}

#[test]
fn gitmessage_types_match_committed_allowed_types_exactly() {
    let cfg = committed_config();
    let allowed: Vec<String> = cfg["allowed_types"]
        .as_array()
        .expect("allowed_types is an array")
        .iter()
        .map(|v| v.as_str().expect("type is a string").to_owned())
        .collect();

    let text = gitmessage();
    let types_line = text
        .lines()
        .find(|line| line.starts_with("# Types:"))
        .expect(".gitmessage has a `# Types:` line");
    let documented: Vec<String> = types_line
        .trim_start_matches("# Types:")
        .split(',')
        .map(|t| t.trim().to_owned())
        .collect();

    // EXACT match: same members, same order. Both lists document one contract.
    assert_eq!(documented, allowed, ".gitmessage `# Types:` must equal committed.toml allowed_types");
    assert_eq!(allowed.len(), 11, "the convention has eleven types");
}

#[test]
fn gitmessage_length_caps_match_committed_config() {
    let cfg = committed_config();
    let subject = cfg["subject_length"].as_integer().expect("subject_length");
    let line = cfg["line_length"].as_integer().expect("line_length");
    assert_eq!(subject, 50, "header cap is 50");
    assert_eq!(line, 72, "body/footer cap is 72");

    let text = gitmessage();
    assert_eq!(number_after(&text, "maximum of "), subject);
    assert_eq!(number_after(&text, "Limit the subject line to "), subject);
    assert_eq!(number_after(&text, "Wrap the body and footer at "), line);
}

#[test]
fn committed_config_expresses_the_convention() {
    let cfg = committed_config();
    assert_eq!(cfg["style"].as_str(), Some("conventional"));
    assert_eq!(cfg["subject_capitalized"].as_bool(), Some(false), "lower-case subjects must be accepted");
    assert_eq!(cfg["subject_not_punctuated"].as_bool(), Some(true));
    assert_eq!(cfg["imperative_subject"].as_bool(), Some(false), "no mood rule was agreed by the sources");
    assert_eq!(cfg["merge_commit"].as_bool(), Some(false), "merge commits are rejected explicitly on the range path; PR branches are linear");
    let hard = cfg.get("hard_line_length").and_then(|v| v.as_integer()).unwrap_or(0);
    assert_eq!(hard, 0, "hard_line_length must stay disabled on committed 1.1.x (checks.rs:98-100 defect)");
    assert!(cfg.get("ignore_author_re").is_none(), "no whole-commit author exemption: it would skip the type check for bots");
}

#[test]
fn bot_config_relaxes_only_the_width_rules() {
    let main = committed_config();
    let text = fs::read_to_string(root().join("committed.bot.toml")).expect("read committed.bot.toml");
    let bot: toml::Value = toml::from_str(&text).expect("parse committed.bot.toml");
    assert_eq!(bot["style"], main["style"], "bots keep the Conventional grammar");
    assert_eq!(bot["allowed_types"], main["allowed_types"], "bots keep the eleven-type enum");
    assert_eq!(bot["subject_not_punctuated"], main["subject_not_punctuated"]);
    assert_eq!(bot["subject_capitalized"], main["subject_capitalized"]);
    assert_eq!(bot["subject_length"].as_integer(), Some(0), "subject width check off for bots");
    assert_eq!(bot["line_length"].as_integer(), Some(0), "line width check off for bots");
    assert!(bot.get("hard_line_length").map_or(true, |v| v.as_integer() == Some(0)));
    assert!(bot.get("ignore_author_re").is_none(), "no author exemption in the bot config either");
}
