# Project settings example

A project keeps this at `.claude/shipyard/land.md`. The values below are illustrative; every setting is optional, and anything left out uses the defaults in SKILL.md or is reported as `not configured`. Commands run from the repo root; `<merge sha>`, `<branch>`, and `<base>` in a command are filled in at run time.

```markdown
# land settings

- base branch: main
- remote: origin
- review station: project gate
- verify: required
- gate: `./scripts/gate.sh` (lint, unit tests, integration tests; about 6 minutes)
- re-sync cap: 2
- merge: auto
- merge strategy: squash
- record merge: insert a row `(<merge sha>, <branch>, now())` into the `merges` table with `./scripts/record_merge.sh <merge sha> <branch>`; read back: `./scripts/record_merge.sh --show <merge sha>` prints the row
- deploy wait: 10 minutes, probe every 30 seconds
- deploy probe: `curl -fsS https://api.example.test/version` prints `<merge sha>`
- manual deploy: `./scripts/deploy.sh <merge sha>`
- external records:
  - routines: `./scripts/sync_routines.sh --push`; hash check: the API's `GET /routines/hash` equals `sha256sum routines/*.yaml`
- issues: the code host's tracker; linked issues come from the pull request body and the plan file's `Closes` lines
- demo: agent-demo-film
- lock stale after: 30 minutes
```

| Field | Meaning | Default |
|---|---|---|
| `base branch`, `remote` | where the branch lands | the remote's default branch; `origin` |
| `review station` | `project gate` (land's gate is the review) or `pr-review` (an approved pull request is required at entry) | `project gate` |
| `verify` | `required`, or `skip for <paths or kinds of change>` | `required` |
| `gate` | the command that must exit 0 on the synced tree | none: the gate step is `not configured` and the run stops before merging |
| `re-sync cap` | how many times the base may move during the gate before the run stops | 2 |
| `merge` | `auto` lets the skill merge without asking; anything else asks | ask |
| `merge strategy` | `merge`, `squash`, or `rebase` | `merge` |
| `record merge` | where the merge is written and how to read it back | the report is the record |
| `deploy wait` | `T` and the probe interval | 10 minutes, every 30 seconds |
| `deploy probe` | a command whose success means the merge sha is live | none: the deploy step is `not configured` and the verdict is `landed` on the read-back alone |
| `manual deploy` | the command handed to the user on `deploy did not run` | none: the report says no manual command is configured |
| `external records` | records to push after landing, each with its hash check | none |
| `issues` | the tracker and where linked issue ids come from | none: issues are listed, not closed |
| `demo` | the skill `next:` names after a landed merge | none: `next:` is done |
| `lock stale after` | age past which a lock with no running land is reported as stale | 30 minutes |

`merge: auto` is the project's autonomy grant for merging only. It never covers the always-ask list (public posts, deletes, money, facts about the user), so this skill deletes no branch and no record whatever the settings say.
