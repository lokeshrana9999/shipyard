---
max_turns: 15
allowed_tools: [Read, Glob, Grep, Skill]
---

/shipyard-delivery:prisma-workflow In our Prisma schema I want to rename the User field `name` to `fullName` (the users table has about 2 million rows in production). What's the plan for the migration? Just describe it, don't run anything.
