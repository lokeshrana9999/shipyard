---
# Bench issue: Advisory lock uses non-deterministic hash breaking concurrency control (src/prefect/server/events/models/composite_trigger_child_firing.py:38-45); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*models[\\/]+composite_trigger_child_firing\.py")(?=[^{}]*"line"\s*:\s*"?(?:33|34|35|36|37|38|39|40|41|42|43|44|45|46|47|48|49|50)(?![0-9]))[^{}]*\}'
flags: i
---
