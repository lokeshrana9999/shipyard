# Ledger and needs-you table

One row per launch, written by the wrapper, with every timestamp from the store or the wrapper's clock. The store can be a database table, an append-only JSON-lines file, or a sheet; the columns are the same.

## Ledger columns

| Column | Written by | Notes |
|---|---|---|
| run_id | wrapper | job, scheduled time, process id; deterministic enough to spot a double launch |
| job | wrapper | |
| scheduled_at, started_at, ended_at | store default or wrapper clock | never from the model's output |
| trigger | wrapper | which scheduler fired |
| status | outcome script | `ok`, `ok-flagged`, `idle`, `skipped`, `failed`, `limit`, `killed`, `needs-check` |
| reason | outcome script | `lease_held`, `stop_flag`, `daily_cap`, `dependency_down`, `cap_hit`, the limit text, the helper that failed |
| exit_code, result_kind | wrapper | the CLI's exit code and its result kind |
| units_claimed, units_done | result field; done-count script | the claim and the fact; their difference is `ok-flagged` |
| turns, cost, tokens_by_model | result fields | include subagents where the CLI reports them |
| session_id | result field | for reading the transcript |
| stderr_tail | wrapper | last lines of stderr; the first clue in a `failed` row |
| lesson | wrapper or a person | one line a later retro turns into a rule; the model may propose it, the wrapper records it as text |

Status meanings are in SKILL.md; the outcome rules that pick one are in wrapper.md.

A database store gives the timestamps a server default (`now()`), so even a row inserted by a helper the model calls can't carry a model-typed time. A file store gets its timestamps inside the append helper. Neither accepts a time as an argument.

## Needs-you table

| Column | Notes |
|---|---|
| id | the unit or target the question is about |
| question | the one fact a person must supply |
| first_seen | store default or helper clock |
| last_surfaced | updated each time the digest shows it |
| age | derived: now minus first_seen |
| severity | `blocking` (the unit can't proceed) or `advisory` |
| answered_at, answer | set by the person; the requeue script keys on `answered_at` |

Rules: a unit with an open question isn't takeable; the digest (H10) lists items by age with first-seen and escalates those past the settings' age to the channel; the same question is written once, keyed by id, so a question asked in ten summaries becomes one row with an age.

## Queries the review needs

- Cost per productive unit over the last five runs: sum of `cost` over sum of `units_done` where status is `ok` or `ok-flagged`.
- Idle share: rows with status `idle` or `skipped` over all rows. The target after hardening is under 10 percent.
- Silent deaths: dead-man alerts with no row in the same window. The target is 0.
- Lessons: every `lesson` since the last retro, for promotion into the prompt file, a script, or this skill.
