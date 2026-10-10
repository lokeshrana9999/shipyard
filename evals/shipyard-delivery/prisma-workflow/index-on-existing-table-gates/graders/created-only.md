---
type: regex
target: { source: file, path: .shim/prisma-calls.log }
pattern: '\bmigrate\s+dev\b.*--create-only'
arm: with-only
---
