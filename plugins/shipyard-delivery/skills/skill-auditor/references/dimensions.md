# Audit dimensions

Eight dimensions. Each lists its checks, then a severity table.

Contents
1. Frontmatter and triggering
2. Body structure
3. Length and progressive disclosure
4. Approval gates
5. Instruction quality
6. Anti-patterns
7. Abstraction fit
8. Wordiness and distractors
- Citable in findings

## 1. Frontmatter and triggering

Platform hard limits (always apply; the current values are in the platform docs):
- Frontmatter starts on line 1 and parses as YAML. Invalid YAML loads the skill with no frontmatter fields: `/name` still works, but the description can't trigger it, and `disable-model-invocation` and the other flags are dropped.
- `description` is present. Without it, the platform falls back to the first body line, which rarely says when to trigger.
- The skill listing truncates long `description` + `when_to_use` text, so trigger phrases past the cut can't trigger anything. Put the main use case and trigger phrases first. Default: flag trigger phrases past 1,024 characters, unless the platform docs give a lower cut.
- `name` isn't one of the platform's reserved names, and isn't vague (`helper`, `utils`, `tool`, `data`).
- Frontmatter keys are ones the platform documents. As far as the docs say, an unknown key is ignored, so it's usually a typo that does nothing.

Portability (the open Agent Skills spec and other surfaces enforce these; Claude Code doesn't):
- `name`: within the spec's length limit, lowercase letters, digits, and hyphens; doesn't start or end with a hyphen or contain `--`; matches the parent directory; avoids the spec's reserved words.
- `description`: within the spec's length limit, no XML tags.
- Frontmatter uses only spec fields. Claude Code extensions such as `argument-hint` fail spec validators; that only matters if the skill is published beyond Claude Code.

Quality:
- The description says **what** and **when**, in third person ("Audits…", not "I can…" / "You can…"), with words a user would actually type. It describes when to trigger, not a summary of the body.
- Recommend plain "Use when…" descriptions with concrete trigger phrases, and settle close calls with should/shouldn't-trigger evals. Some authoring guides suggest "pushy" descriptions to fight undertriggering, but aggressive trigger language ("CRITICAL: You MUST use this when…") makes Claude Opus 4.5 and later overtrigger.
- A skill with `disable-model-invocation: true` is started only by the user. Where the platform leaves its description out of the model's context (Claude Code does), grade the description as a `/` menu line: what the skill does and what its argument takes, ending with a sentence that it runs only when the user asks, for agents that ignore the flag. Don't ask it for trigger phrases or a `Use when` clause.
- It separates this skill from near-miss neighbours (sibling skills, built-in commands) when confusion is plausible.
- Skills with side effects (deploy, push, commit, send, publish, delete) set `disable-model-invocation: true`, so Claude doesn't decide to run them because the code "looks ready". The flag can also hide the skill from other places that rely on model invocation; check the platform docs for which. Editing a local project file behind an approval gate (a changelog, a config) doesn't count: it's reversible and the gate already covers it.
- Background knowledge that users never invoke directly sets `user-invocable: false`.
- Skills that only matter for certain files use `paths` instead of a broad description.
- `context: fork` skills contain an actual task. Guidelines with no task give the forked agent nothing to do.
- `hooks:` in frontmatter registers hooks that stay active for the rest of the session once the skill runs. That is a side effect; treat it like one for `disable-model-invocation`.
- `argument-hint` is present when the body reads `$ARGUMENTS` / `$N`. An empty-argument check tests `$ARGUMENTS`, which expands to an empty string; an unmatched `$0` stays as the literal text `$0`.
- Plugin skills run as `/<plugin>:<skill>`; references to them in either form are fine.
- `description` on one line. Older Claude Code versions were reported to miss multi-line descriptions (a wrapped plain scalar, or a `|` / `>` block), and current validators pass them, so note one at low severity as a `(prediction)` and suggest confirming the skill appears in the `/` menu.

| Severity | When |
|---|---|
| high | frontmatter that doesn't parse; missing `description`; reserved `name`; side-effecting skill without `disable-model-invocation`; portability violation in a skill published beyond Claude Code (its settings file or README says so) |
| medium | portability violation in a skill not published beyond Claude Code; vague description with no trigger words (except a user-started skill's menu line); key trigger phrases past the listing cut; unknown key; `context: fork` with no task |
| low | multi-line description, as a `(prediction)`; background skill missing `user-invocable: false`; file-scoped skill missing `paths`; missing `argument-hint`; other missing optional fields that would help |
| no finding | Claude Code-only fields in a Claude Code-only skill |

## 2. Body structure

- The body has a recognizable shape: inputs → output → rules → steps → gates. The shipyard default names are `Inputs`, `Output`, `Rules`, `Steps`, plus inline gate markers; the settings file may set others. Names can vary if the shape is there.
- Multi-step skills give a copyable `- [ ]` progress checklist, so the model can track its position across compaction.
- Destructive or batch work follows plan → validate → execute, and quality-sensitive output has a validate → fix → repeat loop.
- The same concept is named the same way throughout ("report", not "report" / "audit doc" / "output file").
- Section order is consistent across sibling skills in the same project. (Checked in the cross-skill step, not per skill.)

| Severity | When |
|---|---|
| high | unstructured prose body for a multi-step task |
| medium | missing inputs or output contract; missing checklist on a flow of 5 or more steps; missing validation loop on output that must be correct |
| low | non-standard but project-consistent section names |

## 3. Length and progressive disclosure

- `SKILL.md` body short enough to load cheaply and survive compaction. Default ceiling: 500 lines, unless the platform docs or the open spec give a tighter line or token guideline. Above it, move detail into sibling files linked from `SKILL.md`.
- Linked files are **one level deep**. A file that links onward is only partly read (Claude may `head` nested files), so content two hops away is often missed.
- Reference files over 100 lines open with a table of contents, so a partial read still shows what exists.
- `SKILL.md` says when to read each linked file, and whether a bundled script is to be **run** or **read**.
- After compaction, re-attached skills are capped per skill and in total, so the rules that matter most sit early in `SKILL.md`, not at the bottom of a long file.
- `SKILL.md` has more than about 15 substantive lines; below that, an inline prompt or a CLAUDE.md line does the same job.

| Severity | When |
|---|---|
| high | body over the length ceiling; critical rules only in a file two links away |
| medium | fewer than about 15 substantive lines; a reference chain more than one level deep; a reference file over 100 lines without a table of contents; unclear whether a script is run or read |

## 4. Approval gates

- Every irreversible or outward-facing operation (commit, push, publish, send, delete, network write, package install, overwriting a user file) has an explicit gate before it.
- Gates use one marker vocabulary. Shipyard default: `STOP — WAIT` (approval needed), `HUMAN TRIGGER` (the user does work), `NO STOP — Agent-owned` (proceeds; may be left implicit if the skill says unmarked steps are agent-owned). The settings file may define another; what matters is that one is used consistently within a skill, and across skills (checked in the cross-skill step).
- A gate says what the user is approving (branch, title, target, file) so approval is informed, not a bare "continue?".
- Gates are reachable: none inside a `context: fork` skill or a step handed to a subagent. Subagents can't ask the user a question; a fork can end with a question but can't wait for the answer, so a `STOP — WAIT` inside one is unreachable.
- Side-effecting skills also set `disable-model-invocation: true` (dimension 1). A gate inside a skill Claude can auto-invoke is a second line of defence, not the first.

| Severity | When |
|---|---|
| high | irreversible operation without a gate; a gate that can't reach the user |
| medium | inconsistent marker vocabulary; a gate that doesn't say what's being approved |

## 5. Instruction quality

- **Standing instructions, not one-shots.** Skill content stays in context across turns, so "Read the requirements file before editing" keeps working; "Now read the file" doesn't.
- **Examples on format-strict rules.** Any rule about output shape has a concrete input → output example.
- **Rules explain why.** A reason lets the model generalize to cases the rule didn't name. Bare `ALWAYS`/`NEVER` is a yellow flag.
- **Calm emphasis.** Emphasis on one line stands out; on many, none does. (Aggressive *trigger* language in descriptions is covered in dimension 1.)
- **Positive phrasing for format and style.** For output formatting, tell Claude what to do instead of what not to do. Treat negatives elsewhere as a style note, not a defect. Genuine prohibitions (security boundary, irreversible action, documented bug) stay negative, with the reason next to them.
- **Freedom matches fragility.** Fragile, exact operations (migrations, publish commands) get low freedom: exact commands or scripts. Judgment tasks get goals and constraints, not every step.
- **Gotchas captured.** Failure modes found in real use are the highest-signal content a skill can carry. A skill wrapping a known-fiddly tool with no gotchas section is missing its most useful part.
- **No re-teaching.** Content that restates what the model already knows (what git is, how to write markdown) costs tokens and dilutes the rules that matter.
- **Evals exist.** At least three evaluation scenarios per skill. Check statically for an eval set that covers this skill (a plugin `evals/` directory, a repo-level `evals/<plugin>/<skill>/` folder, or whatever eval file the platform's eval runner reads). Running it is out of scope.

List every negative-phrasing rule found in the per-skill detail's `Negative-phrasing rules` table, each with a positive rewrite or "keep: genuine prohibition". List every one, even low-severity ones.

| Severity | When |
|---|---|
| medium | format-strict rule without an example; one-shot phrasing throughout; dense ALL-CAPS or MUST; high-freedom instructions on a fragile operation |
| low | negative phrasing on format rules; isolated rules missing why; missing gotchas; no evals |

## 6. Anti-patterns

- **Time-sensitive language** ("after August 2025…"). Move old behaviour into a collapsed "Old patterns" section.
- **Fossilized paths**: absolute or machine-specific paths (`C:\Users\…`, `/home/alice/…`). Resolve paths at run time instead (in Claude Code: `${CLAUDE_SKILL_DIR}` for bundled files, `${CLAUDE_PLUGIN_ROOT}` / `${CLAUDE_PLUGIN_DATA}` in plugins, `${CLAUDE_PROJECT_DIR}` for the project).
- **Backslash paths** in instructions meant to be cross-platform. Use forward slashes.
- **Menus of options** ("use X, Y, or Z"). Pick a default and give one escape hatch.
- **Unexplained constants** ("retry 3 times", "timeout 47s") with no reason given.
- **Dead references** to numbering or documents the agent never loads (`see step 05b.4`).
- **Off-workflow references**: a sibling skill or file path named but never read, invoked, or written by any step. Forward mentions that only duplicate a later use site count too.
- **Project-specific vocabulary** in a skill meant to be reusable: `day-3`, `Phase 5`, one product's module names, one person's name. Replace with generic phrasing or `<placeholders>`, or move the values to the project's settings file.
- **Methodology bleed**: long general methodology embedded in a recipe skill. Link to a process doc instead.
- **Unqualified MCP tool names**: write `Server:tool_name`, since several servers can expose the same tool name.
- **Dynamic context pitfalls** (`` !`cmd` `` runs before Claude sees the skill):
  - A failing command aborts the whole invocation; append `|| true` where failure is expected.
  - A command that would need permission approval also aborts; pre-approve it in `allowed-tools`. A command matching a deny rule aborts even then, so remove it.
  - Commands have a timeout (current value in the platform docs); a slow command aborts the invocation.
  - A `shell` the machine doesn't have (bash on a Windows machine with no bash installed) fails the invocation.
- **Argument placeholders in prose**: substitution is plain text replacement over the whole `SKILL.md`, code spans included. `$ARGUMENTS` expands to the argument string (empty with no arguments), and `$0`/`$1` expand when that argument exists. So "When `$ARGUMENTS` is empty" reads "When `` is empty" exactly when it matters, and `$1.00` becomes an argument. Escape as `\$` or write "the first argument".
- **`${CLAUDE_*}` in reference files** (Claude Code): substitution runs only over `SKILL.md` (and `allowed-tools` Bash rules); a linked file using `${CLAUDE_SKILL_DIR}` gets the literal text. Resolve paths in `SKILL.md` and pass them down.
- **Relative paths handed to subagents**: a subagent resolves them against its own working directory, not the skill's. Pass absolute paths (in Claude Code, `${CLAUDE_SKILL_DIR}/…`).
- **Security surprises** in a shared skill: `` !`cmd` `` or instructions that fetch and execute remote content (`curl … | sh`), network writes, or credential handling the description doesn't mention.
- **Undeclared script dependencies**: bundled scripts whose packages or runtimes aren't listed.

| Severity | When |
|---|---|
| high | dead references; fossilized paths in a published or shared skill; `` !`cmd` `` that can abort on a normal machine (failure, permission, deny rule, missing shell); security surprises |
| medium | argument placeholders in prose; `${CLAUDE_*}` in reference files; relative paths handed to subagents; off-workflow references; project vocabulary; methodology bleed; unqualified MCP names; undeclared dependencies; `` !`cmd` `` that can hit the command timeout |
| low | backslash paths; menus; unexplained constants; time-sensitive asides |

## 7. Abstraction fit

- **Bullseye**: one input shape → one output artifact (or one bounded interactive session), one approval contract, repeatable across many invocations.
- Misfit signals, with the better home for each:

| Signal in the skill | Better home |
|---|---|
| Facts that apply to every session in the project | CLAUDE.md |
| Facts only, no steps, needed only sometimes | `user-invocable: false` reference skill |
| Three-line procedure | Script or inline prompt |
| Branching state across sessions | Orchestrator with skills as primitives |
| Must run on every event | Hook (PostToolUse, Stop, SessionStart, …) |
| Pure code/data transformation | Bundled script or MCP server |
| Judgment-heavy investigation | Subagent dispatch plus a methodology doc |
| One-shot, never repeated | Inline prompt or runbook |
| Several independent artifacts | One skill per artifact |
| Dispatches sibling skills / routes failures | Orchestrator step; artifacts are the seams between skills |
| Methodology > 50% of body | Process doc, linked from the skill |

Routing means a skill starting the next skill itself, or choosing which skill runs after a failure. A handoff isn't routing: a one-line `next:` that names the following stage and leaves starting it to the user or the session. Neither is a skill whose whole job is routing, such as a pipeline router.

- Verdict: **Bullseye** / **Acceptable** / **Misfit**.
- Recommendation: Keep / Refine boundary / Split / Demote to doc / Promote to orchestrator step / Move to other surface.

| Severity | When |
|---|---|
| high | Misfit; routing inside a stage skill (a `next:` handoff and a dedicated router skill are exempt) |
| medium | Acceptable, but the boundary needs refining |

## 8. Wordiness and distractors

- **Filler vs specification.** Politeness, hedging, restating the task, and background the model already has are filler. Ask of each paragraph: does it justify its token cost?
- **Imperative voice**: "Run the build", not "You should run the build".
- **Distractors near critical instructions.** Content that closely resembles a correct instruction but is wrong, such as a stale example next to the current one or a superseded command kept "for reference", measurably degrades model accuracy beyond what length alone does. Label wrong examples as wrong, or remove them.

| Severity | When |
|---|---|
| high | distractor next to a critical instruction |
| medium | high filler ratio |
| low | non-imperative voice |

## Citable in findings

When a finding is likely to be disputed, cite the source that documents the rule. Link the current page rather than quoting a limit from memory:

- The platform docs. For Claude Code: https://code.claude.com/docs/en/skills
- The open Agent Skills spec, for portability findings: https://agentskills.io/specification
- Prompting best practices, for aggressive trigger language and negative phrasing: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- The report behind the multi-line description note: https://github.com/anthropics/claude-code/issues/9817
