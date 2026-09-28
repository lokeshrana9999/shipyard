# Title and description

Contents: title · description template · writing rules · reviewer diagram · trimming to the length limit

## Title

- Imperative, leading with a strong verb (Add, Fix, Remove, Migrate, Harden), about 70 characters at most so it isn't truncated in lists.
- Names the thing and, when it fits, the outcome: "Remove broken approval gate from the release pipeline", not "Refactor pipeline files".
- No trailing punctuation or filler ("various", "minor", "cleanup of"). A prefix only if the repo's convention uses one.

## Description template

Use the repo's template when there is one, mapping these sections onto its headings. Otherwise:

```markdown
## Summary

<Why this pull request exists, in one or two sentences: the problem, what prompted it (incident, ticket, regression), and the outcome. Not what the diff shows. Name a non-obvious choice and why in one clause.>

## Changes

- [<Tag>] <A change the diff doesn't make obvious: a cross-file refactor, a behavior toggle, a version bump and its reason>

## Impact and risks

- **<Area>** (`<path or module>`, affects <user-facing feature>): <Low | Medium | High>. <What could regress, and why.>

## Unrelated changes

- `<path>`: <what changed and why it isn't part of the main change>

## Review focus

<The feedback you want and where to start: "Check the retry logic in `queue/worker.ts` first; the rest is plumbing.">

## Testing

<Results from real evidence, or a placeholder for the author to fill in.>
```

## Writing rules

- **Map commits to bullets, not one to one.** Split a commit that bundles unrelated changes, merge fixup and review-response commits into the change they fix, and drop noise (merge commits, formatting-only rebases) unless it's the point of the pull request.
- **Changes lists only what the diff can't show at a glance.** Three to five grouped bullets at most. If the summary and diff already say everything, leave the section out. No "files changed" list: the reviewer has the diff.
- **Tags**: `Feature`, `Fix`, `Refactor`, `Style`, `Test`, `Docs`, `Chore`, `Perf` by default, or the project's own vocabulary.
- **Impact areas**: check runtime paths (routes, services, UI flows, jobs), data (schema, migrations, caches), infrastructure (pipelines, deploy config, environment variables), integrations (third-party APIs, AI providers), and cross-cutting concerns (auth, rate limits, feature flags). One bullet per area actually touched, rated by how reversible and how wide the damage would be. Skip trivial areas. If the whole change is low-risk, one line says so.
- **Unrelated changes** are edits a reviewer would ask about: drive-by reformatting, config for another feature, stray files. Tests and docs that support the change aren't unrelated. Leave the section out when there are none.
- **Every line leads with its point**: one sentence per bullet, specific paths and versions, and no qualifiers that don't change meaning ("carefully", "robustly", "comprehensive").
- **Short.** A reviewer should get the point from the summary alone. Put detail in extended context, not the description.

## Reviewer diagram

Before drawing, answer three questions; if you can't, don't draw yet.

1. **What one question does it answer for a reviewer?** Almost always "how does this change the system's behavior?" That sentence becomes the diagram's one-line caption.
2. **Which one level of abstraction carries the change?** Components interacting, a request or data lifecycle, or a state machine. Leave out everything below that level and anything unchanged the reviewer already assumes.
3. **Does it pass the insight test?** A diagram that redraws the file list as boxes adds nothing. Each node is part of the change or the context that makes it legible.

By kind of change: a bug fix shows the broken causal chain and where the fix sits; a new flow shows its lifecycle, boundaries only; new branching logic shows the decision and its outcomes. Default to one diagram of about 5 to 9 nodes; add a second only when the change spans two separate concerns. Put it in the description when the host renders it, or link it from extended context.

## Trimming to the length limit

Measure in the host's unit (some count UTF-16 code units, where an emoji costs two). If over, trim in this order and re-measure after each: unrelated changes (if low value), then risk bullets to one sentence each, then merge similar change bullets, then the summary to one sentence, then the extended-context lines, and last, the lowest-severity risk bullet. Rewrite to fit; never cut mid-sentence.
