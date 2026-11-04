# Platform examples

Worked forms of the settings file's `agent CLI` and `trigger` lines for common platforms. These are examples, checked against each platform's docs on the date in `docs/sources/runner-creation.md`; flags drift, so confirm against `--help` before committing them. Nothing here is required by SKILL.md, which stays vendor-neutral.

Contents: agent CLIs (Claude Code, Codex CLI, Gemini CLI), schedulers (cron and systemd, Windows Task Scheduler, desktop app tasks, hosted routines, CI cron), failure hooks.

## Agent CLIs

### Claude Code (example)

- Command: `claude -p "$(cat .runner/prompt.md)" --output-format json --max-turns <n> --max-budget-usd <usd> --permission-mode dontAsk --allowedTools "Bash(scripts/takeable.sh)" "Bash(scripts/claim.sh *)" ... --no-session-persistence`
- Result: JSON on stdout with `subtype` (`success`, `error_max_turns`, `error_max_budget_usd`, `error_during_execution`), `is_error`, `result`, `num_turns`, `total_cost_usd`, `session_id`, `permission_denials`. Gate on `subtype`, not the exit code alone; a limit or auth failure is printed as the `result` text with `is_error` true.
- Dry run: the same command with a prompt whose only step is the first committed script; `permission_denials` must be empty.
- Caps: `--max-turns` and `--max-budget-usd` are print-mode only; subagent spend counts and can overshoot by one response, so set the cap under the real budget. `--permission-prompts none` tells the model not to retry a denied call.
- Startup: `--bare` skips hooks, skills, project instructions, and MCP for a reproducible run, but needs API-key auth and disables background tasks; without it, project hooks load with no trust prompt.
- Limit text seen in results: `You've hit your ... limit`, `This organization has been disabled`, `rate_limit`, `billing_error`, `authentication_failed`.

### Codex CLI (example)

- Command: `codex exec --json --sandbox workspace-write -o .runner/last-message.txt "$(cat .runner/prompt.md)"`
- Result: JSON-lines events on stdout; the final message in the `-o` file. Outcome comes from the exit code plus the state scripts, since the event stream has no single result kind.
- Permissions: the sandbox mode plus the approval policy; keep `read-only` for the dry run.

### Gemini CLI (example)

- Command: `gemini -p "$(cat .runner/prompt.md)" --output-format json`
- Result: a JSON object with the response text and stats; permissions through its approval mode. Treat anything but a zero exit and a parseable object as `failed`.

## Schedulers

| Scheduler | Entry (example) | Constraints to record in the settings |
|---|---|---|
| cron or systemd timer | `17 * * * * cd /srv/<job> && ./scripts/run.sh` or a timer unit with `OnCalendar=hourly` and `Persistent=true` | the host is always on; one entry per job; a systemd unit gives a wall-clock cap through `TimeoutStartSec` |
| Windows Task Scheduler | a task running `powershell -NoProfile -File scripts\run.ps1` hourly, "run whether user is logged on or not", "do not start a new instance" | the machine must be awake, or the task set to wake it; the single-instance setting is a second lock, not a replacement for the lease |
| desktop app scheduled task | the app's own task with the prompt file's text and the same caps | runs only while the app is open and the machine awake; a missed slot gets one catch-up run; minimum interval and stagger per the app's docs; a task in manual permission mode stalls on an unapproved tool until a person answers, so use a deny mode |
| hosted routine | the host's cron form, in UTC unless a zone is set | fresh clone per run, so the ledger must be a remote store; runs may start minutes late; per-hour run limits per account |
| CI cron | the workflow's schedule trigger with `timeout-minutes`, a `concurrency` group for single flight, and the CLI's action with the same caps | runs from the default branch only; disabled after a period of repo inactivity on public repos |

## Failure hooks

Where the CLI offers a hook that fires on an API failure (a rate, billing, or auth error) and can't change control flow, use it to write a `died` marker the wrapper turns into the row's reason. A hook that fires on session end still runs on a termination signal, so it can record the kill.
