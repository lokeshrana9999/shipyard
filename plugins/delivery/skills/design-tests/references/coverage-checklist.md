# Coverage checklist

Contents: scenarios per criterion · cases triggered by the code · API table default rows · priority

## Scenarios per criterion

For each acceptance criterion:

- **Main flow**: the behavior the criterion describes.
- **Boundaries**, listed first because they find the most defects per case. For every limit, test just below, at, and just above it (min−1, min, max, max+1). Put the values in an Examples table instead of writing near-duplicate scenarios.
- **Partitions**: one case per class of input that should behave the same (valid, invalid format, empty, null, missing).
- **State**: already exists, not found, deleted, and concurrent writes when the code uses a transaction or lock.

Write scenarios declaratively: `Given an order owned by another customer`, not `Given I POST to /orders with ownerId 42`. HTTP details and exact values belong in the API table. One behavior per scenario, three to five steps.

## Cases triggered by the code

Add these when the code does the thing in the left column:

| When the code… | Add |
|---|---|
| has a status or state field | every legal transition, and each illegal one rejected |
| catches errors or calls a dependency | one recovery case per error branch: the dependency fails, a partial write rolls back. Mishandled error paths cause most severe production failures |
| handles dates or times | a time-zone case, a daylight-saving boundary, and mixed naive and zone-aware values |
| lists resources | empty page, last page, out-of-range page or cursor, and the page-size limit |
| creates resources | a retried or duplicate submission |
| combines three or more inputs (filters, flags) | pairwise combinations, since most failures involve one or two inputs together |
| is a pure transform or validator | suggest one property test (round trip, invariant) |
| enforces a rate limit | the limit and the 429 after it |
| fetches a URL supplied by the caller | internal and metadata addresses rejected (SSRF) |

## API table default rows

Every endpoint gets these rows, tagged with the API security risk category they cover where one applies:

| Row | Expect | Tag |
|---|---|---|
| Main flow | exact status, exact response fields, exact data change | |
| No, expired, or malformed token | 401, no data change | authentication |
| Another user's or tenant's resource, on read **and** on write, including IDs nested in the path or body | the project's foreign-resource answer (404 or 403), no data change | object-level authz |
| Caller without the required role | 403, no data change | function-level authz |
| Body with fields the caller mustn't set (`role`, `ownerId`, `tenantId`, `isAdmin`) | fields ignored or request rejected, per the project | property-level authz (mass assignment) |
| Response carries only the documented fields | no extra fields, especially internal or other users' data | property-level authz (data exposure) |
| Invalid body | a 4xx with the project's error shape, never a 5xx | |
| Oversized body or page size | rejected or capped | resource consumption |
| Create, read, delete, read again | the second read is 404 | |

The foreign-resource answer comes from project settings, else from existing tests. If neither shows it, list it as an open question: returning 403 reveals that the resource exists.

## Priority

- **P0**: main flow of each criterion, and every authorization and tenancy row.
- **P1**: boundaries, state, and triggered cases.
- **P2**: everything else.
