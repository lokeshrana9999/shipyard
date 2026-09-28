#!/usr/bin/env bash
# Merged upstream PR https://github.com/dotnet/aspnetcore/pull/69233, used as a clean diff (see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/Middleware/OutputCaching/src/OutputCacheKeyProvider.cs b/src/Middleware/OutputCaching/src/OutputCacheKeyProvider.cs
index 03d21a6cc16d..cb1729e292d8 100644
--- a/src/Middleware/OutputCaching/src/OutputCacheKeyProvider.cs
+++ b/src/Middleware/OutputCaching/src/OutputCacheKeyProvider.cs
@@ -16,7 +16,7 @@ internal sealed class OutputCacheKeyProvider : IOutputCacheKeyProvider
     private const char KeyDelimiter = '\x1e';
     // Use the unit separator for delimiting subcomponents of the cache key to avoid possible collisions
     private const char KeySubDelimiter = '\x1f';
-    // Use the group separator for delimiting a name from its value to avoid possible collisions.
+    // Use the group separator for delimiting a name from its value and representing empty values to avoid possible collisions.
     // A literal '=' cannot be used because it can legitimately appear in decoded header/query names and values.
     private const char KeyNameValueDelimiter = '\x1d';
 
@@ -185,12 +185,10 @@ public bool TryAppendVaryByKey(OutputCacheContext context, StringBuilder builder
                         builder.Append(KeySubDelimiter);
                     }
 
-                    if (ContainsDelimiters(headerValuesArray[j]))
+                    if (!TryAppendValue(builder, headerValuesArray[j]))
                     {
                         return false;
                     }
-
-                    builder.Append(headerValuesArray[j]);
                 }
             }
         }
@@ -231,12 +229,10 @@ public bool TryAppendVaryByKey(OutputCacheContext context, StringBuilder builder
                             builder.Append(KeySubDelimiter);
                         }
 
-                        if (ContainsDelimiters(queryValueArray[j]))
+                        if (!TryAppendValue(builder, queryValueArray[j]))
                         {
                             return false;
                         }
-
-                        builder.Append(queryValueArray[j]);
                     }
                 }
             }
@@ -264,12 +260,10 @@ public bool TryAppendVaryByKey(OutputCacheContext context, StringBuilder builder
                             builder.Append(KeySubDelimiter);
                         }
 
-                        if (ContainsDelimiters(queryValueArray[j]))
+                        if (!TryAppendValue(builder, queryValueArray[j]))
                         {
                             return false;
                         }
-
-                        builder.Append(queryValueArray[j]);
                     }
                 }
             }
@@ -344,6 +338,25 @@ public bool TryAppendVaryByKey(OutputCacheContext context, StringBuilder builder
         return true;
     }
 
+    private static bool TryAppendValue(StringBuilder builder, string? value)
+    {
+        if (ContainsDelimiters(value))
+        {
+            return false;
+        }
+
+        if (string.IsNullOrEmpty(value))
+        {
+            builder.Append(KeyNameValueDelimiter);
+        }
+        else
+        {
+            builder.Append(value);
+        }
+
+        return true;
+    }
+
     internal static string[] GetOrderDictionaryKeys(IDictionary<string, string>? dictionary)
     {
         if (dictionary == null || dictionary.Count == 0)
diff --git a/src/Middleware/OutputCaching/test/OutputCacheKeyProviderTests.cs b/src/Middleware/OutputCaching/test/OutputCacheKeyProviderTests.cs
index d08713330758..2bfecfd4d68d 100644
--- a/src/Middleware/OutputCaching/test/OutputCacheKeyProviderTests.cs
+++ b/src/Middleware/OutputCaching/test/OutputCacheKeyProviderTests.cs
@@ -207,6 +207,32 @@ public void OutputCachingKeyProvider_CreateStorageKey_HeaderValuesPreserveOrigin
             cacheKeyProvider.CreateStorageKey(context));
     }
 
+    [Fact]
+    public void OutputCachingKeyProvider_CreateStorageKey_EmptyHeaderValueDoesNotCollideWithAbsentHeader()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var absentContext = TestUtils.CreateTestContext();
+        absentContext.CacheVaryByRules.HeaderNames = new string[] { "HeaderA" };
+        var emptyContext = TestUtils.CreateTestContext();
+        emptyContext.HttpContext.Request.Headers["HeaderA"] = string.Empty;
+        emptyContext.CacheVaryByRules.HeaderNames = new string[] { "HeaderA" };
+
+        Assert.NotEqual(cacheKeyProvider.CreateStorageKey(absentContext), cacheKeyProvider.CreateStorageKey(emptyContext));
+    }
+
+    [Fact]
+    public void OutputCachingKeyProvider_CreateStorageKey_EncodesEmptyHeaderValueInSequence()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.Headers["HeaderA"] = string.Empty;
+        context.HttpContext.Request.Headers.Append("HeaderA", "ValueA");
+        context.CacheVaryByRules.HeaderNames = new string[] { "HeaderA" };
+
+        Assert.Equal($"{EmptyBaseKey}{KeyDelimiter}H{KeyDelimiter}HeaderA{KeyNameValueDelimiter}{KeyNameValueDelimiter}{KeySubDelimiter}ValueA",
+            cacheKeyProvider.CreateStorageKey(context));
+    }
+
     [Fact]
     public void OutputCachingKeyProvider_CreateStorageKey_IncludesListedQueryKeysOnly()
     {
@@ -291,6 +317,45 @@ public void OutputCachingKeyProvider_CreateStorageKey_QueryKeysValuesPreserveOri
             cacheKeyProvider.CreateStorageKey(context));
     }
 
+    [Fact]
+    public void OutputCachingKeyProvider_CreateStorageKey_EmptyQueryValueDoesNotCollideWithAbsentQuery()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var absentContext = TestUtils.CreateTestContext();
+        absentContext.CacheVaryByRules.QueryKeys = new string[] { "QueryA" };
+        var emptyContext = TestUtils.CreateTestContext();
+        emptyContext.HttpContext.Request.QueryString = new QueryString("?QueryA=");
+        emptyContext.CacheVaryByRules.QueryKeys = new string[] { "QueryA" };
+
+        Assert.NotEqual(cacheKeyProvider.CreateStorageKey(absentContext), cacheKeyProvider.CreateStorageKey(emptyContext));
+    }
+
+    [Fact]
+    public void OutputCachingKeyProvider_CreateStorageKey_EncodesEmptyExplicitQueryValueInSequence()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.QueryString = new QueryString("?QueryA=&QueryA=ValueA");
+        context.CacheVaryByRules.QueryKeys = new string[] { "QueryA" };
+
+        Assert.Equal($"{EmptyBaseKey}{KeyDelimiter}Q{KeyDelimiter}QueryA{KeyNameValueDelimiter}{KeyNameValueDelimiter}{KeySubDelimiter}ValueA",
+            cacheKeyProvider.CreateStorageKey(context));
+    }
+
+    [Theory]
+    [InlineData("?QueryA=", "\u001d")]
+    [InlineData("?QueryA=&QueryA=ValueA", "\u001d\u001fValueA")]
+    public void OutputCachingKeyProvider_CreateStorageKey_EncodesEmptyWildcardQueryValues(string queryString, string expectedValues)
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.QueryString = new QueryString(queryString);
+        context.CacheVaryByRules.QueryKeys = new string[] { "*" };
+
+        Assert.Equal($"{EmptyBaseKey}{KeyDelimiter}Q{KeyDelimiter}QUERYA{KeyNameValueDelimiter}{expectedValues}",
+            cacheKeyProvider.CreateStorageKey(context));
+    }
+
     [Fact]
     public void OutputCachingKeyProvider_CreateStorageKey_SelectedHeaderValues_DoesNotMutateRequestHeaderValueOrder()
     {
diff --git a/src/Middleware/ResponseCaching/src/ResponseCachingKeyProvider.cs b/src/Middleware/ResponseCaching/src/ResponseCachingKeyProvider.cs
index 8e4e5b43415a..7c0d025ed6e6 100644
--- a/src/Middleware/ResponseCaching/src/ResponseCachingKeyProvider.cs
+++ b/src/Middleware/ResponseCaching/src/ResponseCachingKeyProvider.cs
@@ -15,7 +15,7 @@ internal sealed class ResponseCachingKeyProvider : IResponseCachingKeyProvider
     private const char KeyDelimiter = '\x1e';
     // Use the unit separator for delimiting subcomponents of the cache key to avoid possible collisions
     private const char KeySubDelimiter = '\x1f';
-    // Use the group separator for delimiting a name from its value to avoid possible collisions.
+    // Use the group separator for delimiting a name from its value and representing empty values to avoid possible collisions.
     // A literal '=' cannot be used because it can legitimately appear in decoded header/query names and values.
     private const char KeyNameValueDelimiter = '\x1d';
 
@@ -130,8 +130,7 @@ public string CreateStorageVaryByKey(ResponseCachingContext context)
                             builder.Append(KeySubDelimiter);
                         }
 
-                        ThrowIfContainsDelimiters(headerValuesArray[j]);
-                        builder.Append(headerValuesArray[j]);
+                        AppendValue(builder, headerValuesArray[j]);
                     }
                 }
             }
@@ -167,8 +166,7 @@ public string CreateStorageVaryByKey(ResponseCachingContext context)
                                 builder.Append(KeySubDelimiter);
                             }
 
-                            ThrowIfContainsDelimiters(queryValueArray[j]);
-                            builder.Append(queryValueArray[j]);
+                            AppendValue(builder, queryValueArray[j]);
                         }
                     }
                 }
@@ -191,8 +189,7 @@ public string CreateStorageVaryByKey(ResponseCachingContext context)
                                 builder.Append(KeySubDelimiter);
                             }
 
-                            ThrowIfContainsDelimiters(queryValueArray[j]);
-                            builder.Append(queryValueArray[j]);
+                            AppendValue(builder, queryValueArray[j]);
                         }
                     }
                 }
@@ -206,6 +203,19 @@ public string CreateStorageVaryByKey(ResponseCachingContext context)
         }
     }
 
+    private static void AppendValue(StringBuilder builder, string? value)
+    {
+        ThrowIfContainsDelimiters(value);
+        if (string.IsNullOrEmpty(value))
+        {
+            builder.Append(KeyNameValueDelimiter);
+        }
+        else
+        {
+            builder.Append(value);
+        }
+    }
+
     internal static void ThrowIfContainsDelimiters(string? value)
     {
         if (!string.IsNullOrEmpty(value) && value.ContainsAny(KeyDelimiter, KeySubDelimiter, KeyNameValueDelimiter))
diff --git a/src/Middleware/ResponseCaching/test/ResponseCachingKeyProviderTests.cs b/src/Middleware/ResponseCaching/test/ResponseCachingKeyProviderTests.cs
index 5b677b32d1e5..837da3a991f4 100644
--- a/src/Middleware/ResponseCaching/test/ResponseCachingKeyProviderTests.cs
+++ b/src/Middleware/ResponseCaching/test/ResponseCachingKeyProviderTests.cs
@@ -139,6 +139,41 @@ public void ResponseCachingKeyProvider_CreateStorageVaryKey_HeaderValuesPreserve
             cacheKeyProvider.CreateStorageVaryByKey(context));
     }
 
+    [Fact]
+    public void ResponseCachingKeyProvider_CreateStorageVaryKey_EmptyHeaderValueDoesNotCollideWithAbsentHeader()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var absentContext = TestUtils.CreateTestContext();
+        absentContext.CachedVaryByRules = new CachedVaryByRules()
+        {
+            Headers = new string[] { "HeaderA" }
+        };
+        var emptyContext = TestUtils.CreateTestContext();
+        emptyContext.HttpContext.Request.Headers["HeaderA"] = string.Empty;
+        emptyContext.CachedVaryByRules = new CachedVaryByRules()
+        {
+            Headers = new string[] { "HeaderA" }
+        };
+
+        Assert.NotEqual(cacheKeyProvider.CreateStorageVaryByKey(absentContext), cacheKeyProvider.CreateStorageVaryByKey(emptyContext));
+    }
+
+    [Fact]
+    public void ResponseCachingKeyProvider_CreateStorageVaryKey_EncodesEmptyHeaderValueInSequence()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.Headers["HeaderA"] = string.Empty;
+        context.HttpContext.Request.Headers.Append("HeaderA", "ValueA");
+        context.CachedVaryByRules = new CachedVaryByRules()
+        {
+            Headers = new string[] { "HeaderA" }
+        };
+
+        Assert.Equal($"{context.CachedVaryByRules.VaryByKeyPrefix}{KeyDelimiter}H{KeyDelimiter}HeaderA{KeyNameValueDelimiter}{KeyNameValueDelimiter}{KeySubDelimiter}ValueA",
+            cacheKeyProvider.CreateStorageVaryByKey(context));
+    }
+
     [Fact]
     public void ResponseCachingKeyProvider_CreateStorageVaryKey_IncludesListedQueryKeysOnly()
     {
@@ -225,6 +260,57 @@ public void ResponseCachingKeyProvider_CreateStorageVaryKey_QueryKeysValuesPrese
             cacheKeyProvider.CreateStorageVaryByKey(context));
     }
 
+    [Fact]
+    public void ResponseCachingKeyProvider_CreateStorageVaryKey_EmptyQueryValueDoesNotCollideWithAbsentQuery()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var absentContext = TestUtils.CreateTestContext();
+        absentContext.CachedVaryByRules = new CachedVaryByRules()
+        {
+            QueryKeys = new string[] { "QueryA" }
+        };
+        var emptyContext = TestUtils.CreateTestContext();
+        emptyContext.HttpContext.Request.QueryString = new QueryString("?QueryA=");
+        emptyContext.CachedVaryByRules = new CachedVaryByRules()
+        {
+            QueryKeys = new string[] { "QueryA" }
+        };
+
+        Assert.NotEqual(cacheKeyProvider.CreateStorageVaryByKey(absentContext), cacheKeyProvider.CreateStorageVaryByKey(emptyContext));
+    }
+
+    [Fact]
+    public void ResponseCachingKeyProvider_CreateStorageVaryKey_EncodesEmptyExplicitQueryValueInSequence()
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.QueryString = new QueryString("?QueryA=&QueryA=ValueA");
+        context.CachedVaryByRules = new CachedVaryByRules()
+        {
+            QueryKeys = new string[] { "QueryA" }
+        };
+
+        Assert.Equal($"{context.CachedVaryByRules.VaryByKeyPrefix}{KeyDelimiter}Q{KeyDelimiter}QueryA{KeyNameValueDelimiter}{KeyNameValueDelimiter}{KeySubDelimiter}ValueA",
+            cacheKeyProvider.CreateStorageVaryByKey(context));
+    }
+
+    [Theory]
+    [InlineData("?QueryA=", "\u001d")]
+    [InlineData("?QueryA=&QueryA=ValueA", "\u001d\u001fValueA")]
+    public void ResponseCachingKeyProvider_CreateStorageVaryKey_EncodesEmptyWildcardQueryValues(string queryString, string expectedValues)
+    {
+        var cacheKeyProvider = TestUtils.CreateTestKeyProvider();
+        var context = TestUtils.CreateTestContext();
+        context.HttpContext.Request.QueryString = new QueryString(queryString);
+        context.CachedVaryByRules = new CachedVaryByRules()
+        {
+            QueryKeys = new string[] { "*" }
+        };
+
+        Assert.Equal($"{context.CachedVaryByRules.VaryByKeyPrefix}{KeyDelimiter}Q{KeyDelimiter}QUERYA{KeyNameValueDelimiter}{expectedValues}",
+            cacheKeyProvider.CreateStorageVaryByKey(context));
+    }
+
     [Fact]
     public void ResponseCachingKeyProvider_CreateStorageVaryByKey_SelectedHeaderValues_DoesNotMutateRequestHeaderValueOrder()
     {
QODO_BENCH_DIFF_END
