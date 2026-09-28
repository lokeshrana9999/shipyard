# Project settings example

A project keeps this at `.claude/shipyard/pr-description.md`. The values below are illustrative. Every setting is optional; anything left out is detected from the repo or uses the default in SKILL.md.

```markdown
# pr-description settings

- base branch: main
- code host: the one in `origin`; publish with the host's CLI
- description length limit: 4000 characters, counted in UTF-16 code units
- title: imperative, no prefix
- tags: emoji plus word (✨ Feature, 🐛 Fix, ♻️ Refactor, 📝 Docs, 🔧 Chore)
- extended context:
  - destination: the project wiki
  - paths: `/PR Context/PR-<number>-<slug>`, with child pages `Developer Context` and `QA Context`
  - publish: the wiki's page create-or-update call; screenshots upload as wiki attachments
  - QA evidence: screenshots saved by the verification step under `.claude/session-scratch/<run>/`
- large change: more than 600 changed lines or 15 files
```
