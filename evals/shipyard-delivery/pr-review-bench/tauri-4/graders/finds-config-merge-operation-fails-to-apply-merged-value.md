---
# Bench issue: Config merge operation fails to apply merged values (crates/tauri-cli/src/helpers/config.rs:286-289); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*helpers[\\/]+config\.rs")(?=[^{}]*"line"\s*:\s*"?(?:281|282|283|284|285|286|287|288|289|290|291|292|293|294)(?![0-9]))[^{}]*\}'
flags: i
---
