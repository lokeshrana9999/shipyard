# Privacy

shipyard collects nothing. The plugin has no server, no telemetry, and no analytics: it's a set of instruction files (skills and agents) that your coding agent reads and follows on your machine.

What the skills do with data happens inside your own agent session and with your own accounts:

- `pr-review` and `pr-description` read your repository and, when you ask, use your code host's CLI or API with your existing login (for example `gh`) to read or post pull request content.
- `live-verify` starts your app locally and signs in with a local development session; it never sends credentials anywhere else.
- `pr-review`'s `mine` mode reads past review comments from your code host with your login, and writes the resulting catalog to your project.

Your coding agent's own provider (for example Anthropic for Claude Code, OpenAI for Codex) processes what the agent reads under that provider's terms. Nothing is sent to the author of this plugin.

Questions: open an issue at https://github.com/lokeshrana9999/shipyard/issues.
