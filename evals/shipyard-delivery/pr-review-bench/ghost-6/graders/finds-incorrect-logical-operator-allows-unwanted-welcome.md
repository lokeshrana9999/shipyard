---
# Bench issue: Incorrect logical operator allows unwanted welcome email triggers (ghost/core/core/server/services/members/members-api/repositories/MemberRepository.js:342-342); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*repositories[\\/]+MemberRepository\.js")(?=[^{}]*"line"\s*:\s*"?(?:337|338|339|340|341|342|343|344|345|346|347)(?![0-9]))[^{}]*\}'
flags: i
---
