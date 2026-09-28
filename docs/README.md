# shipyard docs

These pages cover how the pipeline runs, how to install it outside Claude Code, and how to work on the pack; installing in Claude Code and a first run are in the [repo README](../README.md).

| Page | Read it when |
|---|---|
| [pipeline.md](pipeline.md) | you want the stages, how `ship` picks the next one, each skill's handoff, or how `pr-review` reviews a diff |
| [agents-install.md](agents-install.md) | you use Codex, Gemini CLI, Cursor, GitHub Copilot, OpenCode, or another agent instead of Claude Code |
| [agents.md](helper-agents.md) | you want to know what the four helper agents do and which skill starts each |
| [skills/](skills/README.md) | you need one skill's arguments, who starts it, its settings file, or its handoff |
| [evals.md](evals.md) | you're changing a skill and need to run or write its evals |

Outside this folder:

- [examples/](../examples/): project settings for a NestJS + Prisma API, and an illustrative `ship` run
- [CONTRIBUTING.md](../CONTRIBUTING.md): repo layout and the rules for changing a skill
- [CHANGELOG.md](../CHANGELOG.md): what changed between versions
- `plugins/shipyard-delivery/docs/sources/<skill>.md`: where each skill's rules came from

The pages under `skills/` are generated from each `SKILL.md` by `node scripts/gen-docs.mjs`; edit the skill and re-run the script rather than editing a page.
