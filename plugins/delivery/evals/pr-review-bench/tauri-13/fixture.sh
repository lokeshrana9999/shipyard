#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/tauri/pull/13 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/.changes/docsrs.md b/.changes/docsrs.md
deleted file mode 100644
index be7fe825cd8d..000000000000
--- a/.changes/docsrs.md
+++ /dev/null
@@ -1,9 +0,0 @@
----
-tauri: patch:bug
-tauri-build: patch:bug
-tauri-plugin: patch:bug
-tauri-runtime: patch:bug
-tauri-runtime-wry: patch:bug
----
-
-Fixed an issue that caused docs.rs builds to fail. No user facing changes.
diff --git a/.changes/macos-codesign-error-enum.md b/.changes/macos-codesign-error-enum.md
deleted file mode 100644
index f5bae6975f50..000000000000
--- a/.changes/macos-codesign-error-enum.md
+++ /dev/null
@@ -1,5 +0,0 @@
----
-tauri-macos-sign: "minor:enhance"
----
-
-**Potentially breaking change:** Export custom Error enum instead of using anyhow. The changes happened in https://github.com/tauri-apps/tauri/pull/14126.
diff --git a/Cargo.lock b/Cargo.lock
index 15b6fe5b1e34..671ddc123587 100644
--- a/Cargo.lock
+++ b/Cargo.lock
@@ -1319,7 +1319,7 @@ source = "registry+https://github.com/rust-lang/crates.io-index"
 checksum = "117725a109d387c937a1533ce01b450cbde6b88abceea8473c4d7a85853cda3c"
 dependencies = [
  "lazy_static",
- "windows-sys 0.48.0",
+ "windows-sys 0.59.0",
 ]
 
 [[package]]
@@ -4311,7 +4311,7 @@ source = "registry+https://github.com/rust-lang/crates.io-index"
 checksum = "fc2f4eb4bc735547cfed7c0a4922cbd04a4655978c09b54f1f7b228750664c34"
 dependencies = [
  "cfg-if",
- "windows-targets 0.48.5",
+ "windows-targets 0.52.6",
 ]
 
 [[package]]
@@ -8485,7 +8485,7 @@ checksum = "61c41af27dd6d1e27b1b16b489db798443478cef1f06a660c96db617ba5de3b1"
 
 [[package]]
 name = "tauri"
-version = "2.9.0"
+version = "2.9.1"
 dependencies = [
  "anyhow",
  "bytes",
@@ -8545,7 +8545,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-build"
-version = "2.5.0"
+version = "2.5.1"
 dependencies = [
  "anyhow",
  "cargo_toml",
@@ -8567,7 +8567,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-bundler"
-version = "2.7.0"
+version = "2.7.1"
 dependencies = [
  "anyhow",
  "ar",
@@ -8613,7 +8613,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-cli"
-version = "2.9.0"
+version = "2.9.1"
 dependencies = [
  "ar",
  "axum",
@@ -8772,7 +8772,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-macos-sign"
-version = "2.2.0"
+version = "2.3.0"
 dependencies = [
  "apple-codesign",
  "chrono",
@@ -8804,7 +8804,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-plugin"
-version = "2.5.0"
+version = "2.5.1"
 dependencies = [
  "anyhow",
  "glob",
@@ -8852,7 +8852,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-runtime"
-version = "2.9.0"
+version = "2.9.1"
 dependencies = [
  "cookie",
  "dpi",
@@ -8875,7 +8875,7 @@ dependencies = [
 
 [[package]]
 name = "tauri-runtime-wry"
-version = "2.9.0"
+version = "2.9.1"
 dependencies = [
  "gtk",
  "http 1.3.1",
@@ -10314,7 +10314,7 @@ version = "0.1.9"
 source = "registry+https://github.com/rust-lang/crates.io-index"
 checksum = "cf221c93e13a30d793f7645a0e7762c55d169dbb0a49671918a2319d289b10bb"
 dependencies = [
- "windows-sys 0.48.0",
+ "windows-sys 0.59.0",
 ]
 
 [[package]]
diff --git a/crates/tauri-build/CHANGELOG.md b/crates/tauri-build/CHANGELOG.md
index 05d4867d11de..95ba81d85167 100644
--- a/crates/tauri-build/CHANGELOG.md
+++ b/crates/tauri-build/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.5.1]
+
+### Bug Fixes
+
+- [`4b6b8690a`](https://www.github.com/tauri-apps/tauri/commit/4b6b8690ab886ebdf1307951cffbe03e31280baa) ([#14347](https://www.github.com/tauri-apps/tauri/pull/14347) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) Fixed an issue that caused docs.rs builds to fail. No user facing changes.
+
 ## \[2.5.0]
 
 ### New Features
diff --git a/crates/tauri-build/Cargo.toml b/crates/tauri-build/Cargo.toml
index 6bd2d68f5fc5..3f93769e1c1f 100644
--- a/crates/tauri-build/Cargo.toml
+++ b/crates/tauri-build/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-build"
-version = "2.5.0"
+version = "2.5.1"
 description = "build time code to pair with https://crates.io/crates/tauri"
 exclude = ["CHANGELOG.md", "/target"]
 readme = "README.md"
diff --git a/crates/tauri-bundler/CHANGELOG.md b/crates/tauri-bundler/CHANGELOG.md
index f07521914cc9..d986ea71408c 100644
--- a/crates/tauri-bundler/CHANGELOG.md
+++ b/crates/tauri-bundler/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.7.1]
+
+### Dependencies
+
+- Upgraded to `tauri-macos-sign@2.3.0`
+
 ## \[2.7.0]
 
 ### New Features
diff --git a/crates/tauri-bundler/Cargo.toml b/crates/tauri-bundler/Cargo.toml
index e74135518a63..c4e124d25ff2 100644
--- a/crates/tauri-bundler/Cargo.toml
+++ b/crates/tauri-bundler/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-bundler"
-version = "2.7.0"
+version = "2.7.1"
 authors = [
   "George Burton <burtonageo@gmail.com>",
   "Tauri Programme within The Commons Conservancy",
@@ -59,7 +59,7 @@ features = ["Win32_System_SystemInformation", "Win32_System_Diagnostics_Debug"]
 [target."cfg(target_os = \"macos\")".dependencies]
 icns = { package = "tauri-icns", version = "0.1" }
 time = { version = "0.3", features = ["formatting"] }
-tauri-macos-sign = { version = "2.2.0", path = "../tauri-macos-sign" }
+tauri-macos-sign = { version = "2.3.0", path = "../tauri-macos-sign" }
 
 [target."cfg(target_os = \"linux\")".dependencies]
 heck = "0.5"
diff --git a/crates/tauri-cli/CHANGELOG.md b/crates/tauri-cli/CHANGELOG.md
index 6debafbeea3e..0e9e511da5e3 100644
--- a/crates/tauri-cli/CHANGELOG.md
+++ b/crates/tauri-cli/CHANGELOG.md
@@ -1,5 +1,12 @@
 # Changelog
 
+## \[2.9.1]
+
+### Dependencies
+
+- Upgraded to `tauri-macos-sign@2.3.0`
+- Upgraded to `tauri-bundler@2.7.1`
+
 ## \[2.9.0]
 
 ### New Features
diff --git a/crates/tauri-cli/Cargo.toml b/crates/tauri-cli/Cargo.toml
index 2764488ad1f0..d7c11d0fa542 100644
--- a/crates/tauri-cli/Cargo.toml
+++ b/crates/tauri-cli/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-cli"
-version = "2.9.0"
+version = "2.9.1"
 authors = ["Tauri Programme within The Commons Conservancy"]
 edition = "2021"
 rust-version = "1.77.2"
@@ -47,7 +47,7 @@ sublime_fuzzy = "0.7"
 clap_complete = "4"
 clap = { version = "4", features = ["derive", "env"] }
 thiserror = "2"
-tauri-bundler = { version = "2.7.0", default-features = false, path = "../tauri-bundler" }
+tauri-bundler = { version = "2.7.1", default-features = false, path = "../tauri-bundler" }
 colored = "2"
 serde = { version = "1", features = ["derive"] }
 serde_json = { version = "1", features = ["preserve_order"] }
@@ -132,7 +132,7 @@ libc = "0.2"
 
 [target."cfg(target_os = \"macos\")".dependencies]
 plist = "1"
-tauri-macos-sign = { version = "2.2.0", path = "../tauri-macos-sign" }
+tauri-macos-sign = { version = "2.3.0", path = "../tauri-macos-sign" }
 object = { version = "0.36", default-features = false, features = [
   "macho",
   "read_core",
diff --git a/crates/tauri-cli/config.schema.json b/crates/tauri-cli/config.schema.json
index 672ace507f23..6f5665ce5c91 100644
--- a/crates/tauri-cli/config.schema.json
+++ b/crates/tauri-cli/config.schema.json
@@ -1,6 +1,6 @@
 {
   "$schema": "http://json-schema.org/draft-07/schema#",
-  "$id": "https://schema.tauri.app/config/2.9.0",
+  "$id": "https://schema.tauri.app/config/2.9.1",
   "title": "Config",
   "description": "The Tauri configuration object.\n It is read from a file where you can define your frontend assets,\n configure the bundler and define a tray icon.\n\n The configuration file is generated by the\n [`tauri init`](https://v2.tauri.app/reference/cli/#init) command that lives in\n your Tauri application source directory (src-tauri).\n\n Once generated, you may modify it at will to customize your Tauri application.\n\n ## File Formats\n\n By default, the configuration is defined as a JSON file named `tauri.conf.json`.\n\n Tauri also supports JSON5 and TOML files via the `config-json5` and `config-toml` Cargo features, respectively.\n The JSON5 file name must be either `tauri.conf.json` or `tauri.conf.json5`.\n The TOML file name is `Tauri.toml`.\n\n ## Platform-Specific Configuration\n\n In addition to the default configuration file, Tauri can\n read a platform-specific configuration from `tauri.linux.conf.json`,\n `tauri.windows.conf.json`, `tauri.macos.conf.json`, `tauri.android.conf.json` and `tauri.ios.conf.json`\n (or `Tauri.linux.toml`, `Tauri.windows.toml`, `Tauri.macos.toml`, `Tauri.android.toml` and `Tauri.ios.toml` if the `Tauri.toml` format is used),\n which gets merged with the main configuration object.\n\n ## Configuration Structure\n\n The configuration is composed of the following objects:\n\n - [`app`](#appconfig): The Tauri configuration\n - [`build`](#buildconfig): The build configuration\n - [`bundle`](#bundleconfig): The bundle configurations\n - [`plugins`](#pluginconfig): The plugins configuration\n\n Example tauri.config.json file:\n\n ```json\n {\n   \"productName\": \"tauri-app\",\n   \"version\": \"0.1.0\",\n   \"build\": {\n     \"beforeBuildCommand\": \"\",\n     \"beforeDevCommand\": \"\",\n     \"devUrl\": \"http://localhost:3000\",\n     \"frontendDist\": \"../dist\"\n   },\n   \"app\": {\n     \"security\": {\n       \"csp\": null\n     },\n     \"windows\": [\n       {\n         \"fullscreen\": false,\n         \"height\": 600,\n         \"resizable\": true,\n         \"title\": \"Tauri App\",\n         \"width\": 800\n       }\n     ]\n   },\n   \"bundle\": {},\n   \"plugins\": {}\n }\n ```",
   "type": "object",
diff --git a/crates/tauri-cli/metadata-v2.json b/crates/tauri-cli/metadata-v2.json
index 725d89c0708e..54e944f5a47b 100644
--- a/crates/tauri-cli/metadata-v2.json
+++ b/crates/tauri-cli/metadata-v2.json
@@ -1,9 +1,9 @@
 {
   "cli.js": {
-    "version": "2.9.0",
+    "version": "2.9.1",
     "node": ">= 10.0.0"
   },
-  "tauri": "2.9.0",
-  "tauri-build": "2.5.0",
-  "tauri-plugin": "2.5.0"
+  "tauri": "2.9.1",
+  "tauri-build": "2.5.1",
+  "tauri-plugin": "2.5.1"
 }
diff --git a/crates/tauri-macos-sign/CHANGELOG.md b/crates/tauri-macos-sign/CHANGELOG.md
index 93329f55d7c6..c45220b61276 100644
--- a/crates/tauri-macos-sign/CHANGELOG.md
+++ b/crates/tauri-macos-sign/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.3.0]
+
+### Enhancements
+
+- [`f59bf9d53`](https://www.github.com/tauri-apps/tauri/commit/f59bf9d5392ffd209e26ce5259c26d1acc31c4ba) ([#14337](https://www.github.com/tauri-apps/tauri/pull/14337) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) **Potentially breaking change:** Export custom Error enum instead of using anyhow. The changes happened in https://github.com/tauri-apps/tauri/pull/14126.
+
 ## \[2.2.0]
 
 ### New Features
diff --git a/crates/tauri-macos-sign/Cargo.toml b/crates/tauri-macos-sign/Cargo.toml
index 37e787cd4c23..77984f71b92f 100644
--- a/crates/tauri-macos-sign/Cargo.toml
+++ b/crates/tauri-macos-sign/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-macos-sign"
-version = "2.2.0"
+version = "2.3.0"
 authors = ["Tauri Programme within The Commons Conservancy"]
 license = "Apache-2.0 OR MIT"
 keywords = ["codesign", "signing", "macos", "ios", "tauri"]
diff --git a/crates/tauri-macos-sign/src/lib.rs b/crates/tauri-macos-sign/src/lib.rs
index 64a9c3d57241..0c027502bd1c 100644
--- a/crates/tauri-macos-sign/src/lib.rs
+++ b/crates/tauri-macos-sign/src/lib.rs
@@ -17,59 +17,78 @@ mod provisioning_profile;
 pub use keychain::{Keychain, Team};
 pub use provisioning_profile::ProvisioningProfile;
 
-#[derive(Debug, thiserror::Error)]
+#[derive(Debug)]
 pub enum Error {
-  #[error("failed to create temp directory: {0}")]
   TempDir(std::io::Error),
-  #[error("failed to resolve home dir")]
   ResolveHomeDir,
-  #[error("failed to resolve signing identity")]
   ResolveSigningIdentity,
-  #[error("failed to decode provisioning profile")]
   FailedToDecodeProvisioningProfile,
-  #[error("could not find provisioning profile UUID")]
   FailedToFindProvisioningProfileUuid,
-  #[error("{context} {path}: {error}")]
   Plist {
     context: &'static str,
     path: PathBuf,
     error: plist::Error,
   },
-  #[error("failed to upload app to Apple's notarization servers: {error}")]
   FailedToUploadApp { error: std::io::Error },
-  #[error("failed to notarize app: {0}")]
   Notarize(String),
-  #[error("failed to parse notarytool output as JSON: {output}")]
   ParseNotarytoolOutput { output: String },
-  #[error("failed to run command {command}: {error}")]
   CommandFailed {
     command: String,
     error: std::io::Error,
   },
-  #[error("{context} {path}: {error}")]
   Fs {
     context: &'static str,
     path: PathBuf,
     error: std::io::Error,
   },
-  #[error("failed to parse X509 certificate: {error}")]
   X509Certificate {
     error: x509_certificate::X509CertificateError,
   },
-  #[error("failed to create PFX from self signed certificate")]
   FailedToCreatePFX,
-  #[error("failed to create self signed certificate: {error}")]
   FailedToCreateSelfSignedCertificate {
     error: Box<apple_codesign::AppleCodesignError>,
   },
-  #[error("failed to encode DER: {error}")]
   FailedToEncodeDER { error: std::io::Error },
-  #[error("certificate missing common name")]
   CertificateMissingCommonName,
-  #[error("certificate missing organization unit for common name {common_name}")]
   CertificateMissingOrganizationUnit { common_name: String },
 }
 
+impl std::fmt::Display for Error {
+  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
+    match self {
+      Error::TempDir(e) => write!(f, "failed to create temp directory: {}", e),
+      Error::ResolveHomeDir => write!(f, "failed to resolve home dir"),
+      Error::ResolveSigningIdentity => write!(f, "failed to resolve signing identity"),
+      Error::FailedToDecodeProvisioningProfile => write!(f, "failed to decode provisioning profile"),
+      Error::FailedToFindProvisioningProfileUuid => write!(f, "could not find provisioning profile UUID"),
+      Error::Plist { context, path, error } => write!(f, "{} {}: {}", context, path.display(), error),
+      Error::FailedToUploadApp { error } => write!(f, "failed to upload app to Apple's notarization servers: {}", error),
+      Error::Notarize(msg) => write!(f, "failed to notarize app: {}", msg),
+      Error::ParseNotarytoolOutput { output } => write!(f, "failed to parse notarytool output as JSON: {}", output),
+      Error::CommandFailed { command, error } => write!(f, "failed to run command {}: {}", command, error),
+      Error::Fs { context, path, error } => write!(f, "{} {}: {}", context, path.display(), error),
+      Error::X509Certificate { error } => write!(f, "failed to parse X509 certificate: {}", error),
+      Error::FailedToCreatePFX => write!(f, "failed to create PFX from self signed certificate"),
+      Error::FailedToCreateSelfSignedCertificate { error } => write!(f, "failed to create self signed certificate: {}", error),
+      Error::FailedToEncodeDER { error } => write!(f, "failed to encode DER: {}", error),
+      Error::CertificateMissingCommonName => write!(f, "certificate missing common name"),
+      Error::CertificateMissingOrganizationUnit { common_name } => write!(f, "certificate missing organization unit for common name {}", common_name),
+    }
+  }
+}
+
+impl std::error::Error for Error {
+  fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
+    match self {
+      Error::TempDir(e) => Some(e),
+      Error::FailedToUploadApp { error } => Some(error),
+      Error::CommandFailed { error, .. } => Some(error),
+      Error::Fs { error, .. } => Some(error),
+      _ => None,
+    }
+  }
+}
+
 pub type Result<T> = std::result::Result<T, Error>;
 
 trait CommandExt {
@@ -151,12 +170,12 @@ fn notarize_inner(
     "-k",
     "--keepParent",
     "--sequesterRsrc",
-    app_bundle_path
-      .to_str()
-      .expect("failed to convert bundle_path to string"),
     zip_path
       .to_str()
       .expect("failed to convert zip_path to string"),
+    app_bundle_path
+      .to_str()
+      .expect("failed to convert bundle_path to string"),
   ];
 
   // use ditto to create a PKZip almost identical to Finder
@@ -211,7 +230,7 @@ fn notarize_inner(
       submit_output.message
     );
     // status is empty when not waiting for the notarization to finish
-    if submit_output.status.map_or(!wait, |s| s == "Accepted") {
+    if submit_output.status.map_or(wait, |s| s == "Accepted") {
       println!("Notarizing {log_message}");
 
       if wait {
diff --git a/crates/tauri-plugin/CHANGELOG.md b/crates/tauri-plugin/CHANGELOG.md
index eacb6a9c5a10..104093af20b8 100644
--- a/crates/tauri-plugin/CHANGELOG.md
+++ b/crates/tauri-plugin/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.5.1]
+
+### Bug Fixes
+
+- [`4b6b8690a`](https://www.github.com/tauri-apps/tauri/commit/4b6b8690ab886ebdf1307951cffbe03e31280baa) ([#14347](https://www.github.com/tauri-apps/tauri/pull/14347) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) Fixed an issue that caused docs.rs builds to fail. No user facing changes.
+
 ## \[2.5.0]
 
 ### Dependencies
diff --git a/crates/tauri-plugin/Cargo.toml b/crates/tauri-plugin/Cargo.toml
index f6dac8c6581c..971d8c50f33d 100644
--- a/crates/tauri-plugin/Cargo.toml
+++ b/crates/tauri-plugin/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-plugin"
-version = "2.5.0"
+version = "2.5.1"
 description = "Build script and runtime Tauri plugin definitions"
 authors.workspace = true
 homepage.workspace = true
diff --git a/crates/tauri-runtime-wry/CHANGELOG.md b/crates/tauri-runtime-wry/CHANGELOG.md
index 014fab581c75..d9ac4f1d18e4 100644
--- a/crates/tauri-runtime-wry/CHANGELOG.md
+++ b/crates/tauri-runtime-wry/CHANGELOG.md
@@ -1,5 +1,15 @@
 # Changelog
 
+## \[2.9.1]
+
+### Bug Fixes
+
+- [`4b6b8690a`](https://www.github.com/tauri-apps/tauri/commit/4b6b8690ab886ebdf1307951cffbe03e31280baa) ([#14347](https://www.github.com/tauri-apps/tauri/pull/14347) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) Fixed an issue that caused docs.rs builds to fail. No user facing changes.
+
+### Dependencies
+
+- Upgraded to `tauri-runtime@2.9.1`
+
 ## \[2.9.0]
 
 ### New Features
diff --git a/crates/tauri-runtime-wry/Cargo.toml b/crates/tauri-runtime-wry/Cargo.toml
index ddade7b7763a..e247f37937b8 100644
--- a/crates/tauri-runtime-wry/Cargo.toml
+++ b/crates/tauri-runtime-wry/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-runtime-wry"
-version = "2.9.0"
+version = "2.9.1"
 description = "Wry bindings to the Tauri runtime"
 exclude = ["CHANGELOG.md", "/target"]
 readme = "README.md"
@@ -20,7 +20,7 @@ wry = { version = "0.53.4", default-features = false, features = [
   "linux-body",
 ] }
 tao = { version = "0.34.5", default-features = false, features = ["rwh_06"] }
-tauri-runtime = { version = "2.9.0", path = "../tauri-runtime" }
+tauri-runtime = { version = "2.9.1", path = "../tauri-runtime" }
 tauri-utils = { version = "2.8.0", path = "../tauri-utils" }
 raw-window-handle = "0.6"
 http = "1"
diff --git a/crates/tauri-runtime/CHANGELOG.md b/crates/tauri-runtime/CHANGELOG.md
index 333c6d00590b..edf7e1a03044 100644
--- a/crates/tauri-runtime/CHANGELOG.md
+++ b/crates/tauri-runtime/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.9.1]
+
+### Bug Fixes
+
+- [`4b6b8690a`](https://www.github.com/tauri-apps/tauri/commit/4b6b8690ab886ebdf1307951cffbe03e31280baa) ([#14347](https://www.github.com/tauri-apps/tauri/pull/14347) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) Fixed an issue that caused docs.rs builds to fail. No user facing changes.
+
 ## \[2.9.0]
 
 ### New Features
diff --git a/crates/tauri-runtime/Cargo.toml b/crates/tauri-runtime/Cargo.toml
index 14e58799a6f2..b269b8d329a0 100644
--- a/crates/tauri-runtime/Cargo.toml
+++ b/crates/tauri-runtime/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri-runtime"
-version = "2.9.0"
+version = "2.9.1"
 description = "Runtime for Tauri applications"
 exclude = ["CHANGELOG.md", "/target"]
 readme = "README.md"
diff --git a/crates/tauri-schema-generator/schemas/config.schema.json b/crates/tauri-schema-generator/schemas/config.schema.json
index 672ace507f23..6f5665ce5c91 100644
--- a/crates/tauri-schema-generator/schemas/config.schema.json
+++ b/crates/tauri-schema-generator/schemas/config.schema.json
@@ -1,6 +1,6 @@
 {
   "$schema": "http://json-schema.org/draft-07/schema#",
-  "$id": "https://schema.tauri.app/config/2.9.0",
+  "$id": "https://schema.tauri.app/config/2.9.1",
   "title": "Config",
   "description": "The Tauri configuration object.\n It is read from a file where you can define your frontend assets,\n configure the bundler and define a tray icon.\n\n The configuration file is generated by the\n [`tauri init`](https://v2.tauri.app/reference/cli/#init) command that lives in\n your Tauri application source directory (src-tauri).\n\n Once generated, you may modify it at will to customize your Tauri application.\n\n ## File Formats\n\n By default, the configuration is defined as a JSON file named `tauri.conf.json`.\n\n Tauri also supports JSON5 and TOML files via the `config-json5` and `config-toml` Cargo features, respectively.\n The JSON5 file name must be either `tauri.conf.json` or `tauri.conf.json5`.\n The TOML file name is `Tauri.toml`.\n\n ## Platform-Specific Configuration\n\n In addition to the default configuration file, Tauri can\n read a platform-specific configuration from `tauri.linux.conf.json`,\n `tauri.windows.conf.json`, `tauri.macos.conf.json`, `tauri.android.conf.json` and `tauri.ios.conf.json`\n (or `Tauri.linux.toml`, `Tauri.windows.toml`, `Tauri.macos.toml`, `Tauri.android.toml` and `Tauri.ios.toml` if the `Tauri.toml` format is used),\n which gets merged with the main configuration object.\n\n ## Configuration Structure\n\n The configuration is composed of the following objects:\n\n - [`app`](#appconfig): The Tauri configuration\n - [`build`](#buildconfig): The build configuration\n - [`bundle`](#bundleconfig): The bundle configurations\n - [`plugins`](#pluginconfig): The plugins configuration\n\n Example tauri.config.json file:\n\n ```json\n {\n   \"productName\": \"tauri-app\",\n   \"version\": \"0.1.0\",\n   \"build\": {\n     \"beforeBuildCommand\": \"\",\n     \"beforeDevCommand\": \"\",\n     \"devUrl\": \"http://localhost:3000\",\n     \"frontendDist\": \"../dist\"\n   },\n   \"app\": {\n     \"security\": {\n       \"csp\": null\n     },\n     \"windows\": [\n       {\n         \"fullscreen\": false,\n         \"height\": 600,\n         \"resizable\": true,\n         \"title\": \"Tauri App\",\n         \"width\": 800\n       }\n     ]\n   },\n   \"bundle\": {},\n   \"plugins\": {}\n }\n ```",
   "type": "object",
diff --git a/crates/tauri/CHANGELOG.md b/crates/tauri/CHANGELOG.md
index 8b60c5c7b091..164368723b6a 100644
--- a/crates/tauri/CHANGELOG.md
+++ b/crates/tauri/CHANGELOG.md
@@ -1,5 +1,17 @@
 # Changelog
 
+## \[2.9.1]
+
+### Bug Fixes
+
+- [`4b6b8690a`](https://www.github.com/tauri-apps/tauri/commit/4b6b8690ab886ebdf1307951cffbe03e31280baa) ([#14347](https://www.github.com/tauri-apps/tauri/pull/14347) by [@FabianLars](https://www.github.com/tauri-apps/tauri/../../FabianLars)) Fixed an issue that caused docs.rs builds to fail. No user facing changes.
+
+### Dependencies
+
+- Upgraded to `tauri-build@2.5.1`
+- Upgraded to `tauri-runtime@2.9.1`
+- Upgraded to `tauri-runtime-wry@2.9.1`
+
 ## \[2.9.0]
 
 ### New Features
diff --git a/crates/tauri/Cargo.toml b/crates/tauri/Cargo.toml
index 46a4ee7225a1..ce6907580e00 100644
--- a/crates/tauri/Cargo.toml
+++ b/crates/tauri/Cargo.toml
@@ -1,6 +1,6 @@
 [package]
 name = "tauri"
-version = "2.9.0"
+version = "2.9.1"
 description = "Make tiny, secure apps for all desktop platforms with Tauri"
 exclude = ["/test", "/.scripts", "CHANGELOG.md", "/target"]
 readme = "README.md"
@@ -54,12 +54,12 @@ uuid = { version = "1", features = ["v4"], optional = true }
 url = "2"
 anyhow = "1"
 thiserror = "2"
-tauri-runtime = { version = "2.9.0", path = "../tauri-runtime" }
+tauri-runtime = { version = "2.9.1", path = "../tauri-runtime" }
 tauri-macros = { version = "2.5.0", path = "../tauri-macros" }
 tauri-utils = { version = "2.8.0", features = [
   "resources",
 ], path = "../tauri-utils" }
-tauri-runtime-wry = { version = "2.9.0", path = "../tauri-runtime-wry", default-features = false, optional = true }
+tauri-runtime-wry = { version = "2.9.1", path = "../tauri-runtime-wry", default-features = false, optional = true }
 getrandom = "0.3"
 serde_repr = "0.1"
 http = "1"
@@ -161,7 +161,7 @@ objc2-ui-kit = { version = "0.3.0", default-features = false, features = [
 [build-dependencies]
 glob = "0.3"
 heck = "0.5"
-tauri-build = { path = "../tauri-build/", default-features = false, version = "2.5.0" }
+tauri-build = { path = "../tauri-build/", default-features = false, version = "2.5.1" }
 tauri-utils = { path = "../tauri-utils/", version = "2.8.0", features = [
   "build",
 ] }
diff --git a/packages/cli/CHANGELOG.md b/packages/cli/CHANGELOG.md
index c7b9f0ac2e25..fd4add94a5c3 100644
--- a/packages/cli/CHANGELOG.md
+++ b/packages/cli/CHANGELOG.md
@@ -1,5 +1,11 @@
 # Changelog
 
+## \[2.9.1]
+
+### Dependencies
+
+- Upgraded to `tauri-cli@2.9.1`
+
 ## \[2.9.0]
 
 ### New Features
diff --git a/packages/cli/package.json b/packages/cli/package.json
index f0fc53ed5a50..97e8bba16185 100644
--- a/packages/cli/package.json
+++ b/packages/cli/package.json
@@ -1,6 +1,6 @@
 {
   "name": "@tauri-apps/cli",
-  "version": "2.9.0",
+  "version": "2.9.1",
   "description": "Command line interface for building Tauri apps",
   "type": "commonjs",
   "funding": {
QODO_BENCH_DIFF_END
