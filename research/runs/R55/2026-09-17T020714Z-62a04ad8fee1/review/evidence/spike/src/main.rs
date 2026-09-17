// R55 synthesizer verification spike. Throwaway: it verifies claims made by the
// raw engine reports. It is NOT a template scaffold and is never built in-tree.
use serde::Deserialize;
use serde::de::IntoDeserializer;

#[derive(Debug, Default, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
enum Format {
    #[default]
    Text,
    Json,
}

#[derive(Debug, Default, Deserialize, PartialEq)]
#[serde(default)]
struct Output {
    format: Format,
    limit: u32,
}

#[derive(Debug, Default, Deserialize, PartialEq)]
#[serde(default)]
struct ConfigFile {
    verbose: bool,
    output: Output,
}

/// The failing leaf lives OUTSIDE the flattened target.
#[derive(Debug, Default, Deserialize, PartialEq)]
#[serde(default)]
struct FlatOuter {
    verbose: bool,
    #[serde(flatten)]
    extra: std::collections::BTreeMap<String, toml::Value>,
    output: Output,
}

/// The failing leaf lives INSIDE the flattened target.
#[derive(Debug, Default, Deserialize, PartialEq)]
#[serde(default)]
struct FlatInner {
    verbose: bool,
    #[serde(flatten)]
    output: Output,
}

/// One typed pass over an untyped document, through the two side channels.
/// Returns Ok(value, ignored-key-paths) or Err(tracked-path, message).
fn typed_pass<T: for<'de> Deserialize<'de>>(
    doc: &toml::Value,
) -> Result<(T, Vec<String>), (String, String)> {
    let mut track = serde_path_to_error::Track::new();
    let inner = doc.clone().into_deserializer();
    let de = serde_path_to_error::Deserializer::new(inner, &mut track);
    let mut ignored: Vec<String> = Vec::new();
    let res: Result<T, toml::de::Error> =
        serde_ignored::deserialize(de, |path| ignored.push(path.to_string()));
    match res {
        Ok(v) => Ok((v, ignored)),
        Err(e) => Err((track.path().to_string(), e.to_string())),
    }
}

/// Remove the leaf a dotted path names. Returns false when the path does not
/// address a prunable leaf (empty, root, or absent).
fn prune(doc: &mut toml::Value, path: &str) -> bool {
    if path.is_empty() || path == "." {
        return false;
    }
    let segs: Vec<&str> = path.split('.').collect();
    let mut cur = doc;
    for seg in &segs[..segs.len() - 1] {
        match cur {
            toml::Value::Table(t) => match t.get_mut(*seg) {
                Some(next) => cur = next,
                None => return false,
            },
            _ => return false,
        }
    }
    match cur {
        toml::Value::Table(t) => t.remove(segs[segs.len() - 1]).is_some(),
        _ => false,
    }
}

fn leaf_count(v: &toml::Value) -> usize {
    match v {
        toml::Value::Table(t) => t.values().map(leaf_count).sum::<usize>().max(t.len()),
        _ => 1,
    }
}

#[derive(Debug)]
enum Fatal {
    /// R67 RSLB202 — config document unparsable.
    Rslb202(String),
    /// R67 RSLB203 — config value invalid and not localizable to a prunable leaf.
    Rslb203(String),
}

/// Tolerant sanitize: drop every leaf the typed pass rejects, keep the rest.
/// Returns the sanitized untyped document plus one warning per drop.
fn sanitize<T: for<'de> Deserialize<'de>>(
    mut doc: toml::Value,
    origin: &str,
    warnings: &mut Vec<String>,
) -> Result<toml::Value, Fatal> {
    let bound = leaf_count(&doc) + 1;
    for _ in 0..bound {
        match typed_pass::<T>(&doc) {
            Ok((_v, ignored)) => {
                for k in ignored {
                    warnings.push(format!("ignoring unknown config key {origin}: {k}"));
                }
                return Ok(doc);
            }
            Err((path, msg)) => {
                if !prune(&mut doc, &path) {
                    return Err(Fatal::Rslb203(format!(
                        "invalid config value {origin}: {msg}"
                    )));
                }
                warnings.push(format!(
                    "ignoring invalid config value {origin}: {path} ({msg})"
                ));
            }
        }
    }
    Err(Fatal::Rslb203(format!(
        "invalid config value {origin}: prune bound exceeded"
    )))
}

fn parse(text: &str, origin: &str) -> Result<toml::Value, Fatal> {
    toml::from_str::<toml::Value>(text)
        .map_err(|e| Fatal::Rslb202(format!("invalid TOML in config file {origin}: {e}")))
}

/// Deep-merge `lower` under `higher`; `higher` wins per key.
fn merge(lower: toml::Value, higher: toml::Value) -> toml::Value {
    match (lower, higher) {
        (toml::Value::Table(mut l), toml::Value::Table(h)) => {
            for (k, hv) in h {
                let merged = match l.remove(&k) {
                    Some(lv) => merge(lv, hv),
                    None => hv,
                };
                l.insert(k, merged);
            }
            toml::Value::Table(l)
        }
        (_, h) => h,
    }
}

fn expect(label: &str, cond: bool, detail: &str) {
    println!("{} {label}: {detail}", if cond { "PASS" } else { "FAIL" });
    assert!(cond, "{label} failed: {detail}");
}

fn main() {
    println!("--- toolchain ---");
    println!("spike: r55-spike, edition 2024, built outside the repository");

    // A. One bad leaf among good ones: sibling and other table survive.
    println!("\n--- A. per-leaf drop preserves siblings ---");
    let mut w = Vec::new();
    let doc = parse(
        "verbose = true\n[output]\nformat = \"yaml\"\nlimit = 7\n",
        "/etc/x/config.toml",
    )
    .unwrap();
    let san = sanitize::<ConfigFile>(doc, "/etc/x/config.toml", &mut w).unwrap();
    let (cfg, _) = typed_pass::<ConfigFile>(&san).unwrap();
    println!("value: {cfg:?}\nwarnings: {w:?}");
    expect(
        "A1 sibling limit survives",
        cfg.output.limit == 7,
        &format!("output.limit = {}", cfg.output.limit),
    );
    expect(
        "A2 other table survives",
        cfg.verbose,
        &format!("verbose = {}", cfg.verbose),
    );
    expect(
        "A3 bad leaf fell back to default",
        cfg.output.format == Format::Text,
        &format!("output.format = {:?}", cfg.output.format),
    );
    expect(
        "A4 exactly one warning naming the key path",
        w.len() == 1 && w[0].contains("output.format"),
        &format!("{w:?}"),
    );

    // B. Two bad leaves: both dropped, good leaf preserved.
    println!("\n--- B. two bad leaves ---");
    let mut w = Vec::new();
    let doc = parse(
        "verbose = \"nope\"\n[output]\nformat = \"yaml\"\nlimit = 7\n",
        "b.toml",
    )
    .unwrap();
    let san = sanitize::<ConfigFile>(doc, "b.toml", &mut w).unwrap();
    let (cfg, _) = typed_pass::<ConfigFile>(&san).unwrap();
    println!("value: {cfg:?}\nwarnings: {w:?}");
    expect(
        "B1 two warnings, limit preserved",
        w.len() == 2 && cfg.output.limit == 7,
        &format!("warnings={} limit={}", w.len(), cfg.output.limit),
    );

    // C. Unknown key is reported, not fatal.
    println!("\n--- C. unknown key ---");
    let mut w = Vec::new();
    let doc = parse("[output]\ncolour = \"red\"\nlimit = 3\n", "c.toml").unwrap();
    let san = sanitize::<ConfigFile>(doc, "c.toml", &mut w).unwrap();
    let (cfg, _) = typed_pass::<ConfigFile>(&san).unwrap();
    println!("value: {cfg:?}\nwarnings: {w:?}");
    expect(
        "C1 unknown key warned, load succeeded, sibling survives",
        w.len() == 1 && w[0].contains("output.colour") && cfg.output.limit == 3,
        &format!("{w:?} limit={}", cfg.output.limit),
    );

    // D. Unparsable document is a document-level fault.
    println!("\n--- D. unparsable document ---");
    let e = parse("this is not = = toml\n", "d.toml").unwrap_err();
    println!("error: {e:?}");
    expect(
        "D1 unparsable maps to RSLB202",
        matches!(e, Fatal::Rslb202(_)),
        &format!("{e:?}"),
    );

    // E. The two fatal branches are distinguishable at the point of failure.
    println!("\n--- E. fatal branches distinguishable ---");
    let mut w = Vec::new();
    let doc = parse("output = 5\nverbose = true\n", "e.toml").unwrap();
    let r = sanitize::<ConfigFile>(doc, "e.toml", &mut w);
    println!("result: {r:?}\nwarnings: {w:?}");
    expect(
        "E1 a mis-shaped table is a prunable leaf, not fatal",
        r.is_ok(),
        &format!("{r:?}"),
    );
    let (cfg, _) = typed_pass::<ConfigFile>(&r.unwrap()).unwrap();
    expect(
        "E2 sibling survives the table drop",
        cfg.verbose && w.len() == 1,
        &format!("verbose={} warnings={:?}", cfg.verbose, w),
    );

    // F. A fault the tracked path cannot localize is fatal RSLB203.
    println!("\n--- F. non-localizable fault is RSLB203 ---");
    let mut w = Vec::new();
    let doc: toml::Value = toml::Value::Integer(5);
    let r = sanitize::<ConfigFile>(doc, "f.toml", &mut w);
    println!("result: {r:?}");
    expect(
        "F1 root-level shape fault maps to RSLB203",
        matches!(r, Err(Fatal::Rslb203(_))),
        &format!("{r:?}"),
    );

    // H. serde(flatten) and the tracked path. Opus raw report case H claims the
    // path collapses to "." under flatten. It does -- but only when the failing
    // leaf is inside the flattened target. Both arrangements are measured here.
    println!("\n--- H. flatten and path-based pruning ---");
    let doc_in = parse("verbose = true\nformat = \"yaml\"\nlimit = 7\n", "h-inner.toml").unwrap();
    let e_in = typed_pass::<FlatInner>(&doc_in).unwrap_err();
    println!("failing leaf INSIDE the flattened target: path={:?}", e_in.0);
    expect(
        "H1 a leaf inside the flattened target collapses to a non-prunable path",
        e_in.0 == "." && !prune(&mut doc_in.clone(), &e_in.0),
        &format!("path={:?}", e_in.0),
    );
    let doc_out = parse("verbose = true\n[output]\nformat = \"yaml\"\n", "h-outer.toml").unwrap();
    let e_out = typed_pass::<FlatOuter>(&doc_out).unwrap_err();
    println!("failing leaf OUTSIDE the flattened target: path={:?}", e_out.0);
    expect(
        "H2 a leaf outside the flattened target keeps a prunable path",
        e_out.0 == "output.format" && prune(&mut doc_out.clone(), &e_out.0),
        &format!("path={:?}", e_out.0),
    );

    // M. Two layers: sanitize each, then merge, then one typed pass.
    // Neither engine executed this; it is the BASELINE-REVIEW F238 substance.
    println!("\n--- M. sanitize -> merge -> type once (two layers) ---");
    let mut w = Vec::new();
    let user = parse("[output]\nformat = \"json\"\nlimit = 2\n", "user.toml").unwrap();
    let project = parse("[output]\nformat = \"yaml\"\n", "project.toml").unwrap();
    let user_s = sanitize::<ConfigFile>(user, "user.toml", &mut w).unwrap();
    let project_s = sanitize::<ConfigFile>(project, "project.toml", &mut w).unwrap();
    let merged = merge(user_s, project_s);
    let (cfg, _) = typed_pass::<ConfigFile>(&merged).unwrap();
    println!("value: {cfg:?}\nwarnings: {w:?}");
    expect(
        "M1 the lower layer's valid value survives the higher layer's invalid one",
        cfg.output.format == Format::Json,
        &format!("output.format = {:?}", cfg.output.format),
    );
    expect(
        "M2 exactly one warning, naming the higher layer",
        w.len() == 1 && w[0].contains("project.toml"),
        &format!("{w:?}"),
    );
    expect(
        "M3 the final typed pass over the merged document did not fail",
        cfg.output.limit == 2,
        &format!("output.limit = {}", cfg.output.limit),
    );

    // N. py's merge-then-drop on the same inputs loses the user value.
    println!("\n--- N. merge-then-drop (py's order) on the same inputs ---");
    let mut w2 = Vec::new();
    let user = parse("[output]\nformat = \"json\"\nlimit = 2\n", "user.toml").unwrap();
    let project = parse("[output]\nformat = \"yaml\"\n", "project.toml").unwrap();
    let merged_first = merge(user, project);
    let san = sanitize::<ConfigFile>(merged_first, "<merged>", &mut w2).unwrap();
    let (cfg2, _) = typed_pass::<ConfigFile>(&san).unwrap();
    println!("value: {cfg2:?}\nwarnings: {w2:?}");
    expect(
        "N1 merge-first falls back to the built-in default, losing user.toml's value",
        cfg2.output.format == Format::Text,
        &format!("output.format = {:?}", cfg2.output.format),
    );

    println!("\nALL ASSERTIONS PASSED");
}
