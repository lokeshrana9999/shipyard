# Sources: land

Provenance for `skills/land/`. Kept outside the skill folder so it never loads into context.

`land` is new in factory v3 (plan item C1, 2026-11-04). There is no archived original skill: the recipe it replaces was an ~800-character block pasted into 43 agent briefs over the retro window 2026-10-22 to 11-04 (retro batches b08-b11), with the gate command typed by hand 9 times in one session (b12).

## Where each rule came from

| Rule | Source |
|---|---|
| One land per repo (lock) | three fetch races in a shared checkout (b08-b11); plan v3 section 7, land row: "shared checkout race -> lock". D1 (one active child per shared resource). |
| Plain git, named failures, git identity named as the fix | 113 git identity errors in two weeks (b08-b11, plan item B1); host-specific helpers (`record_merge.sh`, `review_pr.sh`) stayed in the project (B3), so the public skill carries only plain git. |
| Gate on the synced tree; re-sync when the base moves, cap 2 | main moved during a 590 s gate (b11); the cap is the plan's default (section 7). |
| Merge asks unless the settings grant `merge: auto` | decision 4 (2026-11-04): everything outside the always-ask list may merge at Level 4 in that project; the grant lives in the project's overlay, not the skill. 3 "do not merge" briefs followed by "do it" (b09). |
| Record the merge and read it back | 16 hand-posted merge rows and record drift (b10); plan v3: "record failures silent -> read-back". |
| Deploy wait ends in a named verdict at T; manual command handed to the human; skill never runs it | a 35-minute deploy poll with no verdict (b09); H5 andon in plan v3 section 8: "the line stays stopped; nothing merges or publishes". T = 10 minutes is the plan's default. |
| External records synced by API with a hash check | routine record drift between repo and API (b10). |
| Close each linked issue explicitly | "Closes #a, #b" in a merge message closed one issue of two (plan v3 section 7, land row). |
| Never deletes, never posts publicly | the always-ask list (decision 4, E1, E2): public posts, deletes, money, facts about the owner; "what is lost" before any delete. Branch deletion is left to the host or the user. |
| Report shape: verdict first, one line per step, `Checked:` / `Not checked:` | A1 (stage reports end with Checked / Not checked); `walkthrough` skill's writing principles (decision 7). |
| Verdicts `landed`, `gate failed`, `deploy did not run` | the fixed contract in the v3 implementation brief; `not merged` added for stops before the merge (conflict, cap, no yes, missing evidence) so a reader never mistakes a stopped run for a landed one. |
| Entry needs a verify report for HEAD or a verify skip | A1: a report for an older commit counts as not verified. The HEAD checked is the one at entry, before the sync, because the sync itself moves HEAD and the gate then covers the synced tree. |
| Review station named in the overlay | plan v3 section 7, ship row: "review station ambiguous -> overlay names pr-review (human-invoked) or the project gate (land runs it)". |

## Decisions

- **Model-invocable, merge-gated.** The owner chose Level 4 autonomy for projects that grant it: the agent (or `ship`, on the user's yes to the next stage) may start `land`, because everything before the merge is repeatable and safe. The merge is the side effect, so it is gated inside the skill: it waits for the user's yes unless the overlay sets `merge: auto`. The always-ask list is never granted. An earlier draft was user-started (`disable-model-invocation: true`); the owner's autonomy decision (retro 2026-11-04, decision 4) replaced it.
- **Merge in a temporary worktree.** Plain-git merging in the user's checkout would switch branches under them; a detached worktree on the base, a merge there, and a plain fast-forward push leaves the checkout untouched, and the push's own non-fast-forward rejection doubles as the "base moved" detector. Checked on git 2.49 (2026-11-05); `git worktree add --detach` exists since git 2.5.
- **Host merge when a pull request is open and the CLI is signed in.** Branch protection often requires it, and it carries the pull request's own close-issue semantics. The read-back runs the same way either path.
- **The report is the record when none is configured.** Inventing a record location would be the invented-default failure the plan station exists to stop.

## Defaults and their basis

| Default | Basis |
|---|---|
| deploy wait T 10 minutes, probe every 30 seconds | plan v3 section 3 (C1) and section 7; house default for the interval |
| re-sync cap 2 | plan v3 section 7 |
| lock stale after 30 minutes | house default; longer than any gate observed in the retro (590 s, b11) |
| merge strategy `merge` | house default; the strategy belongs to the project and most set it in the overlay |

## Specifics removed from the skill

- The owner's project helpers (`record_merge.sh`, `post_merge_verify.py`, `/pending`, the routines API) are examples in `references/overlay-example.md` only.
- The first real overlay (job-agent) is the project's own file, not part of this repo.
- A code host's CLI (`gh pr merge`, issue close) is not named in `SKILL.md`; the skill says "the host's CLI or API" and the overlay names the tracker.
