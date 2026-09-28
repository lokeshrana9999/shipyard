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
