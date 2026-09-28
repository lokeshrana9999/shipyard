---
# Bench issue: Poll interval delay happens before first status check in timeout loop (src/prefect/deployments/flow_runs.py:229-235); hit = a finding on that file within 5 lines
type: regex
target: { source: file, path: review.json }
pattern: '\{(?=[^{}]*"file"\s*:\s*"[^"]*deployments[\\/]+flow_runs\.py")(?=[^{}]*"line"\s*:\s*"?(?:224|225|226|227|228|229|230|231|232|233|234|235|236|237|238|239|240)(?![0-9]))[^{}]*\}'
flags: i
---
