//! F018 — the shared data contract round-trips through `serde_json` and has the field names both
//! front ends rely on. The concrete wire format is R66's decision; this proves only that one type serves both.

use seam_fixture::{Project, ProjectQuery};

#[test]
fn project_round_trips_and_keeps_its_field_names() {
    let original = Project {
        id: "1".into(),
        name: "alpha".into(),
    };
    let json = serde_json::to_string(&original).unwrap();
    assert_eq!(json, r#"{"id":"1","name":"alpha"}"#);
    let back: Project = serde_json::from_str(&json).unwrap();
    assert_eq!(back, original);
}

#[test]
fn query_round_trips_including_the_absent_filter() {
    let filtered = ProjectQuery::matching("alpha");
    let json = serde_json::to_string(&filtered).unwrap();
    assert_eq!(json, r#"{"q":"alpha"}"#);
    assert_eq!(
        serde_json::from_str::<ProjectQuery>(&json).unwrap(),
        filtered
    );

    // The web adapter's `Query<ProjectQuery>` sees `{}` when no `?q=` is given; `#[serde(default)]` keeps it valid.
    assert_eq!(
        serde_json::from_str::<ProjectQuery>("{}").unwrap(),
        ProjectQuery::default()
    );
}
