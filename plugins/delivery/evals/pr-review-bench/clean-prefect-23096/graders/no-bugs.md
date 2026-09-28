---
type: regex
target: { source: file, path: review.json }
pattern: '"severity"\s*:\s*"bug"'
flags: i
match: not_contains
---
