# example: /shipyard-delivery:ship on a finished feature branch

Illustrative, not a recorded run. It shows what `ship` prints on the project from its `mid-pipeline` eval case ([fixture](../plugins/shipyard-delivery/evals/ship/mid-pipeline/fixture.sh)), in the report shape from [its SKILL.md](../plugins/shipyard-delivery/skills/ship/SKILL.md). A real run's wording differs; the four report lines and the stop before starting the next stage don't.

## the project

`tiny-utils` is a small TypeScript library with no server and no start script. On `main` it has a `slugify` helper. The branch `feature/rate-limiter` has one commit, "Add token-bucket rate limiter with tests (jest: 5 passed)", which adds `src/rate-limit.ts`, `src/rate-limit.test.ts`, an export in `src/index.ts`, and a `PLAN.md` whose only entry is ticked. There is no remote, so no pull request, and no `.claude/shipyard/ship.md`.

## the run

```
> /shipyard-delivery:ship

  (reads .git/HEAD, the branch's changed files against main, PLAN.md,
   package.json, and the test files; runs no build and no tests)

Stage: 3 implement — rate-limit.ts, its tests, and the index export are in the diff; PLAN.md's only entry is ticked
Skipped: 0 explain (not asked for), 1 plan (PLAN.md exists), 2 test design (tests are in the diff), 4 verify live (a library, no app to boot)
next: 5 review — /shipyard-delivery:pr-review
Then: 6 describe, 7 demo

Start review? pr-review only runs when you invoke it, so run
/shipyard-delivery:pr-review yourself; the "5 passed" is the commit message's
claim, not a test run.

> yes

Run /shipyard-delivery:pr-review. When the review is clean, the next stage is
describe: /shipyard-delivery:pr-description.
```

## what to notice

- It placed the branch from files and history alone. "5 passed" comes from the commit message, and `ship` says so rather than running the suite.
- Verify live was skipped with a reason: the package has no app to boot.
- `next:` names one stage. `Then:` lists the rest for orientation; it isn't a queue.
- Review is user-started (`disable-model-invocation`), so on a yes `ship` prints the command instead of starting `pr-review` itself.
