---
# Bench issue: Premature null assignment in TryGetValidatableTypeInfo violates out parameter semantics (src/Validation/src/ValidationOptions.cs:44-56); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*src[\\/]+ValidationOptions\.cs")(?=[^{}]*"line"\s*:\s*"?(?:39|40|41|42|43|44|45|46|47|48|49|50|51|52|53|54|55|56|57|58|59|60|61)(?![0-9]))[^{}]*\}'
flags: i
---
