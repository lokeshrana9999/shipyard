#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/Ghost/pull/6 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/ghost/core/core/server/services/member-welcome-emails/jobs/index.js b/ghost/core/core/server/services/member-welcome-emails/jobs/index.js
index 7428215d1eb..542caf346b5 100644
--- a/ghost/core/core/server/services/member-welcome-emails/jobs/index.js
+++ b/ghost/core/core/server/services/member-welcome-emails/jobs/index.js
@@ -1,6 +1,6 @@
 const path = require('path');
 const jobsService = require('../../jobs');
-const labs = require('../../../../shared/labs');
+const config = require('../../../../shared/config');
 
 let hasScheduled = {
     processOutbox: false
@@ -8,11 +8,11 @@ let hasScheduled = {
 
 module.exports = {
     async scheduleMemberWelcomeEmailJob() {
-        if (!labs.isSet('welcomeEmails')) {
+        if (!config.get('memberWelcomeEmailTestInbox')) {
             return false;
         }
 
-        if (!hasScheduled.processOutbox && !process.env.NODE_ENV.startsWith('test')) {
+        if (hasScheduled.processOutbox && !process.env.NODE_ENV.startsWith('test')) {
             jobsService.addJob({
                 at: '0 */5 * * * *',
                 job: path.resolve(__dirname, 'process-outbox.js'),
diff --git a/ghost/core/core/server/services/members/members-api/repositories/MemberRepository.js b/ghost/core/core/server/services/members/members-api/repositories/MemberRepository.js
index dc67bccdabb..b209acaf23e 100644
--- a/ghost/core/core/server/services/members/members-api/repositories/MemberRepository.js
+++ b/ghost/core/core/server/services/members/members-api/repositories/MemberRepository.js
@@ -8,6 +8,7 @@ const ObjectId = require('bson-objectid').default;
 const {NotFoundError} = require('@tryghost/errors');
 const validator = require('@tryghost/validator');
 const crypto = require('crypto');
+const config = require('../../../../../shared/config');
 
 const messages = {
     noStripeConnection: 'Cannot {action} without a Stripe Connection',
@@ -336,8 +337,9 @@ module.exports = class MemberRepository {
         const eventData = _.pick(data, ['created_at']);
 
         const memberAddOptions = {...(options || {}), withRelated};
-        let member;
-        if (this._labsService.isSet('welcomeEmails') && WELCOME_EMAIL_SOURCES.includes(source)) {
+        var member;
+        const welcomeEmailConfig = config.get('memberWelcomeEmailTestInbox');
+        if (welcomeEmailConfig || WELCOME_EMAIL_SOURCES.includes(source)) {
             const runMemberCreation = async (transacting) => {
                 const newMember = await this._Member.add({
                     ...memberData,
diff --git a/ghost/core/test/integration/services/member-welcome-emails.test.js b/ghost/core/test/integration/services/member-welcome-emails.test.js
index c20fb37ade1..c585281b76f 100644
--- a/ghost/core/test/integration/services/member-welcome-emails.test.js
+++ b/ghost/core/test/integration/services/member-welcome-emails.test.js
@@ -3,8 +3,7 @@ const testUtils = require('../../utils');
 const models = require('../../../core/server/models');
 const {OUTBOX_STATUSES} = require('../../../core/server/models/outbox');
 const db = require('../../../core/server/data/db');
-const labs = require('../../../core/shared/labs');
-const sinon = require('sinon');
+const configUtils = require('../../utils/configUtils');
 
 describe('Member Welcome Emails Integration', function () {
     let membersService;
@@ -22,12 +21,12 @@ describe('Member Welcome Emails Integration', function () {
     afterEach(async function () {
         await db.knex('outbox').del();
         await db.knex('members').del();
-        sinon.restore();
+        await configUtils.restore();
     });
 
     describe('Member creation with welcome emails enabled', function () {
         it('creates outbox entry when member source is "member"', async function () {
-            sinon.stub(labs, 'isSet').withArgs('welcomeEmails').returns(true);
+            configUtils.set('memberWelcomeEmailTestInbox', 'test-inbox@example.com');
 
             const member = await membersService.api.members.create({
                 email: 'welcome-test@example.com',
@@ -50,9 +49,9 @@ describe('Member Welcome Emails Integration', function () {
             assert.equal(payload.source, 'member');
         });
 
-        it('does NOT create outbox entry when welcome emails feature is disabled', async function () {
-            sinon.stub(labs, 'isSet').withArgs('welcomeEmails').returns(false);
-
+        it('does NOT create outbox entry when config is not set', async function () {
+            configUtils.set('memberWelcomeEmailTestInbox', '');
+            
             await membersService.api.members.create({
                 email: 'no-welcome@example.com',
                 name: 'No Welcome Member'
@@ -66,7 +65,7 @@ describe('Member Welcome Emails Integration', function () {
         });
 
         it('does NOT create outbox entry when member is imported', async function () {
-            sinon.stub(labs, 'isSet').withArgs('welcomeEmails').returns(true);
+            configUtils.set('memberWelcomeEmailTestInbox', 'test-inbox@example.com');
 
             await membersService.api.members.create({
                 email: 'imported@example.com',
@@ -81,7 +80,7 @@ describe('Member Welcome Emails Integration', function () {
         });
 
         it('does NOT create outbox entry when member is created by admin', async function () {
-            sinon.stub(labs, 'isSet').withArgs('welcomeEmails').returns(true);
+            configUtils.set('memberWelcomeEmailTestInbox', 'test-inbox@example.com');
 
             await membersService.api.members.create({
                 email: 'admin-created@example.com',
@@ -96,7 +95,7 @@ describe('Member Welcome Emails Integration', function () {
         });
 
         it('creates outbox entry with correct timestamp', async function () {
-            sinon.stub(labs, 'isSet').withArgs('welcomeEmails').returns(true);
+            configUtils.set('memberWelcomeEmailTestInbox', 'test-inbox@example.com');
 
             const beforeCreation = new Date(Date.now() - 1000);
             
diff --git a/ghost/core/test/unit/server/services/members/members-api/repositories/MemberRepository.test.js b/ghost/core/test/unit/server/services/members/members-api/repositories/MemberRepository.test.js
index 582ddfa7e94..0ad82f69203 100644
--- a/ghost/core/test/unit/server/services/members/members-api/repositories/MemberRepository.test.js
+++ b/ghost/core/test/unit/server/services/members/members-api/repositories/MemberRepository.test.js
@@ -4,6 +4,7 @@ const sinon = require('sinon');
 const DomainEvents = require('@tryghost/domain-events');
 const MemberRepository = require('../../../../../../../core/server/services/members/members-api/repositories/MemberRepository');
 const {SubscriptionCreatedEvent, OfferRedemptionEvent} = require('../../../../../../../core/shared/events');
+const config = require('../../../../../../../core/shared/config');
 
 const mockOfferRedemption = {
     add: sinon.stub(),
@@ -466,7 +467,6 @@ describe('MemberRepository', function () {
         let Outbox;
         let MemberStatusEvent;
         let MemberSubscribeEvent;
-        let labsService;
         let newslettersService;
         const oldNodeEnv = process.env.NODE_ENV;
 
@@ -527,16 +527,13 @@ describe('MemberRepository', function () {
         });
 
         it('creates outbox entry for allowed source', async function () {
-            labsService = {
-                isSet: sinon.stub().withArgs('welcomeEmails').returns(true)
-            };
+            sinon.stub(config, 'get').withArgs('memberWelcomeEmailTestInbox').returns('test-inbox@example.com');
 
             const repo = new MemberRepository({
                 Member,
                 Outbox,
                 MemberStatusEvent,
                 MemberSubscribeEventModel: MemberSubscribeEvent,
-                labsService,
                 newslettersService,
                 OfferRedemption: mockOfferRedemption
             });
@@ -554,17 +551,14 @@ describe('MemberRepository', function () {
             assert.equal(payload.source, 'member');
         });
 
-        it('does NOT create outbox entry when welcomeEmails lab flag is disabled', async function () {
-            labsService = {
-                isSet: sinon.stub().withArgs('welcomeEmails').returns(false)
-            };
+        it('does NOT create outbox entry when config is not set', async function () {
+            sinon.stub(config, 'get').withArgs('memberWelcomeEmailTestInbox').returns(undefined);
 
             const repo = new MemberRepository({
                 Member,
                 Outbox,
                 MemberStatusEvent,
                 MemberSubscribeEventModel: MemberSubscribeEvent,
-                labsService,
                 newslettersService,
                 OfferRedemption: mockOfferRedemption
             });
@@ -575,16 +569,13 @@ describe('MemberRepository', function () {
         });
 
         it('does not create outbox entry for disallowed sources', async function () {
-            labsService = {
-                isSet: sinon.stub().withArgs('welcomeEmails').returns(true)
-            };
+            sinon.stub(config, 'get').withArgs('memberWelcomeEmailTestInbox').returns('test-inbox@example.com');
 
             const repo = new MemberRepository({
                 Member,
                 Outbox,
                 MemberStatusEvent,
                 MemberSubscribeEventModel: MemberSubscribeEvent,
-                labsService,
                 newslettersService,
                 OfferRedemption: mockOfferRedemption
             });
@@ -603,16 +594,13 @@ describe('MemberRepository', function () {
         });
 
         it('includes timestamp in outbox payload', async function () {
-            labsService = {
-                isSet: sinon.stub().withArgs('welcomeEmails').returns(true)
-            };
+            sinon.stub(config, 'get').withArgs('memberWelcomeEmailTestInbox').returns('test-inbox@example.com');
 
             const repo = new MemberRepository({
                 Member,
                 Outbox,
                 MemberStatusEvent,
                 MemberSubscribeEventModel: MemberSubscribeEvent,
-                labsService,
                 newslettersService,
                 OfferRedemption: mockOfferRedemption
             });
@@ -625,16 +613,13 @@ describe('MemberRepository', function () {
         });
 
         it('passes transaction to outbox entry creation', async function () {
-            labsService = {
-                isSet: sinon.stub().withArgs('welcomeEmails').returns(true)
-            };
+            sinon.stub(config, 'get').withArgs('memberWelcomeEmailTestInbox').returns('test-inbox@example.com');
 
             const repo = new MemberRepository({
                 Member,
                 Outbox,
                 MemberStatusEvent,
                 MemberSubscribeEventModel: MemberSubscribeEvent,
-                labsService,
                 newslettersService,
                 OfferRedemption: mockOfferRedemption
             });
QODO_BENCH_DIFF_END
