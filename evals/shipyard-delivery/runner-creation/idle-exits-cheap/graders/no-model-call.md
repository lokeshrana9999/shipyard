---
type: regex
target: { source: file, path: .runner/agent-calls.log }
pattern: 'invoked'
match: not_contains
---
