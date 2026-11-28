#!/usr/bin/env bash
# Regression tests for committed.toml and committed.bot.toml (R38).
# Verifies the 11-type enum, 50-col whole-header cap, 72-col soft-line body and
# footer caps, bare-URL / trailer-URL soft-line exemptions, subject punctuation,
# --fixup / --wip hook flags, and dependabot width-only relaxation.
set -euo pipefail

export PATH="${HOME}/.local/bin:${CARGO_HOME:-$HOME/.cargo}/bin:${PATH}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
main_cfg="$repo_root/committed.toml"
bot_cfg="$repo_root/committed.bot.toml"

pass=0
fail=0
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

ok() {
    echo "ok   $1"
    pass=$((pass + 1))
}

bad() {
    echo "FAIL $1" >&2
    fail=$((fail + 1))
}

command -v committed >/dev/null 2>&1 || {
    echo "FAIL committed binary not found on PATH" >&2
    exit 1
}

for cfg in "$main_cfg" "$bot_cfg"; do
    if [ ! -f "$cfg" ]; then
        bad "missing config file: $cfg"
        echo
        echo "$pass passed, $fail failed"
        exit 1
    fi
done

run_msg() {
    local want="$1" name="$2" cfg="$3" extra="$4" msg="$5"
    local msg_file="$tmp_root/msg.txt"
    printf '%s\n' "$msg" >"$msg_file"
    local rc=0
    if [ -n "$extra" ]; then
        # shellcheck disable=SC2086
        committed --config "$cfg" $extra --commit-file "$msg_file" >/dev/null 2>&1 || rc=$?
    else
        committed --config "$cfg" --commit-file "$msg_file" >/dev/null 2>&1 || rc=$?
    fi
    if { [ "$want" = ok ] && [ "$rc" -eq 0 ]; } || { [ "$want" = fail ] && [ "$rc" -ne 0 ]; }; then
        ok "$name"
    else
        bad "$name (exit $rc, wanted $want)"
    fi
}

# 1. All 11 allowed types pass under committed.toml
for t in build chore ci docs feat fix perf refactor revert style test; do
    run_msg ok "allowed type '$t' passes" "$main_cfg" "" "$t: valid subject"
done

# 2. Disallowed type fails under BOTH main and bot configs
run_msg fail "disallowed type fails under committed.toml" "$main_cfg" "" "wibble: invalid type"
run_msg fail "disallowed type fails under committed.bot.toml" "$bot_cfg" "" "wibble: invalid type"

# 3. Header > 50 cols fails (and measures whole 'type(scope): description' line)
# Description alone is 41 cols, whole line is 66 cols.
long_header="feat(workspace-config): add a new configuration flag for output ok"
run_msg fail "66-col whole header fails committed.toml" "$main_cfg" "" "$long_header"
run_msg ok "66-col header passes committed.bot.toml (dependabot width relaxation)" "$bot_cfg" "" "$long_header"

# 4. Exact 50-col header passes
exact_50="feat(cli): add exact fifty character header line x"
if [ "${#exact_50}" -ne 50 ]; then
    bad "internal test invariant: exact_50 length is ${#exact_50}, expected 50"
fi
run_msg ok "exact 50-col header passes committed.toml" "$main_cfg" "" "$exact_50"

# 5. Body line > 72 cols with spaces fails main, passes bot
long_body=$(printf 'feat: short header\n\nThis body line contains spaces and deliberately exceeds the seventy-two column limit.')
run_msg fail "body line > 72 cols fails committed.toml" "$main_cfg" "" "$long_body"
run_msg ok "body line > 72 cols passes committed.bot.toml" "$bot_cfg" "" "$long_body"

# 6. Footer line > 72 cols with spaces fails main
long_footer=$(printf 'feat: short header\n\nBody text.\n\nReviewed-by: Someone With A Very Long Name Who Makes This Footer Line Exceed Seventy Two Columns')
run_msg fail "footer line > 72 cols with spaces fails committed.toml" "$main_cfg" "" "$long_footer"

# 7. Soft-line exemption: bare URL > 72 cols passes
bare_url=$(printf 'docs: add reference link\n\nhttps://github.com/smorinlabs/rs-launch-blueprint/blob/0123456789abcdef0123456789abcdef01234567/docs/port/PARAMETERS.md')
run_msg ok "soft-line bare URL > 72 cols passes committed.toml" "$main_cfg" "" "$bare_url"

# 8. Soft-line exemption: trailer whose final token is a long URL passes
url_trailer=$(printf 'feat: add session reference\n\nBody.\n\nClaude-Session: https://claude.ai/code/session_0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef')
run_msg ok "soft-line trailer with long URL final token passes committed.toml" "$main_cfg" "" "$url_trailer"

# 9. Subject ending with a period fails
run_msg fail "subject ending in period fails committed.toml" "$main_cfg" "" "feat: end with period."

# 10. Lower-case subject and identifier-leading subject both pass
run_msg ok "identifier-leading subject passes committed.toml" "$main_cfg" "" "docs: P05 local quality gates"

# 11. Hook flags --fixup --wip accept fixup! and reject WIP:
run_msg ok "--fixup --wip accepts fixup! commit" "$main_cfg" "--fixup --wip" "fixup! feat: previous commit"
run_msg fail "--fixup --wip rejects WIP: commit" "$main_cfg" "--fixup --wip" "WIP: not ready"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
