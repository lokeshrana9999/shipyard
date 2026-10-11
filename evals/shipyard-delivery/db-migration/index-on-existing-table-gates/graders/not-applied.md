---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t\r]|$))(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*(?:migrate[ \t]+dev\b(?![^\n]*[ \t]--create-only(?:=[^ \t\r\n]*)?(?:[ \t\r]|$))|migrate[ \t]+(?:deploy|reset|resolve)\b|db[ \t]+(?:push|execute|seed)\b)'
flags: m
match: not_contains
---
