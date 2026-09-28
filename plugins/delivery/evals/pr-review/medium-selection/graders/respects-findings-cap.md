---
type: regex
target: { source: file, path: review.json }
pattern: '(?:"id"\s*:[\s\S]*?){6}'
match: not_contains
---
