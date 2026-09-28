# Overlay example

The consuming project keeps this at `.claude/shipyard/skill-auditor.md`. Every key is optional; a missing key falls back to the default in SKILL.md (scan roots, report path) or `dimensions.md` (gate markers, section names).

```markdown
# skill-auditor overlay

- scan roots: .claude/skills/, tools/agents/skills/
- report path: docs/audits/SKILLS-AUDIT.md
- published beyond Claude Code: no
- gate markers:
  - approval: STOP — WAIT
  - user does work: HUMAN TRIGGER
  - agent proceeds: NO STOP — Agent-owned
- section names: Inputs, Output, Rules, Steps
- accepted deviations:
  - Skills under tools/agents/ use "When" instead of "Inputs"; keep it.
  - Long reference tables in db-migrate/ are intentional; don't flag length.
```

`published beyond Claude Code: yes` raises portability findings (dimension 1) from medium to high. Accepted deviations are reported as low at most, with a pointer to this file.
