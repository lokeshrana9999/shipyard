# Risky changes

Changes where the generated migration can lose data or lock a busy table. When one appears, show the user the generated SQL and the safer path, and let them choose.

| Change | What Prisma generates | Safer path |
|---|---|---|
| Rename a column or table | drop and add, which loses the data | Edit the generated file to `ALTER TABLE … RENAME COLUMN …`, or expand and contract: add the new column, write to both, backfill, switch reads, drop the old one in a later release |
| Add a required column to a table with rows | fails, or needs a default | Add it nullable or with a default, backfill, then make it required in a second migration |
| Change a column's type | `ALTER COLUMN … TYPE`, which can fail on existing data and rewrite the table | New column, backfill with a conversion, swap, drop |
| Drop a column or table | `DROP`, irreversible | Confirm nothing reads it, and that the data is backed up or not needed |
| Add an index to a large table | a plain index build, which can block writes while it builds | A non-blocking index build (on Postgres, `CREATE INDEX CONCURRENTLY`) alone in its own migration file: index builds that can't run inside a transaction go in their own migration, since a multi-statement migration may run in one transaction |
| Remove or rename an enum value | recreates the enum type | Migrate rows off the value first; treat it like a rename |

Editing a generated file is the only allowed edit in the migrations folder, and only before it's applied. After editing, the file still has to use the physical names from `@@map`/`@map`.

If a migration linter for the database is available, run it; it flags most of these without needing a database. A linter rule about non-transactional index builds may fire on every single-transaction migration; treat that one as a reminder, not an error.
