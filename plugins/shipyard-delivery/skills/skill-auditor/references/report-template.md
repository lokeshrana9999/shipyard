# Report template

Fill this shape. Sections appear in this order; drop "Cross-cutting issues" in single-skill mode.

````markdown
# Skills Audit

Run: <YYYY-MM-DD>. Scope: <single skill <path> | N skills under <path>>.
Conventions: <overlay .claude/shipyard/skill-auditor.md | inferred from audited set: <what was inferred>>.
Schema check: <validator used: pass / N errors / not run (reason)>.

## Scorecard

| Skill | Lines | Frontmatter | Structure | Length | Gates | Instructions | Anti-patterns | Fit | Wordiness | Max severity | Top issue |
|---|---|---|---|---|---|---|---|---|---|---|---|
| <name> | <raw> (<substantive>) | ✓/⚠/✗ | ✓/⚠/✗ | ✓/⚠/✗ | ✓/⚠/✗/n/a | ✓/⚠/✗ | ✓/⚠/✗ | Bullseye/Acceptable/Misfit | ✓/⚠/✗ | low/medium/high | <one line> |

✓ no findings above low · ⚠ medium findings · ✗ at least one high finding. Gates is n/a when the skill has no side effects. Max severity is the highest finding for that skill; the detail below may list several.

## Cross-cutting issues

- **<pattern>** — <skills affected>. <why it matters, what to change>.

Common ones: fossilized paths, inconsistent gate markers, missing inputs/output contracts, orchestrator routing inside stage skills. Also report combined listing weight (total description + when_to_use characters, longest three).

## Top 5 fixes

1. **<what>** in <where>. <why it ranks #1: severity × skills affected>.

## What's well-designed

- **<pattern>** (<skill>) — <why it works; keep it>.

## Per-skill detail

### <skill-name>

**Frontmatter (⚠)**
- *(medium)* `SKILL.md:3` "<quote>" — <finding>. → <remediation>.
- *(medium, prediction)* `SKILL.md:3` — <runtime claim>. Settle with: <eval / check>.

<repeat per dimension; write "No findings." for a clean dimension so it reads as checked>

**Abstraction fit: <verdict>** — <reasoning>. → <recommendation>.

#### Negative-phrasing rules

| # | Location | Quoted rule | Positive rewrite, or "keep — genuine prohibition" |
|---|---|---|---|
| 1 | `SKILL.md:40` | "Don't paraphrase bullets" | "Quote bullets verbatim." |
| 2 | `SKILL.md:52` | "Never push to main without approval" | keep — genuine prohibition, rationale stated |
````

Example of a finding at the right level of detail:

> *(high)* `SKILL.md:2` `description: >` folded over three lines — multi-line descriptions have been reported to make skills silently undiscoverable. → Put the description on one line.

And one too vague to act on:

> *(medium)* Description could be better.
