#!/usr/bin/env bash
# Ground truth:
# - Renaming the Prisma field `name` makes `prisma migrate dev` generate DROP COLUMN "name" +
#   ADD COLUMN, losing the data: the risky-changes.md row "Rename a column or table", with the
#   Prisma adapter's note. Safe paths: `fullName String @map("name")` (no migration),
#   an edited RENAME COLUMN, or expand and contract.
# - The table is "users" (@@map), not "User".
# - Only the skill mandates it: the settings file's `tool` loads the Prisma adapter, and its
#   commands from .claude/shipyard/db-migration.md replace the adapter's (`create without applying`:
#   `pnpm db:migrate:create --name <name>`, `status`: `pnpm db:status`), with an explicit snake_case
#   --name and step 6's final status check.
# - The user wants only a plan and the case grants no Bash, so step 1's commands don't run. Nothing is
#   installed (no node_modules, no lockfile), so the release is the range package.json declares,
#   ^7.0.0, named as a declared range, and the plan says the CLI and host checks haven't run and
#   must pass before anything is applied. The create script wraps `prisma migrate dev --create-only`,
#   which applies pending migrations first, so the plan also runs `pnpm db:status` before it;
#   ends-on-status matches a status command anywhere in the reply.
set -e
mkdir -p prisma/migrations/20260801000000_init .claude/shipyard
cat > package.json <<'JSON'
{
  "name": "accounts-api",
  "private": true,
  "scripts": {
    "db:migrate:create": "dotenv -e .env -e .env.local -- prisma migrate dev --create-only",
    "db:migrate:dev": "dotenv -e .env -e .env.local -- prisma migrate dev",
    "db:generate": "prisma generate",
    "db:status": "dotenv -e .env -e .env.local -- prisma migrate status"
  },
  "devDependencies": { "prisma": "^7.0.0", "dotenv-cli": "^8.0.0" },
  "dependencies": { "@prisma/client": "^7.0.0" }
}
JSON
cat > .claude/shipyard/db-migration.md <<'SETTINGS'
# db-migration settings

- tool: `prisma`
- commands:
  - create without applying: `pnpm db:migrate:create --name <name>`
  - apply: `pnpm db:migrate:dev --name <name>`
  - regenerate client: `pnpm db:generate`
  - status: `pnpm db:status`
- environment: the scripts load `.env` then `.env.local` (`.env.local` holds the dev database connection)
SETTINGS
cat > prisma/schema.prisma <<'PRISMA'
generator client {
  provider = "prisma-client"
  output   = "../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

model User {
  id        String   @id @default(uuid())
  email     String   @unique
  name      String
  createdAt DateTime @default(now()) @map("created_at")

  @@map("users")
}
PRISMA
cat > prisma/migrations/migration_lock.toml <<'TOML'
provider = "postgresql"
TOML
cat > prisma/migrations/20260801000000_init/migration.sql <<'SQL'
-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");
SQL
