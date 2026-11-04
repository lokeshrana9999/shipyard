# Project settings example

A project keeps this at `.claude/shipyard/runner-creation.md`. The values below are illustrative; every setting is optional, and anything left out uses the default named after it. Vendor-specific commands and flags belong here (and in `examples/` under the repo), never in SKILL.md.

```markdown
# runner-creation settings

- job: `queue-sweep`
- work unit: one row of the work table; done when a script can read its `done_at`
- trigger: one OS scheduler entry, hourly, on the always-on host; no app needs to be open
- agent CLI: `<cli> --prompt-file <file> <non-interactive flag> <result-format flag> <turn-cap flag> <spend-cap flag> <permission-profile flag>`
  - result: one JSON object on stdout with a result kind, an error flag, turn count, cost, and the list of denied commands
  - dry run: the same command with the CLI's dry-run or no-op flag, which checks permissions and runs nothing
  - limit messages: `usage limit`, `rate limit`, `organization has been disabled`, `billing`
- permission profile: `.runner/allow.txt`, one allowed command prefix per line
- prompt file: `.runner/prompt.md`
- ledger: `.runner/ledger.jsonl`, appended through `scripts/ledger-append.sh <run_id> <status> [key=value ...]`
- needs-you: `.runner/needs-you.tsv`; escalate after 48 h to the team channel
- lock: `.runner/lease.lock`, TTL 240 s
- dead-man switch: `scripts/deadman.sh <start|ok|fail>`; grace 15 min
- caps: 6 turns, 0.50 USD, 120 s wall-clock per run; 5 units per run; 40 units per day; 3 attempts per unit then quarantine; subagents 0.20 USD; yield threshold 1 unit per 50k tokens
- cooldown: a target walls 3 runs in a row waits 24 h
- dependencies to pre-check: the browser answers on its debug port; the work store answers a read
- stop flag: `.runner/STOP` present means skip
```

## Fields and defaults

| Field | Meaning | Default when absent |
|---|---|---|
| job | name used in run ids, the lock, and the ledger | the folder name |
| work unit | what one unit is and the fact that proves it done | asked; no default, since the outcome is derived from it |
| trigger | the one scheduler and host, with awake or app-open constraints | asked; one trigger is mandatory |
| agent CLI | the non-interactive command, its result format, its dry-run form, and the text its limit errors carry | asked; see platforms.md for worked examples |
| permission profile | the deny-by-default allow list and where it lives | `.runner/allow.txt`, committed scripts only |
| prompt file | the runner's instruction file | `.runner/prompt.md` |
| ledger | the store and the committed helper that appends a row and stamps the time | `.runner/ledger.jsonl` through `scripts/ledger-append.sh` |
| needs-you | the table of questions only a person can answer, and the escalation age and channel | `.runner/needs-you.tsv`, 48 h, no channel (report only) |
| lock | lease path and TTL | `.runner/lease.lock`, TTL twice the wall-clock cap |
| dead-man switch | the helper that pings start, ok, and fail, and the grace after which a missing ping alerts | `scripts/deadman.sh`, grace equal to the wall-clock cap plus 5 min |
| caps | per-run turns, spend, wall-clock; units per run and per day; attempts per unit; subagent spend; yield threshold | 10 turns, 1.00 USD, 15 min; 10 units; 50 per day; 3 attempts; subagents 40 percent of spend; 1 unit per 100k tokens |
| cooldown | consecutive walls on one target before it waits, and for how long | 3 walls, 24 h |
| dependencies to pre-check | commands that must exit 0 before the model starts | none |
| stop flag | a file whose presence skips every launch | `.runner/STOP` |

The defaults are house defaults; their basis is in `docs/sources/runner-creation.md`.
