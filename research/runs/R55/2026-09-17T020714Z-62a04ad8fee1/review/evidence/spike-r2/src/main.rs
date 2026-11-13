// R55 revision-2 reconciliation probe. Throwaway verification built under
// $TMPDIR, never in-tree. It measures what R53's published per-key loop reports
// against what serde_ignored and serde_path_to_error report on the same inputs,
// to decide whether R55's two crate members still earn their place.
use serde::Deserialize;
use serde::de::IntoDeserializer;
use std::num::NonZeroU32;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
enum OutputFormat {
    #[default]
    Table,
    Json,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Deserialize)]
#[serde(rename_all = "lowercase")]
enum ColorChoice {
    #[default]
    Auto,
    Never,
}

#[derive(Debug, Clone, Default, Deserialize, PartialEq)]
#[serde(default)]
struct OutputSettings {
    format: OutputFormat,
    color: ColorChoice,
    limit: Option<NonZeroU32>,
}

#[derive(Debug, Clone, Default, Deserialize, PartialEq)]
#[serde(default)]
struct ConfigFile {
    output: OutputSettings,
}

/// A flattened target, to test whether the per-key loop can see inside one.
#[derive(Debug, Clone, Default, Deserialize)]
#[serde(default)]
struct FlatConfig {
    #[serde(flatten)]
    output: OutputSettings,
}

/// R53's published Issue type (`review/DECISION.md:521`).
#[derive(Debug, Clone, PartialEq)]
struct Issue {
    path: String,
    message: String,
}

/// R53's published per-key helper, reproduced verbatim in shape
/// (R53 `review/evidence/verify.sh:650-657`).
fn field<T: serde::de::DeserializeOwned>(
    table: &toml::Table,
    section: &str,
    key: &str,
    issues: &mut Vec<Issue>,
) -> Option<T> {
    let value = table.get(key)?.clone();
    match T::deserialize(value) {
        Ok(v) => Some(v),
        Err(e) => {
            issues.push(Issue {
                path: format!("{section}.{key}"),
                message: e.message().to_string(),
            });
            None
        }
    }
}

/// The keys R53's loop names at each level. R53 writes these out by hand; the
/// unconsumed set is their complement, which is what R53 calls "free".
const TOP_LEVEL_KEYS: [&str; 1] = ["output"];
const OUTPUT_KEYS: [&str; 3] = ["format", "color", "limit"];

/// R53's `Unvalidated::validate`: per-key loop over a toml::Table, returning the
/// partial value and the issue list. Extended here with the per-level
/// set-difference R53 states is free but did not measure.
fn r53_validate(table: &toml::Table) -> (ConfigFile, Vec<Issue>, Vec<String>) {
    let mut issues: Vec<Issue> = Vec::new();
    let mut unconsumed: Vec<String> = Vec::new();
    let mut cfg = ConfigFile::default();
    for k in table.keys() {
        if !TOP_LEVEL_KEYS.contains(&k.as_str()) {
            unconsumed.push(k.clone());
        }
    }
    if let Some(t) = table.get("output").and_then(toml::Value::as_table) {
        if let Some(v) = field::<OutputFormat>(t, "output", "format", &mut issues) {
            cfg.output.format = v;
        }
        if let Some(v) = field::<ColorChoice>(t, "output", "color", &mut issues) {
            cfg.output.color = v;
        }
        if let Some(v) = field::<NonZeroU32>(t, "output", "limit", &mut issues) {
            cfg.output.limit = Some(v);
        }
        for k in t.keys() {
            if !OUTPUT_KEYS.contains(&k.as_str()) {
                unconsumed.push(format!("output.{k}"));
            }
        }
    }
    unconsumed.sort();
    (cfg, issues, unconsumed)
}

/// R53's loop with the one-line repair R55 requires: a section key that is
/// present but is not a table is a value-level fault at the section's own path,
/// rather than a silently skipped section.
fn r53_validate_repaired(table: &toml::Table) -> (ConfigFile, Vec<Issue>, Vec<String>) {
    match table.get("output") {
        Some(toml::Value::Table(_)) | None => r53_validate(table),
        Some(other) => {
            let (mut cfg, mut issues, mut unconsumed) = (ConfigFile::default(), Vec::new(), Vec::new());
            issues.push(Issue {
                path: "output".to_string(),
                message: format!(
                    "invalid type: {}, expected a table",
                    other.type_str()
                ),
            });
            for k in table.keys() {
                if !TOP_LEVEL_KEYS.contains(&k.as_str()) {
                    unconsumed.push(k.clone());
                }
            }
            unconsumed.sort();
            cfg.output = OutputSettings::default();
            (cfg, issues, unconsumed)
        }
    }
}

/// What serde_ignored reports for the same document, wrapped in
/// serde_path_to_error exactly as R55 revision 1 composed them.
fn serde_ignored_report(doc: &toml::Value) -> (Option<ConfigFile>, Vec<String>, String) {
    let mut track = serde_path_to_error::Track::new();
    let de = serde_path_to_error::Deserializer::new(doc.clone().into_deserializer(), &mut track);
    let mut ignored: Vec<String> = Vec::new();
    let res: Result<ConfigFile, toml::de::Error> =
        serde_ignored::deserialize(de, |p| ignored.push(p.to_string()));
    ignored.sort();
    match res {
        Ok(v) => (Some(v), ignored, String::new()),
        Err(e) => (None, ignored, format!("{}@{}", e.message(), track.path())),
    }
}

/// Remove the leaf a dotted path names from an untyped table.
fn prune(table: &mut toml::Table, path: &str) -> bool {
    let segs: Vec<&str> = path.split('.').collect();
    if segs.is_empty() {
        return false;
    }
    let mut cur: &mut toml::Table = table;
    for seg in &segs[..segs.len() - 1] {
        match cur.get_mut(*seg) {
            Some(toml::Value::Table(t)) => cur = t,
            _ => return false,
        }
    }
    cur.remove(segs[segs.len() - 1]).is_some()
}

fn merge(lower: toml::Table, higher: toml::Table) -> toml::Table {
    let mut out = lower;
    for (k, hv) in higher {
        let merged = match (out.remove(&k), hv) {
            (Some(toml::Value::Table(l)), toml::Value::Table(h)) => {
                toml::Value::Table(merge(l, h))
            }
            (_, h) => h,
        };
        out.insert(k, merged);
    }
    out
}

fn parse(text: &str) -> toml::Table {
    toml::from_str::<toml::Table>(text).expect("probe input parses as a table")
}

fn expect(label: &str, cond: bool, detail: &str) {
    println!("{} {label}: {detail}", if cond { "PASS" } else { "FAIL" });
    assert!(cond, "{label} failed: {detail}");
}

fn main() {
    // R1 / R2 / R3 — unknown keys at two depths: R53's loop vs serde_ignored.
    println!("--- R1-R3. unknown-key detection: R53's per-key loop vs serde_ignored ---");
    let text = "verbose = true\n[output]\nformat = \"json\"\ncolour = \"red\"\n";
    let table = parse(text);
    let (cfg53, issues53, unconsumed53) = r53_validate(&table);
    println!("R53  partial value: {cfg53:?}");
    println!("R53  issues:        {issues53:?}");
    println!("R53  unconsumed:    {unconsumed53:?}");
    let (cfg_si, ignored_si, err_si) = serde_ignored_report(&toml::Value::Table(table.clone()));
    println!("SI   value:         {cfg_si:?}");
    println!("SI   ignored:       {ignored_si:?}");
    println!("SI   error:         {err_si:?}");
    expect(
        "R1 R53's loop reports both the top-level and the nested unknown key",
        unconsumed53 == vec!["output.colour".to_string(), "verbose".to_string()],
        &format!("{unconsumed53:?}"),
    );
    expect(
        "R2 serde_ignored reports the same two keys",
        ignored_si == vec!["output.colour".to_string(), "verbose".to_string()],
        &format!("{ignored_si:?}"),
    );
    expect(
        "R3 the two unknown-key reports are identical",
        unconsumed53 == ignored_si,
        &format!("R53={unconsumed53:?} serde_ignored={ignored_si:?}"),
    );

    // R4 — R53's Issue.path addresses a prunable leaf in the same table.
    println!("\n--- R4. R53's Issue.path prunes a leaf from the same toml::Table ---");
    let mut t = parse("[output]\nformat = \"yaml\"\nlimit = 7\n");
    let (_, issues, _) = r53_validate(&t);
    println!("issues: {issues:?}");
    let pruned: Vec<bool> = issues.iter().map(|i| prune(&mut t, &i.path)).collect();
    println!("after prune: {t:?}");
    let (cfg_after, issues_after, _) = r53_validate(&t);
    expect(
        "R4 every reported path pruned, siblings survive, second pass is clean",
        issues.len() == 1
            && issues[0].path == "output.format"
            && pruned == vec![true]
            && issues_after.is_empty()
            && cfg_after.output.limit == NonZeroU32::new(7),
        &format!("pruned={pruned:?} after={issues_after:?} limit={:?}", cfg_after.output.limit),
    );

    // R5 — R55 clause 4 over R53's mechanism: sanitize per layer, merge, one pass.
    println!("\n--- R5. sanitize per layer -> merge -> one R53 pass ---");
    let mut user = parse("[output]\nformat = \"json\"\nlimit = 2\n");
    let mut project = parse("[output]\nformat = \"yaml\"\n");
    let mut warnings: Vec<String> = Vec::new();
    for (name, layer) in [("user.toml", &mut user), ("project.toml", &mut project)] {
        let (_, issues, unconsumed) = r53_validate(layer);
        for i in &issues {
            if prune(layer, &i.path) {
                warnings.push(format!("ignoring invalid config value {name}: {}", i.path));
            }
        }
        for k in &unconsumed {
            warnings.push(format!("ignoring unknown config key {name}: {k}"));
        }
    }
    let merged = merge(user, project);
    let (cfg_m, issues_m, _) = r53_validate(&merged);
    println!("value: {cfg_m:?}\nwarnings: {warnings:?}");
    expect(
        "R5 the lower layer's valid value survives and the final pass is clean",
        cfg_m.output.format == OutputFormat::Json
            && cfg_m.output.limit == NonZeroU32::new(2)
            && issues_m.is_empty()
            && warnings.len() == 1
            && warnings[0].contains("project.toml"),
        &format!("format={:?} issues={issues_m:?} warnings={warnings:?}", cfg_m.output.format),
    );

    // R6 — merge-first on the same inputs still loses the value.
    println!("\n--- R6. merge-first (py's order) on the same inputs ---");
    let merged_first = merge(
        parse("[output]\nformat = \"json\"\nlimit = 2\n"),
        parse("[output]\nformat = \"yaml\"\n"),
    );
    let (cfg_n, issues_n, _) = r53_validate(&merged_first);
    println!("value: {cfg_n:?}\nissues: {issues_n:?}");
    expect(
        "R6 merge-first falls back to the default, losing the user layer's value",
        cfg_n.output.format == OutputFormat::Table && issues_n.len() == 1,
        &format!("format={:?} issues={issues_n:?}", cfg_n.output.format),
    );

    // R7 — the per-key loop's hand-written key list and the struct's
    // #[serde(flatten)] must agree about nesting. Here the list is written for
    // the nested schema and the document is flat, which is what a flattened
    // field produces: every leaf lands outside the level the list enumerates.
    println!("\n--- R7. the key list and serde(flatten) disagree about nesting ---");
    let flat = parse("format = \"yaml\"\nlimit = 7\n");
    let (_, issues_f, unconsumed_f) = r53_validate(&flat);
    println!("R53 over a flattened document: issues={issues_f:?} unconsumed={unconsumed_f:?}");
    let flat_typed: Result<FlatConfig, _> = toml::Value::Table(flat.clone()).try_into();
    println!("typed flatten deserialize: {:?}", flat_typed.is_ok());
    expect(
        "R7 leaves at a nesting level the key list does not enumerate are reported as unknown, never validated",
        issues_f.is_empty()
            && unconsumed_f == vec!["format".to_string(), "limit".to_string()],
        &format!("issues={issues_f:?} unconsumed={unconsumed_f:?}"),
    );

    // R8 — a section key whose value is not a table. R53's loop as published
    // skips the section silently; P2 forbids that, so R55 requires the repair.
    println!("\n--- R8. a section key that is not a table ---");
    let mut bad_section = parse("output = 5\n");
    let (cfg_a, issues_a, unconsumed_a) = r53_validate(&bad_section);
    println!("as published: value={cfg_a:?} issues={issues_a:?} unconsumed={unconsumed_a:?}");
    expect(
        "R8a R53's loop as published reports nothing and returns silent defaults",
        issues_a.is_empty()
            && unconsumed_a.is_empty()
            && cfg_a == ConfigFile::default(),
        &format!("issues={issues_a:?} unconsumed={unconsumed_a:?} value={cfg_a:?}"),
    );
    let (_, issues_b, _) = r53_validate_repaired(&bad_section);
    println!("with the repair R55 requires: issues={issues_b:?}");
    let pruned_b = issues_b.iter().all(|i| prune(&mut bad_section, &i.path));
    let (_, issues_b2, _) = r53_validate_repaired(&bad_section);
    expect(
        "R8b the repair makes it a localizable value-level fault, prunable, second pass clean",
        issues_b.len() == 1
            && issues_b[0].path == "output"
            && pruned_b
            && issues_b2.is_empty(),
        &format!("issues={issues_b:?} pruned={pruned_b} after={issues_b2:?}"),
    );

    println!("\nALL R2 PROBE ASSERTIONS PASSED");
}
