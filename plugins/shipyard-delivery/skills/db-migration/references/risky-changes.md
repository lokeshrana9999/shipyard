# Risky changes

Changes where the migration can lose data or lock a busy table. When one appears, show the user the SQL and the safer path, and let them choose. The migration will later run on production, whose row counts can't be seen from here, so every table that existed before it counts as large and full, whatever the development copy holds; a table the same migration creates is exempt from the "existing table" rows.

The middle column is what migration tools typically generate. The adapter's risky-change notes say what its tool generates for each row, and how to take the safer path with that tool.

| Change | What the tool generates | Safer path |
|---|---|---|
| Rename a column or table | drop and add, which loses the data, unless the tool is told it's a rename | Turn it into a rename (`ALTER TABLE … RENAME COLUMN …`) the way the adapter's notes say, or expand and contract: add the new column, write to both, backfill, switch reads, drop the old one in a later release |
| Add a required column to an existing table | `ADD COLUMN … NOT NULL` with no default, which fails on a table with rows | Add it nullable or with a default, backfill, then make it required in a second migration |
| Make a column of an existing table required | `ALTER COLUMN … SET NOT NULL`, which fails if any row is null and scans the table while holding a lock | Backfill and confirm no row is null first; on a large table, use the database's way to check the constraint without a long lock before setting it |
| Change a column's type | `ALTER COLUMN … TYPE`, which can fail on existing data and rewrite the table | New column, backfill with a conversion, swap, drop |
| Drop a column or table | `DROP`, irreversible | Confirm nothing reads it, and that the data is backed up or not needed |
| Add an index to an existing table | a plain index build, which can block writes while it builds | A non-blocking index build (on Postgres, `CREATE INDEX CONCURRENTLY`). It can't run inside a transaction, so follow the adapter's transactions note for where it goes; if the tool can't run it outside one, say so and let the user choose |
| Remove or rename an enum value | recreates the enum type, which fails while a row still holds the removed value | Migrate rows off the value first; treat it like a rename |

Where the adapter says `generates: yes`, editing a generated file is the only allowed edit in the migrations folder, and only before it's applied. After editing, the file still has to use the physical names from the adapter's mapping.

If a migration linter for the database is available, run it; it flags most of these without needing a database. If the linter warns that a statement locks or scans a table (an index build that isn't concurrent, a new constraint, a type change), check whether the table existed before this migration: on a new table, note it and continue; on an existing table, stop as for the matching row above, or as for a risky change if no row matches.
