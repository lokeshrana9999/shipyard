# Shipyard

Agent Skills that take a code change through a delivery pipeline. These terms are the ones the skills, docs, and settings files share.

## Language

**Stage**:
One step of the delivery pipeline (explain, plan, test design, implement, verify live, review, describe, demo), run by one skill or by the agent's normal session.
_Avoid_: step, phase

**Handoff**:
The line that ends a stage skill by naming the stage that comes next; it names that stage, it never starts it.
_Avoid_: routing, next step

**User-started skill**:
A skill the agent never starts on its own; only the user starts it, with its command in Claude Code or by asking for it by name in other agents.
_Avoid_: user-invoked, user-only, manual skill

**Settings file**:
A project's `.claude/shipyard/<skill>.md`, whose values win over a skill's defaults.
_Avoid_: overlay, config

**House default**:
A default value or rule the maintainers chose by judgment, with no source or measurement behind it.
_Avoid_: guess, arbitrary default, unsourced default

**Adapter**:
The tool-specific part of the migration skill: which tool a project uses, how it is detected, and the commands that create, apply, and check migrations. Shipped per tool, overridden by the settings file.
_Avoid_: driver, provider, backend

**Development database**:
A database whose data can be lost without harming anyone. Defined by that role, not by where it is hosted.
_Avoid_: local database, dev DB

**Risky change**:
A schema change whose generated migration can lose data or lock a busy table. The migration skill lists them in one table and stops for every one.
_Avoid_: dangerous change, destructive change

**Gate**:
A point in a skill where the agent stops, shows what it is about to do, and waits for the user to choose.
_Avoid_: checkpoint, approval step
