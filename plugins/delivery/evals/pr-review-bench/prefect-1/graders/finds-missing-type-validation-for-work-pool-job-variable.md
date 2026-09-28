---
# Bench issue: Missing type validation for work pool job variables schema (src/prefect/_sdk/fetcher.py:180-182); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*_sdk[\\/]+fetcher\.py")(?=[^{}]*"line"\s*:\s*"?(?:175|176|177|178|179|180|181|182|183|184|185|186|187)(?![0-9]))[^{}]*\}'
flags: i
---
