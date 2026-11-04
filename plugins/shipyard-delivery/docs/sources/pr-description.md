# Sources: pr-description

Provenance for the rules in `skills/pr-description/`. Kept outside the skill folder so it never loads into context.

- Stating the feedback wanted is the strongest predictor of merging, yet rare (Pirouzkhah, Wurzel Gonçalves, Bacchelli, MSR 2026): https://arxiv.org/abs/2602.14611
- Understanding the change is reviewers' main challenge (Bacchelli & Bird, ICSE 2013): https://www.microsoft.com/en-us/research/publication/expectations-outcomes-and-challenges-of-modern-code-review/
- Google CL description guidance (imperative first line, why, re-sync on update): https://google.github.io/eng-practices/review/developer/cl-descriptions.html
- AI-drafted PR descriptions lack intent, links, template content, and test info (Xiao et al., FSE 2024): https://arxiv.org/abs/2402.08967
- Agent PR descriptions run long and agent PRs are accepted less often (Watanabe et al., TOSEM 2025): https://arxiv.org/html/2509.14745v3
- Structured descriptions get faster responses (Watanabe et al. 2026): https://arxiv.org/abs/2602.17084
- Hallucinations in LLM-written change descriptions (IJCNLP-AACL 2025): https://arxiv.org/abs/2508.08661
- PR templates aren't applied via API or CLI; agents dropping template lines: https://cli.github.com/manual/gh_pr_create and https://github.com/openai/codex/issues/6750
- Template adoption and burden (IST 2021): https://www.sciencedirect.com/science/article/abs/pii/S0950584921002354
- Change size and review (Sadowski et al., ICSE-SEIP 2018): https://sback.it/publications/icse2018seip.pdf ; untangling changes (Di Biase et al., PeerJ CS 2019): https://peerj.com/articles/cs-193/

## Defaults (as of 2026-10-11)

- A reviewer understands the pull request in under a minute (SKILL.md, opening). House default: a target for the reader, not a measurement.
- One approval gate, before the first live write (SKILL.md "Rules"). House default: one approval covers everything that will be published, and nothing reaches the code host before it.
- Degrade, don't abort, when an extended-context publish fails (SKILL.md "Rules"). House default: a failed side publish shouldn't cost the user the pull request.
- A title of about 70 characters at most, so it isn't truncated in lists (body-template.md "Title"). House default: where a list cuts a title depends on the host and the window, and no host's cut was measured.
- Three to five grouped bullets at most under Changes (body-template.md "Writing rules"). House default.
- One diagram of about 5 to 9 nodes (body-template.md "Reviewer diagram"). House default.

## Factory v3 changes (retro 2026-10-22 to 11-04, plan items P2 and A1; as of 2026-11-05)

- **Reads the plan file and the verify report** (Inputs, steps 1 to 3). The plan stage (grill-plan) now writes `.claude/shipyard/plans/<branch>.md` with the decisions, acceptance checks, and flow diagram the user confirmed, and live-verify writes a commit-bound report. A description that re-derives the why from the diff loses the confirmed intent (intent rework was the retro's largest hidden-factory class), and a testing section written from memory was how 5 green pull requests reached a first live crash (b12). The acceptance checks appear ticked only when the report's `Checked:` names them; a report for another commit is quoted as stale, matching `ship`'s rule.
- **One diagram per flow** (rule, step 3, body-template "Reviewer diagram"). Owner decision no. 6 (2026-11-04): later artifacts reuse or update the plan's diagram when it is the same flow. The update goes into the description plus a `## deviations` line in the plan, never into the plan's `## flow`, because grill-plan's approval hash covers everything above `## approval`.
- `<branch>` in both paths is the branch name with `/` replaced by `-`, the integrator's contract for every stage file.

## Specifics removed from the skill (as of 2026-09-27)

- The original project's code-host specifics: organization, project, repository and wiki names and ids; MCP tool names; its description length limit; an attachment upload recipe; personal access token lookup from `.env.local`; a JSON-RPC stdio fallback to the MCP server; a CLI to avoid for description text (Windows console codepage corruption). A placeholder version now lives in `examples/nestjs-prisma/.claude/shipyard/pr-description.md`.
- Host body limits seen in 2026, method not recorded; checked 2026-10-11: GitHub 65,536 characters, which GitHub doesn't document but its API reports as the validation error "Body is too long (maximum is 65536 characters)" (https://bugs.webkit.org/show_bug.cgi?id=243625, https://github.com/w3c/webref/pull/245); Azure DevOps 4,000 UTF-16 units, unverified: no Microsoft documentation found, and the one report found is third-party and says 4,000 characters (https://feedback.gearset.com/forums/283474-help-us-improve-gearset/suggestions/47072533-remove-limitation-of-number-of-prs-to-be-added-to); GitLab and Bitbucket unverified.
- Gitmoji tag set as the default; emoji now only when the repo uses them.
