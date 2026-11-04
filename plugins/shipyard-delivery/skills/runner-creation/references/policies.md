# Watchdog and policies

The scripts around the wrapper that keep a runner honest when nobody is watching. Each is a committed helper, short, with one job.

Contents: reaper, retries and quarantine, per-target cooldown, needs-you ageing, yield governor, take validator.

## Reaper (watchdog)

Runs on its own schedule, every lease TTL or so, as the only process allowed to break a lease.

1. Read the lock. If its expiry is past and the run id's process is gone, remove the lock and write a `killed` row for that run id with reason `reaped`.
2. If the process is still alive past the expiry, kill the process tree (not only the parent: subagents and local servers leak as children), then do step 1.
3. Also mark any ledger row left in a running state past the TTL as `killed`.

A lease TTL without a reaper leaves rows stuck forever; a reaper without a tree kill leaves the expensive child running.

## Retries and quarantine

- Retry at one layer only, the wrapper's unit scheduler; a retry inside the prompt on top of it multiplies attempts.
- Count attempts per unit in the store. A unit at the attempts cap (default 3) is quarantined: it stays out of `takeable` and gets a needs-you row with the last error, so it surfaces once instead of being retried every launch.
- Back off between attempts with jitter, capped; separate permanent errors (a 4xx, a validation failure) from transient ones (timeouts, 5xx) and quarantine permanent ones after the first attempt.
- Retry only idempotent operations. A create carries an idempotency key, the unit id, so a retry after a half-finished run can't create twice.

## Per-target cooldown

A target that walls the runner (a block page, a captcha, a rate limit) on N consecutive runs (default 3) is put on cooldown for the settings' period (default 24 h). `takeable` skips its units until then, and the cooldown row names the wall, so the retro sees which targets burn the budget.

## Needs-you ageing and digest

- `needs-you-add.sh <id> "<question>"` writes the row once per id and marks the unit not takeable.
- The digest job lists open rows by age, oldest first, with first-seen; rows past the escalation age go to the channel the settings name. One list, not one notice per run, because a stop buried in a pile of run summaries isn't a stop.
- `requeue.sh` makes a unit takeable again only when its row has `answered_at`. There is no other path back.

## Yield governor

For batch and sweep runners, stop a batch early when new units per token (or per currency unit) over the last window falls under the threshold (default 1 unit per 100k tokens). The wrapper reads tokens from the result and units from the done count, so the model can't report yield. The stop is a row with reason `low_yield`, not a failure. After five runs, the wrapper's review query reports cost per productive unit, and the person decides whether the threshold moves.

## Take validator (eval and batch sweeps)

A take counts only when all of these hold, checked by script from the CLI's result and transcript, before the take is scored:

1. The skill or instruction under test was loaded (the transcript shows the load, or the result lists it).
2. One prompt per turn: no stacked prompts, no retries folded into the same take.
3. The run ended with a success kind and a zero exit, not a cap or an error.
4. The take's output file exists and is non-empty.

A take that fails the validator is recorded as `invalid` with the failing check and rerun once; two invalid takes for the same case go to needs-you.
