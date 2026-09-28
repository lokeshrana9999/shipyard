---
# Bench issue: Incorrect deployment filtering breaks full-name matching (src/prefect/_sdk/fetcher.py:396-397); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*_sdk[\\/]+fetcher\.py")(?=[^{}]*"line"\s*:\s*"?(?:391|392|393|394|395|396|397|398|399|400|401|402)(?![0-9]))[^{}]*\}'
flags: i
---
