---
tags: [runner-creation]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Write the headless prompt file and the permission profile for this queue project's unattended runner (README-runner.md describes the queue, the agent CLI, and what the previous runner did), check them the way the agent CLI allows, and write one line to runner-result.txt: `denials: <the number the check reported>`.
