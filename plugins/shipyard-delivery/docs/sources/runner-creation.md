# Sources: runner-creation

Provenance for `skills/runner-creation/`. Kept outside the skill folder so it never loads into context.

`runner-creation` is new in the factory v3 plan (plan item R1, section 4 of the owner's plan of 2026-11-04). Its rules come from one retro over 18 batches of the owner's own unattended-runner and eval-sweep transcripts (local evidence, 2026-10 to 2026-11) and from the research note `r3-runners.md` (2026-11-04), which read the Claude Code docs and the SRE and batch-processing literature. The skill body is platform-agnostic by the owner's decision (plan section 6, decision 5); vendor flags sit only in `references/platforms.md` and in overlays under `examples/`.

## Where each rule came from

| Rule in SKILL.md | Basis |
|---|---|
| lease before model; skip, never wait; only the reaper breaks a lease | Google SRE book ch. 24 (favor skipping over double launches; record start and end under a lock): https://sre.google/sre-book/distributed-periodic-scheduling/. Local: 22+ scheduler collisions across 4 batches, each loser burning a session on a conflict |
| nothing to do costs nothing; "pending" means takeable | Local: 71 of 111 sessions (64 percent) did no work: cap-blocked, empty queue, conflict, dependency down, or auth; 26 idle runs cost about 220k output tokens |
| the model asserts; scripts decide (timestamps, caps, counts) | Local: model-typed timestamps rejected in 15 sessions (400 and 403s); caps 6/5 and 7/5 uncorrected for 12+ runs; one "ok" with 0 units; 3 of 3 null read-backs. Server-default timestamps are standard database practice, not tied to one source |
| a failed helper fails the run | Local: two `ok` rows next to a failed helper; wrong store write counted as success |
| every launch leaves a trace; dead-man switch | Healthchecks.io docs (start, success, fail pings with a grace time): https://healthchecks.io/docs/. Local: 5 sessions killed by limit or auth death with no row; 4 silent misses in one batch |
| one scheduler per job | SRE book ch. 24; local collisions above |
| committed one-op scripts; dry run with 0 denials | Local: about 109 permission blocks in 20 of 21 headless sessions versus 0 interactive, on compound or quoted shell; glue rewritten in 5 of 5 sessions with quoting and line-ending bugs. Claude Code headless docs on deny-by-default modes: https://code.claude.com/docs/en/headless |
| caps outside the prompt, including subagents, with headroom | Claude Code cost-tracking docs (subagent spend counts, overshoot by one response): https://code.claude.com/docs/en/agent-sdk/cost-tracking. Local: about 90 percent of run cost in subagents; 19 subagents above 100k tokens. Practitioner posts on cost circuit breakers (anecdotal): https://dev.to/sebastian_chedal/the-cost-circuit-breaker-how-we-prevent-runaway-spending-across-9-ai-agents-4i5k |
| yield governor | No published source found; the idea comes from the local evidence (about 24k tokens per stored row, falling yield late in each batch) |
| needs-you items wait for a fact; ageing and escalation | Local: one question listed in 10+ summaries unanswered; 3 tasks run twice; a task starved 29 h; 14 unread run summaries hid a stop |
| nothing is scheduled until the gates pass | House default: enabling a schedule starts unattended spend, so it is the one STOP — WAIT in the skill |
| retries bounded, one layer, idempotency keys; quarantine | AWS Builders' Library on timeouts, retries, and backoff with jitter: https://builder.aws.com/content/3EumjoZascWd1oZiEgL8ORlv3qE/timeouts-retries-and-backoff-with-jitter. Poison-message handling (attempt cap, dead-letter with reason): https://learn.microsoft.com/en-us/previous-versions/dotnet/netframework-3.0/ms789028(v=vs.85) |
| reaper with tree kill | Local: 6 rows stuck `running`, never reaped; a leaked subagent kept a session open 24 h; 2 orphan runners |
| per-target cooldown | Local: two walled targets retried 5 of 5 days |
| idle fast path, lazy docs, cached prefix | Local: the same docs reread in 24 of 24 runner sessions. Prompt-caching for runs more than 5 minutes apart: https://code.claude.com/docs/en/agent-sdk/cost-tracking |
| `lesson` column | Local: lessons recurring in free-text summaries with no structured home; promoted into a column reviewed at the retro (plan item F1) |
| take validator | Local: an eval take counted although the skill under test never loaded |
| status vocabulary (`ok`, `ok-flagged`, `idle`, `skipped`, `failed`, `limit`, `killed`, `needs-check`) | House default, from the outcome rules in `references/wrapper.md`; `ok-flagged` added so a claim-versus-facts mismatch is visible without failing a run that did work |

## Basis of the defaults in overlay-example.md

| Default | Basis |
|---|---|
| lease TTL twice the wall-clock cap | house default: long enough that a run at the cap never looks stale, short enough that the reaper frees a dead lock within one schedule slot |
| dead-man grace: wall-clock cap plus 5 min | Healthchecks.io practice of sizing grace to run duration, plus scheduler start jitter of a few minutes (desktop and hosted schedulers both document late starts) |
| 10 turns, 1.00 USD, 15 min per run | house default; the owner's runs held under a 100-minute window and a 15-job cap, which supports hard external limits, and smaller caps per run cost less when a run is wasted |
| 3 attempts per unit then quarantine | convention from poison-message handling; not a standard |
| cooldown after 3 consecutive walls, 24 h | house default from the local 5-of-5-days retry pattern |
| yield threshold 1 unit per 100k tokens | house default from the local 24k tokens per stored row; a run four times worse than that median stops |
| escalation age 48 h | house default; the local starvation case was 29 h |
| subagents 40 percent of spend | house default from the local 90 percent share, set well under it |

## Platform facts in references/platforms.md (checked 2026-11-04)

- Claude Code: `-p`, `--output-format json` (`subtype`, `is_error`, `num_turns`, `total_cost_usd`, `session_id`, `permission_denials`), `--max-turns` and `--max-budget-usd` print-mode only, `--permission-mode dontAsk`, `--permission-prompts none`, `--bare`, `--no-session-persistence`; limit and auth failures printed as the result text; `StopFailure` hook fires on API failures and cannot alter control flow. https://code.claude.com/docs/en/headless, https://code.claude.com/docs/en/cli-reference, https://code.claude.com/docs/en/agent-sdk/agent-loop, https://code.claude.com/docs/en/hooks, https://code.claude.com/docs/en/errors
- Desktop scheduled tasks: run only while the app is open and the machine awake; one catch-up run for the latest missed slot; manual-mode tasks stall on an unapproved tool. https://code.claude.com/docs/en/desktop-scheduled-tasks
- Hosted routines: fresh clone per run, cron in UTC unless a zone is set, per-hour run limits, starts may be minutes late. https://code.claude.com/docs/en/routines
- CI cron: schedule trigger runs from the default branch only and is disabled after a period of inactivity on public repos; `timeout-minutes` and `concurrency` for single flight. https://code.claude.com/docs/en/github-actions
- Codex CLI (`codex exec --json`, `-o`, `--sandbox`) and Gemini CLI (`-p`, `--output-format json`) forms are from their published CLI help as of the check date and are marked as examples to confirm against `--help`, since both change often.

## Specifics removed from the skill

- Site names, database names, ports, and the owner's project names (the job-site runner, its routines table, its browser dependency) from the retro. They survive only as counts in this file.
- The vendor flags above, moved to `references/platforms.md` and the example overlay under `examples/`.
- The retro's `bg-run.ps1` wrapper (plan item B4, the owner's global config): the skill describes the same behaviours (PID file, log, kill tree, wall-clock timeout) generically in `references/wrapper.md`.

## Evals

Five cases under `evals/shipyard-delivery/runner-creation/`, one per acceptance gate 1 to 5 in `references/acceptance.md`. Each fixture ships a stand-in agent CLI (`bin/agent-cli`) that logs every invocation, honours a prefix allow list with a dry run, simulates a usage-limit death, and in one case returns a lying result, so every grader reads a file. The ledger path, lock path, prompt-file path, and allow-list path live only in the settings file the fixture plants, which is what makes the no-plugin baseline fail by construction.
