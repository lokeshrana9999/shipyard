# evals

Each skill has eval cases under `plugins/shipyard-delivery/evals/<skill>/`, scored with the plugin loaded and again without it, so a case only counts when the plugin makes the difference. They run through Claude Code's `claude plugin eval`, so running them needs Claude Code even though using the skills doesn't.

## running

From the repo root, in a POSIX shell (Git Bash works on Windows); `eval-stats.py` needs Python 3:

```sh
bash scripts/run-evals.sh plugins/shipyard-delivery --tag walkthrough -j 3
python scripts/eval-stats.py plugins/shipyard-delivery/evals/results/<timestamp>/aggregate-result.json
```

`scripts/run-evals.sh <plugin dir> [claude plugin eval args...]` loads the config for your OS (see [platform config](#platform-config)) and passes every other argument to `claude plugin eval`. It works as-is on Linux and macOS. Results land in `plugins/shipyard-delivery/evals/results/<timestamp>/aggregate-result.json`, which is git-ignored; never commit them.

Flags this repo uses (`claude plugin eval --help` has the full list):

| Flag | Use |
|---|---|
| `--tag <tag...>` | Only cases with this tag (repeatable); usually the skill name. |
| `--case <glob>` | Only cases whose name matches the glob. |
| `--scaffold` | Run each case's `scaffold_script` (author-supplied bash; off by default). Needed for every case with a `fixture.sh`. |
| `--allow-tools <tools...>` | Grant gated tools, e.g. `Bash Write`. Cases whose prompt asks for a result file need `Write`. |
| `-j, --concurrency <n>` | Parallel agent runs (1-8); they share one rate limit. |
| `--ablation none` | Skip the no-plugin baseline arm (default is `with-without`). |
| `--runs <n>` | Runs per case per arm (default `case.runs` or 3). |
| `--model <model>` | Model under test for all cases. |
| `--judge-model <model>` | Model for LLM graders (default `haiku`). |
| `--max-cost-usd <usd>` | Hard cost ceiling; aborts with partial results (exit 2). |
| `--threshold <0..1>` | Exit 1 if any case scores below this (default 1.0); `0` for exploratory runs. |
| `--trust-plugin` | Skip the first-run trust prompt (non-interactive runs). |
| `--no-publish` | Keep the HTML report local. |

## reading results with eval-stats

```sh
python scripts/eval-stats.py plugins/shipyard-delivery/evals/results/<ts>/aggregate-result.json
python scripts/eval-stats.py --merge <a.json> <b.json>   # pool runs of same-named cases
python scripts/eval-stats.py --json <a.json> > stats.json
```

Per case it prints the mean score per arm, the with-minus-without delta with a 95% bootstrap confidence interval, the baseline pass rate, pass^k (`--k`, default 3), and per-grader pass rates, then a suite delta with a case-clustered interval. It flags `NON-DISCRIMINATING` (baseline passes 80% or more), `NOISY` (with-arm sd above 0.25), and `UNDERPOWERED` (the interval includes 0). Errored runs are dropped unless `--keep-errors`.

There is no fixed pass bar. Before merging a skill change, check that its delta is positive and it has no new `NON-DISCRIMINATING` or `UNDERPOWERED` flags.

## writing cases and graders

A case is a folder holding `case.yaml` or `prompt.md`, plus `graders/*.md`, and a `fixture.sh` when it needs a project to work in.

- Grade result files, not chat. Have the prompt ask for a file (`review.json`, `verify-status.txt`, `audit.md`) and grade it with `target: { source: file, path: ... }`. The case then needs `--allow-tools Write`.
- Keep checks binary. Each grader answers one yes/no question; prefer `regex`, `file_exists`, and `tool_used` over `llm` graders.
- Make the baseline fail by construction. A case the no-plugin baseline passes 80% of the time or more tells you nothing. Plant something only the skill knows about: a settings file, a project rule, a trap in the diff.
- `arm: with-only` graders aren't scored. Skill fired, settings read, agent dispatched: they're shown but not counted, so a 1.00 can hide a skill that never ran its pipeline. Always read their pass rates in the eval-stats output.
- A prompt that starts with `/plugin:skill` expands the skill into the prompt, so a `tool_used: Skill` grader never fires for it. Use skill-fired graders only on natural-language prompts.
- Path regexes accept both separators: `shipyard[\\/]+name\.md`, never a bare `/`. Tool inputs are JSON, where a backslash shows up as `\\`; `[\\/]+` covers it.
- Fixtures are portable bash: heredocs and `mkdir -p`; no `sed -i`, `date` flags, GNU-only options, or absolute paths. Use `git -c core.autocrlf=false add -A` and pass `user.name`/`user.email` with `-c`, so a checkout's git config can't change the fixture.
- Long-running processes go in the background. A case that boots a server should tell the agent to start it in the background with output to a log file; a foreground server never exits and uses up `timeout_seconds`.

Known result: live-verify `boots-and-verifies` (2026-09-28) scores 1.00 in both arms. When the prompt names the output format and the settings spell out boot, login, and data checks, a capable model verifies live without the skill. It still proves the Bash path works end to end; a discriminating version needs a bare prompt and no step-by-step settings.

## pr-review-bench

`plugins/shipyard-delivery/evals/pr-review-bench/` holds 12 injected-bug pull requests and 4 clean ones from Qodo's PR-Review-Bench, graded on whether `pr-review` finds each known bug near its line and raises no bugs on the clean diffs. It's a smoke test at one run per case, not a benchmark score. How to run it, how it's graded, its caveats, and the upstream licenses are in [its README](../plugins/shipyard-delivery/evals/pr-review-bench/README.md).

## platform config

The runner detects the platform (`linux`, `macos`, `windows`; WSL and Git Bash count as `windows`) and sources `evals/config/<platform>.sh` from the repo root if it exists. A config can set env vars (`PATH`, `CLAUDE_BIN`), default flags (`EVAL_DEFAULT_ARGS`), and `eval_pre` / `eval_post` hooks; `eval_post` always runs. Only [evals/config/windows.sh](../evals/config/windows.sh) exists: it runs evals under WSL2, because cases that grant Bash can't be sandboxed on native Windows, and also covers running from Git Bash.
