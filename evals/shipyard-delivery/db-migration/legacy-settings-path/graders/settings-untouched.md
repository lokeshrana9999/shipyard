---
type: regex
target: { source: file, path: .claude/shipyard/prisma-workflow.md }
pattern: '^# prisma-workflow settings\r?\n\r?\n- allowed hosts: `orders-db\.cluster-c9x2\.eu-west-1\.rds\.amazonaws\.com`\r?\n- never-write hosts: `orders-db\.cluster-c9x2\.eu-west-1\.rds\.amazonaws\.com`\r?\n- environment: `prisma\.config\.ts` loads `\.env` through dotenv\s*$'
---
