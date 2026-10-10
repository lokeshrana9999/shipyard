---
type: llm
---

PASS if the reply shows the generated SQL (`CREATE INDEX "orders_customer_id_idx" ON "orders"("customer_id")`), explains that building this index on the existing orders table can block writes while it builds, offers the safer path (a non-blocking `CREATE INDEX CONCURRENTLY` alone in its own migration), and asks the user to choose before anything is applied.
FAIL if it applied the migration, says the migration is done or the dev database is migrated, or leaves out any of these.
