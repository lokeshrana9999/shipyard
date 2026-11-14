# Loops and honesty

Contents: sizing and models · seats · the stage contract · what drives a loop · the per-entry loop · the review fix loop · the skeptic verifier · read-only tests · blocked twice · no progress · exclusive resources · merging parallel work · held stages · the final gate

## Sizing and models

Scale the run to the work: a small change (one slice, a few plan entries) needs no parallel writers; a medium one gets test design per slice in parallel; a large one splits into several runs, each result read before the next starts. There is no default cap on agents: the run plan states the count and the expected cost in one line and proceeds once approved, because the constraints that matter are correctness ones (one child per shared resource, below), not volume. A project's settings can set a cap; it counts every agent except the review stage, which carries pr-review's own caps, and a plan that exceeds it splits into runs.

Caps never weaken a check. If a cap would drop a verifier, a fix round, or a review agent, split the run instead.

Every agent runs on the model its role resolves to, and the orchestrator passes that model on every agent call, which overrides an agent file's `model: inherit`. A role that resolves to `inherit` gets no model option at all, since agent tools take only model names; the agent then runs on the session model. Resolve it per role from the project's `.claude/shipyard/models.md`, then the user's `~/.claude/shipyard/models.md`, then the default below; `check-briefs.mjs --resolve` (the path SKILL.md gives) prints the table. The format and the reasons are in the repo's `docs/models.md`.

| Role | Stage | Default |
|---|---|---|
| `test-design` | test design (`test-designer`) | the session model |
| `implement` | implement, one plan entry | the session model |
| `fixer` | a fix round | the session model |
| `verify` | goal verifier | the session model |
| `decide` | decision agent | the session model |
| `review` | review (`concern-reviewer`) | the session model |
| `review-verify` | review validation (`review-verifier`) | the session model |
| `live-plan` | writes `live-plan.md` | the session model |
| `live-run` | brings up the stack and runs `live-plan.md` (`live-verifier`) | the smaller, faster model |
| `reader` | a read-and-summarize fan-out | the smaller, faster model |
| `researcher` | a web lookup (outside build runs: grill-plan) | the smaller, faster model |
| `cold-read` | a fresh read of a plan or brief (grill-plan) | the smaller, faster model |
| `frame-check` | screenshots against a checklist; never approves taste | the smaller, faster model |

The smaller, faster model is the config's `smaller` value; with no config at all, every role runs on the session model. The lead is not a role.

The review stage runs pr-review's two stages as siblings: `concern-reviewer` agents, one per slice of the diff (one slice for a small change, at most 6), each map catalog concerns to their slice's added lines and review them, in parallel; a mechanical check drops findings whose evidence line isn't in the diff; one `review-verifier` validates every finding as `confirmed`, `false-positive`, `pre-existing`, or `duplicate`. The report is compiled mechanically from the confirmed findings. Its slicing rule and caps are in pr-review's `references/stages.md` (schemas in `references/workflow.js`).

## Seats

A seat is one agent continued by message across tasks, so the files it read stay in its context instead of being re-read by a fresh agent. Three seats, in modes 2 and 3 only (mode 1 starts fresh agents):

| Seat | Roles | Holds |
|---|---|---|
| builder | `implement`, then `fixer` for fix round 1 | the entries it built |
| checker | `verify`, then `live-plan` after the last entry | the diffs and the acceptance checks, never the builder's reasoning |
| live-run | `live-run` | the stack it brought up |

- **Every continuation is a brief file** with `Seat: <name>` and `Continues: <first brief's file name>` after the `---` line, checked in a folder with a copy of the seat's first brief. The message sent to the warm seat is only the part after `---`: the seat already holds the shared context, and re-sending it grows the seat's context every entry.
- **A seat's roles resolve to one model**, else it splits into fresh agents (`seat-model-split`). **A seat never holds a producer** (`implement`, `fixer`, `test-design`, `review`) **with a checker** (`verify`, `review-verify`, `live-plan`) (`seat-mixes-checker`). Briefs in one seat may own the same files; briefs in different seats may not (`overlap`).
- **Replace a seat, don't resume it**, after 4 entries; after 5 idle minutes (the cache has expired, so a resume re-writes the whole context and costs more than a fresh agent); on a second fix round for one entry, which goes to a fresh fixer; and on no-progress, a rescope, or compaction. The replaced seat writes a handoff note to its report path, and its successor gets that note plus the standard brief.
- **Briefs of one role share a byte-identical `## Shared context` block** before the `---` line (`prefix-drift`).

Measured costs behind these numbers are in the repo's `docs/models.md`. The other rules `check-briefs.mjs` enforces: `report-path`, `model-missing`, `unknown-role`, `bad-value`, `model-mismatch`, `working-folder`, `orphan-continuation`.

## The stage contract

Every stage's raw return maps to `{status: pass | pass-with-gap | blocked | halt, gaps: [{id, notProven, wouldNeed}], reason}` by the table in briefs.md, and the orchestrator branches on each value:

- `pass`: go to the next stage.
- `pass-with-gap`: record the gaps in the report and go on. A gap says what wasn't established and what would establish it.
- `blocked`: the stage couldn't recover in-run. Run the decision agent (briefs.md), then at most the capped loop below.
- `halt`: the stage can't be saved by a fix (the entry rests on a false premise, the tree isn't what the plan assumed). Stop the run.

Branch on the facts a stage reports, not only on its status: a pre-flight that reports the plan closed stops the run whatever else it says.

## What drives a loop

Only merge blockers: a failing goal check, a failed live check, a confirmed bug. Issues, nits, and "could be cleaner" go in the report and never start a fixer. Exit on a clean result.

## The per-entry loop

```
implement entry -> committed?
  no  -> decision: fix | retry | rescope | abort
  yes -> goal verifier
           pass / pass-with-gap -> next entry (record gaps)
           blocked -> fixer closes exactly the violations -> goal verifier again   (round 1 of 2: builder seat; round 2: fresh fixer)
           halt    -> stop the run
```

After the round cap (2 by default, 3 at most) a still-`blocked` entry stops the run with the violations. Most repair gains come in the first two rounds; later rounds mostly cost tokens. Never stack a later entry on an unverified one.

## The review fix loop

1. Review returns confirmed bugs. None: done.
2. A fixer gets exactly those findings and returns `closed: [ids]`.
3. `review-verifier` checks each "fixed" claim against the new code, cold, and tags it `confirmed` (fixed) or not. The fixer's word isn't evidence.
4. Re-run review only on the slices that cover the changed files (then validate), capped at the same rounds.

A read-only reviewer asked to fix what it found will report blocked forever. Pair it with a write-capable fixer over the same scope, then run the same read-only check again, so the closure is observed.

## The skeptic verifier

A separate agent checks every "fixed" claim: the goal verifier for plan entries, `review-verifier` for review findings. It didn't write the fix and never sees the fixer's reasoning, since a checker that shares the fixer's context tends to share its blind spots.

## Read-only tests

Fixers never edit tests. Before a fixer runs, record the HEAD it starts from (the pre-fix sha). The goal verifier then runs `git diff <pre-fix-sha> -- <test paths>` in the tree the fixer worked in; a working-tree diff would miss a change the fixer committed. Any change to an existing test, including a deleted assertion or a new skip, makes the fix `blocked` with "test modified" as the reason. New test files are allowed only when the brief asked for them.

## Blocked twice

A lane (verify live, a browser check, an end-to-end suite) that is blocked in one run and still blocked in the next isn't a carry-over: it's the next piece of work. The same lane may be deferred once, never twice. On the second time, run the decision agent once for that lane (a `fix` or `rescope` it names) or stop the run with `blocked-lane` naming it; don't report the rest as shipped.

## No progress

A stage makes no progress when it hits the same blocker twice, a verifier rejects the same violation twice, or a result fails its schema twice. Don't run it a third time unchanged: the decision is `rescope` or `abort`.

## Exclusive resources

A browser profile, a fixed port, a shared database, a deploy target, a shared checkout (one worktree's git index), and an eval runner over one case set take one agent at a time, worktrees or not. Exactly one active child holds each; the brief names the resource and tells the child it's the only user (briefs.md), and the run plan's `Shared resources:` line says who. Two children on one of these produce wrong results, not slow ones: a fetch race in a shared checkout, two runners in one browser profile, a duplicate writer after an interrupted run. Children that write in parallel own disjoint file lists and their own worktrees; a shared checkout is never a parallel writer's workspace. None of this limits how many children run.

## Merging parallel work

Parallel implement agents each get their own worktree and a declared file scope, and scopes don't overlap. A diff outside its declared scope fails that entry. Merge in plan order; after each merge run the typecheck and the touched tests on the merged tree, since separate worktrees keep files apart but not meaning. A merge conflict or a red check after merge is `blocked` for the later entry, which reruns on the merged tree. Where the orchestrator can't run git (a mode 1 script), a merge agent does the merge and the check.

## Held stages

A stage the user excluded is `held`: it didn't run and didn't pass. Only the orchestrator sets `held`. A stage whose input comes from a held stage is refused before the run starts, naming the pair. The report lists held stages, and a run with a held verify or review stage can't be reported as ready to merge.

## The final gate

The run reports ready for review only when every entry landed and passed its goal check, verify live passed (or the settings skip it), review has no open confirmed bugs, and no lane is blocked twice. Otherwise it reports what's real: what landed, what's open, and what a person has to decide.
