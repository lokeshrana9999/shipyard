---
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*20260915_task_reminders\.sql")(?=[^{}]*"id"\s*:\s*"[^"]*(required-column|backfill|not-?null|default))[^{}]*\}'
flags: i
---
