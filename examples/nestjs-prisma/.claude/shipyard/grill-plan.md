# grill-plan settings (example: NestJS + Prisma multi-tenant API)

- plan path: `docs/plans/<branch>.md`
- glossary: `GLOSSARY.md`
- decision records: `docs/adr/`
- round cap: 4
- lookup timeout: 5 minutes
- standing questions:
  - Which organizations see this: the caller's own (`/api/organizations/:orgId/…`) or every organization an admin can reach?
  - Does it change a Prisma model? If so, name the migration and whether it backfills existing rows.
  - Which response shape does it return: `{ data: T }` with T's exact fields, or a stream?
  - Does any step send email or call a paid API? Name the cap per day.
- skip when: a change under `docs/` only, or a dependency bump with no code change
