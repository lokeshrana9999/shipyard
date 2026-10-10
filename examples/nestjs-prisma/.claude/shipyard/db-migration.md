# db-migration settings (example: NestJS + Prisma multi-tenant API)

- tool: `prisma`
- schema path: `backend/prisma/schema.prisma`
- migrations path: `backend/prisma/migrations`
- working directory: `backend/`
- commands:
  - create without applying: `pnpm db:migrate:create --name <name>`
  - apply: `pnpm db:migrate:dev --name <name>`
  - regenerate client: `pnpm orm:sync`
  - status: `npx dotenvx run -f .env -f .env.local --overload -- npx prisma migrate status`
  - deploy pending: `npx dotenvx run -f .env -f .env.local --overload -- npx prisma migrate deploy`
- environment: dotenvx with `.env` then `.env.local` (flag order matters; `.env.local` holds this machine's `DATABASE_URL`)
- application types: DTOs in `backend/src/*/dto/`; response DTOs map new fields in their `static from()` factory
- never-write hosts: the staging and production database hosts (`db.staging.internal`, `db.prod.internal`)
