---
type: regex
target: { source: file, path: briefs/entry-1.md }
pattern: '\b(after|max(imum)?|up to|more than|exceeds?|at)\s+\d+\s+(consecutive\s+)?(failed\s+)?(login\s+)?(attempts?|failures?|tries|logins?)\b'
flags: i
match: not_contains
---
