# Sources: live-verify

Provenance for `skills/live-verify/` and `agents/live-verifier.md`. Kept outside the skill folder so it never loads into context.

Merged from three archived originals: the `live-verifier` agent and its workflow script, the `extension-browser-verify` skill, and the `generate-jwt` skill, which became step 4's token option. `generate-jwt` was otherwise project internals (its ORM models, role fields, package paths) and was dropped as a skill.

## Readiness and waiting
- Anthropic webapp-testing skill (server lifecycle, reconnaissance before action): https://github.com/anthropics/skills/blob/main/skills/webapp-testing/SKILL.md
- Actionability and what "visible" means to a driver: https://playwright.dev/docs/actionability

## Test sessions
- Log in through the API, save browser state, keep it out of version control; session storage isn't saved: https://playwright.dev/docs/auth

## Honest results
- Agents satisfy the cheapest signal (METR, 2025): https://metr.org/blog/2025-06-05-recent-reward-hacking/
- ImpossibleBench: hacking falls when agents can't see or edit the tests, and with stricter prompts: https://arxiv.org/html/2510.20270v1
- Show evidence instead of asserting success; a fresh reviewer can refute: https://code.claude.com/docs/en/best-practices
- Self-generated output cited as evidence, tool silence read as absence (field report): https://github.com/obra/superpowers/issues/2286
- Verification-before-completion convention: https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md

## Browser evidence
- Accessibility snapshot for navigation, vision for visual claims: https://playwright.dev/mcp/vision-mode
- Snapshot and screenshot tools: https://github.com/ChromeDevTools/chrome-devtools-mcp/blob/main/docs/tool-reference.md
- Screenshot after each action; page content is untrusted: https://claude.com/blog/best-practices-for-computer-and-browser-use-with-claude

## Safety
- An agent deleted a production database despite written instructions (July 2025), so enforce locality in tooling: https://codenotary.com/blog/when-ai-goes-rogue-the-replit-incident-and-its-lessons

## Extensions
- Persistent context, bundled browser, extension id from the worker URL: https://playwright.dev/docs/chrome-extensions
- Branded Chrome removal of the load-unpacked switch: https://groups.google.com/a/chromium.org/g/chromium-extensions/c/1-g8EFx2BBY/m/S0ET5wPjCAAJ
- Testing worker termination: https://developer.chrome.com/docs/extensions/how-to/test/test-serviceworker-termination-with-puppeteer

## Factory v3 changes (retro 2026-10-22 to 11-04, plan items A1 and A2; as of 2026-11-05)

Evidence is from the owner's workflow retro, cited by batch (b01-b18) as in the plan.

- **Report file bound to a commit** (`Output`, rule "The report is bound to one commit"). Hand-built live checks and 5 pull requests merged green then crashed on first live use (42 verification-gap events; b10, b12, b13). A report keyed by branch alone goes stale when HEAD moves (state-machine review, "pass had no commit binding"), so the report carries the full HEAD sha, and `ship` treats a report for another commit as not verified. `Checked:` / `Not checked:` replace `Not exercised:` so every stage report ends the same way (fixed contract across stage skills).
- **Wider triggers** ("does it actually work", "check it live", "verify these claims"). live-verify ran 0 times in 354 sessions while about 15 live-check harnesses were hand-built (b05, b06, b10, b12, b16): the skill wasn't found by the phrases the owner used.
- **`claims` mode** (Inputs, rule "A claim is a check, not a fact", step 7). Of 72 claims in agent reports, 31 were partial and 2 wrong; of 83 claims checked by hand, 47% held, at 1.3M tokens (b07). Claims judged by the `review-verifier` agent cold, since a checker that shares the claimant's context shares its blind spots (same reasoning as pr-review's validate stage). A claim contradicted by the code is `fail` even when the app can't run; a claim consistent with the code but not observed stays `not run`, because reading isn't observing.
- **Readiness timeout 120 s default** (Inputs). House default: long enough for a cold dev server, short enough that a hung boot is found in one wait; the plan's state-machine table set it (section 7). A project with a slower cold start raises it in the settings (overlay example: 180 s).
- **Fail-round cap 3, then the line stops (andon, H5)** ("When a check fails"). The fix loop had no exit (state-machine review); 3 is the plan's default, on the build-workflow finding that repair gains come in the first rounds and later rounds mostly cost tokens. The `Round:` line in the report lets `ship` count without state of its own.
- **Blocked: one fix attempt, then a precise human ask (H5)** ("When blocked"). A blocked verify had no owner; the plan gives the agent one attempt to fill the missing boot command, port, or session recipe from the repo itself and propose the settings line, then asks the human for the exact missing item instead of a vague "it's blocked".
- **Plan acceptance checks as inputs** (Inputs, step 1). The plan station (grill-plan) writes `## acceptance checks` as observables for this stage, so a verify run checks the contract the user confirmed, not only what the diff suggests.
- **Evals added**: `report-bound-to-commit` (deterministic commit via fixed dates so a grader can check the exact sha) and `claims-mode` (one claim contradicted by the code). `lists-not-exercised` graders accept `Not checked:` as well as the old line.

## Specifics removed from the skill (as of 2026-09-28)

- Branded Google Chrome from version 137 ignores `--load-extension` and `--disable-extensions-except`; with `--enable-logging=stderr` it logs "--load-extension is not allowed in Google Chrome, ignoring." The original run used Microsoft Edge on Windows, which accepts both switches. Branded Chrome can still load unpacked extensions via `--remote-debugging-pipe`, `--enable-unsafe-extension-debugging`, and the CDP call `Extensions.loadUnpacked`.
- Host mapping uses Chromium's `--host-resolver-rules`.
- The driver's bundled `chromium` channel is the one documented to run extensions headless.
- MV3 service workers stop after about 30 seconds idle, but not while DevTools is open or under ChromeDriver.
- The visibility check uses `getBoundingClientRect`, computed `display`, `visibility`, and `opacity`, and `document.elementFromPoint` at the element's center.
- The original agent named specific browser and database MCP tools in its tool list; the ported agent inherits the session's tools so each project brings its own.
- The original decision subagent was pinned to Opus and the verifier to Sonnet (superseded history). The verifier now has `model: inherit` and its decision subagent is a separate agent on the same model; only pre-flight and boot may use a smaller, faster model.
- Evals showed blocked runs grouping checks ("all not run") and dropping `Not exercised:`; the skill's Output and the agent's return rules now require one `[not run]` line per check and the `Not exercised:` line on every report.
- Removed as project internals: a remote-database warning (now the general local-datastore rule and a settings entry), stream-ordering checks for one chat endpoint (now a settings entry), a model-routing decision, the extension's injection files and root element id.
