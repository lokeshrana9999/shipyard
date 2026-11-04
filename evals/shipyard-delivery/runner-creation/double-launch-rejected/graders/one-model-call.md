---
type: regex
target: { source: file, path: .runner/agent-calls.log }
pattern: 'invoked[\s\S]*invoked'
match: not_contains
---
