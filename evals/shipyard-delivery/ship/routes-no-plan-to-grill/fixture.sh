#!/usr/bin/env bash
# A small Node HTTP API on a fresh feature branch with no commits of its own, no diff, no plan file under
# .claude/shipyard/plans/, and no settings. The prompt states a three-part goal (quotas, admin override, usage report),
# which is not a one-file obvious change, so the router should send it to the plan stage (grill-plan) and start
# nothing, rather than telling the session to start implementing.
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
git checkout -q -b feature/quotas
