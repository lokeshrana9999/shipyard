---
name: flow-diagram
description: Draws flowcharts, sequence and state diagrams for any written artifact (plan, PR, issue, doc), in Mermaid where it renders and ASCII elsewhere, reusing the plan's diagram for the same flow. Use when asked to "draw a diagram of this flow" or "add a sequence diagram", when about to draw any diagram, or when another skill asks for one. For data charts (bar, line, pie), use a charting skill instead.
---

# Flow diagram

Input: the flow to draw and where the diagram will be read. Output: one diagram in that destination's syntax, checked as section 7 says.

A diagram works when the reader can tell each node's role from its shape before reading its label, and can follow the flow in one direction without backtracking. Three conventions get there: a shape per role, a color per role, and layout discipline. Apply all three; they reinforce each other.

## 1. Project settings

On every invocation, read `.claude/shipyard/flow-diagram.md` in the project root if it exists. It describes this project: where its diagrams are read, whether its markdown is read rendered, its renderer's limits, and any palette, size, or width overrides; its shape is in [references/overlay-example.md](references/overlay-example.md). Its settings win over the defaults below. Without it, use the defaults as written.

## 2. Start from the plan's diagram

The plan stage draws the first diagram of a change, into the plan file at `.claude/shipyard/plans/<branch>.md` (`<branch>` is the branch name with `/` replaced by `-`) under `## flow`. Before drawing for any later artifact about the same change (a PR description, an issue, a handoff, an ADR, a demo script), read that section.

- **Same flow: reuse it.** Keep its nodes, labels, and branches, translated into the destination's syntax (ASCII in the plan becomes Mermaid in a PR body). Two diagrams of one flow that disagree cost the reader more than none.
- **The flow changed since the plan: update it** in the new artifact, and append one line to the plan's `## deviations` section (`<date> <stage>: flow changed: <what>`). Don't edit the plan above its `## approval` heading: the approval hash covers that text, and a change there makes the plan unconfirmed. A change that alters a decision goes back through the plan stage.
- **A new question gets a new diagram**, not a variant of the plan's. Section 3 says which.

With no plan file, this skill draws the first diagram, and the artifact it lands in becomes the one later artifacts reuse.

## 3. Route by destination

Choose the syntax by where the diagram will be read.

| Destination | Read in | Syntax |
|---|---|---|
| A page that renders Mermaid: docs site, wiki, PR or issue description, ADR | rendered page | Mermaid, per [references/mermaid-syntax.md](references/mermaid-syntax.md) |
| A markdown file in the repo: plan, handoff, spec, report | editor or terminal | ASCII, per [references/ascii-diagrams.md](references/ascii-diagrams.md) |
| Chat reply | terminal | ASCII |

- Markdown in a repo is mostly read in an editor, where Mermaid shows as source instead of a figure, so it gets ASCII by default. The project settings can say the team reads it rendered.
- One artifact, one syntax.
- If the destination is unknown, ask before drawing; guessing costs a full redraw.

## 4. Pick the diagram type

One diagram answers one question. If you can't name the question, you don't yet know what to draw.

| Question | Type |
|---|---|
| Where does data or control go? | flowchart, `LR` |
| What happens if a check fails? | flowchart, `TB`, with a decision gate |
| Who calls whom, in what order, and what if it fails? | sequence diagram, with `alt` for branches |
| What states can this thing be in? | state diagram |
| How do tables relate? | ER diagram |

## 5. Shapes and colors by role

Each role has one shape and one color, used the same way in every diagram so the reader learns it once. Whatever palette is in use, it follows four rules:

- The colors differ in lightness as well as hue, so color-blind readers can still separate them.
- Text on every fill meets accessibility contrast for normal text.
- A neutral mid-tone stroke on every node keeps it visible on both light and dark pages.
- Color never carries meaning alone; shape or label carries it too.

| Role | Mermaid shape | Class | Default fill / text |
|---|---|---|---|
| Actor: user or external system | circle `id((User))` | `actor` | reddish purple, dark text |
| UI surface: page, tab, modal | stadium `id([Upload form])` | `ui` | blue, white text |
| Service, logic, module | rectangle `id[Scanner]` | `logic` | slate, white text |
| API endpoint or boundary | subroutine `id[[POST /uploads]]` | `logic` | slate; the shape marks the boundary |
| Datastore, table, cache | cylinder `id[(Object store)]` | `data` | sky blue, dark text |
| Decision or validation gate | diamond `id{File valid?}` | `gate` | orange, dark text |
| Outcome leaving the system | parallelogram `id[/201 created/]` | `ok` or `reject` | bluish green or vermillion, dark text |

- Pair every color with a difference in shape or label, so the meaning survives for color-blind readers and in grayscale. Outcomes differ in label (`201 created`, `415 rejected`), since red and green are the pair color-blind readers confuse most.
- Use `ok` and `reject` only for real outcomes. A diagram with no branch has no outcome colors.
- When a diagram uses more role types than a reader decodes at a glance (default: more than three), add a one-line legend under the diagram, for example `pill = UI, cylinder = store, diamond = check`. The shape mapping is a convention the reader doesn't know yet.
- Keep the role set fixed. A new kind of node reuses the closest role instead of adding a color: every added color is harder to tell from the others and one more thing to learn.

A default `classDef` block that meets these rules is in `references/mermaid-syntax.md`; the project settings can replace it.

## 6. Layout

- **Fewest crossings first.** Edge crossings hurt comprehension more than any other layout flaw. Reorder nodes or split the diagram before accepting one.
- **Small diagrams.** Size hurts comprehension more than layout does. Keep a diagram small enough to take in at once, and a hand-drawn ASCII diagram smaller still, since its alignment errors grow with the number of edges. Past that, split into two diagrams, each answering its own question. Defaults: about 12 nodes for Mermaid, about 8 edges for ASCII; the project settings can change them.
- **One reading direction.** `LR` for pipelines and request flows, `TB` for decision logic. At most one back-edge, labelled as the loop it is (`inline errors`). Two back-edges mean the wrong direction or two diagrams in one.
- **Label only branch and feedback edges.** A bare arrow already says "next". HTTP verbs, status codes, and sentences go in node labels or the surrounding prose.
- **Node labels are noun phrases**: `Scanner`, not `scanner.worker.ts` or `Scan the file for viruses`. The shape already says what kind of thing it is.
- **Subgraphs only for a real boundary** the reader cares about, such as everything client-side or one deployed service, with more than one node each.
- **One arrow per relationship.** Two nodes firing the same arrow at the same target usually hide one shared upstream node.

## 7. Check before shipping

For Mermaid, check the structure by eye once, then parse once:

1. Every meaningful node has a class; no role is left as a bare rectangle. Every branch is visible: a diamond with labelled exits, or an `alt` block in a sequence diagram.
2. Parse the diagram with the bundled script, run (not read) once per diagram: `node <this skill's folder>/scripts/parse-mermaid.mjs <file>`, where the file is the markdown artifact (every ```` ```mermaid ```` block in it is parsed) or a `.mmd` file holding one diagram. It uses the official Mermaid parser and warns about syntax outside the portable subset in `references/mermaid-syntax.md`. The first run may download the parser (`mermaid` and `jsdom`, unpinned, from the npm registry) through npx; `--no-npx` refuses the download and uses only an installed one. Read the result as follows:
   - `error`: fix what it names and run once more. A parser may be stricter than renderers, so when it rejects a form the Mermaid docs allow, switch to the simpler syntax it accepts instead of arguing with it.
   - `warn`: change the syntax unless the project settings say this renderer supports the form.
   - exit code 2 (parser unavailable): apply the portability rules in `references/mermaid-syntax.md` by hand, and say in the artifact that the diagram wasn't parsed.
   - `ok`: ship it. Don't re-check by eye after a pass; the parse is the check, and repeated self-checks of the same text find nothing new. Parsing doesn't prove every renderer will draw it, so the portability rules still apply.

For ASCII, use the checklist in `references/ascii-diagrams.md`.

For worked before-and-after examples of every rule above, read [references/examples.md](references/examples.md) when a diagram isn't coming together.
