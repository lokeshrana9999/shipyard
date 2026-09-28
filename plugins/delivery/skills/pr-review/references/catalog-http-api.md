# HTTP API concerns

Load when the diff touches server request handlers, routes, middleware, authentication, authorization, or request and response schemas.
load-when: `**/routes/**`, `**/router/**`, `**/*.routes.*`, `**/*.router.*`, `**/controllers/**`, `**/*.controller.*`, `**/handlers/**`, `**/*.handler.*`, `**/middleware/**`, `**/*.middleware.*`, `**/*.guard.*`, `**/api/**`, `**/auth/**`, `**/webhooks/**`, `**/dto/**`, `**/*.dto.*`, `**/app/**/route.*`, `**/views.py`, `**/urls.py`

## Security

- **Missing ownership check** (`security/missing-ownership-check`, default bug): Reads and mutations on user- or tenant-scoped resources must verify the caller owns or may act on the target, on the server; hiding a button in the UI or trusting the id in the path is not authorization. Scope the query itself by owner or tenant where possible.
  - look-for: update or delete by id alone; permission checks present only in client code; where clauses without an owner or tenant condition.

- **Alternate path skips the scope check** (`security/secondary-read-unscoped`, default bug): A handler that validates tenant or ownership on its main lookup, then fetches by id alone on a fallback or enrichment path, gives callers a way around the check.
  - look-for: every call to the fetch helper in the handler, not just the happy path; a second lookup without the scope filter.

- **Unauthenticated webhook** (`security/unauthenticated-webhook`, default bug): A public webhook endpoint that changes state or enqueues work must verify the sender (signature against a shared secret or a validated key); otherwise anyone can trigger it, often with identities taken straight from the body.
  - look-for: a public POST handler with no guard or signature check that reads a user or account id from the payload.
  - triggers: `webhook`, `hook`, `callback`

- **Internal fields leaked in error responses** (`security/error-response-leak`, default bug): Spreading an unknown error object or its extra fields into an HTTP error response exposes internal state to clients. Build the response from an explicit allowlist.
  - look-for: `...rest`, `...error`, or a raw exception object placed into a response body.
  - triggers: `...`, `err`, `exception`

- **Mass assignment of reserved fields** (`security/mass-assignment`, default bug): Passing a request body straight into a create or update lets clients set fields they must not control (ids, owners, timestamps, audit fields, roles).
  - look-for: a request body spread into a persistence call without an allowlist or schema that strips reserved fields.
  - triggers: `body`, `...`, `req.`, `request.`, `input`, `dto`, `data`

- **Tenant inferred from email domain** (`security/email-domain-tenant`, default bug): Deriving an organization from the part after `@` lumps all users of a shared consumer provider into one tenant. Match against an explicit allowed-domain list or an existing membership.
  - look-for: `email.split('@')[1]` used to pick or join an organization.
  - triggers: `@`, `email`, `domain`

- **Sensitive endpoint without rate limiting** (`security/missing-rate-limit`, default issue): Sign-in, sign-up, verification-code, and other abuse-prone endpoints need rate limits.
  - look-for: new auth or public endpoints with no throttling guard.
  - triggers: `login`, `signin`, `sign-in`, `signup`, `sign-up`, `register`, `verify`, `otp`, `password`, `reset`, `token`, `code`, `auth`, `public`

## Correctness

- **Unvalidated request input** (`correctness/unvalidated-input`, default issue): Body, params, and query must be validated at the boundary by a schema, including domain constraints, max lengths on user strings, and trimming; imperative checks scattered in services are easy to miss.
  - look-for: handlers consuming raw input with no schema; manual presence checks in service code; user strings with no maximum length.
  - triggers: `body`, `params`, `Param`, `query`, `searchParams`, `formData`, `request.`, `req.`, `input`

- **Wrong status for failures** (`correctness/wrong-error-status`, default issue): A missing entity should produce a 404 and other failures their proper typed HTTP error, not a generic 500 or a silent success, so clients can react correctly.
  - look-for: `throw new Error` in request paths; lookups that return null through to a success response.
  - triggers: `throw`, `raise`, `null`, `None`, `undefined`, `status`, `find`, `get(`

- **Request-scoped state in a singleton** (`correctness/request-state-in-singleton`, default bug): Capturing a transaction handle, user, or other per-request value in a long-lived service's constructor or fields leaks it across concurrent requests. Read it at call time.
  - look-for: per-request values assigned to `this.` in a singleton's constructor or setter.
  - triggers: `this.`, `self.`, `constructor`, `__init__`

## Architecture

- **Raw persistence model returned** (`architecture/raw-entity-response`, default issue): Returning database entities directly from endpoints exposes internal fields and couples clients to the schema; returning more data than the caller uses costs extra queries and bandwidth. Map to a response shape with only the needed fields.
  - look-for: handlers returning ORM results unchanged; responses including relations the client never reads.
  - triggers: `return `, `json(`, `send(`, `include`, `relations`, `select`

- **Heavy work inside the request** (`architecture/sync-heavy-work`, default issue): Bulk operations and long-running jobs above a size threshold should be queued with retries, not run synchronously in the request handler where they time out and block workers.
  - look-for: loops over user-sized collections, embedding or export jobs, or external batch calls awaited inline in a handler.
  - triggers: `await`, `for`, `forEach`, `.map(`, `Promise.all`, `batch`, `bulk`, `export`, `embed`

- **Queued work reported as done** (`architecture/missing-pending-state`, default issue): An operation that enqueues work must return an accepted or pending status the client can poll, not immediate success.
  - look-for: a handler that enqueues a job and returns a completed result or 200 with final data.
  - triggers: `queue`, `enqueue`, `job`, `task`, `publish`, `dispatch`, `add(`

- **Unconditional read on a hot path** (`architecture/hot-path-read`, default issue): A new database read in middleware, an interceptor, or a handler every request passes through costs a round trip on every call. Use an existing cache or read, or gate it behind the cheap in-memory check that already decides the branch.
  - look-for: a new query in code that runs on every request.
  - triggers: `await`, `find`, `query`, `select`, `db`, `repo`, `load`, `get`
  - gate: flag only when the read is unconditional and per-request; a read inside an already narrow branch is fine.

- **Per-instance state in a scaled service** (`architecture/per-instance-state`, default issue): In-memory caches and rate-limit counters are multiplied or lost across replicas and restarts. Use the shared cache or a gateway-level limit.
  - look-for: a new module-level `Map` cache or in-process rate limiter in a horizontally scaled service.
  - triggers: `new Map(`, `new Set(`, `new WeakMap(`, `Map<`, `cache`, `limit`, `counter`, `= {}`, `= []`
  - gate: skip for single-instance tools or when no shared store exists in that runtime.

- **Undocumented schema field** (`architecture/undocumented-api-field`, default nit): When the project generates API docs from annotations, new request and response fields need them (including array item types), or the docs silently fall out of date.
  - look-for: new schema fields without the doc annotation their siblings carry.
