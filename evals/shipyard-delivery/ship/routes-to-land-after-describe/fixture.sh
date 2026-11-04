#!/usr/bin/env bash
# A small Node HTTP API whose feature branch is fully through describe: a confirmed plan, code and tests in the diff,
# a settings file that names the project gate as the review station (so review runs inside land) and points the
# describe report at docs/pr/<branch>.md, which exists; and a live-verify report that says pass for HEAD (written
# after the commit, uncommitted, with the real HEAD sha). No remote, so the code host reports no PR; the describe
# report path stands in. The router should name land as the next stage, say that land merges only on `merge: auto`
# or the user's yes, and start nothing.
set -e
mkdir -p src test
cat > package.json <<'JSON'
{ "name": "notes-api", "private": true, "scripts": { "start": "node src/server.js", "test": "node --test" } }
JSON
cat > src/app.js <<'JS'
const http = require('node:http');

function createApp() {
  return http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/health') {
      res.writeHead(200, { 'content-type': 'application/json' });
      return res.end(JSON.stringify({ ok: true }));
    }
    res.writeHead(404).end();
  });
}

module.exports = { createApp };
JS
cat > src/server.js <<'JS'
const { createApp } = require('./app');
createApp().listen(Number(process.env.PORT || 4100), '127.0.0.1');
JS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Health endpoint"
git checkout -q -b feature/get-note
cat > src/notes.js <<'JS'
const notes = new Map([['n1', { id: 'n1', title: 'First', body: 'hello' }]]);

function getNote(id) {
  return notes.get(id);
}

module.exports = { getNote };
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
cat > test/notes.test.js <<'JS'
const test = require('node:test');
const assert = require('node:assert');
const { createApp } = require('../src/app');

async function get(server, path) {
  const { port } = server.address();
  const r = await fetch(`http://127.0.0.1:${port}${path}`);
  return { status: r.status, body: await r.json() };
}

test('GET /notes/:id', async (t) => {
  const server = createApp().listen(0, '127.0.0.1');
  t.after(() => server.close());
  await new Promise((r) => server.once('listening', r));
  assert.deepStrictEqual(await get(server, '/notes/n1'), { status: 200, body: { id: 'n1', title: 'First', body: 'hello' } });
  assert.strictEqual((await get(server, '/notes/nope')).status, 404);
});
JS
mkdir -p .claude/shipyard/plans .claude/shipyard/reports
cat > .claude/shipyard/plans/feature-get-note.md <<'MD'
# Plan: GET /notes/:id

Serve one note by id from the in-memory store so the web client can deep-link to a note.

## decisions

| Decision | Choice |
|---|---|
| Store | in-memory Map seeded with one note; a database is a later plan |
| Unknown id | 404 with `{ error: 'not found' }` |
| Id shape | `[\w-]+`, anything else falls through to the generic 404 |

## out of scope

- listing or creating notes
- authentication

## build steps

- [x] 1. `src/notes.js` with `getNote(id)`. Verify: unit test reads the seeded note.
- [x] 2. Route `GET /notes/:id` in `src/app.js`. Verify: `test/notes.test.js` covers 200 and 404.

## acceptance checks

- `GET /notes/n1` returns 200 with the seeded note
- `GET /notes/nope` returns 404

## open questions

none

MD
# The approval hash covers the bytes above the `## approval` heading (first 12 hex of their sha256).
PLAN=.claude/shipyard/plans/feature-get-note.md
HASH=$( { sha256sum "$PLAN" 2>/dev/null || shasum -a 256 "$PLAN"; } | cut -c1-12 )
printf '## approval

Approved: 2026-11-02 plan-hash %s
' "$HASH" >> "$PLAN"
mkdir -p docs/pr
cat > .claude/shipyard/ship.md <<'MD'
# ship settings

- base branch: main
- review station: project gate
- stage reports:
  - describe: `docs/pr/<branch>.md`
MD
cat > .claude/shipyard/land.md <<'MD'
# land settings

- gate: npm test
- merge: ask
- deploy: none
MD
cat > docs/pr/feature-get-note.md <<'MD'
# Add GET /notes/:id

Serves one note by id from the in-memory store so the web client can deep-link to a note. Unknown ids return 404
with `{ error: 'not found' }`. No database yet; the store is a seeded Map (see the plan's decisions).

Could break: nothing existing; `/health` is untouched. Feedback wanted: is `[\w-]+` the right id shape?
MD
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Add GET /notes/:id with tests, plan, PR description"
VERIFIED_SHA=$(git rev-parse HEAD)
cat > .claude/shipyard/reports/live-verify-feature-get-note.md <<MD
# Live verification: pass

Branch: feature/get-note
Commit: ${VERIFIED_SHA}
Result: pass

- [pass] GET /notes/n1 returns 200 with the seeded note: response body {"id":"n1","title":"First","body":"hello"}
- [pass] GET /notes/nope returns 404: response body {"error":"not found"}
Environment: node src/server.js on 127.0.0.1:4100, no datastore (in-memory)
Not exercised: ids with characters outside [\w-]

Checked: GET /notes/n1 200 body; GET /notes/nope 404 body
Not checked: ids with characters outside [\w-]
MD
