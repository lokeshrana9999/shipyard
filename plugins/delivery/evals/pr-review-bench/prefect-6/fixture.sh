#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/prefect/pull/6 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/prefect/deployments/__init__.py b/src/prefect/deployments/__init__.py
index 8a0d147839d7..629d391ddc03 100644
--- a/src/prefect/deployments/__init__.py
+++ b/src/prefect/deployments/__init__.py
@@ -3,18 +3,19 @@
 
 
 if TYPE_CHECKING:
-    from .flow_runs import run_deployment
+    from .flow_runs import arun_deployment, run_deployment
     from .base import initialize_project
     from .runner import deploy
 
 _public_api: dict[str, tuple[str, str]] = {
     "initialize_project": (__spec__.parent, ".base"),
+    "arun_deployment": (__spec__.parent, ".flow_runs"),
     "run_deployment": (__spec__.parent, ".flow_runs"),
     "deploy": (__spec__.parent, ".runner"),
 }
 
 # Declare API for type-checkers
-__all__ = ["initialize_project", "deploy", "run_deployment"]
+__all__ = ["initialize_project", "deploy", "arun_deployment", "run_deployment"]
 
 
 def __getattr__(attr_name: str) -> object:
diff --git a/src/prefect/deployments/flow_runs.py b/src/prefect/deployments/flow_runs.py
index 9f36c5ffce79..f1f7ed71d8e4 100644
--- a/src/prefect/deployments/flow_runs.py
+++ b/src/prefect/deployments/flow_runs.py
@@ -8,14 +8,14 @@
 import prefect
 from prefect._result_records import ResultRecordMetadata
 from prefect.client.schemas import FlowRun, TaskRunResult
-from prefect.client.utilities import inject_client
+from prefect.client.utilities import get_or_create_client
 from prefect.context import FlowRunContext, TaskRunContext
 from prefect.logging import get_logger
 from prefect.states import Pending, Scheduled
 from prefect.tasks import Task
 from prefect.telemetry.run_telemetry import LABELS_TRACEPARENT_KEY, RunTelemetry
 from prefect.types._datetime import now
-from prefect.utilities.asyncutils import sync_compatible
+from prefect.utilities._engine import dynamic_key_for_task_run
 from prefect.utilities.slugify import slugify
 
 
@@ -45,9 +45,7 @@ def _is_instrumentation_enabled() -> bool:
 logger: "logging.Logger" = get_logger(__name__)
 
 
-@sync_compatible
-@inject_client
-async def run_deployment(
+async def arun_deployment(
     name: Union[str, UUID],
     client: Optional["PrefectClient"] = None,
     parameters: Optional[dict[str, Any]] = None,
@@ -62,7 +60,7 @@ async def run_deployment(
     job_variables: Optional[dict[str, Any]] = None,
 ) -> "FlowRun":
     """
-    Create a flow run for a deployment and return it after completion or a timeout.
+    Asynchronously create a flow run for a deployment and return it after completion or a timeout.
 
     By default, this function blocks until the flow run finishes executing.
     Specify a timeout (in seconds) to wait for the flow run to execute before
@@ -79,6 +77,7 @@ async def run_deployment(
     Args:
         name: The deployment id or deployment name in the form:
             `"flow name/deployment name"`
+        client: An optional PrefectClient to use for API requests.
         parameters: Parameter overrides for this flow run. Merged with the deployment
             defaults.
         scheduled_time: The time to schedule the flow run for, defaults to scheduling
@@ -100,6 +99,18 @@ async def run_deployment(
         job_variables: A dictionary of dot delimited infrastructure overrides that
             will be applied at runtime; for example `env.CONFIG_KEY=config_value` or
             `namespace='prefect'`
+
+    Example:
+        ```python
+        import asyncio
+        from prefect.deployments import arun_deployment
+
+        async def main():
+            flow_run = await arun_deployment("my-flow/my-deployment")
+            print(flow_run.state)
+
+        asyncio.run(main())
+        ```
     """
     if timeout is not None and timeout < 0:
         raise ValueError("`timeout` cannot be negative")
@@ -119,6 +130,8 @@ async def run_deployment(
         except ValueError:
             pass
 
+    client, _ = get_or_create_client(client)
+
     if deployment_id:
         deployment = await client.read_deployment(deployment_id=deployment_id)
     else:
@@ -133,7 +146,7 @@ async def run_deployment(
 
         # This was called from a flow. Link the flow run as a subflow.
         task_inputs = {
-            k: await collect_task_run_inputs(v) for k, v in parameters.items()
+            k: collect_task_run_inputs(v) for k, v in parameters.items()
         }
 
         # Track parent task if this is being called from within a task
@@ -196,7 +209,7 @@ async def run_deployment(
     trace_labels = {LABELS_TRACEPARENT_KEY: traceparent} if traceparent else {}
 
     flow_run = await client.create_flow_run_from_deployment(
-        deployment.id,
+        deployment_id,
         parameters=parameters,
         state=Scheduled(scheduled_time=scheduled_time),
         name=flow_run_name,
@@ -215,10 +228,14 @@ async def run_deployment(
 
     with anyio.move_on_after(timeout):
         while True:
+            await anyio.sleep(poll_interval)
             flow_run = await client.read_flow_run(flow_run_id)
             flow_state = flow_run.state
             if flow_state and flow_state.is_final():
                 return flow_run
-            await anyio.sleep(poll_interval)
 
     return flow_run
+
+
+# Alias for backwards compatibility
+run_deployment = arun_deployment
diff --git a/tests/deployment/test_flow_runs.py b/tests/deployment/test_flow_runs.py
index d98998f896ce..1aa30da683b3 100644
--- a/tests/deployment/test_flow_runs.py
+++ b/tests/deployment/test_flow_runs.py
@@ -1,3 +1,4 @@
+import inspect
 import re
 from datetime import timedelta
 from typing import TYPE_CHECKING
@@ -14,7 +15,7 @@
 from prefect.client.schemas import TaskRunResult
 from prefect.client.schemas.responses import DeploymentResponse
 from prefect.context import FlowRunContext
-from prefect.deployments import run_deployment
+from prefect.deployments import arun_deployment, run_deployment
 from prefect.flow_engine import run_flow_async
 from prefect.settings import (
     PREFECT_API_URL,
@@ -595,3 +596,335 @@ async def foo_flow() -> None:
         assert foo_span.parent
         assert foo_span.parent.span_id == app_root_span.get_span_context().span_id
         assert foo_span.parent.trace_id == app_root_span.get_span_context().trace_id
+
+
+class TestArunDeployment:
+    """Tests for the explicit async arun_deployment function."""
+
+    @pytest.fixture
+    async def test_deployment(self, prefect_client: PrefectClient):
+        flow_id = await prefect_client.create_flow_from_name("foo")
+
+        deployment_id = await prefect_client.create_deployment(
+            name="foo-deployment",
+            flow_id=flow_id,
+            parameter_openapi_schema={"type": "object", "properties": {}},
+        )
+        deployment = await prefect_client.read_deployment(deployment_id)
+
+        return deployment
+
+    async def test_arun_deployment_basic(
+        self, prefect_client: PrefectClient, test_deployment: DeploymentResponse
+    ):
+        """Test that arun_deployment can be called directly."""
+        deployment = test_deployment
+        flow_run = await arun_deployment(
+            f"foo/{deployment.name}",
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.state
+
+    async def test_arun_deployment_with_deployment_id(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment works with deployment UUID."""
+        deployment = test_deployment
+
+        flow_run = await arun_deployment(
+            deployment.id,
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.state
+
+    async def test_arun_deployment_with_parameters(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment passes parameters correctly."""
+        deployment = test_deployment
+
+        flow_run = await arun_deployment(
+            f"foo/{deployment.name}",
+            parameters={"test_param": "test_value"},
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.parameters == {"test_param": "test_value"}
+
+    async def test_arun_deployment_with_tags(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment accepts tags."""
+        deployment = test_deployment
+
+        flow_run = await arun_deployment(
+            f"foo/{deployment.name}",
+            tags=["async", "test"],
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+        assert sorted(flow_run.tags) == ["async", "test"]
+
+    async def test_arun_deployment_with_custom_name(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment accepts custom flow run names."""
+        deployment = test_deployment
+
+        flow_run = await arun_deployment(
+            f"foo/{deployment.name}",
+            flow_run_name="custom-async-run",
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+        assert flow_run.name == "custom-async-run"
+
+    async def test_arun_deployment_with_job_variables(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment passes job variables correctly."""
+        deployment = test_deployment
+
+        job_vars = {"env.MY_VAR": "my_value"}
+        flow_run = await arun_deployment(
+            deployment.id,
+            timeout=0,
+            job_variables=job_vars,
+            client=prefect_client,
+        )
+        assert flow_run.job_variables == job_vars
+
+    async def test_arun_deployment_negative_timeout_raises(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment raises on negative timeout."""
+        deployment = test_deployment
+
+        with pytest.raises(ValueError, match="`timeout` cannot be negative"):
+            await arun_deployment(
+                f"foo/{deployment.name}",
+                timeout=-1,
+                client=prefect_client,
+            )
+
+    async def test_arun_deployment_idempotency_key(
+        self,
+        test_deployment: DeploymentResponse,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment respects idempotency keys."""
+        deployment = test_deployment
+
+        flow_run_a = await arun_deployment(
+            f"foo/{deployment.name}",
+            idempotency_key="async-12345",
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+
+        flow_run_b = await arun_deployment(
+            f"foo/{deployment.name}",
+            idempotency_key="async-12345",
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+
+        assert flow_run_a.id == flow_run_b.id
+
+    async def test_arun_deployment_links_to_parent_flow(
+        self,
+        test_deployment: DeploymentResponse,
+        use_hosted_api_server,
+        prefect_client: PrefectClient,
+    ):
+        """Test that arun_deployment links to parent flow when called from within a flow."""
+        my_deployment = test_deployment
+
+        @flow
+        async def parent_flow():
+            return await arun_deployment(
+                f"foo/{my_deployment.name}",
+                timeout=0,
+                poll_interval=0,
+            )
+
+        parent_state = await parent_flow(return_state=True)
+        child_flow_run = await parent_state.result()
+        assert child_flow_run.parent_task_run_id is not None
+        task_run = await prefect_client.read_task_run(child_flow_run.parent_task_run_id)
+        assert task_run.flow_run_id == parent_state.state_details.flow_run_id
+
+
+class TestRunDeploymentSyncContext:
+    """Tests for run_deployment behavior in sync context."""
+
+    @pytest.fixture
+    def test_deployment_sync(self, sync_prefect_client):
+        flow_id = sync_prefect_client.create_flow_from_name("foo-sync")
+
+        deployment_id = sync_prefect_client.create_deployment(
+            name="foo-sync-deployment",
+            flow_id=flow_id,
+            parameter_openapi_schema={"type": "object", "properties": {}},
+        )
+        deployment = sync_prefect_client.read_deployment(deployment_id)
+
+        return deployment
+
+    def test_run_deployment_sync_basic(
+        self,
+        sync_prefect_client,
+        test_deployment_sync,
+    ):
+        """Test that run_deployment works in a synchronous context."""
+        deployment = test_deployment_sync
+        # Force sync execution using _sync parameter
+        flow_run = run_deployment(
+            f"foo-sync/{deployment.name}",
+            timeout=0,
+            poll_interval=0,
+            _sync=True,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.state
+
+    def test_run_deployment_sync_with_parameters(
+        self,
+        sync_prefect_client,
+        test_deployment_sync,
+    ):
+        """Test that run_deployment in sync context passes parameters correctly."""
+        deployment = test_deployment_sync
+
+        flow_run = run_deployment(
+            f"foo-sync/{deployment.name}",
+            parameters={"sync_param": "sync_value"},
+            timeout=0,
+            poll_interval=0,
+            _sync=True,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.parameters == {"sync_param": "sync_value"}
+
+    def test_run_deployment_sync_with_tags(
+        self,
+        sync_prefect_client,
+        test_deployment_sync,
+    ):
+        """Test that run_deployment in sync context accepts tags."""
+        deployment = test_deployment_sync
+
+        flow_run = run_deployment(
+            f"foo-sync/{deployment.name}",
+            tags=["sync", "test"],
+            timeout=0,
+            poll_interval=0,
+            _sync=True,
+        )
+        assert sorted(flow_run.tags) == ["sync", "test"]
+
+    def test_run_deployment_sync_negative_timeout_raises(
+        self,
+        sync_prefect_client,
+        test_deployment_sync,
+    ):
+        """Test that run_deployment in sync context raises on negative timeout."""
+        deployment = test_deployment_sync
+
+        with pytest.raises(ValueError, match="`timeout` cannot be negative"):
+            run_deployment(
+                f"foo-sync/{deployment.name}",
+                timeout=-1,
+                _sync=True,
+            )
+
+    def test_run_deployment_sync_with_deployment_id(
+        self,
+        sync_prefect_client,
+        test_deployment_sync,
+    ):
+        """Test that run_deployment in sync context works with deployment UUID."""
+        deployment = test_deployment_sync
+
+        flow_run = run_deployment(
+            deployment.id,
+            timeout=0,
+            poll_interval=0,
+            _sync=True,
+        )
+        assert flow_run.deployment_id == deployment.id
+        assert flow_run.state
+
+
+class TestAsyncDispatchBehavior:
+    """Tests to verify async_dispatch routes correctly between sync and async."""
+
+    @pytest.fixture
+    async def test_deployment(self, prefect_client: PrefectClient):
+        flow_id = await prefect_client.create_flow_from_name("dispatch-test")
+
+        deployment_id = await prefect_client.create_deployment(
+            name="dispatch-deployment",
+            flow_id=flow_id,
+            parameter_openapi_schema={"type": "object", "properties": {}},
+        )
+        deployment = await prefect_client.read_deployment(deployment_id)
+
+        return deployment
+
+    async def test_run_deployment_dispatches_to_async_in_async_context(
+        self,
+        prefect_client: PrefectClient,
+        test_deployment: DeploymentResponse,
+    ):
+        """Test that run_deployment returns a coroutine when called in async context."""
+        deployment = test_deployment
+
+        # When called without await, run_deployment should return a coroutine in async context
+        result = run_deployment(
+            f"dispatch-test/{deployment.name}",
+            timeout=0,
+            poll_interval=0,
+            client=prefect_client,
+        )
+
+        # Verify it's a coroutine
+        assert inspect.iscoroutine(result)
+
+        # Now await it
+        flow_run = await result
+        assert flow_run.deployment_id == deployment.id
+
+    async def test_run_deployment_aio_attribute(
+        self,
+        prefect_client: PrefectClient,
+        test_deployment: DeploymentResponse,
+    ):
+        """Test that run_deployment.aio attribute references arun_deployment."""
+        # The .aio attribute should be available for backward compatibility
+        assert hasattr(run_deployment, "aio")
+        assert run_deployment.aio is arun_deployment
QODO_BENCH_DIFF_END
