---
# Bench issue: Swapped source and destination in ditto archive command (crates/tauri-macos-sign/src/lib.rs:168-179); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+lib\.rs")(?=[^{}]*"line"\s*:\s*"?(?:163|164|165|166|167|168|169|170|171|172|173|174|175|176|177|178|179|180|181|182|183|184)(?![0-9]))[^{}]*\}'
flags: i
---
