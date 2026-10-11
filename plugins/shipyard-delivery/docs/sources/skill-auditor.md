# Sources: skill-auditor

Provenance for the rules in `skills/skill-auditor/` (references/dimensions.md). Kept outside the skill folder so it never loads into context.

- Skill authoring best practices (at least three evaluation scenarios per skill): https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Agent Skills specification: https://agentskills.io/specification
- Claude Code skills (frontmatter, substitutions, listing budget, compaction, a `disable-model-invocation` skill's description left out of the model's context): https://code.claude.com/docs/en/skills
- Claude Code subagents (subagents don't get `AskUserQuestion`): https://code.claude.com/docs/en/sub-agents
- Claude Code best practices (`disable-model-invocation` for side effects, emphasis, CLAUDE.md vs skills): https://code.claude.com/docs/en/best-practices
- Prompting best practices (tell Claude what to do instead of what not to do for output formatting; aggressive trigger language overtriggers on Claude Opus 4.5 and later): https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- skill-creator (ALL-CAPS ALWAYS/NEVER is a yellow flag, explain why over MUSTs, "pushy" descriptions, description optimization): https://github.com/anthropics/skills/blob/main/skills/skill-creator/SKILL.md
- Lessons from building Claude Code: How we use skills (gotchas, description is for triggering): https://claude.dev/blog/lessons-from-building-claude-code-how-we-use-skills/
- Chroma, *Context Rot* (2025): https://www.trychroma.com/research/context-rot
- Multi-line description made skill undiscoverable: https://github.com/anthropics/claude-code/issues/9817 and https://github.com/anthropics/claude-code/issues/12971. Downgraded in 0.3.2 (#18) to a low `(prediction)` note: the reports predate current Claude Code, `claude plugin validate` on 2.1.296 passes wrapped descriptions (observed 2026-10-11), and the skills docs don't mention them. No live listing check was run.
- Invalid frontmatter YAML: dimensions.md "1. Frontmatter and triggering" says it "fails silently; the skill just doesn't load". Contradicted 2026-10-11: the skills docs say the skill "still loads with no fields set" (https://code.claude.com/docs/en/skills, frontmatter reference), and `claude plugin validate` on Claude Code 2.1.296 reports it as an error (`success: false`, exit 1). Fixed in 0.3.2 (#18): dimensions.md now says the skill loads with no frontmatter fields.
- Claude Code plugin evals (`claude plugin eval` case format): https://code.claude.com/docs/en/plugin-evals
- Public validators: skills-ref (https://github.com/agentskills/agentskills/tree/main/skills-ref), skill-validator (https://github.com/agent-ecosystem/skill-validator)

## Specifics removed from the skill (as of 2026-09-27)

- SKILL.md description named the neighbours: "For creating or rewriting a skill use skill-creator; for skill usage and context cost use /skill-doctor."
- `claude plugin validate <plugin-dir> --json` checks the manifest and whether each skill has frontmatter. It lists only files with issues, so an empty `contents` is normal for a clean plugin. A skill with no frontmatter is only a warning (`success: true`, exit 0). It doesn't report wrapped descriptions, lengths, or unknown keys. Observed 2026-10-11 with Claude Code 2.1.296 on test plugins: a clean skill, a wrapped description, an unknown key, and a description over 2,000 characters each gave `success: true`, exit 0, and an empty `contents`; a skill with no frontmatter gave one warning, exit 0. It also checks that frontmatter parses: YAML that doesn't parse is an error, `success: false`, exit 1.
- Public spec validators: `skills-ref validate <skill-dir>` (the Agent Skills reference) and `skill-validator check <skill-dir>` (spec plus broken links, token counts, content metrics).
- Eval runners: `claude plugin eval` and skill-creator's eval loop; eval sets live in a plugin `evals/` directory for `claude plugin eval`, or a skill-creator eval file.
- Description optimizer: skill-creator's description optimization. skill-creator also suggests "pushy" descriptions; Anthropic guidance says aggressive trigger language overtriggers on Claude Opus 4.5 and later.
- Usage report: `/skill-doctor` (listing cost, usage, never-invoked skills; Claude Code v2.1.252 or later): https://code.claude.com/docs/en/skills, "Find unused skills" (checked 2026-10-11).
- Step 2 ran `claude plugin validate` "if the `claude` CLI is available"; the report header read `Schema check: <claude plugin validate: ...>`.
- The claim that multi-line descriptions made skills undiscoverable, with its two issue links (listed above).
- Listing truncation: `description` + `when_to_use` truncated at 1,536 characters.
- Reserved names: `synced`, `anthropic-skills…`. The skills docs say a skill folder named `synced` is skipped in the enterprise, personal, and project locations, and that outside a plugin a skill named `anthropic-skills` or starting with `anthropic-skills:` doesn't load: https://code.claude.com/docs/en/skills, "Choose where skills load" (checked 2026-10-11).
- Known frontmatter keys: `name`, `description`, `when_to_use`, `argument-hint`, `arguments`, `disable-model-invocation`, `user-invocable`, `allowed-tools`, `disallowed-tools`, `model`, `effort`, `context`, `agent`, `background`, `hooks`, `paths`, `shell`, `license`, `compatibility`, `metadata`.
- Portability limits (the Agent Skills spec, claude.ai, and the API enforce them): `name` 1–64 characters and must not contain `anthropic` or `claude`; `description` at most 1,024 characters; spec fields are `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`.
- `disable-model-invocation: true` also removes the skill from scheduled tasks and from Claude's listing. The skills docs say its description isn't in context and it doesn't run when a scheduled task fires with it as the prompt; it also isn't preloaded into subagents: https://code.claude.com/docs/en/skills, frontmatter reference and "Control who invokes a skill" (checked 2026-10-11).
- Length: `SKILL.md` body under 500 lines; the open spec suggests under ~5,000 tokens.
- Compaction caps for re-attached skills: 5,000 tokens each, 25,000 total.
- Subagents don't get the `AskUserQuestion` tool.
- Dynamic context (`` !`cmd` ``) commands time out after 2 minutes; `shell: bash` is the default and fails on Windows without Git Bash.
- The distractor finding's citation of *Context Rot* (listed above).
- The "Citable in findings" list: the Agent Skills specification, the multi-line description issue, and the prompting best practices (all listed above).
- The report template's example finding cited the multi-line description issue.

## Defaults (as of 2026-10-11)

- A skill earns its place above about 15 substantive lines; below that an inline prompt or a CLAUDE.md line does the same job (dimensions.md "3. Length and progressive disclosure"). House default.
- Methodology over half the body moves to a process doc linked from the skill (dimensions.md "7. Abstraction fit"). House default.
- Flag trigger phrases past 1,024 characters unless the platform docs give a lower cut (dimensions.md "1. Frontmatter and triggering"). From the Agent Skills spec's `description` limit (https://agentskills.io/specification), which is below Claude Code's 1,536-character cap per entry (https://code.claude.com/docs/en/skills, "Skill descriptions are cut short", checked 2026-10-11), so one number covers both.
- Top 5 fixes ranked by highest severity first, then by the number of skills affected (SKILL.md "Steps"). House default.
- With more than 5 skills, one subagent grades each (SKILL.md "Steps"). House default: the reason the skill gives, that past a handful the early skills crowd the later ones out of attention, wasn't measured.
