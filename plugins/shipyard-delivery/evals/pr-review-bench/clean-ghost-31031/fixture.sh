#!/usr/bin/env bash
# Merged upstream PR https://github.com/TryGhost/Ghost/pull/31031, used as a clean diff (see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/ghost/core/core/server/models/post.js b/ghost/core/core/server/models/post.js
index ae71894d85f..bbd7688d545 100644
--- a/ghost/core/core/server/models/post.js
+++ b/ghost/core/core/server/models/post.js
@@ -754,7 +754,14 @@ Post = ghostBookshelf.Model.extend(
           (!this.get('html') && (options.migrating || options.importing)))
       ) {
         try {
-          this.set('lexical', mobiledocToLexical(this.get('mobiledoc')));
+          let lexical = mobiledocToLexical(this.get('mobiledoc'));
+
+          // an empty mobiledoc converts to an empty root, which lexical refuses to render
+          if (!JSON.parse(this.get('mobiledoc')).sections?.length) {
+            lexical = JSON.stringify(lexicalLib.blankDocument);
+          }
+
+          this.set('lexical', lexical);
           this.set('mobiledoc', null);
         } catch (err) {
           throw new errors.ValidationError({
diff --git a/ghost/core/test/integration/importer/v2.test.js b/ghost/core/test/integration/importer/v2.test.js
index 2dde39a7ec8..a504a2cde0e 100644
--- a/ghost/core/test/integration/importer/v2.test.js
+++ b/ghost/core/test/integration/importer/v2.test.js
@@ -1488,6 +1488,70 @@ describe('Importer', function () {
         });
     });
 
+    it('import post with empty mobiledoc and null lexical', async function () {
+      const exportData = exportedBodyV2().db[0];
+
+      exportData.data.posts[0] = testUtils.DataGenerator.forKnex.createPost({
+        slug: 'empty-mobiledoc',
+        mobiledoc: JSON.stringify({
+          version: '0.3.1',
+          atoms: [],
+          cards: [],
+          markups: [],
+          sections: [],
+          ghostVersion: '3.0',
+        }),
+        lexical: null,
+        html: '<p></p>',
+      });
+
+      delete exportData.data.posts[0].html;
+
+      const options = Object.assign(
+        { formats: 'mobiledoc,lexical,html' },
+        testUtils.context.internal,
+      );
+
+      const result = await dataImporter.doImport(exportData, importOptions);
+      assert.deepEqual(result.problems, []);
+
+      const post = (await models.Post.findOne({ slug: 'empty-mobiledoc' }, options)).toJSON(
+        options,
+      );
+
+      assert.equal(post.mobiledoc, null);
+      assert.equal(
+        post.lexical,
+        JSON.stringify(require('../../../core/server/lib/lexical').blankDocument),
+      );
+      assert.equal(post.html, null);
+    });
+
+    it('does not blank a post whose mobiledoc sections are all unsupported', async function () {
+      const exportData = exportedBodyV2().db[0];
+
+      exportData.data.posts[0] = testUtils.DataGenerator.forKnex.createPost({
+        slug: 'unsupported-mobiledoc',
+        mobiledoc: JSON.stringify({
+          version: '0.3.1',
+          atoms: [],
+          cards: [],
+          markups: [],
+          sections: [[2, 'https://example.com/image.jpg']],
+        }),
+        lexical: null,
+        html: '<p></p>',
+      });
+
+      delete exportData.data.posts[0].html;
+
+      await assert.rejects(dataImporter.doImport(exportData, importOptions), (err) => {
+        assert(err instanceof errors.DataImportError);
+        assert.equal(err.errorDetails[0].message, 'Invalid lexical structure.');
+        return true;
+      });
+    });
+
     it('Can import stripe plans with an "amount" of 0', async function () {
       const exportData = exportedBodyV2().db[0];
 
QODO_BENCH_DIFF_END
