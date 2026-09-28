# pr-review-bench

Real-code cases for `pr-review`, taken from
[Qodo PR-Review-Bench](https://huggingface.co/datasets/Qodo/PR-Review-Bench)
(`git_code_review_bench_100_w_open_prs.jsonl`). Tag: `pr-review-bench`.

```sh
PATH="/c/Program Files/Git/bin:$PATH" claude plugin eval plugins/shipyard-delivery --tag pr-review-bench \
  -j 4 --scaffold --trust-plugin --allow-tools Write --threshold 0 --no-publish --runs 1
```

## License and attribution

The benchmark dataset is MIT-licensed, by Qodo. Its PRs live in the
`agentic-review-benchmarks` GitHub org and are copies of upstream PRs with bugs
injected. Each `fixture.sh` vendors one PR's diff, so the code in it stays under
its upstream project's license. Only repos with permissive licenses were used;
cal.com (AGPL), dify (modified Apache with extra conditions), firefox-ios
(MPL-2.0), and redis (RSAL/SSPL/AGPL) were skipped.

| Cases | Upstream | License | Copyright notice |
|---|---|---|---|
| `ghost-*`, `clean-ghost-*` | TryGhost/Ghost | MIT | Copyright (c) 2013-2026 Ghost Foundation |
| `aspnetcore-*`, `clean-aspnetcore-*` | dotnet/aspnetcore | MIT | Copyright (c) .NET Foundation and Contributors |
| `prefect-*`, `clean-prefect-*` | PrefectHQ/prefect | Apache-2.0 | Copyright 2019- Prefect Technologies, Inc. |
| `tauri-*`, `clean-tauri-*` | tauri-apps/tauri | MIT or Apache-2.0 | Copyright (c) 2017 - Present Tauri Apps Contributors |

Each license and notice was read from the upstream repo's license file on its
default branch (`LICENSE`, `LICENSE.txt`, `LICENSE-MIT`) on 2026-09-29. The full
license texts are in those files; the MIT ones require keeping the notice above
with the copied code, and Apache-2.0 requires keeping the license and any
`NOTICE` file.

The raw downloads (answer key and `.diff` files) sit in `evals/data/qodo/`, which
is git-ignored.

## Cases

Bug cases. Source is `github.com/agentic-review-benchmarks/<repo>/pull/<n>`.

| Case | +/- lines | Graded bugs |
|---|---|---|
| ghost-3 | +130/-65 | today's emails are included when they should be excluded; wrong scaling tier at the 400k boundary; boundary values skip their tier |
| ghost-6 | +23/-37 | job never schedules on first call; wrong logical operator triggers welcome emails |
| ghost-12 | +29/-345 | token cache stores the object, not the string; expiry check skips signature validation; `noTimestamp` removed |
| aspnetcore-3 | +71/-10 | case-insensitive path compare on Unix; display path used instead of the real path; wrong event level hides warnings |
| aspnetcore-7 | +38/-61 | renderer type check inverted; parameters not updated on circuit restart |
| aspnetcore-10 | +114/-75 | zero `BackgroundQueueSize` rejected; zero `RetainedFileCountLimit` allowed; `out` param nulled too early |
| prefect-1 | +272/-6 | deployment filter breaks full-name match; no type check on the job-variables schema; `zip(strict=True)` removed |
| prefect-6 | +363/-12 | missing `await`; wrong variable used for deployment id; poll delay runs before the first check |
| prefect-7 | +198/-8 | advisory lock key comes from the non-deterministic `hash()`; race check compares lengths, not id sets; wrong id field returned |
| tauri-4 | +50/-158 | wrong field path for the bundle identifier; schema validation behind an impossible condition; merged config not applied |
| tauri-12 | +231/-17 | wrong field for `UTTypeConformsTo`; inverted condition drops file extensions |
| tauri-13 | +139/-65 | `ditto` source and destination swapped; notarization success check inverted |

Clean cases: small upstream PRs merged in September 2026, with no fix or revert
seen at the time of selection.

| Case | Source | +/- lines |
|---|---|---|
| clean-ghost-31031 | TryGhost/Ghost#31031 (empty mobiledoc import) | +72/-1 |
| clean-aspnetcore-69233 | dotnet/aspnetcore#69233 (absent vs empty cache key values) | +191/-17 |
| clean-prefect-23096 | PrefectHQ/prefect#23096 (falsy variables shown blank) | +30/-1 |
| clean-tauri-16120 | tauri-apps/tauri#16120 (keep the version when converting a dependency to a table) | +38/-1 |

## Selection

- **Repo:** permissive license only (above), at most 3 PRs per repo.
- **Size:** at most ~400 changed lines. prefect#4 (+849), tauri#2 (+457), and
  aspnetcore#6 (-539) were dropped for size; Ghost#10 was fetched but not used.
- **Bugs:** at least one functional bug per PR. Issues with a `rule_name` are
  violations of the repo's rules file (style, AAA comments, yarn vs npm) and
  aren't graded. Issues without a file or line aren't graded either. tauri#13's
  "missing error source" was also left out: it's about the error chain, not
  behavior.
- **Lines:** every graded `start_line..end_line` was checked against the new
  side of the diff's hunk headers, and the snippet was found at or next to that line.

## Grading

The prompt asks for `review.json`, an array of `{id, file, line, severity}`.

- `finds-*` (one per bug): a regex that matches an entry whose `file` ends in
  the bug file's last two path segments (`[\\/]+` separator) and whose `line` is
  in `start_line-5 .. end_line+5`. Severity isn't checked; a hit is any finding
  there.
- `no-bugs` (clean cases): no entry has `"severity": "bug"`.
- `review-json-shape`: `review.json` exists and is a JSON array.

Recall = bugs hit / graded bugs. False positives = `bug`-severity findings on
clean diffs.

## Caveats

- **Injected bugs.** They're planted by the benchmark and often look planted
  (a flipped operator, a missing `await`). That's easier than finding bugs in
  natural code.
- **Incomplete answer key.** A finding not in the key may still be real, so
  precision isn't measured on bug cases. False positives are counted only on the
  clean diffs, and "clean" means only that upstream merged the PR and nothing
  was reverted.
- **Location-only match.** A finding near the right line for the wrong reason
  still counts as a hit. Long bug ranges (up to 17 lines, +/-5) make this
  more likely.
- **Leakage.** These are public PRs; the model may have seen the upstream code.
- **Small n.** 12 bug cases and 4 clean ones, one run each. This is a smoke test,
  not a benchmark score.
