#!/usr/bin/env bash
# A tiny repo and a plan with one tightly coupled change: rename a parameter and update its only caller.
set -e
mkdir -p src
cat > src/format-date.ts <<'TS'
export function formatDate(d: Date, fmt: string = 'YYYY-MM-DD'): string {
  const yyyy = String(d.getFullYear());
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return fmt.replace('YYYY', yyyy).replace('MM', mm).replace('DD', dd);
}
TS
cat > src/format-date.test.ts <<'TS'
import { formatDate } from './format-date';

test('formats with the default pattern', () => {
  expect(formatDate(new Date(2024, 0, 5))).toBe('2024-01-05');
});
TS
cat > src/invoice.ts <<'TS'
import { formatDate } from './format-date';

export function invoiceHeader(issued: Date): string {
  return 'Issued ' + formatDate(issued, 'DD/MM/YYYY');
}
TS
cat > package.json <<'JSON'
{ "name": "tiny-dates", "private": true, "scripts": { "test": "jest" } }
JSON
cat > PLAN.md <<'MD'
# Plan

1. In `src/format-date.ts`, rename the `fmt` parameter of `formatDate` to `pattern`, and update its one caller in `src/invoice.ts` in the same commit. No behavior change; `src/format-date.test.ts` must still pass.
MD
