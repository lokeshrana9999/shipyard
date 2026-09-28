#!/usr/bin/env bash
# A medium diff (task reminders across backend, jobs, a migration, and React) plus pr-review settings.
#
# Ground truth. Planted bugs (everything else in the diff is intended to be correct):
#   1. correctness/unwired-definition: src/jobs/handlers/sendTaskReminders.ts is never added to
#      src/jobs/registry.ts (purgeExpiredReminders is), so reminders are never sent.
#   2. correctness/required-column-no-backfill: db/migrations/20260915_task_reminders.sql adds
#      project_members.reminders_enabled BOOLEAN NOT NULL with no default to a populated table.
#   3. correctness/stale-hook-deps: web/src/components/tasks/TaskRemindersPanel.tsx loads with deps []
#      behind an eslint-disable; the drawer stays mounted across tasks, so switching tasks shows stale reminders.
# Decoy (must NOT be reported): web/src/analytics/trackReminderEvent.ts has an intentionally empty catch
#   around a best-effort telemetry beacon, with a comment saying so; the swallowed-catch gate exempts it.
# Settings only the skill reads: findings cap 5 (.claude/shipyard/pr-review.md).
set -e
mkdir -p .claude/shipyard
cat > .claude/shipyard/pr-review.md <<'SETTINGS'
# pr-review settings

- base branch: main
- findings cap: 5
SETTINGS
cat > branch.diff <<'DIFF'
diff --git a/db/migrations/20260915_task_reminders.sql b/db/migrations/20260915_task_reminders.sql
new file mode 100644
--- /dev/null
+++ b/db/migrations/20260915_task_reminders.sql
@@ -0,0 +1,15 @@
+CREATE TABLE task_reminders (
+  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
+  task_id UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
+  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
+  offset_minutes INTEGER NOT NULL CHECK (offset_minutes > 0),
+  claimed_at TIMESTAMPTZ,
+  sent_at TIMESTAMPTZ,
+  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
+  UNIQUE (task_id, user_id, offset_minutes)
+);
+
+CREATE INDEX task_reminders_pending_idx ON task_reminders (task_id) WHERE sent_at IS NULL;
+CREATE INDEX task_reminders_sent_at_idx ON task_reminders (sent_at) WHERE sent_at IS NOT NULL;
+
+ALTER TABLE project_members ADD COLUMN reminders_enabled BOOLEAN NOT NULL;
diff --git a/src/tasks/reminders/reminder.types.ts b/src/tasks/reminders/reminder.types.ts
new file mode 100644
--- /dev/null
+++ b/src/tasks/reminders/reminder.types.ts
@@ -0,0 +1,18 @@
+export const REMINDER_OFFSETS_MINUTES = [15, 60, 1440] as const;
+
+export interface TaskReminder {
+  id: string;
+  taskId: string;
+  userId: string;
+  offsetMinutes: number;
+  sentAt: Date | null;
+  createdAt: Date;
+}
+
+export interface DueReminder {
+  id: string;
+  userId: string;
+  taskId: string;
+  taskTitle: string;
+  dueAt: Date;
+}
diff --git a/src/tasks/reminders/reminder.repository.ts b/src/tasks/reminders/reminder.repository.ts
new file mode 100644
--- /dev/null
+++ b/src/tasks/reminders/reminder.repository.ts
@@ -0,0 +1,86 @@
+import { db } from '../../db/client';
+import type { DueReminder, TaskReminder } from './reminder.types';
+
+const REMINDER_COLUMNS = `
+  id,
+  task_id AS "taskId",
+  user_id AS "userId",
+  offset_minutes AS "offsetMinutes",
+  sent_at AS "sentAt",
+  created_at AS "createdAt"
+`;
+
+// A claim older than this is treated as abandoned by a crashed run and can be picked up again.
+const CLAIM_TIMEOUT = '10 minutes';
+
+export const reminderRepository = {
+  async listForTask(taskId: string, userId: string): Promise<TaskReminder[]> {
+    const { rows } = await db.query<TaskReminder>(
+      `SELECT ${REMINDER_COLUMNS}
+         FROM task_reminders
+        WHERE task_id = $1 AND user_id = $2
+        ORDER BY offset_minutes`,
+      [taskId, userId],
+    );
+    return rows;
+  },
+
+  async upsert(taskId: string, userId: string, offsetMinutes: number): Promise<TaskReminder> {
+    const { rows } = await db.query<TaskReminder>(
+      `INSERT INTO task_reminders (task_id, user_id, offset_minutes)
+       VALUES ($1, $2, $3)
+       ON CONFLICT (task_id, user_id, offset_minutes)
+       DO UPDATE SET offset_minutes = EXCLUDED.offset_minutes
+       RETURNING ${REMINDER_COLUMNS}`,
+      [taskId, userId, offsetMinutes],
+    );
+    return rows[0];
+  },
+
+  async deleteForUser(id: string, userId: string): Promise<boolean> {
+    const { rowCount } = await db.query(
+      'DELETE FROM task_reminders WHERE id = $1 AND user_id = $2',
+      [id, userId],
+    );
+    return (rowCount ?? 0) > 0;
+  },
+
+  async claimDue(now: Date, limit: number): Promise<DueReminder[]> {
+    const { rows } = await db.query<DueReminder>(
+      `UPDATE task_reminders r
+          SET claimed_at = $1::timestamptz
+         FROM tasks t
+        WHERE t.id = r.task_id
+          AND r.id IN (
+            SELECT r2.id
+              FROM task_reminders r2
+              JOIN tasks t2 ON t2.id = r2.task_id
+              JOIN project_members m ON m.project_id = t2.project_id AND m.user_id = r2.user_id
+             WHERE r2.sent_at IS NULL
+               AND (r2.claimed_at IS NULL OR r2.claimed_at < $1::timestamptz - $3::interval)
+               AND m.reminders_enabled
+               AND t2.completed_at IS NULL
+               AND t2.due_at > $1::timestamptz
+               AND t2.due_at - make_interval(mins => r2.offset_minutes) <= $1::timestamptz
+             ORDER BY t2.due_at
+             LIMIT $2
+             FOR UPDATE OF r2 SKIP LOCKED
+          )
+        RETURNING r.id, r.user_id AS "userId", r.task_id AS "taskId", t.title AS "taskTitle", t.due_at AS "dueAt"`,
+      [now, limit, CLAIM_TIMEOUT],
+    );
+    return rows;
+  },
+
+  async markSent(id: string, sentAt: Date): Promise<void> {
+    await db.query('UPDATE task_reminders SET sent_at = $2 WHERE id = $1', [id, sentAt]);
+  },
+
+  async deleteSentBefore(cutoff: Date): Promise<number> {
+    const { rowCount } = await db.query(
+      'DELETE FROM task_reminders WHERE sent_at IS NOT NULL AND sent_at < $1',
+      [cutoff],
+    );
+    return rowCount ?? 0;
+  },
+};
diff --git a/src/jobs/handlers/sendTaskReminders.ts b/src/jobs/handlers/sendTaskReminders.ts
new file mode 100644
--- /dev/null
+++ b/src/jobs/handlers/sendTaskReminders.ts
@@ -0,0 +1,26 @@
+import type { JobContext, JobDefinition } from '../types';
+import { reminderRepository } from '../../tasks/reminders/reminder.repository';
+
+const BATCH_SIZE = 100;
+
+export const sendTaskReminders: JobDefinition = {
+  name: 'task-reminders.send',
+  schedule: '*/5 * * * *',
+  async run(ctx: JobContext) {
+    const due = await reminderRepository.claimDue(ctx.now, BATCH_SIZE);
+    for (const reminder of due) {
+      await ctx.notifier.send({
+        userId: reminder.userId,
+        template: 'task-reminder',
+        data: {
+          taskId: reminder.taskId,
+          taskTitle: reminder.taskTitle,
+          dueAt: reminder.dueAt.toISOString(),
+        },
+      });
+      await reminderRepository.markSent(reminder.id, ctx.now);
+    }
+    ctx.logger.info('task reminders sent', { count: due.length });
+    return { sent: due.length };
+  },
+};
diff --git a/src/jobs/handlers/purgeExpiredReminders.ts b/src/jobs/handlers/purgeExpiredReminders.ts
new file mode 100644
--- /dev/null
+++ b/src/jobs/handlers/purgeExpiredReminders.ts
@@ -0,0 +1,16 @@
+import type { JobContext, JobDefinition } from '../types';
+import { reminderRepository } from '../../tasks/reminders/reminder.repository';
+
+const RETENTION_DAYS = 30;
+const DAY_MS = 24 * 60 * 60 * 1000;
+
+export const purgeExpiredReminders: JobDefinition = {
+  name: 'task-reminders.purge',
+  schedule: '15 3 * * *',
+  async run(ctx: JobContext) {
+    const cutoff = new Date(ctx.now.getTime() - RETENTION_DAYS * DAY_MS);
+    const removed = await reminderRepository.deleteSentBefore(cutoff);
+    ctx.logger.info('sent task reminders purged', { removed });
+    return { removed };
+  },
+};
diff --git a/src/jobs/handlers/sendTaskReminders.test.ts b/src/jobs/handlers/sendTaskReminders.test.ts
new file mode 100644
--- /dev/null
+++ b/src/jobs/handlers/sendTaskReminders.test.ts
@@ -0,0 +1,63 @@
+import { beforeEach, describe, expect, it, vi } from 'vitest';
+import type { JobContext } from '../types';
+import { reminderRepository } from '../../tasks/reminders/reminder.repository';
+import { sendTaskReminders } from './sendTaskReminders';
+
+vi.mock('../../tasks/reminders/reminder.repository', () => ({
+  reminderRepository: { claimDue: vi.fn(), markSent: vi.fn() },
+}));
+
+const now = new Date('2026-09-01T09:00:00Z');
+
+const dueReminder = {
+  id: 'r1',
+  userId: 'u1',
+  taskId: 't1',
+  taskTitle: 'Draft budget',
+  dueAt: new Date('2026-09-01T09:10:00Z'),
+};
+
+function makeContext(send: ReturnType<typeof vi.fn>): JobContext {
+  return { now, notifier: { send }, logger: { info: vi.fn(), error: vi.fn() } } as unknown as JobContext;
+}
+
+describe('sendTaskReminders', () => {
+  beforeEach(() => {
+    vi.mocked(reminderRepository.claimDue).mockReset();
+    vi.mocked(reminderRepository.markSent).mockReset().mockResolvedValue(undefined);
+  });
+
+  it('notifies the user for each due reminder and marks it sent', async () => {
+    vi.mocked(reminderRepository.claimDue).mockResolvedValue([dueReminder]);
+    const send = vi.fn().mockResolvedValue(undefined);
+
+    const result = await sendTaskReminders.run(makeContext(send));
+
+    expect(reminderRepository.claimDue).toHaveBeenCalledWith(now, 100);
+    expect(send).toHaveBeenCalledWith({
+      userId: 'u1',
+      template: 'task-reminder',
+      data: { taskId: 't1', taskTitle: 'Draft budget', dueAt: '2026-09-01T09:10:00.000Z' },
+    });
+    expect(reminderRepository.markSent).toHaveBeenCalledWith('r1', now);
+    expect(result).toEqual({ sent: 1 });
+  });
+
+  it('leaves the reminder unsent when the notification fails', async () => {
+    vi.mocked(reminderRepository.claimDue).mockResolvedValue([dueReminder]);
+    const send = vi.fn().mockRejectedValue(new Error('mail relay unavailable'));
+
+    await expect(sendTaskReminders.run(makeContext(send))).rejects.toThrow('mail relay unavailable');
+    expect(reminderRepository.markSent).not.toHaveBeenCalled();
+  });
+
+  it('sends nothing when no reminders are due', async () => {
+    vi.mocked(reminderRepository.claimDue).mockResolvedValue([]);
+    const send = vi.fn();
+
+    const result = await sendTaskReminders.run(makeContext(send));
+
+    expect(send).not.toHaveBeenCalled();
+    expect(result).toEqual({ sent: 0 });
+  });
+});
diff --git a/src/jobs/registry.ts b/src/jobs/registry.ts
--- a/src/jobs/registry.ts
+++ b/src/jobs/registry.ts
@@ -1,9 +1,11 @@
 import type { JobDefinition } from './types';
 import { rollupProjectStats } from './handlers/rollupProjectStats';
 import { archiveStaleProjects } from './handlers/archiveStaleProjects';
+import { purgeExpiredReminders } from './handlers/purgeExpiredReminders';
 
 // The scheduler loads every job from this map at startup.
 export const jobRegistry: Record<string, JobDefinition> = {
   [rollupProjectStats.name]: rollupProjectStats,
   [archiveStaleProjects.name]: archiveStaleProjects,
+  [purgeExpiredReminders.name]: purgeExpiredReminders,
 };
diff --git a/src/api/routes/reminders.ts b/src/api/routes/reminders.ts
new file mode 100644
--- /dev/null
+++ b/src/api/routes/reminders.ts
@@ -0,0 +1,72 @@
+import { Router } from 'express';
+import { z } from 'zod';
+import { requireAuth } from '../middleware/requireAuth';
+import { taskRepository } from '../../tasks/task.repository';
+import { reminderRepository } from '../../tasks/reminders/reminder.repository';
+import { REMINDER_OFFSETS_MINUTES, type TaskReminder } from '../../tasks/reminders/reminder.types';
+
+const allowedOffsets: readonly number[] = REMINDER_OFFSETS_MINUTES;
+
+const createReminderSchema = z.object({
+  offsetMinutes: z
+    .number()
+    .int()
+    .refine((value) => allowedOffsets.includes(value), {
+      message: `offsetMinutes must be one of ${allowedOffsets.join(', ')}`,
+    }),
+});
+
+function toReminderDto(reminder: TaskReminder) {
+  return {
+    id: reminder.id,
+    offsetMinutes: reminder.offsetMinutes,
+    sentAt: reminder.sentAt ? reminder.sentAt.toISOString() : null,
+  };
+}
+
+export const remindersRouter = Router();
+
+remindersRouter.get('/tasks/:taskId/reminders', requireAuth, async (req, res, next) => {
+  try {
+    const task = await taskRepository.findForMember(req.params.taskId, req.user.id);
+    if (!task) {
+      return res.status(404).json({ error: 'Task not found' });
+    }
+    const reminders = await reminderRepository.listForTask(task.id, req.user.id);
+    return res.json(reminders.map(toReminderDto));
+  } catch (err) {
+    return next(err);
+  }
+});
+
+remindersRouter.post('/tasks/:taskId/reminders', requireAuth, async (req, res, next) => {
+  try {
+    const parsed = createReminderSchema.safeParse(req.body);
+    if (!parsed.success) {
+      return res.status(400).json({ error: parsed.error.issues[0]?.message ?? 'Invalid reminder' });
+    }
+    const task = await taskRepository.findForMember(req.params.taskId, req.user.id);
+    if (!task) {
+      return res.status(404).json({ error: 'Task not found' });
+    }
+    if (!task.dueAt) {
+      return res.status(422).json({ error: 'Task has no due date' });
+    }
+    const reminder = await reminderRepository.upsert(task.id, req.user.id, parsed.data.offsetMinutes);
+    return res.status(201).json(toReminderDto(reminder));
+  } catch (err) {
+    return next(err);
+  }
+});
+
+remindersRouter.delete('/reminders/:id', requireAuth, async (req, res, next) => {
+  try {
+    const deleted = await reminderRepository.deleteForUser(req.params.id, req.user.id);
+    if (!deleted) {
+      return res.status(404).json({ error: 'Reminder not found' });
+    }
+    return res.status(204).end();
+  } catch (err) {
+    return next(err);
+  }
+});
diff --git a/src/api/routes/index.ts b/src/api/routes/index.ts
--- a/src/api/routes/index.ts
+++ b/src/api/routes/index.ts
@@ -1,8 +1,10 @@
 import { Router } from 'express';
 import { projectsRouter } from './projects';
 import { tasksRouter } from './tasks';
+import { remindersRouter } from './reminders';
 
 export const apiRouter = Router();
 
 apiRouter.use(projectsRouter);
 apiRouter.use(tasksRouter);
+apiRouter.use(remindersRouter);
diff --git a/web/src/api/reminders.ts b/web/src/api/reminders.ts
new file mode 100644
--- /dev/null
+++ b/web/src/api/reminders.ts
@@ -0,0 +1,37 @@
+export interface TaskReminder {
+  id: string;
+  offsetMinutes: number;
+  sentAt: string | null;
+}
+
+async function errorFrom(res: Response): Promise<Error> {
+  const body = (await res.json().catch(() => null)) as { error?: string } | null;
+  return new Error(body?.error ?? `Request failed with status ${res.status}`);
+}
+
+export async function listReminders(taskId: string, signal?: AbortSignal): Promise<TaskReminder[]> {
+  const res = await fetch(`/api/tasks/${encodeURIComponent(taskId)}/reminders`, { signal });
+  if (!res.ok) {
+    throw await errorFrom(res);
+  }
+  return (await res.json()) as TaskReminder[];
+}
+
+export async function createReminder(taskId: string, offsetMinutes: number): Promise<TaskReminder> {
+  const res = await fetch(`/api/tasks/${encodeURIComponent(taskId)}/reminders`, {
+    method: 'POST',
+    headers: { 'Content-Type': 'application/json' },
+    body: JSON.stringify({ offsetMinutes }),
+  });
+  if (!res.ok) {
+    throw await errorFrom(res);
+  }
+  return (await res.json()) as TaskReminder;
+}
+
+export async function deleteReminder(id: string): Promise<void> {
+  const res = await fetch(`/api/reminders/${encodeURIComponent(id)}`, { method: 'DELETE' });
+  if (!res.ok) {
+    throw await errorFrom(res);
+  }
+}
diff --git a/web/src/analytics/trackReminderEvent.ts b/web/src/analytics/trackReminderEvent.ts
new file mode 100644
--- /dev/null
+++ b/web/src/analytics/trackReminderEvent.ts
@@ -0,0 +1,12 @@
+import { ANALYTICS_EVENTS_URL } from './config';
+
+export type ReminderEventName = 'reminder_added' | 'reminder_removed';
+
+export function trackReminderEvent(name: ReminderEventName, taskId: string): void {
+  try {
+    navigator.sendBeacon(ANALYTICS_EVENTS_URL, JSON.stringify({ name, taskId, at: Date.now() }));
+  } catch {
+    // Best-effort telemetry: sendBeacon can throw (unsupported browser, oversized payload), and a lost
+    // analytics event must never break the reminders UI, so the failure is dropped on purpose.
+  }
+}
diff --git a/web/src/components/tasks/TaskRemindersPanel.tsx b/web/src/components/tasks/TaskRemindersPanel.tsx
new file mode 100644
--- /dev/null
+++ b/web/src/components/tasks/TaskRemindersPanel.tsx
@@ -0,0 +1,120 @@
+import { useEffect, useState } from 'react';
+import { createReminder, deleteReminder, listReminders, type TaskReminder } from '../../api/reminders';
+import { trackReminderEvent } from '../../analytics/trackReminderEvent';
+
+const OFFSET_OPTIONS = [
+  { minutes: 15, label: '15 minutes before' },
+  { minutes: 60, label: '1 hour before' },
+  { minutes: 1440, label: '1 day before' },
+];
+
+function labelFor(minutes: number): string {
+  return OFFSET_OPTIONS.find((option) => option.minutes === minutes)?.label ?? `${minutes} minutes before`;
+}
+
+type LoadStatus = 'loading' | 'ready' | 'error';
+
+interface TaskRemindersPanelProps {
+  taskId: string;
+}
+
+export function TaskRemindersPanel({ taskId }: TaskRemindersPanelProps) {
+  const [reminders, setReminders] = useState<TaskReminder[]>([]);
+  const [status, setStatus] = useState<LoadStatus>('loading');
+  const [offset, setOffset] = useState(OFFSET_OPTIONS[0].minutes);
+  const [saving, setSaving] = useState(false);
+  const [actionError, setActionError] = useState<string | null>(null);
+
+  useEffect(() => {
+    const controller = new AbortController();
+    setStatus('loading');
+    listReminders(taskId, controller.signal)
+      .then((rows) => {
+        setReminders(rows);
+        setStatus('ready');
+      })
+      .catch((err: unknown) => {
+        if (err instanceof DOMException && err.name === 'AbortError') return;
+        setStatus('error');
+      });
+    return () => controller.abort();
+    // Load once when the panel opens.
+    // eslint-disable-next-line react-hooks/exhaustive-deps
+  }, []);
+
+  async function handleAdd() {
+    setSaving(true);
+    setActionError(null);
+    try {
+      const created = await createReminder(taskId, offset);
+      setReminders((current) =>
+        [...current.filter((reminder) => reminder.id !== created.id), created].sort(
+          (a, b) => a.offsetMinutes - b.offsetMinutes,
+        ),
+      );
+      trackReminderEvent('reminder_added', taskId);
+    } catch (err) {
+      setActionError(err instanceof Error ? err.message : 'Could not save the reminder');
+    } finally {
+      setSaving(false);
+    }
+  }
+
+  async function handleRemove(id: string) {
+    setActionError(null);
+    try {
+      await deleteReminder(id);
+      setReminders((current) => current.filter((reminder) => reminder.id !== id));
+      trackReminderEvent('reminder_removed', taskId);
+    } catch (err) {
+      setActionError(err instanceof Error ? err.message : 'Could not remove the reminder');
+    }
+  }
+
+  if (status === 'loading') {
+    return <p className="reminders-panel__status">Loading reminders...</p>;
+  }
+  if (status === 'error') {
+    return <p className="reminders-panel__status" role="alert">Reminders could not be loaded.</p>;
+  }
+
+  return (
+    <section className="reminders-panel" aria-label="Reminders">
+      {reminders.length === 0 ? (
+        <p className="reminders-panel__empty">No reminders yet.</p>
+      ) : (
+        <ul className="reminders-panel__list">
+          {reminders.map((reminder) => (
+            <li key={reminder.id}>
+              <span>{labelFor(reminder.offsetMinutes)}</span>
+              {reminder.sentAt && <span className="reminders-panel__sent">Sent</span>}
+              <button type="button" onClick={() => handleRemove(reminder.id)}>
+                Remove
+              </button>
+            </li>
+          ))}
+        </ul>
+      )}
+      <div className="reminders-panel__add">
+        <label>
+          Remind me
+          <select value={offset} onChange={(event) => setOffset(Number(event.target.value))}>
+            {OFFSET_OPTIONS.map((option) => (
+              <option key={option.minutes} value={option.minutes}>
+                {option.label}
+              </option>
+            ))}
+          </select>
+        </label>
+        <button type="button" onClick={handleAdd} disabled={saving}>
+          {saving ? 'Saving...' : 'Add reminder'}
+        </button>
+      </div>
+      {actionError && (
+        <p className="reminders-panel__error" role="alert">
+          {actionError}
+        </p>
+      )}
+    </section>
+  );
+}
diff --git a/web/src/components/tasks/TaskDetailDrawer.tsx b/web/src/components/tasks/TaskDetailDrawer.tsx
--- a/web/src/components/tasks/TaskDetailDrawer.tsx
+++ b/web/src/components/tasks/TaskDetailDrawer.tsx
@@ -1,3 +1,4 @@
 import { Drawer } from '../ui/Drawer';
 import { TaskStatusBadge } from './TaskStatusBadge';
+import { TaskRemindersPanel } from './TaskRemindersPanel';
 import type { Task } from '../../api/tasks';
@@ -28,11 +29,17 @@ export function TaskDetailDrawer({ tasks, selectedTaskId, onClose }: TaskDetailDrawerProps) {
   // The drawer stays mounted while the user moves between tasks in the list.
   const task = tasks.find((candidate) => candidate.id === selectedTaskId);
   if (!task) return null;
 
   return (
     <Drawer open onClose={onClose} title={task.title}>
       <TaskStatusBadge status={task.status} />
       <p className="task-detail__description">{task.description}</p>
+      {task.dueAt && (
+        <>
+          <h3>Reminders</h3>
+          <TaskRemindersPanel taskId={task.id} />
+        </>
+      )}
     </Drawer>
   );
 }
DIFF
