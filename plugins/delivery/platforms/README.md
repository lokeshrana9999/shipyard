# generated agent files

The four agents in `../agents/` (Claude Code's format, the source of truth) generated for other tools: `codex/agents/*.toml` for Codex and `gemini/agents/*.md` for Gemini CLI. Don't edit these files; change the source agent and run `node scripts/gen-agents.mjs` from the repo root (`--check` fails when a generated file is stale).

Where to copy them, the `AGENTS.md` snippet, and what doesn't carry over between tools: [docs/agents-install.md](../../../docs/agents-install.md).
