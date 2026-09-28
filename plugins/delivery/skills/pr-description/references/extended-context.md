# Extended context

Used only when the project settings configure a destination for material too large for the description: diagrams, QA results, screenshots. Typically a wiki with one page per pull request.

## Page layout

Paths come from the settings, filled with the pull request's number and a slug of its title. Once a pull request exists, its number slots into paths the user already approved at the gate, so getting it needs no second approval.

- **Index page**: title, one line linking the pull request, and one bullet per child page with a one-line summary. No diagrams or images here.
- **Developer context**: a link to the pull request and branch; for more than one diagram, a table of diagram names and one-line captions; then each diagram under its own heading.
- **QA context**, only when QA evidence exists:
  - a scenario table: scenario, result (pass, fail, or blocked), and one or two sentences citing the exact behavior observed;
  - one paragraph of caveats, if any;
  - a checklist of repeatable checks for future regressions: one per scenario, plus one or two edge cases this run didn't cover;
  - screenshots, one subsection per scenario, each with a one-line caption.

## Subagent brief

Publishing is tool-heavy and fails in ways unrelated to writing the description, so hand it to a subagent. It has no memory of the conversation, so the brief is self-contained:

- The pull request's number, title, and link, and the page paths.
- Each diagram's name, caption, and source.
- The absolute path of the screenshot directory (resolve it yourself; if there's none, say so and have it skip the QA page), and the scenario results as a list of number, title, result, and description.
- The page layout above, and how to publish to this destination, from the settings.
- Its job: upload screenshots if the destination supports attachments, and never embed an image that failed to upload; compose and publish each page, attempting each independently; return each page's link, whether screenshots uploaded, and for any failure, the page, the step, and the raw error.

## After it returns

- All pages published: add a one-sentence summary and link per page to the description, and replace the testing placeholder with the scenario tally and the QA link.
- Screenshots failed but the pages published: link the QA page, and mark the tally "(screenshots unavailable)".
- Only some pages published: link what exists; leave the testing placeholder if the QA page is missing.
- Nothing published: finish the pull request without extended context, and report the failure.
