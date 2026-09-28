# Project settings example

A project keeps this at `.claude/shipyard/ship.md`. The values below are illustrative; every setting is optional, and anything left out uses the defaults in SKILL.md.

```markdown
# ship settings

- base branch: develop
- stages: plan, test design, implement, verify live, review, describe
- plan files: `docs/plans/*.md`
- stage reports:
  - verify live: `docs/verify/<branch>.md`
  - review: `docs/reviews/<branch>.md`
- overrides:
  - verify live: skip for changes under `docs/`, `scripts/`, or `infra/`
  - describe: the team opens pull requests by hand; name the stage, don't start it
```

`stages` lists the stages the project uses, in order; a stage left out is treated as skipped. An override wins over the skip rules in SKILL.md's table.
