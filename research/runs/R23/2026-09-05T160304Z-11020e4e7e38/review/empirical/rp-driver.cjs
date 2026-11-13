#!/usr/bin/env node
// R23 empirical driver: executes the installed release-please classes (the
// version release-please-action v5.0.0 resolves from "release-please": "^17.6.0")
// against local fixture files. GitHub access is replaced by a filesystem stub
// that implements the only two methods the Rust strategy and the
// cargo-workspace plugin call: getFileContentsOnBranch and findFilesByGlobAndRef.
'use strict';
const fs = require('fs');
const path = require('path');

const RP = path.join(__dirname, 'node_modules', 'release-please', 'build', 'src');
const rpVersion = require(path.join(__dirname, 'node_modules', 'release-please', 'package.json')).version;
// Load the package entry point first: requiring strategies/rust.js directly
// enters the module graph mid-cycle (base.js -> factory.js -> bazel.js -> base.js)
// and BaseStrategy is still undefined at that point.
require(path.join(RP, 'index.js'));
const { CargoLock } = require(path.join(RP, 'updaters', 'rust', 'cargo-lock.js'));
const { CargoToml } = require(path.join(RP, 'updaters', 'rust', 'cargo-toml.js'));
const { GenericToml } = require(path.join(RP, 'updaters', 'generic-toml.js'));
const { Rust } = require(path.join(RP, 'strategies', 'rust.js'));
const { CargoWorkspace } = require(path.join(RP, 'plugins', 'cargo-workspace.js'));
const { Version } = require(path.join(RP, 'version.js'));

function fileContents(root, rel) {
  const abs = path.join(root, rel);
  if (!fs.existsSync(abs)) {
    const e = new Error(`not found: ${rel}`);
    e.name = 'FileNotFoundError';
    throw e;
  }
  const text = fs.readFileSync(abs, 'utf8');
  return { sha: '', mode: '100644', content: Buffer.from(text).toString('base64'), parsedContent: text };
}

function stubGithub(root) {
  return {
    repository: { owner: 'example', repo: 'fixture', defaultBranch: 'main' },
    async getFileContentsOnBranch(rel, _branch) { return fileContents(root, rel); },
    async findFilesByGlobAndRef(glob, _ref) {
      return fs.globSync(glob, { cwd: root })
        .filter((p) => fs.statSync(path.join(root, p)).isDirectory())
        .sort();
    },
  };
}

function parseVersions(pairs) {
  const m = new Map();
  for (const pair of pairs) {
    const [name, v] = pair.split('=');
    m.set(name, Version.parse(v));
  }
  return m;
}

function applyToFile(file, label, fn) {
  const before = fs.readFileSync(file, 'utf8');
  const after = fn(before);
  fs.writeFileSync(file, after);
  console.log(`${label}: ${file} ${before === after ? 'unchanged' : 'updated'}`);
}

const [cmd, ...args] = process.argv.slice(2);

(async () => {
  console.log(`release-please ${rpVersion} (node ${process.version})`);
  switch (cmd) {
    case 'cargo-lock': { // cargo-lock <Cargo.lock> name=version ...
      const [file, ...pairs] = args;
      applyToFile(file, 'CargoLock', (before) => new CargoLock(parseVersions(pairs)).updateContent(before));
      break;
    }
    case 'cargo-toml': { // cargo-toml <Cargo.toml> <newVersion> name=version ...
      const [file, version, ...pairs] = args;
      applyToFile(file, 'CargoToml', (before) =>
        new CargoToml({ version: Version.parse(version), versionsMap: parseVersions(pairs) }).updateContent(before));
      break;
    }
    case 'generic-toml': { // generic-toml <file> <jsonpath> <newVersion>
      const [file, jsonpath, version] = args;
      applyToFile(file, 'GenericToml', (before) => new GenericToml(jsonpath, Version.parse(version)).updateContent(before));
      break;
    }
    case 'bump-rp-manifest': { // bump-rp-manifest <.release-please-manifest.json> <key> <newVersion>
      const [file, key, version] = args;
      applyToFile(file, 'ReleasePleaseManifest', (before) => {
        const j = JSON.parse(before);
        j[key] = version;
        return JSON.stringify(j, null, 2) + '\n';
      });
      break;
    }
    case 'rust-strategy': { // rust-strategy <root> <strategy-path> <oldVersion> <newVersion>
      const [root, spath, oldV, newV] = args;
      const strategy = new Rust({
        github: stubGithub(root),
        targetBranch: 'main',
        path: spath,
        skipChangelog: true,
      });
      const updates = await strategy.buildUpdates({
        newVersion: Version.parse(newV),
        latestVersion: Version.parse(oldV),
        changelogEntry: '',
        commits: [],
      });
      console.log(`Rust.buildUpdates scheduled ${updates.length} update(s): ${updates.map((u) => u.path).join(', ')}`);
      let threw = 0;
      for (const u of updates) {
        const abs = path.join(root, u.path);
        if (!fs.existsSync(abs) && !u.createIfMissing) {
          console.log(`  ${u.path}: did not exist and createIfMissing=false -> skipped (as github.js buildChangeSet does)`);
          continue;
        }
        const before = fs.existsSync(abs) ? fs.readFileSync(abs, 'utf8') : undefined;
        try {
          const after = u.updater.updateContent(before);
          fs.writeFileSync(abs, after);
          console.log(`  ${u.path}: ${before === after ? 'unchanged' : 'updated'} by ${u.updater.constructor.name}`);
        } catch (e) {
          threw += 1;
          console.log(`  ${u.path}: ${u.updater.constructor.name} THREW ${e.name}: ${e.message}`);
        }
      }
      if (threw > 0) {
        console.log(`${threw} updater(s) threw; github.js buildChangeSet has no try/catch around updateContent, so a real run aborts here`);
        process.exit(3);
      }
      break;
    }
    case 'cargo-workspace-plugin': { // cargo-workspace-plugin <root>
      const [root] = args;
      const plugin = new CargoWorkspace(stubGithub(root), 'main', {});
      const r = await plugin.buildAllPackages([]);
      console.log(`CargoWorkspace.buildAllPackages: ${r.allPackages.length} package(s)`);
      for (const p of r.allPackages) console.log(`  ${p.path}  ${p.name}  ${p.version}`);
      break;
    }
    default:
      throw new Error(`unknown command: ${cmd}`);
  }
})().catch((e) => {
  console.log(`ERROR ${e.name || 'Error'}: ${e.message}`);
  process.exit(2);
});
