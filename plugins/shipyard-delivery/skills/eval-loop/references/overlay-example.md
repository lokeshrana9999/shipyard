# Project settings example

A project keeps this at `.claude/shipyard/eval-loop.md`. The values below are illustrative. Every setting except `runner` and `max_cost_usd` is optional; anything left out uses the default named in SKILL.md or here.

```markdown
# eval-loop settings

- text under improvement: `prompts/support-bot.md`
- cases: `evals/cases/`
- holdout: `evals/holdout/`
- runner: `bash scripts/run-case.sh {case} {out}` (one case, one transcript file; exit 0 on success)
- real surface: `bash scripts/real-surface.sh {case} {out}` (the deployed bot, through its real client)
- judge: `claude -p --model <judge model>` (LLM graders only; one judge for a whole round)
- replicates: 3
- wall clock: 20 min per round
- fix rounds: 5
- max_cost_usd: 4 per round
- cost per run: 0.03 (used to size a round when the runner can't report cost)
- run wrapper: `bash scripts/bg-run.sh {command}` (pid file, log, kill-tree on timeout)
- transcripts: `.claude/shipyard/eval-loop/<branch>/`
- report: `.claude/shipyard/reports/eval-loop-<branch>.md`
```

## fields

| Field | Meaning | Default |
|---|---|---|
| `text under improvement` | the file or files the fix rounds may edit; nothing else changes inside a round | asked for when missing |
| `cases` | folder of case folders in the layout of [case-format.md](case-format.md), or whatever the runner reads | `evals/cases/` |
| `holdout` | folder of cases that are run and scored but never opened by whoever edits the text | `evals/holdout/` |
| `runner` | command that runs one case once and writes one transcript; `{case}` is the case folder, `{out}` the transcript path, `{max_cost_usd}` the cap when the runner takes one | required |
| `real surface` | command that runs one case against the real product, not the harness | required for `pass` |
| `judge` | how LLM graders are scored; without it, a fresh subagent sees only the grader text and the transcript | subagent |
| `replicates` | runs per case per round; a case passes only when every replicate passes | 3, never fewer |
| `wall clock` | cap on one round's running time; on timeout the whole process tree is stopped | 20 min |
| `fix rounds` | fix rounds per baseline before the trend goes to the human | 5 |
| `max_cost_usd` | cost cap for one round; a round doesn't open without it | required |
| `cost per run` | estimate used as `cases × replicates × cost per run` when the runner can't report spend | none; then the runner must take `{max_cost_usd}` |
| `run wrapper` | wrapper that runs `{command}` in the background with a pid file, a log, and a kill-tree on timeout | the platform's own background facility |
| `transcripts` | where rounds, locks, runs, and scores are written | `.claude/shipyard/eval-loop/<branch>/` |
| `report` | the report path `ship` reads | `.claude/shipyard/reports/eval-loop-<branch>.md` |

## runner examples

Examples only; the skill names no runner. The command must run one case and produce one transcript, so a batch runner is wrapped to take a single case.

- A plain script that posts the case's turns to a local bot and prints the replies: `bash scripts/run-case.sh {case} {out}`.
- This repository's own cases, through Claude Code's plugin eval runner, one case at a time: `bash scripts/run-evals.sh plugins/<plugin> --case {case} --runs 1 --ablation none --max-cost-usd {max_cost_usd} --output-dir {out}` (the transcript is then the run's result file, and the runner reports its own spend).
