# Sources: ship

Provenance for `skills/ship/`. Kept outside the skill folder so it never loads into context.

`ship` is new in the port; there is no archived original. It is the router the pack was planned around (superpowers-style: a router states the stage order, each stage skill ends with `next:`), built last so it names skills that exist.

## Model invocation of user-started skills (checked 2026-09-28)

Question: can the model invoke a skill that sets `disable-model-invocation: true` through the Skill tool?

Answer: no. The Claude Code skills docs (https://code.claude.com/docs/en/skills) say such a skill can be invoked only by the user; its description is not loaded into context, and the full skill loads only when the user invokes it. If the model tries anyway, Claude Code blocks the call and tells the model not to reproduce the skill's steps another way, so the expected behavior is suggesting the slash command to the user. `user-invocable: false` is the separate, opposite switch (hides it from the user, not the model).

Consequence for the router: pr-review, pr-description, and build-workflow set the flag (they launch costly multi-agent runs or publish to the code host), so `ship` prints their exact command (`/shipyard-delivery:pr-review`) for the user and never works through their steps itself. Model-invocable stage skills (walkthrough, design-tests, db-migration, live-verify, flow-diagram) it invokes directly after the user says yes.

## Decisions (as of 2026-09-28)

- **Model-invocable** (`disable-model-invocation` not set). Routing is cheap and read-only: no builds, test runs, writes, or agents, and it stops before starting any stage. Hiding it would also hide its description, so "what's left before I open a PR?" would never reach it, and it is the one skill that can point at the hidden ones.
- **One next stage, then stop.** Naming a list invites the agent to run them all; one stage plus a gate keeps each stage's own opt-in intact.
- **No stage rules restated.** The table holds order, entry condition, and skip rule only; each stage's how lives in its skill. Duplicated rules drift.
- **Test results are claims.** The router never runs tests to place the work; that would be stage work and can be slow. It reports where a pass claim came from.
- **Works without a shell.** `.git/HEAD` and `.git/logs/HEAD` are plain text, so branch and commits can be read with file tools; the pull request check degrades to "unknown".
- **Schema without migration routes to the migration skill first.** A schema change without a generated migration means implement isn't done, whatever the tests say. The skill was `prisma-workflow` until issue #29 and is `db-migration` now; see below.
- **`all` goes to build-workflow**, which has its own run-plan gate and its own one-agent decision, so the router doesn't duplicate either.
- **Demo has no skill.** demo-video and caption-video are deferred; the router names the stage and says so rather than substituting.
- **Commands are written with the plugin namespace** (`/shipyard-delivery:<skill>`), since the pack installs as the `shipyard-delivery` plugin.

## Schema and migration files (2026-10-10, issue #29)

`prisma-workflow` became `db-migration`, one skill with an adapter per migration tool (`docs/adr/0001-one-migration-skill-with-tool-adapters.md`). The router used to look for "Prisma schema files and their migrations"; it now takes the files from the migration skill, so adding a tool never edits the router.

- **Settings first.** db-migration's settings file (`.claude/shipyard/db-migration.md`, or the older `prisma-workflow.md` when it's missing, which means `tool: prisma`) can set `schema path` and `migrations path`. Those paths win. When `schema path` is a folder, the migration files inside it aren't schema files (those under `migrations path`, or the adapters' `migration files` when it isn't set), so a commit that only adds a migration doesn't look like a schema change that needs one. Any new file under `migrations path` counts as a new migration, so the router needs no adapter when both are set. The old file's `prisma directory` key isn't read: the Prisma adapter's globs already find a schema and migrations under any folder.
- **Otherwise the adapters' detection lines.** Each adapter in `skills/db-migration/references/tools/` has `enabled:`, `schema files:`, and `migration files:` lines in a fixed form (`references/tools/format.md`). The router reads those lines and nothing else: no tool runs, so the check stays cheap and works without a shell.
- **Enabled adapters only, even when `tool` names a draft.** A draft's globs are guesses (the Drizzle draft's `**/schema.ts` would match plenty of ordinary TypeScript), and `format.md` says ship reads only enabled adapters. A `tool` naming a draft leaves no globs unless the settings set the paths, and the router says the schema check didn't run.
- **The settings file isn't written out as a full path in `SKILL.md`.** `gen-docs.mjs` lists every `.claude/shipyard/….md` path in a skill's body as that skill's own settings, and the router's settings file is `ship.md` only.

## Style reference

- superpowers `using-superpowers` (router that says when to use which skill): https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md. Kept: one place that states the order and when each skill applies. Dropped: the mandatory "invoke before any response" rule and red-flag table; this router fires on request.
