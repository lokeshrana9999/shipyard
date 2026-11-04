---
type: regex
target: { source: file, path: .claude/shipyard/reports/live-verify-archive-claims.md }
pattern: '(^[ \t]*(?:[-*]|\d+\.)?[ \t]*\**\[not run\][\s\S]*?){3}'
flags: im
---
