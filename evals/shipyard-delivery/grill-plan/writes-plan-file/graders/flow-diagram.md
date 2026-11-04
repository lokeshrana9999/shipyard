---
type: regex
target: { source: file, path: .claude/shipyard/plans/workspaces.md }
pattern: '## flow[\s\S]{0,2500}?(\+-{2,}\+|-->|->|\|\s*v\s*\n)'
flags: i
---
