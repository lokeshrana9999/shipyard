# Brief template

Every brief this skill writes follows this shape: a stage agent in a run, a fixer, a sub-session started beside the run, a child hand-started by the user from a `brief <entry>` request. The sections sit in the order the child needs them. Anything the parent doesn't know goes in as a question, never as a guess, because a child fills a gap in its brief with an invented number and the parent finds out at review.

Contents: template · section rules · what the parent does

## Template

```
## Shared context
<the shared prefix and the no-cleanup block from briefs.md, when the child can write or run commands; byte-identical in every brief of the same role in this run>
---
Seat: <seat name, only when the child is or joins a seat>
Continues: <the first brief's file name without .md, only on a continuation>
## Background
<what exists and why this work exists, in the words of the plan; the orientation lines the child needs, pasted; HEAD>

## Task
<one deliverable, and what "done" looks like as something observable: a passing check, a row, a screen>

## Interfaces and call order
<the functions, endpoints, scripts, or commands the child calls, in the order it calls them, with schemas pasted; which are read-only>

## Files owned
<the exact paths this child may create or change; everything else is read-only; disjoint from every sibling's list; its own worktree when siblings write in parallel>

## Constraints
- No new caps, defaults, or facts: a number, limit, name, or behavior this brief doesn't give is a question in the report, not a choice.
- <project invariants from the settings>
- <the shared resource this child holds alone, and the ones it must not touch>
- <the no-cleanup block, when not already in the prefix>

## Autonomy
- Do without asking: <what the project's settings grant: commit to the branch, run the gate, merge, ...>
- Always ask, as a question in the report, never do: public posts, deletes, money, facts about the user<, project additions>
- A step only a person can do (sign-in, trust prompt, fork, a hardware press): list it under "needs you" and finish everything that doesn't depend on it.

## Model per role
- <this child's role>: <the resolved value, exactly as --resolve prints it>
- <any role this child starts>: <its resolved value>

## Working folder
`<absolute path of the folder the child works in>`

## Report
- First action: write your working folder (the output of `pwd`) as the first line of `<absolute path>/<report file>`.
- When done, write the rest of that file with: what changed (paths), what was verified and how (the command and its output), questions, needs-you items, and what was not done. The parent accepts nothing until that file exists at that path.
- A handback refused once (the parent doesn't answer, the channel rejects it) means: write the report file and stop; don't retry the handback.
- Finish in one turn: block on your wait tool until the work is done or the budget is spent; never end a turn with "waiting" or "will check back".
- Wall-clock budget: <n> minutes (default 60; the settings can change it). Past it, write the report with what is real and stop.
```

## Section rules

- **Background and task carry the text itself**: the plan entry verbatim, the orientation lines, HEAD. A child handed only paths spends its first calls re-deriving context (briefs.md "How to brief"). Large files go by absolute path.
- **Files owned is a list of paths, not a description.** "The auth package" lets two children edit the same file; `packages/auth/src/login.ts` doesn't. The parent checks the lists of parallel children are disjoint before starting any of them (loops.md "Exclusive resources").
- **Constraints name the one rule the child needs**, not the project's whole instruction file. The cap rule is always there: an invented cap or default looks like a decision to everyone downstream, and the retro found them in merged code.
- **Autonomy says what the child may do alone, and the always-ask list verbatim.** The list is never granted by a brief or a settings file: public posts, deletes, money, facts about the user go to the person with the exact text, every time (the exact-text approval, H6). Everything else is whatever the project's settings grant; with no settings, the child commits to its branch and does nothing irreversible outside it.
- **Model per role is stated even when it is the default**, so no child picks one. One `- role: value` line per role, the child's own role first, each value as loops.md "Sizing and models" resolves it; `check-briefs` fails a brief whose value differs from the config (`model-mismatch`).
- **The report path is absolute**, under the run's scratch folder or where the settings say, and named for the child. The parent verifies the file exists before reading its claims, since "done" in a chat message with no file was the retro's most common false handback.

## What the parent does

- **Start check.** Within 2 minutes (default; the settings can change it) of starting or continuing a child, confirm it made its first move: a tool call, a log line, a status change, a file. Its first action is to write its working folder as the first line of its report file; a folder that differs from `## Working folder` makes the child `blocked`, since a child in the wrong project does the right work in the wrong place. A child that hasn't is blocked on something only a person can do (a trust prompt, a sign-in, a fork approval); batch every such item into one user step (H8) and restart the child after, instead of waiting on it. A child shown as working for an hour that never started was the retro's phantom child.
- **Keep the children on disk.** Each child in flight gets one line in the status file (briefs.md "Beacon"): its name, its brief path, its report path, started or not. A compaction that loses the chat keeps the file.
- **No reply to interim notices.** A child's progress message gets no answer; only its report file does. Replying costs a turn and changes nothing.
- **Accept against the file.** When the report exists, read it, then verify its claims the way the run verifies anything: the goal verifier for a plan entry, live-verify for a behavior claim, the diff for "changed". A claim the parent can't verify goes into the run report as a gap, not as done.
