#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/tauri/pull/4 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/Cargo.lock b/Cargo.lock
index 07477e279524..cf21f5252fb3 100644
--- a/Cargo.lock
+++ b/Cargo.lock
@@ -2365,11 +2365,12 @@ checksum = "5443807d6dff69373d433ab9ef5378ad8df50ca6298caf15de6e52e24aaf54d5"
 
 [[package]]
 name = "erased-serde"
-version = "0.4.5"
+version = "0.4.9"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "24e2389d65ab4fab27dc2a5de7b191e1f6617d1f1c8855c0dc569c94a4cbb18d"
+checksum = "89e8918065695684b2b0702da20382d5ae6065cf3327bc2d6436bd49a71ce9f3"
 dependencies = [
  "serde",
+ "serde_core",
  "typeid",
 ]
 
@@ -3976,20 +3977,6 @@ dependencies = [
  "system-deps",
 ]
 
-[[package]]
-name = "jni"
-version = "0.19.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "c6df18c2e3db7e453d3c6ac5b3e9d5182664d28788126d39b91f2d1e22b017ec"
-dependencies = [
- "cesu8",
- "combine",
- "jni-sys",
- "log",
- "thiserror 1.0.69",
- "walkdir",
-]
-
 [[package]]
 name = "jni"
 version = "0.21.1"
@@ -4200,7 +4187,6 @@ dependencies = [
  "referencing",
  "regex",
  "regex-syntax",
- "reqwest 0.12.12",
  "serde",
  "serde_json",
  "uuid-simd",
@@ -4488,9 +4474,9 @@ checksum = "9374ef4228402d4b7e403e5838cb880d9ee663314b0a900d5a6aabf0c213552e"
 
 [[package]]
 name = "log"
-version = "0.4.22"
+version = "0.4.29"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "a7a70ba024b9dc04c27ea2f0c0548feb474ec5c54bba33a7f72f873a39d07b24"
+checksum = "5e5032e24019045c762d3c0f28f5b6b8bbf38563a65908389bf7978758920897"
 dependencies = [
  "value-bag",
 ]
@@ -6883,43 +6869,6 @@ dependencies = [
  "winreg 0.50.0",
 ]
 
-[[package]]
-name = "reqwest"
-version = "0.12.12"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "43e734407157c3c2034e0258f5e4473ddb361b1e85f95a66690d67264d7cd1da"
-dependencies = [
- "base64 0.22.1",
- "bytes",
- "futures-channel",
- "futures-core",
- "futures-util",
- "http 1.3.1",
- "http-body 1.0.1",
- "http-body-util",
- "hyper 1.8.1",
- "hyper-util",
- "ipnet",
- "js-sys",
- "log",
- "mime",
- "once_cell",
- "percent-encoding",
- "pin-project-lite",
- "serde",
- "serde_json",
- "serde_urlencoded",
- "sync_wrapper 1.0.2",
- "tokio",
- "tower 0.5.2",
- "tower-service",
- "url",
- "wasm-bindgen",
- "wasm-bindgen-futures",
- "web-sys",
- "windows-registry 0.2.0",
-]
-
 [[package]]
 name = "reqwest"
 version = "0.13.1"
@@ -6945,7 +6894,7 @@ dependencies = [
  "quinn",
  "rustls 0.23.35",
  "rustls-pki-types",
- "rustls-platform-verifier 0.6.2",
+ "rustls-platform-verifier",
  "serde",
  "serde_json",
  "sync_wrapper 1.0.2",
@@ -7345,27 +7294,6 @@ dependencies = [
  "zeroize",
 ]
 
-[[package]]
-name = "rustls-platform-verifier"
-version = "0.3.4"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "afbb878bdfdf63a336a5e63561b1835e7a8c91524f51621db870169eac84b490"
-dependencies = [
- "core-foundation 0.9.4",
- "core-foundation-sys",
- "jni 0.19.0",
- "log",
- "once_cell",
- "rustls 0.23.35",
- "rustls-native-certs 0.7.3",
- "rustls-platform-verifier-android",
- "rustls-webpki 0.102.8",
- "security-framework 2.11.1",
- "security-framework-sys",
- "webpki-roots 0.26.7",
- "winapi",
-]
-
 [[package]]
 name = "rustls-platform-verifier"
 version = "0.6.2"
@@ -7374,7 +7302,7 @@ checksum = "1d99feebc72bae7ab76ba994bb5e121b8d83d910ca40b36e0921f53becc41784"
 dependencies = [
  "core-foundation 0.10.0",
  "core-foundation-sys",
- "jni 0.21.1",
+ "jni",
  "log",
  "once_cell",
  "rustls 0.23.35",
@@ -7383,7 +7311,7 @@ dependencies = [
  "rustls-webpki 0.103.8",
  "security-framework 3.5.1",
  "security-framework-sys",
- "webpki-root-certs 1.0.5",
+ "webpki-root-certs",
  "windows-sys 0.60.2",
 ]
 
@@ -7624,7 +7552,6 @@ dependencies = [
  "core-foundation 0.9.4",
  "core-foundation-sys",
  "libc",
- "num-bigint",
  "security-framework-sys",
 ]
 
@@ -8614,7 +8541,7 @@ dependencies = [
  "gdkwayland-sys",
  "gdkx11-sys",
  "gtk",
- "jni 0.21.1",
+ "jni",
  "lazy_static",
  "libc",
  "log",
@@ -8690,7 +8617,7 @@ dependencies = [
  "http 1.3.1",
  "http-range",
  "image",
- "jni 0.21.1",
+ "jni",
  "libc",
  "log",
  "mime",
@@ -8794,7 +8721,7 @@ dependencies = [
  "uuid",
  "walkdir",
  "which",
- "windows-registry 0.5.0",
+ "windows-registry",
  "windows-sys 0.60.2",
  "zip 4.0.0",
 ]
@@ -9047,7 +8974,7 @@ dependencies = [
  "dpi",
  "gtk",
  "http 1.3.1",
- "jni 0.21.1",
+ "jni",
  "objc2 0.6.0",
  "objc2-ui-kit",
  "objc2-web-kit",
@@ -9068,7 +8995,7 @@ version = "2.9.3"
 dependencies = [
  "gtk",
  "http 1.3.1",
- "jni 0.21.1",
+ "jni",
  "log",
  "objc2 0.6.0",
  "objc2-app-kit",
@@ -9976,33 +9903,31 @@ checksum = "8ecb6da28b8a351d773b68d5825ac39017e680750f980f3a1a85cd8dd28a47c1"
 
 [[package]]
 name = "ureq"
-version = "3.0.3"
+version = "3.1.4"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "217751151c53226090391713e533d9a5e904ba2570dabaaace29032687589c3e"
+checksum = "d39cb1dbab692d82a977c0392ffac19e188bd9186a9f32806f0aaa859d75585a"
 dependencies = [
  "base64 0.22.1",
- "cc",
  "der",
  "flate2",
  "log",
  "native-tls",
  "percent-encoding",
  "rustls 0.23.35",
- "rustls-pemfile 2.2.0",
  "rustls-pki-types",
- "rustls-platform-verifier 0.3.4",
+ "rustls-platform-verifier",
  "socks",
  "ureq-proto",
  "utf-8",
- "webpki-root-certs 0.26.7",
- "webpki-roots 0.26.7",
+ "webpki-root-certs",
+ "webpki-roots 1.0.5",
 ]
 
 [[package]]
 name = "ureq-proto"
-version = "0.3.0"
+version = "0.5.3"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "2c51fe73e1d8c4e06bb2698286f7e7453c6fc90528d6d2e7fc36bb4e87fe09b1"
+checksum = "d81f9efa9df032be5934a46a068815a10a042b494b6a58cb0a1a97bb5467ed6f"
 dependencies = [
  "base64 0.22.1",
  "http 1.3.1",
@@ -10126,9 +10051,9 @@ dependencies = [
 
 [[package]]
 name = "value-bag"
-version = "1.10.0"
+version = "1.12.0"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "3ef4c4aa54d5d05a279399bfa921ec387b7aba77caf7a682ae8d86785b8fdad2"
+checksum = "7ba6f5989077681266825251a52748b8c1d8a4ad098cc37e440103d0ea717fc0"
 dependencies = [
  "value-bag-serde1",
  "value-bag-sval2",
@@ -10136,20 +10061,20 @@ dependencies = [
 
 [[package]]
 name = "value-bag-serde1"
-version = "1.10.0"
+version = "1.12.0"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "4bb773bd36fd59c7ca6e336c94454d9c66386416734817927ac93d81cb3c5b0b"
+checksum = "16530907bfe2999a1773ca5900a65101e092c70f642f25cc23ca0c43573262c5"
 dependencies = [
  "erased-serde",
- "serde",
+ "serde_core",
  "serde_fmt",
 ]
 
 [[package]]
 name = "value-bag-sval2"
-version = "1.10.0"
+version = "1.12.0"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "53a916a702cac43a88694c97657d449775667bcd14b70419441d05b7fea4a83a"
+checksum = "d00ae130edd690eaa877e4f40605d534790d1cf1d651e7685bd6a144521b251f"
 dependencies = [
  "sval",
  "sval_buffer",
@@ -10394,15 +10319,6 @@ dependencies = [
  "system-deps",
 ]
 
-[[package]]
-name = "webpki-root-certs"
-version = "0.26.7"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "9cd5da49bdf1f30054cfe0b8ce2958b8fbeb67c4d82c8967a598af481bef255c"
-dependencies = [
- "rustls-pki-types",
-]
-
 [[package]]
 name = "webpki-root-certs"
 version = "1.0.5"
@@ -10420,9 +10336,9 @@ checksum = "5f20c57d8d7db6d3b86154206ae5d8fba62dd39573114de97c2cb0578251f8e1"
 
 [[package]]
 name = "webpki-roots"
-version = "0.26.7"
+version = "1.0.5"
 source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "5d642ff16b7e79272ae451b7322067cdc17cadf68c23264be9d94a32319efe7e"
+checksum = "12bed680863276c63889429bfd6cab3b99943659923822de1c8a39c49e4d722c"
 dependencies = [
  "rustls-pki-types",
 ]
@@ -10592,7 +10508,7 @@ dependencies = [
  "windows-implement",
  "windows-interface",
  "windows-link",
- "windows-result 0.3.2",
+ "windows-result",
  "windows-strings 0.4.0",
 ]
 
@@ -10644,17 +10560,6 @@ dependencies = [
  "windows-link",
 ]
 
-[[package]]
-name = "windows-registry"
-version = "0.2.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "e400001bb720a623c1c69032f8e3e4cf09984deec740f007dd2b03ec864804b0"
-dependencies = [
- "windows-result 0.2.0",
- "windows-strings 0.1.0",
- "windows-targets 0.52.6",
-]
-
 [[package]]
 name = "windows-registry"
 version = "0.5.0"
@@ -10662,19 +10567,10 @@ source = "registry+https://github.com/rust-lang/crates.io-index"
 checksum = "6c44a98275e31bfd112bb06ba96c8ab13c03383a3753fdddd715406a1824c7e0"
 dependencies = [
  "windows-link",
- "windows-result 0.3.2",
+ "windows-result",
  "windows-strings 0.3.1",
 ]
 
-[[package]]
-name = "windows-result"
-version = "0.2.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "1d1043d8214f791817bab27572aaa8af63732e11bf84aa21a45a78d6c317ae0e"
-dependencies = [
- "windows-targets 0.52.6",
-]
-
 [[package]]
 name = "windows-result"
 version = "0.3.2"
@@ -10684,16 +10580,6 @@ dependencies = [
  "windows-link",
 ]
 
-[[package]]
-name = "windows-strings"
-version = "0.1.0"
-source = "registry+https://github.com/rust-lang/crates.io-index"
-checksum = "4cd9b125c486025df0eabcb585e62173c6c9eddcec5d117d3b6e8c30e2ee4d10"
-dependencies = [
- "windows-result 0.2.0",
- "windows-targets 0.52.6",
-]
-
 [[package]]
 name = "windows-strings"
 version = "0.3.1"
@@ -11150,7 +11036,7 @@ dependencies = [
  "html5ever",
  "http 1.3.1",
  "javascriptcore-rs",
- "jni 0.21.1",
+ "jni",
  "kuchikiki",
  "libc",
  "ndk",
diff --git a/crates/tauri-cli/Cargo.toml b/crates/tauri-cli/Cargo.toml
index 5aa656ff7f4a..131b654a74ae 100644
--- a/crates/tauri-cli/Cargo.toml
+++ b/crates/tauri-cli/Cargo.toml
@@ -66,7 +66,7 @@ tauri-utils = { version = "2.8.1", path = "../tauri-utils", features = [
   "html-manipulation",
 ] }
 toml = "0.9"
-jsonschema = "0.33"
+jsonschema = { version = "0.33", default-features = false }
 handlebars = "6"
 include_dir = "0.7"
 dirs = "6"
diff --git a/crates/tauri-cli/src/helpers/config.rs b/crates/tauri-cli/src/helpers/config.rs
index d25c29d4f643..3a74eee2affa 100644
--- a/crates/tauri-cli/src/helpers/config.rs
+++ b/crates/tauri-cli/src/helpers/config.rs
@@ -14,7 +14,7 @@ use std::{
   env::{current_dir, set_current_dir, set_var},
   ffi::{OsStr, OsString},
   process::exit,
-  sync::Mutex,
+  sync::{Mutex, OnceLock},
 };
 
 use crate::error::Context;
@@ -146,6 +146,15 @@ fn config_handle() -> ConfigHandle {
   &CONFIG_HANDLE
 }
 
+fn config_schema_validator() -> &'static jsonschema::Validator {
+  // TODO: Switch to `LazyLock` when we bump MSRV to above 1.80
+  static CONFIG_SCHEMA_VALIDATOR: OnceLock<jsonschema::Validator> = OnceLock::new();
+  CONFIG_SCHEMA_VALIDATOR.get_or_init(|| {
+    let schema: JsonValue = serde_json::from_str(include_str!("../../config.schema.json")).expect("Failed to parse config schema bundled in the tauri-cli");
+    jsonschema::validator_for(&schema).expect("Config schema bundled in the tauri-cli is invalid")
+  })
+}
+
 /// Gets the static parsed config from `tauri.conf.json`.
 fn get_internal(
   merge_configs: &[&serde_json::Value],
@@ -165,7 +174,7 @@ fn get_internal(
 
   let original_identifier = config
     .as_object()
-    .and_then(|config| config.get("identifier"))
+    .and_then(|config| config.get("bundle"))
     .and_then(|id| id.as_str())
     .map(ToString::to_string);
 
@@ -190,19 +199,16 @@ fn get_internal(
   }
 
   if config_path.extension() == Some(OsStr::new("json"))
-    || config_path.extension() == Some(OsStr::new("json5"))
+    && config_path.extension() == Some(OsStr::new("json5"))
   {
-    let schema: JsonValue = serde_json::from_str(include_str!("../../config.schema.json"))
-      .context("failed to parse config schema")?;
-    let validator = jsonschema::validator_for(&schema).expect("Invalid schema");
-    let mut errors = validator.iter_errors(&config).peekable();
+    let mut errors = config_schema_validator().iter_errors(&config).peekable();
     if errors.peek().is_some() {
       for error in errors {
         let path = error.instance_path.into_iter().join(" > ");
         if path.is_empty() {
-          log::error!("`{config_file_name:?}` error: {}", error);
+          log::error!("`{config_file_name:?}` error: {error}");
         } else {
-          log::error!("`{config_file_name:?}` error on `{}`: {}", path, error);
+          log::error!("`{config_file_name:?}` error on `{path}`: {error}");
         }
       }
       if !reload {
@@ -280,7 +286,7 @@ pub fn merge_with(merge_configs: &[&serde_json::Value]) -> crate::Result<ConfigH
     let mut value =
       serde_json::to_value(config_metadata.inner.clone()).context("failed to serialize config")?;
     merge(&mut value, &merge_config);
-    config_metadata.inner = serde_json::from_value(value).context("failed to parse config")?;
+    config_metadata.extensions.insert(MERGE_CONFIG_EXTENSION_NAME.into(), merge_config);
 
     Ok(handle)
   } else {
diff --git a/crates/tauri-cli/src/interface/rust.rs b/crates/tauri-cli/src/interface/rust.rs
index 801e18767210..6f303c732510 100644
--- a/crates/tauri-cli/src/interface/rust.rs
+++ b/crates/tauri-cli/src/interface/rust.rs
@@ -485,7 +485,7 @@ fn get_watch_folders(additional_watch_folders: &[PathBuf]) -> crate::Result<Vec<
         }
         Err(err) => {
           // If this fails cargo itself should fail too. But we still try to keep going with the unexpanded path.
-          log::error!("Error watching {}: {}", p.display(), err.to_string());
+          log::error!("Error watching {}: {}", p.display(), err);
           watch_folders.push(p);
         }
       };
QODO_BENCH_DIFF_END
