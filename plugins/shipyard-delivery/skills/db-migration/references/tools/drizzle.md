# Drizzle adapter: draft, not enabled

enabled: no
releases: drizzle-kit 0.31.11 with drizzle-orm 0.45.4 (npm `latest` on 2026-10-10), Postgres only, measured on PGlite 0.5.8 (in-process Postgres, no server). Not measured: MySQL, SQLite, Turso, SingleStore, Gel, and a Postgres server. The 1.0.0 release candidates differ; see 1.0.0 release candidates.

Detection skips this file. It stays a draft until it has its own evals and the gaps under "Why it isn't enabled" have an answer. Anything marked unverified wasn't run.

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
- Why it isn't enabled
- 1.0.0 release candidates
- Unverified

## 1. Detection

- load-when: `package.json contains "drizzle-kit"`, `drizzle.config.*`
- schema files: `**/schema.ts`, `**/schema/*.ts` (guesses; the real list is the config's schema key, which takes a file, a folder, or an array)
- migration files: `**/drizzle/*.sql` (the default out folder; the config's out key changes it)
- dependency: `drizzle-kit` (the CLI, usually in `devDependencies`) and `drizzle-orm` in `package.json`. Without `drizzle-orm`, `generate` prints `Please install latest version of drizzle-orm` and exits 1.
- installed CLI: `node_modules/.bin/drizzle-kit`
- version without a shell: `version` in `node_modules/drizzle-kit/package.json`, else the `drizzle-kit` entry in the lockfile, else the range declared for `drizzle-kit` in `package.json` (say it's a declared range, not the installed release).

## 2. Running

- invoke: the package manager's runner for the installed CLI, written below as `npx drizzle-kit`. npm `latest` is 0.31.11, but the `rc` and `beta` tags are 1.0.0 builds with a different folder layout and output, so never `npx drizzle-kit@<version>`.
- environment: 0.31.11 bundles dotenv and loads `./.env` from the working directory on its own, so the config needs no dotenv import. It doesn't read `.env.local`. `DOTENV_CONFIG_PATH` names another file, and a variable already set in the shell wins over `.env`.
- CLI check: `npx drizzle-kit --version`, which loads no config and connects to nothing. Pass: `drizzle-kit: v0.31.<n>` on the first line and a `drizzle-orm:` version on the second (measured: `v0.31.11` and `v0.45.4`, exit 0). Fail: a 1.x version, such as `drizzle-kit: v1.0.0-rc.4` (different layout, see 1.0.0 release candidates), or an empty second line, which means `drizzle-orm` isn't installed. `--help` doesn't tell 0.31 from 1.0: both list `generate`, `migrate`, `push`, and `check`.
- unknown command: `Unknown command: '<name>'.` then `Type '--help' to get help on the cli.` on stderr, exit 1. An unknown flag prints `Unrecognized options for command '<command>': --<flag>`, exit 1.
- environment error: `Error  Please provide required params for Postgres driver:` then `[x] url: undefined` on stdout, exit 1 (`[x] url: ''` when the variable is set but empty).

## 3. Paths

- discovery: the config in the working directory, `drizzle.config.ts`, else `drizzle.config.js`, else `drizzle.config.json` (no `.mjs` or `.mts`); `--config <path>` overrides it. Its `schema` key sets the schema, and `out` the migrations folder (default `drizzle`). Without a config, `generate` prints `No config path provided, using default 'drizzle.config.json'` and `<dir>/drizzle.config.json file does not exist`, exit 1.
- schema shape: a file, a folder, or an array of them.
- working directory: the folder holding `drizzle.config.*`.
- client import: none. There's no generated client; application code imports the tables from the schema module.

## 4. Connections

- URLs: `dbCredentials.url` in the config, usually `process.env.DATABASE_URL`. There's no shadow database. With `driver: 'pglite'`, the URL is a local data directory such as `./pgdata`. Unverified: `dbCredentials` written as separate host, port, user, and password fields (the `push` help lists those flags).
- connecting commands: `migrate` and `push` (measured). `introspect` (alias `pull`) and `studio` take connection flags in their help (unverified). `generate` ran with the URL unset; `check` printed no driver line with an unreachable URL; `drop` only deletes files. `up` and `export` take no connection flags (unverified).
- connection-string quirks: the Postgres rules apply as for any client (a `host` query parameter overrides the host before it, and a path there is a unix socket); unverified for drizzle's drivers. A failing `migrate` printed neither the URL nor the password, for a refused port, an unknown host, and a malformed URL. When a config error shows a URL, the source masks the password as `****` (unverified).

## 5. Migrations

- generates: yes
- format: sql. Statements are separated by `--> statement-breakpoint` lines, which the migrator splits on (config `breakpoints`, default true).
- name flag: `--name <name>`; `--name init` gives `0000_init.sql`. Without it the name is random, such as `0000_strong_silverclaw.sql`. `--prefix index|timestamp|unix|supabase|none` sets the numbering (default `index`); mixing prefixes in one folder makes the next `generate` and `check` report a snapshot collision.
- layout: `<out>/<prefix>_<name>.sql`, `<out>/meta/<prefix>_snapshot.json`, and `<out>/meta/_journal.json`, whose entries hold `idx`, `version`, `when` (milliseconds), `tag`, and `breakpoints`. Snapshots chain through `id` and `prevId`. Only `.sql` files listed in the journal run. Applied migrations are recorded in `drizzle.__drizzle_migrations (id serial, hash text, created_at bigint)`: `hash` is the SHA-256 of the file, `created_at` the journal's `when`. The config's `migrations.table` and `migrations.schema` move it.
- transactions: `migrate` runs every pending migration in one transaction, so a failure in a later file rolls back the earlier ones (measured). A statement that can't run inside a transaction, such as `CREATE INDEX CONCURRENTLY`, can't run through `migrate` at all, even alone in its own file: `cannot run inside a transaction block`.
- physical names: the name string given to the column builder (`text('display_name')`), or, without one, the key converted by the config's `casing` (`casing: 'snake_case'` turns `createdAt` into `created_at`). A table's name is `pgTable`'s first argument. Unverified: an enum's name as `pgEnum`'s first argument.

## 6. Commands

- create without applying: `npx drizzle-kit generate --name <name>`. It never connects, so it applies nothing that's pending. Pass no `--out`, `--schema`, or `--dialect` with it: any of them makes `generate` ignore `drizzle.config.ts` and fail on the missing parameters. `generate --custom --name <name>` writes an empty SQL file (`-- Custom SQL migration file, put your code below! --`) with a snapshot and journal entry, for SQL the tool can't generate; it doesn't diff the schema.
- apply: `npx drizzle-kit migrate`. It takes no name and applies every pending migration, not only the new one.
- regenerate client: none; there's no generated client.
- status: none. `drizzle-kit status` is an unknown command, and `migrate` prints the same `migrations applied successfully!` whether it applied nothing or several migrations.
- status exit code: none.
- deploy pending: `npx drizzle-kit migrate`, the same command as apply.
- diff: none. `export` prints the whole schema as SQL from an empty database, not a diff against the migrations. `npx drizzle-kit check` validates the folder without connecting: exit 1 for a snapshot collision; an out-of-order journal only warns on stderr, exit 0.

## 7. Never run

- never run:
  - `npx drizzle-kit push`: changes the database directly, with no migration file and no tracking row. Without a terminal it applies non-destructive changes silently. `--force` approves data loss (from its help; not run).
  - `npx drizzle-kit drop`: deletes a migration's SQL, snapshot, and journal entry, which breaks the history if that migration was applied. Without a terminal it exits 1.
  - `npx drizzle-kit@<any version>`: a release other than the installed one.
- consent setting: none seen in 0.31.11's help or output (unverified: the source wasn't searched for one).

## 8. Refusals and known failures

- refusals:
  - A renamed column or table makes `generate` ask whether it was created or renamed. Without a terminal it prints `Error: Interactive prompts require a TTY terminal (process.stdin.isTTY or process.stdout.isTTY is false). …` and a stack trace on stderr, writes nothing, and exits 0. Treat that text as a refusal whatever the exit code. Under a terminal it waits, and the preselected answer is "create".
  - `push` on a data-losing change prints the warning, then the same TTY error, applies nothing, and exits 0.
  - `drop` without a terminal exits 1.
- known failures:
  - A failing `migrate` prints only `[⣷] applying migrations...` and exits 1, for SQL errors, refused connections, unknown hosts, and malformed URLs alike; the cause is swallowed. Every pending migration was rolled back. The real error shows only when drizzle-orm's `migrate()` is called directly.
  - A pending journal entry whose `when` is older than the newest applied one (after merging a branch, for example) is skipped silently: `migrate` exits 0 with the success line. `check` warns `Warning: <tag> (idx: <n>, when: <ms>) follows <tag> … but its timestamp is not greater.` on stderr and exits 0.
  - An applied file edited afterwards is never detected, by `migrate` or `check`.
  - Two snapshots with the same parent: `generate` prints `Error: [<snapshots>] are pointing to a parent snapshot: … which is a collision.` on stdout, writes nothing, and exits 0; `check` exits 1.
  - No Postgres driver installed: `To connect to Postgres database - please install either of 'pg', 'postgres', '@neondatabase/serverless' or '@vercel/postgres' drivers`, exit 1.

## 9. Risky-change notes

- Rename a column or table: `generate` asks, and without a terminal refuses with exit 0 (section 8). Under a terminal, the preselected "create" writes `ADD COLUMN` and `DROP COLUMN` (or `CREATE TABLE` and `DROP TABLE … CASCADE`), losing the data; choosing rename writes `ALTER TABLE "users" RENAME COLUMN "full_name" TO "display_name";`. The safer path is for the user to run `generate` in their own terminal and choose rename. Unverified: renaming only the TypeScript key and keeping the database name string needs no migration.
- Add a required column to an existing table: `ADD COLUMN "email" text NOT NULL` with no default, which fails on a table with rows: `column "email" of relation "users" contains null values`.
- Make a column of an existing table required: `ALTER COLUMN "nickname" SET NOT NULL`, which fails while a row is null.
- Change a column's type: `ALTER COLUMN "age" SET DATA TYPE integer` with no `USING` clause, which fails from text to integer even on clean data: `column "age" cannot be cast automatically to type integer`. Editing the file to add `USING "age"::integer` applied; a later `generate` didn't notice the edit.
- Drop a column or table: `ALTER TABLE … DROP COLUMN …` or `DROP TABLE "posts" CASCADE;`, with no prompt and no warning.
- Add an index to an existing table: a plain `CREATE INDEX "users_email_idx" ON "users" USING btree ("email");`. `.concurrently()` in the schema emits `CREATE INDEX CONCURRENTLY`, which `migrate` can't run (section 5), so there's no measured way to build the index without blocking writes through drizzle-kit. Stop and let the user choose.
- Remove or rename an enum value: the column is cast to text, the type dropped and recreated, and the column cast back, which fails with `invalid input value for enum status: "banned"` while a row holds the removed value. Adding a value is `ALTER TYPE … ADD VALUE`.

## 10. Permissions

- allowlist: none while this is a draft. When it's enabled, the candidates are `Bash(npx drizzle-kit --version)`, `Bash(npx drizzle-kit check*)`, and `Bash(npx drizzle-kit generate --name *)`; `generate` doesn't connect.
- other agents: use the agent's own way of approving commands, if it has one. Without one, every command asks.

## Why it isn't enabled

- There's no status command, so step 6 can't confirm nothing is pending.
- A failing `migrate` hides the database error, and a skipped out-of-order migration reports success.
- The rename refusal exits 0, so only its text marks it.
- A concurrent index can't run through `migrate`.
- `migrate` applies every pending migration, and with no status command step 3 can't list them, so a migration already in the folder is applied without step 4's review.
- No eval covers it.

## 1.0.0 release candidates

Measured on 1.0.0-rc.4 (the `rc` tag, which needs `--legacy-peer-deps` to install), for contrast:

- One folder per migration, `drizzle/<timestamp>_<name>/migration.sql` and `snapshot.json`, with no `meta/` and no journal.
- `--help` lists `generate migrate pull push studio up check export skills mcp`; `introspect` and `drop` are gone from it.
- A rename without a terminal exits 2 with a `missing_hints` message and the JSON to pass to `--hints`; re-running with the rename hint writes `RENAME COLUMN`.
- A failing `migrate` prints the database error and exits 1. It still runs every pending migration in one transaction.
- The tracking table gains `name` and `applied_at` columns.

## Unverified

- No Postgres server was run. The `pg` driver was measured only for failures. Transaction scope on a server comes from the drizzle-orm source and the PGlite runs.
- Not run: `push --force`, `push --strict`, `studio`, `introspect`/`pull`, `up` on an old-format folder, `breakpoints: false`, and `migrations.prefix` in the config.
- Whether `migrate` holds a lock against concurrent runs.
- The error for `--config` combined with another flag (`You can't use both --config and other cli options for generate command`), read in the source.
- 1.0.0-rc.4: how applied migrations are matched, whether an edited or out-of-order migration is detected, and `check`'s output.
