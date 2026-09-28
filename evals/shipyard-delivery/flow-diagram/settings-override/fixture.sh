#!/usr/bin/env bash
# Project settings that override the default: this team's PR descriptions don't render Mermaid.
set -e
mkdir -p .claude/shipyard
cat > .claude/shipyard/flow-diagram.md <<'SETTINGS'
# flow-diagram settings

- destinations:
  - PR and issue descriptions: ascii (our code host doesn't render Mermaid)
SETTINGS
