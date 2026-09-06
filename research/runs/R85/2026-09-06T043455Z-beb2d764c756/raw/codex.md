### Landscape

**Category.** This is a presentation-boundary pattern: project one canonical result into a text-only view without changing the CLI's machine-readable or web contract.  The field map was made before selecting an implementation:

| Bin | Candidates found | Why it is in the bin |
|---|---|---|
| Built-in or first-party toolchain | `std::io::IsTerminal`; a Rust trait with a default method; a small pure signed-seconds formatter | `IsTerminal` is in the standard library, and the Rust Reference specifies that a trait method body is the default for implementors that do not override it. [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05) |
| Established industry standard | OSC 8 terminal hyperlinks; an explicit `auto`/`always`/`never` emission policy; structured cells rendered after layout | OSC 8 has broad emulator adoption, but its compatibility remains terminal- and multiplexer-dependent. [OSC 8 adoption list](https://github.com/Alhadis/OSC8-Adoption) (retrieved 2026-09-05). The maintained Rust CLIs `ripgrep` and `fd` expose an explicit hyperlink choice rather than polluting every output. [ripgrep release notes](https://github.com/BurntSushi/ripgrep/releases/tag/14.0.0) (retrieved 2026-09-05); [fd manual](https://github.com/sharkdp/fd/blob/master/doc/fd.1) (retrieved 2026-09-05). |
| Up-and-comer | `supports-hyperlinks`, `osc8`, `timeago`, and `jiff` relative-time facilities | These are implementation leads, not a preselected architecture. Their published metadata and documentation were checked below. [crates.io](https://crates.io/crates/supports-hyperlinks) (retrieved 2026-09-05); [osc8 docs](https://docs.rs/osc8/latest/osc8/) (retrieved 2026-09-05); [timeago docs](https://docs.rs/timeago/latest/timeago/) (retrieved 2026-09-05); [Jiff docs](https://docs.rs/jiff/latest/jiff/) (retrieved 2026-09-05). |

**Authorities and practice.** The Rust Reference is authoritative for the trait-default mechanism.  The OSC 8 adoption project is a maintained compatibility inventory, not a standard, and is used only to establish interoperability risk.  `ripgrep` is a widely deployed Rust search CLI and its release notes document a cautious, configurable OSC-8 rollout; `fd` is a maintained Rust CLI whose manual documents `auto`, `always`, and `never`, with `auto` tied to terminal escape acceptance. [ripgrep’s maintainer discussion](https://github.com/BurntSushi/ripgrep/discussions/2611) (retrieved 2026-09-05); [fd source](https://github.com/sharkdp/fd/blob/master/src/main.rs) (retrieved 2026-09-05). This is relevant production practice because it separates data production, layout, and terminal emission, and because its default remains conservative where terminal support is uncertain.

**Candidate figures and maintenance evidence.** These are auxiliary crate leads, not the selected pattern; therefore crate figures do not choose the result.  The values below are from the specified endpoints, retrieved 2026-09-05.

| Crate | 90-day / all-time downloads | Latest non-yanked release | GitHub stars / archived / pushed | Open issues | Maintenance and gate evidence |
|---|---:|---|---|---:|---|
| `supports-hyperlinks` | 9,285,808 / 39,605,406 | 3.2.0, 2025-12-17 | 32 / false / 2025-12-17 | 1 | `Apache-2.0`, MSRV 1.70, no `unsafe` in its source. Its crates.io package declares no default feature list; its narrow purpose is capability detection, not emission. GitHub issue #7 received an owner response in about 0.24 days; the remaining recent-issue sample could not be completed after GitHub rate limiting, so a median is unverified. [crate](https://crates.io/api/v1/crates/supports-hyperlinks) [versions](https://crates.io/api/v1/crates/supports-hyperlinks/versions) [repository](https://api.github.com/repos/zkat/supports-hyperlinks) [open-issue search](https://api.github.com/search/issues?q=repo:zkat/supports-hyperlinks+is:issue+is:open) (all retrieved 2026-09-05). |
| `timeago` | 218,161 / 1,685,884 | 0.6.1, 2026-07-02 | 76 / false / 2026-07-02 | 4 | `MIT OR Apache-2.0`, MSRV 1.63, default feature `default = ["translations"]`; no `unsafe` found in released source. It formats a duration as a past-tense string, so future-time behavior and the exact under-one-minute contract still need wrapper policy. Issue responsiveness is unverified after rate limiting. [crate](https://crates.io/api/v1/crates/timeago) [versions](https://crates.io/api/v1/crates/timeago/versions) [repository](https://api.github.com/repos/vi/timeago) [open-issue search](https://api.github.com/search/issues?q=repo:vi/timeago+is:issue+is:open) (all retrieved 2026-09-05). |
| `jiff` | 61,041,872 / 180,323,289 | 0.2.35, 2026-07-25 | 2,908 / false / 2026-08-07 | 41 | `Unlicense OR MIT`, MSRV 1.70, default features include `std`; released source contains carefully encapsulated `unsafe` implementation code. It is a full date-time library, not a small display-policy dependency. Issue responsiveness is unverified after rate limiting. [crate](https://crates.io/api/v1/crates/jiff) [versions](https://crates.io/api/v1/crates/jiff/versions) [repository](https://api.github.com/repos/BurntSushi/jiff) [open-issue search](https://api.github.com/search/issues?q=repo:BurntSushi/jiff+is:issue+is:open) (all retrieved 2026-09-05). |
| `osc8` | 83,115 / 162,471 | 0.1.0, 2024-08-09 | inapplicable: Codeberg repository, not GitHub | inapplicable | `MIT`; published manifest has no declared MSRV, and no GitHub CI/platform evidence was available from the required GitHub endpoint. It generates/parses OSC 8 but its own documentation delegates support detection to `supports-hyperlinks`. [crate](https://crates.io/api/v1/crates/osc8) [versions](https://crates.io/api/v1/crates/osc8/versions) [docs](https://docs.rs/osc8/latest/osc8/) (all retrieved 2026-09-05). |

The required RustSec package URLs for all four leads returned HTTP 404 on 2026-09-05, so “no open advisory” is **unverified**, not inferred.  CI evidence is likewise inapplicable to the selected dependency-free pattern; for the optional crates it is incomplete: `supports-hyperlinks` and `timeago` do not provide enough current, inspected Ubuntu-and-macOS workflow evidence in this run, while `jiff` has a public GitHub workflow directory but was not adopted.  No candidate is selected on popularity.

### Principles and implementation

**Shared requirement and agreement level.** At the *capability and architectural-policy* level, all three blueprints should expose one canonical result and permit text-only enrichment without changing JSON, CSV, Markdown, or a future web response.  py supplies evidence for that split: `table_rows_rich()` defaults to `table_rows()`, while its text renderer alone reads the rich variant. [py model](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/models.py) [py renderer](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/cli/output.py) (retrieved 2026-09-05). ts has no comparable feature, so this is missing capability rather than evidence that raw markup strings are a shared low-level value. The Rust implementation may differ because Rust’s trait defaults and typed enums remove the need to pass parser-specific markup through a `String`.

Use the named **plain-first terminal projection** pattern:

```rust
enum TextCell {
    Plain(String),
    Link { label: String, target: ValidatedUri },
    RelativeTime { signed_seconds: i64 },
}

trait TableRows {
    fn plain_rows(&self) -> Vec<Vec<String>>;

    fn text_rows(&self) -> Vec<Vec<TextCell>> {
        self.plain_rows()
            .into_iter()
            .map(|row| row.into_iter().map(TextCell::Plain).collect())
            .collect()
    }
}
```

The trait default is the native equivalent of py’s fallback: it is explicit, locally overridable, and defined by the language to apply when an implementation supplies no override. [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05). A result type opts in only where it has semantic link or time data; the renderer formats `RelativeTime` with `fn relative_time(signed_seconds: i64) -> String`, using `unsigned_abs`, largest-first year/month/day/hour/minute buckets, and `just now` under 60 seconds. The helper is pure and deterministic because the caller computes `moment - now` or passes a test-supplied clock. It avoids selecting a date-time dependency merely to express a five-bucket display policy.

`ValidatedUri` is not an untrusted `String`: construct it at the boundary by parsing/percent-encoding the appropriate URI and rejecting C0 controls, DEL, ESC, BEL, and the string terminator sequence. The terminal writer prints the label as literal text (sanitizing terminal-control bytes to a visible representation) and emits `ESC ] 8 ; ; <validated-uri> ST` immediately around that already-laid-out label only when R65 authorizes hyperlinks. It always emits the closing OSC 8 sequence. Thus no table-renderer markup parser sees label text, and a `[` in a path needs no special-case escaping. OSC 8 is an escape-sequence convention rather than a universal guarantee; unsupported terminals therefore receive just the label. [OSC 8 adoption list](https://github.com/Alhadis/OSC8-Adoption) (retrieved 2026-09-05); [osc8 format documentation](https://docs.rs/osc8/latest/osc8/) (retrieved 2026-09-05).

**Architectural comparison.** A separate CLI wrapper/newtype centralizes policy but cannot know which arbitrary string is a link or timestamp without recreating per-model knowledge; it is the runner-up. Raw rich strings match py but make table width, parser injection, and non-text leakage renderer-dependent. A trait default plus structured `TextCell` keeps opt-in semantic and moves irreversible escape emission to the only layer that knows the output destination. `fd` demonstrates the related split between `IsTerminal`, output policy, and hyperlink activation; `ripgrep` demonstrates caution because terminal/multiplexer compatibility is not universal. [fd source](https://github.com/sharkdp/fd/blob/master/src/main.rs) [ripgrep maintainer discussion](https://github.com/BurntSushi/ripgrep/discussions/2611) (retrieved 2026-09-05).

**Observable acceptance criteria.** (1) `plain_rows`, JSON, CSV, and web serialization contain neither ESC nor relative wording. (2) A default `text_rows` override-free result produces exactly the plain cells. (3) An opted-in result renders `2 days ago`, `in 3 hours`, and `just now` for ±172800, -10800, and any absolute delta under 60 seconds. (4) With R65’s terminal/hyperlink gate false, a link cell emits only its literal label; with it true, it emits exactly one opening and closing OSC 8 pair around that label. (5) Labels containing `[`, `ESC`, or BEL cannot start markup or a terminal control sequence. (6) The same snapshot is exercised on Ubuntu and macOS at the declared MSRV. These are proposed checks; none were run because Rust code does not exist yet.

BASELINE-REVIEW: F359 — terminal-only enrichment must never alter machine-readable or web contracts — replace parser-specific rich-markup strings with a default trait projection of structured `TextCell` values, rendered after layout and only through R65’s gate — py demonstrates plain/rich separation; Rust trait defaults support the fallback; fd and ripgrep demonstrate conservative, explicit terminal-hyperlink emission. [F359 ledger](../../../../docs/port/COMMONALITY.md) [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html) [fd manual](https://github.com/sharkdp/fd/blob/master/doc/fd.1) (retrieved 2026-09-05).

### Dominant choice

**Plain-first terminal projection:** a `TableRows` trait whose `text_rows()` default maps `plain_rows()` to `TextCell::Plain`, with opt-in `Link` and `RelativeTime` variants; the text renderer performs all visual formatting and OSC 8 emission after table layout. This has no new crate, async-runtime coupling, binary-size cost, or compile-time cost beyond a small internal enum and formatter. The selected pattern’s crate figures are inapplicable because it adds no crate.

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| Plain-first terminal projection (chosen) | Rust trait default semantics in the [Rust Reference](https://doc.rust-lang.org/reference/items/traits.html) (retrieved 2026-09-05) | py’s default rich-row hook is analogous; `fd` separates output activation from presentation; both are relevant, maintained references. [py model](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/models.py) [fd source](https://github.com/sharkdp/fd/blob/master/src/main.rs) (retrieved 2026-09-05) | Rust Reference, crawled 2026-09-03; retrieved 2026-09-05. |
| CLI wrapper/newtype over plain strings | `fd` output and hyperlink policy modules show centralized output policy. [fd source](https://github.com/sharkdp/fd/blob/master/src/main.rs) (retrieved 2026-09-05) | `fd`; relevant because it gates terminal escapes centrally. | fd current source, retrieved 2026-09-05. |
| Rich-markup string hook | py’s `table_rows_rich()` and Rich-markup helper. [py model](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/models.py) [py formatter](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/format.py) (retrieved 2026-09-05) | `py-launch-blueprint`; it is the only established source precedent. | py main branch, retrieved 2026-09-05. |
| `supports-hyperlinks` plus an OSC-8 emitter crate | [crate documentation](https://docs.rs/supports-hyperlinks/latest/supports_hyperlinks/) and [osc8 documentation](https://docs.rs/osc8/latest/osc8/) (retrieved 2026-09-05) | `osc8` itself recommends `supports-hyperlinks`; independent production adopters were not verified in this run. | `supports-hyperlinks` 3.2.0, 2025-12-17; `osc8` 0.1.0, 2024-08-09, from their crates.io versions endpoints, retrieved 2026-09-05. |

### Excluded by gate

* `osc8` is excluded as the emitter dependency: compatible `MIT` license is documented, but its published manifest does not declare an MSRV and current Ubuntu-and-macOS CI evidence was not verified. Its Codeberg repository also makes the required GitHub figures inapplicable. [versions endpoint](https://crates.io/api/v1/crates/osc8/versions) (retrieved 2026-09-05).
* `supports-hyperlinks` is not adopted: its 1.70 MSRV and Apache-2.0 license fit, and it contains no `unsafe` in the released source, but it answers only a support heuristic that R65 owns; its RustSec package page and complete platform-CI proof were unavailable in this run. [versions endpoint](https://crates.io/api/v1/crates/supports-hyperlinks/versions) [required RustSec URL](https://rustsec.org/packages/supports-hyperlinks.html) (retrieved 2026-09-05).
* `timeago` is not adopted: its license and MSRV fit, but the required RustSec endpoint returned 404 and its policy does not directly cover future wording or the exact `just now` boundary. [versions endpoint](https://crates.io/api/v1/crates/timeago/versions) [required RustSec URL](https://rustsec.org/packages/timeago.html) (retrieved 2026-09-05).
* `jiff` is not adopted for display formatting: license and MSRV fit, but it is a broad time library with default `std` features and internal `unsafe`; the exact display policy is still local. Its required RustSec endpoint returned 404. [versions endpoint](https://crates.io/api/v1/crates/jiff/versions) [required RustSec URL](https://rustsec.org/packages/jiff.html) (retrieved 2026-09-05).

### Up-and-comers

`supports-hyperlinks` is the best future reconsideration candidate if R65 explicitly needs a support-heuristic dependency: it is narrowly scoped, Apache-2.0, MSRV 1.70, has no released-source `unsafe`, and released 3.2.0 on 2025-12-17. [crate endpoint](https://crates.io/api/v1/crates/supports-hyperlinks) [versions endpoint](https://crates.io/api/v1/crates/supports-hyperlinks/versions) (retrieved 2026-09-05). `timeago` is the smaller formatter candidate if localization becomes an owned requirement, but its English duration orientation does not by itself meet the future-time contract. [timeago docs](https://docs.rs/timeago/latest/timeago/) (retrieved 2026-09-05). `jiff` is a strong date-time foundation only if another item already chooses it for timestamp semantics; importing it solely for this row feature would be an integration-cost mismatch. [Jiff docs](https://docs.rs/jiff/latest/jiff/) (retrieved 2026-09-05).

### Fit for this template

* **CLI:** The pattern makes human text nicer only when the R65 gate permits it. It keeps pipes, redirected output, and explicit plain modes literal, following the conservative practice documented by `fd` and ripgrep. [fd manual](https://github.com/sharkdp/fd/blob/master/doc/fd.1) [ripgrep discussion](https://github.com/BurntSushi/ripgrep/discussions/2611) (retrieved 2026-09-05).
* **Library:** Public result types retain stable plain data. The optional trait projection is presentation code, not a serialization contract, so callers do not inherit OSC escapes or wording choices. This preserves the py model/renderer separation while using Rust-native typing. [py model](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/models.py) (retrieved 2026-09-05).
* **Web:** The web service serializes canonical fields and ISO timestamps, never `TextCell`, OSC 8, or relative phrases. This is the same capability-level agreement as py’s non-text renderers; the concrete Rust representation is deliberately different. [py formatter](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/format.py) (retrieved 2026-09-05).

### Recommendation

Adopt **plain-first terminal projection**. Implement a default trait method returning typed plain cells, override it only on result types with semantic links or timestamps, and make the final text writer convert those variants to literal display text or OSC 8 after R65 allows it. Use a small in-tree, pure relative-time helper with the py-compatible coarse policy; do not add `osc8`, `supports-hyperlinks`, `timeago`, or `jiff` for R85. Validate URI and label control bytes at construction and never send renderer markup syntax through table cells. This gives the requested terminal capability with no format leakage, no new dependency, and no re-decision of R65 or R66.

### Ranked runner-up

**CLI-level wrapper/newtype over plain row strings.** It wins only if R66’s selected text-table crate cannot accept typed cells or provide a final-cell emission hook after width calculation. In that case, make the wrapper receive an explicit per-column/per-row semantic map from the result type; do not infer links or times by pattern-matching arbitrary strings. That preserves the essential separation but has more central routing complexity.

### Tradeoffs

Compared with py-style rich markup strings, the pick gives up the shortest implementation and Rich’s automatic parser escaping; it accepts that cost to avoid coupling every Rust table implementation to a markup grammar and to make control-byte handling auditable. Compared with a wrapper/newtype, it gives up a single renderer-owned transformation point; it accepts per-result overrides because semantic knowledge belongs with the result. Compared with `supports-hyperlinks`/`osc8`, it gives up a packaged detection/encoding API; it accepts a tiny locally tested encoder because R65 owns gating and the package gates were not fully evidenced. Compared with `timeago` and `jiff`, it gives up localization and broad date-time functionality; neither is required by the fixed coarse English policy.

### Parameters

No owned or consumed parameter is registered for R85. R65’s color/TTY/hyperlink gate and R66’s base row/format surface remain related, not consumed, decisions. No parameter change is needed; therefore no `CONFLICT:` line is emitted.

### Migration implications

Planned file-level changes after R65 and R66 settle:

1. `crates/<library>/src/result.rs`: define `TableRows`, `TextCell`, `ValidatedUri`, `plain_rows()`, and the default `text_rows()`.
2. `crates/<library>/src/presentation.rs`: add the pure, signed-seconds `relative_time()` and URI/label validation helpers; keep them out of serialized model types.
3. `crates/<cli>/src/output/text.rs`: let the R66 table adapter measure literal labels, then emit OSC 8 only at final write time when R65 grants the capability.
4. `crates/<cli>/src/output/json.rs` and `crates/<cli>/src/output/csv.rs`: consume canonical fields or `plain_rows()` only; add assertions that their bytes contain no ESC.
5. `crates/<library>/tests/presentation.rs` and `crates/<cli>/tests/output.rs`: add deterministic projection, control-byte, pipe, and platform snapshots.

These paths are proposed names because no Rust workspace exists yet; the placement, not a specific existing path, is the decision.

### Validation strategy

Planned, not executed, commands after the workspace exists:

```sh
cargo test -p <library-crate> presentation -- --nocapture
cargo test -p <cli-crate> output::text -- --nocapture
cargo test -p <cli-crate> output::machine -- --nocapture
cargo test --workspace
```

The first test supplies fixed signed deltas and verifies `just now`, `2 days ago`, and `in 3 hours`. The text test exercises a default result, an opted-in link/timestamp result, R65 false, and R65 true; it compares bytes and asserts one OSC 8 opener and closer only in the true case. The machine test renders the same result as JSON and CSV and rejects ESC plus the display phrases. The workspace test runs the same fixtures on `ubuntu-latest` and `macos-latest` with the declared `rust-version`/stable-minus-two-minor MSRV lane. These checks measure one small row set (default and opted-in variants), no asynchronous work, no throughput claim, and no meaningful resource or latency cost; performance is therefore a qualitative constant-factor allocation/formatting cost, not a benchmark result.

### Confidence & re-verify trigger

**Medium-high confidence** in the boundary pattern, because it follows Rust’s documented trait-default semantics and two maintained Rust CLI examples of conservative hyperlink gating. **Medium confidence** in the exact no-dependency implementation until R65 selects its gate and R66 selects a table writer with a post-layout emission seam. Re-verify before implementation if either item selects a renderer that accepts only raw strings, if a new owner requirement adds localization or user-configurable relative-time precision, if the MSRV changes, or if OSC 8 support policy is made independently configurable. Also re-query RustSec, the four crate version endpoints, and the GitHub issue samples then; the RustSec package URLs and full responsiveness samples were unavailable in this run.

### Sources

* Rust trait-default semantics: <https://doc.rust-lang.org/reference/items/traits.html> (retrieved 2026-09-05).
* OSC 8 compatibility inventory: <https://github.com/Alhadis/OSC8-Adoption> (retrieved 2026-09-05); format reference used by the optional crate: <https://docs.rs/osc8/latest/osc8/> (retrieved 2026-09-05).
* Maintained Rust CLI examples: <https://github.com/sharkdp/fd/blob/master/doc/fd.1>, <https://github.com/sharkdp/fd/blob/master/src/main.rs>, <https://github.com/BurntSushi/ripgrep/releases/tag/14.0.0>, and <https://github.com/BurntSushi/ripgrep/discussions/2611> (all retrieved 2026-09-05).
* Source precedent: <https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/models.py>, <https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/format.py>, and <https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/cli/output.py> (all retrieved 2026-09-05); local ledger `docs/port/COMMONALITY.md`, F359 (read 2026-09-05).
* Required crate figures: `GET https://crates.io/api/v1/crates/{supports-hyperlinks,timeago,jiff,osc8}` and `/versions`; GitHub `GET https://api.github.com/repos/{zkat/supports-hyperlinks,vi/timeago,BurntSushi/jiff}` and `GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open` (all queried 2026-09-05).
* Required RustSec package pages: <https://rustsec.org/packages/supports-hyperlinks.html>, <https://rustsec.org/packages/timeago.html>, <https://rustsec.org/packages/jiff.html>, and <https://rustsec.org/packages/osc8.html> (all queried 2026-09-05; each returned HTTP 404, so advisory status is unverified).

Method notes: I queried the four required crates.io crate and versions endpoints; the required GitHub repository, open-issue-search, and recent-issue/comment endpoints where available; the four required RustSec package URLs; docs.rs; maintained project documentation; and the cited py source. GitHub unauthenticated rate limiting prevented a complete ten-issue first-maintainer-response sample after the first verified `supports-hyperlinks` response. RustSec’s required package URLs returned 404. No Rust implementation, performance benchmark, CI run, or empirical terminal probe was executed; all acceptance commands above are proposed.
