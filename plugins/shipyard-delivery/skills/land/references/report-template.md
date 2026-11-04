# Report template

Written to `.claude/shipyard/reports/land-<branch>.md` (a `/` in the branch name becomes `-`) and given as the reply. Verdict first; one line per step; every claim carries the sha, command, or read-back that proves it; `next:` last. Steps that did not run keep their line with the reason, so a reader sees what was skipped.

```markdown
# land: <branch> -> <base>

Verdict: landed | gate failed | not merged | deploy did not run
Commit: <merge sha, or the branch HEAD when not merged>
Base: <base> <sha before> -> <sha after>; re-syncs: <n> of <cap>
Gate: pass | fail (exit <code>) | not configured; `<command>`, <seconds>s
Merge: <strategy> <merge sha> via <host | plain git>; read back: <base> = <sha> | not merged: <why>
Record: <where>; read back: <the line or row as read> | not configured
Deploy: live after <seconds>s (`<probe>`) | did not run within T=<T> | not configured
Records synced: <name>: hash <ok | mismatch> | none configured
Issues closed: #<id> (<state read back>), ... | none linked | not configured
Checked: <what this run observed>
Not checked: <what it did not, and why>

<on gate failed: the gate's output, complete>
<on deploy did not run: andon H5. manual deploy: `<command>`>

next: <one action>
```

Verdicts:

| Verdict | When | `next:` |
|---|---|---|
| `landed` | the base reads back as the merge sha and the probe succeeded (or no probe is configured) | the demo stage the settings name, else done |
| `gate failed` | the gate exited non-zero | implement, with the gate output |
| `not merged` | entry evidence missing, a conflict, the base kept moving past the cap, the user said no, or a required tool is missing | the stage that fills the gap, or the pull request's human reviewers |
| `deploy did not run` | the merge landed but the probe never succeeded within T | the user runs the manual deploy command, then re-checks the probe |

Example of a stopped run:

```markdown
# land: archive-notes -> main

Verdict: gate failed
Commit: 3f2a9c1 (branch HEAD, not merged)
Base: main 8d1e0b4 -> 8d1e0b4; re-syncs: 0 of 2
Gate: fail (exit 1); `bash scripts/gate.sh`, 4s
Merge: not merged: gate failed
Record: not written
Deploy: not run
Records synced: not run
Issues closed: not run
Checked: tree clean, identity set, base synced, gate run on 3f2a9c1
Not checked: merge, record, deploy, records, issues (gate failed first)

gate output:
gate: lint ok
gate: test notes.archive FAIL expected 204 got 500
exit 1

next: fix the archive test in src/notes.js, re-run live-verify, then land again.
```
