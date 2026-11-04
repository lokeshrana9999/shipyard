# Sources: eval-loop

Provenance for `skills/eval-loop/`. Kept outside the skill folder so it never loads into context.

`eval-loop` is new in factory v3 (plan item A3, state machine "eval-loop rounds", human point H7). It has no archived original; its rules come from the owner's retro of 2026-10-22 to 11-04 (batch numbers below are that retro's), the repository's own eval conventions, and published guidance on agent evals.

## from the retro

- **Frozen grader hash, compare on the same hash only.** One prompt-improvement session edited graders in at least 5 rounds while editing the prompt, so a 26/84 round and a 58/84 round could not be compared and "the text is final" rested on shifting numbers (b14, 2026-10-30). Rule: a round opens by hashing the grader set; the delta is reported only against a round with the same hash.
- **A grader edit opens a new baseline that re-scores the previous best.** Same session: graders recalibrated after seeing results and only the changed cases re-run, with the delta then quoted as if nothing had moved (b12, 2026-10-23: "+0.36 over the no-skill baseline" after post-hoc grader tuning). Re-scoring the previous best under the new graders is what keeps the next delta honest.
- **Replicates, at least 3.** Two identical sweeps of the same 25-case suite and prompt (v3a, v3b) diverged on 4 cases: puja-after-DV (answer vs refuse), helpline timing (turn 3 vs turn 1), brevity (long vs one word), and "No." vs "Don't pay." (b18). A single run cannot show a fix. Default 3 is the retro's own recommendation ("at least 3 replicates per case are needed to claim a fix").
- **Mechanical graders first.** The retro's reader judged 147 sessions by hand and listed what a script could have caught: banned strings ("this is a scam" as first words, "the offer is genuine", a leading "No."/"Yes."), a repeated-identical-reply detector, a language-mirroring check, a reply length cap, and the presence of verified helpline numbers in the safety cases (b18). The "canned deflection as whole reply" pattern recurred in 21 sessions and "Which country are you in?" was asked three times in one conversation; both are mechanical catches. Item E4 of the plan asks for the helpline table to be asserted as exact strings, which is the `required` grader type.
- **Holdout cases the implementer never reads, and a diff check.** Graders tuned after results (b12, b14) and a skill example that quoted its own test case (b15) are contamination. StrongDM's write-up (see below) stores scenarios outside the codebase so agents cannot game them; this skill keeps them in-repo but in a folder the editor never opens, with a grep of the diff as the mechanical backstop.
- **No pass on a tally; three raw transcripts to the human.** "6 of 6 cases pass" was reported and emailed, and one minute later the owner said the replies over-explained (b14, 2026-10-30 13:01); "All 8 cases passed" was followed by "still not happy with some responses" (b15). The graders measured structure, not what the owner cared about. The retro's fix: show 3 raw reply transcripts, not a pass tally, before declaring done. Plan v3 names this H7.
- **Real-surface run before pass.** The retro asked for an on-device run of the deployed bot before "6/6 pass" (b14 recommendation 3); harness replies and real-client replies differed in formatting and length.
- **Background runs with a wall-clock cap and kill-tree.** Orphaned eval runners and duplicate writers after an interrupted run (b16, b17), and a 1h18m poll that returned a false negative (b10). The skill runs replicates in the background under a cap and lets the settings name a wrapper (plan item B4) that owns the pid file and kill-tree.
- **Failing cases first.** House ordering, so a round cut by the cost cap has scored the cases that matter.
- **Fix-round cap 5, then the trend to the human.** Plan v3 caps table (overlay defaults: eval fix rounds 5). The 26-to-58 session ran at least 6 spec-edit/re-run cycles with no stopping rule (b14).
- **Cost cap per round, required.** Eval sweeps cost about $8 each on the real set and ran roughly 10 times in one session (b14); plan decision 3 makes `--max-cost-usd` a standing allow rule for the owner's eval runner. Making the cap a required setting means a round can't start uncapped by omission.

## from the repository's own conventions

- Case layout (`case.yaml`, `graders/*.md`, binary graders, `regex`/`file_exists`/`tool_used` over `llm`, result files not chat) from `docs/evals.md` and `evals/shipyard-delivery/*`. The default layout in `references/case-format.md` keeps that shape and adds the conversational mechanical types.
- `eval-stats.py`'s pass^k and `NOISY` flag are the same idea as "every replicate must pass"; the skill reports `k/n` per case rather than a mean so a flaky case is visible.
- `Commit:` and `Result:` lines, `<branch>` with `/` replaced by `-`, and `Checked:` / `Not checked:` follow the live-verify report so `ship` reads both the same way.

## from published guidance

- Anthropic, "Demystifying evals for AI agents": grade outcomes, prefer code graders and add LLM graders where needed, use humans to calibrate, read transcripts, pass^k for reliability (75% per trial is about 42% over three), start from real failures, a 0% pass rate usually means a broken task: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- StrongDM, "Software Factory" (via the retro's research notes): scenarios kept outside the codebase as a holdout set so agents cannot see or game them; the loop runs until holdout scenarios pass and keep passing.
- METR on reward hacking and ImpossibleBench (already cited by live-verify): agents satisfy the cheapest signal and hack less when they cannot see or edit the tests. The unread holdout folder and the "fix rounds edit only the text under improvement" rule follow from this: https://metr.org/blog/2025-06-05-recent-reward-hacking/ , https://arxiv.org/html/2510.20270v1

## defaults (as of 2026-11-05)

| Default | Value | Basis |
|---|---|---|
| replicates | 3 | b18: two runs of one suite diverged on 4 of 25 cases; the retro's own recommendation |
| fix rounds per baseline | 5 | plan v3 caps table |
| wall clock per round | 20 min | house default; the retro's real-set sweeps took about 15 min each (b15) |
| holdout string length | 12 characters | house default: long enough to skip common words, short enough to catch a pasted phrase |
| repeat detector | sentences of 40 characters or more | house default, sized to catch a re-pasted helpline list or a repeated question |
| hash length | 12 hex | matches the plan's `plan-hash <sha256-12>` |

## specifics removed from the skill

- The owner's project names (the support bot, its helpline numbers 112 / 181 / 14416 / 1930, Hinglish mirroring) appear only as illustrations in references, never as rules; the `required` grader type carries whatever exact strings a project needs.
- The owner's `bg-run.ps1` wrapper is the `run wrapper` setting, unnamed in the skill.
- `claude plugin eval` flags appear once, marked as an example, in `references/overlay-example.md`.
