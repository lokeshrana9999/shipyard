#!/usr/bin/env bash
# Shared fixture: a small orders service whose cancel endpoint breaks AC-2 and AC-3.
set -e
mkdir -p app tests
cat > app/orders.py <<'PY'
from app.framework import route, db


@route("POST", "/orders/<order_id>/cancel")
def cancel_order(session, order_id):
    order = db.orders.get(order_id)
    if order is None:
        return 404, {"error": "not_found", "message": "order not found"}
    order.status = "cancelled"
    order.cancelled_at = db.now()
    db.orders.save(order)
    return 200, {"id": order.id, "status": order.status, "cancelled_at": order.cancelled_at}
PY
cat > tests/test_orders.py <<'PY'
from tests.helpers import client_for, make_customer, make_order


def test_get_order_returns_owner_order(db):
    alice = make_customer(db, "alice")
    order = make_order(db, owner=alice, status="placed")
    res = client_for(alice).get(f"/orders/{order.id}")
    assert res.status == 200
    assert res.json == {"id": order.id, "status": "placed"}
PY
