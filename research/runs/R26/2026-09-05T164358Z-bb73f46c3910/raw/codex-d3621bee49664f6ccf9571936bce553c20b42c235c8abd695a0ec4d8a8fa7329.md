### Landscape

This item decides a release-integrity capability: the release job must reject a crate archive whose file set or publish-facing manifest differs from the reviewed source. The capability is shared with TypeScript; the tooling and the precise manifest semantics are Cargo-specific. The source precedent is F039 (file-list assertion) and F078 (publish-time content guard), recorded as one R26 bundle in `docs/port/COMMONALITY.md`; both rows are `DIVERGENT`, not preselected implementations. Retrieved 2026-09-05 from the repository context.

| Field bin | Candidate | Result for this template | Evidence |
|---|---|---|---|
| Built-in / first-party toolchain | `cargo package --list` | The stable file-list oracle. It prints the files Cargo would put in the package without creating it. | Cargo command reference, https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05). |
| Built-in / first-party toolchain | `cargo package` followed by inspection of the generated `.crate` | The archive oracle for the normalized manifest. Cargo documents that packaging writes the archive, rewrites and normalizes `Cargo.toml`, removes `[patch]`, `[replace]`, and `[workspace]`, and retains the author manifest as `Cargo.toml.orig`. | Cargo command reference, https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05). |
| Established industry standard | A checked-in expected package-path file plus POSIX `sort` and `diff` | A small, reviewable policy layer over the first-party list. It adds no Rust dependency and makes every added or removed shipped path an intentional review change. | Cargo recommends `cargo package --list` to verify package contents; Cargo's include/exclude rules are documented at https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05). |
| Up-and-comer, not eligible | `cargo package --list -Zunstable-options --message-format=json` | Do not use. Cargo documents JSON file-list output as unstable and requiring `-Zunstable-options`, which conflicts with the stable-Rust constraint. | Cargo command reference, https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05). |
| External wrapper lead | `cargo-package` crate | Excluded. The crates.io endpoint reports one yanked `0.0.0` release, created 2023-08-31; it has no non-yanked release, no declared MSRV, and no repository URL. It cannot satisfy the maintenance or MSRV gates. Its 90-day downloads are 4 and all-time downloads are 1,206. | Crates.io crate endpoint, https://crates.io/api/v1/crates/cargo-package, and versions endpoint, https://crates.io/api/v1/crates/cargo-package/versions (retrieved 2026-09-05). RustSec's package URL, https://rustsec.org/packages/cargo-package.html, was queried on 2026-09-05 but did not supply usable advisory data. |

The authority set is intentionally first-party. The Cargo Book is maintained by the Rust project and specifies the packaging behavior that crates.io receives; it is stronger evidence for this decision than a wrapper's marketing. Cargo's publishing guide explicitly recommends `cargo publish --dry-run` or the equivalent `cargo package`, identifies `target/package` as the archive location, and recommends `cargo package --list` for inspecting shipped files. Source: https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

Practice evidence is limited but supports the primitive rather than a wrapper: Freenet's public CI invokes `cargo package --list` and fails when required embedded resources are absent. This is evidence that a maintained Rust project uses the built-in listing in CI; it is not evidence for a full exact allowlist or manifest projection. Source: https://github.com/freenet/freenet-core/blob/main/.github/workflows/ci.yml (retrieved 2026-09-05). No maintained, purpose-built action or crate that performs exact Cargo package-list diffing was identified in the targeted crates.io and GitHub repository searches. The GitHub REST repository-detail endpoint was rate-limited, so repository stars, archival state, push time, open-issue count, and first-response medians were not verified and are deliberately not used as selection evidence. GitHub endpoint attempted: https://api.github.com/repos/rust-lang/cargo; search endpoint attempted: https://api.github.com/search/repositories?q=cargo+package+list (retrieved 2026-09-05).

Cargo's default is not a complete security boundary. When neither `[package].include` nor `[package].exclude` is set, Cargo starts from the package root and excludes defined cases, including VCS-ignored files in a Git checkout; setting `include` disables the Git-ignore rule. Cargo also always includes the package `Cargo.toml`, a minimized `Cargo.lock`, and any declared `license-file`. Therefore, the VCS-aware default can reduce accidental leaks, but it does not make a reviewed file-set assertion redundant. Source: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05).

### Principles and implementation

The shared requirement is capability-level agreement: before an irreversible publication, prove that the bytes and package metadata presented to the registry match a reviewed release contract. TypeScript implements the same capability at publish time with an `npm pack --dry-run --json` file assertion (F039) and a guard for npm's `bin` correction (F078); the project inventory identifies both as parts of the same publish verification job. Source: `docs/port/areas/ci-workflows.md` and `docs/port/areas/release-versioning.md` in the supplied repository context, retrieved 2026-09-05.

The Rust-native architecture has two checks driven by the same first-party Cargo invocation:

1. Compare the stable, newline-delimited result of `cargo package --list --locked` with a checked-in expected path list. The comparison must include Cargo-generated entries such as `Cargo.toml.orig`, `Cargo.lock`, and, in a tagged Git checkout, `.cargo_vcs_info.json` when Cargo lists them. It must not attempt to reconstruct Cargo's include/exclude algorithm in shell. Cargo documents the list as the package contents and documents the generated entries and the VCS snapshot file. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).
2. Run `cargo package --locked`, inspect that exact generated `.crate`, and compare a declared publish-facing metadata projection from the source manifest to the archive's normalized manifest. Also byte-compare the source `Cargo.toml` with the archive's `Cargo.toml.orig`. This accepts Cargo's documented transformations while detecting an unexpected change to package identity, version, license, repository, documentation, homepage, readme, categories, keywords, Rust version, edition, publish setting, default binary, or declared targets. Cargo documents the expected transformations; Cargo metadata has a stable, versioned JSON format when called with an explicit `--format-version`. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.crates.io/external-tools.html (retrieved 2026-09-05).

The raw `Cargo.toml` and the packaged `Cargo.toml` must not be expected to be textually equal. Cargo deliberately normalizes the latter and removes `[patch]`, `[replace]`, and `[workspace]`; `Cargo.toml.orig` is the archive member that preserves the author-written manifest. This is a real Cargo analogue to the TypeScript concern, but it is not an undocumented silent correction. The active guard is consequently a projection equality check with a documented allowlist of transformations, not a blanket "no rewrite" check. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

The checks belong in the publish workflow's verify job, immediately before the protected publication step. That placement preserves F039/F078's release-time containment and validates the clean, tagged checkout that is actually about to publish. Running the exact-list check on every pull request is a defensible future hardening, but it adds maintenance pressure to every source-file change and is not necessary to prevent the release being published. This is a recommendation, not an observed benchmark. Cargo's own guidance places package and dry-run publication verification before publishing. Source: https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

Observable acceptance criteria are:

- An extra tracked or included file makes the expected-list diff fail before any `cargo publish` command runs.
- Removing a required shipped file makes the same diff fail before publication.
- The archive's `Cargo.toml.orig` is byte-for-byte the release source manifest.
- The declared publish-facing metadata projection is identical before and after packaging, except for Cargo's documented normalization and removal of the three non-published sections.
- A passing verification runs `cargo package --locked`; therefore Cargo has created and verified the `.crate` that the inspection reads. The separate install-and-run proof remains R50.

No `BASELINE-REVIEW:` finding currently names F039 or F078 in `docs/port/BASELINE-REVIEW.md` (repository checked 2026-09-05). The proposed design retains the principle and publish-time placement; therefore it does not introduce a baseline challenge requiring a new `BASELINE-REVIEW:` line.

### Recommendation

Use Cargo `1.98.0` (the stable toolchain observed in this research environment on 2026-09-05, subject to the repository's stable-minus-two MSRV policy) with no added crates or GitHub Actions: a repository-owned `scripts/check-package-contents.sh` script runs `cargo package --list --locked`, diffs it against a checked-in expected list, creates the archive with `cargo package --locked`, checks `Cargo.toml.orig`, and compares a reviewed `cargo metadata --format-version 1` projection from source and archive. Invoke the script only in the publish workflow's verify job, before `cargo publish`.

`cargo package --list` is the direct stable Cargo analogue to TypeScript's dry-run file list. The stable command emits one path per line; its JSON form is explicitly unstable, so line-oriented `sort`/`diff` is the appropriate native implementation. Cargo's documented normalization makes a separate metadata-projection comparison necessary and makes a direct `Cargo.toml` equality assertion incorrect. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

### Members

#### Cargo package-content contract

##### Landscape

The first-party candidates are `cargo package --list` and archive inspection after `cargo package`; the stable command is the dominant choice. The only machine-readable list mode documented by Cargo requires nightly `-Zunstable-options`, so it is not a stable-Rust candidate. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

##### Principles and implementation

The principle is a reviewed, exact shipped-file contract. The proposed script obtains the file set from Cargo rather than reimplementing manifest include/exclude and Git-ignore semantics. A checked-in list records the contract; a normal PR diff makes any intentional file-list change reviewable. Cargo documents `include`, `exclude`, VCS-ignore behavior, and always-included files. Source: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05).

##### Dominant choice

`cargo package --list --locked`, normalized with `LC_ALL=C sort`, compared by `diff -u` with `ci/package-contents.txt`. It is a built-in stable command, so crate download, release, repository, issue, RustSec, dependency-tree MSRV, `unsafe`, feature, runtime, binary-size, and compile-time figures are inapplicable: no third-party crate is selected. Its platform support is Cargo's supported host toolchain; the planned workflow must run the same script on both `ubuntu-latest` and `macos-latest` as required by the fixed target matrix. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Qualified shortlist

`cargo package --list` is the sole qualified choice. The Cargo publishing guide specifically recommends it to inspect package contents, and Cargo itself applies the inclusion rules that crates.io receives. Source: https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

##### Excluded by gate

`cargo-package` is excluded before popularity: the crates.io versions endpoint has one yanked `0.0.0` release from 2023-08-31, no non-yanked release, no `rust_version`, no repository, and no demonstrated Ubuntu/macOS CI. The crate endpoint reports 4 recent downloads and 1,206 all-time downloads. Its license is `Apache-2.0 OR MIT`, which is compatible, but a license pass does not overcome its failed maintenance and MSRV gates. RustSec advisory status is unverified because the queried package page supplied no usable package result; `unsafe`, default features, async coupling, binary size, compile time, GitHub stars, archived state, pushed date, open issues, and responsiveness are unverified rather than assumed. Sources: https://crates.io/api/v1/crates/cargo-package, https://crates.io/api/v1/crates/cargo-package/versions, and https://rustsec.org/packages/cargo-package.html (retrieved 2026-09-05).

##### Up-and-comers

Cargo's JSON list output is an up-and-comer only. It would ease parsing, but Cargo labels `--message-format=json` for `cargo package --list` unstable and requires `-Zunstable-options`; stable Rust excludes it. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Fit for this template

The command covers a CLI, library, and optional web-service crate because it asks Cargo for the actual archive file set, independent of runtime framework. The expected file list is particularly valuable because Cargo's default is an exclusion policy, not an explicit allowlist, and can vary with VCS-ignore state. Source: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05).

##### Recommendation

Adopt `cargo package --list --locked` plus a checked-in exact list and POSIX `sort`/`diff`; do not add a wrapper crate or action.

##### Ranked runner-up

Use only `[package].include` as the policy and run `cargo package --list` without a checked-in diff. This is weaker because a broad glob can still accidentally admit a new matching file and because generated Cargo entries still need to be understood. Source: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05).

##### Tradeoffs

The exact list creates a deliberate update when an intended source, README, license, or generated Cargo entry changes. That maintenance cost is the review signal. The runtime cost is one Cargo packaging-list calculation; no comparative performance benchmark was run. Binary-size, compile-time, `unsafe`, features, and async-runtime costs are inapplicable because the recommendation adds no crate.

##### Parameters

No owned or consumed parameter is defined for R26. The script receives the package selected by the publish workflow, so it does not assume the unresolved workspace topology. No `CONFLICT:` line is emitted.

##### Migration implications

Add `ci/package-contents.txt`, the reviewed relative-path allowlist; add `scripts/check-package-contents.sh`, the list and archive verifier; and call that script from `.github/workflows/publish.yml`'s verify job before publication. The template has no Rust implementation yet, so these are proposed file-level changes.

##### Validation strategy

Planned, not executed: add an otherwise harmless tracked file such as `leak.txt`; `cargo package --list --locked` must produce it and the list diff must fail. Then delete a required path from the expected list; the same diff must fail. Restore the contract and require the script to pass on `ubuntu-latest` and `macos-latest`. Cargo lists the archive file set without producing the archive. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Confidence & re-verify trigger

High confidence in the built-in primitive because it is Cargo-documented. Re-verify when the pinned stable Cargo version changes, when Cargo stabilizes JSON list output, when the package layout changes, or when the expected list changes. No release-package command was run against a Rust template because none exists yet.

##### Sources

Cargo command documentation: https://doc.rust-lang.org/cargo/commands/cargo-package.html. Cargo publishing guide: https://doc.rust-lang.org/cargo/reference/publishing.html. Cargo manifest inclusion rules: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields. All retrieved 2026-09-05.

#### Cargo manifest-normalization contract

##### Landscape

Cargo package creation is the first-party mechanism. It is not a literal npm `bin` analogue: Cargo documents manifest rewriting as part of archive production and exposes the unmodified author manifest as `Cargo.toml.orig`. No stable Cargo switch provides a declarative "fail on any normalized manifest difference" policy. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Principles and implementation

The principle is semantic metadata integrity, not textual identity. The script must compare a predefined public metadata projection of source and packaged manifests and separately prove that `Cargo.toml.orig` preserves source bytes. It must accept removal of `[patch]`, `[replace]`, and `[workspace]`, because Cargo documents those as packaging transformations. Cargo's manifest reference defines the publish-facing fields and target declarations that the projection contains. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/manifest.html (retrieved 2026-09-05).

##### Dominant choice

Run built-in `cargo metadata --no-deps --locked --format-version 1` on the source manifest and extracted archive manifest. Project and compare `name`, `version`, `description`, `license`, `license_file`, `repository`, `homepage`, `documentation`, `readme`, `keywords`, `categories`, `rust_version`, `edition`, `links`, `publish`, `default_run`, and target names, kinds, crate types, and required features. Crate figures and all third-party fitness gates are inapplicable because this uses the Cargo executable and `jq`, not a third-party Rust crate. Cargo documents explicit metadata format versioning for tool integration. Source: https://doc.rust-lang.org/cargo/reference/external-tools.html (retrieved 2026-09-05).

##### Qualified shortlist

The qualified standard-tool shortlist is `cargo metadata --format-version 1` plus `jq` projection and `diff`. The `cargo_metadata` crate is not selected because the verification is a short workflow script, not a Rust program, and Cargo's JSON is already stable and versioned when the format version is explicit. The crate's documentation identifies its purpose as structured access to Cargo metadata, but no added dependency is justified here. Source: https://docs.rs/cargo_metadata/latest/cargo_metadata/ (retrieved 2026-09-05).

##### Excluded by gate

No wrapper crate or GitHub Action met the direct need for package-archive metadata projection in the targeted survey. The only directly named `cargo-package` crate is excluded under the content member's gates; its evidence is recorded above. `cargo_metadata` is not excluded for a failed license, MSRV, RustSec, platform, `unsafe`, feature, runtime, binary-size, or compile-time gate; it is not selected because it would duplicate stable Cargo JSON parsing and add dependency maintenance. Its figures were not collected because it is not a candidate for the release workflow stack.

##### Up-and-comers

No up-and-comer is recommended. The unstable JSON list option solves a different file-list problem and does not remove the need to inspect Cargo's normalized archive manifest. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Fit for this template

The projection checks package metadata that affects every distributable shape in the template: crate identity and version, license, repository and documentation links, Rust edition and minimum Rust version, binaries, library targets, and publishing policy. It does not test installation or runtime behavior; R50 owns that separate acceptance question. Cargo identifies the manifest as package metadata and documents these fields. Source: https://doc.rust-lang.org/cargo/reference/manifest.html (retrieved 2026-09-05).

##### Recommendation

Adopt a source-versus-archive `cargo metadata` projection plus a byte comparison of source `Cargo.toml` to archive `Cargo.toml.orig`. Treat any projection difference as a failure, and treat only Cargo's documented normalized-manifest changes as expected.

##### Ranked runner-up

Check only that `Cargo.toml.orig` equals the source. This proves author-manifest preservation but does not prove that publish-facing metadata in normalized `Cargo.toml` retained its effective values; it is therefore insufficient alone.

##### Tradeoffs

The explicit field projection must be updated if Cargo introduces a new publish-facing field the template elects to control. That is preferable to silently accepting a future transformation. The check is qualitative low cost: Cargo packaging is already required for release verification, and metadata parsing touches only manifests. Third-party crate cost, `unsafe`, feature, runtime, binary-size, and compile-time metrics are inapplicable.

##### Parameters

No R26-owned or consumed parameter changes. The metadata projection must enforce the fixed `rust-edition = 2024` and the `msrv-policy` outcome through the actual `edition` and `rust_version` values in the selected package manifest. No `CONFLICT:` line is emitted.

##### Migration implications

The proposed `scripts/check-package-contents.sh` owns the projection list and archive extraction. `.github/workflows/publish.yml` supplies the selected package manifest path and runs the verifier before `cargo publish`. No new Cargo dependency or GitHub Action is added.

##### Validation strategy

Planned, not executed: mutate the generated archive copy's `Cargo.toml` `license` or `version` value in a test fixture and verify that the projected JSON diff fails; mutate only a documented non-published section in source and verify that the projection remains meaningful while `Cargo.toml.orig` still equals the source. The integration test must use a fixture archive because changing an actual generated archive is not a normal release operation. Cargo documents the normalizations and `Cargo.toml.orig`. Source: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

##### Confidence & re-verify trigger

Medium-high confidence. The documented transformations are clear, but the exact projection needs an implementation review once the R02 workspace boundary and R49 target declaration are decided. Re-verify on Cargo upgrades, package metadata schema changes, new manifest fields relevant to publication, or a new Cargo warning about normalization.

##### Sources

Cargo package behavior: https://doc.rust-lang.org/cargo/commands/cargo-package.html. Manifest field reference: https://doc.rust-lang.org/cargo/reference/manifest.html. Cargo metadata integration format: https://doc.rust-lang.org/cargo/reference/external-tools.html. All retrieved 2026-09-05.

### Compatibility

The two members compose in one `cargo package --locked` release verification: the pre-package `--list` gives the declared file contract; the generated archive supplies `Cargo.toml.orig` and normalized `Cargo.toml` for the semantic metadata contract; and Cargo's own package verification then compiles the extracted package. This is a same-command compatibility proof, not an assertion that an external wrapper integrates the members. Cargo documents both the archive-creation sequence and the package verification sequence. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

### Parameters

No `owns` or `assumes` entries exist for R26 in the binding prompt. The recommendation uses the fixed `rust-edition = 2024`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest` as validation constraints, not as changed parameters. It respects the MSRV policy by using stable Cargo commands only. No `CONFLICT:` lines are emitted.

### Migration implications

Proposed changes after the implementation plan chooses package topology:

| File | Change | Purpose |
|---|---|---|
| `ci/package-contents.txt` | Add one sorted, relative archive-path contract for the published package. | Makes shipped-file changes explicit in review. |
| `scripts/check-package-contents.sh` | Add a POSIX shell verifier parameterized by the selected publish package. | Performs the stable Cargo list, archive, original-manifest, and metadata-projection checks. |
| `.github/workflows/publish.yml` | Run the verifier in the verify job after checkout/toolchain setup and before the protected `cargo publish` step. | Stops an invalid archive before the irreversible upload. |
| `tests/fixtures/package-content-guard/` | Add positive and negative fixture cases for extra files and metadata drift. | Exercises the verifier without publishing. |

The script must preserve Cargo's generated archive paths in the expected list. It must select the package explicitly with the workflow's manifest path rather than assume a single-package root; this accommodates either outcome of R02 without changing an R26 parameter. These are proposals because the Rust template has no implementation yet. Cargo's package-selection and archive behavior are documented at https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).

### Validation strategy

The following is the planned release verifier core, not an executed result. It uses only stable Cargo, `tar`, `jq`, `sort`, `cmp`, and `diff`; the workflow must confirm those utilities on both required GitHub-hosted runners before adopting it.

```sh
#!/usr/bin/env sh
set -eu

manifest="$1"
expected="ci/package-contents.txt"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT HUP INT TERM
manifest_dir="$(CDPATH= cd "$(dirname "$manifest")" && pwd)"
manifest="$manifest_dir/$(basename "$manifest")"

cargo package --manifest-path "$manifest" --locked --list | LC_ALL=C sort >"$work/actual-files"
LC_ALL=C sort "$expected" >"$work/expected-files"
diff -u "$work/expected-files" "$work/actual-files"

cargo package --manifest-path "$manifest" --locked
source_metadata="$(cargo metadata --manifest-path "$manifest" --no-deps --locked --format-version 1)"
source_package="$(printf '%s' "$source_metadata" | jq -ce --arg manifest "$manifest" '
  [.packages[] | select(.manifest_path == $manifest)] |
  if length == 1 then .[0] else error("publish manifest did not select one package") end
')"
name="$(printf '%s' "$source_package" | jq -r '.name')"
version="$(printf '%s' "$source_package" | jq -r '.version')"
target_directory="$(printf '%s' "$source_metadata" | jq -r '.target_directory')"
archive="$target_directory/package/$name-$version.crate"
tar -xzf "$archive" -C "$work"
root="$work/$name-$version"

cmp "$manifest" "$root/Cargo.toml.orig"

printf '%s' "$source_package" | jq -S '{
  name, version, description, license, license_file, repository, homepage,
  documentation, readme, keywords, categories, rust_version, edition, links,
  publish, default_run,
  targets: [.targets[] | {name, kind, crate_types, required_features}]
}' >"$work/source.json"
cargo metadata --manifest-path "$root/Cargo.toml" --no-deps --locked --format-version 1 |
  jq -S '.packages[0] | {
    name, version, description, license, license_file, repository, homepage,
    documentation, readme, keywords, categories, rust_version, edition, links,
    publish, default_run,
    targets: [.targets[] | {name, kind, crate_types, required_features}]
  }' >"$work/archive.json"
diff -u "$work/source.json" "$work/archive.json"
```

`cargo package --list` is documented to print package files without making the archive. `cargo package` creates the `.crate`, rewrites and normalizes the archive manifest, and verifies the package; the publishing guide identifies `target/package` as the generated archive location. Sources: https://doc.rust-lang.org/cargo/commands/cargo-package.html and https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).

The first implementation must confirm the script against the selected R02 workspace layout; the proposed script already requires the passed manifest to identify exactly one package and derives the archive directory from Cargo metadata. This report did not execute the command because the template has no Rust workspace. The required positive and inverse controls are: (1) exact list and matching metadata pass; (2) an additional shipped fixture file fails the list diff; (3) a missing required fixture path fails the list diff; (4) a changed archive `license` or target fails the metadata diff; and (5) a documented source-only `[patch]`, `[replace]`, or `[workspace]` difference does not cause a false manifest-text failure. R50, not R26, must separately prove that the packaged artifact installs and runs.

### Confidence & re-verify trigger

Confidence is high that `cargo package --list` is the correct stable file-set oracle and high that Cargo has documented, intentional manifest normalization. Confidence is medium-high that the recommended projection is the right policy surface: its field list must be reviewed with the eventual workspace and binary-target decisions. No current Rust template command, two-OS workflow, archive fixture, GitHub issue responsiveness sample, GitHub repository figures, RustSec advisory result for a rejected wrapper, performance benchmark, or package install smoke test was executed in this run.

Re-verify before implementation when R02 selects the workspace boundary and R49 selects target declarations; before each Cargo toolchain bump; if Cargo stabilizes JSON package-list output; if Cargo changes its documented normalization rules; if the published package adds a manifest field that affects registry consumers; or if `ci/package-contents.txt` changes. Re-verify the full command on `ubuntu-latest` and `macos-latest` before declaring the check accepted.

### Sources

- Cargo command reference, including `--list`, unstable JSON output, archive normalization, `Cargo.toml.orig`, generated VCS data, and package verification: https://doc.rust-lang.org/cargo/commands/cargo-package.html (retrieved 2026-09-05).
- Cargo publishing guide, including dry-run equivalence, archive location, and file-list inspection: https://doc.rust-lang.org/cargo/reference/publishing.html (retrieved 2026-09-05).
- Cargo manifest reference, including `include`/`exclude`, VCS-ignore behavior, and always-included files: https://doc.rust-lang.org/cargo/reference/manifest.html#the-exclude-and-include-fields (retrieved 2026-09-05).
- Cargo external-tools reference, including versioned `cargo metadata` JSON: https://doc.rust-lang.org/cargo/reference/external-tools.html (retrieved 2026-09-05).
- `cargo_metadata` documentation, consulted as a non-selected parsing alternative: https://docs.rs/cargo_metadata/latest/cargo_metadata/ (retrieved 2026-09-05).
- Rejected-wrapper figures: https://crates.io/api/v1/crates/cargo-package, https://crates.io/api/v1/crates/cargo-package/versions, and https://rustsec.org/packages/cargo-package.html (retrieved 2026-09-05).
- Practice lead: https://github.com/freenet/freenet-core/blob/main/.github/workflows/ci.yml (retrieved 2026-09-05).

Method notes: queried Cargo Book command, publishing, manifest, and external-tool pages; crates.io's `cargo-package` crate and versions endpoints; the RustSec package page; GitHub REST repository and search endpoints; and a public CI reference. GitHub repository-detail retrieval was rate-limited, so no GitHub maintenance figures were claimed. No Doxa or paid research was used. The source-precedent claims came from the supplied R26 prompt and the repository's `docs/port/` inventory. No other engine's output was consulted.
