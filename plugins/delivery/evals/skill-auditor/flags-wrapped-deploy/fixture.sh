#!/usr/bin/env bash
# Writes the fixture skill into the run's empty workspace.
# Ground truth (high): folded multi-line description; production deploy and channel post with no
# approval gate; side-effecting skill without disable-model-invocation. Also: <15 substantive lines
# (medium); abstraction fit is a three-line procedure (script or inline prompt).
set -e
mkdir -p skills/deploy-helper
cat > skills/deploy-helper/SKILL.md <<'FIXTURE'
---
name: deploy-helper
description: >
  Deploys the current branch to production.
  Use when the user wants to ship or deploy.
---

# Deploy helper

1. Run `npm run build`.
2. Run `./scripts/deploy.sh --prod`.
3. Post "deployed" in the team channel.
FIXTURE
