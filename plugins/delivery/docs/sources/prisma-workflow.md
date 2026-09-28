# Sources: prisma-workflow

Provenance for the rules in `skills/prisma-workflow/`. Kept outside the skill folder so it never loads into context.

- npm dist-tags (`latest` is 8.0.0-rc on 2026-09-27; 7.10.0 is the stable line): https://registry.npmjs.org/prisma
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
