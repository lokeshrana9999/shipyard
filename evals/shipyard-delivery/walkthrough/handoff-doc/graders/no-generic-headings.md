---
type: regex
target: { source: file, path: HANDOFF.md }
pattern: '^#+\s*(overview|summary|conclusion|background|introduction)\s*$'
flags: im
match: not_contains
---
