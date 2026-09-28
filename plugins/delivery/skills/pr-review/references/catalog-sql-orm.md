# SQL, ORM, and migration concerns

Load when the diff touches database queries, ORM models or schema files, migrations, seeders, or backfill scripts.
load-when: `**/migrations/**`, `**/migration/**`, `**/migrate/**`, `**/*.sql`, `**/schema.prisma`, `**/models/**`, `**/*.model.*`, `**/entities/**`, `**/*.entity.*`, `**/*repository*`, `**/*Repository*`, `**/db/**`, `**/database/**`, `**/seeds/**`, `**/seeders/**`, `**/*seed*`, `**/*backfill*`

## Correctness

- **Check-then-write race** (`correctness/check-then-write-race`, default bug): Reading a count, limit, or existence check and then writing in separate steps lets concurrent requests (or at-least-once event deliveries) both pass the check, exceeding limits, creating duplicates, or double-firing side effects. Enforce it inside a transaction, a unique constraint, or an upsert.
  - look-for: find-then-create or find-then-update without a transaction, lock, or unique constraint; event or webhook handlers that check a status before acting.

- **Dependent writes without a transaction** (`correctness/non-atomic-writes`, default issue): Multiple writes that must succeed together (revoke then grant, parent and children) leave inconsistent data when one fails midway.
  - look-for: several awaited writes in one operation with no transaction wrapper.
  - triggers: `await`, `create`, `update`, `delete`, `insert`, `save`, `upsert`, `remove`, `destroy`

- **Single-row lookup on a non-unique key** (`correctness/ambiguous-single-row`, default issue): Fetching "the" row by a key that can match several (versions, duplicates, one-to-many joins) without an explicit order or selector returns an arbitrary one, which changes as data grows.
  - look-for: find-first or `LIMIT 1` without `ORDER BY`; backfills that join a one-to-many relation assuming one match.
  - triggers: `first`, `findOne`, `LIMIT 1`, `limit(1)`, `take: 1`, `[0]`, `JOIN`

- **Migration update without a scope** (`correctness/unscoped-migration-update`, default bug): An `UPDATE` without a `WHERE`, or a column drop without a step that preserves its data, overwrites or destroys valid existing rows.
  - look-for: migration SQL with bare `UPDATE`, or `DROP COLUMN` with no preceding copy or backfill.
  - triggers: `UPDATE`, `DROP COLUMN`, `drop_column`, `dropColumn`, `removeColumn`, `remove_column`

- **Required column added without backfill** (`correctness/required-column-no-backfill`, default bug): Adding a NOT NULL column or required relation to a populated table fails the migration or forces one default onto every historical row even when the correct values differ. Add it nullable, backfill real values, then tighten.
  - look-for: a new required field without a default on an existing model; a backfill that sets one constant for all rows.
  - triggers: `NOT NULL`, `nullable: false`, `null: false`, `required`, `ADD COLUMN`, `addColumn`, `add_column`, `@Column`, `Column(`

- **Constraint added without checking existing data** (`correctness/constraint-vs-existing-data`, default bug): A new length limit, type change, or uniqueness constraint fails or truncates when existing rows violate it; a constraint declared only in the ORM model without a migration does not constrain the column at all.
  - look-for: schema constraint changes with no migration, or no step handling rows that are out of bounds.

- **Rename implemented as drop and recreate** (`correctness/rename-as-drop`, default bug): Renaming a column, table, or enum type via a generated drop-and-create destroys the existing values. The migration must rename in place.
  - look-for: `DROP TYPE`, `DROP COLUMN`, or `DROP TABLE` paired with a create of a similarly named object.
  - triggers: `DROP`, `rename`

- **Non-idempotent backfill** (`correctness/non-idempotent-backfill`, default issue): One-off data scripts and seeders must be safe to re-run: select only rows not yet processed so later runs are no-ops.
  - look-for: backfill updates with no condition excluding already-migrated rows.
  - triggers: `UPDATE`, `backfill`, `seed`, `INSERT`, `create`

- **32-bit integer for sizes or counters** (`correctness/int32-overflow`, default issue): A 32-bit signed integer caps at about 2.1 billion, so byte sizes above roughly 2 GB and fast-growing counters overflow. Use a 64-bit type.
  - look-for: integer columns named like size, bytes, or total counts.
  - triggers: `integer`, `serial`, `int4`, `int32`, ` int `, ` Int `, `Int?`, `int(`, `size`, `bytes`, `count`

## Architecture

- **Query inside a loop** (`architecture/query-in-loop`, default issue): Issuing one query or one write per item makes latency grow with the collection. Fetch with one `IN` query, or use a single bulk update or delete keyed on the parent.
  - look-for: `await` of a data-access call inside `for`, `map`, or `forEach`.
  - triggers: `for`, `forEach`, `.map(`, `while`, `each`, `await`

- **Relation without deliberate delete behavior** (`architecture/undefined-delete-behavior`, default issue): Every foreign key needs an intentional on-delete rule, and relations should match real cardinality; otherwise deletes leave orphans or fail, and needless join tables complicate queries. Add owner relations where cleanup depends on them.
  - look-for: new foreign keys with no on-delete rule or rationale; a join table where a single foreign key suffices; one-to-one modeled as one-to-many.
  - triggers: `references`, `FOREIGN KEY`, `foreign`, `relation`, `ManyTo`, `OneTo`, `belongs_to`, `has_many`, `has_one`, `onDelete`, `on_delete`, `ON DELETE`

- **Missing or unscoped uniqueness** (`architecture/missing-unique-constraint`, default issue): Natural keys and mapping tables need unique constraints, and names unique within a tenant need a composite key including the tenant, or duplicates slip in under concurrency.
  - look-for: mapping tables without a unique pair; a unique name constraint that omits the tenant column.
  - triggers: `unique`, `@@`, `index`, `CREATE TABLE`, `create_table`, `createTable`, `model `, `Entity`, `table`

## Style

- **Non-unique lookup API for a unique key** (`style/find-first-on-unique`, default nit): Use the ORM's unique-lookup method when the filter fully specifies a unique key; it states intent and uses the index.
  - look-for: find-first style calls whose where clause is exactly a primary or unique key.
  - triggers: `findFirst`, `findOne`, `find_first`, `first(`, `.first`

- **Inconsistent schema conventions** (`style/inconsistent-schema-conventions`, default nit): New models should follow the existing id strategy, field casing, and string-length conventions so the schema stays uniform.
  - look-for: a different id default type, snake_case fields among camelCase, or unbounded strings where siblings declare lengths.
  - triggers: `model `, `CREATE TABLE`, `create_table`, `createTable`, `Entity`, `Column`, `@default`, `default:`, `table`
