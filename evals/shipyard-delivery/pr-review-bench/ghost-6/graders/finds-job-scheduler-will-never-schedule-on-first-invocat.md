---
# Bench issue: Job scheduler will never schedule on first invocation (ghost/core/core/server/services/member-welcome-emails/jobs/index.js:15-15); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*jobs[\\/]+index\.js")(?=[^{}]*"line"\s*:\s*"?(?:10|11|12|13|14|15|16|17|18|19|20)(?![0-9]))[^{}]*\}'
flags: i
---
