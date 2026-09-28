---
# Bench issue: Schema validation never executes due to impossible condition (crates/tauri-cli/src/helpers/config.rs:201-203); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*helpers[\\/]+config\.rs")(?=[^{}]*"line"\s*:\s*"?(?:196|197|198|199|200|201|202|203|204|205|206|207|208)(?![0-9]))[^{}]*\}'
flags: i
---
