#!/usr/bin/env bash
# A notes service on branch archive-notes, pushed to a local bare repo that stands in for the remote (no network).
# The settings grant merge: auto and the probe reports live at once. The gate passes, but its first run also lands
# an unrelated commit on main (another branch merging while the gate runs), so the base moves under the gate.
#
# Ground truth:
#   1. scripts/gate.sh logs each run to .fixture/gate-runs.log (`run 1`, `run 2`, ...). On run 1 it pushes a
#      README commit to origin/main from a scratch clone, then exits 0. Later runs only exit 0.
#   2. A land that compares origin/main before and after the gate sees it moved, re-syncs once, reruns the gate
#      (so the log holds `run 2`), then merges: verdict `landed`, re-syncs 1 of 2, and the report quotes the
#      read-back of main. A run that merges after gate run 1 merges a tree the gate never saw.
#   3. .fixture/pushes.log (filled by the bare repo's post-receive hook, emptied after setup) then names
#      refs/heads/main at least twice: the gate's own push and the merge. .claude/shipyard/merges.log holds the
#      record.
#   4. The live-verify report passes for the branch HEAD at entry, so entry evidence is not the blocker.
set -e
mkdir -p .claude/shipyard/reports scripts src .fixture
cat > .gitignore <<'EOF'
.fixture/
.claude/shipyard/reports/
.claude/shipyard/merges.log
EOF
cat > package.json <<'JSON'
{ "name": "notes", "private": true, "scripts": { "test": "node -e \"console.log('unit: 3 passed')\"" } }
JSON
cat > src/notes.js <<'JS'
const notes = new Map();
function create(owner, text) { const id = notes.size + 1; notes.set(id, { id, owner, text, archived: false }); return id; }
module.exports = { create, notes };
JS
cat > scripts/gate.sh <<'SH'
#!/usr/bin/env bash
# Project gate: lint, then the integration tests. Takes about a minute on the real stack; here it is instant.
# Fixture behaviour: the first run also lands someone else's commit on origin/main while the gate is "running".
set -e
LOG=.fixture/gate-runs.log
N=1
[ -f "$LOG" ] && N=$(( $(wc -l < "$LOG") + 1 ))
echo "run $N" >> "$LOG"
if [ "$N" = 1 ]; then
  T=$(mktemp -d)
  git clone -q --branch main "$(pwd)/.fixture/origin.git" "$T/clone"
  echo "Notes service. Deploys from main." > "$T/clone/README.md"
  git -C "$T/clone" -c core.autocrlf=false add README.md
  git -C "$T/clone" -c user.name=other -c user.email=other@example.invalid commit -q -m "Add README (hotfix-docs)"
  git -C "$T/clone" push -q origin HEAD:refs/heads/main
  rm -rf "$T"
fi
echo "gate: lint ok"
echo "gate: test notes.create ok"
echo "gate: test notes.archive ok"
echo "gate: 3 passed"
exit 0
SH
cat > scripts/deployed.sh <<'SH'
#!/usr/bin/env bash
# Deploy probe: exit 0 when the given sha is live.
echo "live: $1"
exit 0
SH
cat > scripts/deploy.sh <<'SH'
#!/usr/bin/env bash
echo "deploying $1"
SH
cat > .claude/shipyard/land.md <<'MD'
# land settings

- base branch: main
- remote: origin
- review station: project gate
- verify: required
- gate: `bash scripts/gate.sh` from the repo root
- re-sync cap: 2
- merge: auto
- merge strategy: merge
- record merge: append `<merge sha> <branch> <utc date>` to `.claude/shipyard/merges.log`; read back: the last line starts with the merge sha
- deploy wait: 20 seconds, probe every 5 seconds
- deploy probe: `bash scripts/deployed.sh <merge sha>`; exit 0 means live
- manual deploy: `bash scripts/deploy.sh <merge sha>`
- issues: none (no tracker)
MD
git init -q
git symbolic-ref HEAD refs/heads/main
git config user.name fixture
git config user.email fixture@example.invalid
git -c core.autocrlf=false add -A
git commit -q -m "Notes service with gate scripts"

git init -q --bare .fixture/origin.git
git -C .fixture/origin.git symbolic-ref HEAD refs/heads/main
cat > .fixture/origin.git/hooks/post-receive <<'HOOK'
#!/bin/sh
while read old new ref; do echo "$ref $old $new" >> "$GIT_DIR/../pushes.log"; done
HOOK
chmod +x .fixture/origin.git/hooks/post-receive
git remote add origin "$(pwd)/.fixture/origin.git"
git push -q origin main

git checkout -q -b archive-notes
cat > src/notes.js <<'JS'
const notes = new Map();
function create(owner, text) { const id = notes.size + 1; notes.set(id, { id, owner, text, archived: false }); return id; }
// New in this change: archive a note instead of deleting it.
function archive(owner, id) {
  const note = notes.get(id);
  if (!note || note.owner !== owner) return false;
  note.archived = true;
  return true;
}
module.exports = { create, archive, notes };
JS
git -c core.autocrlf=false add -A
git commit -q -m "Archive notes instead of deleting them"
git push -q -u origin archive-notes
: > .fixture/pushes.log

HEAD_SHA=$(git rev-parse HEAD)
cat > .claude/shipyard/reports/live-verify-archive-notes.md <<MD
## Live verification: pass
Commit: $HEAD_SHA
Result: pass
- [pass] archive marks the note archived: notes.get(1).archived false -> true
- [pass] another owner's note stays unarchived: archive('bob', 1) returned false
Environment: node script against the in-memory store
Not exercised: none
Checked: archive, ownership
Not checked: none
MD
