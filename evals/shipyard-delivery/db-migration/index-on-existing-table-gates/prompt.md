---
tags: [db-migration]
max_turns: 25
timeout_seconds: 600
allowed_tools: [Bash, Read, Edit, Write, Glob, Grep, Skill]
---

/shipyard-delivery:db-migration Add an index on `customerId` in the Order model and migrate the dev database.
