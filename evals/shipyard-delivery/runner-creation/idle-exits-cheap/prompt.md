---
tags: [runner-creation]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Set up the hourly unattended runner for this queue project (README-runner.md describes the queue and the agent CLI), then launch it once by hand so I can see what a scheduled launch does right now. Write one line to runner-result.txt: `status: <the status the launch recorded>`.
