---
# Bench issue: clear_child_firings returns wrong ID field breaking race detection (src/prefect/server/events/models/composite_trigger_child_firing.py:147-157); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*models[\\/]+composite_trigger_child_firing\.py")(?=[^{}]*"line"\s*:\s*"?(?:142|143|144|145|146|147|148|149|150|151|152|153|154|155|156|157|158|159|160|161|162)(?![0-9]))[^{}]*\}'
flags: i
---
