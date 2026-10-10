# Adapter format

An adapter is the tool-specific part of the db-migration skill: one file per migration tool, `references/tools/<tool>.md`, where `<tool>` is the value a settings file gives as `tool`. SKILL.md holds the rules and takes every command, file name, and error signature from the adapter. Each field below says which part of SKILL.md reads it.

Write each field as one list item, `- <field>: <value>`, under its section's heading, so SKILL.md and ship can find it by name. Put commands and globs in backticks, with placeholders in angle brackets: `<name>`, `<schema path>`, `<migrations path>`. A field that doesn't apply to the tool says `none` and why. The project's settings file wins over the adapter: its `schema path` and `migrations path` over what `discovery` finds, its `working directory` and `environment` over the fields of those names, and each command it lists over the section 6 command of the same name.

Contents
- Header
- 1. Detection
- 2. Running
- 3. Paths
- 4. Connections
- 5. Migrations
- 6. Commands
- 7. Never run
- 8. Refusals and known failures
- 9. Risky-change notes
- 10. Permissions
- Enabling an adapter

## Header

- The first line is `# <Tool> adapter`. A draft adds `: draft, not enabled`.
- `enabled:` `yes` or `no`, the first line below the heading. Read by: SKILL.md's Adapter section, which never detects an adapter without `enabled: yes`, and ship, which reads globs only from enabled adapters.
- `releases:` the releases the facts in the file were checked against. The CLI check (section 2), not this list, decides whether a release is covered.

## 1. Detection

Globs are matched from the project root, outside dependency folders such as `node_modules`. The `load-when`, `schema files`, and `migration files` lines are read by machine: every backticked entry on them is a glob or a manifest check, so a note on those lines goes in parentheses after the entries, without backticks.

- `load-when:` backticked entries; the adapter matches the project when any one matches. Use `package.json contains "<package>"` for a package manifest (the same form as pr-review's catalogs), or a glob for a config or schema file. Read by: Adapter.
- `schema files:` backticked globs for the tool's schema files. Read by: ship, to see that a schema changed.
- `migration files:` backticked globs, each matching one file per migration. Read by: ship, to see whether a migration came with the schema change.
- `dependency:` the package the project must declare, and where. Read by: step 1.
- `installed CLI:` where the installed CLI lives, so step 1 can confirm it's installed with file tools.
- `version without a shell:` where to read the installed release with file tools. Read by: step 1's plan-only path, and the CLI-check stop message.

## 2. Running

- `invoke:` how to run the project's installed CLI, per package manager, and which invocations download a different release instead. Read by: Rules, and every step that runs a command.
- `environment:` how the tool loads environment variables: whether it reads an env file on its own, which one, and what wins over it. Read by: step 1, and the note after step 6.
- `CLI check:` a command that connects to no database, since it runs before the host check; what its output lists when the release is covered (pass); and what it shows when it isn't (fail). Read by: step 1, which reads stdout and stderr together.
- `unknown command:` how the tool reports a command it doesn't have: text, stream, exit code. Read by: Rules.
- `environment error:` how a variable the tool couldn't load shows up. Read by: step 1, which treats it as a loading problem, not an unsupported release.

## 3. Paths

- `discovery:` the order in which to find the schema and the migrations folder when the settings file doesn't set them. Read by: step 1.
- `schema shape:` one file, a folder of files, or either. Read by: step 1.
- `working directory:` where commands run from by default. Read by: every step that runs a command.
- `client import:` where application code imports the generated client or types from. Read by: step 5.

## 4. Connections

- `URLs:` every database URL the tool can connect to (main, direct, shadow, or others), where each is declared, and which commands use it. Read by: step 1's host check.
- `connecting commands:` which commands connect to a database, from section 6 and any others the skill might run. Read by: step 1, whose host check runs before the first of them, and the hand-written migration audit.
- `connection-string quirks:` where the host really is in the tool's connection strings: query parameters that override it, sockets, local files, and strings a URL parser misreads. Read by: step 1's host check.

## 5. Migrations

- `generates:` `yes` when the tool writes migrations from the schema, `no` when people write them. Read by: Rules and step 3. With `yes`, nobody hand-writes a migration; with `no`, each one is audited against the schema before it's applied.
- `format:` `sql`, or `code` followed by a `SQL preview:` command that prints the SQL a code migration will run. Read by: step 4 and Output.
- `name flag:` how a migration gets its name, and what happens without one. Read by: Rules and steps 3 and 5.
- `layout:` where a migration's files go, how they're named, and where applied migrations are recorded. Read by: step 3 when `generates: no`.
- `transactions:` whether the tool runs a migration, or a whole batch, in one transaction, and how a statement that can't run inside one gets run. Read by: step 4's safer paths.
- `physical names:` how the schema's names map to the database's tables, columns, types, and values, or `none` when they're the same. Read by: step 2 (match the mapping style), step 4 and the audit (check identifiers against it; skip that check when it's `none`).

## 6. Commands

- `create without applying:` writes the migration file and leaves the database's schema alone. `none` when `generates: no`. Read by: step 3.
- `apply:` applies the new migration to the development database. Read by: step 5.
- `regenerate client:` regenerates the client or types, or `none` when the tool has no generated client. Read by: step 5, which skips it on `none`.
- `status:` lists applied and pending migrations. Read by: step 6.
- `status exit code:` what the status command's exit codes mean, and whether only its output can tell a pending migration from a connection error. Read by: step 6.
- `deploy pending:` applies migrations already in the folder without creating any. Read by: step 6.
- `diff:` prints the SQL the tool would generate between the migrations folder and the schema, with its arguments, or `none`. Read by: the hand-written migration audit.

## 7. Never run

- `never run:` commands that reset the database, or change its schema without a migration, each with the reason. Read by: Rules.
- `consent setting:` the setting a tool reads before it lets an AI agent run a destructive command, or `none`. Read by: Rules; the skill never sets it.

## 8. Refusals and known failures

- `refusals:` how the tool refuses when it has no terminal: drift, a reset proposal, a data-loss warning, a question it can't ask. Give the exit code; some tools refuse with exit 0, and say so. Read by: Rules and steps 3 and 5.
- `known failures:` other failures with a known cause, and the fix to tell the user. Read by: steps 3 and 5.

## 9. Risky-change notes

One item per row of `references/risky-changes.md`, named by that row's Change: what this tool generates for it, and how to take the safer path with this tool. A row the tool handles as the table says reads `as in the table`. Read by: step 4 and the audit.

## 10. Permissions

- `allowlist:` a JSON block of permission rules for Claude Code's project `.claude/settings.json`, so the listed commands run without a prompt. List only commands the skill runs, never one under `never run`. Read by: Adapter, which points the user to it.
- `other agents:` what to do in agents with no such file. Read by: Adapter.

## Enabling an adapter

Set `enabled: yes` only when every field comes from a real release, measured, with the measurements recorded in the repo's sources for this skill, and evals cover at least the host check, the step 4 gate, and an unknown command. An enabled adapter fills `CLI check`, `apply`, `status`, and `create without applying` when `generates: yes`; any other field may be `none`. Until then it says `enabled: no`, and detection skips it.
