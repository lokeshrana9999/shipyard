---
type: llm
focus: { source: file, path: audit.md }
---

The skill's last line is a `next:` handoff that names the review stage for a pass and the implement stage for a fail; the skill never starts either one.
PASS if the report doesn't grade that line, or the skill, as routing (or orchestrator routing, or a Misfit because of routing) at high severity, and doesn't recommend moving the `next:` line into another skill.
FAIL if it grades the `next:` line as high-severity routing, or recommends moving it out of the skill.
