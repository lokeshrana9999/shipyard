---
type: regex
target: { source: file, path: .claude/shipyard/reports/land-archive-notes.md }
pattern: '^[ \t]*merge\W{0,8}(?:merge|squash|rebase)?\s*[0-9a-f]{7,40}\b[^\n]*(?:via|read back)'
flags: im
match: not_contains
---
