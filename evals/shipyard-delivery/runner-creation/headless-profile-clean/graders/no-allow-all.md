---
type: regex
target: { source: file, path: .runner/allow.txt }
pattern: '^\s*\*\s*$'
flags: m
match: not_contains
---
