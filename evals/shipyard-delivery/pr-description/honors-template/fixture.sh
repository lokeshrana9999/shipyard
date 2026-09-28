#!/usr/bin/env bash
# The branch's log and diff as files, so the case needs no Bash to read them.
set -e
cat > commits.txt <<'LOG'
a1b2c3d Add retry with backoff to webhook delivery
d4e5f6a fixup: backoff jitter off-by-one
0f9e8d7 Reformat README tables
LOG
cat > branch.diff <<'DIFF'
diff --git a/src/webhooks/deliver.ts b/src/webhooks/deliver.ts
--- a/src/webhooks/deliver.ts
+++ b/src/webhooks/deliver.ts
@@ -1,12 +1,28 @@
-export async function deliver(hook: Hook, payload: unknown) {
-  const res = await fetch(hook.url, { method: 'POST', body: JSON.stringify(payload) });
-  if (!res.ok) throw new DeliveryError(hook.id, res.status);
-}
+const MAX_ATTEMPTS = 5;
+
+export async function deliver(hook: Hook, payload: unknown) {
+  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
+    const res = await fetch(hook.url, { method: 'POST', body: JSON.stringify(payload) });
+    if (res.ok) return;
+    if (res.status < 500 && res.status !== 429) throw new DeliveryError(hook.id, res.status);
+    await sleep(backoffMs(attempt));
+  }
+  await markHookFailing(hook.id);
+  throw new DeliveryError(hook.id, 'exhausted');
+}
+
+function backoffMs(attempt: number) {
+  const base = 2 ** (attempt - 1) * 1000;
+  return base + Math.floor(Math.random() * base * 0.2);
+}
diff --git a/src/webhooks/hooks.repository.ts b/src/webhooks/hooks.repository.ts
--- a/src/webhooks/hooks.repository.ts
+++ b/src/webhooks/hooks.repository.ts
@@ -20,3 +20,8 @@
+export async function markHookFailing(id: string) {
+  await db.hooks.update({ where: { id }, data: { status: 'failing', failingSince: new Date() } });
+}
diff --git a/README.md b/README.md
--- a/README.md
+++ b/README.md
@@ -10,4 +10,4 @@
-| Command | Description |
-|---|---|
+| Command   | Description          |
+| --------- | -------------------- |
DIFF
mkdir -p .github
cat > .github/pull_request_template.md <<'TPL'
## What and why

## How to test

## Checklist
- [ ] Tests added or updated
- [ ] Docs updated

Fixes #
TPL
