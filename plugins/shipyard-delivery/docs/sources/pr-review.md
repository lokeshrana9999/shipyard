# Sources: pr-review

Provenance for the rules in `skills/pr-review/`. Kept outside the skill folder so it never loads into context.

- The starter catalog in `references/catalog/` is a de-identified rewrite of concerns mined from one project's review history plus a curated set. The original mined catalog, with its pull request provenance, stays in the private archive and is never published.
- Low precision of AI review tools, and bug findings beating style findings (SWR-Bench 2025): https://arxiv.org/abs/2509.01494
- Rules mined from past reviews, two-stage filtering, retiring correct-but-ignored rules (BitsAI-CR, FSE 2025): https://arxiv.org/abs/2501.15134
- Suppressing non-actionable rules raises usefulness (Google AutoCommenter 2024): https://arxiv.org/html/2405.13565
- Per-category confidence thresholds and suppression (Uber uReview): https://www.uber.com/us/en/blog/ureview/
- Guidelines matter most; an actionability filter beats a factual-correctness judge (Atlassian RovoDev, ICSE-SEIP 2026): https://arxiv.org/abs/2601.01129
- Verdict-first filtering is more precise and faster (BitsAI-CR ReviewFilter); cited-line checks block invented locations (2025): https://arxiv.org/abs/2512.12117
- Inline suggested fixes raise resolution; "intentional design" is the top dismissal reason (2026): https://arxiv.org/html/2607.21997v1
- Detailed prompts asking for fixes can raise false positives (2026): https://arxiv.org/abs/2603.00539
- Size tiers, security paths forcing full review, strict finding caps (Cloudflare): https://blog.cloudflare.com/ai-code-review/
- Cheap verifiers have growing blind spots; audit what they drop (2026): https://arxiv.org/abs/2609.01345
- Unconstrained reviewers find legitimate issues a catalog misses (2026): https://arxiv.org/abs/2602.11925
- Agent-only reviews are mostly noise and merge less; keep humans in the loop (2026): https://arxiv.org/abs/2604.03196

## Specifics removed from the skill (as of 2026-09-27)

- Model ids and effort levels per phase (haiku scoring at low effort, sonnet reviewing and verifying, opus compiling), and the claim of ~98% of frontier accuracy at ~60% of the cost.
- The original project's review paths, its two-package map-reduce split, and its CI-enforced lint rules; the suppression markers now come from project settings.
- The 26 curated entries in the original SKILL.md, now folded into the de-identified starter catalog.

## Folded in from the archived adversarial-code-auditor agent (2026-09-28)

That agent was dropped as a duplicate of this skill. Three of its checks weren't in the catalog and were added to `catalog-general.md`: `correctness/unwired-definition` (defined but never registered where the runtime reads it), `correctness/caller-regression` (read the callers of a changed shared function), and `testing/mocked-subject` (a test that mocks the behavior it claims to prove, or calls a handler directly instead of through its wiring). Its unattended JSON result is left to build-workflow, which can run this skill in a subagent.

## Concern selection: prefilter, cite-the-line, file clusters (2026-09-28, superseded)

Superseded the same day by the map → review → validate pipeline below; kept as history. Replaced pointwise 1-to-5 relevance scoring with a mechanical prefilter (`load-when`, `applies-to`, `triggers`), listwise selection in windows of about 25 where the scorer must quote an added line per concern, and reviewer batches clustered by file.
- Pointwise LLM rankers trail listwise, setwise, and pairwise ones (general retrieval, moderate transfer): https://arxiv.org/html/2602.03422, https://arxiv.org/abs/2310.09497
- Positional bias in long lists; windows of about 20 help, shuffling alone doesn't: https://arxiv.org/html/2604.03642, https://arxiv.org/html/2608.03091. Lost in the middle (weak, QA tasks): https://arxiv.org/pdf/2406.16008
- Shipping review tools route rules by path, not model scoring: Copilot `applyTo` https://docs.github.com/en/copilot/tutorials/customize-code-review, CodeRabbit path instructions https://docs.coderabbit.ai/configuration/path-instructions, Cursor BugBot https://cursor.com/docs/bugbot, Qodo https://github.com/qodo-ai/pr-agent/wiki/.pr_agent_auto_best_practices, Greptile https://www.greptile.com/docs/code-review-bot/custom-context, Anthropic's code-review plugin https://github.com/anthropics/claude-code/blob/main/plugins/code-review/commands/code-review.md
- BitsAI-CR: language prefilter, hunk segmentation, per-rule precision and retirement: https://arxiv.org/html/2501.15134v1
- Line-anchored comments are acted on far more than PR-level ones: https://arxiv.org/html/2508.18771v2
- Deterministic-then-LLM triage cuts noise (vendor numbers, weak): https://semgrep.dev/blog/2025/announcing-ai-noise-filtering-and-triage-memories/
- Embeddings were skipped: no store that works across Claude Code and Codex, and diffs make poor queries for prose rules.

The scorer and verifier became named agents (`agents/review-scorer.md`, `agents/review-verifier.md`) so pr-review and multi-agent runs share one definition. Separate skeptical evaluators beat self-critique, and a weaker checker can make results worse: see build-workflow-research.md.

## Map → review → validate (2026-09-28, superseded)

Superseded on 2026-09-29 by map and review in one agent (below); kept as history.

Replaced the whole funnel (prefilter, `review-scorer` windows, merge and batch by file cluster, evidence reviewers, large-tier verify with an audit sample, a separate compile agent, size tiers) with three stages, following a design the user supplied from a working in-house review skill. Only the design was taken; that skill's catalog, provenance, and project specifics stay private.

- **Map replaces relevance scoring.** One `review-mapper` reads the whole catalog and the added lines and emits every concern that plausibly appears, with its exact sites, or omits it. It doesn't score or judge, so there's no threshold to tune and no scorer-skipped-concerns failure mode; a concern reaches review only with a concrete line to look at. `applies-to` and `triggers` stay in the catalog as hints for the mapper and for mining, but nothing filters on them mechanically. Ad-hoc concerns (`adhoc/<slug>`) replace the separate free-form reviewer.
- **Reviewers and the validator are separate agents.** Reviewers (batches of 10 concerns, at most 6, batches grow past 60) must name a concrete failure scenario or clear the concern. One `review-verifier`, which didn't write the findings and is told to refute them, checks each against the diff, the real code, its callers and tests, and the base, and tags it confirmed, false-positive, pre-existing, or duplicate. Seeing every finding at once is what lets it mark duplicates. This separation, rather than a stronger checker model, is what defeats self-confirmation; the validator now runs on every review, not only on large diffs.
- **The report is compiled mechanically** (by `references/workflow.js`, or by the session filling a fixed template) from confirmed findings only, so nothing unvalidated can leak into it, and the coverage line counts what each stage returned: catalog concerns read, mapped concerns, sites, findings, confirmed, rejected.
- **All stages run on the invoking session's model**, at the user's direction: agents declare `model: inherit` and the workflow script passes no model option. The earlier per-stage model assignments, and the research about cheap selectors and weaker checkers that motivated them, no longer apply to this skill.
- **Scope is a script** (`scope.sh`): one portable POSIX pass writes `full.diff` and `diff.txt` (`path:line: code`, added lines only), so every stage cites the same line numbers, and `added=0` stops the run early.

## Map and review in one agent (2026-09-29)

Merged the map and review stages into one agent, `concern-reviewer` (the `review-mapper` agent was renamed and extended), run once per slice of the diff, at the user's direction. Validation is unchanged.

- **The mapper already holds the context.** To map a concern it has read the catalog entry and the added lines; handing that to a separate reviewer meant serializing it to JSON and having a second agent rebuild it. One agent with two explicit phases in one prompt (map, then review each mapped concern) keeps it, and returns `mapped` next to `findings` and `cleared` so what it mapped but didn't review is still visible.
- **The separation that matters is reviewer vs validator.** Self-confirmation is defeated by a skeptic that didn't write the finding and doesn't see its reasoning; splitting mapper from reviewer added no such independence. `review-verifier` stays a single agent at every size and sees every slice's findings, so it can mark cross-slice duplicates.
- **Slicing by diff keeps each agent's load small.** Instead of one mapper over the whole diff and reviewers batched by concern (10 each, at most 6), each agent gets the whole catalog but only about 400 added lines, grouped by top-level directory so related files stay together, with security-sensitive paths in their own slices. A change of at most 10 files and 400 added lines is one slice. At most 6 agents; past that, slices grow and the run logs it. Each agent may still read the whole repository for callers, registries, and tests.
- **Two checks moved out of the models.** A finding whose `evidence_line` isn't at its `location` in `diff.txt` is dropped before validation, and a mapped concern with no finding and no clearance is reported as unreviewed on the coverage line rather than silently lost.
- Coverage now reads: slices, concerns read, mapped, findings (dropped on evidence check), confirmed, rejected, unreviewed. All agents stay `model: inherit`.
