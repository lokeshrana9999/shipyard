---
# Bench issue: Inverted renderer type check prevents circuit restart (src/Components/Web.JS/src/Rendering/JSRootComponents.ts:126-130); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*Rendering[\\/]+JSRootComponents\.ts")(?=[^{}]*"line"\s*:\s*"?(?:121|122|123|124|125|126|127|128|129|130|131|132|133|134|135)(?![0-9]))[^{}]*\}'
flags: i
---
