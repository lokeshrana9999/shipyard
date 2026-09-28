# Project settings example

A project keeps this at `.claude/shipyard/flow-diagram.md`. Every setting is optional; anything left out falls back to the default in SKILL.md.

```markdown
# flow-diagram settings

- destinations:
  - docs/ pages: mermaid (published to our docs site)
  - PR and issue descriptions: mermaid
  - markdown elsewhere in the repo: mermaid (we read the repo rendered)
  - chat replies: ascii
- renderer limits:
  - our wiki renderer is on an old Mermaid: use `graph`, no `flowchart`
  - no `<br/>` or other HTML in labels
- ascii max width: 72
- max size: mermaid 12 nodes, ascii 8 edges
- validate mermaid: yes (when a parser or validator is available)
- palette: default
```

A "renderer limits" entry adds to the portable rules in `references/mermaid-syntax.md`; it can also relax one when the project's renderer is known to support more (for example newer node-shape syntax). A custom palette replaces the default `classDef` block and must still meet the palette rules in SKILL.md: lightness as well as hue differences, accessible text contrast on every fill, and a stroke visible on light and dark pages.
