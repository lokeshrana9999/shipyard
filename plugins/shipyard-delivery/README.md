# shipyard-delivery

`shipyard-delivery` is the plugin in the [shipyard](https://github.com/lokeshrana9999/shipyard) marketplace. It takes a code change from question to pull request in eight stages: explain, plan, test design, implement, verify live, review, describe, and demo. Say "ship this" (or run `/shipyard-delivery:ship`) and the `ship` skill reads your branch, names the stage it is at, and names the one stage that comes next. Every stage skill ends with a `next:` line, so you always know what to run after it.

## Skills

| Skill | What it does |
|---|---|
| `ship` | Places the branch in the pipeline and names the next stage and the command that runs it. |
| `walkthrough` | Explains code or writes a plan, handoff, or report answer-first, with one next action. |
| `design-tests` | Writes a test-design document from the spec and the real code; it writes no test code. |
| `prisma-workflow` | Plans and makes a Prisma schema change with CLI-generated migrations, reviewing the SQL before it's applied. |
| `live-verify` | Boots the app, drives the changed flow over HTTP or in a browser, and reports each check with evidence. |
| `pr-review` | Reviews a branch against the project's recurring review concerns and validates every finding with a second agent. You start it. |
| `pr-description` | Drafts the PR title and body, shows it for approval, then creates or updates the pull request. You start it. |
| `build-workflow` | Runs several stages as one multi-agent run, with capped fix loops and a separate verifier. You start it. |
| `flow-diagram` | Draws flowcharts, sequence, and state diagrams in Mermaid or ASCII, whichever the destination renders. |
| `skill-auditor` | Audits `SKILL.md` files and writes a scored report with concrete fixes. |

"You start it" means the skill sets `disable-model-invocation`, so Claude won't run it on its own; run it as `/shipyard-delivery:<skill>`.

## Helper agents

Four agents run one step each in their own context: `concern-reviewer` and `review-verifier` (the two stages of `pr-review`), `test-designer`, and `live-verifier` (used by `build-workflow`). The plugin also ships the `signal` output style: answer first, one next step.

## Install

```sh
claude plugin marketplace add lokeshrana9999/shipyard
claude plugin install shipyard-delivery@shipyard
```

If you installed the plugin under its old name, `delivery`, the marketplace's `renames` entry moves it to the new name on Claude Code v2.1.193 or later; if it then reports the plugin isn't cached, run `claude plugin install shipyard-delivery@shipyard` once. On older versions, run `claude plugin uninstall delivery@shipyard` and then install as above.

## What it runs

The plugin has no hooks and no MCP servers, and it sends nothing anywhere on its own. Its skills tell the agent to run commands in your project with your usual permission prompts: `git` to read the branch, your code host's CLI (such as `gh`) to read pull requests and, in `pr-description` after you approve the draft, to create or update one, your project's Prisma CLI against the development database, and your app's own start command plus local HTTP requests or a browser in `live-verify`. `pr-review` includes `scope.sh`, a shell script that writes the diff to a scratch folder.

## More

Each skill reads optional project settings from `.claude/shipyard/<skill>.md`. The [repository README](https://github.com/lokeshrana9999/shipyard#readme) covers installing in other agents such as Codex, Gemini CLI, and Cursor, and the [docs](https://github.com/lokeshrana9999/shipyard/tree/main/docs) cover the pipeline, each skill's arguments and settings, and the evals. MIT licensed; see [LICENSE](LICENSE).
