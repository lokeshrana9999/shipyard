# Changelog

Notable changes to the shipyard pack, in the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format. The version is the `shipyard-delivery` plugin's (named `delivery` through 0.1.0), in `plugins/shipyard-delivery/.claude-plugin/plugin.json`.

## [Unreleased]

### Added

- `db-migration`'s adapter format, `references/tools/format.md`: the fields a tool's adapter fills in, the step that reads each one, and what an adapter needs before it's enabled (every field measured on a real release, and evals for the host check, the risky-change gate, and an unknown command).
- The Prisma adapter, `references/tools/prisma.md`, holding the commands, release notes, and error messages that were in `prisma-workflow`'s `SKILL.md`, plus a permission allowlist to paste into the project's `.claude/settings.json`.
- A draft Drizzle adapter, `references/tools/drizzle.md`, measured on drizzle-kit 0.31.11 against Postgres. It isn't enabled: detection skips it, and the skill uses it only when the settings file names `drizzle` and the user agrees for that run.
- A `legacy-settings-path` eval case: with only the old `.claude/shipyard/prisma-workflow.md` in the project, the skill stops on a host listed under its `never-write hosts` and asks for the rename.
- `plugins/shipyard-delivery/README.md` and `LICENSE`, which Anthropic's plugin directory requires in the plugin folder.
- A `relevance` block on the marketplace entry, so Claude Code can suggest the plugin after reading a `schema.prisma`, a Prisma migration, or a `package.json` that depends on `prisma` or `@prisma/client` (only where an admin allowlists the marketplace).
- `homepage`, `author.url`, and more `keywords` in `plugin.json`.
- Published as a public repo. Install tested in Claude Code (marketplace) and Codex (`npx skills add ... -g` plus the Codex agent files).
- `concern-reviewer` agent: maps the review catalog onto one slice of the diff, then reviews each mapped concern.
- `pr-review` ships `scope.sh`, which writes the diff and its added lines, and `references/workflow.js`, the runnable pipeline.
- `pr-review-bench` evals: 12 pull requests with injected bugs and 4 clean ones from Qodo PR-Review-Bench, with upstream license notices.
- `docs/`: pipeline, installing in other agents, helper agents, evals, and one generated page per skill.
- `scripts/gen-docs.mjs`, which generates `docs/skills/` from each `SKILL.md`, with a `--check` mode.
- `LICENSE` (MIT), `CONTRIBUTING.md`, this changelog, and `examples/ship-transcript.md`.
- Install for other agents with the skills CLI (`npx skills add`).

### Changed

- **`prisma-workflow` is replaced by `db-migration`** ([#29](https://github.com/lokeshrana9999/shipyard/issues/29)): one skill holds the rules for every migration tool, and one adapter per tool, `references/tools/<tool>.md`, holds that tool's commands. Prisma is the only enabled adapter. The command is now `/shipyard-delivery:db-migration`; `/shipyard-delivery:prisma-workflow` is removed, with no stub left in its place. The settings file is now `.claude/shipyard/db-migration.md`. While that file is missing, the skill reads `.claude/shipyard/prisma-workflow.md` as Prisma settings, its `allowed hosts` and `never-write hosts` included, and asks once for the rename; the old name may stop being read in a later release. To migrate: rename the file, add `tool: prisma`, and rename the keys as the skill's `references/overlay-example.md` lists (`prisma directory` becomes `schema path` and `migrations path`, `create migration` becomes `create without applying`, `apply migration` becomes `apply`, `generate client` becomes `regenerate client`). If you installed with `npx skills add` or by copying, delete the old `.agents/skills/prisma-workflow/` folder (`~/.agents/skills/prisma-workflow/` with `-g`), or the agent keeps loading it beside `db-migration`. The skill pre-approves no commands, so in Claude Code each Prisma command asks for permission; the Prisma adapter's `allowlist`, pasted into the project's `.claude/settings.json`, approves the read-only ones and creating a migration.
- **The plugin is renamed from `delivery` to `shipyard-delivery`** (version 0.2.0), and its folder from `plugins/delivery` to `plugins/shipyard-delivery`. Commands are now `/shipyard-delivery:<skill>` and agents `shipyard-delivery:<agent>`. The marketplace keeps its name, `shipyard`, and its `renames` map moves existing installs on Claude Code v2.1.193 or later. To migrate by hand: `claude plugin uninstall delivery@shipyard`, then `claude plugin install shipyard-delivery@shipyard`.
- The GitHub repo is moving from `lokeshrana9999/claude-skills-pack` to `lokeshrana9999/shipyard`; install commands and links use the new name (GitHub redirects the old one).
- Skill descriptions lead with the words a user would say ("review my PR", "write the PR description", "plan a migration"); `prisma-workflow` now also matches questions about planning a migration.
- `pr-review` runs as map and review per diff slice, a mechanical evidence check, then one `review-verifier` over every finding; the report is compiled from confirmed findings only. Slices are about 400 added lines, grouped by directory, with security-sensitive paths on their own, at most 6.
- Every agent runs on the model of the session that started it (`model: inherit`); model tiers are gone.
- `live-verify` reports every check on its own line when a run is blocked.
- The README is cut to the pitch, install, first run, and the skills table; the rest moved to `docs/`. `plugins/delivery/platforms/README.md` and `plugins/delivery/evals/README.md` now point to `docs/`.
- README and manifests describe the pack as Agent Skills for any agent, with Claude Code as one install path.

### Removed

- `review-scorer` agent and `pr-review`'s prefilter, selection, and size-tier funnel (`references/pipeline.md`).
- The `voice` plugin.

### Fixed

- The hand-written migration audit's `diff` command works on Prisma 6. `prisma-workflow` gave only the Prisma 7 form, `migrate diff --to-schema`, which 6.19.3 rejects with `unknown or unexpected option: --to-schema`; the Prisma adapter gives Prisma 6 its own form, with `--to-schema-datamodel` and `--shadow-database-url`.
- `prisma-workflow` stops for every change in `references/risky-changes.md`, including an index on an existing table, removing an enum value, and (a new row) making an existing column required. It counts every existing table as large and full, since production's row counts can't be seen ([#17](https://github.com/lokeshrana9999/shipyard/issues/17)).
- `prisma-workflow` checks in step 1 that every database the CLI will connect to (datasource, direct URL, shadow database) is local or listed under the new `allowed hosts` setting, and always stops on a host under the new `never-write hosts` setting, before generating anything. It prints only the host, never the connection string.
- `prisma-workflow` checks that Prisma is installed as a project dependency and that `prisma migrate --help` lists the subcommands it uses, instead of reading a version it had nothing to compare with, and stops on an unknown command rather than running a similarly named one. A plan-only request skips these commands and says they still have to pass.

## [0.1.0] - 2026-09-28

### Added

- The `shipyard` marketplace with the `delivery` plugin.
- Skills: `ship` (router), `walkthrough`, `design-tests`, `prisma-workflow`, `live-verify`, `pr-review`, `pr-description`, `build-workflow`, `flow-diagram`, and `skill-auditor`, each reading `.claude/shipyard/<skill>.md` project settings.
- Agents: `test-designer`, `live-verifier`, `review-scorer`, and `review-verifier`, with Codex and Gemini CLI copies generated by `scripts/gen-agents.mjs`.
- The `signal` output style for Claude Code.
- Eval cases per skill, scored against the no-plugin baseline, with `scripts/run-evals.sh`, `scripts/eval-stats.py`, and a WSL config for Windows.
- Example project settings for a NestJS + Prisma API.
- A private `voice` plugin placeholder with no skills.

[Unreleased]: https://github.com/lokeshrana9999/shipyard/compare/main...refactor/map-review-validate
[0.1.0]: https://github.com/lokeshrana9999/shipyard/tree/main

<!-- TODO: add a skills.sh badge to the README once the repo has a page on skills.sh. -->
