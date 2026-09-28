#!/usr/bin/env bash
# An Express + Prisma API. main has an Order model and its initial migration. The feature branch adds an
# OrderStatus enum and a status field to Order, a route and tests that use it, and no migration for the change.
set -e
mkdir -p src prisma/migrations/20260801000000_init .claude/shipyard
cat > .claude/shipyard/ship.md <<'MD'
# ship settings

- base branch: main
- overrides:
  - demo: skip
MD
cat > package.json <<'JSON'
{ "name": "orders-api", "private": true, "scripts": { "start": "node dist/server.js", "build": "tsc", "test": "jest" },
  "dependencies": { "@prisma/client": "^5.0.0", "express": "^4.19.0" }, "devDependencies": { "prisma": "^5.0.0" } }
JSON
cat > prisma/schema.prisma <<'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Order {
  id         String   @id @default(uuid())
  customerId String   @map("customer_id")
  totalCents Int      @map("total_cents")
  createdAt  DateTime @default(now()) @map("created_at")

  @@map("orders")
}
PRISMA
cat > prisma/migrations/migration_lock.toml <<'TOML'
provider = "postgresql"
TOML
cat > prisma/migrations/20260801000000_init/migration.sql <<'SQL'
-- CreateTable
CREATE TABLE "orders" (
    "id" TEXT NOT NULL,
    "customer_id" TEXT NOT NULL,
    "total_cents" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);
SQL
cat > src/server.ts <<'TS'
import express from 'express';
import { ordersRouter } from './orders';

const app = express();
app.use(express.json());
app.use('/orders', ordersRouter);
app.listen(Number(process.env.PORT ?? 3000));
TS
cat > src/orders.ts <<'TS'
import { Router } from 'express';
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
export const ordersRouter = Router();

ordersRouter.get('/:id', async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'not found' });
  res.json(order);
});
TS
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Orders API with initial migration"

git checkout -q -b feature/order-status
cat > prisma/schema.prisma <<'PRISMA'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum OrderStatus {
  PENDING
  PAID
  SHIPPED
  CANCELLED

  @@map("order_status")
}

model Order {
  id         String      @id @default(uuid())
  customerId String      @map("customer_id")
  totalCents Int         @map("total_cents")
  status     OrderStatus @default(PENDING)
  createdAt  DateTime    @default(now()) @map("created_at")

  @@map("orders")
}
PRISMA
cat > src/order-status.ts <<'TS'
export type OrderStatus = 'PENDING' | 'PAID' | 'SHIPPED' | 'CANCELLED';

const allowed: Record<OrderStatus, OrderStatus[]> = {
  PENDING: ['PAID', 'CANCELLED'],
  PAID: ['SHIPPED', 'CANCELLED'],
  SHIPPED: [],
  CANCELLED: [],
};

export function canTransition(from: OrderStatus, to: OrderStatus): boolean {
  return allowed[from].includes(to);
}
TS
cat > src/order-status.test.ts <<'TS'
import { canTransition } from './order-status';
test('pending can be paid', () => expect(canTransition('PENDING', 'PAID')).toBe(true));
test('shipped is final', () => expect(canTransition('SHIPPED', 'CANCELLED')).toBe(false));
test('paid can ship', () => expect(canTransition('PAID', 'SHIPPED')).toBe(true));
TS
cat > src/orders.ts <<'TS'
import { Router } from 'express';
import { PrismaClient } from '@prisma/client';
import { canTransition, OrderStatus } from './order-status';

export const prisma = new PrismaClient();
export const ordersRouter = Router();

ordersRouter.get('/:id', async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'not found' });
  res.json(order);
});

ordersRouter.patch('/:id/status', async (req, res) => {
  const to = req.body?.status as OrderStatus;
  const order = await prisma.order.findUnique({ where: { id: req.params.id } });
  if (!order) return res.status(404).json({ error: 'not found' });
  if (!canTransition(order.status as OrderStatus, to)) return res.status(409).json({ error: 'invalid transition' });
  res.json(await prisma.order.update({ where: { id: order.id }, data: { status: to } }));
});
TS
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "Add order status with transitions and PATCH /orders/:id/status (tests pass)"
