---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t]|$))(?:-[\w-]+(?:[ =](?!(?:migrate|migration|db|dev|deploy)(?:[ \t]|$))[^ \t\n-][^ \t\n]*)?[ \t]+)*(?:(?:dev|deploy)(?=[ \t]|$)|(?:migration|db)[ \t]+(?:-[\w-]+(?:[ =](?!(?:migrate|migration|db|dev|deploy)(?:[ \t]|$))[^ \t\n-][^ \t\n]*)?[ \t]+)*(?!help(?:[ \t]|$))[^ \t\n-])'
flags: m
match: not_contains
---
