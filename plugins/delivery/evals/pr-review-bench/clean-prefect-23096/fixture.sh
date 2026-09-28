#!/usr/bin/env bash
# Merged upstream PR https://github.com/PrefectHQ/prefect/pull/23096, used as a clean diff (see ../README.md).
set -e
cat > branch.diff <<'QODO_BENCH_DIFF_END'
diff --git a/ui-v2/src/components/variables/data-table/cells.test.tsx b/ui-v2/src/components/variables/data-table/cells.test.tsx
new file mode 100644
index 000000000000..ca3f95fd3052
--- /dev/null
+++ b/ui-v2/src/components/variables/data-table/cells.test.tsx
@@ -0,0 +1,29 @@
+import { render, screen } from "@testing-library/react";
+import { describe, expect, it, vi } from "vitest";
+import type { components } from "@/api/prefect";
+import type { CellContext } from "@/lib/tanstack-table";
+import { ValueCell } from "./cells";
+
+vi.mock("@/hooks/use-is-overflowing", () => ({
+	useIsOverflowing: () => false,
+}));
+
+const props = (
+	value: NonNullable<components["schemas"]["Variable"]["value"]>,
+) =>
+	({ getValue: () => value }) as CellContext<
+		components["schemas"]["Variable"],
+		NonNullable<components["schemas"]["Variable"]["value"]>
+	>;
+
+describe("ValueCell", () => {
+	it.each([
+		[0, "0"],
+		[false, "false"],
+		["", '""'],
+	])("renders the JSON value %j", (value, expected) => {
+		render(<ValueCell {...props(value)} />);
+
+		expect(screen.getByText(expected)).toBeInTheDocument();
+	});
+});
diff --git a/ui-v2/src/components/variables/data-table/cells.tsx b/ui-v2/src/components/variables/data-table/cells.tsx
index b28169094064..eb32075a0445 100644
--- a/ui-v2/src/components/variables/data-table/cells.tsx
+++ b/ui-v2/src/components/variables/data-table/cells.tsx
@@ -101,7 +101,7 @@ export const ValueCell = (
 	const codeRef = useRef<HTMLDivElement>(null);
 	const isOverflowing = useIsOverflowing(codeRef);
 
-	if (!value) return null;
+	if (value === undefined) return null;
 	return (
 		// Disable the hover card if the value is not overflowing
 		<HoverCard open={isOverflowing ? undefined : false}>
QODO_BENCH_DIFF_END
