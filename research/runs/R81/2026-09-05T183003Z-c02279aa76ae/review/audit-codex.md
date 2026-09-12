decision-sha256: 204949689ccc0c3190c2479ca80d5c18f9fd9753931cffcf78706190d75ff21d
actor: audit-codex-2026-09-05T183003Z-c02279aa76ae-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1 dependency-tree licence summary calls a CC-BY-4.0 AND MIT package permissive; F2 platform-asset claim overstates mdBook 0.5.4 availability; F3 branch transition omits the required Justfile changes; F4 the script does not assert every result the decision says it asserts

## Rerun

- argv: `bash review/evidence/docs-delivery-claims.sh`
- cwd: an isolated copy at `/private/tmp/r81-audit-log-full.1G14uj/repo/research/runs/R81/2026-09-05T183003Z-c02279aa76ae`, preserving the script's expected relative repository layout and using a copied current `docs/port/PARAMETERS.md`. The original audit directory received only this report and the requested log.
- toolchain: macOS 26.4, Darwin 25.4.0 arm64, `rustc 1.98.0`, `cargo 1.98.0`, and `gh 2.98.0`.
- exit: 0; 52 `PASS` assertions; `failed assertions: 0`.
- log: `review/evidence/audit-docs-delivery-model-r1.log`.
- match: yes. `cmp` against `review/evidence/docs-delivery-claims.log` was empty; both files have SHA-256 `6d8da82b7b814743ce9ffc0c641e84968849d7da53a0fb42107601e2c87f9a7e`.
- Linux: `/opt/homebrew/bin/limactl` was callable, but the `ubuntu` instance was stopped. Starting it was denied by the sandbox at `/Users/stevemorin/.lima/ubuntu/ha.stdout.log`; no Linux command ran. The macOS rerun is therefore the executed result.

## Findings

### F1 — the licence summary is wider than the dependency dump supports

`DECISION.md:78` says that all 210 non-mdBook-family packages are permissive. The saved dump has 218 entries: the eight named `mdbook*` packages are `MPL-2.0`, but `font-awesome-as-a-crate 0.3.1` is `CC-BY-4.0 AND MIT`. The next sentence accurately records its attribution obligation, so it cannot also be included in an assertion that all 210 are permissive. The rerun's check 8 reproduced exactly that value and the dump has no other package with a GPL, AGPL, EUPL, or SSPL-only declaration.

Revise the aggregate claim to distinguish the attribution-bearing package from the remaining declarations. Retain the existing conditional statement that a P03 build must determine whether the default theme emits its assets.

### F2 — the release-platform claim must identify the actual asset mapping

`DECISION.md:272-275` says mdBook 0.5.4 publishes prebuilt binaries for Linux and macOS, both x86_64 and aarch64. The decision cites no release-assets check for this statement. The audit queried `GET /repos/rust-lang/mdBook/releases/tags/v0.5.4`; the matching assets are `mdbook-v0.5.4-x86_64-unknown-linux-gnu.tar.gz`, `mdbook-v0.5.4-x86_64-apple-darwin.tar.gz`, and `mdbook-v0.5.4-aarch64-apple-darwin.tar.gz`. There is no `aarch64-unknown-linux-gnu` asset.

The required Ubuntu/macOS matrix may still be satisfied by the listed runner architectures, but the sentence must map each asset to its platform and cite the release endpoint. It must not imply Linux aarch64 support from this release.

### F3 — the claimed one-commit branch transition omits a branch-A artifact

`DECISION.md:33-36` says branch A adds only `book.toml`, `.github/workflows/docs.yml`, and a README URL. `DECISION.md:245-247` also requires branch-A-only `justfile` recipes `docs-build`, `docs-dev`, `docs-init`, and `docs-clean`, all invoking `mdbook`; branch B has no generator recipes. The transition therefore includes a `justfile` change.

Either include those recipes in the branch delta or narrow the statement to corpus and navigation stability. This does not undermine the deliberate licence split: the corpus, dialect, navigation, and landing-page policy remain independent of the ruling; it corrects the claimed implementation delta for the conditional layer.

### F4 — the script emits all listed results, but it does not assert all of them

The rerun reproduced the cited log byte-for-byte, including the archived plugin and yanked-registry facts. It also confirms the required limits: no adopter of the exact proposed Pages-action major versions is claimed, and rendering identity remains explicitly unproven.

However, `DECISION.md:337-339` says every check asserts its expected content. That is false. For example, `docs-delivery-claims.sh:74-79` queries and prints `mdbook-admonish` and `mdbook-alerts` but has no assertion for either result; `:83-95` prints the three Pages actions' `archived` fields but asserts only their licences; and `:157-165` prints Spotifyd's whole action triple but asserts only its deploy action. These commands do run and emit the values the table cites, so the table's current facts reproduced. They are nevertheless not failure-gated assertions as the decision says.

Either add assertions for every cited result or change the decision to distinguish asserted checks from recorded query output. The 52-assertion count and its all-pass result are accurate.

## Assessment

The central split is real. Branch B's no-generator substitute has no dependency tree, no un-audited substitute is named, and both explicit implementation gaps remain correctly labeled as unproven. The document must nevertheless be revised before approval: F1 makes a broad licence classification contradicted by its own dump; F2 overstates a platform fact; F3 understates the conditional implementation delta; and F4 overstates the check script's assertion coverage.
