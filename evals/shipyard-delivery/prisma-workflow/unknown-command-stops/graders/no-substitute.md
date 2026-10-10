---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?!.*\s(?:--help|-h)(?:\s|$))(?:dev|deploy|migration|db)\b'
flags: m
match: not_contains
---
