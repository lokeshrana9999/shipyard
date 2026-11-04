---
tags: [live-verify]
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Agent]
---

Verify these claims from the PR description before I merge:

1. POST /notes/:id/archive returns 204 and sets archived = 1 on the note.
2. Archiving another user's note returns 404 and leaves it unarchived.
3. Archiving a note also clears its pinned flag.
4. Every successful archive writes an audit_log row.
