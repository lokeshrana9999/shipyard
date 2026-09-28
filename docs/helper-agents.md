# helper agents

The pack has four agents, each running one step in its own context so the main session doesn't carry that step's reading. Skills start them; you don't call them directly. Every agent file sets `model: inherit`, so each runs on the model of the session that started it. Without subagent support, the skill does the agent's step in the main session and says so.

| Agent | Job | Started by | Tools |
|---|---|---|---|
| `concern-reviewer` | Maps the review catalog onto one slice of a diff, then reviews each mapped concern: a finding with a failure scenario, or cleared with a reason | `pr-review` (one per slice, in parallel); `build-workflow`'s review stage | read-only |
| `review-verifier` | Tags every finding confirmed, false-positive, pre-existing, or duplicate, sets its final severity, and writes a one-line ship verdict; also checks "fixed" claims | `pr-review` (once, after the check); `build-workflow`'s review stage and fix loops | read-only |
| `test-designer` | Designs tests for one slice from the spec and the real code, unattended, following `design-tests`; lists open questions instead of asking | `build-workflow`'s test-design stage, one per slice | read-only |
| `live-verifier` | Verifies a change in the running app, unattended, following `live-verify`; returns pass, fail, or blocked with evidence as JSON | `build-workflow`'s verify-live stage, once after every commit lands | full |

## when each one runs

`concern-reviewer` and `review-verifier` are the two stages of every `pr-review` run: one reviewer per slice of the diff (one slice for a small change, at most six by default), a script that drops findings whose quoted line isn't in the diff, then one verifier over everything that's left. The verifier never sees the reviewers' reasoning, so it judges each finding cold. [pipeline.md](pipeline.md#how-pr-review-works) has the full flow.

`test-designer` and `live-verifier` run only inside a `build-workflow` run. When you run `design-tests` or `live-verify` yourself, the skill does the work in your session and can ask you questions; the agents exist for runs where nobody is there to answer. That's why both say "unattended": `test-designer` writes its questions into the document, and `live-verifier` decides a blocker itself (fix, retry, rescope, or abort) and never waits for approval.

## files

The source files are in [plugins/shipyard-delivery/agents/](../plugins/shipyard-delivery/agents/), in Claude Code's format. Codex and Gemini CLI copies are generated into `plugins/shipyard-delivery/platforms/` by `node scripts/gen-agents.mjs`; where to put them for each tool is in [agents-install.md](agents-install.md#2-copy-the-agents).

Claude Code also gets the `signal` output style (`plugins/shipyard-delivery/output-styles/signal.md`: answer first, one next step, progress markers), which you pick in Claude Code's settings. It isn't an agent and nothing starts it for you.
