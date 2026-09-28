# pr-description settings (example: NestJS + Prisma API)

Placeholders in `<angle brackets>` stand for your own values; any code host works (GitHub, GitLab, Bitbucket, or another).

- base branch: main
- code host: `<code host>`, organization `<org>`, project `<project>`, repository `<repo>`; confirm the repository and wiki ids resolve at run time
- publish: `<code host>`'s pull-request tools (list by source branch, create, update), through its MCP server or CLI; name any tool that mangles description text (for example emoji or non-ASCII on Windows consoles) so it's never used for the body
- description length limit: `<limit>` characters, in the unit the host counts (for example UTF-16 code units); keep the first draft about 10% under it so later links fit
- tags: gitmoji plus word (✨ Feature, 🐛 Fix, ♻️ Refactor, 💄 Style, ✅ Test, 📝 Docs, 🔧 Chore, ⚡ Perf); one emoji per section header
- extended context:
  - destination: the `<project>` wiki on `<code host>`
  - paths: `/PR Additional Context/PR-<number>-<slug>`, with child pages `Developer Context` and `QA Context`; slug the title the way `<code host>` does
  - publish: the host's wiki create-or-update tool (one call per page)
  - screenshots: upload through the host's attachment endpoint or tool, and note any encoding it requires
  - QA evidence: screenshots under `.claude/session-scratch/<run>/`
