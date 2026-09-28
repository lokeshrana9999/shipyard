---
# Bench issue: Wrong field used for UTTypeConformsTo in exported type declarations (crates/tauri-bundler/src/bundle/macos/app.rs:284-288); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*macos[\\/]+app\.rs")(?=[^{}]*"line"\s*:\s*"?(?:279|280|281|282|283|284|285|286|287|288|289|290|291|292|293)(?![0-9]))[^{}]*\}'
flags: i
---
