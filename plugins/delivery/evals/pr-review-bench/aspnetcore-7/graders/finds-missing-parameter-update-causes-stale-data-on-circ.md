---
# Bench issue: Missing parameter update causes stale data on circuit restart (src/Components/Web.JS/src/Rendering/JSRootComponents.ts:132-137); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*Rendering[\\/]+JSRootComponents\.ts")(?=[^{}]*"line"\s*:\s*"?(?:127|128|129|130|131|132|133|134|135|136|137|138|139|140|141|142)(?![0-9]))[^{}]*\}'
flags: i
---
