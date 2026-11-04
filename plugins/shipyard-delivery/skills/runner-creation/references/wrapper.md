# Launch wrapper, permission profile, prompt file

Templates for the three pieces that run on every launch. Portable shell sketches; angle brackets are filled from the settings file. Notes for PowerShell hosts follow each one.

Contents: wrapper, outcome rules, PowerShell notes, permission profile, prompt file.

## Wrapper

```sh
#!/usr/bin/env sh
# <job> launch wrapper. Every decision before the model call is a script; the row is written whatever happens.
set -eu
JOB=<job>; RUN_ID="$JOB-$(date -u +%Y%m%dT%H%M%SZ)-$$"
LOCK=<lock path>; TTL=<lease ttl seconds>; OUT=.runner/$RUN_ID.out; ERR=.runner/$RUN_ID.err
row()  { scripts/ledger-append.sh "$RUN_ID" "$@"; }   # stamps the time itself; never takes one as an argument
ping() { scripts/deadman.sh "$1" || true; }           # start | ok | fail; a failed ping never fails the run

# 1 lease: skip, never wait. Only the reaper breaks a stale lease.
scripts/lease.sh acquire "$LOCK" "$TTL" "$RUN_ID" || { row skipped reason=lease_held; exit 0; }
trap 'scripts/lease.sh release "$LOCK" "$RUN_ID"' EXIT
ping start

# 2 pre-flight: deterministic and cheap, before any model call
[ ! -e <stop flag> ]        || { row skipped reason=stop_flag; ping ok; exit 0; }
scripts/caps-left.sh        || { row skipped reason=daily_cap; ping ok; exit 0; }
scripts/deps-up.sh          || { row skipped reason=dependency_down; ping fail; exit 0; }
UNITS=$(scripts/takeable.sh)   # applies retry cap, quarantine, cooldown, not-before; prints unit ids
[ -n "$UNITS" ]             || { row idle; ping ok; exit 0; }

# 3 run headless under caps; the result is parsed, never trusted
BEFORE=$(scripts/done-count.sh)
set +e
timeout <wall-clock seconds> <agent cli> --prompt-file <prompt file> <result-format flag> \
  <turn-cap flag> <spend-cap flag> <permission-profile flag> >"$OUT" 2>"$ERR"
CODE=$?
set -e

# 4 derive the outcome from state, then the row
AFTER=$(scripts/done-count.sh); DONE=$((AFTER - BEFORE))
CLAIMED=$(scripts/result-field.sh "$OUT" units_done)
STATUS=$(scripts/outcome.sh "$CODE" "$OUT" "$DONE" "$CLAIMED")
row "$STATUS" units="$DONE" claimed="$CLAIMED" turns="$(scripts/result-field.sh "$OUT" num_turns)" \
  cost="$(scripts/result-field.sh "$OUT" cost_usd)" stderr_tail="$(tail -n 5 "$ERR" | tr '\n' ' ')"
case "$STATUS" in ok|ok-flagged) ping ok ;; *) ping fail ;; esac
```

`scripts/lease.sh acquire` creates the lock atomically (`mkdir`, or `set -C` with `>`), writes the run id and expiry inside, and exits 1 when it exists. `release` removes it only when it holds this run id. The daily cap counts today's `ok` and `ok-flagged` rows' units from the ledger, so the cap is enforced by the ledger, not by the prompt.

## Outcome rules

`scripts/outcome.sh <exit code> <result file> <done> <claimed>` applies these in order; the first match wins.

| Condition | Status |
|---|---|
| exit code is the timeout's (124 for `timeout`), or the reaper killed it | `killed` |
| result text matches a limit message from the settings (usage, rate, billing, auth, org disabled) | `limit` |
| result kind says the turn or spend cap stopped it | `failed`, reason `cap_hit` |
| error flag set, non-zero exit, or any helper exited non-zero | `failed` |
| the done count couldn't be read before or after | `needs-check` |
| done equals claimed, and every invariant script exits 0 | `ok` |
| done differs from claimed, or an invariant script couldn't run | `ok-flagged` |

Limit messages have no reliable exit code or result kind across CLIs, so the match is on text; keep the list in the settings so a new wording is one line, not a code change.

## PowerShell notes

- Atomic lock: `New-Item -ItemType Directory $Lock -ErrorAction Stop` inside `try/catch`; the catch is the skip.
- Wall-clock: `$p = Start-Process <cli> -ArgumentList ... -PassThru -RedirectStandardOutput $Out -RedirectStandardError $Err`, `if (-not $p.WaitForExit(<ms>)) { taskkill /PID $p.Id /T /F; $Code = 124 }`. The `/T` kills the tree, which is what catches a leaked subprocess.
- Timestamps: `Get-Date -Format o` inside the ledger helper, never in the wrapper's arguments.
- Encoding: set `[Console]::OutputEncoding = [Text.Encoding]::UTF8` before parsing the result, and write files with an explicit UTF-8 encoding.
- Save the scripts with LF endings and no quoting that depends on the caller's shell; a one-op script per helper avoids the quoting bugs that compound commands hit when a scheduler, not a person, launches them.

## Permission profile

Deny by default; allow the committed scripts by path, one prefix per line; nothing that takes arbitrary arguments. Example, generic:

```
scripts/takeable.sh
scripts/claim.sh
scripts/mark-done.sh
scripts/needs-you-add.sh
```

Each CLI expresses this differently (an allow list of command prefixes, a settings file, a sandbox mode); platforms.md has the per-platform form. The profile is proven, not assumed: the dry run in SKILL.md step 4 runs the real CLI with this profile and must report 0 denials. A denial found later means the prompt asked for a command the profile doesn't cover; fix the prompt to use a committed script, or commit the script, then rerun the dry run.

## Prompt file

Stable prefix first (so a CLI that caches it does), the idle fast path before anything else, and state read from scripts only.

```markdown
# <job> runner

You run unattended under caps; nobody will answer a question. State comes from the scripts below, never from memory or guesswork.

1. run: scripts/takeable.sh
   Nothing printed means stop now with the single word idle. Read no docs first.
2. For each unit printed, at most <units per run>:
   run: scripts/claim.sh <id>
   do the unit's work with the committed scripts only
   run: scripts/mark-done.sh <id> <receipt>
3. A question only a person can answer: run: scripts/needs-you-add.sh <id> "<question>" and move on; never retry that unit.
4. End with one line: units_done=<n> (the wrapper counts the facts; this is your claim).

Never start background processes, open interactive tools, read the clipboard, or write timestamps, caps, or counts to the store.
```

Subagent briefs, where the CLI supports them, carry a tool-call and token budget each and forbid background work, since subagents are where unattended cost runs away.
