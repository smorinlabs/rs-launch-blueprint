// Hermetic stand-in for the one GitHub REST endpoint `contributors-please init`
// calls during discovery: GET {apiUrl}/repos/{owner}/{repo}/contributors?per_page=100
// (src/engine/github.ts listContributors -> requestJsonPages). For a non-github.com
// server URL the CLI derives apiUrl = `${server}/api/v3` (GitHubClient.deriveUrls).
// Control routes (never called by the CLI): GET /__requests, POST /__reset,
// POST /__fail/<status>, POST /__ok.
import { createServer } from "node:http";

const port = Number(process.env.FAKE_GITHUB_PORT ?? "47470");
const base = `http://127.0.0.1:${port}`;
let failStatus = 0;
const log = [];

const server = createServer((req, res) => {
  const url = new URL(req.url, base);
  const send = (status, body) => {
    res.writeHead(status, { "content-type": "application/json" });
    res.end(JSON.stringify(body));
  };
  if (url.pathname === "/__requests") return send(200, { count: log.length, log });
  if (url.pathname === "/__reset") { log.length = 0; failStatus = 0; return send(200, { ok: true }); }
  if (url.pathname.startsWith("/__fail/")) { failStatus = Number(url.pathname.slice(8)); return send(200, { failStatus }); }
  if (url.pathname === "/__ok") { failStatus = 0; return send(200, { ok: true }); }

  log.push(`${req.method} ${url.pathname}${url.search}`);
  if (failStatus) return send(failStatus, { message: `fake failure ${failStatus}` });
  const m = url.pathname.match(/^\/api\/v3\/repos\/([^/]+)\/([^/]+)\/contributors$/);
  if (req.method === "GET" && m) {
    return send(200, [
      { login: "alice", contributions: 2, avatar_url: `${base}/avatars/alice.png`, html_url: `${base}/alice` },
      { login: "dependabot[bot]", contributions: 5, avatar_url: `${base}/avatars/dependabot.png`, html_url: `${base}/apps/dependabot` },
    ]);
  }
  return send(404, { message: "Not Found" });
});

server.listen(port, "127.0.0.1", () => {
  console.log(`fake-github listening on ${base}`);
});
