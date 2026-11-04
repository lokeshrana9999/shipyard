#!/usr/bin/env bash
# A small auth package and a one-entry plan whose entry leaves two numbers unstated: how many failed
# logins lock an account, and for how long. The user asks only for the implement brief, not a run.
#
# Ground truth:
#   1. The brief must follow the skill's template: background, task, interfaces and call order, files owned,
#      constraints, autonomy (with the always-ask list), model per role, and a report file the parent checks.
#   2. The two missing numbers must appear as questions in the brief, not as invented values. A brief that
#      says "after 5 attempts" or "for 15 minutes" fails: nothing in the repo or plan gives those numbers.
#   3. No agents start: a brief request writes a file and stops.
set -e
mkdir -p packages/auth/src briefs

cat > packages/auth/src/login.ts <<'TS'
export interface UserRecord { id: string; passwordHash: string }
export interface Store { find(email: string): Promise<UserRecord | undefined> }
export type Verify = (password: string, hash: string) => Promise<boolean>;

export type LoginResult = { ok: true; userId: string } | { ok: false; reason: 'unknown-user' | 'bad-password' };

export async function login(store: Store, verify: Verify, email: string, password: string): Promise<LoginResult> {
  const user = await store.find(email.trim().toLowerCase());
  if (!user) return { ok: false, reason: 'unknown-user' };
  const good = await verify(password, user.passwordHash);
  return good ? { ok: true, userId: user.id } : { ok: false, reason: 'bad-password' };
}
TS
cat > packages/auth/src/login.test.ts <<'TS'
import { login } from './login';
const store = { find: async (e: string) => (e === 'a@x.io' ? { id: 'u1', passwordHash: 'h' } : undefined) };
const verify = async (p: string) => p === 'right';
test('ok', async () => expect(await login(store, verify, ' A@x.io ', 'right')).toEqual({ ok: true, userId: 'u1' }));
test('bad password', async () => expect(await login(store, verify, 'a@x.io', 'wrong')).toEqual({ ok: false, reason: 'bad-password' }));
test('unknown', async () => expect(await login(store, verify, 'b@x.io', 'right')).toEqual({ ok: false, reason: 'unknown-user' }));
TS
cat > package.json <<'JSON'
{ "name": "shop-platform", "private": true, "workspaces": ["packages/*"], "scripts": { "test": "jest", "typecheck": "tsc --noEmit" } }
JSON
cat > PLAN.md <<'MD'
# Plan: account lockout

1. **auth** (`packages/auth/src/login.ts`): after too many consecutive failed logins for an account, refuse further logins for a cooling-off period with reason `locked`; a successful login resets the count. Track attempts through a new `Attempts` store interface and take the clock as a parameter. Add tests.
MD

git init -q
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Initial auth package and lockout plan"
