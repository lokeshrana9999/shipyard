# Sources: ship

Provenance for `skills/ship/`. Kept outside the skill folder so it never loads into context.

`ship` is new in the port; there is no archived original. It is the router the pack was planned around (superpowers-style: a router states the stage order, each stage skill ends with `next:`), built last so it names skills that exist.

## Model invocation of user-only skills (checked 2026-09-28)

Question: can the model invoke a skill that sets `disable-model-invocation: true` through the Skill tool?

Answer: no. The Claude Code skills docs (https://code.claude.com/docs/en/skills) say such a skill can be invoked only by the user; its description is not loaded into context, and the full skill loads only when the user invokes it. If the model tries anyway, Claude Code blocks the call and tells the model not to reproduce the skill's steps another way, so the expected behavior is suggesting the slash command to the user. `user-invocable: false` is the separate, opposite switch (hides it from the user, not the model).

Consequence for the router: pr-review, pr-description, and build-workflow set the flag (they launch costly multi-agent runs or publish to the code host), so `ship` prints their exact command (`/shipyard-delivery:pr-review`) for the user and never works through their steps itself. Model-invocable stage skills (walkthrough, design-tests, prisma-workflow, live-verify, flow-diagram) it invokes directly after the user says yes.

## Decisions (as of 2026-09-28)

- **Model-invocable** (`disable-model-invocation` not set). Routing is cheap and read-only: no builds, test runs, writes, or agents, and it stops before starting any stage. Hiding it would also hide its description, so "what's left before I open a PR?" would never reach it, and it is the one skill that can point at the hidden ones.
- **One next stage, then stop.** Naming a list invites the agent to run them all; one stage plus a gate keeps each stage's own opt-in intact.
- **No stage rules restated.** The table holds order, entry condition, and skip rule only; each stage's how lives in its skill. Duplicated rules drift.
- **Test results are claims.** The router never runs tests to place the work; that would be stage work and can be slow. It reports where a pass claim came from.
- **Works without a shell.** `.git/HEAD` and `.git/logs/HEAD` are plain text, so branch and commits can be read with file tools; the pull request check degrades to "unknown".
- **Schema without migration routes to prisma-workflow first.** A schema change without a generated migration means implement isn't done, whatever the tests say.
- **`all` goes to build-workflow**, which has its own run-plan gate and its own one-agent decision, so the router doesn't duplicate either.
- **Demo has no skill.** demo-video and caption-video are deferred; the router names the stage and says so rather than substituting.
- **Commands are written with the plugin namespace** (`/shipyard-delivery:<skill>`), since the pack installs as the `shipyard-delivery` plugin.

## Style reference

- superpowers `using-superpowers` (router that says when to use which skill): https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md. Kept: one place that states the order and when each skill applies. Dropped: the mandatory "invoke before any response" rule and red-flag table; this router fires on request.
