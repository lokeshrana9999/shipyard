#!/usr/bin/env bash
# Ground truth:
# - Renaming the Prisma field `name` makes `prisma migrate dev` generate DROP COLUMN "name" +
#   ADD COLUMN, losing the data. Safe paths: `fullName String @map("name")` (no migration),
#   an edited RENAME COLUMN, or expand and contract.
# - The table is "users" (@@map), not "User".
# - Only the skill mandates it: the project's wrapper commands from
#   .claude/shipyard/prisma-workflow.md (`pnpm db:migrate:create --name <name>`, `pnpm db:status`),
#   an explicit snake_case --name, and a final migrate status check.
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
cat > .claude/shipyard/prisma-workflow.md <<'SETTINGS'
# prisma-workflow settings

- commands:
  - create migration: `pnpm db:migrate:create --name <name>`
  - apply migration: `pnpm db:migrate:dev --name <name>`
  - generate client: `pnpm db:generate`
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
