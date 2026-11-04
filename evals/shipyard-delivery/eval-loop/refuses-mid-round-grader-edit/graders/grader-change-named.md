---
type: regex
target: { source: file, path: .claude/shipyard/reports/eval-loop-bot-tone.md }
pattern: 'grader[^\n]{0,80}(changed|edited|differ|mismatch|new hash|not comparable)'
flags: i
---
