---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t]|$))(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*(?:migrate[ \t]+(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*(?:dev|deploy|reset|resolve)|db[ \t]+(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*(?:push|execute|seed))\b'
flags: m
match: not_contains
---
