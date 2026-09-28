# Loops and honesty

Contents: sizing and models · the stage contract · what drives a loop · the per-entry loop · the review fix loop · the skeptic verifier · read-only tests · blocked twice · no progress · exclusive resources · merging parallel work · held stages · the final gate

## Sizing and models

Scale the run to the work. Agent caps count every agent except the review stage, which carries pr-review's own caps.

- small (one slice, a few plan entries): at most about 6 agents, no parallel writers;
- medium: at most about 15, test design per slice in parallel;
- large: at most the settings' cap (default 30); split into several runs and read each result before starting the next.

Caps never weaken a check. If a cap would drop a verifier, a fix round, or a review agent, split the run instead.

Every stage agent, verifier, and decision agent runs on the model of the session that invoked the skill. The only exceptions: agents that only read files and summarize them in a fan-out, and bringing up the stack before `live-verifier` runs, may use a smaller, faster model.

The review stage runs pr-review's two stages as siblings: `concern-reviewer` agents, one per slice of the diff (one slice for a small change, at most 6), each map catalog concerns to their slice's added lines and review them, in parallel; a mechanical check drops findings whose evidence line isn't in the diff; one `review-verifier` validates every finding as `confirmed`, `false-positive`, `pre-existing`, or `duplicate`. The report is compiled mechanically from the confirmed findings. Its slicing rule and caps are in pr-review's `references/stages.md` (schemas in `references/workflow.js`).

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
           blocked -> fixer closes exactly the violations -> goal verifier again   (round 1 of 2)
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

A browser, a fixed port, a shared database, and one worktree's git index take one agent at a time, worktrees or not. The agent holding one is told it's the only user (briefs.md).

## Merging parallel work

Parallel implement agents each get their own worktree and a declared file scope, and scopes don't overlap. A diff outside its declared scope fails that entry. Merge in plan order; after each merge run the typecheck and the touched tests on the merged tree, since separate worktrees keep files apart but not meaning. A merge conflict or a red check after merge is `blocked` for the later entry, which reruns on the merged tree. Where the orchestrator can't run git (a mode 1 script), a merge agent does the merge and the check.

## Held stages

A stage the user excluded is `held`: it didn't run and didn't pass. Only the orchestrator sets `held`. A stage whose input comes from a held stage is refused before the run starts, naming the pair. The report lists held stages, and a run with a held verify or review stage can't be reported as ready to merge.

## The final gate

The run reports ready for review only when every entry landed and passed its goal check, verify live passed (or the settings skip it), review has no open confirmed bugs, and no lane is blocked twice. Otherwise it reports what's real: what landed, what's open, and what a person has to decide.
