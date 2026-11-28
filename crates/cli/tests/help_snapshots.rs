//! Recursive `insta` CLI `--help` snapshots for every command in the `rslbp` tree (`R33` F123).
//!
//! Snapshots pin the rendered long-help output at a fixed terminal width (`100` columns) so
//! unintended flag, alias, env-var, or help-prose regressions fail immediately in CI.
//!
//! When a CLI flag or subcommand change is intentional, review and accept updated snapshots with:
//!
//! ```text
//! cargo insta review
//! ```
//!
//! Pending `.snap.new` / `.pending-snap` files are gitignored and must never be committed.

use clap::{Command, CommandFactory};
use rs_launch_blueprint_cli::Cli;

fn normalize_command(mut cmd: Command) -> Command {
    cmd = cmd.term_width(100).max_term_width(100);
    // Prevent ambient developer RSLBP_* environment values from leaking into snapshots.
    cmd = cmd.mut_args(|arg| arg.hide_env_values(true));
    cmd
}

fn collect_help_snapshots(cmd: &Command, path: &mut Vec<String>, out: &mut Vec<(String, String)>) {
    let mut rendered_cmd = normalize_command(cmd.clone());
    // Set bin_name so subcommand Usage lines render `rslbp project list [OPTIONS]` cleanly.
    let bin_name = path.join(" ");
    rendered_cmd = rendered_cmd.bin_name(bin_name);
    let help = rendered_cmd.render_long_help().to_string();
    let snap_name = format!("help__{}", path.join("__"));
    out.push((snap_name, help));

    let mut subcommands: Vec<Command> = cmd
        .get_subcommands()
        .filter(|sub| !sub.is_hide_set() && sub.get_name() != "help")
        .cloned()
        .collect();
    subcommands.sort_by(|a, b| a.get_name().cmp(b.get_name()));

    for sub in subcommands {
        path.push(sub.get_name().to_owned());
        collect_help_snapshots(&sub, path, out);
        path.pop();
    }
}

#[test]
fn cli_help_tree_snapshots() {
    let root = Cli::command();
    let mut path = vec![root.get_name().to_owned()];
    let mut snapshots = Vec::new();
    collect_help_snapshots(&root, &mut path, &mut snapshots);

    assert!(
        snapshots.len() >= 10,
        "expected full rslbp command tree snapshots, got {}",
        snapshots.len()
    );

    for (name, help) in snapshots {
        assert!(
            !help.contains("projects"),
            "rendered help `{name}` must use singular canonical noun `project` (R60 AC9):\n{help}"
        );
        insta::assert_snapshot!(name, help);
    }
}
