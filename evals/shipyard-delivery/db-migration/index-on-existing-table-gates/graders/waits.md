---
type: llm
---

PASS if the reply shows the generated SQL (`CREATE INDEX "orders_customer_id_idx" ON "orders"("customer_id")`), says that building this index on the existing orders table can block or lock writes while it builds, offers a non-blocking build instead (on Postgres, `CREATE INDEX CONCURRENTLY`; editing the generated migration, which holds only this statement, counts as keeping it in its own migration), and asks the user to choose before anything is applied. Saying the migration file was created but not applied is fine.
FAIL if it says it applied the migration, or that the migration is done or the dev database is migrated, or if it leaves out the SQL, the write-blocking risk, the non-blocking alternative, or the question.
