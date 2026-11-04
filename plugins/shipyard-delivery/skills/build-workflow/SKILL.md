---
name: build-workflow
description: Runs a plan, the remaining delivery stages, or another multi-step job as one multi-agent run, after deciding whether one agent is enough, with capped fix loops and a separate verifier; or writes one agent or sub-session brief from its template. Takes a goal or plan file, the stages to run, `go` to skip the run-plan approval, or `brief <entry>`. Run only when the user asks for it.
argument-hint: "[goal | plan file] [stages to run] [go | brief <entry>]"
disable-model-invocation: true
---

# Build workflow

Plan and run a multi-agent job so every agent does work one agent couldn't do as well, every result is something the run branches on, and "stuck" is reported as stuck. Multi-agent runs cost many times the tokens of one agent and hurt tightly coupled, sequential work, so the first decision is whether to run one at all.

This skill launches many agents, so it runs only when the user invokes it; that invocation, plus a go on the run plan, is the opt-in for the run and its cost.

## Inputs

- **The goal**: a plan file, a spec, or the job as the user describes it. Which stages to run, if the user names them. `go` skips the plan approval, for headless runs that can't answer a stop. `brief <entry>` asks for one brief instead of a run (see Brief only).
- **Project settings**: on every invocation, read `.claude/shipyard/build-workflow.md` in the project root if it exists; its settings win over the defaults here. It can set stage commands, default stages, caps, a status file path, invariants, and isolation rules. Its shape is in [references/overlay-example.md](references/overlay-example.md).

## Stages

| Stage | Who runs it | Shape |
|---|---|---|
| Pre-flight | one read-only agent checks the tree, plan, commands, and tools, and writes the shared orientation (subsystem map, HEAD, test baseline) | single |
| Test design | `test-designer`, one per slice | parallel, read-only |
| Implement | general-purpose subagent, one call per plan entry | serial; parallel only in separate worktrees |
| Verify live | `live-verifier`, after every commit lands | single, serialized |
| Review | pr-review's pipeline: `concern-reviewer` per slice of the diff maps and reviews concerns, `review-verifier` validates every finding; the report is compiled mechanically | slices in parallel, then validate, all as siblings |
| Describe | the session drafts the description from pr-description's body template; the skill itself is user-started | single |

The orientation is written by an agent, not the walkthrough skill, because its readers are other agents, not a person. Where a named agent isn't available, give a general-purpose subagent the agent file's body as its prompt. Skip a stage another already covers: a test-first implementer makes a separate test-design pass redundant for that entry. Agent counts and caps are in [references/loops.md](references/loops.md).

## Rules

- **Every stage is a direct child of the orchestrator**, never a grandchild. A stage handles in-run recoveries (fix, retry, rescope) itself by the four-action rule, without starting a subagent; only a blocker it can't recover from returns `blocked`, and the orchestrator's decision agent decides it. Review's agents run as siblings under the orchestrator.
- **Every result is branched on.** The orchestrator maps each stage's raw return to `{status: pass | pass-with-gap | blocked | halt, gaps, reason}` by the table in [references/briefs.md](references/briefs.md), and has an `if` for every value. A field nothing reads is a label, not a gate; delete it.
- **Blocked is a correct result.** A pass the stage didn't observe is the only wrong answer.
- **Check the goal, not the tests.** The verifier checks the result against the plan entry or spec, not only that tests pass.
- **Every agent runs on the model of the session that invoked the skill.** The run plan doesn't pick models per stage. A fix is checked by a separate agent that didn't write it and doesn't see its reasoning (loops.md).
- **Every brief comes from the template** in [references/brief-template.md](references/brief-template.md): background, task, interfaces and call order, files owned, constraints (no new caps, defaults, or facts: they go in as questions), autonomy with the always-ask list, model per role, and the report file the parent checks for. A brief typed from memory is where invented caps and unverifiable "done" messages come from.
- **One child per shared resource.** A browser profile, a shared checkout, a deploy target, a database, an eval runner over one case set: exactly one active child holds each at a time, and its brief says so. Children that write in parallel own disjoint files and their own worktrees, never a shared checkout. These are correctness rules, not a cap: two writers on one resource produce wrong results at any volume, so the number of children is unlimited and the number touching one thing is one.
- **A child that hasn't started isn't running.** Within 2 minutes (default: longer than a cold start, shorter than the parent's next stage) of starting a child, confirm its first move. One that hasn't moved is blocked on something only a person can do; batch those into one user step (H8) instead of waiting on it (brief-template.md).

Tests read-only to fixers, the skeptic verifier, loop caps, and exclusive resources are in loops.md; cheap fact checks and never cleaning up are in briefs.md.

## Steps

```
- [ ] 1 Read settings and the goal
- [ ] 2 Decide: one agent or a run
- [ ] 3 Pick the runtime mode
- [ ] 4 Plan the run
- [ ] 5 Pre-flight
- [ ] 6 Run the stages
- [ ] 7 Report
```

1. **Read settings and the goal.** Settings first, then the plan or spec. Compute the shared context once (the diff, the plan entries verbatim, the changed files) so no agent re-derives it.
2. **Decide whether to run at all.** Use one agent when the work is one tightly coupled change, a sequence where each step needs the last one's full context, or small enough that one agent does it well; say so and end with a `next:` line whose first words name the stage for that work: `implement` in this session, or a stage skill (design-tests, live-verify, pr-review). Use a run when the work splits into independent pieces, needs an independent check, or is too big for one context; size it by loops.md.
3. **Pick the runtime mode**, per [references/runtime.md](references/runtime.md).
4. **Plan the run.** For each stage: its agent, inputs, return mapping, isolation, and the exclusive resources it holds. Show the plan in this shape, then **STOP — WAIT** for a go, unless the user passed `go`; the cost is the reason.

   ```
   Run plan (mode <n>: <why>)
   - <Stage>: <agent name> x<count>, <parallel | serial | worktree>
   - <Stage>: held (<why: settings, user, or no input>)
   Agents: <total> of a cap of <cap>   (review's own agents counted separately)
   Shared resources: <resource>: <the one agent that holds it>, ...
   Loop caps: <n> fix rounds per entry, <n> review fix rounds
   Reply `go` to start, or name stages to drop.
   ```

   Name each agent (`test-designer`, `review-verifier`, a general-purpose implementer); a held stage gets its stage name only. With no cap in the settings, the `Agents:` line reads `Agents: <total>, no cap; expected cost: <one line>` instead, and the run proceeds at that size. If the plan won't fit a set cap, say how it splits into runs. If step 2 already chose one agent, don't show a run plan.
5. **Pre-flight**, before any expensive agent: the tree and HEAD are what the plan assumes, the plan isn't landed or closed, stage commands and tools exist, and the orientation is written. A failure ends the run as `blocked` with its reason.
6. **Run the stages** with [references/briefs.md](references/briefs.md) and loops.md, every brief in the template's shape. After starting each child, run the start check; record each child in flight in the status file. Verify live runs once, after every commit lands. In modes 2 and 3, append one line to `STATUS.md` at each stage transition (briefs.md); in mode 1, only when the settings name a status path.
7. **Report**: one line per stage with its status, commits landed, open gaps, blocked lanes, stages held or not run, and the agent count, then `Checked:` / `Not checked:` lines. Pushing, merging, and opening a pull request are **HUMAN TRIGGER**: the run drafts the description and stops.

Steps are agent-owned unless marked.

## Brief only

`brief <entry>` (a plan entry, or a goal in the user's words) writes one brief from [references/brief-template.md](references/brief-template.md) and stops: no run plan, no agents. Read the settings and the plan as in step 1, fill every section, list each cap, default, or fact the plan doesn't give as a question in the brief, and write the brief where the user says (default: `briefs/<entry>.md` next to the plan). The user starts the child, so the start check and the report check are theirs; say so in one line.

## Handoff

`next:` a clean run goes to the describe stage (pr-description) if it didn't run; a blocked or halted run goes back to the user with the blocker and the run's trail.
