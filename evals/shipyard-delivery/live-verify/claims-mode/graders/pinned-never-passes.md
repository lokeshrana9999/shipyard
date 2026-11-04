---
type: regex
target: { source: file, path: .claude/shipyard/reports/live-verify-archive-claims.md }
pattern: '\[(pass|not run)\][^\n]*pinned'
flags: i
match: not_contains
---
