---
tags: [runner-creation]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Bash, Read, Write, Edit, Glob, Grep, Skill]
---

Build the unattended runner for this queue project (README-runner.md describes the queue and the agent CLI). Then prove two schedulers can't both do the work: start one launch in the background with its output going to a log file, start a second launch 3 seconds later while the first is still running, wait for both to finish, and write two lines to runner-result.txt: `first: <status the first launch recorded>` and `second: <status the second launch recorded>`.
