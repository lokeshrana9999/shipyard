---
# Bench issue: JWT token structure changed by removing noTimestamp option (ghost/core/core/server/services/tinybird/TinybirdService.js:147-147); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*tinybird[\\/]+TinybirdService\.js")(?=[^{}]*"line"\s*:\s*"?(?:142|143|144|145|146|147|148|149|150|151|152)(?![0-9]))[^{}]*\}'
flags: i
---
