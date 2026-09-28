---
tags: [pr-review-bench]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
---

/shipyard-delivery:pr-review git isn't available here: the branch's diff against main is in branch.diff. Review it.

When the review is done, also write `review.json` in the current directory: a JSON array with one object per finding in your report, each `{"id": "<short identifier for the kind of problem>", "file": "<path as in the diff>", "line": <line number in the new file>, "severity": "bug" | "issue" | "nit"}`. Write `[]` if there are no findings.
