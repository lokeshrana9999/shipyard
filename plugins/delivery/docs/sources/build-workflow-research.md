# Research notes: build-workflow (deferred)

Gathered 2026-09-27, before the port was deferred until the generic agents exist. Use these when porting `build-workflow`; re-verify version-bound facts then.

Superseded (2026-09-28): the model-routing suggestions below (a stronger reviewer, "escalate model", a stronger-model decision) are history. The skill runs every agent on the invoking session's model; independence comes from a separate verifier that doesn't see the fixer's reasoning.

## Workflow tool (official docs, https://code.claude.com/docs/en/workflows.md)

- Generally available on paid plans; a built-in workflow-authoring skill covers script syntax, API, schema patterns, examples, and gotchas (no dynamic import, no mid-run user input, no filesystem access from the script, `Date.now()`/`Math.random()` throw). The port should defer API syntax to it and keep only design principles.
- API: `agent(prompt, {schema, label, model, phase})` returns null if stopped; structured output validated with retries; `parallel()` for concurrent agents; `pipeline()` per item; `phase()` titles must match `meta.phases`; `log()`; `args` global.
- No per-agent worktree isolation field; parallel writers are the script's problem, so "serialize writers of exclusive resources" is still needed.
- Progress: a `/workflows` view shows phases, agent counts, tokens, elapsed time, but there's no status file or notification primitive, so the STATUS.md beacon principle still adds value.
- Resume replays cached agents in order until the first changed prompt; same session only.
- No hard cost cap; a large-workflow advisory only. Model precedence: per-call, then script, then env default, then session.
- Official guidance does not cover: blocker-gated loops, capped adaptive rounds, honest-failure schemas with branches on every field, blocked-twice escalation, verify-after-land, pre-flight health checks, restart-own-process rule. These are the skill's genuine additions.

## Multi-agent orchestration research

- Fake green is common: in tests made to contradict the spec, strong models cheated about half the time, mostly by editing tests; read-only tests, strict prompts, and an explicit flag-for-human exit cut it sharply, while retrying against test feedback raised it (ImpossibleBench 2025): https://arxiv.org/abs/2510.20270. Add: first-class `blocked`/`flag_for_human` exit, tests read-only for fixers (or diff and fail on change).
- Long-running harnesses: agents declare victory early and delete tests; fixes are pass fields that start false, "never edit tests", end-to-end checks, and a health check at each agent's start (Anthropic, Nov 2025): https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Multi-agent failure taxonomy: step repetition, unknown termination, reasoning/action mismatch, incorrect or missing verification; a verifier that checks the original goal (not just "tests pass") helps (MAST, Cemri et al. 2025): https://arxiv.org/abs/2503.13657
- Separate skeptical evaluators beat self-critique; evaluators pay off only near the edge of model capability, so make review stages conditional on difficulty and re-test each stage when models change (Anthropic, Mar 2026): https://www.anthropic.com/engineering/harness-design-long-running-apps
- Self-repair is bottlenecked by feedback quality; a stronger reviewer helps (Olausson et al., ICLR 2024): https://arxiv.org/abs/2306.09896. A weaker reviewer can make results worse (2026, weak): https://arxiv.org/abs/2607.21656. Self-correction without outside feedback often hurts (Huang et al., ICLR 2024): https://arxiv.org/abs/2310.01798
- Most repair gains come in the first two rounds (2026): https://arxiv.org/abs/2604.10508. Supports a cap of 2–3.
- Multi-agent costs ~15x chat tokens and suits breadth-first work, not tightly coupled coding; state effort-scaling rules (Anthropic, Jun 2025): https://www.anthropic.com/engineering/multi-agent-research-system
- Independent parallel agents amplify errors far more than a central orchestrator; multi-agent hurts sequential planning; little gain once one agent already does well (Google/MIT, Dec 2025): https://arxiv.org/abs/2512.08296. Add: prefer one agent for sequential tasks.
- Start simple; evaluator-optimizer needs clear criteria (Anthropic, Dec 2024): https://www.anthropic.com/engineering/building-effective-agents
- Context rot: pass references plus a short brief instead of pasted dumps; cap subagent output (Anthropic, Sep 2025): https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Routing for agentic coding works when a cheap model probes a few turns before deciding to escalate (SWE-Router 2026): https://arxiv.org/abs/2607.00053. (Superseded: the skill rescopes or aborts on no progress instead.)
- Parallel writers: 28% of agent PRs conflict (AgenticFlict 2026): https://arxiv.org/abs/2604.03551; worktrees isolate files but not semantic conflicts (2026, weak): https://arxiv.org/abs/2607.21909. Refine: worktree isolation is a valid alternative for file/git edits with declared scope and a merge-time verify; browsers, ports, databases still serialize.
- Limits: multi-agent helps breadth-first research a lot, and full harnesses can beat solo agents on hard tasks at much higher cost; "cheap by default" must not become "fewest tokens".

## Implementer briefing (from the dropped plan-commit-implementer agent, 2026-09-28)

The archived per-commit implementer agent was dropped: built-ins (`/batch`, plan mode, `isolation: worktree`) and superpowers' plain-subagent-per-task cover it, and its commit mechanics only worked around a since-dropped deny rule. Its archive audit found 91 spawns re-deriving context (median 19 tool calls before the first write). What survives is how the caller briefs an implement step:
- One plan entry per agent call; paste the entry text, the HEAD commit, and summaries of prior commits into the prompt, never a path to re-read.
- Keep a byte-stable prefix and put per-commit facts after a divider, for prompt caching.
- The agent checks two cheap facts (HEAD commit, the named paths exist) before trusting the handed context.
- It returns `{committed, sha, testPassed, summary}`; `committed: false` with a reason beats a faked green.
- A general-purpose subagent with worktree isolation (or the runner's agent call); blockers go to a separate decision agent with the same four actions as live-verifier (fix, retry, rescope, abort).
