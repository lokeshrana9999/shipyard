#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/prefect/pull/7 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/prefect/server/events/models/composite_trigger_child_firing.py b/src/prefect/server/events/models/composite_trigger_child_firing.py
index a5aeab421ec3..59d85d451603 100644
--- a/src/prefect/server/events/models/composite_trigger_child_firing.py
+++ b/src/prefect/server/events/models/composite_trigger_child_firing.py
@@ -7,12 +7,46 @@
 
 from prefect.server.database import PrefectDBInterface, db_injector
 from prefect.server.events.schemas.automations import CompositeTrigger, Firing
+from prefect.server.utilities.database import get_dialect
 from prefect.types._datetime import DateTime, now
 
 if TYPE_CHECKING:
     from prefect.server.database.orm_models import ORMCompositeTriggerChildFiring
 
 
+async def acquire_composite_trigger_lock(
+    session: AsyncSession,
+    trigger: CompositeTrigger,
+) -> None:
+    """
+    Acquire a transaction-scoped advisory lock for the given composite trigger.
+
+    This serializes concurrent child trigger evaluations for the same compound
+    trigger, preventing a race condition where multiple transactions each see
+    only their own child firing and neither fires the parent.
+
+    The lock is automatically released when the transaction commits or rolls back.
+    """
+    bind = session.get_bind()
+    if bind is None:
+        return
+
+    # Get the engine from either an Engine or Connection
+    engine: sa.Engine = bind if isinstance(bind, sa.Engine) else bind.engine  # type: ignore[union-attr]
+    dialect = get_dialect(engine)
+
+    if dialect.name == "postgresql":
+        # Use the trigger's UUID as the lock key
+        # pg_advisory_xact_lock takes a bigint, so we use the UUID's int representation
+        # truncated to fit (collision is extremely unlikely and benign)
+        lock_key = hash(str(trigger.id)) % (2**63)
+        await session.execute(
+            sa.text("SELECT pg_advisory_xact_lock(:key)"), {"key": lock_key}
+        )
+    # SQLite doesn't support advisory locks, but SQLite also serializes writes
+    # at the database level, so the race condition is less likely to occur
+
+
 @db_injector
 async def upsert_child_firing(
     db: PrefectDBInterface,
@@ -102,11 +136,22 @@ async def clear_child_firings(
     session: AsyncSession,
     trigger: CompositeTrigger,
     firing_ids: Sequence[UUID],
-) -> None:
-    await session.execute(
-        sa.delete(db.CompositeTriggerChildFiring).filter(
+) -> set[UUID]:
+    """
+    Delete the specified child firings and return the IDs that were actually deleted.
+
+    Returns the set of child_firing_ids that were successfully deleted. Callers can
+    compare this to the expected firing_ids to detect races and avoid double-firing
+    composite triggers.
+    """
+    result = await session.execute(
+        sa.delete(db.CompositeTriggerChildFiring)
+        .filter(
             db.CompositeTriggerChildFiring.automation_id == trigger.automation.id,
             db.CompositeTriggerChildFiring.parent_trigger_id == trigger.id,
             db.CompositeTriggerChildFiring.child_firing_id.in_(firing_ids),
         )
+        .returning(db.CompositeTriggerChildFiring.child_trigger_id)
     )
+
+    return set(result.scalars().all())
diff --git a/src/prefect/server/events/triggers.py b/src/prefect/server/events/triggers.py
index a5006bbaab5a..8d5f6fcea91b 100644
--- a/src/prefect/server/events/triggers.py
+++ b/src/prefect/server/events/triggers.py
@@ -35,6 +35,7 @@
     read_automation,
 )
 from prefect.server.events.models.composite_trigger_child_firing import (
+    acquire_composite_trigger_lock,
     clear_child_firings,
     clear_old_child_firings,
     get_child_firings,
@@ -65,12 +66,11 @@
 from prefect.settings.context import get_current_settings
 
 if TYPE_CHECKING:
-    import logging
-
     from prefect.server.database.orm_models import ORMAutomationBucket
 
+import logging
 
-logger: "logging.Logger" = get_logger(__name__)
+logger = logging.getLogger(__name__)
 
 AutomationID: TypeAlias = UUID
 TriggerID: TypeAlias = UUID
@@ -346,6 +346,11 @@ async def evaluate_composite_trigger(session: AsyncSession, firing: Firing) -> N
         )
         return
 
+    # Acquire an advisory lock to serialize concurrent evaluations for this
+    # compound trigger. This prevents a race condition where multiple child
+    # triggers fire concurrently and neither transaction sees both firings.
+    await acquire_composite_trigger_lock(session, trigger)
+
     # If we're only looking within a certain time horizon, remove any older firings that
     # should no longer be considered as satisfying this trigger
     if trigger.within is not None:
@@ -382,8 +387,27 @@ async def evaluate_composite_trigger(session: AsyncSession, firing: Firing) -> N
             },
         )
 
-        # clear by firing id
-        await clear_child_firings(session, trigger, firing_ids=list(firing_ids))
+        # Clear by firing id, and only proceed if we won the race to claim them.
+        # This prevents double-firing when multiple workers evaluate concurrently.
+        deleted_ids = await clear_child_firings(
+            session, trigger, firing_ids=list(firing_ids)
+        )
+
+        if len(deleted_ids) != len(firing_ids):
+            logger.debug(
+                "Composite trigger %s skipped fire; expected to delete %s firings, "
+                "actually deleted %s (another worker likely claimed them)",
+                trigger.id,
+                len(firing_ids),
+                len(deleted_ids),
+                extra={
+                    "automation": automation.id,
+                    "trigger": trigger.id,
+                    "expected_firing_ids": sorted(str(f) for f in firing_ids),
+                    "deleted_firing_ids": sorted(str(f) for f in deleted_ids),
+                },
+            )
+            return
 
         await fire(
             session,
diff --git a/tests/events/server/triggers/test_composite_triggers.py b/tests/events/server/triggers/test_composite_triggers.py
index b6d367c99df5..f135294b922b 100644
--- a/tests/events/server/triggers/test_composite_triggers.py
+++ b/tests/events/server/triggers/test_composite_triggers.py
@@ -1,3 +1,4 @@
+import asyncio
 import datetime
 from datetime import timedelta
 from typing import List
@@ -1624,3 +1625,123 @@ async def test_sequence_trigger_identical_event_triggers_only_one_fired_does_not
         await triggers.reactive_evaluation(ingredients_buy)
 
         act.assert_not_called()
+
+
+class TestCompoundTriggerConcurrency:
+    """Tests for concurrent child trigger evaluation race condition fix."""
+
+    @pytest.fixture
+    async def compound_automation_concurrent(
+        self,
+        automations_session: AsyncSession,
+        cleared_buckets: None,
+        cleared_automations: None,
+    ) -> Automation:
+        """Compound trigger requiring all child triggers to fire."""
+        compound_automation = Automation(
+            name="Compound Automation Concurrency Test",
+            trigger=CompoundTrigger(
+                require="all",
+                within=timedelta(minutes=5),
+                triggers=[
+                    EventTrigger(
+                        expect={"event.A"},
+                        match={"prefect.resource.id": "*"},
+                        posture=Posture.Reactive,
+                        threshold=1,
+                    ),
+                    EventTrigger(
+                        expect={"event.B"},
+                        match={"prefect.resource.id": "*"},
+                        posture=Posture.Reactive,
+                        threshold=1,
+                    ),
+                ],
+            ),
+            actions=[actions.DoNothing()],
+        )
+
+        persisted = await automations.create_automation(
+            session=automations_session, automation=compound_automation
+        )
+        compound_automation.created = persisted.created
+        compound_automation.updated = persisted.updated
+        triggers.load_automation(persisted)
+        await automations_session.commit()
+
+        return compound_automation
+
+    async def test_compound_trigger_does_not_double_fire_when_children_race(
+        self,
+        act: mock.AsyncMock,
+        compound_automation_concurrent: Automation,
+        start_of_test: DateTime,
+    ):
+        """
+        Regression test for compound trigger double-firing when child firings race.
+
+        Verifies that when two child trigger events are processed concurrently,
+        the compound trigger fires exactly once. The DELETE ... RETURNING fix
+        ensures only one worker proceeds to fire the parent trigger.
+        """
+        event_a = ReceivedEvent(
+            occurred=start_of_test + timedelta(microseconds=1),
+            event="event.A",
+            resource={"prefect.resource.id": "test.resource"},
+            id=uuid4(),
+        )
+        event_b = ReceivedEvent(
+            occurred=start_of_test + timedelta(microseconds=2),
+            event="event.B",
+            resource={"prefect.resource.id": "test.resource"},
+            id=uuid4(),
+        )
+
+        # Process both events concurrently
+        await asyncio.gather(
+            triggers.reactive_evaluation(event_a),
+            triggers.reactive_evaluation(event_b),
+        )
+
+        # The compound trigger should fire exactly once
+        act.assert_called_once()
+
+        firing: Firing = act.call_args.args[0]
+        assert isinstance(firing.trigger, CompoundTrigger)
+        assert firing.trigger.id == compound_automation_concurrent.trigger.id
+
+    async def test_concurrent_child_firings_still_triggers_parent(
+        self,
+        act: mock.AsyncMock,
+        compound_automation_concurrent: Automation,
+        start_of_test: DateTime,
+    ):
+        """
+        Verify that when two child trigger events arrive nearly simultaneously,
+        the compound trigger still fires. This tests that the race condition fix
+        doesn't prevent legitimate firings.
+        """
+        event_a = ReceivedEvent(
+            occurred=start_of_test + timedelta(microseconds=1),
+            event="event.A",
+            resource={"prefect.resource.id": "test.resource"},
+            id=uuid4(),
+        )
+        event_b = ReceivedEvent(
+            occurred=start_of_test + timedelta(microseconds=2),
+            event="event.B",
+            resource={"prefect.resource.id": "test.resource"},
+            id=uuid4(),
+        )
+
+        # Process both events concurrently to simulate the race condition
+        await asyncio.gather(
+            triggers.reactive_evaluation(event_a),
+            triggers.reactive_evaluation(event_b),
+        )
+
+        # The compound trigger should fire exactly once
+        act.assert_called_once()
+
+        firing: Firing = act.call_args.args[0]
+        assert firing.trigger.id == compound_automation_concurrent.trigger.id
QODO_BENCH_DIFF_END
