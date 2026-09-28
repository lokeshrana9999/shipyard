---
# Bench issue: JWT signature validation bypassed in token expiration check (ghost/core/core/server/services/tinybird/TinybirdService.js:162-170); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*tinybird[\\/]+TinybirdService\.js")(?=[^{}]*"line"\s*:\s*"?(?:157|158|159|160|161|162|163|164|165|166|167|168|169|170|171|172|173|174|175)(?![0-9]))[^{}]*\}'
flags: i
---
