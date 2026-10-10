# One migration skill with tool adapters

`prisma-workflow` mixed rules that hold for any migration tool (development database only, a gate on every risky change, never reset or bypass migration history, stop on a refusal or an unknown command) with Prisma's commands, and the gate had already drifted from its own list (#17). We replace it with one skill, `db-migration`, that holds the rules, plus one adapter per tool shipped under `references/tools/`, which the project's settings file selects and overrides. Each adapter says whether its tool generates migrations, so hand-written-by-design tools fit the same rules. The skill pre-approves no CLI commands, since `allowed-tools` is static and can't name project commands; adapters ship a permission allowlist for the project to paste instead.

## Considered options

- Keep `prisma-workflow` and add sibling skills per tool, each importing a shared rules file. Rejected: the copies drift, which is the failure #17 found inside a single skill.
- Adapters only in project settings. Rejected: the skill couldn't run in a project without a settings file.
- Keep Prisma's commands pre-approved in the general skill. Rejected: it favours one tool and breaks once a project wraps the CLI.

## Consequences

- Renaming touches ship's routing, the README, pipeline docs, the eval folder, and needs a CHANGELOG migration note like the 0.2.0 one.
- In default permission mode, every migration CLI call prompts unless the project pastes the adapter's allowlist.
- ship reads schema and migration globs from the migration skill's settings or adapters, so adding a tool never edits ship.
