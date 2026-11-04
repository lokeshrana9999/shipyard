---
tags: [runner-creation]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Build the unattended runner for this queue project (README-runner.md describes the queue and the agent CLI). Then show me what happens when the account hits its usage limit mid-schedule: launch the runner once with `AGENT_CLI_SIMULATE=limit` set in its environment, and write one line to runner-result.txt: `status: <the status that launch recorded>`.
