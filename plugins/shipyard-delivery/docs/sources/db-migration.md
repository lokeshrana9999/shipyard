# Sources: db-migration

Provenance for the rules in `skills/db-migration/`. Kept outside the skill folder so it never loads into context.

The skill was `prisma-workflow` until issue #29 split it into tool-independent rules (`SKILL.md`) and one adapter per tool (`references/tools/<tool>.md`); the decision is in `docs/adr/0001-one-migration-skill-with-tool-adapters.md`. The Prisma sections below back `references/tools/prisma.md`, and the Drizzle section backs the draft `references/tools/drizzle.md`. Notes written before the split say "the skill" for what is now the Prisma adapter.

## Prisma

- npm dist-tags (`latest` is 8.0.0-rc on 2026-09-27, and 8.0.0-rc.22 on 2026-10-10; 7.10.0 is the stable line): https://registry.npmjs.org/prisma
- CLI help and exit codes for 6.19.3, 7.10.0, 8.0.0-rc.22 and 8.1.0-dev.9: installed with `npm install --no-save --ignore-scripts prisma@<version>` on 2026-10-10 and run as `prisma --help`, `prisma migrate --help`, `prisma migrate dev --help`, `prisma migration --help`, `prisma db --help`.
- Prisma release status (7 recommended for production until 8 GA): https://www.prisma.io/docs/orm/release-status
- Prisma 8 migration model (`migration plan`, `db migrate`, no reset): https://www.prisma.io/docs/cli/migration-plan
- Upgrade to v7 (no auto-generate, no auto `.env`, `prisma-client` generator with required output): https://docs.prisma.io/docs/guides/upgrade-prisma-orm/v7
- Prisma config reference (schema and migrations path discovery): https://www.prisma.io/docs/orm/v7/reference/prisma-config-reference
- `migrate dev` non-interactive behavior (exit 130 on drift, error on data-loss warning, empty name without `--name`): https://github.com/prisma/prisma/blob/7.10.0/packages/migrate/src/commands/MigrateDev.ts
- Shadow database permissions: https://www.prisma.io/docs/orm/v7/prisma-migrate/understanding-prisma-migrate/shadow-database
- AI-agent guardrail on reset (`PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION`, since 6.15): https://www.prisma.io/docs/orm/v7/reference/prisma-cli-reference
- Prisma AGENTS.md guidance for databases: https://www.prisma.io/blog/agents-md-for-databases
- Customizing migrations, renames, expand and contract: https://www.prisma.io/docs/orm/v7/prisma-migrate/workflows/customizing-migrations
- `CREATE INDEX CONCURRENTLY` inside Prisma's transaction (orm#14456): https://github.com/prisma/orm/issues/14456
- squawk rules: https://squawkhq.com/docs/

### Specifics removed from the skill (as of 2026-09-27)

Facts true on this date that the skill then stated only as patterns. Recheck before relying on them.

- Supported versions: the skill was written against Prisma 6 and 7 (description said "Works with Prisma 6 and 7").
- Prisma 8 replaces the migrate workflow with `prisma migration plan` and `db migrate`, and has no reset; the skill stopped on version 8.
- npm `latest` was 8.0.0-rc; 7.10.0 was the stable line, recommended for production until 8 GA.
- Since Prisma 7, `migrate dev` no longer runs `prisma generate`; the client must be regenerated explicitly.
- Since Prisma 7, the CLI doesn't read `.env` on its own; `prisma.config.*` usually imports `dotenv/config`. The typical symptom is `DATABASE_URL` not found.
- `migrate dev` without a TTY exits with code 130 on drift or when a reset is needed, and errors saying the environment is non-interactive on a data-loss warning.
- `migrate dev` without a TTY and without `--name` names the migration an empty string.
- `prisma migrate status` exits 1 for pending, failed, or diverged migrations and for connection errors.
- Reset guardrail: since Prisma 6.15, Prisma blocks AI agents from `migrate reset` unless the user sets `PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION`.
- Shadow database failure message: "permission denied to create database"; fix is the Postgres `CREATEDB` privilege for the database user, or `shadowDatabaseUrl` in the config.
- Schema and migrations discovery keys: `prisma.config.*` `schema` and `migrations.path`; `package.json` `prisma.schema`.
- Runtime error for the hand-written enum example: `type "order_status" does not exist`.
- Migration linter used: squawk (`npx squawk-cli <file>`, Postgres only, no database needed); its concurrent-index rule fires on Prisma's single-transaction migrations.
- Prisma runs a multi-statement migration in one transaction, so Postgres `CREATE INDEX CONCURRENTLY` must be alone in its own migration file (orm#14456).
- Overlay example environment line was `npx dotenv -e .env -e .env.local -- <command>` with `.env.local` holding the dev `DATABASE_URL`; the lint line was "lint migrations with squawk: yes".

### Specifics removed from the skill (as of 2026-10-10)

Measured for the step 1 CLI check, which replaced the version read (issue #17).

- npm `latest` is 8.0.0-rc.22, so a bare `npx prisma` in a project without Prisma installed downloads the 8 release candidate. That is why step 1 confirms Prisma is a project dependency.
- 8.0.0-rc.22 is a new CLI (from the `prisma/prisma-cli` repo). `prisma --help` lists `auth project postgres bucket branch git service deploy <entry> dev <entry> contract db orm lsp migration init skills feedback telemetry`, with no `migrate` and no `generate`; `generate` is replaced by `contract emit`.
- On 8.0.0-rc.22, `prisma migrate --help`, `migrate dev --help`, and `migrate diff --help` print the root help to stderr (stdout is empty) and exit 0. In that root help, `dev` and `deploy` appear as top-level commands, and `status` and `diff` don't appear at all. That is why step 1 reads stdout and stderr together and requires the four names as subcommands of `migrate`.
- On 8.0.0-rc.22, every command the skill runs (`migrate dev --create-only`, `migrate dev`, `migrate status`, `migrate deploy`, `migrate diff`, `generate`) exits 2 with `CLI.UNKNOWN_COMMAND`, as JSON on stdout when not in a terminal, for example "No command registered for `migrate`, did you mean `migration`?".
- On 8.0.0-rc.22, top-level `prisma dev <entry>` and `prisma deploy <entry>` run or deploy an app on Prisma's hosted platform. Dropping the word `migrate` from a skill command would run one of them; that is why the skill says never to swap in a similarly named command.
- 8.0.0-rc.22 replaces migrations with `prisma migration` (`check graph list log new plan status show ref`) and `prisma db migrate`, with no reset and no diff.
- 8.1.0-dev.9 (the `dev` dist-tag) is the classic CLI from `prisma/orm` and lists `migrate dev reset deploy status resolve diff` like 7; the step 1 check passes on it, as it does on 6.19.3 and 7.10.0.
- The reset consent setting is `PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION` (see above). The skill stopped naming it; since #29 the Prisma adapter names it as its `consent setting`.
- `pnpm db:migrate:dev` was the skill's example of a wrapper command; it now lives only in `references/overlay-example.md` and `examples/nestjs-prisma/`.

Measured on 2026-10-10 (Node 22.22.0, prisma 7.10.0) for the step 1 host and CLI checks:

- With a `prisma.config.ts` that reads its datasource URL through `env()`, `prisma migrate --help` with that variable unset exits 1: `Failed to load config file … PrismaConfigEnvError: Cannot resolve environment variable: DATABASE_URL.` A project that loads its environment only through a wrapper script hits this, so step 1 treats a config or environment error as a loading problem, not an unsupported release.
- In a project that declares `prisma` in `package.json` but hasn't installed it, `npx --yes prisma --version` downloads and runs 8.0.0-rc.22. That is why step 1 checks the CLI is installed, not only declared.
- `new URL("sqlserver://db.example.com;password=hunter2").hostname` returns `db.example.com;password=hunter2`, and an uncaught parse failure prints the error's `input` field, which holds the whole string. That is why the host check uses a script that prints only the host or a fixed error word.

Not measured, from the Prisma schema and Postgres connection-string references: Prisma 6 schemas can set `directUrl` (used by migrate instead of `url`) and `shadowDatabaseUrl` in the datasource block, and Prisma 7 moves the URLs to `prisma.config.*`. A Postgres connection string's `host` query parameter overrides the host before it, and a path there is a unix socket.

### Measured for the adapter split (2026-10-10)

Run against the 6.19.3 and 7.10.0 installs above, with stdin from `/dev/null` and no database.

- `migrate diff --help` differs between the two. 6.19.3 lists `--from-url`/`--to-url`, `--from-schema-datamodel`/`--to-schema-datamodel`, `--from-schema-datasource`/`--to-schema-datasource`, `--from-migrations`/`--to-migrations`, `--from-local-d1`/`--to-local-d1`, and `--shadow-database-url` ("only required if using --from-migrations or --to-migrations"). 7.10.0 lists `--from-schema`/`--to-schema`, `--from-migrations`/`--to-migrations`, and `--from-config-datasource`/`--to-config-datasource`, with no URL flags and no shadow database flag. So the adapter's `diff` has one form per major version.
- On 6.19.3, `prisma migrate diff --from-empty --to-schema prisma/schema.prisma --script` exits 1 and prints `unknown or unexpected option: --to-schema` and the help; with `--to-schema-datamodel` it exits 0 and prints the SQL.
- On both, an unknown command (`prisma frobnicate`, `prisma migrate frobnicate`) prints nothing on stdout, then `! Unknown command "frobnicate"` and the help on stderr, and exits 1.
- `migrate dev --help` lists `-n, --name` and `--create-only` on both. 6.19.3 also lists `--skip-generate` ("Skip triggering generators"); 7.10.0 doesn't, and adds `--url`.

### Moved into the Prisma adapter (#29)

Everything Prisma-specific in the merged `prisma-workflow` (`d647ae2`) moved to `references/tools/prisma.md`: the commands (`npx prisma migrate --help`, `migrate dev --create-only --name`, `migrate dev --name`, `generate`, `migrate status`, `migrate deploy`, `migrate diff`), the `migrate --help` expectations, `CLI.UNKNOWN_COMMAND`, the `env()` load error, `prisma.config.*` and `package.json` discovery, `url`, `directUrl`, and `shadowDatabaseUrl`, `@@map` and `@map`, `migrate reset` and `db push`, the consent variable, the shadow database's `CREATEDB` failure, `status` exit codes, the empty name without `--name`, `node_modules/.bin`, and `npx` fetching `latest` when Prisma isn't installed. The Prisma-only cells of `risky-changes.md` (rename as drop and add, enum recreation, a concurrent index alone in its file) moved to the adapter's risky-change notes. The skill's old `allowed-tools` Bash patterns became the adapter's `allowlist`, less the three the review round dropped (below).

### Checked in the #29 review round (2026-10-10)

Read from the 6.19.3 (`build/index.js`) and 7.10.0 (`build/cli.js`) bundles installed above, and from the shadow database page cited above. Not run against a database.

- `MigrateDev.parse` runs `devDiagnostic()`, exits 130 when it needs a reset, then calls `applyMigrations()` and prints `The following migration(s) have been applied`, and only then calls `createMigration({…, draft: !!args["--create-only"]})`. Nothing guards `applyMigrations()` with `--create-only`, so `migrate dev --create-only` applies every migration already pending in the folder before it writes the new one. That is why the adapter says so under `create without applying`, why step 3 runs `status` first and takes pending migrations through step 4, and why the allowlist no longer lists `migrate dev --create-only`.
- In the same function, data-loss warnings without a terminal throw the non-interactive error before the `--create-only` branch, so no migration file is written. That backs the Drop row's refusal in the adapter's risky-change notes.
- The shadow database page says that shadow databases configured through `shadowDatabaseUrl` "are not dropped, but are reset at the start of the migrate dev command", and: "Do not use the exact same values for url and shadowDatabaseUrl as that might delete all the data in your database." So the Prisma 6 `diff`, which takes `--shadow-database-url`, runs only when the project declares its own shadow URL and never with the main or direct one. Not checked: whether `migrate diff --from-migrations` resets the shadow database it's given the same way.
- The allowlist dropped `npx prisma --version` (the skill no longer runs it), `migrate dev --create-only` (it applies pending migrations), and `migrate diff` (it writes to the shadow database). Rules in a project's `.claude/settings.json` apply in every session, so a listed command skips the skill's host check; only commands that change no database stay listed.

## Drizzle

Measured on 2026-10-10 for the draft adapter, outside the repo, with Node 22.22.0 and npm 10.9.4 on Linux. Database: `@electric-sql/pglite` 0.5.8, an in-process Postgres with no server, through drizzle-kit's `driver: 'pglite'`. `pg` 8.23.1 was added only to measure connection failures. Every command ran with stdin from `/dev/null` (not a TTY) unless marked "under a TTY", which means `script -qfec "<cmd>" /dev/null` with keystrokes piped in. Output below is verbatim except for stripped ANSI colours, `$DIR` for the test folder, and stack traces cut after the first frame. The raw captures stayed in a scratch folder and aren't committed.

- npm dist-tags (`npm view drizzle-kit dist-tags`, `npm view drizzle-orm dist-tags`): drizzle-kit `latest: '0.31.11'` (published 2026-09-21), `rc: '1.0.0-rc.4'`, `beta: '1.0.0-beta.22'`; drizzle-orm `latest: '0.45.4'` (2026-10-08). About 50 more branch tags all point at 1.0.0 prereleases.
- Install: `npm install --no-save --ignore-scripts drizzle-kit@0.31.11 drizzle-orm@0.45.4 @electric-sql/pglite@0.5.8`. 1.0.0-rc.4 needs `--legacy-peer-deps` (`peerOptional effect@">=4.0.0-beta.83 || >=4.0.0" from drizzle-orm@1.0.0-rc.4`).
- drizzle-kit and drizzle-orm source read alongside: `node_modules/drizzle-kit/bin.cjs` (config discovery, `assertCollisions`, `renderWithTask`, bundled dotenv 16.5.0) and `node_modules/drizzle-orm/pg-core/dialect.js` (`PgDialect.migrate`).

### Version, help, unknown command

```
$ npx drizzle-kit --version
[exit 0]
drizzle-kit: v0.31.11
drizzle-orm: v0.45.4
```

Without drizzle-orm installed, the second line is `drizzle-orm:` with nothing after it, and `generate` prints `Please install latest version of drizzle-orm`, exit 1. On 1.0.0-rc.4: `drizzle-kit: v1.0.0-rc.4` / `drizzle-orm: v1.0.0-rc.4`.

`npx drizzle-kit --help` (exit 0) lists `generate migrate introspect push studio up check drop export`. 1.0.0-rc.4 lists `generate migrate pull push studio up check export skills mcp`.

```
$ npx drizzle-kit status
[exit 1]
[stderr]
Unknown command: 'status'.
Type '--help' to get help on the cli.

$ npx drizzle-kit migrate --bogus
[exit 1]
[stderr]
Unrecognized options for command 'migrate': --bogus
```

### Config and environment

Config discovery (`drizzleConfigFromFile`): `drizzle.config.ts`, else `.js`, else `.json`, in the working directory; `--config` overrides. Keys (`configCommonSchema`): `dialect`, `schema`, `out` (default `drizzle`), `breakpoints` (default true), `driver`, `dbCredentials`, `casing`, `migrations: { table, schema, prefix }`, and others. For `generate`, only `--name`, `--custom`, and `--prefix` combine with the config file; `--out`, `--schema`, `--dialect`, `--driver`, `--casing`, or `--breakpoints` switch to flags-only mode:

```
$ npx drizzle-kit generate --out drizzle_none --name p_none --prefix none     (drizzle.config.ts present)
[exit 1]
Error  Please provide required params:
    [x] schema: undefined
    [x] dialect: undefined
    [✓] out: 'drizzle_none'
```

`bin.cjs` runs dotenv's `config.js` at start-up, so `./.env` loads with no import in the config:

```
$ npx drizzle-kit migrate          (DATABASE_URL unset, no .env)
[exit 1]
Error  Please provide required params for Postgres driver:
    [x] url: undefined

$ npx drizzle-kit migrate          (.env holds DATABASE_URL=./pgdata; config doesn't import dotenv)
[exit 0]
[⣷] applying migrations...[✓] migrations applied successfully!
```

With only `.env.local` holding the URL, `migrate` fails the same way; `DOTENV_CONFIG_PATH=.env.local` makes it pass. `DATABASE_URL=./pgdata-from-shell npx drizzle-kit migrate` with `.env` naming another folder created only `pgdata-from-shell`: the shell wins.

### generate: layout, names, rename prompt

```
$ npx drizzle-kit generate --name init
[exit 0]
No config path provided, using default 'drizzle.config.ts'
Reading config file '$DIR/drizzle.config.ts'
1 tables
users 2 columns 0 indexes 0 fks

[✓] Your SQL migration file ➜ drizzle/0000_init.sql 🚀
```

It wrote `drizzle/0000_init.sql`, `drizzle/meta/0000_snapshot.json`, and `drizzle/meta/_journal.json`, whose entry is `{"idx": 0, "version": "7", "when": 1791652060797, "tag": "0000_init", "breakpoints": true}`. It ran with `DATABASE_URL` unset. Without `--name` the file was `0000_strong_silverclaw.sql`. Statements are joined by `--> statement-breakpoint`.

Rename `fullName: text('full_name')` to `displayName: text('display_name')`, without a TTY:

```
$ npx drizzle-kit generate --name rename_col
[exit 0]
[stdout]
No config path provided, using default 'drizzle.config.ts'
Reading config file '$DIR/drizzle.config.ts'
[stderr]
Error: Interactive prompts require a TTY terminal (process.stdin.isTTY or process.stdout.isTTY is false). This can happen when running in CI, piped input, or non-interactive shells.
    at render10 ($DIR/node_modules/drizzle-kit/bin.cjs:1450:31)
```

Nothing was written. Under a TTY it asks `Is display_name column in users table created or renamed from another column?` with `+ display_name create column` preselected; Enter writes `ADD COLUMN "display_name" text;` and `DROP COLUMN "full_name";`, and Down then Enter writes `ALTER TABLE "users" RENAME COLUMN "full_name" TO "display_name";`. A table rename behaves the same, and "create" writes `CREATE TABLE "articles" …` and `DROP TABLE "posts" CASCADE;`.

### Risky changes, as generated

- Required column and index on an existing table: `ALTER TABLE "users" ADD COLUMN "email" text NOT NULL;--> statement-breakpoint` / `CREATE INDEX "users_email_idx" ON "users" USING btree ("email");`
- Make required, change type, concurrent index: `ALTER TABLE "users" ALTER COLUMN "nickname" SET NOT NULL;`, `ALTER TABLE "users" ALTER COLUMN "age" SET DATA TYPE integer;`, `CREATE INDEX CONCURRENTLY "users_name_idx" ON "users" USING btree ("name");` (from `.concurrently()`). Applying through drizzle-orm's migrator failed with `column "nickname" of relation "users" contains null values`, then `column "age" cannot be cast automatically to type integer` even after the bad value was fixed.
- Drops, with no prompt or warning: `DROP TABLE "posts" CASCADE;--> statement-breakpoint` / `ALTER TABLE "users" DROP COLUMN "nickname";`
- Remove an enum value: `ALTER TABLE "users" ALTER COLUMN "status" SET DATA TYPE text;`, `DROP TYPE "public"."status";`, `CREATE TYPE "public"."status" AS ENUM('active', 'inactive');`, `ALTER TABLE "users" ALTER COLUMN "status" SET DATA TYPE "public"."status" USING "status"::"public"."status";`, which failed with `invalid input value for enum status: "banned"` while a row held it.
- `casing: 'snake_case'` turned `createdAt: timestamp()` into `"created_at" timestamp`.

### migrate: transactions, tracking, failures

```
$ npx drizzle-kit migrate          (pending 0002_email_required on a users table holding one row)
[exit 1]
[stdout]
No config path provided, using default 'drizzle.config.ts'
Reading config file '$DIR/drizzle.config.ts'
[⣷] applying migrations...[⣷] applying migrations...
[stderr]
```

Nothing else is printed: `renderWithTask` catches the error and calls `process.exit(1)` before the handler's `console.error`. drizzle-orm's `migrate()`, called directly, shows `ERROR: Failed query: ALTER TABLE "users" ADD COLUMN "email" text NOT NULL;` / `params:  | cause: column "email" of relation "users" contains null values`. With the `pg` driver and no server, a refused port, an unknown host (`db.example.invalid`), and a malformed URL all gave the same two spinner lines after `Using 'pg' driver for database querying`, exit 1, and printed no URL or password.

- Two pending files, the second failing: afterwards `__drizzle_migrations` held only the earlier rows and the first file's table didn't exist. One transaction covers the whole run (`session.transaction` wraps the loop in `PgDialect.migrate`).
- `CREATE INDEX CONCURRENTLY` alone in its own migration, every earlier one applied: exit 1, and the direct migrator shows `cause: CREATE INDEX CONCURRENTLY cannot run inside a transaction block`.
- Nothing pending: `[⣷] applying migrations...[✓] migrations applied successfully!`, exit 0, the same line as a run that applied migrations.
- Tracking: `drizzle.__drizzle_migrations` rows like `{"id":1,"hash":"91738c1b…","created_at":1791652060797}`; `hash` equals `sha256sum drizzle/0000_init.sql`, `created_at` the journal's `when`. Config `migrations: { table: 'schema_history', schema: 'public' }` moved it to `public.schema_history`.
- An applied file edited afterwards: `migrate` exit 0, `check` `Everything's fine 🐶🔥` exit 0; the added statement never ran.
- A pending entry whose `when` is older than the newest applied one: `migrate` exit 0 with the success line, and the migration never ran. `check`:

```
$ npx drizzle-kit check
[exit 0]
[stdout]
… Everything's fine 🐶🔥
[stderr]
Warning: 0004_late_branch (idx: 4, when: 1791652200000) follows 0003_email_required (idx: 3, when: 1791652285184) in the journal, but its timestamp is not greater. If the earlier entry has already been applied, the migrator will skip this entry. Journal timestamps must strictly increase in entry order.
```

- Two snapshots with the same parent: `check` exits 1, and `generate` prints `Error: [drizzle/meta/0004_snapshot.json, drizzle/meta/0005_snapshot.json] are pointing to a parent snapshot: drizzle/meta/0004_snapshot.json/snapshot.json which is a collision.` on stdout, writes nothing, and exits 0.

### push, drop, custom migrations

- `push` with an additive change, no TTY: `[✓] Changes applied`, exit 0, with no migration file and no tracking row. With a dropped column: ` Warning  Found data-loss statements:` / `· You're about to delete age column in users table with 2 items` / `THIS ACTION WILL CAUSE DATA LOSS AND CANNOT BE REVERTED` / `Do you still want to push changes?`, then the TTY error on stderr, exit 0, and the column still there. `push --help` lists `--force  Auto-approve all data loss statements`; not run.
- `drop` without a TTY: `Interactive prompts require a TTY terminal …`, exit 1. Under a TTY it deletes the chosen migration's SQL, snapshot, and journal entry, and leaves the database alone.
- `generate --custom --name probe`: `Prepared empty file for your custom SQL migration!`, a one-line file `-- Custom SQL migration file, put your code below! --`, a snapshot copied from the previous one, and a journal entry. A pending schema change wasn't included.

### 1.0.0-rc.4, for contrast

One folder per migration (`drizzle/20261010171629_init/migration.sql` and `snapshot.json`, no journal). A rename without a TTY exits 2:

```
missing_hints: 1 unresolved decisions

1. Rename or create  —  column  public.users.display_name
   Add to --hints:
     { "type": "rename", "kind": "column", "from": ["<schema>", "<table>", "<old_name>"], "to": ["public", "users", "display_name"] }
     OR
     { "type": "create", "kind": "column", "entity": ["public", "users", "display_name"] }

Re-run with --hints '<json-array>'. Exit code 2.
```

A failing `migrate` prints the database error (`[✗] Error during migration:` / `Failed query: …`) and exits 1, still rolling back every pending migration together. The tracking table gains `name` and `applied_at`.

### Not verified

- No Postgres server was run; transaction scope on a server comes from the drizzle-orm source and the PGlite runs.
- Not run: `push --force`, `push --strict`, `studio`, `introspect`/`pull`, `up` on an old-format folder, `breakpoints: false`, `migrations.prefix` in the config, and `--config` combined with another `generate` flag (the source prints `You can't use both --config and other cli options for generate command`).
- Whether `migrate` holds a lock against concurrent runs.
- MySQL, SQLite, Turso, SingleStore, and Gel.
- 1.0.0-rc.4: how applied migrations are matched, whether an edited or out-of-order migration is detected, and `check`'s output.

## Decisions (as of 2026-10-10)

- The settings file's `tool` wins; otherwise only adapters with `enabled: yes` are detected, through their `load-when` lines (the form pr-review's catalogs use). None or several matching means asking the user, as flow-diagram does for an unknown destination.
- A draft adapter loads only when its tool is named, by the settings file's `tool` or by the user when detection asks, and then only after the user says to use it for that run.
- An adapter is enabled only with a `status` command, among other fields. The Drizzle draft has none, which is one reason it stays a draft.
- `.claude/shipyard/prisma-workflow.md` is still read as the settings file, with `tool: prisma`, when `db-migration.md` is missing, and the skill asks once for the rename, in the reply that reports how the run ended. When both files exist, the skill reads `db-migration.md`, also honours the old file's `never-write hosts`, and asks for the old file to be merged and deleted.
- `never-write hosts` is checked before anything else in the host check, so it wins over a loopback address and over `allowed hosts`.
- A tool with no adapter file gets no checks: the skill says so and hands the request back to the normal session.
- An adapter can be enabled with fields taken from the tool's docs or source where measuring them needs a database server, as long as each is recorded here. The Prisma adapter's `directUrl`, `shadowDatabaseUrl`, `host` query parameter, transactions note, and `@map` rename path are such fields.

## Known gaps

- The step 1 host check reads the hostname. A tunnel or proxy listening on a loopback address that forwards to staging or production passes it, and a `never-write hosts` entry can't see through it. Don't point a development environment file at such a tunnel; keep it in a separate file or wrapper the skill isn't told to load.
- The skill's `allowed-tools` is only `Read, Glob, Grep`, so in default permission mode every CLI call asks for permission unless the project pastes the adapter's allowlist into its `.claude/settings.json`. The allowlist lists only commands that change no database, since its rules apply in every session and skip the host check. Creating, applying, and deploying a migration, `diff`, the host check's one-line script, and the project's environment loader always ask; a rule broad enough to cover the last two would approve any script.
- The gate treats every table that existed before the migration as large and full, so it stops for most index and required-column changes on a seeded development database. The user answers at the stop when the table is small.
- No shipped adapter has `generates: no`, so the hand-written-by-design branch has no eval.
