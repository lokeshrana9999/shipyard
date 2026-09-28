# Test design document template

Sections in this order. The example rows show the level of detail; replace them.

````markdown
# Test design: <feature>

Spec: <path or ticket>. Code: <files read>.
Conventions: <each with its source>, e.g. layers `unit` (`*.test.ts`, mocks external services only) and `integration` (`*.int.test.ts`, real database), from `CONTRIBUTING.md`; fixtures from `test/helpers/db.ts`, seen in `orders.int.test.ts`.

## Divergences and open questions

| # | Spec says | Code does | Treated as |
|---|---|---|---|
| D-1 | AC-2: cancelling a shipped order is refused | `cancelOrder` cancels any status (`orders.ts:48`) | suspected bug; TC-2.2 expects the refusal |
| Q-1 | nothing on another customer's order | returns 404 | open question: confirm 404 over 403 |

## AC-1: a customer can place an order

Scenario: TC-1.1 place an order with items in stock (P0, integration: writes to the real database)
  Given a customer with a valid session
  And an item with stock 5
  When they order 2 of the item
  Then the order is created and stock drops to 3
Source: spec

Scenario Outline: TC-1.2 quantity limits (P1, unit: pure validation)
  When a customer orders <qty> of an item with stock 5
  Then the order is <result>
  Examples:
    | qty | result   |
    | 0   | rejected |
    | 1   | accepted |
    | 5   | accepted |
    | 6   | rejected |
Source: spec (limit), code (stock check in `validateOrder`)

## API tests

| TC | Endpoint | Method | Auth | Body | Status | Response | Data assertion | Tag |
|---|---|---|---|---|---|---|---|---|
| TC-1.1 | `/orders` | POST | customer | `{ itemId, qty: 2 }` | 201 | `{ id, status: "placed", total }` | 1 order row; item stock 5 → 3 | |
| TC-1.5 | `/orders/:id` | GET | other customer | none | 404 | project error shape | none | object-level authz |
| TC-1.6 | `/orders` | POST | customer | `{ itemId, qty: 1, status: "shipped" }` | 201 | `status: "placed"` | `status` from the body is ignored | property-level authz |

## Coverage matrix

| Criterion | Cases |
|---|---|
| AC-1 | TC-1.1 to TC-1.6 |
| AC-2 | TC-2.1, TC-2.2 |

## Fixtures and test data

- Integration layer: follow `test/orders.int.test.ts` for database setup and the customer session helper.
- Data: two customers in separate accounts; one item with stock 5; one order per status.
````

Rules for the sections:

- Each scenario line carries its ID, priority, and layer with the reason. Each scenario ends with its source tag.
- Put values in the API table; scenarios stay declarative.
- Leave out a section with nothing in it, except divergences: write "none found" there, so the reader knows the comparison happened.
