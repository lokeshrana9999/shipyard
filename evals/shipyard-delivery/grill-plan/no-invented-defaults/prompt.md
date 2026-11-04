---
tags: [grill-plan]
max_turns: 25
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

add retry to the webhook sender in src/webhooks, with a cap on attempts and backoff between tries, and something sensible when it finally gives up
