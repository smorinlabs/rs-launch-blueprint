// Comparison-only config: the same convention (11 types, 50/72/72) written as
// explicit commitlint rules, plus the two config-conventional rules that
// matter for the comparison (subject-case, subject-full-stop). No `extends`,
// so it loads without node_modules.
const types = ['build', 'chore', 'ci', 'docs', 'feat', 'fix', 'perf', 'refactor', 'revert', 'style', 'test'];
export default {
  rules: {
    'type-enum': [2, 'always', types],
    'type-empty': [2, 'never'],
    'subject-empty': [2, 'never'],
    'header-max-length': [2, 'always', 50],
    'body-max-line-length': [2, 'always', 72],
    'footer-max-line-length': [2, 'always', 72],
    'subject-case': [2, 'never', ['sentence-case', 'start-case', 'pascal-case', 'upper-case']],
    'subject-full-stop': [2, 'never', '.'],
  },
};
