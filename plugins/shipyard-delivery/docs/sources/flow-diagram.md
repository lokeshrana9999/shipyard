# Sources: flow-diagram

Provenance for the rules in `skills/flow-diagram/` (SKILL.md and references/). Kept outside the skill folder so it never loads into context.

## Platform support
- Azure DevOps Mermaid limits (`graph` not `flowchart`, no long arrow, no Font Awesome, limited HTML; supported diagram types): https://learn.microsoft.com/en-us/azure/devops/project/wiki/markdown-guidance?view=azure-devops
- Azure DevOps accepts ```` ```mermaid ```` in wiki, PRs, and work items (Sprint 274, May 2026): https://learn.microsoft.com/en-us/azure/devops/release-notes/2026/wiki/sprint-274-update
- GitHub diagram support (Mermaid, GeoJSON, TopoJSON, STL only): https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams
- GitHub switches the Mermaid theme with the page theme: https://github.com/orgs/community/discussions/35733
- `@{ shape }` can't take a `:::class` (mermaid #7826): https://github.com/mermaid-js/mermaid/issues/7826
- maid validator: https://github.com/probelabs/maid
- The portability rules in `references/mermaid-syntax.md` that say "some renderers" (`graph` only, no long arrow, HTML stripped from labels, icons not loaded) rest on the Azure DevOps limits above. No other renderer was checked for them, so the reference says "some", not "many" or "most" (#26).

## Perception and comprehension
- Edge crossings hurt comprehension most (Purchase 1997): https://link.springer.com/chapter/10.1007/3-540-63938-1_67
- Diagram size outweighs layout flaws (Störrle 2016): https://link.springer.com/article/10.1007/s10270-016-0529-x
- Redundant color and shape coding aids grouping (Nothelfer, Gleicher, Franconeri 2017): https://graphics.cs.wisc.edu/Papers/2017/NGF17/Nothelfer,%20Gleicher,%20Franconeri%20-%20JEP%20HPP%202017.pdf
- Redundancy helps most at 5–8 categories (CatPAW 2026): https://arxiv.org/abs/2602.06792
- Semantic transparency of notations needs a key for novices: https://link.springer.com/article/10.1007/s10270-021-00895-w
- Color must not be the only carrier of meaning (WCAG 1.4.1): https://www.w3.org/WAI/WCAG21/Understanding/use-of-color
- Okabe-Ito color-blind-safe palette: https://jfly.uni-koeln.de/color/
- Color-vision deficiency simulation (Machado, Oliveira, Fernandes 2009), used for the palette check below: https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html

## LLM diagram generation
- Models read ASCII layouts better than they draw them (2026): https://arxiv.org/abs/2604.14641
- ASCII graph drawing failure tracks edge count, r = −0.85 (PlanarBench 2026): https://arxiv.org/abs/2606.02010

## Palette check (2026-10-11)
The default `classDef` fills, measured against the color rules in SKILL.md "Shapes and colors by role" (#26):

- Lightness doesn't separate every pair: CIELAB L* is 69.8 for `data` (`#56B4E9`) and 70.6 for `gate` (`#E69F00`), 57.7 for `ok` (`#009E73`) and 54.2 for `reject` (`#D55E00`). The rule used to say the colors "differ in lightness as well as hue"; it now says the hues stay distinct under the common color-vision deficiencies, and grayscale relies on shape and label.
- Hue does separate them: simulated at full severity with the Machado 2009 matrices on linear RGB, the closest pair of fills is 20.7 CIELAB units apart under protanopia (`actor`, `data`), 17.9 under deuteranopia (`actor`, `ok`), and 16.1 under the rarer tritanopia (`data`, `ok`).
- Text contrast: every fill meets 4.5:1 against its text color; `reject` is lowest at 4.504:1.

## Defaults (as of 2026-10-11)
All house defaults. The studies above back the direction of the size defaults, not their numbers.

- ASCII for markdown in the repo, because it reads the same in an editor, a terminal, and a rendered page (SKILL.md "Route by destination"). House default: how a team reads its repo markdown wasn't measured, so the project settings can say it reads it rendered.
- A legend when a diagram uses more than three role types (SKILL.md "Shapes and colors by role"). House default; the semantic-transparency study above backs giving novices a key, not the threshold.
- About 12 nodes for Mermaid (SKILL.md "Layout"). House default; Störrle 2016 backs keeping diagrams small, not this number.
- About 8 edges for hand-drawn ASCII (SKILL.md "Layout", ascii-diagrams.md). House default; PlanarBench backs counting edges rather than boxes, not this number.
- 72 columns for ASCII (ascii-diagrams.md). House default: under the common 80-column terminal, with room for a reserved column or an indented chat pane.
- One reading direction, with at most one back-edge (SKILL.md "Layout"). House default: a search on 2026-10-11 found no comprehension study of flow direction or back-edges; Burattin et al. 2016 (https://arxiv.org/abs/1602.02992) measures how people perceive flow consistency, not whether it aids understanding.
- Label only branch and feedback edges (SKILL.md "Layout"). House default.
- Node labels are noun phrases (SKILL.md "Layout"). House default; the shape already gives the kind of thing, so the label names it.
- One arrow per relationship (SKILL.md "Layout"). House default.

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
