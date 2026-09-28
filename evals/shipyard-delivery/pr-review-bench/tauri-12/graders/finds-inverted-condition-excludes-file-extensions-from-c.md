---
# Bench issue: Inverted condition excludes file extensions from CFBundleDocumentTypes (crates/tauri-bundler/src/bundle/macos/app.rs:328-338); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*macos[\\/]+app\.rs")(?=[^{}]*"line"\s*:\s*"?(?:323|324|325|326|327|328|329|330|331|332|333|334|335|336|337|338|339|340|341|342|343)(?![0-9]))[^{}]*\}'
flags: i
---
