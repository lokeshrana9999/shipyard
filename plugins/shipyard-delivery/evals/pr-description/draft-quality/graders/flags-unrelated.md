---
type: llm
---

PASS if the draft lists the README table reformatting as an unrelated change (not as part of the main change), and folds the "fixup: backoff jitter off-by-one" commit into the retry change instead of giving it its own bullet.
FAIL if the README change is presented as part of the feature, or the fixup commit appears as a separate change bullet.
