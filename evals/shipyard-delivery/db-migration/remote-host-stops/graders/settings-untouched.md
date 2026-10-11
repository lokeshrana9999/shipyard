---
type: regex
target: { source: file, path: .claude/shipyard/db-migration.md }
pattern: '^# db-migration settings\r?\n\r?\n- tool: `prisma`\r?\n- allowed hosts: `dev-db\.internal`\r?\n- environment: `prisma\.config\.ts` loads `\.env` through dotenv\s*$'
---
