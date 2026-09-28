# TypeScript and JavaScript concerns

Load when the diff touches TypeScript or JavaScript source or tests.
load-when: `**/*.ts`, `**/*.tsx`, `**/*.js`, `**/*.jsx`, `**/*.mjs`, `**/*.cjs`, `**/*.mts`, `**/*.cts`

## Correctness

- **Loose `isNaN`** (`correctness/loose-isnan`, default bug): Global `isNaN` coerces its argument, so `isNaN('foo')` is true; `Number.isNaN` only returns true for the actual NaN value. Use the strict form, or parse first and check the result.
  - look-for: bare `isNaN(` calls.
  - triggers: `isNaN(`

- **First-match-only `replace`** (`correctness/replace-first-only`, default issue): `str.replace('x', 'y')` with a string pattern replaces only the first occurrence. Use `replaceAll` or a global regex when every occurrence must change.
  - look-for: `.replace(` with a string literal pattern where multiple occurrences are possible.
  - triggers: `.replace(`
  - gate: skip when replacing only the first occurrence is intended.

- **Generic error breaks type-based handling** (`correctness/generic-error-type`, default bug): Throwing a plain `Error` where a caller branches on `instanceof SomeError` means the branch never matches and the error takes the wrong path.
  - look-for: `throw new Error(` in code whose callers or catch blocks check `instanceof` a specific subclass.
  - triggers: `new Error(`, `instanceof`

- **Optional chaining stops short** (`correctness/partial-optional-chain`, default bug): `a?.b.c` only guards `a`; if `b` can be null the access still throws, often inside an error handler where it hides the original failure. Guard every nullable hop, and do not remove a `?.` link without confirming the parent is always defined.
  - look-for: `?.` followed by plain `.` on a field that can be null, especially in catch blocks and error-message extraction.
  - triggers: `?.`

- **Unguarded nullable access** (`correctness/unguarded-nullable`, default bug): Property access or destructuring on a value that can be null or undefined, even when its parent is set, throws at runtime. Guard it or supply a safe default.
  - look-for: destructuring of optional fields or API results without `?? {}` or a prior check.

- **`fetch` does not reject on HTTP errors** (`correctness/fetch-unchecked-status`, default bug): `fetch` resolves on 4xx and 5xx responses, so code that assumes success will parse error bodies as data. Check `response.ok` or the status.
  - look-for: `await fetch(` followed by `.json()` with no status check.
  - triggers: `fetch(`

- **Binary data coerced to a string** (`correctness/binary-to-string`, default bug): Using a `FileReader` result or other buffer as a string yields `[object ArrayBuffer]` or garbage. Read text with `await file.text()` and binary with `arrayBuffer()`; avoid callback-style `FileReader` for either.
  - look-for: `reader.result` used as a string; `?? ''` fallbacks on a buffer.
  - triggers: `FileReader`, `reader.result`, `.result`, `ArrayBuffer`, `arrayBuffer(`, `readAsText`, `readAsArrayBuffer`, `Buffer`, `toString(`

- **Spread of a huge array into a call** (`correctness/spread-arg-overflow`, default nit): `arr.push(...big)` or `Math.max(...big)` passes every element as an argument and throws a range error past the engine's argument limit.
  - look-for: spread into `push`, `Math.max`, `Math.min`, or `apply` on arrays of unbounded size.
  - triggers: `...`
  - gate: flag only when the array can be large (user data, query results); small fixed arrays are fine.

- **Value returned from a void function** (`correctness/void-return-value`, default nit): Returning a value from a function whose result is never used, or using `return false` purely to exit, misleads readers about the contract.
  - look-for: `return <expr>` in functions typed or used as void.
  - triggers: `return `

## Architecture

- **`any` and inferred public types** (`architecture/any-and-inferred-types`, default issue): `any` and `as any` switch off the type checker exactly where shapes are uncertain; exported functions and service methods without return types let accidental shape changes leak to callers. Type bodies properly (a union when one endpoint accepts several shapes) and declare return types on public APIs.
  - look-for: `any`-typed parameters or bodies, `as any` casts, exported functions without a return type.
  - triggers: `any`, `export `, `public `

## Testing

- **Unawaited async assertion** (`testing/unawaited-async-assertion`, default bug): `expect(promise).rejects.toThrow()` or `.resolves` without `await` or `return` is a floating promise; the test passes even when the code never throws.
  - look-for: `expect(...).rejects` or `.resolves` without a leading `await` or `return`.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`
  - triggers: `.rejects`, `.resolves`
