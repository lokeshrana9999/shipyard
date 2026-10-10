---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '^(?!.* (?:--help|-h)(?: |$)).*\b(?:migrate +(?:dev|deploy|reset|resolve)|db +(?:push|execute|seed))\b'
flags: m
match: not_contains
---
