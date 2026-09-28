#!/usr/bin/env bash
# Qodo PR-Review-Bench https://github.com/agentic-review-benchmarks/tauri/pull/12 (MIT, see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/.changes/file-association-content-type.md b/.changes/file-association-content-type.md
new file mode 100644
index 000000000000..985bbfa2411b
--- /dev/null
+++ b/.changes/file-association-content-type.md
@@ -0,0 +1,6 @@
+---
+"tauri-cli": minor:feat
+"@tauri-apps/cli": minor:feat
+---
+
+Added support to defining the content type of the declared file association on macOS (maps to LSItemContentTypes property).
diff --git a/.changes/file-association-exported-type-cli.md b/.changes/file-association-exported-type-cli.md
new file mode 100644
index 000000000000..b2685b37dd58
--- /dev/null
+++ b/.changes/file-association-exported-type-cli.md
@@ -0,0 +1,6 @@
+---
+"tauri-cli": minor:feat
+"@tauri-apps/cli": minor:feat
+---
+
+Added support to defining the metadata for custom types declared in `tauri.conf.json > bundle > fileAssociations > exportedType` via the `UTExportedTypeDeclarations` Info.plist property.
diff --git a/.changes/file-association-exported-type.md b/.changes/file-association-exported-type.md
new file mode 100644
index 000000000000..75cf0545fdfd
--- /dev/null
+++ b/.changes/file-association-exported-type.md
@@ -0,0 +1,5 @@
+---
+"tauri-utils": minor:feat
+---
+
+Added `FileAssociation::exported_type` and `FileAssociation::content_types` for better support to defining custom types on macOS.
diff --git a/crates/tauri-bundler/src/bundle/macos/app.rs b/crates/tauri-bundler/src/bundle/macos/app.rs
index 25ae06a01b2c..8c8ec7db0ae2 100644
--- a/crates/tauri-bundler/src/bundle/macos/app.rs
+++ b/crates/tauri-bundler/src/bundle/macos/app.rs
@@ -268,6 +268,55 @@ fn create_info_plist(
   }
 
   if let Some(associations) = settings.file_associations() {
+    let exported_associations = associations
+      .iter()
+      .filter_map(|association| {
+        association.exported_type.as_ref().map(|exported_type| {
+          let mut dict = plist::Dictionary::new();
+
+          dict.insert(
+            "UTTypeIdentifier".into(),
+            exported_type.identifier.clone().into(),
+          );
+          if let Some(description) = &association.description {
+            dict.insert("UTTypeDescription".into(), description.clone().into());
+          }
+          if let Some(content_types) = &association.content_types {
+            dict.insert(
+              "UTTypeConformsTo".into(),
+              plist::Value::Array(content_types.iter().map(|s| s.clone().into()).collect()),
+            );
+          }
+
+          let mut specification = plist::Dictionary::new();
+          specification.insert(
+            "public.filename-extension".into(),
+            plist::Value::Array(
+              association
+                .ext
+                .iter()
+                .map(|s| s.to_string().into())
+                .collect(),
+            ),
+          );
+          if let Some(mime_type) = &association.mime_type {
+            specification.insert("public.mime-type".into(), mime_type.clone().into());
+          }
+
+          dict.insert("UTTypeTagSpecification".into(), specification.into());
+
+          plist::Value::Dictionary(dict)
+        })
+      })
+      .collect::<Vec<_>>();
+
+    if !exported_associations.is_empty() {
+      plist.insert(
+        "UTExportedTypeDeclarations".into(),
+        plist::Value::Array(exported_associations),
+      );
+    }
+
     plist.insert(
       "CFBundleDocumentTypes".into(),
       plist::Value::Array(
@@ -275,22 +324,33 @@ fn create_info_plist(
           .iter()
           .map(|association| {
             let mut dict = plist::Dictionary::new();
-            dict.insert(
-              "CFBundleTypeExtensions".into(),
-              plist::Value::Array(
-                association
-                  .ext
-                  .iter()
-                  .map(|ext| ext.to_string().into())
-                  .collect(),
-              ),
-            );
+
+            if association.ext.is_empty() {
+              dict.insert(
+                "CFBundleTypeExtensions".into(),
+                plist::Value::Array(
+                  association
+                    .ext
+                    .iter()
+                    .map(|ext| ext.to_string().into())
+                    .collect(),
+                ),
+              );
+            }
+
+            if let Some(content_types) = &association.content_types {
+              dict.insert(
+                "LSItemContentTypes".into(),
+                plist::Value::Array(content_types.iter().map(|s| s.to_string().into()).collect()),
+              );
+            }
+
             dict.insert(
               "CFBundleTypeName".into(),
               association
                 .name
                 .as_ref()
-                .unwrap_or(&association.ext[0].0)
+                .expect("File association must have a name")
                 .to_string()
                 .into(),
             );
diff --git a/crates/tauri-cli/config.schema.json b/crates/tauri-cli/config.schema.json
index b84ac6d358dd..6d480475ceec 100644
--- a/crates/tauri-cli/config.schema.json
+++ b/crates/tauri-cli/config.schema.json
@@ -2159,7 +2159,7 @@
           ]
         },
         "fileAssociations": {
-          "description": "File associations to application.",
+          "description": "File types to associate with the application.",
           "type": [
             "array",
             "null"
@@ -2433,6 +2433,16 @@
             "$ref": "#/definitions/AssociationExt"
           }
         },
+        "contentTypes": {
+          "description": "Declare support to a file with the given content type. Maps to `LSItemContentTypes` on macOS.\n\n This allows supporting any file format declared by another application that conforms to this type.\n Declaration of new types can be done with [`Self::exported_type`] and linking to certain content types are done via [`ExportedFileAssociation::conforms_to`].",
+          "type": [
+            "array",
+            "null"
+          ],
+          "items": {
+            "type": "string"
+          }
+        },
         "name": {
           "description": "The name. Maps to `CFBundleTypeName` on macOS. Default to `ext[0]`",
           "type": [
@@ -2471,6 +2481,17 @@
               "$ref": "#/definitions/HandlerRank"
             }
           ]
+        },
+        "exportedType": {
+          "description": "The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.\n\n You should define this if the associated file is a custom file type defined by your application.",
+          "anyOf": [
+            {
+              "$ref": "#/definitions/ExportedFileAssociation"
+            },
+            {
+              "type": "null"
+            }
+          ]
         }
       },
       "additionalProperties": false
@@ -2552,6 +2573,30 @@
         }
       ]
     },
+    "ExportedFileAssociation": {
+      "description": "The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.",
+      "type": "object",
+      "required": [
+        "identifier"
+      ],
+      "properties": {
+        "identifier": {
+          "description": "The unique identifier for the exported type. Maps to `UTTypeIdentifier`.",
+          "type": "string"
+        },
+        "conformsTo": {
+          "description": "The types that this type conforms to. Maps to `UTTypeConformsTo`.\n\n Examples are `public.data`, `public.image`, `public.json` and `public.database`.",
+          "type": [
+            "array",
+            "null"
+          ],
+          "items": {
+            "type": "string"
+          }
+        }
+      },
+      "additionalProperties": false
+    },
     "WindowsConfig": {
       "description": "Windows bundler configuration.\n\n See more: <https://v2.tauri.app/reference/config/#windowsconfig>",
       "type": "object",
diff --git a/crates/tauri-schema-generator/schemas/config.schema.json b/crates/tauri-schema-generator/schemas/config.schema.json
index b84ac6d358dd..6d480475ceec 100644
--- a/crates/tauri-schema-generator/schemas/config.schema.json
+++ b/crates/tauri-schema-generator/schemas/config.schema.json
@@ -2159,7 +2159,7 @@
           ]
         },
         "fileAssociations": {
-          "description": "File associations to application.",
+          "description": "File types to associate with the application.",
           "type": [
             "array",
             "null"
@@ -2433,6 +2433,16 @@
             "$ref": "#/definitions/AssociationExt"
           }
         },
+        "contentTypes": {
+          "description": "Declare support to a file with the given content type. Maps to `LSItemContentTypes` on macOS.\n\n This allows supporting any file format declared by another application that conforms to this type.\n Declaration of new types can be done with [`Self::exported_type`] and linking to certain content types are done via [`ExportedFileAssociation::conforms_to`].",
+          "type": [
+            "array",
+            "null"
+          ],
+          "items": {
+            "type": "string"
+          }
+        },
         "name": {
           "description": "The name. Maps to `CFBundleTypeName` on macOS. Default to `ext[0]`",
           "type": [
@@ -2471,6 +2481,17 @@
               "$ref": "#/definitions/HandlerRank"
             }
           ]
+        },
+        "exportedType": {
+          "description": "The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.\n\n You should define this if the associated file is a custom file type defined by your application.",
+          "anyOf": [
+            {
+              "$ref": "#/definitions/ExportedFileAssociation"
+            },
+            {
+              "type": "null"
+            }
+          ]
         }
       },
       "additionalProperties": false
@@ -2552,6 +2573,30 @@
         }
       ]
     },
+    "ExportedFileAssociation": {
+      "description": "The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.",
+      "type": "object",
+      "required": [
+        "identifier"
+      ],
+      "properties": {
+        "identifier": {
+          "description": "The unique identifier for the exported type. Maps to `UTTypeIdentifier`.",
+          "type": "string"
+        },
+        "conformsTo": {
+          "description": "The types that this type conforms to. Maps to `UTTypeConformsTo`.\n\n Examples are `public.data`, `public.image`, `public.json` and `public.database`.",
+          "type": [
+            "array",
+            "null"
+          ],
+          "items": {
+            "type": "string"
+          }
+        }
+      },
+      "additionalProperties": false
+    },
     "WindowsConfig": {
       "description": "Windows bundler configuration.\n\n See more: <https://v2.tauri.app/reference/config/#windowsconfig>",
       "type": "object",
diff --git a/crates/tauri-utils/src/config.rs b/crates/tauri-utils/src/config.rs
index a967815e719a..89ec983c7a4e 100644
--- a/crates/tauri-utils/src/config.rs
+++ b/crates/tauri-utils/src/config.rs
@@ -1177,6 +1177,12 @@ impl<'d> serde::Deserialize<'d> for AssociationExt {
 pub struct FileAssociation {
   /// File extensions to associate with this app. e.g. 'png'
   pub ext: Vec<AssociationExt>,
+  /// Declare support to a file with the given content type. Maps to `LSItemContentTypes` on macOS.
+  ///
+  /// This allows supporting any file format declared by another application that conforms to this type.
+  /// Declaration of new types can be done with [`Self::exported_type`] and linking to certain content types are done via [`ExportedFileAssociation::conforms_to`].
+  #[serde(alias = "content-types")]
+  pub content_types: Option<Vec<String>>,
   /// The name. Maps to `CFBundleTypeName` on macOS. Default to `ext[0]`
   pub name: Option<String>,
   /// The association description. Windows-only. It is displayed on the `Type` column on Windows Explorer.
@@ -1190,6 +1196,24 @@ pub struct FileAssociation {
   /// The ranking of this app among apps that declare themselves as editors or viewers of the given file type.  Maps to `LSHandlerRank` on macOS.
   #[serde(default)]
   pub rank: HandlerRank,
+  /// The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.
+  ///
+  /// You should define this if the associated file is a custom file type defined by your application.
+  pub exported_type: Option<ExportedFileAssociation>,
+}
+
+/// The exported type definition. Maps to a `UTExportedTypeDeclarations` entry on macOS.
+#[derive(Debug, PartialEq, Eq, Clone, Deserialize, Serialize)]
+#[cfg_attr(feature = "schema", derive(JsonSchema))]
+#[serde(rename_all = "camelCase", deny_unknown_fields)]
+pub struct ExportedFileAssociation {
+  /// The unique identifier for the exported type. Maps to `UTTypeIdentifier`.
+  pub identifier: String,
+  /// The types that this type conforms to. Maps to `UTTypeConformsTo`.
+  ///
+  /// Examples are `public.data`, `public.image`, `public.json` and `public.database`.
+  #[serde(alias = "conforms-to")]
+  pub conforms_to: Option<Vec<String>>,
 }
 
 /// Deep link protocol configuration.
@@ -1356,7 +1380,7 @@ pub struct BundleConfig {
   /// Should be one of the following:
   /// Business, DeveloperTool, Education, Entertainment, Finance, Game, ActionGame, AdventureGame, ArcadeGame, BoardGame, CardGame, CasinoGame, DiceGame, EducationalGame, FamilyGame, KidsGame, MusicGame, PuzzleGame, RacingGame, RolePlayingGame, SimulationGame, SportsGame, StrategyGame, TriviaGame, WordGame, GraphicsAndDesign, HealthcareAndFitness, Lifestyle, Medical, Music, News, Photography, Productivity, Reference, SocialNetworking, Sports, Travel, Utility, Video, Weather.
   pub category: Option<String>,
-  /// File associations to application.
+  /// File types to associate with the application.
   pub file_associations: Option<Vec<FileAssociation>>,
   /// A short description of your application.
   #[serde(alias = "short-description")]
diff --git a/examples/file-associations/README.md b/examples/file-associations/README.md
index da58498eb075..0579e7eb2ede 100644
--- a/examples/file-associations/README.md
+++ b/examples/file-associations/README.md
@@ -11,3 +11,9 @@ This feature is commonly used for functionality such as previewing or editing fi
    ```
    cargo build --features tauri/protocol-asset
    ```
+
+## Associations
+
+This example creates associations with PNG, JPG, JPEG and GIF files.
+
+Additionally, it defines two new extensions - `taurid` (derives from a raw data file) and `taurijson` (derives from JSON). They have special treatment on macOS (see `exportedType` in `src-tauri/tauri.conf.json`).
diff --git a/examples/file-associations/src-tauri/Cargo.toml b/examples/file-associations/src-tauri/Cargo.toml
index a67d0a1bb688..bfdcac621e69 100644
--- a/examples/file-associations/src-tauri/Cargo.toml
+++ b/examples/file-associations/src-tauri/Cargo.toml
@@ -11,5 +11,5 @@ tauri-build = { path = "../../../crates/tauri-build", features = ["codegen"] }
 [dependencies]
 serde_json = "1"
 serde = { version = "1", features = ["derive"] }
-tauri = { path = "../../../crates/tauri", features = [] }
+tauri = { path = "../../../crates/tauri", features = ["protocol-asset"] }
 url = "2"
diff --git a/examples/file-associations/src-tauri/tauri.conf.json b/examples/file-associations/src-tauri/tauri.conf.json
index 3ac3be0fd0ab..3d9afcd65866 100644
--- a/examples/file-associations/src-tauri/tauri.conf.json
+++ b/examples/file-associations/src-tauri/tauri.conf.json
@@ -1,12 +1,15 @@
 {
-  "$schema": "../../../crates/tauri-cli/schema.json",
+  "$schema": "../../../crates/tauri-cli/config.schema.json",
   "identifier": "com.tauri.dev-file-associations-demo",
   "build": {
     "frontendDist": ["../index.html"]
   },
   "app": {
     "security": {
-      "csp": "default-src 'self'"
+      "csp": "default-src 'self'",
+      "assetProtocol": {
+        "enable": true
+      }
     }
   },
   "bundle": {
@@ -34,6 +37,20 @@
         "ext": ["gif"],
         "mimeType": "image/gif",
         "rank": "Owner"
+      },
+      {
+        "ext": ["taurijson"],
+        "exportedType": {
+          "identifier": "com.tauri.dev-file-associations-demo.taurijson",
+          "conformsTo": ["public.json"]
+        }
+      },
+      {
+        "ext": ["taurid"],
+        "exportedType": {
+          "identifier": "com.tauri.dev-file-associations-demo.tauridata",
+          "conformsTo": ["public.data"]
+        }
       }
     ]
   }
QODO_BENCH_DIFF_END
