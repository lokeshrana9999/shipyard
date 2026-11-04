#!/usr/bin/env bash
# A webhook sender with one attempt and a 60 s request timeout; no retry anywhere.
set -e
mkdir -p src/webhooks
cat > package.json <<'JSON'
{ "name": "hooks", "private": true, "scripts": { "test": "node --test" } }
JSON
cat > src/webhooks/send.js <<'JS'
const REQUEST_TIMEOUT_MS = 60_000;

async function sendWebhook(delivery) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const res = await fetch(delivery.url, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify(delivery.payload),
      signal: controller.signal,
    });
    return { ok: res.ok, status: res.status };
  } catch (err) {
    return { ok: false, status: 0, error: String(err) };
  } finally {
    clearTimeout(timer);
  }
}

module.exports = { sendWebhook, REQUEST_TIMEOUT_MS };
JS
cat > src/webhooks/deliver.js <<'JS'
const { sendWebhook } = require('./send');

// One attempt. A failed delivery is logged and dropped.
async function deliver(delivery) {
  const result = await sendWebhook(delivery);
  if (!result.ok) console.error('webhook failed', delivery.id, result.status);
  return result;
}

module.exports = { deliver };
JS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Webhook sender, single attempt"
git checkout -q -b webhook-retry
