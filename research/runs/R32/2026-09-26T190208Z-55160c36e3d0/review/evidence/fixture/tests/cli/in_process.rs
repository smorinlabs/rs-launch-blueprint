use crate::support::{fake, run_captured};

#[test]
fn projects_lists_names_in_process() {
    let (code, out, err) = run_captured(&["rslbp", "projects"], &fake(&["Alpha", "Beta"]));
    assert_eq!((code, out.as_str(), err.as_str()), (0, "Alpha\nBeta\n", ""));
}

#[test]
fn unknown_command_is_usage_error_in_process() {
    let (code, out, err) = run_captured(&["rslbp", "nope"], &fake(&[]));
    assert_eq!(code, 2);
    assert!(out.is_empty());
    assert!(err.contains("RSLB201"));
}
