# Report template

The report lives at `.claude/shipyard/reports/eval-loop-<branch>.md` and is rewritten at the end of every round; `ship` reads `Commit:` and `Result:`. Values below are an illustration.

```markdown
# eval-loop: feat-bot-tone

Commit: 4c1e9d0b7a2f3e5d6c8b9a0f1e2d3c4b5a6f7e8d
Result: not passed
Text under improvement: prompts/support-bot.md
Cases: 12 locked (3 holdout) · Replicates: 3 · Judge: <judge> · Cap: 4 USD per round

## rounds

| Round | Kind | Grader hash | Text hash | Cases | Reps | Suite pass | Delta | Cost |
|---|---|---|---|---|---|---|---|---|
| 1 | baseline | 3f9c1a7b2e04 | 8ad02c6e1b57 | 12 | 3 | 7/12 | — | 2.10 |
| 2 | fix: helpline-first, country-loop | 3f9c1a7b2e04 | c41d7e9a0b23 | 12 | 3 | 9/12 | +2 | 2.25 |
| 3 | baseline (graders changed: one-language) | a07e55c2d9f1 | c41d7e9a0b23 | 12 | 3 | 8/12 | — | 2.20 |
| 4 | fix: one-language | a07e55c2d9f1 | 0e2b9d4c71aa | 12 | 3 | 11/12 | +3 | 2.30 |

Delta is against the latest round with the same grader hash. Round 3 re-scored round 2's text under the edited graders, so round 4 compares to round 3, not round 2.

## pass rate per case

| Case | R1 | R2 | R3 | R4 |
|---|---|---|---|---|
| helpline-first | 1/3 | 3/3 | 3/3 | 3/3 |
| country-loop | 0/3 | 3/3 | 3/3 | 3/3 |
| one-language | 2/3 | 2/3 | 0/3 | 3/3 |
| no-leading-no | 3/3 | 3/3 | 3/3 | 3/3 |
| holdout (3 cases, scores only) | 2 pass | 2 pass | 2 pass | 2 pass |
| ... | | | | |

Failing in round 4: holdout case 2 (required string missing in replicate 2).

## holdout check

Round 4: diff of prompts/support-bot.md against main, 0 matches against 41 holdout strings.

## real surface

Not run yet: round 4 has one failing case. Runs when every case passes.
(After the run: the command, three transcripts pasted in full, the cases they came from, and the line `Shown to <who> on <date>; verdict: pass` once the human has read them.)

## evidence

- round 4: `.claude/shipyard/eval-loop/feat-bot-tone/round-4/` (`lock.json`, `runs/`, `scores.json`, `cost.txt`)
- fix rounds used: 1 of 5 since the round-3 baseline

Checked: 9 cases × 3 replicates on the harness runner; 3 holdout cases scored.
Not checked: the real surface; cases in Hindi script (none locked).
```

Rules the shape enforces:

- `Result:` is `pass` only after the real-surface section holds three full transcripts and the human's verdict line; `stopped` after the fix-round cap or a holdout match; otherwise `not passed`.
- Every delta cell on a baseline row is `—`.
- A partial round (cost or clock cut) says `partial` in its `Kind` cell and is never the row the next fix compares to.
- Transcripts in the real-surface section are pasted whole, not excerpted or summarized, so the human reads what the user would have read.
