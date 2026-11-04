---
type: regex
target: { source: file, path: .claude/shipyard/reports/live-verify-archive-notes.md }
pattern: '(^[ \t]*(?:[-*]|\d+\.)?[ \t]*\**\[?not run\b[\s\S]*?){3}'
flags: im
---
