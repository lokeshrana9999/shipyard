---
tags: [runner-creation]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Build the unattended runner for this queue project (README-runner.md describes the queue and the agent CLI) and launch it once. Then write three lines to runner-result.txt: `status: <the status the launch recorded>`, `units: <the unit count it recorded>`, and `cap: <the maximum units per run the next launch will use>`.
