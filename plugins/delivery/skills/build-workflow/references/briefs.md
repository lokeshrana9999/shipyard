# Agent briefs

Contents: how to brief · status mapping · the shared prefix · the no-cleanup block · pre-flight · test design · implement · fixer · goal verifier · verify live · review · decision · beacon

## How to brief

- **Give each agent the text itself**: the plan entry, the orientation, the findings. Agents that re-derive context spend most of their calls before the first useful one. Large files (the spec, a long plan) go by path.
- **A byte-stable prefix, then a divider, then the per-item facts.** The prefix is identical for every agent of a stage, so it's cached; anything that varies goes after the divider.
- **Short output.** Ask for the return shape and nothing else; cap free text to a few sentences.
- **Name the one rule a stage needs** rather than pasting the project's whole instructions file; subagents usually load that file already.

## Status mapping

Stages return their own shapes. The orchestrator maps each to `{status, gaps, reason}` and branches on that plus the fields listed as read. An agent call that returns nothing, or a malformed result after one re-ask, is `blocked`.

| Stage | Raw return | Maps to | Fields the run reads |
|---|---|---|---|
| Pre-flight | `{head, planClosed, entryLanded, toolsMissing, map, baseline, reason}` | `planClosed`, `entryLanded`, or any `toolsMissing` → blocked; no `map` → pass-with-gap; else pass | `head`, `map`, `baseline` into every later brief |
| Test design | document with `status: complete \| partial \| blocked` | complete → pass; partial or blocked → pass-with-gap on that slice | the document, into that slice's implement briefs |
| Implement | `{committed, sha, testPassed, summary, blocker}` | `committed: false` or `testPassed: false` → blocked with `blocker`; else pass | `sha` (new HEAD), `summary` (into later briefs) |
| Fixer | implement's shape plus `closed: [ids]` | as implement | `sha` (the verifier's diff), `closed` (what the verifier checks) |
| Goal verifier | `{status, gaps, violations, reason}` | as returned | `violations` (into the fixer brief) |
| Verify live | `live-verifier`'s `{verdict, checks, notExercised, errors, ...}` | `fail` → blocked with the failed `checks`; `blocked` → blocked with `errors`; `pass` → pass, or pass-with-gap when `notExercised` is non-empty or a check is `not run` | failed `checks` (into the fixer brief), `errors`, `notExercised` as gaps |
| Review | pr-review's report, compiled from `review-verifier`'s confirmed findings, and its coverage line | a confirmed `bug`, or a broken funnel, → blocked; else pass | bug findings (into the fixer brief); issues and nits go to the report |
| Describe | the drafted description | drafted → pass; else blocked | the description, into the report |

`halt` comes from the goal verifier (a false premise) or a decision of `abort`. Anything a stage returns that the table doesn't read (`live-verifier`'s `environment` and `decision`) is copied into the report unread.

## The shared prefix

Every brief starts with these lines, adapted to the stage:

```
You are one stage of a multi-agent run. Do only this stage's job; don't start subagents.
If you hit a blocker, recover yourself: fix your own setup, retry once, or narrow the scope and
record what you dropped. Return blocked, with the real reason, only when none of those works.
Return exactly the shape at the end. A pass you didn't observe is the only wrong result.
Before trusting the facts below, check two cheaply: HEAD is <sha>, and the paths named below exist.
If either is wrong, say so in your result and derive what you need.
```

Agents that hold an exclusive resource (loops.md) also get: "You are the only agent using <resource> right now." If that would be false, don't dispatch the agent yet.

## The no-cleanup block

Paste into every brief for an agent that can write or run commands:

```
Never delete, drop, reset, or remove data, artifacts, or history: no dropping tables or volumes,
no deleting logs, evidence, dependencies, branches, worktrees, or stashes, no hard resets or
forced checkouts, and never amend or revert another agent's commit. Adding is always fine.
The one exception: restarting a process of your own role so it serves the code just committed.
Find it by the port it listens on, stop that one process, never all processes of one name,
confirm the port is free, start it, and read its error log: an "address in use" error means
the old process is still answering and every result after it is stale.
```

A process that answers isn't necessarily the right process. Check readiness with a response only the current build and database can give (the seeded test user in an authenticated reply, or an asset hash matching HEAD), not a bare success status.

## Pre-flight

Read-only, once per run. It checks the plan's status header and first entry, git log and the tree for the first entry's change, and each stage's commands and tools, quoting the command and output that settled each fact in `reason`. It also writes the orientation every later brief pastes: a subsystem map of 30 to 60 lines (each file that matters, what it owns, how they connect), HEAD, and one line naming what's green at HEAD (the test baseline), so a later red is attributable to the change.

## Test design

The `test-designer` agent, one per slice, in parallel. After the divider: the slice, the spec's acceptance criteria for it, and the orientation. An incomplete design becomes a gap on that slice, and its implementers are told the design is incomplete.

## Implement

A general-purpose subagent, one call per plan entry.

Prefix (identical for every entry): the shared prefix, the no-cleanup block, the project's invariants from the settings, the stage commands, and:

```
Implement exactly one plan entry and commit it, nothing from later entries.
Write or update this entry's tests first, then the change; run only the tests you touched plus
the typecheck and lint for the package. Stage only the paths you changed, never everything.
The commit message describes the change for someone who never saw the plan: no entry ids.
If you can't land a clean, tested commit, return committed: false with the blocker.
```

After the divider: the plan entry verbatim, HEAD, the test baseline, one-line summaries of the commits already landed in this run, the test design for its slice if there is one, and any rescope or fix instruction.

## Fixer

Same prefix as implement. After the divider: exactly the violations or confirmed findings to close, each with its location, and the test files it may not touch (loops.md, read-only tests).

## Goal verifier

A separate agent from the implementer or fixer whose commit it checks, given the diff but not their reasoning. Read-only, one per landed commit. It reads the commit's diff and checks, in order: the diff does what the entry says (not something adjacent); every file is within the entry's scope; no earlier commit's change was undone; each new test reaches the code through its real wiring (a registry, a route, a module) rather than calling a handler directly or asserting through a mock of the thing under test; and, after a fix, tests weren't weakened: in the tree the fixer worked in, `git diff <pre-fix-sha> -- <test paths>` shows no change to an existing test. A gap names only what wasn't established and what would establish it, never "probably fine".

## Verify live

The `live-verifier` agent, once, after every commit lands, holding the browser, ports, and database alone. After the divider: the diff range, the mode, the spec's observable outcomes, and: "Inside this run, don't start a decision subagent, even though your instructions allow one: decide blockers yourself by your fix, retry, rescope, abort rules."

## Review

pr-review's two stages, each agent a sibling under the orchestrator: one `concern-reviewer` per slice of the diff maps catalog concerns to its added lines and reviews them, in parallel; a mechanical check drops findings whose evidence line isn't in the diff; one `review-verifier` validates every surviving finding. The report is compiled mechanically from confirmed findings; the slicing rule and caps are in pr-review's `references/stages.md`, schemas in its `references/workflow.js`. Only confirmed bugs drive a fix loop.

## Decision

A separate agent from the stage that blocked. Input: the stage, the blocker, what landed so far, and what was already tried. Returns `{action: fix | retry | rescope | abort, rationale}`, the same four actions as `live-verifier`:

- `fix`: correct the setup or the brief, then rerun the stage once;
- `retry`: rerun once, unchanged;
- `rescope`: rerun a narrower scope it names, keeping what was dropped as a gap, so the run can't report a full pass;
- `abort`: `halt`; stop and report what's real so far.

A plan entry that correctly shouldn't exist (its condition didn't fire, or the bug it targets isn't there) is a `rescope` to nothing, recorded as a planned skip, not an abort.

## Beacon

In modes 2 and 3 the orchestrator appends one line to `STATUS.md` itself (where the settings say, default next to the plan), never overwriting. In mode 1 the script can't write files, so it appends through a one-line agent only when the settings name a status path; otherwise it uses the runner's phases and log lines.

```
<UTC time> | stage 3/6 implement | entries landed 4/7 | last gate: verify pass | next: entry 5
```

A failed append is logged and ignored.
