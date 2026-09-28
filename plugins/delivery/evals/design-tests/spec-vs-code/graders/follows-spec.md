---
type: llm
---

PASS if the design expects cancelling a shipped order to be refused with 409 (as the spec says) AND states that the current code does not refuse it (it cancels any order).
FAIL if the design expects the shipped-order cancellation to succeed, or never mentions that the code disagrees with the spec.
