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

## Factory v3: evidence-gated routing (2026-11-05)

Source: the owner's retro plan `plan-v3.md` (items A1, P1, C1; the "ship routing" row of its state-machine table in section 7; the human-in-the-loop table in section 8) and the approved `factory-flow.mmd`. The retro counted 42 verification gaps across 18 batches and zero live-verify runs: branches reached review and merge on claims ("tests pass" in a commit message, a PR marked green) that the router accepted because it read the diff, not an artifact. The fixes below each answer one defect the retro found.

- **Evidence files decide, `next:` suggests.** A stage skill's `next:` line and the router could disagree; now the router is the authority on evidence and reads the stage's report, not its handoff line. Routing stays one read-only pass, so no timeout is needed.
- **The verify report is bound to a commit.** A report keyed by branch alone went stale when HEAD moved. live-verify writes `Commit: <full HEAD sha>` and `Result:`; the router moves 4 -> 5 only on `Result: pass` with `Commit:` equal to HEAD (or the settings skip verify, as before for libraries). Anything else is "verify not done" with the gap named in one line. Eval case: `refuses-stale-verify-report`.
- **Three fails is an andon stop.** The verify fix loop had no exit. Cap 3 (settings `caps: verify fix loop`), then the router names the failing check and asks fix, re-plan, or stop (H5) instead of routing back to implement a fourth time. `blocked` after live-verify's own single fix attempt stops the same way.
- **The plan station is stage 1, with a file.** Plan mode left no artifact, so "shared understanding" had no evidence. grill-plan writes `plans/<branch>.md` with an `Approved: <date> plan-hash <hash>` line; the router shows `Plan: confirmed | unconfirmed | none` at every stage. A goal with no plan file and no code goes to grill-plan unless it is a one-file obvious change (the retro's entry rule, D2). Code already in the diff with no plan is reported as `Plan: none` and routed on: re-grilling a built branch is waste, and the line shows the gap instead. Eval case: `routes-no-plan-to-grill`.
- **The review station is named once.** pr-review and a project gate both claimed review (double ownership). The settings' `review station` names one: `pr-review` (human-invoked, the router prints the command, H4) or `gate` (land runs it, so review is deferred to stage 7 and describe comes next). Default `pr-review`, which keeps the old behavior for projects without settings.
- **Land is stage 7.** Open or described PRs route to land, which syncs, runs the gate, merges, records, and waits for deploy up to T; its report's `Verdict:` line is the evidence. land is model-invocable but merges only with `merge: auto` in its own settings or the user's yes; the router says which applies when it routes there. Eval case: `routes-to-land-after-describe`.
- **Demo is stage 8 and settings-driven.** Stage 7 used to be a dead end; now the settings' `demo skill` names one, else the router says none and stops. The pack still ships no demo skill.
- **Prompt text needs eval-loop.** When the diff touches prompt, skill, or instruction text (settings `prompt paths`; default `**/SKILL.md`, `**/agents/*.md`, `**/prompts/**`), the eval-loop report must pass before verify counts as done; `eval-loop as verify evidence: yes` lets it stand in for live-verify where there is no app.
- **`Checked:` / `Not checked:` lines.** Stage reports end with them so the next stage knows what it inherits; the router quotes `Not checked:` when it names the change.
- **`<branch>` in file names** is the branch name with `/` replaced by `-` (integrator contract, 2026-11-05: `feat/x` -> `plans/feat-x.md`, `reports/live-verify-feat-x.md`); a project can override the paths in `plan files` and `stage reports`. The plan's approval hash covers the bytes above its `## approval` heading, so the router can recompute it with a shell and flag a plan edited after approval; without a shell it trusts the line and says so.
- **land is model-invocable; its merge is gated inside it.** The router may start land on the user's yes; the merge itself waits for `merge: auto` in land's settings or a yes, and land takes `.git/shipyard-land.lock` first. Its report's `Verdict:` vocabulary (`landed | gate failed | not merged | deploy did not run`) is land's; only `landed` counts as stage 7 done. The review station is read from ship's settings first, then land's, so a project sets it once.
- **Artifact paths in SKILL.md are written relative to `.claude/shipyard/`** (`plans/<branch>.md`, `reports/live-verify-<branch>.md`), because `gen-docs.mjs` lists every full `.claude/shipyard/….md` path in a skill body as that skill's own settings file, and the router's is `ship.md` only.

Human-in-the-loop names H1 to H10 and the caps come from plan-v3 section 8 and its caps list; they are kept stable across skill text so a stop reads the same everywhere. Owner project names in the plan (used there as first overlays) were dropped; the skill stays generic.
