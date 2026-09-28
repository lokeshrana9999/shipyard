#!/usr/bin/env bash
# A committed monorepo with four independent packages, each with its own module and tests, and a plan with
# one self-contained entry per package (no entry reads another entry's output). No settings file, so defaults apply.
set -e
mkdir -p packages/billing/src packages/search/src packages/notifications/src packages/auth/src

cat > packages/billing/src/invoice.ts <<'TS'
export interface LineItem { sku: string; unitCents: number; qty: number }
export interface Invoice { customerId: string; items: LineItem[]; currency: 'USD' | 'EUR' }

export function subtotalCents(inv: Invoice): number {
  return inv.items.reduce((sum, it) => sum + it.unitCents * it.qty, 0);
}

export function taxCents(inv: Invoice, rate: number): number {
  if (rate < 0 || rate > 1) throw new RangeError('rate must be between 0 and 1');
  return Math.round(subtotalCents(inv) * rate);
}

export function totalCents(inv: Invoice, rate: number): number {
  return subtotalCents(inv) + taxCents(inv, rate);
}
TS
cat > packages/billing/src/invoice.test.ts <<'TS'
import { subtotalCents, taxCents, totalCents } from './invoice';
const inv = { customerId: 'c1', currency: 'USD' as const, items: [{ sku: 'a', unitCents: 1000, qty: 2 }, { sku: 'b', unitCents: 250, qty: 4 }] };
test('subtotal', () => expect(subtotalCents(inv)).toBe(3000));
test('tax rounds', () => expect(taxCents(inv, 0.0825)).toBe(248));
test('total', () => expect(totalCents(inv, 0.1)).toBe(3300));
test('bad rate', () => expect(() => taxCents(inv, 2)).toThrow(RangeError));
TS

cat > packages/search/src/rank.ts <<'TS'
export interface Doc { id: string; title: string; body: string; updatedAt: number }

function tokens(s: string): string[] {
  return s.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean);
}

export function score(doc: Doc, query: string): number {
  const q = tokens(query);
  const title = tokens(doc.title);
  const body = tokens(doc.body);
  let s = 0;
  for (const t of q) {
    if (title.includes(t)) s += 3;
    if (body.includes(t)) s += 1;
  }
  return s;
}

export function search(docs: Doc[], query: string, limit = 10): Doc[] {
  return docs
    .map(d => ({ d, s: score(d, query) }))
    .filter(x => x.s > 0)
    .sort((a, b) => b.s - a.s)
    .slice(0, limit)
    .map(x => x.d);
}
TS
cat > packages/search/src/rank.test.ts <<'TS'
import { search, score } from './rank';
const docs = [
  { id: '1', title: 'Refund policy', body: 'How refunds work', updatedAt: 1 },
  { id: '2', title: 'Shipping', body: 'refund after return', updatedAt: 2 },
];
test('title beats body', () => expect(search(docs, 'refund').map(d => d.id)).toEqual(['1', '2']));
test('no match scores zero', () => expect(score(docs[0], 'banana')).toBe(0));
TS

cat > packages/notifications/src/schedule.ts <<'TS'
export interface Prefs { timezoneOffsetMinutes: number; channels: ('email' | 'sms' | 'push')[] }
export interface Message { userId: string; channel: 'email' | 'sms' | 'push'; body: string }

export function allowedChannel(prefs: Prefs, msg: Message): boolean {
  return prefs.channels.includes(msg.channel);
}

export function localHour(nowUtcMs: number, prefs: Prefs): number {
  const local = new Date(nowUtcMs + prefs.timezoneOffsetMinutes * 60_000);
  return local.getUTCHours();
}

export function shouldSendNow(prefs: Prefs, msg: Message, nowUtcMs: number): boolean {
  return allowedChannel(prefs, msg);
}
TS
cat > packages/notifications/src/schedule.test.ts <<'TS'
import { shouldSendNow, localHour } from './schedule';
const prefs = { timezoneOffsetMinutes: -300, channels: ['email' as const] };
test('blocked channel', () => expect(shouldSendNow(prefs, { userId: 'u', channel: 'sms', body: 'x' }, 0)).toBe(false));
test('allowed channel', () => expect(shouldSendNow(prefs, { userId: 'u', channel: 'email', body: 'x' }, 0)).toBe(true));
test('local hour', () => expect(localHour(Date.UTC(2024, 0, 1, 12), prefs)).toBe(7));
TS

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
cat > SPEC.md <<'MD'
# Platform hardening

Four independent changes, one per package. None depends on another.

- billing: invoices support a percentage discount applied before tax; discounts outside 0-100% are rejected.
- search: among equal scores, more recently updated documents rank first; a query of only stop words returns no results.
- notifications: users can set quiet hours (start and end local hour, may wrap midnight); sms and push are not sent during quiet hours, email always is.
- auth: after 5 consecutive failed logins for an account, further logins are refused for 15 minutes with reason `locked`; a success resets the count.
MD
cat > PLAN.md <<'MD'
# Plan (see SPEC.md)

Each entry touches only its own package and can land in any order.

1. **billing** (`packages/billing/src/invoice.ts`): add `discountPct?: number` to `Invoice`; apply it to the subtotal before tax in `taxCents` and `totalCents`; throw `RangeError` outside 0-100. Add tests.
2. **search** (`packages/search/src/rank.ts`): break score ties by `updatedAt` descending; drop the stop words `the, a, an, of, and, or` from queries, returning `[]` when nothing is left. Add tests.
3. **notifications** (`packages/notifications/src/schedule.ts`): add `quietHours?: { start: number; end: number }` to `Prefs`, handling ranges that wrap midnight; `shouldSendNow` returns false for sms and push inside quiet hours, true for email. Add tests.
4. **auth** (`packages/auth/src/login.ts`): track consecutive failures per account through a new `Attempts` store interface; after 5 failures refuse logins for 15 minutes with reason `locked`; reset on success. Take the clock as a parameter. Add tests.
MD

git init -q
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Initial platform packages"
