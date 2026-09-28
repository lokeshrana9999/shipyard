---
type: regex
target: { source: file, path: review.json }
pattern: 'trackReminderEvent|swallowed-catch'
flags: i
match: not_contains
---
