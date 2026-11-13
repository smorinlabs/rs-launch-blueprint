#!/usr/bin/env bash
# shellcheck disable=SC2016
#   SC2016 is disabled file-wide and deliberately: every single-quoted
#   search string below is a literal quotation of a source file, a
#   registry cell or a compiler message, and the backticks, `$` signs and
#   Markdown emphasis inside them must NOT expand. Single quotes are the
#   point, not an oversight.
#
# R03 port-absence-vs-failure-contract — synthesizer check 3 of 3.
#
# Verifies the practice and language claims the raw reports rest on, by reading
# the sources themselves at pinned tags and commits, and checks whether the
# URLs the Doxa OpenAI provider cited for the two source repositories actually
# resolve — raw/opus.md asserts those repositories are private and answer 404.
# Implements nothing.
#
# Determinism contract
# --------------------
#   * Every source file is fetched at an immutable ref — a git tag for
#     `rust-lang/rust` and a full commit SHA for each practice repository — so
#     the bytes cannot drift. Each fetch is snapshotted into ./snap/ and read
#     from the snapshot afterwards; delete ./snap/ to re-fetch.
#   * crates.io download counters DO drift. The one JSON response used is
#     snapshotted the same way and the figures are reported with the endpoint
#     and the retrieval date recorded in ./snap/RETRIEVED.txt.
#   * Repository visibility is asked of the GitHub API through the `gh` binary,
#     which is already authenticated; no token is read, printed or passed here.
#   * No machine-dependent text reaches stdout. So
#     `bash r03-practice.sh | diff - r03-practice.log` is empty on any rerun
#     against the same snapshots.
#   * Without the network (and without a populated ./snap/), each section
#     prints `SKIP` with the reason instead of failing.
#
# Usage: bash r03-practice.sh          (run from anywhere)

set -uo pipefail

GREP=/usr/bin/grep
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
EVID="$HERE"
SNAP="$EVID/snap"
UA='rs-launch-blueprint-research/1.0'

RUST_TAG=1.96.0
CRATESIO_SHA=3a31e6c87ee884a3ff0608f0d65ede1f01454c98
SQLX_SHA=b54008a329541c0ce230d8b203e0c00fc8e8ea48
JJ_SHA=e6dd2c0d60f22ef8d21d171b5fb8e4178f0af1d9
OBJSTORE_SHA=279572ea60f3a7a6e5237e066a6f4a35eee611e0

mkdir -p "$SNAP"

FAILED=0
section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }
skip()    { printf 'SKIP %s — %s\n' "$1" "$2"; }

assert() {
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
  else
    printf 'FAIL %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}

count() { $GREP -c -F -- "$2" "$1" 2>/dev/null || true; }

# ctx <snapname> <anchor-fixed-string> <lines-before> <lines-after>
#   prints the anchored block and leaves it in $CTXFILE for a following assert
CTXDIR=$(mktemp -d)
trap 'rm -rf "$CTXDIR"' EXIT
CTXFILE=""
CTXN=0
ctx() {
  local f="$SNAP/$1"
  CTXN=$((CTXN + 1))
  CTXFILE="$CTXDIR/ctx.$CTXN"
  [ -s "$f" ] || return 1
  $GREP -n -B"$3" -A"$4" -F -- "$2" "$f" > "$CTXFILE" 2>/dev/null || return 1
  cat "$CTXFILE"
  return 0
}

# fetch <snapname> <url>  — cached; returns 1 when the file cannot be obtained
fetch() {
  local f="$SNAP/$1"
  if [ ! -s "$f" ]; then
    curl -sSfL -H "User-Agent: $UA" -o "$f" "$2" || { rm -f "$f"; return 1; }
    date -u '+%Y-%m-%dT%H:%M:%SZ' | sed "s|^|$1 |" >> "$SNAP/RETRIEVED.txt"
  fi
  return 0
}

# has <snapname> <label> <expected-count> <fixed-string>
has() {
  local f="$SNAP/$1"
  if [ ! -s "$f" ]; then skip "$2" "snapshot $1 unavailable (offline and not cached)"; return; fi
  assert "$2" "$3" "$(count "$f" "$4")"
}

section '1. std at rust-lang/rust tag '"$RUST_TAG"' — the language claims'

RAW_RUST="https://raw.githubusercontent.com/rust-lang/rust/$RUST_TAG"
fetch option.rs "$RAW_RUST/library/core/src/option.rs"
fetch io-error.rs "$RAW_RUST/library/std/src/io/error.rs"
fetch path.rs "$RAW_RUST/library/std/src/path.rs"

claim 'Option is the std-documented channel for partial functions'
has option.rs 'option.rs module docs name partial functions' 1 \
  'over their entire input range (partial functions)'

claim 'ok_or_else — the translation combinator — with the stability attribute above it'
if ctx option.rs 'pub const fn ok_or_else<E, F>' 3 0; then
  assert 'ok_or_else is stable since 1.0.0' 1 \
    "$(count "$CTXFILE" '#[stable(feature = "rust1", since = "1.0.0")]')"
else
  skip 'ok_or_else stability' 'snapshot option.rs unavailable'
fi

claim 'transpose — the std-supplied conversion that names the canonical nesting'
if ctx option.rs 'pub const fn transpose(self) -> Result<Option<T>, E>' 4 0; then
  assert 'transpose is stable since 1.33.0' 1 \
    "$(count "$CTXFILE" '#[stable(feature = "transpose_result", since = "1.33.0")]')"
else
  skip 'transpose stability' 'snapshot option.rs unavailable'
fi

claim 'std reports filesystem absence as an error variant, not as None — the runner-up shape in std'
has io-error.rs 'io::ErrorKind is #[non_exhaustive]' 1 '#[non_exhaustive]'
has io-error.rs 'io::ErrorKind carries a NotFound variant' 1 'An entity was not found, often a file.'

claim 'and std warns against the separate existence probe this decision forbids'
has path.rs 'Path::exists carries the TOCTOU warning' 1 \
  'this method may be error-prone, consider using [`try_exists()`] instead!'

section '2. rust-lang/crates.io @ '"$CRATESIO_SHA"' — the split shape in a production port'

fetch crates_io_github.rs \
  "https://raw.githubusercontent.com/rust-lang/crates.io/$CRATESIO_SHA/crates/crates_io_github/src/lib.rs"
has crates_io_github.rs 'the port trait is declared' 1 'pub trait GitHubClient: Send + Sync'
has crates_io_github.rs 'team_membership returns Result<Option<..>> (trait + impl)' 2 \
  'Result<Option<GitHubTeamMembership>>'
has crates_io_github.rs 'org_membership returns Result<Option<..>> (trait + impl)' 2 \
  'Result<Option<GitHubOrgMembership>>'
has crates_io_github.rs 'the adapter owns the 404 rule, per operation' 2 \
  'Err(GitHubError::NotFound(_)) => Ok(None),'
if [ -s "$SNAP/crates_io_github.rs" ]; then
  claim 'the per-operation translation, verbatim'
  $GREP -n -B2 -A1 -F 'Err(GitHubError::NotFound(_)) => Ok(None),' "$SNAP/crates_io_github.rs" | head -14
fi

section '3. sqlx @ '"$SQLX_SHA"' — the split shape is the primitive, the fold is derived'

fetch sqlx-executor.rs \
  "https://raw.githubusercontent.com/launchbadge/sqlx/$SQLX_SHA/sqlx-core/src/executor.rs"
fetch sqlx-error.rs \
  "https://raw.githubusercontent.com/launchbadge/sqlx/$SQLX_SHA/sqlx-core/src/error.rs"
claim 'fetch_optional is declared without a body — a driver author implements the split shape'
if ctx sqlx-executor.rs 'fn fetch_optional<' 0 6; then
  assert 'its return type carries the Option inside the Result' 1 \
    "$(count "$CTXFILE" 'Result<Option<<Self::Database as Database>::Row>, Error>>')"
  assert 'and the declaration ends in a semicolon (required, not provided)' 1 \
    "$(count "$CTXFILE" "E: 'q + Execute<'q, Self::Database>;")"
else
  skip 'sqlx fetch_optional' 'snapshot sqlx-executor.rs unavailable'
fi
has sqlx-executor.rs 'fetch_one is built from fetch_optional' 1 'self.fetch_optional(query)'
has sqlx-executor.rs 'and it is the fold that introduces the error' 1 'None => Err(Error::RowNotFound),'
has sqlx-error.rs 'sqlx also ships the folded variant' 1 'RowNotFound,'

section '4. The runner-up shape, read at its own pins'

fetch objstore-lib.rs \
  "https://raw.githubusercontent.com/apache/arrow-rs-object-store/$OBJSTORE_SHA/src/lib.rs"
claim 'object_store folds absence into its error enum, with a boxed cause'
if ctx objstore-lib.rs 'NotFound {' 0 5; then
  assert 'the NotFound variant carries the boxed std cause' 1 \
    "$(count "$CTXFILE" "source: Box<dyn std::error::Error + Send + Sync + 'static>,")"
else
  skip 'object_store NotFound' 'snapshot objstore-lib.rs unavailable'
fi

fetch jj-backend.rs \
  "https://raw.githubusercontent.com/jj-vcs/jj/$JJ_SHA/core/src/backend.rs"
has jj-backend.rs 'jj folds absence into its backend error' 1 'ObjectNotFound {'

section '5. thiserror, the only crate in the picture (R67 selected it; not re-evaluated here)'

if fetch thiserror.json 'https://crates.io/api/v1/crates/thiserror'; then
  claim 'GET https://crates.io/api/v1/crates/thiserror — retrieval date in ./snap/RETRIEVED.txt'
  if command -v jq > /dev/null 2>&1; then
    jq -r '"crate.recent_downloads = \(.crate.recent_downloads)",
           "crate.downloads        = \(.crate.downloads)",
           "crate.max_stable_version = \(.crate.max_stable_version)"' "$SNAP/thiserror.json"
    assert 'max_stable_version is the 2.x line the probe pinned' 2 \
      "$(jq -r '.crate.max_stable_version' "$SNAP/thiserror.json" | cut -d. -f1)"
  else
    skip 'thiserror figures' 'jq not on PATH'
  fi
else
  skip 'thiserror figures' 'crates.io not reachable and no snapshot cached'
fi

section '6. Source-repository visibility, and the citations given for them'

claim 'visibility through the authenticated gh binary (no token is read or printed here)'
if command -v gh > /dev/null 2>&1; then
  for r in py-launch-blueprint ts-launch-blueprint rs-launch-blueprint; do
    v=$(gh api "repos/smorinlabs/$r" --jq '.private' 2> /dev/null)
    if [ -z "$v" ]; then v='(no answer)'; fi
    printf 'repos/smorinlabs/%-22s .private = %s\n' "$r" "$v"
  done
else
  skip 'visibility' 'gh not on PATH'
fi

claim 'unauthenticated HTTP status of the URLs raw/doxa-openai.normalized.md cites as its evidence'
for u in 'https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts' \
         'https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md' \
         'https://github.com/smorinlabs/rs-launch-blueprint'; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "User-Agent: $UA" "$u")
  st=$?
  if [ "$st" -ne 0 ]; then code='(no answer)'; fi
  printf '%s  %s\n' "$code" "$u"
  assert "the cited URL resolves unauthenticated: ${u##*/}" 200 "$code"
done

section 'RESULT'
if [ "$FAILED" -eq 0 ]; then
  printf 'ALL CHECKS PASSED\n'
else
  printf '%s CHECK(S) FAILED\n' "$FAILED"
fi
exit "$FAILED"
