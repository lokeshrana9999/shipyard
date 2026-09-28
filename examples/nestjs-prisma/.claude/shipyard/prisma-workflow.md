# prisma-workflow settings (example: NestJS + Prisma multi-tenant API)

- prisma directory: `backend/prisma` (run commands from `backend/`)
- commands:
  - create migration: `pnpm db:migrate:create --name <name>`
  - apply migration: `pnpm db:migrate:dev` (prompts for a name; pass it when unattended)
  - generate client: `pnpm orm:sync`
  - status: `npx dotenvx run -f .env -f .env.local --overload -- npx prisma migrate status`
  - deploy pending: `npx dotenvx run -f .env -f .env.local --overload -- npx prisma migrate deploy`
- environment: dotenvx with `.env` then `.env.local` (flag order matters; `.env.local` holds this machine's `DATABASE_URL`)
- application types: DTOs in `backend/src/*/dto/`; response DTOs map new fields in their `static from()` factory
