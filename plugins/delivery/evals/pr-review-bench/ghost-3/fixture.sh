#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/Ghost/pull/3 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/ghost/core/core/server/services/email-service/DomainWarmingService.ts b/ghost/core/core/server/services/email-service/DomainWarmingService.ts
index 4822a0a2ac0..041f42413cf 100644
--- a/ghost/core/core/server/services/email-service/DomainWarmingService.ts
+++ b/ghost/core/core/server/services/email-service/DomainWarmingService.ts
@@ -3,7 +3,7 @@ type LabsService = {
 };
 
 type EmailModel = {
-    findOne: (options: {filter: string; order: string}) => Promise<EmailRecord | null>;
+    findPage: (options: {filter: string; order: string; limit: number}) => Promise<{data: EmailRecord[]}>;
 };
 
 type EmailRecord = {
@@ -20,22 +20,48 @@ type WarmupScalingTable = {
         limit: number;
         scale: number;
     }[];
-    defaultScale: number;
+    highVolume: {
+        threshold: number;
+        maxScale: number;
+        maxAbsoluteIncrease: number;
+    };
 }
 
+/**
+ * Configuration for domain warming email volume scaling.
+ *
+ * | Volume Range | Multiplier                                       |
+ * |--------------|--------------------------------------------------|
+ * | ≤100 (base)  | 200 messages                                     |
+ * | 101 – 1k     | 1.25× (conservative early ramp)                  |
+ * | 1k – 5k      | 1.5× (moderate increase)                         |
+ * | 5k – 100k    | 1.75× (faster ramp after proving deliverability) |
+ * | 100k – 400k  | 2×                                               |
+ * | 400k+        | min(1.2×, +75k) cap                              |
+ */
 const WARMUP_SCALING_TABLE: WarmupScalingTable = {
     base: {
         limit: 100,
         value: 200
     },
     thresholds: [{
+        limit: 1_000,
+        scale: 1.25
+    }, {
+        limit: 5_000,
+        scale: 1.5
+    }, {
         limit: 100_000,
-        scale: 2
+        scale: 1.75
     }, {
         limit: 400_000,
-        scale: 1.5
+        scale: 2
     }],
-    defaultScale: 1.25
+    highVolume: {
+        threshold: 400_000,
+        maxScale: 1.2,
+        maxAbsoluteIncrease: 75_000
+    }
 };
 
 export class DomainWarmingService {
@@ -72,17 +98,18 @@ export class DomainWarmingService {
      * @returns The highest number of messages sent from the CSD in a single email (excluding today)
      */
     async #getHighestCount(): Promise<number> {
-        const email = await this.#emailModel.findOne({
-            filter: `created_at:<${new Date().toISOString().split('T')[0]}`,
-            order: 'csd_email_count DESC'
+        const result = await this.#emailModel.findPage({
+            filter: `created_at:<=${new Date().toISOString().split('T')[0]}`,
+            order: 'csd_email_count DESC',
+            limit: 1
         });
 
-        if (!email) {
+        if (!result.data.length) {
             return 0;
         }
 
-        const count = email.get('csd_email_count');
-        return count || 0;
+        const count = result.data[0].get('csd_email_count');
+        return count != null ? count : 0;
     }
 
     /**
@@ -94,12 +121,20 @@ export class DomainWarmingService {
             return WARMUP_SCALING_TABLE.base.value;
         }
 
+        // For high volume senders (400k+), cap the increase at 20% or 75k absolute
+        if (lastCount >= WARMUP_SCALING_TABLE.highVolume.threshold) {
+            const scaledIncrease = Math.ceil(lastCount * WARMUP_SCALING_TABLE.highVolume.maxScale);
+            const absoluteIncrease = lastCount + WARMUP_SCALING_TABLE.highVolume.maxAbsoluteIncrease;
+            return Math.min(scaledIncrease, absoluteIncrease);
+        }
+
         for (const threshold of WARMUP_SCALING_TABLE.thresholds.sort((a, b) => a.limit - b.limit)) {
-            if (lastCount <= threshold.limit) {
+            if (lastCount < threshold.limit) {
                 return Math.ceil(lastCount * threshold.scale);
             }
         }
 
-        return Math.ceil(lastCount * WARMUP_SCALING_TABLE.defaultScale);
+        // This should not be reached given the thresholds cover all cases up to highVolume.threshold
+        return Math.ceil(lastCount * WARMUP_SCALING_TABLE.highVolume.maxScale);
     }
 }
diff --git a/ghost/core/test/integration/services/email-service/domain-warming.test.js b/ghost/core/test/integration/services/email-service/domain-warming.test.js
index a0aae1fb18c..4e50ec69375 100644
--- a/ghost/core/test/integration/services/email-service/domain-warming.test.js
+++ b/ghost/core/test/integration/services/email-service/domain-warming.test.js
@@ -50,14 +50,20 @@ describe('Domain Warming Integration Tests', function () {
     }
 
     // Helper: Set fake time to specific day
+    // Uses a fixed base date to ensure consistent day progression
+    const baseDate = new Date();
+    baseDate.setHours(12, 0, 0, 0);
+
     function setDay(daysFromNow = 0) {
         if (clock) {
             clock.restore();
         }
-        const time = new Date();
+        const time = new Date(baseDate.getTime());
         time.setDate(time.getDate() + daysFromNow);
-        time.setHours(12, 0, 0, 0);
-        clock = sinon.useFakeTimers(time.getTime());
+        clock = sinon.useFakeTimers({
+            now: time.getTime(),
+            shouldAdvanceTime: true
+        });
     }
 
     // Helper: Count recipients by domain type
@@ -183,13 +189,12 @@ describe('Domain Warming Integration Tests', function () {
             const email2 = await sendEmail('Test Post Day 2');
             const email2Count = email2.get('email_count');
             const csdCount2 = email2.get('csd_email_count');
-            const expectedLimit = Math.min(email2Count, csdCount1 * 2);
+            const expectedLimit = Math.min(email2Count, Math.ceil(csdCount1 * 1.25));
 
             assert.equal(csdCount2, expectedLimit);
 
-            // Verify doubling behavior
-            if (email2Count >= csdCount1 * 2) {
-                assert.equal(csdCount2, csdCount1 * 2, 'Limit should double when enough recipients exist');
+            if (email2Count >= Math.ceil(csdCount1 * 1.25)) {
+                assert.equal(csdCount2, Math.ceil(csdCount1 * 1.25), 'Limit should increase by 1.25× when enough recipients exist');
             } else {
                 assert.equal(csdCount2, email2Count, 'Limit should equal total when recipients < limit');
             }
@@ -212,28 +217,27 @@ describe('Domain Warming Integration Tests', function () {
         it('handles progression through multiple days correctly', async function () {
             await createMembers(500, 'multi');
 
-            setDay(0); // Day 1
+            // Day 1: Base limit of 200 (no prior emails)
+            setDay(0);
             const email1 = await sendEmail('Test Post Multi Day 1');
             const csdCount1 = email1.get('csd_email_count');
 
-            assert.ok(csdCount1 > 0, 'Day 1: Should send some via custom domain');
             assert.ok(email1.get('email_count') >= 500, 'Day 1: Should have at least 500 recipients');
+            assert.equal(csdCount1, 200, 'Day 1: Should use base limit of 200');
 
-            setDay(1); // Day 2
+            // Day 2: 200 × 1.25 = 250
+            setDay(1);
             const email2 = await sendEmail('Test Post Multi Day 2');
             const csdCount2 = email2.get('csd_email_count');
 
-            assert.ok(csdCount2 > 0, 'Day 2: Should send some via custom domain');
-            assert.equal(csdCount2, csdCount1 * 2, `Day 2: Should double (got ${csdCount2}, expected ${csdCount1 * 2})`);
+            assert.equal(csdCount2, 250, 'Day 2: Should scale to 250');
 
-            setDay(2); // Day 3
+            // Day 3: 250 × 1.25 = 313
+            setDay(2);
             const email3 = await sendEmail('Test Post Multi Day 3');
             const csdCount3 = email3.get('csd_email_count');
 
-            assert.ok(csdCount3 > 0, 'Day 3: Should send some via custom domain');
-            assert.ok(csdCount3 >= csdCount2, 'Day 3: Should be >= day 2');
-            assert.ok(csdCount3 === csdCount2 || csdCount3 === csdCount2 * 2 || csdCount3 === email3.get('email_count'),
-                `Day 3: Should be same, doubled, or total (got ${csdCount3})`);
+            assert.equal(csdCount3, 313, 'Day 3: Should scale to 313');
         });
 
         it('respects total email count when it is less than warmup limit', async function () {
@@ -283,6 +287,19 @@ describe('Domain Warming Integration Tests', function () {
 
             let previousCsdCount = 0;
 
+            const getExpectedScale = (count) => {
+                if (count <= 100) {
+                    return 200;
+                }
+                if (count <= 1000) {
+                    return Math.ceil(count * 1.25);
+                }
+                if (count <= 5000) {
+                    return Math.ceil(count * 1.5);
+                }
+                return Math.ceil(count * 1.75);
+            };
+
             for (let day = 0; day < 5; day++) {
                 setDay(day);
 
@@ -299,8 +316,9 @@ describe('Domain Warming Integration Tests', function () {
                     if (csdCount === totalCount) {
                         assert.equal(csdCount, totalCount, `Day ${day + 1}: Reached full capacity`);
                     } else {
-                        assert.ok(csdCount === previousCsdCount || csdCount === previousCsdCount * 2,
-                            `Day ${day + 1}: Should maintain or double (got ${csdCount}, previous ${previousCsdCount})`);
+                        const expectedScale = getExpectedScale(previousCsdCount);
+                        assert.ok(csdCount === previousCsdCount || csdCount === expectedScale,
+                            `Day ${day + 1}: Should maintain or scale appropriately (got ${csdCount}, previous ${previousCsdCount}, expected ${expectedScale})`);
                     }
                 }
 
diff --git a/ghost/core/test/unit/server/services/email-service/domain-warming-service.test.ts b/ghost/core/test/unit/server/services/email-service/domain-warming-service.test.ts
index 1c687a715e6..453f8a7d5b4 100644
--- a/ghost/core/test/unit/server/services/email-service/domain-warming-service.test.ts
+++ b/ghost/core/test/unit/server/services/email-service/domain-warming-service.test.ts
@@ -8,7 +8,7 @@ describe('Domain Warming Service', function () {
         isSet: sinon.SinonStub;
     };
     let Email: ReturnType<typeof createModelClass> | {
-        findOne: sinon.SinonStub | (() => Promise<any>);
+        findPage: sinon.SinonStub | (() => Promise<any>);
     };
 
     beforeEach(function () {
@@ -17,7 +17,7 @@ describe('Domain Warming Service', function () {
         };
 
         Email = createModelClass({
-            findOne: null
+            findAll: []
         });
     });
 
@@ -65,9 +65,9 @@ describe('Domain Warming Service', function () {
 
     describe('getWarmupLimit', function () {
         it('should return 200 when no previous emails exist', async function () {
-            Email = {
-                findOne: async () => null
-            };
+            Email = createModelClass({
+                findAll: []
+            });
 
             const service = new DomainWarmingService({
                 models: {Email},
@@ -80,9 +80,9 @@ describe('Domain Warming Service', function () {
 
         it('should return 200 when highest count is 0', async function () {
             Email = createModelClass({
-                findOne: {
+                findAll: [{
                     csd_email_count: 0
-                }
+                }]
             });
 
             const service = new DomainWarmingService({
@@ -96,9 +96,9 @@ describe('Domain Warming Service', function () {
 
         it('should return emailCount when it is less than calculated limit', async function () {
             Email = createModelClass({
-                findOne: {
+                findAll: [{
                     csd_email_count: 1000
-                }
+                }]
             });
 
             const service = new DomainWarmingService({
@@ -106,15 +106,17 @@ describe('Domain Warming Service', function () {
                 labs
             });
 
-            const result = await service.getWarmupLimit(1500);
-            assert.equal(result, 1500);
+            // With lastCount=1000, calculated limit is 1250 (1.25× scale)
+            // emailCount=1000 is less than 1250, so return emailCount
+            const result = await service.getWarmupLimit(1000);
+            assert.equal(result, 1000);
         });
 
         it('should return calculated limit when emailCount is greater', async function () {
             Email = createModelClass({
-                findOne: {
+                findAll: [{
                     csd_email_count: 1000
-                }
+                }]
             });
 
             const service = new DomainWarmingService({
@@ -123,14 +125,14 @@ describe('Domain Warming Service', function () {
             });
 
             const result = await service.getWarmupLimit(5000);
-            assert.equal(result, 2000);
+            assert.equal(result, 1250);
         });
 
         it('should handle csd_email_count being null', async function () {
             Email = createModelClass({
-                findOne: {
+                findAll: [{
                     csd_email_count: null
-                }
+                }]
             });
 
             const service = new DomainWarmingService({
@@ -144,9 +146,9 @@ describe('Domain Warming Service', function () {
 
         it('should handle csd_email_count being undefined', async function () {
             Email = createModelClass({
-                findOne: {
+                findAll: [{
                     // csd_email_count is undefined
-                }
+                }]
             });
 
             const service = new DomainWarmingService({
@@ -159,9 +161,9 @@ describe('Domain Warming Service', function () {
         });
 
         it('should query for emails created before today', async function () {
-            const findOneStub = sinon.stub().resolves(null);
+            const findPageStub = sinon.stub().resolves({data: []});
             Email = {
-                findOne: findOneStub
+                findPage: findPageStub
             };
 
             const today = new Date().toISOString().split('T')[0];
@@ -173,35 +175,45 @@ describe('Domain Warming Service', function () {
 
             await service.getWarmupLimit(1000);
 
-            sinon.assert.calledOnce(findOneStub);
-            const callArgs = findOneStub.firstCall.args[0];
+            sinon.assert.calledOnce(findPageStub);
+            const callArgs = findPageStub.firstCall.args[0];
             assert.ok(callArgs.filter);
             assert.ok(callArgs.filter.includes(`created_at:<${today}`));
             assert.equal(callArgs.order, 'csd_email_count DESC');
+            assert.equal(callArgs.limit, 1);
         });
 
         it('should return correct warmup progression through the stages', async function () {
             // Test the complete warmup progression
+            // New conservative scaling:
+            // - Base: 200 for counts ≤100
+            // - 1.25× until 1k (conservative early ramp)
+            // - 1.5× until 5k (moderate increase)
+            // - 1.75× until 100k (faster ramp after proving deliverability)
+            // - 2× until 400k
+            // - High volume (400k+): min(1.2×, lastCount + 75k) to avoid huge jumps
             const testCases = [
                 {lastCount: 0, expected: 200},
                 {lastCount: 50, expected: 200},
                 {lastCount: 100, expected: 200},
-                {lastCount: 200, expected: 400},
-                {lastCount: 500, expected: 1000},
-                {lastCount: 1000, expected: 2000},
-                {lastCount: 50000, expected: 100000},
-                {lastCount: 100000, expected: 200000},
-                {lastCount: 200000, expected: 300000},
-                {lastCount: 400000, expected: 600000},
-                {lastCount: 500000, expected: 625000},
-                {lastCount: 800000, expected: 1000000}
+                {lastCount: 200, expected: 250}, // 200 × 1.25 = 250
+                {lastCount: 500, expected: 625}, // 500 × 1.25 = 625
+                {lastCount: 1000, expected: 1250}, // 1000 × 1.25 = 1250
+                {lastCount: 2000, expected: 3000}, // 2000 × 1.5 = 3000
+                {lastCount: 5000, expected: 7500}, // 5000 × 1.5 = 7500
+                {lastCount: 50000, expected: 87500}, // 50000 × 1.75 = 87500
+                {lastCount: 100000, expected: 175000}, // 100000 × 1.75 = 175000
+                {lastCount: 200000, expected: 400000}, // 200000 × 2 = 400000
+                {lastCount: 400000, expected: 800000}, // 400000 × 2 = 800000
+                {lastCount: 500000, expected: 575000}, // min(500000 × 1.2, 500000 + 75000) = min(600000, 575000)
+                {lastCount: 800000, expected: 875000} // min(800000 × 1.2, 800000 + 75000) = min(960000, 875000)
             ];
 
             for (const testCase of testCases) {
                 const EmailModel = createModelClass({
-                    findOne: {
+                    findAll: [{
                         csd_email_count: testCase.lastCount
-                    }
+                    }]
                 });
 
                 const service = new DomainWarmingService({
QODO_BENCH_DIFF_END
