# Sources: flow-diagram

Provenance for the rules in `skills/flow-diagram/` (SKILL.md and references/). Kept outside the skill folder so it never loads into context.

## Platform support
- Azure DevOps Mermaid limits (`graph` not `flowchart`, no long arrow, no Font Awesome, limited HTML; supported diagram types): https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops
- Azure DevOps accepts ```` ```mermaid ```` in wiki, PRs, and work items (Sprint 274, May 2026): https://learn.microsoft.com/en-us/azure/devops/release-notes/2026/wiki/sprint-274-update
- GitHub diagram support (Mermaid, GeoJSON, TopoJSON, STL only): https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams
- GitHub switches the Mermaid theme with the page theme: https://github.com/orgs/community/discussions/35733
- `@{ shape }` can't take a `:::class` (mermaid #7826): https://github.com/mermaid-js/mermaid/issues/7826
- Mermaid 12.0.0 (ELK default layout, new default look): https://github.com/mermaid-js/mermaid/releases
- maid validator: https://github.com/probelabs/maid

## Perception and comprehension
- Edge crossings hurt comprehension most (Purchase 1997): https://link.springer.com/chapter/10.1007/3-540-63938-1_67
- Diagram size outweighs layout flaws (Störrle 2016): https://link.springer.com/article/10.1007/s10270-016-0529-x
- Redundant color and shape coding aids grouping (Nothelfer, Gleicher, Franconeri 2017): https://graphics.cs.wisc.edu/Papers/2017/NGF17/Nothelfer,%20Gleicher,%20Franconeri%20-%20JEP%20HPP%202017.pdf
- Redundancy helps most at 5–8 categories (CatPAW 2026): https://arxiv.org/abs/2602.06792
- Semantic transparency of notations needs a key for novices: https://link.springer.com/article/10.1007/s10270-021-00895-w
- Color must not be the only carrier of meaning (WCAG 1.4.1): https://www.w3.org/WAI/WCAG21/Understanding/use-of-color
- Okabe-Ito color-blind-safe palette: https://jfly.uni-koeln.de/color/

## LLM diagram generation
- Models read ASCII layouts better than they draw them (2026): https://arxiv.org/abs/2604.14641
- ASCII graph drawing failure tracks edge count, r = −0.85 (PlanarBench 2026): https://arxiv.org/abs/2606.02010

## Factory v3 changes (retro 2026-10-22 to 11-04, plan item P2 and decision 6; as of 2026-11-05)

- **The plan station draws the first diagram; later artifacts reuse or update it** (SKILL.md section 2). In the retro the one diagram set was drawn after a 2.5-day build (b07) and eval flows were hand-drawn mid-session with no reuse (b14), so nothing downstream shared a picture. The owner's decision (2026-11-04, no. 6): flow-diagram is not planning-only; PR descriptions, issues, and any doc may draw with it, reusing or updating the plan's diagram when it is the same flow.
- **Updates go to the new artifact plus a `## deviations` line, not into the plan's `## flow`.** The plan item said "write the update back to the plan file", but grill-plan's approval hash covers every byte above `## approval`, flow included, so editing it would mark the plan unconfirmed. The deviations section is the one part later stages own (grill-plan `references/plan-template.md`, section 4). House resolution of that conflict.
- **A bundled parse script, run once per diagram** (`scripts/parse-mermaid.mjs`, SKILL.md section 7). Validating one diagram set by hand took 12 calls (b07). The script uses the official `mermaid` package's `parse()` under jsdom (mermaid 12.3.0 at the time of writing: `graph`, `sequenceDiagram`, `stateDiagram-v2`, and `erDiagram` all parse without a browser), resolved from the skill folder, the project, or npx's cache when re-run through `npx -y -p mermaid -p jsdom`. Its warnings encode the portability rules of `references/mermaid-syntax.md`. The earlier design named the third-party maid validator (see "Specifics removed" below); the official parser was preferred because its acceptance is what renderers do, and maid's stricter grammar rejected forms the docs allow. Exit code 2 is reserved for "parser unavailable" so the skill can tell "not parsed" from "parse failed".
- **"Check once, then parse once"** replaces the earlier per-rule self-check list: repeated self-checks of the same text found nothing new in the retro and cost calls.
- **Eval added**: `reuses-plan-diagram` (a plan file with an ASCII flow and a PR-description ask; the Mermaid must carry the plan's nodes, including one the prompt leaves out).

## Specifics removed from the skill (as of 2026-09-27)
The skill now states these as patterns; the specifics are kept here so nothing is lost.

- Validator: the maid Mermaid validator, run as `npx -y @probelabs/maid <file>` on a `.mmd` file; it comes from npm, and the first run downloads a ~5 MB package. The SKILL.md description said it "can check Mermaid with the maid validator via npx, which downloads it from npm on first use". The overlay example had `validate mermaid with maid: yes`.
- maid uses its own stricter grammar: it rejected a trailing `;` and `-- text -->` edge labels, both allowed by the Mermaid docs; the simpler forms it accepts are `-->|text|` and no `;`.
- Palette name: the role palette was described as "Okabe-Ito-based" (see the Okabe-Ito link above). The concrete default `classDef` block (fills `#CC79A7`, `#0072B2`, `#52514e`, `#56B4E9`, `#E69F00`, `#009E73`, `#D55E00`; text `#1a1a19` or `#fff`) stays in `references/mermaid-syntax.md` and the worked example as a copy-paste default.
- Contrast threshold: every fill had "at least 4.5:1 text contrast" (the WCAG AA ratio for normal text); a custom palette had to "keep every fill at 4.5:1 or better against its text color".
- Stroke: the grey `#888` stroke was named as the value that keeps nodes visible on white and dark pages (it remains in the default `classDef` block).
- Role ceiling: "Seven roles is the ceiling"; a new kind of node reused the closest role "instead of adding an eighth color".
- Legend threshold: add a legend "when more than three role types appear" (kept as a labelled default).
- Diagram size: "about 12 nodes" for Mermaid and "about 8 edges" for hand-drawn ASCII, stated as fixed limits (kept as labelled defaults the project settings can change).
- ASCII width: "at most 72 columns" as a fixed rule (kept as a labelled default the project settings can change).
- Mermaid version fact: "The v11 `@{ shape: … }` syntax isn't reliable across platforms, and it can't take a `:::class`" (mermaid #7826, linked above).
