# Verifying a browser extension

Read this when the change under test is a browser extension. What loads is the built output, not the source, so every claim rests on three things: which browser executable ran it, how fresh the build was, and how its background worker was observed.

## Browser gate

The executable decides the outcome before anything else. Browsers differ, by brand and by version, in whether they honor the command-line switches that load an unpacked extension, and a refusal can be silent: the switches are accepted, then discarded. Name the executable in the report, and use one already observed to load unpacked extensions: from project settings, or from a run that proved it.

Labelled default: branded builds of the most common browser discard the load-unpacked switch, silently, while the browser a test driver bundles and other Chromium-based browsers accept it. Branded builds still allow loading through the browser's debugging protocol, but that's a different path from the one users take; prefer a browser that accepts the switch.

## One symptom, four causes

"The background worker never appeared" has four unrelated causes:

```
worker absent
   |
   +-- the browser discarded the extension switches   <-- silent unless logging is on
   +-- the build is stale or missing
   +-- the worker exists but was observed wrong
   +-- the extension genuinely failed to start
```

Launch with the browser's logging sent to stderr: a browser that discards the switches says so there. Without it, a discarded switch looks the same as bot detection or a broken build.

## Loading

- Extensions load only into a **persistent browser profile**. A throwaway, stateless launch can't carry them, whatever the flags say.
- Background service workers are unreliable **headless** in most browsers. Run headed unless the driver documents headless extension support for the browser it bundles; an unsupported headless run brings back the four-causes ambiguity.
- **Build first**, with the project's build command. A stale build presents exactly like a discarded switch.
- The worker starts **lazily**. Its start event can fire before or after a listener registered after launch, so check for an existing worker before waiting for the event, and wait with a timeout, so observation fails instead of hanging. The extension's id is in the worker's URL.
- The worker is **stopped when idle** in real use, but automation and open developer tools keep it alive, so a normal run hides bugs where state is lost between wake-ups. When the change keeps state in the worker, stop the worker on purpose mid-flow and check the state survives.
- The browser driver has to resolve from where the script runs. If the extension's own package doesn't depend on one, run the driver from a package that does.

## Injection

- Content scripts arrive either by the manifest's match patterns or programmatically from the background worker. Read which one the change uses before driving it.
- Nothing scriptable can click the browser's toolbar icon. Set whatever state the icon's click handler sets, and say so in the report.
- Injecting the script yourself tests your injection, not the extension's.
- An injected root can be **attached but not visible**, for example while a panel is collapsed. Wait for attachment, then check visibility separately.
- Extension storage holds the extension's own session. Put a test session there the same way the extension does, reading the claim shape from the auth code each run.

## Test page host

A page served from a bare local IP gives host-dependent code an address where it expects a domain, so scoring, URL patterns, allowlists, and per-site rules can silently take another path. When the behavior reads the host, map realistic hostnames to the local server with the browser's host-resolver option, or say in the report that the host-dependent path wasn't exercised.

## Symptom table

| Symptom | First distinction to make |
| --- | --- |
| Worker never appears | Discarded switches or a stale build: relaunch with logging on |
| Timeout finding injected UI | Attached or visible; and whether the tab is the one the worker targeted |
| Extension UI never reaches its signed-in state | Token claims or origin: compare against the auth code |
| An expected network call never fires | Injection worked, but a later step didn't: read the page console first |
| Plausible data that still fails checks | The environment doesn't hold what the check assumed |

## What makes a run trustworthy

- The executable is named, and is one observed to load unpacked extensions.
- Every service and data dependency stayed up for the whole run.
- Host-dependent behavior ran against realistic hostnames, or the report says it didn't.
- Nothing is claimed about paths that weren't driven.
