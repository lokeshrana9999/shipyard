---
# Bench issue: Race detection compares lengths instead of ID sets allowing double-firing (src/prefect/server/events/triggers.py:390-396); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*events[\\/]+triggers\.py")(?=[^{}]*"line"\s*:\s*"?(?:385|386|387|388|389|390|391|392|393|394|395|396|397|398|399|400|401)(?![0-9]))[^{}]*\}'
flags: i
---
