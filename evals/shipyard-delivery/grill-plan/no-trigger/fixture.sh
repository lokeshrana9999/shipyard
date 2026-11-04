#!/usr/bin/env bash
# One file with one misspelled word in a response message.
set -e
mkdir -p src
cat > package.json <<'JSON'
{ "name": "inbox-api", "private": true, "scripts": { "start": "node src/app.js" } }
JSON
cat > src/app.js <<'JS'
const http = require('node:http');

http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/messages') {
    res.writeHead(202, { 'content-type': 'application/json' });
    return res.end(JSON.stringify({ status: 'queued to recieve' }));
  }
  res.writeHead(404).end();
}).listen(4100, '127.0.0.1');
JS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Inbox API"
