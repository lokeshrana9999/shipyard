---
max_turns: 10
allowed_tools: [Read, Skill]
tags: [walkthrough]
---

Walk me through how this retry logic works and why a request can end up failing even though we retry:

```ts
async function fetchWithRetry(url: string, token: Token) {
  for (let attempt = 1; attempt <= 3; attempt++) {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${token.value}` } });
    if (res.status === 401) throw new AuthError("unauthorized");
    if (res.ok) return res.json();
    await sleep(2 ** attempt * 500);
  }
  throw new Error("gave up after 3 attempts");
}
```
