# Runtime modes

Contents: choosing a mode · the nesting rule · mode 1: workflow script · mode 2: subagents · mode 3: flat spawn · no subagents · script skeleton

## Choosing a mode

Use the first mode the platform supports. The run plan says which mode it uses and why. Every agent call omits a model, so it runs on the invoking session's model (loops.md names the two exceptions).

| Mode | When | Parallel | Worktree isolation | Structured results |
|---|---|---|---|---|
| 1 Workflow script | the platform has a workflow runner and the user asked for the run | yes | per agent call, where the runner offers it | schema-validated |
| 2 Subagents | the session can start subagents (and several at once) | yes | where the subagent tool offers it | ask for JSON, validate it yourself |
| 3 Flat spawn | subagents exist but can't nest, or run one at a time | if the tool allows | usually not: serialize writers | ask for JSON, validate it yourself |

A workflow runner that needs the user's explicit opt-in gets it from the user invoking this skill and approving the run plan. Don't start a workflow the user didn't ask for; offer mode 2 instead.

## The nesting rule

Every stage agent is a direct child of whatever orchestrates: the workflow script in mode 1, the session in modes 2 and 3. That keeps the design portable (some platforms allow one level of subagents, some none) and keeps every result visible to the orchestrator that branches on it.

- A stage never starts subagents. Its brief says so.
- pr-review as a stage: the orchestrator runs its two stages itself, map-and-review per slice, then validate, with the mechanical evidence check between them. The parallel `concern-reviewer` agents and `review-verifier` are sibling agents; the report is compiled mechanically from the confirmed findings, in orchestrator code. The slicing rule and caps come from pr-review's `references/stages.md`, schemas from its `references/workflow.js`.
- Decisions: a stage recovers from a blocker itself (fix, retry, rescope) without starting a subagent; only a blocker it can't recover from returns `blocked`, and the orchestrator starts the decision agent (loops.md). `live-verifier`'s brief tells it not to start its own decision subagent.

## Mode 1: workflow script

Load the platform's workflow-authoring reference for the exact API before writing the script; the notes here are design patterns, not syntax.

- **One agent call per stage item.** Named agents go through the call's agent-type option; results come back schema-validated, so every schema lists only fields the script branches on.
- **The script can't read files, run git, or read the clock.** Pass the goal, settings, and shared context in the run's arguments, or let pre-flight collect them. Git work goes to agents: the goal verifier checks test files against the pre-fix sha, and a merge agent merges parallel worktrees (loops.md).
- **Arguments may arrive as a string.** Parse them if they're a string, and fail loudly if a required key is missing; a silent default aims the run at the wrong tree.
- **An agent call can return nothing** when the user skips it or it dies. Treat that as `blocked` with that reason, never as a pass.
- **Pipeline by default.** Use a barrier (wait for all) only when the next stage needs every result together: dedup across findings, or an early exit when there are none.
- **Worktree isolation per call** only for parallel writers; it costs setup time and disk.
- **Resume** replays cached agent calls up to the first changed one, so keep prompts byte-stable where you can and put per-item facts at the end.
- **Progress**: phases and log lines. Append to `STATUS.md` through a one-line agent only when the settings name a status path (briefs.md, beacon).

## Mode 2: subagents

The session is the orchestrator and holds the loop.

- Start independent stage items in one message so they run concurrently; start dependent ones only after reading the previous result.
- Use the named agent type where it's installed; otherwise a general-purpose subagent with the agent file's body pasted as the prompt.
- Ask for the return shape as one JSON block. Parse and check it against the schema; re-ask once on a malformed result, then treat it as `blocked`.
- Use worktree isolation for implement agents running in parallel. Merge their commits in plan order and run the merge-time verify (see loops.md).
- Run long stages in the background only when nothing else waits on them; the session must read every result before moving on.

## Mode 3: flat spawn

For tools where subagents run one level deep, or can't start other agents, or run one at a time.

- Use the platform's generated agent files for the named agents (see the plugin's `platforms/README.md`). Agents there run on the session's model too.
- The session spawns every stage itself, including each pr-review sibling. Where agents can't run in parallel, run them in stage order within the caps; if the caps would weaken a check, split the run (loops.md).
- Without worktree isolation, run implement agents serially in one tree.
- Read-only agents may only be read-only by instruction; diff the tree after each read-only stage and treat any change as a failed stage.

## No subagents

If the platform can't start agents at all, this skill doesn't run. Say so, and do the work in the session one stage at a time, running each stage's skill directly. The honesty rules still apply: the same schemas, the same caps, and a verify pass that re-reads the goal before reporting.

## Script skeleton

A mode 1 outline, to adapt, not to run as is. Syntax follows the workflow-authoring reference; `brief`, `toStatus` (the status mapping), and the schemas come from briefs.md, and `fixLoop` from loops.md.

```js
export const meta = {
  name: 'deliver-change',
  description: 'Pre-flight, test design per slice, implement per entry, verify live, review, with capped fix loops',
  phases: [
    { title: 'Pre-flight' }, { title: 'Test design' }, { title: 'Implement' },
    { title: 'Verify live' }, { title: 'Review' }, { title: 'Report' },
  ],
}

const A = typeof args === 'string' ? JSON.parse(args) : args
if (!A || !A.entries || !A.slices) throw new Error('args needs entries, slices')

const beacon = async (line) => {
  log(line)
  if (!A.statusPath) return
  try { await agent(`Append this line to ${A.statusPath}, prefixed with the current UTC time: ${line}`, { label: 'beacon' }) }
  catch (e) { log(`beacon failed, ignored: ${e}`) }
}

phase('Pre-flight')                        // checks and orientation in one read-only agent
const preRaw = await agent(brief('preflight', A), { schema: PREFLIGHT })
const pre = toStatus('preflight', preRaw)  // null -> blocked
if (pre.status === 'blocked' || pre.status === 'halt') return { status: pre.status, reason: pre.reason }
const orient = { head: preRaw.head, map: preRaw.map, baseline: preRaw.baseline }

phase('Test design')
const designs = (await parallel(A.slices.map(s => () =>
  agent(brief('test-design', A, orient, s), { agentType: 'test-designer', phase: 'Test design' })))).filter(Boolean)

phase('Implement')                         // serial, one tree; parallel writers need worktrees and a merge agent
let head = orient.head
const landed = []
for (const entry of A.entries) {
  const raw = await agent(brief('implement', A, orient, entry, head, landed, designs), { schema: IMPL })
  const r = await fixLoop(toStatus('implement', raw), raw, entry, head)   // separate goal verifier, capped rounds, decision on blocked; returns status, sha, summary
  if (r.status === 'halt' || r.status === 'blocked') { await beacon(`halt at ${entry.id}: ${r.reason}`); return summary(landed, r) }
  landed.push({ id: entry.id, sha: r.sha, summary: r.summary }); head = r.sha
  await beacon(`implement ${landed.length}/${A.entries.length} | last: ${entry.id} ${r.status} | next: ${A.entries[landed.length]?.id || 'verify live'}`)
}

phase('Verify live')                       // once, after every commit lands; holds the browser and ports
const live = toStatus('verify-live', await agent(brief('verify-live', A, orient, head), { agentType: 'live-verifier', schema: LIVE }))

phase('Review')                            // concern-reviewer slices, check, review-verifier as siblings, per pr-review's stages.md
const review = toStatus('review', await runReviewPipeline(A, head))

phase('Report')
return summary(landed, { live, review, designs })
```
