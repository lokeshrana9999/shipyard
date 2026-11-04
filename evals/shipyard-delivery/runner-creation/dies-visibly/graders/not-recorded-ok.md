---
type: regex
target: { source: file, path: .runner/ledger.jsonl }
pattern: '"status"\s*:\s*"ok"'
match: not_contains
---
