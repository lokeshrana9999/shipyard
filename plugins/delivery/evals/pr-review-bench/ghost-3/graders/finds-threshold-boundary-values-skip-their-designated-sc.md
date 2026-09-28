---
# Bench issue: Threshold boundary values skip their designated scaling tier (ghost/core/core/server/services/email-service/DomainWarmingService.ts:131-135); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*email\-service[\\/]+DomainWarmingService\.ts")(?=[^{}]*"line"\s*:\s*"?(?:126|127|128|129|130|131|132|133|134|135|136|137|138|139|140)(?![0-9]))[^{}]*\}'
flags: i
---
