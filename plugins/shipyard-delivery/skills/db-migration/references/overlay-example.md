# Project settings example

A project keeps this at `.claude/shipyard/db-migration.md`. The values below are illustrative. Every setting is optional; anything left out comes from the adapter, or is discovered as SKILL.md describes.

```markdown
# db-migration settings

- tool: `prisma`
- schema path: `backend/prisma/schema.prisma`
- migrations path: `backend/prisma/migrations`
- working directory: `backend/`
- commands:
  - create without applying: `pnpm db:migrate:create --name <name>`
  - apply: `pnpm db:migrate:dev --name <name>`
  - regenerate client: `pnpm db:generate`
  - status: `pnpm db:status`
  - deploy pending: `pnpm db:deploy`
  - diff: `pnpm db:diff --from-migrations <migrations path> --to-schema <schema path> --script`
- environment: load `.env` then `.env.local` before each command (`.env.local` holds the dev database connection)
- application types: DTOs in `backend/src/*/dto/`; response DTOs map new fields in their `from()` factory
- lint migrations: yes, with the project's migration linter
- allowed hosts: `dev-db.internal` (development databases that aren't on a loopback address)
- never-write hosts: `db.staging.internal`, `db.prod.internal` (always stop, even if also allowed)
```

| Setting | What it sets | Without it |
|---|---|---|
| `tool` | the adapter, `references/tools/<tool>.md` | the enabled adapter whose `load-when` matches the project |
| `schema path` | the schema file or folder | the adapter's `discovery` |
| `migrations path` | the migrations folder | the adapter's `discovery` |
| `working directory` | where every command runs | the adapter's `working directory` |
| `commands` | replacements for the adapter's commands of the same name: `create without applying`, `apply`, `regenerate client`, `status`, `deploy pending`, `diff` | the adapter's commands |
| `environment` | how to load environment variables before each command | the adapter's `environment` |
| `application types` | where types, DTOs, and validation schemas that mirror the models live | the adapter's `client import`, and a search for the changed models |
| `lint migrations` | whether step 4 runs a migration linter, and which | run one if available |
| `allowed hosts` | hostnames, besides local ones, of development databases | none |
| `never-write hosts` | hostnames the skill always stops on, even if also allowed | none |

Project commands replace the adapter's commands step for step, so a wrapper script that adds flags or loads environment variables keeps working. The skill fills in `<name>`, `<schema path>`, and `<migrations path>`. A command left out keeps the adapter's.

Paths are relative to the project root. When a command runs from another working directory, the skill fills `<schema path>` and `<migrations path>` relative to that directory: with `working directory: backend/`, `backend/prisma/migrations` becomes `prisma/migrations`.

Hosts are compared by hostname only, and the connection string is never printed. Loopback addresses, unix sockets, and local database files count as development without being listed. Don't list a hostname that also serves staging or production databases, such as a hosted provider's shared endpoint or connection pooler: the hostname can't tell those databases apart.

## Old file name

Before this skill was renamed, its settings lived at `.claude/shipyard/prisma-workflow.md`. If `db-migration.md` is missing and that file exists, the skill reads it as the settings file with `tool: prisma`, keeps its `allowed hosts` and `never-write hosts` as written, and asks once for the rename. If both files exist, the skill reads `db-migration.md`, also stops on every host the old file lists under `never-write hosts`, and asks once for the old file to be merged into the new one and deleted. Its older keys mean:

| Old key | Current key |
|---|---|
| `prisma directory: <dir>` | `schema path`: `<dir>/schema.prisma`, or `<dir>` when it holds several `.prisma` files; `migrations path`: `<dir>/migrations` |
| `(run commands from <dir>)` after it | `working directory` |
| `create migration` | `create without applying` |
| `apply migration` | `apply` |
| `generate client` | `regenerate client` |
| `status`, `deploy pending` | unchanged |

To move, rename the file, add `tool: prisma`, split `prisma directory` as above, and rename the other keys.
