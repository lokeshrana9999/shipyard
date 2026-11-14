# models per role

Every agent a shipyard skill starts runs on the model its role resolves to, read from one config file. With no config file, every agent runs on the model of the session that started it, so nothing changes until you write one.

## where the config lives

For each role, the first layer that sets it wins:

1. `.claude/shipyard/models.md` in the project
2. `~/.claude/shipyard/models.md` for the user
3. the default: `smaller` for the read-only roles and `live-run`, `inherit` for every other role

`smaller` resolves through the same layers; unset everywhere, it is `inherit`. Check what a project resolves to:

```bash
node plugins/shipyard-delivery/skills/build-workflow/scripts/check-briefs.mjs --resolve --project .
```

## format

A markdown file. A line counts when it reads `role: value`, `smaller: value`, or `codex.<role>: value` (a leading `- `, backticks, and any letter case in the key are allowed); every other line is prose, so the file can explain its choices. A role line holds exactly one value: `reader: sonnet # cheap` fails `bad-value` rather than silently falling back.

```
# Models for this project
Judgement roles stay on opus; anything that only reads or runs goes smaller.
smaller: sonnet
implement: opus
review-verify: sonnet
codex.implement: gpt-5-codex
```

Claude values: `sonnet`, `opus`, `haiku`, `fable`, `inherit`. A wrong value fails `--resolve` and every brief check with `bad-value`. A `codex.` value is any single model id; it is parsed and kept for the Codex agent files, but `gen-agents` doesn't write it into them yet. A role whose value is `inherit` is passed with no model option, so the agent runs on the session model.

## roles

| Role | Agent's job | Default | Kind |
|---|---|---|---|
| `reader` | reads files or transcripts and returns findings | smaller | read-only |
| `researcher` | answers a question from the web, with sources | smaller | read-only |
| `frame-check` | checks screenshots or frames against a checklist; never approves taste | smaller | read-only |
| `cold-read` | reads a plan or brief fresh and lists what is unclear | smaller | read-only |
| `test-design` | designs tests for a slice (`test-designer`) | inherit | producer |
| `implement` | builds one plan entry and commits it | inherit | producer |
| `fixer` | closes exactly the violations a checker found | inherit | producer |
| `review` | reviews one slice of a diff (`concern-reviewer`) | inherit | producer |
| `verify` | checks an entry against the plan's acceptance checks | inherit | checker |
| `review-verify` | tags each review finding (`review-verifier`) | inherit | checker |
| `live-plan` | writes `live-plan.md`: steps, expected effect and fail condition per acceptance check | inherit | checker |
| `live-run` | brings up the stack, runs `live-plan.md`, returns `matches: yes \| no \| unclear` per check (`live-verifier`) | smaller | runs, never judges |
| `decide` | picks fix, retry, rescope, or abort when a stage is blocked | inherit | judgement |

The lead, the session that runs the skill, is not a role: it always runs on the session model. Agent files keep `model: inherit`; the model passed on the agent call overrides it.

## seats

A seat is one agent continued by message across several tasks, so the files it read stay in its context. `build-workflow` uses three: builder (`implement`, `fixer`), checker (`verify`, `live-plan`), and live-run (`live-run`). A seat's roles must resolve to one model, and a seat never holds a producer together with a checker; `check-briefs` fails `seat-model-split` and `seat-mixes-checker` otherwise.

Why seats only pay while warm, measured on sonnet subagents in Claude Code (2026-11-14):

| Start | Tokens written | Tokens read from cache |
|---|---|---|
| fresh agent | 31.5k | 39.5k (system and tools) |
| fresh agent, brief byte-identical to a sibling's | 31.6k | 39.5k |
| seat resumed after 25 s | 142 | 71.1k |
| seat resumed after 6 min | 31.7k | 39.5k |

A fresh agent never reuses a sibling's brief, a warm resume reuses everything, and a resume after the cache expires costs a fresh start plus whatever the seat had built up. So a seat is replaced, not resumed, after 5 idle minutes, after 4 entries, on a second fix round for one entry, and after compaction.

## a config for the owner's setup

```
smaller: sonnet
test-design: opus
implement: opus
fixer: opus
verify: opus
review: opus
live-plan: opus
decide: fable
review-verify: sonnet
live-run: sonnet
reader: sonnet
researcher: sonnet
cold-read: sonnet
frame-check: haiku
```
