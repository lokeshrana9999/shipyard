# Project settings example

A project keeps this at `.claude/shipyard/prisma-workflow.md`. The values below are illustrative. Every setting is optional; anything left out is discovered as SKILL.md describes.

```markdown
# prisma-workflow settings

- prisma directory: `backend/prisma` (run commands from `backend/`)
- commands:
  - create migration: `pnpm db:migrate:create --name <name>`
  - apply migration: `pnpm db:migrate:dev --name <name>`
  - generate client: `pnpm db:generate`
  - status: `pnpm db:status`
- environment: load `.env` then `.env.local` before each command (`.env.local` holds the dev database connection)
- application types: DTOs in `backend/src/*/dto/`; response DTOs map new fields in their `from()` factory
- lint migrations: yes, with the project's migration linter
- allowed hosts: `dev-db.internal` (development databases that aren't on this machine)
- never-write hosts: `db.staging.internal`, `db.prod.internal` (always stop, even if also allowed)
```

Project commands replace the plain `prisma …` commands step for step, so a wrapper script that adds flags or loads environment variables keeps working.

Hosts are compared by hostname only, and the connection string is never printed. Loopback addresses, unix sockets, and local database files count as development without being listed. Don't list a hostname that also serves staging or production databases, such as a hosted provider's shared endpoint or connection pooler: the hostname can't tell those databases apart.
