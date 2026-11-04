---
type: regex
target: { source: file, path: .runner/deadman.log }
pattern: '\bstart\b[\s\S]*\bfail\b'
---
