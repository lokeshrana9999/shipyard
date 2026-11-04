---
type: regex
target: { source: file, path: .fixture/pushes.log }
pattern: 'refs/heads/main'
match: not_contains
---
