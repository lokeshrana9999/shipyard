# delivery evals

Eval cases for the `shipyard-delivery` plugin, one folder per skill (`walkthrough/`, `pr-review/`, ...), each case a `case.yaml` or `prompt.md` plus `graders/*.md`. `pr-review-bench/` holds real-code cases for `pr-review` and has [its own README](pr-review-bench/README.md). Run from the repo root:

```sh
bash scripts/run-evals.sh plugins/shipyard-delivery --tag walkthrough -j 3
```

Flags, reading results with `eval-stats.py`, writing cases, and the platform config: [docs/evals.md](../../../docs/evals.md). Results land in `results/` here, git-ignored.
