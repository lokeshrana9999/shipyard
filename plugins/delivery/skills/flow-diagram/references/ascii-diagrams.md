# ASCII diagrams

For terminals, chat replies, and repo markdown read in an editor. Drawn by hand, so the rules below are what keeps a hand-drawn grid aligned.

## Rules

- **Plain ASCII only**: `+ - | < > v ^ X`. It renders the same in any monospace context, including plain email and `cat`.
- **Fit the narrowest reader**: default 72 columns; the project settings can change it. Wider rows wrap once a terminal reserves a column or a chat pane indents, and one wrapped row breaks the figure.
- **Keep it small, smaller than a rendered diagram.** Alignment errors grow with the number of edges, not boxes. Past the limit (default about 8 edges; the project settings can change it), split into two diagrams.
- **Boxes** are `+----+` with the label inside. A label n characters wide gets n+2 dashes on the top and bottom borders.
- **Give boxes in one column the same width.** Pad shorter labels with spaces. Arrows then leave from and arrive at the same column, which removes most misalignment.
- **One reading direction**: top to bottom by default, left to right for a short pipeline. At most one back-edge, labelled as the loop.
- **Arrows**: `-->` horizontal, `|` then `v` vertical. Plain "and then" arrows stay unlabelled.
- **Branches**: a gate is the only box whose label ends in `?`, and it has two or more labelled exits. A horizontal exit carries its label inline (`--valid-->`); a vertical exit carries it as a word on its own row under the arm.
- **Aborts**: the failing exit ends in `X` and the outcome: `--fail--> X 415 rejected`. `X` is the only terminal marker; a successful end is just the last box.
- **Labels are noun phrases.** An exact identifier is fine when it is the subject (`POST /uploads`, `:8080`); a filename standing in for a role isn't.

Role has no shape or color here, so it rides the label and position: gates end in `?`, actors are named as people or systems, stores are named as the store (`object store`), and outcomes leave the flow. Keep every box a plain rectangle; invented ASCII shapes like `((circle))` read as noise.

## Template

An upload with validation:

```
+---------------+     +---------------+
| upload form   | --> | file valid?   |--fail--> X 415 rejected
+---------------+     +---------------+
                              |
                            valid
                              |
                              v
                      +---------------+
                      | object store  |
                      +---------------+
```

## Before sending

1. Every row fits the width limit (default 72 columns). Count the longest row.
2. Every box's top and bottom borders are the same length, and its side bars line up in the same columns on every row. Count the characters; don't judge by eye.
3. Every vertical arrow stays in one column from start to end.
4. One reading direction, at most one back-edge, and it's labelled.
5. Only branch and feedback edges carry labels.
6. Every branch is a `?` gate with two or more labelled exits, and every abort ends in `X` with its outcome.
7. The edge count is within the size limit (default about 8), and the diagram answers one question.
