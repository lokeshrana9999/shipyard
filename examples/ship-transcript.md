# example: /shipyard-delivery:ship on a finished feature branch

Illustrative, not a recorded run. It shows what `ship` prints on the project from its `mid-pipeline` eval case ([fixture](../evals/shipyard-delivery/ship/mid-pipeline/fixture.sh)), in the report shape from [its SKILL.md](../plugins/shipyard-delivery/skills/ship/SKILL.md). A real run's wording differs; the five report lines and the stop before starting the next stage don't.

## the project

`tiny-utils` is a small TypeScript library with no server and no start script. On `main` it has a `slugify` helper. The branch `feature/rate-limiter` has one commit, "Add token-bucket rate limiter with tests (jest: 5 passed)", which adds `src/rate-limit.ts`, `src/rate-limit.test.ts`, an export in `src/index.ts`, and the plan file `.claude/shipyard/plans/feature-rate-limiter.md`, written by `grill-plan`, whose one build step is ticked and whose `## approval` section reads `Approved: 2026-11-03 plan-hash <first 12 hex of the sha256 of the bytes above that heading>`. There is no remote, so no pull request, no `.claude/shipyard/ship.md`, and no verify report.

## the run

```
> /shipyard-delivery:ship

  (reads .git/HEAD, the branch's changed files against main, the plan file,
   package.json, the test files, and looks for .claude/shipyard/reports/;
   runs no build and no tests)

Stage: 3 implement — rate-limit.ts, its tests, and the index export are in the diff; the plan's only build step is ticked
Plan: confirmed 2026-11-03 (plans/feature-rate-limiter.md; hash matches)
Skipped: 0 explain (not asked for), 2 test design (tests are in the diff), 4 verify live (a library, no app to boot; no live-verify report expected)
next: 5 review — /shipyard-delivery:pr-review
Then: 6 describe, 7 land, 8 demo (no demo skill named; last stage)

Start review? No settings name a review station, so it is pr-review, which only
you can run: /shipyard-delivery:pr-review. The "5 passed" is the commit
message's claim, not a test run. The plan's Not checked: line is empty.

> yes

Run /shipyard-delivery:pr-review. When the review is clean, the next stage is
describe: /shipyard-delivery:pr-description, then land (I can start it; it
asks before merging unless .claude/shipyard/land.md says merge: auto).
```

## what to notice

- It placed the branch from files and history alone. "5 passed" comes from the commit message, and `ship` says so rather than running the suite.
- The `Plan:` line says the plan is confirmed, with the date from its `Approved:` line. A plan without that line would show `unconfirmed` here and at every later stage.
- Verify live was skipped with a reason: the package has no app to boot. On an app, this is where `ship` would read `reports/live-verify-feature-rate-limiter.md` and refuse to move on without `Result: pass` for the current HEAD.
- `next:` names one stage. `Then:` lists the rest for orientation; it isn't a queue.
- Review is user-started (`disable-model-invocation`), so on a yes `ship` prints the command instead of starting `pr-review` itself (H4).
