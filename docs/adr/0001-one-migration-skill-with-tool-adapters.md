# One migration skill with tool adapters

`prisma-workflow` mixed rules that hold for any migration tool (development database only, a gate on every risky change, never reset or bypass migration history, stop on a refusal or an unknown command) with Prisma's commands, and the gate had already drifted from its own list (#17). We replace it with one skill, `db-migration`, that holds the rules, plus one adapter per tool shipped under `references/tools/`, which the project's settings file selects and overrides. Each adapter says whether its tool generates migrations, so hand-written-by-design tools fit the same rules. The skill pre-approves no CLI commands, since `allowed-tools` is static and can't name project commands; adapters ship a permission allowlist for the project to paste instead.

## Considered options

- Keep `prisma-workflow` and add sibling skills per tool, each importing a shared rules file. Rejected: the copies drift, which is the failure #17 found inside a single skill.
- Adapters only in project settings. Rejected: the skill couldn't run in a project without a settings file.
- Keep Prisma's commands pre-approved in the general skill. Rejected: it favours one tool and breaks once a project wraps the CLI.

## Consequences

- Renaming touches ship's routing, the README, pipeline docs, the eval folder, and needs a CHANGELOG migration note like the 0.2.0 one.
- In default permission mode, every migration CLI call prompts. The adapter's allowlist, pasted into the project's settings, approves only the commands that change no database; creating, applying, and deploying still prompt.
- ship reads schema and migration globs from the migration skill's settings or adapters, so adding a tool never edits ship.
- An adapter is detected, read by ship, and named in the description only once it says `enabled: yes` (what that takes is in `references/tools/format.md`). A draft such as `drizzle.md` is used only when the settings file or the user names its tool, and the user agrees for that run after seeing its `Why it isn't enabled` section.
- While `.claude/shipyard/db-migration.md` is missing, the skill reads the old `.claude/shipyard/prisma-workflow.md` as its settings file with `tool: prisma` and asks once for the rename, so the hosts a project listed under `never-write hosts` stay protected after the upgrade. When both files exist, it reads the new one, still stops on the old file's `never-write hosts`, and asks for the old file to be merged in and deleted.
- `/shipyard-delivery:prisma-workflow` is removed with no stub skill in its place; the CHANGELOG's migration note points to `/shipyard-delivery:db-migration`.
- `SKILL.md` names no tool, command, version, env var, or error string; those live in the adapters, and `docs/sources/db-migration.md` records where each came from. There are two exceptions: the `description` names the enabled adapters' tools so prompts that name a tool still trigger the skill, and the old-settings fallback names the old file and the tool it implies (`prisma-workflow.md`, `tool: prisma`), as ship's `SKILL.md` does too, until that fallback is removed. `CONTRIBUTING.md`'s rule on specifics says the same for any skill with adapters.
