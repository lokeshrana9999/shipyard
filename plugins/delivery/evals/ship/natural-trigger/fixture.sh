#!/usr/bin/env bash
# A small Node HTTP API. main serves GET /health; the feature branch adds GET /notes/:id with an in-memory
# store, and tests for it. No database, no remote, no pull request.
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
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Add GET /notes/:id with tests"
