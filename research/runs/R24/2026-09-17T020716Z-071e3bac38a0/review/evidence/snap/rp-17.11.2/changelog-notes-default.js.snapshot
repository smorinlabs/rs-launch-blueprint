"use strict";
// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
Object.defineProperty(exports, "__esModule", { value: true });
exports.DefaultChangelogNotes = void 0;
// eslint-disable-next-line @typescript-eslint/no-var-requires
const conventionalChangelogWriter = require('conventional-changelog-writer');
// eslint-disable-next-line @typescript-eslint/no-var-requires
const presetFactory = require('conventional-changelog-conventionalcommits');
const DEFAULT_HOST = 'https://github.com';
class DefaultChangelogNotes {
    constructor(options = {}) {
        this.commitPartial = options.commitPartial;
        this.headerPartial = options.headerPartial;
        this.mainTemplate = options.mainTemplate;
    }
    async buildNotes(commits, options) {
        var _a;
        const context = {
            host: options.host || DEFAULT_HOST,
            owner: options.owner,
            repository: options.repository,
            version: options.version,
            previousTag: options.previousTag,
            currentTag: options.currentTag,
            linkCompare: !!options.previousTag,
        };
        const config = {};
        if (options.changelogSections) {
            config.types = options.changelogSections;
        }
        const preset = await presetFactory(config);
        // Replace the default ", closes" keyword with ", refs" to prevent GitHub from
        // automatically closing referenced issues when the release PR is merged.
        preset.writerOpts.commitPartial =
            this.commitPartial ||
                ((_a = preset.writerOpts.commitPartial) === null || _a === void 0 ? void 0 : _a.replace(/,\s*closes/g, ', refs'));
        preset.writerOpts.headerPartial =
            this.headerPartial || preset.writerOpts.headerPartial;
        preset.writerOpts.mainTemplate =
            this.mainTemplate || preset.writerOpts.mainTemplate;
        const changelogCommits = commits.map(commit => {
            const notes = commit.notes
                .filter(note => note.title === 'BREAKING CHANGE')
                .map(note => replaceIssueLink(note, context.host, context.owner, context.repository));
            let subject = htmlEscape(commit.bareMessage);
            // Append author info if enabled and author is available
            if (options.includeCommitAuthors && commit.author) {
                const authorDisplay = commit.author.username
                    ? `@${commit.author.username}`
                    : commit.author.name;
                subject = `${subject} (${authorDisplay})`;
            }
            return {
                body: '',
                subject,
                type: commit.type,
                scope: commit.scope,
                notes,
                references: commit.references,
                mentions: [],
                merge: null,
                revert: null,
                header: commit.message,
                footer: commit.notes
                    .filter(note => note.title === 'RELEASE AS')
                    .map(note => `Release-As: ${note.text}`)
                    .join('\n'),
                hash: commit.sha,
            };
        });
        return conventionalChangelogWriter
            .parseArray(changelogCommits, context, preset.writerOpts)
            .trim();
    }
}
exports.DefaultChangelogNotes = DefaultChangelogNotes;
function replaceIssueLink(note, host, owner, repo) {
    note.text = note.text.replace(/\(#(\d+)\)/, `([#$1](${host}/${owner}/${repo}/issues/$1))`);
    return note;
}
function htmlEscape(message) {
    return message.replace(/``[^`].*[^`]``|`[^`]*`|<|>/g, match => match.length > 1 ? match : match === '<' ? '&lt;' : '&gt;');
}
//# sourceMappingURL=default.js.map