#!/usr/bin/env bash
# A small Node HTTP API: GET /health and GET /notes/:id over an in-memory store, with a nightly reconcile job stub.
# The project's grill-plan settings add one standing question that names the reconcile job, so a round that read
# the settings mentions it and a round that didn't can't.
set -e
mkdir -p src/jobs .claude/shipyard
cat > package.json <<'JSON'
{ "name": "notes-api", "private": true, "scripts": { "start": "node src/server.js", "test": "node --test", "reconcile": "node src/jobs/reconcile.js" } }
JSON
cat > src/notes.js <<'JS'
const notes = new Map([['n1', { id: 'n1', owner: 'u1', title: 'First', body: 'hello' }]]);

function getNote(id) {
  return notes.get(id);
}

module.exports = { getNote, notes };
JS
cat > src/app.js <<'JS'
const http = require('node:http');
const { getNote } = require('./notes');

function send(res, status, body) {
  res.writeHead(status, { 'content-type': 'application/json' });
  res.end(JSON.stringify(body));
}

function createApp() {
  return http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/health') return send(res, 200, { ok: true });
    const m = req.method === 'GET' && req.url.match(/^\/notes\/([\w-]+)$/);
    if (m) {
      const note = getNote(m[1]);
      return note ? send(res, 200, note) : send(res, 404, { error: 'not found' });
    }
    send(res, 404, { error: 'not found' });
  });
}

module.exports = { createApp };
JS
cat > src/server.js <<'JS'
const { createApp } = require('./app');
createApp().listen(Number(process.env.PORT || 4100), '127.0.0.1');
JS
cat > src/jobs/reconcile.js <<'JS'
// Nightly job: drops notes whose owner no longer exists. Runs at 02:00 with a 10-minute window.
const { notes } = require('../notes');
for (const [id, note] of notes) if (!note.owner) notes.delete(id);
JS
cat > .claude/shipyard/grill-plan.md <<'MD'
# grill-plan settings

- standing questions:
  - Does this touch rows the nightly `reconcile` job reads or deletes, and if so does it fit the job's 10-minute window?
MD
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Notes API with reconcile job"
git checkout -q -b workspaces
