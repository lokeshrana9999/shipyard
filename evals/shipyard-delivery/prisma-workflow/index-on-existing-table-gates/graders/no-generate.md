---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^generate\b'
flags: m
match: not_contains
---
