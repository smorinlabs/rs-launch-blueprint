#!/usr/bin/env bash
# R84 revision 3 — registry, repository and advisory figures, collected the way
# the prompt's figure table prescribes (spec §7.6), retrieved on the run date.
# Revision 3 changes: the M01 Maven Central block keeps the timeout-60 /
# three-attempt form it took during the r2 regeneration (disclosed, not
# silent); volatile output honours $R84_SNAPSHOT, so a rerun only overwrites
# the cited snapshots/registry-figures.json when the override is unset.
#
# Stable facts (a published version's metadata, an advisory page's absence, a
# repository's archived flag, a document's text) are ASSERTED here. Volatile
# figures (downloads, stars, open-issue counts, issue latencies, newest
# versions) are written to snapshots/registry-figures.json with their endpoint
# and are asserted only where the decision leans on them, against a floor.
#
# Endpoints: crates.io /api/v1/crates/<name>, /versions, /reverse_dependencies
# (one call per second, with a User-Agent, as crates.io's policy asks);
# api.github.com through `gh api` (REST only, at least 21 s between calls);
# rustsec.org/packages/<name>.html with a known-advisory control; Maven Central
# (reachability only); doc.rust-lang.org (the Cargo Book's text).
# Sections whose network is unreachable print SKIP by name. The log carries no
# timestamp beyond the retrieval date, and no temporary path.
# Reruns that must not disturb the cited evidence set R84_SNAPSHOT to a path
# outside the tree; the log is byte-identical either way.

set -uo pipefail

HERE=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
export R84_SNAPSHOT="${R84_SNAPSHOT:-$HERE/snapshots/registry-figures.json}"
mkdir -p "${R84_SNAPSHOT%/*}"
command -v python3 >/dev/null 2>&1 || { echo "SKIP  S0 python3 is absent"; echo; echo "PASS=0 FAIL=0 SKIP=1 TOTAL=1"; exit 0; }

python3 - <<'PY'
import datetime, json, os, shutil, statistics, subprocess, sys, time, urllib.request, urllib.error

UA = "rs-launch-blueprint-research (R84 synthesis)"
counts = {"PASS": 0, "FAIL": 0, "SKIP": 0}
snap = {"retrieved": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d"), "crates": {}, "github": {}, "notes": []}

def out(kind, msg):
    counts[kind] += 1
    print("%-5s %s" % (kind, msg), flush=True)

def check(cond, msg):
    out("PASS" if cond else "FAIL", msg)

def http(url, method="GET", timeout=40):
    req = urllib.request.Request(url, method=method, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, b""
    except Exception as e:
        return None, str(e).encode()

last_crates = [0.0]
def crates(path):
    wait = 1.1 - (time.time() - last_crates[0])
    if wait > 0:
        time.sleep(wait)
    last_crates[0] = time.time()
    status, body = http("https://crates.io/api/v1/" + path)
    return json.loads(body) if status == 200 else None

last_gh = [0.0]
def gh(path):
    wait = 21 - (time.time() - last_gh[0])
    if wait > 0:
        time.sleep(wait)
    last_gh[0] = time.time()
    try:
        p = subprocess.run(["gh", "api", "-X", "GET", path], capture_output=True, text=True, timeout=60)
    except Exception:
        return None
    return json.loads(p.stdout) if p.returncode == 0 and p.stdout.strip() else None

print("R84 registry and repository figures (revision 3)")
print("retrieval date (UTC): %s" % snap["retrieved"])
print("volatile figures: snapshots/registry-figures.json")
print()

# ---------------------------------------------------------------- crates.io
PINNED = {
    # name: (version the decision cites, expected rust_version, expected license, expected created_at date)
    "openapi-to-rust": ("0.17.0", "1.88.0", "MIT", "2026-09-14"),
    "progenitor": ("0.15.0", "1.88", "MPL-2.0", "2026-09-10"),
    "progenitor-client": ("0.15.0", "1.88", "MPL-2.0", "2026-09-10"),
    "cargo-progenitor": ("0.15.0", "1.88", "MPL-2.0", "2026-09-10"),
    "spargen": ("0.4.0", "1.88", "MIT OR Apache-2.0", "2026-08-29"),
    "utoipa": ("5.5.0", None, None, None),
}
SURVEY = ["openapi-to-rust", "progenitor", "progenitor-client", "cargo-progenitor", "spargen", "ploidy",
          "openapi-nexus", "oas3-gen", "openapi-gen", "paperclip", "openapi-model-generator",
          "openapi-generator-cli", "openapiv3", "oas3", "utoipa", "reqwest", "reqwest-middleware",
          "meteora-api", "lance-namespace-reqwest-client"]
probe = crates("crates/openapi-to-rust")
if probe is None:
    for n in ["F01-F12 crates.io figures"]:
        out("SKIP", n + " — crates.io API unreachable")
else:
    for name in SURVEY:
        c = crates("crates/" + name)
        v = crates("crates/%s/versions" % name)
        if c is None or v is None:
            snap["crates"][name] = {"error": "unreachable or absent"}
            continue
        live = [x for x in v["versions"] if not x["yanked"]]
        newest = live[0] if live else None
        snap["crates"][name] = {
            "endpoint": "https://crates.io/api/v1/crates/%s (+ /versions)" % name,
            "recent_downloads_90d": c["crate"]["recent_downloads"],
            "downloads_all_time": c["crate"]["downloads"],
            "newest_non_yanked": newest and {"num": newest["num"], "created_at": newest["created_at"],
                                            "rust_version": newest.get("rust_version"), "license": newest.get("license"),
                                            "edition": newest.get("edition")},
            "non_yanked_versions": len(live),
            "versions_declaring_rust_version": sum(1 for x in live if x.get("rust_version")),
            "repository": c["crate"].get("repository"),
        }
        if name in PINNED:
            num, rv, lic, day = PINNED[name]
            row = next((x for x in live if x["num"] == num), None)
            if row is None:
                out("FAIL", "F01-%s version %s is not a live (non-yanked) release" % (name, num))
                continue
            if rv is None:
                out("PASS", "F01-%s %s is a live release" % (name, num))
                continue
            check(row.get("rust_version") == rv and row.get("license") == lic and row["created_at"].startswith(day),
                  "F01-%s %s: rust_version %s, license %s, published %s" % (name, num, rv, lic, day))
    oz = snap["crates"].get("openapi-to-rust", {})
    ver = crates("crates/openapi-to-rust/versions")
    if ver:
        nums = [x for x in ver["versions"] if not x["yanked"] and x["created_at"] >= "2026-02-13" and x["created_at"] < "2026-09-15"]
        snap["notes"].append("openapi-to-rust live versions published 2026-02-13..2026-09-14: %d" % len(nums))
        check(len(nums) >= 30, "F02 openapi-to-rust published >= 30 live versions between 2026-02-13 and 2026-09-14 (a weekly cadence; count in snapshot)")
    rd = crates("crates/openapi-to-rust/reverse_dependencies")
    if rd is not None:
        snap["crates"]["openapi-to-rust"]["reverse_dependencies"] = rd["meta"]["total"]
        out("PASS", "F03 openapi-to-rust reverse dependencies read (count in snapshot: the adoption-risk figure)")
    for name in ("paperclip", "openapi-model-generator"):
        s = snap["crates"].get(name, {})
        check(s.get("versions_declaring_rust_version") == 0,
              "F04-%s no live version declares rust_version, so gate 2 cannot be satisfied" % name)
    m = snap["crates"].get("meteora-api", {})
    check(m.get("repository") == "https://github.com/ChiefWoods/meteora-ag-api",
          "F05 meteora-api (the Doxa-OpenAI 'adopter') exists, repository github.com/ChiefWoods/meteora-ag-api (downloads in snapshot)")
    status, body = http("https://static.crates.io/crates/meteora-api/meteora-api-0.1.0.crate")
    if status == 200:
        import io, tarfile
        tf = tarfile.open(fileobj=io.BytesIO(body), mode="r:gz")
        marks = sorted({m.name for m in tf.getmembers() if m.isfile() and
                        b"Generated by openapi-to-rust v0.12.2" in (tf.extractfile(m).read() or b"")})
        check(len(marks) > 0, "F06 meteora-api 0.1.0's source carries 'Generated by openapi-to-rust v0.12.2' (%d files)" % len(marks))
    else:
        out("SKIP", "F06 meteora-api 0.1.0 crate could not be fetched")

# ---------------------------------------------------------------- RustSec
st, _ = http("https://rustsec.org/packages/atty.html")
if st != 200:
    out("SKIP", "RS01-RS06 rustsec.org unreachable (control atty.html answered %s)" % st)
else:
    out("PASS", "RS01 control: rustsec.org/packages/atty.html answers 200, so a 404 means 'no advisory page'")
    for i, name in enumerate(["openapi-to-rust", "progenitor", "progenitor-client", "reqwest", "reqwest-middleware"], 2):
        st, _ = http("https://rustsec.org/packages/%s.html" % name)
        check(st == 404, "RS%02d rustsec.org has no advisory page for %s (HTTP %s against the 200 control)" % (i, name, st))

# ---------------------------------------------------------------- Maven Central
# Timeout 60, not the 25 this line carried at r1: the endpoint answers in 10-16 s
# (measured 2026-09-26), so 25 s times out under load and flips M01 to SKIP.
# Three attempts: back-to-back full-sequence runs starve single attempts past 60 s.
st, err = None, b""
for _try in range(3):
    st, err = http("https://repo1.maven.org/maven2/org/openapitools/openapi-generator-cli/maven-metadata.xml", timeout=60)
    if st == 200:
        break
    time.sleep(10)
if st == 200:
    out("PASS", "M01 Maven Central is reachable from this host (openapi-generator-cli maven-metadata.xml)")
else:
    out("SKIP", "M01 Maven Central is unreachable from this host, so OpenAPI Generator 7.25.0 could not be downloaded or executed here")

# ---------------------------------------------------------------- Cargo Book
st, body = http("https://doc.rust-lang.org/cargo/reference/build-script-examples.html")
if st == 200:
    import re
    text = re.sub(r"\s+", " ", re.sub(r"<[^>]+>", " ", body.decode("utf-8", "replace")))
    # Inline <code> tags leave a space before punctuation once stripped, so the
    # sentence is matched in three fragments rather than whole.
    check("Sometimes, projects want to check in a generated file, and treat it as source code." in text
          and "the file shouldn’t be generated from" in text
          and "run that test as part of your CI" in text,
          "CB01 the Cargo Book: a checked-in generated file is not produced by build.rs and a CI test compares it with a fresh generation")
else:
    out("SKIP", "CB01 doc.rust-lang.org unreachable")

# ---------------------------------------------------------------- GitHub
if shutil.which("gh") is None or gh("rate_limit") is None:
    out("SKIP", "G01-G09 gh is absent or unauthenticated, so api.github.com figures were not collected")
else:
    REPOS = ["gpu-cli/openapi-to-rust", "oxidecomputer/progenitor", "OpenAPITools/openapi-generator", "getkono/spargen"]
    for i, repo in enumerate(REPOS, 1):
        r = gh("repos/" + repo)
        q = gh("search/issues?q=repo:%s+is:issue+is:open&per_page=1" % repo)
        if r is None:
            out("SKIP", "G%02d %s unreadable" % (i, repo))
            continue
        snap["github"][repo] = {"endpoint": "https://api.github.com/repos/" + repo, "stargazers_count": r["stargazers_count"],
                                "archived": r["archived"], "pushed_at": r["pushed_at"],
                                "open_issues_total_count": q and q["total_count"]}
        check(r["archived"] is False, "G%02d %s is not archived (stars, pushed_at, open issues in snapshot)" % (i, repo))
    for num in (762, 1268):
        iss = gh("repos/oxidecomputer/progenitor/issues/%d" % num)
        if iss:
            snap["github"]["progenitor#%d" % num] = {"title": iss["title"], "state": iss["state"], "created_at": iss["created_at"]}
            check(iss["state"] == "open" and "3.1" in iss["title"],
                  "G05-%d progenitor issue #%d is open and concerns OpenAPI 3.1 ('%s')" % (num, num, iss["title"]))
        else:
            out("SKIP", "G05-%d progenitor issue #%d unreadable" % (num, num))
    recent = gh("search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue&sort=created&order=desc&per_page=10")
    if recent:
        rows = []
        for it in recent["items"]:
            comments = gh("repos/gpu-cli/openapi-to-rust/issues/%d/comments?per_page=20" % it["number"]) or []
            first = next((c for c in comments if c["user"]["login"] != it["user"]["login"]
                          and c.get("author_association") in ("OWNER", "MEMBER", "COLLABORATOR")), None)
            opened = datetime.datetime.fromisoformat(it["created_at"].replace("Z", "+00:00"))
            def days(ts):
                return round((datetime.datetime.fromisoformat(ts.replace("Z", "+00:00")) - opened).total_seconds() / 86400, 2)
            rows.append({"number": it["number"], "created_at": it["created_at"], "author": it["user"]["login"],
                         "author_association": it.get("author_association"), "state": it["state"],
                         "closed_after_days": days(it["closed_at"]) if it.get("closed_at") else None,
                         "first_maintainer_comment_after_days": days(first["created_at"]) if first else None})
        answered = [r["first_maintainer_comment_after_days"] for r in rows if r["first_maintainer_comment_after_days"] is not None]
        closed = [r["closed_after_days"] for r in rows if r["closed_after_days"] is not None]
        snap["github"]["openapi-to-rust recent issues"] = {
            "endpoint": "https://api.github.com/search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue&sort=created&order=desc&per_page=10 (+ /issues/<n>/comments)",
            "issues": rows, "median_days_to_first_maintainer_comment": statistics.median(answered) if answered else None,
            "no_maintainer_comment": len(rows) - len(answered),
            "closed": len(closed), "median_days_to_close": statistics.median(closed) if closed else None}
        out("PASS", "G06 the 10 most recently opened openapi-to-rust issues and their first maintainer comments were read (medians in snapshot)")
    else:
        out("SKIP", "G06 openapi-to-rust recent issues unreadable")
    t = gh("search/issues?q=repo:gpu-cli/openapi-to-rust+timeout+in:title,body&per_page=5")
    if t is not None:
        snap["github"]["openapi-to-rust issues mentioning timeout"] = {"total_count": t["total_count"],
            "titles": [(i["number"], i["title"], i["state"]) for i in t["items"]]}
        out("PASS", "G07 openapi-to-rust's tracker searched for 'timeout' (hits in snapshot: whether the inert timeout_seconds key is reported upstream)")
    rel = gh("repos/rust-lang/rust/releases/latest")
    if rel:
        snap["notes"].append("rust-lang/rust latest release tag: %s (%s)" % (rel["tag_name"], rel["published_at"]))
        out("PASS", "G08 the current stable Rust release was read from rust-lang/rust (tag in snapshot; msrv floor = stable minus 2)")
    ci = gh("repos/gpu-cli/openapi-to-rust/contents/.github/workflows/ci.yml?ref=a968c13de9c1171bbee54f803e72cc914e06b04b")
    if ci:
        import base64
        yml = base64.b64decode(ci["content"]).decode()
        runs_on = sorted({l.split("runs-on:")[1].strip() for l in yml.splitlines() if "runs-on:" in l})
        pinned = [l.strip() for l in yml.splitlines() if l.strip().startswith("toolchain:")]
        print("      ci.yml at a968c13d: runs-on %s; explicit toolchain lines %s" % (runs_on, pinned))
        check(runs_on == ["ubuntu-latest"], "G09 openapi-to-rust 0.17.0's CI (ci.yml at its release commit a968c13d) runs on ubuntu-latest only — no macOS job")
        check("toolchain: 1.88.0" in pinned, "G10 that CI has an MSRV job pinned to toolchain 1.88.0, matching the manifest's rust-version")
    else:
        out("SKIP", "G09-G10 ci.yml at a968c13d unreadable")

json.dump(snap, open(os.environ["R84_SNAPSHOT"], "w"), indent=1, sort_keys=True)
print()
print("PASS=%d FAIL=%d SKIP=%d TOTAL=%d" % (counts["PASS"], counts["FAIL"], counts["SKIP"], sum(counts.values())))
sys.exit(counts["FAIL"])
PY
