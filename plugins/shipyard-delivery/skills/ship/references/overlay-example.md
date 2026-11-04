# Project settings example

A project keeps this at `.claude/shipyard/ship.md`. The values below are illustrative; every setting is optional, and anything left out uses the defaults in SKILL.md.

```markdown
# ship settings

- base branch: develop
- stages: plan, test design, implement, verify live, review, describe, land
- plan files: `.claude/shipyard/plans/<branch>.md`
- stage reports:
  - verify live: `.claude/shipyard/reports/live-verify-<branch>.md`
  - eval-loop: `.claude/shipyard/reports/eval-loop-<branch>.md`
  - describe: `docs/pr/<branch>.md`
  - land: `.claude/shipyard/reports/land-<branch>.md`
- review station: project gate
- prompt paths: `prompts/**`, `plugins/*/skills/*/SKILL.md`
- eval-loop as verify evidence: yes
- demo skill: agent-demo-film
- caps:
  - verify fix loop: 3
- overrides:
  - verify live: skip for changes under `docs/`, `scripts/`, or `infra/`
  - describe: the team opens pull requests by hand; name the stage, don't start it
```

| Field | Meaning | Default |
|---|---|---|
| `base branch` | what the diff is taken against | the remote's default branch, else `main` or `master` |
| `stages` | the stages the project uses, in order; a stage left out is skipped | all nine |
| `plan files` | where grill-plan's plan file is; `<branch>` is the branch name with `/` replaced by `-` | `.claude/shipyard/plans/<branch>.md` |
| `stage reports` | where each stage's report is read from | the paths in SKILL.md's evidence table; `describe` has none (the open PR is the evidence) |
| `review station` | `pr-review` (the user runs `/shipyard-delivery:pr-review`, H4) or `project gate` (the project's own check, run by the land skill from its settings; review is then deferred to land and describe comes next). Land's settings file has the same field with the same values; set it in one place, and ship reads land's when its own is silent | `pr-review` when neither file sets it; land's default is `project gate`, so a project with a `land.md` gets that |
| `prompt paths` | globs whose changes make the eval-loop report required before verify counts as done | `**/SKILL.md`, `**/agents/*.md`, `**/prompts/**` |
| `eval-loop as verify evidence` | `yes` lets a passing eval-loop report stand in for the live-verify report when there is no app to boot | `no` |
| `demo skill` | the skill stage 8 runs; without it, ship names demo as the last stage and stops | none |
| `caps` | `verify fix loop`: how many `fail` rounds before ship stops the line (H5) | 3 |
| `overrides` | per-stage rules; an override wins over the skip rules in SKILL.md's table | none |

Whether land merges on its own is land's setting (`merge: auto` in `.claude/shipyard/land.md`), not ship's; ship only says which applies when it routes there.
