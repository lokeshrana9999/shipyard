#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/aspnetcore/pull/3 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/Shared/CertificateGeneration/CertificateManager.cs b/src/Shared/CertificateGeneration/CertificateManager.cs
index 6d4f847158f3..5430a956d7c7 100644
--- a/src/Shared/CertificateGeneration/CertificateManager.cs
+++ b/src/Shared/CertificateGeneration/CertificateManager.cs
@@ -966,9 +966,6 @@ internal static bool TryFindCertificateInStore(X509Store store, X509Certificate2
         return foundCertificate is not null;
     }
 
-    /// <remarks>
-    /// Note that dotnet-dev-certs won't display any of these, regardless of level, unless --verbose is passed.
-    /// </remarks>
     [EventSource(Name = "Dotnet-dev-certs")]
     public sealed class CertificateManagerEventSource : EventSource
     {
@@ -1303,7 +1300,7 @@ public sealed class CertificateManagerEventSource : EventSource
         internal void UnixNotOverwritingCertificate(string certPath) => WriteEvent(109, certPath);
 
         [Event(110, Level = EventLevel.LogAlways, Message = "For OpenSSL trust to take effect, '{0}' must be listed in the {2} environment variable. " +
-            "For example, `export SSL_CERT_DIR={0}:{1}`. " +
+            "For example, `export {2}=\"{0}:{1}\"`. " +
             "See https://aka.ms/dev-certs-trust for more information.")]
         internal void UnixSuggestSettingEnvironmentVariable(string certDir, string openSslDir, string envVarName) => WriteEvent(110, certDir, openSslDir, envVarName);
 
@@ -1313,6 +1310,14 @@ public sealed class CertificateManagerEventSource : EventSource
 
         [Event(112, Level = EventLevel.Warning, Message = "Directory '{0}' may be readable by other users.")]
         internal void DirectoryPermissionsNotSecure(string directoryPath) => WriteEvent(112, directoryPath);
+
+        [Event(113, Level = EventLevel.Verbose, Message = "The certificate directory '{0}' is already included in the {1} environment variable.")]
+        internal void UnixOpenSslCertificateDirectoryAlreadyConfigured(string certDir, string envVarName) => WriteEvent(113, certDir, envVarName);
+
+        [Event(114, Level = EventLevel.LogAlways, Message = "For OpenSSL trust to take effect, '{0}' must be listed in the {1} environment variable. " +
+            "For example, `export {1}=\"{0}:${1}\"`. " +
+            "See https://aka.ms/dev-certs-trust for more information.")]
+        internal void UnixSuggestAppendingToEnvironmentVariable(string certDir, string envVarName) => WriteEvent(114, certDir, envVarName);
     }
 
     internal sealed class UserCancelledTrustException : Exception
diff --git a/src/Shared/CertificateGeneration/UnixCertificateManager.cs b/src/Shared/CertificateGeneration/UnixCertificateManager.cs
index 10cfcc08d38f..689a22982d9e 100644
--- a/src/Shared/CertificateGeneration/UnixCertificateManager.cs
+++ b/src/Shared/CertificateGeneration/UnixCertificateManager.cs
@@ -355,14 +355,57 @@ protected override TrustLevel TrustCertificateCore(X509Certificate2 certificate)
                 ? Path.Combine("$HOME", certDir[homeDirectoryWithSlash.Length..])
                 : certDir;
 
-            if (TryGetOpenSslDirectory(out var openSslDir))
+            var hasValidSslCertDir = false;
+
+            // Check if SSL_CERT_DIR is already set and if certDir is already included
+            var existingSslCertDir = Environment.GetEnvironmentVariable(OpenSslCertificateDirectoryVariableName);
+            if (!string.IsNullOrEmpty(existingSslCertDir))
+            {
+                var existingDirs = existingSslCertDir.Split(Path.PathSeparator);
+                var certDirFullPath = Path.GetFullPath(prettyCertDir);
+                var isCertDirIncluded = existingDirs.Any(dir =>
+                {
+                    if (string.IsNullOrWhiteSpace(dir))
+                    {
+                        return false;
+                    }
+
+                    try
+                    {
+                        return string.Equals(Path.GetFullPath(dir), certDirFullPath, StringComparison.OrdinalIgnoreCase);
+                    }
+                    catch
+                    {
+                        // Ignore invalid directory entries in SSL_CERT_DIR
+                        return false;
+                    }
+                });
+
+                if (isCertDirIncluded)
+                {
+                    // The certificate directory is already in SSL_CERT_DIR, no action needed
+                    Log.UnixOpenSslCertificateDirectoryAlreadyConfigured(prettyCertDir, OpenSslCertificateDirectoryVariableName);
+                    hasValidSslCertDir = true;
+                }
+                else
+                {
+                    // SSL_CERT_DIR is set but doesn't include our directory - suggest appending
+                    Log.UnixSuggestAppendingToEnvironmentVariable(prettyCertDir, OpenSslCertificateDirectoryVariableName);
+                    hasValidSslCertDir = false;
+                }
+            }
+            else if (TryGetOpenSslDirectory(out var openSslDir))
             {
                 Log.UnixSuggestSettingEnvironmentVariable(prettyCertDir, Path.Combine(openSslDir, "certs"), OpenSslCertificateDirectoryVariableName);
+                hasValidSslCertDir = false;
             }
             else
             {
                 Log.UnixSuggestSettingEnvironmentVariableWithoutExample(prettyCertDir, OpenSslCertificateDirectoryVariableName);
+                hasValidSslCertDir = false;
             }
+
+            sawTrustFailure = !hasValidSslCertDir;
         }
 
         return sawTrustFailure
@@ -948,9 +991,18 @@ private static bool TryRehashOpenSslCertificates(string certificateDirectory)
         return true;
     }
 
-    private sealed class NssDb(string path, bool isFirefox)
+    private sealed class NssDb
     {
-        public string Path => path;
-        public bool IsFirefox => isFirefox;
+        private readonly string _path;
+        private readonly bool _isFirefox;
+
+        public NssDb(string path, bool isFirefox)
+        {
+            _path = path;
+            _isFirefox = isFirefox;
+        }
+
+        public string Path => _path;
+        public bool IsFirefox => _isFirefox;
     }
 }
diff --git a/src/Tools/dotnet-dev-certs/src/Program.cs b/src/Tools/dotnet-dev-certs/src/Program.cs
index bf6a9d964a5c..23256d88e609 100644
--- a/src/Tools/dotnet-dev-certs/src/Program.cs
+++ b/src/Tools/dotnet-dev-certs/src/Program.cs
@@ -124,16 +124,20 @@ public static int Main(string[] args)
                 {
                     var reporter = new ConsoleReporter(PhysicalConsole.Singleton, verbose.HasValue(), quiet.HasValue());
 
+                    var listener = new ReporterEventListener(reporter);
                     if (verbose.HasValue())
                     {
-                        var listener = new ReporterEventListener(reporter);
                         listener.EnableEvents(CertificateManager.Log, System.Diagnostics.Tracing.EventLevel.Verbose);
                     }
+                    else
+                    {
+                        listener.EnableEvents(CertificateManager.Log, System.Diagnostics.Tracing.EventLevel.LogAlways);
+                    }
 
                     if (checkJsonOutput.HasValue())
                     {
                         if (exportPath.HasValue() || trust?.HasValue() == true || format.HasValue() || noPassword.HasValue() || check.HasValue() || clean.HasValue() ||
-                           (!import.HasValue() && password.HasValue()) || 
+                           (!import.HasValue() && password.HasValue()) ||
                            (import.HasValue() && !password.HasValue()))
                         {
                             reporter.Error(InvalidUsageErrorMessage);
QODO_BENCH_DIFF_END
