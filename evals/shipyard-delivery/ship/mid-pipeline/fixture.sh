#!/usr/bin/env bash
# A small TypeScript library (no server, no start script). main holds a slugify helper; the feature branch adds a
# token-bucket rate limiter with tests, and a confirmed grill-plan file (Approved line) whose one build step is ticked.
# No remote, so no pull request; no verify report, which is fine here since a library has no app to boot.
# Branch name encoding: feature/rate-limiter -> plans/feature-rate-limiter.md.
set -e
mkdir -p src
cat > package.json <<'JSON'
{ "name": "tiny-utils", "version": "0.3.0", "private": true, "main": "dist/index.js", "scripts": { "build": "tsc", "test": "jest" } }
JSON
cat > src/slugify.ts <<'TS'
export function slugify(s: string): string {
  return s.toLowerCase().trim().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '');
}
TS
cat > src/slugify.test.ts <<'TS'
import { slugify } from './slugify';
test('slugifies', () => expect(slugify('  Hello, World! ')).toBe('hello-world'));
TS
cat > src/index.ts <<'TS'
export { slugify } from './slugify';
TS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Initial utils"

git checkout -q -b feature/rate-limiter
mkdir -p .claude/shipyard/plans
cat > .claude/shipyard/plans/feature-rate-limiter.md <<'MD'
# Plan: token-bucket rate limiter for tiny-utils

Add `createLimiter({ capacity, refillPerSec, now })` to the library so callers can throttle without a dependency.

## decisions

| Decision | Choice |
|---|---|
| Algorithm | token bucket, refill computed lazily on `take()` |
| Clock | injectable `now` for tests, `Date.now` by default |
| Bad options | `RangeError` on non-positive capacity or refill |

## out of scope

- a sliding-window limiter
- persistence across processes

## build steps

- [x] 1. `src/rate-limit.ts`: `createLimiter`; `take()` returns true and spends a token when one is available, false otherwise. Verify: tests cover refill, capacity cap, exhaustion, bad options. Export from `src/index.ts`.

## acceptance checks

- `take()` is false once capacity is spent and true again after refill time passes
- the library has no runtime dependency added

## open questions

none

MD
# The approval hash covers the bytes above the `## approval` heading (first 12 hex of their sha256).
PLAN=.claude/shipyard/plans/feature-rate-limiter.md
HASH=$( { sha256sum "$PLAN" 2>/dev/null || shasum -a 256 "$PLAN"; } | cut -c1-12 )
printf '## approval

Approved: 2026-11-03 plan-hash %s
' "$HASH" >> "$PLAN"
cat > src/rate-limit.ts <<'TS'
export interface LimiterOptions { capacity: number; refillPerSec: number; now?: () => number }

export function createLimiter({ capacity, refillPerSec, now = Date.now }: LimiterOptions) {
  if (capacity <= 0 || refillPerSec <= 0) throw new RangeError('capacity and refillPerSec must be positive');
  let tokens = capacity;
  let last = now();
  return {
    take(): boolean {
      const t = now();
      tokens = Math.min(capacity, tokens + ((t - last) / 1000) * refillPerSec);
      last = t;
      if (tokens >= 1) { tokens -= 1; return true; }
      return false;
    },
  };
}
TS
cat > src/rate-limit.test.ts <<'TS'
import { createLimiter } from './rate-limit';

function clock(start = 0) { let t = start; return { now: () => t, advance: (ms: number) => { t += ms; } }; }

test('exhausts after capacity', () => {
  const c = clock();
  const l = createLimiter({ capacity: 2, refillPerSec: 1, now: c.now });
  expect([l.take(), l.take(), l.take()]).toEqual([true, true, false]);
});
test('refills over time', () => {
  const c = clock();
  const l = createLimiter({ capacity: 1, refillPerSec: 2, now: c.now });
  l.take();
  c.advance(500);
  expect(l.take()).toBe(true);
});
test('never exceeds capacity', () => {
  const c = clock();
  const l = createLimiter({ capacity: 1, refillPerSec: 10, now: c.now });
  c.advance(10_000);
  expect([l.take(), l.take()]).toEqual([true, false]);
});
test('rejects bad options', () => expect(() => createLimiter({ capacity: 0, refillPerSec: 1 })).toThrow(RangeError));
TS
cat > src/index.ts <<'TS'
export { slugify } from './slugify';
export { createLimiter } from './rate-limit';
TS
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Add token-bucket rate limiter with tests (jest: 5 passed)"
