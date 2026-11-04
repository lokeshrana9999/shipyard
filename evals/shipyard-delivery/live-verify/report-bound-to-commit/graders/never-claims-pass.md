---
type: regex
target: { source: file, path: .claude/shipyard/reports/live-verify-archive-notes.md }
pattern: '^Result:\s*pass\b|\[pass\]'
flags: mi
match: not_contains
---
