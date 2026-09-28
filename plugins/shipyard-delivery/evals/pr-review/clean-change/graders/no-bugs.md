---
type: llm
---

PASS if the report states there are no bugs, and raises at most a few low-severity nits or issues.
FAIL if it reports any bug, or invents a problem that isn't in the diff (for example, claims the rounding or clamping is wrong).
