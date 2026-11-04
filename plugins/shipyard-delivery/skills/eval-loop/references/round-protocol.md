# Round protocol

Read this at step 3 of SKILL.md, before opening a round. It fixes how the two hashes are computed, what a lock holds, how scores are written, and when a round counts as better.

Contents: hashes · lock · running · scores · comparison · baseline rounds · holdout check

## hashes

Both hashes are the first 12 hex characters of a SHA-256 over file paths and contents, paths sorted bytewise, line endings normalized to LF so a checkout setting can't change the hash.

- **Grader hash**: every file under every case's `graders/` folder, holdout included, plus the sorted list of locked case names. Any grader or case edit changes it.
- **Text hash**: the file or files named as the text under improvement.

With a POSIX shell (`sha256sum` on Linux and Git Bash; `shasum -a 256` on macOS):

```sh
sha12() { { command -v sha256sum >/dev/null 2>&1 && sha256sum || shasum -a 256; } | cut -c1-12; }
hash_files() {  # usage: hash_files <file>...  (paths relative to the project root, sorted)
  for f in "$@"; do printf '%s\n' "$f"; tr -d '\r' < "$f"; done
}
grader_hash=$( { hash_files $(find evals/cases evals/holdout -path '*/graders/*' -type f | LC_ALL=C sort);
                 find evals/cases evals/holdout -name case.yaml | LC_ALL=C sort; } | sha12 )
text_hash=$( hash_files prompts/support-bot.md | sha12 )
```

Run it from the project root; the paths are part of the hash, so the same tree hashed from another directory gives another value.

Without a shell there is nothing to hash with, so the round can't open; say so instead of guessing.

## lock

`round-<n>/lock.json`, written before any run:

```json
{
  "round": 3,
  "kind": "fix",
  "grader_hash": "3f9c1a7b2e04",
  "text_hash": "8ad02c6e1b57",
  "cases": ["helpline-first", "one-language", "no-leading-no"],
  "holdout_cases": 1,
  "replicates": 3,
  "max_cost_usd": 4,
  "wall_clock_min": 20,
  "opened": "2026-11-05T10:12:00Z",
  "commit": "<full HEAD sha>"
}
```

`kind` is `baseline` when the grader hash differs from the previous round's (or there is no previous round) and `fix` otherwise. The case list is read once here; a case added later belongs to the next round.

## running

Order the cases by the previous same-hash round's pass rate, ascending, unscored cases first. For each case and each replicate `r` in `1..replicates`, run the runner in the background (through the settings' wrapper when there is one) with the wall-clock cap, and write the transcript to `round-<n>/runs/<case>/<r>.txt`. Holdout transcripts go to `round-<n>/runs/holdout/<case>/<r>.txt` and are read only by the scoring script and the judge, never shown.

Cost: when the runner reports spend, sum it into `round-<n>/cost.txt` after each run and stop the round when the cap is reached. When it can't, size the round first: `cases × replicates × cost per run`; above the cap, don't open it. A round the cap or the clock cut is `partial` in the report and never becomes the best round.

## scores

`round-<n>/scores.json`, one entry per case per replicate, mechanical graders first:

```json
{
  "helpline-first": {
    "1": { "required-helpline": "pass", "no-leading-no": "pass", "tone": "pass" },
    "2": { "required-helpline": "fail: 181 missing from first reply", "no-leading-no": "pass", "tone": "skipped" },
    "3": { "required-helpline": "pass", "no-leading-no": "pass", "tone": "fail: opens with a question" }
  }
}
```

A replicate passes when every grader passes; a case passes the round when every replicate passes (`k/n` in the matrix, `3/3` to pass). A replicate the clock cut is `not run` on every grader. LLM graders are `skipped` on a replicate that failed a mechanical grader.

## comparison

Suite pass rate = cases passing / cases locked (holdout cases included; they are scored, just never read). The delta is this round's suite pass rate minus the latest round with the **same grader hash**. A round with a different hash gets no delta and the report says why. "Better" means a higher suite pass rate and no case that passed before failing now; a round that trades one case for another is "same" and gets another fix round.

## baseline rounds

When a grader or case edit changes the hash, the next round is a baseline: it runs the **previous best text** (the text hash of the best round so far, restored from `round-<n>/text/` where each round keeps a copy of the text it ran) under the new graders, so the following fix round has a reference. The fix-round count restarts at the baseline. The report's round table shows `baseline (graders changed)` in the `kind` column.

## holdout check

Before each round, from the holdout cases' `turns` and `required` graders, build the list of strings of 12 characters or more (long enough to skip single common words, short enough to catch a pasted phrase), and check the diff of the text under improvement against the base branch for each, with a script that prints only counts:

```sh
git diff <base>...HEAD -- prompts/support-bot.md > /tmp/text.diff
matches=$(grep -c -F -f <(<script that prints holdout strings, one per line>) /tmp/text.diff)
```

`0` lets the round open. Anything else stops it: the report names the file and the match count, not the matched strings, and the human decides.
