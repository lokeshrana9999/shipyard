# General concerns

Load for every review; these apply regardless of language or stack.

Contents: correctness · security · architecture · naming · style · testing · process

## Correctness

- **Swallowed exception** (`correctness/swallowed-catch`, default bug): A catch block that is empty or only logs, with no rethrow, return value, or response, makes runtime failures vanish and leaves callers believing the operation succeeded.
  - look-for: `catch (e) {}` or a catch whose only statement is a log call, in code that is not a top-level handler.
  - triggers: `catch`, `except`, `rescue`
  - gate: skip when the swallowed failure is explicitly optional (best-effort cleanup, telemetry) and a comment says so.

- **Catch-all hides unexpected failures** (`correctness/overbroad-catch`, default issue): A catch meant for one expected case (not found, already exists) that absorbs every error turns real outages into silent wrong behavior. Handle the expected case and rethrow the rest; when replacing an error with a generic one, log it or attach it as the cause so the root cause survives.
  - look-for: a catch that returns a default or continues without checking the error type, code, or status; `throw new X('failed')` with the caught error never logged or passed as `cause`.
  - triggers: `catch`, `except`, `rescue`

- **Side effect before validation** (`correctness/side-effect-before-validation`, default issue): Creating external resources, sending messages, or writing rows before existence checks, authorization, and input validation run means a rejected request still leaves orphaned state behind. Validate and fail fast first.
  - look-for: an external create/send/write call placed above guard clauses or throws in the same function.

- **External and local state diverge on failure** (`correctness/external-state-divergence`, default bug): When a resource lives both locally and in an external system, an unhandled failure in the external call (already gone, timeout) can block the local cleanup, or vice versa, leaving the two out of sync.
  - look-for: an external API delete/update followed by a local write, with no handling for "external resource missing" or partial failure.

- **Duplicate input silently ignored** (`correctness/silent-duplicate`, default issue): When a create or add flow skips an item because it already exists, or the backend rejects it on a unique constraint, the user should get a specific message rather than a silent no-op or a generic error.
  - look-for: dedup logic that drops items without reporting them; a create path on a unique field with no conflict handling.

- **Defined but never wired in** (`correctness/unwired-definition`, default bug): A new handler, tool, route, job, plugin, or migration that exists, has a schema, and passes its unit test, but is never added to the registry, router, or list the runtime actually reads, so it never runs. It's the failure that looks most like working code.
  - look-for: a new exported handler or definition whose id or name doesn't appear in the registration list, router, module declaration, or config the running app loads; tests that import the new handler directly instead of reaching it through that registration.
  - gate: skip when the diff states the piece is deliberately unregistered (behind a flag, staged for a later change).

- **Changed contract breaks existing callers** (`correctness/caller-regression`, default bug): Changing a shared function's signature, return shape, nullability, thrown errors, or side effects breaks callers outside the diff that relied on the old behavior. Read the callers, not just the changed function.
  - look-for: a changed exported function, method, hook, or type whose callers elsewhere in the codebase aren't updated in the diff; a return value that can now be null or empty; an error that's now thrown or no longer thrown.
  - gate: skip when every caller is updated in the same diff.

## Security

- **Super-linear regex on untrusted input** (`security/regex-backtracking`, default issue): A pattern with nested or overlapping quantifiers can backtrack quadratically or worse on crafted input, which is a denial-of-service vector.
  - look-for: patterns like `(a+)+`, `(\d+)$` with an unused capture, or `.*` followed by an overlapping quantifier, applied to request data.
  - triggers: `new RegExp(`, `RegExp(`, `re.compile(`, `re.match(`, `re.search(`, `Regex`, `regexp`, `.match(`, `.test(`, `.replace(`, `.search(`, `.split(`, `.*`, `.+`, `+)`, `*)`, `\d+`, `\w+`, `\s+`
  - gate: skip when the input is trusted and bounded in length.

- **Removed mode falls through to a less-safe path** (`security/unsafe-fallthrough`, default bug): Deleting an enum value or execution mode that stored data or flags may still reference can route those callers into a default branch with weaker isolation or checks, with no error raised.
  - look-for: an enum member or mode removed while a `default`/`else` branch runs the least-restricted path.

- **Weak or shared salt** (`security/weak-salt`, default bug): A short, fixed, or globally shared salt makes hashed or derived secrets far easier to brute-force. Salts should be random, sufficiently long, and unique per record.
  - look-for: a hardcoded salt constant, a small salt length, or one salt reused across users.
  - triggers: `salt`

## Architecture

- **Duplicated logic** (`architecture/duplicated-logic`, default issue): The same list, constant, block, or component appearing in two or more places drifts as soon as one copy changes. This includes new helpers (queries, filters, pagination, utilities) that re-implement one already in the codebase, and hand-maintained lists that repeat an enum's values. Extract or reuse one shared definition, and derive lists from their source.
  - look-for: identical arrays or literals, copy-pasted functions, near-identical sibling components or markup, a new helper whose name or body closely matches an existing one, an array mirroring an enum's members.

- **Bypasses the owning module** (`architecture/bypasses-owner`, default issue): Reading or writing another module's data directly, instead of through the module that owns it, skips any cross-cutting behavior that module applies (encryption, auditing, cache invalidation).
  - look-for: direct data-access calls on an entity owned by a different module when that module exposes a service for it.

- **Rule duplicated across packages** (`architecture/cross-package-drift`, default issue): A rule the client and server must agree on (which statuses count as active, which roles may edit, a size limit, an enum of values) declared separately in each drifts silently and surfaces as a UI that disagrees with the API.
  - look-for: the diff adds a second copy of a constant, enum, or limit that already exists in another package, or one side types as a loose string what the other models as an enum.

- **Peer imports a peer's internals** (`architecture/peer-internal-import`, default issue): One plugin, handler, or domain importing a helper or event type from a sibling couples units meant to be independent. Move the shared piece into a layer both depend on, or translate at the adapter boundary.
  - look-for: an import path reaching into a sibling module's internal folder.
  - triggers: `import`, `require(`, `from `
  - gate: a child importing from its own parent module is normal.

- **Non-idempotent registration** (`architecture/non-idempotent-registration`, default issue): A registry that throws on duplicate ids is right in production but crashes on hot reload or a repeated init hook. Make registration tolerate re-registration of the same entry without weakening the duplicate check for distinct entries.
  - look-for: `throw` on duplicate key inside a register call reached from a lifecycle or init hook.
  - triggers: `register`, `throw`, `raise`

- **Generic component with special cases** (`architecture/special-cased-generic`, default issue): A shared component that branches on specific callers or source types is no longer generic. Parameterize the varying content and keep per-type mappings in one config.
  - look-for: `if (type === 'x')` chains inside a shared component; per-type maps duplicated across files.
  - triggers: `===`, `==`, `case `, `switch`

- **Oversized parameter** (`architecture/overbroad-parameter`, default issue): Passing a whole user or request object when the callee only needs an id hides the real dependency and invites misuse, such as confusing the resource owner with the caller.
  - look-for: a function taking a full object and reading one field from it.

- **Long method with several jobs** (`architecture/long-method`, default issue): A method mixing separable responsibilities (validation, persistence, telemetry, formatting) is hard to test and review. Extract named helpers.
  - look-for: a function over roughly 50 lines with distinct blocks, or inline analytics and metrics code inside business logic.

- **Dead code left behind** (`architecture/dead-code`, default issue): Unused methods, hooks, fields, config, dependencies, test mocks, or a superseded implementation kept alongside its replacement mislead readers and rot. Delete it and confirm nothing references it.
  - look-for: a new implementation added while the old one stays; schema or DTO fields with no read site; config, packages, or mocks for a removed approach.

- **Deprecated API in the installed version** (`architecture/deprecated-api`, default issue): Using an API that the installed major version deprecates or removes adds migration debt or fails at upgrade.
  - look-for: imports or calls documented as deprecated for the version pinned in the manifest.

## Naming

- **Magic value instead of a named constant or enum** (`naming/magic-value`, default issue): String or number literals used as discriminants, limits, or config scatter across files and break silently on rename or change. Use an enum or a named constant in an appropriately scoped file.
  - look-for: repeated string literals for statuses or types; numeric literals for limits, thresholds, modes.

- **Vague name** (`naming/vague-name`, default nit): Names like `data`, `info`, `helper`, `handle`, or abbreviations of domain terms hide what a value holds or what a function does. Name by purpose, source, and cardinality; booleans should read as predicates (`isX`, `hasX`, `shouldX`) without double negatives.
  - look-for: generic nouns, `Data`/`Info`/`Details` suffixes, abbreviations where the codebase uses the full word, verb-led names for non-function values, `!isNotX`-style negated booleans.

- **Name no longer matches behavior** (`naming/stale-name`, default issue): A function, file, or component whose scope broadened or whose behavior changed but kept its old narrow name actively misleads. Rename to match what it does now.
  - look-for: a component reused for a different entity; a feature-specific prefix on something now shared; a verb that no longer matches the effect.

- **Spelling mistake in identifier or copy** (`naming/typo`, default nit): Misspelled identifiers and file names break search and spread through the codebase once used; typos in user-facing copy look careless.
  - look-for: misspelled words in new names, file names, or strings; inconsistent capitalization of proper nouns.

## Style

- **Misleading or stale comment** (`style/stale-comment`, default issue): A comment that describes old behavior or contradicts the code is worse than none because readers trust it.
  - look-for: a comment adjacent to changed code that still describes the previous logic.

- **Comment noise and commented-out code** (`style/comment-noise`, default nit): Comments that restate the next line, narrate the change history, or keep commented-out code add reading cost with no information. Comment why, not what.
  - look-for: commented-out blocks, including in migration scripts; comments like "increment counter" above `count++`.
  - triggers: `//`, `/*`, `#`, `--`, `<!--`

- **Leftover debug output** (`style/debug-output`, default issue): Stray console or print statements in production or test code add noise and can leak data into logs. Remove them or route through the project logger with a meaningful message.
  - look-for: `console.log`, `print`, or equivalent added in non-debug code.
  - triggers: `console.`, `print(`, `println`, `printf(`, `fmt.Print`, `debugger`, `var_dump(`, `dump(`, `puts `, `pp `

- **Nested ternary** (`style/nested-ternary`, default nit): More than one level of conditional expression is hard to read and easy to get wrong. Extract a named value or use early returns.
  - look-for: `a ? b : c ? d : e`.
  - triggers: `?`, ` else `

- **Deep nesting instead of guard clauses** (`style/deep-nesting`, default nit): Wrapping the main logic under several conditions buries it. Handle loading, empty, and error cases first with early returns.
  - look-for: the core of a function indented under two or more `if` levels.

- **Redundant condition** (`style/redundant-condition`, default nit): A guard that can never trigger, or branches that produce the same result, adds complexity without value.
  - look-for: null checks on values guaranteed non-null upstream; `if/else` arms with identical effect.
  - gate: confirm the condition truly cannot occur; if in doubt, ask instead of flagging.

## Testing

- **Happy path only** (`testing/happy-path-only`, default issue): New validation, error handling, and conditional branches need tests that exercise them and assert the specific error, not just the success case.
  - look-for: new `throw`, `catch`, or `if` branches with no corresponding test; assertions for a generic throw where a specific error type applies.
  - triggers: `throw`, `raise`, `catch`, `except`, `if `, `if(`, `else`, `switch`, `case `

- **Behavior change without tests** (`testing/untested-change`, default issue): New non-trivial logic, custom utilities, and bug fixes should arrive with tests that lock the behavior in; changed behavior should update the tests that describe it.
  - look-for: new or changed source functions with no test file changes in the diff.

- **Missing negative authorization test** (`testing/missing-auth-test`, default issue): A guarded endpoint needs a test proving unauthenticated and unauthorized requests are rejected, or the guard can be removed without any test failing.
  - look-for: new or changed protected endpoints with only authorized-caller tests.

- **Assertion checks too little** (`testing/weak-assertion`, default issue): Asserting only a return value, or that a collaborator was called without checking its arguments, lets real regressions pass. Integration tests should assert both the response and the resulting persisted state, including absence after deletes.
  - look-for: bare `toHaveBeenCalled()`; end-to-end tests with no data-store check; create tests that ignore the returned id.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`
  - triggers: `toHaveBeenCalled(`, `toBeCalled(`, `called`, `expect(`, `assert`, `should`

- **Test mocks away what it claims to prove** (`testing/mocked-subject`, default issue): A test that mocks the very behavior a fix or feature claims (the query, the guard, the registration) passes whether or not that behavior works. A test that calls a handler directly proves the handler, never how it's wired in.
  - look-for: a test named for a fix or feature that stubs the function or collaborator doing that work; tests of a new route, tool, or job that call its handler directly with no test through the router or registry.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`
  - triggers: `mock`, `jest.fn`, `vi.fn`, `spyOn`, `stub`, `patch(`, `fake`, `handler`
  - gate: skip when another test in the diff covers the same behavior unmocked.

- **Unreachable assertions** (`testing/unreachable-assertion`, default issue): Test code after an early return, skip, or inside a branch that never runs silently disables assertions; the test passes while checking nothing.
  - look-for: dead code in test files, conditional `expect` calls, leftover `.skip` or `.only`.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`
  - triggers: `.skip`, `.only`, `xit(`, `xdescribe(`, `fit(`, `fdescribe(`, `skip`, `return`, `if `, `if(`

- **Test does too much** (`testing/multi-concern-test`, default nit): One test asserting many unrelated behaviors fails with a vague signal and must be edited for every change. Split by behavior and group by the unit's public methods.
  - look-for: a single test with many unrelated expectations or a long step-by-step pipeline.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`

- **Leaked test data** (`testing/leaked-test-data`, default issue): Records a test inserts must be removed in that suite's own teardown, or later tests become order-dependent and flaky.
  - look-for: inserts in integration tests without matching cleanup in after hooks.
  - applies-to: `**/*.test.*`, `**/*.spec.*`, `**/__tests__/**`, `**/test/**`, `**/tests/**`, `**/e2e/**`, `**/*_test.*`, `**/test_*`
  - triggers: `create`, `insert`, `save(`, `seed`, `persist`, `add(`

## Process

- **Unrelated changes in the diff** (`process/unrelated-changes`, default issue): Files or hunks unrelated to the stated purpose, from a stale base, incidental renames, or stray edits, make the change harder to review and riskier to merge.
  - look-for: diffs in files the description never mentions; renames outside the change's scope.

- **Formatting churn** (`process/formatting-churn`, default nit): Large whitespace or quote-style changes usually mean a local formatter disagrees with the project config; they bury the real change.
  - look-for: many lines changed only in formatting.

- **UI change without visual evidence** (`process/missing-visual-evidence`, default nit): Changes to user-facing screens should include screenshots or a short recording so reviewers can validate them without running the branch.
  - look-for: diffs touching UI components where the description has no images or demo link.
  - applies-to: `**/*.jsx`, `**/*.tsx`, `**/*.vue`, `**/*.svelte`, `**/*.html`, `**/*.css`, `**/*.scss`, `**/*.less`, `**/components/**`, `**/pages/**`, `**/views/**`, `**/screens/**`, `**/*.swift`, `**/*.dart`

- **Placeholder or unclear user-facing copy** (`process/placeholder-copy`, default nit): Draft text, "coming soon" strings, and inconsistent punctuation or messages should be finalized before merge.
  - look-for: placeholder strings, mismatched validation messages across sibling fields.
  - triggers: `TODO`, `TBD`, `FIXME`, `XXX`, `coming soon`, `lorem`, `placeholder`, `message`
