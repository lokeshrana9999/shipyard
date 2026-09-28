# design-tests settings (example: NestJS + Prisma multi-tenant API)

- test layers (exactly two; never propose a third):
  - service spec: `*.service.spec.ts`, pure branching in service methods, Prisma mocked with `mockDeep`
  - e2e: `*.e2e-spec.ts`, anything touching the HTTP auth guard or a real Prisma write
  - no standalone adapter, resilience, config, or pure-util spec files
  - never mock a throw the real library doesn't throw
  - the full testing strategy lives in root `CLAUDE.md` ("Testing Strategy"); re-read it rather than a paraphrase
- reference tests: helpers in `test/support/*.support.ts`; copy the `mockDeep` setup from the nearest existing service spec
- response shape: success bodies are `{ data: T }` (added by `ResponseTransformInterceptor`); name the exact fields of T
- error shape: `{ statusCode, timestamp, path, message, error }` (from `AllExceptionsFilter`)
- auth: routes guarded by `@Authenticated()` (JWT, optional role) or `@GoogleAuthenticated()`; no token answers 401, wrong role 403
- tenancy: resources live under `/api/organizations/:orgId/…`; cross-organization access answers 403
