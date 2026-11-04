---
type: regex
target: { source: file, path: .claude/shipyard/merges.log }
pattern: '^[0-9a-f]{40} archive-notes\b'
flags: m
---
