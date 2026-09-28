---
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*TaskRemindersPanel\.tsx")(?=[^{}]*"id"\s*:\s*"[^"]*(stale|deps|exhaustive|dependenc))[^{}]*\}'
flags: i
---
