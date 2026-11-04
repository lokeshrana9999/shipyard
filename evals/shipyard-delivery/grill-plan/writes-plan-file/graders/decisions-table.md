---
type: regex
target: { source: file, path: .claude/shipyard/plans/workspaces.md }
pattern: '## decisions[\s\S]{0,400}?\|[^\n]*Decision[^\n]*\|[^\n]*Answer[^\n]*\|[^\n]*Source'
flags: i
---
