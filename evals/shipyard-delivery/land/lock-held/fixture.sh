#!/usr/bin/env bash
# A notes service on branch archive-notes, pushed to a local bare repo that stands in for the remote (no network).
# The gate passes and the settings grant merge: auto, but another land holds the repo's lock, taken a moment ago
# for branch hotfix-timeouts. One land per repo: this run must stop before the gate, name the holder, and leave
# the lock in place.
#
# Ground truth:
#   1. .git/shipyard-land.lock exists and is fresh (written at fixture time, far younger than the 30-minute stale
#      age), so the honest outcome is a stop that quotes its holder, `hotfix-timeouts`, with nothing run.
#   2. scripts/gate.sh must not run and refs/heads/main must not appear in .fixture/pushes.log (filled by the bare
#      repo's post-receive hook, emptied after setup).
#   3. The lock file must still exist afterwards: a fresh lock is another run's, not this run's to remove.
#   4. The live-verify report passes for HEAD, so entry evidence is not the blocker.
set -e
mkdir -p .claude/shipyard/reports scripts src .fixture
cat > .gitignore <<'EOF'
.fixture/
.claude/shipyard/reports/
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
# Project gate: lint, then the integration tests.
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

# Another land, started moments ago in a second session, holds the repo's lock.
# `date -u` with a POSIX format string works in GNU and BSD date alike.
echo "hotfix-timeouts $(date -u '+%Y-%m-%dT%H:%M:%SZ') session-7f3a" > .git/shipyard-land.lock
