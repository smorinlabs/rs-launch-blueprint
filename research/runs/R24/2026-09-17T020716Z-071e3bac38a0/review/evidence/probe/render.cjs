// R24 changelog-section-mapping — rendering probe.
//
// This program RENDERS NOTHING OF ITS OWN. It calls release-please's own
// compiled code, installed from npm at the exact version 17.11.2:
//
//   build/src/commit.js            -> parseConventionalCommits()
//   build/src/changelog-notes/default.js -> DefaultChangelogNotes.buildNotes()
//   build/src/strategies/base.js   -> BaseStrategy.prototype.changelogEmpty()
//
// It is not a replica of those ~40 lines; it is those lines, reached through
// release-please's own entry points, so the breaking-change note text is the
// one release-please itself computes rather than a fixture constant.
//
// Usage: node render.cjs <path-to-node_modules-root> <output-directory>
// Writes one Markdown file per rendered case plus mech5.txt.
// It implements nothing the decision recommends: no template, no repository,
// no release-please-config.json is created anywhere.

'use strict';

const fs = require('fs');
const path = require('path');

const root = process.argv[2];
const outDir = process.argv[3];
if (!root || !outDir) {
  console.error('usage: node render.cjs <install-root> <out-dir>');
  process.exit(2);
}

const rp = (rel) => path.join(root, 'node_modules', 'release-please', 'build', 'src', rel);
// release-please's strategy modules form a require cycle through factory.js,
// so the package index is loaded first and the deep modules are read from the
// warm cache afterwards. Loading strategies/base.js cold throws
// "Class extends value undefined".
require(path.join(root, 'node_modules', 'release-please', 'build', 'src', 'index.js'));
const {parseConventionalCommits} = require(rp('commit.js'));
const {DefaultChangelogNotes} = require(rp('changelog-notes/default.js'));
const {BaseStrategy} = require(rp('strategies/base.js'));

// One commit per type in commit-message-convention's eleven-member enum,
// plus the Dependabot bump shape R19 fixes (chore(deps)), plus two breaking
// commits of otherwise-hidden types. Fixed shas so the output is stable.
const MESSAGES = [
  'feat: add the projects list command',
  'fix: correct the exit code for a missing project',
  'perf: read the config in one syscall',
  'revert: undo the projects list command',
  'docs: correct the rustdoc example on ProjectsPort',
  'refactor: split the composition root',
  'test: add an integration test for the port',
  'build: pin the workspace resolver to 3',
  'ci: run the matrix on macos-latest',
  'style: reflow the imports',
  'chore: tidy the justfile',
  'chore(deps): bump serde from 1.0.230 to 1.0.231',
  'style!: rename the public Error variants',
  'chore!: drop the deprecated no-color flag',
];

// Commits whose types are all hidden under the recommended array: the
// mechanism-5 input. The second list adds one visible-type commit.
const HIDDEN_ONLY = [
  'test: add an integration test for the port',
  'ci: run the matrix on macos-latest',
  'chore(deps): bump serde from 1.0.230 to 1.0.231',
];
const HIDDEN_PLUS_ONE_VISIBLE = HIDDEN_ONLY.concat([
  'fix: correct the exit code for a missing project',
]);

function commits(messages) {
  return messages.map((message, index) => ({
    sha: String(index + 1).repeat(40).slice(0, 40),
    message,
    files: ['src/lib.rs'],
  }));
}

// py-launch-blueprint release-please-config.json at pin b08bccfb, lines 23-34.
const PY = [
  {type: 'feat', section: 'Features'},
  {type: 'fix', section: 'Bug Fixes'},
  {type: 'perf', section: 'Performance Improvements'},
  {type: 'refactor', section: 'Refactor'},
  {type: 'revert', section: 'Reverts'},
  {type: 'deps', section: 'Dependencies'},
  {type: 'chore', section: 'Miscellaneous', hidden: true},
  {type: 'docs', section: 'Documentation', hidden: true},
  {type: 'style', section: 'Styles', hidden: true},
  {type: 'test', section: 'Tests', hidden: true},
  {type: 'ci', section: 'CI', hidden: true},
  {type: 'build', section: 'Build System', hidden: true},
];

// ts-launch-blueprint release-please-config.json at pin cb1cbcb2, lines 12-18.
const TS = [
  {type: 'feat', section: 'Features'},
  {type: 'fix', section: 'Bug Fixes'},
  {type: 'perf', section: 'Performance Improvements'},
  {type: 'docs', section: 'Documentation'},
  {type: 'test', section: 'Tests'},
  {type: 'refactor', section: 'Code Refactoring'},
  {type: 'chore', section: 'Miscellaneous', hidden: true},
];

// The recommendation this decision records.
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

// conventional-changelog-writer stamps the header with the machine's current
// date, which release-please's buildNotes does not let a caller set. The date
// carries nothing this decision turns on, so it is normalised out of the saved
// bodies; nothing else in the output is touched, and the substitution is
// anchored to the release-header line so it cannot silently rewrite a bullet.
function normaliseDate(body) {
  return body.replace(/^(## 0\.2\.0 )\(\d{4}-\d{2}-\d{2}\)$/m, '$1(<release-date>)');
}

async function render(messages, changelogSections) {
  const notes = new DefaultChangelogNotes({});
  const parsed = parseConventionalCommits(commits(messages));
  const options = {
    owner: 'smorinlabs',
    repository: 'rs-launch-blueprint',
    version: '0.2.0',
    currentTag: 'v0.2.0',
    targetBranch: 'main',
  };
  if (changelogSections) {
    options.changelogSections = changelogSections;
  }
  return normaliseDate(await notes.buildNotes(parsed, options));
}

async function main() {
  fs.mkdirSync(outDir, {recursive: true});
  const cases = [
    ['A-preset-default', MESSAGES, undefined],
    ['B-py', MESSAGES, PY],
    ['C-ts', MESSAGES, TS],
    ['D-recommended', MESSAGES, RECOMMENDED],
  ];
  for (const [name, messages, sections] of cases) {
    const body = await render(messages, sections);
    fs.writeFileSync(path.join(outDir, name + '.md'), body, 'utf8');
  }

  // Mechanism 5: release-please's own emptiness predicate, taken off
  // BaseStrategy.prototype, applied to bodies rendered by the path above.
  const empty = BaseStrategy.prototype.changelogEmpty;
  const hiddenOnly = await render(HIDDEN_ONLY, RECOMMENDED);
  const plusVisible = await render(HIDDEN_PLUS_ONE_VISIBLE, RECOMMENDED);
  const lines = [
    'changelogEmpty source: ' + empty.toString().replace(/\s+/g, ' ').trim(),
    'hidden-only lines: ' + hiddenOnly.split('\n').length,
    'hidden-only changelogEmpty: ' + empty.call(null, hiddenOnly),
    'hidden-plus-one-visible lines: ' + plusVisible.split('\n').length,
    'hidden-plus-one-visible changelogEmpty: ' + empty.call(null, plusVisible),
    '',
  ];
  fs.writeFileSync(path.join(outDir, 'mech5.txt'), lines.join('\n'), 'utf8');
  fs.writeFileSync(path.join(outDir, 'E-hidden-only.md'), hiddenOnly, 'utf8');
  fs.writeFileSync(path.join(outDir, 'F-hidden-plus-visible.md'), plusVisible, 'utf8');
}

main().catch((error) => {
  console.error(error && error.stack ? error.stack : String(error));
  process.exit(1);
});
