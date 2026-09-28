---
# Bench issue: Date filter includes today's emails instead of excluding them (ghost/core/core/server/services/email-service/DomainWarmingService.ts:101-105); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*email\-service[\\/]+DomainWarmingService\.ts")(?=[^{}]*"line"\s*:\s*"?(?:96|97|98|99|100|101|102|103|104|105|106|107|108|109|110)(?![0-9]))[^{}]*\}'
flags: i
---
