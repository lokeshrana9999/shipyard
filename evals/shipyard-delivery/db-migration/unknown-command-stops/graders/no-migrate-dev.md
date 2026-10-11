---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t]|$))(?:-[\w-]+(?:[ =](?!(?:migrate|migration|db|dev|deploy)(?:[ \t]|$))[^ \t\n-][^ \t\n]*)?[ \t]+)*migrate[ \t]+(?:-[\w-]+(?:[ =](?!(?:migrate|migration|db|dev|deploy)(?:[ \t]|$))[^ \t\n-][^ \t\n]*)?[ \t]+)*dev(?=[ \t]|$)'
flags: m
match: not_contains
---
