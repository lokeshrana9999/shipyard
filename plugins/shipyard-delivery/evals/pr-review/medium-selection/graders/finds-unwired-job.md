---
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*(sendTaskReminders\.ts|jobs[\\/]+registry\.ts)")(?=[^{}]*"id"\s*:\s*"[^"]*(unwired|regist))[^{}]*\}'
flags: i
---
