Local companion/tool availability (read-only)

Codex companion:
  /Users/stevemorin/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs
  Usage supports task --background/--model/--effort, status [job-id] [--all]
  [--json], result [job-id] [--json], and cancel [job-id] [--json].
  The source defines MODEL_ALIASES only for spark -> gpt-5.3-codex-spark;
  arbitrary model strings pass through. It does not define aliases for the
  host-advertised gpt-5.6-terra or gpt-5.6-luna names.

Superpowers writing-plans:
  Codex cache: /Users/stevemorin/.codex/plugins/cache/openai-curated/superpowers/11c74d6b/skills/writing-plans/SKILL.md
  Claude cache: /Users/stevemorin/.claude/plugins/cache/claude-plugins-official/superpowers/6.2.0/skills/writing-plans/SKILL.md
  Both files exist and are readable. No writing-plans workflow was run by this
  readiness inspection.

Runtime host note:
  The execution host advertises gpt-6-astra, gpt-5.6-terra,
  gpt-5.6-luna and four total concurrent agents (including root). The current
  bounded inspection completed successfully as a Luna runtime probe; this is
  evidence about the agent runtime only, not a Doxa provider/model-access test.
