---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?!.*(?:--create-only|--help|(?:^|\s)-h(?:\s|$))).*?\b(?:migrate\s+(?:dev|deploy)|db\s+push)\b'
flags: m
match: not_contains
---
