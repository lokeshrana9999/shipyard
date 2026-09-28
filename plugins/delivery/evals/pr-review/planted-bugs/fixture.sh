#!/usr/bin/env bash
# A small diff with three planted bugs: a missing ownership check, a swallowed error, and isNaN on user input.
set -e
cat > branch.diff <<'DIFF'
diff --git a/api/documents/documents.controller.ts b/api/documents/documents.controller.ts
--- a/api/documents/documents.controller.ts
+++ b/api/documents/documents.controller.ts
@@ -40,6 +40,30 @@ export class DocumentsController {
+  @Patch(':id')
+  @Authenticated()
+  async rename(@Param('id') id: string, @Body() body: { title: string }, @CurrentUser() user: User) {
+    const doc = await this.db.document.update({ where: { id }, data: { title: body.title } });
+    return { id: doc.id, title: doc.title };
+  }
+
+  @Get(':id/pages')
+  @Authenticated()
+  async pages(@Param('id') id: string, @Query('limit') limit: string, @CurrentUser() user: User) {
+    const n = isNaN(limit as any) ? 20 : Number(limit);
+    try {
+      return await this.pagesService.list(id, user.accountId, n);
+    } catch (e) {
+      console.log(e);
+    }
+  }
DIFF
