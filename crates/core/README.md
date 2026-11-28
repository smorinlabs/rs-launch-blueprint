# rs-launch-blueprint-core

Transport-, CLI-, web-, and runtime-agnostic domain core for `rs-launch-blueprint`.

Most Rust library consumers should depend on the top-level
[`rs-launch-blueprint`](https://crates.io/crates/rs-launch-blueprint) facade crate, which
re-exports this crate alongside optional HTTP (`ureq`) and OS keychain adapters. Depend on
`rs-launch-blueprint-core` directly when you only need the domain models, synchronous
`ProjectsPort` trait, `ProjectsService`, secret redaction (`Token`), and `ErrorCode` catalog.

## Installation

```sh
cargo add rs-launch-blueprint-core
```

For a minimal pure-domain dependency graph without XDG path discovery or TOML config parsing:

```sh
cargo add rs-launch-blueprint-core --no-default-features
```

## Feature flags

| Feature  | Default | Description                                                                                    |
| -------- | ------- | ---------------------------------------------------------------------------------------------- |
| `config` | yes     | XDG path resolution (`Paths`), layered TOML config loading/editing, and `FileCredentialStore`. |
| `mock`   | no      | Enables `mockall`-generated `MockProjectsPort` for unit testing.                               |

## Usage

```rust
use rs_launch_blueprint_core::{
    InMemoryProjectsPort, Project, ProjectQuery, ProjectsService,
};

let port = InMemoryProjectsPort::with_projects([Project {
    id: "1".to_owned(),
    name: "Demo".to_owned(),
    workspace: None,
}]);
let service = ProjectsService::new(port);
let projects = service.list_projects(&ProjectQuery::default())?;
assert_eq!(projects.len(), 1);
# Ok::<(), rs_launch_blueprint_core::DomainError>(())
```

## License

Dual-licensed under [Apache-2.0](LICENSE) or [MIT](LICENSE-MIT), at your option.
