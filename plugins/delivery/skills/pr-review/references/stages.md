# Review stages

Contents: scope · slices · map and review · check · validate · report · running without a workflow runner

[workflow.js](workflow.js) is the executable form of this file: the prompts, schemas, slicing, check, and report template live there. Every agent runs on the model of the session that invoked the skill.

## Scope

`scope.sh` (in the skill folder) writes, into a scratch directory:

- `full.diff`: the unified diff against the base, three lines of context, limited to the review paths;
- `diff.txt`: added lines only, one per line as `path:line: code`, the line number in the new file.

It prints `files=N added=M`, and `No changes to review.` when `M` is 0. Git mode takes a worktree and a base ref (`main`, `origin/main`, a sha); `--diff <file>` takes a diff you already have. Review paths follow the out-dir; `:!path` excludes one.

Without a shell, build the same two payloads yourself from the diff, and count them with a tool, not by eye.

## Slices

Computed mechanically from `diff.txt`, no model. Defaults, each overridable in settings: slice size 400 added lines, agent cap 6, security-sensitive paths `auth`, `permission`, `payment`, `secret`, `tenant`, `tenancy` (a path containing any of them, case-insensitive; a settings list replaces the default).

1. **≤ 10 files and ≤ 400 added lines**: one slice, one agent.
2. **Otherwise**: files are grouped by top-level directory (root-level files form one group) and packed in path order into slices of about 400 added lines. A group joins the current slice while it fits, else starts a new one; a group bigger than a slice fills slices file by file. A file is never split.
3. **Security-sensitive files** are packed the same way into their own slices, never mixed with other files.
4. **Past the agent cap**, the slice size grows by a quarter at a time until the plan fits, and the run logs the old and new plan. Agents never exceed the cap.

## Map and review

One `concern-reviewer` agent per slice, all in parallel. Each gets the whole catalog (`catalog.md` for the format, every `catalog-*.md`, the project's `concerns.md`), its slice's added lines verbatim from `diff.txt`, the whole change's file list, the paths of `full.diff` and `diff.txt`, the CI-enforced rules and suppression markers, the security-sensitive paths, and the caller's focus. It reads the repository freely, outside its slice too, for callers, registries, config, and tests.

In one prompt, two explicit phases:

- **Map**: every concern with a site in its slice, each site as `location` (the `path:line` prefix verbatim from `diff.txt`) plus the code line. `applies-to` and `triggers` are hints, not filters. Adds `adhoc/<slug>` for a likely defect the catalog doesn't cover. A CI-enforced rule maps only where an added line carries its suppression marker.
- **Review**: for each mapped concern, read its sites, callers, callees, and tests; emit a finding only with a concrete failure scenario (what input or sequence, and what goes wrong), else clear it with a reason.

Returns:

```json
{
  "catalogConcernsRead": 0,
  "mapped": [{ "canonical_id": "domain/kebab-id", "source": "starter | project | adhoc", "sites": [{ "location": "path:line", "code_line": "..." }] }],
  "findings": [{ "canonical_id": "...", "severity": "bug | issue | nit", "location": "path:line", "evidence_line": "verbatim", "description": "failure scenario", "fix": "..." }],
  "cleared": [{ "canonical_id": "...", "reason": "..." }]
}
```

Every mapped id appears in `findings`, `cleared`, or both.

## Check

Mechanical, no model, between the two stages. Findings are numbered `F1`, `F2`, … across slices in slice order, then:

- **Evidence**: a finding whose `location` isn't an added line in `diff.txt`, or whose `evidence_line` isn't the code at that location (whitespace and backticks ignored), is dropped and counted as dropped.
- **Unreviewed**: a mapped id with no finding and no clearance in its slice is unreviewed; a slice whose agent died is unreviewed whole. Both are counted and listed under the coverage line, never hidden.

## Validate

One `review-verifier` agent at every size sees every surviving finding from every slice at once, without the reviewers' reasoning, so it can mark cross-slice duplicates. It returns `{ verdicts: [{ id, verdict (confirmed | false-positive | pre-existing | duplicate), duplicate_of, final_severity, reason }], ship_verdict }`.

It checks each `evidence_line` at its `location`, reads the real code, callers, and tests, checks the defect isn't already on the base, marks duplicates, and may downgrade severity. The ship verdict is one line from confirmed findings only. A finding it returns no verdict for is dropped as unvalidated and counted as rejected. With no finding surviving the check, validation doesn't run and the verdict is set mechanically.

## Report

Compiled mechanically, never rewritten by a model: confirmed findings only, at their `final_severity`, bugs first, cut at the findings cap (lowest severity dropped first, the cut stated). Each section says `- none` when empty.

```
## Bugs
- `path:line` — <description with failure scenario> Fix: <fix>
  > `<evidence_line>`

## Issues
- none

## Nits
- none

## Summary
X bugs · Y issues · Z nits. Verdict: <ship verdict> (advisory)
Coverage: <slices> slice(s); <catalog> concerns read; <mapped> mapped; <findings> findings (<dropped> dropped on evidence check); <confirmed> confirmed, <rejected> rejected; <unreviewed> unreviewed
Unreviewed: <id (slice n), ...>        (only when unreviewed > 0)
Pipeline: <workflow | subagents | inline (<why>)>.
```

`mapped` counts concern ids per slice (a concern mapped in two slices counts twice); `concerns read` is the largest count any reviewer reported. Every count comes from an agent's output or the check; a count nothing produced is `n/a`, never an estimate. If nothing maps, or every mapped concern clears, the report says so with zero findings. The rejected and dropped findings (id, location, verdict or reason) are kept for the audit trail and shown only if the user asks.

## Running without a workflow runner

Compute the slices with a tool (count added lines per file in `diff.txt`, e.g. `cut -d: -f1 diff.txt | uniq -c`), then dispatch from the session, each a direct child: one `concern-reviewer` per slice in parallel (plugin agents are namespaced, e.g. `delivery:concern-reviewer`) with the prompt from `workflow.js`; run the check yourself with a tool (look up each finding's `location` in `diff.txt`); then the `review-verifier` agent with every surviving finding. Fill the report template from the verifier's output, confirmed findings only, and print `Pipeline: subagents`.

Only when no subagent tool exists, run the stages yourself in the same order, one slice at a time, keep the same outputs, and print `Pipeline: inline (no subagent tool)`. Never imply a stage ran that didn't.
