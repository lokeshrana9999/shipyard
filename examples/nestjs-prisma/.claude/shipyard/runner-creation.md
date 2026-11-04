# runner-creation settings (example: NestJS + Prisma API, nightly invitation sweep, Claude Code on a Linux host)

Vendor-specific example. The agent CLI flags below are Claude Code's as of 2026-11-04; confirm against `claude --help` before committing them.

- job: `invitation-sweep`
- work unit: one row of `Invitation` whose `expiresAt` has passed and `remindedAt` is null; done when `remindedAt` is set (read with `scripts/runner/done-count.sh`)
- trigger: one systemd timer, `OnCalendar=02:17`, `Persistent=true`, on the API host; nothing needs to be open
- agent CLI: `claude -p "$(cat .runner/prompt.md)" --output-format json --max-turns 8 --max-budget-usd 0.80 --permission-mode dontAsk --permission-prompts none --no-session-persistence --allowedTools "Bash(scripts/runner/takeable.sh)" "Bash(scripts/runner/remind.sh *)" "Bash(scripts/runner/needs-you-add.sh *)"`
  - result: JSON on stdout; `subtype` is `success`, `error_max_turns`, `error_max_budget_usd`, or `error_during_execution`; gate on it, not on the exit code
  - dry run: the same command with `.runner/prompt-dry.md`, whose only step runs `scripts/runner/takeable.sh`; `permission_denials` must be empty
  - limit messages: `You've hit your`, `This organization has been disabled`, `rate_limit`, `billing_error`, `authentication_failed`
- permission profile: the `--allowedTools` rules above, mirrored in `.claude/settings.json` under `permissions.allow`
- prompt file: `.runner/prompt.md`
- ledger: table `runner_ledger` in the app database (`started_at`, `ended_at` default `now()`), appended through `scripts/runner/ledger-append.sh <run_id> <status> [key=value ...]`
- needs-you: table `runner_needs_you`; escalate after 48 h to the team chat channel through `scripts/runner/notify.sh`
- lock: `.runner/lease.lock`, TTL 1800 s
- dead-man switch: `scripts/runner/deadman.sh <start|ok|fail>` (an HTTP ping to the monitoring check); grace 20 min
- caps: 8 turns, 0.80 USD, 15 min wall-clock per run; 25 units per run; 100 units per day; 3 attempts per unit then quarantine; subagents 0.30 USD
- cooldown: a mail provider that rejects 3 runs in a row waits 12 h
- dependencies to pre-check: `scripts/runner/db-up.sh` (a read against the app database); `scripts/runner/mail-up.sh` (the provider's status endpoint)
- stop flag: `.runner/STOP`
