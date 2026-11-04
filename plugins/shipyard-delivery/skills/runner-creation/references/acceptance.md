# Acceptance gates

Every gate runs through the wrapper, with the real agent CLI and the real permission profile, and names its expected row before it runs. The schedule is enabled only when all seven pass. The report is this table, filled in, followed by the open questions and the exact scheduler entry waiting for the user's yes.

| # | Gate | How to check | Passes when |
|---|---|---|---|
| 1 | one scheduler, lock rejects a second launch | list every scheduler entry that names the wrapper; start a launch, start a second while it runs | exactly one entry; the second launch's row is `skipped` with reason `lease_held` and the model was called once |
| 2 | headless profile is clean | run the wrapper with the CLI's dry-run form and the real profile | the result shows 0 denials and checked at least one command |
| 3 | idle exits cheap | make nothing takeable (cap every unit, or empty the queue) and launch | an `idle` row exists; the CLI was never called |
| 4 | failures are visible | force each: kill at the deadline; the CLI's simulated limit message; a dependency check that exits 1 | rows `killed`, `limit`, `skipped` (reason `dependency_down`) respectively, or a dead-man alert within grace; a `limit` row also has a fail ping |
| 5 | no model-typed facts | run once with a result that claims a different count, a timestamp, and a new cap | the row's units equal the done-count difference, its timestamp is the wrapper's, the cap in force is unchanged, and the status is `ok-flagged` |
| 6 | quarantine surfaces | fail one unit N times | the unit leaves `takeable` and has a needs-you row with the last error |
| 7 | cost per unit reported | after the first five scheduled runs | the review query prints cost per productive unit and the `lesson` lines |

Gate 7 is checked after enabling; the first six block it.

## Report shape

```
## Runner gates: <job>: <6 of 6 pass | n of 6 pass>
| # | gate | result | evidence |
| 1 | one scheduler, lock | pass | 1 entry; run <id> skipped lease_held; agent-calls 1 |
...
Open questions: <none | the inputs still unanswered, one per line>
Scheduler entry to enable: <the exact entry>
Caps in force: <turns, spend, wall-clock, units per run, per day>
```

Then STOP — WAIT for the user to enable the entry. A gate that didn't run is `not run` with the reason, never a pass.
