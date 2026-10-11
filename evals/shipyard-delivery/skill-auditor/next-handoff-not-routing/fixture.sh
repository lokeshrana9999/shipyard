#!/usr/bin/env bash
# Writes the fixture skill into the run's empty workspace.
# Ground truth: a stage skill whose last line is a handoff naming one stage per outcome (a pass to
# review, a fail back to implement). It names the stages and starts none of them, so it isn't
# routing (dimensions.md, 7): no high routing finding, and no advice to move the line elsewhere.
set -e
mkdir -p skills/smoke-check
cat > skills/smoke-check/SKILL.md <<'FIXTURE'
---
name: smoke-check
description: Runs the project's smoke tests against the local dev server and reports each check with its output. Use when asked to "smoke-test this", "run the smoke checks", or to check a change before review.
---

# Smoke check

## Inputs

- The project's smoke command, from `package.json`'s `smoke` script.
- The local dev server's URL, default `http://localhost:3000`.

## Output

- A table of checks, each with pass or fail and the command output that settled it.

## Rules

- Run against the local dev server only, so nothing shared is touched.
- Quote each failing check's output in full, because the fixer needs the exact error.
- A check that couldn't run is reported as not run, never as a pass.

## Steps

- [ ] 1 Confirm the dev server answers at its URL; if it doesn't, report every check as not run and stop.
- [ ] 2 Run the smoke command.
- [ ] 3 Write the table.

`next:` a pass goes to the review stage; a fail goes back to the implement stage with the table.
FIXTURE
