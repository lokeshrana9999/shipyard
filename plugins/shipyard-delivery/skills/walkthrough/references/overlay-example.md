# Project settings example

A project keeps this at `.claude/shipyard/walkthrough.md`. Every setting is optional; anything left out keeps the default in SKILL.md.

```markdown
# walkthrough settings

- reader: newcomer
- length ceiling: 60 lines
- headings: sentence case
- avoid: "leverage", "synergy", internal codenames in docs meant for customers
- cold-read check: handoffs and specs only
```

- `reader: newcomer` adds one short line of *why* to each step and defines project terms on first use. Terse steps help experts but leave newcomers without the reasoning they need to act. The default is `experienced`.
- `length ceiling` replaces the ~40-line default, per reply and per `##` section in a document.
- `headings` replaces the lowercase-fragment default.
- `avoid` adds to `references/writing-tells.md`.
- `cold-read check` narrows or widens which documents get it (default: plans, handoffs, and specs someone else will act on).
