---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?![^\n]*(?:^|[ \t])(?:--help|-h)(?:[ \t\r]|$))(?:-[\w-]+(?:[ =][^ \n-][^ \n]*)?[ \t]+)*migrate[ \t]+dev\b[^\n]*[ \t]--create-only(?:=[^ \t\r\n]*)?(?:[ \t\r]|$)'
flags: m
arm: with-only
---
