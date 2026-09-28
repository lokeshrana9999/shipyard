---
# Bench issue: High-volume threshold boundary applies wrong scaling factor at 400k (ghost/core/core/server/services/email-service/DomainWarmingService.ts:124-129); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*email\-service[\\/]+DomainWarmingService\.ts")(?=[^{}]*"line"\s*:\s*"?(?:119|120|121|122|123|124|125|126|127|128|129|130|131|132|133|134)(?![0-9]))[^{}]*\}'
flags: i
---
