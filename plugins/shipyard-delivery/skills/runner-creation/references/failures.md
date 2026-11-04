# Failure classes and the piece that prevents each

Read this when hardening an existing runner: find the symptom, then generate the piece in the right-hand column. The classes come from reading the ledgers and transcripts of real unattended runs; the counts and sources are in `docs/sources/runner-creation.md`.

| Failure class | Symptom in the ledger or transcript | Prevention generated |
|---|---|---|
| two triggers fire one job | two runs with the same scheduled time; one dies on a conflict | one scheduler; lease before the model call |
| launch with nothing takeable pays full startup | most rows cost tokens and do zero units | deterministic pre-flight; `pending` means takeable |
| headless blocks on compound or quoted shell | denials on the first command; the model rewrites it and is denied again | committed one-op scripts; allow rules by path; dry run with 0 denials |
| model invents timestamps, caps, counts | rejected writes; a cap that drifts; a count the facts don't match | store-side timestamps; caps in code; outcome from state; `ok-flagged` |
| limit, auth, or dependency death leaves no trace | a scheduled slot with no row at all | wrapper writes the row; dead-man switch; the CLI's failure hook where it has one |
| rows stuck in a running state | rows that never end; later launches skipped forever | lease TTL plus reaper with tree kill |
| subagent cost blowup | most of the cost in subagents; units per token falling | per-batch caps; yield governor; budget that includes subagents |
| hostile targets retried every pass | the same wall in every run's stderr tail | per-target cooldown |
| same question surfaced, never answered | one question in every summary; a unit starved for days | needs-you table with ageing and escalation; no requeue until the fact exists |
| glue rewritten each run | the transcript writes the same helper every launch, with quoting bugs | committed, tested helpers |
| leaked background process | a child alive long after the run; a session reopened later | background work forbidden in the prompt; tree kill at the deadline |
| docs reread every run | the same files read at the top of every transcript | idle fast path first; lazy docs; stable cached prefix |
| lessons only in free text | the same mistake in several summaries | `lesson` column, reviewed at the retro |
| `ok` with a failed helper or broken invariant | a helper's non-zero exit next to a success row | helper exit fails the run; invariant scripts in the outcome rules |
| a take counted with the skill never loaded | an eval score from a run that never loaded the thing under test | take validator |
