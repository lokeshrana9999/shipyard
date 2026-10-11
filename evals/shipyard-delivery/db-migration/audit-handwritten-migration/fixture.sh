#!/usr/bin/env bash
# Ground truth:
# - Planted bug: the hand-written migration creates and uses the enum type "OrderStatus";
#   the schema maps it to "order_status" (@@map), so the client looks for a type that doesn't exist.
# - Everything else in the SQL is correct and must not be flagged as a name mismatch:
#   "orders" (@@map), "status" (no @map), the enum values and the PLACED default.
# - Only the skill mandates it: the settings file's `tool` loads the Prisma adapter, which says
#   `generates: yes`. The migration is up for review before merge, so if it hasn't been applied to
#   any database yet, the fix is to remove it and create it again with step 3's `create without
#   applying` command, the one .claude/shipyard/db-migration.md names: `pnpm db:migrate:create
#   --name <name>` (package.json has the same scripts), name included. If it has been applied
#   somewhere, the fix is a new migration that corrects it, made with the same command;
#   regenerate-with-cli passes either answer.
set -e
mkdir -p prisma/migrations/20260801000000_init prisma/migrations/20260901000000_add_order_status .claude/shipyard
cat > package.json <<'JSON'
{
  "name": "orders-api",
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

enum OrderStatus {
  PLACED
  SHIPPED
  CANCELLED

  @@map("order_status")
}

model Order {
  id        String      @id @default(uuid())
  status    OrderStatus @default(PLACED)
  createdAt DateTime    @default(now()) @map("created_at")

  @@map("orders")
}
PRISMA
cat > prisma/migrations/migration_lock.toml <<'TOML'
provider = "postgresql"
TOML
cat > prisma/migrations/20260801000000_init/migration.sql <<'SQL'
-- CreateTable
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);
SQL
cat > prisma/migrations/20260901000000_add_order_status/migration.sql <<'SQL'
-- written by hand
CREATE TYPE "OrderStatus" AS ENUM ('PLACED', 'SHIPPED', 'CANCELLED');
ALTER TABLE "orders" ADD COLUMN "status" "OrderStatus" NOT NULL DEFAULT 'PLACED';
SQL
