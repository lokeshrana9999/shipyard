#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/aspnetcore/pull/10 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/src/Caching/SqlServer/src/SqlServerCacheOptions.cs b/src/Caching/SqlServer/src/SqlServerCacheOptions.cs
index 6885696027cf..8ec41a458932 100644
--- a/src/Caching/SqlServer/src/SqlServerCacheOptions.cs
+++ b/src/Caching/SqlServer/src/SqlServerCacheOptions.cs
@@ -8,39 +8,44 @@
 namespace Microsoft.Extensions.Caching.SqlServer;
 
 /// <summary>
-/// Configuration options for <see cref="SqlServerCache"/>.
+/// Represents configuration options for <see cref="SqlServerCache"/>.
 /// </summary>
 public class SqlServerCacheOptions : IOptions<SqlServerCacheOptions>
 {
     /// <summary>
-    /// An abstraction to represent the clock of a machine in order to enable unit testing.
+    /// Gets or sets an abstraction to represent the clock of a machine in order to enable unit testing.
     /// </summary>
     public ISystemClock SystemClock { get; set; } = new SystemClock();
 
     /// <summary>
-    /// The periodic interval to scan and delete expired items in the cache. Default is 30 minutes.
+    /// Gets or sets the periodic interval to scan and delete expired items in the cache. Default is 30 minutes.
     /// </summary>
+    /// <value>
+    /// The periodic interval to scan and delete expired items in the cache. The default is 30 minutes.
+    /// </value>
     public TimeSpan? ExpiredItemsDeletionInterval { get; set; }
 
     /// <summary>
-    /// The connection string to the database.
+    /// Gets or sets the connection string to the database.
     /// </summary>
     public string? ConnectionString { get; set; }
 
     /// <summary>
-    /// The schema name of the table.
+    /// Gets or sets the schema name of the table.
     /// </summary>
     public string? SchemaName { get; set; }
 
     /// <summary>
-    /// Name of the table where the cache items are stored.
+    /// Gets or sets the name of the table where the cache items are stored.
     /// </summary>
     public string? TableName { get; set; }
 
     /// <summary>
-    /// The default sliding expiration set for a cache entry if neither Absolute or SlidingExpiration has been set explicitly.
-    /// By default, its 20 minutes.
+    /// Gets or sets the default sliding expiration set for a cache entry if neither Absolute or SlidingExpiration has been set explicitly.
     /// </summary>
+    /// <value>
+    /// The default is 20 minutes.
+    /// </value>
     public TimeSpan DefaultSlidingExpiration { get; set; } = TimeSpan.FromMinutes(20);
 
     SqlServerCacheOptions IOptions<SqlServerCacheOptions>.Value
diff --git a/src/HttpClientFactory/Polly/src/DependencyInjection/PollyHttpClientBuilderExtensions.cs b/src/HttpClientFactory/Polly/src/DependencyInjection/PollyHttpClientBuilderExtensions.cs
index 777412480336..019813bead09 100644
--- a/src/HttpClientFactory/Polly/src/DependencyInjection/PollyHttpClientBuilderExtensions.cs
+++ b/src/HttpClientFactory/Polly/src/DependencyInjection/PollyHttpClientBuilderExtensions.cs
@@ -11,13 +11,13 @@
 namespace Microsoft.Extensions.DependencyInjection;
 
 /// <summary>
-/// Extensions methods for configuring <see cref="PolicyHttpMessageHandler"/> message handlers as part of
+/// Provides extensions methods for configuring <see cref="PolicyHttpMessageHandler"/> message handlers as part of
 /// and <see cref="HttpClient"/> message handler pipeline.
 /// </summary>
 public static class PollyHttpClientBuilderExtensions
 {
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with the provided
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with the provided
     /// <see cref="IAsyncPolicy{HttpResponseMessage}"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
@@ -45,7 +45,7 @@ public static IHttpClientBuilder AddPolicyHandler(this IHttpClientBuilder builde
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a policy returned
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a policy returned
     /// by the <paramref name="policySelector"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
@@ -77,7 +77,7 @@ public static IHttpClientBuilder AddPolicyHandler(
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a policy returned
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a policy returned
     /// by the <paramref name="policySelector"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
@@ -112,7 +112,7 @@ public static IHttpClientBuilder AddPolicyHandler(
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a policy returned
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a policy returned
     /// by the <see cref="IReadOnlyPolicyRegistry{String}"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
@@ -149,7 +149,7 @@ public static IHttpClientBuilder AddPolicyHandlerFromRegistry(this IHttpClientBu
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a policy returned
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a policy returned
     /// by the <see cref="IReadOnlyPolicyRegistry{String}"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
@@ -185,7 +185,7 @@ public static IHttpClientBuilder AddPolicyHandlerFromRegistry(
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a <see cref="Policy"/>
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a <see cref="Policy"/>
     /// created by executing the provided configuration delegate. The policy builder will be preconfigured to trigger
     /// application of the policy for requests that fail with conditions that indicate a transient failure.
     /// </summary>
@@ -207,8 +207,8 @@ public static IHttpClientBuilder AddPolicyHandlerFromRegistry(
     /// </para>
     /// <para>
     /// The policy created by <paramref name="configurePolicy"/> will be cached indefinitely per named client. Policies
-    /// are generally designed to act as singletons, and can be shared when appropriate. To share a policy across multiple
-    /// named clients, first create the policy and then pass it to multiple calls to 
+    /// are generally designed to act as singletons and can be shared when appropriate. To share a policy across multiple
+    /// named clients, first create the policy and then pass it to multiple calls to
     /// <see cref="AddPolicyHandler(IHttpClientBuilder, IAsyncPolicy{HttpResponseMessage})"/> as desired.
     /// </para>
     /// </remarks>
@@ -236,8 +236,8 @@ public static IHttpClientBuilder AddTransientHttpErrorPolicy(
     }
 
     /// <summary>
-    /// Adds a <see cref="PolicyHttpMessageHandler"/> which will surround request execution with a policy returned
-    /// by executing provided key selection logic <paramref name="keySelector"/> and <paramref name="policyFactory"/>
+    /// Adds a <see cref="PolicyHttpMessageHandler"/> that will surround request execution with a policy returned
+    /// by executing provided key selection logic <paramref name="keySelector"/> and <paramref name="policyFactory"/>.
     /// </summary>
     /// <param name="builder">The <see cref="IHttpClientBuilder"/>.</param>
     /// <param name="policyFactory">Selects an <see cref="IAsyncPolicy{HttpResponseMessage}"/> to apply to the current request based on key selection.</param>
diff --git a/src/Logging.AzureAppServices/src/AzureAppServicesLoggerFactoryExtensions.cs b/src/Logging.AzureAppServices/src/AzureAppServicesLoggerFactoryExtensions.cs
index 360bf0f0d8d8..f91731bf94cd 100644
--- a/src/Logging.AzureAppServices/src/AzureAppServicesLoggerFactoryExtensions.cs
+++ b/src/Logging.AzureAppServices/src/AzureAppServicesLoggerFactoryExtensions.cs
@@ -13,14 +13,14 @@
 namespace Microsoft.Extensions.Logging;
 
 /// <summary>
-/// Extension methods for adding Azure diagnostics logger.
+/// Provides extension methods for adding Azure diagnostics logger.
 /// </summary>
 public static class AzureAppServicesLoggerFactoryExtensions
 {
     /// <summary>
     /// Adds an Azure Web Apps diagnostics logger.
     /// </summary>
-    /// <param name="builder">The extension method argument</param>
+    /// <param name="builder">The extension method argument.</param>
     /// <returns></returns>
     public static ILoggingBuilder AddAzureWebAppDiagnostics(this ILoggingBuilder builder)
     {
diff --git a/src/Logging.AzureAppServices/src/AzureBlobLoggerContext.cs b/src/Logging.AzureAppServices/src/AzureBlobLoggerContext.cs
index a59036cdbb4d..3cb8d888ec82 100644
--- a/src/Logging.AzureAppServices/src/AzureBlobLoggerContext.cs
+++ b/src/Logging.AzureAppServices/src/AzureBlobLoggerContext.cs
@@ -6,12 +6,12 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// The context containing details for formatting the file name for the azure blob logger.
+/// Represents the context containing details for formatting the file name for the Azure blob logger.
 /// </summary>
 public readonly struct AzureBlobLoggerContext
 {
     /// <summary>
-    /// Create a new <see cref="AzureBlobLoggerContext"/>.
+    /// Creates a new <see cref="AzureBlobLoggerContext"/>.
     /// </summary>
     /// <param name="appName">The app name.</param>
     /// <param name="identifier">The file identifier.</param>
@@ -24,17 +24,17 @@ public AzureBlobLoggerContext(string appName, string identifier, DateTimeOffset
     }
 
     /// <summary>
-    /// The name of the application.
+    /// Gets the name of the application.
     /// </summary>
     public string AppName { get; }
 
     /// <summary>
-    /// The identifier for the log. This value is set to "<see cref="AzureBlobLoggerOptions.ApplicationInstanceId"/>_<see cref="AzureBlobLoggerOptions.BlobName"/>".
+    /// Gets the identifier for the log. This value is set to "<see cref="AzureBlobLoggerOptions.ApplicationInstanceId"/>_<see cref="AzureBlobLoggerOptions.BlobName"/>".
     /// </summary>
     public string Identifier { get; }
 
     /// <summary>
-    /// The timestamp representing when the log was created.
+    /// Gets the timestamp representing when the log was created.
     /// </summary>
     public DateTimeOffset Timestamp { get; }
 }
diff --git a/src/Logging.AzureAppServices/src/AzureBlobLoggerOptions.cs b/src/Logging.AzureAppServices/src/AzureBlobLoggerOptions.cs
index c42bb4bfc17f..767cac7f7e59 100644
--- a/src/Logging.AzureAppServices/src/AzureBlobLoggerOptions.cs
+++ b/src/Logging.AzureAppServices/src/AzureBlobLoggerOptions.cs
@@ -7,7 +7,7 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// Options for Azure diagnostics blob logging.
+/// Specifies options for Azure diagnostics blob logging.
 /// </summary>
 public class AzureBlobLoggerOptions : BatchingLoggerOptions
 {
@@ -15,8 +15,10 @@ public class AzureBlobLoggerOptions : BatchingLoggerOptions
 
     /// <summary>
     /// Gets or sets the last section of log blob name.
-    /// Defaults to <c>"applicationLog.txt"</c>.
     /// </summary>
+    /// <value>
+    /// The last section of the log blob name. The default is <c>"applicationLog.txt"</c>.
+    /// </value>
     public string BlobName
     {
         get { return _blobName; }
@@ -29,8 +31,10 @@ public string BlobName
 
     /// <summary>
     /// Gets or sets the format of the file name.
-    /// Defaults to "AppName/Year/Month/Day/Hour/Identifier".
     /// </summary>
+    /// <value>
+    /// The format of the file name. The default is "AppName/Year/Month/Day/Hour/Identifier".
+    /// </value>
     public Func<AzureBlobLoggerContext, string> FileNameFormat { get; set; } = context =>
     {
         var timestamp = context.Timestamp;
diff --git a/src/Logging.AzureAppServices/src/AzureFileLoggerOptions.cs b/src/Logging.AzureAppServices/src/AzureFileLoggerOptions.cs
index f8beb284b335..9cbaa31677f0 100644
--- a/src/Logging.AzureAppServices/src/AzureFileLoggerOptions.cs
+++ b/src/Logging.AzureAppServices/src/AzureFileLoggerOptions.cs
@@ -7,7 +7,7 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// Options for Azure diagnostics file logging.
+/// Specifies options for Azure diagnostics file logging.
 /// </summary>
 public class AzureFileLoggerOptions : BatchingLoggerOptions
 {
@@ -16,10 +16,15 @@ public class AzureFileLoggerOptions : BatchingLoggerOptions
     private string _fileName = "diagnostics-";
 
     /// <summary>
-    /// Gets or sets a strictly positive value representing the maximum log size in bytes or null for no limit.
-    /// Once the log is full, no more messages will be appended.
-    /// Defaults to <c>10MB</c>.
+    /// Gets or sets a strictly positive value representing the maximum log size in bytes, or null for no limit.
     /// </summary>
+    /// <value>
+    /// The maximum log size in bytes, or <see langword="null" /> for no limit.
+    /// The default is 10 MB.
+    /// </value>
+    /// <remarks>
+    /// Once the log is full, no more messages are appended.
+    /// </remarks>
     public int? FileSizeLimit
     {
         get { return _fileSizeLimit; }
@@ -34,15 +39,18 @@ public int? FileSizeLimit
     }
 
     /// <summary>
-    /// Gets or sets a strictly positive value representing the maximum retained file count or null for no limit.
-    /// Defaults to <c>2</c>.
+    /// Gets or sets a strictly positive value representing the maximum retained file count.
     /// </summary>
+    /// <value>
+    /// The maximum retained file count, or <see langword="null" /> for no limit.
+    /// The default is 2.
+    /// </value>
     public int? RetainedFileCountLimit
     {
         get { return _retainedFileCountLimit; }
         set
         {
-            if (value <= 0)
+            if (value < 0)
             {
                 throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(RetainedFileCountLimit)} must be positive.");
             }
@@ -51,10 +59,13 @@ public int? RetainedFileCountLimit
     }
 
     /// <summary>
-    /// Gets or sets a string representing the prefix of the file name used to store the logging information.
-    /// The current date, in the format YYYYMMDD will be added after the given value.
-    /// Defaults to <c>diagnostics-</c>.
+    /// Gets or sets the prefix of the file name used to store the logging information.
+    /// The current date, in the format YYYYMMDD, is added after this value.
     /// </summary>
+    /// <value>
+    /// The prefix of the file name used to store the logging information.
+    /// The default is <c>diagnostics-</c>.
+    /// </value>
     public string FileName
     {
         get { return _fileName; }
diff --git a/src/Logging.AzureAppServices/src/BatchingLoggerOptions.cs b/src/Logging.AzureAppServices/src/BatchingLoggerOptions.cs
index 67d6e60f3b69..798167fcc02d 100644
--- a/src/Logging.AzureAppServices/src/BatchingLoggerOptions.cs
+++ b/src/Logging.AzureAppServices/src/BatchingLoggerOptions.cs
@@ -6,7 +6,7 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// Options for a logger which batches up log messages.
+/// Specifies options for a logger that batches log messages.
 /// </summary>
 public class BatchingLoggerOptions
 {
@@ -31,16 +31,20 @@ public TimeSpan FlushPeriod
     }
 
     /// <summary>
-    /// Gets or sets the maximum size of the background log message queue or null for no limit.
-    /// After maximum queue size is reached log event sink would start blocking.
-    /// Defaults to <c>1000</c>.
+    /// Gets or sets the maximum size of the background log message queue, or null for no limit.
     /// </summary>
+    /// <value>
+    /// The maximum size of the background log message queue, or <see langword="null" /> for no limit. The default is 1000.
+    /// </value>
+    /// <remarks>
+    /// After the maximum queue size is reached, the log event sink starts blocking.
+    /// </remarks>
     public int? BackgroundQueueSize
     {
         get { return _backgroundQueueSize; }
         set
         {
-            if (value < 0)
+            if (value <= 0)
             {
                 throw new ArgumentOutOfRangeException(nameof(value), $"{nameof(BackgroundQueueSize)} must be non-negative.");
             }
@@ -49,9 +53,11 @@ public int? BackgroundQueueSize
     }
 
     /// <summary>
-    /// Gets or sets a maximum number of events to include in a single batch or null for no limit.
+    /// Gets or sets the maximum number of events to include in a single batch.
     /// </summary>
-    /// Defaults to <c>null</c>.
+    /// <value>
+    /// The maximum number of events to include in a single batch, or <see langword="null" /> for no limit. The default is <see langword="null" />.
+    /// </value>
     public int? BatchSize
     {
         get { return _batchSize; }
@@ -66,13 +72,15 @@ public int? BatchSize
     }
 
     /// <summary>
-    /// Gets or sets value indicating if logger accepts and queues writes.
+    /// Gets or sets a value indicating whether the logger accepts and queues writes.
     /// </summary>
     public bool IsEnabled { get; set; }
 
     /// <summary>
     /// Gets or sets a value indicating whether scopes should be included in the message.
-    /// Defaults to <c>false</c>.
     /// </summary>
+    /// <value>
+    /// The default is <see langword="false" />.
+    /// </value>
     public bool IncludeScopes { get; set; }
 }
diff --git a/src/Logging.AzureAppServices/src/BatchingLoggerProvider.cs b/src/Logging.AzureAppServices/src/BatchingLoggerProvider.cs
index 40fcc93e3904..70cf516013b2 100644
--- a/src/Logging.AzureAppServices/src/BatchingLoggerProvider.cs
+++ b/src/Logging.AzureAppServices/src/BatchingLoggerProvider.cs
@@ -11,7 +11,7 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// A provider of <see cref="BatchingLogger"/> instances.
+/// Represents a provider of <see cref="BatchingLogger"/> instances.
 /// </summary>
 public abstract class BatchingLoggerProvider : ILoggerProvider, ISupportExternalScope
 {
@@ -59,7 +59,7 @@ internal BatchingLoggerProvider(IOptionsMonitor<BatchingLoggerOptions> options)
     }
 
     /// <summary>
-    /// Checks if the queue is enabled.
+    /// Gets a value that indicates whether the queue is enabled.
     /// </summary>
     public bool IsEnabled { get; private set; }
 
@@ -124,11 +124,11 @@ private async Task ProcessLogQueue()
     }
 
     /// <summary>
-    /// Wait for the given <see cref="TimeSpan"/>.
+    /// Waits for the given <see cref="TimeSpan"/>.
     /// </summary>
     /// <param name="interval">The amount of time to wait.</param>
     /// <param name="cancellationToken">A <see cref="CancellationToken"/> that can be used to cancel the delay.</param>
-    /// <returns>A <see cref="Task"/> which completes when the <paramref name="interval"/> has passed or the <paramref name="cancellationToken"/> has been canceled.</returns>
+    /// <returns>A <see cref="Task"/> that completes when the <paramref name="interval"/> has passed or the <paramref name="cancellationToken"/> has been canceled.</returns>
     protected virtual Task IntervalAsync(TimeSpan interval, CancellationToken cancellationToken)
     {
         return Task.Delay(interval, cancellationToken);
diff --git a/src/Logging.AzureAppServices/src/FileLoggerProvider.cs b/src/Logging.AzureAppServices/src/FileLoggerProvider.cs
index 8291b8520c40..25ab016b71df 100644
--- a/src/Logging.AzureAppServices/src/FileLoggerProvider.cs
+++ b/src/Logging.AzureAppServices/src/FileLoggerProvider.cs
@@ -12,7 +12,7 @@
 namespace Microsoft.Extensions.Logging.AzureAppServices;
 
 /// <summary>
-/// A <see cref="BatchingLoggerProvider"/> which writes out to a file.
+/// Represents a <see cref="BatchingLoggerProvider"/> that writes out to a file.
 /// </summary>
 [ProviderAlias("AzureAppServicesFile")]
 public class FileLoggerProvider : BatchingLoggerProvider
@@ -25,7 +25,7 @@ public class FileLoggerProvider : BatchingLoggerProvider
     /// <summary>
     /// Creates a new instance of <see cref="FileLoggerProvider"/>.
     /// </summary>
-    /// <param name="options">The options to use when creating a provider.</param>
+    /// <param name="options">The options to use when creating the provider.</param>
     [SuppressMessage("ApiDesign", "RS0022:Constructor make noninheritable base class inheritable", Justification = "Required for backwards compatibility")]
     public FileLoggerProvider(IOptionsMonitor<AzureFileLoggerOptions> options) : base(options)
     {
diff --git a/src/Validation/src/IValidatableInfoResolver.cs b/src/Validation/src/IValidatableInfoResolver.cs
index 706204ab6284..96b672647daa 100644
--- a/src/Validation/src/IValidatableInfoResolver.cs
+++ b/src/Validation/src/IValidatableInfoResolver.cs
@@ -18,16 +18,16 @@ public interface IValidatableInfoResolver
     /// </summary>
     /// <param name="type">The type to get validation information for.</param>
     /// <param name="validatableInfo">
-    /// The output parameter that will contain the validatable information if found.
+    /// When this method returns, contains the validatable information if found.
     /// </param>
-    /// <returns><see langword="true" /> if the validatable type information was found; otherwise, false.</returns>
+    /// <returns><see langword="true" /> if the validatable type information was found; otherwise, <see langword="false" />.</returns>
     bool TryGetValidatableTypeInfo(Type type, [NotNullWhen(true)] out IValidatableInfo? validatableInfo);
 
     /// <summary>
     /// Gets validation information for the specified parameter.
     /// </summary>
     /// <param name="parameterInfo">The parameter to get validation information for.</param>
-    /// <param name="validatableInfo">The output parameter that will contain the validatable information if found.</param>
-    /// <returns><see langword="true" /> if the validatable parameter information was found; otherwise, false.</returns>
+    /// <param name="validatableInfo">When this method returns, contains the validatable information if found.</param>
+    /// <returns><see langword="true" /> if the validatable parameter information was found; otherwise, <see langword="false" />.</returns>
     bool TryGetValidatableParameterInfo(ParameterInfo parameterInfo, [NotNullWhen(true)] out IValidatableInfo? validatableInfo);
 }
diff --git a/src/Validation/src/SkipValidationAttribute.cs b/src/Validation/src/SkipValidationAttribute.cs
index ddbb2f56531e..9e2e95572ffb 100644
--- a/src/Validation/src/SkipValidationAttribute.cs
+++ b/src/Validation/src/SkipValidationAttribute.cs
@@ -6,12 +6,14 @@
 namespace Microsoft.Extensions.Validation;
 
 /// <summary>
-/// Indicates that a property, parameter, or a type should not be validated.
+/// Indicates that a property, parameter, or type should not be validated.
+/// </summary>
+/// <remarks>
 /// When applied to a property, validation is skipped for that property.
 /// When applied to a parameter, validation is skipped for that parameter.
 /// When applied to a type, validation is skipped for all properties and parameters of that type.
 /// This includes skipping validation of nested properties for complex types.
-/// </summary>
+/// </remarks>
 [Experimental("ASP0029", UrlFormat = "https://aka.ms/aspnet/analyzer/{0}")]
 [AttributeUsage(AttributeTargets.Class | AttributeTargets.Property | AttributeTargets.Parameter, AllowMultiple = false, Inherited = true)]
 public sealed class SkipValidationAttribute : Attribute
diff --git a/src/Validation/src/ValidateContext.cs b/src/Validation/src/ValidateContext.cs
index 5cce279c4be9..d200e3353a92 100644
--- a/src/Validation/src/ValidateContext.cs
+++ b/src/Validation/src/ValidateContext.cs
@@ -23,7 +23,7 @@ public sealed class ValidateContext
     /// the complete set of validation scenarios.
     /// </remarks>
     /// <example>
-    /// <code>
+    /// <code language="csharp">
     /// var validationContext = new ValidationContext(objectToValidate, serviceProvider, items);
     /// var validationOptions = serviceProvider.GetService&lt;IOptions&lt;ValidationOptions&gt;&gt;()?.Value;
     /// var validateContext = new ValidateContext
@@ -37,8 +37,10 @@ public sealed class ValidateContext
 
     /// <summary>
     /// Gets or sets the prefix used to identify the current object being validated in a complex object graph.
-    /// This is used to build property paths in validation error messages (e.g., "Customer.Address.Street").
     /// </summary>
+    /// <remarks>
+    /// This prefix is used to build property paths in validation error messages (for example, "Customer.Address.Street").
+    /// </remarks>
     public string CurrentValidationPath { get; set; } = string.Empty;
 
     /// <summary>
@@ -49,15 +51,19 @@ public sealed class ValidateContext
 
     /// <summary>
     /// Gets or sets the dictionary of validation errors collected during validation.
+    /// </summary>
+    /// <remarks>
     /// Keys are property names or paths, and values are arrays of error messages.
     /// In the default implementation, this dictionary is initialized when the first error is added.
-    /// </summary>
+    /// </remarks>
     public Dictionary<string, string[]>? ValidationErrors { get; set; }
 
     /// <summary>
     /// Gets or sets the current depth in the validation hierarchy.
-    /// This is used to prevent stack overflows from circular references.
     /// </summary>
+    /// <remarks>
+    /// This value is used to prevent stack overflows from circular references.
+    /// </remarks>
     public int CurrentDepth { get; set; }
 
     /// <summary>
diff --git a/src/Validation/src/ValidationOptions.cs b/src/Validation/src/ValidationOptions.cs
index 13729b5f124a..711011fbd880 100644
--- a/src/Validation/src/ValidationOptions.cs
+++ b/src/Validation/src/ValidationOptions.cs
@@ -7,13 +7,13 @@
 namespace Microsoft.Extensions.Validation;
 
 /// <summary>
-/// Provides configuration options for the validation system.
+/// Specifies configuration options for the validation system.
 /// </summary>
 public class ValidationOptions
 {
     /// <summary>
     /// Gets the list of resolvers that provide validation metadata for types and parameters.
-    /// Resolvers are processed in order, with the first resolver providing a non-null result being used.
+    /// Resolvers are processed in order, with the first resolver that provides a non-null result being used.
     /// </summary>
     /// <remarks>
     /// Source-generated resolvers are typically inserted at the beginning of this list
@@ -24,9 +24,13 @@ public class ValidationOptions
 
     /// <summary>
     /// Gets or sets the maximum depth for validation of nested objects.
-    /// This prevents stack overflows from circular references or extremely deep object graphs.
-    /// Default value is 32.
     /// </summary>
+    /// <value>
+    /// The default is 32.
+    /// </value>
+    /// <remarks>
+    /// A maximum depth prevents stack overflows from circular references or extremely deep object graphs.
+    /// </remarks>
     public int MaxDepth { get; set; } = 32;
 
     /// <summary>
@@ -34,11 +38,12 @@ public class ValidationOptions
     /// </summary>
     /// <param name="type">The type to get validation information for.</param>
     /// <param name="validatableTypeInfo">When this method returns, contains the validation information for the specified type,
-    /// if the type was found; otherwise, null.</param>
-    /// <returns>true if validation information was found for the specified type; otherwise, false.</returns>
+    /// if the type was found; otherwise, <see langword="null" />.</param>
+    /// <returns><see langword="true" /> if validation information was found for the specified type; otherwise, <see langword="false" />.</returns>
     [Experimental("ASP0029", UrlFormat = "https://aka.ms/aspnet/analyzer/{0}")]
     public bool TryGetValidatableTypeInfo(Type type, [NotNullWhen(true)] out IValidatableInfo? validatableTypeInfo)
     {
+        validatableTypeInfo = null;
         foreach (var resolver in Resolvers)
         {
             if (resolver.TryGetValidatableTypeInfo(type, out validatableTypeInfo))
@@ -47,7 +52,6 @@ public bool TryGetValidatableTypeInfo(Type type, [NotNullWhen(true)] out IValida
             }
         }
 
-        validatableTypeInfo = null;
         return false;
     }
 
@@ -56,11 +60,10 @@ public bool TryGetValidatableTypeInfo(Type type, [NotNullWhen(true)] out IValida
     /// </summary>
     /// <param name="parameterInfo">The parameter to get validation information for.</param>
     /// <param name="validatableInfo">When this method returns, contains the validation information for the specified parameter,
-    /// if validation information was found; otherwise, null.</param>
-    /// <returns>true if validation information was found for the specified parameter; otherwise, false.</returns>
+    /// if validation information was found; otherwise, <see langword="null" />.</param>
+    /// <returns><see langword="true" /> if validation information was found for the specified parameter; otherwise, <see langword="false" />.</returns>
     [Experimental("ASP0029", UrlFormat = "https://aka.ms/aspnet/analyzer/{0}")]
-    public bool TryGetValidatableParameterInfo(ParameterInfo parameterInfo, [NotNullWhen(true)] out IValidatableInfo? validatableInfo)
-    {
+    public bool TryGetValidatableParameterInfo(ParameterInfo parameterInfo, [NotNullWhen(true)] out IValidatableInfo? validatableInfo) {
         foreach (var resolver in Resolvers)
         {
             if (resolver.TryGetValidatableParameterInfo(parameterInfo, out validatableInfo))
QODO_BENCH_DIFF_END
