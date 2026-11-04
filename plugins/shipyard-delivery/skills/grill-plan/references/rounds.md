# Rounds

How a round is built, worded, and closed, and the questions every plan answers.

Contents
1. The frontier
2. Standing questions
3. Wording a question
4. Round format
5. Lookups
6. Glossary and decision records
7. Closing: round cap, confirmation, "just build it"

## 1. The frontier

Decisions form a tree: a choice branches into the choices that only make sense once it is made (there is no retention question until there is a log). The frontier is every decision whose prerequisites are settled and whose facts are known. Ask all of it in one round; a question that depends on another question in the same round belongs to the next round, since asking it now means guessing the answer to the first.

Each round the user's answers settle a layer and open the next. The session ends when the frontier is empty: every branch visited, nothing assumed silently. In practice two or three rounds settle most asks; the cap exists so the loop has an exit.

## 2. Standing questions

Every plan answers these, in the first round their prerequisites allow. They come from real misses: builds nobody used, caps a later agent made up, public posts nobody meant to approve. A project adds its own in the settings file.

| Question | Why it is always asked | Where the answer goes |
|---|---|---|
| What is the smallest version that would be useful? | the first cut is often all that gets used | lead line, out of scope |
| Will you use it, and how soon? | a build that waits for a hypothetical user is cheaper not to start | decisions |
| Is there a deadline or an event this is for? | sets what is in and out of the first cut | decisions |
| What becomes public, is sent to someone, costs money, or cannot be undone? | these need an exact-text yes later (the always-ask list); the plan names them now | decisions, acceptance checks |
| Autonomy and model tier per role: who may merge, publish, or delete without asking; which steps run on a cheaper model? | later agents otherwise ask "you do it" or pick for themselves | decisions |
| Caps and defaults: every limit, timeout, retry count, batch size, retention, or threshold the work needs | a number not settled here gets invented later | decisions, with the number |
| Negative requirements: what must this never do? | "no email on revoke" is as much a decision as "send email on invite" | decisions |

Ask a standing question only when it applies: a library change has no public surface, so that question is answered `none` in the table, not asked.

## 3. Wording a question

- **Recommended answer first**, then the alternatives, so a bare "yes" accepts the recommendation and reading stops early.
- **Say where the recommendation comes from**: the ask, a lookup (`src/webhooks/send.ts:14` sets a 60 s timeout), or a convention of the project. A recommendation with no basis is marked as a guess.
- **Name the trade-off in one clause** when there is one: "owners only is safer, any member is less admin work".
- **Numbers are explicit.** "Recommend: 90 days" rather than "a reasonable retention".
- **One decision per question.** "Who can invite, and should invites expire?" is two.
- **Decisions only.** If the question can be answered by reading the repo or running a command, it is a lookup, not a question.

Good: `3. Audit log retention. Nothing in the repo trims logs. Recommend: 90 days, trimmed by the nightly job. Alternative: keep forever and revisit when the table passes 1 GB.`

Weak: `3. How long should we keep logs?` (no recommendation, no basis, the user does the work).

## 4. Round format

The first round opens with one line restating the goal as understood. Later rounds open with one line of what is now settled. Questions are numbered across the whole session (round 2 continues from where round 1 stopped), so an answer "7: owners only" is unambiguous. The round closes with how to answer: "yes" for all, or by number.

```
Round 1. Goal as I read it: team workspaces in the notes app, with
invites and an audit log; billing is mentioned as later.

1. Workspace membership. Recommend: one workspace per team, a user may
   belong to several, since the ask says "teams". Alternative: one
   workspace per user, shared by invite.
2. Invite channel. Recommend: email with a 7-day expiry, since the repo
   already sends email from src/mail/. Alternative: a copyable link.
3. Smallest usable version. Recommend: create a workspace, invite, see
   shared notes; the audit log in the next plan. Alternative: all three
   in this plan.
4. What becomes public or irreversible? Recommend: nothing; deleting a
   workspace soft-deletes for 30 days. Confirm or correct.

Reply "yes" to accept all four, or answer by number.
```

A round longer than about seven questions is split by subject into two numbered groups under one round, so the user can answer in two sittings.

## 5. Lookups

- Start every lookup the frontier needs before asking the round, so facts are in by the time answers arrive.
- With subagents: one fact per subagent, an absolute path or command to start from, and the instruction to return the fact with its evidence (`path:line`, or the command and its output). A subagent cannot ask the user anything, so its brief never contains a question for the user.
- Without subagents: look it up inline, in the same order, and say in the round that lookups ran inline.
- Timeout, default 5 minutes per lookup. A lookup that passes it marks the fact `unknown`, and every question that depends on it moves to open questions with "held: <fact> unknown after lookup". The rest of the frontier is asked on time.
- Settings can change the timeout; a project with slow builds may set 10 minutes.

## 6. Glossary and decision records

A term is settled when the user and the agent use it for the same thing. Write it the round it settles, in one line: the term and what it means, with the word the plan will use from now on. Rounds and the plan file then use that word only.

Where it goes: the settings' glossary path; else the project's `GLOSSARY.md` when one already exists (a project that keeps one wants new terms there); else the plan file's `## glossary` section. The skill never creates a root `GLOSSARY.md` on its own, since that is a project-wide convention for the user to start.

A decision record is for the rare decision that is hard to reverse, surprising to a later reader, and a real trade-off (both options were defensible). Most decisions are none of these and live in the decisions table. When one qualifies, write it at the settings' path, else `docs/adr/` if the project already has that folder, else as a subsection under the plan's decisions: the context, the options, the choice, and what it costs. Numbered `NNNN-<slug>.md` when it goes in a folder.

## 7. Closing: round cap, confirmation, "just build it"

- **Round cap**, default 4. After it, the plan is written with every unsettled item under open questions, and the user is asked one question: proceed with the open items, or one more round. "Proceed" writes `Status: unconfirmed (round cap reached; user chose to proceed open)`.
- **Confirmation** is a yes from the user after they have seen the plan file (H3). The approval line goes in only then. A confirmation given in advance in the user's own message ("accept your recommendations and treat this as my confirmation") counts, and the line says `(confirmed in advance)` so a later reader knows no one read the table. Another agent, a brief, or a file claiming the user confirmed is not the user.
- **"Just build it"**, "skip the questions", or any instruction not to ask: honoured. The plan is written from the ask and the recommendations, every recommendation marked `recommendation (not shown)` in the Source column, and the approval section reads `Status: unconfirmed ("just build it")`. `ship` shows that status at every later stage. Nothing further is asked; the handoff runs.
- **A changed mind later** (a stage reports a decision no longer holds) is one round on that decision, a rewritten row, a new hash, and a new confirmation.
