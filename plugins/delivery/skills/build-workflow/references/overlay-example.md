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
- caps: 20 agents per run (review excluded); 2 fix rounds; 4 parallel implement agents
- status file: `docs/runs/<run name>/STATUS.md`
- invariants pasted into every implement brief:
  - <project invariant the verifier checks>
  - <another project invariant the verifier checks>
- isolation:
  - exclusive: the browser, ports 3000 and 4000, the local database
  - parallel implement agents get worktrees; `api/` and `web/` entries may run side by side
  - never write to: the shared staging database
- skip verify live for: changes under `docs/` or test-only changes
```
