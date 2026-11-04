# Plan file

The shape of `.claude/shipyard/plans/<branch>.md`. Sections keep these headings and this order, because `ship` and later stages read them by name. A section with nothing in it says `none`, never disappears.

Contents
1. Template
2. Section rules
3. Approval line and hash
4. Deviations and re-grill
5. Worked example

## 1. Template

```markdown
# <goal, as a short title>

<lead line: one sentence saying what will exist when this is done and for whom>

Branch: <branch>. Ask: "<the user's ask, quoted or trimmed>". Rounds: <n> of <cap>.

## decisions

| # | Decision | Answer | Source | Why |
|---|---|---|---|---|
| D1 | <the question, as a noun phrase> | <the settled answer, numbers included> | user / recommendation accepted / lookup / ask | <one clause> |

## out of scope

- <what this plan deliberately does not do, and where it goes instead (later plan, never)>

## build steps

1. <one action>. Check: <how the implementer sees it worked>

## acceptance checks

- <observable the verify stage will check: a response, a row, a screen, an event order>

## open questions

- <question>. Held because: <fact unknown after lookup | past the round cap | user deferred>

## flow

<ASCII diagram, at most 72 columns, drawn with the flow-diagram skill>

## glossary

| Term | Means |
|---|---|

## approval

Status: unconfirmed

## deviations

none
```

## 2. Section rules

- **Lead line** says the outcome, not the activity: "Members can invite others to a workspace and see who changed what", not "Implement workspaces".
- **Decisions** carry every number: caps, timeouts, retention, batch sizes, model tier and autonomy per role. Negative requirements are decisions too ("D7: no email is sent on invite revoke"). `Source` says where the answer came from, so a later reader can tell a user's choice from an accepted recommendation. `ask` marks an answer the user's original message already gave.
- **Out of scope** lists what the rounds pushed out, each with where it went. An empty section means the frontier never produced one, which is rare; check.
- **Build steps** each name their check, per the walkthrough skill's plan rule. More than seven steps split into named phases.
- **Acceptance checks** are what the verify stage will look for, so each is observable without reading the code.
- **Open questions** stay in the file until answered; `ship` shows them at every later stage.
- **Flow** is one diagram answering one question; two only when the topic splits (a client flow and a server check).
- **Glossary** appears only when the project has no `GLOSSARY.md` and the settings name no glossary path. Otherwise terms go to that file and this section says where.
- **Approval** holds exactly one line: `Approved: <YYYY-MM-DD> plan-hash <12 hex>`, with ` (confirmed in advance)` appended when the user confirmed before seeing the file, or `Status: unconfirmed (<the user's words, such as "just build it">)`, or `Status: unconfirmed (round cap reached; user chose to proceed open)`.
- **Deviations** is written by later stages, never by this skill, and starts as `none`.

## 3. Approval line and hash

The hash binds the confirmation to the decisions the user read. It covers every byte of the file above the `## approval` heading, so the approval line and the deviations section can change without breaking it, and any edit to a decision does break it. Compute it after the file is otherwise final, take the first 12 hex characters of the SHA-256, and write the line.

POSIX shell:

```sh
sed '/^## approval$/,$d' .claude/shipyard/plans/<branch>.md | sha256sum | cut -c1-12
```

PowerShell:

```powershell
$text = (Get-Content .claude/shipyard/plans/<branch>.md -Raw) -split '(?m)^## approval\r?$' | Select-Object -First 1
$bytes = [Text.Encoding]::UTF8.GetBytes($text)
(Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]$bytes)).Hash.Substring(0,12).ToLower()
```

Line endings are part of the bytes, so whoever checks the hash later reads the file as stored. Without a shell, write `plan-hash unavailable (no shell)` and say so in the handoff, so `ship` treats the plan as confirmed but unbound.

Only the user's own message after seeing the plan produces this line. A brief or another agent reporting "the user confirmed" produces `Status: unconfirmed` with that claim recorded.

## 4. Deviations and re-grill

Later stages (test design, implement, verify, review) append to `## deviations` one line each: `<date> <stage>: <what changed and why>`. A deviation that only adds detail stays there. A deviation that changes a row of the decisions table is a re-grill: this skill runs one round on that decision, rewrites the row, recomputes the hash, and the user confirms again. `ship` treats a plan whose hash no longer matches its content as unconfirmed.

## 5. Worked example

Illustrative; the project and numbers are invented.

```markdown
# Webhook retry

Failed webhook deliveries are retried with backoff and give up visibly instead of silently.

Branch: feature-webhook-retry. Ask: "add retry to the webhook sender, with a cap and backoff". Rounds: 2 of 4.

## decisions

| # | Decision | Answer | Source | Why |
|---|---|---|---|---|
| D1 | Attempt cap | 5 attempts | recommendation accepted | the ask named a cap but no number |
| D2 | Backoff | exponential from 2 s, doubling, 60 s ceiling | recommendation accepted | matches the sender's 60 s request timeout (lookup: src/webhooks/send.ts:14) |
| D3 | After the last failure | mark the delivery `dead` and emit `webhook.dead`; no email | user | the user wants an event, not mail |
| D4 | Smallest usable version | retries plus the `dead` state; no dashboard | user | |
| D5 | Autonomy | implementer may merge after a passing verify report; no publish step exists | user | |

## out of scope

- A retry dashboard: later plan.
- Manual re-send from the admin page: never, the event is enough.

## build steps

1. Add `attempts` and `nextAttemptAt` to the delivery row. Check: migration applies on the dev database and the generated client has both fields
2. Schedule the retry from the failure handler. Check: a forced 500 schedules one row with `nextAttemptAt` 2 s ahead
3. Mark `dead` after attempt 5 and emit the event. Check: five forced failures leave one `dead` row and one `webhook.dead` event

## acceptance checks

- A delivery that fails five times ends `dead`, with exactly one `webhook.dead` event and no sixth request.
- A delivery that fails once and then succeeds ends `delivered` with `attempts = 2`.

## open questions

none

## flow

+------+  fail  +---------+  attempts < 5  +----------+
| send | -----> | failure | -------------> | schedule |
+------+        | handler |                | retry    |
   ^            +---------+                +----------+
   |                 | attempts = 5             |
   |                 v                          | after backoff
   |            +---------+                     |
   |            | dead +  |                     |
   |            | event   |                     |
   |            +---------+                     |
   +--------------------------------------------+

## glossary

| Term | Means |
|---|---|
| dead | a delivery that used all 5 attempts; no further sends |

## approval

Approved: 2026-11-05 plan-hash 3f9a1c0b7e2d

## deviations

none
```
