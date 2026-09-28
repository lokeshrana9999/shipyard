---
# Bench issue: Missing await on async function call in task input collection (src/prefect/deployments/flow_runs.py:148-150); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*deployments[\\/]+flow_runs\.py")(?=[^{}]*"line"\s*:\s*"?(?:143|144|145|146|147|148|149|150|151|152|153|154|155)(?![0-9]))[^{}]*\}'
flags: i
---
