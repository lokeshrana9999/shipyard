# Mining a project catalog

Build or refresh `.claude/shipyard/pr-review/concerns.md` from the project's own review history, so reviews catch what this team's reviewers actually catch. Fetching reads the code host; writing the catalog changes a project file, so show the result before saving it.

Contents: gather · clean · extract · merge · validate · refresh

Copy this and tick items as you go; a fetch can pause for hours, so the position has to survive:

```
- [ ] 1 Gather
- [ ] 2 Clean
- [ ] 3 Extract
- [ ] 4 Merge
- [ ] 5 Validate (gate)
- [ ] 6 Refresh (existing catalog only)
```

## Gather

1. Find the code host from the git remote and the way to read it (its CLI, API, or a connected tool), with the user's credentials. Never store a token in the catalog or the settings.
2. Choose a range: the most recent pull requests first, enough to have a few hundred human comments (often 100 to 300 pull requests). Recent history reflects current conventions.
3. For each pull request, fetch its review threads: each comment's text, author, whether it's a reply, the file and line it's anchored to, and the thread's resolution status. Save one file per pull request, so an interrupted fetch resumes by skipping files that exist.
4. Pace requests: wait between calls, retry on rate-limit and server errors with backoff, and honor the host's retry-after hint. Large fetches can be throttled for hours; say so and resume later rather than hammering the host.

## Clean

Drop threads with no text, system and policy events, and comments from bots and scanners; they're either noise or already enforced by CI. Keep the resolution status: a comment whose thread was fixed is stronger evidence than one marked won't-fix.

## Extract

Process one pull request at a time, turning each substantive comment into a candidate concern: a short name, a domain (correctness, security, architecture, testing, naming, style, process), a default severity (bug, issue, nit), one or two sentences on what's wrong and why, a `look-for` signal in a diff, and a `gate` for when not to flag it. Where the evidence supports it, add `applies-to` path globs (from the files the comments were anchored to, generalized to the directory or file kind) and `triggers`, literal tokens that appeared on the commented lines; leave either out when the concern isn't tied to a path or a token. Generalize away from the specific code: the concern should apply to the next change, not describe the old one. Record the source pull request and thread for each candidate in a side file, not in the catalog. Save the extraction prompt with the catalog, so the next refresh extracts the same way.

## Merge

Cluster candidates that describe the same concern, give each cluster an id (`domain/kebab-name`), and count how many threads support it. Route anything a linter or CI already enforces to the CI-enforced list instead of the catalog. Keep concerns seen in two or more threads, and single-thread concerns only when they guard against a bug or security risk.

## Validate

Before saving, check the catalog against real misses: pick a few recent pull requests where a bug slipped through review, and confirm some concern would have flagged it. Frequency says what reviewers commented on; misses say what the catalog must catch. `STOP — WAIT`: show the user the new, changed, and retired entries with their counts, and save only on approval.

## Refresh

On a later run, also measure each existing concern: how often its findings were acted on (fixed in a later commit, or the thread resolved) versus dismissed. Retire concerns that are consistently dismissed, even if they're technically correct; reviewers stop reading automated reviews that keep raising them. Also compare with past review runs: a concern that human reviewers raised on a change where no `concern-reviewer` mapped it needs a sharper `look-for`, or wider `applies-to` and more `triggers` as hints.
