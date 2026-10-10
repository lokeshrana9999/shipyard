# Prisma adapter

enabled: yes
releases: Prisma 6 and 7, checked against 6.19.3 and 7.10.0. 8.1.0-dev.9 (the classic CLI) passes the CLI check too. 8.0.0-rc.22 fails it: that release has no `migrate` command.

Contents
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

## 1. Detection

- load-when: `package.json contains "prisma"`, `prisma.config.*`, `**/*.prisma`
- schema files: `**/*.prisma`
- migration files: `**/migration.sql`
- dependency: `prisma` in `dependencies` or `devDependencies` of the working directory's `package.json`, or the workspace root's. `@prisma/client` alone isn't enough: it doesn't carry the CLI.
- installed CLI: `node_modules/.bin/prisma`, in the working directory or the workspace root.
- version without a shell: `version` in `node_modules/prisma/package.json`, else the `prisma` entry in the lockfile, else the range declared for `prisma` in `package.json` (say it's a declared range, not the installed release).

## 2. Running

- invoke: the package manager's runner for the installed CLI, matching the lockfile: `npx prisma`, `pnpm prisma`, `yarn prisma`, or `bunx prisma`. The commands below are written with `npx prisma`. Never `npx prisma@latest` or any other pinned release: on 2026-10-10 npm `latest` was 8.0.0-rc.22, a different major version whose CLI has no `migrate`. A bare `npx prisma` in a project that declares Prisma but hasn't installed it downloads and runs that release too, which is why step 1 checks `installed CLI`.
- environment: since Prisma 7 the CLI doesn't read `.env` on its own. `prisma.config.*` usually imports `dotenv/config`; some projects load the environment through a wrapper script instead. Prisma 6 read `.env` itself.
- CLI check: `npx prisma migrate --help`, with the environment loaded. Pass: the help lists `dev`, `status`, `diff`, and `deploy` as subcommands of `migrate` (6.19.3, 7.10.0, and 8.1.0-dev.9 do). Fail: it prints the top-level help instead, or reports `migrate` as unknown. On 8.0.0-rc.22, `migrate --help` prints the top-level help to stderr, with stdout empty and exit 0; `dev` and `deploy` appear there as top-level commands, and `status` and `diff` don't appear at all.
- unknown command: 6 and 7 print `! Unknown command "<name>"` and the help to stderr, and exit 1. 8.0.0-rc.22 exits 2 with `CLI.UNKNOWN_COMMAND`, as JSON on stdout when not in a terminal, for example "No command registered for `migrate`, did you mean `migration`?". Never follow the "did you mean" hint: on rc.22, top-level `prisma dev <entry>` and `prisma deploy <entry>` run or deploy an app on Prisma's hosted platform.
- environment error: with a `prisma.config.ts` that reads its URL through `env()` and the variable unset, `prisma migrate --help` exits 1 with `Failed to load config file … PrismaConfigEnvError: Cannot resolve environment variable: DATABASE_URL.` The other usual symptom is `DATABASE_URL` not found. Both mean the environment wasn't loaded the way the project loads it.

## 3. Paths

- discovery: first `prisma.config.*` in the working directory, whose `schema` and `migrations.path` set the schema and the migrations folder; then the `prisma.schema` key in `package.json`; then `prisma/schema.prisma`. Without `migrations.path`, the migrations folder is `migrations/` beside the schema.
- schema shape: one `schema.prisma` file, or a folder of `.prisma` files when the config's `schema` names a folder.
- working directory: the folder holding `prisma.config.*`, else the one whose `package.json` declares `prisma`.
- client import: the `output` path of the schema's `generator` block when it sets one (Prisma 7's `prisma-client` generator requires it), else `@prisma/client`.

## 4. Connections

- URLs: check each in both `prisma.config.*` (its `datasource` block) and the schema's `datasource` block, since Prisma 6 declares them in the schema and Prisma 7 moves them to the config.
  - main: `url`, usually `env("DATABASE_URL")`.
  - direct: `directUrl`. When set, migrations connect through it instead of `url`, which is often a connection pooler.
  - shadow: `shadowDatabaseUrl`. Without it, `migrate dev` creates and drops a temporary shadow database on the main URL's server.
- connecting commands: `create without applying` and `apply` (the main or direct URL, and the shadow database), `status`, `deploy pending`, and `diff` with `--from-migrations` (it replays the migrations on the shadow database). The CLI check, `regenerate client`, and `--version` don't connect.
- connection-string quirks: in a Postgres connection string, a `host` query parameter overrides the host before it, and a path there is a unix socket. A SQLite `file:` URL is a local database file. A SQL Server string such as `sqlserver://db.example.com;password=hunter2` isn't a URL: `new URL()` returns `db.example.com;password=hunter2` as its hostname, and an uncaught parse failure prints the error's `input` field, which holds the whole string. Take the part before the first `;` as the host.

## 5. Migrations

- generates: yes
- format: sql
- name flag: `--name <name>` (or `-n`). Without a terminal and without `--name`, `migrate dev` names the migration an empty string.
- layout: `<migrations path>/<timestamp>_<name>/migration.sql`, with `migration_lock.toml` in the migrations folder.
- transactions: on Postgres, Prisma runs a multi-statement migration in one transaction, so a statement that can't run inside a transaction, such as `CREATE INDEX CONCURRENTLY`, must be alone in its own migration file (prisma/orm#14456).
- physical names: `@@map("name")` on a model or enum sets the table or type name; `@map("name")` on a field or enum value sets the column or value name. Without them, the Prisma name is the database name, case included. A schema `enum OrderStatus { … @@map("order_status") }` is the type `"order_status"`; a hand-written `CREATE TYPE "OrderStatus"` passes tests that mock the database, then fails against a real one with `type "order_status" does not exist`.

## 6. Commands

- create without applying: `npx prisma migrate dev --create-only --name <name>`. It first applies every migration already pending in the folder to the development database (6.19.3 and 7.10.0 call `applyMigrations` before `createMigration`), then writes the new one without applying it.
- apply: `npx prisma migrate dev --name <name>`, with the same name. On Prisma 7 it no longer runs `generate`.
- regenerate client: `npx prisma generate`. Run it after every apply.
- status: `npx prisma migrate status`
- status exit code: 1 both for pending, failed, or diverged migrations and for connection errors, so read the output. 0 with "Database schema is up to date!" means nothing is pending.
- deploy pending: `npx prisma migrate deploy`
- diff: on Prisma 7, `npx prisma migrate diff --from-migrations <migrations path> --to-schema <schema path> --script`, with the shadow database from `datasource.shadowDatabaseUrl` in the config (7.10.0 has no `--shadow-database-url` flag). On Prisma 6, `npx prisma migrate diff --from-migrations <migrations path> --to-schema-datamodel <schema path> --shadow-database-url "$<shadow variable>" --script`, with the variable loaded the way the project loads it, so the URL never appears in the command; 6.19.3 rejects `--to-schema` with `unknown or unexpected option: --to-schema` and exit 1. Run the Prisma 6 form only when the project declares its own shadow database URL (`shadowDatabaseUrl`), and never pass the main or direct URL's variable: Prisma's docs say it resets the shadow database at the start of `migrate dev`, deleting its data (unverified for `migrate diff`, so treat it the same). Without a separate shadow URL, skip the diff and say so. The shell expands `"$<shadow variable>"` before a wrapper such as `dotenv` loads it, so load the variable into the shell first or run the command inside the wrapper with `sh -c '…'`. If the CLI rejects a flag, skip the diff and say so: the identifier check doesn't depend on it.

## 7. Never run

- never run:
  - `npx prisma migrate reset`: drops the database and reapplies every migration, deleting the data.
  - `npx prisma db push`, in a project with a migrations folder: changes the schema without a migration, so the database no longer matches the migration history.
  - `npx prisma@<any version>`: a release other than the installed one (section 2).
- consent setting: `PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION`. Since 6.15, when Prisma detects an AI agent it refuses `migrate reset` unless this variable holds the user's consent. Only the user sets it.

## 8. Refusals and known failures

- refusals: without a terminal, `migrate dev` exits 130 on drift or when it needs a reset, and fails with an error saying the environment is non-interactive on a data-loss warning. The reset guardrail under `consent setting` is a refusal too.
- known failures:
  - `migrate dev` fails with "permission denied to create database": it needs a shadow database, and the database user can't create one. Tell the user that user needs Postgres's `CREATEDB` privilege, or the config needs a separate `shadowDatabaseUrl`.
  - The client isn't updated after `apply`: Prisma 7's `migrate dev` doesn't run `generate`; run `regenerate client`.

## 9. Risky-change notes

- Rename a column or table: renaming a field or model makes Prisma generate a drop and add, which loses the data; it never asks whether it's a rename. Two safer paths specific to Prisma: keep the old database name with `@map("old_name")` on the field (or `@@map` on the model), which needs no migration at all; or edit the generated file into `ALTER TABLE … RENAME COLUMN …` before applying. On a table with rows, `create without applying` stops on the drop's data-loss warning without a terminal and writes no file (section 8); then the `@map` path, or the user creating the migration in their own terminal, is the way through.
- Add a required column to an existing table: as in the table.
- Make a column of an existing table required: as in the table.
- Change a column's type: as in the table.
- Drop a column or table: as in the table. When `migrate dev` warns about data loss, that warning is a refusal without a terminal (section 8).
- Add an index to an existing table: Prisma generates a plain `CREATE INDEX "<name>" ON "<table>"("<column>")`. The safer path is `CREATE INDEX CONCURRENTLY` alone in its own migration file (section 5). When the generated file holds only that statement, editing it keeps it alone. squawk's concurrent-index rule fires on Prisma migrations, because they run in one transaction.
- Remove or rename an enum value: Prisma recreates the enum type, which fails while a row still holds the removed value.

After editing a generated file, it still has to use the `@@map` and `@map` names.

## 10. Permissions

- allowlist: for the project's `.claude/settings.json`. It covers only commands that change no database: the CLI check, `status`, and `regenerate client`. These rules apply in every session in the project, not only while this skill runs, so they also skip the skill's host check. Creating a migration (which applies pending migrations first), `diff` (which writes to the shadow database), applying, and deploying aren't listed and still ask.

  ```json
  {
    "permissions": {
      "allow": [
        "Bash(npx prisma migrate --help*)",
        "Bash(npx prisma migrate status*)",
        "Bash(npx prisma generate*)"
      ]
    }
  }
  ```

  A project that runs Prisma through its own scripts lists those instead, for example `Bash(pnpm db:status*)`. The host check's one-line script and the project's environment loader aren't listed: a rule broad enough to cover them would approve any script.
- other agents: use the agent's own way of approving commands, if it has one, with the same command list. Without one, every command asks.
