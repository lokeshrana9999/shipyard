# Worked examples

Contents: flowchart before and after · sequence diagram before and after

One scenario runs through both pairs: a user uploads a file, and the server checks it before storing it. Copy the technique (role shapes, classes, one direction, a visible gate), not these boxes. The "before" versions are deliberately wrong.

## Flowchart

### Before: wrong

```mermaid
graph LR
    subgraph Browser[Upload page]
        Form[Upload form]
        Picker[File picker]
        Utils[upload.utils.ts]
    end
    subgraph Server[Validation]
        Check[Check type and size and reject bad files]
    end
    Form --> Utils
    Picker --> Utils
    Form -->|POST /uploads| Check
    Picker -->|POST /uploads| Check
    Check -->|415 if wrong type, 413 if too large| Form
    Utils -->|progress| Form
```

What's wrong:

1. Every node is a plain rectangle, so the form, the utility module, and the check look alike and the reader has to read every label.
2. No classes, so nothing draws the eye to the check, which is the point of the diagram.
3. `POST /uploads` sits on two identical edges, and a sentence rides on the reject edge.
4. Two back-edges (`415 …` and `progress`) turn an `LR` flow into a tangle.
5. The `Validation` subgraph wraps a single node, and `Upload page` mixes UI with a code module.
6. A filename (`upload.utils.ts`) stands in for a role.
7. The accept path isn't drawn at all, so the branch is invisible.

### After

```mermaid
graph LR
    User((User)):::actor
    Form([Upload form]):::ui
    Api[[POST /uploads]]:::logic
    Check{File valid?}:::gate
    Store[(Object store)]:::data
    Created[/201 created/]:::ok
    Rejected[/415 rejected/]:::reject

    User --> Form
    Form --> Api
    Api --> Check
    Check -->|valid| Store
    Store --> Created
    Check -->|wrong type or too large| Rejected

    classDef actor  fill:#CC79A7,color:#1a1a19,stroke:#888,stroke-width:1.5px
    classDef ui     fill:#0072B2,color:#fff,stroke:#888,stroke-width:1.5px
    classDef logic  fill:#52514e,color:#fff,stroke:#888,stroke-width:1.5px
    classDef data   fill:#56B4E9,color:#1a1a19,stroke:#888,stroke-width:1.5px
    classDef gate   fill:#E69F00,color:#1a1a19,stroke:#888,stroke-width:1.5px
    classDef ok     fill:#009E73,color:#1a1a19,stroke:#888,stroke-width:1.5px
    classDef reject fill:#D55E00,color:#1a1a19,stroke:#888,stroke-width:1.5px
```

Legend: circle = user, pill = UI, double bars = API, diamond = check, cylinder = store, parallelogram = outcome.

What changed: each role has its shape and class, the check is an orange diamond with two labelled exits, the outcomes differ in label as well as color, the HTTP route is a node instead of an edge label, and there are no back-edges or filenames.

## Sequence diagram

### Before: wrong

```mermaid
sequenceDiagram
    participant U as User
    participant P as POST /uploads
    participant V as upload.validator.ts
    U->>P: Upload file
    P->>V: Check type, size, virus scan
    V-->>U: 415/413 error or 201 created
```

What's wrong: `POST /uploads` is a request, not a system, and `upload.validator.ts` is a filename. One message crams three checks together. Worst, the accept-or-reject fork is flattened into a single "error or created" return, so the decision isn't a branch at all.

### After

```mermaid
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

What changed: participants are systems, the HTTP route is a message, and the fork is an `alt` block showing both outcomes.
