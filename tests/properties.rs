//! Generative property-based tests at serialization and config seams (`R33` F122).
//!
//! Example-based tests verify cases we thought of; these verify round-trip
//! invariants across the input space with automatic shrinking and committed
//! `proptest-regressions/` replay.

use std::fs;
use std::num::NonZeroU32;
use std::str::FromStr;

use proptest::prelude::*;
use rs_launch_blueprint::{
    ColorPreference, ConfigDiscoveryInputs, ErrorCode, ErrorEnvelope, FileLogFormat, LogLevel,
    OutputFormat, Paths, Project, load_config, set_config_value,
};
use rs_launch_blueprint_cli::{ProjectListView, TermCaps, render_view};
use tempfile::TempDir;

/// Non-control Unicode text strategy matching py's alphabet narrowing so
/// properties test our serialization round-trip rather than control-byte quirks.
fn safe_text() -> impl Strategy<Value = String> {
    proptest::collection::vec(
        any::<char>().prop_filter("non-control char", |c| !c.is_control()),
        0..48,
    )
    .prop_map(|chars| chars.into_iter().collect())
}

fn non_empty_safe_text() -> impl Strategy<Value = String> {
    proptest::collection::vec(
        any::<char>().prop_filter("non-control char", |c| !c.is_control()),
        1..48,
    )
    .prop_map(|chars| chars.into_iter().collect())
}

fn output_format_strategy() -> impl Strategy<Value = OutputFormat> {
    prop_oneof![
        Just(OutputFormat::Table),
        Just(OutputFormat::Json),
        Just(OutputFormat::Markdown),
        Just(OutputFormat::Name),
    ]
}

fn color_pref_strategy() -> impl Strategy<Value = ColorPreference> {
    prop_oneof![
        Just(ColorPreference::Auto),
        Just(ColorPreference::Always),
        Just(ColorPreference::Never),
    ]
}

fn log_level_strategy() -> impl Strategy<Value = LogLevel> {
    prop_oneof![
        Just(LogLevel::Off),
        Just(LogLevel::Error),
        Just(LogLevel::Warn),
        Just(LogLevel::Info),
        Just(LogLevel::Debug),
        Just(LogLevel::Trace),
    ]
}

fn file_log_format_strategy() -> impl Strategy<Value = FileLogFormat> {
    prop_oneof![Just(FileLogFormat::Text), Just(FileLogFormat::Json)]
}

proptest! {
    #[test]
    fn project_json_wire_round_trip(
        id in non_empty_safe_text(),
        name in safe_text(),
        workspace in prop::option::of(safe_text()),
    ) {
        let original = Project { id, name, workspace };
        let encoded = serde_json::to_string(&original).expect("serialize Project");
        let decoded: Project = serde_json::from_str(&encoded).expect("deserialize Project");
        prop_assert_eq!(decoded, original);
    }

    #[test]
    fn error_envelope_json_round_trip_and_hint_omission(
        idx in 0..ErrorCode::ALL.len(),
        message in safe_text(),
        hint in prop::option::of(safe_text()),
    ) {
        let code = ErrorCode::ALL[idx];
        let envelope = ErrorEnvelope::new(code, message, hint.clone());
        let encoded = serde_json::to_string(&envelope).expect("serialize envelope");
        let value: serde_json::Value = serde_json::from_str(&encoded).expect("parse value");
        if hint.is_none() {
            prop_assert!(value["error"].get("hint").is_none());
        } else {
            prop_assert_eq!(value["error"]["hint"].as_str(), hint.as_deref());
        }
        let decoded: ErrorEnvelope = serde_json::from_str(&encoded).expect("deserialize envelope");
        prop_assert_eq!(decoded, envelope);
    }

    #[test]
    fn config_enum_display_from_str_round_trip(
        fmt in output_format_strategy(),
        color in color_pref_strategy(),
        level in log_level_strategy(),
        file_fmt in file_log_format_strategy(),
    ) {
        prop_assert_eq!(OutputFormat::from_str(fmt.as_str()).unwrap(), fmt);
        prop_assert_eq!(ColorPreference::from_str(color.as_str()).unwrap(), color);
        prop_assert_eq!(LogLevel::from_str(level.as_str()).unwrap(), level);
        prop_assert_eq!(FileLogFormat::from_str(file_fmt.as_str()).unwrap(), file_fmt);
    }

    #[test]
    fn config_write_then_load_round_trip_preserves_values_and_comments(
        fmt in output_format_strategy(),
        color in color_pref_strategy(),
        limit in 1u32..=10_000u32,
        level in log_level_strategy(),
        file_fmt in file_log_format_strategy(),
        comment_body in "[A-Za-z0-9 _-]{1,24}",
    ) {
        let tmp = TempDir::new().expect("temp dir");
        let cfg_path = tmp.path().join("rslbp_config.toml");
        let header_comment = format!("# {comment_body}");
        fs::write(&cfg_path, format!("{header_comment}\n[output]\nformat = \"table\"\n"))
            .expect("seed config");

        set_config_value(&cfg_path, "output.format", fmt.as_str()).expect("set format");
        set_config_value(&cfg_path, "output.color", color.as_str()).expect("set color");
        set_config_value(&cfg_path, "output.limit", &limit.to_string()).expect("set limit");
        set_config_value(&cfg_path, "logging.level", level.as_str()).expect("set level");
        set_config_value(&cfg_path, "logging.file-format", file_fmt.as_str())
            .expect("set file-format");

        let raw = fs::read_to_string(&cfg_path).expect("read config");
        prop_assert!(raw.contains(&header_comment), "header comment must survive edits");

        let paths = Paths::from_roots(
            tmp.path().join("c"),
            tmp.path().join("d"),
            tmp.path().join("s"),
            tmp.path().join("k"),
        );
        let loaded = load_config(&ConfigDiscoveryInputs {
            explicit_flag: Some(&cfg_path),
            explicit_env: None,
            cwd: tmp.path(),
            paths: &paths,
            xdg_config_dirs: None,
        })
        .expect("reload config");

        prop_assert!(loaded.warnings.is_empty(), "warnings: {:?}", loaded.warnings);
        let cfg = loaded.config.as_config();
        prop_assert_eq!(cfg.output.format, fmt);
        prop_assert_eq!(cfg.output.color, color);
        prop_assert_eq!(cfg.output.limit, NonZeroU32::new(limit));
        prop_assert_eq!(cfg.logging.level, level);
        prop_assert_eq!(cfg.logging.file_format, file_fmt);
    }

    #[test]
    fn cli_output_renderers_preserve_machine_invariants_across_arbitrary_projects(
        projects in proptest::collection::vec(
            (
                "[A-Za-z0-9_|\\\\ -]{1,20}",
                "[A-Za-z0-9_|\\\\\",\\n\\x1b -]{0,32}",
                prop::option::of("[A-Za-z0-9_|\\\\\",\\n -]{0,20}"),
            )
                .prop_map(|(id, name, workspace)| Project { id, name, workspace }),
            0..8,
        ),
    ) {
        let view = ProjectListView {
            projects: projects.clone(),
        };

        // JSON: valid parse, zero raw 0x1b bytes, exact project list round-trip.
        let mut json_buf = Vec::new();
        render_view(&view, OutputFormat::Json, TermCaps::plain(), &mut json_buf)
            .expect("render json");
        prop_assert!(!json_buf.contains(&0x1b));
        let parsed: serde_json::Value = serde_json::from_slice(&json_buf).expect("valid json");
        prop_assert_eq!(parsed["projects"].as_array().unwrap().len(), projects.len());

        // Markdown: zero raw 0x1b bytes, exact line count (1 empty-state line or title + blank + header + sep + N).
        let mut md_buf = Vec::new();
        render_view(&view, OutputFormat::Markdown, TermCaps::plain(), &mut md_buf)
            .expect("render markdown");
        prop_assert!(!md_buf.contains(&0x1b));
        let md = String::from_utf8(md_buf).expect("utf-8 md");
        if projects.is_empty() {
            prop_assert_eq!(md.lines().count(), 1);
        } else {
            prop_assert_eq!(md.lines().count(), projects.len() + 4);
        }

        // Name: zero raw 0x1b bytes, exact N lines.
        let mut name_buf = Vec::new();
        render_view(&view, OutputFormat::Name, TermCaps::plain(), &mut name_buf)
            .expect("render name");
        prop_assert!(!name_buf.contains(&0x1b));
        let names = String::from_utf8(name_buf).expect("utf-8 name");
        prop_assert_eq!(names.lines().count(), projects.len());

        // Table (plain): zero raw 0x1b bytes.
        let mut table_buf = Vec::new();
        render_view(&view, OutputFormat::Table, TermCaps::plain(), &mut table_buf)
            .expect("render table");
        prop_assert!(!table_buf.contains(&0x1b));
    }
}
