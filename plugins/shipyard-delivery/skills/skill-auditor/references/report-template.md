# Report template

Fill this shape. Sections appear in this order; drop "Cross-cutting issues" in single-skill mode.

````markdown
# Skills Audit

Run: <YYYY-MM-DD>. Scope: <single skill <path> | N skills under <path>>.
Conventions: <settings file .claude/shipyard/skill-auditor.md | inferred from audited set: <what was inferred>>.
Schema check: <validator used: pass / N errors / not run (reason)>.

## Scorecard

| Skill | Lines | Frontmatter | Structure | Length | Gates | Instructions | Anti-patterns | Fit | Wordiness | Max severity | Top issue |
|---|---|---|---|---|---|---|---|---|---|---|---|
| <name> | <raw> (<substantive>) | ✓/⚠/✗ | ✓/⚠/✗ | ✓/⚠/✗ | ✓/⚠/✗/n/a | ✓/⚠/✗ | ✓/⚠/✗ | Bullseye/Acceptable/Misfit | ✓/⚠/✗ | low/medium/high | <one line> |

✓ no findings above low · ⚠ medium findings · ✗ at least one high finding. Gates is n/a when the skill has no side effects. Max severity is the highest finding for that skill; the detail below may list several.

## Cross-cutting issues

| Pattern | Skills affected | Why it matters and what to change |
|---|---|---|
| <pattern> | <skills> | <why it matters>. <what to change> |

Examples: fossilized paths, inconsistent gate markers, missing inputs/output contracts, orchestrator routing inside stage skills. Also report combined listing weight (total description + when_to_use characters, longest three).

## Top 5 fixes

Ranked by highest severity first, then by the number of skills affected.

| # | Fix | Where | Severity | Skills affected |
|---|---|---|---|---|
| 1 | <what to change> | <where> | <highest severity it clears> | <N> |

## What's well-designed

- <pattern> (<skill>): <why it works; keep it>.

## Per-skill detail

### <skill-name>

#### Frontmatter (⚠)

| Location | Severity | Finding | Fix |
|---|---|---|---|
| `SKILL.md:3` | medium | "<quote>": <finding> | <remediation> |
| `SKILL.md:3` | medium, prediction | <runtime claim> | Settle with: <eval / check> |

<repeat per dimension; write "No findings." for a clean dimension so it reads as checked>

#### Abstraction fit: <verdict>

<reasoning>. Recommendation: <recommendation>.

#### Negative-phrasing rules

| # | Location | Quoted rule | Positive rewrite, or "keep: genuine prohibition" |
|---|---|---|---|
| 1 | `SKILL.md:40` | "Don't paraphrase bullets" | "Quote bullets verbatim." |
| 2 | `SKILL.md:52` | "Never push to main without approval" | keep: genuine prohibition, rationale stated |
````

Example of a finding at the right level of detail:

| Location | Severity | Finding | Fix |
|---|---|---|---|
| `SKILL.md:3` | high | "Deploys the current branch to production.": a production deploy with no `disable-model-invocation: true`, so Claude can start it on its own when the code looks ready | Add `disable-model-invocation: true` to the frontmatter |

And one too vague to act on:

| Location | Severity | Finding | Fix |
|---|---|---|---|
| | medium | Description could be better. | |
