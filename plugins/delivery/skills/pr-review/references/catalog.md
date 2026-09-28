# Concern catalog

Starter concerns each `concern-reviewer` agent maps onto its slice of a diff. Every reviewer reads every file; each stack file's `load-when:` line (path globs and manifest checks) tells it which stack the file is about.

Entry format:

```
- **<Concern name>** (`<domain>/<kebab-id>`, default <bug|issue|nit>): <what's wrong and why it matters>.
  - look-for: <concrete signal in a diff>
  - applies-to: <path globs; optional, absent means every file>
  - triggers: <literal tokens on an added line; optional, absent means always a candidate>
  - gate: <when NOT to flag; optional>
```

`applies-to` and `triggers` are hints for the reviewer's map phase about where a concern tends to show, not filters: a concern still maps when its `look-for` signal appears under another path or token. Mining uses them too, to check what the catalog would catch.

Domains: `correctness`, `security`, `architecture`, `testing`, `naming`, `style`, `process`.

Default severity (a finding may be raised or lowered with evidence):
- **bug**: wrong behavior, or a security or data-integrity risk.
- **issue**: a design or maintainability problem likely to cause bugs.
- **nit**: a preference, always with a stated reason.

Ids are `<domain>/<kebab-id>`, unique across all catalog files, and stable: findings cite them, so rename by adding a new id rather than reusing an old one.

Project concerns go in `.claude/shipyard/pr-review/concerns.md` in the same format. On an id collision the project entry wins, which also lets a project retune or silence (via `gate`) a starter concern.
