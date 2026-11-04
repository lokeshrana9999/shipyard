# Project settings example

A project keeps this at `.claude/shipyard/grill-plan.md`. The values below are illustrative; every setting is optional, and anything left out uses the defaults in SKILL.md.

```markdown
# grill-plan settings

- plan path: `docs/plans/<branch>.md`
- glossary: `docs/GLOSSARY.md`
- decision records: `docs/adr/`
- round cap: 3
- lookup timeout: 3 minutes
- standing questions:
  - Which tenant sees this: one workspace, or every workspace in the account?
  - Does it run inside the nightly `reconcile` job window, and if so, what is its time budget?
  - Which environment does the acceptance check run against: `dev` or `staging`?
- skip when: a change under `docs/` only, or a dependency bump
```

| Setting | Default | What it changes |
|---|---|---|
| `plan path` | `.claude/shipyard/plans/<branch>.md` | Where the plan file goes. `<branch>` is the current branch with `/` replaced by `-`; without a branch, a slug of the goal. `ship` reads this path to place the branch, so change it in `ship`'s settings too. |
| `glossary` | the project's `GLOSSARY.md` if it exists, else a `## glossary` section in the plan file | Where settled terms are written. |
| `decision records` | `docs/adr/` if it exists, else a subsection of the plan's decisions | Where a hard-to-reverse, surprising trade-off is recorded. |
| `round cap` | 4 | Rounds asked before the plan is written with open items and the user chooses "proceed open" or "one more round". |
| `lookup timeout` | 5 minutes | How long a fact lookup runs before the fact is marked `unknown` and its question held. |
| `standing questions` | none beyond SKILL.md's | Questions every plan in this project answers, asked in the first round their prerequisites allow. |
| `skip when` | a one-file obvious change | Extra conditions under which the skill says so in one line and hands to implement. |
