# Sources: skill-auditor

Provenance for the rules in `skills/skill-auditor/` (references/dimensions.md). Kept outside the skill folder so it never loads into context.

- Skill authoring best practices (at least three evaluation scenarios per skill): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Agent Skills specification: https://agentskills.io/specification
- Claude Code skills (frontmatter, substitutions, listing budget, compaction): https://code.claude.com/docs/en/skills
- Claude Code subagents (subagents don't get `AskUserQuestion`): https://code.claude.com/docs/en/sub-agents
- Claude Code best practices (`disable-model-invocation` for side effects, emphasis, CLAUDE.md vs skills): https://code.claude.com/docs/en/best-practices
- Prompting best practices (tell Claude what to do instead of what not to do for output formatting; aggressive trigger language overtriggers on Claude Opus 4.5 and later): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- skill-creator (ALL-CAPS ALWAYS/NEVER is a yellow flag, explain why over MUSTs, "pushy" descriptions, description optimization): https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
- Lessons from building Claude Code: How we use skills (gotchas, description is for triggering): https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/
- Chroma, *Context Rot* (2025): https://www.trychroma.com/research/context-rot
- Multi-line description made skill undiscoverable: https://github.com/anthropics/claude-code/issues/9817 and https://github.com/anthropics/claude-code/issues/12971
- Claude Code plugin evals (`claude plugin eval` case format): https://code.claude.com/docs/en/plugin-evals
- Public validators: skills-ref (https://github.com/agentskills/agentskills/tree/main/skills-ref), skill-validator (https://github.com/agent-ecosystem/skill-validator)

## Specifics removed from the skill (as of 2026-09-27)

- SKILL.md description named the neighbours: "For creating or rewriting a skill use skill-creator; for skill usage and context cost use /skill-doctor."
- `claude plugin validate <plugin-dir> --json` checks the manifest and whether each skill has frontmatter. It lists only files with issues, so an empty `contents` is normal for a clean plugin. A skill with no frontmatter is only a warning (`success: true`, exit 0). It doesn't report wrapped descriptions, lengths, or unknown keys.
- Public spec validators: `skills-ref validate <skill-dir>` (the Agent Skills reference) and `skill-validator check <skill-dir>` (spec plus broken links, token counts, content metrics).
- Eval runners: `claude plugin eval` and skill-creator's eval loop; eval sets live in a plugin `evals/` directory for `claude plugin eval`, or a skill-creator eval file.
- Description optimizer: skill-creator's description optimization. skill-creator also suggests "pushy" descriptions; Anthropic guidance says aggressive trigger language overtriggers on Claude Opus 4.5 and later.
- Usage report: `/skill-doctor` (listing cost, usage, never-invoked skills).
- Step 2 ran `claude plugin validate` "if the `claude` CLI is available"; the report header read `Schema check: <claude plugin validate: ...>`.
- Multi-line descriptions made skills undiscoverable: anthropics/claude-code#9817 and #12971 (https://github.com/anthropics/claude-code/issues/9817).
- Listing truncation: `description` + `when_to_use` truncated at 1,536 characters.
- Reserved names: `synced`, `anthropic-skills…`.
- Known frontmatter keys: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `license`, `compatibility`, `metadata`.
- Portability limits (the Agent Skills spec, claude.ai, and the API enforce them): `name` 1–64 characters and must not contain `anthropic` or `claude`; `description` at most 1,024 characters; spec fields are `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
- `disable-model-invocation: true` also removes the skill from scheduled tasks and from Claude's listing.
- Length: `SKILL.md` body under 500 lines; the open spec suggests under ~5,000 tokens.
- Compaction caps for re-attached skills: 5,000 tokens each, 25,000 total.
- Subagents don't get the `AskUserQuestion` tool.
- Dynamic context (`` !`cmd` ``) commands time out after 2 minutes; `shell: bash` is the default and fails on Windows without Git Bash.
- Distractor finding cited Chroma, *Context Rot*, 2025.
- Former "Citable in findings" links: https://agentskills.io/specification, https://github.com/anthropics/claude-code/issues/9817, https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- Report-template example finding cited `(claude-code#9817)`.
