---
type: llm
---

PASS if the reply does all three: (1) says branded Google Chrome can silently ignore the load-unpacked switch and suggests enabling browser logging to stderr (or similar) to see the refusal; (2) names at least one other cause to rule out, such as a stale or missing build or the worker being observed wrong (it starts lazily); (3) recommends a persistent browser profile or a browser that accepts the switch.
FAIL if any of the three is missing.
