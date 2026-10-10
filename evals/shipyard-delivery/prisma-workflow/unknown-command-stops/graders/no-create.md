---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?!.*\s(?:--help|-h)(?:\s|$))migrate\s+dev\b'
flags: m
match: not_contains
---
