---
# Bench issue: Incorrect event level causes important certificate warnings to be suppressed in non-verbose mode (src/Tools/dotnet-dev-certs/src/Program.cs:132-135); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+Program\.cs")(?=[^{}]*"line"\s*:\s*"?(?:127|128|129|130|131|132|133|134|135|136|137|138|139|140)(?![0-9]))[^{}]*\}'
flags: i
---
