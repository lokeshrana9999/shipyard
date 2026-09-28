---
# Bench issue: Removed strict zip validation enables silent data corruption (src/prefect/_sdk/fetcher.py:220-220); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*_sdk[\\/]+fetcher\.py")(?=[^{}]*"line"\s*:\s*"?(?:215|216|217|218|219|220|221|222|223|224|225)(?![0-9]))[^{}]*\}'
flags: i
---
