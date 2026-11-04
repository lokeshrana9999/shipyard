#!/usr/bin/env bash
# A branch with a confirmed plan file whose ## flow section already draws the change. The PR-description
# diagram must reuse that flow instead of drawing a new one from the prompt alone.
#
# Ground truth (what is planted):
#   1. The plan's flow has two things the prompt leaves out: the stock check goes through an
#      "inventory service" (the prompt says "inventory DB"), and a "reserve stock row" step sits between
#      the check and saving the order. A diagram that reuses the plan carries both; one drawn from the
#      prompt alone has neither.
#   2. The destination is a PR description, which renders Mermaid, so the plan's ASCII becomes Mermaid.
#   3. The plan is approved; its hash covers the flow section, so the plan file itself must not be edited.
set -e
mkdir -p .claude/shipyard/plans src
cat > src/orders.ts <<'TS'
export async function createOrder(req: OrderRequest): Promise<OrderResult> {
  const stock = await inventory.check(req.sku, req.qty);
  if (!stock.available) return { status: 409, reason: 'short' };
  await inventory.reserve(req.sku, req.qty, req.orderId);
  await orders.save(req);
  return { status: 201, orderId: req.orderId };
}
TS
cat > .claude/shipyard/plans/stock-check.md <<'PLAN'
# Stock check on order creation

Orders are refused when stock is short, and stock is reserved before an order is saved.

Branch: stock-check. Ask: "check stock before saving an order". Rounds: 2 of 4.

## decisions

| # | Decision | Answer | Source | Why |
|---|---|---|---|---|
| D1 | Where stock is checked | the inventory service, not a direct DB read | recommendation accepted | one owner for stock rules |
| D2 | Short stock response | 409 with reason `short` | user | |
| D3 | Reservation | reserve a stock row before saving the order | user | avoids double-selling between check and save |

## out of scope

- Backorders: later plan.

## build steps

1. Call the inventory service's check from the order handler — check: a short sku returns 409
2. Reserve before save — check: a reserve row exists before the orders row

## acceptance checks

- An order for a short sku returns 409 and writes no orders row and no reserve row.
- An order for an in-stock sku returns 201 and writes one reserve row and one orders row.

## open questions

none

## flow

+----------+      +--------------+      +-------------------+
| checkout | ---> | POST /orders | ---> | inventory service |
| page     |      +--------------+      | stock check       |
+----------+                            +-------------------+
                                           |            |
                                     short |            | in stock
                                           v            v
                                  +-----------+   +-------------------+
                                  | 409 short |   | reserve stock row |
                                  +-----------+   +-------------------+
                                                          |
                                                          v
                                                  +-------------+
                                                  | save order  |
                                                  | 201 created |
                                                  +-------------+

## glossary

| Term | Means |
|---|---|
| short | requested qty exceeds available stock |

## approval

Approved: 2026-11-05 plan-hash 7c1e4a9b02d3

## deviations

none
PLAN
git init -q
git symbolic-ref HEAD refs/heads/stock-check
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Check stock before saving an order"
