#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/aspnetcore/pull/7 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/Components/Web.JS/src/Rendering/JSRootComponents.ts b/src/Components/Web.JS/src/Rendering/JSRootComponents.ts
index a18a7f2d6cd4..eab1e22c99fa 100644
--- a/src/Components/Web.JS/src/Rendering/JSRootComponents.ts
+++ b/src/Components/Web.JS/src/Rendering/JSRootComponents.ts
@@ -10,7 +10,9 @@ let nextPendingDynamicRootComponentIdentifier = 0;
 type ComponentParameters = object | null | undefined;
 
 let manager: DotNet.DotNetObject | undefined;
+let currentRendererId: number | undefined;
 let jsComponentParametersByIdentifier: JSComponentParametersByIdentifier;
+let hasInitializedJsComponents = false;
 
 // These are the public APIs at Blazor.rootComponents.*
 export const RootComponentsFunctions = {
@@ -116,28 +118,35 @@ class DynamicRootComponent {
 
 // Called by the framework
 export function enableJSRootComponents(
+  rendererId: number,
   managerInstance: DotNet.DotNetObject,
   jsComponentParameters: JSComponentParametersByIdentifier,
   jsComponentInitializers: JSComponentIdentifiersByInitializer
 ): void {
-  if (manager) {
-    // This will only happen in very nonstandard cases where someone has multiple hosts.
-    // It's up to the developer to ensure that only one of them enables dynamic root components.
+  if (manager && currentRendererId === rendererId) {
+    // A different renderer type (e.g., Server vs WebAssembly) is trying to enable JS root components.
+    // This is a multi-host scenario which is not supported for dynamic root components.
     throw new Error('Dynamic root components have already been enabled.');
   }
 
+  // When the same renderer type re-enables (e.g., circuit restart or new circuit on same page),
+  // accept the new manager. The old manager's DotNetObjectReference is no longer valid anyway
+  // because the old circuit is gone. We don't dispose the old manager - doing so would cause
+  // JSDisconnectedException because the circuit that created it no longer exists.
+  currentRendererId = rendererId;
   manager = managerInstance;
-  jsComponentParametersByIdentifier = jsComponentParameters;
-
-  // Call the registered initializers. This is an arbitrary subset of the JS component types that are registered
-  // on the .NET side - just those of them that require some JS-side initialization (e.g., to register them
-  // as custom elements).
-  for (const [initializerIdentifier, componentIdentifiers] of Object.entries(jsComponentInitializers)) {
-    const initializerFunc = DotNet.findJSFunction(initializerIdentifier, 0) as JSComponentInitializerCallback;
-    for (const componentIdentifier of componentIdentifiers) {
-      const parameters = jsComponentParameters[componentIdentifier];
-      initializerFunc(componentIdentifier, parameters);
+
+  if (!hasInitializedJsComponents) {
+    // Call the registered initializers. This is an arbitrary subset of the JS component types that are registered
+    // on the .NET side - just those of them that require some JS-side initialization (e.g., to register them
+    // as custom elements).
+    for (const [initializerIdentifier, componentIdentifiers] of Object.entries(jsComponentInitializers)) {
+      const initializerFunc = DotNet.findJSFunction(initializerIdentifier, 0) as JSComponentInitializerCallback;
+      for (const componentIdentifier of componentIdentifiers)
+        initializerFunc(componentIdentifier, jsComponentParameters[componentIdentifier]);
     }
+
+    hasInitializedJsComponents = true;
   }
 }
 
diff --git a/src/Components/Web.JS/src/Rendering/WebRendererInteropMethods.ts b/src/Components/Web.JS/src/Rendering/WebRendererInteropMethods.ts
index 08ad1f73553b..d8b20b5a6b81 100644
--- a/src/Components/Web.JS/src/Rendering/WebRendererInteropMethods.ts
+++ b/src/Components/Web.JS/src/Rendering/WebRendererInteropMethods.ts
@@ -31,7 +31,7 @@ export function attachWebRendererInterop(
 
   if (jsComponentParameters && jsComponentInitializers && Object.keys(jsComponentParameters).length > 0) {
     const manager = getInteropMethods(rendererId);
-    enableJSRootComponents(manager, jsComponentParameters, jsComponentInitializers);
+    enableJSRootComponents(rendererId, manager, jsComponentParameters, jsComponentInitializers);
   }
 
   rendererByIdResolverMap.get(rendererId)?.[0]?.();
diff --git a/src/Components/test/E2ETest/Tests/StatePersistanceJSRootTest.cs b/src/Components/test/E2ETest/Tests/StatePersistanceJSRootTest.cs
deleted file mode 100644
index 9c554fccab79..000000000000
--- a/src/Components/test/E2ETest/Tests/StatePersistanceJSRootTest.cs
+++ /dev/null
@@ -1,42 +0,0 @@
-// Licensed to the .NET Foundation under one or more agreements.
-// The .NET Foundation licenses this file to you under the MIT license.
-
-using Components.TestServer.RazorComponents;
-using Microsoft.AspNetCore.Components.E2ETest.Infrastructure;
-using Microsoft.AspNetCore.Components.E2ETest.Infrastructure.ServerFixtures;
-using Microsoft.AspNetCore.Components.E2ETests.ServerRenderingTests;
-using Microsoft.AspNetCore.Components.Web;
-using Microsoft.AspNetCore.E2ETesting;
-using OpenQA.Selenium;
-using TestServer;
-using Xunit.Abstractions;
-
-namespace Microsoft.AspNetCore.Components.E2ETests.Tests;
-
-// These tests are for Blazor Web implementation
-// For Blazor Server and Webassembly, check SaveStateTest.cs
-public class StatePersistanceJSRootTest : ServerTestBase<BasicTestAppServerSiteFixture<RazorComponentEndpointsStartup<App>>>
-{
-    public StatePersistanceJSRootTest(
-        BrowserFixture browserFixture,
-        BasicTestAppServerSiteFixture<RazorComponentEndpointsStartup<App>> serverFixture,
-        ITestOutputHelper output)
-        : base(browserFixture, serverFixture, output)
-    {
-        serverFixture.AdditionalArguments.AddRange("--RegisterDynamicJSRootComponent", "true");
-    }
-
-    [Theory]
-    [InlineData("ServerNonPrerendered")]
-    [InlineData("WebAssemblyNonPrerendered")]
-    public void PersistentStateIsSupportedInDynamicJSRoots(string renderMode)
-    {
-        Navigate($"subdir/WasmMinimal/dynamic-js-root.html?renderMode={renderMode}");
-
-        Browser.Equal("Counter", () => Browser.Exists(By.TagName("h1")).Text);
-        Browser.Equal("Current count: 0", () => Browser.Exists(By.CssSelector("p[role='status']")).Text);
-
-        Browser.Click(By.CssSelector("button.btn-primary"));
-        Browser.Equal("Current count: 1", () => Browser.Exists(By.CssSelector("p[role='status']")).Text);
-    }
-}
diff --git a/src/Components/test/E2ETest/Tests/StatePersistenceTest.cs b/src/Components/test/E2ETest/Tests/StatePersistenceTest.cs
index 007c7ce5de16..3f74c7bc177a 100644
--- a/src/Components/test/E2ETest/Tests/StatePersistenceTest.cs
+++ b/src/Components/test/E2ETest/Tests/StatePersistenceTest.cs
@@ -276,6 +276,20 @@ public async Task StateIsProvidedEveryTimeACircuitGetsCreated(string streaming)
         RenderComponentsWithPersistentStateAndValidate(suppressEnhancedNavigation: false, mode, typeof(InteractiveServerRenderMode), streaming, stateValue: "other");
     }
 
+    [Theory]
+    [InlineData("ServerNonPrerendered")]
+    [InlineData("WebAssemblyNonPrerendered")]
+    public void PersistentStateIsSupportedInDynamicJSRoots(string renderMode)
+    {
+        Navigate($"subdir/WasmMinimal/dynamic-js-root.html?renderMode={renderMode}");
+
+        Browser.Equal("Counter", () => Browser.Exists(By.TagName("h1")).Text);
+        Browser.Equal("Current count: 0", () => Browser.Exists(By.CssSelector("p[role='status']")).Text);
+
+        Browser.Click(By.CssSelector("button.btn-primary"));
+        Browser.Equal("Current count: 1", () => Browser.Exists(By.CssSelector("p[role='status']")).Text);
+    }
+
     private void BlockWebAssemblyResourceLoad()
     {
         // Clear local storage so that the resource hash is not found
diff --git a/src/Components/test/testassets/Components.TestServer/Program.cs b/src/Components/test/testassets/Components.TestServer/Program.cs
index 58e39b5d11c8..2f06b00b72ac 100644
--- a/src/Components/test/testassets/Components.TestServer/Program.cs
+++ b/src/Components/test/testassets/Components.TestServer/Program.cs
@@ -24,7 +24,6 @@ public static async Task Main(string[] args)
             ["CORS (WASM)"] = (BuildWebHost<CorsStartup>(CreateAdditionalArgs(args)), "/subdir"),
             ["Prerendering (Server-side)"] = (BuildWebHost<PrerenderedStartup>(CreateAdditionalArgs(args)), "/prerendered"),
             ["Razor Component Endpoints"] = (BuildWebHost<RazorComponentEndpointsStartup<App>>(CreateAdditionalArgs(args)), "/subdir"),
-            ["Razor Component Endpoints with JS Root Component"] = (BuildWebHost<RazorComponentEndpointsStartup<App>>(CreateAdditionalArgs([.. args, "--RegisterDynamicJSRootComponent", "true"])), "/subdir"),
             ["Deferred component content (Server-side)"] = (BuildWebHost<DeferredComponentContentStartup>(CreateAdditionalArgs(args)), "/deferred-component-content"),
             ["Locked navigation (Server-side)"] = (BuildWebHost<LockedNavigationStartup>(CreateAdditionalArgs(args)), "/locked-navigation"),
             ["Client-side with fallback"] = (BuildWebHost<StartupWithMapFallbackToClientSideBlazor>(CreateAdditionalArgs(args)), "/fallback"),
diff --git a/src/Components/test/testassets/Components.TestServer/RazorComponentEndpointsStartup.cs b/src/Components/test/testassets/Components.TestServer/RazorComponentEndpointsStartup.cs
index 986d4c391fd0..13e457f49995 100644
--- a/src/Components/test/testassets/Components.TestServer/RazorComponentEndpointsStartup.cs
+++ b/src/Components/test/testassets/Components.TestServer/RazorComponentEndpointsStartup.cs
@@ -51,10 +51,7 @@ public void ConfigureServices(IServiceCollection services)
                     options.DisconnectedCircuitMaxRetained = 0;
                     options.DetailedErrors = true;
                 }
-                if (Configuration.GetValue<bool>("RegisterDynamicJSRootComponent"))
-                {
-                    options.RootComponents.RegisterForJavaScript<TestContentPackage.PersistentComponents.ComponentWithPersistentState>("dynamic-js-root-counter");
-                }
+                options.RootComponents.RegisterForJavaScript<TestContentPackage.PersistentComponents.ComponentWithPersistentState>("dynamic-js-root-counter");
             })
             .AddAuthenticationStateSerialization(options =>
             {
QODO_BENCH_DIFF_END
