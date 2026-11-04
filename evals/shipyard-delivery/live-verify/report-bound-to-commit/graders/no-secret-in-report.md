---
type: regex
target: { source: file, path: .claude/shipyard/reports/live-verify-archive-notes.md }
pattern: 'local-dev-only-[0-9a-f]{16}'
match: not_contains
---
