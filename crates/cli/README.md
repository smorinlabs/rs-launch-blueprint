# rs-launch-blueprint-cli (`rslbp`)

Command-line interface (`rslbp`) for `rs-launch-blueprint`, built on top of the standalone
[`rs-launch-blueprint`](https://crates.io/crates/rs-launch-blueprint) library crate.

## Installation

```sh
cargo install rs-launch-blueprint-cli --locked
```

Disable desktop clipboard support (`arboard`) on headless systems:

```sh
cargo install rs-launch-blueprint-cli --locked --no-default-features
```

## Usage

```sh
rslbp --help
rslbp --version
rslbp diagnostics --json
rslbp config show
rslbp project list --output json
```

## Feature flags

| Feature     | Default | Description                                                            |
| ----------- | ------- | ---------------------------------------------------------------------- |
| `clipboard` | yes     | Enables `--copy` OS clipboard support via `arboard`.                   |
| `keychain`  | no      | Enables native OS keychain storage via `rs-launch-blueprint/keychain`. |

## License

Dual-licensed under [Apache-2.0](LICENSE) or [MIT](LICENSE-MIT), at your option.
