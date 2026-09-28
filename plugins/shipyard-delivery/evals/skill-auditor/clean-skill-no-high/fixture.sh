#!/usr/bin/env bash
# Writes the fixture skill into the run's empty workspace.
# Ground truth: a well-formed skill with no high-severity finding. Writing CHANGELOG.md is a local,
# reversible edit behind a STOP — WAIT gate, so it needs no disable-model-invocation (dimensions.md, 1).
# Expected at most medium/low: short body (<15 substantive lines), no evals.
set -e
mkdir -p skills/changelog-writer
cat > skills/changelog-writer/SKILL.md <<'FIXTURE'
---
name: changelog-writer
description: Drafts a CHANGELOG.md entry from the commits since the last tag. Use when asked to write, draft, or update a changelog or release notes.
---

# Changelog writer

## Inputs

- The git history since the most recent tag (`git describe --tags --abbrev=0`).

## Output

- A new section at the top of `CHANGELOG.md`, printed for review before it is saved.

## Rules

- Group entries under Added, Changed, Fixed, Removed, so readers can scan by kind of change.
- One line per user-visible change, in past tense. Merge commits and version bumps are left out because readers don't act on them.

## Steps

- [ ] 1 Read the commits since the last tag.
- [ ] 2 Draft the section.
- [ ] 3 STOP — WAIT: show the draft and ask before writing it to `CHANGELOG.md`.
- [ ] 4 Write it.

Example entry:

```
### Fixed
- Stopped login failing when the email had uppercase letters.
```
FIXTURE
