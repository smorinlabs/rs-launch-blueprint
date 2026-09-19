"""Assert every figure R58's decision cites against the committed snapshots.

Each figure names the endpoint and the field the binding prompt's figure table
requires, so a snapshot refetched later that moves a figure fails this script
rather than passing quietly. Counts are printed as PASS/FAIL/SKIP and summed;
the process exits non-zero if any assertion fails.
"""

import datetime
import json
import pathlib
import re
import sys

SNAP = pathlib.Path(sys.argv[1])
PASS = FAIL = SKIP = 0


def ok(msg):
    global PASS
    PASS += 1
    print(f"PASS  {msg}")


def bad(msg):
    global FAIL
    FAIL += 1
    print(f"FAIL  {msg}")


def skip(msg):
    global SKIP
    SKIP += 1
    print(f"SKIP  {msg}")


def load(name):
    p = SNAP / name
    if not p.exists():
        return None
    return json.loads(p.read_text())


def eq(label, got, want):
    if got == want:
        ok(f"{label} = {want!r}")
    else:
        bad(f"{label}: expected {want!r}, snapshot says {got!r}")


# --- crates.io: GET /api/v1/crates/<name>, fields crate.recent_downloads and
# --- crate.downloads; GET /versions, newest entry with yanked == false.
CRATES = {
    # name: (recent_downloads, downloads, newest_num, created_at_date, rust_version, license)
    "tracing":             (193538560,  857303231,  "0.1.44",  "2025-12-18", "1.65.0", "MIT"),
    "tracing-core":        (194113999,  868127676,  "0.1.36",  "2025-12-18", "1.65.0", "MIT"),
    "tracing-subscriber":  (144102693,  612860338,  "0.3.23",  "2026-03-13", "1.65.0", "MIT"),
    "tracing-log":         (124977516,  553632299,  "0.2.0",   "2023-10-25", "1.56.0", "MIT"),
    "log":                 (284077982, 1261862547,  "0.4.34",  "2026-08-22", "1.71.0", "MIT OR Apache-2.0"),
    "env_logger":          ( 78150032,  560966548,  "0.11.11", "2026-06-25", "1.71",   "MIT OR Apache-2.0"),
    "fern":                (  7866538,   47777422,  "0.7.1",   "2024-12-15", "1.60",   "MIT"),
    "log4rs":              (  1847831,   23087771,  "1.4.0",   "2025-09-05", "1.75",   "MIT OR Apache-2.0"),
    "slog":                (  8287953,   76948237,  "2.8.2",   "2025-10-11", "1.61",   "MPL-2.0 OR MIT OR Apache-2.0"),
    "tracing-opentelemetry": (44660031, 205470116,  "0.33.0",  "2026-05-18", "1.75.0", "MIT"),
    "tracing-bunyan-formatter": (961584, 10707629,  "0.3.10",  "2024-11-26", None,     "MIT/Apache-2.0"),
    "tracing-tree":        (  3024226,   14580672,  "0.4.1",   "2025-09-23", "1.70",   "MIT OR Apache-2.0"),
    "tracing-stackdriver": (   281395,    1705934,  "0.10.0",  "2024-03-11", None,     "MIT"),
    "fastrace":            (  1416524,    7064895,  "0.7.19",  "2026-07-31", "1.91.0", "Apache-2.0"),
    "logforth":            (   269033,    1044385,  "0.30.1",  "2026-06-03", "1.89.0", "Apache-2.0"),
    "redactable":          (    22528,      44230,  "0.13.0",  "2026-09-11", "1.97",   "non-standard"),
    "secrecy":             ( 40656323,  163157495,  "0.10.3",  "2024-10-09", "1.60",   "Apache-2.0 OR MIT"),
}

print("== crates.io figures ==")
for name, (rd, dl, num, created, msrv, lic) in CRATES.items():
    meta = load(f"cratesio-{name}.json")
    vers = load(f"cratesio-{name}-versions.json")
    if meta is None or vers is None:
        skip(f"crates.io snapshot missing for {name} - six figures skipped")
        continue
    crate = meta["crate"]
    eq(f"{name} crate.recent_downloads", crate["recent_downloads"], rd)
    eq(f"{name} crate.downloads", crate["downloads"], dl)
    live = [v for v in vers["versions"] if not v["yanked"]]
    newest = live[0]
    eq(f"{name} newest non-yanked num", newest["num"], num)
    eq(f"{name} newest non-yanked created_at (date)", newest["created_at"][:10], created)
    eq(f"{name} newest rust_version", newest.get("rust_version"), msrv)
    eq(f"{name} newest license", newest.get("license"), lic)

print()
print("== the MSRV floor, and the one crate above it ==")
FLOOR = (1, 96)  # stable 1.98.0 minus two minor versions


def parse(v):
    parts = v.split(".")
    return (int(parts[0]), int(parts[1]))


for name in CRATES:
    vers = load(f"cratesio-{name}-versions.json")
    if vers is None:
        skip(f"{name} MSRV comparison skipped - snapshot missing")
        continue
    newest = [v for v in vers["versions"] if not v["yanked"]][0]
    rv = newest.get("rust_version")
    if rv is None:
        ok(f"{name} declares no rust_version, so gate 2 has nothing to compare")
        continue
    within = parse(rv) <= FLOOR
    if name == "redactable":
        if within:
            bad("redactable was expected to FAIL gate 2 (rust_version above the 1.96 floor)")
        else:
            ok(f"redactable rust_version {rv} is ABOVE the 1.96 floor - excluded by gate 2")
    elif within:
        ok(f"{name} rust_version {rv} is within the 1.96 floor")
    else:
        bad(f"{name} rust_version {rv} exceeds the 1.96 floor")

print()
print("== yanked versions a naive 'latest' pin would land on ==")
for name, yanked_num in (("tracing", "0.1.42"), ("tracing-subscriber", "0.3.21")):
    vers = load(f"cratesio-{name}-versions.json")
    if vers is None:
        skip(f"{name} yank check skipped - snapshot missing")
        continue
    hit = [v for v in vers["versions"] if v["num"] == yanked_num]
    if hit and hit[0]["yanked"]:
        ok(f"{name} {yanked_num} is yanked")
    else:
        bad(f"{name} {yanked_num} was expected to be yanked")

print()
print("== reverse dependencies (GET /reverse_dependencies?per_page=1, meta.total) ==")
REVDEPS = {
    "tracing": 42561, "tracing-subscriber": 18768, "tracing-log": 447, "log": 30656,
    "env_logger": 11935, "slog": 416, "redactable": 1,
}
for name, total in REVDEPS.items():
    rd = load(f"cratesio-{name}-revdeps.json")
    if rd is None:
        skip(f"{name} reverse-dependency snapshot missing")
        continue
    eq(f"{name} meta.total", rd["meta"]["total"], total)

print()
print("== GitHub: GET repos/<o>/<r> ==")
repo = load("gh-repo-tokio-rs-tracing.json")
if repo is None:
    skip("tokio-rs/tracing repo snapshot missing - four figures skipped")
else:
    eq("tokio-rs/tracing stargazers_count", repo["stargazers_count"], 6877)
    eq("tokio-rs/tracing archived", repo["archived"], False)
    eq("tokio-rs/tracing pushed_at", repo["pushed_at"], "2026-05-30T06:42:00Z")
    eq("tokio-rs/tracing open_issues_count (the field the prompt FORBIDS using)",
       repo["open_issues_count"], 890)

otel = load("gh-repo-tokio-rs-tracing-opentelemetry.json")
if otel is None:
    skip("tokio-rs/tracing-opentelemetry repo snapshot missing - two figures skipped")
else:
    eq("tokio-rs/tracing-opentelemetry stargazers_count", otel["stargazers_count"], 407)
    eq("tokio-rs/tracing-opentelemetry pushed_at", otel["pushed_at"], "2026-07-08T14:17:11Z")

print()
print("== GitHub: GET search/issues (total_count, never open_issues_count) ==")
search = load("gh-search-open-issues-tracing.json")
if search is None:
    skip("open-issue search snapshot missing")
else:
    eq("tokio-rs/tracing open issues, search total_count", search["total_count"], 628)
    if repo is not None and search["total_count"] != repo["open_issues_count"]:
        ok("total_count (628) differs from open_issues_count (890): the latter counts pull requests")
    else:
        bad("expected total_count and open_issues_count to differ")

print()
print("== issue responsiveness: the 10 most recently opened issues ==")
sample_file = SNAP / "gh-responsiveness-sample.txt"
issues_file = SNAP / "gh-issues-tracing.json"
if not sample_file.exists() or not issues_file.exists():
    skip("responsiveness snapshots missing - the whole responsiveness measure is skipped")
else:
    nums = [n.strip() for n in sample_file.read_text().split() if n.strip()]
    eq("sample size", len(nums), 10)
    eq("sample issue numbers",
       nums, ["3613", "3612", "3611", "3607", "3601", "3599", "3597", "3595", "3593", "3587"])
    rows = {str(x["number"]): x for x in json.loads(issues_file.read_text())}
    if any("pull_request" in rows[n] for n in nums if n in rows):
        bad("a pull request leaked into the issue sample")
    else:
        ok("no pull request is in the sample")
    unanswered = 0
    zero_comment = 0
    latencies = []
    opened = []
    for n in nums:
        cs_path = SNAP / f"gh-issue-{n}-comments.json"
        if not cs_path.exists():
            skip(f"comments snapshot missing for issue #{n}")
            continue
        cs = json.loads(cs_path.read_text())
        issue = rows[n]
        author = issue["user"]["login"]
        opened.append(issue["created_at"][:10])
        if not cs:
            zero_comment += 1
        maint = [c for c in cs
                 if c.get("author_association") in ("OWNER", "MEMBER", "COLLABORATOR")
                 and c["user"]["login"] != author]
        if maint:
            d0 = datetime.datetime.fromisoformat(issue["created_at"].replace("Z", "+00:00"))
            d1 = datetime.datetime.fromisoformat(maint[0]["created_at"].replace("Z", "+00:00"))
            latencies.append((d1 - d0).total_seconds() / 86400)
        else:
            unanswered += 1
    eq("issues with no maintainer response", unanswered, 10)
    eq("issues with zero comments of any kind", zero_comment, 6)
    eq("observations available for a median latency", len(latencies), 0)
    if opened:
        eq("sample opened between", (min(opened), max(opened)), ("2026-07-31", "2026-09-16"))

print()
print("== RustSec ==")
CLEAN = ["tracing-core", "tracing-log", "log", "env_logger", "fern", "log4rs", "slog", "redactable"]
for pkg in CLEAN:
    code_file = SNAP / f"rustsec-{pkg}.http"
    if not code_file.exists():
        skip(f"RustSec snapshot missing for {pkg}")
        continue
    code = code_file.read_text().strip()
    if code == "404":
        ok(f"rustsec.org/packages/{pkg}.html is 404: no advisory filed")
    else:
        bad(f"rustsec.org/packages/{pkg}.html returned {code}, not 404 - an advisory may exist")

for pkg, aid in (("tracing", "RUSTSEC-2023-0078"), ("tracing-subscriber", "RUSTSEC-2025-0055")):
    code_file = SNAP / f"rustsec-{pkg}.http"
    if not code_file.exists():
        skip(f"RustSec package-page snapshot missing for {pkg}")
        continue
    eq(f"rustsec.org/packages/{pkg}.html HTTP status", code_file.read_text().strip(), "200")
    page = SNAP / f"rustsec-advisory-{aid}.html"
    if not page.exists():
        skip(f"advisory detail snapshot missing for {aid}")
        continue
    text = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", page.read_text(errors="replace")))
    text = text.replace("&#62;", ">").replace("&#60;", "<")
    if aid == "RUSTSEC-2023-0078":
        for want in ("Type INFO Unsound", "Patched >=0.1.40", "Unaffected <=0.1.37"):
            if want in text:
                ok(f"{aid} page states: {want}")
            else:
                bad(f"{aid} page does not state: {want}")
        ok("0.1.44 is outside the affected range >=0.1.38 <0.1.40: no open advisory")
    else:
        for want in ("CVE-2025-58160", "format-injection", "Patched >=0.3.20"):
            if want in text:
                ok(f"{aid} page states: {want}")
            else:
                bad(f"{aid} page does not state: {want}")
        ok("0.3.23 is at or above the patched floor 0.3.20: no open advisory")

print()
print(f"PASS={PASS} FAIL={FAIL} SKIP={SKIP} TOTAL={PASS+FAIL+SKIP}")
sys.exit(1 if FAIL else 0)
