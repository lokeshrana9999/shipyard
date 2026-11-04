---
name: ship
description: Places the current branch in the delivery pipeline from the evidence on disk and names the next stage, or hands the rest to a multi-agent run. Use when asked "ship this", "what's next in the pipeline", "where am I in the pipeline", "what's left before I open a PR", or "take this to PR". Not for "what's next" about code, a function, or a plan step; answer those directly.
argument-hint: "[stage | all]"
---

# Ship

Say where the work stands and which one stage comes next, from evidence on disk, not from claims. This skill only routes: every stage's rules live in that stage's own skill, so it never restates them and never does stage work itself. A stage skill's own `next:` line is a suggestion; the file check here decides.

**Project settings**: on every invocation, read `.claude/shipyard/ship.md` in the project root if it exists; its settings win over the defaults here. It can set which stages the project uses, the base branch, where plans and stage reports live, the review station, the demo skill, which paths count as prompt text, and per-stage overrides such as when to skip a stage. Its shape is in [references/overlay-example.md](references/overlay-example.md).

## Stages

| # | Stage | Runs with | Enter when | Skip when |
|---|---|---|---|---|
| 0 | explain | walkthrough | the user needs the area or the change explained | the user knows the area |
| 1 | plan | grill-plan | there is a goal and no plan file | a one-file, obvious change |
| 2 | test design | design-tests (test-designer agent) | a plan exists and the diff has no tests for it | tests for the change are already in the diff; docs-only change |
| 3 | implement | this session; db-migration when a database schema changes | tests are designed, or the diff is partial | never; db-migration only when a schema file changed |
| 4 | verify live | live-verify (live-verifier agent); eval-loop too when the diff changes prompt or skill text | code and tests are in the diff | docs-only, test-only, no runnable app (a library), or the settings say so |
| 5 | review | the review station the settings name: `/shipyard-delivery:pr-review` (the user runs it) or a project gate (land runs it) | the verify report passes for HEAD, or verify is skipped | never |
| 6 | describe | `/shipyard-delivery:pr-description` (flow-diagram for diagrams; reuses the plan's) | reviewed, no PR yet or its description is stale | the user isn't opening a PR |
| 7 | land | land | described, or a PR is open | the user isn't merging |
| 8 | demo | the skill the settings name, else none | landed | always, unless the settings name a skill |

A schema file changed with no new migration for it means stage 3 isn't done: route to db-migration before verify live. Cross-cutting, at any stage: flow-diagram, skill-auditor, the signal output style. `/shipyard-delivery:build-workflow` runs several stages as one multi-agent run and decides itself when one agent is enough.

## Evidence

A stage is done when its artifact exists and is current; otherwise it isn't, whatever a commit message or `next:` line says. Artifact paths below are under `.claude/shipyard/` in the project root; the settings' `plan files` and `stage reports` override them. `<branch>` is the branch name with `/` replaced by `-`, as the stage skills write it. Stage skills end their reports with `Checked:` / `Not checked:` lines: quote the `Not checked:` line when it names the change, since an unchecked path is a gap the next stage inherits. H4 and H5 are the pipeline's named human points: H4, the user runs pr-review (it launches many agents, so the cost is theirs to accept); H5, andon, the line is stopped on a cause the agent couldn't remove, and only a person restarts it.

| Stage | Artifact | Done when | Otherwise |
|---|---|---|---|
| 1 plan | `plans/<branch>.md` | the file exists and its `## approval` section holds `Approved: <date> plan-hash <hash>`: `confirmed`. With a shell, check the hash: the first 12 hex of the sha256 of the bytes above the `## approval` heading; a mismatch means the plan was edited after approval, so report `confirmed <date>, edited since`; `plan-hash unavailable (no shell)` on the line means `confirmed <date>, unbound` | no file and no code yet: route to grill-plan unless the change is one obvious file. No `Approved:` line: the plan is `unconfirmed`. Code already in the diff and no file: `Plan: none`. Both are shown on the `Plan:` line at every later stage; neither blocks routing, the user decided to build. |
| 4 verify live | `reports/live-verify-<branch>.md` | `Result: pass` and `Commit:` equals the full HEAD sha | no report, `Result: fail` or `blocked`, or a `Commit:` that isn't HEAD (stale: the code moved after the check) all mean verify isn't done. Name the gap in one line (`report is for a1b2c3d, HEAD is e4f5a6b`) and route to live-verify. A `fail` goes back to implement; a third `fail` in a row, or `blocked` after live-verify's own fix attempt, is an andon stop (H5): don't route on, name the failing check, and ask whether to fix, re-plan, or stop. |
| 4 eval-loop | `reports/eval-loop-<branch>.md` | required, saying `Result: pass` for HEAD, when the diff touches prompt, skill, or instruction text (default: `**/SKILL.md`, `**/agents/*.md`, `**/prompts/**`; the settings' `prompt paths` override); the settings can make it the verify evidence where there is no app to boot | missing, `not passed`, `stopped`, or for another commit: verify isn't done; route to eval-loop first |
| 5 review | the station the settings name: `review station` in ship's settings, else in land's `land.md` in the same folder (whose own default is `project gate`) | `pr-review`: the user ran it and it is clean (a claim; say whose). `project gate`: it runs inside land, so review is deferred to stage 7 and describe comes next | with neither settings file: pr-review, so print its command |
| 6 describe | an open PR with a description (code host CLI), or the settings' `describe` report path | the PR exists and describes HEAD | none or stale: pr-description |
| 7 land | `reports/land-<branch>.md` | `Verdict: landed` | any other verdict (`gate failed`, `not merged`, `deploy did not run`) means land isn't done. `deploy did not run` is a stopped line (H5): report it with the command the report hands over, don't route past it. `gate failed` and `not merged` go back to implement with the report's reason |

## Schema and migration files

These are the files the db-migration skill works on. Find them by reading a few small text files; never run a migration tool to find them.

- db-migration's settings first: `db-migration.md` in `.claude/shipyard/`, or, if it's missing, the older `prisma-workflow.md` there, which means `tool: prisma`. Its `schema path` is the schema file, or a folder whose files are the schema except migration files (those under `migrations path`, or, if that isn't set, those matching the adapters' `migration files`). Any new file under its `migrations path` is a new migration.
- For whichever of those two paths the settings don't set, read the `enabled:`, `schema files:`, and `migration files:` lines of every adapter file in `../db-migration/references/tools/`, relative to this skill's folder (all but `format.md`). Use only adapters that say `enabled: yes`, narrowed to the settings' `tool` if it names one. Every backticked entry on those lines is a glob matched from the project root, outside dependency folders. A changed schema file needs a new migration file from the same adapter.
- With no schema path and no enabled adapter's globs, say the schema check didn't run.

## Steps

Steps are agent-owned unless marked.

```
- [ ] 1 Read settings
- [ ] 2 Look
- [ ] 3 Place the work
- [ ] 4 Report (gate)
- [ ] 5 Start on a yes
```

1. **Read settings.** Base branch: the settings, else the remote's default branch, else whichever of `main` or `master` exists.
2. **Look, read-only and cheap.** No builds, no test runs, no writes, no agents. With a shell: current branch, full HEAD sha, changed files against the merge base plus uncommitted ones, whether a pull request is open (the code host's CLI, if installed and authenticated; otherwise "PR: unknown"). Without one: `.git/HEAD` for the branch, `.git/refs/heads/<branch>` or `.git/logs/HEAD` for the sha and commits, and file globs. Without a shell there is no diff: infer the change from the branch's commit messages and the files they name, and say the diff is inferred. Then read the evidence files from the table above, test files for the changed code, and schema and migration files. Test results are a claim (commit message, the user, CI), never a run.
3. **Place the work.** Walk the stage table top-down. The current stage is the last one with current evidence, or one left half-done; the next stage is the first whose evidence is missing and that isn't skipped, which may be the half-done one. Evidence of a later stage (code in the diff, an open PR) marks explain, plan, and test design done, with `Plan:` saying what was found; it never marks verify, review, or land done, since those are what the evidence files are for. Signals that conflict (tests in the diff but no code, a pass report for another commit) get named, not guessed past.
4. **Report**, in this shape:

   ```
   Stage: <n> <name> — <evidence, one line>
   Plan: <confirmed <date> | unconfirmed | none (<why>)>
   Skipped: <stage (why)>, ...
   next: <n> <name> — <skill or command>
   Then: <the remaining stages, in order>
   ```

   A stopped line replaces the `next:` stage with `stopped (H5): <the failing check or missing item>` and the one thing that would restart it. Then **STOP — WAIT**: ask whether to start the next stage. `next:` names one stage; `Then:` is orientation, not a queue.
5. **Start on a yes.** A skill the model may invoke (walkthrough, grill-plan, design-tests, db-migration, live-verify, eval-loop, flow-diagram, land): invoke it. land merges only when its settings say `merge: auto` or the user says yes to the merge inside it, and takes the repo's land lock first; say so when routing to it. pr-review, pr-description, and build-workflow are user-started skills (they launch costly runs or publish); the platform blocks the model from invoking them, so print the exact command (`/shipyard-delivery:pr-review`, H4) for the user to run, and don't reproduce their steps by hand. Implement is the session's own: continue here.

## Arguments

- **A stage** (number, name, or skill name): jump to it. If its entry condition isn't met, say which and **STOP — WAIT** before starting it anyway. Jumping never skips the verify gate for review: say the report is missing or stale and let the user decide.
- **`all`**: hand the remaining stages to a multi-agent run: print `/shipyard-delivery:build-workflow <plan file> <remaining stages>`. It shows its own run plan and waits for a go.
- **Nothing**: steps 1 to 4.

Demo has no skill in this pack: when it comes next and the settings name none, say so, name it as the last stage, and stop; don't substitute another skill.

`next:` the stage the user confirms, through its own skill; this skill hands off and ends.
