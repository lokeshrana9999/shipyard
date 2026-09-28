#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/prefect/pull/1 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/docs/docs.json b/docs/docs.json
index 85dfbd232fa8..71a9c2729c1e 100644
--- a/docs/docs.json
+++ b/docs/docs.json
@@ -255,11 +255,17 @@
               "v3/advanced/transactions",
               "v3/advanced/cancel-workflows",
               "v3/advanced/interactive",
-              "v3/advanced/form-building",
               "v3/advanced/results",
               "v3/advanced/background-tasks"
             ]
           },
+          {
+            "group": "Deployments",
+            "pages": [
+              "v3/advanced/form-building",
+              "v3/advanced/generate-custom-sdk"
+            ]
+          },
           {
             "group": "Automations",
             "pages": [
@@ -800,6 +806,7 @@
                   "v3/api-ref/cli/init",
                   "v3/api-ref/cli/profile",
                   "v3/api-ref/cli/profiles",
+                  "v3/api-ref/cli/sdk",
                   "v3/api-ref/cli/server",
                   "v3/api-ref/cli/shell",
                   "v3/api-ref/cli/task-run",
diff --git a/docs/v3/advanced/generate-custom-sdk.mdx b/docs/v3/advanced/generate-custom-sdk.mdx
new file mode 100644
index 000000000000..90dea206cd30
--- /dev/null
+++ b/docs/v3/advanced/generate-custom-sdk.mdx
@@ -0,0 +1,174 @@
+---
+title: How to generate a custom SDK for your deployments
+sidebarTitle: Generate a Custom SDK
+description: Generate a custom Python SDK from your deployments for IDE autocomplete and type checking.
+---
+
+The `prefect sdk generate` command creates a typed Python file from your [deployments](/v3/concepts/deployments). This gives you IDE autocomplete and static type checking when triggering deployment runs programmatically.
+
+<Note>
+This feature is in **beta**. APIs may change in future releases.
+</Note>
+
+## Prerequisites
+
+- An active Prefect API connection (Prefect Cloud or self-hosted server)
+- At least one [deployment](/v3/how-to-guides/deployments/create-deployments) in your workspace
+
+## Generate an SDK from the CLI
+
+Generate a typed SDK for all deployments in your workspace:
+
+```bash
+prefect sdk generate --output ./my_sdk.py
+```
+
+### Filter to specific flows or deployments
+
+Generate an SDK for specific flows:
+
+```bash
+prefect sdk generate --output ./my_sdk.py --flow my-etl-flow
+```
+
+Generate an SDK for specific deployments:
+
+```bash
+prefect sdk generate --output ./my_sdk.py --deployment my-flow/production
+```
+
+Combine multiple filters:
+
+```bash
+prefect sdk generate --output ./my_sdk.py \
+    --flow etl-flow \
+    --flow data-sync \
+    --deployment analytics/daily
+```
+
+## Run deployments with the generated SDK
+
+The generated SDK provides a `deployments.from_name()` method that returns a typed deployment object:
+
+{/* pmd-metadata: notest */}
+```python
+from my_sdk import deployments
+
+# Get a deployment by name
+deployment = deployments.from_name("my-etl-flow/production")
+
+# Run with parameters
+future = deployment.run(
+    source="s3://my-bucket/data",
+    batch_size=100,
+)
+
+# Get the flow run ID immediately
+print(f"Started flow run: {future.flow_run_id}")
+
+# Wait for completion and get result
+result = future.result()
+```
+
+### Configure run options
+
+Use `with_options()` to set tags, scheduling, and other run configuration:
+
+{/* pmd-metadata: notest */}
+```python
+from my_sdk import deployments
+from datetime import datetime, timedelta
+
+future = deployments.from_name("my-etl-flow/production").with_options(
+    tags=["manual", "production"],
+    idempotency_key="daily-run-2024-01-15",
+    scheduled_time=datetime.now() + timedelta(hours=1),
+    flow_run_name="custom-run-name",
+).run(
+    source="s3://bucket",
+)
+```
+
+Available options:
+- `tags`: Tags to apply to the flow run
+- `idempotency_key`: Unique key to prevent duplicate runs
+- `work_queue_name`: Override the work queue
+- `as_subflow`: Run as a subflow of the current flow
+- `scheduled_time`: Schedule the run for a future time
+- `flow_run_name`: Custom name for the flow run
+
+### Override job variables
+
+Use `with_infra()` to override work pool job variables:
+
+{/* pmd-metadata: notest */}
+```python
+from my_sdk import deployments
+
+future = deployments.from_name("my-etl-flow/production").with_infra(
+    image="my-registry/my-image:latest",
+    cpu_request="2",
+    memory="8Gi",
+).run(
+    source="s3://bucket",
+)
+```
+
+The available job variables depend on your work pool type. The generated SDK provides type hints for the options available on each deployment's work pool.
+
+### Async usage
+
+In an async context, use `run_async()`:
+
+{/* pmd-metadata: notest */}
+```python
+import asyncio
+from my_sdk import deployments
+
+async def trigger_deployment():
+    future = await deployments.from_name("my-etl-flow/production").run_async(
+        source="s3://bucket",
+    )
+    result = await future.result()
+    return result
+
+# Run it
+result = asyncio.run(trigger_deployment())
+```
+
+### Chain methods together
+
+{/* pmd-metadata: notest */}
+```python
+from my_sdk import deployments
+
+future = (
+    deployments.from_name("my-etl-flow/production")
+    .with_options(tags=["production"])
+    .with_infra(memory="8Gi")
+    .run(source="s3://bucket", batch_size=100)
+)
+```
+
+## Regenerate the SDK after changes
+
+The SDK is generated from server-side metadata. Regenerate it when:
+- Deployments are added, removed, or renamed
+- Flow parameter schemas change
+- Work pool job variable schemas change
+
+The `generate` command overwrites the existing file:
+
+```bash
+prefect sdk generate --output ./my_sdk.py
+```
+
+<Tip>
+Add SDK regeneration to your CI/CD pipeline to keep it in sync with your deployments.
+</Tip>
+
+## Further reading
+
+- [Create deployments](/v3/how-to-guides/deployments/create-deployments)
+- [Trigger ad-hoc deployment runs](/v3/how-to-guides/deployments/run-deployments)
+- [Override job configuration](/v3/how-to-guides/deployments/customize-job-variables)
diff --git a/docs/v3/api-ref/cli/sdk.mdx b/docs/v3/api-ref/cli/sdk.mdx
new file mode 100644
index 000000000000..6e30b727b2d9
--- /dev/null
+++ b/docs/v3/api-ref/cli/sdk.mdx
@@ -0,0 +1,82 @@
+---
+title: " "
+sidebarTitle: prefect sdk
+---
+
+# `prefect sdk`
+
+
+
+```command
+prefect sdk [OPTIONS] COMMAND [ARGS]...
+```
+
+
+
+<Info>
+Manage Prefect SDKs. (beta)
+</Info>
+
+
+
+
+
+
+
+
+## `prefect sdk generate`
+
+
+
+```command
+prefect sdk generate [OPTIONS]
+```
+
+
+
+<Info>
+(beta) Generate a typed Python SDK from workspace deployments.
+
+The generated SDK provides IDE autocomplete and type checking for your deployments.
+Requires an active Prefect API connection (use `prefect cloud login` or configure
+PREFECT_API_URL).
+
+
+Examples:
+    Generate SDK for all deployments:
+        \$ prefect sdk generate --output ./my_sdk.py
+
+    Generate SDK for specific flows:
+        \$ prefect sdk generate --output ./my_sdk.py --flow my-etl-flow
+
+    Generate SDK for specific deployments:
+        \$ prefect sdk generate --output ./my_sdk.py --deployment my-flow/production
+</Info>
+
+
+
+
+
+
+<AccordionGroup>
+
+
+
+
+<Accordion title="Options" defaultOpen>
+
+<ResponseField name="--output">
+    Output file path for the generated SDK.
+</ResponseField>
+
+<ResponseField name="--flow">
+    Filter to specific flow(s). Can be specified multiple times.
+</ResponseField>
+
+<ResponseField name="--deployment">
+    Filter to specific deployment(s). Can be specified multiple times. Use 'flow-name/deployment-name' format for exact matching.
+</ResponseField>
+
+</Accordion>
+
+</AccordionGroup>
diff --git a/src/prefect/_sdk/fetcher.py b/src/prefect/_sdk/fetcher.py
index d4873540d875..9e076e73e265 100644
--- a/src/prefect/_sdk/fetcher.py
+++ b/src/prefect/_sdk/fetcher.py
@@ -8,12 +8,16 @@
 from __future__ import annotations
 
 import asyncio
+import logging
 from dataclasses import dataclass, field
 from datetime import datetime, timezone
 from typing import TYPE_CHECKING, Any
 from uuid import UUID
 
 import prefect
+
+# Logger for SDK fetcher operations
+logger = logging.getLogger(__name__)
 from prefect._sdk.models import (
     DeploymentInfo,
     FlowInfo,
@@ -175,9 +179,7 @@ async def _fetch_work_pool(
         job_vars_schema: dict[str, Any] = {}
         base_job_template = work_pool.base_job_template
         if base_job_template and "variables" in base_job_template:
-            variables = base_job_template["variables"]
-            if isinstance(variables, dict):
-                job_vars_schema = variables
+            job_vars_schema = base_job_template["variables"]
 
         return WorkPoolInfo(
             name=work_pool.name,
@@ -215,7 +217,7 @@ async def _fetch_work_pools_parallel(
     results = await asyncio.gather(*tasks, return_exceptions=True)
 
     work_pools: dict[str, WorkPoolInfo] = {}
-    for name, result in zip(pool_names_list, results, strict=True):
+    for name, result in zip(pool_names_list, results):
         if isinstance(result, BaseException):
             warnings.append(
                 f"Could not fetch work pool '{name}' - `with_infra()` will not be "
@@ -316,6 +318,7 @@ async def fetch_sdk_data(
     errors: list[str] = []
 
     # Check authentication first
+    logger.debug("Checking authentication with Prefect API")
     await _check_authentication(client)
 
     # Build filters
@@ -391,7 +394,7 @@ async def fetch_sdk_data(
 
         # If filtering by deployment name, check the full name matches
         full_name = f"{flow_name}/{dep.name}"
-        if deployment_names and full_name not in deployment_names:
+        if deployment_names and dep.name not in deployment_names:
             # Only include if the full name matches (filter was by name parts)
             # Skip if user specified full names and this doesn't match
             found_match = False
QODO_BENCH_DIFF_END
