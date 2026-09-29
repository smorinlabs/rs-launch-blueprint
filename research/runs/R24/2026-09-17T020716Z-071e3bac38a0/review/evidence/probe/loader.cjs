// R24 changelog-section-mapping — config-loader probe (revision 2).
//
// render.cjs hands a changelogSections array straight to buildNotes. This
// program instead takes the path a real repository takes: a
// release-please-config.json is read by release-please's own
// Manifest.fromManifest -> parseConfig -> extractReleaserConfig ->
// mergeReleaserConfig, the strategy is built by Manifest.getStrategiesByPath,
// and the release notes come from that strategy's own buildReleaseNotes. It
// answers one question: does a per-entry `scope` key, which the published
// schema does not document, survive that loader and reach the renderer?
//
// The GitHub client is an in-memory stub that serves exactly two files, the
// config and the versions manifest; no network call is made. The emptiness
// predicate applied to the result is release-please's own
// BaseStrategy.prototype.changelogEmpty, as in render.cjs.
//
// Usage: node loader.cjs <path-to-node_modules-root> <output-directory>
// Writes loader.txt and G-scope-routed-hidden-only.md. It implements nothing
// the decision recommends: no template, no repository and no
// release-please-config.json file is created anywhere.

'use strict';

const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const outDir = process.argv[3];
if (!root || !outDir) {
  console.error('usage: node loader.cjs <install-root> <out-dir>');
  process.exit(2);
}

const rp = (rel) => path.join(root, 'node_modules', 'release-please', 'build', 'src', rel);
// Same require-cycle workaround as render.cjs: load the index first.
const index = require(path.join(root, 'node_modules', 'release-please', 'build', 'src', 'index.js'));
const {Manifest} = require(rp('manifest.js'));
const {FileNotFoundError} = require(rp('errors/index.js'));
const {parseConventionalCommits} = require(rp('commit.js'));
const {BaseStrategy} = require(rp('strategies/base.js'));
const {Version} = require(rp('version.js'));
const {TagName} = require(rp('util/tag-name.js'));

// Keep release-please's progress lines off every output.
const silent = {error() {}, warn() {}, info() {}, debug() {}, trace() {}};
index.setLogger(silent);

// The mechanism-5 push from render.cjs, unchanged.
const HIDDEN_ONLY = [
  'test: add an integration test for the port',
  'ci: run the matrix on macos-latest',
  'chore(deps): bump serde from 1.0.230 to 1.0.231',
];

// The recommendation this decision records (same as render.cjs RECOMMENDED).
const RECOMMENDED = [
  {type: 'feat', section: 'Features'},
  {type: 'fix', section: 'Bug Fixes'},
  {type: 'perf', section: 'Performance Improvements'},
  {type: 'revert', section: 'Reverts'},
  {type: 'docs', section: 'Documentation'},
  {type: 'refactor', section: 'Code Refactoring', hidden: true},
  {type: 'test', section: 'Tests', hidden: true},
  {type: 'build', section: 'Build System', hidden: true},
  {type: 'ci', section: 'Continuous Integration', hidden: true},
  {type: 'style', section: 'Styles', hidden: true},
  {type: 'chore', section: 'Miscellaneous Chores', hidden: true},
];

// The alternative the revision-2 audit named: one scope-routed entry, placed
// before the bare `chore` entry because the preset's lookup is first-match.
const SCOPE_ROUTED = RECOMMENDED.slice(0, 5).concat(
  [{type: 'chore', scope: 'deps', section: 'Dependencies'}],
  RECOMMENDED.slice(5),
);

function stubGithub(config) {
  const files = {
    'release-please-config.json': config,
    '.release-please-manifest.json': {'.': '0.1.0'},
  };
  return {
    repository: {owner: 'smorinlabs', repo: 'rs-launch-blueprint', defaultBranch: 'main'},
    async getFileJson(file) {
      if (Object.prototype.hasOwnProperty.call(files, file)) {
        return JSON.parse(JSON.stringify(files[file]));
      }
      throw new FileNotFoundError(file);
    },
    async getFileContentsOnBranch(file) {
      throw new FileNotFoundError(file);
    },
  };
}

// The three keys R25 fixes, plus the array under test, in the "." package.
function config(sections) {
  return {
    packages: {
      '.': {
        'release-type': 'rust',
        'bump-minor-pre-major': true,
        'bump-patch-for-minor-pre-major': true,
        'changelog-sections': sections,
      },
    },
  };
}

function commits(messages) {
  return messages.map((message, index) => ({
    sha: String(index + 1).repeat(40).slice(0, 40),
    message,
    files: ['src/lib.rs'],
  }));
}

// Same normalisation as render.cjs, for the same reason.
function normaliseDate(body) {
  return body.replace(/^(## 0\.2\.0 )\(\d{4}-\d{2}-\d{2}\)$/m, '$1(<release-date>)');
}

async function loadAndRender(sections) {
  const manifest = await Manifest.fromManifest(stubGithub(config(sections)), 'main');
  const loaded = manifest.repositoryConfig['.'].changelogSections;
  const strategy = (await manifest.getStrategiesByPath())['.'];
  const version = Version.parse('0.2.0');
  const tag = new TagName(version, undefined, '-', true);
  const body = normaliseDate(await strategy.buildReleaseNotes(
    parseConventionalCommits(commits(HIDDEN_ONLY)), version, tag, undefined, commits(HIDDEN_ONLY)));
  return {loaded, strategySections: strategy.changelogSections, body};
}

async function main() {
  fs.mkdirSync(outDir, {recursive: true});
  const empty = BaseStrategy.prototype.changelogEmpty;
  const lines = [];
  for (const [name, sections] of [['recommended', RECOMMENDED], ['scope-routed', SCOPE_ROUTED]]) {
    const {loaded, strategySections, body} = await loadAndRender(sections);
    lines.push(
      `${name} loaded entries: ${loaded.length}`,
      `${name} loaded scoped entry: ${JSON.stringify(loaded.find((e) => e.scope) || null)}`,
      `${name} strategy entries: ${strategySections.length}`,
      `${name} strategy scoped entry: ${JSON.stringify(strategySections.find((e) => e.scope) || null)}`,
      `${name} hidden-only lines: ${body.split('\n').length}`,
      `${name} hidden-only changelogEmpty: ${empty.call(null, body)}`,
    );
    if (name === 'scope-routed') {
      fs.writeFileSync(path.join(outDir, 'G-scope-routed-hidden-only.md'), body, 'utf8');
    }
  }
  lines.push('');
  fs.writeFileSync(path.join(outDir, 'loader.txt'), lines.join('\n'), 'utf8');
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
});
