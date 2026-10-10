---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t\r]|$))(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*generate\b'
flags: m
match: not_contains
arm: with-only
---
