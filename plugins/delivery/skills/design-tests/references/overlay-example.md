# Project settings example

A project keeps this at `.claude/shipyard/design-tests.md`. Every setting is optional; anything left out is inferred from the repo as SKILL.md step 2 describes.

```markdown
# design-tests settings

- test layers:
  - unit: `*.test.ts`, pure logic, external services mocked
  - integration: `*.int.test.ts`, real database and real auth
  - no other layers
- reference tests: unit `src/orders/orders.test.ts`, integration `test/orders.int.test.ts`
- response shape: success bodies are `{ data: T }`
- error shape: `{ status, code, message }`
- auth: session cookie; roles `customer`, `staff`, `admin`
- tenancy: every resource belongs to an account; cross-account access answers 404
- extra default rows: every write endpoint checks the audit-log entry
- document: write to `docs/test-designs/<feature>.md`
```

Settings about layers and fixtures matter most: without them the skill infers from existing tests, which works only if the project already has tests of each kind.
