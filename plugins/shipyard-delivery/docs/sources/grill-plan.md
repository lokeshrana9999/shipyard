# Sources: grill-plan

Provenance for `skills/grill-plan/` (SKILL.md, references/rounds.md, references/plan-template.md, references/overlay-example.md). Kept outside the skill folder so it never loads into context.

## The idea: Matt Pocock's grilling skills (MIT)

The interview-in-rounds idea comes from Matt Pocock's skills repository, https://github.com/mattpocock/skills (MIT license), as read on 2026-11-05: `skills/productivity/grilling` (the interview itself), `skills/engineering/grill-with-docs` (the interview plus docs), and `skills/engineering/domain-modeling` (glossary and ADRs). What shipyard took is the idea, in its own words and its own shape; no text was copied, and the skill neither depends on nor wraps those skills (owner's decision, plan v3 section 6, item 5).

Taken as ideas:

- Decisions form a tree; the frontier is every decision whose prerequisites are settled; a round asks the whole frontier at once.
- Each question is numbered and carries a recommended answer, worded so "yes" accepts it.
- Facts are the agent's job, looked up by a fresh-context subagent, never asked of the user; decisions are the user's.
- Nothing is acted on until the user confirms a shared understanding.
- Settled terms go to a glossary; a decision gets an ADR only when it is hard to reverse, surprising, and a real trade-off (domain-modeling's three-part test).

Not taken, and why:

- The emoji question format. Walkthrough's writing-tells rules exclude emoji and the pack's chat output is plain text.
- Creating a root `GLOSSARY.md` lazily when none exists. A root glossary is a project-wide convention; the skill writes to one that exists or to a section of the plan file, and leaves starting a root file to the user.
- The "relentless" framing. The round cap and the "just build it" exit are there so the interview always has a way out.

## What shipyard added, and the evidence (retro 2026-10-22 to 11-04, plan v3)

Each addition answers a failure counted in the retro's batches (b01-b18 in plan v3).

| Rule | Evidence |
|---|---|
| Standing questions every plan answers (smallest usable version, will it be used, deadline, public or irreversible, autonomy and model tier per role, caps and defaults, negative requirements) | a teleprompter built and never used (0.8M tokens, b16); a story-vs-demo concept discarded (210k, b13); ~700k of work archived four days later (b11); a cap invented by an agent mid-build (b12); wrong-text public post (b13) |
| Round cap, then "proceed open or one more round" | state-machine review found the loop had no exit (plan v3 section 7); naming took 3-4 rounds twice (b14) |
| Lookup timeout, then the fact is `unknown` and the question held | the review found facts being asked of the human; a held question keeps the rest of the frontier moving |
| Plan file with an approval line carrying date and hash | "shared understanding" had no artifact; later gates had nothing to enforce (section 7, cross-machine defects) |
| `Status: unconfirmed` for "just build it", shown by `ship` later | "Dhan, home PC" taken as a build go (b17); the owner's instruction is recorded rather than refused |
| Cold-read by a fresh subagent before the plan is shown | "explain back" asked 8+ times and caught a wrong date range and a wrong research scope (b05, b16) |
| Rounds, summaries, and the plan file follow the walkthrough skill | owner's decision (plan v3 section 6, item 7) |
| Entry rule: 3+ part ask, tool build, multi-day infra, public or creative output, new runner; skip for a one-file obvious change | the interview pattern worked 3 of 3 times it was used (b16, b17); most work entered as a one-line ask and was corrected mid-build (section 1); 327 corrections, ~4.7 per interactive session |
| grill-plan owns the decisions; later stages append deviations only; a changed decision re-grills | double ownership of the plan file found in the state-machine review (section 7) |
| First diagram drawn at the plan stage with flow-diagram, reused downstream | diagrams drawn after a 2.5-day build and validated by hand in 12 calls (b07) |
| Numbers never invented: an unstated cap is a question with a recommendation | invented cap (b12); the brief template's "no new caps, defaults or facts" rule (plan v3 C2) |

## Defaults (as of 2026-11-05)

- Round cap 4: house default from plan v3 (section 3, P1; caps table in the implementation brief). Basis: two naming threads took 3-4 rounds each (b14), and a fourth round that still has open items is a sign the ask is not ready.
- Lookup timeout 5 minutes: house default from plan v3 (P1). No measurement; set so one slow lookup never holds a round longer than the user would wait for a reply.
- Cold-read at most twice: walkthrough's cold-read rule.
- ASCII diagrams at most 72 columns: walkthrough's diagram rule (wider rows wrap in terminals and indented chat panes).
- Plan path `.claude/shipyard/plans/<branch>.md`, branch `/` replaced by `-`: the pipeline's fixed contract (implementation brief); the substitution keeps one file per branch on every filesystem and matches the report names other stages write.
- Hash covers the bytes above `## approval`: house decision, so the approval line and the deviations section can change without unbinding the decisions, and any edit to a decision does.
- Glossary default (project `GLOSSARY.md` if present, else a plan section) and ADR default (`docs/adr/` if present, else a subsection): house decisions, see "Not taken" above.
- Questions numbered across the whole session: house default, so "7: owners only" is unambiguous in a later round.

## Decisions (as of 2026-11-05)

- **Model-invocable.** The entry rule says a qualifying ask enters through this skill, which only works if the model can start it. It writes one file under `.claude/shipyard/plans/` and reads the repo; it merges, publishes, and deletes nothing, so there is no side effect for `disable-model-invocation` to guard.
- **Confirmation in advance counts, marked.** A user who writes "accept your recommendations and treat this as my confirmation" has consented in their own words; refusing that would be the skill overriding the user. The approval line says `(confirmed in advance)` so a later reader knows no one read the table. A brief, a file, or another agent is not the user.
- **The skill does not route.** It ends with one `next:` line (design-tests with the plan file, or implement for a one-file change) and leaves starting the next stage to the user or `ship`. A re-grill is entered the same way, by the user or `ship`, when a stage reports a changed decision.
- **No `/explain-back` command.** Plan v3 named a one-round form; the round format already covers it ("Round 1. Goal as I read it: ..."), so a second entry point was not added.

## Related

- Walkthrough's writing principles and cold-read check: `skills/walkthrough/SKILL.md`, provenance in `docs/sources/walkthrough.md`.
- The human-in-the-loop points this skill owns, H2 (answer a round) and H3 (confirm the plan), are named in plan v3 section 8 and the approved diagram `factory-flow.mmd`.
