---
type: regex
target: { source: file, path: briefs/entry-1.md }
pattern: '\b(for|of|lasting|within)\s+\d+\s*(-|\s)?(minutes?|mins?|hours?|seconds?|secs?)\b'
flags: i
match: not_contains
---
