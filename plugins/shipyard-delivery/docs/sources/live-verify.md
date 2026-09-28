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
