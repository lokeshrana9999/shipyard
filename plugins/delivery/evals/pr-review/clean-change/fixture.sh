#!/usr/bin/env bash
# A harmless change: an internal variable rename and a new test. A good review finds no bugs.
set -e
cat > branch.diff <<'DIFF'
diff --git a/api/pricing/discount.ts b/api/pricing/discount.ts
--- a/api/pricing/discount.ts
+++ b/api/pricing/discount.ts
@@ -1,6 +1,6 @@
 export function applyDiscount(total: number, pct: number): number {
-  const clamped = Math.min(Math.max(pct, 0), 100);
-  return Math.round(total * (1 - clamped / 100) * 100) / 100;
+  const boundedPercent = Math.min(Math.max(pct, 0), 100);
+  return Math.round(total * (1 - boundedPercent / 100) * 100) / 100;
 }
diff --git a/api/pricing/discount.test.ts b/api/pricing/discount.test.ts
--- /dev/null
+++ b/api/pricing/discount.test.ts
@@ -0,0 +1,9 @@
+import { applyDiscount } from './discount';
+
+describe('applyDiscount', () => {
+  it('clamps the percent to 0-100', () => {
+    expect(applyDiscount(50, 150)).toBe(0);
+    expect(applyDiscount(50, -10)).toBe(50);
+  });
+  it('rounds to cents', () => expect(applyDiscount(9.99, 15)).toBe(8.49));
+});
DIFF
