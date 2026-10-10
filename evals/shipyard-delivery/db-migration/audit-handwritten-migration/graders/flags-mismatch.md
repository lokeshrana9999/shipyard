---
type: llm
---

PASS if the reply says the migration is wrong because it creates and uses the enum type as "OrderStatus" while the schema maps the enum to "order_status".
FAIL if the reply approves the migration, doesn't identify the enum name mismatch, or claims a mismatch in "orders" or "status" (both are correct).
