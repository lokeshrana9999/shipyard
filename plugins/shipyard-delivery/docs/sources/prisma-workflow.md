# Sources: prisma-workflow

Provenance for the rules in `skills/prisma-workflow/`. Kept outside the skill folder so it never loads into context.

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

## Specifics removed from the skill (as of 2026-09-27)

Facts true on this date that the skill now states only as patterns. Recheck before relying on them.

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

## Specifics removed from the skill (as of 2026-10-10)

Measured for the step 1 CLI check, which replaced the version read (issue #17).

- npm `latest` is 8.0.0-rc.22, so a bare `npx prisma` in a project without Prisma installed downloads the 8 release candidate. That is why step 1 confirms Prisma is a project dependency.
- 8.0.0-rc.22 is a new CLI (from the `prisma/prisma-cli` repo). `prisma --help` lists `auth project postgres bucket branch git service deploy <entry> dev <entry> contract db orm lsp migration init skills feedback telemetry`, with no `migrate` and no `generate`; `generate` is replaced by `contract emit`.
- On 8.0.0-rc.22, `prisma migrate --help`, `migrate dev --help`, and `migrate diff --help` print the root help to stderr (stdout is empty) and exit 0. In that root help, `dev` and `deploy` appear as top-level commands, and `status` and `diff` don't appear at all. That is why step 1 reads stdout and stderr together and requires the four names as subcommands of `migrate`.
- On 8.0.0-rc.22, every command the skill runs (`migrate dev --create-only`, `migrate dev`, `migrate status`, `migrate deploy`, `migrate diff`, `generate`) exits 2 with `CLI.UNKNOWN_COMMAND`, as JSON on stdout when not in a terminal, for example "No command registered for `migrate`, did you mean `migration`?".
- On 8.0.0-rc.22, top-level `prisma dev <entry>` and `prisma deploy <entry>` run or deploy an app on Prisma's hosted platform. Dropping the word `migrate` from a skill command would run one of them; that is why the skill says never to swap in a similarly named command.
- 8.0.0-rc.22 replaces migrations with `prisma migration` (`check graph list log new plan status show ref`) and `prisma db migrate`, with no reset and no diff.
- 8.1.0-dev.9 (the `dev` dist-tag) is the classic CLI from `prisma/orm` and lists `migrate dev reset deploy status resolve diff` like 7; the step 1 check passes on it, as it does on 6.19.3 and 7.10.0.
- The reset consent setting is `PRISMA_USER_CONSENT_FOR_DANGEROUS_AI_ACTION` (see above); the skill no longer names it.
- `pnpm db:migrate:dev` was the skill's example of a wrapper command; it now lives only in `references/overlay-example.md` and `examples/nestjs-prisma/`.

## Known gaps

- The step 1 host check reads the hostname. A tunnel or proxy listening on a loopback address that forwards to staging or production passes it, and a `never-write hosts` entry can't see through it. A project using one should keep the tunnel's real target out of its development environment files.
- The host check needs a one-line script to parse the connection string (for example `node -e`), and loading the project's environment may need its wrapper command. Neither is in `allowed-tools`, since a pattern broad enough to cover them would pre-approve any script, so in default permission mode that step asks for permission.
- The gate treats every table that existed before the migration as large and full, so it stops for most index and required-column changes on a seeded development database. The user answers at the stop when the table is small.
