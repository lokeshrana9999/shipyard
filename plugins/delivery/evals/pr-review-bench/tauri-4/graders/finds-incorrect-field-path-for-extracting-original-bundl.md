---
# Bench issue: Incorrect field path for extracting original bundle identifier (crates/tauri-cli/src/helpers/config.rs:175-179); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*helpers[\\/]+config\.rs")(?=[^{}]*"line"\s*:\s*"?(?:170|171|172|173|174|175|176|177|178|179|180|181|182|183|184)(?![0-9]))[^{}]*\}'
flags: i
---
