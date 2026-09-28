#!/usr/bin/env bash
# Merged upstream PR https://github.com/tauri-apps/tauri/pull/16120, used as a clean diff (see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/.changes/cli-cargo-toml-version-value.md b/.changes/cli-cargo-toml-version-value.md
new file mode 100644
index 000000000000..e509c9b641ec
--- /dev/null
+++ b/.changes/cli-cargo-toml-version-value.md
@@ -0,0 +1,6 @@
+---
+"tauri-cli": patch:bug
+"@tauri-apps/cli": patch:bug
+---
+
+Fix the Cargo.toml feature rewrite corrupting a string dependency version that has a trailing comment or uses single quotes (e.g. `tauri = "2" # pin` became `"2#pin"`). The version value is now kept as-is and the comment is preserved.
diff --git a/crates/tauri-cli/src/interface/rust/manifest.rs b/crates/tauri-cli/src/interface/rust/manifest.rs
index dbb76e975bf7..8543fabb8a74 100644
--- a/crates/tauri-cli/src/interface/rust/manifest.rs
+++ b/crates/tauri-cli/src/interface/rust/manifest.rs
@@ -164,8 +164,10 @@ fn write_features<F: Fn(&str) -> bool>(
       }
       Value::String(version) => {
         let mut def = InlineTable::default();
-        def.get_or_insert("version", version.to_string().replace(['\"', ' '], ""));
+        def.get_or_insert("version", version.value().as_str());
         def.get_or_insert("features", Value::Array(toml_array(features)));
+        // keep the surrounding whitespace and trailing comment
+        *def.decor_mut() = version.decor().clone();
         *dep = Value::InlineTable(def);
       }
       _ => {
@@ -485,6 +487,35 @@ mod tests {
     );
   }
 
+  #[test]
+  fn inject_features_string_keeps_version_value() {
+    let mut manifest = r#"[dependencies]
+tauri = "2" # pin
+tauri-build = '2.1'
+"#
+    .parse::<toml_edit::DocumentMut>()
+    .unwrap();
+
+    let mut dependencies = vec![
+      tauri_dependency(HashSet::from_iter(vec!["isolation".into()])),
+      DependencyAllowlist {
+        name: "tauri-build".into(),
+        kind: DependencyKind::Normal,
+        all_cli_managed_features: vec![],
+        features: HashSet::from_iter(vec!["codegen".into()]),
+      },
+    ];
+    super::inject_features(&mut manifest, &mut dependencies).unwrap();
+
+    assert_eq!(
+      manifest.to_string(),
+      r#"[dependencies]
+tauri = { version = "2", features = ["isolation"] } # pin
+tauri-build = { version = "2.1", features = ["codegen"] }
+"#
+    );
+  }
+
   #[test]
   fn inject_features_string() {
     inject_features(
QODO_BENCH_DIFF_END
