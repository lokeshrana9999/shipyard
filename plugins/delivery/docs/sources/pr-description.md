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

## Specifics removed from the skill (as of 2026-09-27)

- The original project's code-host specifics: organization, project, repository and wiki names and ids; MCP tool names; its description length limit; an attachment upload recipe; personal access token lookup from `.env.local`; a JSON-RPC stdio fallback to the MCP server; a CLI to avoid for description text (Windows console codepage corruption). A placeholder version now lives in `examples/nestjs-prisma/.claude/shipyard/pr-description.md`.
- Host body limits seen in 2026: GitHub 65,536 characters; Azure DevOps 4,000 UTF-16 units; GitLab and Bitbucket unverified.
- Gitmoji tag set as the default; emoji now only when the repo uses them.
