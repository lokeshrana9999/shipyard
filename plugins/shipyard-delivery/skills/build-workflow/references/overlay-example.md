# Project settings example

A project keeps this at `.claude/shipyard/build-workflow.md`. The values below are illustrative; every setting is optional, and anything left out uses the defaults in SKILL.md and its references.

```markdown
# build-workflow settings

- stages: pre-flight, test design, implement, verify live, review (describe runs in the session)
- stage commands:
  - test: `npm test -- <files>` in the package the change touches
  - typecheck: `npx tsc --noEmit` in `api/` or `web/`
  - lint: `npm run lint` in the same package
  - boot: see `.claude/shipyard/live-verify.md`
- caps: 20 agents per run (review excluded; no cap unless set here); 2 fix rounds; 4 parallel implement agents
- child start check: 2 minutes (default); child wall-clock budget: 60 minutes (default)
- briefs: `docs/runs/<run name>/briefs/<child>.md`; reports: `docs/runs/<run name>/reports/<child>.md`
- autonomy granted to children: commit to the branch, run the gate, merge (the always-ask list stays: public posts, deletes, money, facts about the user)
- models per role: default (the invoking session's model); fan-out readers: a smaller model
- status file: `docs/runs/<run name>/STATUS.md`
- invariants pasted into every implement brief:
  - <project invariant the verifier checks>
  - <another project invariant the verifier checks>
- isolation:
  - shared resources, one child each: the browser profile, ports 3000 and 4000, the local database, the review checkout, the staging deploy target
  - parallel implement agents get worktrees and disjoint file lists; `api/` and `web/` entries may run side by side
  - never write to: the shared staging database
- skip verify live for: changes under `docs/` or test-only changes
```
