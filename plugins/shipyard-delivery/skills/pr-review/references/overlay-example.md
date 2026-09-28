# Project settings example

A project keeps settings at `.claude/shipyard/pr-review.md` and its own concerns at `.claude/shipyard/pr-review/concerns.md` (same entry format as `references/catalog-*.md`). The values below are illustrative; every setting is optional.

```markdown
# pr-review settings

- base branch: main
- review paths: `api/`, `web/`; skip `docs/`, generated code
- security-sensitive paths: `api/auth/`, `api/billing/`, `tokens`
- slice size: 300 added lines
- agent cap: 4
- findings cap: 8
- CI-enforced rules: listed in `.claude/shipyard/pr-review/ci-rules.md`; suppression markers `eslint-disable`, `ts-ignore`, `ts-expect-error`, `noqa`
```

- **base branch**: what the change is diffed against (three-dot, so only what the branch adds). Default: the repository's default branch.
- **review paths**: passed to `scope.sh`; a skip becomes `:!path`. Default: the whole diff.
- **security-sensitive paths**: path fragments; a file whose path contains one is reviewed in a slice of its own, and a finding there is never downgraded below `issue` without naming the guard that makes it safe. Replaces the default list: `auth`, `permission`, `payment`, `secret`, `tenant`, `tenancy`.
- **slice size**: about how many added lines one `concern-reviewer` gets once the change is past one slice (more than 10 files or 400 added lines). Default: 400.
- **agent cap**: the most `concern-reviewer` agents one review starts; past it, slices grow instead, and the run logs it. Default: 6.
- **findings cap**: how many confirmed findings the report shows, highest severity first. Default: 10.
- **CI-enforced rules**: what CI or a linter already checks, so the review doesn't repeat it; a rule maps only where an added line carries one of the suppression markers.
