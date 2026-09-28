---
# Bench issue: Inverted logic for non-blocking notarization success check (crates/tauri-macos-sign/src/lib.rs:232-248); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+lib\.rs")(?=[^{}]*"line"\s*:\s*"?(?:227|228|229|230|231|232|233|234|235|236|237|238|239|240|241|242|243|244|245|246|247|248|249|250|251|252|253)(?![0-9]))[^{}]*\}'
flags: i
---
