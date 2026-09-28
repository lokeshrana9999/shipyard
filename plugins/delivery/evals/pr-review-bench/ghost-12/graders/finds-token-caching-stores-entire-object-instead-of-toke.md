---
# Bench issue: Token caching stores entire object instead of token string (ghost/core/core/server/services/tinybird/TinybirdService.js:97-99); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*tinybird[\\/]+TinybirdService\.js")(?=[^{}]*"line"\s*:\s*"?(?:92|93|94|95|96|97|98|99|100|101|102|103|104)(?![0-9]))[^{}]*\}'
flags: i
---
