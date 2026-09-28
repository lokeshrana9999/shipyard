---
type: llm
---

PASS if the plan warns that Prisma would generate a drop-and-add for the rename (losing the column's data) and proposes a safe path: keeping the column with `@map("name")`, editing the generated migration into a RENAME COLUMN, or expand and contract.
FAIL if the plan would drop the existing column's data, or doesn't mention the data-loss risk.
