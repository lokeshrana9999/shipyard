# Browser evidence

Read this before driving a user interface. A browser run proves something only when someone could look at the evidence and see the claim.

## Find with text, judge with pixels

- Use the page's accessibility or DOM snapshot to **find** things to click and type into. It's cheap and names elements exactly.
- Use a screenshot to **judge** whether the expected result is on screen. A snapshot proves an element is in the tree, never that a person can see it: it can be covered by a modal, clipped by a parent, transparent, or far below the fold.

## Frames at beats

A beat is one step of the flow where something observable should change. A snapshot is enough to confirm a navigation step; any claim about what a person sees needs a frame you looked at. Per beat, take the frames yourself and look at each one:

- the frame where the expected result should be on screen; this one decides pass or fail;
- a frame of anything wrong: an error, an empty state, a spinner that outlives a few seconds, a control you can't find;
- a before frame, only when it's what makes the after frame meaningful.

Usually two to four frames a beat. Request the screenshot so the image comes back to you, then save the frames that decide a beat to disk so a reviewer can re-read them. Hide dev-only overlays (element outlines, debug toolbars) before capturing; they don't represent what users see.

Don't build a timed recorder that captures frames on a schedule. It produces near-identical frames, misses the beat, and hides blockers, such as a modal covering the page in every frame, behind a frame count that looks healthy. Frames nobody looked at aren't evidence.

## A beat passes only if you saw it

When the expected element isn't visible, find out which of these it is, because they need different fixes:

- **absent**: not in the tree at all, so the render or data path failed;
- **hidden**: in the tree, but its bounding box is empty, its computed display or visibility hides it, or it sits outside the viewport or a clipping parent;
- **covered or transparent**: laid out and "visible" to a driver's actionability check, but another element sits on top of it or its opacity is zero. Drivers usually count these as visible, so a passing wait doesn't rule them out.

Check with a script in the page: the element's bounding rectangle, its computed style, and the element found at its center point (a different element there means something covers it). Report which case it was.

## Waiting

Wait on a condition (an element, a network response, a text change), never on a fixed delay. A fixed delay is either too short on a slow run or wasted on a fast one, and a timeout that expires is a finding, not a reason to retry until it passes.
