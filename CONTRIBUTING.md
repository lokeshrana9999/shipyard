# contributing

A skill is a folder under `plugins/delivery/skills/` holding a `SKILL.md` (frontmatter `name` and `description`, then the instructions) and optional `references/`. Changes land through a branch and a pull request against `main`. Contributions are licensed under the repo's [MIT license](LICENSE).

## repo layout

```
.claude-plugin/marketplace.json   Claude Code marketplace "shipyard"
plugins/delivery/
  .claude-plugin/plugin.json      Claude Code plugin manifest
  skills/<skill>/                 SKILL.md plus references/
  agents/                         helper agents, Claude Code format (source)
  platforms/                      agents generated for Codex and Gemini CLI
  output-styles/signal.md         Claude Code output style
  evals/<skill>/                  eval cases per skill
  evals/pr-review-bench/          real-code cases for pr-review
  docs/sources/<skill>.md         where each skill's rules came from
docs/                             user docs; docs/skills/ is generated
examples/                         example project settings, example run
evals/config/                     per-OS eval config (windows.sh)
scripts/                          run-evals.sh, eval-stats.py,
                                  gen-agents.mjs, gen-docs.mjs
```

## rules for skills

- Write patterns, not specifics. A skill states the rule plus a default marked as a default (`default: about 12 nodes`). Version numbers, issue IDs, env var names, fixed limits of one platform or API, and named third-party tools stay out of `SKILL.md`. A skill's own core tool commands (the Prisma CLI in `prisma-workflow`) stay in.
- Don't depend on one agent. Where a skill uses a feature only some agents have (subagents, plan mode, slash-command arguments), say what to do without it.
- End each stage skill with a `next:` line naming the following stage. `gen-docs.mjs` reads that line into the skill's reference page.
- Give each skill a settings file: read `.claude/shipyard/<skill>.md` on every invocation, and document its fields in `references/overlay-example.md`. Project-specific values go in an example under `examples/`, not in the skill.
- Record where a rule came from, and any specifics removed from the skill, in `plugins/delivery/docs/sources/<skill>.md`. That folder sits outside `skills/`, so it never loads into an agent's context.

## before merging

1. Run `skill-auditor` on the changed skill and fix what its report finds. Its default report file, `SKILLS-AUDIT.md`, is a working file: don't commit it.
2. Run that skill's evals, `bash scripts/run-evals.sh plugins/delivery --tag <skill>`, and check with `eval-stats.py` that the with-minus-without delta is positive and no new `NON-DISCRIMINATING` or `UNDERPOWERED` flag appears. There is no fixed pass bar. Details are in [docs/evals.md](docs/evals.md).
3. After changing an agent in `plugins/delivery/agents/`, run `node scripts/gen-agents.mjs`.
4. After changing any `SKILL.md`, run `node scripts/gen-docs.mjs`.
5. Check nothing is stale: `node scripts/gen-agents.mjs --check`, `node scripts/gen-docs.mjs --check`, and `claude plugin validate plugins/delivery`.
6. Add a line under `Unreleased` in [CHANGELOG.md](CHANGELOG.md).

Never commit eval results (`plugins/delivery/evals/results/`) or downloaded eval data (`evals/data/`); both are git-ignored.

## trying a change

In Claude Code, start it with `claude --plugin-dir plugins/delivery` from the repo root. In other agents, link the skill folder from your checkout into their skills folder, or run `npx skills add <path to your checkout> --skill <skill> --agent <agent>`.
