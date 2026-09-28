# Sources: build-workflow

Provenance for `skills/build-workflow/`. Kept outside the skill folder so it never loads into context.

The archived original was a checklist for writing one workflow script that hardens a diff. The port widens it to designing and running a run across the delivery stages on three runtimes, and moves the detail into references.

## Kept from the original

- Gate loops on merge blockers only, exit when there are none; report non-blockers without acting (loops.md "What drives a loop").
- Adaptive depth with capped rounds instead of an always-max loop.
- Compute shared context once and pass it down (SKILL.md step 1, briefs.md "How to brief").
- Pre-flight before expensive agents, an honest `blocked` short-circuit, reuse of a warm stack.
- Cheap by default: no agent that doesn't change what the run branches on. (The original's per-stage model routing is superseded; see Port decisions.)
- Honesty schemas: every field has an `if` that reads it; stuck routes to a decision agent with `{action, rationale}`.
- A lane blocked twice stops the run ("deferred once, never twice").
- Verify live only after all commits land.
- Fold overlapping stages (a test-first implementer makes a separate test-design pass redundant).
- The `STATUS.md` beacon: append-only, one line per transition answering what's running, what landed, what's next; it can't fail the run. Demoted in the port to plain appends by the orchestrator in modes 2 and 3, and in mode 1 only when the settings name a status path, since the runner's phases and log already show progress.
- Exclusive resources named and serialized, with the "only agent" clause.
- The reconciled no-cleanup rule with its one exception (restart your own process by port, never by name), and "liveness isn't identity" readiness checks.

## Taken from the original's workflow scripts

- The uniform stage contract `{status: pass | pass-with-gap | blocked | halt, gaps, reason}`, gaps that state only what wasn't proven, and branching on reported facts rather than the agent's own status. The pack's agents return their own shapes, so the port has the orchestrator map each raw return to the contract (briefs.md "Status mapping") instead of requiring every stage to return it.
- The per-commit goal verifier's checks: intent mismatch, scope creep, clobbering a prior commit, tests that don't reach the code through its wiring.
- Pre-flight refusing a closed or already-landed plan before any implementer runs.
- A planned no-op entry recorded as a skip, not an abort.
- Pairing a read-only attacker with a write-capable fixer, then re-running the same attack.
- Held stages, and refusing a stage selection that excludes another stage's input.
- Defensive parsing of workflow arguments that arrive as a string.
- The implement briefing, recorded in the research notes below.

## From research

See [build-workflow-research.md](build-workflow-research.md) for the Workflow tool notes, the multi-agent research with links, and the implementer briefing rules. What it added: the decision whether to run multi-agent at all and effort scaling; the three runtime modes; first-class `blocked` exits; read-only tests for fixers; verifying the original goal; a separate skeptical verifier that didn't write the fix and doesn't see its reasoning; a 2-to-3 round cap; rescope or abort on no progress; health checks at agent start; worktree isolation with declared scope and a merge-time verify; the implement brief.

One conflict with the research notes: they say the workflow runner has no per-agent worktree isolation, while the workflow-authoring reference loaded during the port documents a per-call worktree option and an agent-type option. The skill defers exact syntax to that reference and says "where the runner offers it".

One tension with the research: context-engineering guidance says to pass references plus a short brief, not pasted dumps, while the implementer audit found agents re-deriving context when handed paths. The skill pastes the small, stable things (the plan entry, HEAD, prior commit summaries, the orientation) and references large files (the spec, a long plan) by path.

## Port decisions (as of 2026-09-28)

- The original's explain stage is merged into pre-flight: one read-only agent runs the checks and writes the orientation. It's an agent, not the walkthrough skill, because its readers are other agents.
- Stages recover in-run (fix, retry, rescope) themselves; only an unrecoverable blocker returns `blocked` for the orchestrator's decision agent. `live-verifier` is told not to start its own decision subagent inside a run.
- Agent caps exclude the review stage, which keeps pr-review's caps; a cap never weakens a check, and a run that would need it to is split instead.
- A mode 1 script can't run git, so the test-file check (a diff against the pre-fix sha, which catches committed changes a working-tree diff misses) is part of the goal verifier, and worktree merges go to a merge agent.
- Every agent runs on the model of the session that invoked the skill (`model: inherit` for the named agents); the skill names no models or tiers. The only allowed exceptions, stated once in loops.md: fan-out agents that only read and summarize files, and bringing up the stack before `live-verifier` runs, may use a smaller, faster model. This supersedes the original's model routing and the port's earlier four-tier scheme (cheapest, mid, stronger, strongest), including "verifier one tier above the fixer" and "escalate one tier on no progress".
- The review stage follows pr-review's rebuild: `review-mapper` maps concerns to added lines, general-purpose reviewers check them in parallel, and `review-verifier` validates every finding, all as siblings under the orchestrator; the report is compiled mechanically. `review-scorer` no longer exists.
- A `go` argument skips the plan approval stop, for headless runs; the stop stays by default.
- Choosing one agent ends with `next:` naming the matching stage skill rather than a bare stop.

## Dropped as project-specific

- The original's stage list (plan attack, slice smoke, API tests, browser story, triage, CI parity, publish) is replaced by the pack's six stages.
- Hardcoded worktree and plan paths, architecture invariants, and decision records pasted into prompts; invariants became a settings entry.
- A per-commit implementer agent and a commit-method skill, both dropped from the pack earlier.
- Pinned model names per stage (superseded history; the skill now runs every agent on the invoking model, see Port decisions).
- Publishing the pull request from inside the run; the port stops at a drafted description (HUMAN TRIGGER).
- Notes on invoking scripts by path because of one repository's excluded workflow folder.

## Specifics removed from the skill (as of 2026-09-28)

- The original named port numbers for its dev stack, a browser MCP by name, and a document database's remote cluster warning.
- Its process-restart recipe was Windows PowerShell: find the listener with the TCP connection cmdlet, read the command line through the process CIM class, then stop that one PID; it warned against killing all `node.exe` processes by image name and against `EADDRINUSE` in the new process's log.
- Its no-cleanup list named `docker compose down`, `prune`, `DROP`/`TRUNCATE`, migrate reset, `git clean`, `git reset --hard`, `git checkout -- .`, and `stash drop`.
- Identity check examples: an authenticated call returning the seeded user, or a served asset hash matching `git log -1 --format=%H`.
- Model routing, superseded history (the skill now runs every agent on the invoking model): the strongest model (then Opus) for attack and decisions, a mid model (then Sonnet) for implement, fix, and verify, the smallest (then Haiku) for pre-flight and the beacon.
- Workflow runner gotchas at the time: scripts can't call `Date.now()`, `Math.random()`, or argless `new Date()`; `agent()` returns `null` on a skipped or dead agent; concurrency is capped per workflow; nesting via `workflow()` is one level.
- The multi-agent token multiple (about 15x a chat) and the repair-round figures come from the research notes.
