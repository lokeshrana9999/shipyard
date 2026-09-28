# the pipeline

A change moves through eight stages, each run by one skill or by your agent's normal session; the `ship` skill works out which stage the branch is at and hands off to the next one, and each stage skill ends with a `next:` line naming the stage after it.

## stages

| # | Stage | Runs with | Agents it starts | Who starts it |
|---|---|---|---|---|
| 0 | explain | `walkthrough` | | you or the agent |
| 1 | plan | your agent's plan mode, or a plan written in chat | | you |
| 2 | test design | `design-tests` | `test-designer` (in multi-agent runs) | you or the agent |
| 3 | implement | you and your agent in the normal session; `prisma-workflow` when a Prisma schema changes | | you or the agent |
| 4 | verify live | `live-verify` | `live-verifier` (in multi-agent runs) | you or the agent |
| 5 | review | `pr-review` | `concern-reviewer`, `review-verifier` | you, `/delivery:pr-review` |
| 6 | describe | `pr-description`, drawing with `flow-diagram` | | you, `/delivery:pr-description` |
| 7 | demo | no skill yet | | |

Usable at any stage: `flow-diagram` (Mermaid for pages that render it, ASCII for terminals and editors), `skill-auditor` (scores `SKILL.md` files), and in Claude Code the `signal` output style (answer first, one next step, progress markers), picked in Claude Code's settings.

Some stages need tools beyond the agent itself. `pr-review` reads pull requests and `pr-description` creates or updates them, both through your code host's CLI or API, signed in. `live-verify` in browser mode needs a browser the agent can drive. Each skill says what it needs when it's missing.

## how ship places a branch

`ship` only routes; it never does a stage's work. It reads the project's `.claude/shipyard/ship.md` if there is one, then looks at the branch with cheap read-only checks: the current branch, files changed against the merge base plus uncommitted ones, whether a pull request is open, a plan file, test files for the changed code, Prisma schema files and their migrations. It runs no builds and no tests; a test result is a claim from a commit message, you, or CI.

It walks the stage table top-down. The current stage is the last one done, or one left half-done; the next stage is the first whose work isn't done and isn't skipped. Evidence of a later stage (code in the diff, an open pull request) marks the stages before it done. A changed schema with no new migration means implement isn't done, so it routes to `prisma-workflow` first. Its report has four lines, `Stage:`, `Skipped:`, `next:`, and `Then:`, and it stops to ask before starting the next stage. [examples/ship-transcript.md](../examples/ship-transcript.md) shows one run.

On a yes, it starts the next skill itself when the agent may start it (walkthrough, design-tests, prisma-workflow, live-verify, flow-diagram). For `pr-review`, `pr-description`, and `build-workflow` it prints the exact command for you to run, because those skills set `disable-model-invocation` and Claude Code blocks the agent from starting them. Agents that ignore that field may start them unasked, which is why the [AGENTS.md snippet](agents-install.md#3-paste-the-agentsmd-snippet) says not to. Plan and implement belong to your agent: `ship` tells you to enter plan mode or to continue in the session.

Arguments: a stage (number, name, or skill name) jumps to it, asking first if its entry condition isn't met. `all` prints a `/delivery:build-workflow <plan file> <remaining stages>` command, which runs the remaining stages as one multi-agent run; it shows its own run plan and waits for a go. When demo comes next, `ship` says it has no skill yet and stops.

## handoffs

| Skill | `next:` |
|---|---|
| `design-tests` | the implement stage, or whoever writes the tests |
| `prisma-workflow` | back to implement, with the migration name and the final `migrate status` output |
| `live-verify` | a pass goes to review; a fail goes back to implement with the report |
| `pr-review` | fixes go back to implement; a clean review goes to describe |
| `pr-description` | the pull request's human reviewers, with its link; demo when the change is user-facing and the project has one |
| `build-workflow` | a clean run goes to describe if it didn't run; a blocked or halted run goes back to you with the blocker |
| `ship` | the stage you confirm, through its own skill |

`walkthrough`, `flow-diagram`, and `skill-auditor` have no stage after them. The exact wording of each handoff is on its page under [skills/](skills/README.md).

## how pr-review works

`pr-review` slices the diff, has one agent per slice map the review concerns to the added lines and review each one, drops any finding whose quoted line isn't in the diff, and has a separate agent validate what's left. Every agent runs on the model of the session that started the skill, and nothing edits files or commits.

```
scope.sh ──> full.diff + diff.txt ("path:line: code", added lines only)
   │         slices: one if ≤ 10 files and ≤ 400 added lines; else ~400 lines each,
   ▼         by top-level directory, security paths alone, at most 6 (slices grow past it)
1 Map and review   concern-reviewer per slice, in parallel, whole catalog each:
   │               MAP concerns to its lines, then REVIEW each: finding or cleared
   ▼
check (no model)   drop findings whose evidence_line isn't at location; flag unreviewed ids
   ▼
2 Validate         review-verifier, one agent over every slice's findings:
   │               confirmed | false-positive | pre-existing | duplicate
   ▼
report from confirmed findings only: Bugs / Issues / Nits / Summary + coverage
```

The catalog is the list of concerns a reviewer checks: the starter files in the skill's `references/catalog-*.md` plus the project's own `.claude/shipyard/pr-review/concerns.md`, which wins when ids collide. `/delivery:pr-review mine` builds or refreshes that project file from past review comments.

Scope: `scope.sh` writes `full.diff` (the unified diff against the base, limited to the review paths) and `diff.txt` (added lines only, one per line as `path:line: code`). With no added lines it reports "No changes to review." and stops.

Slices are computed without a model. A change of at most 10 files and 400 added lines is one slice. A bigger one is grouped by top-level directory and packed into slices of about 400 added lines; files under security-sensitive paths (default: paths containing `auth`, `permission`, `payment`, `secret`, `tenant`, `tenancy`) get slices of their own; a file is never split. Past the agent cap (default 6), slices grow by a quarter at a time until the plan fits. Slice size, the cap, and the security paths can be set in the project's settings.

Map and review: each `concern-reviewer` gets the whole catalog and its slice's added lines, and can read the whole repository. It first writes out every concern that has a site in its slice, each site as a `path:line` copied from `diff.txt`, then reviews each one against the real code (callers, callees, tests). A concern ends as a finding with a concrete failure scenario, or cleared with a reason.

Check: a script, no model. A finding whose `location` isn't an added line, or whose quoted `evidence_line` isn't the code at that line, is dropped and counted. A mapped concern with neither a finding nor a clearance is counted and listed as unreviewed, never hidden.

Validate: one `review-verifier` sees every surviving finding from every slice at once, without the reviewers' reasoning. It tags each one confirmed, false-positive, pre-existing (the base already had it), or duplicate, may lower its severity, and writes a one-line ship verdict.

Report: compiled by the script from confirmed findings only, bugs first, cut at the findings cap (default 10) with the cut stated. Bugs, Issues, and Nits each say `none` when empty. The summary line gives the counts, the advisory verdict, and a coverage line: slices, concerns read, concerns mapped, findings dropped, confirmed, rejected, unreviewed. A count nothing produced prints as `n/a`, never an estimate.

With a workflow runner (Claude Code's Workflow tool), the skill runs `references/workflow.js`. Without one, the session starts the agents itself; without any subagent support, it runs the stages inline, one slice at a time, and says so in the report's `Pipeline:` line. Contracts, schemas, and the report template are in [stages.md](../plugins/delivery/skills/pr-review/references/stages.md).
