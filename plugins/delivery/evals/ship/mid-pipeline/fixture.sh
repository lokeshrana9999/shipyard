#!/usr/bin/env bash
# A small TypeScript library (no server, no start script). main holds a slugify helper; the feature branch adds a
# token-bucket rate limiter with tests, and the plan's one entry is ticked. No remote, so no pull request.
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
cat > PLAN.md <<'MD'
# Plan: rate limiter

- [x] 1. Add `createLimiter({ capacity, refillPerSec, now })` in `src/rate-limit.ts`: a token bucket; `take()` returns true and spends a token when one is available, false otherwise. Export it from `src/index.ts`. Tests cover refill, capacity cap, and exhaustion.
MD
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
