# Mermaid syntax

Copy-paste syntax for the shapes, classes, and structures SKILL.md prescribes. It sticks to the portable subset of Mermaid: the syntax that older and restricted renderers accept, so a diagram renders wherever it ends up. Project settings can relax or tighten these rules for a known renderer.

Contents: portability rules · node shapes · classes · subgraphs · edges · sequence diagrams · state diagrams

## Portability rules

- Start flowcharts with `graph LR` or `graph TB`. Some renderers accept only the older `graph` keyword, not `flowchart`.
- Use `-->`, not the long arrow `---->`, which some renderers reject.
- Keep labels to one line of plain text. Many renderers strip HTML, including `<br/>`. A label that needs two lines is two nodes or a shorter name.
- Use the classic bracket shapes below. Newer node-shape syntax (such as `@{ shape: … }`) isn't reliable across renderers and may not combine with `:::class`, which would cost the node its role color.
- Leave out icons (`fa:`, `registerIconPacks`). They need fonts or page scripts most hosted renderers don't load.
- Leave out `%%{init}%%` directives and `config:` theme blocks. Renderers that follow the page's light or dark theme lose that switch when a directive sets one, which can leave dark arrows on a dark page.
- Stick to `graph`, `sequenceDiagram`, `stateDiagram-v2`, and `erDiagram`. Beta diagram types such as `architecture-beta` and `block-beta` aren't widely supported.
- Fence with ```` ```mermaid ````, the most widely accepted fence.

## Node shapes

| Shape | Syntax | Role |
|---|---|---|
| Circle | `id((User))` | actor |
| Stadium | `id([Upload form])` | UI surface |
| Rectangle | `id[Scanner]` | service, logic |
| Subroutine | `id[[POST /uploads]]` | API endpoint, boundary |
| Cylinder | `id[(Object store)]` | datastore |
| Diamond | `id{File valid?}` | decision gate |
| Parallelogram | `id[/201 created/]` | outcome |

Quote a label that contains punctuation Mermaid reserves: `id["POST /uploads (multipart)"]`.

## Classes

A default palette that meets the color rules in SKILL.md: fills that differ in lightness as well as hue, readable text contrast on every fill, and a neutral mid-tone stroke. Paste this block at the bottom of a `graph`, keeping only the lines you use, and tag nodes with `:::class`. A project palette from the settings replaces it.

```
classDef actor  fill:#CC79A7,color:#1a1a19,stroke:#888,stroke-width:1.5px
classDef ui     fill:#0072B2,color:#fff,stroke:#888,stroke-width:1.5px
classDef logic  fill:#52514e,color:#fff,stroke:#888,stroke-width:1.5px
classDef data   fill:#56B4E9,color:#1a1a19,stroke:#888,stroke-width:1.5px
classDef gate   fill:#E69F00,color:#1a1a19,stroke:#888,stroke-width:1.5px
classDef ok     fill:#009E73,color:#1a1a19,stroke:#888,stroke-width:1.5px
classDef reject fill:#D55E00,color:#1a1a19,stroke:#888,stroke-width:1.5px
```

- Always set both `fill` and `color`. The page theme controls anything without them, so a node without `color` can end up as dark text on a dark fill.
- The neutral mid-tone stroke keeps every node's edge visible on both light and dark pages, including a dark fill such as `logic`, which alone is too close to a dark background.
- Apply by id instead of inline with `class Scan,Store logic`, with no spaces after the commas.
- Style subgraphs too, with `style Client fill:none` plus the same stroke as the nodes (`stroke:#888` in the default). `fill:none` lets the title keep the theme's text color, which switches correctly between light and dark.
- Edge labels sit on a theme-controlled background you can't style portably, so keep them to a word or two.

## Subgraphs

```
graph LR
    subgraph Client[Browser]
        direction TB
        Form([Upload form]):::ui --> Check[Client-side checks]:::logic
    end
    Client --> Api[[POST /uploads]]:::logic
    style Client fill:none,stroke:#888
```

`subgraph Id[Title]` sets the visible title. A `direction` line inside the subgraph sets its internal flow independently of the parent.

## Edges

| Form | Syntax |
|---|---|
| Arrow | `A --> B` |
| Labelled arrow | `A -->|valid| B` |
| Dotted (async, optional) | `A -.-> B` |
| Thick (the main path) | `A ==> B` |

Use `linkStyle` sparingly: its edge index shifts when edges are added, so it breaks silently.

## Sequence diagrams

```
sequenceDiagram
    actor User
    participant UI as Upload form
    participant API as Upload API
    participant S as Scanner

    User->>UI: Choose file
    UI->>API: POST /uploads
    API->>S: Scan file
    alt file rejected
        S-->>API: wrong type or too large
        API-->>User: 415 rejected
    else file accepted
        S-->>API: clean
        API-->>User: 201 created
    end
```

- `actor` is the human. Name each `participant` as the system it represents; HTTP verbs and routes go in the messages.
- `->>` for calls, `-->>` for responses, so calls and returns read apart at a glance.
- Show an accept-or-reject fork as an `alt`/`else` block with one return per outcome. `opt` marks an optional step, `loop` a repetition, `par` concurrency.

## State diagrams

```
stateDiagram-v2
    [*] --> Uploaded
    Uploaded --> Scanning: scan starts
    Scanning --> Available: clean
    Scanning --> Quarantined: infected
    Available --> [*]
```

`[*]` is the start or end. Transition labels name the event.
