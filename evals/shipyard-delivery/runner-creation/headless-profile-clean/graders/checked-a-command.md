---
type: regex
target: { source: file, path: .runner/last-result.json }
pattern: '"dry_run"\s*:\s*true[\s\S]*"commands_checked"\s*:\s*[1-9]'
---
