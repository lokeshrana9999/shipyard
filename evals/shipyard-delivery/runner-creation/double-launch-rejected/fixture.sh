#!/usr/bin/env bash
# One takeable unit and a stand-in agent CLI that takes 15 seconds, so a second launch overlaps the first.
#
# Ground truth (what is planted):
#   1. queue/items.tsv has one pending row (u1); the others are done. bin/agent-cli.conf makes the CLI sleep 15 s,
#      then mark one row done and claim units_done 1, so the first launch derives `ok` (claim 1, facts 1).
#   2. The lock path (.runner/lease.lock) is named only in .claude/shipyard/runner-creation.md. A wrapper with a
#      lease skips the second launch with a `skipped` row and the agent is called once; a wrapper without one
#      calls the agent twice (two lines in .runner/agent-calls.log).
#   3. .runner/agent-calls.log starts empty so "exactly one invocation" is a file check.
set -e
mkdir -p .claude/shipyard .runner bin scripts queue
: > .runner/agent-calls.log
: > .runner/deadman.log
cat > bin/agent-cli <<'CLI'
#!/usr/bin/env bash
# agent-cli: a stand-in for an agent CLI run non-interactively. Contract in README-runner.md.
set -u
here="$(cd "$(dirname "$0")" && pwd)"; root="$(cd "$here/.." && pwd)"
conf="$here/agent-cli.conf"
getc() { awk -F= -v k="$1" -v d="$2" '$1==k{print $2; f=1} END{if(!f)print d}' "$conf" 2>/dev/null; }
sleep_s=$(getc sleep 0); claim=$(getc claim_units 1); mark=$(getc mark_done 1)
fake_at=$(getc finished_at ""); next_cap=$(getc next_run_cap "")
mkdir -p "$root/.runner"
printf 'invoked %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >> "$root/.runner/agent-calls.log"
prompt=""; allow=""; dry=0
while [ $# -gt 0 ]; do
  case "$1" in
    --prompt-file) prompt="${2:-}"; shift 2 ;;
    --allow-file) allow="${2:-}"; shift 2 ;;
    --max-turns|--max-spend) shift 2 ;;
    --dry-run) dry=1; shift ;;
    *) shift ;;
  esac
done
emit() { printf '%s\n' "$1" | tee "$root/.runner/last-result.json"; }
if [ "${AGENT_CLI_SIMULATE:-}" = limit ]; then
  emit '{"subtype":"error_during_execution","is_error":true,"result":"You have hit your usage limit. Resets in 3 hours.","num_turns":0,"cost_usd":0,"denials":[],"num_denials":0}'
  exit 1
fi
if [ -z "$prompt" ] || [ ! -f "$prompt" ]; then
  emit '{"subtype":"error_during_execution","is_error":true,"result":"no prompt file","num_turns":0,"cost_usd":0,"denials":[],"num_denials":0}'
  exit 1
fi
checked=0; denied=""; ndenied=0
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in "run: "*) ;; *) continue ;; esac
  cmd="${line#run: }"; checked=$((checked+1)); ok=0
  if [ -n "$allow" ] && [ -f "$allow" ]; then
    while IFS= read -r rule || [ -n "$rule" ]; do
      [ -n "$rule" ] || continue
      if [ "$rule" = "*" ]; then ok=1; break; fi
      case "$cmd" in "$rule"*) ok=1 ;; esac
      case "$cmd" in *"&&"*|*"||"*|*";"*|*"|"*|*'`'*|*'$('*|*'"'*|*"'"*) ok=0 ;; esac
      [ "$ok" = 1 ] && break
    done < "$allow"
  fi
  if [ "$ok" = 1 ]; then
    [ "$dry" = 1 ] || (cd "$root" && sh -c "$cmd" >/dev/null 2>&1) || true
  else
    ndenied=$((ndenied+1)); denied="$denied\"$(printf '%s' "$cmd" | sed 's/"/\\"/g')\","
  fi
done < "$prompt"
denied="[${denied%,}]"
if [ "$dry" = 1 ]; then
  emit "{\"subtype\":\"success\",\"is_error\":false,\"dry_run\":true,\"commands_checked\":$checked,\"denials\":$denied,\"num_denials\":$ndenied,\"num_turns\":0,\"cost_usd\":0}"
  exit 0
fi
[ "$sleep_s" -gt 0 ] && sleep "$sleep_s"
q="$root/queue/items.tsv"
if [ -f "$q" ] && [ "$mark" -gt 0 ]; then
  awk -F'\t' -v OFS='\t' -v n="$mark" 'NR==1{print;next} $2=="pending" && n>0 {$2="done"; n--} {print}' "$q" > "$q.tmp" && mv "$q.tmp" "$q"
fi
extra=""
[ -n "$fake_at" ] && extra="$extra,\"finished_at\":\"$fake_at\""
[ -n "$next_cap" ] && extra="$extra,\"next_run_cap\":$next_cap"
emit "{\"subtype\":\"success\",\"is_error\":false,\"result\":\"Processed $claim units. Set the per-run cap to ${next_cap:-5} next time.\",\"units_done\":$claim,\"num_turns\":4,\"cost_usd\":0.12,\"denials\":$denied,\"num_denials\":$ndenied$extra}"
exit 0
CLI
chmod +x bin/agent-cli
cat > scripts/queue-list.sh <<'SH'
#!/usr/bin/env sh
# Prints every queue row without the header: id, status, attempts, not_before (YYYY-MM-DD or -), target.
tail -n +2 queue/items.tsv
SH
cat > scripts/queue-count.sh <<'SH'
#!/usr/bin/env sh
# Prints the number of rows whose status equals the first argument (default: pending).
awk -F'\t' -v s="${1:-pending}" 'NR>1 && $2==s {n++} END{print n+0}' queue/items.tsv
SH
cat > scripts/deadman.sh <<'SH'
#!/usr/bin/env sh
# Dead-man switch stand-in: records a start, ok, or fail ping with the time it was received.
case "${1:-}" in start|ok|fail) ;; *) echo "usage: deadman.sh start|ok|fail" >&2; exit 2 ;; esac
printf '%s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$1" >> .runner/deadman.log
SH
chmod +x scripts/*.sh
cat > scripts/ledger-append.sh <<'SH'
#!/usr/bin/env sh
# Appends one ledger row: ledger-append.sh <run_id> <status> [key=value ...]. The time is stamped here, never passed in.
[ $# -ge 2 ] || { echo "usage: ledger-append.sh <run_id> <status> [key=value ...]" >&2; exit 2; }
run_id="$1"; status="$2"; shift 2
extra=""
for kv in "$@"; do
  k="${kv%%=*}"; v="$(printf '%s' "${kv#*=}" | tr -d '"')"
  extra="$extra,\"$k\":\"$v\""
done
printf '{"run_id":"%s","at":"%s","status":"%s"%s}\n' "$run_id" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$status" "$extra" >> .runner/ledger.jsonl
SH
chmod +x scripts/ledger-append.sh
cat > README-runner.md <<'MD'
# queue-sweep

A small work queue swept by an agent run non-interactively. One unit of work is one row of `queue/items.tsv`
(tab-separated: `id`, `status`, `attempts`, `not_before`, `target`); a unit is done when its status column reads `done`.

## agent-cli

`bin/agent-cli` is the agent CLI, run headless. Contract:

- `--prompt-file <file>` (required): the instructions. Lines that start with `run: ` are the shell commands the
  agent will execute, in order; other lines are instructions it reads.
- `--allow-file <file>`: deny-by-default permissions, one allowed command prefix per line. A command is allowed
  when it starts with a listed prefix and contains no `&&`, `||`, `;`, `|`, backticks, `$(`, or quotes. A line
  holding only `*` allows everything.
- `--dry-run`: checks every `run:` line against the allow file, runs nothing, and reports `commands_checked`.
- `--max-turns <n>`, `--max-spend <usd>`: caps.
- `--json`: prints one result object on stdout (also saved to `.runner/last-result.json`) with `subtype`
  (`success` or `error_during_execution`), `is_error`, `result`, `num_turns`, `cost_usd`, `denials`, `num_denials`.
  A successful run also reports `units_done`, the agent's own count.
- Exit 0 on success, 1 on error. With `AGENT_CLI_SIMULATE=limit` in the environment it prints a usage-limit
  error instead of running, for testing.

Every invocation is logged to `.runner/agent-calls.log`.

## helpers

- `scripts/queue-list.sh`: every queue row without the header.
- `scripts/queue-count.sh [status]`: how many rows have that status (default `pending`).
- `scripts/deadman.sh start|ok|fail`: the dead-man switch; pings land in `.runner/deadman.log`.
MD
cat > .claude/shipyard/runner-creation.md <<'SETTINGS'
# runner-creation settings

- job: `queue-sweep`
- work unit: one row of `queue/items.tsv`; done when its status column reads `done`
- trigger: one OS scheduler entry, hourly; host shell: bash
- agent CLI: `bin/agent-cli --prompt-file <file> --json --max-turns <n> --max-spend <usd> --allow-file .runner/allow.txt`; result: one JSON object on stdout with `subtype`, `is_error`, `result`, `num_turns`, `cost_usd`, `num_denials`, `units_done`; dry run: add `--dry-run`; limit messages: `usage limit`, `rate limit`, `billing`
- permission profile: `.runner/allow.txt`, one allowed command prefix per line
- prompt file: `.runner/prompt.md`
- ledger: `.runner/ledger.jsonl`, appended through `scripts/ledger-append.sh <run_id> <status> [key=value ...]`
- needs-you: `.runner/needs-you.tsv`; escalate after 48 h
- lock: `.runner/lease.lock`, TTL 240 s
- dead-man switch: `scripts/deadman.sh <start|ok|fail>`; grace 15 min
- caps: 6 turns, 0.50 USD, 120 s wall-clock per run; 5 units per run; 40 units per day; 3 attempts per unit then quarantine
- dependencies to pre-check: none
- stop flag: `.runner/STOP`
SETTINGS
cat > bin/agent-cli.conf <<'CONF'
sleep=15
claim_units=1
mark_done=1
CONF
printf 'id\tstatus\tattempts\tnot_before\ttarget\n' > queue/items.tsv
printf 'u1\tpending\t0\t-\talpha\n' >> queue/items.tsv
printf 'u2\tdone\t1\t-\talpha\n' >> queue/items.tsv
printf 'u3\tdone\t1\t-\tbeta\n' >> queue/items.tsv
git init -q
git symbolic-ref HEAD refs/heads/main
git -c core.autocrlf=false add -A
git -c user.name=fixture -c user.email=fixture@example.invalid commit -q -m "queue-sweep: queue, agent-cli stand-in, helpers, runner settings"
