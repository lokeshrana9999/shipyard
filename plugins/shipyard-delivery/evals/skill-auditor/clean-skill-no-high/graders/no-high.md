---
type: regex
target: { source: file, path: audit.md }
pattern: '\(high\b[^)\n]{0,30}\)|severity\W{0,4}\s*high\b|\|\s*high\s*\|'
match: not_contains
flags: i
---
